import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('vote-box', {
  tagName: 'div.voting-wrapper',

  buildClasses(attrs, state) {
    if (Discourse.SiteSettings.feature_voting_show_who_voted) { return 'show-pointer'; }
  },

  defaultState() {
    return { whoVotedUsers: [] };
  },

  html(attrs, state){
    var voteCount = this.attach('vote-count', attrs);
    var voteButton = this.attach('vote-button', attrs);
    var voteOptions = this.attach('vote-options', {
      listClassName: 'popup-menu',
      addSelf: attrs
    });
    return [voteCount, voteButton, voteOptions];
  },

  vote(){
    this.state.voteCount++;
  },

  unvote(){
    this.state.voteCount--;
  }
});