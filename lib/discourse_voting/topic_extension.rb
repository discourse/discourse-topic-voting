# frozen_string_literal: true

module DiscourseVoting
  module TopicExtension
    def self.prepended(base)
      base.has_one :topic_vote_count, class_name: 'DiscourseVoting::TopicVoteCount', dependent: :destroy
      base.has_many :votes, class_name: 'DiscourseVoting::Vote', dependent: :destroy
      base.attribute :current_user_voted
    end

    def can_vote?
      SiteSetting.voting_enabled && Category.can_vote?(category_id) && category.topic_id != id
    end

    def vote_count
      self.topic_vote_count&.votes_count.to_i
    end

    def user_voted?(user)
      if self.current_user_voted
        self.current_user_voted == 1
      else
        votes.map(&:user_id).include?(user.id)
      end
    end

    def update_vote_count
      count = self.votes.count

      topic_vote_count = self.topic_vote_count || DiscourseVoting::TopicVoteCount.new(topic: self)
      topic_vote_count.update!(votes_count: count)
    end

    def who_voted
      return nil unless SiteSetting.voting_show_who_voted
      self.votes.map(&:user)
    end
  end
end
