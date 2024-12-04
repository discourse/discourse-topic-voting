import { createWidget } from "discourse/widgets/widget";
import { iconNode } from "discourse-common/lib/icon-library";
import I18n from "I18n";

export default createWidget("remove-vote", {
  tagName: "div.remove-vote",

  buildClasses() {
    return "vote-option";
  },

  html() {
    return [iconNode("xmark"), I18n.t("topic_voting.remove_vote")];
  },

  click() {
    this.sendWidgetAction("removeVote");
  },
});
