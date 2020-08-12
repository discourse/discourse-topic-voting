# frozen_string_literal: true

require 'rails_helper'

describe Jobs::VotingEnsureConsistency do
  it "ensures consistency" do
    user = Fabricate(:user)
    user2 = Fabricate(:user)

    no_vote_topic = Fabricate(:topic)
    DiscourseVoting::VoteCounter.create(topic: no_vote_topic, counter: 10)
    no_vote_topic.custom_fields["random1"] = "random"
    no_vote_topic.save_custom_fields

    one_vote_topic = Fabricate(:topic)
    DiscourseVoting::VoteCounter.create(topic: one_vote_topic, counter: 10)
    one_vote_topic.custom_fields["random2"] = "random"
    one_vote_topic.save_custom_fields

    two_vote_topic = Fabricate(:topic)
    two_vote_topic.custom_fields["random3"] = "random"
    two_vote_topic.save_custom_fields

    # one vote
    DiscourseVoting::Vote.create!(user: user, topic: one_vote_topic, archive: true)

    # two votes
    DiscourseVoting::Vote.create(user: user, topic: two_vote_topic, archive: true)
    DiscourseVoting::Vote.create(user: user2, topic: two_vote_topic)

    subject.execute_onceoff(nil)

    no_vote_topic.reload
    expect(no_vote_topic.custom_fields["random1"]).to eq("random")

    expect(DiscourseVoting::Vote.where(user: user).pluck(:topic_id)).to eq([one_vote_topic.id, two_vote_topic.id])
    expect(DiscourseVoting::Vote.where(user: user2).pluck(:topic_id)).to eq([two_vote_topic.id])

    one_vote_topic.reload
    expect(one_vote_topic.vote_counter.counter).to eq(1)
    expect(one_vote_topic.custom_fields["random2"]).to eq("random")

    two_vote_topic.reload
    expect(two_vote_topic.vote_counter.counter).to eq(2)
    expect(two_vote_topic.custom_fields["random3"]).to eq("random")

    expect(no_vote_topic.reload.custom_fields).to eq("random1" => "random")
    expect(one_vote_topic.reload.custom_fields).to eq("random2" => "random")
    expect(two_vote_topic.reload.custom_fields).to eq("random3" => "random")
  end
end
