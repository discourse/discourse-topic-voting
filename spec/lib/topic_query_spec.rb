# frozen_string_literal: true

require 'rails_helper'

describe TopicQuery do
  let!(:user0) { Fabricate(:user) }
  let!(:category1) { Fabricate(:category) }
  let!(:topic0) { Fabricate(:topic, category: category1) }
  let!(:topic1) { Fabricate(:topic, category: category1) }

  before do
    SiteSetting.voting_enabled = true
    SiteSetting.voting_show_who_voted = true
    DiscourseVoting::CategorySetting.create!(category_id: category1)
    DiscourseVoting::Vote.create!(topic_id: topic1.id, user_id: user0.id)
    DiscourseVoting::VoteCounter.create!(topic_id: topic1.id, counter: 1)
  end

  it "order topic by votes" do
    expect(TopicQuery.new(user0, { order: 'votes' }).list_latest.topics.map(&:id)).to eq([topic1.id, topic0.id])
  end

  it "returns topics voted by user" do
    expect(TopicQuery.new(user0, { order: 'my_votes' }).list_latest.topics.map(&:id)).to eq([topic1.id])
  end
end
