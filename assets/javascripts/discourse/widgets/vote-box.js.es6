import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('vote-box', {
  tagName: 'div.voting-wrapper',

  buildClasses(attrs, state) {
    if (Discourse.SiteSettings.feature_voting_show_who_voted) { return 'show-pointer'; }
  },

  defaultState() {
    return { whoVotedUsers: [], allowClick: true };
  },

  html(attrs, state){
    var voteCount = this.attach('vote-count', attrs);
    var voteButton = this.attach('vote-button', attrs);
    var voteOptions = this.attach('vote-options', {
      listClassName: 'popup-menu',
      addSelf: attrs
    });
    return [voteCount, voteButton];
  },

  addVote(attrs){
    var topic = this.attrs;
    var state = this.state;
    return Discourse.ajax("/voting/vote", {
      type: 'POST',
      data: {
        topic_id: topic.id,
        user_id: Discourse.User.current().id
      }
    }).then(function(result) {
      topic.set('vote_count', result.vote_count);
      topic.set('user_voted', true);
      Discourse.User.current().set('vote_limit', result.vote_limit);
      state.allowClick = true;
    }).catch(function(error) {
      console.log(error);
    });
  },

  removeVote(attrs){
    var topic = this.attrs;
    var state = this.state;
    return Discourse.ajax("/voting/unvote", {
      type: 'POST',
      data: {
        topic_id: topic.id,
        user_id: Discourse.User.current().id
      }
    }).then(function(result) {
      topic.set('vote_count', result.vote_count);
      topic.set('user_voted', false);
      Discourse.User.current().set('vote_limit', result.vote_limit);
      state.allowClick = true;
    }).catch(function(error) {
      console.log(error);
    });
  },

  addSuperVote(){

  },

  removeSuperVote(){

  }
});