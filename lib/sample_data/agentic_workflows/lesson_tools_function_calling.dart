import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 2: how a model actually reaches out into the world —
/// structured tool calls, good tool design, error handling, and MCP.
const Lesson toolsFunctionCallingLesson = Lesson(
  id: 'agentic-tools-function-calling',
  title: 'Tools & Function Calling',
  description:
      'The mechanics of tool calling, writing tool descriptions that '
      'actually get used correctly, error handling, and the Model Context '
      'Protocol.',
  estimatedMinutes: 28,
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
      id: 'mechanics',
      heading: 'What a tool call actually is',
      blocks: [
        ProseBlock(
          'A language model cannot execute code. It can only produce text — '
          'or, more precisely, tokens. Tool calling is the convention that '
          'turns that limitation into a feature: instead of asking the model '
          'to describe an action in prose and hoping your application can '
          'parse the description, you give the model a catalogue of '
          'available actions up front, described as structured schemas, and '
          'the model emits a structured request to invoke one of them.',
        ),
        ProseBlock(
          'The schema is ordinary JSON Schema: a tool has a name, a '
          'human-readable description, and an input schema describing its '
          'arguments — their names, their types, which are required. When '
          'the model decides a tool is the right next move, it does not '
          'write "I will now search the web for X" as prose. It emits a '
          'block that names the tool and supplies arguments matching the '
          'schema, and your application code is the thing that actually runs '
          'the search, reads the file, or hits the API.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# A tool definition is data: name, description, and a JSON Schema for
# the arguments. Nothing here executes anything.
get_weather_tool = {
    "name": "get_weather",
    "description": "Get the current weather for a given location.",
    "input_schema": {
        "type": "object",
        "properties": {
            "location": {
                "type": "string",
                "description": "City and state, e.g. 'San Francisco, CA'",
            },
        },
        "required": ["location"],
    },
}

# The model's response contains a tool_use block shaped like this. Your
# application reads .name and .input, not a sentence it has to parse.
# {
#     "type": "tool_use",
#     "id": "toolu_01A...",
#     "name": "get_weather",
#     "input": {"location": "San Francisco, CA"}
# }
''',
          caption:
              'The tool definition and the tool call are both data, not '
              'prose — which is exactly what makes them reliable to parse '
              'and route in application code.',
        ),
        ProseBlock(
          'The round trip has a fixed shape regardless of which model '
          'provider you use. Send the model a message plus the list of '
          'available tools. The model replies with either ordinary text (it '
          'decided a tool was not needed) or a structured tool-use block '
          '(it decided one was). Your application executes the named '
          'function with the supplied arguments, and sends the result back '
          'to the model as a new message — a tool result — so the model can '
          'use it to keep going or produce a final answer.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'The model never runs anything',
          text:
              'It is worth saying plainly because it is easy to lose track '
              'of: the model only ever decides and describes an action. Your '
              'application is the thing with actual permissions — to the '
              'filesystem, the network, a database. The model requesting a '
              'tool call and your code deciding whether and how to honour '
              'that request are two separate, separable steps, and that '
              'separation is where all of your security controls live.',
        ),
      ],
    ),
    Section(
      id: 'providers',
      heading: 'Anthropic, OpenAI, and the shared shape underneath',
      blocks: [
        ProseBlock(
          'Every major provider implements essentially the same idea under '
          'slightly different names and slightly different JSON shapes. '
          'Anthropic calls it tool use: you pass a tools list to the '
          'Messages API, and Claude responds with a tool_use content block '
          'inside its message, which you answer with a tool_result content '
          'block in your next message. OpenAI calls the equivalent concept '
          'function calling, exposed through a tools parameter on the '
          'Chat Completions or Responses API, where the model returns a '
          'function call with a name and a JSON string of arguments.',
        ),
        ProseBlock(
          'The differences that matter in practice are mostly plumbing: '
          'where exactly in the response object the call appears, whether '
          'arguments arrive as a parsed object or a JSON string you must '
          'parse yourself, and how the result is threaded back into the '
          'conversation. None of that changes the underlying model: define '
          'a schema, let the model choose to invoke it, execute it yourself, '
          'return the result as a new turn. Code that is organised around '
          'that shared shape ports between providers far more easily than '
          'code written against one provider\'s specific field names.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# The provider-specific plumbing differs; the loop does not.

def call_with_tools(client, tools, messages):
    """Provider-agnostic sketch of one round of the tool-use loop."""
    response = client.generate(messages=messages, tools=tools)

    if response.wants_tool_call:
        name = response.tool_call.name
        args = response.tool_call.arguments        # already a dict either way
        result = execute_tool(name, args)
        messages.append(response.as_message())
        messages.append(tool_result_message(response.tool_call.id, result))
        return call_with_tools(client, tools, messages)   # loop again

    return response.text
''',
          caption:
              'Wrapping each provider\'s SDK behind execute_tool and '
              'tool_result_message keeps the agent loop itself provider-'
              'agnostic, which matters the day you need to switch models.',
        ),
      ],
    ),
    Section(
      id: 'good-descriptions',
      heading: 'Writing tool descriptions is prompt engineering',
      blocks: [
        ProseBlock(
          'The model chooses which tool to call, and how to fill its '
          'arguments, based entirely on the name, the description and the '
          'argument documentation you wrote — it has no other information '
          'about what the tool actually does. A vague description produces '
          'vague, wrong, or missing tool calls in exactly the way a vague '
          'prompt produces a vague answer. Writing a good tool is writing a '
          'good prompt for one specific, narrow decision: should I call '
          'this, and with what.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Weak: the model has to guess format, units, and what "recent" means.
weak = {
    "name": "get_orders",
    "description": "Get orders.",
    "input_schema": {
        "type": "object",
        "properties": {"customer": {"type": "string"}},
    },
}

# Strong: format, defaults, and edge cases are spelled out explicitly,
# the same way you would document a public API for a human.
strong = {
    "name": "get_orders",
    "description": (
        "Look up a customer's order history, most recent first. Returns "
        "at most 'limit' orders. Use this before answering any question "
        "about a specific past order or delivery status - do not guess "
        "order details from memory."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "customer_id": {
                "type": "string",
                "description": "Internal customer ID, e.g. 'cus_8f2a1'. "
                                "Not an email address.",
            },
            "limit": {
                "type": "integer",
                "description": "Max orders to return. Defaults to 10 if "
                                "omitted.",
            },
        },
        "required": ["customer_id"],
    },
}
''',
          caption:
              'Every ambiguity left in the weak version — what "customer" '
              'means, what "recent" caps out at — is a place the model will '
              'improvise, and improvised arguments are a common source of '
              'wrong tool calls.',
        ),
        ProseBlock(
          'Distinct tool names and non-overlapping responsibilities matter '
          'just as much as good descriptions. Two tools with similar names '
          'and similar-sounding purposes give the model a coin flip to make '
          'on every call, and it will occasionally call the wrong one '
          'confidently. When a tool set grows large, group and name tools so '
          'their purposes are obviously distinct, and consider exposing '
          'fewer, more general tools rather than many narrow overlapping '
          'ones.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Test tool descriptions the way you test prompts',
          text:
              'Run the same tool-use conversation multiple times, and with '
              'edge-case inputs, and check what the model actually calls and '
              'with what arguments — not just whether it eventually got the '
              'right answer. A description that "usually works" hides '
              'failures in the cases that matter least until they show up in '
              'production.',
        ),
      ],
    ),
    Section(
      id: 'errors-and-parallel',
      heading: 'Errors, retries and parallel calls',
      blocks: [
        ProseBlock(
          'Tools fail: a network call times out, an API returns a 404, an '
          'argument the model supplied does not exist in your system. The '
          'single most important rule is that a tool failure should come '
          'back to the model as a tool result describing the failure, not '
          'as an unhandled exception that crashes the whole loop. Feeding '
          'the error back in gives the model a chance to recover — retry '
          'with different arguments, try a different tool, or tell the user '
          'the operation is not possible — the same way a human would react '
          'to an error message rather than a program crashing.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def execute_tool_safely(name, args, tools):
    """Never raise; always return a tool_result the model can react to."""
    try:
        return tools[name](**args)
    except KeyError:
        return f"Error: unknown tool '{name}'."
    except TypeError as e:
        return f"Error: invalid arguments for '{name}': {e}"
    except Exception as e:                     # the tool's own failure
        return f"Error: '{name}' failed: {e}"


# The model sees this exactly like any other observation, and a
# reasonably capable model will often retry sensibly on its own -
# for example, calling get_weather("San Francisco") again after seeing
# "Error: invalid arguments: 'location' must include a state code."
''',
          caption:
              'A caught, described error is a recoverable observation. An '
              'unhandled exception is a crashed agent loop with no chance to '
              'recover at all.',
        ),
        ProseBlock(
          'Not every retry should be automatic, though. A transient network '
          'error is usually safe to retry a bounded number of times. A tool '
          'call that keeps failing with the same error after a retry is a '
          'sign the model has a wrong assumption, and blindly retrying '
          'forever just burns time and tokens — this connects directly to '
          'the stuck-loop guardrails from the previous lesson.',
        ),
        ProseBlock(
          'When several independent pieces of information are all needed to '
          'proceed, the model can often be given several tools to call in '
          'one turn rather than one at a time — checking the weather in '
          'three cities, say, none of which depends on the others\' results. '
          'Parallel tool calls cut wall-clock latency significantly on '
          'independent lookups, but they only make sense when the calls are '
          'genuinely independent; if call two needs the result of call one, '
          'they have to run sequentially regardless of what the API allows.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Do not silently swallow tool errors',
          text:
              'Returning an empty result or a bare "false" on failure looks '
              'like a successful, uneventful call from the model\'s point of '
              'view, and it will proceed as if the operation worked. Always '
              'describe what went wrong in the tool result text itself, so '
              'the model\'s next decision is informed by the failure rather '
              'than blind to it.',
        ),
      ],
    ),
    Section(
      id: 'security-and-mcp',
      heading: 'Security, scoping, and a standard for tools: MCP',
      blocks: [
        ProseBlock(
          'Because the model is choosing which tool to call and with what '
          'arguments, a tool is only as safe as the permissions behind it. A '
          'tool that can run arbitrary shell commands, delete database rows, '
          'or send emails on a user\'s behalf needs to be treated with the '
          'same caution as handing those permissions to an untrusted script — '
          'because that is functionally what is happening. The model\'s '
          'output is not adversarial by design, but it is also not a '
          'trusted, fully predictable source of commands.',
        ),
        ProseBlock(
          'Two practices do most of the work. Sandbox execution: run '
          'file operations, code execution and shell access inside a '
          'container or restricted environment with no access to anything '
          'outside the task at hand, so a wrong or manipulated tool call '
          'cannot reach production data or unrelated systems. And scope '
          'tools to least privilege: a tool that reads a customer\'s own '
          'order history should not also be able to read every customer\'s '
          'records, even if the underlying API technically supports it — '
          'the tool\'s scope should match exactly what the task requires, '
          'not what the API happens to allow.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: the Model Context Protocol (MCP)',
          children: [
            ProseBlock(
              'Every provider having its own tool-calling format means every '
              'tool integration has to be rewritten per provider, and every '
              'application wiring up the same external systems — a '
              'filesystem, a database, a ticketing system — duplicates that '
              'wiring from scratch. The Model Context Protocol, introduced '
              'by Anthropic and since adopted by other providers, is an open '
              'standard aimed at that duplication: a common way to expose '
              'tools, data and prompts to a model, independent of which '
              'model or application is consuming them.',
            ),
            ProseBlock(
              'The architecture has two sides. An MCP server exposes a set '
              'of tools (and other resources) over a standard protocol — a '
              'GitHub MCP server exposing repository and issue operations, a '
              'Postgres MCP server exposing schema-aware queries. An MCP '
              'client, embedded in an application like an IDE or a chat '
              'client, discovers what a server offers and lets the model '
              'call into it, translating between the model\'s tool-calling '
              'format and MCP\'s wire format underneath.',
            ),
            ProseBlock(
              'The practical benefit is the same one standards always '
              'provide: a tool built once as an MCP server can be used by '
              'any MCP-compatible client without custom integration code per '
              'application, and an application that speaks MCP gains access '
              'to every MCP server someone has already built, rather than '
              'writing bespoke integrations for each one. The security '
              'considerations above do not go away — a sandboxed, '
              'least-privilege tool is still sandboxed and least-privilege '
              'when exposed through MCP — but the plumbing for exposing and '
              'discovering it becomes reusable.',
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
      id: 'ex-tool-schema',
      title: 'Write a tool schema and route a call',
      prompt: [
        ProseBlock(
          'Define a JSON-Schema tool definition for a create_reminder tool '
          'that takes a required "text" and an optional "remind_at" '
          'ISO-8601 timestamp, defaulting to one hour from now if omitted. '
          'Write the description precisely enough that a model would know '
          'when to call it and what "remind_at" should look like.',
        ),
        ProseBlock(
          'Then write a small router that takes a simulated tool_use call '
          '(a name and an arguments dict) and dispatches it to the right '
          'Python function, raising a clear error for an unknown tool name.',
        ),
      ],
      starterCode: '''
create_reminder_tool = {
    "name": "create_reminder",
    "description": "...",   # TODO: write a real, precise description
    "input_schema": {
        "type": "object",
        "properties": {
            # TODO
        },
        "required": [],   # TODO
    },
}


def create_reminder(text, remind_at=None):
    remind_at = remind_at or "one hour from now"
    return f"Reminder set: {text!r} at {remind_at}"


TOOLS = {"create_reminder": create_reminder}


def route_tool_call(name, arguments):
    """Dispatch a simulated tool_use call to the matching function."""
    ...


print(route_tool_call("create_reminder", {"text": "call the dentist"}))
''',
      solutionCode: '''
create_reminder_tool = {
    "name": "create_reminder",
    "description": (
        "Create a reminder for the user. Use this whenever the user asks "
        "to be reminded of something, whether or not they specify a time. "
        "If no time is given, it defaults to one hour from now."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "text": {
                "type": "string",
                "description": "What to remind the user about.",
            },
            "remind_at": {
                "type": "string",
                "description": "ISO-8601 timestamp, e.g. "
                                "'2026-08-03T15:00:00'. Omit to default to "
                                "one hour from now.",
            },
        },
        "required": ["text"],
    },
}


def create_reminder(text, remind_at=None):
    remind_at = remind_at or "one hour from now"
    return f"Reminder set: {text!r} at {remind_at}"


TOOLS = {"create_reminder": create_reminder}


def route_tool_call(name, arguments):
    """Dispatch a simulated tool_use call to the matching function."""
    if name not in TOOLS:
        raise ValueError(f"Unknown tool: {name!r}")
    return TOOLS[name](**arguments)


print(route_tool_call("create_reminder", {"text": "call the dentist"}))
# Reminder set: 'call the dentist' at one hour from now

print(route_tool_call(
    "create_reminder",
    {"text": "team standup", "remind_at": "2026-08-04T09:00:00"},
))
# Reminder set: 'team standup' at 2026-08-04T09:00:00
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Your description says "defaults to one hour from now if '
              'omitted." Why does that detail belong in the schema rather '
              'than only in your Python function\'s default argument?',
          expectedAnswer:
              'Because the model only ever sees the schema and description — '
              'it has no visibility into your function\'s implementation. If '
              'the default behaviour is undocumented in the description, the '
              'model has no way to know that omitting remind_at is safe and '
              'may either guess a time value it was never asked for, or '
              'refuse to call the tool because it thinks a required piece of '
              'information is missing. The description is the only contract '
              'the model actually reads.',
        ),
        SelfCheckQuestion(
          question:
              'Why raise a ValueError for an unknown tool name instead of '
              'silently returning None or an empty string?',
          expectedAnswer:
              'A silent None looks, from the model\'s perspective, '
              'indistinguishable from a tool that ran and legitimately '
              'returned nothing, so the model will proceed as though the '
              'reminder was created when it was not. Raising - or, in a real '
              'agent loop, catching that raise and turning it into an '
              'explicit "Error: unknown tool" result - makes the failure '
              'visible to the model so it can react, and to a developer '
              'reading logs so they can see the model requested a tool that '
              'was never registered.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-safe-execution',
      title: 'Wrap tool execution so nothing crashes the loop',
      prompt: [
        ProseBlock(
          'Write execute_tool_safely(name, args, tools) that looks up and '
          'calls a tool by name, and returns a tool-result string in every '
          'case — success or failure — without ever letting an exception '
          'escape. Cover an unknown tool name, wrong or missing arguments, '
          'and the tool itself raising during execution.',
        ),
        ProseBlock(
          'Then simulate a model that calls a "divide" tool with a zero '
          'divisor and confirm the loop keeps running instead of crashing.',
        ),
      ],
      starterCode: '''
def divide(a, b):
    return a / b


TOOLS = {"divide": divide}


def execute_tool_safely(name, args, tools):
    """Never raise; always return a string tool result."""
    ...


calls = [
    ("divide", {"a": 10, "b": 2}),
    ("divide", {"a": 10, "b": 0}),
    ("divide", {"a": 10}),          # missing required arg
    ("square_root", {"a": 9}),      # unknown tool
]

for name, args in calls:
    print(execute_tool_safely(name, args, TOOLS))
''',
      solutionCode: '''
def divide(a, b):
    return a / b


TOOLS = {"divide": divide}


def execute_tool_safely(name, args, tools):
    """Never raise; always return a string tool result."""
    if name not in tools:
        return f"Error: unknown tool '{name}'."
    try:
        result = tools[name](**args)
        return str(result)
    except TypeError as e:
        return f"Error: invalid arguments for '{name}': {e}"
    except ZeroDivisionError:
        return f"Error: '{name}' failed: division by zero."
    except Exception as e:
        return f"Error: '{name}' failed: {e}"


calls = [
    ("divide", {"a": 10, "b": 2}),
    ("divide", {"a": 10, "b": 0}),
    ("divide", {"a": 10}),          # missing required arg
    ("square_root", {"a": 9}),      # unknown tool
]

for name, args in calls:
    print(execute_tool_safely(name, args, TOOLS))

# 5.0
# Error: 'divide' failed: division by zero.
# Error: invalid arguments for 'divide': divide() missing 1 required
# positional argument: 'b'
# Error: unknown tool 'square_root'.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why catch ZeroDivisionError separately instead of letting it '
              'fall through to the generic Exception handler?',
          expectedAnswer:
              'Both paths would keep the loop alive, so it is not strictly '
              'necessary for safety, but the separate message is far more '
              'useful to the model: "division by zero" tells it precisely '
              'what went wrong and suggests an obvious fix - check the '
              'divisor before calling again - whereas a generic "failed: '
              'division by zero" wrapped in the same phrasing as every other '
              'error gives the model less specific signal to act on. Specific '
              'error messages are what make automatic recovery plausible.',
        ),
        SelfCheckQuestion(
          question:
              'This wrapper turns every failure into a string the model '
              'reads as a tool result. What class of bug does this hide from '
              'you as the developer, and how would you guard against it?',
          expectedAnswer:
              'It can hide a genuine programming bug - a typo in an '
              'argument name, a tool that always fails for a reason that has '
              'nothing to do with the model\'s input - behind a message that '
              'looks like ordinary recoverable friction, so it never '
              'surfaces as a loud crash during development. The guard is to '
              'log every caught exception with its full traceback '
              'server-side even while returning a clean, short message to '
              'the model, so developers can see real bugs in logs and '
              'monitoring even though the model only ever sees a description '
              'it can act on.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 258000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Tool calling, in five minutes. A model can only produce text, '
              'so instead of asking it to describe what it wants to do in '
              'prose — "I will now search for the weather in Paris" — you '
              'give it a catalogue of tools as JSON schemas. Name, '
              'description, arguments. The model emits a structured request '
              'to invoke one, like filling out a form instead of writing a '
              'paragraph. Your code reads the form and executes the actual '
              'action.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Anthropic calls it tool use, OpenAI calls it function '
              'calling — different names, slightly different plumbing, but '
              'the shape is identical everywhere: define a schema, the model '
              'decides to call it, your application actually executes it, '
              'the result goes back in as a new turn. Like giving someone a '
              'menu of things they can ask you to do on their behalf.',
          startMs: 44000,
          endMs: 86000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'The part that\'s easy to underrate: writing a tool description '
              'IS prompt engineering. The model has no idea what your '
              'function does beyond the name and description you gave it. '
              'Vague wording produces wrong or missing calls exactly like a '
              'vague prompt produces a vague answer. It\'s like labeling '
              'the drawers in someone\'s toolbox — "stuff" versus "Phillips '
              'head screwdrivers, sizes 1-3."',
          startMs: 86000,
          endMs: 128000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'And tools fail — networks time out, arguments are wrong. '
              'The rule that matters most: a failure has to come back to the '
              'model as a described result, never an unhandled crash. It\'s '
              'like the difference between a teammate saying "the database '
              'query failed — here\'s the error" versus just walking away '
              'silently. One lets you recover; the other kills the whole '
              'operation.',
          startMs: 128000,
          endMs: 170000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'On security: the model chooses the call, but your application '
              'holds the real permissions — the model is like a customer '
              'placing an order, not the chef with knife access. Sandbox '
              'anything with real reach — filesystem, shell, network — and '
              'scope every tool to the least it needs, not the most the '
              'underlying API happens to allow.',
          startMs: 170000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 'c6',
          speaker: 'Guest',
          text:
              'And one thing worth knowing: the Model Context Protocol, '
              'MCP, standardises exposing tools to models — think of it as '
              'a universal power adapter. A server built once — a database, '
              'a filesystem — works with any compatible client, instead of '
              'every integration being rewritten per provider. Same security '
              'rules apply, just less plumbing to write.',
          startMs: 214000,
          endMs: 258000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 468000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Last time we covered the agent loop in the abstract — '
              'observe, plan, act, repeat. Today\'s the "act" part in detail: '
              'how a model actually reaches out and does something in the '
              'world. Think of it like giving someone a toolbox. You don\'t '
              'say "please handle the weather" and hope they figure it out — '
              'you give them a specific tool called "check_weather" with '
              'labeled slots for city and date.',
          startMs: 0,
          endMs: 46000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Start from the constraint: a model only produces tokens. It '
              'cannot execute code, open a socket, or write a file. So '
              'instead of asking it to narrate an action and hoping you can '
              'parse the narration, you hand it a catalogue of tools as JSON '
              'schemas — name, description, input schema for arguments — and '
              'it emits a structured call instead of prose. Like giving '
              'someone order forms instead of asking them to write essays '
              'about what they want.',
          startMs: 46000,
          endMs: 100000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'The round trip is fixed regardless of provider. Send the '
              'message plus the tool list. The model replies with text, or '
              'with a tool-use block naming a tool and its arguments. Your '
              'application runs the real function — the model never does — '
              'and sends the result back as a new turn so the model can '
              'continue. The model decides, your code executes, the model '
              'reacts. Clean separation.',
          startMs: 100000,
          endMs: 148000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Anthropic and OpenAI both do this under different names — '
              'tool use versus function calling — with different field names '
              'in the response. None of that changes the underlying loop. '
              'Code organised around the shared shape, wrapped behind your '
              'own execute and format functions, ports between providers '
              'far more easily than code tied to one SDK\'s specific response '
              'format.',
          startMs: 148000,
          endMs: 196000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Here\'s the point that gets missed: writing a tool description '
              'IS prompt engineering, full stop. The model decides whether '
              'and how to call your function purely from the name, '
              'description, and argument docs you wrote. It has zero other '
              'visibility. If you label the drawer "stuff," don\'t be '
              'surprised when someone puts the wrong thing in it.',
          startMs: 196000,
          endMs: 242000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'So "get orders" with no units, no format, no default is an '
              'invitation to guess. Spell out formats, edge cases and '
              'defaults the way you\'d document a public API for a stranger — '
              '"customer_id, not an email; limit defaults to 10." Every gap '
              'you leave is a gap the model fills with improvisation, and '
              'improvised arguments are the number one source of wrong tool '
              'calls.',
          startMs: 242000,
          endMs: 288000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Then failures. A tool will time out, get a bad argument, hit '
              'a 404. The rule that matters most: the failure comes back as '
              'a tool result the model can read, never an unhandled '
              'exception that kills the loop. A caught, described error is '
              'recoverable — the model can retry, try a different tool, or '
              'explain the failure. A crash is just game over.',
          startMs: 288000,
          endMs: 334000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Worth adding parallel calls here too: when several pieces of '
              'information are genuinely independent — weather in three '
              'different cities — the model can fire off several tool calls '
              'in one turn instead of one at a time, cutting real latency. '
              'But only when the calls truly don\'t depend on each other\'s '
              'results — checking three cities is parallel; checking a city '
              'and THEN its population is sequential no matter what.',
          startMs: 334000,
          endMs: 378000,
        ),
        PodcastSegment(
          id: 's9',
          speaker: 'Host',
          text:
              'And security, because the model choosing the call doesn\'t '
              'mean the model has the permissions — your application does. '
              'It\'s like a customer placing an order versus the chef '
              'actually wielding the knife. Sandbox anything with real '
              'access, and scope every tool to least privilege: a tool for '
              'reading one customer\'s orders should not be able to read '
              'everyone\'s, even if the API behind it could.',
          startMs: 378000,
          endMs: 424000,
        ),
        PodcastSegment(
          id: 's10',
          speaker: 'Guest',
          text:
              'Last thing: the Model Context Protocol. Every provider having '
              'its own tool format means every integration gets rewritten '
              'per provider — like every country having its own power plug. '
              'MCP standardises exposing tools, so a server built once works '
              'with any compatible client. The security rules don\'t change, '
              'but the plumbing to expose and discover tools becomes '
              'reusable.',
          startMs: 424000,
          endMs: 468000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 834000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Deep dive on tools and function calling. The route: the '
              'actual mechanics of a tool call, how Anthropic and OpenAI '
              'converge on the same shape despite different names, why a '
              'tool description is prompt engineering in disguise, error '
              'handling and parallel calls, security and least privilege, '
              'and MCP as the standardisation effort tying it all together.',
          startMs: 0,
          endMs: 62000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Ground it in the actual constraint. A language model produces '
              'tokens. It cannot open a socket, write a file, or run a '
              'query. Every "the agent looked something up" you\'ve ever heard '
              'is shorthand for: the model emitted a structured request, and '
              'something outside the model actually did the looking up. The '
              'model is the decision-maker, never the executor.',
          startMs: 62000,
          endMs: 122000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'The schema is ordinary JSON Schema — name, description, '
              'input schema listing argument names, types, which are '
              'required. Given that up front, the model emits a tool_use '
              'block instead of a paragraph your code would have to parse '
              'and hope it got right. The round trip: message plus tool list '
              'goes in; text or a tool-use block comes back; if it\'s a '
              'call, your code executes it and sends the result back as a '
              'tool_result for the model to incorporate.',
          startMs: 122000,
          endMs: 230000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Anthropic and OpenAI both implement that shape under '
              'different names and slightly different field layouts — tool '
              'use versus function calling, parsed object versus JSON string '
              'arguments. None of that touches the underlying model. Code '
              'written around the shared loop, wrapped behind your own '
              'execute and format functions, ports between providers far '
              'more easily than code tied to one SDK\'s response shape.',
          startMs: 230000,
          endMs: 290000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Now the part that\'s genuinely underrated: writing a tool '
              'description IS prompt engineering, not documentation as an '
              'afterthought. The model decides whether to call a tool and '
              'how to fill its arguments based entirely on the name, '
              'description and per-argument docs you wrote. It has zero '
              'other visibility. Label the drawer "stuff" and don\'t be '
              'surprised when people put the wrong things in it.',
          startMs: 290000,
          endMs: 346000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              '"Get orders" with an undocumented "customer" field and no '
              'stated limit is an invitation for the model to guess a format, '
              'guess a cap, guess what "recent" means. Spell out exactly '
              'what a strong description would: the ID format, what it is '
              'NOT — not an email — the default when a field is omitted. '
              'Every ambiguity is a place the model improvises, and '
              'improvisation is the number one source of wrong tool calls.',
          startMs: 346000,
          endMs: 404000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'And distinct names matter as much as good descriptions. Two '
              'tools with similar names and similar-sounding purposes give '
              'the model a coin flip on every call, and it will occasionally '
              'call the wrong one with total confidence. When a tool set '
              'grows large, default to fewer, clearly distinct tools over '
              'many narrow overlapping ones.',
          startMs: 404000,
          endMs: 454000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Then failure handling — the operational half of this lesson. '
              'Tools time out, get bad arguments, hit real errors. The rule: '
              'a failure MUST come back as a described tool result, never '
              'an unhandled exception. A caught error is a chance to recover; '
              'a crash ends the whole loop. And not every failure should '
              'auto-retry — a transient network error is worth a bounded '
              'retry, but the same failure twice in a row means the model '
              'has a wrong assumption baked in, and retrying forever just '
              'burns tokens.',
          startMs: 454000,
          endMs: 558000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Parallel tool calls are worth a mention: independent lookups — '
              'weather in three cities, none depending on the others — can '
              'go out in one turn instead of one at a time, cutting real '
              'wall-clock latency. The moment call two needs call one\'s '
              'result, though, they\'re sequential no matter what the API '
              'allows. It\'s the difference between asking three friends to '
              'look up three things simultaneously versus asking one friend '
              'something, waiting, then asking the next.',
          startMs: 558000,
          endMs: 606000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Security follows from one fact: the model chooses the call, '
              'but never holds the permissions — your application does. The '
              'model is like a customer placing an order; your code is the '
              'chef with the knife. Sandbox anything with real reach — shell '
              'access, file writes — and scope every tool to the least it '
              'needs. A tool for one customer\'s orders should not double '
              'as a tool for everyone\'s.',
          startMs: 606000,
          endMs: 658000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Which brings us to MCP, the Model Context Protocol. The '
              'problem: every provider\'s own tool format means every '
              'integration gets rewritten per provider and per application — '
              'like every country having different power plugs. MCP is an '
              'open standard for exposing tools to a model in a provider-'
              'agnostic way.',
          startMs: 658000,
          endMs: 714000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'The shape is server and client. An MCP server exposes tools '
              'over the standard protocol; an MCP client discovers what\'s '
              'available and lets the model call into it. Build a server '
              'once, any compatible client can use it. The security rules '
              'don\'t get easier — a tool still needs sandboxing and least '
              'privilege whether wired through MCP or by hand. MCP reduces '
              'the integration work, not the responsibility to think '
              'carefully about what any given tool is allowed to touch.',
          startMs: 714000,
          endMs: 834000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'A tool call is structured data, not prose',
      body:
          'Models cannot execute code, so tool calling gives the model a '
          'catalogue of JSON-Schema tool definitions up front and lets it '
          'emit a structured request naming a tool and its arguments. Your '
          'application executes the real function and returns the result as '
          'a new turn — the model only ever decides and describes, never '
          'runs.',
    ),
    SummaryCard(
      title: 'Tool descriptions are prompt engineering',
      body:
          'The model chooses which tool to call and how to fill its '
          'arguments based entirely on the name, description and argument '
          'docs you wrote. Vague descriptions produce wrong or missing '
          'calls the same way vague prompts produce vague answers — spell '
          'out formats, defaults and edge cases explicitly.',
    ),
    SummaryCard(
      title: 'Failures must be recoverable, and scope must be minimal',
      body:
          'A tool failure should come back as a described tool result the '
          'model can react to, never an unhandled exception. Tools should be '
          'sandboxed and scoped to least privilege, because the model '
          'chooses the call but the application holds the real permissions. '
          'MCP standardises how tools are exposed to models, not the '
          'security responsibilities around them.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Tool use / function calling',
      definition:
          'The mechanism by which a model is given JSON-Schema tool '
          'definitions and, instead of producing free text, emits a '
          'structured request naming a tool and its arguments for the host '
          'application to execute.',
    ),
    KeyConcept(
      term: 'Input schema',
      definition:
          'The JSON Schema describing a tool\'s arguments — their names, '
          'types, descriptions and which are required — that the model '
          'reads to decide how to fill a tool call correctly.',
    ),
    KeyConcept(
      term: 'Tool result',
      definition:
          'The value or error returned after executing a tool call, sent '
          'back to the model as a new message so it can incorporate the '
          'outcome — success or failure — into its next decision.',
    ),
    KeyConcept(
      term: 'Least privilege (tool scoping)',
      definition:
          'Restricting a tool to exactly the access its task requires, '
          'rather than whatever the underlying API happens to allow, so a '
          'wrong or manipulated call cannot reach more than it needs to.',
    ),
    KeyConcept(
      term: 'Parallel tool calls',
      definition:
          'Issuing several independent tool calls within one turn rather '
          'than sequentially, cutting latency when the calls do not depend '
          'on each other\'s results.',
    ),
    KeyConcept(
      term: 'Model Context Protocol (MCP)',
      definition:
          'An open standard for exposing tools, data and prompts to a model '
          'independent of any one provider, so a tool built once as an MCP '
          'server can be used by any MCP-compatible client without custom '
          'per-application integration.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake: 'Writing a terse, ambiguous tool description and trusting '
          'the model to infer the details.',
      correction:
          'The model has no visibility into a tool beyond its name, '
          'description and argument docs. Spell out formats, units, '
          'defaults and edge cases explicitly, the same discipline you would '
          'apply to documenting a public API for a developer who has never '
          'seen your codebase.',
    ),
    Mistake(
      mistake: 'Letting a tool\'s exception propagate up and crash the '
          'agent loop.',
      correction:
          'Catch every exception at the point of tool execution and return '
          'a clear, descriptive error string as the tool result instead. A '
          'caught error the model can read is a chance to recover — retry, '
          'try another tool, or explain the failure to the user. An '
          'unhandled exception ends the loop with no recovery at all.',
    ),
    Mistake(
      mistake: 'Giving a tool broader access than its task requires because '
          'the underlying API happens to support it.',
      correction:
          'Scope every tool to least privilege deliberately: a tool for '
          'reading one customer\'s orders should not be able to read every '
          'customer\'s, even if the API behind it technically allows it. '
          'The model chooses when to call a tool; the tool\'s permissions '
          'determine how much damage a wrong or manipulated call can do.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Walk me through what happens, end to end, when a model decides '
          'to call a tool.',
      answer:
          'The application sends the model a message along with a list of '
          'available tools, each described as a JSON-Schema definition with '
          'a name, description and input schema. The model, based purely on '
          'that description and the conversation so far, either replies with '
          'ordinary text or with a structured tool-use block naming a tool '
          'and supplying arguments that match its schema. The model itself '
          'never executes anything — the host application reads that '
          'structured block, calls the real function with the given '
          'arguments, and sends the result back to the model as a new '
          'message, a tool result. The model then incorporates that result '
          'into its next decision: call another tool, or produce a final '
          'answer. The whole thing is a strict request-execute-respond loop, '
          'and the separation between "the model decides" and "the '
          'application executes" is exactly where error handling and '
          'security controls have to live.',
    ),
    InterviewQuestion(
      question:
          'A tool you built keeps getting called with subtly wrong '
          'arguments. How would you debug and fix that?',
      answer:
          'First I would look at the tool\'s description and input schema as '
          'the primary suspect, because the model has no information about '
          'the tool beyond what is written there — a vague or ambiguous '
          'description produces exactly this failure mode. I would check '
          'whether units, formats, defaults, and required-versus-optional '
          'fields are stated explicitly, since anything left ambiguous is a '
          'gap the model fills by guessing. I would also check whether a '
          'similarly named tool exists that the model might be confusing it '
          'with — overlapping names and purposes cause exactly this kind of '
          'misfire. Concretely, I would log the actual tool-use blocks the '
          'model produces across several runs, including edge-case inputs, '
          'compare them against the schema, tighten the wording and add '
          'concrete examples of correct arguments in the description, and '
          're-run the same conversations to confirm the fix, the same way I '
          'would iterate on a prompt.',
    ),
    InterviewQuestion(
      question:
          'You need to give an agent the ability to run SQL queries against '
          'a production database. What would you actually build, and what '
          'would you refuse to build?',
      answer:
          'I would not expose a general "run this SQL" tool against '
          'production directly. Instead I would build a narrower tool — '
          'something like "look up an order by ID" or "search orders by '
          'customer" — backed by a read-only, least-privilege database role '
          'that can only see the tables and rows the task actually needs, '
          'rather than a tool that can execute arbitrary queries. If ad hoc '
          'querying is genuinely required, I would run it against a '
          'sandboxed replica with row-level restrictions, never the live '
          'production database, and I would validate that generated SQL is '
          'read-only before executing it. I would make sure every failure — '
          'a malformed query, a permissions error — comes back as a clear '
          'tool result rather than an unhandled exception, and I would log '
          'every query the tool actually executes for audit purposes. The '
          'model choosing to query something is not the same as the model '
          'being trusted with unrestricted database access, and the tool\'s '
          'scope is what enforces that distinction, not the model\'s good '
          'behaviour.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'Tool use with Claude — Claude Platform Docs',
    url: 'https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview',
    description:
        'The full request/response round trip for tool use, including '
        'client vs. server tools and the tool_use / tool_result cycle '
        'reproduced in this lesson\'s code samples.',
  ),
  Source(
    title: 'Writing effective tools for AI agents — Anthropic Engineering',
    url: 'https://www.anthropic.com/engineering/writing-tools-for-agents',
    description:
        'Anthropic\'s own guidance on tool naming, description quality and '
        'reducing ambiguity, directly behind this lesson\'s "tool '
        'descriptions are prompt engineering" section.',
  ),
  Source(
    title: 'Function calling — OpenAI API',
    url: 'https://developers.openai.com/api/docs/guides/function-calling',
    description:
        'OpenAI\'s equivalent mechanism and terminology, used here to show '
        'that the underlying request-execute-respond shape is shared across '
        'providers despite different field names.',
  ),
  Source(
    title: 'Model Context Protocol — introduction',
    url: 'https://modelcontextprotocol.io/introduction',
    description:
        'The official overview of MCP\'s client/server architecture, '
        'source for this lesson\'s deep dive on a provider-agnostic standard '
        'for exposing tools to models.',
  ),
];
