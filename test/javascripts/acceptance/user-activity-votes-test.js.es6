import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";
import I18n from "I18n";

acceptance(
  "Discourse Voting Plugin | /activity/votes | empty state",
  function (needs) {
    const currentUser = "eviltrout";
    const anotherUser = "charlie";

    needs.user();

    needs.pretender((server, helper) => {
      const emptyResponse = { topic_list: { topics: [] } };

      server.get(`/topics/voted-by/${currentUser}.json`, () => {
        return helper.response(emptyResponse);
      });

      server.get(`/topics/voted-by/${anotherUser}.json`, () => {
        return helper.response(emptyResponse);
      });
    });

    test("When looking at the own activity page", async function (assert) {
      await visit(`/u/${currentUser}/activity/votes`);
      assert.equal(
        query("div.empty-state span.empty-state-title").innerText,
        I18n.t("voting.no_votes_title_self")
      );
    });

    test("When looking at another user's activity page", async function (assert) {
      await visit(`/u/${anotherUser}/activity/votes`);
      assert.equal(
        query("div.empty-state span.empty-state-title").innerText,
        I18n.t("voting.no_votes_title_others", { username: anotherUser })
      );
    });
  }
);
