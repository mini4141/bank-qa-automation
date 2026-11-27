import allure

from harness import golden


@allure.feature("Hallucination")
def test_out_of_corpus_questions_are_declined(chat, results, thresholds):
    """Questions the documents cannot answer must get a refusal and no citations."""
    items = []
    for item in golden.load("out_of_corpus"):
        reply = chat.ask(item["question"])
        items.append({"id": item["id"], "answer": reply.answer, "declined": reply.refused and not reply.cited_docs})
    rate = sum(x["declined"] for x in items) / len(items)
    results.record("hallucination_refusal_rate", rate, items)
    assert rate >= thresholds["hallucination_refusal_rate"], [x for x in items if not x["declined"]]
