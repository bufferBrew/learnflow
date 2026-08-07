import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 2: how Python decides what runs next.
const Lesson controlFlowLesson = Lesson(
  id: 'py-control-flow',
  title: 'Control Flow',
  description:
      'Branching, looping and pattern matching — how Python decides which '
      'statement runs next.',
  estimatedMinutes: 28,
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
      id: 'branching',
      heading: 'Branching with if, elif and else',
      blocks: [
        ProseBlock(
          'Straight-line code runs top to bottom. Control flow is everything '
          'that breaks that line: a condition that skips a block, a loop that '
          'repeats one, a branch that picks between several. Python keeps the '
          'syntax deliberately small — if, elif, else, for, while, break, '
          'continue and match are very nearly the whole vocabulary.',
        ),
        ProseBlock(
          'An if statement evaluates its condition once and runs the first '
          'branch whose condition is true. elif is not sugar for a nested if: '
          'the chain stops at the first match, so later conditions are never '
          'evaluated. That matters when a later condition would be expensive, '
          'or would raise on the values that an earlier branch has already '
          'caught.',
        ),
        ProseBlock(
          'Indentation is the block delimiter. There are no braces, so the '
          'shape of the code on screen is the shape the interpreter sees — a '
          'misindented line is a different program, not a style complaint.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def grade(score):
    if score >= 90:
        return "A"
    elif score >= 80:
        return "B"
    elif score >= 70:
        return "C"
    else:
        return "F"


print(grade(95))   # A
print(grade(83))   # B
print(grade(12))   # F

# Chained comparison: reads like maths, evaluates each operand once.
age = 34
if 18 <= age < 65:
    print("working age")
''',
          caption:
              'The first true branch wins; the rest are never evaluated.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Order your conditions from most specific to least',
          text:
              'Because elif stops at the first match, a broad condition placed '
              'early swallows every narrower case below it. If score >= 70 came '
              'first, no score would ever be graded A.',
        ),
        ProseBlock(
          'A guard clause is an if at the top of a function that bails out '
          'early on an edge case — invalid input, a missing argument, a '
          'boundary condition. It keeps the "happy path" at one indentation '
          'level and avoids the deep nesting that makes conditions hard to '
          'follow. This is arguably the single most important readability '
          'pattern in control flow.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Deep nesting: the happy path is buried under three indentation levels.
def process(order):
    if order is not None:
        if order.total > 0:
            if order.status == "pending":
                # Finally, the actual logic.
                order.fulfill()

# Guard clauses: bail out early, happy path stays at the top level.
def process(order):
    if order is None:
        return
    if order.total <= 0:
        raise ValueError("order must have a positive total")
    if order.status != "pending":
        return
    # Clear, un-nested logic follows.
    order.fulfill()

# Ternary expression: a single if/else that fits on one line.
status = "passed" if score >= 70 else "failed"
print(status)
''',
          caption: 'Guard clauses flatten logic; ternary for one-line branches.',
        ),
      ],
    ),
    Section(
      id: 'truthiness',
      heading: 'Truthiness: what counts as false',
      blocks: [
        ProseBlock(
          'A condition does not have to be a bool. Python asks any object '
          'whether it is truthy, and the rule is short: False, None, zero of '
          'any numeric type, and every empty container or string are falsy. '
          'Everything else — including the string "False" and the list [0] — '
          'is truthy.',
        ),
        ProseBlock(
          'The boolean operators and/or return one of their operands rather '
          'than a bool, and they short-circuit: and stops at the first falsy '
          'operand, or stops at the first truthy one. That is why '
          'name = user_name or "anonymous" works as a default, and why '
          'if data and data[0] is safe on an empty list.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
values = []
if not values:
    print("nothing to process")     # empty list is falsy

print(bool(0), bool(0.0), bool(""), bool([]), bool({}), bool(None))
# False False False False False False

print(bool("False"), bool([0]), bool(" "))   # True True True

# Short-circuiting: the right side is only evaluated when needed.
user_name = ""
display = user_name or "anonymous"
print(display)                      # anonymous

def expensive():
    print("called")
    return True

if False and expensive():           # expensive() never runs
    pass
''',
          caption: 'Falsy values, and operators that return operands.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Falsy is not the same as missing',
          text:
              'if not count: fires for 0 as well as for None. When zero is a '
              'legitimate value, test explicitly with if count is None: — '
              'otherwise a valid zero silently takes the "missing" branch.',
        ),
        ProseBlock(
          'Python resolves truthiness by calling __bool__ first, and falling '
          'back to __len__ if __bool__ is not defined — zero length means '
          'falsy. This is why empty containers are automatically falsy with '
          'no special-casing, and why types like NumPy arrays can explicitly '
          'refuse the question by raising ValueError in __bool__ rather than '
          'guess between any() and all().',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# __bool__ has priority; __len__ is the fallback.
class AlwaysTrue:
    def __bool__(self):
        return True

class AlwaysFalse:
    def __len__(self):
        return 0

print(bool(AlwaysTrue()), bool(AlwaysFalse()))   # True False

# The "all" and "any" builtins work on any iterable and short-circuit.
print(all([True, True, False]))   # False — stops at the first False
print(any([0, 0, 1]))            # True — stops at the first truthy value

# Practical: validate a whole form at once.
fields = {"name": "Ada", "email": "", "age": 25}
valid = all(fields.values())      # False — email is empty string
print(valid)
''',
          caption: '__bool__/__len__ decide truthiness; all/any test collections.',
        ),
      ],
    ),
    Section(
      id: 'for-loops',
      heading: 'for loops iterate over objects, not indexes',
      blocks: [
        ProseBlock(
          'Python\'s for loop is a foreach. It asks the object for an iterator '
          'and pulls items until the iterator is exhausted; it never manages a '
          'counter for you. Writing for i in range(len(items)) and then '
          'indexing is a C habit that Python has a better answer for in almost '
          'every case.',
        ),
        ProseBlock(
          'The three helpers that remove nearly all manual indexing are '
          'enumerate, which pairs each item with its position; zip, which '
          'walks several sequences in lockstep and stops at the shortest; and '
          'reversed, which walks backwards without building a copy. range '
          'still earns its place when you genuinely want a count rather than '
          'the contents of a collection.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
names = ["ada", "grace", "alan"]
scores = [91, 88, 74]

for name in names:
    print(name.title())

for position, name in enumerate(names, start=1):
    print(position, name)           # 1 ada / 2 grace / 3 alan

for name, score in zip(names, scores):
    print(f"{name}: {score}")

for n in range(0, 10, 3):
    print(n)                        # 0 3 6 9

# Unpacking works in the loop target too.
points = [(0, 0), (3, 4)]
for x, y in points:
    print(x + y)
''',
          caption: 'enumerate, zip and range cover almost every loop shape.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Name the loop variable after the item',
          text:
              'for user in users reads better than for i in range(len(users)) '
              'followed by users[i], and it cannot go out of range. Reach for '
              'an index only when you need the number itself.',
        ),
        ProseBlock(
          'zip_longest from itertools fills shorter sequences with a sentinel '
          'value instead of stopping, and strict=True (Python 3.10+) makes '
          'zip raise when sequences have mismatched lengths — turning a subtle '
          'data-loss bug into a loud error. These two variations cover the '
          'cases where plain zip\'s "stop at the shortest" behaviour is wrong.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from itertools import zip_longest

names = ["ada", "grace"]
scores = [91, 88, 74]

# zip stops silently at the shortest — scores[2] is silently dropped.
for n, s in zip(names, scores):
    print(n, s)

# strict=True makes mismatched lengths a bug.
try:
    for n, s in zip(names, scores, strict=True):
        print(n, s)
except ValueError as exc:
    print("mismatch:", exc)     # "zip() argument 2 is longer than argument 1"

# zip_longest fills the gaps with a sentinel.
for n, s in zip_longest(names, scores, fillvalue=0):
    print(n, s)
# ada 91 / grace 88 / 0 74
''',
          caption: 'zip(strict=True) catches mismatches; zip_longest pads them.',
        ),
      ],
    ),
    Section(
      id: 'while-break-else',
      heading: 'while, break, continue and the loop else',
      blocks: [
        ProseBlock(
          'Use for when you know what you are iterating over and while when '
          'you are looping until a condition changes — reading until input '
          'runs out, retrying until something succeeds. break leaves the '
          'innermost loop immediately; continue skips to the next iteration.',
        ),
        ProseBlock(
          'Both loops accept an else clause, and it is the most misread piece '
          'of Python syntax. The else block runs when the loop finished '
          'normally, i.e. when no break executed. Read it as "no break" rather '
          'than "otherwise" and it stops being mysterious: it is exactly the '
          'search idiom of "if I got all the way through without finding it".',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def first_factor(n):
    for candidate in range(2, n):
        if n % candidate == 0:
            print(f"{n} is divisible by {candidate}")
            break
    else:
        # Reached only when the loop was not broken out of.
        print(f"{n} is prime")


first_factor(9)     # 9 is divisible by 3
first_factor(13)    # 13 is prime

# continue skips the rest of this iteration only.
total = 0
for value in [3, -1, 7, -8]:
    if value < 0:
        continue
    total += value
print(total)        # 10

# while loops until the condition goes false.
countdown = 3
while countdown:
    print(countdown)
    countdown -= 1
''',
          caption: 'break, continue, and the "no break" else clause.',
        ),
        CollapsibleBlock(
          title: 'Common pitfalls: mutating a sequence while looping over it',
          children: [
            ProseBlock(
              'A list iterator holds an index into the live list. Removing an '
              'item shifts everything after it down one position, but the '
              'iterator\'s index still advances — so the loop silently skips '
              'elements. The same applies to changing a dict\'s set of keys '
              'during iteration, except there Python is kind enough to raise '
              'RuntimeError instead of quietly doing the wrong thing.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
numbers = [1, 2, 2, 3]
for n in numbers:
    if n == 2:
        numbers.remove(n)   # skips the second 2
print(numbers)              # [1, 2, 3]  - not what was wanted

# Build a new list instead.
numbers = [1, 2, 2, 3]
numbers = [n for n in numbers if n != 2]
print(numbers)              # [1, 3]

# For dicts, iterate over a snapshot of the keys.
config = {"debug": True, "cache": None}
for key in list(config):
    if config[key] is None:
        del config[key]
print(config)               # {'debug': True}
''',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'match',
      heading: 'Structural pattern matching with match',
      blocks: [
        ProseBlock(
          'Python 3.10 added match, and it is not a switch statement. It '
          'matches the shape of a value, binding parts of the structure to '
          'names as it goes: a sequence of two elements, a dict with a "type" '
          'key, an instance of a class with particular attributes. Cases are '
          'tried in order and the first structural match wins.',
        ),
        ProseBlock(
          'Inside a pattern, a bare name is a binding, not a comparison — '
          'case x captures anything and calls it x. To compare against a '
          'constant you need a dotted name such as Status.DONE, or a literal. '
          'The wildcard _ matches anything without binding, and a guard '
          '(if ...) after a pattern adds an extra condition.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def describe(event):
    match event:
        case {"type": "click", "x": x, "y": y}:
            return f"click at {x},{y}"
        case {"type": "key", "value": str(value)}:
            return f"key {value}"
        case [start, end] if end > start:
            return f"range {start}..{end}"
        case []:
            return "empty"
        case _:
            return "unknown event"


print(describe({"type": "click", "x": 3, "y": 9}))  # click at 3,9
print(describe({"type": "key", "value": "esc"}))    # key esc
print(describe([1, 5]))                             # range 1..5
print(describe([]))                                 # empty
print(describe(42))                                 # unknown event
''',
          caption: 'Patterns match structure and bind the pieces they match.',
        ),
        ProseBlock(
          'Reach for match when you are dispatching on the shape of data — '
          'parsed JSON, an AST, a message protocol. For a simple equality '
          'lookup a dict of handlers is usually shorter, and a plain if/elif '
          'chain remains the right tool for conditions that are not about '
          'structure at all.',
        ),
        ProseBlock(
          'OR patterns (|) combine alternatives, AS patterns (as) bind '
          'sub-patterns to names, and class patterns match instance attributes. '
          'These compose: you can match {"status": 200 | 201 as code} to '
          'match either status and capture it as "code". This makes match '
          'dramatically more expressive than a chain of isinstance checks.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y


def locate(p):
    match p:
        case Point(x=0, y=0):
            return "origin"
        case Point(x=0, y=y):
            return f"y-axis at {y}"
        case Point(x=x, y=y) if x == y:
            return f"diagonal at {x}"
        case Point():
            return f"point ({p.x}, {p.y})"
        case _:
            return "not a point"


print(locate(Point(0, 0)))    # origin
print(locate(Point(0, 5)))    # y-axis at 5
print(locate(Point(3, 3)))    # diagonal at 3
print(locate(Point(5, 8)))    # point (5, 8)
''',
          caption: 'Class patterns match attributes; guards add conditions.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-cf-classify',
      title: 'Classify a value without over-branching',
      prompt: [
        ProseBlock(
          'Write classify(n) that returns "negative" for values below zero, '
          '"zero" for exactly zero, "small" for 1 through 9, and "large" for '
          '10 and above. Use a single if/elif/else chain — no nested ifs, and '
          'no repeated comparisons.',
        ),
      ],
      starterCode: '''
def classify(n):
    # TODO: one if/elif/else chain, four possible return values
    ...


for value in (-4, 0, 7, 41):
    print(value, classify(value))
''',
      solutionCode: '''
def classify(n):
    if n < 0:
        return "negative"
    elif n == 0:
        return "zero"
    elif n < 10:
        return "small"
    else:
        return "large"


for value in (-4, 0, 7, 41):
    print(value, classify(value))
# -4 negative / 0 zero / 7 small / 41 large
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why is the third branch just n < 10 rather than 0 < n < 10?',
          expectedAnswer:
              'The chain only reaches that branch when both earlier conditions '
              'were false, so n is already known to be greater than zero. '
              'Re-testing it would be dead code that hides the fact that elif '
              'stops at the first match.',
        ),
        SelfCheckQuestion(
          question:
              'The function returns from each branch. What would change if it '
              'assigned to a result variable instead and returned at the end?',
          expectedAnswer:
              'Nothing about the output, but every branch would then have to '
              'be written so it cannot fall through unassigned. Returning '
              'early keeps each case self-contained and makes an unhandled '
              'case a visible None rather than a stale value.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-cf-enumerate',
      title: 'Retire the index loop',
      prompt: [
        ProseBlock(
          'The function below prints a numbered leaderboard, but it manages '
          'indexes by hand and breaks if the two lists have different lengths. '
          'Rewrite it using enumerate and zip so no index arithmetic remains.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def leaderboard(names, scores):
    for i in range(len(names)):
        print(str(i + 1) + ". " + names[i] + " - " + str(scores[i]))
''',
        ),
      ],
      starterCode: '''
def leaderboard(names, scores):
    for i in range(len(names)):
        print(str(i + 1) + ". " + names[i] + " - " + str(scores[i]))


leaderboard(["ada", "grace", "alan"], [91, 88, 74])
''',
      solutionCode: '''
def leaderboard(names, scores):
    for rank, (name, score) in enumerate(zip(names, scores), start=1):
        print(f"{rank}. {name} - {score}")


leaderboard(["ada", "grace", "alan"], [91, 88, 74])
# 1. ada - 91
# 2. grace - 88
# 3. alan - 74
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'What happens with the rewritten version if scores is shorter '
              'than names, and is that better or worse than the original?',
          expectedAnswer:
              'zip stops at the shortest sequence, so the extra names are '
              'simply not printed. The original would raise IndexError. Which '
              'is better depends on intent: zip fails silently, so use '
              'zip(..., strict=True) on Python 3.10+ when the lengths are '
              'supposed to match and a mismatch is a bug.',
        ),
        SelfCheckQuestion(
          question: 'Why does the loop target need the parentheses in (name, score)?',
          expectedAnswer:
              'enumerate yields (index, item) pairs, and here the item is '
              'itself the (name, score) tuple from zip. The parentheses unpack '
              'that nested tuple in place; without them Python would try to '
              'unpack two values into three names.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-cf-for-else',
      title: 'Search with for/else',
      prompt: [
        ProseBlock(
          'Write find_first_even(numbers) that prints the first even number it '
          'finds and stops looking, or prints "no even numbers" if it gets '
          'through the whole list without finding one. Use a for/else clause '
          'rather than a found flag.',
        ),
      ],
      starterCode: '''
def find_first_even(numbers):
    for n in numbers:
        # TODO: print and break on the first even value
        ...
    # TODO: attach an else clause for the "never found" case


find_first_even([3, 5, 8, 10])
find_first_even([1, 3, 5])
''',
      solutionCode: '''
def find_first_even(numbers):
    for n in numbers:
        if n % 2 == 0:
            print(f"first even: {n}")
            break
    else:
        print("no even numbers")


find_first_even([3, 5, 8, 10])   # first even: 8
find_first_even([1, 3, 5])       # no even numbers
find_first_even([])              # no even numbers
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question: 'When exactly does the else block run?',
          expectedAnswer:
              'Only when the loop ended by exhausting the iterable — including '
              'when the iterable was empty and the body never ran. Any break '
              'skips it. return and an exception also skip it, because the '
              'loop never completes.',
        ),
        SelfCheckQuestion(
          question:
              'What would the flag-based version look like, and why is for/else '
              'preferred here?',
          expectedAnswer:
              'You would set found = False before the loop, set it True '
              'alongside the break, then test it afterwards. That is three '
              'extra lines of bookkeeping whose only job is to remember '
              'whether break ran — which is precisely what the else clause '
              'already records.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-cf-match-dispatch',
      title: 'Dispatch commands with match',
      prompt: [
        ProseBlock(
          'Write process_command(cmd) that takes a dict with a "command" key '
          'and optional parameters. Use match to dispatch: {"command": "echo", '
          '"text": t} returns the text, {"command": "add", "a": a, "b": b} '
          'returns a + b, {"command": "quit"} returns "bye", and anything else '
          'raises ValueError. Assume numbers may be int or float.',
        ),
      ],
      starterCode: '''
def process_command(cmd):
    match cmd:
        # TODO: three patterns for echo, add, quit, plus a default case
        ...


print(process_command({"command": "echo", "text": "hello"}))
print(process_command({"command": "add", "a": 10, "b": 3.5}))
print(process_command({"command": "quit"}))
''',
      solutionCode: '''
def process_command(cmd):
    match cmd:
        case {"command": "echo", "text": str(text)}:
            return text
        case {"command": "add", "a": int(a) | float(a), "b": int(b) | float(b)}:
            return a + b
        case {"command": "quit"}:
            return "bye"
        case _:
            raise ValueError(f"unknown command: {cmd}")


print(process_command({"command": "echo", "text": "hello"}))     # hello
print(process_command({"command": "add", "a": 10, "b": 3.5}))   # 13.5
print(process_command({"command": "quit"}))                      # bye

try:
    process_command({"command": "delete"})
except ValueError as exc:
    print(exc)     # unknown command: {'command': 'delete'}
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why use int(a) | float(a) in the add pattern rather than just '
              'accepting any value?',
          expectedAnswer:
              'It validates the types structurally, so passing {"command": '
              '"add", "a": "ten"} would not match the add case and would fall '
              'through to ValueError instead of producing a confusing '
              'TypeError at runtime.',
        ),
        SelfCheckQuestion(
          question: 'What happens if an unrecognised key such as "debug" is '
              'present in the echo command dict?',
          expectedAnswer:
              'The pattern still matches because dict patterns match by the '
              'presence of the specified keys, not by exact equality. Extra '
              'keys are ignored — which is usually what you want for '
              'extensible message protocols.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-cf-refactor-nesting',
      title: 'Flatten deep nesting with guard clauses',
      prompt: [
        ProseBlock(
          'The function below validates a user record with deeply nested '
          'conditionals. Refactor it to use guard clauses: each invalid case '
          'returns early, so the successful path stays at one indentation '
          'level. Raise ValueError with a specific message for each failure, '
          'then return the sanitised record on success.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def sanitise(record):
    if record is not None:
        if "name" in record:
            if len(record["name"]) > 0:
                return record
    return None
''',
        ),
      ],
      starterCode: '''
def sanitise(record):
    if record is not None:
        if "name" in record:
            if len(record["name"]) > 0:
                return record
    return None


# Should raise informative errors, not return None.
print(sanitise({"name": "Ada"}))
# print(sanitise({"name": ""}))   # should raise ValueError
''',
      solutionCode: '''
def sanitise(record):
    if record is None:
        raise ValueError("record must not be None")
    if "name" not in record:
        raise ValueError("record must contain a 'name' field")
    if len(record["name"]) == 0:
        raise ValueError("name must not be empty")
    return record


print(sanitise({"name": "Ada"}))     # {'name': 'Ada'}

for bad in [None, {}, {"name": ""}]:
    try:
        sanitise(bad)
    except ValueError as exc:
        print(exc)
# record must not be None
# record must contain a 'name' field
# name must not be empty
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why raise ValueError instead of returning None for each failure?',
          expectedAnswer:
              'Returning None tells the caller only that something failed — '
              'not what or why. An exception carries a specific message and '
              'type, so the caller can log, report, or recover differently '
              'depending on which failure occurred. It also cannot be silently '
              'ignored the way a returned None can.',
        ),
        SelfCheckQuestion(
          question:
              'What is the advantage of the guard-clause style here?',
          expectedAnswer:
              'Each failure is isolated to a single if statement, the happy '
              'path stays at the top indentation level, and adding a new '
              'validation rule means inserting one new guard clause — not '
              'nesting another level deeper.',
        ),
      ],
    ),
  ],
);

const GameContent _play = GameContent(
  games: [
    SyntaxScrambleGame(
      id: 'game-control-flow-scramble',
      title: 'Rebuild the grade ladder',
      instructions: 'Drag or use the arrows to put these lines back in order.',
      lines: [
        'def grade(score):',
        '    if score >= 90:',
        '        return "A"',
        '    elif score >= 80:',
        '        return "B"',
        '    else:',
        '        return "F"',
      ],
    ),
    OutputPredictorGame(
      id: 'game-control-flow-for-else',
      title: 'What does this print?',
      instructions: 'Pick what first_factor(9) prints.',
      code: '''
def first_factor(n):
    for candidate in range(2, n):
        if n % candidate == 0:
            print(f"{n} is divisible by {candidate}")
            break
    else:
        print(f"{n} is prime")


first_factor(9)
''',
      options: [
        '9 is prime',
        '9 is divisible by 3',
        'Nothing is printed',
        '9 is divisible by 9',
      ],
      correctIndex: 1,
      explanation:
          'candidate=2 does not divide 9, but candidate=3 does — the if body '
          'prints and breaks, which skips the loop\'s else clause entirely. '
          'else only runs when the loop finishes without a break.',
    ),
    FillBlankGame(
      id: 'game-control-flow-enumerate',
      title: 'Pair items with their position',
      instructions: 'Type the missing built-in function.',
      code: '''
names = ["ada", "grace", "alan"]
for position, name in ______(names, start=1):
    print(position, name)
''',
      blanks: [Blank(answer: 'enumerate', hint: 'built-in function')],
    ),
    BugHuntGame(
      id: 'game-control-flow-range-bug',
      title: 'Find the empty loop',
      instructions: 'Tap the line that stops this loop from ever running.',
      code: '''
def countdown_from(n):
    for i in range(n, 0):
        print(i)


countdown_from(3)
''',
      buggyLine: 2,
      explanation:
          'range(n, 0) counts upward by a default step of +1, but n is '
          'already greater than 0 — so the range is empty and the loop body '
          'never runs. Count down explicitly with range(n, 0, -1).',
      fixedCode: '''
def countdown_from(n):
    for i in range(n, 0, -1):
        print(i)


countdown_from(3)   # 3 2 1
''',
    ),
    TermMatchGame(
      id: 'game-control-flow-terms',
      title: 'Match the vocabulary',
      instructions: 'Tap a term, then tap its definition.',
      pairs: [
        TermPair(
          term: 'Truthiness',
          definition: 'The truth value Python derives from any object in a condition.',
        ),
        TermPair(
          term: 'Short-circuit evaluation',
          definition: 'and/or stop at the first operand that decides the result.',
        ),
        TermPair(
          term: 'Loop else clause',
          definition: 'Runs only when the loop finished without hitting a break.',
        ),
        TermPair(
          term: 'Structural pattern matching',
          definition: 'match tests the shape of a value and binds the parts it matches.',
        ),
        TermPair(
          term: 'Guard clause',
          definition: 'An early return that handles an edge case before the main logic.',
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
              'Control flow in about three minutes. Python gives you a tiny toolkit — '
              'if, elif, else, for, while, break, continue, and match. '
              'It\'s like having seven basic tools in your kitchen drawer. '
              'You can cook almost anything with them, but the real skill '
              'is knowing which one to grab, not memorizing what each looks like.',
          startMs: 0,
          endMs: 40000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'First up: truthiness — it\'s the bouncer at the door of every if statement. '
              'False, None, zero of any kind, empty strings, empty lists — all get turned away. '
              'Everything else gets in. So "if not items" is the pythonic way to ask "is this list empty?" — '
              'but careful, because it also says yes when items is None or zero, '
              'and zero might be a perfectly valid value in your program.',
          startMs: 40000,
          endMs: 88000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'On to loops. Python\'s for loop is more like a tour guide than a counter — '
              'it walks through the items themselves, not index numbers. '
              'If you catch yourself writing "for i in range of len of something," '
              'stop right there. You probably want enumerate if you need positions, '
              'or zip if you\'re walking two lists side by side. '
              'It\'s the difference between counting seats and actually visiting each room.',
          startMs: 88000,
          endMs: 132000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'And here\'s the one nobody sees coming: loops in Python can have an else clause. '
              'It doesn\'t mean "if the loop was empty" — it means "if the loop finished without hitting break." '
              'Mentally read it as "nobreak." It\'s perfect for search patterns: '
              'you loop through looking for something, break when you find it, '
              'and the else block handles the "not found" case without any extra flags.',
          startMs: 132000,
          endMs: 176000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And finally, match — the new kid from Python 3.10. '
              'Think of it as a Swiss Army knife for data shapes. '
              'It\'s brilliant when you\'re dealing with parsed JSON or message patterns '
              'where you want to pull apart the structure and react differently. '
              'But for simple equality checks? A dictionary of handlers is still shorter. '
              'That\'s your whole control flow toolkit, right there.',
          startMs: 176000,
          endMs: 210000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 486000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Today we are talking about control flow — the statements that decide what runs next. '
              'The actual syntax fits on a postcard, honestly. So instead of memorizing, '
              'let\'s spend our time on judgment: which tool says what you really mean, '
              'and where Python quietly behaves differently from the languages '
              'most of us grew up with.',
          startMs: 0,
          endMs: 52000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The first thing that throws people: blocks are defined by indentation, not braces. '
              'What you see on screen is exactly what Python sees — there\'s no hidden punctuation. '
              'It\'s like writing an outline for a paper: the indentation IS the structure. '
              'One space too many and you\'ve written a different program. '
              'This trips up almost everyone in their first week, so you\'re in good company.',
          startMs: 52000,
          endMs: 116000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'With if and elif, here\'s the key insight: the chain stops at the first match. '
              'It\'s like a series of bouncers at a club — the first one who lets you in wins, '
              'and nobody else even looks at you. So order matters tremendously. '
              'Put your narrow, specific conditions first. A broad condition early on '
              'will swallow every narrower case below it — like putting "age > 0" '
              'before "age > 65" and wondering why the senior discount never fires.',
          startMs: 116000,
          endMs: 172000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Here\'s something surprising: conditions don\'t need to be booleans. '
              'Python asks every object "are you truthy?" — like a bouncer checking IDs. '
              'Empty things, zero, None, and False get turned away. Everything else gets in — '
              'even the string "False" (it\'s not empty!) or a list containing [0] (it\'s not empty either!). '
              'And the and/or operators are shortcut operators — they return one of their operands, not True/False, '
              'which is exactly why "name or anonymous" works as a default value.',
          startMs: 172000,
          endMs: 248000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Now the trap: treating falsy as "missing." If you write "if not count" you\'ll catch None — '
              'great! — but you\'ll also catch zero, which might be a perfectly legitimate value. '
              'Imagine you\'re checking a bank balance: zero dollars is very different from "no data available." '
              'When zero is real data in your domain, compare against None explicitly. '
              'This bug is silent, deadly, and everywhere in configuration code.',
          startMs: 248000,
          endMs: 304000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'On to loops. Python\'s for loop is like a waiter delivering dishes from the kitchen — '
              'it brings you the items themselves, not table numbers. '
              'enumerate gives you table numbers when you need them, and it accepts a start argument '
              'so you can number from 1 like normal humans do. '
              'zip walks several sequences in lockstep like two people walking side by side, '
              'stopping when the shorter one runs out — or it can raise an error on 3.10+ '
              'if you pass strict=True and they\'re different lengths.',
          startMs: 304000,
          endMs: 372000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'while is for looping until something changes — like stirring a pot until it boils, '
              'rather than counting how many stirs you\'ve done. '
              'break bails out of the innermost loop entirely. continue skips to the next lap. '
              'And both loop types can carry an else clause — which fires only when no break happened, '
              'like a "plan B" for when you searched everything and found nothing. '
              'Just say "nobreak" out loud whenever you see it and it stops being weird.',
          startMs: 372000,
          endMs: 434000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'One golden rule: never add or remove items from the thing you\'re currently looping over. '
              'It\'s like trying to repaint a road while you\'re driving on it — things shift under you. '
              'Removing from a list mid-loop makes it skip elements (everyone shifts down but your index still advances). '
              'Changing a dict\'s keys mid-iteration raises a RuntimeError — Python catches you red-handed. '
              'The fix: build a new collection, or loop over a snapshot like list(my_dict).',
          startMs: 434000,
          endMs: 486000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 822000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Welcome to the deep dive on control flow. We\'re going to peel back every layer: '
              'branching, the truthiness machinery, the iterator protocol that powers for loops, '
              'the mysterious else clause, structural pattern matching, and how to keep deeply nested code sane. '
              'Some of this you might only need once — but it\'s exactly the stuff that explains '
              'those "why did my code do THAT?" moments we\'ve all had.',
          startMs: 0,
          endMs: 66000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Let\'s go under the if statement. Python doesn\'t actually require a bool — it asks the object politely. '
              'First it calls __bool__. If that doesn\'t exist, it tries __len__ — zero means false. '
              'If neither exists, the object is unconditionally true. That\'s the whole rule! '
              'It\'s like asking a restaurant "are you open?" — first check the sign, '
              'if there\'s no sign, count the customers. No customers and no sign? Assume open. '
              'This elegant fallback chain is why empty containers are falsy without anyone special-casing them.',
          startMs: 66000,
          endMs: 148000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'This also explains a bug that bites data scientists. A NumPy array with multiple elements '
              'refuses to give a truth value — it raises an error instead. Why? '
              'Because "is this array true?" is genuinely ambiguous — does it mean "are ALL elements true" '
              'or "is ANY element true"? NumPy says "I\'m not guessing — you tell me with .any() or .all()." '
              'The interpreter isn\'t being difficult; the type is wisely refusing to pick for you.',
          startMs: 148000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Short-circuiting deserves precision because it\'s both brilliant and treacherous. '
              '"a and b" checks a first — if a is falsy, it returns a immediately without even glancing at b. '
              'It\'s like checking if you have your keys before checking if the car has gas — no point looking further. '
              '"a or b" returns a if truthy, b otherwise. These return the actual operand, not True/False. '
              'That\'s the magic behind "name or \'anonymous\'" — and the curse behind "x or 0" silently replacing '
              'a legitimate empty string or zero with a default you didn\'t mean.',
          startMs: 214000,
          endMs: 288000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Now the for loop — and this is beautiful once you see it. It\'s just syntax sugar over three steps: '
              'call iter() on the object, call next() repeatedly, and stop when StopIteration is raised. '
              'That\'s it. The loop itself knows nothing about lists or indexes — it\'s like a universal remote '
              'that works with any device that speaks the same protocol. '
              'That\'s why the same for statement works on lists, files, dicts, generators, '
              'and anything you make iterable. No special cases, just a clean contract.',
          startMs: 288000,
          endMs: 368000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'This protocol also explains why mutating while iterating goes wrong — but differently for different types. '
              'A list iterator keeps an integer index. Remove item 3, everything after shifts down, '
              'but the index still ticks to 4 — skipping exactly one element. It\'s like removing a rung '
              'from a ladder while climbing: you miss the next step entirely. '
              'Dicts are smarter: they track a version counter and raise RuntimeError the moment the size changes. '
              'Much kinder — at least it screams instead of silently skipping your data.',
          startMs: 368000,
          endMs: 448000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'The else clause on loops finally makes sense when you see it as a search pattern. '
              'You\'re looking through items. You break when you find what you want. '
              'The else runs when you searched everything and came up empty. '
              'Without it, you\'d need a "found" flag — set in one place when you find it, '
              'test in another place after the loop. It\'s poorly named, I\'ll grant you — '
              'Knuth would have called it "nobreak" — but it eliminates real bookkeeping.',
          startMs: 448000,
          endMs: 524000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Now match, the feature that arrived in Python 3.10. Here\'s the thing everyone gets wrong: '
              'a bare name in a case pattern is a BINDING, not a comparison. "case x" matches literally anything '
              'and names it x — it\'s like saying "I\'ll take whatever you give me and call it Bob." '
              'If you want to compare against a constant, you need a dotted name like Colour.RED, or a literal value. '
              'I\'ve seen people write "case MY_CONSTANT" expecting a comparison and instead creating '
              'a catch-all that silently shadows every case below it. Painful.',
          startMs: 524000,
          endMs: 606000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Beyond the basics, patterns compose beautifully. You can match a dict with specific keys, '
              'a sequence of a certain length, a class with particular attribute values, '
              'or alternatives separated by a vertical bar — like saying "match this OR that." '
              'You can add a guard — an if after the pattern — for conditions about values, not shapes. '
              'And underscore is your wildcard: it matches anything without capturing it, '
              'like a trash can that says "I don\'t care what this is, just move on."',
          startMs: 606000,
          endMs: 682000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'So when should you actually reach for match? When your decision depends on the SHAPE of data — '
              'parsed JSON from an API, an abstract syntax tree, a protocol message with different variants. '
              'For dispatching on a single value? A dictionary mapping values to functions is usually shorter and clearer. '
              'And when the decision isn\'t about structure at all — just a chain of conditions? '
              'Good old if/elif is still the honest, readable answer. Match is a precision tool, not a hammer.',
          startMs: 682000,
          endMs: 754000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Let\'s close on readability, because ultimately that\'s what control flow is about. '
              'Deep nesting is the real enemy — it\'s like a Russian doll where you need to open seven layers '
              'to find the actual logic. Prefer guard clauses: check the invalid cases first and return early, '
              'so the happy path stays at one indentation level. Keep conditions short enough to name. '
              'And here\'s your mental cheat sheet: conditions ask objects for truthiness, '
              'for loops consume iterators, else means "no break happened," and match matches structure. '
              'That\'s the whole game.',
          startMs: 754000,
          endMs: 822000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Branches stop at the first match',
      body:
          'An if/elif chain evaluates conditions in order and runs only the '
          'first true branch — later conditions are never evaluated. Order '
          'cases from most specific to least, because a broad condition placed '
          'early hides every narrower one below it.',
    ),
    SummaryCard(
      title: 'Loops iterate over objects',
      body:
          'for asks an object for an iterator and consumes it, so you rarely '
          'need indexes: enumerate supplies positions, zip walks sequences in '
          'lockstep, reversed goes backwards. break exits the innermost loop '
          'and the loop\'s else clause runs only when no break happened.',
    ),
    SummaryCard(
      title: 'Truthiness is not equality',
      body:
          'False, None, zero and every empty container are falsy. That makes '
          '"if not items" idiomatic for emptiness, but it also means "if not '
          'count" treats a real zero as missing. Test against None explicitly '
          'when zero is valid data.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Truthiness',
      definition:
          'The truth value Python derives from any object for use in a '
          'condition, via __bool__ or, failing that, __len__ == 0. False, '
          'None, numeric zero and empty containers are falsy; everything else '
          'is truthy.',
    ),
    KeyConcept(
      term: 'Short-circuit evaluation',
      definition:
          'and stops at the first falsy operand, or at the first truthy one, '
          'and both return that operand rather than a bool. The remaining '
          'operands are never evaluated.',
    ),
    KeyConcept(
      term: 'Loop else clause',
      definition:
          'A block attached to for or while that runs only when the loop '
          'completed without executing a break. Best read as "no break".',
    ),
    KeyConcept(
      term: 'enumerate',
      definition:
          'A built-in that yields (index, item) pairs from any iterable, with '
          'an optional start value, removing the need for a manual counter.',
    ),
    KeyConcept(
      term: 'Structural pattern matching',
      definition:
          'The match statement (Python 3.10+), which tests the shape of a '
          'value — sequence, mapping, class — and binds the matched parts to '
          'names. A bare name in a pattern always binds; it never compares.',
    ),
    KeyConcept(
      term: 'Guard clause',
      definition:
          'An early return or raise that handles an invalid or edge case at '
          'the top of a function, keeping the main logic un-nested below it.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Removing items from a list while iterating over that same list.',
      correction:
          'The iterator\'s index keeps advancing as elements shift down, so '
          'items get skipped. Build a new list with a comprehension, or '
          'iterate over a copy such as list(items).',
    ),
    Mistake(
      mistake:
          'Using "if not value:" to check whether an optional argument was '
          'supplied.',
      correction:
          'That branch also fires for 0, "" and []. Use "if value is None:" '
          'when the absence of a value is what you actually mean.',
    ),
    Mistake(
      mistake:
          'Writing "case MAX_RETRIES:" in a match statement expecting a '
          'comparison against that constant.',
      correction:
          'A bare name in a pattern binds rather than compares, so that case '
          'matches everything. Use a dotted name (Config.MAX_RETRIES), a '
          'literal, or a guard: "case n if n == MAX_RETRIES:".',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'What does the else clause on a for loop do, and when would you use '
          'it?',
      answer:
          'It runs when the loop terminates by exhausting its iterable — that '
          'is, when no break executed. The canonical use is search: loop over '
          'candidates, break when you find a match, and put the "not found" '
          'handling in the else. It replaces a boolean found flag that would '
          'otherwise have to be initialised, set and tested separately.',
    ),
    InterviewQuestion(
      question: 'How does Python decide whether an arbitrary object is true?',
      answer:
          'It calls the type\'s __bool__ method. If that is not defined it '
          'calls __len__ and treats a length of zero as false. If neither is '
          'defined the object is always true. This is why empty containers are '
          'falsy without any special case in the language, and why a type can '
          'refuse the question by raising in __bool__.',
    ),
    InterviewQuestion(
      question:
          'Why is "for i in range(len(items))" discouraged, and what replaces '
          'it?',
      answer:
          'It reintroduces manual index arithmetic that Python\'s iterator '
          'protocol already handles, and every use of items[i] is an '
          'opportunity for an off-by-one or an IndexError. Iterate directly '
          'when you need the item, use enumerate when you also need the '
          'position, and use zip when you are walking two sequences together. '
          'range stays appropriate when the number itself is the subject, such '
          'as repeating an action n times.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: '4. More Control Flow Tools — Python Docs',
    url: 'https://docs.python.org/3/tutorial/controlflow.html',
    description:
        'Tutorial chapter covering if, for, range, break, continue, the loop '
        'else clause, pass and match.',
  ),
  Source(
    title: '8. Compound statements — Python Docs',
    url: 'https://docs.python.org/3/reference/compound_stmts.html',
    description:
        'Language reference for every statement that contains a suite, '
        'including the precise semantics of match patterns.',
  ),
];

const List<Source> _furtherReading = [
  Source(
    title: '8. Errors and Exceptions — Python Docs',
    url: 'https://docs.python.org/3/tutorial/errors.html',
    description:
        'Covers raising and handling exceptions, which is the companion topic '
        'to control flow and the preferred way to signal failure in Python.',
  ),
  Source(
    title: 'Conditional Statements in Python — Real Python',
    url: 'https://realpython.com/python-conditional-statements/',
    description:
        'In-depth guide to if/elif/else chains, ternary expressions, and common branching patterns.',
  ),
  Source(
    title: 'PEP 636 – Structural Pattern Matching: Tutorial',
    url: 'https://peps.python.org/pep-0636/',
    description:
        'The official tutorial introducing match/case with walk-through examples '
        'of sequence, mapping, and class patterns.',
  ),
  Source(
    title: 'Python "for" Loops (Definite Iteration) — Real Python',
    url: 'https://realpython.com/python-for-loop/',
    description:
        'Comprehensive guide to for loops, iterables, iterators, enumerate, zip, '
        'and the iterator protocol.',
  ),
];
