require 'rails_helper'

describe DiscourseVoting do

  let(:user0) { Fabricate(:user) }
  let(:user1) { Fabricate(:user) }
  let(:user2) { Fabricate(:user) }
  let(:user3) { Fabricate(:user) }

  let(:category1) { Fabricate(:category) }
  let(:category2) { Fabricate(:category) }

  let(:topic0) { Fabricate(:topic, category: category1) }
  let(:topic1) { Fabricate(:topic, category: category2) }

  before do
    SiteSetting.voting_enabled = true
    SiteSetting.voting_show_who_voted = true
  end

  it 'moves votes when topics are merged' do

    users = [user0, user1, user2, user3]

    # +user0+ votes +topic0+, +user1+ votes +topic1+ and +user2+ votes both
    # topics.
    users[0].custom_fields['votes'] = users[0].votes.dup.push(topic0.id.to_s)
    users[1].custom_fields['votes'] = users[1].votes.dup.push(topic1.id.to_s)
    users[2].custom_fields['votes'] = users[2].votes.dup.push(topic0.id.to_s)
    users[2].custom_fields['votes'] = users[2].votes.dup.push(topic1.id.to_s)
    users.each { |u| u.save }
    [topic0, topic1].each { |t| t.update_vote_count }

    # Simulating merger of +topic0+ into +topic1+.
    DiscourseEvent.trigger(:topic_merged, topic0, topic1)

    # Force user refresh.
    users.map! { |u| User.find_by(id: u.id) }

    expect(users[0].votes).to eq([nil, topic1.id.to_s])
    expect(users[1].votes).to eq([nil, topic1.id.to_s])
    expect(users[2].votes).to eq([nil, topic1.id.to_s])
    expect(users[3].votes).to eq([nil])

    expect(topic0.vote_count).to eq(0)
    expect(topic1.vote_count).to eq(3)
  end

  context "when a user has an empty string as the votes custom field" do
    before do
      user0.custom_fields["votes"] = ""
      user0.save
    end

    it "returns a vote count of zero" do
      expect(user0.vote_count).to eq (0)
    end
  end

  context "when a topic is moved to a category" do
    let(:admin) { Fabricate(:admin) }
    let(:post0) { Fabricate(:post, topic: topic0, post_number: 1) }
    let(:post1) { Fabricate(:post, topic: topic1, post_number: 1) }
    
    before do
      category1.custom_fields["enable_topic_voting"] = "true"
      category1.save!
      Category.reset_voting_cache
    end

    it "enqueus a job to reclaim votes if voting is enabled for the new category" do
      user = post1.user
      user.custom_fields["votes_archive"] = [post1.topic_id, 456456]
      user.save!

      PostRevisor.new(post1).revise!(admin, category_id: category1.id)
      expect(Jobs::VoteReclaim.jobs.first["args"].first["topic_id"]).to eq(post1.reload.topic_id)

      Jobs::VoteReclaim.new.execute(topic_id: post1.topic_id)
      user.reload

      expect(user.votes).to contain_exactly(post1.topic_id.to_s, nil)
      expect([user.votes_archive]).to contain_exactly("456456")
    end

    it "enqueus a job to release votes if voting is disabled for the new category" do
      user = post0.user
      user.custom_fields["votes"] = [post0.topic_id, 456456]
      user.save!

      PostRevisor.new(post0).revise!(admin, category_id: category2.id)
      expect(Jobs::VoteRelease.jobs.first["args"].first["topic_id"]).to eq(post0.reload.topic_id)

      Jobs::VoteRelease.new.execute(topic_id: post0.topic_id)
      user.reload

      expect(user.votes_archive).to contain_exactly(post0.topic_id.to_s, nil)
      expect([user.votes]).to contain_exactly("456456")
    end

    it "doesn't enqueue a job if the topic has no votes" do
      PostRevisor.new(post0).revise!(admin, category_id: category2.id)
      expect(Jobs::VoteRelease.jobs.size).to eq(0)

      PostRevisor.new(post1).revise!(admin, category_id: category1.id)
      expect(Jobs::VoteReclaim.jobs.size).to eq(0)
    end
  end
end
