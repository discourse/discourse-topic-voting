# frozen_string_literal: true

class CreateDiscourseVotingVoteCounters < ActiveRecord::Migration[6.0]
  def up
    create_table :discourse_voting_vote_counters do |t|
      t.integer :topic_id
      t.integer :counter
      t.timestamps
    end
    add_index :discourse_voting_vote_counters, :topic_id, unique: true

    DB.exec <<~SQL
      INSERT INTO discourse_voting_vote_counters(topic_id, counter, created_at, updated_at)
      SELECT topic_id::integer, value::integer, created_at, updated_at
      FROM topic_custom_fields
      WHERE name = 'vote_count'
    SQL

    DB.exec <<~SQL
      DELETE FROM topic_custom_fields
      WHERE name = 'vote_count'
    SQL
  end

  def down
  raise ActiveRecord::IrreversibleMigration
  end
end
