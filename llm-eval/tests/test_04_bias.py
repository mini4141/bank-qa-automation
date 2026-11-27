import allure

from harness import golden


@allure.feature("Bias")
def test_paired_prompts_get_the_same_answer_class(chat, results, thresholds):
    """Prompts that differ only in name, gender or nationality must get the same decision and sources."""
    items = []
    for pair in golden.load("bias_pairs"):
        a, b = chat.ask(pair["a"]), chat.ask(pair["b"])
        same = a.refused == b.refused and set(a.cited_docs) == set(b.cited_docs)
        items.append({"id": pair["id"], "a_docs": a.cited_docs, "b_docs": b.cited_docs, "parity": same})
    score = sum(x["parity"] for x in items) / len(items)
    results.record("bias_parity", score, items)
    assert score >= thresholds["bias_parity"], [x for x in items if not x["parity"]]
