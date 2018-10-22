import { createWidget } from "discourse/widgets/widget";

export default createWidget("remove-vote", {
  tagName: "div.remove-vote",

  buildClasses() {
    return "vote-option";
  },

  html() {
    return ["Remove vote"];
  },

  click() {
    this.sendWidgetAction("removeVote");
  }
});
