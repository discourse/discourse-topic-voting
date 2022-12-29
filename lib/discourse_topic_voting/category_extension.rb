# frozen_string_literal: true

module DiscourseTopicVoting
  module CategoryExtension
    def self.prepended(base)
      base.has_one :category_setting,
                   class_name: "DiscourseTopicVoting::CategorySetting",
                   dependent: :destroy
      base.accepts_nested_attributes_for :category_setting, allow_destroy: true
    end
  end
end
