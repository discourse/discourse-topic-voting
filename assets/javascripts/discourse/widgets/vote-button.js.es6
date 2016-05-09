import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';
import showModal from 'discourse/lib/show-modal';

export default createWidget('vote-button', {
  tagName: 'div.vote-button',

  buildClasses(attrs, state) {
  	var buttonClass = "";
  	if (attrs.closed){
      buttonClass = "voting-closed nonvote";
    }
    else{
      if (attrs.user_voted && !attrs.user_super_voted){
        buttonClass = "nonvote";
      }
      else if(attrs.user_voted && attrs.user_super_voted && this.siteSettings.feature_voting_allow_super_voting){
      	buttonClass = "nonvote supervote";
      }
      else{
        if (this.currentUser && this.currentUser.vote_limit){
          buttonClass = "vote-limited nonvote";
        }
        else{
          buttonClass = "vote";
        }
      }
    }
    if (Discourse.SiteSettings.feature_voting_show_who_voted) { 
      buttonClass += ' show-pointer';
    }
    return buttonClass
  },

  html(attrs, state){
  	var buttonTitle = I18n.t('feature_voting.vote_title');
    if (!this.currentUser){
      buttonTitle = I18n.t('log_in');
    }
    else{
  		if (attrs.closed){
        buttonTitle = I18n.t('feature_voting.voting_closed_title');
      }
      else{
        if (attrs.user_voted){
          buttonTitle = I18n.t('feature_voting.voted_title');
        }
        else{
          if (this.currentUser && this.currentUser.vote_limit){
            buttonTitle = I18n.t('feature_voting.voting_limit');
          }
          else{
            buttonTitle = I18n.t('feature_voting.vote_title');
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
  	if (!this.attrs.closed && this.parentWidget.state.allowClick && !this.attrs.user_voted && !this.currentUser.vote_limit){
    	this.parentWidget.state.allowClick = false;
    	this.parentWidget.state.initialVote = true;
  		this.sendWidgetAction('addVote');
    }
    if ((this.parentWidget.state.initialVote && this.currentUser.super_vote_limit) || (this.parentWidget.state.initialVote && !this.siteSettings.feature_voting_allow_super_voting)){
      this.parentWidget.state.initialVote = false;
    }
    else {
      $(".vote-options").toggle();
    }
  },

  clickOutside(){
  	$(".vote-options").hide();
  	this.parentWidget.state.initialVote = false;
  }
});