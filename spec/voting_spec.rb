require 'rails_helper'

describe DiscourseVoting do

  let(:user0) { Fabricate(:user) }
  let(:user1) { Fabricate(:user) }
  let(:user2) { Fabricate(:user) }
  let(:user3) { Fabricate(:user) }

  let(:topic0) { Fabricate(:topic) }
  let(:topic1) { Fabricate(:topic) }

  before do
    SiteSetting.voting_enabled = true
    SiteSetting.voting_show_who_voted = true
  end

  it 'moves votes when topics are merged' do

    users = [user0, user1, user2, user3]

    # +user0+ votes +topic0+, +user1+ votes +topic1+ and +user2+ votes both
    # topics.
    users[0].custom_fields['votes'] = users[0].votes.dup.push(topic0.id.to_s)
    users[1].custom_fields['votes'] = users[1].votes.dup.push(topic1.id.to_s)
    users[2].custom_fields['votes'] = users[2].votes.dup.push(topic0.id.to_s)
    users[2].custom_fields['votes'] = users[2].votes.dup.push(topic1.id.to_s)
    users.each { |u| u.save }
    [topic0, topic1].each { |t| t.update_vote_count }

    # Simulating merger of +topic0+ into +topic1+.
    DiscourseEvent.trigger(:topic_merged, topic0, topic1)

    # Force user refresh.
    users.map! { |u| User.find_by(id: u.id) }

    expect(users[0].votes).to eq([nil, topic1.id.to_s])
    expect(users[1].votes).to eq([nil, topic1.id.to_s])
    expect(users[2].votes).to eq([nil, topic1.id.to_s])
    expect(users[3].votes).to eq([nil])

    expect(topic0.vote_count).to eq(0)
    expect(topic1.vote_count).to eq(3)
  end

  context "when a user has an empty string as the votes custom field" do
    before do
      user0.custom_fields["votes"] = ""
      user0.save
    end

    it "returns a vote count of zero" do
      expect(user0.vote_count).to eq (0)
    end
  end

end
