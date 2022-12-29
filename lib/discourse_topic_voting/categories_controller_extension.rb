# frozen_string_literal: true

module DiscourseTopicVoting
  module CategoriesControllerExtension
    def category_params
      @vote_enabled ||=
        !!ActiveRecord::Type::Boolean.new.cast(params[:custom_fields]&.delete(:enable_topic_voting))
      category_params = super
      if @vote_enabled && !@category&.category_setting
        category_params[:category_setting_attributes] = {}
      elsif !@vote_enabled && @category&.category_setting
        category_params[:category_setting_attributes] = {
          id: @category.category_setting.id,
          _destroy: "1",
        }
      end
      category_params
    end
  end
end
