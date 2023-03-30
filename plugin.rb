# frozen_string_literal: true

# name: discourse-topic-voting
# about: Adds the ability to vote on features in a specified category.
# version: 0.5
# author: Joe Buhlig joebuhlig.com, Sam Saffron
# url: https://github.com/discourse/discourse-topic-voting

register_asset "stylesheets/common/topic-voting.scss"
register_asset "stylesheets/desktop/topic-voting.scss", :desktop
register_asset "stylesheets/mobile/topic-voting.scss", :mobile

enabled_site_setting :voting_enabled

Discourse.top_menu_items.push(:votes)
Discourse.anonymous_top_menu_items.push(:votes)
Discourse.filters.push(:votes)
Discourse.anonymous_filters.push(:votes)

after_initialize do
  module ::DiscourseTopicVoting
    PLUGIN_NAME = "discourse-topic-voting"

    class Engine < ::Rails::Engine
      isolate_namespace DiscourseTopicVoting
    end
  end

  %w[
    app/controllers/discourse_topic_voting/votes_controller.rb
    app/jobs/onceoff/voting_ensure_consistency.rb
    app/jobs/regular/vote_reclaim.rb
    app/jobs/regular/vote_release.rb
    app/models/discourse_topic_voting/category_setting.rb
    app/models/discourse_topic_voting/topic_vote_count.rb
    app/models/discourse_topic_voting/vote.rb
    lib/discourse_topic_voting/categories_controller_extension.rb
    lib/discourse_topic_voting/category_extension.rb
    lib/discourse_topic_voting/list_controller_extension.rb
    lib/discourse_topic_voting/topic_extension.rb
    lib/discourse_topic_voting/topic_query_extension.rb
    lib/discourse_topic_voting/user_extension.rb
  ].each { |path| require_relative path }

  reloadable_patch do
    CategoriesController.class_eval { prepend DiscourseTopicVoting::CategoriesControllerExtension }
    Category.class_eval { prepend DiscourseTopicVoting::CategoryExtension }
    ListController.class_eval { prepend DiscourseTopicVoting::ListControllerExtension }
    Topic.class_eval { prepend DiscourseTopicVoting::TopicExtension }
    TopicQuery.class_eval { prepend DiscourseTopicVoting::TopicQueryExtension }
    User.class_eval { prepend DiscourseTopicVoting::UserExtension }
  end

  add_to_serializer(:post, :can_vote, false) { object.topic&.can_vote? }
  add_to_serializer(:post, :include_can_vote?) do
    SiteSetting.voting_enabled && object.post_number == 1
  end

  add_to_serializer(:topic_view, :can_vote) { object.topic.can_vote? }
  add_to_serializer(:topic_view, :vote_count) { object.topic.vote_count }
  add_to_serializer(:topic_view, :user_voted) do
    scope.user ? object.topic.user_voted?(scope.user) : false
  end

  if TopicQuery.respond_to?(:results_filter_callbacks)
    TopicQuery.results_filter_callbacks << ->(_type, result, user, options) do
      result = result.includes(:topic_vote_count)

      if user
        result =
          result.select(
            "topics.*, COALESCE((SELECT 1 FROM discourse_voting_votes WHERE user_id = #{user.id} AND topic_id = topics.id), 0) AS current_user_voted",
          )

        if options[:state] == "my_votes"
          result =
            result.joins(
              "INNER JOIN discourse_voting_votes ON discourse_voting_votes.topic_id = topics.id AND discourse_voting_votes.user_id = #{user.id}",
            )
        end
      end

      if options[:order] == "votes"
        sort_dir = (options[:ascending] == "true") ? "ASC" : "DESC"
        result =
          result.joins(
            "LEFT JOIN discourse_voting_topic_vote_count ON discourse_voting_topic_vote_count.topic_id = topics.id",
          ).reorder(
            "COALESCE(discourse_voting_topic_vote_count.votes_count,'0')::integer #{sort_dir}, topics.bumped_at DESC",
          )
      end

      result
    end
  end

  add_to_serializer(:category, :custom_fields, false) do
    return object.custom_fields if !SiteSetting.voting_enabled

    object.custom_fields.merge(
      enable_topic_voting:
        DiscourseTopicVoting::CategorySetting.find_by(category_id: object.id).present?,
    )
  end

  add_to_serializer(:topic_list_item, :vote_count, false) { object.vote_count }
  add_to_serializer(:topic_list_item, :can_vote, false) { object.can_vote? }
  add_to_serializer(:topic_list_item, :user_voted, false) do
    object.user_voted?(scope.user) if scope.user
  end
  add_to_serializer(:topic_list_item, :include_vote_count?) { object.can_vote? }
  add_to_serializer(:topic_list_item, :include_can_vote?) do
    SiteSetting.voting_enabled && object.regular?
  end
  add_to_serializer(:topic_list_item, :include_user_voted?) { object.can_vote? }
  add_to_serializer(:basic_category, :can_vote, false) { true }
  add_to_serializer(:basic_category, :include_can_vote?) { Category.can_vote?(object.id) }

  register_search_advanced_filter(/^min_vote_count:(\d+)$/) do |posts, match|
    posts.where(
      "(SELECT votes_count FROM discourse_voting_topic_vote_count WHERE discourse_voting_topic_vote_count.topic_id = posts.topic_id) >= ?",
      match.to_i,
    )
  end

  register_search_advanced_order(:votes) do |posts|
    posts.reorder(
      "COALESCE((SELECT dvtvc.votes_count FROM discourse_voting_topic_vote_count dvtvc WHERE dvtvc.topic_id = topics.id), 0) DESC",
    )
  end

  add_to_serializer(:current_user, :votes_exceeded) { object.reached_voting_limit? }
  add_to_serializer(:current_user, :votes_count) { object.vote_count }
  add_to_serializer(:current_user, :votes_left) { [object.vote_limit - object.vote_count, 0].max }

  on(:topic_status_updated) do |topic, status, enabled|
    if (status == "closed" || status == "autoclosed" || status == "archived") && enabled == true
      Jobs.enqueue(:vote_release, topic_id: topic.id)
    end

    if (status == "closed" || status == "autoclosed" || status == "archived") && enabled == false
      Jobs.enqueue(:vote_reclaim, topic_id: topic.id)
    end
  end

  on(:topic_trashed) do |topic|
    if !topic.closed && !topic.archived
      Jobs.enqueue(:vote_release, topic_id: topic.id, trashed: true)
    end
  end

  on(:topic_recovered) do |topic|
    Jobs.enqueue(:vote_reclaim, topic_id: topic.id) if !topic.closed && !topic.archived
  end

  on(:post_edited) do |post, topic_changed|
    if topic_changed && SiteSetting.voting_enabled &&
         DiscourseTopicVoting::Vote.exists?(topic_id: post.topic_id)
      new_category_id = post.reload.topic.category_id
      if Category.can_vote?(new_category_id)
        Jobs.enqueue(:vote_reclaim, topic_id: post.topic_id)
      else
        Jobs.enqueue(:vote_release, topic_id: post.topic_id)
      end
    end
  end

  on(:topic_merged) do |orig, dest|
    moved_votes = 0
    duplicated_votes = 0

    if orig.who_voted.present? && orig.closed
      orig.who_voted.each do |user|
        next if user.blank?

        user_votes = user.topics_with_vote.pluck(:topic_id)
        user_archived_votes = user.topics_with_archived_vote.pluck(:topic_id)

        if user_votes.include?(orig.id) || user_archived_votes.include?(orig.id)
          if user_votes.include?(dest.id) || user_archived_votes.include?(dest.id)
            duplicated_votes += 1
            user.votes.destroy_by(topic_id: orig.id)
          else
            user
              .votes
              .find_by(topic_id: orig.id, user_id: user.id)
              .update!(topic_id: dest.id, archive: dest.closed)
            moved_votes += 1
          end
        else
          next
        end
      end
    end

    if moved_votes > 0
      orig.update_vote_count
      dest.update_vote_count

      if moderator_post = orig.ordered_posts.where(action_code: "split_topic").last
        moderator_post.raw << "\n\n#{I18n.t("topic_voting.votes_moved", count: moved_votes)}"
        if duplicated_votes > 0
          moderator_post.raw << " #{I18n.t("topic_voting.duplicated_votes", count: duplicated_votes)}"
        end
        moderator_post.save!
      end
    end
  end

  DiscourseTopicVoting::Engine.routes.draw do
    post "vote" => "votes#vote"
    post "unvote" => "votes#unvote"
    get "who" => "votes#who"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseTopicVoting::Engine, at: "/voting"

    get "topics/voted-by/:username" => "list#voted_by",
        :as => "voted_by",
        :constraints => {
          username: RouteFormat.username,
        }
  end
end
