import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('upgrade-vote', {
  tagName: 'div.upgrade-vote',

  buildClasses(attrs, state) {
    return 'vote-option';
  },

  html(attrs, state){
    return "Would you like to make that a <em>super vote</em>?<br>Yes!"
  },

  click(){
    this.sendWidgetAction('upgradeVote');
  }
});