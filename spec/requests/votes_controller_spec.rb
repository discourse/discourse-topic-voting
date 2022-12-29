# frozen_string_literal: true

require "rails_helper"

describe DiscourseTopicVoting::VotesController do
  let(:user) { Fabricate(:user) }
  let(:category) { Fabricate(:category) }
  let(:topic) { Fabricate(:topic, category_id: category.id) }

  before do
    DiscourseTopicVoting::CategorySetting.create!(category: category)
    Category.reset_voting_cache
    SiteSetting.voting_show_who_voted = true
    SiteSetting.voting_enabled = true
    sign_in(user)
  end

  it "does not allow voting if voting is not enabled" do
    SiteSetting.voting_enabled = false
    post "/voting/vote.json", params: { topic_id: topic.id }
    expect(response.status).to eq(403)
  end

  it "can correctly show deal with voting workflow" do
    SiteSetting.public_send "voting_tl#{user.trust_level}_vote_limit=", 2

    post "/voting/vote.json", params: { topic_id: topic.id }
    expect(response.status).to eq(200)

    post "/voting/vote.json", params: { topic_id: topic.id }
    expect(response.status).to eq(403)
    expect(topic.reload.vote_count).to eq(1)
    expect(user.reload.vote_count).to eq(1)

    get "/voting/who.json", params: { topic_id: topic.id }
    expect(response.status).to eq(200)
    json = JSON.parse(response.body)
    expect(json.length).to eq(1)
    expect(json.first.keys.sort).to eq(%w[avatar_template id name username])
    expect(json.first["id"]).to eq(user.id)

    post "/voting/unvote.json", params: { topic_id: topic.id }
    expect(response.status).to eq(200)

    expect(topic.reload.vote_count).to eq(0)
    expect(user.reload.vote_count).to eq(0)
  end
end
