import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('remove-vote', {
  tagName: 'div.remove-vote',

  buildClasses(attrs, state) {
    return 'vote-option';
  },

  defaultState(attrs) {
    return {  };
  },

  html(attrs, state){
    return "Remove vote"
  },

  click(){
    this.sendWidgetAction('removeVote');
  }
});