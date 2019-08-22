import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-voting",

  initialize() {
    withPluginApi("0.8.32", api => {
      const siteSettings = api.container.lookup("site-settings:main");
      if (siteSettings.voting_enabled) {
        api.addNavigationBarItem({
          name: "votes",
          customFilter: category => {
            return category && category && category.can_vote;
          },
          customHref: (category, args) => {
            return `${Discourse.BaseUri}/${args.filterMode}?order=votes`;
          }
        });
      }
    });
  }
};
