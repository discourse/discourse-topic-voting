# frozen_string_literal: true

module DiscourseTopicVoting
  module CategoryExtension
    def self.prepended(base)
      base.class_eval do
        has_one :category_setting,
                class_name: "DiscourseTopicVoting::CategorySetting",
                dependent: :destroy

        accepts_nested_attributes_for :category_setting, allow_destroy: true

        after_save :reset_voting_cache

        @allowed_voting_cache = DistributedCache.new("allowed_voting")

        def self.reset_voting_cache
          @allowed_voting_cache["allowed"] = CategorySetting.pluck(:category_id)
        end

        def self.can_vote?(category_id)
          return false if !SiteSetting.voting_enabled

          (@allowed_voting_cache["allowed"] || reset_voting_cache).include?(category_id)
        end
      end
    end

    protected

    def reset_voting_cache
      ::Category.reset_voting_cache
    end
  end
end
