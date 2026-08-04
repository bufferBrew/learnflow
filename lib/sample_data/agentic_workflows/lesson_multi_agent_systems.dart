import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 1: composing the single-agent loop into orchestrators,
/// hierarchies and debating panels — and the coordination failures that
/// only show up once more than one agent is involved.
const Lesson multiAgentSystemsLesson = Lesson(
  id: 'agentic-multi-agent-systems',
  title: 'Multi-Agent Systems',
  description:
      'Why single-agent loops break down on complex tasks, the '
      'orchestrator/supervisor pattern, hierarchical orchestration, debate '
      'and critique, and the coordination failures unique to systems of '
      'agents.',
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
      id: 'why-multi-agent',
      heading: 'When one agent stops being enough',
      blocks: [
        ProseBlock(
          'Nothing in this lesson is a new primitive. A multi-agent system '
          'is the same observe-plan-act loop from the first lesson in this '
          'topic, built from the same tool-calling mechanics as the second, '
          'run by more than one agent at once and wired together. Everything '
          'interesting here is about composition — how you connect loops you '
          'already understand — not about a fundamentally different kind of '
          'agent.',
        ),
        ProseBlock(
          'The reason to compose them at all is that a single agent has a '
          'single context window, and a complex task can overload it. '
          'Consider one agent asked to research a market, write a report, '
          'fact-check its own claims, and format the result professionally. '
          'Its system prompt has to carry instructions for all four jobs at '
          'once — research methodology, writing style, verification '
          'standards, formatting rules — stacked into one prompt, competing '
          'for the model\'s attention alongside every tool result and every '
          'prior turn. Instructions buried in the middle of a long, crowded '
          'context are reliably followed less often than instructions near '
          'the start or the most recent turn, so the fact-checking rule '
          'written on line forty of a sprawling system prompt is exactly the '
          'kind of thing that gets quietly dropped once the context fills up '
          'with research notes.',
        ),
        ProseBlock(
          'Tool selection degrades for a related reason. Lesson two '
          'established that a model chooses which tool to call based purely '
          'on the name and description you gave it, and that similarly named '
          'tools with overlapping purposes give the model a coin flip on '
          'every call. A generalist agent with forty tools spanning finance, '
          'writing, code execution and web search accumulates exactly this '
          'problem: not because the underlying model got worse, but because '
          'the toolset it has to choose from on every single turn got '
          'bigger, noisier, and more ambiguous.',
        ),
        ProseBlock(
          'Separation of concerns is the fix, and it is a direct import from '
          'ordinary software design. A specialist agent with a narrow tool '
          'subset and a system prompt that says exactly one thing keeps its '
          'context clean by construction — there is no writing-style '
          'instruction competing for attention inside the research agent\'s '
          'prompt, because the research agent was never given one. Several '
          'narrow, focused agents each doing one job well tend to outperform '
          'one generalist agent doing all of the jobs adequately, for the '
          'same underlying reason a team of specialists usually outperforms '
          'one person trying to be a researcher, writer and editor '
          'simultaneously.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Multi-agent is a cost, not a default',
          text:
              'Every agent you add multiplies the number of model calls, the '
              'tokens spent, and the number of places a failure can hide. '
              'The autonomy-spectrum argument from lesson one applies here '
              'directly: reach for a multi-agent architecture because a task '
              'genuinely spans separable concerns that one focused prompt '
              'cannot hold, not because a framework makes spinning up more '
              'agents easy.',
        ),
      ],
    ),
    Section(
      id: 'orchestrator-pattern',
      heading: 'The orchestrator: one controller, many specialists',
      blocks: [
        ProseBlock(
          'The most common shape for a multi-agent system is the '
          'orchestrator, also called a supervisor: one controller agent — '
          'itself running the ordinary agent loop — whose "tools" are not '
          'APIs but other agents. Given a task, the orchestrator decomposes '
          'it into subtasks, dispatches each subtask to a specialist worker '
          'agent with its own narrow tool access and focused prompt, and '
          'once the workers report back, synthesizes their results into one '
          'coherent final answer.',
        ),
        ProseBlock(
          'The interesting design decision is routing: how does the '
          'orchestrator decide which specialist owns a given subtask? Two '
          'approaches dominate in practice. A router LLM call is a small, '
          'cheap model invocation whose only job is classification — given '
          'the query and a fixed list of specialist categories, pick one — '
          'run before any expensive specialist reasoning happens at all. '
          'Explicit task classification does the same job through a '
          'structured output schema rather than free text, which is easier '
          'to validate and harder for the model to answer ambiguously. '
          'Either way, the routing step is deliberately cheaper than the '
          'work it is routing to, because paying full specialist-agent cost '
          'just to decide which specialist should run defeats the purpose.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def billing_worker(query, context):
    return (f"Billing: opened a dispute referencing {context.get('order_id', "
            f"'the order')} for: {query!r}")


def technical_worker(query, context):
    return f"Technical: matched a known crash signature for: {query!r}"


def refunds_worker(query, context):
    return f"Refunds: policy check passed, 5-7 business days, for: {query!r}"


WORKERS = {
    "billing": billing_worker,
    "technical": technical_worker,
    "refunds": refunds_worker,
}


def route(query, model):
    """One cheap classification call: which specialist owns this query?

    A real router asks the model for a single label from a fixed set of
    categories - far cheaper than running every specialist and comparing
    their answers afterwards.
    """
    return model.classify(query, categories=list(WORKERS))


def orchestrate(query, model, context=None):
    """Route once, dispatch to exactly one specialist, then synthesize."""
    context = context or {}
    category = route(query, model)
    print(f"router -> {category!r}")

    worker_result = WORKERS[category](query, context)
    print(f"{category} worker -> {worker_result}")

    # The orchestrator's own model call reasons over the worker's raw
    # output and drafts the reply - it does not just relay the text.
    return model.synthesize(query, category, worker_result)


result = orchestrate(
    "My card was charged twice for the same order", model=production_model
)
print(result)

# router -> 'billing'
# billing worker -> Billing: opened a dispute referencing the order for:
# 'My card was charged twice for the same order'
# We found a duplicate charge and opened a dispute. You will see a
# refund for the extra charge within 5-7 business days.
''',
          caption:
              'route() is deliberately the cheapest call in the whole '
              'system — its only job is picking a specialist, not doing the '
              'specialist\'s work.',
        ),
        ProseBlock(
          'What happens on the way back up matters as much as the routing '
          'decision. The orchestrator does not simply forward a worker\'s '
          'raw output to the user — its final synthesis call reasons over '
          'that output, checks it against the original request, and '
          'produces the actual reply. This is where an orchestrator can '
          'catch an obviously wrong worker answer before it reaches anyone, '
          'and it is also where a subtle mistake most often slips through '
          'unchecked, since the orchestrator has no independent way to '
          'verify a claim a worker hands it beyond noticing it looks '
          'plausible.',
        ),
      ],
    ),
    Section(
      id: 'hierarchical-systems',
      heading: 'Going hierarchical, and what depth costs',
      blocks: [
        ProseBlock(
          'A flat orchestrator dispatching to workers is a two-level tree. '
          'Nothing stops a worker from being an orchestrator itself, '
          'managing its own set of specialists — a supervisor of '
          'supervisors. Anthropic\'s own multi-agent research system works '
          'this way: a lead agent decomposes a research question and spawns '
          'three to five subagents in parallel, and each subagent runs its '
          'own internal loop of tool calls, deciding on its own when it has '
          'gathered enough before reporting back up. That is already a '
          'two-level hierarchy, and frameworks like LangGraph\'s supervisor '
          'pattern support going further — a top-level supervisor '
          'coordinating a research-team supervisor and a writing-team '
          'supervisor, each of which manages its own workers underneath.',
        ),
        ProseBlock(
          'Hierarchy is warranted when a subtask is genuinely large enough '
          'to deserve its own decomposition — when "gather competitive '
          'intelligence" is not one job but a small team\'s worth of '
          'parallel sub-investigations that themselves need coordinating. It '
          'is not warranted just because a task has many steps. A task whose '
          'steps are tightly coupled — where every agent needs to see the '
          'same, constantly changing shared state, the way collaborators '
          'editing the same source file do — tends to do worse under '
          'hierarchical decomposition than under one agent, or one flat '
          'orchestrator, precisely because splitting tightly coupled work '
          'across isolated contexts is what breaks the coupling.',
        ),
        ProseBlock(
          'Coordination overhead is the cost, and it grows with depth for '
          'three concrete reasons. Every layer adds a full round trip — a '
          'prompt, a generation, a parse — before any of the actual work '
          'underneath it even starts. Every layer also compresses: the '
          'top-level orchestrator sees only a summary from the layer below '
          'it, not the raw detail the leaf-level workers actually saw, so '
          'information degrades hop by hop the way a message degrades '
          'passed down a chain of people. And every layer multiplies token '
          'cost, because each sub-orchestrator carries its own system '
          'prompt and its own workers\' transcripts on top of everything '
          'above it. Anthropic reported roughly fifteen times the token '
          'cost of a single chat turn for their two-level system — and that '
          'multiplier compounds, not adds, with every further layer you '
          'stack on top.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Depth is a design decision, not a default',
          text:
              'Adding a layer of orchestration should require the same '
              'justification as reaching for more autonomy in lesson one: '
              'the task genuinely needs it. An extra layer added because a '
              'framework makes nesting supervisors easy pays the full '
              'coordination-overhead cost for no matching benefit.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: why Anthropic caps its own system at two levels',
          children: [
            ProseBlock(
              'Anthropic\'s engineering writeup of their research system is '
              'candid about the failure modes an early, more deeply nested '
              'version actually hit: agents spawning far too many subagents '
              'for simple queries, subagents searching endlessly for '
              'sources that did not exist, and — the one specific to '
              'hierarchy — agents "distracting each other with excessive '
              'updates" once enough of them were coordinating at once. The '
              'fix was not architectural; it was prompt engineering, '
              'because each agent in the hierarchy is steered entirely by '
              'the instructions it was given, and vague instructions at any '
              'layer propagate confusion to every layer beneath it.',
            ),
            ProseBlock(
              'The deeper reason a subagent needs unusually explicit '
              'instructions is that it lacks the shared context the lead '
              'agent has. The lead agent sees the whole conversation and the '
              'whole plan; a subagent typically sees only the specific task '
              'description it was handed. If that description is even '
              'slightly ambiguous, the subagent has no surrounding context '
              'to resolve the ambiguity with — unlike a single agent, which '
              'can always fall back on everything that came before in its '
              'own transcript. Every additional layer of hierarchy repeats '
              'this problem one level further down, which is the concrete '
              'reason coordination overhead is not just a token-cost line '
              'item but a real accuracy risk.',
            ),
            ProseBlock(
              'The practical heuristic that falls out of this: default to a '
              'flat orchestrator-and-workers structure, and add another '
              'layer only when a specific subtask is, on its own, complex '
              'enough to deserve its own decomposition — not as a blanket '
              'policy for "big tasks." Treat each additional layer as a '
              'decision that has to earn its cost, exactly like the '
              'autonomy-spectrum framing from the first lesson in this '
              'topic.',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'debate-and-critique',
      heading: 'Debate and critique: agents checking each other',
      blocks: [
        ProseBlock(
          'Orchestration splits a task by subject matter. Debate splits it '
          'by perspective: several agent instances — the same model prompted '
          'as different personas, or genuinely different models — '
          'independently produce a first-pass answer to the same question, '
          'then each is shown every other agent\'s answer and reasoning and '
          'asked to critique it and, if warranted, revise its own. The cycle '
          'repeats for a small number of rounds, after which a final answer '
          'is settled by consensus, a vote, or a separate judge agent.',
        ),
        ProseBlock(
          'The research behind this is specific: a 2023 paper on '
          'multiagent debate found that having several language model '
          'instances propose and argue over answers across multiple rounds '
          'measurably improves mathematical and strategic reasoning and '
          'reduces factual errors compared to a single model answering '
          'once. The mechanism is intuitive once you see it: a wrong '
          'first-pass answer often survives simply because nothing forces '
          'the model to re-examine its own reasoning. A second agent\'s '
          'independently derived, differing answer is a forcing function — '
          'it surfaces a contradiction that has to be explained, which '
          'self-reflection alone tends to miss, the same way a person '
          'catches their own bug far more reliably once a colleague\'s '
          'different answer forces them to justify the discrepancy out '
          'loud.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def propose(question, persona, model):
    """First-pass, independent answer from one persona."""
    return model.generate_as(persona, question)


def critique_and_revise(question, persona, own_answer, other_answers, model):
    """See every other agent's answer, then revise or hold."""
    return model.generate_as(
        persona,
        f"{question}\\nYour answer: {own_answer}\\n"
        f"Other agents said: {other_answers}\\n"
        "Point out any concrete flaw you see, then give your answer again.",
    )


def debate(question, personas, model, rounds=2):
    """Independent proposals, then critique-and-revise for `rounds` rounds."""
    answers = {p: propose(question, p, model) for p in personas}

    for round_n in range(rounds):
        print(f"-- round {round_n} --")
        next_answers = {}
        for p in personas:
            others = {k: v for k, v in answers.items() if k != p}
            next_answers[p] = critique_and_revise(
                question, p, answers[p], others, model
            )
            print(f"{p}: {next_answers[p]}")
        answers = next_answers

    return answers


final_answers = debate(
    "Is it safe to deploy this migration during business hours?",
    personas=["optimist", "skeptic"],
    model=production_model,
    rounds=2,
)

# -- round 0 --
# optimist: Yes - the migration is additive and staging ran clean.
# skeptic: No - staging never saw production write volume; wait for a
# maintenance window.
# -- round 1 --
# optimist: Agreed, staging load doesn't match production - deploy in
# the next maintenance window instead.
# skeptic: Confirmed - deploy in the next maintenance window.
''',
          caption:
              'The optimist changes its answer only after seeing a concrete, '
              'specific objection — that is the whole value of debate, and '
              'also exactly the step that can fail silently if the critique '
              'is vague or the objection is dismissed too easily.',
        ),
        ProseBlock(
          'The costs are real and worth stating plainly. Debate multiplies '
          'token and latency cost by roughly the number of agents times the '
          'number of rounds — two personas across three rounds is on the '
          'order of six times the tokens of asking once, before counting a '
          'judge agent if one is added to break ties. That multiplier has to '
          'be worth paying, which is why debate tends to show up on '
          'high-stakes reasoning or factuality questions rather than as a '
          'default wrapper around every model call.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title:
              'Agreement is not evidence when the agents share a blind '
              'spot',
          text:
              'If every "independent" debater is a separate call to the '
              'same underlying model, they are prone to the exact same '
              'reasoning shortcuts and gaps, because they share the same '
              'training data and biases. Confident three-way agreement in '
              'that setup can just mean a shared mistake went unchallenged '
              'by everyone in the room. Debate\'s error-catching power comes '
              'from genuine diversity — different model families, different '
              'prompted assumptions, different sources — not from the raw '
              'number of agents in the panel.',
        ),
      ],
    ),
    Section(
      id: 'communication-and-failure-modes',
      heading: 'How agents talk, and how the wiring breaks',
      blocks: [
        ProseBlock(
          'Every multi-agent system needs a way for agents to pass '
          'information to each other, and in practice there are three '
          'patterns. A shared scratchpad, or blackboard, is mutable state — '
          'a document, a key-value store — that any agent can read from and '
          'write to; agents post partial results and later agents pick up '
          'from whatever is there. Direct message passing has the '
          'orchestrator send each worker an explicit task and receive an '
          'explicit result back, the handoff-tool style used by LangGraph\'s '
          'supervisor pattern, with no shared state at all. A shared '
          'conversation transcript puts every agent\'s turns into one '
          'growing conversation that every agent reads in full, like a '
          'group chat everyone is present in.',
        ),
        ProseBlock(
          'Each pattern fails in its own characteristic way. A blackboard '
          'loses context silently: if one agent overwrites a field another '
          'agent expected to still be there, or reads a stale value written '
          'before a more recent update, the agents\' beliefs about the '
          'shared state quietly diverge from what is actually in it, and '
          'nothing flags the mismatch. Direct message passing keeps each '
          'agent\'s context clean and isolated, but every hop costs a full '
          'round trip of serialization and prompting, so passing large '
          'blobs of raw data between many agents this way multiplies '
          'latency and token cost per hop. A shared transcript keeps '
          'everyone synchronized with no explicit handoff plumbing at all, '
          'but it grows without bound — every agent re-reads the entire '
          'history on every turn, so cost grows with the number of turns '
          'times the number of agents, and it is precisely the "agents '
          'distracting each other with excessive updates" failure Anthropic '
          'reported when too many agents share one transcript.',
        ),
        ProseBlock(
          'Beyond how they talk, multi-agent systems fail in ways a single '
          'agent loop cannot, because a single agent has no downstream '
          'agent to mislead. A cascading error starts small: a subagent '
          'misreads a tool result or hallucinates a detail, hands it '
          'upward as though verified, and the orchestrator — with no '
          'independent way to check a worker\'s claim — treats it as '
          'ground truth. A third agent further downstream builds prose '
          'around that wrong fact. By the time the final output is wrong, '
          'no single agent\'s own transcript looks obviously broken; the '
          'mistake is only visible in the gap between what was claimed and '
          'what was true, several hops removed from where it actually '
          'happened. An infinite delegation loop is the second distinctive '
          'failure: a worker decides it needs help and hands part of the '
          'task to another agent, which — lacking the full picture — hands '
          'it to a third, which hands it back to the first, and the '
          'system\'s entire step budget gets consumed by handoffs instead '
          'of work. Both compound directly into the third failure, '
          'cost and latency blowup, since a cascading error often triggers '
          'retries at every layer it passed through, which is strictly '
          'more expensive than one agent retrying its own single mistake.',
        ),
        ProseBlock(
          'Three mitigations do most of the work, and they map directly '
          'onto the three failure modes above. Turn limits extend the '
          'max_steps guardrail from the first lesson in this topic to a '
          'system-wide handoff budget, so a delegation loop fails loudly '
          'and cheaply instead of quietly consuming the entire run. A '
          'supervisor with veto power means the orchestrator validates or '
          'spot-checks a worker\'s output against some structural check '
          'before accepting it and passing it downstream, rather than '
          'treating every result as ground truth by default. And '
          'structured handoff schemas — typed, validated objects instead '
          'of free-text messages an agent can wander outside of — make a '
          'cascading error traceable after the fact, because each handoff '
          'is a discrete, inspectable record rather than a claim buried '
          'somewhere inside a paragraph.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
REQUIRED_HANDOFF_KEYS = {"status", "to", "task", "reason"}


def validate_handoff(handoff):
    missing = REQUIRED_HANDOFF_KEYS - handoff.keys()
    if missing:
        raise ValueError(f"Malformed handoff, missing keys: {missing}")


def run_with_handoffs(task, workers, start, max_handoffs=4):
    """Follow structured handoffs between workers until one finishes,
    or the system-wide handoff budget runs out."""
    trail = []
    current, handoffs = start, 0

    while handoffs < max_handoffs:
        result = workers[current](task)

        if result["status"] == "done":
            return result["output"]

        validate_handoff(result)
        trail.append(f"{current} -> {result['to']} ({result['reason']})")
        current, handoffs = result["to"], handoffs + 1

    return f"Stopped after {max_handoffs} handoffs: {' | '.join(trail)}"


def cautious_worker(task):
    return {
        "status": "handoff",
        "to": "specialist",
        "task": task,
        "reason": "needs domain expertise",
    }


def specialist_worker(task):
    return {
        "status": "handoff",
        "to": "cautious_worker",
        "task": task,
        "reason": "needs a second opinion",
    }


WORKERS = {"cautious_worker": cautious_worker, "specialist": specialist_worker}

print(run_with_handoffs("audit this contract", WORKERS, start="cautious_worker"))
# Stopped after 4 handoffs: cautious_worker -> specialist (needs domain
# expertise) | specialist -> cautious_worker (needs a second opinion) |
# cautious_worker -> specialist (needs domain expertise) | specialist ->
# cautious_worker (needs a second opinion)
''',
          caption:
              'Two misconfigured workers ping-pong the task forever; the '
              'handoff budget converts an invisible infinite loop into a '
              'loud, traceable stop with the full delegation trail attached.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-mas-orchestrator',
      title: 'Route and dispatch to a specialist worker',
      prompt: [
        ProseBlock(
          'Implement classify_task(query), a stand-in for a router LLM '
          'call, that returns one of "billing", "technical" or "refunds" '
          'based on keywords in the query. Then implement orchestrate(query) '
          'so it routes once, dispatches to exactly the matching worker, and '
          'returns a synthesized reply that names which specialist handled '
          'it.',
        ),
        ProseBlock(
          'Keep the classifier simple — this exercise is about the control '
          'flow of routing and dispatching to one specialist, not about '
          'building a real classifier.',
        ),
      ],
      starterCode: '''
def billing_worker(query):
    return f"[billing] Duplicate-charge dispute opened for: {query!r}"


def technical_worker(query):
    return f"[technical] Diagnostic run, matched a known bug for: {query!r}"


def refunds_worker(query):
    return f"[refunds] Refund policy check complete for: {query!r}"


WORKERS = {
    "billing": billing_worker,
    "technical": technical_worker,
    "refunds": refunds_worker,
}


def classify_task(query):
    """Stub for a router LLM call: pick one of WORKERS by keyword."""
    ...


def orchestrate(query):
    """Route, dispatch to exactly one specialist, and synthesize a reply."""
    ...


print(orchestrate("My card was charged twice for the same order"))
print(orchestrate("The app crashes every time I open settings"))
print(orchestrate("I'd like a refund for a cancelled subscription"))
''',
      solutionCode: '''
def billing_worker(query):
    return f"[billing] Duplicate-charge dispute opened for: {query!r}"


def technical_worker(query):
    return f"[technical] Diagnostic run, matched a known bug for: {query!r}"


def refunds_worker(query):
    return f"[refunds] Refund policy check complete for: {query!r}"


WORKERS = {
    "billing": billing_worker,
    "technical": technical_worker,
    "refunds": refunds_worker,
}


def classify_task(query):
    """Stub for a router LLM call: pick one of WORKERS by keyword."""
    lowered = query.lower()
    if "refund" in lowered or "cancel" in lowered:
        return "refunds"
    if "charge" in lowered or "billed" in lowered:
        return "billing"
    if "crash" in lowered or "bug" in lowered or "error" in lowered:
        return "technical"
    return "technical"  # default: safest guess when nothing matches


def orchestrate(query):
    """Route, dispatch to exactly one specialist, and synthesize a reply."""
    category = classify_task(query)
    worker_result = WORKERS[category](query)
    return f"[orchestrator routed to {category}] {worker_result}"


print(orchestrate("My card was charged twice for the same order"))
print(orchestrate("The app crashes every time I open settings"))
print(orchestrate("I'd like a refund for a cancelled subscription"))

# [orchestrator routed to billing] [billing] Duplicate-charge dispute
# opened for: 'My card was charged twice for the same order'
# [orchestrator routed to technical] [technical] Diagnostic run, matched
# a known bug for: 'The app crashes every time I open settings'
# [orchestrator routed to refunds] [refunds] Refund policy check
# complete for: "I'd like a refund for a cancelled subscription"
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'This router is a hardcoded keyword classifier standing in '
              'for a router LLM call. What real-world queries would break '
              'it, and why would a real router LLM call generally handle '
              'those better?',
          expectedAnswer:
              'A query that spans two categories at once — "my order never '
              'arrived and now I can\'t log in" — has no clean keyword '
              'match, so a hardcoded classifier either falls through to a '
              'default category or matches whichever keyword happens to '
              'appear first, sending the whole query to a specialist who '
              'has no reason to also handle the other half. A real router '
              'LLM call can actually read the query\'s meaning, recognize '
              'that it spans two concerns, and either pick the better-fit '
              'specialist for the primary complaint or split the query into '
              'two subtasks — something string matching can never do '
              'because it has no understanding of the query, only surface '
              'overlap with a fixed set of words.',
        ),
        SelfCheckQuestion(
          question:
              'Why does the orchestrator call exactly one worker rather '
              'than calling all three and picking the best answer?',
          expectedAnswer:
              'Calling every worker for every query would technically work, '
              'but it multiplies cost by the number of specialists on every '
              'single request regardless of relevance — exactly the '
              'token-and-latency cost problem the lesson raises about '
              'adding agents. Routing to one worker is the entire point of '
              'separation of concerns: a cheap classification step up front '
              'means only the relevant specialist\'s narrower, more '
              'expensive reasoning ever runs, instead of paying for three '
              'specialists\' full reasoning to answer a question only one '
              'of them was actually equipped to handle.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-mas-handoff-guardrail',
      title: 'Stop an infinite delegation loop with a handoff budget',
      prompt: [
        ProseBlock(
          'Two workers below are misconfigured: each one always hands the '
          'task straight back to the other instead of finishing it. '
          'Implement run_with_handoffs(task, workers, start, max_handoffs) '
          'so it follows the chain of handoffs, but stops and reports the '
          'full delegation trail once max_handoffs is exceeded instead of '
          'looping forever.',
        ),
        ProseBlock(
          'Also validate that every handoff dict contains "status", "to", '
          '"task" and "reason" before following it, raising a clear error '
          'if any key is missing — a malformed handoff should never be '
          'silently followed.',
        ),
      ],
      starterCode: '''
def worker_a(task, history):
    """Always escalates to worker_b, claiming it needs pricing data."""
    return {"status": "handoff", "to": "worker_b", "task": task,
            "reason": "needs pricing data"}


def worker_b(task, history):
    """Misconfigured: always hands back to worker_a instead of finishing."""
    return {"status": "handoff", "to": "worker_a", "task": task,
            "reason": "needs manager approval"}


WORKERS = {"worker_a": worker_a, "worker_b": worker_b}


def run_with_handoffs(task, workers, start, max_handoffs=5):
    """Follow handoffs until one worker finishes, or the budget runs out."""
    ...


print(run_with_handoffs("price a bulk order", WORKERS, start="worker_a"))
''',
      solutionCode: '''
REQUIRED_KEYS = {"status", "to", "task", "reason"}


def worker_a(task, history):
    """Always escalates to worker_b, claiming it needs pricing data."""
    return {"status": "handoff", "to": "worker_b", "task": task,
            "reason": "needs pricing data"}


def worker_b(task, history):
    """Misconfigured: always hands back to worker_a instead of finishing."""
    return {"status": "handoff", "to": "worker_a", "task": task,
            "reason": "needs manager approval"}


WORKERS = {"worker_a": worker_a, "worker_b": worker_b}


def run_with_handoffs(task, workers, start, max_handoffs=5):
    """Follow handoffs until one worker finishes, or the budget runs out."""
    history = []
    current, handoffs = start, 0

    while handoffs < max_handoffs:
        result = workers[current](task, history)

        if result["status"] == "done":
            return result["output"]

        missing = REQUIRED_KEYS - result.keys()
        if missing:
            raise ValueError(f"Malformed handoff, missing keys: {missing}")

        history.append(f"{current} -> {result['to']} ({result['reason']})")
        current, handoffs = result["to"], handoffs + 1

    trail = " | ".join(history)
    return f"Stopped after {max_handoffs} handoffs: {trail}"


print(run_with_handoffs("price a bulk order", WORKERS, start="worker_a"))
# Stopped after 5 handoffs: worker_a -> worker_b (needs pricing data) |
# worker_b -> worker_a (needs manager approval) | worker_a -> worker_b
# (needs pricing data) | worker_b -> worker_a (needs manager approval) |
# worker_a -> worker_b (needs pricing data)
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The handoff budget stopped the loop, but the task never '
              'got done. What does catching this failure with a '
              'handoff-specific guard buy you compared to letting a generic '
              'max_steps cap from lesson one eventually stop the same run?',
          expectedAnswer:
              'A generic step cap would also stop the run eventually, but '
              'it would report only "ran out of steps" with no indication '
              'of why — it has no concept of which two agents were '
              'ping-ponging or over what. A handoff-specific guard keeps a '
              'structured trail of who handed off to whom and for what '
              'reason at every step, so when it fires you get a debuggable '
              'record — worker_a to worker_b to worker_a, alternating '
              '"pricing data" and "manager approval" reasons — instead of an '
              'opaque timeout. That trail is the difference between noticing '
              'a bug exists and immediately knowing which two agents to fix.',
        ),
        SelfCheckQuestion(
          question:
              'Suppose worker_b returned a handoff dict missing the '
              '"reason" key. Should run_with_handoffs silently proceed with '
              'the handoff anyway, or reject it? Why does that matter more '
              'here than it would for a single agent calling one tool with '
              'a missing argument?',
          expectedAnswer:
              'It should reject it, which is exactly what the missing-keys '
              'check does by raising instead of following the handoff. In a '
              'single agent calling one tool, a malformed call is caught, '
              'described as an error, and fed back so the model can retry a '
              'moment later — the mistake never leaves the loop. In a '
              'multi-agent system, a malformed handoff becomes state the '
              'next agent inherits and reasons from immediately, and that '
              'next agent may make its own downstream decisions before '
              'anyone re-examines the handoff. Validating the schema at '
              'every hop is what keeps one malformed handoff from turning '
              'into a cascading error several agents removed from where it '
              'actually happened.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-mas-debate',
      title: 'Run a two-persona debate loop',
      prompt: [
        ProseBlock(
          'Implement debate(question, rounds) using the two deterministic '
          'persona stubs below. optimist_step should change its stance to '
          'agreement only after it sees the literal phrase "test coverage" '
          'in the skeptic\'s most recent message; otherwise it holds its '
          'original position. After the rounds finish, return the '
          'optimist\'s final message if it starts with "Agreed", otherwise '
          'return a string saying no consensus was reached.',
        ),
        ProseBlock(
          'Print each turn as it happens, in the order optimist then '
          'skeptic, so the transcript reads like an actual back-and-forth.',
        ),
      ],
      starterCode: '''
def optimist_step(history):
    """Deterministic stand-in for a persona LLM call."""
    skeptic_msgs = [m["text"] for m in history if m["speaker"] == "skeptic"]
    if skeptic_msgs and "test coverage" in skeptic_msgs[-1]:
        return "Agreed - the payment path needs coverage before shipping."
    return "Ship it today, the failure risk looks low."


def skeptic_step(history):
    """Always raises the same concern regardless of what optimist said."""
    return "The new payment path has no test coverage yet - do not ship."


def debate(question, rounds=2):
    """Alternate optimist/skeptic turns, then settle on a final answer."""
    ...


print(debate("Should we ship the payment feature today?"))
''',
      solutionCode: '''
def optimist_step(history):
    """Deterministic stand-in for a persona LLM call."""
    skeptic_msgs = [m["text"] for m in history if m["speaker"] == "skeptic"]
    if skeptic_msgs and "test coverage" in skeptic_msgs[-1]:
        return "Agreed - the payment path needs coverage before shipping."
    return "Ship it today, the failure risk looks low."


def skeptic_step(history):
    """Always raises the same concern regardless of what optimist said."""
    return "The new payment path has no test coverage yet - do not ship."


def debate(question, rounds=2):
    """Alternate optimist/skeptic turns, then settle on a final answer."""
    history = [{"speaker": "question", "text": question}]
    last_optimist = None

    for round_n in range(rounds):
        optimist_text = optimist_step(history)
        history.append({"speaker": "optimist", "text": optimist_text})
        print(f"round {round_n} optimist: {optimist_text}")
        last_optimist = optimist_text

        skeptic_text = skeptic_step(history)
        history.append({"speaker": "skeptic", "text": skeptic_text})
        print(f"round {round_n} skeptic: {skeptic_text}")

    if last_optimist is not None and last_optimist.startswith("Agreed"):
        return last_optimist
    return "No consensus reached - escalate to a human reviewer."


print(debate("Should we ship the payment feature today?"))
# round 0 optimist: Ship it today, the failure risk looks low.
# round 0 skeptic: The new payment path has no test coverage yet - do
# not ship.
# round 1 optimist: Agreed - the payment path needs coverage before
# shipping.
# round 1 skeptic: The new payment path has no test coverage yet - do
# not ship.
# Agreed - the payment path needs coverage before shipping.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'optimist_step only changes its answer when it sees the '
              'literal substring "test coverage" in the skeptic\'s message. '
              'What does this simplification hide about why real '
              'multi-agent debate can fail to converge?',
          expectedAnswer:
              'Real models do not search for exact substrings — they have '
              'to actually parse another agent\'s argument and judge '
              'whether it is a valid objection, and that judgment itself can '
              'go wrong: an agent might dismiss a genuinely valid critique '
              'as unconvincing, or get talked into a confidently worded but '
              'incorrect argument. The deterministic stub always '
              '"recognizes" the objection because it is pattern-matching '
              'one specific phrase, but a real debate has no such '
              'guarantee — convergence toward the correct answer depends on '
              'the agents actually being able to tell a good argument from '
              'a bad one, which is precisely the capability debate is '
              'supposed to be testing, not something you can assume up '
              'front.',
        ),
        SelfCheckQuestion(
          question:
              'If debate() ran three personas instead of two, each an '
              'independent call to the same underlying model, would you '
              'expect three-way debate to be roughly three times as likely '
              'to catch an error as one model answering alone? Why or why '
              'not?',
          expectedAnswer:
              'Not reliably, no. If all three personas are calls to the '
              'same underlying model, they share its training data and its '
              'blind spots, so the same category of mistake can appear in '
              'all three independently generated answers at once — three '
              'agents "agreeing" in that case only shows the shared blind '
              'spot went unquestioned by everyone in the room, not that it '
              'was checked and passed. Extra agents add real error-catching '
              'power only to the extent they are genuinely diverse — '
              'different model families, different prompted assumptions, '
              'different sources of information — otherwise a bigger panel '
              'is mostly a bigger token bill for a similar failure rate.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 244000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Multi-agent systems, in under five minutes. Imagine you\'re '
              'managing a project team. You wouldn\'t ask one person to be '
              'the researcher, writer, editor, AND fact-checker all at once '
              '— they\'d drown in conflicting instructions. Same problem hits '
              'a single agent when a task crams too many roles into one '
              'context. The fix is composing multiple copies of the loop you '
              'already know, not inventing a new kind of agent.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'The default shape is the orchestrator, or supervisor: one '
              'controller agent decomposes the task — like a project manager '
              'breaking work into tickets — routes each piece to a narrow '
              'specialist with its own tight tool set and prompt, and once '
              'they report back, synthesizes their results into one answer. '
              'Routing is usually a cheap classification call, not an '
              'expensive specialist.',
          startMs: 42000,
          endMs: 84000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Stack that pattern and you get hierarchy — a manager of '
              'managers — useful when a subtask is itself big enough to '
              'need its own team. But every extra layer adds a full round '
              'trip and loses detail on the way up, like a game of '
              'telephone. Anthropic measured roughly fifteen times the '
              'tokens of a normal chat for just a two-level system. Depth '
              'costs real money.',
          startMs: 84000,
          endMs: 126000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Then there\'s debate: multiple agents propose answers and '
              'critique each other before settling on a final one — like '
              'having two analysts independently evaluate the same problem '
              'and then compare notes. It genuinely catches reasoning errors '
              'a solo pass misses, especially on math and factual questions. '
              'But it multiplies cost by roughly agents times rounds, and '
              'if the "debaters" are all the same underlying model, they can '
              'share the exact same blind spot and agree on the wrong answer '
              'with total confidence.',
          startMs: 126000,
          endMs: 168000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'However agents pass information — a shared scratchpad anyone '
              'can scribble on, direct handoffs between specific agents, or '
              'one shared group chat — each pattern has its own failure '
              'mode: silently lost context when someone overwrites the '
              'whiteboard, per-hop overhead, or a transcript that bloats '
              'without bound while every agent rereads the whole thing.',
          startMs: 168000,
          endMs: 206000,
        ),
        PodcastSegment(
          id: 'c6',
          speaker: 'Guest',
          text:
              'And the failure modes to remember: cascading errors '
              'compounding through the chain — one agent\'s mistake becomes '
              'another\'s "fact," infinite delegation loops where agents '
              'just hand a task back and forth like a hot potato, and cost '
              'blowup. Mitigated with turn limits, a supervisor that can '
              'veto a worker\'s output, and structured handoff schemas '
              'instead of free text.',
          startMs: 206000,
          endMs: 244000,
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
              'Quick recap: an agent is the observe-plan-act loop from '
              'lesson one, calling tools the way lesson two described. '
              'Today\'s question: what happens when a task is too big for one '
              'loop to carry alone? The answer is composition — several '
              'loops wired together, like building a team instead of relying '
              'on one person. Nothing new at the primitive level, everything '
              'new at the coordination level.',
          startMs: 0,
          endMs: 48000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Two concrete things break first. Context window pressure: '
              'cram research rules, writing style, and fact-checking '
              'standards into one system prompt, and instructions buried in '
              'the middle get followed less reliably than ones near the '
              'top. And tool-selection confusion: a generalist agent with '
              'forty tools across unrelated domains starts making wrong '
              'calls just from name overlap — exactly the failure mode from '
              'the tools lesson.',
          startMs: 48000,
          endMs: 96000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'The fix is separation of concerns — specialist agents with '
              'narrow tool subsets and single-purpose prompts, like having a '
              'research analyst, a writer, and an editor instead of one '
              'overloaded generalist. Nothing irrelevant competes for '
              'attention inside any one agent\'s context. Several focused '
              'agents beat one generalist for the same reason a specialist '
              'team beats a solo generalist on complex projects.',
          startMs: 96000,
          endMs: 144000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Which brings us to the default architecture: the orchestrator, '
              'or supervisor. One controller decomposes the task, routes '
              'each piece to a specialist — usually via a cheap router LLM '
              'call or structured classification — and once workers report '
              'back, synthesizes results into one coherent reply. The '
              'synthesis step is where an orchestrator can catch an obviously '
              'wrong worker answer, and also where subtle mistakes most '
              'often slip through unchecked.',
          startMs: 144000,
          endMs: 192000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Nothing stops a worker from being an orchestrator itself — '
              'that\'s hierarchy. Anthropic\'s research system does this: a '
              'lead agent spawns three to five subagents in parallel, and '
              'each runs its own internal tool-calling loop before reporting '
              'up. It\'s warranted when a subtask is genuinely big enough to '
              'need its own team — like "gather competitive intelligence" '
              'being a team effort, not a single lookup.',
          startMs: 192000,
          endMs: 240000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'And it costs accordingly. Every layer adds a full round trip '
              'before real work starts, every layer compresses detail the way '
              'a message degrades passed down a chain of people, and every '
              'layer multiplies tokens — Anthropic reported roughly fifteen '
              'times the cost of a normal chat for a two-level system, and '
              'that compounds, not adds, with each layer. It\'s also worth '
              'noting this does poorly on tightly coupled tasks like coding, '
              'where everyone needs to see the same live state.',
          startMs: 240000,
          endMs: 288000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Different axis entirely: debate. Multiple agents propose '
              'answers independently, then critique each other and revise '
              'over a few rounds — like having an optimist and a skeptic '
              'argue before reaching consensus. A 2023 paper found this '
              'measurably improves math and reasoning and cuts factual '
              'errors, because a second, independently derived, differing '
              'answer forces a contradiction to be explained — something '
              'self-reflection alone tends to miss.',
          startMs: 288000,
          endMs: 336000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'The cost is roughly agents times rounds in extra tokens — '
              'two personas, three rounds, is about six times one call. '
              'And the sharper risk: if the "independent" debaters are all '
              'calls to the same model, they share its blind spots. '
              'Confident agreement can just mean nobody in the room caught '
              'the shared mistake, not that the answer was actually checked.',
          startMs: 336000,
          endMs: 384000,
        ),
        PodcastSegment(
          id: 's9',
          speaker: 'Host',
          text:
              'Underneath all of this is how agents actually communicate. '
              'A shared blackboard any agent can read and write loses context '
              'silently when writes overwrite or go unseen — like someone '
              'erasing part of the whiteboard without telling anyone. Direct '
              'message passing keeps context clean but costs a round trip '
              'per hop. A shared transcript keeps everyone synced but grows '
              'without bound — every agent rereads everything every turn.',
          startMs: 384000,
          endMs: 432000,
        ),
        PodcastSegment(
          id: 's10',
          speaker: 'Guest',
          text:
              'Which sets up the failure modes unique to multi-agent systems: '
              'cascading errors — one agent\'s mistake gets accepted as fact '
              'by the next and compounds downstream; infinite delegation '
              'loops — a task ping-pongs between agents; and cost blowup. '
              'Turn limits, supervisor veto power, and structured handoff '
              'schemas instead of free text are what actually contain all '
              'three. Same lesson as autonomy in general: more agents buy '
              'more capability AND more cost, and the scaffolding that keeps '
              'it trustworthy is part of the price.',
          startMs: 432000,
          endMs: 480000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 840000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Deep dive on multi-agent systems. Think of it as scaling from '
              'a solo consultant to a consulting firm. The route: why a '
              'single agent loop breaks down, the orchestrator-and-worker '
              'pattern, hierarchical orchestration and what depth costs, '
              'debate and critique as a different axis of composition, how '
              'agents communicate in practice, and the three failure modes '
              'that only show up once you have more than one agent.',
          startMs: 0,
          endMs: 60000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with why one agent stops being enough — it\'s two '
              'concrete failures, not a vague feeling. First, context window '
              'pressure. Give one agent a task spanning research, writing, '
              'fact-checking, and formatting, and its system prompt has to '
              'carry instructions for all four at once. Instructions buried '
              'in the middle get followed less reliably — the fact-checking '
              'rule on line forty quietly gets dropped once the context '
              'fills with research notes.',
          startMs: 60000,
          endMs: 130000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Second failure, connecting back to the tools lesson: '
              'tool-selection confusion. A model chooses which tool to call '
              'based purely on name and description. Similarly named, '
              'overlapping tools give it a coin flip on every call. A '
              'generalist agent juggling forty tools across finance, '
              'writing, code execution and search accumulates that problem — '
              'not because the model got worse, but because the toolset it '
              'chooses from on every turn got bigger and noisier.',
          startMs: 130000,
          endMs: 196000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Separation of concerns is the fix, imported directly from '
              'software design: a specialist agent with a narrow tool subset '
              'and a prompt that says exactly one thing keeps its context '
              'clean by construction. But say it plainly — this is a cost, '
              'not a default. Every agent you add multiplies model calls, '
              'tokens spent, and places a failure can hide. Reach for it '
              'because a task genuinely spans separable concerns, not '
              'because a framework makes spinning up agents easy.',
          startMs: 196000,
          endMs: 256000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'So, the orchestrator pattern. One controller agent — just '
              'running the ordinary loop — treats other agents as its tools. '
              'Given a task, it decomposes, dispatches subtasks to specialist '
              'workers, and synthesizes the results. The interesting design '
              'decision is routing: usually a cheap router LLM call or '
              'structured classification run before any expensive specialist '
              'work happens.',
          startMs: 256000,
          endMs: 322000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'What happens on the way back up matters as much as routing. '
              'The orchestrator\'s synthesis call reasons over a worker\'s '
              'output rather than just relaying it — that\'s where an '
              'obviously wrong answer can get caught. It\'s also exactly '
              'where a subtle mistake most often slips through, since the '
              'orchestrator has no independent way to verify a worker\'s '
              'claim beyond noticing it looks plausible.',
          startMs: 322000,
          endMs: 380000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Nothing stops a worker from being an orchestrator — a manager '
              'of managers. Anthropic\'s lead agent spawns three to five '
              'subagents in parallel, each running its own internal loop. '
              'It\'s warranted when a subtask is genuinely big enough to '
              'deserve its own team, not just because a task has many steps. '
              'Tightly coupled work like coding, where everyone needs the '
              'same live state, does poorly under this architecture.',
          startMs: 380000,
          endMs: 446000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'And it costs accordingly, for three reasons. Every layer '
              'adds a full round trip before work starts. Every layer '
              'compresses — the top sees only summaries, so information '
              'degrades like a message passed down a chain. And every layer '
              'multiplies token cost. Anthropic measured roughly fifteen '
              'times for their two-level system — a compounding multiplier, '
              'not additive.',
          startMs: 446000,
          endMs: 512000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Different axis of composition entirely: debate. Instead of '
              'splitting by subject matter, split by perspective — several '
              'agent instances independently answer the same question, then '
              'each sees others\' answers and critiques. A 2023 paper found '
              'this measurably improves mathematical reasoning and reduces '
              'factual errors compared to one model answering once. Like '
              'having an optimist and skeptic debate before settling.',
          startMs: 512000,
          endMs: 572000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'The mechanism is intuitive: a wrong first-pass answer often '
              'survives simply because nothing forces the model to re-examine '
              'its reasoning. A second agent\'s independently derived, '
              'differing answer forces a contradiction to be explained — '
              'like a colleague pointing out you missed something. But the '
              'cost is real: roughly agents times rounds in extra tokens. '
              'And if the debaters are all the same model, they share blind '
              'spots — confident agreement can just mean nobody caught the '
              'shared mistake.',
          startMs: 572000,
          endMs: 632000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Underneath every pattern: how agents actually communicate. '
              'Three answers. A shared blackboard — mutable state — loses '
              'context silently when writes overwrite or go unseen. Direct '
              'message passing keeps context clean but costs a round trip '
              'per hop. A shared transcript keeps everyone synced with no '
              'explicit plumbing, but grows without bound — every agent '
              'rereads everything every turn, exactly the "agents distracting '
              'each other" failure Anthropic reported.',
          startMs: 632000,
          endMs: 698000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Which lands on the three failure modes distinctive to '
              'multi-agent systems. Cascading errors: a subagent hallucinates '
              'a detail, hands it up as verified, the orchestrator treats it '
              'as ground truth, and by the time the output is wrong, no '
              'single agent\'s transcript looks broken. Infinite delegation '
              'loops: a task ping-pongs between agents, consuming the whole '
              'step budget. And cost blowup, compounding with both.',
          startMs: 698000,
          endMs: 770000,
        ),
        PodcastSegment(
          id: 'd13',
          speaker: 'Host',
          text:
              'Three mitigations map directly onto those three failures. '
              'Turn limits extend the max_steps guardrail to a system-wide '
              'handoff budget. A supervisor with veto power validates '
              'worker output before accepting it. And structured handoff '
              'schemas — typed, validated objects instead of free text — '
              'make cascading errors traceable after the fact. Same lesson '
              'as autonomy: more agents buy more capability AND more cost, '
              'and the scaffolding that keeps it trustworthy is part of the '
              'price, not an optional add-on.',
          startMs: 770000,
          endMs: 840000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Multi-agent systems compose the loop you already know',
      body:
          'A multi-agent system is not a new primitive — it is the '
          'observe-plan-act loop and tool-calling mechanics from earlier '
          'lessons, run by more than one agent and wired together. Reach '
          'for it when a task genuinely spans separable concerns that '
          'overload a single context, not by default, since every extra '
          'agent multiplies latency, tokens, and the surface area for '
          'something to go wrong.',
    ),
    SummaryCard(
      title: 'Orchestration ranges from flat to hierarchical',
      body:
          'A single orchestrator decomposes a task, routes each piece to a '
          'narrow specialist, and synthesizes the results. Stacking '
          'orchestrators into a hierarchy handles genuinely large, '
          'separable sub-domains, but every added layer costs a full round '
          'trip, loses detail at each hop, and multiplies token spend — '
          'Anthropic measured roughly fifteen times the tokens of a single '
          'chat for just a two-level system.',
    ),
    SummaryCard(
      title:
          'Debate helps reasoning, but agreement between clones is not '
          'evidence',
      body:
          'Multiple agents proposing and critiquing each other\'s answers '
          'can catch reasoning errors a single pass misses, especially on '
          'math and factual tasks. But debate multiplies token and latency '
          'cost by roughly agents times rounds, and if the debaters are all '
          'calls to the same underlying model, they can share the exact '
          'same blind spot — confident agreement then means nothing more '
          'than a shared mistake going unchallenged.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Orchestrator (supervisor) pattern',
      definition:
          'A controller agent that decomposes a task, routes subtasks to '
          'specialist worker agents with narrow tool access and focused '
          'prompts, and synthesizes their results into a final answer '
          'rather than relaying them unedited.',
    ),
    KeyConcept(
      term: 'Router',
      definition:
          'The component — typically a cheap classification call or an '
          'explicit structured-output schema — that decides which '
          'specialist a subtask goes to. Routing accuracy bounds the whole '
          'system\'s accuracy, since a task sent to the wrong specialist '
          'rarely recovers.',
    ),
    KeyConcept(
      term: 'Hierarchical multi-agent system',
      definition:
          'Multiple layers of orchestration, where orchestrators themselves '
          'act as workers under a higher-level orchestrator. Warranted when '
          'a subtask is itself large enough to need its own decomposition, '
          'at the cost of coordination overhead that compounds with depth.',
    ),
    KeyConcept(
      term: 'Multi-agent debate',
      definition:
          'Multiple agent instances or personas independently proposing and '
          'critiquing answers to the same question over several rounds '
          'before a final answer is selected, trading multiplied token and '
          'latency cost for improved accuracy on reasoning-heavy tasks.',
    ),
    KeyConcept(
      term: 'Blackboard / message passing / shared transcript',
      definition:
          'The three practical patterns for agents to exchange information: '
          'shared mutable state any agent can read or write, an explicit '
          'task-and-result handoff between two agents, or one growing '
          'conversation every agent reads in full — each with a distinct '
          'failure mode of lost context, per-hop overhead, or unbounded '
          'growth.',
    ),
    KeyConcept(
      term: 'Cascading error',
      definition:
          'A mistake made by one agent that a downstream agent accepts as '
          'ground truth and builds on, compounding through the system until '
          'the final output is wrong in a way no single agent\'s own '
          'transcript looks obviously broken.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Reaching for a multi-agent system as the default architecture '
          'for any complex task.',
      correction:
          'Multi-agent systems multiply latency, token cost, and failure '
          'surface. Use one well-scoped agent, or a single tool-augmented '
          'call, until a task genuinely spans separable concerns that one '
          'focused prompt and tool set cannot hold at once.',
    ),
    Mistake(
      mistake:
          'Treating a subagent\'s output as verified ground truth just '
          'because it came back successfully.',
      correction:
          'A subagent can hallucinate or misread its own tool results '
          'exactly like a single agent can, and the orchestrator has no '
          'independent way to check unless it validates or spot-checks '
          'results before passing them downstream. Treat every handoff as '
          'an unverified claim, not a fact.',
    ),
    Mistake(
      mistake:
          'Assuming that multiple agents proposing the same answer '
          'confirms the answer is correct.',
      correction:
          'Agreement is only meaningful if the agents could plausibly have '
          'failed differently. Multiple calls to the same underlying model '
          'share its training data and blind spots, so confident consensus '
          'can just mean a shared mistake went unchallenged by everyone at '
          'the table.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'When would you reach for a multi-agent system instead of a '
          'single agent with a broad toolset, and what would make you '
          'decide against it?',
      answer:
          'I would reach for multi-agent when a task genuinely spans '
          'separable concerns that overload a single context — a task '
          'whose system prompt would otherwise have to carry conflicting '
          'instructions for several distinct jobs at once, or whose tool '
          'set has grown large and heterogeneous enough that the model '
          'starts confusing similarly named tools. Splitting into narrow '
          'specialist agents, each with a focused prompt and a small tool '
          'subset, keeps every individual context clean and measurably '
          'reduces both kinds of failure. I would decide against it when '
          'the steps are tightly coupled — when every part of the task '
          'needs to see the same, constantly changing shared state, the '
          'way collaborators editing one source file do — because '
          'splitting that kind of work across isolated agent contexts '
          'breaks the coupling it depends on; Anthropic explicitly reports '
          'their own multi-agent architecture performing worse than a '
          'single agent on tasks like that. I would also weigh the flat '
          'cost: every additional agent multiplies token spend and '
          'latency, roughly fifteen times a single chat for even a modest '
          'two-level system, so the decomposition has to be worth that '
          'multiplier and not just architecturally convenient.',
    ),
    InterviewQuestion(
      question:
          'Walk me through how you would design the routing logic for an '
          'orchestrator handling customer support tickets across billing, '
          'technical, and refunds.',
      answer:
          'I would put a cheap classification call in front of the '
          'expensive specialist reasoning — a single, fast model '
          'invocation, or an explicit structured-output schema, whose only '
          'job is picking a category from a fixed, known set, deliberately '
          'kept cheaper than any specialist\'s own work. I would validate '
          'the router\'s output against the known category list rather than '
          'trusting free text, since an unvalidated category is exactly the '
          'kind of malformed state that turns into a downstream error. For '
          'queries that plausibly span two categories — a billing dispute '
          'tangled up with a login bug — I would either build in an '
          'explicit multi-category path that dispatches to more than one '
          'specialist, or default to escalating ambiguous cases rather than '
          'guessing, since a wrong single-category route rarely recovers on '
          'its own. I would treat the router itself as a small classifier '
          'to be tested and iterated on independently — logging what it '
          'actually routes real queries to, checking that against what a '
          'human would have chosen, and tightening its prompt or schema the '
          'way I would tune any classifier, because routing accuracy is the '
          'ceiling on the whole system\'s accuracy regardless of how good '
          'the specialists downstream are.',
    ),
    InterviewQuestion(
      question:
          'A production multi-agent pipeline you built starts producing '
          'subtly wrong final answers, and no individual agent\'s '
          'transcript looks obviously broken. How would you debug this, '
          'and what would you change to prevent it?',
      answer:
          'This is the signature of a cascading error, so I would start by '
          'reconstructing the handoff chain rather than inspecting any one '
          'agent in isolation — if handoffs are structured and validated, '
          'that trail already exists and I can walk it looking for the '
          'point where a claim was accepted without ever being checked. I '
          'would look specifically for a subagent output that the '
          'orchestrator treated as ground truth and built on, since that is '
          'exactly where a small misread or hallucination first enters and '
          'starts compounding. To prevent recurrence, I would add a '
          'supervisor veto step at exactly that boundary — some structural '
          'check or spot-verification before a worker\'s claim is accepted '
          'and passed downstream, rather than trusting every successful '
          'return by default. I would also tighten the handoff schema '
          'itself, since free-text handoffs make this kind of postmortem '
          'far harder than structured, typed ones do, and for the highest-'
          'stakes junctures I would consider adding a debate or critique '
          'step, where a second independent pass has to agree with the '
          'first before the claim propagates further. Finally I would add a '
          'circuit breaker — a bound on how many additional hops a claim '
          'can travel through before something checks it — so the next '
          'cascading error is caught within a couple of hops instead of '
          'reaching the final output undetected.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title:
        'How we built our multi-agent research system — Anthropic '
        'Engineering',
    url:
        'https://www.anthropic.com/engineering/built-multi-agent-research-system',
    description:
        'Anthropic\'s own lead-agent/subagent architecture, its roughly '
        '15x token-cost figure, and the failure modes — excessive subagent '
        'spawning, agents distracting each other — behind this lesson\'s '
        'orchestrator and hierarchical-overhead sections.',
  ),
  Source(
    title:
        'Improving Factuality and Reasoning in Language Models through '
        'Multiagent Debate (Du et al., 2023)',
    url: 'https://arxiv.org/abs/2305.14325',
    description:
        'The paper behind this lesson\'s debate-and-critique section — '
        'multiple language model instances proposing and critiquing each '
        'other\'s answers over several rounds to improve mathematical '
        'reasoning and reduce hallucination.',
  ),
  Source(
    title: 'langgraph-supervisor — LangGraph Supervisor Multi-Agent Library',
    url: 'https://github.com/langchain-ai/langgraph-supervisor-py',
    description:
        'Reference implementation of the supervisor/orchestrator pattern '
        'and supervisor-of-supervisors hierarchies, used as the concrete '
        'framework example in this lesson\'s orchestrator and hierarchical '
        'sections.',
  ),
];
