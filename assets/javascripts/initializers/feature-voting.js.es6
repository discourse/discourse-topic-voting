import { withPluginApi } from 'discourse/lib/plugin-api';
import TopicRoute from 'discourse/routes/topic';
import TopicController from 'discourse/controllers/topic';
import { createWidget } from 'discourse/widgets/widget';

function  startVoting(api){
  TopicRoute.reopen({
    actions: {
      vote() {
        var topic = this.modelFor('topic');
        return Discourse.ajax("/voting/vote", {
          type: 'POST',
          data: {
            topic_id: topic.id,
            user_id: Discourse.User.current().id
          }
        }).then(function(result) {
          topic.set('vote_count', result.vote_count);
          topic.set('user_voted', true);
          Discourse.User.current().set('vote_limit', result.vote_limit);

        }).catch(function(error) {
          console.log(error);
        });
      },
      unvote() {
        var topic = this.modelFor('topic');
        return Discourse.ajax("/voting/unvote", {
          type: 'POST',
          data: {
            topic_id: topic.id,
            user_id: Discourse.User.current().id
          }
        }).then(function(result) {
          topic.set('vote_count', result.vote_count);
          topic.set('user_voted', false);
          Discourse.User.current().set('vote_limit', result.vote_limit);
        }).catch(function(error) {
          console.log(error);
        });
      }
    }
  })

  TopicController.reopen({
    actions: {
      showWhoVoted() {
        this.set('whoVotedVisible', true);
      },

      hideWhoVoted() {
        this.set('whoVotedVisible', false);
      }
    }
  })

  createWidget('who-voted', {
    tagName: 'div.who-voted',

    html(attrs, state) {
      const contents = this.attach('small-user-list', {
        users: this.getWhoVoted(),
        addSelf: attrs.liked,
        listClassName: 'who-voted',
        description: 'feature_voting.who_voted'
      })
      return contents;
    },

    getWhoVoted() {
      const { attrs, state } = this;
      var users = attrs.who_voted;
      return state.whoVotedUsers = users.map(whoVotedAvatars);
    }
  });
}

function whoVotedAvatars(user) {
  return { template: user.user.avatar_template,
           username: user.user.username,
           post_url: user.user.post_url,
           url: Discourse.getURL('/users/') + user.user.username_lower };
}

export default {
  name: 'feature-voting',
  initialize: function() {
    withPluginApi('0.1', api => startVoting(api));
  }
}