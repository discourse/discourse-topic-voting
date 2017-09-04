module DiscourseVoting
  class VotesController < ::ApplicationController
    before_action :ensure_logged_in

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

      voted = false

      unless current_user.reached_voting_limit?

        current_user.custom_fields["votes"] = current_user.votes.dup.push(params["topic_id"])
        current_user.save

        update_vote_count(topic)

        voted = true
      end

      obj = {
        can_vote: !current_user.reached_voting_limit?,
        vote_limit: current_user.vote_limit,
        vote_count: topic.custom_fields["vote_count"].to_i,
        who_voted: who_voted(topic),
        alert:  current_user.alert_low_votes?,
        votes_left: [(current_user.vote_limit - current_user.vote_count), 0].max
      }

      render json: obj, status: voted ? 200 : 403
    end

    def remove
      topic = Topic.find_by(id: params["topic_id"])

      guardian.ensure_can_see!(topic)

      current_user.custom_fields["votes"] = current_user.votes.dup - [params["topic_id"].to_s]
      current_user.save

      update_vote_count(topic)

      obj = {
        can_vote: !current_user.reached_voting_limit?,
        vote_limit: current_user.vote_limit,
        vote_count: topic.custom_fields["vote_count"].to_i,
        who_voted: who_voted(topic),
        votes_left: [(current_user.vote_limit - current_user.vote_count), 0].max
      }

      render json: obj
    end

    protected

    def update_vote_count(topic)
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
