export default {
  setupComponent(args, component) {
    component.set("url", `${Discourse.BaseUri}/${args.filterMode}?order=votes`);
  },
  shouldRender(args, component) {
    const category = component.category;
    return !!(category && category.can_vote);
  }
};
