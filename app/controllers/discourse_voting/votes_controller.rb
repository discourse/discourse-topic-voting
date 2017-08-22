module DiscourseVoting
  class VotesController < ::ApplicationController
    before_filter :ensure_logged_in

    def who
      params.require(:topic_id)
      topic = Topic.find(params[:topic_id].to_i)
      guardian.ensure_can_see!(topic)

      render json: MultiJson.dump(who_voted(topic))
    end

    def add
      topic = Topic.find_by(id: params["topic_id"])

      raise Discourse::InvalidAccess if !topic.can_vote?
      guardian.ensure_can_see!(topic)

      user = current_user
      voted = false
      has_category_limit = user.has_category_limit?(topic.category_id)

      reached_applicable_limit = has_category_limit ?
                                  user.reached_category_voting_limit?(topic.category_id) :
                                  user.reached_voting_limit?

      unless reached_applicable_limit
        user.add_vote(topic)
        user.save

        update_topic_vote_count(topic)

        voted = true
      end

      vote_limit = user.vote_limit(topic.category_id)
      user_vote_count = user.vote_count(topic.category_id)

      obj = {
        user_votes_exceeded: user.reached_voting_limit?,
        user_voted: true,
        vote_limit: vote_limit,
        vote_count: topic.custom_fields["vote_count"].to_i,
        who_voted: who_voted(topic),
        alert: user.alert_low_votes?,
        votes_left: [(vote_limit - user_vote_count), 0].max
      }

      if has_category_limit
        obj[:category_votes_exceeded] = user.reached_category_voting_limit?(topic.category_id)
      end

      render json: obj, status: voted ? 200 : 403
    end

    def remove
      topic = Topic.find_by(id: params["topic_id"])

      guardian.ensure_can_see!(topic)

      user = current_user
      user.remove_vote(topic)
      user.save

      update_topic_vote_count(topic)

      vote_limit = user.vote_limit(topic.category_id)
      obj = {
        user_votes_exceeded: user.reached_voting_limit?,
        user_voted: false,
        vote_limit: vote_limit,
        vote_count: topic.custom_fields["vote_count"].to_i,
        who_voted: who_voted(topic),
        votes_left: [(vote_limit - user.vote_count(topic.category_id)), 0].max
      }

      if user.has_category_limit?(topic.category_id)
        obj[:category_votes_exceeded] = user.reached_category_voting_limit?(topic.category_id)
      end

      render json: obj
    end

    protected

    def update_topic_vote_count(topic)
      topic.custom_fields["vote_count"] = UserCustomField.where(value: topic.id.to_s, name: 'votes').count
      topic.save
    end

    def who_voted(topic)
      return nil unless SiteSetting.voting_show_who_voted

      users = User.where("id in (
        SELECT user_id FROM user_custom_fields WHERE name = 'votes' AND value = ?
      )", params[:topic_id].to_i.to_s)

      ActiveModel::ArraySerializer.new(users, scope: guardian, each_serializer: BasicUserSerializer)
    end

  end
end
