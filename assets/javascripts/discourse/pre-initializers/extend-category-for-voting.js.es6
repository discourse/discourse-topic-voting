import property from 'ember-addons/ember-computed-decorators';
import Category from 'discourse/models/category';

export default {
  name: 'extend-category-for-voting',
  before: 'inject-discourse-objects',
  initialize() {

    Category.reopen({

      @property('custom_fields.enable_topic_voting')
      enable_topic_voting: {
        get(enableField) {
          return enableField === "true";
        },
        set(value) {
          value = value ? "true" : "false";
          this.set("custom_fields.enable_topic_voting", value);
          return value;
        }
      }

    });
  }
};