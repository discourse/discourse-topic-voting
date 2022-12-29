# frozen_string_literal: true

require "rails_helper"

describe Jobs::VotingEnsureConsistency do
  it "ensures consistency" do
    user = Fabricate(:user)
    user2 = Fabricate(:user)

    no_vote_topic = Fabricate(:topic)
    DiscourseTopicVoting::TopicVoteCount.create!(topic: no_vote_topic, votes_count: 10)

    one_vote_topic = Fabricate(:topic)
    DiscourseTopicVoting::TopicVoteCount.create!(topic: one_vote_topic, votes_count: 10)

    two_vote_topic = Fabricate(:topic)

    # one vote
    DiscourseTopicVoting::Vote.create!(user: user, topic: one_vote_topic, archive: true)

    # two votes
    DiscourseTopicVoting::Vote.create!(user: user, topic: two_vote_topic, archive: true)
    DiscourseTopicVoting::Vote.create!(user: user2, topic: two_vote_topic)

    subject.execute_onceoff(nil)

    no_vote_topic.reload

    expect(DiscourseTopicVoting::Vote.where(user: user).pluck(:topic_id)).to eq(
      [one_vote_topic.id, two_vote_topic.id],
    )
    expect(DiscourseTopicVoting::Vote.where(user: user2).pluck(:topic_id)).to eq(
      [two_vote_topic.id],
    )

    one_vote_topic.reload
    expect(one_vote_topic.topic_vote_count.votes_count).to eq(1)

    two_vote_topic.reload
    expect(two_vote_topic.topic_vote_count.votes_count).to eq(2)
  end
end
