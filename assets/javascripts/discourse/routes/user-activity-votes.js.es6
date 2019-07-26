import UserTopicListRoute from "discourse/routes/user-topic-list";
import UserAction from "discourse/models/user-action";

export default UserTopicListRoute.extend({
  userActionType: UserAction.TYPES.topics,

  model() {
    const username = this.modelFor("user").username_lower;
    return this.store.findFiltered("topicList", {
      filter: `topics/voted-by/${username}`
    });
  }
});
