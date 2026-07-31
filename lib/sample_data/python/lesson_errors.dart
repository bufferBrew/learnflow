import '../../models/content_block.dart';
import '../../models/exercise.dart';
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
              'Error handling, condensed. Exceptions are objects arranged in a '
              'class hierarchy, and an except clause catches the class you name '
              'plus everything below it. That is the fact that decides all your '
              'handling: catch precisely, and you have documented which failure '
              'you expected.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'So keep the try block tiny — one risky operation. Put the code '
              'that depends on success in the else clause, and anything that '
              'must happen either way in finally. Those four keywords each have '
              'exactly one job, and using them properly makes the handling read '
              'as documentation.',
          startMs: 44000,
          endMs: 92000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Never write a bare except. It catches KeyboardInterrupt and '
              'SystemExit too, so it eats Ctrl-C and orderly shutdown. If you '
              'really need a net, catch Exception, log it, and re-raise unless '
              'you have a genuine reason not to.',
          startMs: 92000,
          endMs: 134000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Python prefers asking forgiveness to asking permission. Just do '
              'the operation and handle the failure, rather than checking first '
              '— because between the check and the action the world can change, '
              'and because try costs nothing when nothing goes wrong.',
          startMs: 134000,
          endMs: 178000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And when you translate a low-level error into your own, use '
              'raise from, so the original stays attached as the cause. Cleanup '
              'belongs in a context manager, not in a finally block you have to '
              'remember to write.',
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
              'Exceptions today, and I want to reframe them at the start. In a '
              'lot of languages an exception is an emergency. In Python it is '
              'ordinary control flow — StopIteration ends every for loop you '
              'have ever written. So the question is never "how do I avoid '
              'exceptions", it is "which failures do I anticipate, and where do '
              'I handle them".',
          startMs: 0,
          endMs: 58000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The machinery is simple. Raising an exception unwinds the stack '
              'frame by frame until some try block is willing to handle it. If '
              'nothing is, the interpreter prints a traceback and exits with a '
              'non-zero status. Exceptions are classes, so an except clause '
              'catches the named class and every subclass of it.',
          startMs: 58000,
          endMs: 122000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Which makes the hierarchy worth learning. ValueError: right '
              'type, wrong value. TypeError: wrong type entirely. LookupError '
              'is the parent of KeyError and IndexError, so you can catch both '
              'at once. OSError covers file and network problems and carries an '
              'errno. And everything you should be catching lives under '
              'Exception.',
          startMs: 122000,
          endMs: 190000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Above Exception sits BaseException, which also has '
              'KeyboardInterrupt, SystemExit and GeneratorExit under it. Those '
              'are not errors — they are the program being asked to stop. That '
              'is exactly why a bare except is a bug: it catches those too, and '
              'suddenly Ctrl-C does nothing.',
          startMs: 190000,
          endMs: 250000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'On structure: keep the try block down to the single operation '
              'that can fail. Everything that depends on success goes in else. '
              'Cleanup goes in finally, which runs even when the block returns '
              'or raises. That discipline stops you catching a KeyError from '
              'your own follow-up code and blaming the operation you were '
              'guarding.',
          startMs: 250000,
          endMs: 316000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'When you write your own exceptions, give the package a single '
              'base class and derive the rest from it, so a user can catch '
              'everything from your library in one clause. Put structured '
              'detail on the object — the field name, the path, the status code '
              '— because handlers need data, and parsing your message string is '
              'not an API.',
          startMs: 316000,
          endMs: 384000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Then chaining. If you catch a low-level error and raise your own '
              'domain error, write raise MyError from the original. The '
              'traceback then says "the above was the direct cause" and nobody '
              'has to guess. A bare raise inside an except block re-raises with '
              'the original traceback fully intact — much better than raising a '
              'fresh copy.',
          startMs: 384000,
          endMs: 442000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And put cleanup in a context manager. Files, locks, '
              'transactions, temporary directories — all of it. '
              'contextlib.contextmanager makes writing one about five lines: '
              'setup, yield, teardown in a finally.',
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
              'The long version on exceptions. We will cover the hierarchy in '
              'detail, the cost model, chaining and tracebacks, EAFP versus '
              'LBYL and why it is about races rather than style, exception '
              'groups, and how to decide where in a system a failure should be '
              'handled at all.',
          startMs: 0,
          endMs: 64000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with the tree. BaseException is the root. Directly under '
              'it are SystemExit, KeyboardInterrupt, GeneratorExit and '
              'Exception. Everything an application should normally catch is '
              'under Exception; the other three signal that the program or a '
              'generator is being shut down, and swallowing them turns a clean '
              'exit into a hang.',
          startMs: 64000,
          endMs: 146000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Under Exception the useful groupings are ArithmeticError over '
              'ZeroDivisionError and OverflowError, LookupError over IndexError '
              'and KeyError, and OSError which absorbed the old IOError and '
              'now has friendly subclasses like FileNotFoundError, '
              'PermissionError and TimeoutError. Catch the subclass when you '
              'know exactly what you expect, the parent when several siblings '
              'genuinely share handling.',
          startMs: 146000,
          endMs: 240000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Now the cost model, because it drives the EAFP preference. '
              'Entering a try block is essentially free in modern CPython — '
              'since 3.11 there is zero cost on the non-raising path, the '
              'handler information lives in a side table. Raising and catching '
              'is not free: building the exception and its traceback costs '
              'roughly a microsecond. So exceptions are cheap for the '
              'exceptional case and bad as a loop mechanism.',
          startMs: 240000,
          endMs: 336000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Which brings us to look-before-you-leap. The real objection is '
              'not verbosity, it is the race. Between "if the file exists" and '
              '"open the file", another process can delete it. Between "if the '
              'key is in the dict" and reading it, another thread can pop it. '
              'The check does not prevent the failure; it just makes you write '
              'the handler anyway, or ship a bug.',
          startMs: 336000,
          endMs: 424000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Chaining is the next thing people under-use. Raise inside an '
              'except block and Python sets dunder-context automatically, which '
              'prints as "during handling of the above exception". Say raise X '
              'from Y and it sets dunder-cause, which prints as "the above was '
              'the direct cause". The first usually means you made a mistake '
              'while handling; the second means you translated deliberately.',
          startMs: 424000,
          endMs: 512000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'And there is raise X from None, which suppresses the chain. It '
              'has a legitimate use — hiding irrelevant internals from a '
              'library boundary — but every time you use it you are deleting '
              'evidence someone will want at three in the morning. Default to '
              'keeping the cause.',
          startMs: 512000,
          endMs: 580000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Python 3.11 added exception groups and except-star. When a '
              'concurrent operation fails in several ways at once — say five '
              'tasks in a task group, three of which raise — a single exception '
              'cannot represent that. ExceptionGroup holds them all and '
              'except-star lets you handle each type present, leaving the rest '
              'to propagate as a smaller group.',
          startMs: 580000,
          endMs: 668000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'On placement: handle an exception where you can actually do '
              'something about it. That is usually far up the stack — a request '
              'handler, a retry loop, a command-line entry point — not in the '
              'function that raised. A try/except that catches, logs and '
              're-raises at every level produces five traceback fragments for '
              'one failure and helps nobody.',
          startMs: 668000,
          endMs: 750000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Two rules to finish. Never let an except body be just "pass" '
              'unless you have written a comment explaining why the failure is '
              'genuinely irrelevant. And use assert only for programmer errors '
              'you never expect, never for validating input — assertions are '
              'stripped entirely when Python runs with the -O flag.',
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
