# frozen_string_literal: true
require "rails_helper"

describe DiscourseTopicVoting::CategorySetting do
  fab!(:category) { Fabricate(:category) }

  describe "logs category setting changes" do
    it "logs changes when voting is enabled/disabled" do
      DiscourseTopicVoting::CategorySetting.create!(category: category)
      expect(UserHistory.count).to eq(1)

      DiscourseTopicVoting::CategorySetting.first.destroy!
      expect(UserHistory.count).to eq(2)
    end
  end
end
