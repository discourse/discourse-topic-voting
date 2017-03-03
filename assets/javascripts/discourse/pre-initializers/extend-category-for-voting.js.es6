import property from 'ember-addons/ember-computed-decorators';
import Category from 'discourse/models/category';
import { withPluginApi } from 'discourse/lib/plugin-api';

function initialize(api) {
  api.addTagsHtmlCallback((topic) => {
    if (!topic.can_vote) { return; }

    var buffer = [];

    let title;
    if (topic.user_voted) {
      title = ` title='${I18n.t('feature_voting.voted')}'`;
    }

    let userVotedClass = topic.user_voted ? " voted" : "";
    buffer.push(`<span class='list-vote-count discourse-tag${userVotedClass}'${title}>`);
    buffer.push(I18n.t('feature_voting.votes', {count: topic.vote_count}));
    if (topic.user_voted) {
      buffer.push(`<i class='fa fa-star'></i>`);
    }
    buffer.push("</span>");

    if (buffer.length > 0){
      return buffer.join("");
    }

  }, {priority: -100});
}

export default {
  name: 'extend-category-for-voting',
  before: 'inject-discourse-objects',
  initialize(container) {

    withPluginApi('0.8.3', api => {
      initialize(api, container);
    });

    Category.reopen({

      @property('custom_fields.enable_topic_voting')
      enable_topic_voting: {
        get(enableField) {
          return enableField === "true";
        },
        set(value) {
          value = value ? "true" : "false";
          this.set("custom_fields.enable_topic_voting", value);
          return value;
        }
      }

    });
  }
};
