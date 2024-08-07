import { withPluginApi } from "discourse/lib/plugin-api";
import NavItem from "discourse/models/nav-item";
import I18n from "I18n";

export default {
  name: "discourse-topic-voting",

  initialize() {
    withPluginApi("0.8.32", (api) => {
      const siteSettings = api.container.lookup("service:site-settings");
      if (siteSettings.topic_voting_enabled) {
        const pageSearchController = api.container.lookup(
          "controller:full-page-search"
        );
        pageSearchController.sortOrders.pushObject({
          name: I18n.t("search.most_votes"),
          id: 5,
          term: "order:votes",
        });

        api.addNavigationBarItem({
          name: "votes",
          before: "top",
          customFilter: (category) => {
            return category && category.can_vote;
          },
          customHref: (category, args) => {
            const path = NavItem.pathFor("latest", args);
            return `${path}?order=votes`;
          },
          forceActive: (category, args, router) => {
            const queryParams = router.currentRoute.queryParams;
            return (
              queryParams &&
              Object.keys(queryParams).length === 1 &&
              queryParams["order"] === "votes"
            );
          },
        });
        api.addNavigationBarItem({
          name: "my_votes",
          before: "top",
          customFilter: (category) => {
            return category && category.can_vote && api.getCurrentUser();
          },
          customHref: (category, args) => {
            const path = NavItem.pathFor("latest", args);
            return `${path}?state=my_votes`;
          },
          forceActive: (category, args, router) => {
            const queryParams = router.currentRoute.queryParams;
            return (
              queryParams &&
              Object.keys(queryParams).length === 1 &&
              queryParams["state"] === "my_votes"
            );
          },
        });
      }
    });

    withPluginApi("0.11.7", (api) => {
      const siteSettings = api.container.lookup("service:site-settings");
      if (siteSettings.topic_voting_enabled) {
        api.addSearchSuggestion("order:votes");
      }
    });
  },
};
