# frozen_string_literal: true

module DiscourseTopicVoting
  module ListControllerExtension
    def self.prepended(base)
      base.class_eval do
        before_action :ensure_discourse_topic_voting, only: %i[voted_by]
        skip_before_action :ensure_logged_in, only: %i[voted_by]
      end
    end

    def voted_by
      list_opts = build_topic_list_options
      target_user = fetch_user_from_params(include_inactive: current_user.try(:staff?))
      list = generate_list_for("voted_by", target_user, list_opts)
      list.more_topics_url = url_for(construct_url_with(:next, list_opts))
      list.prev_topics_url = url_for(construct_url_with(:prev, list_opts))
      respond_with_list(list)
    end

    protected

    def ensure_discourse_topic_voting
      if !SiteSetting.voting_enabled || !SiteSetting.voting_show_votes_on_profile
        raise Discourse::NotFound
      end
    end
  end
end
