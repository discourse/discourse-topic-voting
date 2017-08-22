import { createWidget } from 'discourse/widgets/widget';
import showModal from 'discourse/lib/show-modal';

export default createWidget('vote-button', {
  tagName: 'div.vote-button',

  buildClasses(attrs) {
    var buttonClass = "";
    if (attrs.closed){
      buttonClass = "voting-closed";
    }
    else{
      if (!attrs.user_voted){
        buttonClass = "nonvote";
      }
      else{
        if (this.currentUser && this.currentUser.votes_exceeded){
          buttonClass = "vote-limited nonvote";
        }
        else{
          buttonClass = "vote";
        }
      }
    }
    if (this.siteSettings.voting_show_who_voted) {
      buttonClass += ' show-pointer';
    }
    return buttonClass;
  },

  html(attrs){
    var buttonTitle = I18n.t('voting.vote_title');
    if (!this.currentUser){
      buttonTitle = I18n.t('log_in');
    }
    else{
      if (attrs.closed){
        buttonTitle = I18n.t('voting.voting_closed_title');
      }
      else{
        if (attrs.user_voted){
          buttonTitle = I18n.t('voting.voted_title');
        }
        else{
          if (this.currentUser && (attrs.category.votes_exceeded || this.currentUser.votes_exceeded)){
            buttonTitle = I18n.t(`voting.voting_limit`);
          }
          else{
            buttonTitle = I18n.t('voting.vote_title');
          }
        }
      }
    }
    return buttonTitle;
  },

  click(){
    if (!this.currentUser){
      showModal('login');
    }

    let votesExceeded = this.attrs.category.votes_exceeded || this.currentUser.votes_exceeded;

    if (!this.attrs.closed && !votesExceeded && this.parentWidget.state.allowClick && !this.attrs.user_voted){
      this.parentWidget.state.allowClick = false;
      this.parentWidget.state.initialVote = true;
      this.sendWidgetAction('addVote');
    }

    if (this.attrs.user_voted || votesExceeded) {
      $(".vote-options").toggle();
    }
  },

  clickOutside(){
    $(".vote-options").hide();
    this.parentWidget.state.initialVote = false;
  }
});
