import computed from "ember-addons/ember-computed-decorators";
import Category from "discourse/models/category";
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "extend-category-for-voting",

  before: "inject-discourse-objects",

  initialize() {
    Category.reopen({
      @computed("custom_fields.enable_topic_voting")
      enable_topic_voting: {
        get(enableField) {
          return enableField;
        },
        set(value) {
          this.set("custom_fields.enable_topic_voting", value);
          return value;
        }
      }
    });
  }
};
