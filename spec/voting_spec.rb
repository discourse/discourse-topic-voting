# frozen_string_literal: true

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

  it "doesn't allow users to vote more than they are allowed" do
    SiteSetting.voting_tl1_vote_limit = 1
    user0.update!(trust_level: 1)

    expect(user0.reached_voting_limit?).to eq(false)

    user0.custom_fields["votes"] = [topic0.id.to_s]
    user0.save!

    expect(user0.reached_voting_limit?).to eq(true)
  end

  context "with two topics" do
    let(:users) { [user0, user1, user2, user3] }

    before do
      Fabricate(:post, topic: topic0, user: user0)
      Fabricate(:post, topic: topic0, user: user0)

      # +user0+ votes +topic0+, +user1+ votes +topic1+ and +user2+ votes both
      # topics.
      users[0].custom_fields[DiscourseVoting::VOTES] = users[0].votes.dup.push(topic0.id.to_s)
      users[1].custom_fields[DiscourseVoting::VOTES] = users[1].votes.dup.push(topic1.id.to_s)
      users[2].custom_fields[DiscourseVoting::VOTES] = users[2].votes.dup.push(topic0.id.to_s)
      users[2].custom_fields[DiscourseVoting::VOTES] = users[2].votes.dup.push(topic1.id.to_s)

      users.each { |u| u.save! }

      [topic0, topic1].each { |t| t.update_vote_count }
    end

    it 'moves votes when entire topic is merged' do
      topic0.move_posts(Discourse.system_user, topic0.posts.pluck(:id), destination_topic_id: topic1.id)

      expect(users[0].reload.votes).to eq([topic1.id])
      expect(users[1].reload.votes).to eq([topic1.id])
      expect(users[2].reload.votes).to eq([topic1.id])
      expect(users[3].reload.votes).to eq([])

      expect(topic0.reload.vote_count).to eq(0)
      expect(topic1.reload.vote_count).to eq(3)

      merged_post = topic0.posts.find_by(action_code: 'split_topic')
      expect(merged_post.raw).to include(I18n.t('voting.votes_moved', count: 1))
      expect(merged_post.raw).to include(I18n.t('voting.duplicated_votes', count: 1))
    end

    it 'does not move votes when a single post is moved' do
      topic0.move_posts(Discourse.system_user, topic0.posts[1, 2].map(&:id), destination_topic_id: topic1.id)

      expect(users[0].reload.votes).to eq([topic0.id])
      expect(users[1].reload.votes).to eq([topic1.id])
      expect(users[2].reload.votes).to eq([topic0.id, topic1.id])
      expect(users[3].reload.votes).to eq([])

      expect(topic0.reload.vote_count).to eq(2)
      expect(topic1.reload.vote_count).to eq(2)
    end
  end

  context "when a user has an empty string as the votes custom field" do
    before do
      user0.custom_fields[DiscourseVoting::VOTES] = ""
      user0.custom_fields[DiscourseVoting::VOTES_ARCHIVE] = ""
      user0.save
      user0.reload
    end

    it "returns a vote count of zero" do
      expect(user0.vote_count).to eq (0)
      expect(user0.votes_archive).to eq ([])
    end
  end

  context "when topic status is changed" do
    it "enqueues a job for releasing/reclaiming votes" do
      DiscourseEvent.on(:topic_status_updated) do |topic|
        expect(topic).to be_instance_of(Topic)
      end

      topic1.update_status('closed', true, Discourse.system_user)
      expect(Jobs::VoteRelease.jobs.first["args"].first["topic_id"]).to eq(topic1.id)

      topic1.update_status('closed', false, Discourse.system_user)
      expect(Jobs::VoteReclaim.jobs.first["args"].first["topic_id"]).to eq(topic1.id)
    end
  end

  context "when a job is trashed and then recovered" do
    it "released the vote back to the user, then reclaims it on topic recovery" do
      Jobs.run_immediately!
      user0.custom_fields[DiscourseVoting::VOTES] = [topic1.id]
      user0.save

      topic1.reload.trash!
      expect(user0.reload.votes).to eq([])

      topic1.recover!
      expect(user0.reload.votes).to eq([topic1.id])
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
      user.custom_fields[DiscourseVoting::VOTES_ARCHIVE] = [post1.topic_id, 456456]
      user.save!

      PostRevisor.new(post1).revise!(admin, category_id: category1.id)
      expect(Jobs::VoteReclaim.jobs.first["args"].first["topic_id"]).to eq(post1.reload.topic_id)

      Jobs::VoteReclaim.new.execute(topic_id: post1.topic_id)
      user.reload

      expect(user.votes).to eq([post1.topic_id])
      expect(user.votes_archive).to eq([456456])
    end

    it "enqueus a job to release votes if voting is disabled for the new category" do
      user = post0.user
      user.custom_fields[DiscourseVoting::VOTES] = [post0.topic_id, 456456]
      user.save!

      PostRevisor.new(post0).revise!(admin, category_id: category2.id)
      expect(Jobs::VoteRelease.jobs.first["args"].first["topic_id"]).to eq(post0.reload.topic_id)

      Jobs::VoteRelease.new.execute(topic_id: post0.topic_id)
      user.reload

      expect(user.votes_archive).to eq([post0.topic_id])
      expect(user.votes).to eq([456456])
    end

    it "doesn't enqueue a job if the topic has no votes" do
      PostRevisor.new(post0).revise!(admin, category_id: category2.id)
      expect(Jobs::VoteRelease.jobs.size).to eq(0)

      PostRevisor.new(post1).revise!(admin, category_id: category1.id)
      expect(Jobs::VoteReclaim.jobs.size).to eq(0)
    end
  end

  context "when a category has voting enabled/disabled" do
    let(:category3) { Fabricate(:category) }
    let(:topic2) { Fabricate(:topic, category: category3) }

    before do
      category1.custom_fields["enable_topic_voting"] = true
      category1.save!

      category2.custom_fields["enable_topic_voting"] = true
      category2.save!

      category3.custom_fields["enable_topic_voting"] = false
      category3.save!

      user0.custom_fields[DiscourseVoting::VOTES] = [topic0.id, topic1.id]
      user0.custom_fields[DiscourseVoting::VOTES_ARCHIVE] = [topic2.id]
      user0.save!
    end

    it "reclaims votes when voting is disabled on a category" do
      category = Category.find(category1.id)
      category.custom_fields["enable_topic_voting"] = false
      category.save!

      user0.reload

      expect(user0.custom_fields[DiscourseVoting::VOTES]).to contain_exactly(topic1.id)
      expect(user0.custom_fields[DiscourseVoting::VOTES_ARCHIVE]).to contain_exactly(topic0.id, topic2.id)
    end

    it "restores votes when voting is enabled on a category" do
      category = Category.find(category3.id)
      category.custom_fields["enable_topic_voting"] = true
      category.save!

      user0.reload

      expect(user0.custom_fields[DiscourseVoting::VOTES]).to contain_exactly(topic0.id, topic1.id, topic2.id)
      expect(user0.custom_fields[DiscourseVoting::VOTES_ARCHIVE]).to eq(nil)
    end
  end
end
