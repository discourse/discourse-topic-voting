import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('add-super-vote', {
  tagName: 'div.add-super-vote',

  buildClasses(attrs, state) {
    return 'vote-option';
  },

  html(attrs, state){
    var user = this.currentUser;
    var superVotesRemaining = user.super_vote_count - user.super_vote_limit;
    if (superVotesRemaining == 1){
      var superVoteDescription = I18n.t("feature_voting.super_votes_remaining.singular");
    }
    else{
      var superVoteDescription = I18n.t("feature_voting.super_votes_remaining.plural", {number: superVotesRemaining});
    }
    return ["Add super vote", h("div.vote-option-description", superVoteDescription)];
  },

  click(){
    this.sendWidgetAction('upgradeVote');
  }
});