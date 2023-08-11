# frozen_string_literal: true

module DiscourseTopicVoting
  module WebHookExtension
    def self.prepended(base)
      base.class_eval do
        def self.enqueue_topic_voting_hooks(event, topic, payload)
          if active_web_hooks("topic_voting").exists?
            WebHook.enqueue_hooks(
              :topic_voting,
              event,
              category_id: topic.category_id,
              tag_ids: topic.tags.pluck(:id),
              payload: payload,
            )
          end
        end
      end
    end
  end
end
