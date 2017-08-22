import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('vote-options', {
  tagName: 'div.vote-options',

  buildClasses() {
    return 'voting-popup-menu popup-menu hidden';
  },

  html(attrs){
    var contents = [];

    if (attrs.user_voted){
        contents.push(this.attach('remove-vote', attrs));
    }
    else if (this.currentUser && !attrs.user_voted && (attrs.category.votes_exceeded || this.currentUser.votes_exceeded)) {
      let text = I18n.t('voting.reached_limit');

      if (attrs.category.votes_exceeded) {
        text = I18n.t('voting.reached_category_limit', { categoryName: attrs.category.name });
      }

      contents.push([
          h("div", text),
          h("p",
            h("a",{ href: this.currentUser.get("path") + "/activity/votes" }, I18n.t("voting.list_votes"))
          )
      ]);
    }
    return contents;
  }
});
