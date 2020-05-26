# frozen_string_literal: true

# name: discourse-voting
# about: Adds the ability to vote on features in a specified category.
# version: 0.4
# author: Joe Buhlig joebuhlig.com, Sam Saffron
# url: https://github.com/discourse/discourse-voting

register_asset "stylesheets/common/feature-voting.scss"
register_asset "stylesheets/desktop/feature-voting.scss", :desktop
register_asset "stylesheets/mobile/feature-voting.scss", :mobile

enabled_site_setting :voting_enabled

Discourse.top_menu_items.push(:votes)
Discourse.anonymous_top_menu_items.push(:votes)
Discourse.filters.push(:votes)
Discourse.anonymous_filters.push(:votes)

after_initialize do
  module ::DiscourseVoting
    VOTES = "votes".freeze
    VOTES_ARCHIVE = "votes_archive".freeze
    VOTE_COUNT = "vote_count".freeze
    VOTING_ENABLED = "enable_topic_voting"

    class Engine < ::Rails::Engine
      isolate_namespace DiscourseVoting
    end
  end

  User.register_custom_field_type(::DiscourseVoting::VOTES, [:integer])
  User.register_custom_field_type(::DiscourseVoting::VOTES_ARCHIVE, [:integer])
  Topic.register_custom_field_type(::DiscourseVoting::VOTE_COUNT, :integer)
  Category.register_custom_field_type(::DiscourseVoting::VOTING_ENABLED, :boolean)

  load File.expand_path('../app/jobs/onceoff/voting_ensure_consistency.rb', __FILE__)

  reloadable_patch do |plugin|
    require_dependency 'post_serializer'
    class ::PostSerializer
      attributes :can_vote

      def include_can_vote?
        object.post_number == 1 && object.topic && object.topic.can_vote?
      end

      def can_vote
        true
      end
    end

    require_dependency 'topic_view_serializer'
    class ::TopicViewSerializer
      attributes :can_vote, :vote_count, :user_voted

      def can_vote
        object.topic.can_vote?
      end

      def vote_count
        object.topic.vote_count
      end

      def user_voted
        if scope.user
          object.topic.user_voted(scope.user)
        else
          false
        end
      end
    end

    add_to_serializer(:topic_list_item, :vote_count) { object.vote_count }
    add_to_serializer(:topic_list_item, :can_vote) { object.can_vote? }
    add_to_serializer(:topic_list_item, :user_voted) {
      object.user_voted(scope.user) if scope.user
    }

    add_to_serializer(:basic_category, :can_vote, false) do
      SiteSetting.voting_enabled
    end

    add_to_serializer(:basic_category, :include_can_vote?) do
      Category.can_vote?(object.id)
    end

    class ::Category
      def self.reset_voting_cache
        @allowed_voting_cache["allowed"] =
          begin
            Set.new(
              CategoryCustomField
              .where(name: ::DiscourseVoting::VOTING_ENABLED, value: "true")
              .pluck(:category_id)
            )
          end
      end

      @allowed_voting_cache = DistributedCache.new("allowed_voting")

      def self.can_vote?(category_id)
        return false unless SiteSetting.voting_enabled

        unless set = @allowed_voting_cache["allowed"]
          set = reset_voting_cache
        end
        set.include?(category_id)
      end

      after_save :reset_voting_cache
      before_save :reclaim_release_votes

      protected
      def reset_voting_cache
        ::Category.reset_voting_cache
      end

      def reclaim_release_votes
        return if self.new_record?
        return if !SiteSetting.voting_enabled

        aliases = {
          votes: DiscourseVoting::VOTES,
          votes_archive: DiscourseVoting::VOTES_ARCHIVE,
          category_id: id
        }

        was_enabled = CategoryCustomField.where(
          "name = :name AND value similar to :value AND category_id = :id",
          id: id,
          name: ::DiscourseVoting::VOTING_ENABLED,
          value: '(t|T|1)%'
        ).exists?

        is_enabled = custom_fields[::DiscourseVoting::VOTING_ENABLED]

        if !was_enabled && is_enabled
          # Unarchive all votes in the category
          DB.exec(<<~SQL, aliases)
          UPDATE user_custom_fields ucf
          SET name = :votes
          FROM topics t
          WHERE ucf.name = :votes_archive
          AND NOT t.closed
          AND NOT t.archived
          AND t.deleted_at IS NULL
          AND t.id::text = ucf.value
          AND t.category_id = :category_id
          SQL
        elsif was_enabled && !is_enabled
          # Archive all votes in category
          DB.exec(<<~SQL, aliases)
          UPDATE user_custom_fields ucf
          SET name = :votes_archive
          FROM topics t
          WHERE ucf.name = :votes
          AND t.id::text = ucf.value
          AND t.category_id = :category_id
          SQL
        end
      end
    end

    require_dependency 'user'
    class ::User
      def vote_count
        votes.length
      end

      def alert_low_votes?
        (vote_limit - vote_count) <= SiteSetting.voting_alert_votes_left
      end

      def votes
        votes = self.custom_fields[DiscourseVoting::VOTES] || []
        # "" can be in there sometimes, it gets turned into a 0
        votes = votes.reject { |v| v == 0 }.uniq
        votes
      end

      def votes_archive
        archived_votes = self.custom_fields[DiscourseVoting::VOTES_ARCHIVE] || []
        archived_votes = archived_votes.reject { |v| v == 0 }.uniq
        archived_votes
      end

      def reached_voting_limit?
        vote_count >= vote_limit
      end

      def vote_limit
        SiteSetting.public_send("voting_tl#{self.trust_level}_vote_limit")
      end

    end

    require_dependency 'current_user_serializer'
    class ::CurrentUserSerializer
      attributes :votes_exceeded,  :vote_count

      def votes_exceeded
        object.reached_voting_limit?
      end

      def vote_count
        object.vote_count
      end

    end

    require_dependency 'topic'
    class ::Topic

      def can_vote?
        SiteSetting.voting_enabled && Category.can_vote?(category_id) && category.topic_id != id
      end

      def vote_count
        if count = self.custom_fields[DiscourseVoting::VOTE_COUNT]
          # we may have a weird array here, don't explode
          # need to fix core to enforce types on fields
          count.try(:to_i) || 0
        else
          0 if self.can_vote?
        end
      end

      def user_voted(user)
        if user && user.custom_fields[DiscourseVoting::VOTES]
          user.custom_fields[DiscourseVoting::VOTES].include? self.id
        else
          false
        end
      end

      def update_vote_count
        count =
          UserCustomField.where("value = :value AND name IN (:keys)",
                                value: id.to_s, keys: [DiscourseVoting::VOTES, DiscourseVoting::VOTES_ARCHIVE]).count

        custom_fields[DiscourseVoting::VOTE_COUNT] = count
        save_custom_fields
      end

      def who_voted
        return nil unless SiteSetting.voting_show_who_voted

        User.where("id in (
        SELECT user_id FROM user_custom_fields WHERE name IN (:keys) AND value = :value
      )", value: id.to_s, keys: [DiscourseVoting::VOTES, DiscourseVoting::VOTES_ARCHIVE])
      end

    end

    require_dependency 'list_controller'
    class ::ListController
      def voted_by
        unless SiteSetting.voting_show_votes_on_profile
          render nothing: true, status: 404
        end
        list_opts = build_topic_list_options
        target_user = fetch_user_from_params(include_inactive: current_user.try(:staff?))
        list = generate_list_for("voted_by", target_user, list_opts)
        list.more_topics_url = url_for(construct_url_with(:next, list_opts))
        list.prev_topics_url = url_for(construct_url_with(:prev, list_opts))
        respond_with_list(list)
      end
    end

    require_dependency 'topic_query'
    class ::TopicQuery
      SORTABLE_MAPPING["votes"] = "custom_fields.#{::DiscourseVoting::VOTE_COUNT}"

      def list_voted_by(user)
        create_list(:user_topics) do |topics|
          topics.where(id: user.custom_fields[DiscourseVoting::VOTES])
        end
      end

      def list_votes
        create_list(:votes, unordered: true) do |topics|
          topics.joins("left join topic_custom_fields tfv ON tfv.topic_id = topics.id AND tfv.name = '#{DiscourseVoting::VOTE_COUNT}'")
            .order("coalesce(tfv.value,'0')::integer desc, topics.bumped_at desc")
        end
      end
    end

    require_dependency "jobs/base"
    module ::Jobs

      class VoteRelease < ::Jobs::Base
        def execute(args)
          if topic = Topic.with_deleted.find_by(id: args[:topic_id])
            UserCustomField.where(name: DiscourseVoting::VOTES, value: args[:topic_id]).find_each do |user_field|
              user = User.find(user_field.user_id)
              user.custom_fields[DiscourseVoting::VOTES] = user.votes.dup - [args[:topic_id]]
              user.custom_fields[DiscourseVoting::VOTES_ARCHIVE] = user.votes_archive.dup.push(args[:topic_id]).uniq
              user.save!
            end
            topic.update_vote_count
          end
        end
      end

      class VoteReclaim < ::Jobs::Base
        def execute(args)
          if topic = Topic.with_deleted.find_by(id: args[:topic_id])
            UserCustomField.where(name: DiscourseVoting::VOTES_ARCHIVE, value: topic.id).find_each do |user_field|
              user = User.find(user_field.user_id)
              user.custom_fields[DiscourseVoting::VOTES] = user.votes.dup.push(topic.id).uniq
              user.custom_fields[DiscourseVoting::VOTES_ARCHIVE] = user.votes_archive.dup - [topic.id]
              user.save!
            end
            topic.update_vote_count
          end
        end
      end

    end
  end

  DiscourseEvent.on(:topic_status_updated) do |topic, status, enabled|
    if (status == 'closed' || status == 'autoclosed' || status == 'archived') && enabled == true
      Jobs.enqueue(:vote_release, topic_id: topic.id)
    end

    if (status == 'closed' || status == 'autoclosed' || status == 'archived') && enabled == false
      Jobs.enqueue(:vote_reclaim, topic_id: topic.id)
    end
  end

  DiscourseEvent.on(:topic_trashed) do |topic|
    Jobs.enqueue(:vote_release, topic_id: topic.id) if !topic.closed && !topic.archived
  end

  DiscourseEvent.on(:topic_recovered) do |topic|
    Jobs.enqueue(:vote_reclaim, topic_id: topic.id) if !topic.closed && !topic.archived
  end

  DiscourseEvent.on(:post_edited) do |post, topic_changed|
    if topic_changed &&
        SiteSetting.voting_enabled &&
        UserCustomField.where(
          "value = :value AND name in (:keys)",
          value: post.topic_id.to_s,
          keys: [DiscourseVoting::VOTES, DiscourseVoting::VOTES_ARCHIVE]
        ).exists?
      new_category_id = post.reload.topic.category_id
      if Category.can_vote?(new_category_id)
        Jobs.enqueue(:vote_reclaim, topic_id: post.topic_id)
      else
        Jobs.enqueue(:vote_release, topic_id: post.topic_id)
      end
    end
  end

  DiscourseEvent.on(:topic_merged) do |orig, dest|
    moved_votes = 0
    duplicated_votes = 0

    if orig.who_voted.present? && orig.closed
      orig.who_voted.each do |user|
        if user.votes.include?(orig.id)
          if user.votes.include?(dest.id)
            duplicated_votes += 1
            user.custom_fields[DiscourseVoting::VOTES] = user.votes.dup - [orig.id]
          else
            user.custom_fields[DiscourseVoting::VOTES] = user.votes.map { |vote| vote == orig.id ? dest.id : vote }
            moved_votes += 1
          end
        elsif user.votes_archive.include?(orig.id)
          if user.votes_archive.include?(dest.id)
            duplicated_votes += 1
            user.custom_fields[DiscourseVoting::VOTES_ARCHIVE] = user.votes_archive.dup - [orig.id]
          else
            user.custom_fields[DiscourseVoting::VOTES_ARCHIVE] = user.votes_archive.map { |vote| vote == orig.id ? dest.id : vote }
            moved_votes += 1
          end
        else
          next
        end

        user.save_custom_fields
      end
    end

    if moved_votes > 0
      orig.update_vote_count
      dest.update_vote_count

      if moderator_post = orig.ordered_posts.where(action_code: 'split_topic').last
        moderator_post.raw << "\n\n#{I18n.t('voting.votes_moved', count: moved_votes)}"
        moderator_post.raw << " #{I18n.t('voting.duplicated_votes', count: duplicated_votes)}" if duplicated_votes > 0
        moderator_post.save!
      end
    end
  end

  require File.expand_path(File.dirname(__FILE__) + '/app/controllers/discourse_voting/votes_controller')

  DiscourseVoting::Engine.routes.draw do
    post 'vote' => 'votes#vote'
    post 'unvote' => 'votes#unvote'
    get 'who' => 'votes#who'
  end

  Discourse::Application.routes.append do
    mount ::DiscourseVoting::Engine, at: "/voting"
    # USERNAME_ROUTE_FORMAT is deprecated but we may need to support it for older installs
    username_route_format = defined?(RouteFormat) ? RouteFormat.username : USERNAME_ROUTE_FORMAT
    get "topics/voted-by/:username" => "list#voted_by", as: "voted_by", constraints: { username: username_route_format }
  end

  TopicList.preloaded_custom_fields << DiscourseVoting::VOTE_COUNT if TopicList.respond_to? :preloaded_custom_fields
end
