import I18n from "I18n";
import { withPluginApi } from "discourse/lib/plugin-api";
import { setDefaultHomepage } from "discourse/lib/utilities";
import NavItem from "discourse/models/nav-item";

export default {
  name: "discourse-voting",
  after: "url-redirects",
  initialize() {
    withPluginApi("0.8.32", (api) => {
      const siteSettings = api.container.lookup("site-settings:main");
      if (siteSettings.voting_enabled) {
        const pageSearchController = api.container.lookup(
          "controller:full-page-search"
        );
        pageSearchController.sortOrders.pushObject({
          name: I18n.t("search.most_votes"),
          id: 5,
          term: "order:votes",
        });

        const topMenuItems = siteSettings.top_menu.split('|');
        const votesBeforeNavItem = siteSettings.voting_show_votes_before;
        if (topMenuItems.indexOf(votesBeforeNavItem) === 0) {
          setDefaultHomepage('votes');
        }

        const showVotesOnHome = siteSettings.voting_show_votes_on_homepage;
        api.addNavigationBarItem({
          name: "votes",
          before: votesBeforeNavItem,
          customFilter: (category) => ((!category && showVotesOnHome) || (category && category.can_vote)),
          customHref: (category, args) => (category ? `${category.url}/l/votes` : '/votes')
        });

        const myVotesBeforeNavItem = siteSettings.voting_show_my_votes_before;
        const showMyVotesOnHome = siteSettings.voting_show_my_votes_on_homepage;
        api.addNavigationBarItem({
          name: "my_votes",
          before: myVotesBeforeNavItem,
          customFilter: (category) => {
            return api.getCurrentUser() && (category ? category.can_vote : showMyVotesOnHome);
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
      const siteSettings = api.container.lookup("site-settings:main");
      if (siteSettings.voting_enabled) {
        api.addSearchSuggestion("order:votes");
      }
    });
  },
};
