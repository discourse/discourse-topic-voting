export default {
  setupComponent(args, component) {
    component.set(
      "url",
      Discourse.BaseUri + "/" + args.filterMode + "?order=votes"
    );
  },
  shouldRender(args, component) {
    const category = component.get("category");
    return !!(category && category.get("can_vote"));
  }
};
