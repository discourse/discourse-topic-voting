import { withPluginApi } from "discourse/lib/plugin-api";

function initialize(api) {
  api.addPostClassesCallback(post => {
    if (post.post_number === 1 && post.can_vote) {
      return ["voting-post"];
    }
  });
  api.includePostAttributes("can_vote");
  api.addTagsHtmlCallback(
    topic => {
      if (!topic.can_vote) {
        return;
      }

      var buffer = [];

      let title = "";
      if (topic.user_voted) {
        title = ` title='${I18n.t("voting.voted")}'`;
      }

      let userVotedClass = topic.user_voted ? " voted" : "";
      buffer.push(
        `<span class='list-vote-count discourse-tag${userVotedClass}'${title}>`
      );

      buffer.push(I18n.t("voting.votes", { count: topic.vote_count }));
      buffer.push("</span>");

      if (buffer.length > 0) {
        return buffer.join("");
      }
    },
    { priority: -100 }
  );
}

export default {
  name: "discourse-voting",

  initialize(api) {
    withPluginApi("0.8.4", api => initialize(api));
    withPluginApi("0.8.30", api => api.addCategorySortCriteria("votes"));
    withPluginApi("0.8.32", api => {
      api.addNavigationBarItem({
        name: "votes",
        customFilter: (category, args, router) => {
          const siteSettings = api.container.lookup("site-settings:main");
          return siteSettings.voting_enabled && category && category.can_vote;
        },
        customHref: (category, args, router) => {
          return `${Discourse.BaseUri}/${args.filterMode}?order=votes`;
        }
      });
    });
  }
};
