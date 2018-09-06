module Jobs
  class CleanDupNullVotes < Jobs::Onceoff
    def execute_onceoff(args)
      # delete duplicate votes
      DB.exec("
        DELETE FROM user_custom_fields ucf1
        USING user_custom_fields ucf2
        WHERE ucf1.id < ucf2.id AND
              ucf1.user_id = ucf2.user_id AND
              ucf1.value = ucf2.value AND
              ucf1.name = ucf2.name AND
              (ucf1.name IN ('#{DiscourseVoting::VOTES}', '#{DiscourseVoting::VOTES_ARCHIVE}'))
      ")

      # delete votes associated with no topics
      DB.exec("
        DELETE FROM user_custom_fields ucf
        WHERE ucf.value IS NULL
        AND ucf.name IN ('#{DiscourseVoting::VOTES}', '#{DiscourseVoting::VOTES_ARCHIVE}')
      ")

      # delete duplicate vote counts for topics
      DB.exec("
        DELETE FROM topic_custom_fields tcf
        USING topic_custom_fields tcf2
        WHERE tcf.id < tcf2.id AND
              tcf.name = tcf2.name AND
              tcf.topic_id = tcf2.topic_id AND
              tcf.value = tcf.value AND
              tcf.name = '#{DiscourseVoting::VOTE_COUNT}'
      ")

      # insert missing vote counts for topics
      DB.exec("
        WITH missing_ids AS (
          SELECT t.id FROM topics t
          JOIN user_custom_fields ucf
          ON t.id::text = ucf.value
          LEFT JOIN topic_custom_fields tcf
          ON t.id = tcf.topic_id
          WHERE ucf.name IN ('#{DiscourseVoting::VOTES}', '#{DiscourseVoting::VOTES_ARCHIVE}') AND
          tcf.topic_id IS NULL OR tcf.name <> '#{DiscourseVoting::VOTE_COUNT}'
        )
        INSERT INTO topic_custom_fields (value, topic_id, name, created_at, updated_at)
        SELECT '0', id, '#{DiscourseVoting::VOTE_COUNT}', now(), now() FROM missing_ids
      ")

      # correct topics vote counts
      DB.exec("
        UPDATE topic_custom_fields tcf
        SET value = (
          SELECT COUNT(*) FROM user_custom_fields ucf
          WHERE tcf.topic_id::text = ucf.value AND ucf.name IN ('#{DiscourseVoting::VOTES}', '#{DiscourseVoting::VOTES_ARCHIVE}')
          GROUP BY ucf.value
        )
        WHERE tcf.name = '#{DiscourseVoting::VOTE_COUNT}'
      ")
    end
  end
end
