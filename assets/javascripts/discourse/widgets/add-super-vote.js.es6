import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('add-super-vote', {
  tagName: 'div.add-super-vote',

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