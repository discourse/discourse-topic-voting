import { createWidget } from 'discourse/widgets/widget';

createWidget('who-voted', {
  tagName: 'div.who-voted',

  html(attrs, state) {
    const contents = this.attach('small-user-list', {
      users: this.getWhoVoted(),
      addSelf: attrs.liked,
      listClassName: 'who-voted',
      description: 'feature_voting.who_voted'
    })
    return contents;
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