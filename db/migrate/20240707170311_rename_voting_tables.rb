# frozen_string_literal: true

require "migration/table_dropper"

class RenameVotingTables < ActiveRecord::Migration[7.0]
  def up
    unless table_exists?(:topic_voting_topic_vote_count)
      Migration::TableDropper.read_only_table(:discourse_voting_topic_vote_count)
      execute <<~SQL
        CREATE TABLE topic_voting_topic_vote_count
        (LIKE discourse_voting_topic_vote_count INCLUDING ALL);
      SQL

      execute <<~SQL
        INSERT INTO topic_voting_topic_vote_count
        SELECT *
        FROM discourse_voting_topic_vote_count
      SQL

      execute <<~SQL
        ALTER SEQUENCE discourse_voting_topic_vote_count_id_seq
        RENAME TO topic_voting_topic_vote_count_id_seq
      SQL

      execute <<~SQL
        ALTER SEQUENCE topic_voting_topic_vote_count_id_seq
        OWNED BY topic_voting_topic_vote_count.id
      SQL

      add_index :topic_voting_topic_vote_count, :topic_id, unique: true
    end

    unless table_exists?(:topic_voting_votes)
      Migration::TableDropper.read_only_table(:discourse_voting_votes)
      execute <<~SQL
        CREATE TABLE topic_voting_votes
        (LIKE discourse_voting_votes INCLUDING ALL);
      SQL

      execute <<~SQL
        INSERT INTO topic_voting_votes
        SELECT *
        FROM discourse_voting_votes
      SQL

      execute <<~SQL
        ALTER SEQUENCE discourse_voting_votes_id_seq
        RENAME TO topic_voting_votes_id_seq
      SQL

      execute <<~SQL
        ALTER SEQUENCE topic_voting_votes_id_seq
        OWNED BY topic_voting_votes.id
      SQL

      add_index :topic_voting_votes, %i[user_id topic_id], unique: true
    end

    unless table_exists?(:topic_voting_category_settings)
      Migration::TableDropper.read_only_table(:discourse_voting_category_settings)
      execute <<~SQL
        CREATE TABLE topic_voting_category_settings
        (LIKE discourse_voting_category_settings INCLUDING ALL);
      SQL

      execute <<~SQL
        INSERT INTO topic_voting_category_settings
        SELECT *
        FROM discourse_voting_category_settings
      SQL

      execute <<~SQL
        ALTER SEQUENCE discourse_voting_category_settings_id_seq
        RENAME TO topic_voting_category_settings_id_seq
      SQL

      execute <<~SQL
        ALTER SEQUENCE topic_voting_category_settings_id_seq
        OWNED BY topic_voting_category_settings.id
      SQL

      add_index :topic_voting_category_settings, :category_id, unique: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
