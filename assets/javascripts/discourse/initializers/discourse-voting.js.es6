import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-voting",

  initialize() {
    withPluginApi("0.8.32", api => {
      api.addNavigationBarItem({
        name: "votes",
        customFilter: category => {
          const siteSettings = api.container.lookup("site-settings:main");
          return siteSettings.voting_enabled && category && category.can_vote;
        },
        customHref: (category, args) => {
          return `${Discourse.BaseUri}/${args.filterMode}?order=votes`;
        }
      });
    });
  }
};
