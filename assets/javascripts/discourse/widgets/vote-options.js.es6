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
    console.log(this);
    return "Hello World"
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