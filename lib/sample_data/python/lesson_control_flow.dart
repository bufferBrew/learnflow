import '../../models/content_block.dart';
import '../../models/exercise.dart';
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
  estimatedMinutes: 20,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  review: _review,
  sources: _sources,
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
              'Control flow in about three minutes. Python gives you a very '
              'small set of tools here — if, elif, else, for, while, break, '
              'continue and match — and almost all the skill is in picking the '
              'right one rather than in remembering syntax.',
          startMs: 0,
          endMs: 40000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Start with truthiness, because it shows up in every condition. '
              'False, None, zero, and any empty container or string are falsy. '
              'Everything else is truthy. So "if not items" is the idiomatic '
              'way to ask whether a list is empty — but be careful, because it '
              'also fires when items is None or zero.',
          startMs: 40000,
          endMs: 88000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Then loops. Python\'s for loop is a foreach: it walks the '
              'objects themselves, not indexes. If you find yourself writing '
              'for i in range of len of something, you almost certainly want '
              'enumerate for positions, or zip to walk two lists together.',
          startMs: 88000,
          endMs: 132000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'And the one piece of syntax nobody guesses correctly: a loop '
              'can have an else clause, and it runs when the loop finished '
              'without hitting a break. Read it as "no break". It is the '
              'search idiom — did I get all the way through without finding '
              'what I was looking for.',
          startMs: 132000,
          endMs: 176000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Finally, match, from Python 3.10. It matches the shape of data '
              'and binds the pieces, so it shines on parsed JSON and message '
              'dispatch. For plain equality, a dict of handlers is still '
              'shorter. That is the whole toolkit.',
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
              'Today we are on control flow: the statements that decide what '
              'runs next. The syntax fits on a postcard, so we are going to '
              'spend the time on judgement instead — which construct says what '
              'you actually mean, and where Python quietly differs from the '
              'languages people arrive from.',
          startMs: 0,
          endMs: 52000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The first difference is that blocks are defined by indentation. '
              'There are no braces, so what you see on screen is exactly what '
              'the interpreter sees. A line indented one level too far is a '
              'different program, not a formatting quibble — and that is the '
              'single most common source of confusion in someone\'s first '
              'week.',
          startMs: 52000,
          endMs: 116000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'With if and elif, the important property is that the chain '
              'stops at the first true condition. Later branches are never '
              'evaluated. That means order matters: put the specific cases '
              'first, because a broad condition placed early swallows every '
              'narrower one underneath it.',
          startMs: 116000,
          endMs: 172000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Conditions do not have to be booleans, either. Python asks any '
              'object whether it is truthy. Empty containers, empty strings, '
              'zero of any numeric type, None and False are falsy; everything '
              'else is truthy — including the string "False" and the list '
              'containing a single zero. And the and/or operators return one '
              'of their operands rather than a bool, which is why "name or '
              'anonymous" works as a default value.',
          startMs: 172000,
          endMs: 248000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'The trap there is treating falsy as a synonym for missing. If '
              'you write "if not count", you catch None and you also catch a '
              'perfectly legitimate zero. When zero is real data, compare '
              'against None explicitly. This bug is very quiet and very common '
              'in configuration handling.',
          startMs: 248000,
          endMs: 304000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Loops next. Python\'s for asks an object for an iterator and '
              'pulls values from it, so it iterates over items rather than '
              'positions. enumerate gives you positions when you need them, '
              'and takes a start argument so you can number from one. zip '
              'walks several sequences in lockstep and stops at the shortest — '
              'or raises, if you pass strict equals True on 3.10 and later.',
          startMs: 304000,
          endMs: 372000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'while is for looping until a condition changes rather than over '
              'a known collection. break leaves the innermost loop, continue '
              'skips to the next iteration, and both loop types can carry an '
              'else clause that runs only when no break happened. Say "no '
              'break" out loud each time you read it and it stops being '
              'confusing.',
          startMs: 372000,
          endMs: 434000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And keep one rule in your head: do not add or remove items from '
              'the thing you are iterating over. Removing from a list while '
              'looping makes the loop skip elements, and changing a dict\'s '
              'keys raises RuntimeError. Build a new collection, or iterate '
              'over a snapshot such as list of the dict.',
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
              'The long version of control flow. We will go through branching, '
              'truthiness, the iterator protocol behind the for loop, the else '
              'clause, structural pattern matching, and finish on how to keep '
              'deeply branched code readable. Some of this is mechanism you '
              'will only need once, but it is exactly the mechanism that '
              'explains the surprises.',
          startMs: 0,
          endMs: 66000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start underneath the if statement. The interpreter does not '
              'require a bool; it calls the object\'s dunder bool method to ask '
              'for a truth value. If the type does not define one, Python falls '
              'back to dunder len and treats length zero as false. If neither '
              'exists, the object is unconditionally true. That is the entire '
              'rule, and it explains why empty containers are falsy without '
              'anyone special-casing them.',
          startMs: 66000,
          endMs: 148000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'It also explains a class of bug in numeric libraries. A NumPy '
              'array with more than one element raises when you ask it for a '
              'truth value, because element-wise comparison makes "is this '
              'array true" genuinely ambiguous. The interpreter is not being '
              'awkward; the type is declining to guess.',
          startMs: 148000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Short-circuiting is worth being precise about too. "a and b" '
              'evaluates a, and if a is falsy it returns a itself without '
              'touching b. "a or b" returns a if a is truthy. So these '
              'operators return operands, not booleans — which is both the '
              'trick behind default values and the reason "x or 0" quietly '
              'replaces a legitimate empty string.',
          startMs: 214000,
          endMs: 288000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Now the for loop. It is pure syntax over the iterator protocol: '
              'Python calls iter on the object to get an iterator, then calls '
              'next repeatedly until StopIteration is raised, and that '
              'exception is what ends the loop. Nothing about the loop knows '
              'about lists or indexes, which is why the same statement works '
              'over files, dicts, generators and anything else you make '
              'iterable.',
          startMs: 288000,
          endMs: 368000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'That protocol also explains the mutation bug. A list iterator '
              'keeps an integer index. Remove an item and everything after it '
              'shifts down, but the index still advances, so exactly one '
              'element gets skipped for each removal. Dicts take a different '
              'approach: they track a version counter and raise RuntimeError '
              'if the size changes mid-iteration, which is a much kinder '
              'failure.',
          startMs: 368000,
          endMs: 448000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'The loop else clause makes most sense once you know it exists '
              'for search. You loop looking for something; you break when you '
              'find it; the else runs when you did not. The alternative is a '
              'found flag you set in two places and test in a third. The '
              'clause is genuinely poorly named — Donald Knuth would have '
              'called it "nobreak" — but it removes real bookkeeping.',
          startMs: 448000,
          endMs: 524000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'On to match, added in 3.10. The critical thing to internalise '
              'is that a bare name inside a pattern is a binding, not a '
              'comparison. "case x" matches anything and names it x. If you '
              'want to compare against a constant you need a dotted name, like '
              'Colour.RED, or a literal. People write "case CONSTANT" expecting '
              'equality and get a catch-all that shadows every case below it.',
          startMs: 524000,
          endMs: 606000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Beyond that, patterns compose. You can match a mapping with '
              'particular keys, a sequence of a given length, a class with '
              'specific attributes, or alternatives separated by a vertical '
              'bar. You can add a guard — an if after the pattern — for '
              'conditions that are about values rather than shape. And '
              'underscore is the wildcard that matches without binding.',
          startMs: 606000,
          endMs: 682000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'When should you use it? When you are dispatching on the shape '
              'of data — parsed JSON, an abstract syntax tree, a protocol '
              'message. When you are dispatching on a single value, a '
              'dictionary mapping values to functions is usually shorter and '
              'faster to read. And when the decision is not about structure at '
              'all, if/elif is still the honest answer.',
          startMs: 682000,
          endMs: 754000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Close on readability. Deep nesting is the real enemy: prefer '
              'guard clauses that return early on the invalid cases so the '
              'happy path stays at one indentation level. Keep conditions '
              'short enough to name. And remember the summary: conditions ask '
              'objects for truthiness, for loops consume iterators, else means '
              'no break, and match matches structure.',
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
