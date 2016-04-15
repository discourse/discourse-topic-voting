import { withPluginApi } from 'discourse/lib/plugin-api';
import TopicRoute from 'discourse/routes/topic';
import TopicController from 'discourse/controllers/topic';
import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

function  startVoting(api){
  TopicRoute.reopen({
    actions: {
      vote() {
        var topic = this.modelFor('topic');
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

        }).catch(function(error) {
          console.log(error);
        });
      },
      unvote() {
        var topic = this.modelFor('topic');
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
        }).catch(function(error) {
          console.log(error);
        });
      }
    }
  })

  TopicController.reopen({
    actions: {
      showWhoVoted() {
        this.model.set('whoVotedVisible', true);
      },

      hideWhoVoted() {
        this.model.set('whoVotedVisible', false);
      }
    }
  })

  api.createWidget('vote-box', {
    tagName: 'div.voting-wrapper',

    buildClasses(attrs, state) {
      if (Discourse.SiteSettings.feature_voting_show_who_voted) { return 'show-pointer'; }
    },

    defaultState() {
      return { whoVotedUsers: [] };
    },

    html(attrs, state){
      var voteCount = h('div.vote-count', attrs.vote_count);
      if (attrs.single_vote){
        var voteDescription = I18n.t('feature_voting.vote.one');
      }
      else {
        var voteDescription = I18n.t('feature_voting.vote.multiple');
      }
      var voteLabel = h('div.vote-label', voteDescription);
      var whoVoted = this.attach('small-user-list', {
        users: state.whoVotedUsers,
        addSelf: attrs.liked,
        listClassName: 'who-voted popup-menu hidden',
        description: 'feature_voting.who_voted'
      })
      if (!Discourse.SiteSettings.feature_voting_show_who_voted) {
        whoVoted = [];
      }
      return [voteCount, voteLabel, whoVoted];
    },
    click(attrs){
      if (Discourse.SiteSettings.feature_voting_show_who_voted) {
        this.getWhoVoted();
        $(".who-voted").show();
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
    }
  });

  function whoVotedAvatars(user) {
    return { template: user.user.avatar_template,
             username: user.user.username,
             post_url: user.user.post_url,
             url: Discourse.getURL('/users/') + user.user.username_lower };
  }

}

function whoVotedAvatars(user) {
  return { template: user.user.avatar_template,
           username: user.user.username,
           post_url: user.user.post_url,
           url: Discourse.getURL('/users/') + user.user.username_lower };
}

export default {
  name: 'feature-voting',
  initialize: function() {
    withPluginApi('0.1', api => startVoting(api));
  }
}