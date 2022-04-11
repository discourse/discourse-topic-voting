export default {
  setupComponent(attrs, component) {
    let votingEnabled = attrs.category?.custom_fields?.discourse_voting_enabled;
    this.set("votingEnabled", votingEnabled);
  },
  actions: {
    updateVotingEnabled(value) {
      this.set(
        "category.custom_fields.discourse_voting_enabled",
        value ? "t" : "f"
      );
    },
  },
};
