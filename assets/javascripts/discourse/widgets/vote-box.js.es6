import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';
import { ajax } from 'discourse/lib/ajax';

export default createWidget('vote-box', {
  tagName: 'div.voting-wrapper',
  buildKey: () => 'vote-box',

  buildClasses(attrs, state) {
    if (Discourse.SiteSettings.feature_voting_show_who_voted) { return 'show-pointer'; }
  },

  defaultState() {
    return { allowClick: true, initialVote: false };
  },

  html(attrs, state){
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
        topic_id: topic.id,
        user_id: Discourse.User.current().id
      }
    }).then(function(result) {
      topic.set('vote_count', result.vote_count);
      topic.set('has_votes', true);
      topic.set('user_voted', true);
      Discourse.User.current().set('vote_limit', result.vote_limit);
      Discourse.User.current().set('super_votes_remaining', result.super_votes_remaining);
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
        topic_id: topic.id,
        user_id: Discourse.User.current().id
      }
    }).then(function(result) {
      topic.set('vote_count', result.vote_count);
      topic.set('super_vote_count', result.super_vote_count);
      if (result.vote_count == 0){
        topic.set('has_votes', false);
      }
      if (result.super_vote_count == 0){
        topic.set('has_super_votes', false);
      }
      topic.set('user_voted', false);
      topic.set('user_super_voted', false);
      Discourse.User.current().set('vote_limit', result.vote_limit);
      Discourse.User.current().set('super_vote_limit', result.super_vote_limit);
      Discourse.User.current().set('super_votes_remaining', result.super_votes_remaining);
      topic.set('who_voted', result.who_voted);
      topic.set('who_super_voted', result.who_super_voted);
      state.allowClick = true;
    }).catch(function(error) {
      console.log(error);
    });
  },

  upgradeVote(){
    var topic = this.attrs;
    var state = this.state;
    return ajax("/voting/upgrade", {
      type: 'POST',
      data: {
        topic_id: topic.id,
        user_id: Discourse.User.current().id
      }
    }).then(function(result) {
      topic.set('vote_count', result.vote_count);
      topic.set('super_vote_count', result.super_vote_count);
      topic.set('has_super_votes', true);
      topic.set('user_super_voted', true);
      Discourse.User.current().set('super_vote_limit', result.super_vote_limit);
      Discourse.User.current().set('super_votes_remaining', result.super_votes_remaining);
      topic.set('who_super_voted', result.who_super_voted);
      state.allowClick = true;
    }).catch(function(error) {
      console.log(error);
    });
  },

  downgradeVote(){
    var topic = this.attrs;
    var state = this.state;
    return ajax("/voting/downgrade", {
      type: 'POST',
      data: {
        topic_id: topic.id,
        user_id: Discourse.User.current().id
      }
    }).then(function(result) {
      topic.set('vote_count', result.vote_count);
      topic.set('super_vote_count', result.super_vote_count);
      if (result.super_vote_count == 0){
        topic.set('has_super_votes', false);
      }
      topic.set('user_super_voted', false);
      Discourse.User.current().set('super_vote_limit', result.super_vote_limit);
      Discourse.User.current().set('super_votes_remaining', result.super_votes_remaining);
      topic.set('who_super_voted', result.who_super_voted);
      state.allowClick = true;
    }).catch(function(error) {
      console.log(error);
    });
  }
});
