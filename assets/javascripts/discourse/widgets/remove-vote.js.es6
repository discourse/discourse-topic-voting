import { createWidget } from "discourse/widgets/widget";
import { iconNode } from "discourse-common/lib/icon-library";

export default createWidget("remove-vote", {
  tagName: "div.remove-vote",

  buildClasses() {
    return "vote-option";
  },

  html() {
    return [iconNode("times"), I18n.t("voting.remove_vote")];
  },

  click() {
    this.sendWidgetAction("removeVote");
  }
});
