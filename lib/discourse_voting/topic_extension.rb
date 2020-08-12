# frozen_string_literal: true

module DiscourseVoting
  module TopicExtension
    def self.prepended(base)
      base.has_one :topic_vote_count, class_name: 'DiscourseVoting::TopicVoteCount'
      base.has_many :votes, class_name: 'DiscourseVoting::Vote'
      base.attribute :current_user_voted
    end
  end
end
