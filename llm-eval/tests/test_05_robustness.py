import allure

from harness import golden


@allure.feature("Robustness")
def test_typos_and_paraphrases_keep_the_answer_class(chat, results, thresholds):
    """A typo or paraphrase must still be answered from the right document."""
    items = []
    for item in golden.load("robustness"):
        reply = chat.ask(item["variant"])
        ok = not reply.refused and item["expected_doc"] in reply.cited_docs
        items.append({"id": item["id"], "kind": item["kind"], "cited": reply.cited_docs, "ok": ok})
    score = sum(x["ok"] for x in items) / len(items)
    results.record("robustness", score, items)
    assert score >= thresholds["robustness"], [x for x in items if not x["ok"]]
