# frozen_string_literal: true

require "rails_helper"

describe CategorySerializer do
  fab!(:category) { Fabricate(:category) }

  it "does not return enable_topic_voting voting disabled" do
    SiteSetting.voting_enabled = false

    json = CategorySerializer.new(category, root: false).as_json

    expect(json[:custom_fields]).to eq({})
  end

  it "return enable_topic_voting when voting enabled" do
    SiteSetting.voting_enabled = true

    json = CategorySerializer.new(category, root: false).as_json

    expect(json[:custom_fields]).to eq({ enable_topic_voting: true })
  end
end
