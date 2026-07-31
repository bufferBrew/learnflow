import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 3: defining functions and the scopes their names live in.
const Lesson functionsLesson = Lesson(
  id: 'py-functions-and-scope',
  title: 'Functions & Scope',
  description:
      'Defining functions, passing arguments in every form Python allows, and '
      'the rules that decide which name wins.',
  estimatedMinutes: 22,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  review: _review,
  sources: _sources,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'defining',
      heading: 'A function is an object you happen to call',
      blocks: [
        ProseBlock(
          'def creates a function object and binds it to a name, exactly as '
          'assignment binds any other object. That is not a pedantic framing: '
          'because functions are ordinary objects you can store them in lists, '
          'pass them as arguments, return them from other functions and attach '
          'attributes to them. Decorators, callbacks and dispatch tables all '
          'fall out of that one fact.',
        ),
        ProseBlock(
          'Every function returns something. If control reaches the end of the '
          'body without a return statement, or hits a bare return, the call '
          'evaluates to None. A docstring — the first statement in the body, a '
          'string literal — becomes the function\'s __doc__ and is what help() '
          'shows.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def area(width, height):
    """Return the area of a rectangle."""
    return width * height


print(area(3, 4))              # 12
print(area.__doc__)            # Return the area of a rectangle.
print(type(area))              # <class 'function'>

# Functions are values: store them, pass them, call them later.
operations = {"area": area, "perimeter": lambda w, h: 2 * (w + h)}
print(operations["perimeter"](3, 4))   # 14

def apply_twice(fn, value):
    return fn(fn(value))

print(apply_twice(str.upper, "hi"))    # HI
''',
          caption: 'def binds a callable object to a name — nothing more.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'lambda is for expressions, not for naming',
          text:
              'A lambda is a function limited to a single expression. Assigning '
              'one to a name (f = lambda x: ...) gains nothing over def and '
              'loses the useful name in tracebacks. Use lambda inline, as a '
              'sort key or a small callback.',
        ),
      ],
    ),
    Section(
      id: 'arguments',
      heading: 'Parameters: positional, keyword, variadic',
      blocks: [
        ProseBlock(
          'Parameters can be filled positionally or by name, and defaults make '
          'them optional. *args collects any surplus positional arguments into '
          'a tuple; **kwargs collects surplus keyword arguments into a dict. '
          'At the call site the same two stars do the reverse — they unpack a '
          'sequence or mapping into arguments.',
        ),
        ProseBlock(
          'Two markers control how arguments may be passed. A bare * means '
          'everything after it must be given by keyword, which is how you stop '
          'callers writing connect("localhost", True, False) with three '
          'unreadable booleans. A / means everything before it must be '
          'positional, which keeps parameter names free to be renamed later '
          'without breaking callers.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def connect(host, port=5432, *, timeout=10, retries=3):
    return f"{host}:{port} timeout={timeout} retries={retries}"


print(connect("db.internal"))
print(connect("db.internal", 5433, timeout=2))
# connect("db.internal", 5433, 2)  -> TypeError: too many positional arguments


def log(level, *parts, **fields):
    detail = " ".join(str(p) for p in parts)
    extras = ", ".join(f"{k}={v}" for k, v in fields.items())
    return f"[{level}] {detail} ({extras})"


print(log("warn", "disk", "full", host="db1", pct=93))
# [warn] disk full (host=db1, pct=93)

# The same stars unpack at the call site.
args = ("info", "started")
options = {"host": "web2"}
print(log(*args, **options))
''',
          caption: 'Keyword-only parameters and variadic collection.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Never default a parameter to a mutable object',
          text:
              'def add(item, items=[]) evaluates that list once, when the def '
              'runs — not on each call. Every caller who omits items shares one '
              'growing list. Default to None and build a fresh list inside the '
              'body.',
        ),
      ],
    ),
    Section(
      id: 'legb',
      heading: 'Scope: the LEGB rule',
      blocks: [
        ProseBlock(
          'When Python resolves a name it searches four scopes in order: Local '
          'to the current function, Enclosing functions, Global to the module, '
          'and finally Builtins. The first hit wins; if nothing matches you get '
          'a NameError. Scopes are created by functions, classes and modules — '
          'not by if statements or for loops, so a name bound inside a loop is '
          'still visible after it.',
        ),
        ProseBlock(
          'The rule that surprises people is that assignment anywhere in a '
          'function body makes the name local for the whole body, decided when '
          'the function is compiled rather than when it runs. Reading a global '
          'is fine; assigning to it without declaring global makes it a '
          'brand-new local and turns the earlier read into an '
          'UnboundLocalError.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
total = 0            # module-level (global)

def broken():
    print(total)     # UnboundLocalError: 'total' is assigned below
    total = 1

def reading_is_fine():
    print(total)     # 0 - reads the global happily

def explicit():
    global total
    total += 1       # now really updates the module-level name


reading_is_fine()
explicit()
print(total)         # 1

# Loops and ifs do not create a scope.
for i in range(3):
    last = i
print(i, last)       # 2 2
''',
          caption: 'Assignment decides locality at compile time.',
        ),
      ],
    ),
    Section(
      id: 'closures',
      heading: 'Closures, nonlocal and global',
      blocks: [
        ProseBlock(
          'A function defined inside another function can read the enclosing '
          'function\'s variables even after the outer call has returned. The '
          'inner function plus the captured environment is a closure, and it '
          'is how decorators, callbacks with remembered configuration and '
          'simple factories are built.',
        ),
        ProseBlock(
          'To rebind an enclosing variable rather than shadow it, declare it '
          'nonlocal. global does the same for module-level names. Both are '
          'occasionally the right tool and usually a sign that the state wants '
          'to live in a class or be passed explicitly — mutable module state is '
          'the hardest kind of code to test.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def make_counter(start=0):
    count = start

    def increment(step=1):
        nonlocal count       # rebind the enclosing name, do not shadow it
        count += step
        return count

    return increment


tick = make_counter()
print(tick(), tick(), tick(5))   # 1 2 7

other = make_counter(100)
print(other())                   # 101 - a separate captured environment

# Closures capture the variable, not its value at definition time.
funcs = [lambda: i for i in range(3)]
print([f() for f in funcs])      # [2, 2, 2]

fixed = [lambda i=i: i for i in range(3)]
print([f() for f in fixed])      # [0, 1, 2]
''',
          caption: 'Each call to make_counter gets its own captured count.',
        ),
        CollapsibleBlock(
          title: 'Under the hood: how a closure is actually stored',
          children: [
            ProseBlock(
              'A variable captured by an inner function is not copied. CPython '
              'promotes it to a cell object — a one-slot box — and both '
              'functions reference that cell. The outer function\'s frame can '
              'disappear entirely; the cell survives because the inner '
              'function\'s __closure__ tuple still points at it. That shared '
              'cell is exactly why the late-binding loop above prints 2, 2, 2: '
              'all three lambdas hold the same cell, and by the time they are '
              'called the loop has left 2 in it.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
def outer():
    message = "hi"

    def inner():
        return message

    return inner


fn = outer()
print(fn.__code__.co_freevars)          # ('message',)
print(fn.__closure__[0].cell_contents)  # hi
''',
            ),
            ProseBlock(
              'The default-argument trick (lambda i=i: i) works because '
              'defaults are evaluated once, at definition time, so each lambda '
              'stores its own snapshot instead of sharing a cell. Same '
              'mechanism as the mutable-default gotcha, used deliberately.',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'signatures',
      heading: 'Designing a signature people can use',
      blocks: [
        ProseBlock(
          'A function\'s signature is its public contract, and it is far harder '
          'to change than its body. Prefer few positional parameters, make '
          'anything ambiguous keyword-only, and never accept a bare boolean '
          'positionally. Annotations document the intended types for readers '
          'and static checkers; the interpreter does not enforce them at '
          'runtime.',
        ),
        ProseBlock(
          'Return one kind of thing. A function that returns a string on '
          'success and False on failure forces every caller to write a type '
          'test, and someone will eventually forget. Raise an exception, or '
          'return None and document it.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def resize(image, width: int, height: int, *, keep_aspect: bool = True) -> str:
    """Resize image, optionally preserving its aspect ratio."""
    mode = "fit" if keep_aspect else "stretch"
    return f"{image} -> {width}x{height} ({mode})"


print(resize("photo.png", 800, 600))
print(resize("photo.png", 800, 600, keep_aspect=False))

# Annotations are metadata, not enforcement.
print(resize.__annotations__["width"])   # <class 'int'>
print(resize(1, "wide", "tall"))         # runs; nothing checks the types
''',
          caption: 'Keyword-only flags read at the call site; hints document.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-fn-mutable-default',
      title: 'Fix the shared default',
      prompt: [
        ProseBlock(
          'add_task looks fine and passes its first test, then behaves '
          'bizarrely on the second call. Explain what is happening and fix it '
          'so each call that omits tasks starts from an empty list.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def add_task(name, tasks=[]):
    tasks.append(name)
    return tasks
''',
        ),
      ],
      starterCode: '''
def add_task(name, tasks=[]):
    tasks.append(name)
    return tasks


print(add_task("write"))    # ['write']
print(add_task("review"))   # should be ['review'] - what does it print?
''',
      solutionCode: '''
def add_task(name, tasks=None):
    if tasks is None:
        tasks = []
    tasks.append(name)
    return tasks


print(add_task("write"))              # ['write']
print(add_task("review"))             # ['review']
print(add_task("ship", ["draft"]))    # ['draft', 'ship']
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question: 'When exactly is the default list created?',
          expectedAnswer:
              'Once, when the def statement executes and the function object is '
              'built — not on each call. The list is stored in '
              'add_task.__defaults__ and every call that omits the argument '
              'mutates that one object.',
        ),
        SelfCheckQuestion(
          question:
              'Why is None the conventional sentinel rather than, say, an '
              'empty tuple?',
          expectedAnswer:
              'None is immutable, unambiguous and cannot be confused with a '
              'real argument. An empty tuple would also be safe from mutation, '
              'but it is a plausible real value for a sequence parameter, so it '
              'cannot reliably mean "not supplied".',
        ),
      ],
    ),
    Exercise(
      id: 'ex-fn-kwargs',
      title: 'Write a flexible formatter',
      prompt: [
        ProseBlock(
          'Write summarise(title, *items, separator=", ", **labels) that '
          'returns the title, then the items joined by separator, then any '
          'keyword labels as key=value pairs in parentheses. Calling '
          'summarise("Build", "compile", "test", status="ok") must return '
          '"Build: compile, test (status=ok)". With no items the colon section '
          'is omitted; with no labels the parentheses are omitted.',
        ),
      ],
      starterCode: '''
def summarise(title, *items, separator=", ", **labels):
    # TODO: assemble "<title>: <items> (<labels>)", omitting empty parts
    ...


print(summarise("Build", "compile", "test", status="ok"))
print(summarise("Build"))
print(summarise("Deploy", "push", region="eu", dry_run=True))
''',
      solutionCode: '''
def summarise(title, *items, separator=", ", **labels):
    text = title
    if items:
        text += ": " + separator.join(str(item) for item in items)
    if labels:
        pairs = ", ".join(f"{key}={value}" for key, value in labels.items())
        text += f" ({pairs})"
    return text


print(summarise("Build", "compile", "test", status="ok"))
# Build: compile, test (status=ok)
print(summarise("Build"))
# Build
print(summarise("Deploy", "push", region="eu", dry_run=True))
# Deploy: push (region=eu, dry_run=True)
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why must separator be keyword-only here, and what makes it so?',
          expectedAnswer:
              'It sits after *items, and everything after a variadic positional '
              'parameter can only be supplied by keyword. That is also what you '
              'want: a positional separator would be swallowed by *items as '
              'just another value.',
        ),
        SelfCheckQuestion(
          question:
              'What order are the keys in labels, and can you rely on it?',
          expectedAnswer:
              'Yes — **kwargs is a regular dict, and since Python 3.7 dicts '
              'preserve insertion order as a language guarantee, so labels '
              'appear in the order the caller wrote them.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-fn-closure',
      title: 'Build a running average with a closure',
      prompt: [
        ProseBlock(
          'Write make_averager() that returns a function. Each call to that '
          'function takes a number, records it, and returns the mean of every '
          'value seen so far by that particular averager. Two averagers created '
          'by separate calls must not share state. Use nonlocal rather than a '
          'class or a global.',
        ),
      ],
      starterCode: '''
def make_averager():
    # TODO: capture the running total and count, return an inner function
    ...


avg = make_averager()
print(avg(10))    # 10.0
print(avg(20))    # 15.0
print(make_averager()(4))   # 4.0 - independent state
''',
      solutionCode: '''
def make_averager():
    total = 0
    count = 0

    def add(value):
        nonlocal total, count
        total += value
        count += 1
        return total / count

    return add


avg = make_averager()
print(avg(10))              # 10.0
print(avg(20))              # 15.0
print(avg(30))              # 20.0
print(make_averager()(4))   # 4.0 - independent state
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'What error do you get if you drop the nonlocal declaration, and '
              'why?',
          expectedAnswer:
              'UnboundLocalError on total. Assigning to total inside add makes '
              'it local to add for the entire body, so the += tries to read a '
              'local that has never been assigned. nonlocal tells the compiler '
              'to bind the enclosing variable instead.',
        ),
        SelfCheckQuestion(
          question:
              'If total were a list and you only ever called append, would you '
              'still need nonlocal?',
          expectedAnswer:
              'No. Appending mutates the object the enclosing name already '
              'points at, and never rebinds the name, so no declaration is '
              'needed. nonlocal is only required for assignment.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 204000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Functions and scope, short version. A def statement builds a '
              'function object and binds it to a name — that is all it does. '
              'Functions are values, so you can pass them around, store them in '
              'dicts and return them from other functions.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'On arguments: defaults make parameters optional, star-args '
              'collects extra positional arguments into a tuple, and '
              'double-star-kwargs collects extra keyword arguments into a dict. '
              'A bare star in the parameter list forces everything after it to '
              'be passed by keyword, which is the cheapest readability win in '
              'the language.',
          startMs: 42000,
          endMs: 92000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'The one rule you must not forget: never use a mutable default. '
              'The default is evaluated once when the function is defined, so '
              'every call shares the same list. Default to None and create the '
              'list inside the body.',
          startMs: 92000,
          endMs: 130000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Scope follows LEGB: local, enclosing, global, builtins, first '
              'match wins. And assigning to a name anywhere in a function makes '
              'that name local for the whole function, which is why reading a '
              'global before assigning it raises UnboundLocalError.',
          startMs: 130000,
          endMs: 172000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Use global and nonlocal only when you really mean to rebind an '
              'outer name. Everything else is closures — inner functions '
              'remembering the environment they were built in. That is the '
              'foundation for decorators.',
          startMs: 172000,
          endMs: 204000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 492000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Functions today — and specifically the two halves people tend to '
              'learn separately: how arguments get in, and how names get '
              'resolved once you are inside. Get both right and a surprising '
              'amount of Python stops being mysterious, including decorators, '
              'callbacks and most import-time bugs.',
          startMs: 0,
          endMs: 54000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The framing that helps most is that def is an assignment. It '
              'creates a function object at runtime and binds it to a name. '
              'Nothing about it is special: you can put function objects in a '
              'list, use them as dict values for dispatch, or hand them to '
              'sorted as a key. Every callable-based pattern in Python comes '
              'from that.',
          startMs: 54000,
          endMs: 120000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'On the parameter side, Python is unusually expressive. You have '
              'positional parameters, defaults, star-args for surplus '
              'positionals, double-star-kwargs for surplus keywords, and two '
              'markers: a bare star meaning "keyword-only from here" and a '
              'slash meaning "positional-only up to here".',
          startMs: 120000,
          endMs: 178000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Keyword-only is the one to adopt today. Any call site that reads '
              'like a function name followed by True, False, False has lost the '
              'argument. Force those flags to be named and the call becomes '
              'self-documenting — and you can reorder or add options later '
              'without breaking anyone.',
          startMs: 178000,
          endMs: 236000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Then defaults, and the classic trap. Default values are '
              'evaluated once, when the def executes, and stored on the '
              'function object. So a default of empty-list is a single list '
              'shared by every call that omits the argument. It accumulates. '
              'The fix is always the same: default to None, then build the real '
              'value inside the body.',
          startMs: 236000,
          endMs: 300000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Now scope. Python searches local, then enclosing functions, then '
              'module globals, then builtins — LEGB — and stops at the first '
              'match. Note what does not create a scope: if statements, for '
              'loops and with blocks. A name bound inside a loop body is '
              'perfectly visible after the loop.',
          startMs: 300000,
          endMs: 360000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'The compile-time part trips everyone up once. If a function '
              'assigns to a name anywhere in its body, that name is local for '
              'the entire body, decided before the function ever runs. So '
              'printing a global on line one and assigning to it on line two '
              'gives you UnboundLocalError on line one. Declaring global fixes '
              'it — or better, pass the value in and return the new one.',
          startMs: 360000,
          endMs: 428000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Closures round it off. An inner function keeps access to the '
              'enclosing function\'s variables even after the outer call has '
              'returned, and nonlocal lets it rebind them. That is how you get '
              'counters, memoisers and decorators without a class. Just '
              'remember closures capture variables, not values — a lambda made '
              'in a loop sees the loop variable\'s final value.',
          startMs: 428000,
          endMs: 492000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 828000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'The long form on functions. We are going to cover the function '
              'object itself, the full argument protocol, how CPython resolves '
              'names at compile time, closures and cells, and then some '
              'signature design. By the end, decorators should look like an '
              'obvious consequence rather than magic.',
          startMs: 0,
          endMs: 68000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with what def leaves behind. You get an object with a '
              'dunder code attribute holding the compiled bytecode, a dunder '
              'defaults tuple, a dunder globals reference to the defining '
              'module\'s namespace, a dunder closure tuple, and a mutable dunder '
              'dict you can hang attributes on. Every one of those is '
              'inspectable at runtime, which is what makes tools like '
              'functools.wraps and inspect.signature possible.',
          startMs: 68000,
          endMs: 154000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'The defaults tuple is the whole explanation for the mutable '
              'default bug. It is built once, at def time, and it lives on the '
              'function. Nothing re-evaluates it. So a list default is one '
              'object for the process lifetime — and you can actually watch it '
              'grow by printing the function\'s dunder defaults between calls.',
          startMs: 154000,
          endMs: 224000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'On to argument passing, which people describe wrongly all the '
              'time. Python is neither pass-by-value nor pass-by-reference in '
              'the C++ sense. It passes object references by value: the callee '
              'gets its own name bound to the caller\'s object. Rebinding the '
              'parameter does nothing to the caller; mutating the object is '
              'visible everywhere. That single sentence resolves most arguments '
              'about it.',
          startMs: 224000,
          endMs: 304000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Then there is the shape of the parameter list. Positional-only '
              'parameters, marked with a slash, exist because the standard '
              'library has functions whose parameter names were never meant to '
              'be part of the contract. If you write a library, a slash lets '
              'you rename parameters later without breaking callers, and a '
              'bare star lets you add options without disturbing positional '
              'order.',
          startMs: 304000,
          endMs: 380000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Name resolution is where CPython does something genuinely '
              'clever. The compiler decides for each name whether it is local, '
              'a free variable from an enclosing scope, or global — before the '
              'function ever runs. Locals are then not dictionary lookups at '
              'all; they are numbered slots in the frame, loaded with the '
              'LOAD_FAST instruction. Globals stay dictionary lookups. That is '
              'why locals are measurably faster.',
          startMs: 380000,
          endMs: 466000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'And that compile-time decision is exactly why UnboundLocalError '
              'exists as a distinct error from NameError. The compiler saw an '
              'assignment somewhere in the body, so it allocated a local slot '
              'for the whole function. Reading it before anything is stored '
              'there is a different failure from a name that does not exist at '
              'all.',
          startMs: 466000,
          endMs: 536000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Closures use a third storage class. A variable that an inner '
              'function needs is promoted to a cell — a small box holding one '
              'reference. Both functions point at that cell, so the outer '
              'frame can be destroyed and the value survives. You can see it: '
              'the inner function\'s dunder closure is a tuple of cells, each '
              'with a cell_contents attribute.',
          startMs: 536000,
          endMs: 616000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'The shared cell is why late binding bites. Build three lambdas '
              'in a loop over range three and call them afterwards and all '
              'three return two, because they share one cell that the loop left '
              'at two. The usual fix is a default argument capturing the '
              'current value, which works precisely because defaults are '
              'evaluated eagerly at definition time.',
          startMs: 616000,
          endMs: 692000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Put closures together with the fact that functions are objects '
              'and you have decorators. A decorator is a function that takes a '
              'function, defines a wrapper that closes over it, and returns the '
              'wrapper. The at-sign syntax is pure sugar for rebinding the '
              'name. Use functools.wraps on the wrapper so the name, docstring '
              'and signature metadata survive.',
          startMs: 692000,
          endMs: 764000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'To close, signature design. Few positionals, flags keyword-only, '
              'no mutable defaults, one kind of return value, and annotations '
              'as documentation for readers and static checkers — the runtime '
              'ignores them. The body of a function is easy to change; its '
              'signature is a promise.',
          startMs: 764000,
          endMs: 828000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'def is an assignment',
      body:
          'A def statement builds a function object and binds it to a name. '
          'Functions are ordinary values: store them, pass them, return them. '
          'Every call returns something — None when no return statement runs.',
    ),
    SummaryCard(
      title: 'Defaults are evaluated once',
      body:
          'Default values are computed when the def executes and stored on the '
          'function object, so a mutable default is shared by every call that '
          'omits it. Default to None and build the real value in the body.',
    ),
    SummaryCard(
      title: 'LEGB, decided at compile time',
      body:
          'Names resolve local, enclosing, global, builtins — first match wins. '
          'Assigning to a name anywhere in a function makes it local for the '
          'whole body; use global or nonlocal to rebind an outer name instead.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Keyword-only parameter',
      definition:
          'A parameter declared after a bare * (or after *args) that callers '
          'must pass by name. Used to keep boolean flags and rarely-used '
          'options readable at the call site.',
    ),
    KeyConcept(
      term: '*args and **kwargs',
      definition:
          'Collect surplus positional arguments into a tuple and surplus '
          'keyword arguments into a dict. The same operators at a call site '
          'unpack a sequence or mapping into individual arguments.',
    ),
    KeyConcept(
      term: 'LEGB rule',
      definition:
          'The order in which Python searches scopes for a name: Local, '
          'Enclosing, Global, Builtins. Functions, classes and modules create '
          'scopes; loops and if statements do not.',
    ),
    KeyConcept(
      term: 'Closure',
      definition:
          'An inner function together with the enclosing variables it captured, '
          'which stay alive after the outer call returns. Stored as cell '
          'objects in the function\'s __closure__.',
    ),
    KeyConcept(
      term: 'nonlocal',
      definition:
          'A declaration that a name refers to a variable in the nearest '
          'enclosing function scope, so assignment rebinds that variable '
          'instead of creating a new local.',
    ),
    KeyConcept(
      term: 'UnboundLocalError',
      definition:
          'Raised when a function reads a name that the compiler classified as '
          'local — because it is assigned somewhere in the body — before any '
          'value has been stored in it.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake: 'Writing def f(items=[]) or def f(cache={}).',
      correction:
          'The container is created once at definition time and shared across '
          'calls. Use def f(items=None) and set items = [] inside the body when '
          'it is None.',
    ),
    Mistake(
      mistake:
          'Assigning to a module-level variable inside a function and expecting '
          'the change to stick.',
      correction:
          'The assignment creates a local instead. Declare global (or better, '
          'return the new value and let the caller rebind it) — and if the same '
          'function also reads that name earlier, the read raises '
          'UnboundLocalError.',
    ),
    Mistake(
      mistake:
          'Creating callbacks in a loop with a lambda that references the loop '
          'variable.',
      correction:
          'All the lambdas share one cell, so they see the loop variable\'s '
          'final value. Capture the current value with a default argument '
          '(lambda i=i: ...) or with functools.partial.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question: 'Is Python pass-by-value or pass-by-reference?',
      answer:
          'Neither, in the usual sense — it passes object references by value. '
          'The callee gets its own name bound to the same object the caller '
          'passed. Rebinding the parameter has no effect on the caller, but '
          'mutating the object does, which is why passing a list and calling '
          'append is visible outside and passing it and reassigning it is not.',
    ),
    InterviewQuestion(
      question:
          'Explain the difference between global and nonlocal, and when you '
          'would use each.',
      answer:
          'global binds a name in the module namespace; nonlocal binds one in '
          'the nearest enclosing function scope, and it is an error if no such '
          'binding exists. Both exist only to make assignment rebind an outer '
          'name rather than create a local. nonlocal has a legitimate home in '
          'closures such as counters and decorators; global usually signals '
          'state that would be better held in a class or passed explicitly, '
          'because module-level mutation is hard to test.',
    ),
    InterviewQuestion(
      question:
          'Why does a mutable default argument accumulate values between '
          'calls?',
      answer:
          'Default values are evaluated once, when the def statement runs, and '
          'stored in the function object\'s __defaults__ tuple. Every call that '
          'omits the argument binds the parameter to that same object, so any '
          'mutation persists into the next call. Immutable defaults are safe '
          'because they cannot be mutated in the first place.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: '4. More Control Flow Tools — Python Docs',
    url: 'https://docs.python.org/3/tutorial/controlflow.html',
    description:
        'Tutorial chapter whose second half covers defining functions, default '
        'values, keyword arguments, arbitrary argument lists and lambdas.',
  ),
  Source(
    title: 'PEP 227 – Statically Nested Scopes',
    url: 'https://peps.python.org/pep-0227/',
    description:
        'The proposal that introduced lexical scoping for nested functions, '
        'with the rationale behind the LEGB name-resolution rules.',
  ),
];
