# frozen_string_literal: true

require 'rails_helper'

describe TopicsController do
  fab!(:topic1) { Fabricate(:topic) }
  fab!(:topic2) { Fabricate(:topic) }
  fab!(:post1) { Fabricate(:post, topic: topic1) }
  fab!(:post2) { Fabricate(:post, topic: topic2) }
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }
  fab!(:user4) { Fabricate(:user) }
  fab!(:admin) { Fabricate(:admin) }

  it 'moves votes when topics are merged' do
    sign_in(admin)
    vote1 = DiscourseVoting::Vote.create!(user: user1, topic: topic1)

    vote2 = DiscourseVoting::Vote.create!(user: user2, topic: topic1)
    vote3 = DiscourseVoting::Vote.create!(user: user2, topic: topic2)

    vote_archive1 = DiscourseVoting::Vote.create!(user: user3, topic: topic1, archive: true)

    vote_archive2 = DiscourseVoting::Vote.create!(user: user4, topic: topic1, archive: true)
    vote_archive3 = DiscourseVoting::Vote.create!(user: user4, topic: topic2, archive: true)

    post "/t/#{topic1.id}/move-posts.json", params: {
      post_ids: [post1.id],
      destination_topic_id: topic2.id
    }

    expect(vote1.reload.topic).to eq(topic2)

    expect { vote2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(vote3.reload.topic).to eq(topic2)

    expect(vote_archive1.reload.topic).to eq(topic2)

    expect { vote_archive2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(vote_archive3.reload.topic).to eq(topic2)
  end
end
