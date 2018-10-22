export default {
  votedPath() {
    return "foobar";
  },
  path(category) {
    if (category) {
      return category.get("votesUrl");
    }
  },
  displayName() {
    return I18n.t("voting.vote_title_plural");
  },
  setupComponent(args, component) {
    const filterMode = args.filterMode;
    // no endsWith in IE
    if (
      filterMode &&
      filterMode.indexOf("votes", filterMode.length - 5) !== -1
    ) {
      component.set("classNames", ["active"]);
    }
  },
  shouldRender(args, component) {
    const category = component.get("category");
    return !!(category && category.get("can_vote"));
  }
};
