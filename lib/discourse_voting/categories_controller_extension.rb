# frozen_string_literal: true

module DiscourseVoting
  module CategoriesControllerExtension
    def category_params
      @vote_enabled ||= params[:custom_fields] && params[:custom_fields].delete(:enable_topic_voting) == "true"
      category_params = super
      if @vote_enabled
        category_params[:category_setting_attributes] = {}
      elsif @category&.category_setting 
        category_params[:category_setting_attributes] = { id: @category.category_setting.id, _destroy: '1' }
      end
      category_params
    end
  end
end
