# frozen_string_literal: true

module DiscourseVoting
  class CategorySetting < ActiveRecord::Base
    self.table_name = 'discourse_voting_category_settings'

    belongs_to :category

    before_create :unarchive_votes
    before_destroy :archive_votes
    after_save :reset_voting_cache

    def unarchive_votes
      DB.exec(<<~SQL, { category_id: self.category_id })
        UPDATE discourse_voting_votes
        SET archive=false
        FROM topics
        WHERE topics.category_id = :category_id
        AND topics.deleted_at is NULL
        AND NOT topics.closed
        AND NOT topics.archived
        AND discourse_voting_votes.topic_id = topics.id
      SQL
    end

    def archive_votes
      DB.exec(<<~SQL, { category_id: self.category_id })
        UPDATE discourse_voting_votes
        SET archive=true
        FROM topics
        WHERE topics.category_id = :category_id
        AND discourse_voting_votes.topic_id = topics.id
      SQL
    end

    def reset_voting_cache
      ::Category.reset_voting_cache
    end
  end
end
