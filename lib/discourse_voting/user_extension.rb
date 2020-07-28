# frozen_string_literal: true

module DiscourseVoting
  module UserExtension
    def self.prepended(base)
      base.has_many :topic_votes, class_name: 'DiscourseVoting::Vote'
    end
  end
end
