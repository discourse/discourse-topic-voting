import { withPluginApi } from 'discourse/lib/plugin-api';
import TopicRoute from 'discourse/routes/topic';
import UserAction from "discourse/models/user-action";

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

  UserAction.reopen({
    voteType: Em.computed.equal('action_type', 100)
  })
}

export default {
  name: 'feature-voting',
  initialize: function() {
    withPluginApi('0.1', api => startVoting(api));
  }
}