# frozen_string_literal: true

module DiscourseVoting
  module CategoriesControllerExtension
    def update
      guardian.ensure_can_edit!(@category)
      vote_enabled = params[:custom_fields] && params[:custom_fields].delete(:enable_topic_voting) == "true"
      vote_enabled ? DiscourseVoting::CategorySetting.create(category: @category) : DiscourseVoting::CategorySetting.destroy_by(category: @category)
      super
    end
  end
end
