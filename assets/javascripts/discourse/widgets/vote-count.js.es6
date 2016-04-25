import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('vote-count', {
  tagName: 'div.vote-count-wrapper',

  buildClasses(attrs, state) {
    if (!attrs.has_votes){
      return "no-votes";
    }
  },

  defaultState() {
    return { voteCount: 0, whoVotedUsers: [], whoSuperVotedUsers: [] };
  },

  html(attrs, state){
    if (!attrs.has_votes){
      return
    }
    var voteCount = h('div.vote-count', attrs.vote_count.toString());
    if (attrs.single_vote){
      var voteDescription = I18n.t('feature_voting.vote.one');
    }
    else {
      var voteDescription = I18n.t('feature_voting.vote.multiple');
    }
    var voteLabel = h('div.vote-label', voteDescription);
    var whoVoted = [];
    if (Discourse.SiteSettings.feature_voting_show_who_voted && attrs.has_votes) {
      whoVoted = this.attach('small-user-list', {
        users: this.state.whoVotedUsers,
        addSelf: attrs.liked,
        listClassName: 'regular-votes',
        description: 'feature_voting.who_voted'
      })
    }
    if (attrs.single_super_vote){
      var superVoteDescription = I18n.t('feature_voting.vote.one');
    }
    else {
      var superVoteDescription = I18n.t('feature_voting.vote.multiple');
    }
    var superVoteCount = [];
    var whoSuperVoted = [];
    if (Discourse.SiteSettings.feature_voting_show_who_voted && attrs.has_super_votes) {
      if (attrs.single_super_vote){
        var superVoteDescription = I18n.t('feature_voting.vote.one');
      }
      else {
        var superVoteDescription = I18n.t('feature_voting.vote.multiple');
      }
      superVoteCount = h('div.super-vote-count', [attrs.super_vote_count.toString(), superVoteDescription]);
      var whoSuperVoted = [];
      whoSuperVoted = this.attach('small-user-list', {
        users: this.state.whoSuperVotedUsers,
        addSelf: attrs.liked,
        listClassName: 'super-votes',
        description: 'feature_voting.who_super_voted'
      })
    }
    return [voteCount, voteLabel, h('div.who-voted.popup-menu.voting-popup-menu.hidden', [superVoteCount, whoSuperVoted, whoVoted])];
  },

  click(){
    if (Discourse.SiteSettings.feature_voting_show_who_voted && this.attrs.has_votes) {
      this.getWhoVoted();
      $(".who-voted").toggle();
    }
  },

  clickOutside(){
    $(".who-voted").hide();
  },

  getWhoVoted() {
    var users = this.attrs.who_voted;
    var superUsers = this.attrs.who_super_voted;
    if (users.length){
      this.state.whoVotedUsers = users.map(whoVotedAvatars);
    }
    else{
      this.state.whoVotedUsers = [];
    }

    if (superUsers.length){
      this.state.whoSuperVotedUsers = superUsers.map(whoVotedAvatars);
    }
    else{
      this.state.whoSuperVotedUsers = [];
    }
  },
});

function whoVotedAvatars(user) {
  return { template: user.user.avatar_template,
           username: user.user.username,
           post_url: user.user.post_url,
           url: Discourse.getURL('/users/') + user.user.username.toLowerCase() };
}