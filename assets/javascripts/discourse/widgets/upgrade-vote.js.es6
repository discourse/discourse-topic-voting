import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('upgrade-vote', {
  tagName: 'div.upgrade-vote',

  buildClasses(attrs, state) {
    return 'vote-option';
  },

  html(attrs, state){
    var upgradeQuestion = h('div.upgrade-question', I18n.t('feature_voting.upgrade_question'));
    var upgradeAnswer = h('div.upgrade-answer', [h('i.fa.fa-star', ""), I18n.t('feature_voting.upgrade_answer')]);
    return [upgradeQuestion, upgradeAnswer];
  },

  click(){
    this.sendWidgetAction('upgradeVote');
  }
});