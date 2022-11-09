# frozen_string_literal: true

require 'rails_helper'

describe TopicViewSerializer do
  let(:user) { Fabricate(:user) }
  let(:category) { Fabricate(:category) }
  let(:topic) { Fabricate(:topic, category_id: category.id) }
  let(:topic_view) { TopicView.new(topic, user) }
  let(:guardian) { Guardian.new(user) }

  it 'returns false when voting disabled' do
    SiteSetting.voting_enabled = false
    DiscourseTopicVoting::CategorySetting.create!(category: category)

    json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    expect(json[:can_vote]).to eq(false)
  end

  it 'returns false when topic not in category' do
    SiteSetting.voting_enabled = true

    json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    expect(json[:can_vote]).to eq(false)
  end

  it 'returns false when voting disabled and topic not in category' do
    json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    expect(json[:can_vote]).to eq(false)
  end

  it 'returns true when voting enabled and topic in category' do
    SiteSetting.voting_enabled = true
    DiscourseTopicVoting::CategorySetting.create!(category: category)

    json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    expect(json[:can_vote]).to eq(true)
  end
end
