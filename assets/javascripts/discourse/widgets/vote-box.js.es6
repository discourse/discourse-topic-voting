import { createWidget } from 'discourse/widgets/widget';
import { ajax } from 'discourse/lib/ajax';

export default createWidget('vote-box', {
  tagName: 'div.voting-wrapper',
  buildKey: () => 'vote-box',

  buildClasses() {
    if (Discourse.SiteSettings.voting_show_who_voted) { return 'show-pointer'; }
  },

  defaultState() {
    return { allowClick: true, initialVote: false };
  },

  html(attrs){
    var voteCount = this.attach('vote-count', attrs);
    var voteButton = this.attach('vote-button', attrs);
    var voteOptions = this.attach('vote-options', attrs);
    return [voteCount, voteButton, voteOptions];
  },

  addVote(){
    var topic = this.attrs;
    var state = this.state;
    return ajax("/voting/vote", {
      type: 'POST',
      data: {
        topic_id: topic.id
      }
    }).then(function(result) {
      topic.set('vote_count', result.vote_count);
      topic.set('user_voted', true);
      Discourse.User.current().set('votes_exceeded', !result.can_vote);
      topic.set('who_voted', result.who_voted);
      state.allowClick = true;
    }).catch(function(error) {
      console.log(error);
    });
  },

  removeVote(){
    var topic = this.attrs;
    var state = this.state;
    return ajax("/voting/unvote", {
      type: 'POST',
      data: {
        topic_id: topic.id
      }
    }).then(function(result) {
      topic.set('vote_count', result.vote_count);
      topic.set('user_voted', false);
      Discourse.User.current().set('votes_exceeded', !result.can_vote);
      topic.set('who_voted', result.who_voted);
      state.allowClick = true;
    }).catch(function(error) {
      console.log(error);
    });
  }

});
