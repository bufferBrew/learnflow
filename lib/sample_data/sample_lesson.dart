import '../models/content_block.dart';
import '../models/exercise.dart';
import '../models/game.dart';
import '../models/lesson.dart';
import '../models/podcast.dart';
import '../models/review.dart';
import '../models/source.dart';
import '../models/topic.dart';

/// A single fully-populated lesson used to exercise the model shape end to end.
/// Content for the remaining lessons arrives in a later milestone.
const Lesson sampleLesson = Lesson(
  id: 'py-variables-and-data-types',
  title: 'Variables & Data Types',
  description:
      'How Python names values, and the built-in types those values can have.',
  estimatedMinutes: 25,
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
      id: 'names-not-boxes',
      heading: 'Names, not boxes',
      blocks: [
        ProseBlock(
          'In many languages a variable is a box in memory: declaring it '
          'reserves space of a fixed size, and assigning to it copies bytes '
          'into that space. Python works differently. Every value is an '
          'object living on the heap, and a variable is just a name bound to '
          'one of those objects. Assignment never copies the object; it only '
          'points a name at it.',
        ),
        ProseBlock(
          'This is why Python has no type declarations. The name carries no '
          'type at all — the object it points to does. Rebinding a name to an '
          'object of a different type is legal, because you are changing what '
          'the name refers to, not changing the contents of a box.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
count = 42          # count now refers to an int object
print(type(count))  # <class 'int'>

count = "forty-two" # the same name, rebound to a str object
print(type(count))  # <class 'str'>

a = [1, 2, 3]
b = a               # b refers to the SAME list, not a copy
b.append(4)
print(a)            # [1, 2, 3, 4]
''',
          caption: 'Assignment binds a name; it does not copy the object.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Shared references bite',
          text:
              'Because b = a shares one list, mutating through either name is '
              'visible through both. Use list(a) or a.copy() when you want an '
              'independent copy.',
        ),
        ProseBlock(
          'The "is" operator tests identity — are these two names pointing at '
          'the exact same object? — while "==" tests equality — are these two '
          'objects meaningfully the same value? Because CPython caches small '
          'integers (-5 to 256) and may intern short strings, "is" can appear '
          'to work for value comparison in simple cases and then fail '
          'silently at scale. The rule: use "is" only for None, and "==" for '
          'everything else.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Small integers are cached — "is" happens to work... until it doesn't.
a = 256
b = 256
print(a is b)   # True — both point to the same cached 256

a = 257
b = 257
print(a is b)   # False — different objects at different addresses
print(a == b)   # True — equality is what you meant

# The one legitimate use of "is": comparing with None.
def process(data=None):
    if data is None:
        data = []
    # Now data is always a list, never None.
    data.append("result")
    return data
''',
          caption: '"is" compares identity, "==" compares value. Only use "is" for None.',
        ),
      ],
    ),
    Section(
      id: 'built-in-types',
      heading: 'The built-in types you will actually use',
      blocks: [
        ProseBlock(
          'Python ships with a small set of built-in types that cover most '
          'day-to-day work: int for whole numbers of unlimited precision, '
          'float for IEEE-754 doubles, str for immutable Unicode text, bool '
          'for True/False, and NoneType whose single value None means "no '
          'value". The container types — list, tuple, dict and set — hold '
          'references to other objects.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
whole      = 7                    # int
ratio      = 7 / 2                # float -> 3.5
floor_div  = 7 // 2               # int   -> 3
name       = "Ada"                # str
is_ready   = True                 # bool
nothing    = None                 # NoneType

scores     = [90, 85, 77]         # list  - ordered, mutable
point      = (3, 4)               # tuple - ordered, immutable
ages       = {"ada": 36}          # dict  - key -> value
unique     = {1, 2, 2, 3}         # set   - {1, 2, 3}

print(isinstance(is_ready, int))  # True: bool subclasses int
''',
          caption: 'One value of each core built-in type.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Check types with isinstance',
          text:
              'Prefer isinstance(x, int) over type(x) == int. isinstance '
              'respects subclassing, which is how bool relates to int.',
        ),
        CollapsibleBlock(
          title: 'Why does 0.1 + 0.2 != 0.3?',
          children: [
            ProseBlock(
              'float uses binary floating point, so decimal fractions like '
              '0.1 have no exact representation. The tiny rounding error is '
              'visible once you print enough digits. When exact decimal '
              'behaviour matters — money, most obviously — use the decimal '
              'module instead.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
print(0.1 + 0.2)            # 0.30000000000000004
print(0.1 + 0.2 == 0.3)     # False

from decimal import Decimal
print(Decimal("0.1") + Decimal("0.2") == Decimal("0.3"))  # True
''',
            ),
          ],
        ),
        ProseBlock(
          'Type annotations (x: int = 5) are optional metadata that the '
          'interpreter ignores at runtime. They exist for humans, IDEs, and '
          'static type checkers like mypy. Python remains dynamically typed '
          'regardless of annotations — adding : int does not prevent x from '
          'holding a string at runtime.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Type hints document intent; they are never enforced by the interpreter.
def greet(name: str, age: int) -> str:
    return f"{name} is {age} years old"

print(greet("Ada", 36))          # works
print(greet(42, "oops"))         # also works — hints are just metadata
print(greet.__annotations__)     # {'name': <class 'str'>, 'age': <class 'int'>, 'return': <class 'str'>}

# Use mypy to check hints statically (separate tool, not runtime).
# mypy script.py
''',
          caption: 'Annotations document; mypy checks them before runtime.',
        ),
      ],
    ),
    Section(
      id: 'mutability',
      heading: 'Mutable vs immutable',
      blocks: [
        ProseBlock(
          'The single most useful axis for sorting Python types is whether '
          'they can be changed in place. int, float, str, bool and tuple are '
          'immutable: every "change" produces a new object. list, dict and '
          'set are mutable: methods like append or update modify the existing '
          'object, and every name bound to it sees the change. Only immutable '
          'objects can be dictionary keys or set members.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
text = "hello"
upper = text.upper()
print(text, upper)      # hello HELLO  - text is unchanged

items = ["a"]
items.append("b")       # mutates in place, returns None
print(items)            # ['a', 'b']

lookup = {(0, 0): "origin"}   # tuple key: fine
# lookup[[0, 0]] = "origin"   # TypeError: unhashable type: 'list'
''',
        ),
        ProseBlock(
          'Understanding what happens when you call a method on an immutable '
          'object is critical. str.upper() returns a new string; the original '
          'is untouched. This is true for all immutable types. If you do not '
          'capture the return value — name = name.upper() — the new object is '
          'lost. This is why forgetting to rebind after calling an immutable '
          'method is one of the most common early mistakes.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Immutable: the original never changes. You MUST rebind.
name = "ada"
name.upper()           # returns "ADA" but does nothing with it
print(name)            # "ada" — unchanged!

name = name.upper()    # rebind the name to the new object
print(name)            # "ADA"

# Same pattern for any immutable type.
point = (3, 4)
# point[0] = 5         # TypeError: tuple does not support item assignment

# But a tuple containing a mutable object can be modified "through" the tuple.
nested = ([1, 2], "hello")
nested[0].append(3)
print(nested)          # ([1, 2, 3], 'hello') — the list inside mutated
try:
    hash(nested)       # TypeError: unhashable — the tuple contains a list
except TypeError as exc:
    print(exc)
''',
          caption: 'Immutable methods return new objects; mutable methods return None.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-describe-value',
      title: 'Report a value and its type',
      prompt: [
        ProseBlock(
          'Write describe(value) so it returns a string of the form '
          '"<repr> is a <type name>". Use repr() for the value and '
          'type(value).__name__ for the type. describe(42) must return '
          '"42 is a int" and describe("hi") must return "\'hi\' is a str".',
        ),
      ],
      starterCode: '''
def describe(value):
    # TODO: return "<repr> is a <type name>"
    ...


print(describe(42))
print(describe("hi"))
''',
      solutionCode: '''
def describe(value):
    return f"{value!r} is a {type(value).__name__}"


print(describe(42))       # 42 is a int
print(describe("hi"))     # 'hi' is a str
print(describe([1, 2]))   # [1, 2] is a list
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question: 'Why use repr() instead of str() here?',
          expectedAnswer:
              'repr() shows the value as it would appear in source code, so '
              'strings keep their quotes and 42 stays distinguishable from '
              '"42". str() would render both identically.',
        ),
        SelfCheckQuestion(
          question: 'What does describe(True) return, and why not "bool is int"?',
          expectedAnswer:
              '"True is a bool". type() reports the exact class, bool; the '
              'fact that bool subclasses int only shows up through isinstance.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-safe-copy',
      title: 'Stop a shared list from leaking',
      prompt: [
        ProseBlock(
          'add_score below is meant to return a new list with one extra score '
          'while leaving the caller\'s list untouched. As written it mutates '
          'the original. Fix it without using any imports.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def add_score(scores, score):
    scores.append(score)
    return scores
''',
        ),
      ],
      starterCode: '''
def add_score(scores, score):
    scores.append(score)
    return scores


original = [90, 85]
updated = add_score(original, 77)
print(original)   # should stay [90, 85]
print(updated)    # should be [90, 85, 77]
''',
      solutionCode: '''
def add_score(scores, score):
    return [*scores, score]


original = [90, 85]
updated = add_score(original, 77)
print(original)   # [90, 85]
print(updated)    # [90, 85, 77]
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question: 'Would scores + [score] also work?',
          expectedAnswer:
              'Yes. Both [*scores, score] and scores + [score] build a new '
              'list and leave the argument alone.',
        ),
        SelfCheckQuestion(
          question:
              'If the list held dictionaries, would this copy protect those too?',
          expectedAnswer:
              'No. It is a shallow copy: the new list holds the same dict '
              'objects, so mutating a dict is still visible to the caller. A '
              'deep copy would be needed for that.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-vars-mutable-default',
      title: 'Detect and fix the shared default trap',
      prompt: [
        ProseBlock(
          'The function below uses a mutable default argument. Explain why '
          'the second call does not return ["review"], then fix it so every '
          'call that omits tasks starts with a fresh empty list.',
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


print(add_task("write"))     # ['write']
print(add_task("review"))    # what does this print, and why?
''',
      solutionCode: '''
def add_task(name, tasks=None):
    if tasks is None:
        tasks = []
    tasks.append(name)
    return tasks


print(add_task("write"))              # ['write']
print(add_task("review"))             # ['review'] — fresh list each time
print(add_task("ship", ["draft"]))    # ['draft', 'ship']
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question: 'When is the default list [] actually created?',
          expectedAnswer:
              'Once, at definition time — when the def statement runs. It is '
              'stored in add_task.__defaults__ and every call that omits tasks '
              'mutates that one shared object.',
        ),
        SelfCheckQuestion(
          question: 'Why is None the right sentinel here?',
          expectedAnswer:
              'None is unique, immutable, and cannot be confused with a real '
              'argument. No caller would intentionally pass None to mean "here '
              'is my list of tasks", so it safely means "not provided".',
        ),
      ],
    ),
    Exercise(
      id: 'ex-vars-decimal',
      title: 'Handle money without floating point errors',
      prompt: [
        ProseBlock(
          'Write total_price(items) where items is a list of (quantity, '
          'unit_price) tuples. Use decimal.Decimal for all arithmetic so '
          'that the result is exact. Construct Decimals from strings, not '
          'floats. Return a Decimal rounded to two decimal places.',
        ),
      ],
      starterCode: '''
from decimal import Decimal, ROUND_HALF_UP


def total_price(items):
    # TODO: compute exact total using Decimal, round to 2 places
    ...


order = [(3, "4.99"), (1, "12.50"), (2, "0.79")]
print(total_price(order))    # should be exactly 29.05
''',
      solutionCode: '''
from decimal import Decimal, ROUND_HALF_UP


def total_price(items):
    total = Decimal("0")
    for quantity, unit_price in items:
        total += Decimal(unit_price) * quantity
    return total.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


order = [(3, "4.99"), (1, "12.50"), (2, "0.79")]
print(total_price(order))    # 29.05 — no floating-point rounding surprise
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question: 'Why build Decimal from strings rather than floats?',
          expectedAnswer:
              'Decimal(0.1) captures the float approximation of 0.1 first, '
              'then converts it. Decimal("0.1") creates the exact value '
              'directly. Constructing from strings avoids importing the very '
              'floating-point error you are trying to escape.',
        ),
        SelfCheckQuestion(
          question:
              'Why use .quantize() instead of round()?',
          expectedAnswer:
              'round() with Decimals does banker\'s rounding (round half to '
              'even), which can produce unexpected results for financial '
              'applications. quantize() gives explicit control over the '
              'rounding strategy.',
        ),
      ],
    ),
  ],
);

const GameContent _play = GameContent(
  games: [
    TermMatchGame(
      id: 'game-variables-terms',
      title: 'Match the vocabulary',
      instructions: 'Tap a term, then tap its definition.',
      pairs: [
        TermPair(
          term: 'Binding',
          definition: 'Associating a name in a namespace with an object.',
        ),
        TermPair(
          term: 'Aliasing',
          definition: 'Two or more names referring to the same object.',
        ),
        TermPair(
          term: 'Immutability',
          definition: 'A property of objects that cannot change after construction.',
        ),
        TermPair(
          term: 'Hashability',
          definition: 'Having a stable hash value, so an object can be a dict key.',
        ),
      ],
    ),
    OutputPredictorGame(
      id: 'game-variables-aliasing-output',
      title: 'What does this print?',
      instructions: 'Pick what the last line prints.',
      code: '''
a = [1, 2, 3]
b = a
b.append(4)
print(a)
''',
      options: ['[1, 2, 3]', '[1, 2, 3, 4]', '[4, 1, 2, 3]', 'TypeError'],
      correctIndex: 1,
      explanation:
          'b = a binds a second name to the same list object — nothing is '
          'copied. Appending through b mutates that one shared list, so a '
          'sees the extra element too.',
    ),
    FillBlankGame(
      id: 'game-variables-isinstance',
      title: 'Check the type safely',
      instructions: 'Type the missing function name.',
      code: '''
is_ready = True
print(______(is_ready, int))   # True: bool subclasses int
''',
      blanks: [Blank(answer: 'isinstance', hint: 'built-in function')],
    ),
    BugHuntGame(
      id: 'game-variables-shared-list-bug',
      title: 'Find the leaking mutation',
      instructions: 'Tap the line that mutates the caller\'s list by mistake.',
      code: '''
def add_score(scores, score):
    scores.append(score)
    return scores


original = [90, 85]
updated = add_score(original, 77)
print(original)
''',
      buggyLine: 2,
      explanation:
          'scores.append(score) mutates the very list the caller passed in — '
          'scores and original name the same object. Build a new list '
          'instead: return [*scores, score].',
      fixedCode: '''
def add_score(scores, score):
    return [*scores, score]


original = [90, 85]
updated = add_score(original, 77)
print(original)   # [90, 85]
print(updated)    # [90, 85, 77]
''',
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 96000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Ninety seconds on Python variables — and here\'s the big idea. '
              'Imagine you have a sticky note with "42" on it. '
              'You can move that sticky note from your monitor to your fridge — '
              'the note stays the same, you\'re just changing where it lives. '
              'That\'s exactly how Python variables work: they\'re labels, not boxes.',
          startMs: 0,
          endMs: 16000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Exactly. When you say x equals 5, Python creates the number 5 somewhere in memory, '
              'then sticks the label "x" on it. The label has no type — it\'s just a name. '
              'The number 5 is what knows it\'s an integer. '
              'And if you later point x at a string, no problem — you just moved the label.',
          startMs: 16000,
          endMs: 38000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Here are the types you\'ll actually use every day. Numbers: int for whole numbers, float for decimals. '
              'Text: str. True or False: bool. "There\'s nothing here": None. '
              'Then the containers — list, tuple, dict, and set. '
              'Think of them like kitchen storage: list is a drawer you can rearrange, '
              'dict is a labelled cabinet, set is a bowl that won\'t hold duplicates.',
          startMs: 38000,
          endMs: 60000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'And here\'s the key that unlocks almost all confusion: mutability. '
              'Some things you can change after creating them — lists and dicts are like a whiteboard. '
              'Others are set in stone — strings and tuples are more like a printed book. '
              'Once you know which is which, most Python surprises just disappear.',
          startMs: 60000,
          endMs: 84000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text: 'So remember: names are sticky notes, objects know their own types, '
              'and mutability tells you what can change and what can\'t. '
              'That\'s it — you\'ve got the foundation everything else builds on.',
          startMs: 84000,
          endMs: 96000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 258000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Welcome back! Today we\'re talking about something that seems almost too simple: '
              'variables and data types. You know, it\'s like learning to walk — '
              'everyone assumes they already know how, '
              'but if your footing is slightly off, you\'ll stumble months later '
              'and have no idea why. Trust me, this one\'s worth the attention.',
          startMs: 0,
          endMs: 24000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Most of us come in carrying mental baggage from other languages. '
              'In Java or C, a variable is like a parking space — it has a fixed size, '
              'a specific type, and when you assign, you\'re copying a car into that spot. '
              'Python is completely different. The value lives wherever it wants in memory, '
              'and the variable? It\'s just a sticky note you slap on it. '
              'No copying, no fixed size, no type on the label.',
          startMs: 24000,
          endMs: 56000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'And this is where it gets fun. You can write count equals 42, '
              'then literally the next line write count equals "forty-two" as a string, '
              'and Python just nods. No complaints, no type errors. '
              'Because you didn\'t change what\'s inside count — you just peeled the label off one object '
              'and stuck it on another. Totally different from a language that would scream at you.',
          startMs: 56000,
          endMs: 86000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'But here\'s the catch — and it\'s bitten every Python programmer at least once. '
              'Say you have a shopping list taped to your fridge, '
              'and you tell your roommate "hey, the list is on the fridge." '
              'If your roommate adds "ice cream" — you both see it, because there\'s only one list. '
              'That\'s aliasing. b equals a doesn\'t make a copy; '
              'it just gives the same object a second name.',
          startMs: 86000,
          endMs: 124000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Alright, quick tour of the type family. int is your whole number — '
              'and unlike some languages, it\'ll never overflow no matter how big it gets. '
              'float handles decimals, but fair warning: it uses binary under the hood, '
              'so 0.1 plus 0.2 isn\'t exactly 0.3. str is text, always Unicode, never changes after creation. '
              'bool is just True and False — fun fact, it\'s actually a subclass of int, '
              'so True is really 1 wearing a fancy hat. And None? '
              'That\'s the polite way of saying "nothing here, move along."',
          startMs: 124000,
          endMs: 168000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Now the containers — think of them as different ways to organize a desk. '
              'A list is like a stack of papers you can shuffle, add to, or remove from. '
              'A tuple is like a museum display — once it\'s set, nothing moves. '
              'A dict is your filing cabinet: every folder has a label, and you go straight to it. '
              'A set is like a guest list at a club — no duplicates allowed, '
              'and checking who\'s inside is lightning fast. '
              'Oh, and dict keys and set items need to be hashable — which mostly just means immutable. '
              'That\'s why a tuple can be a key but a list can\'t.',
          startMs: 168000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'So here\'s your mental checklist for any Python variable you encounter: '
              'One — what actual object is this name pointing at right now? '
              'Two — what type is that object? '
              'Three — can someone else change it out from under me? '
              'Answer those three questions and Python goes from mysterious to predictable overnight.',
          startMs: 214000,
          endMs: 258000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 420000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Welcome to the deep dive! We\'re going under the hood today — '
              'reference semantics, Python\'s object model, and those sneaky CPython details '
              'that quietly affect code you\'ll actually write. '
              'Think of this as the factory tour — you\'ll see how the machinery works, '
              'so when it makes a funny noise, you\'ll know exactly why.',
          startMs: 0,
          endMs: 32000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Let\'s start at the very bottom. Every single Python object — even the number 1 — '
              'has a tiny ID card attached to it: a type pointer saying "I\'m an int" '
              'and a reference count tracking how many names are pointing at it. '
              'When you assign a variable, you\'re not copying data — you\'re just '
              'writing a pointer in a namespace and bumping that counter by one. '
              'It\'s like a coat check system: the object is the coat, '
              'the variable is the claim ticket.',
          startMs: 32000,
          endMs: 78000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'This sets up one of the classic gotchas: "is" versus double equals. '
              '"is" asks "are these the exact same coat check ticket?" — it compares memory addresses. '
              'Double equals asks "do these coats look the same?" — it calls the __eq__ method. '
              'Here\'s where it gets tricky: CPython recycles small integers from -5 to 256, '
              'and sometimes interns short strings. So "a is b" might accidentally be True '
              'when they\'re small numbers, and False when they\'re big ones. '
              'The rule: only use "is" for None, and use double equals for everything else.',
          startMs: 78000,
          endMs: 138000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Let\'s dig deeper on mutability — it\'s the concept that explains half of Python\'s design choices. '
              'Imagine you\'re at a potluck. An immutable dish is one that\'s already plated — '
              'you can share it freely because nobody can take a bite out of your portion. '
              'A mutable dish is a communal bowl — if someone adds hot sauce, everyone tastes it. '
              'This is why dict keys must be hashable: the hash is like a table number, '
              'and if your dish changes after being placed, nobody can find it anymore. '
              'That\'s exactly why lists can\'t be dict keys — they\'re mutable.',
          startMs: 138000,
          endMs: 196000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Now, the trap that catches literally everyone. Say you write a function with items equals an empty list as default. '
              'Here\'s the thing: that empty list is created once, when Python reads your def statement, '
              'not each time you call the function. It\'s like a shared office stapler — '
              'everyone who comes to the desk uses the same one, and it accumulates everyone\'s staples. '
              'The fix is beautifully simple: default to None, then inside the function, '
              'create a fresh list if items is still None.',
          startMs: 196000,
          endMs: 248000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'And a quick word on floating point, because this one drives people crazy. '
              'Floats use binary, and some decimal numbers — like 0.1 — are repeating fractions in binary, '
              'just like one-third is 0.33333... in decimal. So 0.1 plus 0.2 equals 0.30000000000000004. '
              'For money, reach for Decimal — but construct it from strings, not floats. '
              'For exact fractions, there\'s Fraction. And for comparisons, use math.isclose. '
              'Throwing round() at the problem just sweeps the dust under the rug.',
          startMs: 248000,
          endMs: 306000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'One last thing about type hints, since people often wonder if they change the game. '
              'They don\'t. If you write x colon int, you\'re leaving a note for your IDE and for mypy — '
              'it\'s like writing "fragile" on a box. The interpreter reads it, shrugs, and moves on. '
              'At runtime, Python stays as dynamically typed as ever. '
              'The hints are documentation that a machine can check, not enforcement.',
          startMs: 306000,
          endMs: 356000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'So let\'s wrap up with the three pillars. Names are sticky notes — they don\'t hold data, they point to it. '
              'Objects own their type — the value knows what it is, not the label. '
              'And mutability is the great divider — it determines whether change is a shared surprise or a local affair. '
              'Everything coming up — functions, classes, closures, async — sits squarely on these three ideas. '
              'Get comfortable with them now and everything else clicks faster.',
          startMs: 356000,
          endMs: 420000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Variables are names, not boxes',
      body:
          'Assignment binds a name to an object on the heap. It never copies, '
          'and the name has no type of its own — the object does. Two names '
          'bound to one mutable object see each other\'s changes.',
    ),
    SummaryCard(
      title: 'Mutability is the axis that matters',
      body:
          'int, float, str, bool and tuple are immutable; list, dict and set '
          'are mutable. Only immutable (hashable) objects can be dict keys or '
          'set members.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Binding',
      definition:
          'Associating a name in a namespace with an object. Rebinding points '
          'the name elsewhere and leaves the original object untouched.',
    ),
    KeyConcept(
      term: 'Aliasing',
      definition:
          'Two or more names referring to the same object, so a mutation made '
          'through one name is visible through all of them.',
    ),
    KeyConcept(
      term: 'Immutability',
      definition:
          'A property of objects that cannot change after construction. '
          'Operations that appear to modify them return new objects instead.',
    ),
    KeyConcept(
      term: 'Hashability',
      definition:
          'An object has a stable hash value and can be used as a dict key or '
          'set member. Built-in mutable containers are deliberately '
          'unhashable.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Copying a list with b = a, then mutating b and expecting a to be '
          'unchanged.',
      correction:
          'b = a only adds a second name for one list. Use list(a), a.copy() '
          'or [*a] for an independent shallow copy.',
    ),
    Mistake(
      mistake: 'Using a mutable default argument, e.g. def f(items=[]).',
      correction:
          'The default is created once at definition time and shared across '
          'calls. Default to None and create the list inside the function.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question: 'What is the difference between "is" and "==" in Python?',
      answer:
          '"is" tests object identity — whether two names point at the same '
          'object — while "==" calls __eq__ and tests value equality. Use "is" '
          'only for singletons such as None; small-int and string caching can '
          'make "is" appear to work on values by accident.',
    ),
    InterviewQuestion(
      question: 'Why can a tuple be a dictionary key but a list cannot?',
      answer:
          'Dict keys must be hashable, and a hash must stay constant for the '
          'object\'s lifetime. Tuples are immutable so their hash is stable, '
          'while lists can be mutated in place, which would silently move the '
          'entry to the wrong bucket. A tuple containing a list is itself '
          'unhashable for the same reason.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'Data Types — Python 3.14.6 documentation',
    url: 'https://docs.python.org/3/library/datatypes.html',
    description:
        'Standard library reference for the modules that supplement the '
        'built-in types, including datetime, decimal and enum.',
  ),
  Source(
    title: '5. Data Structures — Python 3.14.6 documentation',
    url: 'https://docs.python.org/3/tutorial/datastructures.html',
    description:
        'Tutorial chapter covering lists, tuples, dictionaries and sets, with '
        'the operations available on each.',
  ),
];

const List<Source> _furtherReading = [
  Source(
    title: 'Variables in Python — Real Python',
    url: 'https://realpython.com/python-variables/',
    description:
        'Deep dive into variable assignment, object references, identity '
        'vs equality, and the "everything is an object" model.',
  ),
  Source(
    title: 'Basic Data Types in Python — Real Python',
    url: 'https://realpython.com/python-data-types/',
    description:
        'Tour of int, float, str, bool, and NoneType with practical '
        'examples of type conversion, arithmetic, and string operations.',
  ),
  Source(
    title: 'Python\'s Mutable vs Immutable Types — Real Python',
    url: 'https://realpython.com/python-mutable-vs-immutable-types/',
    description:
        'Explains the mutable/immutable distinction, why it matters for '
        'dict keys and function defaults, and how to use it correctly.',
  ),
  Source(
    title: 'Floating Point Arithmetic: Issues and Limitations — Python Docs',
    url: 'https://docs.python.org/3/tutorial/floatingpoint.html',
    description:
        'Official explanation of why 0.1 + 0.2 != 0.3, and how decimal '
        'and fractions modules provide exact alternatives.',
  ),
];

/// The sample lesson wrapped in its module and topic, so the full hierarchy is
/// exercised.
const Module sampleModule = Module(
  id: 'py-foundations',
  title: 'Python Foundations',
  description:
      'The core language mechanics every later Python topic builds on.',
  lessons: [sampleLesson],
);

const Topic sampleTopic = Topic(
  id: 'python',
  title: 'Python',
  description:
      'A practical path through Python, from the object model to the tools '
      'you will use every day.',
  iconName: 'code',
  modules: [sampleModule],
);
