module DiscourseFeatureVoting
	class VotesController < ::ApplicationController
		requires_plugin 'discourse-feature-voting'

		def add
			user = User.find_by(id: params["user_id"])

			topic = Topic.find_by(id: params["topic_id"])

			topic.custom_fields["vote_count"] = topic.custom_fields["vote_count"].to_i + 1
			topic.save

			user.custom_fields["votes"] = user.votes.dup.push(params["topic_id"])
			user.save

			obj = {vote_limit: user.vote_limit, vote_count: topic.custom_fields["vote_count"].to_i}

			render json: obj
		end

		def subtract
			topic = Topic.find_by(id: params["topic_id"])
			user = User.find_by(id: params["user_id"])

			if topic.custom_fields["vote_count"].to_i > 0
				topic.custom_fields["vote_count"] = topic.custom_fields["vote_count"].to_i - 1
			end
			topic.save

			user.custom_fields["votes"] = user.votes.dup - [params["topic_id"].to_s]
			user.save

			obj = {vote_limit: user.vote_limit, vote_count: topic.custom_fields["vote_count"].to_i}

			render json: obj
		end
	end
end