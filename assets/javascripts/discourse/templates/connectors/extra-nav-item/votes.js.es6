export default {
  votedPath(){
    return "foobar";
  },
  setupComponent(args, component) {
    const filterMode = args.filterMode;
    // no endsWith in IE
    if (filterMode && filterMode.indexOf("votes", filterMode.length - 5) !== -1) {
      component.set("classNames", ["active"]);
    }
  },
  shouldRender(args, component) {
    const category = component.get("category");
    return !!(category && category.get("can_vote"));
  }
};
