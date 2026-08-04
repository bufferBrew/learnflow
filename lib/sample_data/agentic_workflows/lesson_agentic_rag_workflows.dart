import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 2: what changes when retrieval stops being a fixed
/// pipeline stage and becomes a tool an agent chooses to call — iterative
/// research loops, self-grading, corrective fallback, and when the added
/// control flow is and is not worth it.
const Lesson agenticRagWorkflowsLesson = Lesson(
  id: 'agentic-rag-workflows',
  title: 'Agentic RAG & Workflows',
  description:
      'Retrieval as a tool the agent chooses to call instead of a fixed '
      'pipeline stage — iterative research loops, self-grading, corrective '
      'fallback, and the failure modes unique to letting an agent drive '
      'retrieval.',
  estimatedMinutes: 30,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  play: GameContent(games: <Game>[]),
  review: _review,
  sources: _sources,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'from-pipeline-to-decision',
      heading: 'From a pipeline stage to a decision',
      blocks: [
        ProseBlock(
          'Plain RAG, as covered in the previous topic, is a fixed pipeline: '
          'a query arrives, it gets embedded, the embedding is compared '
          'against an index, the top-k chunks are pulled back, and those '
          'chunks go into the prompt — every single time, exactly once, no '
          'matter what the query actually is. The retrieval step has no '
          'judgment. It runs because the code says it runs, on a schedule of '
          '"once per request," whether the query needed outside information '
          'at all, whether one retrieval round was enough, or whether the '
          'first pass came back with nothing useful.',
        ),
        ProseBlock(
          'Agentic RAG removes that fixed schedule and replaces it with a '
          'decision. Instead of retrieval being a pipeline stage the '
          'application always runs, retrieval becomes a tool sitting in the '
          'agent\'s toolbox, exactly like the tools from the previous lesson — '
          'and the agent, running the same observe-plan-act loop you already '
          'know from ReAct, decides whether to call it, what to search for, '
          'how many times to search, and when it has gathered enough to '
          'answer. The retrieval mechanics underneath — embed, compare, rank, '
          'return chunks — do not change at all. What changes is who decides '
          'when that mechanism runs.',
        ),
        ProseBlock(
          'This is a small-sounding change with large consequences. A plain '
          'RAG system asked "what is the capital of France?" still pays for a '
          'vector search and still stuffs retrieved chunks into the prompt, '
          'even though the model already knows the answer cold. An agentic '
          'system can recognise that no lookup is needed and answer directly. '
          'Conversely, a plain RAG system asked a question that needs facts '
          'from three different documents, discovered one at a time, gets '
          'exactly one retrieval pass and has to hope the top-k chunks from '
          'that single pass happen to cover all three. An agentic system can '
          'retrieve, notice it only found two of the three facts, and go '
          'back for the third.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Same retriever, different controller',
          text:
              'Nothing about the embedding model, the index, or the '
              'similarity search changes between plain and agentic RAG. What '
              'changes is the control flow wrapped around it: a fixed '
              '"always retrieve once" schedule versus a model that decides, '
              'turn by turn, whether to retrieve at all. Every technique from '
              'the previous topic — chunking, embeddings, IVF and HNSW '
              'indexes — is still exactly what sits underneath.',
        ),
      ],
    ),
    Section(
      id: 'retriever-as-tool',
      heading: 'The retriever as one tool among several',
      blocks: [
        ProseBlock(
          'Concretely, making retrieval agentic means exposing it through '
          'the same tool-calling interface as everything else the agent can '
          'do: a name, a description, an input schema. It sits in the tools '
          'list next to a calculator, a web-search tool, a code executor, '
          'maybe an API for looking up live data — and the agent\'s '
          'tool-selection reasoning, the same thought-action-observation '
          'cycle from ReAct, decides which one a given query actually needs, '
          'if any.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
retrieve_docs_tool = {
    "name": "retrieve_docs",
    "description": (
        "Search the internal knowledge base (product docs, policies, "
        "past support tickets) for passages relevant to a query. Use "
        "this for questions about internal, company-specific, or "
        "frequently-changing information. Do not use it for general "
        "knowledge, arithmetic, or anything you already know confidently."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "A focused search query, not the full "
                                "user question verbatim.",
            },
        },
        "required": ["query"],
    },
}

calculator_tool = {
    "name": "calculator",
    "description": "Evaluate a numeric expression. Use for arithmetic.",
    "input_schema": {
        "type": "object",
        "properties": {"expression": {"type": "string"}},
        "required": ["expression"],
    },
}

web_search_tool = {
    "name": "web_search",
    "description": (
        "Search the public internet. Use for current events or anything "
        "not likely to be in the internal knowledge base."
    ),
    "input_schema": {
        "type": "object",
        "properties": {"query": {"type": "string"}},
        "required": ["query"],
    },
}

# The agent sees all three and picks based on the query -- exactly the
# tool-selection reasoning from the previous lesson, with retrieval as
# just one more entry in the catalogue rather than a guaranteed step.
tools = [retrieve_docs_tool, calculator_tool, web_search_tool]
''',
          caption:
              'The description is doing real work: "do not use it for '
              'general knowledge" is what stops the agent from retrieving '
              'reflexively on every query.',
        ),
        ProseBlock(
          'The tool description is where the real design decision lives. A '
          'weak description ("search documents") gives the model no signal '
          'about when retrieval is actually warranted, and models tend to err '
          'toward calling a tool that is available rather than reasoning '
          'their way to "I already know this." A description that states '
          'explicitly what the tool is for and, just as importantly, what it '
          'is not for, is what lets the agent\'s tool-selection reasoning '
          'skip retrieval for a general-knowledge question and reach for it '
          'on a company-specific one.',
        ),
        ProseBlock(
          'This is also where multiple tools compete for the same query, and '
          'the agent has to arbitrate. "What is our refund policy for orders '
          'placed after a price change?" is unambiguously a retrieve_docs '
          'question — it needs an internal, company-specific answer. "What is '
          'today\'s exchange rate?" is unambiguously a web_search question — '
          'internal docs will not have it and are likely stale even if they '
          'do. A genuinely hard case, like "how does our refund policy '
          'compare to industry standard," might reasonably call both: '
          'retrieve_docs for the internal policy, web_search for the '
          'external comparison, before synthesising an answer from the two.',
        ),
      ],
    ),
    Section(
      id: 'iterative-research-loop',
      heading: 'The iterative research loop: retrieve, reflect, reformulate',
      blocks: [
        ProseBlock(
          'Plain RAG retrieves once. The prior topic\'s lesson on multi-hop '
          'retrieval already showed one way past that limit: decompose the '
          'query into sub-questions in advance, then retrieve for each '
          'sub-question in a fixed sequence. That is still a schedule, just a '
          'longer one — the decomposition is decided upfront, before any '
          'retrieval has actually run, and the sequence of sub-queries does '
          'not change based on what comes back.',
        ),
        ProseBlock(
          'Agentic RAG\'s iterative loop is different in exactly the way '
          'ReAct is different from a plan made in advance: it re-plans based '
          'on what it actually found. Retrieve, then read what came back and '
          'ask "does this actually answer the question?" If yes, stop and '
          'answer. If no — the chunks are off-topic, too generic, or only '
          'partially cover the question — reformulate the query based on '
          'specifically what was missing, and retrieve again. Repeat until '
          'the agent judges it has enough, or a step budget runs out. Nothing '
          'about the number of retrieval rounds, or what each one searches '
          'for, is decided before the first result comes back.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def grade_relevance(query, chunk, llm):
    """Ask the model whether a retrieved chunk actually answers the
    query. Returns "relevant" or "irrelevant" -- a cheap, focused call,
    not the same call that will eventually generate the final answer."""
    prompt = (
        f"Question: {query}\\n\\nRetrieved passage:\\n{chunk}\\n\\n"
        "Does this passage contain information that helps answer the "
        "question? Reply with exactly one word: relevant or irrelevant."
    )
    return llm.generate(prompt).strip().lower()


def agentic_retrieve(query, retriever, llm, max_rounds=3):
    """Retrieve, grade, and reformulate until enough relevant context is
    found or the round budget runs out."""
    gathered = []
    current_query = query

    for round_num in range(1, max_rounds + 1):
        chunks = retriever.search(current_query, k=3)
        relevant = [c for c in chunks if grade_relevance(query, c, llm) == "relevant"]
        gathered.extend(relevant)

        print(f"round {round_num}: searched {current_query!r}, "
              f"found {len(relevant)} relevant of {len(chunks)} retrieved")

        if len(gathered) >= 2:
            print(f"stopping: {len(gathered)} relevant chunks is enough")
            return gathered

        # Reflect on what's missing and reformulate -- not a fixed
        # decomposition, but a query built from this round's shortfall.
        current_query = llm.generate(
            f"Original question: {query}\\n"
            f"Already found: {[c[:40] for c in gathered]}\\n"
            "The results so far are insufficient. Write a more specific "
            "or differently-phrased search query to find what's missing."
        )

    print(f"stopping: hit max_rounds={max_rounds} with {len(gathered)} chunks")
    return gathered

# Example trace against a corpus where the 2024 policy update is filed
# under a section heading the first query does not mention:
#
# round 1: searched 'refund policy after price change', found 0 relevant of 3
# round 2: searched 'refund eligibility price adjustment 2024 amendment',
#          found 2 relevant of 3
# stopping: 2 relevant chunks is enough
''',
          caption:
              'The second query exists only because the first one failed — '
              'nothing about "price adjustment 2024 amendment" was decided '
              'before round one\'s empty result came back.',
        ),
        ProseBlock(
          'Notice that grading uses a separate, narrow call — "is this '
          'passage relevant, yes or no" — rather than folding the judgment '
          'into the final answer-generation call. That separation matters '
          'for the same reason a dedicated tool works better than an '
          'overloaded one: a narrow, single-purpose prompt is easier for the '
          'model to answer reliably than a prompt simultaneously asking it to '
          'judge relevance and compose a final answer. It also means the '
          'grading step can run against a cheaper, faster model than the one '
          'doing final generation, since a relevant/irrelevant judgment needs '
          'far less capability than synthesising a well-written answer.',
        ),
        CollapsibleBlock(
          title:
              'Deep dive: single-hop, multi-hop, and agentic retrieval side '
              'by side',
          children: [
            ProseBlock(
              'Single-hop retrieval is plain RAG: one query, one retrieval '
              'call, whatever comes back is what the generator gets. It is '
              'cheap, predictable, and fails silently whenever a question '
              'genuinely needs information that no single query surfaces in '
              'one pass — a question spanning two documents, or one whose '
              'best-matching passage uses different vocabulary than the '
              'question itself.',
            ),
            ProseBlock(
              'Multi-hop retrieval fixes the "needs two documents" case by '
              'decomposing the query into sub-questions ahead of time and '
              'retrieving for each — "who directed the movie X came out in '
              'the same year as" becomes "what year did X come out" followed '
              'by "which movies released that year" followed by "who directed '
              'movie Y", each sub-query fixed in advance based on the '
              'decomposition. It is more thorough than single-hop, but the '
              'plan is still committed to before any retrieval has run: if '
              'the second sub-query\'s premise turns out to be wrong, or the '
              'first retrieval came back empty, the fixed decomposition has '
              'no way to notice or adapt.',
            ),
            ProseBlock(
              'Agentic retrieval keeps multi-hop\'s ability to search '
              'multiple times but removes the upfront commitment. Each round '
              'is planned after seeing the previous round\'s actual result, '
              'not before. That buys real robustness — an unexpectedly empty '
              'first search gets a reformulated second attempt instead of a '
              'silently incomplete answer — at the cost of unpredictable '
              'latency (some queries finish in one round, some take the full '
              'budget) and the very real risk, covered later in this lesson, '
              'of looping longer than the question ever warranted.',
            ),
            ProseBlock(
              'The practical rule of thumb: reach for multi-hop when the '
              'decomposition is genuinely knowable in advance — a question '
              'has an obvious two-part structure you could write down '
              'yourself. Reach for the fully agentic loop when you cannot '
              'know in advance how many rounds a query will need, or whether '
              'the first attempt will even come back with anything useful.',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'corrective-self-reflective',
      heading: 'Corrective and self-reflective RAG',
      blocks: [
        ProseBlock(
          'The relevance-grading step from the previous section is the seed '
          'of a broader pattern, formalised in two influential 2023-2024 '
          'papers. Self-RAG trains the model itself to emit special '
          '"reflection tokens" alongside its normal output — judgments like '
          '"is retrieval needed here", "is this retrieved passage relevant", '
          '"is my generated sentence actually supported by the passage" — so '
          'that self-critique is built into the model\'s own generation '
          'process rather than bolted on as a separate call. Corrective RAG '
          '(CRAG) takes a lighter-weight, model-agnostic approach: a '
          'retrieval evaluator scores each retrieved document\'s relevance, '
          'and that score routes the system down one of three paths — use '
          'the documents as-is if they score well, refine and filter them if '
          'the score is ambiguous, or discard them entirely and fall back to '
          'a web search if the score is low.',
        ),
        ProseBlock(
          'The fallback path is the piece worth dwelling on, because it is '
          'what "corrective" actually means: when local retrieval comes up '
          'empty or clearly irrelevant — the knowledge base simply does not '
          'cover this question — a corrective system does not silently hand '
          'the generator low-quality context and hope for the best. It '
          'recognises the failure and reaches for a different source '
          'entirely, the same way a human researcher who strikes out in one '
          'reference book reaches for a different one rather than writing an '
          'answer from a book that clearly does not cover the topic.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def corrective_retrieve(query, local_retriever, web_search, llm):
    """CRAG-style: grade local retrieval, fall back to web search when it
    comes up short instead of generating from irrelevant context."""
    chunks = local_retriever.search(query, k=4)
    scores = [grade_relevance(query, c, llm) for c in chunks]
    relevant = [c for c, s in zip(chunks, scores) if s == "relevant"]

    if len(relevant) >= 2:
        print(f"local retrieval sufficient: {len(relevant)}/{len(chunks)} relevant")
        return relevant, "local"

    if relevant:
        print(f"local retrieval partial: {len(relevant)}/{len(chunks)} relevant, "
              "supplementing with web search")
        supplement = web_search.search(query, k=2)
        return relevant + supplement, "local+web"

    print("local retrieval empty: falling back to web search entirely")
    return web_search.search(query, k=3), "web"


# Query about a competitor's product the internal knowledge base was
# never populated with:
#
# local retrieval empty: falling back to web search entirely
''',
          caption:
              'The three-way branch — use, supplement, or discard-and-'
              'fall-back — is the whole idea of "corrective" retrieval in '
              'one function.',
        ),
        ProseBlock(
          'Self-reflection can also run after generation, not just after '
          'retrieval: a second pass checks whether each sentence in the '
          'draft answer is actually supported by a retrieved passage, and '
          'flags or regenerates any sentence that is not. That closes a gap '
          'the retrieval-grading step alone cannot: even with perfectly '
          'relevant retrieved chunks, a generator can still drift into an '
          'unsupported claim while writing the final answer, and checking '
          'the retrieval was good says nothing about whether the generation '
          'stayed faithful to it.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Grading is itself an LLM call, with its own failure rate',
          text:
              'The relevance grader is not a ground-truth oracle — it is '
              'another model call, and it can be wrong in both directions: '
              'marking a genuinely useful passage irrelevant because the '
              'connection is indirect, or marking an off-topic passage '
              'relevant because it superficially shares vocabulary with the '
              'query. Corrective and self-reflective patterns raise the '
              'system\'s reliability on average; they do not make the '
              'pipeline infallible, and a bad grading call can still send a '
              'good passage to the discard pile.',
        ),
      ],
    ),
    Section(
      id: 'failure-modes-and-when-to-use',
      heading: 'Failure modes, and when the extra control flow earns its keep',
      blocks: [
        ProseBlock(
          'Giving an agent control over retrieval trades one set of failure '
          'modes for another, and the new ones are specific to the added '
          'control flow rather than to retrieval itself. Over-retrieval is '
          'the agent calling the retriever when it did not need to — asking '
          'the knowledge base something it already knew confidently, or '
          'retrieving a second and third time for a question the first '
          'result already answered — burning latency and cost for no gain in '
          'answer quality. It is the tool-calling equivalent of a student who '
          'looks up a fact they already had memorised: harmless in isolation, '
          'expensive at scale.',
        ),
        ProseBlock(
          'Under-retrieval, or premature stopping, is the opposite failure '
          'and the more dangerous one: the agent decides it has "enough" '
          'information and answers confidently from stale internal knowledge '
          'when a lookup was actually needed, or stops after one retrieval '
          'round that only partially covered the question. This produces '
          'exactly the fluent, wrong, confident answer that plain RAG was '
          'built to prevent in the first place — except now the failure is '
          'harder to spot, because the system did retrieve something, just '
          'not enough of the right thing, and a shallow check of "did it '
          'retrieve at all" would not catch it.',
        ),
        ProseBlock(
          'And a runaway research loop is the compounding-error problem from '
          'the very first lesson of this topic, specific to retrieval: '
          'without a step budget, an agent that keeps grading its own '
          'results as insufficient can reformulate and retrieve indefinitely, '
          'each round adding latency and cost without ever reaching the '
          'agent\'s own bar for "enough." A max_rounds guard, exactly like '
          'the max_steps guard from the general agent loop, is not optional — '
          'it is the difference between a bounded research process and an '
          'unbounded one that a confused query can send spinning.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'A step budget bounds cost, not correctness',
          text:
              'Capping max_rounds stops a confused loop from running '
              'forever, but it does not make the answer at round three any '
              'better than the answer at round one if the agent genuinely '
              'never found what it needed. Pair the budget with an explicit '
              '"insufficient information found" fallback path, the same way '
              'a plain RAG prompt should instruct the model to say so rather '
              'than guess — hitting the budget should produce an honest '
              'admission, not a confident answer built on thin context.',
        ),
        ProseBlock(
          'None of this argues against plain, single-shot RAG as a default. '
          'A well-scoped question against a corpus where the right passage '
          'reliably shows up in the top few results — a support bot answering '
          'from a stable FAQ, a lookup against a single well-indexed policy '
          'document — gets no benefit from the extra machinery: the answer at '
          'round one is already correct, and every additional round of '
          'grading and reformulation is pure overhead with nothing to fix. '
          'The agentic control flow earns its cost specifically on '
          'open-ended research questions, queries whose full answer is '
          'synthesised across several retrieval rounds, and corpora where a '
          'single query commonly misses — exactly the cases where a fixed, '
          'single retrieval pass would have silently returned an incomplete '
          'or irrelevant answer with no mechanism to notice.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-agentic-retrieve-loop',
      title: 'Build a grade-and-reformulate retrieval loop',
      prompt: [
        ProseBlock(
          'Implement agentic_retrieve(query, corpus, grader, reformulator, '
          'max_rounds) using a fake keyword-overlap retriever and a fake '
          'grader/reformulator standing in for LLM calls. Each round should '
          'retrieve, grade every chunk, stop as soon as at least one relevant '
          'chunk has been found across all rounds combined, and otherwise '
          'reformulate the query and try again.',
        ),
        ProseBlock(
          'Print each round\'s query and how many relevant chunks it found, '
          'so the trace makes the reformulation visible — the point of the '
          'exercise is seeing round two\'s query change because of round '
          'one\'s actual result, not the retrieval mechanics themselves.',
        ),
      ],
      starterCode: '''
corpus = [
    ("policy_2022.txt", "Employees get 12 vacation days per year."),
    ("policy_2024.txt", "Starting 2024, employees accrue 18 vacation days, "
                         "with an additional 2 days after 3 years tenure."),
    ("it_faq.txt", "Laptops are replaced on a three-year cycle."),
]


def keyword_retrieve(query, corpus, k=2):
    """Toy retriever: rank chunks by how many query words they contain."""
    query_words = set(query.lower().split())
    scored = []
    for source, text in corpus:
        overlap = len(query_words & set(text.lower().split()))
        scored.append((overlap, source, text))
    scored.sort(key=lambda row: -row[0])
    return [(source, text) for _, source, text in scored[:k]]


def fake_grader(query, chunk_text):
    """Stub: 'relevant' if the chunk mentions vacation *and* 2024."""
    text = chunk_text.lower()
    return "relevant" if "vacation" in text and "2024" in text else "irrelevant"


def fake_reformulator(query, round_num):
    """Stub: sharpen the query with a fixed hint after a failed round."""
    return f"{query} 2024 accrual policy update"


def agentic_retrieve(query, corpus, grader, reformulator, max_rounds=3):
    """Retrieve, grade, and reformulate until a relevant chunk is found
    or max_rounds is exhausted. Return the list of relevant chunks."""
    ...


result = agentic_retrieve(
    "how many vacation days do employees get",
    corpus, fake_grader, fake_reformulator,
)
print(result)
''',
      solutionCode: '''
corpus = [
    ("policy_2022.txt", "Employees get 12 vacation days per year."),
    ("policy_2024.txt", "Starting 2024, employees accrue 18 vacation days, "
                         "with an additional 2 days after 3 years tenure."),
    ("it_faq.txt", "Laptops are replaced on a three-year cycle."),
]


def keyword_retrieve(query, corpus, k=2):
    """Toy retriever: rank chunks by how many query words they contain."""
    query_words = set(query.lower().split())
    scored = []
    for source, text in corpus:
        overlap = len(query_words & set(text.lower().split()))
        scored.append((overlap, source, text))
    scored.sort(key=lambda row: -row[0])
    return [(source, text) for _, source, text in scored[:k]]


def fake_grader(query, chunk_text):
    """Stub: 'relevant' if the chunk mentions vacation *and* 2024."""
    text = chunk_text.lower()
    return "relevant" if "vacation" in text and "2024" in text else "irrelevant"


def fake_reformulator(query, round_num):
    """Stub: sharpen the query with a fixed hint after a failed round."""
    return f"{query} 2024 accrual policy update"


def agentic_retrieve(query, corpus, grader, reformulator, max_rounds=3):
    """Retrieve, grade, and reformulate until a relevant chunk is found
    or max_rounds is exhausted. Return the list of relevant chunks."""
    current_query = query

    for round_num in range(1, max_rounds + 1):
        chunks = keyword_retrieve(current_query, corpus, k=2)
        relevant = [
            (source, text) for source, text in chunks
            if grader(query, text) == "relevant"
        ]
        print(f"round {round_num}: query={current_query!r} "
              f"-> {len(relevant)} relevant of {len(chunks)}")

        if relevant:
            return relevant

        current_query = reformulator(query, round_num)

    print(f"stopping: exhausted max_rounds={max_rounds} with no relevant chunks")
    return []


result = agentic_retrieve(
    "how many vacation days do employees get",
    corpus, fake_grader, fake_reformulator,
)
print(result)

# round 1: query='how many vacation days do employees get' -> 0 relevant of 2
# round 2: query='how many vacation days do employees get 2024 accrual
#          policy update' -> 1 relevant of 2
# [('policy_2024.txt', 'Starting 2024, employees accrue 18 vacation days, ...')]
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Round 1 retrieved policy_2022.txt, a chunk that genuinely '
              'answers "how many vacation days" — just with an outdated '
              'number. Why does fake_grader mark it irrelevant instead of '
              'relevant?',
          expectedAnswer:
              'fake_grader is deliberately checking for "2024" as well as '
              '"vacation" — it is a stand-in for a real grader judging '
              'relevance to the actual intent behind the question, not just '
              'topical overlap. policy_2022.txt is on-topic but represents '
              'stale information, which a good grader should treat as failing '
              'to actually answer a question implicitly about the current '
              'policy, the same way the lesson\'s worked example filtered out '
              'the 2022 handbook chunk by relevance score rather than letting '
              'topical overlap alone qualify it. A grader that only checked '
              'for the word "vacation" would have stopped after round one '
              'with a stale, wrong answer.',
        ),
        SelfCheckQuestion(
          question:
              'This implementation stops as soon as ANY relevant chunk is '
              'found, even just one. What real failure mode could that '
              'cause, and how would you change the stopping condition to '
              'guard against it?',
          expectedAnswer:
              'A single relevant chunk might only partially answer a '
              'question that actually needs facts synthesised from several '
              'chunks — for example a question needing both the 2024 vacation '
              'number and the additional-tenure bonus, where a chunk '
              'mentioning only one of the two would pass the current check '
              'and stop the loop prematurely. This is the under-retrieval / '
              'premature-stopping failure mode from the lesson. A more '
              'robust stopping condition would ask the grader, or a separate '
              'sufficiency check, whether the accumulated relevant chunks '
              'together answer the full question, not just whether the count '
              'is non-zero, and would keep reformulating and retrieving if '
              'the answer is still incomplete.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-corrective-fallback',
      title: 'Add a corrective web-search fallback',
      prompt: [
        ProseBlock(
          'Extend the retrieval loop with a CRAG-style three-way branch: if '
          'local retrieval returns two or more relevant chunks, use them '
          'as-is; if it returns exactly one, supplement it with a (fake) web '
          'search; if it returns zero, discard the local results entirely '
          'and fall back to web search alone.',
        ),
        ProseBlock(
          'Run it against three queries — one the local corpus covers well, '
          'one it partially covers, and one it does not cover at all — and '
          'confirm each one takes the branch the lesson describes.',
        ),
      ],
      starterCode: '''
local_corpus = [
    ("returns_policy.txt", "Refunds are issued within 14 days of return."),
    ("returns_policy.txt#2", "Refunds require the original receipt."),
]


def local_retrieve(query, corpus):
    """Toy retriever: return chunks containing any query word."""
    words = set(query.lower().split())
    return [
        (source, text) for source, text in corpus
        if words & set(text.lower().split())
    ]


def grade(query, text):
    """Stub grader keyed to specific fixtures for this exercise."""
    if "refund" in query.lower() and "refund" in text.lower():
        return "relevant"
    return "irrelevant"


def fake_web_search(query, k=2):
    return [(f"web_result_{i}", f"Web result {i} for: {query}") for i in range(k)]


def corrective_retrieve(query, corpus, retriever, grader, web_search):
    """Grade local retrieval; use it, supplement it, or fall back to web
    search entirely depending on how many chunks graded relevant."""
    ...


for q in [
    "what is the refund policy",          # local covers this well
    "refund policy for gift cards",       # local partially covers this
    "what is your shipping carrier",      # local does not cover this
]:
    chunks, source = corrective_retrieve(
        q, local_corpus, local_retrieve, grade, fake_web_search,
    )
    print(q, "->", source, "->", len(chunks), "chunks")
''',
      solutionCode: '''
local_corpus = [
    ("returns_policy.txt", "Refunds are issued within 14 days of return."),
    ("returns_policy.txt#2", "Refunds require the original receipt."),
]


def local_retrieve(query, corpus):
    """Toy retriever: return chunks containing any query word."""
    words = set(query.lower().split())
    return [
        (source, text) for source, text in corpus
        if words & set(text.lower().split())
    ]


def grade(query, text):
    """Stub grader keyed to specific fixtures for this exercise."""
    if "refund" in query.lower() and "refund" in text.lower():
        return "relevant"
    return "irrelevant"


def fake_web_search(query, k=2):
    return [(f"web_result_{i}", f"Web result {i} for: {query}") for i in range(k)]


def corrective_retrieve(query, corpus, retriever, grader, web_search):
    """Grade local retrieval; use it, supplement it, or fall back to web
    search entirely depending on how many chunks graded relevant."""
    chunks = retriever(query, corpus)
    relevant = [(s, t) for s, t in chunks if grader(query, t) == "relevant"]

    if len(relevant) >= 2:
        return relevant, "local"
    if len(relevant) == 1:
        return relevant + web_search(query), "local+web"
    return web_search(query), "web"


for q in [
    "what is the refund policy",          # local covers this well
    "refund policy for gift cards",       # local partially covers this
    "what is your shipping carrier",      # local does not cover this
]:
    chunks, source = corrective_retrieve(
        q, local_corpus, local_retrieve, grade, fake_web_search,
    )
    print(q, "->", source, "->", len(chunks), "chunks")

# what is the refund policy -> local -> 2 chunks
# refund policy for gift cards -> local -> 2 chunks
#   (both local chunks contain "refund", so both grade relevant here --
#    a sharper grader keyed to "gift cards" specifically would find zero,
#    which is the point of the self-check below)
# what is your shipping carrier -> web -> 2 chunks
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The comment in the solution admits the "gift cards" query '
              'does not actually exercise the "local+web" branch with this '
              'toy grader. Why not, and what would a grader that actually '
              'caught this look like?',
          expectedAnswer:
              'The stub grader only checks whether both the query and the '
              'chunk contain the word "refund" — it has no way to notice that '
              'the chunk is about the general refund window and receipt '
              'requirement, not gift cards specifically, so both chunks pass '
              'as "relevant" even though neither actually answers the '
              'gift-card question. A grader that caught this would need to '
              'judge relevance to the specific intent of the query, not just '
              'keyword overlap — in a real system this is exactly what an LLM '
              'call does that a keyword check cannot: recognise that a '
              'passage covering the general case does not necessarily cover '
              'a specific exception the query is asking about.',
        ),
        SelfCheckQuestion(
          question:
              'Why does the "local+web" branch keep the one relevant local '
              'chunk and add web results, rather than discarding the local '
              'chunk once web search is triggered at all?',
          expectedAnswer:
              'The one relevant local chunk is still genuinely useful '
              'information — discarding it would throw away a correct, '
              'already-verified piece of context for no reason. The point of '
              'the CRAG-style branch is that partial local coverage should be '
              'supplemented, not replaced, since the local chunk and the web '
              'results are answering different parts of the question rather '
              'than competing to answer the same part. Only when local '
              'retrieval found nothing relevant at all does discarding it '
              'entirely make sense, because there is nothing worth keeping.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 246000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Imagine a research assistant who, no matter what question you ask, '
              'runs to the library, grabs the first book on the nearest shelf, and '
              'hands it to you — even if you asked \u201cwhat\u2019s two plus two?\u201d Agentic '
              'RAG is the upgraded assistant who pauses, checks whether they even '
              'need to leave their chair, then decides what to look for, and only '
              'stops when they\u2019ve actually found what you need.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'In practice, the retriever lives in the agent\u2019s toolbelt right '
              'next to a calculator, a web search, maybe a code runner \u2014 and the '
              'agent\u2019s own reasoning picks which tool, if any, the question '
              'actually calls for. Same tool-selection smarts from the tools '
              'lesson, just with retrieval as one more option instead of a '
              'mandatory stop.',
          startMs: 42000,
          endMs: 82000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'The real magic is the iterative loop: retrieve some documents, '
              'then pause and ask \u201cdoes this actually answer the question?\u201d If '
              'not \u2014 and here\u2019s the key \u2014 you don\u2019t just try again with the '
              'same words. You figure out specifically what was missing and '
              'search for that. This is different from multi-hop, which plans '
              'every step before seeing a single result. Agentic adapts based '
              'on what it actually finds.',
          startMs: 82000,
          endMs: 126000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Corrective RAG takes that grading step and makes it systematic: '
              'score every retrieved document, and if they\u2019re lousy, don\u2019t '
              'just shrug and generate an answer from garbage \u2014 fall back to a '
              'different source entirely, like a web search. Self-RAG goes '
              'further and trains the model to critique its own work mid-stream, '
              'emitting little \u201cis this passage actually useful?\u201d signals right '
              'alongside its output.',
          startMs: 126000,
          endMs: 168000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'But handing the keys to the agent creates new ways to fail. '
              'Over-retrieval is like a student who Googles facts they already '
              'memorized \u2014 harmless once, expensive at scale. Under-retrieval '
              'is worse: the agent gets lazy, stops after one search, and '
              'confidently answers from stale memory \u2014 producing exactly the '
              'kind of fluent nonsense RAG was built to prevent.',
          startMs: 168000,
          endMs: 212000,
        ),
        PodcastSegment(
          id: 'c6',
          speaker: 'Guest',
          text:
              'So it\u2019s not a free upgrade. If you\u2019ve got a clean FAQ and a '
              'well-indexed doc where the answer reliably pops up on the first '
              'try, plain single-shot RAG already nails it. Save the agentic '
              'machinery for those messy, open-ended questions that genuinely '
              'need a few rounds of digging to piece together a complete '
              'answer.',
          startMs: 212000,
          endMs: 246000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 462000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'We\u2019ve walked through plain RAG and we\u2019ve walked through the '
              'agent loop and tool calling separately. Today they collide \u2014 '
              'and the question is: what changes when retrieval stops being a '
              'mandatory step in a pipeline and becomes a decision an agent '
              'gets to make?',
          startMs: 0,
          endMs: 40000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Let\u2019s anchor this in what plain RAG actually commits to. '
              'Every single query \u2014 whether it\u2019s \u201cwhat\u2019s the capital of France?\u201d '
              'or \u201cexplain our obscure internal refund policy\u201d \u2014 triggers the '
              'exact same choreography: embed, search, fetch top-k, stuff into '
              'prompt. Every time. Zero judgment. No pause to ask \u201cdo I even '
              'need outside info for this?\u201d It runs because the code says so.',
          startMs: 40000,
          endMs: 90000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Agentic RAG tears up that fixed schedule. The retriever becomes '
              'just another tool \u2014 same interface, same tool-calling dance you '
              'learned two lessons ago. The agent\u2019s observe-plan-act loop now '
              'decides: should I retrieve at all? What exactly should I search '
              'for? One round or three? Am I done yet? The actual retrieval '
              'guts \u2014 embeddings, indexes, similarity scores \u2014 haven\u2019t changed '
              'one bit.',
          startMs: 90000,
          endMs: 138000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Think of it like a chef\u2019s kitchen. A calculator is the '
              'measuring cup, a web search is the phone to call a supplier, '
              'and the retriever is the well-organized recipe binder on the '
              'shelf. The chef \u2014 the agent \u2014 decides which tool to reach for '
              'based on what they\u2019re cooking. And the tool description is '
              'everything: \u201cuse this for our internal recipes, not general '
              'cooking knowledge\u201d is what stops the chef from flipping through '
              'the binder to figure out how to boil water.',
          startMs: 138000,
          endMs: 186000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Now the iterative loop, and this is where agentic RAG genuinely '
              'parts ways with multi-hop retrieval. Multi-hop is like planning '
              'an entire road trip before you\u2019ve checked a single map \u2014 you '
              'decompose the question upfront into sub-steps. Agentic RAG is '
              'like driving with GPS: you go one stretch, check whether you\u2019re '
              'on track, and only then decide the next turn based on what you '
              'actually see.',
          startMs: 186000,
          endMs: 236000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'So round two\u2019s search query isn\u2019t pre-planned \u2014 it\u2019s born from '
              'round one\u2019s actual failure. Maybe the corpus filed the answer '
              'under different vocabulary than your question used, so the '
              'first search came back empty. A fixed multi-hop plan has no way '
              'to notice that and adapt. The agentic loop goes \u201chmm, nothing '
              'useful \u2014 let me try phrasing this differently\u201d and reformulates '
              'around the specific gap it just discovered.',
          startMs: 236000,
          endMs: 284000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'This connects to two named patterns worth having in your '
              'vocabulary. Corrective RAG \u2014 CRAG \u2014 is like a quality-control '
              'checkpoint: grade every retrieved document, and route based on '
              'the score. Solid scores? Use as-is. Mixed? Keep the good stuff, '
              'supplement with web search. Garbage across the board? Toss it '
              'all and fall back entirely. Self-RAG takes a different angle '
              'and trains the model to bake self-critique into its own output '
              'stream \u2014 little reflection tokens that say \u201cdo I even need '
              'retrieval here?\u201d or \u201cis my own sentence supported by what I '
              'found?\u201d',
          startMs: 284000,
          endMs: 336000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Let\u2019s be honest about the grader though. It\u2019s not some '
              'infallible oracle \u2014 it\u2019s just another model call, and it can '
              'be wrong in both directions. It might dismiss a genuinely '
              'useful passage because the connection isn\u2019t obvious, or accept '
              'a totally off-topic one because it shares some surface-level '
              'words with your query. These patterns boost reliability on '
              'average across many queries. They don\u2019t make any single run '
              'bulletproof.',
          startMs: 336000,
          endMs: 376000,
        ),
        PodcastSegment(
          id: 's9',
          speaker: 'Host',
          text:
              'And new control flow means new failure modes \u2014 the classic '
              'trade. Over-retrieval is the harmless-but-expensive one: '
              'calling the retriever when you already knew the answer, burning '
              'time and money for zero gain. Under-retrieval is the dangerous '
              'one: the agent gets overconfident, stops too early, and answers '
              'from stale memory when a lookup was genuinely needed. That\u2019s '
              'the fluent-wrong-answer nightmare RAG was built to prevent \u2014 '
              'except now it\u2019s sneakier, because the system did retrieve '
              'something. Just not enough of the right thing.',
          startMs: 376000,
          endMs: 424000,
        ),
        PodcastSegment(
          id: 's10',
          speaker: 'Guest',
          text:
              'And don\u2019t forget the runaway loop \u2014 the compounding-error '
              'problem from lesson one, now dressed in retrieval clothes. '
              'Without a step budget, an agent that keeps grading itself \u201cnot '
              'good enough yet\u201d can search forever. So max_rounds is mandatory, '
              'paired with an honest \u201cI couldn\u2019t find enough to answer this '
              'properly\u201d fallback. And for plenty of questions \u2014 a stable FAQ, '
              'a single policy doc \u2014 none of this extra machinery earns its '
              'keep. Plain single-shot RAG already gets it right on the first '
              'try.',
          startMs: 424000,
          endMs: 462000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 892000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Welcome to the long-form deep dive on agentic RAG and '
              'workflows \u2014 the final lesson in this topic. Here\u2019s the route '
              'map: what actually changes between plain and agentic RAG, '
              'exposing the retriever as one tool among many, the iterative '
              'retrieve-reflect-reformulate loop and how it\u2019s genuinely '
              'different from multi-hop, corrective and self-reflective '
              'patterns by name, the specific failure modes this new control '
              'flow introduces, and \u2014 most practically \u2014 when all this extra '
              'machinery is actually worth building.',
          startMs: 0,
          endMs: 70000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Let\u2019s ground this in the contrast, because the whole lesson '
              'lives in that gap. Picture a factory assembly line: every item '
              'that comes down the belt gets the exact same operation, whether '
              'it needs it or not. That\u2019s plain RAG. A query arrives \u2014 any '
              'query \u2014 and it goes through embed, compare, rank, return chunks, '
              'stuff into prompt. Once. Every time. No judgment. The retrieval '
              'step has no idea whether outside information was even needed. '
              'It runs because the assembly line says so.',
          startMs: 70000,
          endMs: 148000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Agentic RAG dismantles that assembly line and hands the '
              'controls to a person \u2014 well, an agent running the observe-'
              'plan-act loop from lesson one. Retrieval stops being a '
              'mandatory station on the belt and becomes a tool the agent can '
              'choose to pick up. Should I retrieve at all? What should I '
              'search for? One round or three? Am I satisfied yet? Nothing '
              'about the embedding model, the vector index, or the similarity '
              'search changes \u2014 same engine, different driver deciding when '
              'to turn the key.',
          startMs: 148000,
          endMs: 224000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'In concrete terms, you write a tool definition for the '
              'retriever exactly like the tools lesson taught: name, '
              'description, input schema. It sits in the tool list alongside '
              'a calculator, a web search, maybe a live database API. And the '
              'description is where the real engineering lives. \u201cUse this for '
              'company-specific or frequently-changing information \u2014 not '
              'general knowledge\u201d is what stops the agent from reflexively '
              'retrieving on every single query, the same way vague tool '
              'descriptions produce wrong tool calls in every other domain.',
          startMs: 224000,
          endMs: 294000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'And sometimes tools genuinely compete for the same question, '
              'which makes the agent\u2019s arbitration interesting. \u201cWhat\u2019s our '
              'refund policy?\u201d is unambiguously a retrieve_docs call \u2014 '
              'internal, company-specific. \u201cWhat\u2019s today\u2019s exchange rate?\u201d is '
              'unambiguously web_search \u2014 internal docs won\u2019t have it and '
              'would be stale even if they did. But \u201chow does our refund policy '
              'compare to the industry standard?\u201d \u2014 that\u2019s a genuinely hard '
              'case that might reasonably call both tools and synthesize '
              'across them. That\u2019s the tool-selection reasoning from two '
              'lessons ago doing real, multi-way arbitration, not just a yes/'
              'no on one option.',
          startMs: 294000,
          endMs: 356000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Now the loop itself, and I want to be precise here because '
              'it\u2019s easy to conflate this with multi-hop retrieval, which '
              'you\u2019d already know from the RAG topic. Multi-hop is like a '
              'chess player who plans ten moves ahead before touching a '
              'piece \u2014 decompose the query into sub-questions upfront, in a '
              'fixed sequence, decided before any retrieval has actually run '
              'at all.',
          startMs: 356000,
          endMs: 414000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Agentic retrieval keeps the ability to search multiple times '
              'but tears up that advance plan. It\u2019s more like a detective '
              'working a case: interview one witness, assess what you learned, '
              'and only then decide who to interview next based on what\u2019s '
              'still unclear. Retrieve, reflect \u2014 \u201cdoes this actually answer '
              'the question?\u201d If yes, case closed. If no \u2014 the chunks are '
              'off-topic, too vague, only partial \u2014 reformulate around what '
              'specifically was missing and go again. Round two\u2019s query exists '
              'only because round one\u2019s actual result came back short, not '
              'because a plan predicted it would.',
          startMs: 414000,
          endMs: 480000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'The relevance grading step inside that loop deserves its own '
              'spotlight. \u201cIs this passage relevant \u2014 yes or no\u201d is a narrow, '
              'focused question that a smaller, cheaper, faster model can '
              'answer reliably. That\u2019s deliberate: separating grading from '
              'final answer generation means you\u2019re not asking one model call '
              'to both judge quality AND compose a beautiful answer '
              'simultaneously. Split responsibilities, and each call does its '
              'one job better \u2014 just like you\u2019d use a dedicated spellchecker '
              'rather than asking your writing partner to proofread while also '
              'brainstorming the next paragraph.',
          startMs: 480000,
          endMs: 530000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'That grading idea crystallized into two papers worth knowing '
              'by name. Self-RAG trains the model to emit reflection tokens '
              'alongside its normal output \u2014 little self-assessments like '
              '\u201cdo I need retrieval here?\u201d, \u201cis this passage actually '
              'relevant?\u201d, \u201cis my own sentence supported by what I retrieved?\u201d '
              '\u2014 baking self-critique directly into the generation stream '
              'rather than bolting it on as a separate step. Corrective RAG, '
              'or CRAG, takes a lighter, model-agnostic approach: a retrieval '
              'evaluator scores each document, and that score routes the '
              'system down one of three paths.',
          startMs: 530000,
          endMs: 594000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Path one: documents score well \u2014 use them as-is, same as '
              'plain RAG. Path two: scores are mixed \u2014 keep what\u2019s good, '
              'supplement with another source like web search. Path three: '
              'scores are uniformly terrible \u2014 discard everything and fall '
              'back to web search entirely. And that third path is what '
              '\u201ccorrective\u201d really means. It\u2019s the difference between a '
              'researcher who, finding nothing useful in one reference book, '
              'says \u201cwell, I\u2019ll just write my answer based on this irrelevant '
              'book anyway\u201d versus one who says \u201cwrong book \u2014 let me reach for '
              'a different one entirely.\u201d',
          startMs: 594000,
          endMs: 656000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'But let\u2019s flag the honesty check: the grader itself is just '
              'another LLM call, not some ground-truth oracle. It can mark a '
              'genuinely useful passage as irrelevant because the connection '
              'requires connecting two dots it missed. It can mark a '
              'completely off-topic passage as relevant because it shares '
              'surface vocabulary with your query \u2014 a passage about \u201cbank\u201d '
              'the financial institution gets flagged for a query about '
              '\u201cbank\u201d the river\u2019s edge. These patterns raise reliability on '
              'average across many queries. They do not make any single '
              'pipeline run infallible, and one bad grading call can still '
              'send a perfectly good passage to the discard pile.',
          startMs: 656000,
          endMs: 710000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Which brings us to the failure modes that come bundled with '
              'all this new control flow. Over-retrieval first: it\u2019s the '
              'digital equivalent of a student who looks up facts they '
              'already memorized. Calling the retriever when you didn\u2019t need '
              'to, or retrieving a second and third time when round one '
              'already had the answer \u2014 burning latency and cost for '
              'absolutely no gain. Harmless in isolation, expensive when it '
              'happens across thousands of queries.',
          startMs: 710000,
          endMs: 758000,
        ),
        PodcastSegment(
          id: 'd13',
          speaker: 'Host',
          text:
              'Under-retrieval is the scarier twin. The agent decides it '
              'has \u201cenough,\u201d gets overconfident, and answers from stale '
              'internal knowledge when a lookup was genuinely needed. Or it '
              'stops after one retrieval round that only covered half the '
              'question. This reproduces the exact fluent-wrong-answer '
              'failure that plain RAG was invented to prevent \u2014 except now '
              'it\u2019s harder to catch, because the system did retrieve '
              'something. Just not enough of the right thing, and a shallow '
              'check of \u201cdid retrieval happen at all?\u201d would give it a '
              'passing grade.',
          startMs: 758000,
          endMs: 812000,
        ),
        PodcastSegment(
          id: 'd14',
          speaker: 'Guest',
          text:
              'And the runaway research loop \u2014 the compounding-error problem '
              'from lesson one, now wearing retrieval clothing. Without a '
              'step budget, an agent that keeps grading its own results as '
              '\u201cnot sufficient\u201d can reformulate and search forever, each '
              'round adding latency and cost without ever clearing its own '
              'bar. A max_rounds guard is not optional \u2014 it\u2019s the difference '
              'between a bounded research process and an infinite loop '
              'triggered by a confused query. And pair it with an honest '
              '\u201cinsufficient information found\u201d fallback, so hitting the '
              'budget produces an admission, not a confident guess built on '
              'thin context.',
          startMs: 812000,
          endMs: 862000,
        ),
        PodcastSegment(
          id: 'd15',
          speaker: 'Host',
          text:
              'So here\u2019s the closing judgment call, and it\u2019s the practical '
              'takeaway: none of this is a universal upgrade over plain RAG. '
              'If you\u2019ve got a well-scoped question against a stable, well-'
              'indexed corpus \u2014 a support bot answering from a curated FAQ, a '
              'lookup against a single policy document \u2014 round one is already '
              'correct, and every extra round of grading and reformulation is '
              'pure overhead. Save the agentic control flow for open-ended '
              'research questions and answers that genuinely need several '
              'rounds of retrieval to assemble. Those are exactly the cases '
              'where a fixed single-shot pipeline would have silently returned '
              'an incomplete answer with no mechanism to notice \u2014 and no way '
              'to try again.',
          startMs: 862000,
          endMs: 892000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Retrieval becomes a decision, not a pipeline stage',
      body:
          'Plain RAG retrieves exactly once per query on a fixed schedule. '
          'Agentic RAG exposes the retriever as one tool among several — a '
          'calculator, a web search tool — and lets the agent\'s own '
          'observe-plan-act loop decide whether to call it, what to search '
          'for, how many times, and when it has enough. The retrieval '
          'mechanics underneath do not change; the controller deciding when '
          'they run does.',
    ),
    SummaryCard(
      title: 'The loop re-plans on what it finds, unlike fixed multi-hop',
      body:
          'Multi-hop retrieval decomposes a query into sub-questions before '
          'any retrieval runs. Agentic retrieval retrieves, reflects on '
          'whether the result actually answers the question, and only then '
          'decides what to search for next — so a reformulated query is '
          'built from a specific shortfall, not committed to in advance. '
          'Corrective RAG formalises the grading step; Self-RAG bakes '
          'similar reflection into the model\'s own output.',
    ),
    SummaryCard(
      title: 'The new control flow has its own failure modes',
      body:
          'Over-retrieval wastes cost calling the retriever when it was not '
          'needed. Under-retrieval — the more dangerous one — stops too '
          'early and answers confidently from stale memory. A loop with no '
          'step budget can research indefinitely without ever hitting its '
          'own bar for enough. And none of this beats plain single-shot RAG '
          'when a corpus is stable and well-indexed — the extra machinery '
          'earns its cost only on open-ended, multi-round questions.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Agentic RAG',
      definition:
          'A RAG architecture in which an LLM agent, rather than fixed '
          'application code, decides whether to retrieve, what to retrieve, '
          'how many retrieval rounds to run, and when it has gathered '
          'enough information to answer — with retrieval exposed as a tool '
          'the agent chooses to call.',
    ),
    KeyConcept(
      term: 'Iterative retrieval loop',
      definition:
          'A retrieve-reflect-reformulate cycle: retrieve, judge whether the '
          'result answers the question, and if not, build a new query from '
          'what specifically was missing and retrieve again, repeating '
          'until sufficient or a step budget is hit.',
    ),
    KeyConcept(
      term: 'Relevance grading',
      definition:
          'A narrow, separate model call that judges whether a retrieved '
          'chunk actually answers the query, distinct from the call that '
          'generates the final answer — the mechanism underlying both the '
          'iterative loop\'s stopping condition and corrective RAG\'s '
          'routing decision.',
    ),
    KeyConcept(
      term: 'Corrective RAG (CRAG)',
      definition:
          'A pattern that scores retrieved documents with a relevance '
          'evaluator and routes accordingly: use them if the score is high, '
          'supplement with another source like web search if ambiguous, or '
          'discard them and fall back entirely if the score is low.',
    ),
    KeyConcept(
      term: 'Self-RAG',
      definition:
          'A framework that trains the model itself to emit reflection '
          'tokens alongside its output, judging whether retrieval is '
          'needed, whether a retrieved passage is relevant, and whether its '
          'own generated text is supported by that passage.',
    ),
    KeyConcept(
      term: 'Over-retrieval / under-retrieval',
      definition:
          'Two opposite agentic-RAG failure modes: over-retrieval calls the '
          'retriever needlessly, wasting latency and cost; under-retrieval '
          'stops too early and answers from stale internal knowledge '
          'instead of retrieving when a lookup was genuinely needed.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Writing a vague retrieval tool description and expecting the '
          'agent to reliably skip it for general-knowledge questions.',
      correction:
          'State explicitly what the tool is for and what it is not for — '
          '"use for company-specific or frequently-changing information, '
          'not general knowledge" — the same discipline the tools lesson '
          'applied to every other tool. Without that signal, models tend to '
          'call an available tool rather than reasoning their way to "I '
          'already know this," producing over-retrieval on questions that '
          'never needed a lookup.',
    ),
    Mistake(
      mistake: 'Running an iterative retrieval loop with no step budget.',
      correction:
          'An agent that keeps grading its own results as insufficient can '
          'reformulate and retrieve indefinitely, the same compounding-'
          'error risk as any unbounded agent loop. Cap max_rounds, and pair '
          'the cap with an explicit "insufficient information found" '
          'fallback so hitting the budget produces an honest admission '
          'rather than a confident answer built on thin context.',
    ),
    Mistake(
      mistake:
          'Reaching for agentic RAG by default because it sounds strictly '
          'more capable than plain RAG.',
      correction:
          'A well-scoped question against a stable, well-indexed corpus '
          'gets no benefit from grading and reformulation — the single-shot '
          'answer is already correct, and every extra round is pure '
          'overhead in latency and cost. The added control flow earns its '
          'keep on open-ended research questions and answers that genuinely '
          'need several retrieval rounds to assemble, not as a universal '
          'upgrade.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'How is agentic RAG different from multi-hop RAG? Both retrieve '
          'more than once.',
      answer:
          'The difference is when the plan is decided. Multi-hop RAG '
          'decomposes a query into sub-questions before any retrieval runs — '
          'the sequence of sub-queries is fixed in advance based on the '
          'decomposition, and if the first sub-query\'s retrieval comes back '
          'empty or the decomposition\'s premise turns out wrong, the fixed '
          'plan has no way to notice or adapt. Agentic RAG retrieves, then '
          'reflects on whether the actual result answers the question, and '
          'only then decides what to search for next — each round is '
          'planned after seeing the previous round\'s real outcome, the same '
          'way ReAct interleaves reasoning and acting instead of planning '
          'everything upfront. That buys robustness against surprises a '
          'fixed decomposition cannot handle, at the cost of unpredictable '
          'latency and the risk of a runaway loop without a step budget. In '
          'practice, I would reach for multi-hop when the decomposition is '
          'genuinely knowable upfront and for the agentic loop when it is '
          'not clear in advance how many rounds a query will need.',
    ),
    InterviewQuestion(
      question:
          'Walk me through what "corrective RAG" actually does when local '
          'retrieval comes back with irrelevant documents.',
      answer:
          'A retrieval evaluator — in practice, a separate, narrow LLM call — '
          'scores each retrieved document for relevance to the query. If the '
          'documents score well, the system uses them as-is, same as plain '
          'RAG. If the score is ambiguous — some relevant, some not — it '
          'keeps what is useful and supplements with another source, like a '
          'web search, rather than answering from an incomplete set alone. '
          'If the score is uniformly low, meaning local retrieval essentially '
          'came up empty, the system discards those results entirely and '
          'falls back to web search rather than handing the generator '
          'low-quality context and hoping the model notices it should ignore '
          'it. The key design point is that the fallback is a deliberate '
          'branch triggered by a measured signal, not something left to the '
          'generator to figure out implicitly — a plain RAG system with no '
          'grading step would hand over the same bad documents and produce a '
          'fluent answer built on nothing useful, with no mechanism to catch '
          'it.',
    ),
    InterviewQuestion(
      question:
          'A team wants to make their RAG chatbot "agentic" because it '
          'sounds more capable. How would you push back or guide that '
          'decision?',
      answer:
          'I would start by asking what specific failure their current '
          'system has, because agentic RAG is a fix for particular problems — '
          'questions needing information from multiple retrieval rounds, '
          'queries where the first attempt commonly misses due to vocabulary '
          'mismatch, or a corpus that sometimes just does not cover the '
          'question — not a general quality upgrade. If their corpus is '
          'stable and well-indexed and the top-k chunks from a single '
          'retrieval pass reliably contain the answer, adding grading and '
          'reformulation loops adds latency, cost and a new class of failure '
          'modes — over-retrieval, under-retrieval, runaway loops without a '
          'step budget — for no measurable gain. I would ask for concrete '
          'examples of queries the current single-shot system gets wrong, '
          'check whether those failures actually look like "needed a second '
          'retrieval round" or "needed a different source entirely" rather '
          'than, say, a chunking or embedding problem that agentic control '
          'flow would not fix at all, and only then scope a bounded '
          'iterative loop or a corrective fallback aimed specifically at '
          'those failure cases, with a step budget and an honest '
          '"insufficient information" fallback built in from the start.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title:
        'Self-RAG: Learning to Retrieve, Generate, and Critique through '
        'Self-Reflection (Asai et al., 2023)',
    url: 'https://arxiv.org/abs/2310.11511',
    description:
        'The paper behind this lesson\'s Self-RAG summary — training a model '
        'to emit reflection tokens judging retrieval necessity, passage '
        'relevance and its own generated output\'s support.',
  ),
  Source(
    title: 'Corrective Retrieval Augmented Generation (Yan et al., 2024)',
    url: 'https://arxiv.org/abs/2401.15884',
    description:
        'The CRAG paper, source of this lesson\'s three-way relevance-'
        'grading and web-search-fallback pattern used in the corrective RAG '
        'section and its code example.',
  ),
  Source(
    title: 'Build a custom RAG agent with LangGraph — LangChain Docs',
    url: 'https://docs.langchain.com/oss/python/langgraph/agentic-rag',
    description:
        'A worked LangGraph implementation of an agent that decides when to '
        'retrieve, grades retrieved document relevance, and rewrites the '
        'query on a failed grade — the concrete architecture this lesson\'s '
        'agentic_retrieve code sketches in plain Python.',
  ),
];
