import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('vote-options', {
  tagName: 'div.vote-options',

  buildClasses(attrs, state) {
    return 'voting-popup-menu popup-menu hidden';
  },

  defaultState(attrs) {
    return {  };
  },

  html(attrs, state){
    var addVote = this.attach('add-vote', attrs);
    var removeVote = this.attach('remove-vote', attrs);
    var addSuperVote = this.attach('add-super-vote', attrs);
    var removeSuperVote = this.attach('remove-super-vote', attrs);
    var upgradeVote = this.attach('upgrade-vote', attrs);
    return [addVote, removeVote, addSuperVote, removeSuperVote, upgradeVote];
  },

  click(){
    if (!this.state.votingClosed){
      if (this.state.userVoted){

      }
      else{
        if (currentUser.vote_limit){

        }
        else{
          this.sendWidgetAction('vote');
        }
      }
      this.sendWidgetAction('otherAction');
    }
  }
});