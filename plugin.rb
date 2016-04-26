# name: discourse-feature-voting
# about: Adds the ability to vote on features in a specified category.
# version: 0.2
# author: Joe Buhlig joebuhlig.com
# url: https://www.github.com/joebuhlig/discourse-feature-voting

register_asset "stylesheets/feature-voting.scss"
register_asset "javascripts/feature-voting.js"

enabled_site_setting :feature_voting_enabled

# load the engine
load File.expand_path('../lib/discourse_feature_voting/engine.rb', __FILE__)

after_initialize do

  require_dependency 'topic_view_serializer'
  class ::TopicViewSerializer
    attributes :can_vote, :single_vote, :vote_count, :has_votes, :super_vote_count, :has_super_votes, :user_voted, :user_super_voted, :who_voted, :who_super_voted

    def can_vote
      object.topic.can_vote
    end

    def single_vote
      object.topic.vote_count.to_i == 1
    end

    def single_super_vote
      object.topic.super_vote_count.to_i == 1
    end

    def vote_count
      object.topic.vote_count
    end

    def has_votes
      object.topic.vote_count.to_i > 0
    end

    def super_vote_count
      object.topic.super_vote_count
    end

    def has_super_votes
      object.topic.super_vote_count.to_i > 0
    end

    def user_voted
      object.topic.user_voted(scope.user.id)
    end

    def user_super_voted
      object.topic.user_super_voted(scope.user.id)
    end

    def who_voted
      users = []
      User.where(id: object.topic.who_voted).each do |user|
        users.push(UserSerializer.new(user, scope: scope, root: 'user'))
      end
      return users
    end

    def who_super_voted
      users = []
      User.where(id: object.topic.who_super_voted).each do |user|
        users.push(UserSerializer.new(user, scope: scope, root: 'user'))
      end
      return users
    end
  end

  add_to_serializer(:topic_list_item, :vote_count) { object.vote_count }
  add_to_serializer(:topic_list_item, :can_vote) { object.can_vote }
  add_to_serializer(:topic_list_item, :user_voted) { object.user_voted(scope.user.id) }
  add_to_serializer(:topic_list_item, :user_super_voted) { object.user_super_voted(scope.user.id) }

  class ::Category
      after_save :reset_voting_cache

      protected
      def reset_voting_cache
        ::Guardian.reset_voting_cache
      end
  end

  class ::Guardian

    @@allowed_voting_cache = DistributedCache.new("allowed_voting")

    def self.reset_voting_cache
      @@allowed_voting_cache["allowed"] =
        begin
          Set.new(
            CategoryCustomField
              .where(name: "enable_topic_voting", value: "true")
              .pluck(:category_id)
          )
        end
    end
  end


  require_dependency 'user'
  class ::User
      def vote_count
        if self.custom_fields["votes"]
          user_votes = self.custom_fields["votes"]
          return user_votes.length - 1
        else 
          return 0
        end
      end

      def super_vote_count
        if self.custom_fields["super_votes"]
          user_super_votes = self.custom_fields["super_votes"]
          return user_super_votes.length - 1
        else 
          return 0
        end
      end

      def votes
        if self.custom_fields["votes"]
          return self.custom_fields["votes"]
        else
          return [nil]
        end
      end

      def super_votes
        if self.custom_fields["super_votes"]
          return self.custom_fields["super_votes"]
        else
          return [nil]
        end
      end

      def votes_archive
        if self.custom_fields["votes_archive"]
          return self.custom_fields["votes_archive"]
        else
          return [nil]
        end
      end

      def super_votes_archive
        if self.custom_fields["super_votes_archive"]
          return self.custom_fields["super_votes_archive"]
        else
          return [nil]
        end
      end

      def vote_limit
        self.vote_count >= SiteSetting.feature_voting_vote_limit
      end

      def super_vote_limit
        self.super_vote_count >= SiteSetting.feature_voting_super_vote_limit
      end
  end

  require_dependency 'current_user_serializer'
  class ::CurrentUserSerializer
    attributes :vote_limit, :super_vote_limit, :vote_count, :super_vote_count

    def vote_limit
      object.vote_limit
    end

    def super_vote_limit
      object.super_vote_limit
    end

    def vote_count
      object.vote_count
    end

    def super_vote_count
      object.super_vote_count
    end

   end

  require_dependency 'topic'
  class ::Topic

    def can_vote
      self.category.respond_to?(:custom_fields) and SiteSetting.feature_voting_enabled and self.category.custom_fields["enable_topic_voting"].eql?("true")
    end

    def vote_count
      if self.custom_fields["vote_count"]
        return self.custom_fields["vote_count"]
      else
        if self.can_vote
          Set.new(
            TopicCustomField
              .where(name: "vote_count", value: 0)
              .pluck(:topic_id)
          )
        end
        return 0
      end
    end

    def super_vote_count
      UserCustomField.where(name: "super_votes", value: self.id).count
    end

    def who_voted
      UserCustomField.where(name: "votes", value: self.id).pluck(:user_id)
    end

    def who_super_voted
      UserCustomField.where(name: "super_votes", value: self.id).pluck(:user_id)
    end

    def user_voted(user_id)
      user = User.find(user_id)
      if user && user.custom_fields["votes"]
          user_votes = user.custom_fields["votes"]
          return user_votes.include? self.id.to_s
      else
        return false
      end
    end

    def user_super_voted(user_id)
      user = User.find(user_id)
      if user && user.custom_fields["super_votes"]
          user_super_votes = user.custom_fields["super_votes"]
          return user_super_votes.include? self.id.to_s
      else
        return false
      end
    end
  end

  require_dependency 'list_controller'
  class ::ListController
    def voted_by
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
  end

  require_dependency "jobs/base"
  module ::Jobs
    
    class VoteRelease < Jobs::Base
      def execute(args)
        if topic = Topic.find_by(id: args[:topic_id])
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
        if topic = Topic.find_by(id: args[:topic_id])
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

  Discourse::Application.routes.append do
    mount ::DiscourseFeatureVoting::Engine, at: "/voting"
    get "topics/voted-by/:username" => "list#voted_by", as: "voted_by", constraints: {username: USERNAME_ROUTE_FORMAT}
  end

  TopicList.preloaded_custom_fields << "vote_count" if TopicList.respond_to? :preloaded_custom_fields
end