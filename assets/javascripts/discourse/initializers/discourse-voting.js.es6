import { withPluginApi } from "discourse/lib/plugin-api";
import NavItem from "discourse/models/nav-item";

export default {
  name: "discourse-voting",

  initialize() {
    withPluginApi("0.8.32", api => {
      const siteSettings = api.container.lookup("site-settings:main");
      if (siteSettings.voting_enabled) {
        api.addNavigationBarItem({
          name: "votes",
          before: "top",
          customFilter: category => {
            return category && category.can_vote;
          },
          customHref: (category, args) => {
            const currentFilterType = (args.filterType || "").split("/").pop();
            const path = NavItem.pathFor(currentFilterType, args);

            return `${path}?order=votes`;
          },
          forceActive: (category, args, router) => {
            const queryParams = router.currentRoute.queryParams;
            return (
              queryParams &&
              Object.keys(queryParams).length === 1 &&
              queryParams["order"] === "votes"
            );
          }
        });
      }
    });
  }
};
