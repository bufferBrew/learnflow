import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
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
  estimatedMinutes: 30,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  play: _play,
  review: _review,
  sources: _sources,
  furtherReading: _furtherReading,
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
        ProseBlock(
          'Because functions are first-class values, you can use them to build '
          'dispatch tables — dicts mapping keys to functions — which are often '
          'cleaner than long if/elif chains. And partial application via '
          'functools.partial lets you "pre-fill" some arguments of a function, '
          'creating a new callable with fewer parameters. This is how you '
          'adapt a function to match a callback signature without writing '
          'boilerplate wrappers.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from functools import partial

# Dispatch table: cleaner than a chain of if/elif.
def handle_get(request):
    return "GET " + request

def handle_post(request):
    return "POST " + request

router = {"GET": handle_get, "POST": handle_post}
print(router.get("PUT", lambda r: "unknown")( "data"))
# unknown data — .get() with a default avoids KeyError

# partial: pre-fill arguments to match a callback interface.
def log(level, message, timestamp=None):
    return f"[{level}] {message}"

error_log = partial(log, "ERROR")
print(error_log("disk full"))
# [ERROR] disk full

# Practical: sort by a computed key without a lambda.
names = ["grace hopper", "ada lovelace", "alan turing"]
by_surname = partial(sorted, key=lambda n: n.split()[-1])
print(by_surname(names))    # ['ada lovelace', 'grace hopper', 'alan turing']
''',
          caption: 'Dispatch tables and partial for cleaner callback wiring.',
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
        ProseBlock(
          'The / (positional-only) marker is less well known but equally '
          'important for library authors. Parameters before / cannot be passed '
          'by keyword. This lets you rename them later without breaking callers '
          'who may have been using keyword argument syntax. The standard '
          'library uses this extensively: pow(x, y, /) means you cannot call '
          'pow(x=2, y=3).',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# / = everything before is positional-only.
# * = everything after is keyword-only.
# Between them = either positional or keyword.

def configure(host, port, /, *, timeout=10, retries=3):
    """host and port are positional-only; timeout and retries keyword-only."""
    return f"{host}:{port} (timeout={timeout}, retries={retries})"

print(configure("db.internal", 5432, timeout=5))
# configure(host="db.internal", port=5432)   -> TypeError
# configure("db.internal", 5432, 5)          -> TypeError (timeout is keyword-only)

# Standard library example: str.replace(old, new, /, count=-1)
# The positional-only marker means old and new can be renamed later.
print("ababab".replace("a", "x", 2))    # xbxbab
''',
          caption: 'Positional-only (/) protects parameter names for future refactoring.',
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
        ProseBlock(
          'Decorators are the natural consequence of first-class functions '
          'plus closures. A decorator is a function that takes a function '
          'and returns a replacement (usually a wrapper). Always use '
          'functools.wraps on your wrapper — it copies __name__, __doc__, '
          'and __module__ from the original, so help() and tracebacks show '
          'the real identity rather than "wrapper".',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import functools
import time


def timed(fn):
    """Decorator: prints how long the decorated function took."""
    @functools.wraps(fn)          # preserves fn's name, docstring, signature
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = fn(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{fn.__name__} took {elapsed:.3f}s")
        return result
    return wrapper


@timed
def slow_add(a, b):
    """Returns the sum after pausing."""
    time.sleep(0.1)
    return a + b

print(slow_add(2, 3))
print(slow_add.__name__, slow_add.__doc__)
# slow_add took 0.1xxs / 5 / slow_add Returns the sum after pausing.
''',
          caption: 'Decorators are closure factories; @wraps keeps metadata intact.',
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
    Exercise(
      id: 'ex-fn-partial',
      title: 'Simplify callbacks with functools.partial',
      prompt: [
        ProseBlock(
          'You have a logger(log_level, source, message) that takes three '
          'arguments, but the callback framework only calls its handlers with '
          'a single (message) argument. Write bind_logger(log_level, source) '
          'that returns a callable accepting only the message, using '
          'functools.partial. Then verify the returned function has the right '
          'signature.',
        ),
      ],
      starterCode: '''
from functools import partial


def logger(log_level, source, message):
    return f"[{log_level}] {source}: {message}"


def bind_logger(log_level, source):
    # TODO: return a callable with log_level and source pre-filled
    ...


error_log = bind_logger("ERROR", "api")
print(error_log("connection refused"))
print(error_log("timeout after 5s"))
''',
      solutionCode: '''
from functools import partial


def logger(log_level, source, message):
    return f"[{log_level}] {source}: {message}"


def bind_logger(log_level, source):
    return partial(logger, log_level, source)


error_log = bind_logger("ERROR", "api")
print(error_log("connection refused"))
# [ERROR] api: connection refused
print(error_log("timeout after 5s"))
# [ERROR] api: timeout after 5s

# partial produces a callable with the right metadata.
print(error_log.func.__name__)    # logger
print(error_log.args)             # ('ERROR', 'api')
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why use partial instead of a lambda or a nested def?',
          expectedAnswer:
              'partial explicitly states intent — "this callable is logger '
              'with some arguments frozen" — and preserves the original '
              'function name and metadata via the .func attribute. A lambda '
              'or def loses that information and is harder to inspect at '
              'runtime.',
        ),
        SelfCheckQuestion(
          question:
              'What happens if bind_logger is called with keyword arguments '
              'like bind_logger(log_level="WARN", source="auth")?',
          expectedAnswer:
              'partial freezes positional arguments; keyword arguments from '
              'bind_logger are forwarded to partial as keyword arguments to '
              'logger, which also works correctly. logger(log_level="WARN", '
              'source="auth", message="...") is a valid call.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-fn-decorator',
      title: 'Write a retry decorator',
      prompt: [
        ProseBlock(
          'Write a decorator @retry(times, delay=0) that re-runs a function '
          'up to "times" times if it raises an exception, sleeping "delay" '
          'seconds between attempts. If all attempts fail, re-raise the last '
          'exception. Use functools.wraps to preserve metadata, and make the '
          'decorator accept parameters by nesting it one level deeper.',
        ),
      ],
      starterCode: '''
import functools
import time


def retry(times, delay=0):
    # TODO: return a decorator that wraps fn with retry logic
    ...


@retry(times=3, delay=0.1)
def flaky_divide(a, b):
    # Pretend this sometimes fails.
    if b == 0:
        raise ZeroDivisionError("cannot divide by zero")
    return a / b


print(flaky_divide(10, 2))
# print(flaky_divide(10, 0))   # should retry 3 times, then raise
''',
      solutionCode: '''
import functools
import time


def retry(times, delay=0):
    def decorator(fn):
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            last_exc = None
            for attempt in range(1, times + 1):
                try:
                    return fn(*args, **kwargs)
                except Exception as exc:
                    last_exc = exc
                    if attempt < times:
                        time.sleep(delay)
            raise last_exc
        return wrapper
    return decorator


@retry(times=3, delay=0.1)
def flaky_divide(a, b):
    if b == 0:
        raise ZeroDivisionError("cannot divide by zero")
    return a / b


print(flaky_divide(10, 2))     # 5.0

try:
    flaky_divide(10, 0)
except ZeroDivisionError as exc:
    print("failed after retries:", exc)
# failed after retries: cannot divide by zero

print(flaky_divide.__name__)   # flaky_divide — @wraps preserved the name
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why is retry(times, delay) a function returning a decorator, '
              'rather than the decorator itself?',
          expectedAnswer:
              'A decorator is always called with exactly one argument — the '
              'function being decorated. To accept parameters, you wrap the '
              'real decorator in an outer function: retry(times, delay) runs '
              'first and returns decorator, which Python then calls with the '
              'function. Without the nesting, @retry would receive the '
              'function as "times".',
        ),
        SelfCheckQuestion(
          question:
              'Why are only Exception subclasses caught, not BaseException?',
          expectedAnswer:
              'BaseException includes KeyboardInterrupt and SystemExit, which '
              'are not errors — they are the user or the program asking to '
              'stop. Retrying on Ctrl-C would hang the program indefinitely.',
        ),
      ],
    ),
  ],
);

const GameContent _play = GameContent(
  games: [
    BugHuntGame(
      id: 'game-functions-mutable-default',
      title: 'Find the shared default',
      instructions: 'Tap the line that causes tasks to leak between calls.',
      code: '''
def add_task(name, tasks=[]):
    tasks.append(name)
    return tasks


print(add_task("write"))
print(add_task("review"))
''',
      buggyLine: 1,
      explanation:
          'The default list is built once, when def runs, and stored on the '
          'function object. Every call that omits tasks shares that one list, '
          'so it grows across calls instead of starting fresh.',
      fixedCode: '''
def add_task(name, tasks=None):
    if tasks is None:
        tasks = []
    tasks.append(name)
    return tasks


print(add_task("write"))    # ['write']
print(add_task("review"))   # ['review']
''',
    ),
    OutputPredictorGame(
      id: 'game-functions-closure-loop',
      title: 'What does this print?',
      instructions: 'Pick what the list comprehension prints.',
      code: '''
funcs = [lambda: i for i in range(3)]
print([f() for f in funcs])
''',
      options: ['[0, 1, 2]', '[2, 2, 2]', '[0, 0, 0]', 'TypeError'],
      correctIndex: 1,
      explanation:
          'Closures capture the variable i, not its value at definition time. '
          'All three lambdas share one cell, and by the time they are called '
          'the loop has left 2 in it — so every call returns 2.',
    ),
    FillBlankGame(
      id: 'game-functions-keyword-only',
      title: 'Force a keyword-only parameter',
      instructions: 'Type the missing symbol.',
      code: '''
def connect(host, port=5432, ______, timeout=10):
    return f"{host}:{port} timeout={timeout}"


print(connect("db.internal", timeout=2))
''',
      blanks: [Blank(answer: '*', hint: 'a single symbol')],
    ),
    SyntaxScrambleGame(
      id: 'game-functions-closure-scramble',
      title: 'Rebuild the counter closure',
      instructions: 'Drag or use the arrows to put these lines back in order.',
      lines: [
        'def make_counter(start=0):',
        '    count = start',
        '    def increment(step=1):',
        '        nonlocal count',
        '        count += step',
        '        return count',
        '    return increment',
      ],
    ),
    TermMatchGame(
      id: 'game-functions-terms',
      title: 'Match the vocabulary',
      instructions: 'Tap a term, then tap its definition.',
      pairs: [
        TermPair(
          term: 'Keyword-only parameter',
          definition: 'A parameter after a bare * that callers must pass by name.',
        ),
        TermPair(
          term: '*args and **kwargs',
          definition: 'Collect surplus positional and keyword arguments.',
        ),
        TermPair(
          term: 'LEGB rule',
          definition: 'The scope search order: Local, Enclosing, Global, Builtins.',
        ),
        TermPair(
          term: 'Closure',
          definition: 'An inner function plus the enclosing variables it captured.',
        ),
        TermPair(
          term: 'nonlocal',
          definition: 'Declares that assignment rebinds an enclosing function variable.',
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
              'Functions and scope, the short version. A def statement does exactly one thing: '
              'it builds a function object and slaps a name on it. That\'s it. No magic. '
              'And since functions are just values — like numbers or strings — you can pass them around, '
              'store them in dicts, or return them from other functions. '
              'It\'s like having a recipe card you can hand to anyone, photocopy, or pin to a bulletin board.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Quick tour of arguments. Defaults make parameters optional — classic and essential. '
              '*args collects extra positional arguments into a tuple. **kwargs collects extra keyword arguments into a dict. '
              'But the real gem is a bare * in the parameter list: it forces everything after it to be keyword-only. '
              'This is the cheapest readability win in all of Python. No more call sites that look like '
              '"process(data, True, False, 42)" where nobody knows what True and False mean.',
          startMs: 42000,
          endMs: 92000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'One rule you absolutely must remember: never use a mutable default value. '
              'That default is evaluated once, when Python reads the def line — not each time you call. '
              'It\'s like an office coffee pot that was brewed once and everyone drinks from the same batch. '
              'Default to None, then build your fresh list or dict inside the function body. '
              'This single rule prevents a whole class of sneaky, hard-to-debug errors.',
          startMs: 92000,
          endMs: 130000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Scope follows the LEGB rule: Local, Enclosing, Global, Builtins — first match wins. '
              'Like searching for your keys: check your pockets first, then your desk, then the whole room, then the entire house. '
              'Critical gotcha: if you assign to a name ANYWHERE in a function, that name is local EVERYWHERE in that function — '
              'even on lines before the assignment. So reading a global on line 1 and assigning to it on line 2? '
              'UnboundLocalError. Python already decided it\'s local, and you haven\'t put anything in it yet.',
          startMs: 130000,
          endMs: 172000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Use global and nonlocal sparingly — only when you genuinely need to rebind a name in an outer scope. '
              'Everything else is closures: inner functions that remember the environment they were born in, '
              'like a snapshot of the room at the moment of creation. '
              'Closures are the foundation for decorators, factories, and half the elegant patterns in Python. '
              'Master them and a whole category of problems becomes trivial.',
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
              'Functions today — and we\'re tackling the two halves people usually learn years apart: '
              'how arguments get into a function, and how names get resolved once you\'re inside the body. '
              'Get both of these right and a shocking amount of Python stops feeling like magic — '
              'decorators make sense, callbacks become obvious, and those weird import-time bugs just evaporate.',
          startMs: 0,
          endMs: 54000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Here\'s the mental model that changes everything: def is just an assignment. '
              'At runtime, Python creates a function object — a real thing in memory — '
              'and binds a name to it. Nothing magical. You can put function objects in a list, '
              'use them as dict values for a dispatch table, or pass them to sorted() as the key. '
              'It\'s like having a toolbox where the tools themselves are also objects you can sort, label, and hand around. '
              'Every callback, every decorator, every higher-order function pattern flows from this one insight.',
          startMs: 54000,
          endMs: 120000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'On parameters, Python gives you an unusually rich vocabulary. Positional parameters, defaults, '
              '*args for catching extra positional arguments, **kwargs for catching extra keyword arguments. '
              'And two special markers: a bare * that says "everything after this must be named" '
              'and a / that says "everything before this must be positional." '
              'Between these two markers you can design an API that\'s impossible to call wrong.',
          startMs: 120000,
          endMs: 178000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Keyword-only arguments are the pattern to adopt today. If your call site looks like '
              '"process(data, True, False, False)" — you\'ve already lost. Nobody knows what those booleans mean. '
              'Force them to be keyword-only with a bare *, and suddenly the call reads like English: '
              '"process(data, validate=True, cache=False, async_mode=False)." '
              'Self-documenting, and you can reorder or add options later without breaking any existing calls.',
          startMs: 178000,
          endMs: 236000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Now defaults, and the classic trap that catches every Python developer at least once. '
              'Default values are evaluated exactly once — when the def statement runs — '
              'and they\'re stored right on the function object. So an empty list default is ONE list '
              'shared by every single call that doesn\'t provide that argument. It accumulates across calls '
              'like a shared shopping cart that nobody ever empties. '
              'The fix never changes: default to None, then create the real value inside the function body.',
          startMs: 236000,
          endMs: 300000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Now scope — the LEGB rule. Python searches Local, then Enclosing functions, then Global module, '
              'then Builtins — and stops at the very first match. Simple and predictable. '
              'But here\'s what trips people up: lots of things that LOOK like they should create a scope... don\'t. '
              'If statements, for loops, with blocks — none of them create a new scope. '
              'A variable defined inside a loop is perfectly visible after the loop ends. '
              'Only functions (and comprehensions, and class bodies) create new scopes in Python.',
          startMs: 300000,
          endMs: 360000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'The compile-time rule trips up everyone exactly once. If a function assigns to a name ANYWHERE '
              'in its body, Python decides BEFORE the function runs that this name is local for the ENTIRE body. '
              'So if you print a global on line 1 and assign to it on line 2 — UnboundLocalError on line 1. '
              'Python already decided it\'s local, and nothing is in it yet. You can fix it with the global keyword — '
              'but honestly, the better fix is passing the value in as a parameter and returning the new one. '
              'Cleaner, testable, no surprises.',
          startMs: 360000,
          endMs: 428000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Closures bring it all together. An inner function keeps access to its enclosing function\'s variables '
              'even after the outer function has returned — it\'s like having a key to a room that no longer exists. '
              'nonlocal lets the inner function rebind those variables, enabling counters, memoizers, and decorators '
              'without writing a single class. One critical detail: closures capture VARIABLES, not VALUES. '
              'Make three lambdas in a loop and all three will see the loop variable\'s final value — '
              'not the value it had when each lambda was created. This is the classic "late binding" trap.',
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
              'The deep dive on functions. We\'re going to explore the function object itself — '
              'what it actually contains — the full argument passing protocol, how CPython resolves names '
              'at compile time (before your code even runs!), closures and cells, and some signature design wisdom. '
              'By the end, decorators should feel like an obvious consequence of everything we\'ve discussed, '
              'not some arcane wizardry.',
          startMs: 0,
          endMs: 68000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Let\'s look at what a def statement actually leaves behind. You get a function object with: '
              '__code__ — the compiled bytecode. __defaults__ — a tuple of default values. '
              '__globals__ — a reference to the module\'s namespace. __closure__ — captured variables from enclosing scopes. '
              'And __dict__ — a mutable dictionary where you can hang arbitrary attributes. '
              'Every one of these is inspectable at runtime! That\'s how tools like functools.wraps and inspect.signature work: '
              'they just read these attributes. A function is a regular object you can poke and prod.',
          startMs: 68000,
          endMs: 154000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'The __defaults__ tuple explains the mutable default bug completely. '
              'It\'s built once, at def time, and lives on the function object forever. Nothing re-evaluates it. '
              'So if your default is [], that\'s ONE list for the entire lifetime of your program. '
              'You can literally watch it grow by printing the_function.__defaults__ between calls — '
              'each call that appends adds to the same list, and you can see the damage accumulate. '
              'It\'s not a bug in Python; it\'s a direct consequence of how function objects store their defaults.',
          startMs: 154000,
          endMs: 224000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Now argument passing — a topic people argue about endlessly because they use the wrong framework. '
              'Python is neither pass-by-value nor pass-by-reference in the C++ sense. '
              'It\'s "pass object reference by value": the callee gets its own local name bound to the same object '
              'the caller passed. Rebinding that name inside the function? Caller never sees it. '
              'Mutating the object through that name? Caller sees it immediately — because it\'s the same object. '
              'Think of it like sharing a Google Doc: you each have your own link, but edits are visible to everyone.',
          startMs: 224000,
          endMs: 304000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Let\'s talk parameter list design — the / and * markers that most people skip over. '
              'The slash makes parameters before it positional-only. Why would you want that? '
              'The standard library has functions whose parameter names were never meant to be public API — '
              'allowing keyword calls would lock those names in forever. With /, you can rename them later. '
              'The bare * makes parameters after it keyword-only — letting you add options without disturbing '
              'positional order. Together they let you design an API that\'s both flexible and stable.',
          startMs: 304000,
          endMs: 380000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Name resolution is where CPython shows its clever side. At compile time — BEFORE your function runs — '
              'the compiler scans the entire function body and tags every name: local, free variable (from an enclosing scope), '
              'or global. Locals get special treatment: they become numbered slots in the stack frame, '
              'accessed with the LOAD_FAST instruction — no dictionary lookup needed. '
              'Globals stay as dictionary lookups. This is why accessing a local variable is measurably faster '
              'than accessing a global. The compiler did the hard work before you even hit "run."',
          startMs: 380000,
          endMs: 466000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'This compile-time classification explains why UnboundLocalError is a distinct error from NameError. '
              'The compiler saw an assignment somewhere in the function body, so it said "this name is local" '
              'and allocated a numbered slot for it. When you try to read that slot before anything is stored in it, '
              'you get UnboundLocalError — "I have a slot for this, but it\'s empty." '
              'NameError is different: it means "I have no idea what this name refers to at all." '
              'Two different errors, two different problems — and the compiler decided which one you\'d get before execution.',
          startMs: 466000,
          endMs: 536000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Closures introduce a third kind of variable storage: the cell. '
              'When an inner function needs a variable from an enclosing scope, Python promotes that variable '
              'into a cell — a tiny box that holds exactly one reference. Both the outer and inner functions '
              'point to this same cell. The outer frame can be garbage collected, but the cell survives, '
              'keeping the value alive. You can inspect this: the inner function\'s __closure__ attribute '
              'is a tuple of cells, each with a .cell_contents you can read. '
              'It\'s like a safety deposit box that outlives the bank that issued it.',
          startMs: 536000,
          endMs: 616000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'The shared cell explains the late binding trap perfectly. Build three lambdas in a loop '
              'and call them afterward — all three return the loop variable\'s final value. Why? '
              'All three lambdas share the SAME cell. The loop updates that cell, and by the time you call them, '
              'the cell holds the final value. The fix: capture the current value in a default argument — '
              'lambda x=i: x. This works because defaults are evaluated eagerly at definition time, '
              'snapshotting the value before the loop moves on. It\'s a clever trick that exploits '
              'the very behavior we just learned about mutable defaults, but in a good way this time.',
          startMs: 616000,
          endMs: 692000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Finally, decorators: they\'re just closures and first-class functions colliding beautifully. '
              'A decorator takes a function, defines a wrapper that captures it in a closure, '
              'and returns the wrapper. The @ syntax is pure sugar — @log above def foo() '
              'is exactly the same as writing foo = log(foo) underneath. '
              'Always use functools.wraps on your wrapper — it copies over the original function\'s name, '
              'docstring, and signature so tools and debuggers still see the real identity underneath. '
              'Without wraps, every decorated function looks like it\'s called "wrapper" in tracebacks.',
          startMs: 692000,
          endMs: 764000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'To close, let\'s talk signature design — because a function\'s signature is a promise to every caller. '
              'Keep positionals to a minimum. Make flags and options keyword-only. '
              'Never use mutable defaults. Return one kind of thing consistently — '
              'don\'t make callers check isinstance on your return value. '
              'Use type annotations as documentation for humans and static checkers — '
              'the runtime ignores them, but your teammates won\'t. '
              'The body you can refactor anytime. The signature? That\'s a contract. Choose it carefully.',
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

const List<Source> _furtherReading = [
  Source(
    title: 'Python Scope & the LEGB Rule — Real Python',
    url: 'https://realpython.com/python-scope-legb-rule/',
    description:
        'Comprehensive guide to Python scoping rules with visual diagrams '
        'and walkthroughs of global vs nonlocal vs local resolution.',
  ),
  Source(
    title: 'Python Closures — Real Python',
    url: 'https://realpython.com/python-closure/',
    description:
        'Deep dive into closures, captured cells, late binding, and the '
        'functools.partial alternative for factory functions.',
  ),
  Source(
    title: 'Primer on Python Decorators — Real Python',
    url: 'https://realpython.com/primer-on-python-decorators/',
    description:
        'Step-by-step tutorial on writing decorators, parameterised decorators, '
        'and using functools.wraps to preserve metadata.',
  ),
  Source(
    title: 'PEP 3102 – Keyword-Only Arguments',
    url: 'https://peps.python.org/pep-3102/',
    description:
        'The PEP that introduced the bare * syntax for keyword-only parameters, '
        'with usage examples and design rationale.',
  ),
];
