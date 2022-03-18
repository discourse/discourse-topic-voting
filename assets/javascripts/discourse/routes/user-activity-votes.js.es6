import UserTopicListRoute from "discourse/routes/user-topic-list";
import UserAction from "discourse/models/user-action";
import I18n from "I18n";

export default UserTopicListRoute.extend({
  userActionType: UserAction.TYPES.topics,

  model() {
    return this.store
      .findFiltered("topicList", {
        filter:
          "topics/voted-by/" + this.modelFor("user").get("username_lower"),
      })
      .then((model) => {
        model.set("emptyState", this.emptyState());
        return model;
      });
  },

  emptyState() {
    const user = this.modelFor("user");
    const title = this.isCurrentUser(user)
      ? I18n.t("voting.no_votes_title_self")
      : I18n.t("voting.no_votes_title_others", { username: user.username });

    return {
      title: title,
      body: "",
    };
  },
});
