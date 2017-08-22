import { createWidget } from 'discourse/widgets/widget';
import { ajax } from 'discourse/lib/ajax';
import RawHtml from 'discourse/widgets/raw-html';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import Category from 'discourse/models/category';

export default createWidget('vote-box', {
  tagName: 'div.voting-wrapper',
  buildKey: () => 'vote-box',

  buildClasses() {
    if (this.siteSettings.voting_show_who_voted) { return 'show-pointer'; }
  },

  defaultState() {
    return { allowClick: true, initialVote: false };
  },

  html(attrs, state){
    var voteCount = this.attach('vote-count', attrs);
    var voteButton = this.attach('vote-button', attrs);
    var voteOptions = this.attach('vote-options', attrs);
    let contents = [voteCount, voteButton, voteOptions];

    if (state.votesAlert > 0) {
      let text = "voting.votes_left";
      let textParams = {
        count: state.votesAlert,
        path: this.currentUser.get("path") + "/activity/votes",
      }

      if (attrs.category.has_vote_limit) {
        text = "voting.votes_left_category";
        textParams['categoryName'] = attrs.category.name;
      }

      const html = "<div class='voting-popup-menu vote-options popup-menu'>" + I18n.t(text, textParams) + "</div>";
      contents.push(new RawHtml({html}));
    }

    return contents;

  },

  hideVotesAlert() {
    if (this.state.votesAlert) {
      this.state.votesAlert = null;
      this.scheduleRerender();
    }
  },

  click() {
    this.hideVotesAlert();
  },

  clickOutside(){
    this.hideVotesAlert();
  },

  addVote(){
    var topic = this.attrs;
    var state = this.state;
    return ajax("/voting/vote", {
      type: 'POST',
      data: {
        topic_id: topic.id
      }
    }).then(result => {
      this.updateTopic(result);
      this.updateCategory(result);
      this.updateUser(result);

      if (result.alert) {
        state.votesAlert = result.votes_left;
      }

      state.allowClick = true;
      this.scheduleRerender();
    }).catch(popupAjaxError);
  },

  removeVote(){
    const topic = this.attrs;
    const state = this.state;

    return ajax("/voting/unvote", {
      type: 'POST',
      data: {
        topic_id: topic.id
      }
    }).then(result => {
      this.updateTopic(result);
      this.updateCategory(result);
      this.updateUser(result);

      state.allowClick = true;
      this.scheduleRerender();
    }).catch(popupAjaxError);
  },

  updateCategory(result) {
    const categoryId = this.attrs.category_id;
    const category = Category.findById(categoryId);

    if (result.hasOwnProperty('category_votes_exceeded')) {
      category.set('votes_exceeded', result.category_votes_exceeded);
    }
  },

  updateTopic(result) {
    const topic = this.attrs;
    topic.set('vote_count', result.vote_count);
    topic.set('user_voted', result.user_voted);
    topic.set('who_voted', result.who_voted);
  },

  updateUser(result) {
    this.currentUser.set('votes_exceeded', result.user_votes_exceeded);
  }
});
