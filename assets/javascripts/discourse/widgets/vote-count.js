import { h } from "virtual-dom";
import { ajax } from "discourse/lib/ajax";
import cookie from "discourse/lib/cookie";
import getURL from "discourse/lib/get-url";
import { createWidget } from "discourse/widgets/widget";

export default createWidget("vote-count", {
  tagName: "div.vote-count-wrapper",
  buildKey: () => "vote-count",

  buildClasses() {
    if (this.attrs.vote_count === 0) {
      return "no-votes";
    }
  },

  defaultState() {
    return { whoVotedUsers: null };
  },

  html(attrs) {
    let voteCount = h("div.vote-count", attrs.vote_count.toString());
    let whoVoted = null;
    if (
      this.siteSettings.topic_voting_show_who_voted &&
      this.state.whoVotedUsers &&
      this.state.whoVotedUsers.length > 0
    ) {
      whoVoted = this.attach("small-user-list", {
        users: this.state.whoVotedUsers,
        addSelf: attrs.liked,
        listClassName: "regular-votes",
      });
    }

    let buffer = [voteCount];
    if (whoVoted) {
      buffer.push(h("div.who-voted.popup-menu.voting-popup-menu", [whoVoted]));
    }
    return buffer;
  },

  click() {
    if (!this.currentUser) {
      this.sendWidgetAction("showLogin");
      cookie("destination_url", window.location.href, { path: "/" });
      return;
    }

    if (
      this.siteSettings.topic_voting_show_who_voted &&
      this.attrs.vote_count > 0
    ) {
      if (this.state.whoVotedUsers === null) {
        return this.getWhoVoted();
      } else {
        const whoVotedElement = document.querySelector(".who-voted");
        whoVotedElement.style.display =
          whoVotedElement.style.display === "none" ? "block" : "none";
      }
    }
  },

  clickOutside() {
    const whoVotedElement = document.querySelector(".who-voted");
    if (whoVotedElement) {
      whoVotedElement.style.display = "none";
    }
  },

  getWhoVoted() {
    return ajax("/voting/who", {
      type: "GET",
      data: {
        topic_id: this.attrs.id,
      },
    }).then((users) => {
      this.state.whoVotedUsers = users.map(whoVotedAvatars);
    });
  },
});

function whoVotedAvatars(user) {
  return {
    template: user.avatar_template,
    username: user.username,
    post_url: user.post_url,
    url: getURL("/u/") + user.username.toLowerCase(),
  };
}
