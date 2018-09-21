require 'rails_helper'

describe "Voting Consistency" do
  it "cleans up mess" do

    user = Fabricate(:user)
    user2 = Fabricate(:user)

    no_vote_topic = Fabricate(:topic)
    no_vote_topic.custom_fields[DiscourseVoting::VOTE_COUNT] = "10"
    no_vote_topic.custom_fields["random1"] = "random"
    no_vote_topic.save_custom_fields

    one_vote_topic = Fabricate(:topic)
    one_vote_topic.custom_fields[DiscourseVoting::VOTE_COUNT] = "10"
    one_vote_topic.custom_fields["random2"] = "random"
    one_vote_topic.save_custom_fields

    two_vote_topic = Fabricate(:topic)
    two_vote_topic.custom_fields["random3"] = "random"
    two_vote_topic.save_custom_fields

    # one vote
    UserCustomField.create!(user_id: user.id, name: DiscourseVoting::VOTES_ARCHIVE, value: one_vote_topic.id)

    # two votes
    UserCustomField.create!(user_id: user.id, name: DiscourseVoting::VOTES_ARCHIVE, value: two_vote_topic.id)
    UserCustomField.create!(user_id: user2.id, name: DiscourseVoting::VOTES, value: two_vote_topic.id)

    Jobs::VotingEnsureConsistency.new.execute_onceoff(nil)

    no_vote_topic.reload
    expect(no_vote_topic.custom_fields).to eq("random1" => "random")

    user.reload
    expect(user.custom_fields).to eq("votes" => [one_vote_topic.id, two_vote_topic.id])

    user2.reload
    expect(user2.custom_fields).to eq("votes" => [two_vote_topic.id])

    one_vote_topic.reload
    expect(one_vote_topic.custom_fields).to eq("vote_count" => 1, "random2" => "random")

    two_vote_topic.reload
    expect(two_vote_topic.custom_fields).to eq("vote_count" => 2, "random3" => "random")

  end
end
