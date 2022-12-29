# frozen_string_literal: true

require "rails_helper"

describe ListController do
  fab!(:user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic) }
  # "topics/voted-by/:username"
  before { SiteSetting.voting_enabled = true }

  it "allow anons to view votes" do
    DiscourseTopicVoting::Vote.create!(user: user, topic: topic)

    get "/topics/voted-by/#{user.username}.json"
    topic_json = response.parsed_body.dig("topic_list", "topics").first

    expect(topic_json["id"]).to eq(topic.id)
  end

  it "returns a 404 when we don't show votes on profiles" do
    DiscourseTopicVoting::Vote.create!(user: user, topic: topic)
    SiteSetting.voting_show_votes_on_profile = false

    get "/topics/voted-by/#{user.username}.json"

    expect(response.status).to eq(404)
  end
end
