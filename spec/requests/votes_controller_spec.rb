require 'rails_helper'

describe DiscourseVoting::VotesController do

  let(:user) { Fabricate(:user) }
  let(:category) { Fabricate(:category) }
  let(:topic) { Fabricate(:topic, category_id: category.id) }

  before do
    CategoryCustomField.create!(category_id: category.id, name: "enable_topic_voting", value: "true")
    Category.reset_voting_cache
    SiteSetting.voting_show_who_voted = true
    SiteSetting.voting_enabled = true
    sign_in(user)
  end

  it "doesn't allow users to vote more than once on a topic" do
    post "/voting/vote.json", params: { topic_id: topic.id }
    expect(response.status).to eq(200)

    post "/voting/vote.json", params: { topic_id: topic.id }
    expect(response.status).to eq(403)
    expect(topic.reload.vote_count).to eq(1)
    expect(user.reload.vote_count).to eq(1)
  end

  context "when a user has tallyed votes with no topic id" do
    before do
      user.custom_fields[DiscourseVoting::VOTES] = [nil, nil, nil]
      user.save
    end

    it "removes extra votes" do
      post "/voting/vote.json", params: { topic_id: topic.id }
      expect(response.status).to eq(200)
      expect(user.reload.vote_count).to eq (1)
    end
  end
end
