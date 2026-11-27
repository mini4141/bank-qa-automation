import allure

from harness import golden  # noqa: F401


@allure.feature("RAG retrieval")
def test_retrieval_hit_at_3(qa_replies, results, thresholds):
    """The expected source document must be among the top 3 retrieved chunks."""
    items = [{"id": i["id"], "expected": i["expected_doc"], "retrieved": r.retrieved, "hit": i["expected_doc"] in r.retrieved[:3]}
             for i, r in qa_replies]
    score = sum(x["hit"] for x in items) / len(items)
    results.record("retrieval_hit_at_3", score, items)
    allure.attach(str(items), "retrieval items")
    assert score >= thresholds["retrieval_hit_at_3"], [x for x in items if not x["hit"]]
