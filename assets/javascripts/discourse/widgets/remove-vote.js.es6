import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('remove-super-vote', {
  tagName: 'div.remove-super-vote',

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