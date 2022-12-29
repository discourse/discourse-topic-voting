# frozen_string_literal: true

require "rails_helper"

describe BasicCategorySerializer do
  fab!(:category) { Fabricate(:category) }

  it "does not return can_vote when voting disabled" do
    SiteSetting.voting_enabled = false

    json = BasicCategorySerializer.new(category, root: false).as_json

    expect(json[:can_vote]).to eq(nil)
  end

  it "does not return can_vote when voting disabled" do
    SiteSetting.voting_enabled = true
    DiscourseTopicVoting::CategorySetting.create!(category: category)

    json = BasicCategorySerializer.new(category, root: false).as_json

    expect(json[:can_vote]).to eq(true)
  end
end
