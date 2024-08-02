# frozen_string_literal: true

class EnsureConsistency < ActiveRecord::Migration[7.0]
  def up
    # un-archive votes to open topics
    DB.exec(<<~SQL)
      UPDATE topic_voting_votes
      SET archive=false
      FROM topics
      WHERE topics.id = topic_voting_votes.topic_id
      AND topic_voting_votes.archive IS TRUE
      AND NOT topics.closed
      AND NOT topics.archived
      AND topics.deleted_at IS NULL
    SQL

    # delete duplicate votes
    DB.exec(<<~SQL)
      DELETE FROM topic_voting_votes dvv1
      USING topic_voting_votes dvv2
      WHERE dvv1.id < dvv2.id AND
            dvv1.user_id = dvv2.user_id AND
            dvv1.topic_id = dvv2.topic_id AND
            dvv1.archive = dvv2.archive
    SQL

    # delete votes associated with no user
    DB.exec(<<~SQL)
      DELETE FROM topic_voting_votes
      USING topic_voting_votes tvv
      LEFT JOIN users u ON tvv.user_id = u.id
      WHERE u.id IS NULL;
    SQL

    # delete votes associated with no topics
    DB.exec(<<~SQL)
      DELETE FROM topic_voting_votes
      WHERE topic_voting_votes.topic_id IS NULL
    SQL

    # delete duplicate vote counts for topics
    DB.exec(<<~SQL)
      DELETE FROM topic_voting_topic_vote_count dvtvc
      USING topic_voting_topic_vote_count dvtvc2
      WHERE dvtvc.id < dvtvc2.id AND
            dvtvc.topic_id = dvtvc2.topic_id AND
            dvtvc.votes_count = dvtvc2.votes_count
    SQL

    # insert missing vote counts for topics
    # ensures we have "something" for every topic with votes
    DB.exec(<<~SQL)
      WITH missing_ids AS (
        SELECT DISTINCT t.id FROM topics t
        JOIN topic_voting_votes dvv ON t.id = dvv.topic_id
        LEFT JOIN topic_voting_topic_vote_count dvtvc ON t.id = dvtvc.topic_id
        WHERE dvtvc.topic_id IS NULL
      )
      INSERT INTO topic_voting_topic_vote_count (votes_count, topic_id, created_at, updated_at)
      SELECT '0', id, now(), now() FROM missing_ids
    SQL

    # remove all superflous vote count custom fields
    DB.exec(<<~SQL)
      DELETE FROM topic_voting_topic_vote_count
      WHERE topic_id IN (
        SELECT t1.id FROM topics t1
        LEFT JOIN topic_voting_votes dvv
          ON dvv.topic_id = t1.id
        WHERE dvv.id IS NULL
      )
    SQL

    # correct topics vote counts
    DB.exec(<<~SQL)
      UPDATE topic_voting_topic_vote_count dvtvc
      SET votes_count = (
        SELECT COUNT(*) FROM topic_voting_votes dvv
        WHERE dvtvc.topic_id = dvv.topic_id
        GROUP BY dvv.topic_id
      )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
