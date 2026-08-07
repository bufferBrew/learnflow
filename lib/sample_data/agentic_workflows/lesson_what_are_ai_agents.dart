import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 1: what actually makes something an "agent" rather than a
/// chatbot or a fixed prompt chain, and the loop underneath every agent.
const Lesson whatAreAiAgentsLesson = Lesson(
  id: 'agentic-what-are-ai-agents',
  title: 'What are AI Agents',
  description:
      'The agent loop, the ReAct pattern, the autonomy spectrum, and why more '
      'autonomous steps mean more chances to fail.',
  estimatedMinutes: 34,
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
      id: 'what-is-an-agent',
      heading: 'An agent is a loop, not a single call',
      blocks: [
        ProseBlock(
          'Ask a chatbot a question and you get one response: a single '
          'forward pass from prompt to text. Ask it something that needs '
          'three steps — check a calendar, cross-reference a document, draft '
          'a reply — and a plain chatbot cannot do it, because it has no way '
          'to act on the world between the question and the answer. It can '
          'only talk about what it would do.',
        ),
        ProseBlock(
          'An agent closes that gap. Anthropic\'s own working definition is '
          'deliberately plain: an agent is "an LLM autonomously using tools '
          'in a loop." The model does not just produce a final answer — it '
          'produces a decision about what to do next, that decision gets '
          'executed against the real world (a search, a database query, a '
          'file write), the result comes back as new input, and the model '
          'decides again. The loop continues until the model decides the '
          'task is done, or some outer limit stops it.',
        ),
        ProseBlock(
          'That is the whole definition, and it is worth resisting the urge '
          'to make it fancier. There is no separate "agent module" bolted '
          'onto a language model. It is the same next-token model you would '
          'use for a chatbot, wired into a loop where its outputs can trigger '
          'real actions and where the consequences of those actions are fed '
          'back in as text it reads before its next decision.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Agent vs. chatbot vs. workflow',
          text:
              'A chatbot maps one prompt to one response with no ability to '
              'act in between. A workflow (covered in depth two lessons from '
              'now) calls an LLM at points fixed in advance by the '
              'application\'s code — the path is predetermined even if a step '
              'along it is dynamic. An agent is the one where the model '
              'itself decides, turn by turn, what happens next: which tool to '
              'call, whether to call one at all, and when it is finished.',
        ),
      ],
    ),
    Section(
      id: 'react-pattern',
      heading: 'ReAct: interleaving reasoning and acting',
      blocks: [
        ProseBlock(
          'Before agents were common in production, a 2022 paper called '
          'ReAct asked a simple question: what if you let a language model '
          'write out its reasoning and its actions in the same stream, '
          'alternating between them, rather than asking it to jump straight '
          'to an action or straight to a final answer? "ReAct" is short for '
          'Reasoning and Acting, and the pattern it names — think, act, '
          'observe, repeat — is close to how every practical agent still '
          'works today.',
        ),
        ProseBlock(
          'Each cycle has three parts. A **thought**: a short piece of text '
          'where the model reasons about what it knows and what it still '
          'needs, in plain language, before committing to anything. An '
          '**action**: a specific, structured call to a tool — search this, '
          'read that file, run this calculation — chosen because of the '
          'thought that preceded it. And an **observation**: whatever the '
          'tool actually returned, appended to the model\'s context so the '
          'next thought is grounded in a real result rather than a guess.',
        ),
        CodeBlock(
          language: 'text',
          code: '''
Task: "What was the revenue growth rate of the company that acquired
the maker of the ChatGPT-style product X last year?"

Thought: I don't know who acquired the maker of X. I should search for
that first before I can look up any financials.
Action: search("who acquired the maker of X")
Observation: "Acme Corp acquired Widgets Inc in March last year."

Thought: Now I need Acme Corp's revenue growth rate. I should search
for their financial reports.
Action: search("Acme Corp revenue growth rate last year")
Observation: "Acme Corp reported 18% year-over-year revenue growth."

Thought: I now have enough information to answer directly.
Action: finish("Acme Corp acquired Widgets Inc and grew revenue 18%
year-over-year.")
''',
          caption:
              'Notice the second search only became possible because of what '
              'the first observation revealed — the plan was built one step '
              'at a time, not decided upfront.',
        ),
        ProseBlock(
          'The reason interleaving matters, rather than asking for reasoning '
          'and then a list of actions upfront, is that the second thought '
          'depends on the first observation. A plan committed to in advance, '
          'before any tool has actually run, is a guess about what the world '
          'will look like. ReAct lets the model revise its plan after every '
          'single fact it gathers, which is what makes it robust to '
          'surprises — a search that returns nothing, an unexpected error, a '
          'fact that contradicts the model\'s assumption.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'The thought step is not decoration',
          text:
              'It is tempting to see the "thought" text as filler the model '
              'produces on the way to the real work. In practice, forcing '
              'the model to articulate its reasoning before acting measurably '
              'improves the quality of the action that follows — it gives the '
              'model a scratchpad to catch its own confusion before '
              'committing to a tool call, rather than after.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: ReAct vs Plan-and-Execute vs Code-Acting agents',
          children: [
            ProseBlock(
              'Three families of agent architecture have emerged beyond basic '
              'ReAct. Plan-and-Execute (sometimes called Plan-and-Solve) '
              'separates planning and execution into two phases: first, the '
              'model drafts a complete plan (step 1 do X, step 2 do Y...), '
              'then a separate executor carries out each step, revisiting the '
              'plan only if a step fails. This works well when tasks are '
              'predictable but is brittle to surprises that the plan could '
              'not anticipate — exactly the failure mode ReAct avoids by '
              'interleaving.',
            ),
            ProseBlock(
              'Code-Acting agents (used by SWE-Agent, Open Interpreter, and '
              'Claude\'s computer use) go further: instead of producing '
              'thought-action pairs in natural language, the agent writes and '
              'executes code (Python, bash) as its action. The observation is '
              'the code\'s stdout/stderr/return value. This gives the agent '
              'deterministic tools (code execution is precise) while still '
              'letting it adapt via conditional logic — a hybrid between the '
              'strictness of tool calling and the flexibility of natural '
              'language reasoning. The tradeoff: code is harder to audit '
              'than prose for non-technical users, and a coding error can '
              'have real side effects if execution is not sandboxed.',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'agent-loop',
      heading: 'The loop in full: observe, plan, act, repeat',
      blocks: [
        ProseBlock(
          'Strip away the specific ReAct wording and what is left is the '
          'general shape every agent runs, regardless of framework: observe '
          'the current state (the task, plus whatever has happened so far), '
          'think or plan the next step, act by calling a tool, observe the '
          'result of that action, and repeat. The loop ends when the model '
          'itself signals it is done, or when some external limit — a '
          'maximum number of steps, a time budget, a cost cap — cuts it off.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def run_agent(task, tools, model, max_steps=15):
    """A minimal skeleton of the observe-plan-act-repeat loop."""
    history = [{"role": "user", "content": task}]

    for step in range(max_steps):
        response = model.generate(history, tools=tools)

        if response.is_final_answer:
            return response.text                 # model decided it's done

        # response.action names a tool and its arguments
        result = tools[response.action.tool_name](**response.action.args)
        history.append({"role": "assistant", "content": response.raw})
        history.append({"role": "tool_result", "content": str(result)})

    return "Stopped: exceeded max_steps without a final answer."
''',
          caption:
              'Every framework — LangGraph, a hand-rolled loop, whatever — is '
              'a variation on this shape. The interesting engineering '
              'happens in what fills history and how max_steps is chosen.',
        ),
        ProseBlock(
          'The max_steps guard is not a minor detail. Without it, an agent '
          'that gets stuck in a confused loop — retrying the same failing '
          'search, misreading its own tool output — will burn tokens '
          'indefinitely. Every serious agent framework builds in some hard '
          'stop: a step count, a wall-clock timeout, or a token budget, so a '
          'confused agent fails loudly and cheaply instead of running '
          'forever.',
        ),
      ],
    ),
    Section(
      id: 'autonomy-spectrum',
      heading: 'The autonomy spectrum',
      blocks: [
        ProseBlock(
          '"Agent" is not a binary label — systems sit on a spectrum of how '
          'much control they hand to the model. At one end is a single '
          'tool-augmented call: the model gets one shot to call a tool or '
          'not, and the application handles everything else. One step up is '
          'a bounded loop: the model can call tools repeatedly, but the task '
          'is narrow and the number of plausible steps is small. At the far '
          'end is a fully autonomous agent that plans, delegates, and revises '
          'its own strategy across many steps with minimal human input '
          'between the start of the task and its completion.',
        ),
        ProseBlock(
          'Where a system should sit on that spectrum is a design decision, '
          'not a default to maximize. More autonomy means the system can '
          'handle open-ended tasks without a human specifying every step, but '
          'it also means more opportunities for the model to wander off '
          'course before anyone notices. Anthropic\'s own guidance is '
          'consistent on this point: find the simplest system that works, '
          'and add autonomy only when the task genuinely needs it, not '
          'because an agent framework happens to be available.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Autonomy is a cost, not just a capability',
          text:
              'A single well-scoped tool call is fast, cheap, and easy to '
              'verify. A fully autonomous multi-step agent is slower, more '
              'expensive per task, and considerably harder to debug when it '
              'goes wrong, because the failure could be in any of the steps '
              'it chose for itself. Reach for more autonomy only when a fixed '
              'sequence of steps genuinely cannot be specified in advance.',
        ),
      ],
    ),
    Section(
      id: 'why-agents-fail',
      heading: 'Why agents fail in practice',
      blocks: [
        ProseBlock(
          'The single biggest practical risk with autonomous agents is '
          'compounding error. If a model is right 95% of the time on any '
          'individual step, that sounds excellent — but a task that takes '
          'ten autonomous steps in a row succeeds end to end only about 60% '
          'of the time at that per-step accuracy, because the errors '
          'multiply rather than average. A single wrong tool call, a '
          'misread observation, or a subtly wrong assumption early in the '
          'loop can steer every subsequent step further from a correct '
          'answer, and the agent has no built-in mechanism to notice it has '
          'gone astray.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Illustrative only: naive per-step accuracy compounding across a chain
# of independent decisions.
per_step_accuracy = 0.95

for n_steps in (1, 5, 10, 20):
    task_success = per_step_accuracy ** n_steps
    print(f"{n_steps:>2} steps -> {task_success:.1%} expected success")

#  1 steps -> 95.0% expected success
#  5 steps -> 77.4% expected success
# 10 steps -> 59.9% expected success
# 20 steps -> 35.8% expected success
''',
          caption:
              'A rough model, not a guarantee — real steps are not '
              'independent and models often catch their own mistakes — but '
              'it explains why long autonomous chains need more than raw '
              'per-step accuracy to be reliable.',
        ),
        ProseBlock(
          'The practical answer is not to abandon autonomy, but to bound it. '
          'Guardrails — validating a tool\'s output before trusting it, '
          'capping how many steps an agent can take, restricting which tools '
          'it can call for a given task — reduce the blast radius of any one '
          'mistake. Human checkpoints — asking for confirmation before an '
          'irreversible action, surfacing a plan for approval before '
          'execution begins, sampling completed runs for review — catch '
          'errors that a fully hands-off loop would otherwise compound.',
        ),
        ProseBlock(
          'The two ideas connect directly to the autonomy spectrum above: '
          'the further a system sits toward full autonomy, the more of these '
          'guardrails and checkpoints it needs to stay trustworthy, and the '
          'more that operational cost should factor into the decision to '
          'build an agent at all rather than a narrower, more predictable '
          'system.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-agent-loop',
      title: 'Implement a bounded observe-plan-act loop',
      prompt: [
        ProseBlock(
          'Build a tiny agent loop over a fake "search" tool that looks up '
          'answers in a hardcoded dictionary. The loop should let the model '
          'stub call search() as many times as it needs, feed each result '
          'back in, and stop either when a fake "model" decides it has the '
          'answer or when max_steps is reached.',
        ),
        ProseBlock(
          'The point of the exercise is the control flow, not the model — a '
          'plain function stands in for what a real LLM call would decide.',
        ),
      ],
      starterCode: '''
facts = {
    "capital of france": "Paris",
    "population of paris": "about 2.1 million",
}


def fake_search(query):
    return facts.get(query.lower(), "no result found")


def fake_model_step(history):
    """Stub: decide the next action from the conversation so far.

    Return either ("search", query) or ("finish", answer_text).
    """
    ...


def run_agent(task, max_steps=5):
    """Observe-plan-act loop. Return the final answer or a stop message."""
    ...


print(run_agent("What is the population of the capital of France?"))
''',
      solutionCode: '''
facts = {
    "capital of france": "Paris",
    "population of paris": "about 2.1 million",
}


def fake_search(query):
    return facts.get(query.lower(), "no result found")


def fake_model_step(history):
    """Stub: decide the next action from the conversation so far.

    Return either ("search", query) or ("finish", answer_text).
    """
    # A real model would reason over the whole history. This stub follows
    # a fixed two-hop script so the loop's behaviour is easy to trace.
    observations = [h["content"] for h in history if h["role"] == "observation"]

    if not observations:
        return ("search", "capital of france")
    if len(observations) == 1:
        return ("search", f"population of {observations[0].lower()}")
    return ("finish", f"The population is {observations[-1]}.")


def run_agent(task, max_steps=5):
    """Observe-plan-act loop. Return the final answer or a stop message."""
    history = [{"role": "user", "content": task}]

    for step in range(max_steps):
        action, payload = fake_model_step(history)

        if action == "finish":
            return payload

        result = fake_search(payload)
        history.append({"role": "assistant", "content": f"search({payload!r})"})
        history.append({"role": "observation", "content": result})
        print(f"step {step}: searched {payload!r} -> {result!r}")

    return "Stopped: exceeded max_steps without a final answer."


print(run_agent("What is the population of the capital of France?"))
# step 0: searched 'capital of france' -> 'Paris'
# step 1: searched 'population of paris' -> 'about 2.1 million'
# The population is about 2.1 million.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why does the loop append both the assistant\'s action and the '
              'tool\'s observation to history, rather than just the '
              'observation?',
          expectedAnswer:
              'Because the next decision needs to see not just what came '
              'back, but what was asked to get it — otherwise the model has '
              'no way to tell which result answers which sub-question when '
              'several searches have run. Keeping both also means the full '
              'transcript is self-describing: anyone debugging a failed run '
              'can read exactly what the agent tried and what it learned at '
              'each step, in order.',
        ),
        SelfCheckQuestion(
          question:
              'What would happen to this loop if fake_search silently '
              'returned the wrong answer for one query, and how does that '
              'relate to the compounding-error discussion in the lesson?',
          expectedAnswer:
              'The wrong observation gets appended to history exactly like a '
              'correct one — the loop has no mechanism to notice a fact is '
              'wrong, only to notice a fact is missing. Every subsequent '
              'decision is then built on that bad premise, which is precisely '
              'the compounding-error problem: a single bad step early in a '
              'chain propagates forward because the agent has no independent '
              'way to verify the observations it is trusting.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-max-steps-guardrail',
      title: 'Add a stuck-loop guardrail',
      prompt: [
        ProseBlock(
          'Extend the loop so it detects when the model repeats the exact '
          'same search query twice in a row — a classic symptom of an agent '
          'stuck in a confused loop — and stops early with a clear message '
          'instead of burning through the rest of max_steps.',
        ),
        ProseBlock(
          'This is a small guardrail, but it is the same idea as the '
          'lesson\'s discussion of bounding autonomy: cheap checks that catch '
          'a failure mode early are worth more than a bigger step budget.',
        ),
      ],
      starterCode: '''
facts = {"capital of france": "Paris"}


def fake_search(query):
    return facts.get(query.lower(), "no result found")


def confused_model_step(history, query="capital of germany"):
    """Always searches the same (wrong / unanswerable) query."""
    return ("search", query)


def run_agent(task, model_step, max_steps=5):
    """Observe-plan-act loop with a repeated-query guardrail."""
    history = [{"role": "user", "content": task}]
    last_query = None

    for step in range(max_steps):
        action, payload = model_step(history)
        ...  # TODO: detect a repeated query and stop early

        result = fake_search(payload)
        history.append({"role": "observation", "content": result})
        last_query = payload

    return "Stopped: exceeded max_steps without a final answer."


print(run_agent("Look something up", confused_model_step))
''',
      solutionCode: '''
facts = {"capital of france": "Paris"}


def fake_search(query):
    return facts.get(query.lower(), "no result found")


def confused_model_step(history, query="capital of germany"):
    """Always searches the same (wrong / unanswerable) query."""
    return ("search", query)


def run_agent(task, model_step, max_steps=5):
    """Observe-plan-act loop with a repeated-query guardrail."""
    history = [{"role": "user", "content": task}]
    last_query = None

    for step in range(max_steps):
        action, payload = model_step(history)

        if action == "search" and payload == last_query:
            return (
                f"Stopped after {step} steps: repeated the same query "
                f"{payload!r} twice in a row, which usually means the "
                f"agent is stuck rather than making progress."
            )

        result = fake_search(payload)
        history.append({"role": "observation", "content": result})
        last_query = payload

    return "Stopped: exceeded max_steps without a final answer."


print(run_agent("Look something up", confused_model_step))
# Stopped after 1 steps: repeated the same query 'capital of germany'
# twice in a row, which usually means the agent is stuck rather than
# making progress.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'This guardrail only catches an exact repeated query. What '
              'kind of stuck loop would it miss, and how might you catch '
              'that instead?',
          expectedAnswer:
              'It would miss a loop that cycles between two or three '
              'slightly different queries without making progress — search '
              'A, search B, search A again with a rephrasing, and so on — '
              'since no single query repeats back to back. A more robust '
              'check would track the full set of queries tried and flag it '
              'when a small set starts repeating, or would ask the model '
              'itself, every few steps, whether it believes it is making '
              'progress toward an answer.',
        ),
        SelfCheckQuestion(
          question:
              'Why stop and return a message rather than just letting '
              'max_steps eventually cut the loop off anyway?',
          expectedAnswer:
              'Because max_steps is a blunt backstop meant for genuinely '
              'long tasks, and waiting for it to fire wastes every remaining '
              'step on the same mistake — extra tool calls, extra tokens, '
              'extra latency, for no additional chance of success. Detecting '
              'the specific failure mode early lets the system fail fast and '
              'cheaply, and the distinct error message also tells whoever is '
              'debugging the run exactly what went wrong, rather than just '
              '"ran out of steps."',
        ),
      ],
    ),
    Exercise(
      id: 'ex-compounding-error',
      title: 'Model compounding error across sequential agent steps',
      prompt: [
        ProseBlock(
          'Implement simulate_agent_runs(per_step_accuracy, n_steps, '
          'n_trials) that simulates n_trials independent agent runs, each '
          'with n_steps sequential decisions where each step succeeds with '
          'probability per_step_accuracy independently. Return the fraction '
          'of runs where all steps succeeded.',
        ),
        ProseBlock(
          'Run it at per_step_accuracy=0.95 for n_steps from 1 to 20 and '
          'compare the empirical results against the theoretical '
          'per_step_accuracy^n_steps. This is the napkin-math version of '
          'the lesson\'s compounding error argument.',
        ),
      ],
      starterCode: '''
import random


def simulate_agent_runs(per_step_accuracy, n_steps, n_trials=10000):
    """Return fraction of trials where all n_steps succeeded."""
    ...


random.seed(42)
for n_steps in (1, 5, 10, 15, 20):
    empirical = simulate_agent_runs(0.95, n_steps)
    theoretical = 0.95 ** n_steps
    print(
        f"steps={n_steps:>2}  empirical={empirical:.3f}  "
        f"theoretical={theoretical:.3f}"
    )
''',
      solutionCode: '''
import random


def simulate_agent_runs(per_step_accuracy, n_steps, n_trials=10000):
    successes = 0
    for _ in range(n_trials):
        if all(random.random() < per_step_accuracy for _ in range(n_steps)):
            successes += 1
    return successes / n_trials


random.seed(42)
for n_steps in (1, 5, 10, 15, 20):
    empirical = simulate_agent_runs(0.95, n_steps)
    theoretical = 0.95 ** n_steps
    print(
        f"steps={n_steps:>2}  empirical={empirical:.3f}  "
        f"theoretical={theoretical:.3f}"
    )

# steps= 1  empirical=0.950  theoretical=0.950
# steps= 5  empirical=0.774  theoretical=0.774
# steps=10  empirical=0.595  theoretical=0.599
# steps=15  empirical=0.463  theoretical=0.463
# steps=20  empirical=0.359  theoretical=0.358
#
# Even at 95% per-step accuracy, a 20-step autonomous chain fails ~64%
# of the time. This is why the lesson argues for shorter bounded loops
# rather than long autonomous chains.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The simulation assumes each step is independent. In a real '
              'agent, if step 3 fails, steps 4-20 do not even get a chance '
              'to succeed because the plan is already broken. Does that make '
              'real agents better or worse than this model, and why?',
          expectedAnswer:
              'Worse — the independence assumption is optimistic. In a real '
              'agent, a failure at step 3 typically cascades: the agent '
              'builds subsequent decisions on wrong information from step '
              '3\'s result, so steps 4-20 are not just independent attempts '
              'but actively steered further from the correct answer. The '
              'simulation\'s 0.95^n is actually a lower bound on failure '
              'rate, not an upper bound. Real agents fail more often than '
              'this model predicts because errors compound directionally, '
              'not just independently.',
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
              'What actually is an AI agent, in under five minutes. Think '
              'about how you\'d delegate a task to a team member. You don\'t '
              'just ask for the final answer — you give them tools, check '
              'their progress, and adjust based on what they find. '
              'Anthropic\'s definition is refreshingly plain: an LLM '
              'autonomously using tools in a loop. Not a special kind of '
              'model — the same model, wired so its decisions can trigger '
              'real actions and read back the results.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Compare this to a chatbot, which is like asking someone a '
              'single question and getting one answer with no follow-up '
              'actions. And compare it to a workflow, which is like a '
              'checklist where the steps are pre-written — the LLM gets '
              'called at fixed points. An agent is the one where the model '
              'itself decides, turn by turn, what to do next — like a '
              'trusted team member figuring out their own approach.',
          startMs: 42000,
          endMs: 84000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'The pattern underneath is called ReAct — reasoning and '
              'acting, interleaved. Think, then act, then observe what '
              'actually came back, then think again. It\'s like navigating '
              'with a map: you don\'t plan the entire route before taking '
              'your first step. You walk a bit, check your surroundings, '
              'adjust, walk again. The interleaving matters because your '
              'second thought genuinely depends on how step one turned out.',
          startMs: 84000,
          endMs: 132000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'That loop keeps running until the model decides it\'s done, '
              'or an outer limit cuts it off — a max number of steps, a '
              'time budget. Without that limit, a confused agent is like a '
              'stuck GPS recalculating the same route forever, burning '
              'tokens indefinitely. The guardrail is essential.',
          startMs: 132000,
          endMs: 174000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Autonomy is a spectrum, not a switch. On one end: a single '
              'tool call, like asking someone to quickly look up one fact. '
              'On the other: a fully autonomous multi-step agent that plans, '
              'delegates, and revises across many steps. More autonomy '
              'handles more open-ended work, but every extra step is another '
              'chance to go wrong — like giving someone more independence '
              'but also more ways to make mistakes.',
          startMs: 174000,
          endMs: 210000,
        ),
        PodcastSegment(
          id: 'c6',
          speaker: 'Guest',
          text:
              'Which is the failure mode to remember: errors compound. '
              'Ninety-five percent accuracy per step sounds great — but '
              'chain ten of those steps together and you only succeed about '
              'sixty percent of the time, because mistakes multiply rather '
              'than average. It\'s like a game of telephone: a small '
              'misunderstanding early on gets amplified at every step. '
              'Guardrails and human checkpoints exist to catch that before '
              'it snowballs.',
          startMs: 210000,
          endMs: 246000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 456000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Let\'s define our terms carefully, because "agent" gets tossed '
              'around loosely. The definition we\'ll use, straight from '
              'Anthropic\'s engineering writing: an LLM autonomously using '
              'tools in a loop. Three parts worth noticing — autonomous, '
              'tools, and loop. Think of it like hiring someone to research '
              'a topic: you don\'t script their every move — you give them '
              'access to resources, a goal, and let them figure out the '
              'steps.',
          startMs: 0,
          endMs: 46000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Start with what it\'s not. A chatbot is one prompt in, one '
              'response out — like asking a stranger for directions. They '
              'give you one answer and can\'t walk with you. No ability to '
              'act on the world between the question and answer, so a '
              'three-step task is simply impossible. The chatbot can '
              'describe what it would do, but it cannot DO it.',
          startMs: 46000,
          endMs: 92000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'A workflow is closer but still not an agent: it calls an LLM '
              'at points the application\'s code decided on in advance, like '
              'a factory assembly line where every station is predetermined. '
              'The path is fixed even if one step along that path is dynamic. '
              'We\'ll come back to that distinction in detail two lessons '
              'from now.',
          startMs: 92000,
          endMs: 138000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'An agent is the one where the model decides, at each turn, '
              'what happens next — which tool to call, whether to call one '
              'at all, when to stop. The mechanism that made this practical '
              'is a 2022 pattern called ReAct: reasoning and acting, '
              'interleaved in the same stream. Like a detective working a '
              'case: they don\'t plan all interviews upfront — they '
              'interview one person, process what they learned, then decide '
              'who to talk to next.',
          startMs: 138000,
          endMs: 188000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Walk through one cycle. A thought — plain-language reasoning '
              'about what\'s known and what\'s still needed. An action — a '
              'structured call to a specific tool, chosen because of that '
              'thought. An observation — what the tool actually returned, '
              'fed back into context before the next thought. It\'s the same '
              'cycle you\'d follow if I asked you to research something on '
              'your own.',
          startMs: 188000,
          endMs: 238000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'The reason to interleave rather than plan everything upfront '
              'is that step two depends on step one\'s real result. A plan '
              'made before any tool has run is a guess about the world — '
              'like planning your entire vacation itinerary before checking '
              'if flights are even available. ReAct lets the model revise '
              'after every fact it actually gathers, which is what makes '
              'it robust to surprises.',
          startMs: 238000,
          endMs: 288000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Zoom out to the general shape, because every framework is a '
              'variation on it: observe the current state, plan the next '
              'step, act by calling a tool, observe the result, repeat. '
              'It\'s the same loop you\'d use yourself: look at what you have, '
              'figure out what\'s missing, go get it, see what you found, '
              'repeat. It ends when the model says it\'s done, or a hard '
              'limit — max steps, timeout, cost cap — cuts it off.',
          startMs: 288000,
          endMs: 334000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And autonomy sits on a spectrum rather than being on or off. '
              'A single tool-augmented call at one end is fast and easy to '
              'verify — like asking someone to check one fact. A fully '
              'autonomous multi-step agent at the other handles open-ended '
              'tasks but is slower, costlier, and much harder to debug — '
              'like trusting someone to run a whole project independently.',
          startMs: 334000,
          endMs: 384000,
        ),
        PodcastSegment(
          id: 's9',
          speaker: 'Host',
          text:
              'Which lands on the real risk: compounding error. Ninety-five '
              'percent per-step accuracy across ten dependent steps lands '
              'around sixty percent end-to-end success, because mistakes '
              'multiply rather than average out. One bad early step steers '
              'everything after it off course — like a tiny navigation error '
              'at the start of a road trip that puts you in the wrong state.',
          startMs: 384000,
          endMs: 424000,
        ),
        PodcastSegment(
          id: 's10',
          speaker: 'Guest',
          text:
              'So the practical takeaway isn\'t "avoid autonomy" — it\'s '
              'bound it. Guardrails that check a tool\'s output before '
              'trusting it, step caps, and human checkpoints before anything '
              'irreversible all shrink the blast radius of any one mistake. '
              'It\'s like giving someone a credit card with a spending limit '
              'instead of unlimited access — they can still get things done, '
              'but a bad decision can only go so far.',
          startMs: 424000,
          endMs: 456000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 830000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Deep dive on what an AI agent actually is. Imagine you\'re '
              'training a new hire. You don\'t write them a 50-step script — '
              'you give them goals, tools, and the authority to figure things '
              'out. That\'s the mental model. The route: the plain definition '
              'and why it\'s deliberately unglamorous, the three-way '
              'distinction between chatbot, workflow and agent, the ReAct '
              'pattern in detail, the general agent loop, the autonomy '
              'spectrum as a design decision, and why more autonomy means '
              'more chances to fail.',
          startMs: 0,
          endMs: 60000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with the definition, because it does real work: an LLM '
              'autonomously using tools in a loop. Not a new architecture, '
              'not a different training objective — the same next-token '
              'model, wired so its output can trigger a real action and read '
              'back what happened, then decide again. The plainness is the '
              'point: it resists treating "agent" as some mystical extra '
              'capability. Everything interesting — the usefulness AND the '
              'failure modes — follows from that one sentence.',
          startMs: 60000,
          endMs: 150000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'So place it against the alternatives. A chatbot: one prompt, '
              'one response, no way to act between them — like asking a '
              'stranger for advice. They tell you something useful but can\'t '
              'DO anything on your behalf. A workflow gets closer: it calls '
              'the LLM at points the application\'s code decided on ahead of '
              'time, like an assembly line where stations are fixed. That\'s '
              'Anthropic\'s framing in "Building Effective Agents," and it '
              'matters for choosing which one to build.',
          startMs: 150000,
          endMs: 240000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'An agent is the one where the model itself decides, on every '
              'turn, what happens next. The mechanism that made this workable '
              'is ReAct — reasoning and acting, interleaved. The 2022 paper '
              'asked: what if a model writes reasoning and actions into the '
              'same stream instead of jumping straight to one or the other? '
              'It\'s like the difference between handing someone a complete '
              'plan versus letting them figure it out step by step.',
          startMs: 240000,
          endMs: 300000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Break down one cycle properly. A thought: plain language, the '
              'model reasoning about what it knows and what\'s missing, '
              'before committing to anything — like thinking "I need to '
              'check the calendar first before I can propose a meeting '
              'time." An action: a specific structured tool call chosen '
              'because of that thought. An observation: the tool\'s actual '
              'return value, appended to context so the next thought is '
              'grounded in reality rather than a guess.',
          startMs: 300000,
          endMs: 364000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'The interleaving is the whole trick. A plan made entirely '
              'upfront is a bet on what the world will look like — like '
              'writing a detailed dinner recipe before you\'ve checked what\'s '
              'in the fridge. Interleaving lets the model revise after every '
              'fact it gathers: an empty search result, an unexpected error, '
              'a contradiction all get incorporated before the next '
              'decision, not after the whole plan has already failed.',
          startMs: 364000,
          endMs: 428000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Zoom out to the general loop — every framework is a variation '
              'of this: observe the current state — the task plus everything '
              'that\'s happened so far — plan the next step, act by calling '
              'a tool, observe the result, repeat. Ends when the model '
              'signals done, or an outer limit — step count, timeout, cost '
              'cap — cuts it off.',
          startMs: 428000,
          endMs: 488000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'That outer limit is not a minor detail. Without it, an agent '
              'that gets confused — retrying an identical failing search, '
              'misreading its own tool output — burns tokens indefinitely, '
              'like a stuck printer spitting out the same page forever. Every '
              'serious agent framework builds in a hard stop so a confused '
              'run fails loudly and cheaply.',
          startMs: 488000,
          endMs: 546000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Now the autonomy spectrum — a genuine design decision, not '
              'a dial you crank to maximum. One end: a single tool-augmented '
              'call, fast, cheap, trivially verifiable — like asking someone '
              'to look up one fact. The far end: a fully autonomous agent '
              'planning, delegating and revising its own strategy across many '
              'steps with almost no human input.',
          startMs: 546000,
          endMs: 602000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'More autonomy buys the ability to handle genuinely open-ended '
              'tasks without specifying every step in advance. It costs you '
              'speed, cost per task, and debuggability — when something goes '
              'wrong, the failure could be hiding in any of the steps the '
              'model chose for itself, not one you wrote down. It\'s the '
              'difference between debugging a script you wrote and debugging '
              'decisions someone else made on the fly.',
          startMs: 602000,
          endMs: 660000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Which brings us to why agents actually fail in the field: '
              'compounding error. Ninety-five percent on any single step '
              'sounds excellent. Chain ten of those steps together and the '
              'naive expected success rate is under sixty percent, because '
              'mistakes multiply rather than average. Think of it like a '
              'recipe: a small mistake in step one — misreading "tablespoon" '
              'as "teaspoon" — ruins the entire dish, and no amount of '
              'perfectly executed later steps can fix it.',
          startMs: 660000,
          endMs: 750000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'So the practical response is bounding, not abandoning, '
              'autonomy: validate a tool\'s output before trusting it, cap '
              'the number of steps, restrict which tools a given task can '
              'even reach, and add human checkpoints before anything '
              'irreversible. The further out on the autonomy spectrum a '
              'system sits, the more of this scaffolding it needs to stay '
              'trustworthy — and that scaffolding is itself part of the '
              'cost of choosing to build an agent at all.',
          startMs: 750000,
          endMs: 830000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'An agent is an LLM using tools in a loop',
      body:
          'The model does not just answer — it decides an action, the action '
          'runs against the real world, the result feeds back as new input, '
          'and the model decides again. This is what separates an agent from '
          'a chatbot (one prompt, one response, no acting in between) and '
          'from a workflow (the LLM is called at points the application\'s '
          'code fixed in advance).',
    ),
    SummaryCard(
      title: 'ReAct interleaves thought, action and observation',
      body:
          'Each cycle is a plain-language thought, a structured tool call '
          'chosen because of that thought, and an observation of what the '
          'tool actually returned. Interleaving rather than planning upfront '
          'matters because each new thought is grounded in a real result, not '
          'a guess about what the world will look like.',
    ),
    SummaryCard(
      title: 'Autonomy is a spectrum, and errors compound along it',
      body:
          'Systems range from a single bounded tool call to a fully '
          'autonomous multi-step agent, and the choice is a real design '
          'tradeoff: more autonomy handles open-ended tasks but multiplies '
          'the chances for something to go wrong, since even a high per-step '
          'accuracy compounds into a much lower end-to-end success rate over '
          'many steps. Guardrails and human checkpoints exist to bound that '
          'risk.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Agent',
      definition:
          'An LLM autonomously using tools in a loop: the model decides an '
          'action, the action executes, the result feeds back as new input, '
          'and the model decides again until it signals it is done or an '
          'outer limit stops it.',
    ),
    KeyConcept(
      term: 'ReAct',
      definition:
          'A pattern — short for Reasoning and Acting — that interleaves a '
          'plain-language thought, a structured tool action, and an '
          'observation of the result in a repeating cycle, so each new '
          'decision is grounded in the previous action\'s real outcome.',
    ),
    KeyConcept(
      term: 'Agent loop',
      definition:
          'The general shape of any agent: observe the current state, plan '
          'the next step, act by calling a tool, observe the result, repeat '
          'until done or until an outer limit such as a max step count cuts '
          'it off.',
    ),
    KeyConcept(
      term: 'Autonomy spectrum',
      definition:
          'The range from a single bounded tool-augmented call to a fully '
          'autonomous multi-step agent. Higher autonomy handles more '
          'open-ended tasks at the cost of speed, expense, and '
          'debuggability.',
    ),
    KeyConcept(
      term: 'Compounding error',
      definition:
          'The way per-step mistakes multiply rather than average across a '
          'chain of autonomous decisions, so a high per-step accuracy can '
          'still yield a much lower end-to-end success rate over many steps.',
    ),
    KeyConcept(
      term: 'Guardrail',
      definition:
          'A bound placed on an agent to limit the damage of a mistake — a '
          'step cap, a restricted tool set, output validation, or a human '
          'checkpoint before an irreversible action.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Treating any LLM call that uses a tool as "an agent."',
      correction:
          'A single tool-augmented call with no loop — the model calls one '
          'tool once and the application handles the rest — sits at the '
          'narrow end of the autonomy spectrum, not the agent end. The '
          'defining feature of an agent is the loop: the model itself '
          'deciding, repeatedly, what to do next based on what just '
          'happened.',
    ),
    Mistake(
      mistake:
          'Assuming a higher per-step accuracy guarantees a reliable '
          'multi-step agent.',
      correction:
          'Per-step accuracy compounds across a chain of decisions, so even '
          '95% accuracy per step can fall well under 60% success over ten '
          'dependent steps. Reliability at the task level requires bounding '
          'the chain — guardrails, checkpoints, verification — not just a '
          'strong model.',
    ),
    Mistake(
      mistake:
          'Reaching for maximum autonomy by default because a framework '
          'makes it easy.',
      correction:
          'More autonomy is a cost as much as a capability: slower, more '
          'expensive, and harder to debug when it fails, because the failure '
          'could be hiding in any self-chosen step. Anthropic\'s own guidance '
          'is to find the simplest system that works and add autonomy only '
          'when the task genuinely requires it.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'How would you distinguish an agent from a workflow to someone '
          'who has only used chatbots?',
      answer:
          'A chatbot is one prompt to one response, with no ability to act '
          'on the world in between — it can describe a plan but not execute '
          'one. A workflow adds real actions, but the sequence of steps and '
          'when the LLM gets consulted are fixed in advance by the '
          'application\'s code; the LLM might make a dynamic decision at one '
          'point, like which category a request falls into, but the overall '
          'path is predetermined. An agent removes that predetermination: '
          'the model itself decides, turn by turn, what tool to call next, '
          'whether to call one at all, and when the task is finished. The '
          'practical test I\'d apply is "does the sequence of steps exist '
          'before the task starts, or does the model construct it as it '
          'goes" — a fixed sequence is a workflow, a model-constructed one '
          'is an agent.',
    ),
    InterviewQuestion(
      question:
          'Why interleave reasoning and acting instead of having the model '
          'produce a full plan upfront and then execute it?',
      answer:
          'Because a plan made before any tool has actually run is a guess '
          'about what the world looks like, and real tasks are full of '
          'surprises the model cannot anticipate — a search that returns '
          'nothing useful, a value that contradicts an assumption baked into '
          'step three of a five-step plan. Interleaving, the ReAct pattern, '
          'lets the model revise its next move immediately after each real '
          'observation instead of discovering the plan was wrong only after '
          'committing to all of it. It also makes debugging tractable: the '
          'thought before each action documents why the model chose it, so a '
          'reviewer can see exactly where reasoning diverged from reality '
          'rather than only seeing a final wrong answer.',
    ),
    InterviewQuestion(
      question:
          'You are asked to automate a task that currently takes a human '
          'about twenty sequential steps. Walk through how you would decide '
          'how much autonomy to give the system.',
      answer:
          'I would start by asking whether the twenty steps are actually '
          'fixed and predictable, in which case a workflow that calls an LLM '
          'only where genuine judgment is needed is safer and cheaper than a '
          'fully autonomous agent — autonomy should be added because a task '
          'needs it, not because it is available. If the steps genuinely '
          'depend on what earlier steps discover, I would still avoid '
          'building one long autonomous chain by default, because twenty '
          'sequential model-driven decisions compound error badly even at a '
          'good per-step accuracy. I would look for ways to break the task '
          'into shorter, independently verifiable chunks, add guardrails at '
          'the boundaries — validate a chunk\'s output before feeding it into '
          'the next stage — and insert a human checkpoint before any '
          'irreversible action. Only after establishing that scaffolding '
          'would I let the system run with real autonomy inside each bounded '
          'chunk, and I would instrument it so a human can audit exactly '
          'which step went wrong when the end-to-end result is off, rather '
          'than being left with an opaque twenty-step transcript.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'ReAct: Synergizing Reasoning and Acting in Language Models '
        '(Yao et al., 2022)',
    url: 'https://arxiv.org/abs/2210.03629',
    description:
        'The paper that named and formalized the think-act-observe cycle '
        'reproduced in this lesson\'s toy trace and the practice exercises.',
  ),
  Source(
    title: 'Building Effective Agents — Anthropic Engineering',
    url: 'https://www.anthropic.com/engineering/building-effective-agents',
    description:
        'Anthropic\'s own workflow-vs-agent distinction, the source of this '
        'lesson\'s framing for when the model itself controls the process '
        'versus when application code does.',
  ),
  Source(
    title: 'Effective context engineering for AI agents — Anthropic '
        'Engineering',
    url:
        'https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents',
    description:
        'Source of the plain "LLMs autonomously using tools in a loop" '
        'definition of an agent used at the top of this lesson.',
  ),
  Source(
    title: 'Tool use with Claude — Claude Platform Docs',
    url: 'https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview',
    description:
        'Shows the concrete request/response round trip behind the abstract '
        'act-and-observe step in the agent loop, ahead of the next lesson\'s '
        'deep dive on tool calling.',
  ),
];

const List<Source> _furtherReading = <Source>[
  Source(
    title: 'SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering (Yang et al., 2024)',
    url: 'https://arxiv.org/abs/2405.15793',
    description:
        'Production agent design patterns from the SWE-bench winning system, '
        'including the agent-computer interface (ACI) concept that constrains agent actions.',
  ),
  Source(
    title: 'The Dawn of Agentic Software Engineering — Lilian Weng\'s Blog',
    url: 'https://lilianweng.github.io/posts/2024-10-24-agents/',
    description:
        'Comprehensive overview of LLM agent architectures: planning, memory, tool use, '
        'and the autonomy spectrum with practical design recommendations.',
  ),
  Source(
    title: 'Generative Agents: Interactive Simulacra of Human Behavior (Park et al., 2023)',
    url: 'https://arxiv.org/abs/2304.03442',
    description:
        'Foundational paper on agent architectures with memory streams, reflection, and planning — '
        'the architecture behind multi-step agent behaviour that goes beyond single loops.',
  ),
  Source(
    title: 'Anthropic\'s Research on AI Agent Safety and Evaluation',
    url: 'https://www.anthropic.com/research#agent-safety',
    description:
        'Collection of Anthropic research on evaluating agent capabilities, '
        'safety guardrails, and the failure modes observed in production agent systems.',
  ),
];
