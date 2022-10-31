# frozen_string_literal: true

module DiscourseTopicVoting
  module UserExtension
    def self.prepended(base)
      base.has_many :votes, class_name: 'DiscourseVoting::Vote', dependent: :destroy
    end
  end
end
