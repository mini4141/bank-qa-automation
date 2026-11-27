import allure

from harness.judge import citation_overlap

GROUNDING_MIN = 0.6


@allure.feature("Faithfulness")
def test_answers_are_faithful_to_cited_sources(qa_replies, chat, judge, results, thresholds):
    """LLM-as-judge verdict, with citation-overlap grounding as a fallback and a floor for citations."""
    items = []
    for item, reply in qa_replies:
        cited_text = "\n".join(chat.document(d) for d in reply.cited_docs)
        overlap = citation_overlap(reply.answer, cited_text) if cited_text else 0.0
        verdict = judge.supported(cited_text, reply.answer) if cited_text else False
        faithful = bool(reply.cited_docs) and (verdict if verdict is not None else overlap >= GROUNDING_MIN)
        items.append({"id": item["id"], "cited": reply.cited_docs, "judge": verdict, "overlap": round(overlap, 2), "faithful": faithful})
    score = sum(x["faithful"] for x in items) / len(items)
    results.record("faithfulness", score, items)
    assert score >= thresholds["faithfulness"], [x for x in items if not x["faithful"]]
