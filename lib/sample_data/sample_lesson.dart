import '../models/content_block.dart';
import '../models/exercise.dart';
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
  estimatedMinutes: 18,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  review: _review,
  sources: _sources,
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
              'Ninety seconds on Python variables. The one idea to take away: '
              'a variable is a name, not a box.',
          startMs: 0,
          endMs: 16000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Right. Assignment binds a name to an object that already '
              'exists on the heap. Nothing is copied, and the name itself has '
              'no type — the object does.',
          startMs: 16000,
          endMs: 38000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'The built-ins worth memorising are int, float, str, bool and '
              'None, plus the containers: list, tuple, dict and set.',
          startMs: 38000,
          endMs: 60000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'And sort them by mutability. Strings and tuples are immutable, '
              'lists and dicts are not. That single distinction explains most '
              'surprises beginners hit.',
          startMs: 60000,
          endMs: 84000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text: 'Names bind, objects have types, mutability decides. Done.',
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
              'Welcome back. Today: variables and data types in Python. It '
              'looks like the easiest topic in the language, and it is the one '
              'that quietly causes the most bugs six months later.',
          startMs: 0,
          endMs: 24000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Because people carry over a mental model from C or Java. There, '
              'a variable is storage of a declared type and assignment copies '
              'bytes into it. In Python the object lives on the heap and the '
              'variable is a label you stick on it.',
          startMs: 24000,
          endMs: 56000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Which is why you can write count equals forty-two, then count '
              'equals the string "forty-two", and Python does not complain. '
              'You moved the label; you did not change a box.',
          startMs: 56000,
          endMs: 86000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'The flip side is aliasing. If b equals a, and a is a list, both '
              'names point at one list. Append through b and a sees it. That '
              'is not a bug in Python, it is the direct consequence of names '
              'binding rather than copying.',
          startMs: 86000,
          endMs: 124000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Let us do the type tour. int is arbitrary precision, so no '
              'overflow. float is a normal IEEE double, with all the usual '
              'rounding surprises. str is immutable Unicode text. bool is '
              'True and False, and it is technically a subclass of int. None '
              'is the single value meaning "nothing here".',
          startMs: 124000,
          endMs: 168000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Then the containers. list is ordered and mutable, tuple is '
              'ordered and immutable, dict maps keys to values, and set holds '
              'unique members. Keys and set members must be hashable, which in '
              'practice means immutable — that is why a tuple can be a key and '
              'a list cannot.',
          startMs: 168000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'So the checklist: what object does this name point at, what '
              'type is that object, and can anyone else mutate it. Answer '
              'those three and Python stops being surprising.',
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
              'This is the long version, so we are going below the surface: '
              'reference semantics, the object model, and the places where '
              'CPython implementation details leak into code you will write.',
          startMs: 0,
          endMs: 32000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with the object header. Every Python object carries a '
              'type pointer and a reference count. A name in a scope is an '
              'entry in a namespace dictionary, or a slot in a function frame, '
              'holding a pointer to that object. Assignment writes the '
              'pointer and bumps the count.',
          startMs: 32000,
          endMs: 78000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'That explains the identity operator. "is" compares pointers, '
              'while "==" calls __eq__. Beginners hit this when small integers '
              'and short strings appear to be identical objects — CPython '
              'caches ints from minus five to two hundred fifty six and '
              'interns some strings. Never rely on it; compare with == unless '
              'you genuinely mean identity, as with None.',
          startMs: 78000,
          endMs: 138000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Mutability deserves the same depth. An immutable object can be '
              'shared freely because nobody can change it underneath you. That '
              'is what makes hashing safe: hash values must stay stable for '
              'the lifetime of a dict key. Mutate a key in place and you '
              'corrupt the table — which is exactly why list is unhashable.',
          startMs: 138000,
          endMs: 196000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'The classic trap is the mutable default argument. Write def f, '
              'items equals empty list, and that list is created once when the '
              'function is defined, then reused on every call. The fix is a '
              'default of None and building a fresh list inside the body.',
          startMs: 196000,
          endMs: 248000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'And numeric precision. float is binary, so 0.1 plus 0.2 is not '
              'exactly 0.3. For money use decimal.Decimal constructed from '
              'strings; for exact ratios use fractions.Fraction; for tolerance '
              'comparisons use math.isclose. Reaching for round() as a fix '
              'usually just moves the error somewhere less visible.',
          startMs: 248000,
          endMs: 306000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Worth saying that type hints change none of this. Annotating x '
              'as int is documentation plus a signal to a static checker; the '
              'interpreter does not enforce it at runtime. Dynamic typing '
              'stays dynamic.',
          startMs: 306000,
          endMs: 356000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'To close: names bind to objects, objects own their type, and '
              'mutability determines who can be surprised by a change. Every '
              'later topic — functions, classes, closures, concurrency — is '
              'built on those three facts.',
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
