import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('vote-count', {
  tagName: 'div.vote-count-wrapper',

  buildClasses(attrs, state) {

  },

  defaultState() {
    return { voteCount: 0 };
  },

  html(attrs, state){
    state.voteCount = attrs.vote_count;
    var voteCount = h('div.vote-count', state.voteCount);
    if (attrs.single_vote){
      var voteDescription = I18n.t('feature_voting.vote.one');
    }
    else {
      var voteDescription = I18n.t('feature_voting.vote.multiple');
    }
    var voteLabel = h('div.vote-label', voteDescription);
    var whoVoted = [];
    if (Discourse.SiteSettings.feature_voting_show_who_voted) {
      whoVoted = this.attach('small-user-list', {
        users: state.whoVotedUsers,
        addSelf: attrs.liked,
        listClassName: 'who-voted popup-menu voting-popup-menu hidden',
        description: 'feature_voting.who_voted'
      })
    }
    return [voteCount, voteLabel, whoVoted];
  },

  click(attrs){
    if (Discourse.SiteSettings.feature_voting_show_who_voted) {
      this.getWhoVoted();
      $(".who-voted").toggle();
    }
  },

  clickOutside(){
    $(".who-voted").hide();
  },

  getWhoVoted() {
    const { attrs, state } = this;
    var users = attrs.who_voted;
    if (users.length){
      return state.whoVotedUsers = users.map(whoVotedAvatars);
    }
    else{
      return state.whoVotedUsers = [];
    }
  },
});

function whoVotedAvatars(user) {
  return { template: user.user.avatar_template,
           username: user.user.username,
           post_url: user.user.post_url,
           url: Discourse.getURL('/users/') + user.user.username.toLowerCase() };
}