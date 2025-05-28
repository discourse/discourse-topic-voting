import Component from "@ember/component";
import { LinkTo } from "@ember/routing";
import { classNames, tagName } from "@ember-decorators/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

@tagName("")
@classNames("user-activity-bottom-outlet", "user-voted-topics")
export default class UserVotedTopics extends Component {
  <template>
    {{#if this.siteSettings.topic_voting_show_votes_on_profile}}
      <LinkTo @route="userActivity.votes">
        {{icon "heart"}}
        {{i18n "topic_voting.vote_title_plural"}}
      </LinkTo>
    {{/if}}
  </template>
}
