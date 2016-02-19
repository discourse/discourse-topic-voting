import TopicRoute from 'discourse/routes/topic';

export default {
  name: 'feature-voting',
  initialize(){

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
            topic.reload();
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
            topic.reload();
          }).catch(function(error) {
            console.log(error);
          });
        }
      }
    })
  }
}