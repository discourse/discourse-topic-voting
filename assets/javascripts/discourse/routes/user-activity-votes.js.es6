import ViewingActionType from "discourse/mixins/viewing-action-type";

export default Discourse.Route.extend(ViewingActionType, {
  model() {
    return this.modelFor("user").get("stream");
  },

  afterModel() {
  	console.log(this);
    return this.modelFor("user").get("stream").filterBy(1);
  },

  renderTemplate() {
    this.render("user_stream");
  },

  setupController(controller, model) {
    controller.set("model", model);
    this.viewingActionType(1);
  },

  actions: {

    didTransition() {
      this.controllerFor("user-activity")._showFooter();
      return true;
    },

    removeBookmark(userAction) {
      var user = this.modelFor("user");
      Discourse.Post.updateBookmark(userAction.get("post_id"), false)
        .then(function() {
          // remove the user action from the stream
          user.get("stream").remove(userAction);
          // update the counts
          user.get("stats").forEach(function (stat) {
            if (stat.get("action_type") === userAction.action_type) {
              stat.decrementProperty("count");
            }
          });
        });
    },

  }
});