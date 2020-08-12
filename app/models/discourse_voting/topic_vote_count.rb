# frozen_string_literal: true

module DiscourseVoting
  class TopicVoteCount < ActiveRecord::Base
    self.table_name = 'discourse_voting_topic_vote_count'

    belongs_to :topic
  end
end
