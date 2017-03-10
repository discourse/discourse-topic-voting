import computed from 'ember-addons/ember-computed-decorators';
import Category from 'discourse/models/category';
import { withPluginApi } from 'discourse/lib/plugin-api';

function initialize(api) {

  api.addPostClassesCallback((post) => {
    if (post.post_number === 1 && post.can_vote) {
      return ["voting-post"];
    }
  });
  api.includePostAttributes('can_vote');
  api.addTagsHtmlCallback((topic) => {
    if (!topic.can_vote) { return; }

    var buffer = [];

    let title;
    if (topic.user_voted) {
      title = ` title='${I18n.t('voting.voted')}'`;
    }

    let userVotedClass = topic.user_voted ? " voted" : "";
    buffer.push(`<a href='${topic.get('url')}' class='list-vote-count discourse-tag${userVotedClass}'${title}>`);
    buffer.push(I18n.t('voting.votes', {count: topic.vote_count}));
    if (topic.user_voted) {
      buffer.push(`<i class='fa fa-star'></i>`);
    }
    buffer.push("</a>");

    if (buffer.length > 0){
      return buffer.join("");
    }

  }, {priority: -100});
}

export default {
  name: 'extend-category-for-voting',
  before: 'inject-discourse-objects',
  initialize(container) {

    withPluginApi('0.8.4', api => {
      initialize(api, container);
    });

    Category.reopen({

      @computed("url")
      votesUrl(url) {
        return `${url}/l/votes`;
      },

      @computed('custom_fields.enable_topic_voting')
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
