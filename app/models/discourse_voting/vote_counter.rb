# frozen_string_literal: true

module DiscourseVoting
  class VoteCounter < ActiveRecord::Base
    self.table_name = 'discourse_voting_vote_counters'

    belongs_to :topic
  end
end
