import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-voting",

  initialize() {
    withPluginApi("0.8.32", api => {
      api.addNavigationBarItem({
        name: "votes",
        customFilter: category => {
          const container = api.container;

          if (
            container &&
            (!container.isDestroying || !container.isDestroyed)
          ) {
            const siteSettings = container.lookup("site-settings:main");
            return siteSettings.voting_enabled && category && category.can_vote;
          }

          return false;
        },
        customHref: (category, args) => {
          return `${Discourse.BaseUri}/${args.filterMode}?order=votes`;
        }
      });
    });
  }
};
