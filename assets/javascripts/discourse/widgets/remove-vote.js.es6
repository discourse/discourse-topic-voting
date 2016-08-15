import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('remove-vote', {
  tagName: 'div.remove-vote',

  buildClasses(attrs, state) {
    return 'vote-option';
  },

  html(attrs, state){
    var voteDescription = []
    if (this.siteSettings.feature_voting_allow_super_voting && attrs.user_super_voted) {
      voteDescription = h("div.vote-option-description", I18n.t("feature_voting.remove_vote_warning"));
    }
    return ["Remove vote", voteDescription];
  },

  click(){
    this.sendWidgetAction('removeVote');
  }
});
