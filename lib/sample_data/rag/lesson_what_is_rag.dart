import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 1: the problem retrieval-augmented generation solves, the
/// two-phase architecture that solves it, and where it fits next to
/// fine-tuning and long context.
const Lesson whatIsRagLesson = Lesson(
  id: 'rag-what-is-rag',
  title: 'What is RAG',
  description:
      'Why frozen parametric knowledge causes hallucination and staleness, '
      'and how retrieving documents at query time grounds generation instead.',
  estimatedMinutes: 32,
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
      id: 'frozen-knowledge',
      heading: "Why a model's knowledge has a shelf life",
      blocks: [
        ProseBlock(
          "A language model's factual knowledge is parametric: it lives "
          "nowhere but the weights, compressed during training from whatever "
          'text the model happened to see. Nothing about that knowledge is '
          'looked up at answer time — it is baked in, the same way a fact you '
          'memorised in school is baked into your memory rather than fetched '
          "from a book. That is fast and requires no external system, and it's "
          'also the entire source of two separate failure modes.',
        ),
        ProseBlock(
          "The first is hallucination. Ask a closed-book model something it "
          'never saw enough of during training, and it does not respond with '
          '"I don\'t know" — it responds with the most statistically plausible '
          'continuation of the prompt, which is often a fluent, confident, '
          'specific-sounding answer that is simply wrong. The model has no '
          'introspective signal for "this fact is thin in my training data"; '
          'fluency and correctness are produced by the same mechanism and are '
          'not otherwise linked.',
        ),
        ProseBlock(
          'The second is staleness. Training has a cutoff date, so a model '
          'trained in early 2024 has no way to know who won an election in '
          '2025, what a company\'s refund policy became after last week\'s '
          "update, or what is in a document that did not exist until after "
          'training finished. Retraining or fine-tuning the whole model every '
          'time a fact changes is far too slow and far too expensive to be the '
          'answer for information that turns over daily.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Hallucination is not a sampling bug',
          text:
              'It is tempting to blame hallucination on randomness in '
              'decoding, but a deterministic, temperature-zero model '
              'hallucinates too. The real cause is that the model is being '
              'asked a closed-book question — answer from memory alone — for '
              'something its memory never encoded well. The fix is not a '
              'better sampler; it is giving the model something to read.',
        ),
      ],
    ),
    Section(
      id: 'what-rag-is',
      heading: 'Retrieve, then generate: the core idea',
      blocks: [
        ProseBlock(
          'Retrieval-augmented generation attacks both problems the same way: '
          'stop asking the model to answer purely from memory. At the moment '
          'a query arrives, search an external collection of documents for the '
          'passages most relevant to that query, insert those passages into '
          "the prompt as context, and only then ask the model to answer — "
          'explicitly instructed to ground its response in the supplied text '
          'rather than in whatever it recalls unaided.',
        ),
        ProseBlock(
          'This turns a closed-book exam into an open-book one. The model is '
          'still doing what it always does — predicting the next token given '
          'a prompt — but the prompt itself now contains the specific facts '
          'needed to answer correctly, retrieved fresh for this exact '
          'question. Update the document collection and the next query sees '
          'the update immediately; nothing about the model\'s weights has to '
          'change.',
        ),
        CodeBlock(
          language: 'text',
          code: '''
User query
   |
   v
[ retrieve relevant chunks from an external corpus ]
   |
   v
[ insert chunks into the prompt as context ]
   |
   v
[ LLM generates an answer grounded in that context ]
   |
   v
Answer (ideally with a citation back to the source chunk)
''',
          caption:
              'The whole mechanism in one line: look something up before '
              'answering, instead of only ever answering from memory.',
        ),
        ProseBlock(
          'Because the retrieved passages sit in the prompt in plain text, the '
          'model can quote or closely paraphrase them, and a well-built system '
          'can report which chunk and which source document a given sentence '
          'of the answer came from. That traceability — a citation trail back '
          'to a real document — is not something a purely parametric answer '
          'can offer, because there is no passage to point to; there is only '
          'the model\'s memory.',
        ),
      ],
    ),
    Section(
      id: 'two-phases',
      heading: 'Two phases: build the index once, query it forever',
      blocks: [
        ProseBlock(
          'Every RAG system splits cleanly into an offline phase and an '
          'online phase, and conflating them is a common source of confusion '
          'for anyone new to the architecture. The offline phase — indexing — '
          'happens once per document collection, or once per update to it. '
          'Documents are collected, split into manageable chunks, each chunk '
          'is converted into a vector embedding, and the embeddings are stored '
          'in a structure built for fast similarity search.',
        ),
        ProseBlock(
          'The online phase — query time — happens on every single user '
          'question, in milliseconds. The incoming query is embedded with the '
          'same embedding model used at indexing time, compared against the '
          'stored vectors to find the most similar chunks, and those chunks '
          'are assembled into a prompt alongside the original query before '
          'being sent to the LLM for generation.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Offline: run once, or whenever the source documents change.
def build_index(documents, embed_model, chunker):
    chunks = [c for doc in documents for c in chunker(doc)]
    vectors = [embed_model.encode(chunk) for chunk in chunks]
    return VectorIndex(chunks, vectors)   # persisted, not rebuilt per query


# Online: runs on every user query, using the index built above.
def answer_query(query, index, embed_model, llm, k=4):
    query_vector = embed_model.encode(query)
    top_chunks = index.search(query_vector, k=k)
    prompt = build_prompt(query, top_chunks)
    return llm.generate(prompt)
''',
          caption:
              'The expensive work — embedding an entire corpus — happens '
              'offline. The per-query work is one embedding call and one '
              'nearest-neighbour search.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'A stale index is a stale answer',
          text:
              'RAG only fixes staleness if the index is kept current. A '
              'vector index built once and never refreshed will confidently '
              'retrieve last quarter\'s policy document for a question about '
              'this quarter\'s policy — the failure mode looks identical to '
              'the parametric staleness RAG was supposed to solve, just moved '
              'one layer down the stack.',
        ),
      ],
    ),
    Section(
      id: 'walkthrough',
      heading: 'A worked example, start to finish',
      blocks: [
        ProseBlock(
          'Say an internal support bot is asked: "How many vacation days do '
          'new hires get under the 2024 policy?" A parametric-only model '
          'either never saw the company\'s HR handbook or saw an older '
          'version of it during training, so it guesses — and the guess is '
          'exactly the kind of plausible-sounding wrong answer that erodes '
          'trust in the tool.',
        ),
        CodeBlock(
          language: 'text',
          code: '''
Query: "How many vacation days do new hires get under the 2024 policy?"

Retrieved chunk (score 0.91), from hr_handbook_2024.pdf, section 4.2:
  "Effective January 2024, new hires accrue 15 paid vacation days in
  their first year, increasing to 20 days after two years of service."

Retrieved chunk (score 0.44), from hr_handbook_2022.pdf, section 4.1:
  "New hires accrue 12 paid vacation days in their first year..."
  -> below the relevance threshold used here; not included in the prompt

Assembled prompt:
  "Using only the context below, answer the question. Cite the source
  document. If the answer is not in the context, say so.

  Context:
  [hr_handbook_2024.pdf, section 4.2] Effective January 2024, new hires
  accrue 15 paid vacation days in their first year...

  Question: How many vacation days do new hires get under the 2024 policy?"

Generated answer:
  "Under the 2024 policy, new hires accrue 15 paid vacation days in
  their first year (hr_handbook_2024.pdf, section 4.2)."
''',
          caption:
              'The 2022 chunk scored high enough to be a plausible near-miss '
              'but low enough to be filtered out — retrieval quality, not the '
              'LLM, decided which facts made it into the answer.',
        ),
        ProseBlock(
          'Notice what changed. The model did not "know" the 2024 policy '
          'number any better than it did before; it was simply handed the '
          'specific paragraph containing that number and asked to summarise '
          'it faithfully, which is a task language models are very good at. '
          'The hard problem — finding the right paragraph among thousands — '
          'was solved by the retrieval step, not by the generator.',
        ),
      ],
    ),
    Section(
      id: 'rag-vs-alternatives',
      heading: 'RAG vs fine-tuning vs stuffing the whole context window',
      blocks: [
        ProseBlock(
          'RAG is one of three ways to get external knowledge into a model\'s '
          'answers, and picking the wrong one is a common design mistake. '
          'Fine-tuning bakes new information into the weights by further '
          'training on examples, which is the right tool for teaching a '
          'model a style, a tone, a tool-calling format or a narrow skill — '
          'but it is a slow, expensive way to keep up with facts that change '
          'weekly, and it does not reliably erase or override facts already '
          'in the weights, so old and new information can coexist and '
          'contradict.',
        ),
        ProseBlock(
          'Long-context stuffing skips retrieval entirely: paste the whole '
          'knowledge base into the prompt and let the model\'s attention find '
          'what matters. Modern context windows are large enough that this '
          'works for a handful of documents, but it does not scale — a '
          'corpus of a million pages does not fit in any context window at '
          'all — and even within the window, models attend less reliably to '
          'information buried in the middle of a very long prompt, a pattern '
          'researchers call "lost in the middle". It is also the most '
          'expensive option per query, since every token in the stuffed '
          'context is reprocessed on every call.',
        ),
        ProseBlock(
          'RAG\'s niche is exactly the gap between those two: knowledge that '
          'is too large to fit in context, changes too often to fine-tune '
          'against, and needs to be cited back to a source. Its cost is a new '
          'failure mode of its own — retrieval can miss the right passage, or '
          'rank a near-miss above it — so a RAG system is only as good as its '
          'retrieval step, a theme the rest of this topic returns to '
          'repeatedly.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: where the term "RAG" comes from',
          children: [
            ProseBlock(
              'The name and the architecture come from Lewis et al., '
              '"Retrieval-Augmented Generation for Knowledge-Intensive NLP '
              'Tasks" (2020). The paper combined a pretrained sequence-to-'
              'sequence model — the parametric memory — with a dense vector '
              'index over Wikipedia passages, accessed through a neural '
              'retriever — the non-parametric memory — and trained the whole '
              'system end to end so the generator learned to make use of '
              'whatever the retriever handed it.',
            ),
            ProseBlock(
              'The paper actually proposed two variants. RAG-Sequence '
              'retrieves once per query and conditions the entire generated '
              'answer on the same set of retrieved documents throughout. '
              'RAG-Token allows the model to draw on a different retrieved '
              'document for each generated token, which is more flexible but '
              'more expensive. Nearly every production RAG system today is '
              'architecturally closer to RAG-Sequence, just with the encoder-'
              'decoder swapped for a general-purpose decoder-only LLM and the '
              'retriever trained separately rather than end to end.',
            ),
            ProseBlock(
              'What survived from 2020 is the core framing: separate the '
              'model that knows how to write from the store that knows what '
              'is currently true, and connect them at query time rather than '
              'baking the second into the first.',
            ),
          ],
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'These are not mutually exclusive',
          text:
              'Production systems routinely combine all three. A model might '
              'be fine-tuned to follow a house style and call tools reliably, '
              'given a moderately large context window for recent '
              'conversation history, and use RAG for the large, frequently '
              'updated knowledge base underneath it all. The question is '
              'rarely "which one" — it is which problem each layer is there '
              'to solve.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: the cost and latency tradeoffs in production',
          children: [
            ProseBlock(
              'A RAG pipeline adds latency compared to a plain LLM call: '
              'embedding the query (typically 10-50ms for a small embedding '
              'model), running an ANN search (1-10ms for a well-tuned index, '
              'potentially more for very large corpora with metadata '
              'filtering), and then the actual LLM generation with the '
              'augmented prompt. The embedding and retrieval overhead is '
              'usually dwarfed by the LLM\'s generation time for anything '
              'more than a short answer, but on latency-sensitive '
              'applications like real-time chat, every millisecond counts.',
            ),
            ProseBlock(
              'Cost is dominated by two factors: the LLM call itself (where '
              'retrieved chunks add input tokens to the prompt), and the '
              'storage and compute for the vector index. Input tokens are '
              'typically 3-5x cheaper than output tokens, so adding context '
              'from retrieval costs less than generating more text. The index '
              'side — storing and searching millions of vectors — has a '
              'small but non-trivial ongoing cost, especially with HNSW '
              'indexes which keep the graph in memory. For a team deciding '
              'whether RAG is worth the infrastructure, the rule of thumb is: '
              'if the knowledge changes weekly or the corpus exceeds 10x the '
              'context window, RAG pays for itself; otherwise, simpler '
              'approaches (long context or no augmentation at all) are worth '
              'trying first.',
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
      id: 'ex-rag-retrieve-augment',
      title: 'A minimal retrieve-then-augment pipeline',
      prompt: [
        ProseBlock(
          'Implement retrieve(query_vector, corpus, k) that returns the k '
          'chunks whose toy embeddings are most similar to the query, using '
          'cosine similarity. Then implement assemble_prompt(query, chunks) '
          'that formats the retrieved chunks and the question into a single '
          'prompt string, the way a real RAG system would before calling an '
          'LLM.',
        ),
        ProseBlock(
          'The embeddings here are three-dimensional and hand-picked so the '
          'result is checkable by eye; a production system would use a real '
          'embedding model producing hundreds of dimensions, but the retrieval '
          'logic is identical.',
        ),
      ],
      starterCode: '''
import numpy as np

corpus = [
    ("hr_2024.pdf#4.2", "New hires accrue 15 vacation days in year one.",
     np.array([0.90, 0.10, 0.05])),
    ("hr_2022.pdf#4.1", "New hires accrue 12 vacation days in year one.",
     np.array([0.62, 0.15, 0.10])),
    ("it_policy.pdf#2.1", "Laptops are replaced every three years.",
     np.array([0.05, 0.85, 0.20])),
    ("travel_policy.pdf#1.0", "Business travel must be booked two weeks out.",
     np.array([0.08, 0.20, 0.88])),
]

query = "How many vacation days do new hires get under the 2024 policy?"
query_vector = np.array([0.88, 0.12, 0.06])   # pretend this came from an
                                               # embedding model


def cosine_similarity(a, b):
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))


def retrieve(query_vector, corpus, k=2):
    """Return the k (source, text) pairs most similar to query_vector."""
    ...


def assemble_prompt(query, chunks):
    """Build the final prompt string from the query and retrieved chunks."""
    ...


chunks = retrieve(query_vector, corpus, k=2)
print(assemble_prompt(query, chunks))
''',
      solutionCode: '''
import numpy as np

corpus = [
    ("hr_2024.pdf#4.2", "New hires accrue 15 vacation days in year one.",
     np.array([0.90, 0.10, 0.05])),
    ("hr_2022.pdf#4.1", "New hires accrue 12 vacation days in year one.",
     np.array([0.62, 0.15, 0.10])),
    ("it_policy.pdf#2.1", "Laptops are replaced every three years.",
     np.array([0.05, 0.85, 0.20])),
    ("travel_policy.pdf#1.0", "Business travel must be booked two weeks out.",
     np.array([0.08, 0.20, 0.88])),
]

query = "How many vacation days do new hires get under the 2024 policy?"
query_vector = np.array([0.88, 0.12, 0.06])


def cosine_similarity(a, b):
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))


