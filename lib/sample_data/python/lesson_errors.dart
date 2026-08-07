import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 3: exceptions, and using them as a design tool rather than
/// a nuisance.
const Lesson errorsLesson = Lesson(
  id: 'py-error-handling',
  title: 'Error Handling',
  description:
      'Exceptions as control flow: raising, catching, chaining and cleaning up '
      'without hiding bugs.',
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
      id: 'exceptions-are-objects',
      heading: 'Exceptions are objects in a hierarchy',
      blocks: [
        ProseBlock(
          'An exception is an ordinary object. Raising one unwinds the call '
          'stack until some frame is willing to handle it; if nothing does, the '
          'interpreter prints a traceback and exits. Because exceptions are '
          'classes, they form a tree, and an except clause catches the class '
          'you name plus every subclass of it.',
        ),
        ProseBlock(
          'That hierarchy is the whole game when deciding what to catch. '
          'ValueError means the type was right but the value was not; TypeError '
          'means the type itself was wrong; LookupError is the parent of '
          'KeyError and IndexError; OSError covers file and network failures '
          'and carries an errno. Catching a precise class documents exactly '
          'which failure you anticipated.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
print(int.__mro__)
# (<class 'int'>, <class 'object'>)

print(ValueError.__mro__)
# (ValueError, Exception, BaseException, object)

print(issubclass(KeyError, LookupError))    # True
print(issubclass(FileNotFoundError, OSError))  # True

try:
    {"a": 1}["b"]
except LookupError as exc:          # catches KeyError via the hierarchy
    print(type(exc).__name__, exc)  # KeyError 'b'

err = ValueError("bad port")
print(err.args)                     # ('bad port',)
''',
          caption: 'except matches a class and all of its subclasses.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Never write a bare except',
          text:
              '"except:" also catches KeyboardInterrupt and SystemExit, so it '
              'swallows Ctrl-C and orderly shutdown. If you truly need a '
              'catch-all, write "except Exception:" — and log the exception '
              'rather than passing.',
        ),
        ProseBlock(
          'Beyond the basic hierarchy, Python 3.11 introduced ExceptionGroup '
          'and the except* syntax. When multiple concurrent tasks fail — each '
          'with a different exception — a single Exception object cannot '
          'represent that. ExceptionGroup wraps them together, and except* '
          'lets you handle each type present in the group, pulling out the '
          'ones you can manage and letting the rest propagate.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# ExceptionGroup: multiple failures wrapped together (Python 3.11+).
try:
    raise ExceptionGroup("validation", [
        ValueError("bad email"),
        KeyError("missing name"),
        ValueError("bad phone"),
    ])
except* ValueError as eg:
    print("value errors:", eg.exceptions)
except* KeyError as eg:
    print("key errors:", eg.exceptions)
# value errors: (ValueError('bad email'), ValueError('bad phone'))
# key errors: (KeyError('missing name'),)
''',
          caption: 'except* pulls specific types from an ExceptionGroup.',
        ),
      ],
    ),
    Section(
      id: 'try-shape',
      heading: 'The full shape of try',
      blocks: [
        ProseBlock(
          'A try statement has four parts and each has a distinct job. try '
          'holds the operation that might fail — keep it as small as possible, '
          'because anything else in there might raise the same exception for a '
          'different reason. except handles a specific failure. else runs only '
          'when no exception was raised, which is where the code that depends '
          'on success belongs. finally always runs, whether the block '
          'succeeded, failed, or returned.',
        ),
        ProseBlock(
          'Multiple except clauses are tried top to bottom and the first '
          'matching one wins, so subclasses must come before their parents. A '
          'single clause can name a tuple of classes when they share handling.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def load_port(raw):
    try:
        port = int(raw)             # only the risky call lives here
    except ValueError:
        print(f"not a number: {raw!r}")
        return None
    except TypeError:
        print("expected a string")
        return None
    else:
        # runs only when no exception was raised
        print("parsed cleanly")
        return port
    finally:
        # runs on every path, including the returns above
        print("done with", raw)


print(load_port("8080"))    # parsed cleanly / done with 8080 / 8080
print(load_port("http"))    # not a number / done with http / None
print(load_port(None))      # expected a string / done with None / None
''',
          caption: 'try / except / else / finally, each with one job.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'else is not decoration',
          text:
              'Putting the success path in else keeps it outside the protected '
              'block, so a KeyError raised by your follow-up code cannot be '
              'mistaken for one raised by the operation you were guarding.',
        ),
      ],
    ),
    Section(
      id: 'raising',
      heading: 'Raising, re-raising and custom exceptions',
      blocks: [
        ProseBlock(
          'Raise an exception when a function cannot do what its name promises. '
          'Returning None or False as an error signal pushes the check onto '
          'every caller, and one of them will forget; an exception is loud by '
          'default and can carry detail in its message and attributes.',
        ),
        ProseBlock(
          'Define your own exception class when callers might reasonably want '
          'to catch your failure specifically. Give a library one base class '
          'and derive the rest from it, so users can catch everything from your '
          'package with a single clause. Subclass Exception, never '
          'BaseException.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class ConfigError(Exception):
    """Base class for every error this module raises."""


class MissingKey(ConfigError):
    def __init__(self, key):
        super().__init__(f"missing required key: {key}")
        self.key = key              # structured detail for the handler


def require(config, key):
    if key not in config:
        raise MissingKey(key)
    return config[key]


try:
    require({"host": "db1"}, "port")
except ConfigError as exc:          # catches MissingKey too
    print(exc)                      # missing required key: port
    print(exc.key)                  # port

# Re-raise after logging: a bare raise preserves the original traceback.
def retry_once(fn):
    try:
        return fn()
    except OSError:
        print("first attempt failed, retrying")
        raise
''',
          caption: 'One base class per package; structured attributes on top.',
        ),
        ProseBlock(
          'The difference between assert and raise is critical and often '
          'misunderstood. assert is for programmer errors — invariants that '
          'should be mathematically impossible. raise is for expected failures '
          '— bad input, missing files, network errors. Crucially, assertions '
          'are stripped when Python runs with -O (optimise), so production '
          'code must never rely on them for validation.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# assert: "this can never happen" (stripped with python -O).
def sqrt(x):
    assert x >= 0, "sqrt of negative number"   # programmer mistake
    return x ** 0.5

# raise: "this might happen, and the caller can handle it".
def divide(a, b):
    if b == 0:
        raise ValueError("cannot divide by zero")   # expected failure
    return a / b

# assert with a message — the message is part of the AssertionError.
try:
    sqrt(-4)
except AssertionError as exc:
    print(exc)    # sqrt of negative number
''',
          caption: 'assert is for invariants; raise is for expected failures.',
        ),
      ],
    ),
    Section(
      id: 'eafp',
      heading: 'EAFP: ask forgiveness, not permission',
      blocks: [
        ProseBlock(
          'Two styles compete. Look Before You Leap checks preconditions first: '
          'if the key exists, then read it. Easier to Ask Forgiveness than '
          'Permission just does the thing and handles the failure. Python '
          'leans strongly toward the second, and not merely as a matter of '
          'taste.',
        ),
        ProseBlock(
          'The check-then-act pattern has a race in it: between the check and '
          'the action, another thread or another process can delete the file or '
          'remove the key. It also duplicates the work — the membership test '
          'hashes the key, then the lookup hashes it again. try/except costs '
          'essentially nothing when no exception is raised, so the happy path '
          'is actually faster.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import os

# LBYL: racy, and does the lookup twice.
if os.path.exists("config.toml"):
    with open("config.toml") as handle:   # file may be gone by now
        data = handle.read()

# EAFP: one attempt, one clear failure mode.
try:
    with open("config.toml") as handle:
        data = handle.read()
except FileNotFoundError:
    data = ""

# The same idea with dicts.
settings = {"host": "db1"}

try:
    port = settings["port"]
except KeyError:
    port = 5432

port = settings.get("port", 5432)   # simplest of all when a default exists
''',
          caption: 'Attempt the operation; handle the specific failure.',
        ),
        CollapsibleBlock(
          title: 'Under the hood: chaining, and why "from" matters',
          children: [
            ProseBlock(
              'When an exception is raised inside an except block, Python '
              'attaches the original to the new one as __context__ and prints '
              'both, separated by "During handling of the above exception, '
              'another exception occurred". That is implicit chaining, and it '
              'often means you accidentally raised while handling.',
            ),
            ProseBlock(
              'raise NewError(...) from original sets __cause__ instead, and '
              'the traceback reads "The above exception was the direct cause". '
              'Use it when you deliberately translate a low-level failure into '
              'your own vocabulary — the caller gets your exception type '
              'without losing the underlying reason. raise ... from None '
              'suppresses the chain entirely, which is occasionally right and '
              'usually hides evidence.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
class ConfigError(Exception):
    pass


def load(raw):
    try:
        return int(raw)
    except ValueError as exc:
        raise ConfigError(f"invalid port {raw!r}") from exc


try:
    load("http")
except ConfigError as exc:
    print(exc)                 # invalid port 'http'
    print(repr(exc.__cause__)) # ValueError("invalid literal for int() ...")
''',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'cleanup',
      heading: 'Cleanup with with',
      blocks: [
        ProseBlock(
          'Anything that must be released — a file handle, a lock, a database '
          'transaction — should be managed by a context manager rather than a '
          'finally block you have to remember to write. The with statement '
          'calls __enter__ on entry and __exit__ on exit, and __exit__ runs '
          'even if the body raised or returned.',
        ),
        ProseBlock(
          'The easiest way to write one is contextlib.contextmanager: '
          'everything before the yield is setup, everything after is teardown, '
          'and a try/finally around the yield guarantees the teardown runs. '
          'Since Python 3.10 a with statement can also take a parenthesised '
          'list of several managers.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from contextlib import contextmanager
import time


@contextmanager
def timed(label):
    start = time.perf_counter()
    try:
        yield                       # the body of the with block runs here
    finally:
        elapsed = time.perf_counter() - start
        print(f"{label} took {elapsed:.3f}s")


with timed("work"):
    total = sum(range(1_000_000))
# work took 0.019s  - printed even if the body raises


class Transaction:
    def __enter__(self):
        print("BEGIN")
        return self

    def __exit__(self, exc_type, exc, tb):
        print("ROLLBACK" if exc_type else "COMMIT")
        return False                # False: do not swallow the exception


try:
    with Transaction():
        raise ValueError("nope")
except ValueError:
    print("handled outside")        # BEGIN / ROLLBACK / handled outside
''',
          caption:
              'Returning False from __exit__ lets the exception propagate.',
        ),
        ProseBlock(
          'contextlib also has several ready-made managers worth knowing. '
          'contextlib.redirect_stdout captures print output to a file or '
          'StringIO. contextlib.suppress silently swallows specific '
          'exceptions — use it when a failure is genuinely irrelevant. And '
          'contextlib.ExitStack lets you manage a dynamic number of context '
          'managers, which is essential when you do not know at compile time '
          'how many resources you will need.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from contextlib import redirect_stdout, ExitStack, suppress
import io

# Capture all print output inside a block.
buffer = io.StringIO()
with redirect_stdout(buffer):
    print("captured")
    print("also captured")
print("output:", repr(buffer.getvalue()))
# output: 'captured\\nalso captured\\n'

# ExitStack: manage a variable number of files.
filenames = ["a.txt", "b.txt", "c.txt"]
with ExitStack() as stack:
    handles = [stack.enter_context(open(f, "w")) for f in filenames]
    for i, h in enumerate(handles):
        h.write(f"file {i}")
# All three files are closed when the block exits.

# suppress: swallow specific exceptions silently.
with suppress(FileNotFoundError):
    os.remove("nonexistent.txt")   # no error if the file doesn't exist
''',
          caption: 'redirect_stdout, ExitStack, and suppress for common patterns.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-err-narrow',
      title: 'Replace a catch-all with a real handler',
      prompt: [
        ProseBlock(
          'The function below hides every bug in the program: a typo in a '
          'variable name, a KeyboardInterrupt, an out-of-memory error — all '
          'become the string "error". Rewrite it so it handles exactly the two '
          'failures it can anticipate, returns None for a missing file, raises '
          'a ValueError with a helpful message for unparseable content, and '
          'lets anything else propagate.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def read_count(path):
    try:
        with open(path) as handle:
            return int(handle.read())
    except:
        return "error"
''',
        ),
      ],
      starterCode: '''
def read_count(path):
    try:
        with open(path) as handle:
            return int(handle.read())
    except:
        return "error"


print(read_count("missing.txt"))   # should be None
print(read_count("counts.txt"))    # should be an int, or raise ValueError
''',
      solutionCode: '''
def read_count(path):
    try:
        with open(path) as handle:
            raw = handle.read()
    except FileNotFoundError:
        return None

    try:
        return int(raw)
    except ValueError as exc:
        raise ValueError(f"{path} does not contain a number: {raw!r}") from exc


print(read_count("missing.txt"))   # None

# Anything unexpected - PermissionError, IsADirectoryError, a bug in this
# module - now reaches the caller with its original traceback intact.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why split the file read and the int conversion into two try '
              'blocks?',
          expectedAnswer:
              'So each block guards exactly one operation. With both inside one '
              'try, a ValueError could only be attributed to the conversion by '
              'assumption, and any future call added to the block would be '
              'silently covered by handlers written for something else.',
        ),
        SelfCheckQuestion(
          question:
              'What does "from exc" add here, given the message already '
              'explains the problem?',
          expectedAnswer:
              'It sets __cause__, so the traceback shows the original '
              'ValueError from int() as the direct cause. The caller gets a '
              'domain-level message and a debugger still sees exactly which '
              'low-level operation failed.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-err-custom',
      title: 'Design an exception for a small library',
      prompt: [
        ProseBlock(
          'Write a validation helper for a user record. Define ValidationError '
          'as the package base, and FieldMissing and FieldInvalid deriving from '
          'it, each carrying a field attribute. validate(record) should raise '
          'FieldMissing when "email" is absent and FieldInvalid when it '
          'contains no "@". A caller must be able to catch both with a single '
          'except ValidationError.',
        ),
      ],
      starterCode: '''
class ValidationError(Exception):
    ...


# TODO: FieldMissing and FieldInvalid, both carrying .field


def validate(record):
    # TODO: raise the right exception, or return the record
    ...


for record in [{"email": "a@b.com"}, {}, {"email": "nope"}]:
    try:
        print("ok:", validate(record))
    except ValidationError as exc:
        print(type(exc).__name__, exc.field, exc)
''',
      solutionCode: '''
class ValidationError(Exception):
    """Base class for every validation failure in this package."""

    def __init__(self, message, field):
        super().__init__(message)
        self.field = field


class FieldMissing(ValidationError):
    def __init__(self, field):
        super().__init__(f"{field} is required", field)


class FieldInvalid(ValidationError):
    def __init__(self, field, value):
        super().__init__(f"{field} is not valid: {value!r}", field)
        self.value = value


def validate(record):
    if "email" not in record:
        raise FieldMissing("email")
    if "@" not in record["email"]:
        raise FieldInvalid("email", record["email"])
    return record


for record in [{"email": "a@b.com"}, {}, {"email": "nope"}]:
    try:
        print("ok:", validate(record))
    except ValidationError as exc:
        print(type(exc).__name__, exc.field, exc)
# ok: {'email': 'a@b.com'}
# FieldMissing email email is required
# FieldInvalid email email is not valid: 'nope'
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why give the library one base exception class rather than '
              'raising built-ins like ValueError?',
          expectedAnswer:
              'It lets callers catch everything from this package with a single '
              'clause, without also catching unrelated ValueErrors from their '
              'own code or another library. Deriving from a sensible built-in '
              'as well — for example ValidationError(ValueError) — can give '
              'both behaviours at once.',
        ),
        SelfCheckQuestion(
          question:
              'Why store the field name as an attribute when it is already in '
              'the message?',
          expectedAnswer:
              'Because handlers need data, not prose. A caller can build an API '
              'response keyed by exc.field or highlight the offending form '
              'input; parsing the message string to recover it would be fragile '
              'and would break the moment the wording changes.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-err-context',
      title: 'Guarantee cleanup with a context manager',
      prompt: [
        ProseBlock(
          'Write a context manager called suppress_and_log(*exception_types) '
          'that runs its block, and if one of the listed exception types is '
          'raised, prints "suppressed: <exception>" and carries on instead of '
          'propagating. Any other exception must propagate normally. Use '
          'contextlib.contextmanager.',
        ),
      ],
      starterCode: '''
from contextlib import contextmanager


@contextmanager
def suppress_and_log(*exception_types):
    # TODO: yield, catch only the listed types, print and swallow them
    ...


with suppress_and_log(ZeroDivisionError):
    print(1 / 0)
print("still running")

with suppress_and_log(ZeroDivisionError):
    raise KeyError("boom")     # should NOT be suppressed
''',
      solutionCode: '''
from contextlib import contextmanager


@contextmanager
def suppress_and_log(*exception_types):
    try:
        yield
    except exception_types as exc:
        print(f"suppressed: {type(exc).__name__}: {exc}")


with suppress_and_log(ZeroDivisionError):
    print(1 / 0)
# suppressed: ZeroDivisionError: division by zero

print("still running")

try:
    with suppress_and_log(ZeroDivisionError):
        raise KeyError("boom")
except KeyError as exc:
    print("propagated:", exc)   # propagated: 'boom'
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'How does an exception raised in the with body reach the except '
              'clause inside the generator?',
          expectedAnswer:
              'The @contextmanager wrapper throws the exception into the '
              'generator at the point of the yield, so ordinary try/except '
              'around the yield sees it. If the generator swallows it, the with '
              'statement treats it as handled; if it escapes, it propagates.',
        ),
        SelfCheckQuestion(
          question:
              'contextlib already ships suppress(). When is writing your own '
              'still worthwhile?',
          expectedAnswer:
              'contextlib.suppress discards the exception silently, so use it '
              'when you genuinely do not care. Writing your own is worth it '
              'when you want to log, count or report what was suppressed — '
              'because a silently swallowed exception is indistinguishable from '
              'code that never ran.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-err-retry',
      title: 'Build a retry loop with exponential backoff',
      prompt: [
        ProseBlock(
          'Write retry_with_backoff(fn, max_attempts=3, base_delay=0.1) that '
          'calls fn() and retries on any Exception, doubling the delay each '
          'time. If all attempts fail, re-raise the last exception with a '
          'helpful message chained via "from". Use time.sleep for the delay '
          'and return the result on success.',
        ),
      ],
      starterCode: '''
import time


def retry_with_backoff(fn, max_attempts=3, base_delay=0.1):
    # TODO: loop up to max_attempts, with exponentially increasing delay
    ...


def always_fails():
    raise ConnectionError("no route to host")


try:
    retry_with_backoff(always_fails, max_attempts=3, base_delay=0.1)
except ConnectionError as exc:
    print("gave up:", exc)
''',
      solutionCode: '''
import time


def retry_with_backoff(fn, max_attempts=3, base_delay=0.1):
    last_exc = None
    for attempt in range(1, max_attempts + 1):
        try:
            return fn()
        except Exception as exc:
            last_exc = exc
            if attempt < max_attempts:
                delay = base_delay * (2 ** (attempt - 1))
                print(f"attempt {attempt} failed, retrying in {delay:.2f}s")
                time.sleep(delay)
    raise RuntimeError(f"all {max_attempts} attempts failed") from last_exc


def always_fails():
    raise ConnectionError("no route to host")


try:
    retry_with_backoff(always_fails, max_attempts=3, base_delay=0.1)
except RuntimeError as exc:
    print("gave up:", exc)
    print("caused by:", exc.__cause__)
# attempt 1 failed, retrying in 0.10s
# attempt 2 failed, retrying in 0.20s
# gave up: all 3 attempts failed
# caused by: no route to host
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question: 'Why chain with "from last_exc" instead of just raising '
              'RuntimeError?',
          expectedAnswer:
              'Without "from", the traceback would show RuntimeError with no '
              'connection to the underlying failure, making debugging harder. '
              'The chain preserves the full evidence: "all attempts failed '
              'BECAUSE of ConnectionError".',
        ),
        SelfCheckQuestion(
          question:
              'Why catch Exception rather than BaseException?',
          expectedAnswer:
              'BaseException includes KeyboardInterrupt and SystemExit. '
              'Retrying on Ctrl-C would hang the program — the user is '
              'explicitly asking it to stop, and that intent must be '
              'respected.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-err-exitstack',
      title: 'Manage dynamic resources with ExitStack',
      prompt: [
        ProseBlock(
          'Write open_files(paths) that takes a list of file paths, opens '
          'all of them for writing using contextlib.ExitStack, and returns '
          'the list of file handles. If any open fails, all previously '
          'opened files must be closed automatically. Do not write a '
          'try/finally by hand.',
        ),
      ],
      starterCode: '''
from contextlib import ExitStack


def open_files(paths):
    # TODO: use ExitStack to open all files; clean up on any failure
    ...


try:
    handles = open_files(["a.txt", "b.txt", "/root/forbidden.txt"])
except PermissionError as exc:
    print("failed:", exc)
# a.txt and b.txt must be closed by the time this runs.
''',
      solutionCode: '''
from contextlib import ExitStack


def open_files(paths):
    with ExitStack() as stack:
        return [stack.enter_context(open(p, "w")) for p in paths]
    # When the with block exits, all files opened so far are closed.
    # If open() raises, ExitStack immediately closes any files already opened
    # by earlier iterations, then propagates the exception.


try:
    handles = open_files(["a.txt", "b.txt", "/root/forbidden.txt"])
except PermissionError as exc:
    print("failed:", exc)
# a.txt and b.txt were created, written, and closed before the exception
# reached the caller.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'How does ExitStack ensure earlier files are closed when a '
              'later open() fails?',
          expectedAnswer:
              'ExitStack.__exit__ is called as soon as the with block is left — '
              'including when an exception propagates. It calls __exit__ on '
              'every context manager that was entered, in reverse order. A '
              'file\'s __exit__ closes it, so every successfully opened file '
              'is guaranteed to be closed.',
        ),
        SelfCheckQuestion(
          question:
              'What would happen without ExitStack, using a plain list and '
              'a try/finally?',
          expectedAnswer:
              'You would need to track which files were successfully opened '
              'and close only those, while also handling the case where '
              'closing itself raises. ExitStack does all of this correctly '
              'and is the standard solution for the "open N resources '
              'atomically" problem.',
        ),
      ],
    ),
  ],
);

const GameContent _play = GameContent(
  games: [
    BugHuntGame(
      id: 'game-errors-bare-except',
      title: 'Find the bare except',
      instructions: 'Tap the line that catches more than it should.',
      code: '''
def load(raw):
    try:
        return int(raw)
    except:
        print("bad value")
        return None
''',
      buggyLine: 4,
      explanation:
          'A bare except: also catches KeyboardInterrupt and SystemExit, so '
          'it can swallow Ctrl-C and an orderly shutdown. Name the specific '
          'exception you expect, here ValueError.',
      fixedCode: '''
def load(raw):
    try:
        return int(raw)
    except ValueError:
        print("bad value")
        return None
''',
    ),
    FillBlankGame(
      id: 'game-errors-try-shape',
      title: 'Complete the try statement',
      instructions: 'Type the two missing clause keywords, in order.',
      code: '''
try:
    port = int(raw)
except ValueError:
    return None
______:
    print("parsed cleanly")
    return port
______:
    print("done")
''',
      blanks: [
        Blank(answer: 'else', hint: 'runs only on success'),
        Blank(answer: 'finally', hint: 'always runs'),
      ],
    ),
    OutputPredictorGame(
      id: 'game-errors-try-order',
      title: 'What does this print?',
      instructions: 'Pick the order these lines print in.',
      code: '''
def f():
    try:
        print("try")
    except ValueError:
        print("except")
    else:
        print("else")
    finally:
        print("finally")


f()
''',
      options: [
        'try / except / finally',
        'try / else / finally',
        'try / finally',
        'try / except / else / finally',
      ],
      correctIndex: 1,
      explanation:
          'Nothing raises, so except is skipped entirely. else runs because '
          'the try block succeeded, and finally always runs last regardless '
          'of what happened above it.',
    ),
    SyntaxScrambleGame(
      id: 'game-errors-scramble',
      title: 'Rebuild the custom exception',
      instructions: 'Drag or use the arrows to put these lines back in order.',
      lines: [
        'class ConfigError(Exception):',
        '    pass',
        'def require(config, key):',
        '    if key not in config:',
        '        raise ConfigError(key)',
        '    return config[key]',
      ],
    ),
    TermMatchGame(
      id: 'game-errors-terms',
      title: 'Match the vocabulary',
      instructions: 'Tap a term, then tap its definition.',
      pairs: [
        TermPair(
          term: 'Exception hierarchy',
          definition: 'Exceptions are classes, so except also catches subclasses.',
        ),
        TermPair(
          term: 'EAFP',
          definition: 'Try the operation and handle failure, rather than pre-checking.',
        ),
        TermPair(
          term: 'Exception chaining',
          definition: 'Linking a new exception to the one that caused it.',
        ),
        TermPair(
          term: 'Bare raise',
          definition: 'raise with no argument, re-raising the current exception.',
        ),
        TermPair(
          term: 'finally',
          definition: 'A clause that runs whether the try block failed or not.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 210000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Error handling, condensed. Here\'s the analogy that makes exceptions click: think of '
              'exceptions like a fire alarm system that tells you exactly which room is burning instead '
              'of just making noise. Exceptions are objects arranged in a class hierarchy — like a family '
              'tree where catching a parent catches all its children too. An except clause catches the '
              'class you name plus everything below it. That single fact decides all your handling '
              'strategy: catch precisely, and your code documents exactly which failure you expected '
              'and planned for. Catch broadly, and you\'re hiding bugs you don\'t even know exist.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'So here\'s the discipline: keep the try block tiny — one risky operation, like holding '
              'only the egg you might drop, not the entire carton. Put the code that depends on success '
              'in the else clause — "everything went fine, now let\'s use the result." Put anything that '
              'must happen either way in finally — "whether we succeed or fail, close the door on the way '
              'out." These four keywords — try, except, else, finally — each have exactly one job, and '
              'using them properly makes your error handling read like clear documentation rather than '
              'defensive noise.',
          startMs: 44000,
          endMs: 92000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'One rule to tattoo on your brain: never write a bare "except:". Ever. It catches '
              'KeyboardInterrupt and SystemExit too — so Ctrl-C stops working and your program can\'t even '
              'shut down cleanly. It\'s like soundproofing your entire house because the smoke detector is '
              'annoying — sure, you can\'t hear the alarm anymore, but you also can\'t hear someone knocking '
              'on the door. If you genuinely need a catch-all safety net, catch Exception, log what happened, '
              'and re-raise unless you have a documented, commented reason not to.',
          startMs: 92000,
          endMs: 134000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Python has a philosophy here that\'s different from many languages: EAFP — Easier to Ask '
              'Forgiveness than Permission. Instead of checking "does this file exist?" and then opening it, '
              'just open it and handle the FileNotFoundError if it happens. Why? Because between the check '
              'and the action, the world can change — the file could be deleted, the key removed, the '
              'connection dropped. Plus, try/except costs essentially nothing when no exception is raised. '
              'It\'s like learning to ride a bike: you WILL fall. What matters isn\'t avoiding every fall — '
              'it\'s knowing how to get back up, brush yourself off, and keep going.',
          startMs: 134000,
          endMs: 178000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And when you translate a low-level error into your own domain-specific exception, use '
              '"raise NewError from original". This chains them together so the traceback says "the above '
              'was the direct cause" — the original evidence stays attached. Cleanup — closing files, '
              'releasing locks, rolling back transactions — belongs in a context manager with a with '
              'statement, not in a finally block scattered across your codebase. Make the cleanup '
              'reusable, not something you have to remember to copy-paste every time.',
          startMs: 178000,
          endMs: 210000,
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
              'Exceptions today, and I want to reframe them at the start because too many people treat '
              'them as something to fear. In a lot of languages, an exception is an emergency — something '
              'went catastrophically wrong. In Python, exceptions are ordinary control flow. StopIteration '
              'ends every single for loop you\'ve ever written — that\'s not a crash, that\'s the loop saying '
              '"I\'m done." So the question is never "how do I avoid exceptions." It\'s "which failures do I '
              'anticipate, and where in my program is the right place to handle them?" It\'s like driving a '
              'car: you don\'t try to avoid ever touching the brake pedal. You learn when and how to brake '
              'effectively.',
          startMs: 0,
          endMs: 58000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The machinery is refreshingly simple. Raising an exception unwinds the call stack frame '
              'by frame — like peeling layers of an onion — until some try block says "I\'ll handle this." '
              'If nothing does, the interpreter prints a traceback and exits with a non-zero status code. '
              'Exceptions are classes, which is the key insight: an except clause catches the named class '
              'and every subclass of it. So "except LookupError" catches both KeyError and IndexError in '
              'one clause because they\'re both children of LookupError. It\'s a family tree, and catching '
              'the parent nets you all the kids.',
          startMs: 58000,
          endMs: 122000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Which makes the hierarchy worth actually learning — it\'s not just academic trivia. '
              'ValueError means "right type, wrong value" — like int("hello"). TypeError means "wrong type '
              'entirely" — like adding a string to an integer. LookupError is the parent of both KeyError '
              'and IndexError, so one handler can catch both missing dict keys and out-of-range list '
              'accesses. OSError covers file and network problems and carries an errno attribute with the '
              'operating system\'s error code. And everything an application should normally catch lives '
              'under Exception — that\'s your safety net\'s safety net.',
          startMs: 122000,
          endMs: 190000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Above Exception sits BaseException, and this is where you need to pay attention. '
              'BaseException also parents KeyboardInterrupt — that\'s Ctrl-C — SystemExit — that\'s '
              'sys.exit() — and GeneratorExit. These aren\'t errors. They\'re the program being politely '
              'asked to stop what it\'s doing. That\'s exactly why a bare "except:" is a bug, not a style '
              'choice: it catches those too, and suddenly pressing Ctrl-C does absolutely nothing. Your '
              'program just sits there, ignoring the user frantically trying to stop it. Always catch '
              'Exception or something more specific.',
          startMs: 190000,
          endMs: 250000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'On structure: keep the try block down to the single operation that can fail. Not two '
              'operations, not three — one. Everything that depends on success goes in else. Cleanup goes '
              'in finally, which runs even when the block returns or raises — it\'s the "no matter what" '
              'clause. This discipline stops the most insidious debugging scenario: catching a KeyError '
              'from your own follow-up code and mistakenly blaming the operation you were guarding. The '
              'bug isn\'t where the traceback says it is, and you waste hours chasing a phantom.',
          startMs: 250000,
          endMs: 316000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'When you write your own exceptions, give your package a single base class and derive '
              'everything from it. Why? So a user of your library can catch everything your code raises '
              'with one clause: "except MyLibError." Put structured detail on the exception object — the '
              'field name that was missing, the file path that couldn\'t be read, the HTTP status code '
              'that came back — because handlers need data to make decisions, and parsing your error '
              'message string with regex is not an API. Think of custom exceptions like well-designed '
              'error reports, not just error messages.',
          startMs: 316000,
          endMs: 384000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Then chaining — the feature people discover too late. If you catch a low-level error — '
              'a ValueError from int() — and raise your own domain error, write "raise MyError(...) from '
              'original". The traceback then explicitly says "the above was the direct cause" and nobody '
              'has to guess where the real problem originated. A bare "raise" inside an except block '
              're-raises the current exception with its original traceback perfectly intact — much better '
              'than raising a fresh copy of the same exception, which would lose the original stack trace '
              'and make debugging nearly impossible. The traceback is evidence; preserve it.',
          startMs: 384000,
          endMs: 442000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And put cleanup in a context manager. Files, locks, database transactions, temporary '
              'directories — all of it belongs inside a "with" block. contextlib.contextmanager makes '
              'writing one about five lines: setup before yield, teardown after yield in a finally block. '
              'It\'s like having an automatic cleanup crew that shows up whether your party was a success '
              'or a disaster. The "with" statement guarantees __exit__ runs even if the body raised, '
              'returned, or was interrupted. Once you start using context managers for all resource '
              'management, you\'ll wonder why you ever wrote a bare try/finally by hand.',
          startMs: 442000,
          endMs: 480000,
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
              'The long version on exceptions — we\'re going to understand error handling not as a '
              'chore but as a design tool. Here\'s the mental model: exceptions are like a fire alarm '
              'system with a detailed display panel. A bad alarm just screams — you know something is '
              'wrong but not what. A good alarm tells you "smoke detected in server room B, temperature '
              'rising" so you can respond precisely. That\'s what a well-designed exception hierarchy '
              'gives you. Today we\'re covering the hierarchy in detail, the cost model that explains '
              'why try/except is faster than if/else on the happy path, chaining and tracebacks, EAFP '
              'versus LBYL and why it\'s actually about race conditions rather than style, exception '
              'groups for concurrent failures, and how to decide where in a system a failure should '
              'be handled at all.',
          startMs: 0,
          endMs: 64000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with the tree — this is the map you\'ll navigate for your entire Python career. '
              'BaseException is the root of everything. Directly under it are four branches: SystemExit '
              '(raised by sys.exit()), KeyboardInterrupt (Ctrl-C), GeneratorExit (when a generator is '
              'closed), and Exception — the branch where all normal errors live. Everything an application '
              'should normally catch is under Exception. The other three signal that the program or a '
              'generator is being shut down, and swallowing them turns what should be a clean exit into '
              'a hung process. It\'s like the difference between a "stop" sign and a "road closed" barrier '
              '— you handle them very differently.',
          startMs: 64000,
          endMs: 146000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Under Exception, the useful groupings give you leverage. ArithmeticError is the parent '
              'of ZeroDivisionError and OverflowError — catch the parent and you handle any math gone '
              'wrong. LookupError sits above IndexError and KeyError — one handler for any "thing not '
              'found" scenario. OSError absorbed the old IOError and now has wonderfully specific '
              'subclasses: FileNotFoundError, PermissionError, TimeoutError, ConnectionError — each '
              'mapped from the operating system\'s errno codes. Catch the subclass when you know exactly '
              'what you expect ("this file might not exist"), catch the parent when several siblings '
              'genuinely share the same handling ("any OS-level problem gets logged and retried").',
          startMs: 146000,
          endMs: 240000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Now the cost model, because it\'s what drives the whole EAFP philosophy and everyone gets '
              'it wrong. Entering a try block is essentially free in modern CPython — since 3.11, there\'s '
              'zero overhead on the non-raising path because the handler information lives in a side table '
              'that the interpreter only consults when an exception actually occurs. Raising and catching '
              'is not free: building the exception object and its traceback costs roughly a microsecond. '
              'So exceptions are cheap for the exceptional case and terrible as a loop mechanism — don\'t '
              'use raise/except as a replacement for if/else in a tight loop. But for guarding an '
              'operation that normally succeeds? The try block costs you literally nothing.',
          startMs: 240000,
          endMs: 336000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Which brings us to LBYL — Look Before You Leap — and why it\'s actually about correctness, '
              'not just style preference. The real objection to "if the file exists: open the file" isn\'t '
              'verbosity — it\'s the race condition. Between checking and acting, another process can '
              'delete the file. Between "if key in dict" and reading it, another thread can pop that key. '
              'The check doesn\'t prevent the failure; it just makes the window between check and action '
              'slightly narrower. You still need the error handler anyway, and now you have two code paths '
              'to maintain. It\'s like checking if a parking spot is empty from a block away — by the time '
              'you arrive, someone else may have taken it. Just drive up and handle it if it\'s occupied.',
          startMs: 336000,
          endMs: 424000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Chaining is the next thing people dramatically under-use, and it\'s one of Python\'s best '
              'features. If you raise inside an except block, Python automatically sets __context__ on '
              'the new exception linking it to the original, and prints "During handling of the above '
              'exception, another exception occurred." That usually means you made a mistake while '
              'handling — your handler itself crashed. When you say "raise NewError(...) from original", '
              'Python sets __cause__ instead and prints "The above exception was the direct cause." '
              'That means you deliberately translated a low-level failure into your own vocabulary. '
              'The first reads like an accident; the second reads like intentional design.',
          startMs: 424000,
          endMs: 512000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'And there\'s "raise X from None" which suppresses the chain entirely. It has a legitimate '
              'use — hiding irrelevant internal implementation details at a library boundary so users '
              'don\'t see traces of your private helper functions. But every time you use it, you are '
              'actively deleting evidence that someone — possibly future you at 3 AM — will desperately '
              'want. Default to keeping the cause chain intact. Only suppress it when the internals would '
              'genuinely confuse rather than help. The traceback is a story; don\'t rip out the chapters '
              'unless they\'re in a language the reader doesn\'t speak.',
          startMs: 512000,
          endMs: 580000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Python 3.11 added exception groups and except*, and this was a genuinely necessary '
              'evolution. When concurrent operations fail — say five tasks in a TaskGroup, three of '
              'which raise different exceptions — a single exception object cannot represent that reality. '
              'ExceptionGroup wraps them all together like a bundle. except* lets you handle each type '
              'present in the group, pulling out the ones you can deal with and letting the rest continue '
              'propagating as a smaller regrouped set. It\'s like sorting mail: "I\'ll handle all the '
              'bills, send the letters to the living room, and the junk mail goes straight to recycling." '
              'This is the error handling equivalent of structured concurrency — failures have structure '
              'too.',
          startMs: 580000,
          endMs: 668000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'On placement — where should you actually handle exceptions? The answer is almost never '
              '"right where they happened." Handle an exception where you can actually do something '
              'meaningful about it. That\'s usually far up the call stack — a request handler that can '
              'return a 500, a retry loop that can try again, a command-line entry point that can print '
              'a user-friendly message and exit. A try/except that catches, logs, and re-raises at every '
              'intermediate level produces five separate traceback fragments for one failure and helps '
              'exactly nobody. Let exceptions bubble up to the level that has context to make a decision. '
              'It\'s like a company: the intern shouldn\'t decide strategy, and the CEO shouldn\'t fix the '
              'printer. Each level handles what it has authority and context for.',
          startMs: 668000,
          endMs: 750000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Two rules to finish, and they\'ve saved me more times than I can count. First: never let '
              'an except body be just "pass" — the silent exception swallower. Unless you have written '
              'a clear comment explaining exactly why this specific failure is genuinely, provably '
              'irrelevant, it\'s a bug waiting to happen. Second: use assert only for programmer errors '
              '— "this should be mathematically impossible" — never for validating user input or external '
              'data. Assertions are stripped entirely when Python runs with the -O (optimize) flag, '
              'which means your production deployment might be running without your safety checks. That\'s '
              'not a bug — it\'s a design choice built into the language. Validate with if/raise, assert '
              'for invariants.',
          startMs: 750000,
          endMs: 834000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Catch precisely, at the right level',
      body:
          'An except clause catches the named class and all its subclasses, so '
          'the class you name documents the failure you expected. Handle it '
          'where you can actually do something about it — usually far up the '
          'stack — and let everything else propagate.',
    ),
    SummaryCard(
      title: 'try / except / else / finally each have one job',
      body:
          'try holds only the risky operation, except handles one anticipated '
          'failure, else holds the code that depends on success, and finally '
          'runs on every path including returns. Keeping them separate stops '
          'you misattributing an exception.',
    ),
    SummaryCard(
      title: 'EAFP over LBYL',
      body:
          'Attempt the operation and handle the failure rather than checking '
          'preconditions first. Check-then-act contains a race — the file can '
          'vanish between the two — and try costs nothing when nothing is '
          'raised.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Exception hierarchy',
      definition:
          'Exceptions are classes: BaseException at the root, Exception below '
          'it for ordinary errors, and groupings such as LookupError and '
          'OSError that let one clause catch related failures.',
    ),
    KeyConcept(
      term: 'EAFP',
      definition:
          '"Easier to Ask Forgiveness than Permission" — perform the operation '
          'inside try and handle the specific failure, instead of testing '
          'preconditions that can change before you act.',
    ),
    KeyConcept(
      term: 'Exception chaining',
      definition:
          'Raising inside a handler links the exceptions: implicitly via '
          '__context__, or explicitly with "raise New from old", which sets '
          '__cause__ and reports the original as the direct cause.',
    ),
    KeyConcept(
      term: 'Bare raise',
      definition:
          'A raise statement with no argument inside an except block, which '
          're-raises the current exception with its original traceback rather '
          'than starting a new one.',
    ),
    KeyConcept(
      term: 'finally',
      definition:
          'A clause that runs whether the try block succeeded, raised or '
          'returned. Used for cleanup, though a context manager is usually the '
          'better expression of the same idea.',
    ),
    KeyConcept(
      term: 'Context manager',
      definition:
          'An object with __enter__ and __exit__ (or a generator decorated with '
          '@contextmanager) that the with statement uses to guarantee setup and '
          'teardown around a block.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake: 'Writing "except:" or "except Exception: pass".',
      correction:
          'A bare except also catches KeyboardInterrupt and SystemExit, and a '
          'silent pass turns every bug into invisible behaviour. Name the '
          'exception you expect; if you must catch broadly, log it and re-raise '
          'unless you can explain in a comment why swallowing is correct.',
    ),
    Mistake(
      mistake:
          'Wrapping a whole function body in one try so several operations '
          'share a single handler.',
      correction:
          'You can no longer tell which call raised, and later additions to the '
          'block get covered by handlers not written for them. Keep the try '
          'around the single risky operation and move the rest into else.',
    ),
    Mistake(
      mistake:
          'Catching a low-level error and raising your own without "from".',
      correction:
          'Python attaches the original as __context__, which reads as an '
          'accident. Use "raise MyError(...) from exc" so the traceback names '
          'the real cause deliberately.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'What is the difference between the else and finally clauses of a '
          'try statement?',
      answer:
          'else runs only when the try block completed without raising, and it '
          'is where the success path belongs so that its own exceptions are not '
          'caught by handlers meant for the guarded operation. finally runs on '
          'every path — success, exception, break, continue or return — and is '
          'for cleanup that must happen regardless. A return inside finally '
          'even overrides a return or exception from the try block, which is a '
          'good reason not to put one there.',
    ),
    InterviewQuestion(
      question: 'Why is catching BaseException almost always wrong?',
      answer:
          'BaseException is the parent of SystemExit, KeyboardInterrupt and '
          'GeneratorExit, which are not errors but requests to stop. Catching '
          'them means Ctrl-C is ignored, sys.exit() does not exit, and '
          'generators cannot be closed cleanly. Application code should catch '
          'Exception at the broadest, and normally something far more '
          'specific.',
    ),
    InterviewQuestion(
      question:
          'Explain EAFP versus LBYL with an example where the difference is a '
          'correctness issue, not a style preference.',
      answer:
          'Checking os.path.exists before opening a file is LBYL, and it has a '
          'time-of-check to time-of-use race: another process can delete or '
          'replace the file in the gap, so you still need the FileNotFoundError '
          'handler and now have two code paths. The EAFP version just opens the '
          'file inside try and catches the error, which is atomic from the '
          'caller\'s point of view. The same applies to checking a dict key '
          'that another thread may pop.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: '8. Errors and Exceptions — Python Docs',
    url: 'https://docs.python.org/3/tutorial/errors.html',
    description:
        'Tutorial chapter on syntax errors versus exceptions, handling, '
        'raising, user-defined exceptions, cleanup actions and exception '
        'groups.',
  ),
  Source(
    title: 'Built-in Exceptions — Python Docs',
    url: 'https://docs.python.org/3/library/exceptions.html',
    description:
        'Reference for every built-in exception, including the full class '
        'hierarchy and the OSError subclasses mapped from errno values.',
  ),
];

const List<Source> _furtherReading = [
  Source(
    title: 'Context Manager Types — Python Docs',
    url: 'https://docs.python.org/3/library/contextlib.html',
    description:
        'Reference for contextlib.contextmanager, ExitStack, redirect_stdout, '
        'suppress, closing, and other context manager utilities.',
  ),
  Source(
    title: 'Python Exceptions: An Introduction — Real Python',
    url: 'https://realpython.com/python-exceptions/',
    description:
        'Guided tour of try/except/else/finally, raising, custom exceptions, '
        'and the EAFP vs LBYL philosophy.',
  ),
  Source(
    title: 'How to Write Beautiful Python Code With Exception Handling — Real Python',
    url: 'https://realpython.com/python-exceptions-best-practices/',
    description:
        'Concrete patterns: narrow try blocks, meaningful messages, structured '
        'exception attributes, and chaining with raise ... from.',
  ),
  Source(
    title: 'PEP 654 – Exception Groups and except*',
    url: 'https://peps.python.org/pep-0654/',
    description:
        'The proposal introducing ExceptionGroup and except* for handling '
        'multiple concurrent exceptions in structured concurrency.',
  ),
];
