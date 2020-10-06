import I18n from "I18n";
import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";

export default createWidget("vote-button", {
  tagName: "div",

  buildClasses(attrs) {
    var buttonClass = "";
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
    if (this.siteSettings.voting_show_who_voted) {
      buttonClass += " show-pointer";
    }
    return buttonClass;
  },

  buttonTitle(attrs) {
    if (this.currentUser) {
      if (attrs.closed) {
        return I18n.t("voting.voting_closed_title");
      }

      if (attrs.user_voted) {
        return I18n.t("voting.voted_title");
      }

      if (this.currentUser.votes_exceeded) {
        return I18n.t("voting.voting_limit");
      }

      return I18n.t("voting.vote_title");
    }

    if (attrs.vote_count) {
      return I18n.t("voting.anonymous_button", {
        count: attrs.vote_count,
      });
    }

    return I18n.t("voting.anonymous_button", { count: 1 });
  },

  html(attrs) {
    return h(
      "button",
      {
        attributes: {
          title: this.currentUser
            ? I18n.t("voting.votes_left_button_title", {
                count: this.currentUser.votes_left,
              })
            : "",
        },
        className: "btn btn-primary vote-button",
      },
      this.buttonTitle(attrs)
    );
  },

  click() {
    if (!this.currentUser) {
      this.sendWidgetAction("showLogin");
      $.cookie("destination_url", window.location.href);
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
      $(".vote-options").toggleClass("hidden");
    }
  },

  clickOutside() {
    $(".vote-options").addClass("hidden");
    this.parentWidget.state.initialVote = false;
  },
});
