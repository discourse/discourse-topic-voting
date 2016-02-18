module DiscourseFeatureVoting
	class VotesController < ::ApplicationController
		requires_plugin 'discourse-feature-voting'

		def add
			topic = Topic.find_by(id: params["topic_id"])
			user = User.find_by(id: params["user_id"])
			if topic.custom_fields["vote_count"]
				current = topic.custom_fields["vote_count"].to_i
				updated = current + 1
				topic.custom_fields["vote_count"] = updated
			else 
				topic.custom_fields["vote_count"] = 1
			end
			topic.save

			render json: topic.custom_fields["vote_count"]
		end

		def subtract
			topic = Topic.find_by(id: params["topic_id"])
			user = User.find_by(id: params["user_id"])
			if topic.custom_fields["vote_count"].to_i > 0
				current = topic.custom_fields["vote_count"].to_i
				updated = current - 1
				topic.custom_fields["vote_count"] = updated
			end
			topic.save

			render json: topic.custom_fields["vote_count"]
		end
	end
end