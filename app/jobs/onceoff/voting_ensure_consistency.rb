module Jobs
  class VotingEnsureConsistency < Jobs::Onceoff
    def execute_onceoff(args)
      aliases = {
        vote_count: DiscourseVoting::VOTE_COUNT,
        votes: DiscourseVoting::VOTES,
        votes_archive: DiscourseVoting::VOTES_ARCHIVE,
      }

      # archive votes to closed or archived or deleted topics
      DB.exec(<<~SQL, aliases)
        UPDATE user_custom_fields ucf
        SET name = :votes_archive
        FROM topics t
        WHERE ucf.name = :votes
        AND (t.closed OR t.archived OR t.deleted_at IS NOT NULL)
        AND t.id::text = ucf.value
      SQL

      # un-archive votes to open topics
      DB.exec(<<~SQL, aliases)
        UPDATE user_custom_fields ucf
        SET name = :votes
        FROM topics t
        WHERE ucf.name = :votes_archive
        AND NOT t.closed
        AND NOT t.archived
        AND t.deleted_at IS NULL
        AND t.id::text = ucf.value
      SQL

      # delete duplicate votes
      DB.exec(<<~SQL, aliases)
        DELETE FROM user_custom_fields ucf1
        USING user_custom_fields ucf2
        WHERE ucf1.id < ucf2.id AND
              ucf1.user_id = ucf2.user_id AND
              ucf1.value = ucf2.value AND
              ucf1.name = ucf2.name AND
              (ucf1.name IN (:votes, :votes_archive))
      SQL

      # delete votes associated with no topics
      DB.exec(<<~SQL, aliases)
        DELETE FROM user_custom_fields ucf
        WHERE ucf.value IS NULL
        AND ucf.name IN (:votes, :votes_archive)
      SQL

      # delete duplicate vote counts for topics
      DB.exec(<<~SQL, aliases)
        DELETE FROM topic_custom_fields tcf
        USING topic_custom_fields tcf2
        WHERE tcf.id < tcf2.id AND
              tcf.name = tcf2.name AND
              tcf.topic_id = tcf2.topic_id AND
              tcf.value = tcf.value AND
              tcf.name = :vote_count
      SQL

      # insert missing vote counts for topics
      # ensures we have "something" for every topic with votes
      DB.exec(<<~SQL, aliases)
        WITH missing_ids AS (
          SELECT DISTINCT t.id FROM topics t
          JOIN user_custom_fields ucf ON t.id::text = ucf.value AND
            ucf.name IN (:votes, :votes_archive)
          LEFT JOIN topic_custom_fields tcf ON t.id = tcf.topic_id
            AND tcf.name = :vote_count
          WHERE tcf.topic_id IS NULL
        )
        INSERT INTO topic_custom_fields (value, topic_id, name, created_at, updated_at)
        SELECT '0', id, :vote_count, now(), now() FROM missing_ids
      SQL

      # remove all superflous vote count custom fields
      DB.exec(<<~SQL, aliases)
        DELETE FROM topic_custom_fields
        WHERE name = :vote_count
        AND topic_id IN (
          SELECT t1.id FROM topics t1
          LEFT JOIN user_custom_fields ucf
            ON ucf.value = t1.id::text AND
              ucf.name IN (:votes, :votes_archive)
          WHERE ucf.id IS NULL
        )
      SQL

      # correct topics vote counts
      DB.exec(<<~SQL, aliases)
        UPDATE topic_custom_fields tcf
        SET value = (
          SELECT COUNT(*) FROM user_custom_fields ucf
          WHERE tcf.topic_id::text = ucf.value AND
            ucf.name IN (:votes, :votes_archive)
          GROUP BY ucf.value
        )
        WHERE tcf.name = :vote_count
      SQL
    end
  end
end
