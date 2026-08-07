import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 2: hybrid retrieval, cross-encoder re-ranking, multi-hop
/// chains and query construction — the patterns that pick up where naive
/// top-k dense retrieval runs out of road.
const Lesson advancedRagPatternsLesson = Lesson(
  id: 'rag-advanced-rag-patterns',
  title: 'Advanced RAG Patterns',
  description:
      'Hybrid search and Reciprocal Rank Fusion, cross-encoder re-ranking, '
      'multi-hop retrieval and self-querying — and when each one is worth '
      'the extra latency.',
  estimatedMinutes: 38,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  play: GameContent(games: <Game>[]),
  review: _review,
  sources: _sources,
  furtherReading: _furtherReading,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'why-topk-breaks',
      heading: 'Where top-k dense retrieval runs out of road',
      blocks: [
        ProseBlock(
          'The previous two lessons treated retrieval as solved once you had '
          'an embedding model and an index: embed the query, ask for the k '
          'nearest chunks, done. That gets a RAG system most of the way to '
          'working, and it is also where a surprising number of production '
          'systems stop — which is a mistake, because plain top-k dense '
          'retrieval has structural weaknesses that no amount of index '
          'tuning fixes, and all of them show up constantly once real users '
          'start asking real questions.',
        ),
        ProseBlock(
          'The first is the recall/precision tradeoff built into any fixed '
          'k. Ask for k=3 and a genuinely relevant passage that happens to '
          'rank fourth is invisible to the system — not deprioritised, gone, '
          'because nothing downstream of retrieval ever sees it. Ask for '
          'k=20 to be safe and precision drops instead: most of what comes '
          'back is topically adjacent but not actually useful, and every '
          'irrelevant chunk that makes it into the prompt is context budget '
          'spent on nothing, with the added problem that models attend less '
          'reliably to text buried in the middle of a long prompt. There is '
          'no value of k that is simultaneously safe against both failure '
          'modes for every query — the right k for a narrow factual '
          'question is wrong for a question whose answer is scattered '
          'across six passages.',
        ),
        ProseBlock(
          'The second weakness is sharper and easier to miss in a demo: '
          'embedding similarity measures topical closeness, not '
          'correctness, and the two come apart constantly. Ask "does this '
          'medication interact with alcohol" and a passage stating "this '
          'medication has no known interaction with alcohol" embeds almost '
          'identically to a passage stating the opposite — both are about '
          'the medication, both are about alcohol, both use nearly the same '
          'vocabulary, and a bi-encoder never checks which one actually '
          'answers the question, because it has no mechanism for checking '
          'anything; it only measures how close two independently-computed '
          'vectors happen to sit in space. A retrieval system built purely '
          'on cosine similarity will confidently return either passage with '
          'a high score, and a downstream LLM asked to summarise whatever '
          'it is handed will happily generate a fluent answer from the '
          'wrong one.',
        ),
        ProseBlock(
          'The third weakness is the mirror image of the second: embeddings '
          'are bad at exact tokens. A part number, an error code, a legal '
          'clause reference, a rare product SKU — these are precisely the '
          'strings a general-purpose embedding model has the least reason '
          'to represent distinctly, because it was trained on ordinary '
          'language, and "ERR_4029" or "clause 14.3(b)" looks to it like '
          'noise wrapped around whatever ordinary words happen to sit '
          'nearby. A user who pastes an exact error code expects the '
          'passage containing that exact code back, and dense retrieval '
          'routinely returns three plausible-sounding but wrong passages '
          'instead, because the code itself contributed almost nothing to '
          'the similarity score.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Cosine similarity is not relevance',
          text:
              'A high similarity score means "these two texts are about '
              'similar things," not "this passage answers the question" or '
              'even "this passage agrees with the question\'s premise." '
              'Negation, contradiction, and "topically adjacent but '
              'factually wrong" all produce embeddings that sit close '
              'together, because embedding models were never trained to '
              'check truth values — only to model what paraphrase pairs and '
              'click data treat as related. Treat a high similarity score '
              'as "worth reading," not as "verified."',
        ),
      ],
    ),
    Section(
      id: 'hybrid-search',
      heading: 'Hybrid search: fusing sparse and dense retrieval',
      blocks: [
        ProseBlock(
          'Sparse retrieval is the older technology and it never went away '
          'for a reason. BM25 — the standard scoring function behind most '
          '"search" boxes built before embeddings existed — scores a '
          'document by how often the query\'s exact terms appear in it, '
          'adjusted for document length and for how rare each term is '
          'across the whole corpus, so a term that appears in nearly every '
          'document contributes almost nothing while a term that appears in '
          'only a handful of documents contributes a lot. It has no notion '
          'of synonymy: search for "automobile" and a document that only '
          'says "car" scores zero contribution from that term, no matter '
          'how obviously related a human would find them. That is exactly '
          'the deficiency dense retrieval was built to fix, and dense '
          'retrieval introduces exactly the opposite deficiency: strong on '
          'synonymy and paraphrase, weak on exact tokens.',
        ),
        ProseBlock(
          'Hybrid search runs both retrievers over the same corpus for the '
          'same query and keeps both ranked lists, on the theory that a '
          'passage worth showing the user is one that at least one method — '
          'ideally both — considers strong. A part-number query gets '
          'rescued by BM25 even though the dense retriever finds it '
          'unremarkable; a paraphrased question gets rescued by the dense '
          'retriever even though none of its words appear verbatim anywhere '
          'in the right passage. Where hybrid search gets interesting, and '
          'where a surprising number of implementations get it wrong, is '
          'how the two ranked lists actually get merged into one.',
        ),
        ProseBlock(
          'The naive approach is to average or weight-sum the two scores '
          'directly, and it fails quietly rather than loudly. A BM25 score '
          'is an unbounded, corpus-dependent number driven by term-rarity '
          'statistics that shift every time the corpus changes; a cosine '
          'similarity score is bounded in [-1, 1] and shaped entirely '
          'differently. Averaging 0.83 — a strong cosine score — with 11.2 — '
          'a middling BM25 score on this particular corpus — produces a '
          'number with no principled meaning, and a blend that happened to '
          'work on last month\'s corpus can silently stop working once '
          'enough documents are added or removed to shift the BM25 term '
          'statistics. Whatever weighting the blend is tuned to today is '
          'corpus-specific and needs re-tuning as the corpus grows, which '
          'nobody remembers to do.',
        ),
        ProseBlock(
          'Reciprocal Rank Fusion sidesteps the scale problem entirely by '
          'throwing away the scores and keeping only the ranks. For a '
          'document d, its RRF score is the sum, over every ranked list it '
          'appears in, of one divided by a constant k plus its rank in that '
          'list: RRF(d) = Σ 1 / (k + rank(d)). k is a small constant, '
          'conventionally 60, whose only job is to flatten the gap between '
          'adjacent ranks: 1/(60+1) and 1/(60+2) differ by under two '
          'percent, whereas 1/1 and 1/2 differ by fifty. That damping is '
          'the whole point — RRF is deliberately insensitive to exactly how '
          'far ahead a document is ranked, and cares much more about '
          'whether it shows up reasonably highly across multiple '
          'independent retrievers at all. A document one retriever ranks '
          'first but the other never surfaces gets credit from only one '
          'list; a document that lands consistently in second or third '
          'place in both lists accumulates two decent-sized contributions '
          'instead of one large one and one zero — and, as the worked '
          'example below shows, that consistency frequently wins.',
        ),
        CodeBlock(
          language: 'text',
          code: '''
BM25 ranking:   1. doc_X   2. doc_Y   3. doc_Z
Dense ranking:  1. doc_W   2. doc_Y

RRF, k = 60:
  doc_X:  1/(60+1)                    = 0.01639
  doc_Y:  1/(60+2)  +  1/(60+2)       = 0.01613 + 0.01613 = 0.03226
  doc_Z:  1/(60+3)                    = 0.01587
  doc_W:                  1/(60+1)    = 0.01639

Fused order:  doc_Y (0.03226)  >  doc_X (0.01639) = doc_W (0.01639)  >  doc_Z (0.01587)
''',
          caption:
              'Consistency across retrievers beats a single first-place '
              'finish: doc_Y wins the fusion despite never topping either '
              'individual list.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def reciprocal_rank_fusion(ranked_lists, k=60):
    """ranked_lists: list of ranked doc-id lists, each best match first.
    Returns [(doc_id, score), ...] sorted by fused score, best first."""
    scores = {}
    for ranked in ranked_lists:
        for rank, doc_id in enumerate(ranked, start=1):
            scores[doc_id] = scores.get(doc_id, 0.0) + 1.0 / (k + rank)
    return sorted(scores.items(), key=lambda item: -item[1])


bm25_ranking = ["doc_X", "doc_Y", "doc_Z"]
dense_ranking = ["doc_W", "doc_Y"]

for doc_id, score in reciprocal_rank_fusion([bm25_ranking, dense_ranking]):
    print(doc_id, round(score, 5))

# doc_Y 0.03226   <- never ranked #1 anywhere, but shows up mid-pack in both
# doc_X 0.01639   <- #1 in BM25, completely absent from the dense ranking
# doc_W 0.01639   <- #1 in dense, completely absent from the BM25 ranking
# doc_Z 0.01587   <- #3 in BM25 only
''',
          caption:
              'The same table, run as code — worth confirming the two '
              'agree before trusting the formula on a real corpus.',
        ),
      ],
    ),
    Section(
      id: 'reranking',
      heading: 'Re-ranking: a second, more expensive look',
      blocks: [
        ProseBlock(
          'Hybrid search fixes coverage — making sure the right passage is '
          'somewhere in the candidate set — but it does not fix ordering '
          'with much precision, because both BM25 and a bi-encoder '
          'embedding model score the query and each candidate independently '
          'of every other candidate, and independently of one another '
          'within the pair. The standard fix widens the net first and '
          'narrows it carefully second: retrieve a wide candidate set '
          'cheaply — the top 50 or 100 by hybrid or dense search, well '
          'beyond what you would ever hand to the LLM directly — and then '
          're-score just that shortlist with a slower but more accurate '
          'model before truncating to the handful of chunks that actually '
          'go in the prompt.',
        ),
        ProseBlock(
          'A bi-encoder — the embedding model used for retrieval so far — '
          'encodes the query and encodes each document completely '
          'independently, each pass through the network never aware the '
          'other text exists, and then compares the two resulting vectors '
          'with a cheap operation like cosine similarity. That independence '
          'is what makes it fast: every document\'s embedding is computed '
          'once, offline, at indexing time, and stored; a query at runtime '
          'only has to be embedded once and compared against millions of '
          'precomputed vectors. It is also exactly what limits its '
          'accuracy — the model never gets to look at the query and the '
          'document together, so it cannot represent interactions between '
          'them, only how each looks in isolation.',
        ),
        ProseBlock(
          'A cross-encoder removes that independence by design: it takes '
          'the concatenation of the query and a single candidate document '
          'as one input, runs the pair through a transformer\'s shared '
          'attention layers, and outputs a single relevance score '
          'directly. Because query tokens and document tokens attend to '
          'each other, the model can represent exactly the kind of '
          'interaction a bi-encoder structurally cannot: whether the '
          'document actually answers the question, contradicts it, or '
          'merely shares vocabulary with it. Cross-encoders consistently '
          'outperform bi-encoders on ranking accuracy for this reason — at '
          'a cost: a cross-encoder score cannot be precomputed, because it '
          'does not exist until a specific query is known, so there is '
          'nothing to store ahead of time and no shortcut around running '
          'the model once per query-document pair.',
        ),
        ProseBlock(
          'That cost is exactly why re-ranking is a second stage rather '
          'than a replacement for the first. Running a cross-encoder over '
          'an entire corpus of a million chunks means a million forward '
          'passes per query — computationally absurd at interactive '
          'latency. Running it over the 50-100 candidates a bi-encoder or '
          'hybrid search already narrowed things down to is a few hundred '
          'milliseconds on modern hardware, cheap enough to be worth it for '
          'the accuracy gain — and that is the entire retrieve-then-rerank '
          'pattern: fast-and-approximate first, slow-and-accurate second, '
          'over a shortlist small enough for the slow step to be '
          'affordable.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Stage 1: bi-encoder cosine similarity already ran and produced this order.
candidates = [
    ("doc_faq_1", "Free tier accounts are limited to 1,000 API calls per "
                  "day.", 0.81),
    ("doc_webhooks", "Webhooks are available on the free tier, rate-limited "
                      "to 10 events per minute.", 0.74),
    ("doc_pricing", "Paid tiers remove the daily call limit entirely.", 0.69),
]
query = "Does the free tier support webhooks?"

# Stage 2: a cross-encoder scores (query, document) pairs jointly. Its output
# can't be precomputed -- it doesn't exist until the query is known -- so it
# only runs over this short candidate list, never the whole corpus.
cross_encoder_scores = {
    "doc_faq_1": 0.11,      # about the free tier, but never mentions webhooks
    "doc_webhooks": 0.95,   # directly answers the question
    "doc_pricing": 0.08,    # about pricing tiers, not webhooks at all
}

reranked = sorted(candidates, key=lambda c: -cross_encoder_scores[c[0]])

print("bi-encoder order:  ", [c[0] for c in candidates])
# ['doc_faq_1', 'doc_webhooks', 'doc_pricing']

print("cross-encoder order:", [c[0] for c in reranked])
# ['doc_webhooks', 'doc_faq_1', 'doc_pricing']
''',
          caption:
              'The bi-encoder ranked the passage that merely shares '
              'vocabulary with the query above the one that actually '
              'answers it; the cross-encoder, scoring the pair jointly, '
              'gets it right.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: "Re-ranking can't retrieve what was never in the shortlist",
          text:
              'If the true answer passage never made it into the initial '
              'candidate set — a keyword-heavy passage an under-tuned '
              'dense-only first stage missed entirely — the cross-encoder '
              'never sees it and cannot promote it. Hybrid search as the '
              'first stage still matters even after re-ranking is added; '
              'the two patterns compound, they do not substitute for each '
              'other. Candidate-pool size (50? 100? 200?) is itself a '
              'tuning knob measured against a latency budget, not a '
              'constant to set once and forget.',
        ),
      ],
    ),
    Section(
      id: 'multi-hop',
      heading: 'Multi-hop retrieval: when one lookup is not enough',
      blocks: [
        ProseBlock(
          'Some questions cannot be answered by any single passage, no '
          'matter how good retrieval is, because the fact the question is '
          'actually asking for is never stated next to anything that '
          'mentions the entity in the question. "What company did the '
          'founder of Anthropic work at before starting it?" is the '
          'canonical shape: no single sentence in a typical corpus says '
          'both "Dario Amodei founded Anthropic" and "Dario Amodei '
          'previously worked at OpenAI" in the same breath — one document '
          'establishes who founded the company, and a completely different '
          'document, likely a biography page that never mentions '
          'Anthropic\'s founding at all, holds the employment history. '
          'Retrieval built to find the passage most similar to the full '
          'question finds the first document — because that is the one '
          'actually about founding Anthropic — and stops there, having '
          'retrieved something real and relevant that simply cannot answer '
          'what was asked.',
        ),
        ProseBlock(
          'Single-shot retrieval\'s implicit assumption is that the answer '
          'lives in the neighbourhood of the query\'s own embedding. '
          'Multi-hop questions violate that assumption structurally, not as '
          'a matter of degree — no amount of widening k or improving the '
          'embedding model puts the employment fact any closer to a query '
          'embedding built from a sentence that never mentions the '
          'founder\'s name, because the query as originally written does '
          'not know that name yet either. The name is itself an '
          'intermediate result that has to be discovered before the second '
          'retrieval can even be phrased.',
        ),
        ProseBlock(
          'The fix is to chain retrieval calls, using the output of one as '
          'input to the next. Hop one retrieves against the original '
          'question and finds the passage naming the founder. An '
          'extraction step — an LLM, in practice, reading that passage and '
          'pulling out the name — turns that passage into a fact: "Dario '
          'Amodei." Hop two builds a new, more specific query from that '
          'fact — "Dario Amodei prior employer" — and retrieves again, this '
          'time against a passage the original question\'s embedding was '
          'never close to, because the original question never contained '
          'that name.',
        ),
        ProseBlock(
          'The dangerous failure mode is stopping after one hop and not '
          'noticing. A system with a fixed hop budget of one, or an agent '
          'that decides too eagerly that it has enough context, hands the '
          'LLM only the founding-story passage and asks it to answer a '
          'question about prior employment that passage structurally '
          'cannot contain. Unlike a plain retrieval miss — which at least '
          'tends to surface a passage visibly unrelated to the question, '
          'something a careful prompt can catch with "if the answer isn\'t '
          'here, say so" — a premature single hop surfaces a passage that '
          'is genuinely, verifiably relevant to part of the question. It '
          'just does not contain the specific fact being asked for, and a '
          'model under instructions to answer helpfully will often paper '
          'over that gap with a plausible guess rather than admit the '
          'passage stopped short. The wrong answer looks more confident '
          'precisely because the retrieved evidence looks legitimate.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: deciding the query for hop two',
          children: [
            ProseBlock(
              'There are two broad ways to decide what to search for on '
              'later hops, and they trade planning cost against '
              'flexibility. Upfront decomposition asks an LLM to read the '
              'full question once and produce an ordered list of '
              'sub-questions before any retrieval happens at all — "first '
              'find who founded Anthropic, then find that person\'s prior '
              'employer" — and then executes each sub-question\'s '
              'retrieval in sequence, feeding results forward. It is cheap '
              'to reason about and easy to debug, because the whole plan '
              'is visible before anything runs, but it commits to a plan '
              'before seeing any actual retrieval results, so a plan that '
              'assumes a fact that turns out to be wrong — say, '
              'misidentifying which of two co-founders the question means — '
              'cannot self-correct.',
            ),
            ProseBlock(
              'Iterative — often called agentic — retrieval makes no '
              'upfront plan at all. After each retrieval call, an LLM '
              'inspects what came back and decides fresh whether it has '
              'enough evidence to answer or needs another hop, and if so, '
              'what that hop\'s query should be. This handles questions '
              'whose second hop genuinely cannot be known in advance — the '
              'query for hop two might depend on which of several names '
              'hop one actually returned — at the cost of an LLM call after '
              'every single retrieval step, which is slower and more '
              'expensive per question, and introduces a genuine risk of '
              'looping: an agent that never reliably recognises "I have '
              'enough now" can keep retrieving past the point of '
              'diminishing returns, or even indefinitely without a hard hop '
              'cap as a backstop.',
            ),
            ProseBlock(
              'Production systems typically cap the hop budget explicitly '
              'regardless of which strategy is used — three to five hops '
              'is a common ceiling — precisely because an ungrounded '
              'stopping decision is one of the more common ways an agentic '
              'RAG pipeline runs up cost and latency without a matching '
              'gain in answer quality.',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'query-construction-and-practice',
      heading: 'Query construction, and knowing when to bother',
      blocks: [
        ProseBlock(
          'Every pattern so far still treats the corpus as an '
          'undifferentiated pool of text to search semantically. Real '
          'corpora usually carry structure the search string alone throws '
          'away: a date, a document type, an author, a product category, a '
          'status field. "What changed in the refund policy after March '
          '2024" is really two different constraints bundled into one '
          'sentence — a metadata filter (documents dated after March 2024, '
          'of type "policy") and a semantic search string (refund policy '
          'changes) — and treating the whole sentence as one embedding '
          'query wastes the date entirely, leaving the embedding model to '
          'somehow encode "after March 2024" as a similarity signal, which '
          'it is not built to do.',
        ),
        ProseBlock(
          'Query construction — sometimes called self-querying retrieval — '
          'hands the raw question to an LLM along with a schema describing '
          'what metadata fields the vector store supports, and asks it to '
          'emit a structured query: a set of filter conditions plus a '
          'cleaned semantic search string, executed together against a '
          'store that supports both simultaneously. LlamaIndex\'s '
          'auto-retriever and LangChain\'s self-query retriever are the '
          'same idea under different names: describe the available '
          'metadata fields and their types once, and let the LLM figure '
          'out, per query, which fields are actually being constrained and '
          'what is left over for semantic search.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# A toy stand-in for the LLM call a self-querying retriever makes: parse a
# natural-language question into metadata filters plus a semantic search
# string, given a schema of what the vector store can filter on.
def llm_parse_query(question, schema):
    """In production this is one LLM call with the schema in the prompt.
    Hardcoded here to keep the example runnable without an API key."""
    del question, schema  # the real call reads both; this stub already knows
    return {
        "filter": {"doc_type": "policy", "date": {"\$gte": "2024-03-01"}},
        "search": "refund policy changes",
    }


schema = {
    "doc_type": "one of: policy, faq, changelog",
    "date": "ISO date the document was published",
}

question = "What changed in the refund policy after March 2024?"
structured_query = llm_parse_query(question, schema)
print(structured_query)
# {'filter': {'doc_type': 'policy', 'date': {'\$gte': '2024-03-01'}},
#  'search': 'refund policy changes'}

corpus = [
    {"id": "policy_2023", "doc_type": "policy", "date": "2023-06-01",
     "text": "Refunds are issued within 30 days of purchase."},
    {"id": "policy_2024", "doc_type": "policy", "date": "2024-04-15",
     "text": "Refunds are now issued within 14 days, and store credit is "
             "offered as an alternative."},
    {"id": "faq_refunds", "doc_type": "faq", "date": "2024-05-01",
     "text": "Refunds: see the refund policy page for current timelines."},
]


def apply_filter(corpus, filt):
    """Keep only documents matching every condition in filt."""
    return [
        doc for doc in corpus
        if doc["doc_type"] == filt["doc_type"]
        and doc["date"] >= filt["date"]["\$gte"]
    ]


filtered = apply_filter(corpus, structured_query["filter"])
print([doc["id"] for doc in filtered])
# ['policy_2024']  -- the 2023 policy and the FAQ page are excluded before
# semantic search over "search" ever runs, not ranked low and hoped past
''',
          caption:
              'The date filter eliminates the outdated 2023 policy and the '
              'loosely related FAQ page exactly, before semantic search has '
              'to try to distinguish them by similarity alone.',
        ),
        ProseBlock(
          'The gain over folding everything into one semantic query is '
          'precision without a corresponding recall cost. A metadata '
          'filter is exact — "date >= 2024-03-01" either holds for a '
          'document or it does not, with none of the fuzziness a '
          'similarity score carries — so it can eliminate every document '
          'outside the constraint before semantic search even runs, '
          'shrinking the candidate pool and removing an entire class of '
          'false positives that no amount of re-ranking would reliably '
          'catch, because a stale and a current policy document can be '
          'nearly indistinguishable in embedding space.',
        ),
        ProseBlock(
          'None of hybrid search, re-ranking, multi-hop chaining or query '
          'construction is free, and stacking all four onto every query is '
          'rarely the right call. Hybrid search is close to a default: the '
          'BM25 side is cheap to run alongside an existing dense index, and '
          'it buys robustness against exact-match misses with little added '
          'latency, so there is rarely a reason not to have it available. '
          'Re-ranking earns its cost — one extra model call over a '
          'shortlist — when answer quality is genuinely high-stakes or the '
          'corpus is large and noisy enough that ordering among the top '
          'candidates matters; it is overkill for a small, curated '
          'knowledge base where the top hybrid result is almost always '
          'right already. Multi-hop chaining should be reserved for query '
          'types that are actually structurally multi-hop — most real user '
          'questions are not — because running an unnecessary '
          'extraction-and-second-retrieval step on every query multiplies '
          'latency and cost for no benefit on the large majority of '
          'questions a single hop already answers. Query construction is '
          'worth building only where the corpus actually has clean, '
          'queryable metadata to filter on; there is nothing for it to do '
          'against a pile of unstructured text with no dates, categories '
          'or authors attached.',
        ),
        ProseBlock(
          'Whether any of this actually helped is an empirical question, '
          'not something to decide from a handful of manual spot-checks. '
          'The minimum viable setup is a held-out evaluation set — a few '
          'dozen to a few hundred representative (query, expected passage '
          'or answer) pairs, ideally including the exact failure modes '
          'this lesson describes: a negation case, an exact-ID case, a '
          'multi-hop case — scored on retrieval metrics like recall@k (did '
          'the right passage make it into the candidate set at all?) and '
          'mean reciprocal rank (how high did it rank when it did?), run '
          'before and after each change. Retrieval metrics improving is '
          'necessary but not sufficient: it is entirely possible for '
          're-ranking to correctly promote the right passage to position '
          'one and for the final answer to still be wrong because of an '
          'unrelated prompting issue, so a second, answer-level check — an '
          'LLM-as-judge comparing the generated answer against a '
          'reference, or a human review pass on a sample — is what '
          'actually confirms the pattern paid for itself. And every '
          'comparison should be read alongside its latency cost: a change '
          'that improves recall@10 by three points while doubling p95 '
          'latency is not automatically worth shipping, particularly for a '
          'chat interface where users notice a slow response far more '
          'readily than a marginally better citation.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: cost/benefit analysis of each advanced pattern',
          children: [
            ProseBlock(
              'Each advanced RAG pattern has a measurable cost in latency, '
              'token spend, and engineering complexity. Hybrid search (dense '
              '+ sparse) adds one extra retrieval call plus the RRF fusion '
              'step — roughly 1.3-1.5x the latency of dense-only retrieval, '
              'but typically improves recall by 10-20% on mixed-domain '
              'corpora where BM25 catches exact vocabulary matches that '
              'embeddings miss. Cross-encoder reranking adds k extra model '
              'calls per query (one per candidate in the shortlist), making '
              'it the most expensive single addition — a reranker processing '
              '10 candidates at 50ms each adds half a second of latency.',
            ),
            ProseBlock(
              'Multi-hop retrieval adds latency proportional to the number of '
              'hops, and each hop depends on the previous one, so they '
              'serialize. A 3-hop query takes roughly 3x the retrieval '
              'latency plus extra LLM synthesis calls between hops. '
              'Self-querying (metadata extraction from natural language) '
              'adds one cheap LLM call before retrieval — typically the best '
              'ROI of the advanced patterns, because ~50ms and a few tokens '
              'can generate metadata filters that cut the search space by '
              '90%+. The practical rule: start with self-querying if you '
              'have rich metadata; add hybrid search if sparse retrieval '
              '(BM25) captures vocabulary your embeddings miss; add '
              'reranking only if your recall is already good but precision '
              '— ranking quality — is the bottleneck that actually limits '
              'answer quality.',
            ),
          ],
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-rag-rrf',
      title: 'Implement Reciprocal Rank Fusion',
      prompt: [
        ProseBlock(
          'Implement reciprocal_rank_fusion(ranked_lists, k=60), which '
          'takes a list of ranked doc-id lists (each ordered best match '
          'first) and returns [(doc_id, score), ...] sorted by fused score, '
          'best first. A document missing from one of the lists simply '
          'contributes nothing from that list — do not treat a missing '
          'document as an error.',
        ),
        ProseBlock(
          'Run it against the bm25_ranking and dense_ranking below and '
          'check the result against a hand computation for at least one '
          'document, the way the lesson\'s worked example does.',
        ),
      ],
      starterCode: '''
def reciprocal_rank_fusion(ranked_lists, k=60):
    """ranked_lists: list of ranked doc-id lists, each best-first.
    Return [(doc_id, score), ...] sorted by fused score, best first."""
    ...


bm25_ranking = ["p3", "p1", "p5", "p2"]
dense_ranking = ["p1", "p4", "p3", "p5"]

fused = reciprocal_rank_fusion([bm25_ranking, dense_ranking])
for doc_id, score in fused:
    print(doc_id, round(score, 5))
''',
      solutionCode: '''
def reciprocal_rank_fusion(ranked_lists, k=60):
    """ranked_lists: list of ranked doc-id lists, each best-first.
    Return [(doc_id, score), ...] sorted by fused score, best first."""
    scores = {}
    for ranked in ranked_lists:
        for rank, doc_id in enumerate(ranked, start=1):
            scores[doc_id] = scores.get(doc_id, 0.0) + 1.0 / (k + rank)
    return sorted(scores.items(), key=lambda item: -item[1])


bm25_ranking = ["p3", "p1", "p5", "p2"]
dense_ranking = ["p1", "p4", "p3", "p5"]

fused = reciprocal_rank_fusion([bm25_ranking, dense_ranking])
for doc_id, score in fused:
    print(doc_id, round(score, 5))

# p1 0.03252   <- rank 2 in BM25, rank 1 in dense: strong in both
# p3 0.03227   <- rank 1 in BM25, rank 3 in dense: strong in both
# p5 0.0315    <- rank 3 in BM25, rank 4 in dense: present in both, lower
# p4 0.01613   <- rank 2 in dense only, absent from BM25
# p2 0.01562   <- rank 4 in BM25 only, absent from dense
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why does RRF use 1/(k+rank) instead of just 1/rank, and what '
              'does raising k do to the fused ranking?',
          expectedAnswer:
              'k acts as a smoothing constant. Without it — equivalent to '
              'k=0 — a rank-1 result contributes 1.0 versus a rank-2 '
              'result\'s 0.5, a huge relative gap, so whichever retriever '
              'happens to put a document in the very top slot would '
              'dominate the fused score almost regardless of its position '
              'in the other list. Adding a constant, commonly 60, flattens '
              'that gap: rank 1 versus rank 2 becomes 1/61 versus 1/62, a '
              'difference of under two percent, so RRF ends up caring much '
              'more about consistently ranking reasonably well across '
              'multiple lists than about occasionally being ranked #1 in '
              'just one. Raising k further flattens the score differences '
              'between adjacent ranks, making the fused order depend more '
              'on how many lists a document appears in at all, and less on '
              'its exact position within each list.',
        ),
        SelfCheckQuestion(
          question:
              'p3 was ranked #1 by BM25, yet p1 — never ranked #1 by either '
              'retriever alone — scores higher after fusion. How is that '
              'possible, and is it a bug?',
          expectedAnswer:
              'Not a bug — it is the mechanism working as intended. RRF '
              'only credits a document with 1/(k+rank) from each list it '
              'actually appears in, and zero from lists where it is '
              'absent. p3 is #1 in BM25 but only #3 in dense, while p1 is '
              '#2 in BM25 and #1 in dense — two solidly good positions '
              'instead of one great one, and since 1/(k+1), 1/(k+2) and '
              '1/(k+3) are all close in value once k=60, "good in every '
              'list" edges out "great in one list, merely present in the '
              'other." The intuition is that a passage multiple '
              'independent retrieval strategies agree is reasonably '
              'relevant is safer to trust than one only a single method '
              'ranks at the very top.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-rag-cross-encoder-rerank',
      title: 'Re-rank a bi-encoder shortlist with cross-encoder scores',
      prompt: [
        ProseBlock(
          'Implement rerank(candidates, cross_encoder_scores, top_n), '
          'which reorders a list of (doc_id, text, bi_encoder_score) tuples '
          'by their cross_encoder_scores instead, and returns only the top '
          'top_n candidates. You are not implementing a cross-encoder '
          'model — the scores are given, precomputed, exactly as they '
          'would arrive from a rerank API call over this shortlist.',
        ),
        ProseBlock(
          'Print the bi-encoder order and the reranked order side by side '
          'and look at which candidate drops out of the top 2 once the '
          'cross-encoder actually checks whether each passage answers the '
          'query rather than just resembles it.',
        ),
      ],
      starterCode: '''
candidates = [
    ("doc_async", "Uploads are processed asynchronously; larger files may "
                  "take longer to appear.", 0.81),
    ("doc_limit", "The maximum size for a single upload is 500MB; larger "
                  "files must use the chunked upload API.", 0.77),
    ("doc_batch", "Multiple files can be uploaded at once via the batch "
                  "endpoint.", 0.74),
    ("doc_chunked", "The chunked upload API accepts files up to 5GB in "
                    "total.", 0.68),
]
query = "What is the maximum file size for a single upload?"

# A cross-encoder was already run over this shortlist -- implement the
# reordering, not the model itself.
cross_encoder_scores = {
    "doc_async": 0.18,
    "doc_limit": 0.97,
    "doc_batch": 0.12,
    "doc_chunked": 0.55,
}


def rerank(candidates, cross_encoder_scores, top_n=2):
    """Return the top_n candidates ordered by cross_encoder_scores,
    best first."""
    ...


print("bi-encoder order:", [c[0] for c in candidates])
print("reranked top 2:  ", [c[0] for c in rerank(candidates, cross_encoder_scores, top_n=2)])
''',
      solutionCode: '''
candidates = [
    ("doc_async", "Uploads are processed asynchronously; larger files may "
                  "take longer to appear.", 0.81),
    ("doc_limit", "The maximum size for a single upload is 500MB; larger "
                  "files must use the chunked upload API.", 0.77),
    ("doc_batch", "Multiple files can be uploaded at once via the batch "
                  "endpoint.", 0.74),
    ("doc_chunked", "The chunked upload API accepts files up to 5GB in "
                    "total.", 0.68),
]
query = "What is the maximum file size for a single upload?"

cross_encoder_scores = {
    "doc_async": 0.18,
    "doc_limit": 0.97,
    "doc_batch": 0.12,
    "doc_chunked": 0.55,
}


def rerank(candidates, cross_encoder_scores, top_n=2):
    """Return the top_n candidates ordered by cross_encoder_scores,
    best first."""
    ordered = sorted(candidates, key=lambda c: -cross_encoder_scores[c[0]])
    return ordered[:top_n]


print("bi-encoder order:", [c[0] for c in candidates])
# ['doc_async', 'doc_limit', 'doc_batch', 'doc_chunked']

print("reranked top 2:  ", [c[0] for c in rerank(candidates, cross_encoder_scores, top_n=2)])
# ['doc_limit', 'doc_chunked']
# doc_async led the bi-encoder ranking on vocabulary overlap with "uploads"
# and "files" alone, and drops out of the top 2 entirely once the
# cross-encoder actually checks whether each passage answers the question.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The bi-encoder ranked doc_async above doc_limit, even though '
              'doc_limit is the passage that actually states the 500MB '
              'limit. Both are about uploads. Why does a bi-encoder score '
              'the wrong one higher?',
          expectedAnswer:
              'A bi-encoder embeds the query and each document completely '
              'independently — it never sees them together — so its score '
              'reflects overall topical and lexical proximity of the two '
              'embeddings, not whether the document actually answers what '
              'is asked. "uploads," "files," and "processed" are shared '
              'vocabulary between the query and doc_async, pulling their '
              'independently-computed embeddings close together, while '
              'doc_limit\'s phrasing shares less surface vocabulary with '
              'the query despite being the literal answer. A cross-encoder '
              'does not have this blind spot because it processes the '
              'concatenated query-and-document pair through shared '
              'attention layers, so it can directly learn that a question '
              'about a size limit should reward numeric limit language even '
              'when the surface wording differs.',
        ),
        SelfCheckQuestion(
          question:
              'Why can\'t the two-stage retrieve-then-rerank pattern just '
              'run the cross-encoder over the entire corpus and skip the '
              'first-stage bi-encoder retrieval altogether?',
          expectedAnswer:
              'Because a cross-encoder score can only be computed once both '
              'the query and a specific document are known — there is '
              'nothing to precompute offline, unlike a bi-encoder embedding '
              'which is computed once per document at indexing time and '
              'reused for every future query. Scoring the full corpus with '
              'a cross-encoder means running one transformer forward pass '
              'per document, per query; over a corpus of a million chunks, '
              'that is a million forward passes on every single question, '
              'computationally infeasible at interactive latencies. The '
              'bi-encoder stage exists purely to cheaply cut the corpus '
              'down from millions to a shortlist of tens or hundreds of '
              'plausible candidates using precomputed vectors and fast '
              'nearest-neighbour search, so the expensive cross-encoder '
              'only ever has to score that small shortlist.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-rag-multi-hop',
      title: 'Chain two retrieval hops to answer a question single-shot cannot',
      prompt: [
        ProseBlock(
          'Implement retrieve(query, corpus), a toy retriever that scores '
          'each document by word overlap with the query and returns the '
          'best match, and extract_name(passage_text), which pulls the two '
          'words following " by " out of a passage. Then implement '
          'multi_hop_retrieve(question, corpus), which retrieves hop one, '
          'extracts a name from it, builds a hop-two query from that name, '
          'and retrieves again.',
        ),
        ProseBlock(
          'Compare a single call to retrieve(question, corpus) against '
          'multi_hop_retrieve(question, corpus) and look at whether the '
          'single-hop passage actually contains the fact the question asks '
          'for.',
        ),
      ],
      starterCode: '''
corpus = {
    "anthropic_team": "Interpretability research at Anthropic is led by "
                       "Chris Olah.",
    "chris_bio": "Chris Olah worked at OpenAI and Google Brain before "
                 "joining Anthropic.",
    "claude_pricing": "Claude API pricing is billed per million tokens for "
                       "input and output.",
}

question = ("What company did the person who led interpretability research "
            "at Anthropic work at before joining Anthropic?")


def normalize(text):
    """Lowercase words, stripped of leading/trailing punctuation, as a set."""
    return {w.strip('.,!?\\'"()').lower() for w in text.split()}


def retrieve(query, corpus):
    """Return the (doc_id, text) pair with the most word overlap with
    query."""
    ...


def extract_name(passage_text):
    """Toy entity extraction: the two words following ' by ' in the
    passage."""
    ...


def multi_hop_retrieve(question, corpus):
    """Retrieve hop 1, extract a name from it, retrieve hop 2 using that
    name. Return [(doc_id, text), (doc_id, text)] for both hops in order."""
    ...


single_id, single_text = retrieve(question, corpus)
print("single-hop:", single_id, "->", single_text)

for doc_id, text in multi_hop_retrieve(question, corpus):
    print("hop:", doc_id, "->", text)
''',
      solutionCode: '''
corpus = {
    "anthropic_team": "Interpretability research at Anthropic is led by "
                       "Chris Olah.",
    "chris_bio": "Chris Olah worked at OpenAI and Google Brain before "
                 "joining Anthropic.",
    "claude_pricing": "Claude API pricing is billed per million tokens for "
                       "input and output.",
}

question = ("What company did the person who led interpretability research "
            "at Anthropic work at before joining Anthropic?")


def normalize(text):
    """Lowercase words, stripped of leading/trailing punctuation, as a set."""
    return {w.strip('.,!?\\'"()').lower() for w in text.split()}


def retrieve(query, corpus):
    """Return the (doc_id, text) pair with the most word overlap with
    query."""
    scored = [
        (doc_id, text, len(normalize(query) & normalize(text)))
        for doc_id, text in corpus.items()
    ]
    scored.sort(key=lambda row: -row[2])
    doc_id, text, _ = scored[0]
    return doc_id, text


def extract_name(passage_text):
    """Toy entity extraction: the two words following ' by ' in the
    passage."""
    words = passage_text.split()
    by_index = words.index("by")
    name_words = words[by_index + 1 : by_index + 3]
    return " ".join(w.strip(".") for w in name_words)


def multi_hop_retrieve(question, corpus):
    """Retrieve hop 1, extract a name from it, retrieve hop 2 using that
    name. Return [(doc_id, text), (doc_id, text)] for both hops in order."""
    hop1_id, hop1_text = retrieve(question, corpus)
    name = extract_name(hop1_text)
    hop2_query = f"{name} previous employer before Anthropic"
    hop2_id, hop2_text = retrieve(hop2_query, corpus)
    return [(hop1_id, hop1_text), (hop2_id, hop2_text)]


single_id, single_text = retrieve(question, corpus)
print("single-hop:", single_id, "->", single_text)
# single-hop: anthropic_team -> Interpretability research at Anthropic is
# led by Chris Olah.
# Names who leads the team -- but says nothing about where they worked
# before, so a single-hop system has no way to answer the actual question
# from this passage alone.

for doc_id, text in multi_hop_retrieve(question, corpus):
    print("hop:", doc_id, "->", text)
# hop: anthropic_team -> Interpretability research at Anthropic is led by
# Chris Olah.
# hop: chris_bio -> Chris Olah worked at OpenAI and Google Brain before
# joining Anthropic.
# Hop 2's query -- "Chris Olah previous employer before Anthropic" -- only
# exists because hop 1 supplied the name; the original question never
# mentions Chris Olah at all.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The single-hop call and the first step of the multi-hop '
              'chain both call retrieve() with the exact same question and '
              'get the exact same passage back. So what does the two-hop '
              'version actually add?',
          expectedAnswer:
              'retrieve() itself does not change — what changes is that '
              'the multi-hop version does not stop there. It treats the '
              'first retrieved passage as a source of an intermediate fact '
              '(the name "Chris Olah") rather than as the final answer, '
              'uses that extracted fact to build a brand-new, more '
              'specific query, and issues a second retrieval call the '
              'single-hop version never makes. The single-hop system hands '
              'the LLM the "who leads the team" passage and asks it to '
              'answer a question about employment history that passage '
              'never mentions; the multi-hop system uses that same passage '
              'as a stepping stone to reach chris_bio, which actually '
              'contains the requested fact. The value is not a smarter '
              'first retrieval — it is recognising that one retrieval was '
              'never going to be enough, and chaining a second one off the '
              'first\'s output.',
        ),
        SelfCheckQuestion(
          question:
              'This exercise hardcodes a fixed two-hop chain: always '
              'exactly one extraction, one follow-up query, then stop. '
              'What real question would break that fixed structure, and '
              'what would a more general multi-hop system need instead?',
          expectedAnswer:
              'Any question needing three or more chained facts breaks it — '
              'for example, "What company did the person who succeeded '
              'Chris Olah\'s manager at OpenAI go on to found?" needs a hop '
              'to find the manager, a hop to find who succeeded them, and '
              'a hop to find what they founded: an unknown number of steps '
              'decided by the question itself rather than a number picked '
              'in advance. A more general system needs a stopping '
              'condition decided dynamically rather than hardcoded — '
              'typically an LLM that, after each retrieval, judges whether '
              'the accumulated evidence already answers the question or '
              'whether another hop is needed, up to some hop budget that '
              'caps runaway loops. Hardcoding "exactly two hops" only works '
              'because this particular exercise\'s question happens to '
              'need exactly two; production multi-hop systems cannot '
              'assume the hop count in advance.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-rag-self-query',
      title: 'Parse a natural-language query into metadata filters',
      prompt: [
        ProseBlock(
          'Implement parse_query(question, schema) that takes a natural '
          'language question and a metadata schema (a dict mapping field '
          'names to their types/descriptions) and returns (filters, search), '
          'where filters is a dict of field->value constraints and search '
          'is the cleaned semantic search string.',
        ),
        ProseBlock(
          'For this exercise, use simple keyword matching rather than an '
          'LLM call: detect date constraints ("after March 2024"), type '
          'constraints ("policy document"), and strip those from the '
          'search string. The point is the structured output format, not '
          'the parsing sophistication.',
        ),
      ],
      starterCode: '''
import re

schema = {
    "doc_type": "one of: policy, faq, changelog",
    "date": "ISO date the document was published",
    "author": "document author name",
}

questions = [
    "What changed in the refund policy after March 2024?",
    "Show me the changelog written by Alice about authentication.",
    "How do I reset my password?",
]


def parse_query(question, schema):
    """Return (filters_dict, search_string) parsed from the question."""
    ...


for q in questions:
    filters, search = parse_query(q, schema)
    print(f"Q: {q}")
    print(f"  filters: {filters}")
    print(f"  search:  {search!r}")
    print()
''',
      solutionCode: '''
import re

schema = {
    "doc_type": "one of: policy, faq, changelog",
    "date": "ISO date the document was published",
    "author": "document author name",
}

questions = [
    "What changed in the refund policy after March 2024?",
    "Show me the changelog written by Alice about authentication.",
    "How do I reset my password?",
]


def parse_query(question, schema):
    filters = {}
    search = question

    # Detect doc_type mentions
    for doc_type in ["policy", "faq", "changelog"]:
        if doc_type in question.lower():
            filters["doc_type"] = doc_type
            search = re.sub(rf"\\b{doc_type}\\b", "", search, flags=re.IGNORECASE)

    # Detect date constraints
    date_match = re.search(r"after\\s+(\\w+\\s+\\d{4})", question, re.IGNORECASE)
    if date_match:
        filters["date"] = {"\$gte": date_match.group(1)}
        search = re.sub(r"after\\s+\\w+\\s+\\d{4}", "", search, flags=re.IGNORECASE)

    # Detect author mentions
    author_match = re.search(r"(?:written\\s+by|by)\\s+([A-Z][a-z]+)", question)
    if author_match:
        filters["author"] = author_match.group(1)
        search = re.sub(r"(?:written\\s+by|by)\\s+[A-Z][a-z]+", "", search)

    # Clean up the search string
    search = " ".join(search.split()).strip()
    return filters, search


for q in questions:
    filters, search = parse_query(q, schema)
    print(f"Q: {q}")
    print(f"  filters: {filters}")
    print(f"  search:  {search!r}")
    print()

# Q: What changed in the refund policy after March 2024?
#   filters: {'doc_type': 'policy', 'date': {'\$gte': 'March 2024'}}
#   search:  'What changed in the refund ?'
#
# Q: Show me the changelog written by Alice about authentication.
#   filters: {'doc_type': 'changelog', 'author': 'Alice'}
#   search:  'Show me the written about authentication.'
#
# Q: How do I reset my password?
#   filters: {}
#   search:  'How do I reset my password?'
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The third question ("How do I reset my password?") produces '
              'no filters at all. Is that a failure of the parser, or '
              'correct behaviour?',
          expectedAnswer:
              'Correct behaviour. Some questions genuinely carry no '
              'metadata constraints — they are pure semantic search '
              'queries. The parser correctly returns an empty filters dict '
              'and passes the full question as the search string. Forcing '
              'the parser to always produce filters would add phantom '
              'constraints that narrow the search incorrectly. The lesson\'s '
              'self-querying pattern is: extract metadata constraints that '
              'DO exist, and let the rest flow through to semantic search '
              'untouched.',
        ),
        SelfCheckQuestion(
          question:
              'The search string after stripping metadata is sometimes '
              'grammatically broken ("What changed in the refund ?"). '
              'Does this matter for retrieval, and why or why not?',
          expectedAnswer:
              'It matters less than it looks like it would. The embedding '
              'model processes the semantic content, not grammatical '
              'correctness — "refund" and "changed" are the key signals '
              'regardless of whether the grammar is intact. However, for '
              'keyword-based sparse retrieval (BM25), the stripped search '
              'may miss function words that help disambiguate. In practice, '
              'LLM-based query parsing produces cleaner search strings '
              'because the model can rephrase rather than just delete — but '
              'this exercise demonstrates the structural idea: separate '
              'constraints from search intent.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 240000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Advanced RAG patterns in about four minutes. Plain top-k '
              'retrieval is like going to a library and grabbing the first '
              'three books closest to the door — they\'re probably relevant, '
              'but you\'ve got blind spots. A fixed k can\'t be simultaneously '
              'safe against missing something important AND not drowning in '
              'noise. And cosine similarity measures "about the same topic," '
              'not "actually correct" — a passage that flatly contradicts the '
              'right answer can still score high because it talks about the '
              'same thing.',
          startMs: 0,
          endMs: 40000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Hybrid search patches one half: run a keyword method like '
              'BM25 alongside your embedding search. Think of it as having '
              'two librarians — one who knows topics, one who knows exact '
              'phrases. Exact IDs, error codes, part numbers get found by '
              'the keyword librarian even when the topic librarian glosses '
              'over them. The trick is combining two differently-scaled '
              'ranked lists, and Reciprocal Rank Fusion does it by ignoring '
              'raw scores — just sum one over a constant plus each rank.',
          startMs: 40000,
          endMs: 80000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Fusion fixes coverage, not precision. That\'s where re-ranking '
              'comes in: retrieve a wide shortlist cheaply, then re-score '
              'it with a cross-encoder — a model that reads the query and '
              'each candidate TOGETHER instead of separately, so it can tell '
              '"about the same topic" from "actually answers the question." '
              'Like having a second expert who actually reads the passage '
              'alongside your question, rather than just comparing labels. '
              'Too slow for a million documents, cheap enough for a hundred.',
          startMs: 80000,
          endMs: 120000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Some questions need more than one retrieval no matter how '
              'good the ranking is. "Where did the CEO work before?" needs '
              'one lookup to find the CEO\'s name, and a second lookup built '
              'from that name to find their job history. A single embedding '
              'of the original question is never near that second passage '
              'because the question doesn\'t contain the name yet. It\'s like '
              'trying to find someone\'s previous job without knowing their '
              'name — you have to look it up first.',
          startMs: 120000,
          endMs: 160000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And real corpora carry structure a search string throws '
              'away — dates, categories, authors. Self-querying retrieval '
              'hands the question to an LLM along with a schema of '
              'filterable fields, and gets back a metadata filter plus a '
              'clean semantic query. A stale document with nearly identical '
              'wording to the current one gets excluded by the date filter '
              'before similarity search even has to guess. It\'s like saying '
              '"only show me documents from 2024 about refund policies" '
              'instead of just "refund policies."',
          startMs: 160000,
          endMs: 200000,
        ),
        PodcastSegment(
          id: 'c6',
          speaker: 'Guest',
          text:
              'None of this is free, so layer it deliberately. Hybrid '
              'search is close to a default. Re-ranking earns its cost on '
              'large or high-stakes corpora. Multi-hop only for genuinely '
              'multi-hop questions. Self-querying only where metadata '
              'actually exists. And always measure — recall and MRR on a '
              'held-out set before and after, plus an answer-level check, '
              'because better retrieval doesn\'t automatically mean a '
              'better final answer.',
          startMs: 200000,
          endMs: 240000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 480000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Let\'s go deeper on what happens once plain top-k retrieval '
              'stops being enough. Think of it like searching a library '
              'where the first three books near the door are probably good, '
              'but you keep missing the perfect book tucked in the back '
              'corner. There\'s no single k that\'s safe against both missing '
              'relevant passages AND not drowning the prompt in noise. And '
              'a high similarity score tells you two passages are about the '
              'same topic — not that either one is actually correct.',
          startMs: 0,
          endMs: 60000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'That second one bites hard. Ask whether a medication '
              'interacts with alcohol, and "no known interaction" embeds '
              'almost identically to its opposite because both share the '
              'same words about the same medication. A bi-encoder can\'t '
              'check which one is true — it only measures how close the '
              'vectors sit. And exact tokens like error codes are exactly '
              'what a general-purpose embedding model is worst at — paste '
              '"ERR_4029" and you\'ll get three plausible-sounding wrong '
              'passages instead of the one that actually contains it.',
          startMs: 60000,
          endMs: 120000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Hybrid search covers the exact-token gap by running BM25 '
              'alongside embedding search — like having a keyword-obsessed '
              'librarian AND a topic-savvy one working together. BM25 rewards '
              'exact matches and doesn\'t care about synonyms, the mirror '
              'image of what dense retrieval is good at. But you can\'t just '
              'average their scores — BM25 is unbounded, cosine is bounded '
              'between -1 and 1, and blending them produces a number that '
              'silently stops working as your corpus grows.',
          startMs: 120000,
          endMs: 180000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Reciprocal Rank Fusion sidesteps that by throwing away '
              'scores and keeping only ranks. A document\'s RRF score is '
              'the sum, across every list it\'s in, of one over a constant '
              'k — usually sixty — plus its rank. Say BM25 puts doc X first '
              'and dense puts doc W first, but both rank doc Y second. Y '
              'beats both X and W in the fusion despite never topping either '
              'list alone — because it earns a decent contribution from two '
              'lists instead of one big hit and a zero. Consistency across '
              'retrievers wins over a single first place.',
          startMs: 180000,
          endMs: 240000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Fusion fixes what\'s in the candidate set, not how precisely '
              'it\'s ordered — that\'s re-ranking\'s job. The embedding model '
              'used so far is a bi-encoder: it encodes query and document '
              'completely separately, then compares vectors. That\'s why it\'s '
              'fast — every document\'s vector is precomputed offline. But '
              'it\'s also the limit on accuracy — the model never sees the '
              'query and document together, so it can\'t represent how they '
              'actually interact.',
          startMs: 240000,
          endMs: 300000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'A cross-encoder removes that separation: query and document '
              'go in together, run through shared attention, and out comes '
              'one relevance score. The model can directly see how the two '
              'texts relate. Consistently more accurate, but also impossible '
              'to precompute — the score doesn\'t exist until the query '
              'arrives. So the pattern is two-stage: retrieve a wide '
              'shortlist cheaply, fifty to a hundred candidates, then '
              'rerank just that shortlist with the expensive model before '
              'deciding what goes in the prompt.',
          startMs: 300000,
          endMs: 360000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Some questions defeat all of that, because the fact being '
              'asked for isn\'t near anything mentioning the question\'s '
              'subject. "What company did the founder work at before?" — '
              'one document says who founded the company, a completely '
              'different bio page holds the employment history and never '
              'even mentions the company\'s founding. A single retrieval '
              'finds the founding document, which is genuinely relevant, '
              'and stops — having retrieved something real that structurally '
              'can\'t answer what was asked.',
          startMs: 360000,
          endMs: 420000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'The fix chains retrieval: hop one finds the founder\'s name, '
              'an extraction step pulls it out, hop two builds a new query '
              'from that name and retrieves again — against a passage the '
              'original question\'s embedding was never near. And for '
              'metadata, self-querying hands the question to an LLM with a '
              'schema of filterable fields and gets back a filter plus a '
              'clean search string, so a stale document gets excluded by '
              'its date outright. None of these are free, so add each only '
              'where its specific failure mode is actually showing up.',
          startMs: 420000,
          endMs: 480000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 910000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Deep dive on advanced RAG — everything that kicks in once '
              'naive top-k stops being enough. Think of it as upgrading from '
              'a basic library search to having research assistants who '
              'cross-check each other, follow citation trails, and know '
              'exactly which shelf to ignore. We\'ll cover: the structural '
              'failure modes of fixed-k dense retrieval, hybrid search with '
              'Reciprocal Rank Fusion, bi-encoder versus cross-encoder '
              're-ranking, multi-hop retrieval, query construction for '
              'metadata-rich corpora, and when each pattern earns its cost.',
          startMs: 0,
          endMs: 70000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with the first failure mode: the recall-precision '
              'tradeoff baked into any fixed k. Ask for three chunks and '
              'a genuinely relevant fourth-ranked passage is invisible — '
              'not deprioritised, simply gone, because retrieval is the only '
              'stage that looks at the whole corpus. Ask for twenty to be '
              'safe and you flood the prompt with topically adjacent filler, '
              'burning context budget on nothing. There\'s no k that\'s '
              'simultaneously safe against both failure modes for every '
              'query shape.',
          startMs: 70000,
          endMs: 140000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'The second failure mode is sharper: cosine similarity measures '
              'topical closeness, not correctness. Ask whether a medication '
              'interacts with alcohol, and "no known interaction" sits almost '
              'on top of its exact opposite in embedding space because both '
              'share the medication name, "alcohol," and identical grammar. '
              'A bi-encoder can\'t check which one is true — it only measures '
              'vector distance. It\'ll hand back either one with a high score, '
              'and the generator will produce a fluent wrong answer from the '
              'bad one just as readily as the good one.',
          startMs: 140000,
          endMs: 210000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'The third failure mode is the mirror image: exact tokens. '
              'A part number, an error code, a clause reference — these are '
              'precisely what embeddings are worst at representing. An error '
              'code looks like noise to a model trained on natural language. '
              'Paste "ERR_4029" and dense retrieval returns three plausible-'
              'sounding unrelated passages instead of the one containing it, '
              'because the code barely moved the similarity score — it just '
              'doesn\'t have the vocabulary pattern embeddings are good at.',
          startMs: 210000,
          endMs: 280000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Hybrid search fixes exactly that gap by keeping the older '
              'technology around. BM25 scores a document by how often the '
              'query\'s exact terms appear, weighted by how rare each term '
              'is across the corpus — so "ERR_4029" contributes heavily '
              'while common words like "the" contribute almost nothing. '
              'BM25 has zero notion of synonyms — "car" scores zero against '
              '"automobile." Running both retrievers together means a '
              'part-number query gets rescued by BM25 and a paraphrase '
              'gets rescued by the embedding model.',
          startMs: 280000,
          endMs: 350000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'The part everyone gets wrong first is merging the two lists. '
              'You can\'t just average a BM25 score — unbounded, shifting '
              'with corpus size — and a cosine similarity bounded between '
              '-1 and 1. Averaging 0.83 with 11.2 produces a meaningless '
              'number, and whatever weight happened to work today silently '
              'degrades as your corpus grows. Reciprocal Rank Fusion '
              'sidesteps the scale mismatch by throwing the scores away '
              'and keeping only rank position.',
          startMs: 350000,
          endMs: 420000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'RRF scores a document as the sum of one over k-plus-rank '
              'across every list it appears in — k is conventionally sixty, '
              'and its job is damping. Concretely: BM25 ranks doc X first, '
              'doc Y second; dense ranks doc W first, doc Y second. Doc Y '
              'accumulates two mid-sized contributions and beats both X '
              'and W, which each get one large contribution from first '
              'place and a flat zero from the list they\'re absent from. '
              'Consistency across retrievers beats a single win — that\'s '
              'the whole mechanism.',
          startMs: 420000,
          endMs: 490000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Fusion widens the candidate set but doesn\'t order it with '
              'much precision, because both BM25 and bi-encoders score '
              'query and document independently. A bi-encoder encodes the '
              'query and document in two completely separate passes, neither '
              'aware the other exists, then compares vectors cheaply. That '
              'independence makes it fast — every document vector is '
              'precomputed offline — and exactly what caps its accuracy: the '
              'model never sees the query and document side by side.',
          startMs: 490000,
          endMs: 560000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'A cross-encoder removes that independence: concatenate query '
              'and candidate into one input, run through shared attention, '
              'and output one relevance score. Because tokens from both '
              'sides attend to each other, the model can represent what '
              'bi-encoders structurally can\'t — whether a passage actually '
              'answers, contradicts, or just shares vocabulary. Consistently '
              'more accurate, but the score can\'t be precomputed. Run it '
              'over a million documents and you\'ve got a million forward '
              'passes. Run it over the fifty to hundred candidates hybrid '
              'search already narrowed to, and it\'s a few hundred '
              'milliseconds — which is the entire retrieve-then-rerank '
              'pattern in a nutshell.',
          startMs: 560000,
          endMs: 630000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Even a perfect re-ranker can\'t fix a question that needs '
              'more than one retrieval. "What company did the founder work '
              'at before starting it?" is the canonical shape: no single '
              'passage in a typical corpus says both who founded the '
              'company AND where they worked previously. One document '
              'establishes the founder, a completely different bio page '
              'holds the employment history and likely never mentions the '
              'company\'s founding. Retrieval finds the founding document — '
              'genuinely relevant — and stops there, having fetched '
              'something real that structurally can\'t answer the question.',
          startMs: 630000,
          endMs: 700000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'The dangerous part: this doesn\'t look like a retrieval miss. '
              'A plain miss surfaces something visibly off-topic. A '
              'premature single hop surfaces something genuinely relevant '
              'to part of the question — it just doesn\'t hold the specific '
              'fact being asked for. The fix chains retrieval: hop one '
              'finds the founder\'s name, extraction pulls it out, hop two '
              'builds a new query from that name and retrieves again '
              'against a passage the original embedding was never near. '
              'Deciding when to stop matters too — upfront decomposition '
              'plans every hop before seeing results; iterative agentic '
              'retrieval replans after each result, handling surprises at '
              'the cost of an LLM call per hop.',
          startMs: 700000,
          endMs: 770000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Separately from all of that, real corpora carry structure a '
              'plain search string throws away — dates, document types, '
              'authors. "What changed in the refund policy after March 2024" '
              'bundles a metadata filter with a semantic string, and '
              'treating the whole sentence as one embedding query wastes '
              'the date — the model was never built to encode "after March '
              '2024" as a similarity signal. Self-querying hands the '
              'question to an LLM with a schema of filterable fields and '
              'gets back a structured query: a date filter plus a cleaned '
              'search string. The metadata filter is exact — a document is '
              'either after March or it isn\'t — eliminating stale documents '
              'before semantic search even runs.',
          startMs: 770000,
          endMs: 840000,
        ),
        PodcastSegment(
          id: 'd13',
          speaker: 'Host',
          text:
              'None of this is free, and stacking every pattern onto every '
              'query is rarely right. Hybrid search is close to a default — '
              'cheap, buys real robustness. Re-ranking earns its cost on '
              'large, noisy corpora; it\'s overkill against a small curated '
              'knowledge base. Multi-hop only for genuinely multi-hop '
              'questions. Query construction only where clean metadata '
              'exists. And always measure — held-out recall and MRR before '
              'and after, plus an answer-level check, because better '
              'retrieval metrics don\'t automatically mean a better final '
              'answer, and every gain has to be weighed against its added '
              'latency.',
          startMs: 840000,
          endMs: 910000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Naive top-k retrieval has structural blind spots',
      body:
          'No fixed k is simultaneously safe against missing a relevant '
          'passage and burying the prompt in noise. Embedding similarity '
          'measures topical closeness, not correctness, so a passage that '
          'contradicts the right answer can outscore the correct one, and '
          'exact tokens like part numbers or error codes are exactly what '
          'general-purpose embeddings represent worst.',
    ),
    SummaryCard(
      title: 'Hybrid search and RRF fix coverage; re-ranking fixes ordering',
      body:
          'BM25 and dense retrieval fail in opposite ways, so hybrid search '
          'runs both and merges the ranked lists with Reciprocal Rank '
          'Fusion — a rank-based, scale-independent combination, not a raw '
          'score average. A cross-encoder then re-scores a wide shortlist '
          'by reading the query and each candidate jointly, catching '
          'relevance a bi-encoder\'s independent scoring cannot.',
    ),
    SummaryCard(
      title:
          'Multi-hop chaining and query construction extend retrieval '
          'further',
      body:
          'Some answers require chaining retrieval calls when the needed '
          'fact sits in a document the original query never resembles. '
          'Query construction uses an LLM to split a question into '
          'metadata filters and a semantic string against a store that '
          'supports both. Apply each pattern only where its specific '
          'failure mode actually shows up, and verify gains with held-out '
          'evaluation, not spot checks.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Reciprocal Rank Fusion (RRF)',
      definition:
          'A rank-based method for merging multiple ranked lists into one: '
          'RRF(d) = Σ 1 / (k + rank(d)) summed over every list a document '
          'appears in, with k conventionally 60. Sidesteps the problem of '
          'incompatible score scales by using only rank position.',
    ),
    KeyConcept(
      term: 'Bi-encoder',
      definition:
          'An embedding model that encodes a query and a document '
          'completely independently, comparing the resulting vectors '
          'afterward. Fast because document embeddings are precomputed '
          'offline, but unable to represent interactions between the query '
          'and the document since neither is seen alongside the other.',
    ),
    KeyConcept(
      term: 'Cross-encoder',
      definition:
          'A model that scores a query and a single candidate document '
          'jointly, processing their concatenation through shared '
          'attention layers to output one relevance score. More accurate '
          'than a bi-encoder because it can represent interactions, but '
          'its score cannot be precomputed, so it only runs over a small '
          'shortlist.',
    ),
    KeyConcept(
      term: 'Retrieve-then-rerank',
      definition:
          'A two-stage retrieval pattern: cheaply retrieve a wide candidate '
          'set (tens to hundreds of chunks) with hybrid or dense search, '
          'then re-score just that shortlist with a slower, more accurate '
          'cross-encoder before truncating to what goes in the prompt.',
    ),
    KeyConcept(
      term: 'Multi-hop retrieval',
      definition:
          'Chaining multiple retrieval calls where a later query is built '
          'from a fact extracted from an earlier result, needed when the '
          'answer to a question is not in any single passage close to the '
          'question\'s own embedding.',
    ),
    KeyConcept(
      term: 'Query construction (self-querying retrieval)',
      definition:
          'Using an LLM to translate a natural-language question into a '
          'structured query — metadata filters plus a semantic search '
          'string — executed against a vector store that supports both, '
          'rather than treating the whole question as one embedding query.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Combining BM25 and dense retrieval scores by averaging or '
          'weight-summing them directly.',
      correction:
          'The two scores live on incompatible, corpus-dependent scales, so '
          'a raw blend is tuned to today\'s corpus and silently degrades as '
          'the corpus changes. Use a rank-based fusion method like '
          'Reciprocal Rank Fusion, which only depends on rank position and '
          'needs no scale-matching or corpus-specific tuning.',
    ),
    Mistake(
      mistake:
          'Assuming re-ranking can recover a passage that first-stage '
          'retrieval never fetched into the candidate set.',
      correction:
          'A cross-encoder only scores what is already in the shortlist it '
          'is given; if the true answer passage was never retrieved into '
          'that set, no amount of re-ranking will surface it. Fix first-'
          'stage recall — often by adding hybrid search — before assuming '
          'a re-ranker will paper over a retrieval miss.',
    ),
    Mistake(
      mistake:
          'Applying multi-hop chaining, re-ranking, or query construction '
          'to every query regardless of whether the query actually needs '
          'it.',
      correction:
          'Each pattern adds latency and cost, and most real user '
          'questions are answerable from a single hybrid retrieval. Reserve '
          'multi-hop chaining for genuinely multi-hop question types, '
          're-ranking for large or high-stakes corpora, and query '
          'construction for corpora with real filterable metadata — and '
          'confirm the gain with a held-out evaluation before shipping it '
          'broadly.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Walk me through how Reciprocal Rank Fusion combines a BM25 '
          'ranking and a dense ranking, and why it does not just average '
          'the two scores.',
      answer:
          'RRF assigns each document a fused score equal to the sum, over '
          'every ranked list it appears in, of one divided by a constant k '
          'plus its rank in that list — RRF(d) = Σ 1/(k+rank(d)), with k '
          'conventionally 60. A document absent from a list simply '
          'contributes zero from it. The reason it avoids averaging raw '
          'scores is that BM25 and cosine similarity live on incompatible '
          'scales: BM25 is unbounded and shifts with corpus-wide term '
          'statistics, while cosine similarity is bounded between -1 and '
          '1, so a direct blend produces a number with no principled '
          'meaning and needs re-tuning every time the corpus changes '
          'enough to shift BM25\'s statistics. Working with rank instead of '
          'raw score sidesteps that entirely — rank 1 means the same thing '
          'regardless of which scoring function produced it. The constant '
          'k also matters: it damps the gap between adjacent ranks so that '
          'showing up reasonably highly in multiple lists tends to beat an '
          'occasional first-place finish in just one, which in practice '
          'rewards documents multiple independent retrieval methods agree '
          'on over documents only one method loves.',
    ),
    InterviewQuestion(
      question:
          'What is the actual architectural difference between a '
          'bi-encoder and a cross-encoder, and why does that difference '
          'mean re-ranking cannot replace first-stage retrieval?',
      answer:
          'A bi-encoder runs the query and a document through the network '
          'in two entirely separate passes, producing two independent '
          'vectors that are then compared with a cheap operation like '
          'cosine similarity — neither pass ever sees the other text. That '
          'independence is exactly what makes it usable at retrieval '
          'scale: every document\'s vector can be computed once, offline, '
          'at indexing time, and reused unchanged for every future query, '
          'so comparing a new query against millions of stored vectors is '
          'cheap. A cross-encoder gives up that independence for accuracy: '
          'it concatenates the query and one document into a single input '
          'and runs the pair through shared attention layers, letting '
          'query tokens and document tokens attend directly to each other '
          'so the model can represent whether the document actually '
          'answers the question rather than merely resembling it in '
          'vocabulary. The cost is that a cross-encoder score cannot exist '
          'until a specific query is known, so nothing about it can be '
          'precomputed — scoring an entire corpus this way means one '
          'forward pass per document per query, computationally infeasible '
          'at scale. That is why the standard pattern retrieves a wide '
          'candidate set cheaply with a bi-encoder or hybrid search first, '
          'then runs the cross-encoder only over that shortlist: the '
          'bi-encoder stage is what makes cross-encoder accuracy '
          'affordable at all, not a step re-ranking can skip.',
    ),
    InterviewQuestion(
      question:
          'Describe a query that would require multi-hop retrieval, and '
          'explain what goes wrong if a RAG system only does a single '
          'retrieval pass on it.',
      answer:
          '"What company did the founder of Anthropic work at before '
          'starting it?" is a clean example: no single passage in a '
          'typical corpus states both who founded Anthropic and where that '
          'person worked previously, because those are two different facts '
          'that live in two different documents — one about the company\'s '
          'founding, one a biography that likely never mentions Anthropic '
          'at all in its account of prior employment. A single-pass system '
          'embeds the full question and retrieves the passage closest to '
          'it, which is genuinely the founding-story document, since that '
          'is what the question most resembles — and then has to answer a '
          'question about prior employment from a passage that never '
          'contains that fact. The dangerous part is that this does not '
          'look like an obvious retrieval failure: the retrieved passage '
          'is real and relevant to part of the question, so a model '
          'instructed to be helpful often produces a confident, plausible-'
          'sounding guess rather than admitting the passage stops short, '
          'which is harder to catch than a retrieval miss that surfaces '
          'something visibly off-topic. The fix is to chain retrieval: use '
          'the founding-story passage to extract the founder\'s name, '
          'build a new query from that name, and retrieve a second time — '
          'against a passage the original question\'s embedding was never '
          'close to, because the original question never contained that '
          'name to search with.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'Auto-Retrieval from a Vector Database — LlamaIndex Docs',
    url:
        'https://developers.llamaindex.ai/python/examples/vector_stores/chroma_auto_retriever/',
    description:
        'Documents the auto-retriever / self-querying pattern of using an '
        'LLM to infer metadata filters plus a semantic query string from a '
        'natural-language question, the basis for this lesson\'s query-'
        'construction section.',
  ),
  Source(
    title: 'Reranking — Quickstart | Cohere',
    url: 'https://docs.cohere.com/docs/reranking-quickstart',
    description:
        'Cohere\'s own walkthrough of passing a query and a list of '
        'already-retrieved documents to a rerank endpoint that scores them '
        'jointly, backing the two-stage retrieve-then-rerank pattern '
        'described here.',
  ),
  Source(
    title:
        'MultiHop-RAG: Benchmarking Retrieval-Augmented Generation for '
        'Multi-Hop Queries (Tang & Yang, 2024)',
    url: 'https://arxiv.org/abs/2401.15391',
    description:
        'The benchmark paper showing that standard RAG systems answer '
        'multi-hop queries poorly because the needed evidence is spread '
        'across documents no single retrieval pass surfaces together, the '
        'basis for this lesson\'s multi-hop retrieval section.',
  ),
];

const List<Source> _furtherReading = <Source>[
  Source(
    title: 'Improving Document Retrieval with Reranking — DeepLearning.AI',
    url: 'https://www.deeplearning.ai/short-courses/advanced-retrieval-for-ai/',
    description:
        'Short course covering cross-encoder reranking, query expansion, and hybrid search '
        'with practical code examples using Cohere and Chroma.',
  ),
  Source(
    title: 'Query Rewriting for Retrieval-Augmented Large Language Models (Ma et al., 2024)',
    url: 'https://arxiv.org/abs/2305.14283',
    description:
        'Paper surveying query rewriting and decomposition techniques — reformulating, '
        'step-back prompting, and sub-query generation — used in production RAG systems.',
  ),
  Source(
    title: 'Self-RAG: Learning to Retrieve, Generate, and Critique through Self-Reflection (Asai et al., 2023)',
    url: 'https://arxiv.org/abs/2310.11511',
    description:
        'The Self-RAG paper: training an LM to emit special reflection tokens to decide '
        'when to retrieve, judge passage relevance, and self-critique its own output.',
  ),
  Source(
    title: 'From On-Premises Software to RAG: Fusion of Retrieval and Generation — Microsoft Research',
    url: 'https://www.microsoft.com/en-us/research/blog/graphrag-improving-global-search-via-dynamic-community-selection/',
    description:
        'Microsoft\'s GraphRAG approach that combines knowledge graphs with vector retrieval, '
        'an emerging advanced pattern for datasets with rich entity relationships.',
  ),
];
