# frozen_string_literal: true

Fabricator(:topic_voting_web_hook, from: :web_hook) do
  transient topic_voting_hook: WebHookEventType.find_by(name: "topic_upvote")

  after_build do |web_hook, transients|
    web_hook.web_hook_event_types = [transients[:topic_voting_hook]]
  end
end
