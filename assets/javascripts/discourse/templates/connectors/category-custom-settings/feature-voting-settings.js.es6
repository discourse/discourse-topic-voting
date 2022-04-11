export default {
  actions: {
    updateVotingEnabled(value) {
      this.set(
        "category.custom_fields.discourse_voting_enabled",
        value ? "t" : "f"
      );
    },
  },
};
