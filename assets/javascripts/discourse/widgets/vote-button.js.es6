import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('vote-button', {
  tagName: 'div.vote-button',

  buildClasses(attrs, state) {
    if (Discourse.SiteSettings.feature_voting_show_who_voted) { return 'show-pointer'; }
  },

  defaultState(attrs) {
    return { 
    	userVoted: attrs.user_voted, 
    	superVote: false, 
    	votingClosed: attrs.closed, 
    	buttonTitle: I18n.t('feature_voting.vote_title')
    };
  },

  html(attrs, state){
  	this.refreshButtonTitle();
    return state.buttonTitle;
  },

  click(){
  	$(".vote-options").toggle();
  },

  clickOutside(){
  	$(".vote-options").hide();
  },

  refreshButtonTitle(){
  	const currentUser = this.container.lookup('current-user:main');
    var buttonTitle = I18n.t('feature_voting.vote_title');
		if (this.state.votingClosed){
      buttonTitle = I18n.t('feature_voting.voting_closed_title');
    }
    else{
      if (this.state.userVoted){
        buttonTitle = I18n.t('feature_voting.unvote_title');
      }
      else{
        if (currentUser.vote_limit){
          buttonTitle = I18n.t('feature_voting.voting_limit');
        }
        else{
          buttonTitle = I18n.t('feature_voting.vote_title');
        }
      }
    }
    this.state.buttonTitle = buttonTitle;
  }
});