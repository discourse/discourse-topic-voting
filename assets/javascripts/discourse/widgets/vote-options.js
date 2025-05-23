import { h } from "virtual-dom";
import { createWidget } from "discourse/widgets/widget";
import { i18n } from "discourse-i18n";

export default createWidget("vote-options", {
  tagName: "div.vote-options",

  buildClasses() {
    return "voting-popup-menu popup-menu hidden";
  },

  html(attrs) {
    let contents = [];

    if (attrs.user_voted) {
      contents.push(this.attach("remove-vote", attrs));
    } else if (
      this.currentUser &&
      this.currentUser.votes_exceeded &&
      !attrs.user_voted
    ) {
      contents.push([
        h("div", i18n("topic_voting.reached_limit")),
        h(
          "p",
          h(
            "a",
            { href: this.currentUser.get("path") + "/activity/votes" },
            i18n("topic_voting.list_votes")
          )
        ),
      ]);
    }
    return contents;
  },
});
