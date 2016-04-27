import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('remove-vote', {
  tagName: 'div.remove-vote',

  buildClasses(attrs, state) {
    return 'vote-option';
  },

  html(attrs, state){
    return ["Remove vote", h("div.vote-option-description", I18n.t("feature_voting.remove_vote_warning"))]
  },

  click(){
    this.sendWidgetAction('removeVote');
  }
});