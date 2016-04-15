import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('vote-button', {
  tagName: 'div.vote-button',

  buildClasses(attrs, state) {
  	var buttonClass = "";
  	if (this.attrs.closed){
      buttonClass = "voting-closed unvote";
    }
    else{
      if (this.attrs.user_voted){
        buttonClass = "unvote";
      }
      else{
        if (this.currentUser.vote_limit){
          buttonClass = "vote-limited unvote";
        }
        else{
          buttonClass = "vote";
        }
      }
    }
    if (Discourse.SiteSettings.feature_voting_show_who_voted) { return buttonClass + ' show-pointer'; }
  },

  html(attrs, state){
  	var buttonTitle = I18n.t('feature_voting.vote_title');
		if (this.attrs.closed){
      buttonTitle = I18n.t('feature_voting.voting_closed_title');
    }
    else{
      if (this.attrs.user_voted){
        buttonTitle = I18n.t('feature_voting.unvote_title');
      }
      else{
        if (this.currentUser.vote_limit){
          buttonTitle = I18n.t('feature_voting.voting_limit');
        }
        else{
          buttonTitle = I18n.t('feature_voting.vote_title');
        }
      }
    }
    return buttonTitle;
  },

  click(){
  	if (!this.attrs.closed && this.parentWidget.state.allowClick){
  		this.parentWidget.state.allowClick = false;
      if (this.attrs.user_voted){
        this.sendWidgetAction('removeVote');
      }
      else{
        if (!this.currentUser.vote_limit){
		  		this.sendWidgetAction('addVote');
        }
      }
    }
	  $(".vote-options").toggle();
  },

  clickOutside(){
  	$(".vote-options").hide();
  }
});