import { iconNode } from "discourse/lib/icon-library";
import { createWidget } from "discourse/widgets/widget";
import { i18n } from "discourse-i18n";

export default createWidget("remove-vote", {
  tagName: "div.remove-vote",

  buildClasses() {
    return "vote-option";
  },

  html() {
    return [iconNode("xmark"), i18n("topic_voting.remove_vote")];
  },

  click() {
    this.sendWidgetAction("removeVote");
  },
});
