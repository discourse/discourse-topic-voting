import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import MountWidget from "discourse/components/mount-widget";
import routeAction from "discourse/helpers/route-action";

@tagName("div")
@classNames("topic-above-post-stream-outlet", "topic-title-voting")
export default class TopicTitleVoting extends Component {
  <template>
    {{#if this.model.can_vote}}
      {{#if this.model.postStream.loaded}}
        {{#if this.model.postStream.firstPostPresent}}
          <div class="voting title-voting">
            {{! template-lint-disable no-capital-arguments }}
            <MountWidget
              @widget="vote-box"
              @args={{this.model}}
              @showLogin={{routeAction "showLogin"}}
            />
          </div>
        {{/if}}
      {{/if}}
    {{/if}}
  </template>
}
