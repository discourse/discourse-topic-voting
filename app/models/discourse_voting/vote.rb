# frozen_string_literal: true

module DiscourseVoting
  class Vote < ActiveRecord::Base
    self.table_name = 'discourse_voting_votes'

    belongs_to :user
    belongs_to :topic
  end
end
