import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('upgrade-vote', {
  tagName: 'div.upgrade-vote',

  buildClasses(attrs, state) {
    return 'vote-option';
  },

  defaultState(attrs) {
    return {  };
  },

  html(attrs, state){
    return "Hello World"
  },

  click(){
    this.sendWidgetAction('');
  }
});