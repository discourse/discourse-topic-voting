# frozen_string_literal: true

require 'rails_helper'

describe TopicQuery do
  fab!(:user0) { Fabricate(:user) }
  fab!(:category1) { Fabricate(:category) }
  fab!(:topic0) { Fabricate(:topic, category: category1) }
  fab!(:topic1) { Fabricate(:topic, category: category1) }
  fab!(:category_setting) { DiscourseVoting::CategorySetting.create!(category_id: category1) }
  fab!(:vote) { DiscourseVoting::Vote.create!(topic_id: topic1.id, user_id: user0.id) }
  fab!(:topic_vote_count) { DiscourseVoting::TopicVoteCount.create!(topic_id: topic1.id, votes_count: 1) }

  before do
    SiteSetting.voting_enabled = true
    SiteSetting.voting_show_who_voted = true
  end

  it "order topic by votes" do
    expect(TopicQuery.new(user0, { order: 'votes' }).list_latest.topics.map(&:id)).to eq([topic1.id, topic0.id])
  end

  it "returns topics voted by user" do
    expect(TopicQuery.new(user0, { status: 'my_votes' }).list_latest.topics.map(&:id)).to eq([topic1.id])
  end
end
