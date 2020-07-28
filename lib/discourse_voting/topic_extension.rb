# frozen_string_literal: true

module DiscourseVoting
  module TopicExtension
    def self.prepended(base)
      base.has_one :vote_counter, class_name: 'DiscourseVoting::VoteCounter'
      base.has_many :votes, class_name: 'DiscourseVoting::Vote'
      base.attribute :current_user_voted
    end
  end
end
