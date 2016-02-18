import TopicRoute from 'discourse/routes/topic';

export default {
  name: 'feature-voting',
  initialize(){

    TopicRoute.reopen({
      actions: {
        vote() {
          var topic = this.modelFor('topic');
          var topic_id = topic.id;
          var user_id = Discourse.User.current().id;
          const self = this;
          return Discourse.ajax("/voting/vote", {
            type: 'POST',
            data: {
              topic_id: topic_id,
              user_id: user_id
            }
          }).then(function(result) {
            topic.reload();

          }).catch(function(error) {
            console.log(error);
          });
        },
        unvote() {
          var topic = this.modelFor('topic');
          var topic_id = topic.id;
          var user_id = Discourse.User.current().id;
          const self = this;
          return Discourse.ajax("/voting/unvote", {
            type: 'POST',
            data: {
              topic_id: topic_id,
              user_id: user_id
            }
          }).then(function(result) {
            topic.reload();
          }).catch(function(error) {
            console.log(error);
          });
        }
      }
    })
  }
}