def retrieve(query_vector, corpus, k=2):
    """Return the k (source, text) pairs most similar to query_vector."""
    scored = [
        (source, text, cosine_similarity(query_vector, vec))
        for source, text, vec in corpus
    ]
    scored.sort(key=lambda row: -row[2])
    return [(source, text) for source, text, _ in scored[:k]]


def assemble_prompt(query, chunks):
    """Build the final prompt string from the query and retrieved chunks."""
    context = "\\n".join(f"[{source}] {text}" for source, text in chunks)
    return (
        "Using only the context below, answer the question and cite the "
        "source.\\n\\n"
        f"Context:\\n{context}\\n\\n"
        f"Question: {query}"
    )


chunks = retrieve(query_vector, corpus, k=2)
print(assemble_prompt(query, chunks))

# Using only the context below, answer the question and cite the source.
#
# Context:
# [hr_2024.pdf#4.2] New hires accrue 15 vacation days in year one.
# [hr_2022.pdf#4.1] New hires accrue 12 vacation days in year one.
#
# Question: How many vacation days do new hires get under the 2024 policy?
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The 2022 policy chunk still made it into the top two results. '
              'What does that reveal about relying on k alone?',
          expectedAnswer:
              'Taking a fixed top-k returns the k closest chunks whether or '
              'not any of them are actually a good match, so a stale but '
              'topically related document can crowd out irrelevant filler '
              'and still land in the prompt purely because nothing better '
              'was available. A relevance-score threshold in addition to k — '
              'as sketched in the lesson\'s walkthrough, where the 2022 chunk '
              'was excluded for scoring too low — is what actually protects '
              'against this, not the choice of k by itself.',
        ),
        SelfCheckQuestion(
          question:
              'Why does assemble_prompt include an explicit instruction to '
              'answer only from the given context, rather than just pasting '
              'the chunks above the question?',
          expectedAnswer:
              'Without an explicit instruction, the model is free to blend '
              'the retrieved text with whatever it already believes from '
              'training, which reintroduces the exact hallucination risk RAG '
              'is meant to remove — a fluent answer that quietly mixes a '
              'stale parametric fact with the fresh retrieved one. Naming the '
              'constraint directly, and asking the model to say so when the '
              'context does not contain the answer, gives the generator a '
              'clear signal for when to defer to the retrieved text versus '
              'when to admit it does not know.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-rag-choose-approach',
      title: 'RAG, fine-tuning, or long context: pick one',
      prompt: [
        ProseBlock(
          'Write choose_approach(scenario) that takes a dict describing a '
          'use case and returns "rag", "fine-tune" or "long-context", using '
          'the tradeoffs from the lesson: data volatility, corpus size versus '
          'context window, need for citations, and whether training budget is '
          'available.',
        ),
        ProseBlock(
          'Run it against the four scenarios provided and check that each '
          'one lands on the tool the lesson argues for, then write a fifth '
          'scenario of your own that should pick "fine-tune".',
        ),
      ],
      starterCode: '''
scenarios = [
    {
        "name": "customer support over a 50k-article help centre",
        "corpus_tokens": 12_000_000,
        "context_window_tokens": 128_000,
        "updates_per_week": 40,
        "needs_citations": True,
        "has_training_budget": False,
    },
    {
        "name": "assistant that must always reply in a strict JSON schema",
        "corpus_tokens": 0,
        "context_window_tokens": 128_000,
        "updates_per_week": 0,
        "needs_citations": False,
        "has_training_budget": True,
    },
    {
        "name": "summarising the five documents in this week's board packet",
        "corpus_tokens": 40_000,
        "context_window_tokens": 128_000,
        "updates_per_week": 1,
        "needs_citations": False,
        "has_training_budget": False,
    },
    {
        "name": "medical guideline lookup with mandatory source citations",
        "corpus_tokens": 3_000_000,
        "context_window_tokens": 128_000,
        "updates_per_week": 5,
        "needs_citations": True,
        "has_training_budget": True,
    },
]


def choose_approach(scenario):
    """Return "rag", "fine-tune" or "long-context" for one scenario dict."""
    ...


for s in scenarios:
    print(s["name"], "->", choose_approach(s))
''',
      solutionCode: '''
scenarios = [
    {
        "name": "customer support over a 50k-article help centre",
        "corpus_tokens": 12_000_000,
        "context_window_tokens": 128_000,
        "updates_per_week": 40,
        "needs_citations": True,
        "has_training_budget": False,
    },
    {
        "name": "assistant that must always reply in a strict JSON schema",
        "corpus_tokens": 0,
        "context_window_tokens": 128_000,
        "updates_per_week": 0,
        "needs_citations": False,
        "has_training_budget": True,
    },
    {
        "name": "summarising the five documents in this week's board packet",
        "corpus_tokens": 40_000,
        "context_window_tokens": 128_000,
        "updates_per_week": 1,
        "needs_citations": False,
        "has_training_budget": False,
    },
    {
        "name": "medical guideline lookup with mandatory source citations",
        "corpus_tokens": 3_000_000,
        "context_window_tokens": 128_000,
        "updates_per_week": 5,
        "needs_citations": True,
        "has_training_budget": True,
    },
]


def choose_approach(scenario):
    """Return "rag", "fine-tune" or "long-context" for one scenario dict."""
    fits_in_context = scenario["corpus_tokens"] <= scenario["context_window_tokens"]
    changes_often = scenario["updates_per_week"] >= 2

    # A corpus that fits comfortably in context and rarely changes doesn't
    # need retrieval infrastructure at all.
    if fits_in_context and not changes_often:
        return "long-context"

    # No factual corpus to speak of: this is a behaviour/format problem,
    # which is what fine-tuning is for.
    if scenario["corpus_tokens"] == 0:
        return "fine-tune"

    # Everything left either doesn't fit in context, changes too often to
    # fine-tune against, or both -- RAG's actual niche.
    return "rag"


for s in scenarios:
    print(s["name"], "->", choose_approach(s))

# customer support over a 50k-article help centre -> rag
# assistant that must always reply in a strict JSON schema -> fine-tune
# summarising the five documents in this week's board packet -> long-context
# medical guideline lookup with mandatory source citations -> rag
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The medical guideline scenario has has_training_budget set to '
              'True, yet the function still returns "rag". Why doesn\'t '
              'available budget push it toward fine-tuning?',
          expectedAnswer:
              'Training budget only matters once you have decided the '
              'problem is a behaviour or format problem that fine-tuning can '
              'actually fix. Here the corpus is large, updates weekly and '
              'demands citations back to a specific guideline — all reasons '
              'fine-tuning is the wrong tool regardless of budget, since '
              'fine-tuning does not give you a pointer back to a source '
              'document and does not cleanly update on a weekly cadence. '
              'Budget is a tiebreaker for feasibility, not a reason to '
              'override what the data\'s shape already tells you.',
        ),
        SelfCheckQuestion(
          question:
              'Write a fifth scenario that this function would send to '
              '"fine-tune", and explain in one sentence why none of the other '
              'two branches should claim it instead.',
          expectedAnswer:
              'Any scenario with corpus_tokens set to 0 routes to '
              '"fine-tune" — for example, "make the model always respond in '
              'a company\'s specific tone of voice with no factual lookup '
              'involved". It should not go to long-context because there is '
              'no corpus to stuff into the window in the first place, and it '
              'should not go to RAG because there is nothing to retrieve — '
              'the task is entirely about behaviour, which is exactly what '
              'fine-tuning changes and retrieval cannot.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-rag-build-index',
      title: 'Build a minimal embedding index with cosine retrieval',
      prompt: [
        ProseBlock(
          'Implement build_index(documents, embed_fn) that takes a list of '
          'text strings and an embedding function, and returns a dict mapping '
          'each document index to its embedding vector. Then implement '
          'retrieve(query, index, embed_fn, k=3) that returns the indices of '
          'the k documents most similar to the query by cosine similarity.',
        ),
        ProseBlock(
          'Use a simple hash-based embed_fn stub (e.g., sum of character '
          'codes) so the exercise stands alone without an API call. The '
          'point is the retrieval infrastructure, not the embedding quality.',
        ),
      ],
      starterCode: '''
def embed_fn(text):
    """Toy embedding: map each character to its ASCII code and sum
    into a 2-dimensional vector by position parity."""
    even = sum(ord(c) for i, c in enumerate(text) if i % 2 == 0)
    odd = sum(ord(c) for i, c in enumerate(text) if i % 2 == 1)
    return (float(even), float(odd))


def cosine_similarity(a, b):
    dot = a[0] * b[0] + a[1] * b[1]
    norm_a = (a[0] ** 2 + a[1] ** 2) ** 0.5
    norm_b = (b[0] ** 2 + b[1] ** 2) ** 0.5
    return dot / (norm_a * norm_b) if norm_a and norm_b else 0.0


def build_index(documents, embed_fn):
    """Return a dict mapping idx -> embedding vector."""
    ...


def retrieve(query, index, embed_fn, k=3):
    """Return the indices of the k documents most similar to query."""
    ...


docs = [
    "Paris is the capital of France",
    "The Eiffel Tower is in Paris",
    "Tokyo is the capital of Japan",
    "Sushi is a popular Japanese dish",
]
idx = build_index(docs, embed_fn)
results = retrieve("What is the capital of France?", idx, embed_fn, k=2)
print([docs[i] for i in results])
''',
      solutionCode: '''
def embed_fn(text):
    even = sum(ord(c) for i, c in enumerate(text) if i % 2 == 0)
    odd = sum(ord(c) for i, c in enumerate(text) if i % 2 == 1)
    return (float(even), float(odd))


def cosine_similarity(a, b):
    dot = a[0] * b[0] + a[1] * b[1]
    norm_a = (a[0] ** 2 + a[1] ** 2) ** 0.5
    norm_b = (b[0] ** 2 + b[1] ** 2) ** 0.5
    return dot / (norm_a * norm_b) if norm_a and norm_b else 0.0


def build_index(documents, embed_fn):
    return {i: embed_fn(doc) for i, doc in enumerate(documents)}


def retrieve(query, index, embed_fn, k=3):
    q_vec = embed_fn(query)
    scored = [
        (idx, cosine_similarity(q_vec, vec))
        for idx, vec in index.items()
    ]
    scored.sort(key=lambda x: -x[1])
    return [idx for idx, _ in scored[:k]]


docs = [
    "Paris is the capital of France",
    "The Eiffel Tower is in Paris",
    "Tokyo is the capital of Japan",
    "Sushi is a popular Japanese dish",
]
idx = build_index(docs, embed_fn)
results = retrieve("What is the capital of France?", idx, embed_fn, k=2)
print([docs[i] for i in results])

# First result should be doc 0: "Paris is the capital of France"
# Second result should be doc 1: "The Eiffel Tower is in Paris"
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why does build_index embed every document at indexing time '
              'rather than embedding each one on-the-fly during retrieval?',
          expectedAnswer:
              'Because indexing is the offline phase that runs once — '
              'embedding 100,000 documents takes minutes and storing the '
              'vectors takes space, but neither cost is paid per query. If '
              'documents were embedded at query time, every query would pay '
              'the embedding cost for the entire corpus, which is exactly '
              'what RAG\'s two-phase design avoids. The offline/online '
              'separation is the single most important architectural '
              'decision in a RAG system.',
        ),
        SelfCheckQuestion(
          question:
              'This toy embed_fn produces terrible semantic vectors — '
              'character sums do not encode meaning at all. Why is it still '
              'useful for learning the retrieval loop?',
          expectedAnswer:
              'The retrieval infrastructure — the cosine comparison, the '
              'ranking, the top-k selection — is identical regardless of '
              'whether the embeddings come from this stub, from a real '
              'transformer model, or from any other source. Learning the '
              'control flow with a deterministic, inspectable embedding '
              'function lets you verify the retrieval logic is correct '
              'before introducing the complexity of a real embedding model. '
              'The same code, with embed_fn replaced by a call to OpenAI\'s '
              'or Cohere\'s embedding API, is a production retrieval system.',
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
              'Imagine asking someone who memorised an encyclopedia in 2023 '
              "about today's news headlines. They can't look anything up — "
              "they only have what's in their head. That's exactly the "
              "problem with language models. Their knowledge is frozen in "
              "their weights from training day. Ask about anything newer "
              "or obscure and they don't say \"I'm not sure\" — they "
              'confidently guess, and that guess can be completely wrong.',

          startMs: 0,
          endMs: 40000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Retrieval-augmented generation is like giving that person a '
              'library card and a librarian. Before they answer, they go look '
              'up the relevant pages first, bring them back to their desk, '
              'and only then respond — with the facts right in front of them '
              'instead of relying on memory alone. The model still does the '
              'same thing, predicting text, but now it has the right '
              'documents sitting open on the table.',
          startMs: 40000,
          endMs: 80000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Think of it like a restaurant. The prep work — chopping '
              'vegetables, stocking the fridge — happens once before service '
              'starts. That\'s the offline phase: chunk your documents, embed '
              'each one, store them in a searchable index. Then when a '
              'customer orders, you cook fresh — that\'s online: embed the '
              'question, search the index, and serve the best matches into '
              'the prompt. Same two phases, every RAG system.',
          startMs: 80000,
          endMs: 120000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Here\'s a concrete example. Someone asks "how many vacation '
              'days do new hires get under the 2024 policy?" Instead of '
              'guessing from an old handbook, the system finds this year\'s '
              'HR doc, pulls out the right paragraph, and says "answer from '
              'this and cite it." The model didn\'t magically learn the '
              'number — it was literally handed the right page, like an '
              'open-book exam.',
          startMs: 120000,
          endMs: 160000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'RAG isn\'t your only option though. You could fine-tune the '
              'model — like sending it back to school for a specific subject, '
              'great for learning a style or format, terrible for facts that '
              'change every week. Or you could just paste everything into a '
              'massive prompt, like photocopying the entire library — works '
              'for a few books, breaks completely when the library has a '
              'million volumes.',
          startMs: 160000,
          endMs: 200000,
        ),
        PodcastSegment(
          id: 'c6',
          speaker: 'Guest',
          text:
              'So RAG lives in the sweet spot: knowledge that\'s too massive '
              'to paste in a prompt and changes too fast to bake into '
              'weights. The catch? Your system is only as good as its '
              'librarian — if retrieval grabs the wrong book, everything '
              'downstream falls apart. And that retrieval quality question is '
              'exactly what the rest of this topic is all about.',
          startMs: 200000,
          endMs: 240000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 432000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Imagine you\'re in a library doing research. You don\'t read '
              'every book cover to cover, right? You ask the librarian where '
              'to look. Now imagine the opposite — someone who can ONLY answer '
              'from memory, who memorised the entire library five years ago '
              'and never stepped back in since. That\'s a language model. Its '
              'knowledge is frozen in its weights at training time, and that '
              'creates two specific problems we need to talk about.',
          startMs: 0,
          endMs: 54000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The first is hallucination, and it\'s not what people think. '
              'Imagine asking that memoriser about a topic barely mentioned in '
              'the books they read — they don\'t say "I\'m not sure." They '
              'confidently string together the most plausible-sounding '
              'continuation, mixing bits of related knowledge into something '
              'that sounds great and is completely wrong. There\'s no separate '
              '"confidence meter" — fluency and accuracy come from the same '
              'mechanism.',
          startMs: 54000,
          endMs: 108000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'The second is staleness, and it\'s like having a textbook from '
              '2020 and being quizzed on 2025 regulations. The model has a '
              'hard cutoff — nothing after training day exists in its brain. '
              'A policy changed last week? A product launched yesterday? '
              'Gone. And you can\'t reasonably retrain the whole thing every '
              'time a fact changes. That would be like reprinting the entire '
              'encyclopedia because one entry is wrong.',
          startMs: 108000,
          endMs: 162000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'RAG fixes both by saying: stop treating the model like a '
              'walking encyclopedia and start treating it like a researcher '
              'with library access. When a question comes in, go search the '
              'external documents first, find the relevant passages, put them '
              'right in the prompt, and tell the model "answer from THESE, '
              'not from memory." It\'s the difference between a closed-book '
              'and an open-book exam. Update the books, not the student.',
          startMs: 162000,
          endMs: 216000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Mechanically it splits into two phases, like meal prep versus '
              'cooking. The offline indexing phase is your prep work: collect '
              'all the documents, chop them into digestible pieces, embed '
              'each one, store those embeddings in a searchable index. Do '
              'this once, redo it when the sources change. Then the online '
              'phase is cooking to order: embed the incoming question, search '
              'the index for the closest matches, assemble everything into a '
              'prompt, and generate.',
          startMs: 216000,
          endMs: 270000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Let me walk the vacation policy example through that pipeline '
              'so you can see it in action. Someone asks about the 2024 '
              'vacation policy. The system searches, and the 2024 handbook '
              'paragraph scores highest — it\'s the most relevant. An old '
              '2022 version scores lower, gets filtered out by a relevance '
              'threshold, and never reaches the prompt. The generator is told '
              '"answer from this text, cite your source." It didn\'t get '
              'smarter — it got handed the right page.',
          startMs: 270000,
          endMs: 324000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Which is why you need to compare it to the alternatives, '
              'because RAG isn\'t always the right answer. Fine-tuning is '
              'like sending the model to grad school — great for teaching it '
              'your company\'s tone, format, or how to call tools reliably. '
              'Terrible for facts that change weekly because it doesn\'t '
              'cleanly overwrite old information — new and old knowledge '
              'can coexist and contradict silently inside the same model.',
          startMs: 324000,
          endMs: 378000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Long context is the brute force approach — just paste '
              'everything in and hope the model\'s attention finds what '
              'matters. It\'s like photocopying every relevant book and '
              'dropping the stack on someone\'s desk. Works fine for a few '
              'documents, hopeless for a million. And even within the '
              'window, there\'s the "lost in the middle" problem — models '
              'pay less attention to text buried far from either end. Plus '
              'it\'s the most expensive per query since every token is '
              'reprocessed every single time.',
          startMs: 378000,
          endMs: 432000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 880000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Alright, grab a coffee — we\'re going deep on retrieval-augmented '
              'generation. Here\'s the roadmap: we\'ll start with the closed-book '
              'problem and why it\'s actually two separate failures disguised as '
              'one, then unpack what "retrieve then generate" really means under '
              'the hood, walk through the offline-online split every RAG system '
              'shares, trace a full real example from question to answer, '
              'compare RAG against fine-tuning and long context, and wrap up with '
              'where the term came from in 2020.',
          startMs: 0,
          endMs: 80000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Let\'s start with parametric knowledge — fancy term, simple idea. '
              'Everything a model "knows" is compressed into its weights during '
              'training, like someone who memorised an entire library and now '
              'can only answer from recall. There\'s no lookup step, no external '
              'reference, no "let me check that." It\'s all just statistical '
              'patterns baked into billions of numbers. That makes inference '
              'blazing fast, and it\'s also the single root cause of two '
              'failure modes that sound similar but are actually distinct.',
          startMs: 80000,
          endMs: 160000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Hallucination first, and it\'s not a random sampling glitch — '
              'that\'s the most common misconception. Even a deterministic, '
              'zero-temperature model hallucinates. Here\'s why: ask about '
              'something that was barely in the training data, and the model '
              'doesn\'t have a separate "I\'m uncertain" channel. It just '
              'produces the most statistically plausible continuation. '
              'Fluency and correctness come from the exact same mechanism, '
              'so a confident, detailed, completely wrong answer sounds '
              'exactly like a correct one. There\'s no internal alarm bell.',
          startMs: 160000,
          endMs: 240000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Staleness second, and it\'s sneakier than it sounds. Training '
              'has a hard cutoff date — imagine a textbook printed in early '
              '2024. An election in 2025? Not in there. A refund policy updated '
              'last week? Nowhere. A document created yesterday? Doesn\'t exist '
              'in the weights. And you can\'t just "patch in" one new fact — '
              'retraining or fine-tuning the entire model for every policy '
              'change is like reprinting the whole encyclopedia because one '
              'entry went stale. It\'s wildly impractical for anything that '
              'changes weekly or daily.',
          startMs: 240000,
          endMs: 320000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'RAG\'s answer to both is beautifully simple: stop demanding '
              'the model answer from memory alone. When a question arrives, '
              'go search an external, easily updatable corpus for the '
              'passages most relevant to this specific question. Insert those '
              'passages into the prompt as context. Then instruct the model '
              '"ground your answer in THIS text, not in whatever you half-'
              'remember." The generation mechanism hasn\'t changed at all — '
              'the model is still predicting tokens. What changed is what\'s '
              'sitting right in front of it when it does.',
          startMs: 320000,
          endMs: 400000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'And here\'s a benefit that\'s easy to overlook: because the '
              'retrieved text sits in the prompt as plain language, the '
              'system can report exactly which document and which section '
              'a claim came from. That\'s a citation trail — proof that the '
              'answer is grounded in something real. A purely parametric '
              'answer can\'t do this because there\'s no passage behind it to '
              'point at, only weights. It\'s the difference between "I read '
              'this in section 4.2" and "I just feel like this is right."',
          startMs: 400000,
          endMs: 480000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Architecturally, every RAG system is two phases, like a '
              'restaurant\'s prep kitchen versus the line. The offline indexing '
              'phase is prep: collect all your documents, chunk them into '
              'manageable pieces, embed every chunk with an embedding model, '
              'and store those vectors in a structure built for fast '
              'similarity search. This is the expensive part, but it\'s '
              'amortised — done once, reused across every future query. You '
              'only redo it when the source documents change.',
          startMs: 480000,
          endMs: 560000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'The online query phase is what runs per request, in '
              'milliseconds: embed the incoming question with that same '
              'embedding model, search the stored index for the nearest '
              'chunks, assemble them with the query into a single prompt, '
              'and hand it to the generator. One subtle bug to watch for: '
              'if the embedding model used at query time is different from '
              'the one used at indexing time, the similarity scores become '
              'meaningless numbers — like measuring distance in kilometres '
              'on one end and miles on the other.',
          startMs: 560000,
          endMs: 640000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Let\'s trace the vacation policy example end to end so this '
              'isn\'t abstract. Someone types "how many vacation days do new '
              'hires get under the 2024 policy?" The 2024 handbook paragraph '
              'scores highest — it\'s talking about the exact thing. An '
              'outdated 2022 version scores lower and gets filtered out by '
              'a relevance threshold, not just fixed top-k, so it never '
              'reaches the prompt. The model receives the right paragraph, '
              'the question, and an instruction to cite its source. It '
              'summarises faithfully and includes the citation. The model '
              'didn\'t learn anything new — it was handed the page.',
          startMs: 640000,
          endMs: 720000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Now let\'s put RAG next to the alternatives so you know '
              'when to use what. Fine-tuning is like sending the model to '
              'grad school — you\'re changing its weights directly with more '
              'training. This is the right tool when you need to teach a '
              'specific behaviour: a consistent tone, a tool-calling format, '
              'a particular reasoning style. It\'s the wrong tool for facts '
              'that change weekly, partly because it doesn\'t reliably erase '
              'old knowledge — new and old facts can coexist and contradict '
              'inside the same model with neither clearly winning.',
          startMs: 720000,
          endMs: 800000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Long-context stuffing is the brute force option: skip '
              'retrieval entirely, just paste the whole knowledge base into '
              'the prompt. It\'s like dropping a stack of photocopied books '
              'on someone\'s desk and saying "the answer is in there '
              'somewhere." Works for a handful of documents, breaks '
              'completely when your corpus has a million pages. Even within '
              'the window, there\'s the "lost in the middle" effect — models '
              'pay less attention to content buried far from either end. And '
              'it\'s the priciest per query since every stuffed token is '
              'reprocessed every single call. RAG\'s niche is the gap '
              'between all of that: knowledge too big for context, too '
              'volatile for fine-tuning, needing a citation trail — traced '
              'back to Lewis and colleagues\' 2020 paper that literally '
              'coined the term for exactly this combination.',
          startMs: 800000,
          endMs: 880000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'RAG fixes a closed-book problem',
      body:
          'A model\'s factual knowledge is frozen in its weights at training '
          'time, which produces hallucination on thin topics and staleness on '
          'anything that changed since the cutoff. RAG answers both by '
          'retrieving relevant text at query time and inserting it into the '
          'prompt, so the model answers from a fresh, external source instead '
          'of from memory alone.',
    ),
    SummaryCard(
      title: 'Two phases: build the index once, query it every time',
      body:
          'Offline indexing chunks documents, embeds them, and stores the '
          'vectors — done once and refreshed when sources change. Online '
          'query time embeds the incoming question, searches the index for '
          'the nearest chunks, and assembles a prompt for generation — done '
          'on every request. Conflating the two, or letting the index go '
          'stale, undermines the whole design.',
    ),
    SummaryCard(
      title: 'RAG is one tool among three, not the default answer',
      body:
          'Fine-tuning changes weights and suits behaviour, tone and format, '
          'not fast-changing facts. Long-context stuffing works until the '
          'corpus stops fitting and suffers from reduced attention to text '
          'buried in the middle. RAG fits the gap: knowledge too large for '
          'context, too volatile for fine-tuning, and needing a citation back '
          'to a real source.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Parametric knowledge',
      definition:
          'Factual knowledge encoded directly in a model\'s weights during '
          'training, with no external lookup involved. Fast to access, but '
          'frozen at the training cutoff and the root cause of both '
          'hallucination and staleness.',
    ),
    KeyConcept(
      term: 'Retrieval-augmented generation (RAG)',
      definition:
          'An architecture that searches an external document collection for '
          'passages relevant to the current query, inserts them into the '
          'prompt, and generates an answer grounded in that retrieved text '
          'rather than in the model\'s unaided memory.',
    ),
    KeyConcept(
      term: 'Offline indexing phase',
      definition:
          'The one-time (or update-triggered) process of chunking documents, '
          'embedding each chunk, and storing the resulting vectors in a '
          'structure built for fast similarity search.',
    ),
    KeyConcept(
      term: 'Online query phase',
      definition:
          'The per-request process of embedding an incoming query, searching '
          'the index for the most similar chunks, assembling them with the '
          'query into a prompt, and generating a grounded answer.',
    ),
    KeyConcept(
      term: 'Grounding',
      definition:
          'Constraining a model\'s answer to information explicitly supplied '
          'in the prompt, rather than allowing it to draw freely on '
          'parametric memory — the property that makes citation back to a '
          'source document possible.',
    ),
    KeyConcept(
      term: 'Hallucination',
      definition:
          'A fluent, confident, factually wrong answer produced when a '
          'model is asked something its training data covered poorly. Not a '
          'sampling artifact — it occurs even at zero temperature, because '
          'fluency and correctness are not linked signals.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake: 'Treating RAG as a guaranteed cure for hallucination.',
      correction:
          'RAG only grounds an answer if retrieval actually surfaces the '
          'right passage. If the relevant chunk is missing, poorly ranked, or '
          'never indexed, the model is back to answering from unaided memory '
          'while the surrounding system gives a false impression of being '
          'grounded. Retrieval quality is the real determinant of whether RAG '
          'helps at all.',
    ),
    Mistake(
      mistake:
          'Building the index once and never refreshing it when source '
          'documents change.',
      correction:
          'A stale vector index reproduces the exact staleness problem RAG '
          'was built to solve, just one layer down — the system will '
          'confidently retrieve and cite an outdated document. Indexing needs '
          'to be treated as an ongoing pipeline tied to document updates, not '
          'a one-time setup step.',
    ),
    Mistake(
      mistake:
          'Reaching for RAG by default instead of checking whether '
          'fine-tuning or long context actually fits better.',
      correction:
          'A behaviour or formatting problem with no real factual lookup is '
          'a fine-tuning problem, and a handful of documents that comfortably '
          'fit the context window may not need retrieval infrastructure at '
          'all. RAG earns its complexity — an index, an embedding model, a '
          'retrieval step — only when the knowledge is too large or too '
          'volatile for the simpler alternatives.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          "What problem does RAG solve that simply using a model with a "
          "bigger context window doesn't?",
      answer:
          'Two things a bigger window does not fix. First, scale: even the '
          'largest context windows top out well short of a corpus with '
          'millions of documents, so at some point stuffing simply is not an '
          'option regardless of window size. Second, cost and attention '
          'quality: every token in a stuffed context gets reprocessed on '
          'every call, and models attend less reliably to content buried in '
          'the middle of a very long prompt — the "lost in the middle" '
          'effect — so relevant information can be present yet effectively '
          'ignored. RAG sidesteps both by selecting only the handful of '
          'passages relevant to this specific query, which is cheaper per '
          'call and keeps the relevant text near the front of a short prompt '
          'rather than buried in a huge one. The tradeoff is that RAG\'s '
          'quality now depends on retrieval finding the right passage, which '
          'is a new failure mode a long-context approach does not have.',
    ),
    InterviewQuestion(
      question:
          "Walk me through what happens between a user's query and RAG's "
          'generated answer.',
      answer:
          'The query is embedded with the same embedding model used when the '
          'corpus was indexed — using a different or mismatched model here '
          'silently breaks the whole system, since similarity scores between '
          'incompatible embedding spaces are meaningless. That query vector '
          'is compared against the stored chunk vectors, typically with an '
          'approximate nearest-neighbour search rather than an exhaustive '
          'scan once the corpus is large, and the top-k most similar chunks '
          'are pulled back, usually filtered by a relevance threshold as well '
          'as k, so a mediocre match doesn\'t make it in just because nothing '
          'better was available. Those chunks are assembled into a prompt '
          'alongside the original query, typically with an explicit '
          'instruction to answer only from the supplied context and to say so '
          'if the answer isn\'t there. The LLM then generates a response '
          'conditioned on that prompt, ideally citing which chunk supported '
          'which part of the answer. Every step in that chain — embedding '
          'consistency, retrieval quality, prompt construction, and the '
          'grounding instruction — is a place quality can be lost.',
    ),
    InterviewQuestion(
      question:
          'When would you choose fine-tuning over RAG, and when would you '
          'choose RAG over fine-tuning?',
      answer:
          'Fine-tuning wins when the problem is about behaviour rather than '
          'facts: getting a model to consistently follow a tone, a response '
          'format, a tool-calling convention, or a narrow skill that '
          'training examples can demonstrate directly. It is a poor fit when '
          'the underlying facts change often, because each update requires '
          'retraining, and because fine-tuning does not reliably overwrite '
          'facts already present in the weights, so old and new information '
          'can coexist unpredictably. RAG wins when the knowledge is large, '
          'changes frequently, and needs to be traceable back to a specific '
          'source — updating the document store takes effect on the very '
          'next query, with no retraining at all, and a citation can point '
          'back to the exact passage used. In practice the two aren\'t '
          'mutually exclusive: I\'d commonly fine-tune a model for the '
          'house style and tool usage it needs, and layer RAG on top for the '
          'large, frequently updated knowledge base underneath.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title:
        'Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks '
        '(Lewis et al., 2020)',
    url: 'https://arxiv.org/abs/2005.11401',
    description:
        'The paper that named and defined RAG, combining a parametric '
        'seq2seq generator with a dense-vector, non-parametric retriever — '
        'the origin of the two-phase architecture and the RAG-Sequence vs '
        'RAG-Token distinction covered in the deep dive.',
  ),
  Source(
    title: 'RAG — Hugging Face Transformers docs',
    url: 'https://huggingface.co/docs/transformers/model_doc/rag',
    description:
        'Reference documentation for the original RAG model implementation, '
        'describing the question encoder, retriever and generator components '
        'this lesson\'s retrieve-then-generate pipeline is modelled on.',
  ),
  Source(
    title: 'Retrieval-Augmented Generation (RAG) — Pinecone Learn',
    url: 'https://www.pinecone.io/learn/retrieval-augmented-generation/',
    description:
        'A practitioner-oriented explanation of the RAG pipeline and why it '
        'reduces hallucination, used here to cross-check the framing of the '
        'core-idea and worked-example sections.',
  ),
  Source(
    title: 'Retrieval Augmented Generation (RAG) — LangChain docs',
    url: 'https://docs.langchain.com/oss/python/langchain/rag',
    description:
        'LangChain\'s own walkthrough of building a RAG application, '
        'showing the same offline-index / online-query split this lesson '
        'presents in pseudocode.',
  ),
];

