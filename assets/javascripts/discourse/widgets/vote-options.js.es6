import { createWidget } from 'discourse/widgets/widget';

export default createWidget('vote-options', {
  tagName: 'div.vote-options',

  buildClasses() {
    return 'voting-popup-menu popup-menu hidden';
  },

  html(attrs){
    var contents = [];
    if (attrs.user_voted){
        contents.push(this.attach('remove-vote', attrs));
    }
    return contents;
  }
});
