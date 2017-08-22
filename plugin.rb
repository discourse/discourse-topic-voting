# name: discourse-voting
# about: Adds the ability to vote on features in a specified category.
# version: 0.4
# author: Joe Buhlig joebuhlig.com, Sam Saffron
# url: https://www.github.com/joebuhlig/discourse-feature-voting

register_asset "stylesheets/common/feature-voting.scss"
register_asset "stylesheets/desktop/feature-voting.scss", :desktop
register_asset "stylesheets/mobile/feature-voting.scss", :mobile

enabled_site_setting :voting_enabled

Discourse.top_menu_items.push(:votes)
Discourse.anonymous_top_menu_items.push(:votes)
Discourse.filters.push(:votes)
Discourse.anonymous_filters.push(:votes)

after_initialize do

  require_dependency 'basic_category_serializer'
  class ::BasicCategorySerializer
    attributes :can_vote, :has_vote_limit, :votes_exceeded

    def include_can_vote?
      Category.can_vote?(object.id)
    end

    def include_votes_exceeded?
      has_vote_limit
    end

    def has_vote_limit
      scope && scope.user && !!scope.user.category_vote_limit(object.id)
    end

    def votes_exceeded
      scope.user.reached_category_voting_limit?(object.id)
    end

    def can_vote
      true
    end

  end

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
        return false unless SiteSetting.voting_enabled

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
      def vote_count(category_id = nil)
        user_votes = category_id ? category_votes(category_id) : votes

        if user_votes
          user_votes.length
        else
          0
        end
      end

      def alert_low_votes?
        (vote_limit - vote_count) <= SiteSetting.voting_alert_votes_left
      end

      def votes
        [*self.custom_fields["votes"]]
      end

      def category_votes(category_id)
        [*self.custom_fields["#{category_id}_votes"]]
      end

      def votes_archive
        [*self.custom_fields["votes_archive"]]
      end

      def reached_voting_limit?
        vote_count >= vote_limit
      end

      def vote_limit(category_id = nil)
        self.category_vote_limit(category_id) || SiteSetting.send("voting_tl#{self.trust_level}_vote_limit")
      end

      def category_vote_limit(category_id = nil)
        return nil if !category_id

        limit = CategoryCustomField.where(name: "tl#{self.trust_level}_vote_limit", category_id: category_id)
                                   .pluck(:value)[0]

        limit.present? ? limit.to_i : nil
      end

      def has_category_limit?(category_id)
        !!category_vote_limit(category_id)
      end

      def reached_category_voting_limit?(category_id)
        vote_count(category_id) >= category_vote_limit(category_id)
      end

      def add_vote(topic)
        self.custom_fields["votes"] = votes.dup.push(topic.id)
        self.custom_fields["#{topic.category.id}_votes"] = category_votes(topic.category.id).dup.push(topic.id)
      end

      def remove_vote(topic)
        self.custom_fields["votes"] = votes.dup - [topic.id.to_s]
        self.custom_fields["#{topic.category.id}_votes"] = category_votes(topic.category.id).dup - [topic.id.to_s]
      end

      def remove_archived_vote(topic)
        self.custom_fields["votes_archive"] = votes_archive.dup.push(topic.id)
      end

      def add_archived_vote(topic)
        self.custom_fields["votes_archive"] = votes_archive.dup - [topic.id.to_s]
      end
      
  end

  require_dependency 'current_user_serializer'
  class ::CurrentUserSerializer
    attributes :votes_exceeded, :vote_count

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
    SORTABLE_MAPPING["votes"] = "custom_fields.vote_count"

    def list_voted_by(user)
      create_list(:user_topics) do |topics|
        topics.where(id: user.custom_fields["votes"])
      end
    end

    def list_votes
      create_list(:votes, unordered: true) do |topics|
        topics.joins("left join topic_custom_fields tfv ON tfv.topic_id = topics.id AND tfv.name = 'vote_count'")
              .order("coalesce(tfv.value,'0')::integer desc, topics.bumped_at desc")
      end
    end
  end

  require_dependency "jobs/base"
  module ::Jobs

    class VoteRelease < Jobs::Base
      def execute(args)
        topic = Topic.find_by(id: args[:topic_id])

        if topic
          UserCustomField.where(name: "votes", value: topic.id).find_each do |user_field|
            user = User.find(user_field.user_id)
            user.remove_vote(topic)
            user.remove_archived_vote(topic)
            user.save
          end
        end
      end
    end

    class VoteReclaim < Jobs::Base
      def execute(args)
        topic = Topic.find_by(id: args[:topic_id])

        if topic
          UserCustomField.where(name: "votes_archive", value: topic.id).find_each do |user_field|
            user = User.find(user_field.user_id)
            user.add_vote(topic)
            user.add_archived_vote(topic)
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

  module ::DiscourseVoting
    class Engine < ::Rails::Engine
      isolate_namespace DiscourseVoting
    end
  end

  require File.expand_path(File.dirname(__FILE__) + '/app/controllers/discourse_voting/votes_controller')

  DiscourseVoting::Engine.routes.draw do
    post 'vote' => 'votes#add'
    post 'unvote' => 'votes#remove'
    get 'who' => 'votes#who'
  end

  Discourse::Application.routes.append do
    mount ::DiscourseVoting::Engine, at: "/voting"
    get "topics/voted-by/:username" => "list#voted_by", as: "voted_by", constraints: {username: USERNAME_ROUTE_FORMAT}
  end

  TopicList.preloaded_custom_fields << "vote_count" if TopicList.respond_to? :preloaded_custom_fields
end