const List<Source> _furtherReading = <Source>[
  Source(
    title: 'A Survey of Retrieval-Augmented Generation (Fan et al., 2024)',
    url: 'https://arxiv.org/abs/2406.19469',
    description:
        'Comprehensive survey of the RAG ecosystem: naive RAG, advanced RAG, '
        'and modular RAG architectures with production case studies.',
  ),
  Source(
    title: 'Building RAG-based LLM Applications for Production — Anyscale',
    url:
        'https://www.anyscale.com/blog/a-comprehensive-guide-for-building-rag-based-llm-applications-part-1',
    description:
        'End-to-end production guide covering chunking strategies, embedding '
        'model selection, vector store tradeoffs, and prompt engineering for RAG pipelines.',
  ),
  Source(
    title: 'Lost in the Middle: How Language Models Use Long Contexts (Liu et al., 2023)',
    url: 'https://arxiv.org/abs/2307.03172',
    description:
        'Empirical study showing that decoder-only LLMs attend best to the '
        'beginning and end of a context window, the evidence behind the RAG-vs-long-context '
        'tradeoff discussed in this lesson.',
  ),
  Source(
    title: 'When Not to Use RAG: Choosing Between Fine-tuning, Prompt Stuffing, and Retrieval',
    url: 'https://www.llamaindex.ai/blog/when-not-to-use-rag',
    description:
        'Practical framework for deciding among RAG, fine-tuning, and long-context approaches '
        'based on corpus size, update frequency, and citation requirements.',
  ),
];
