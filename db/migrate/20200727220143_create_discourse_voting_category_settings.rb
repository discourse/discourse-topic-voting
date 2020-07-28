# frozen_string_literal: true

class CreateDiscourseVotingCategorySettings < ActiveRecord::Migration[6.0]
  def up
    create_table :discourse_voting_category_settings do |t|
      t.integer :category_id
      t.timestamps
    end
    add_index :discourse_voting_category_settings, :category_id, unique: true

    DB.exec <<~SQL
      INSERT INTO discourse_voting_category_settings(category_id, created_at, updated_at)
      SELECT category_id, created_at, updated_at
      FROM category_custom_fields
      WHERE name = 'enable_topic_voting' and value = 'true'
    SQL

    DB.exec <<~SQL
      DELETE FROM category_custom_fields
      WHERE name = 'enable_topic_voting'
    SQL
  end

  def down
    DB.exec <<~SQL
      INSERT INTO category_custom_fields(category_id, created_at, updated_at, name, value)
      SELECT category_id, created_at, updated_at, 'enable_topic_voting', 'true'
      FROM discourse_voting_category_settings
    SQL
    drop_table :discourse_voting_category_settings
  end
end
