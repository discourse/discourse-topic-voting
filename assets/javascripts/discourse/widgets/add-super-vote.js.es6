import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('add-super-vote', {
  tagName: 'div.add-super-vote',

  buildClasses(attrs, state) {
    return 'vote-option';
  },

  html(attrs, state){
    return "Add super vote"
  },

  click(){
    this.sendWidgetAction('upgradeVote');
  }
});