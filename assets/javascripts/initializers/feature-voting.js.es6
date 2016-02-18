import TopicRoute from 'discourse/routes/topic';

export default {
  name: 'feature-voting',
  initialize(){

    TopicRoute.reopen({
      actions: {
        vote() {
          var topic_id = this.modelFor('topic').id;
          var user_id = Discourse.User.current().id;
          const self = this;
          return Discourse.ajax("/voting/vote", {
            type: 'POST',
            data: {
              topic_id: topic_id,
              user_id: user_id
            }
          }).then(function(result) {

          }).catch(function(error) {
            popupAjaxError(error);
          });
        },
        unvote() {
          console.log("unvoted");
          var topic_id = this.modelFor('topic').id;
          var user_id = Discourse.User.current().id;
          const self = this;
          return Discourse.ajax("/voting/unvote", {
            type: 'POST',
            data: {
              topic_id: topic_id,
              user_id: user_id
            }
          }).then(function(result) {

          }).catch(function(error) {
            popupAjaxError(error);
          });
        }
      }
    })
  }
}