# name: discourse-feature-voting
# about: Adds the ability to vote on features in a specified category.
# version: 0.3
# author: Joe Buhlig joebuhlig.com, Sam Saffron
# url: https://www.github.com/joebuhlig/discourse-feature-voting

register_asset "stylesheets/feature-voting.scss"

enabled_site_setting :feature_voting_enabled

Discourse.top_menu_items.push(:votes)
Discourse.anonymous_top_menu_items.push(:votes)
Discourse.filters.push(:votes)
Discourse.anonymous_filters.push(:votes)

after_initialize do

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

  class ::Category
      def self.reset_voting_cache
        @allowed_voting_cache["allowed"] =
          begin
            Set.new(
              CategoryCustomField
                .where(name: "enable_topic_voting", value: "true")
                .pluck(:category_id)
            )
          end
      end

      @allowed_voting_cache = DistributedCache.new("allowed_voting")

      def self.can_vote?(category_id)
        unless set = @allowed_voting_cache["allowed"]
          set = reset_voting_cache
        end
        set.include?(category_id)
      end


      after_save :reset_voting_cache


      protected
      def reset_voting_cache
        ::Category.reset_voting_cache
      end
  end

  require_dependency 'user'
  class ::User
      def vote_count
        if self.custom_fields["votes"]
          user_votes = self.custom_fields["votes"]
          user_votes.length - 1
        else
          0
        end
      end

      def votes
        if self.custom_fields["votes"]
          self.custom_fields["votes"]
        else
          [nil]
        end
      end

      def votes_archive
        if self.custom_fields["votes_archive"]
          return self.custom_fields["votes_archive"]
        else
          return [nil]
        end
      end

      def reached_voting_limit?
        vote_count >= vote_limit
      end

      def vote_limit
        SiteSetting.send("feature_voting_tl#{self.trust_level}_vote_limit")
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
      SiteSetting.feature_voting_enabled and Category.can_vote?(category_id)
    end

    def vote_count
      if self.custom_fields["vote_count"]
        self.custom_fields["vote_count"].to_i
      else
        0 if self.can_vote?
      end
    end

    def user_voted(user)
      if user && user.custom_fields["votes"]
        user.custom_fields["votes"].include? self.id.to_s
      else
        false
      end
    end

  end

  require_dependency 'list_controller'
  class ::ListController
    def voted_by
      unless SiteSetting.feature_voting_show_votes_on_profile
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
    SORTABLE_MAPPING["votes"] = "custom_fields.vote_count"

    def list_voted_by(user)
      create_list(:user_topics) do |topics|
        topics.where(id: user.custom_fields["votes"])
      end
    end

    def list_votes
      create_list(:votes, {order: "votes"})
    end
  end

  require_dependency "jobs/base"
  module ::Jobs

    class VoteRelease < Jobs::Base
      def execute(args)
        if Topic.find_by(id: args[:topic_id])
          UserCustomField.where(name: "votes", value: args[:topic_id]).find_each do |user_field|
            user = User.find(user_field.user_id)
            user.custom_fields["votes"] = user.votes.dup - [args[:topic_id].to_s]
            user.custom_fields["votes_archive"] = user.votes_archive.dup.push(args[:topic_id])
            user.save
          end
        end
      end
    end

    class VoteReclaim < Jobs::Base
      def execute(args)
        if Topic.find_by(id: args[:topic_id])
          UserCustomField.where(name: "votes_archive", value: args[:topic_id]).find_each do |user_field|
            user = User.find(user_field.user_id)
            user.custom_fields["votes"] = user.votes.dup.push(args[:topic_id])
            user.custom_fields["votes_archive"] = user.votes_archive.dup - [args[:topic_id].to_s]
            user.save
          end
        end
      end
    end

  end

  DiscourseEvent.on(:topic_status_updated) do |topic_id, status, enabled|
    if (status == 'closed' || status == 'autoclosed' || status == 'archived') && enabled == true
      Jobs.enqueue(:vote_release, {topic_id: topic_id})
    end

    if (status == 'closed' || status == 'autoclosed' || status == 'archived') && enabled == false
      Jobs.enqueue(:vote_reclaim, {topic_id: topic_id})
    end
  end

  module ::DiscourseFeatureVoting
    class Engine < ::Rails::Engine
      isolate_namespace DiscourseFeatureVoting
    end
  end

  require File.expand_path(File.dirname(__FILE__) + '/app/controllers/discourse_feature_voting/votes_controller')

  DiscourseFeatureVoting::Engine.routes.draw do
    post 'vote' => 'votes#add'
    post 'unvote' => 'votes#remove'
    get 'who' => 'votes#who'
  end

  Discourse::Application.routes.append do
    mount ::DiscourseFeatureVoting::Engine, at: "/voting"
    get "topics/voted-by/:username" => "list#voted_by", as: "voted_by", constraints: {username: USERNAME_ROUTE_FORMAT}
  end

  TopicList.preloaded_custom_fields << "vote_count" if TopicList.respond_to? :preloaded_custom_fields
end
