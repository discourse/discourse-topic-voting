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

      raise Discourse::InvalidAccess if !topic.can_vote? || topic.user_voted(current_user)
      guardian.ensure_can_see!(topic)

      voted = false

      unless current_user.reached_voting_limit?

        current_user.custom_fields[DiscourseVoting::VOTES] = current_user.votes.dup.push(params["topic_id"]).uniq
        current_user.save!

        topic.update_vote_count

        voted = true
      end

      obj = {
        can_vote: !current_user.reached_voting_limit?,
        vote_limit: current_user.vote_limit,
        vote_count: topic.custom_fields[DiscourseVoting::VOTE_COUNT].to_i,
        who_voted: who_voted(topic),
        alert:  current_user.alert_low_votes?,
        votes_left: [(current_user.vote_limit - current_user.vote_count), 0].max
      }

      render json: obj, status: voted ? 200 : 403
    end

    def remove
      topic = Topic.find_by(id: params["topic_id"])

      guardian.ensure_can_see!(topic)

      current_user.custom_fields[DiscourseVoting::VOTES] = current_user.votes.dup - [params["topic_id"].to_s]
      current_user.save!

      topic.update_vote_count

      obj = {
        can_vote: !current_user.reached_voting_limit?,
        vote_limit: current_user.vote_limit,
        vote_count: topic.custom_fields[DiscourseVoting::VOTE_COUNT].to_i,
        who_voted: who_voted(topic),
        votes_left: [(current_user.vote_limit - current_user.vote_count), 0].max
      }

      render json: obj
    end

    protected

    def who_voted(topic)
      return nil unless SiteSetting.voting_show_who_voted

      ActiveModel::ArraySerializer.new(topic.who_voted, scope: guardian, each_serializer: BasicUserSerializer)
    end

  end
end
