# frozen_string_literal: true

class RenameTopicVotingSiteSettings < ActiveRecord::Migration[7.0]
  def up
    execute "UPDATE site_settings SET name = 'topic_voting_alert_votes_left' WHERE name = 'voting_alert_votes_left_flags_after'"
    execute "UPDATE site_settings SET name = 'topic_voting_enabled' WHERE name = 'voting_enabled_flags_after'"
    execute "UPDATE site_settings SET name = 'topic_voting_show_who_voted' WHERE name = 'voting_show_who_voted_flags_after'"
    execute "UPDATE site_settings SET name = 'topic_voting_show_votes_on_profile' WHERE name = 'voting_show_votes_on_profile_flags_after'"
    execute "UPDATE site_settings SET name = 'topic_voting_tl0_vote_limit' WHERE name = 'voting_tl0_vote_limit_flags_after'"
    execute "UPDATE site_settings SET name = 'topic_voting_tl1_vote_limit' WHERE name = 'voting_tl1_vote_limit_flags_after'"
    execute "UPDATE site_settings SET name = 'topic_voting_tl2_vote_limit' WHERE name = 'voting_tl2_vote_limit_flags_after'"
    execute "UPDATE site_settings SET name = 'topic_voting_tl3_vote_limit' WHERE name = 'voting_tl3_vote_limit_flags_after'"
    execute "UPDATE site_settings SET name = 'topic_voting_tl4_vote_limit' WHERE name = 'voting_tl4_vote_limit_flags_after'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
