import { h } from "virtual-dom";
import cookie from "discourse/lib/cookie";
import { applyBehaviorTransformer } from "discourse/lib/transformer";
import { createWidget } from "discourse/widgets/widget";
import { i18n } from "discourse-i18n";

export default createWidget("vote-button", {
  tagName: "div",

  buildClasses(attrs) {
    let buttonClass = "";
    if (attrs.closed) {
      buttonClass = "voting-closed";
    } else {
      if (!attrs.user_voted) {
        buttonClass = "nonvote";
      } else {
        if (this.currentUser && this.currentUser.votes_exceeded) {
          buttonClass = "vote-limited nonvote";
        } else {
          buttonClass = "vote";
        }
      }
    }
    if (this.siteSettings.topic_voting_show_who_voted) {
      buttonClass += " show-pointer";
    }
    return buttonClass;
  },

  buildButtonTitle(attrs) {
    if (this.currentUser) {
      if (attrs.closed) {
        return i18n("topic_voting.voting_closed_title");
      }

      if (attrs.user_voted) {
        return i18n("topic_voting.voted_title");
      }

      if (this.currentUser.votes_exceeded) {
        return i18n("topic_voting.voting_limit");
      }

      return i18n("topic_voting.vote_title");
    }

    if (attrs.vote_count) {
      return i18n("topic_voting.anonymous_button", {
        count: attrs.vote_count,
      });
    }

    return i18n("topic_voting.anonymous_button", { count: 1 });
  },

  html(attrs) {
    return h(
      "button",
      {
        attributes: {
          title: this.currentUser
            ? i18n("topic_voting.votes_left_button_title", {
                count: this.currentUser.votes_left,
              })
            : "",
        },
        className: "btn btn-primary vote-button",
      },
      this.buildButtonTitle(attrs)
    );
  },

  click() {
    applyBehaviorTransformer("topic-vote-button-click", () => {
      if (!this.currentUser) {
        this.sendWidgetAction("showLogin");
        cookie("destination_url", window.location.href, { path: "/" });
        return;
      }
      if (
        !this.attrs.closed &&
        this.parentWidget.state.allowClick &&
        !this.attrs.user_voted &&
        !this.currentUser.votes_exceeded
      ) {
        this.parentWidget.state.allowClick = false;
        this.parentWidget.state.initialVote = true;
        this.sendWidgetAction("addVote");
      }
      if (this.attrs.user_voted || this.currentUser.votes_exceeded) {
        document.querySelector(".vote-options").classList.toggle("hidden");
      }
    });
  },

  clickOutside() {
    document.querySelector(".vote-options").classList.add("hidden");
    this.parentWidget.state.initialVote = false;
  },
});
