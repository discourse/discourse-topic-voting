# name: discourse-feature-voting
# about: Adds the ability to vote on features in a specified category.
# version: 0.1
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
    attributes :can_vote, :single_vote, :vote_count, :user_voted

    def can_vote
      return object.topic.category.custom_fields["enable_topic_voting"]
    end

    def single_vote
      if object.topic.vote_count.to_i == 1
        return true
      else
        return false
      end
    end

    def vote_count
      object.topic.vote_count
    end

    def user_voted
      user = scope.user
      if user && user.custom_fields["votes"]
          user_votes = user.custom_fields["votes"]
          return user_votes.include? object.topic.id.to_s
      else
        return false
      end
    end
  end

  add_to_serializer(:topic_list_item, :vote_count) { object.vote_count }
  add_to_serializer(:topic_list_item, :can_vote) { object.can_vote }

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

      def votes
        if self.custom_fields["votes"]
          return self.custom_fields["votes"]
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

      def vote_limit
        if self.vote_count >= SiteSetting.feature_voting_vote_limit
          return true
        else
          return false
        end
      end
  end

  require_dependency 'current_user_serializer'
  class ::CurrentUserSerializer
    attributes :vote_limit

    def vote_limit
      object.vote_limit
    end

   end

  require_dependency 'topic'
  class ::Topic

    def can_vote
      return self.category.custom_fields["enable_topic_voting"]
    end

    def vote_count
      if self.custom_fields["vote_count"]
        return self.custom_fields["vote_count"]
      else
        if self.category.custom_fields["enable_topic_voting"]
          Set.new(
            TopicCustomField
              .where(name: "vote_count", value: 0)
              .pluck(:topic_id)
          )
        end
        return 0
      end
    end

  end

  require_dependency 'topic_query'
  class ::TopicQuery
    SORTABLE_MAPPING["votes"] = "custom_fields.vote_count"
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
  end
end