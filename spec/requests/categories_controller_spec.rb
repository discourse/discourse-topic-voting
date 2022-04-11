# frozen_string_literal: true

require 'rails_helper'

describe CategoriesController do
  fab!(:category) { Fabricate(:category) }
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:admin) { Fabricate(:user, admin: true) }

  before do
    SiteSetting.voting_enabled = true
    sign_in(admin)
  end

  it "enables voting correctly" do
    put "/categories/#{category.id}.json", params: {
      custom_fields: { "enable_topic_voting" => true }
    }
    expect(Category.can_vote?(category.id)).to eq(true)
  end
end
