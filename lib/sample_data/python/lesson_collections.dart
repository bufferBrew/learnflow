import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 1: the container types and the standard library that
/// extends them.
const Lesson collectionsLesson = Lesson(
  id: 'py-lists-dicts-collections',
  title: 'Lists, Dicts & Collections',
  description:
      'Choosing the right container, and the comprehensions and collections '
      'module that make them pleasant to use.',
  estimatedMinutes: 24,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  play: _play,
  review: _review,
  sources: _sources,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'lists',
      heading: 'Lists and slicing',
      blocks: [
        ProseBlock(
          'A list is an ordered, mutable sequence of references. Appending is '
          'fast because CPython over-allocates the underlying array, so growth '
          'is amortised constant time. Inserting or deleting at the front is '
          'linear, because every later element has to shift — which is the one '
          'performance fact about lists worth remembering.',
        ),
        ProseBlock(
          'Slicing takes start, stop and step, with stop exclusive, and always '
          'produces a new list. A negative step walks backwards; omitted '
          'bounds mean "from the beginning" and "to the end". Because a slice '
          'is a copy, items[:] is a quick shallow copy — though list(items) '
          'says so more clearly.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
scores = [90, 85, 77, 61, 100]

print(scores[0], scores[-1])      # 90 100
print(scores[1:3])                # [85, 77]   stop is exclusive
print(scores[:2], scores[3:])     # [90, 85] [61, 100]
print(scores[::2])                # [90, 77, 100]
print(scores[::-1])               # reversed copy

scores.append(72)                 # O(1) amortised, at the end
scores.insert(0, 55)              # O(n): everything shifts right
top = sorted(scores, reverse=True)[:3]
print(top)                        # [100, 90, 85]

scores.sort()                     # sorts in place, returns None
print(scores)
''',
          caption: 'Slices copy; sort() mutates while sorted() returns a list.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'sort() returns None',
          text:
              'Methods that mutate in place — sort, reverse, append, extend — '
              'return None by convention. best = scores.sort() silently binds '
              'None. Use sorted(scores) when you want a value back.',
        ),
      ],
    ),
    Section(
      id: 'dicts',
      heading: 'Dictionaries: the workhorse',
      blocks: [
        ProseBlock(
          'A dict maps hashable keys to arbitrary values with average O(1) '
          'lookup, insertion and deletion. Since Python 3.7 insertion order is '
          'a guaranteed part of the language, not an implementation detail, so '
          'iteration yields keys in the order they were first added.',
        ),
        ProseBlock(
          'Three access patterns cover nearly everything: d[key] when a missing '
          'key is a bug and should raise KeyError; d.get(key, default) when it '
          'is not; and d.setdefault(key, default) when you want to insert the '
          'default at the same time. items(), keys() and values() return live '
          'views, so they reflect later changes to the dict rather than '
          'snapshotting it.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
inventory = {"apples": 12, "pears": 3}

inventory["plums"] = 7            # insert
inventory["apples"] += 1          # update

print(inventory.get("figs"))          # None - no exception
print(inventory.get("figs", 0))       # 0
print(inventory.setdefault("figs", 0))  # inserts figs=0 and returns 0

for name, count in inventory.items():
    print(f"{name}: {count}")

print("pears" in inventory)       # True - checks keys, and it is O(1)

# Merge: right-hand side wins on conflicts.
defaults = {"colour": "red", "size": "M"}
chosen = defaults | {"size": "L"}
print(chosen)                     # {'colour': 'red', 'size': 'L'}
''',
          caption: 'get, setdefault and the | merge operator (3.9+).',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Membership tests are where dicts and sets earn their keep',
          text:
              '"x in some_list" scans the whole list; "x in some_dict" or '
              '"x in some_set" hashes once. Converting a list to a set before a '
              'loop of membership tests turns an O(n*m) loop into O(n+m).',
        ),
      ],
    ),
    Section(
      id: 'sets-tuples',
      heading: 'Sets and tuples: the other two',
      blocks: [
        ProseBlock(
          'A set is an unordered collection of unique, hashable objects. It is '
          'the right answer to "have I seen this before", "what do these two '
          'collections have in common" and "remove the duplicates" — all of '
          'which are one operator or one call.',
        ),
        ProseBlock(
          'A tuple is an immutable sequence. Use one for a fixed-size record '
          'whose positions mean different things — a coordinate, a database '
          'row, a function returning two values — and a list for a variable '
          'number of homogeneous items. Because tuples are immutable they are '
          'hashable, so they can be dict keys and set members.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
seen = {"ada", "grace"}
seen.add("alan")
print("ada" in seen)              # True

a = {1, 2, 3, 4}
b = {3, 4, 5}
print(a & b)                      # {3, 4}     intersection
print(a | b)                      # {1,2,3,4,5} union
print(a - b)                      # {1, 2}     difference
print(a ^ b)                      # {1, 2, 5}  symmetric difference

print(list(dict.fromkeys([3, 1, 3, 2])))   # [3, 1, 2] - dedupe, order kept
print(sorted(set([3, 1, 3, 2])))           # [1, 2, 3] - dedupe, sorted

point = (3, 4)
x, y = point                      # unpacking
grid = {(0, 0): "origin", point: "corner"}
print(grid[(3, 4)])               # corner

empty_set = set()                 # {} would be an empty dict
''',
          caption: 'Set algebra, deduplication and tuples as keys.',
        ),
      ],
    ),
    Section(
      id: 'comprehensions',
      heading: 'Comprehensions',
      blocks: [
        ProseBlock(
          'A comprehension builds a list, dict or set from an iterable in one '
          'expression. It is not merely shorter than the equivalent loop: it '
          'states that the result is a new collection derived from an old one, '
          'which is a stronger claim than a loop full of appends. There are '
          'list, set and dict forms, plus generator expressions that produce '
          'values lazily.',
        ),
        ProseBlock(
          'Keep them flat. One for clause and one optional if clause is '
          'comfortable; two nested fors with a condition is where readers start '
          'losing track, and a plain loop becomes the kinder choice. Note also '
          'that a comprehension has its own scope — its loop variable does not '
          'leak into the surrounding function.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
words = ["Ada", "grace", "ALAN", "hopper"]

lowered = [w.lower() for w in words]
short = [w for w in words if len(w) <= 4]
lengths = {w: len(w) for w in words}
initials = {w[0].lower() for w in words}

print(lowered)    # ['ada', 'grace', 'alan', 'hopper']
print(short)      # ['Ada', 'ALAN']
print(lengths)    # {'Ada': 3, 'grace': 5, 'ALAN': 4, 'hopper': 6}
print(initials)   # {'a', 'g', 'h'}

# Generator expression: no list is built, values arrive one at a time.
total_length = sum(len(w) for w in words)
print(total_length)               # 18

# Nested loop: the clauses read in the same order as the equivalent for loops.
pairs = [(a, b) for a in (1, 2) for b in ("x", "y")]
print(pairs)      # [(1, 'x'), (1, 'y'), (2, 'x'), (2, 'y')]
''',
          caption: 'List, set, dict and generator forms.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Use a generator expression inside a call',
          text:
              'sum(len(w) for w in words) needs no extra brackets and builds no '
              'intermediate list. Only materialise a list when you need to '
              'index it, keep it, or iterate over it more than once.',
        ),
      ],
    ),
    Section(
      id: 'collections-module',
      heading: 'The collections module',
      blocks: [
        ProseBlock(
          'Four types in the standard library remove most hand-written '
          'container bookkeeping. Counter counts hashable items and can report '
          'the most common ones. defaultdict calls a factory the first time a '
          'missing key is accessed, so grouping needs no setdefault. deque is a '
          'double-ended queue with O(1) appends and pops at both ends. '
          'namedtuple gives a tuple\'s fields names.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from collections import Counter, defaultdict, deque, namedtuple

text = "the rain in spain stays mainly in the plain"

counts = Counter(text.split())
print(counts.most_common(2))      # [('in', 2), ('the', 2)]

by_initial = defaultdict(list)
for word in text.split():
    by_initial[word[0]].append(word)
print(by_initial["s"])            # ['spain', 'stays']

recent = deque(maxlen=3)          # a bounded history buffer
for page in ["a", "b", "c", "d"]:
    recent.append(page)
print(list(recent))               # ['b', 'c', 'd']

Point = namedtuple("Point", "x y")
p = Point(3, 4)
print(p.x, p[1], p._replace(y=9)) # 3 4 Point(x=3, y=9)
''',
          caption: 'Counter, defaultdict, deque and namedtuple.',
        ),
        CollapsibleBlock(
          title: 'Under the hood: why dict lookup is O(1), and what it costs',
          children: [
            ProseBlock(
              'A dict is an open-addressed hash table. Looking up a key hashes '
              'it, uses the low bits of that hash to pick a slot, and compares '
              'the stored key — first by identity, then by equality. Collisions '
              'probe other slots, so worst-case lookup is linear, but with a '
              'decent hash function it is constant on average. When the table '
              'gets about two-thirds full it is resized and every entry is '
              'rehashed.',
            ),
            ProseBlock(
              'The consequences are practical. Keys must be hashable, and their '
              'hash must never change while they are in use — that is exactly '
              'why mutable built-ins are unhashable. Two objects that compare '
              'equal must have the same hash, so if you write __eq__ on a class '
              'you must write __hash__ too or the type becomes unhashable. And '
              'a dict trades memory for speed: since 3.6 the layout is split '
              'into a compact insertion-ordered entries array plus a sparse '
              'index array, which is what made ordering free.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
class Tag:
    def __init__(self, name):
        self.name = name

    def __eq__(self, other):
        return isinstance(other, Tag) and self.name == other.name

    # Defining __eq__ sets __hash__ to None; restore it explicitly.
    def __hash__(self):
        return hash(self.name)


print(len({Tag("a"), Tag("a")}))   # 1 - equal and same hash, so deduped
''',
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
      id: 'ex-col-wordcount',
      title: 'Count words two ways',
      prompt: [
        ProseBlock(
          'Write word_counts(text) returning a dict mapping each lowercase word '
          'to how many times it appears. Write it once by hand with a plain '
          'dict, then again in one line with collections.Counter, and satisfy '
          'yourself that both produce equal results.',
        ),
      ],
      starterCode: '''
def word_counts(text):
    counts = {}
    for word in text.lower().split():
        # TODO: increment the count for word without a KeyError
        ...
    return counts


sample = "the cat the hat the end"
print(word_counts(sample))
''',
      solutionCode: '''
from collections import Counter


def word_counts(text):
    counts = {}
    for word in text.lower().split():
        counts[word] = counts.get(word, 0) + 1
    return counts


def word_counts_fast(text):
    return dict(Counter(text.lower().split()))


sample = "the cat the hat the end"
print(word_counts(sample))
# {'the': 3, 'cat': 1, 'hat': 1, 'end': 1}
print(word_counts(sample) == word_counts_fast(sample))   # True
print(Counter(sample.split()).most_common(1))            # [('the', 3)]
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why is counts.get(word, 0) + 1 preferable to checking "if word '
              'in counts" first?',
          expectedAnswer:
              'It hashes the key once instead of twice and expresses the intent '
              '— "the count so far, defaulting to zero" — in a single '
              'expression. The membership test version is not wrong, just '
              'noisier and slightly slower.',
        ),
        SelfCheckQuestion(
          question: 'Is a Counter a dict, and what does it do differently?',
          expectedAnswer:
              'It is a dict subclass, so every dict operation works on it. The '
              'differences are that a missing key returns 0 instead of raising, '
              'it adds most_common, and it supports arithmetic between counters '
              'such as addition and subtraction.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-col-group',
      title: 'Group records without setdefault',
      prompt: [
        ProseBlock(
          'Given a list of (department, name) tuples, write group_by_department '
          'returning a dict mapping each department to a list of names, in the '
          'order they appeared. Use collections.defaultdict so no key has to be '
          'initialised by hand, and return a plain dict.',
        ),
      ],
      starterCode: '''
from collections import defaultdict

staff = [
    ("eng", "ada"),
    ("ops", "grace"),
    ("eng", "alan"),
]


def group_by_department(records):
    # TODO: use a defaultdict(list), then return a plain dict
    ...


print(group_by_department(staff))
''',
      solutionCode: '''
from collections import defaultdict

staff = [
    ("eng", "ada"),
    ("ops", "grace"),
    ("eng", "alan"),
]


def group_by_department(records):
    grouped = defaultdict(list)
    for department, name in records:
        grouped[department].append(name)
    return dict(grouped)


print(group_by_department(staff))
# {'eng': ['ada', 'alan'], 'ops': ['grace']}
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why convert back to a plain dict before returning it?',
          expectedAnswer:
              'A defaultdict silently creates an entry whenever a caller reads a '
              'missing key, which turns a typo into a new empty group instead '
              'of a KeyError. Returning dict(grouped) gives callers normal '
              'lookup semantics.',
        ),
        SelfCheckQuestion(
          question:
              'The keys come out in the order the departments were first seen. '
              'Is that guaranteed?',
          expectedAnswer:
              'Yes. Since Python 3.7 dicts preserve insertion order as part of '
              'the language spec, and defaultdict is a dict subclass, so first '
              'appearance determines position.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-col-dedupe',
      title: 'Deduplicate while keeping order',
      prompt: [
        ProseBlock(
          'Write unique(items) that removes duplicates but preserves the order '
          'of first appearance. sorted(set(items)) loses the order and needs '
          'the items to be comparable — do not use it. Aim for a single pass '
          'with O(n) total work.',
        ),
      ],
      starterCode: '''
def unique(items):
    # TODO: one pass, remember what has been seen, keep first-seen order
    ...


print(unique(["b", "a", "b", "c", "a"]))   # ['b', 'a', 'c']
''',
      solutionCode: '''
def unique(items):
    seen = set()
    result = []
    for item in items:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result


print(unique(["b", "a", "b", "c", "a"]))   # ['b', 'a', 'c']

# Same thing, exploiting guaranteed dict ordering:
print(list(dict.fromkeys(["b", "a", "b", "c", "a"])))   # ['b', 'a', 'c']
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why keep a separate seen set rather than testing "if item not in '
              'result"?',
          expectedAnswer:
              'Membership in a list is a linear scan, making the whole function '
              'O(n squared). A set hashes once, so the loop stays O(n) overall '
              'at the cost of holding one extra collection.',
        ),
        SelfCheckQuestion(
          question: 'What happens if items contains lists?',
          expectedAnswer:
              'TypeError: unhashable type. Both the set version and '
              'dict.fromkeys need hashable items. For unhashable elements you '
              'have to fall back to a linear comparison, or key on something '
              'hashable derived from each item, such as a tuple of its '
              'contents.',
        ),
      ],
    ),
  ],
);

const GameContent _play = GameContent(
  games: [
    FillBlankGame(
      id: 'game-collections-comprehension',
      title: 'Filter with a comprehension',
      instructions: 'Type the missing keyword.',
      code: '''
words = ["Ada", "grace", "ALAN"]
short = [w for w in words ______ len(w) <= 4]
print(short)
''',
      blanks: [Blank(answer: 'if', hint: 'comprehension keyword')],
    ),
    BugHuntGame(
      id: 'game-collections-sort-none',
      title: 'Find the None',
      instructions: 'Tap the line that binds best to the wrong thing.',
      code: '''
scores = [90, 85, 77]
best = scores.sort()
print(best)
''',
      buggyLine: 2,
      explanation:
          'sort() mutates the list in place and returns None, like every '
          'method that mutates. best ends up bound to None instead of a '
          'sorted list — use sorted(scores) when you want a value back.',
      fixedCode: '''
scores = [90, 85, 77]
best = sorted(scores)
print(best)   # [77, 85, 90]
''',
    ),
    OutputPredictorGame(
      id: 'game-collections-slice-output',
      title: 'What does this print?',
      instructions: 'Pick what the slice expression prints.',
      code: '''
scores = [90, 85, 77, 61, 100]
print(scores[::-1][:2])
''',
      options: ['[90, 85]', '[100, 61]', '[100, 90]', '[61, 100]'],
      correctIndex: 1,
      explanation:
          'scores[::-1] reverses the list to [100, 61, 77, 85, 90]; slicing '
          'that reversed copy with [:2] keeps its first two elements.',
    ),
    SyntaxScrambleGame(
      id: 'game-collections-scramble',
      title: 'Rebuild the dict comprehension',
      instructions: 'Drag or use the arrows to put these lines back in order.',
      lines: [
        'def word_lengths(words):',
        '    lengths = {w: len(w) for w in words}',
        '    return lengths',
        'print(word_lengths(["Ada", "grace"]))',
      ],
    ),
    TermMatchGame(
      id: 'game-collections-terms',
      title: 'Match the vocabulary',
      instructions: 'Tap a term, then tap its definition.',
      pairs: [
        TermPair(
          term: 'Hashable',
          definition: 'Has a stable hash, so it can be a dict key or set member.',
        ),
        TermPair(
          term: 'View object',
          definition: 'A live window onto a dict, returned by keys/values/items.',
        ),
        TermPair(
          term: 'Generator expression',
          definition: 'A comprehension in parentheses that yields values lazily.',
        ),
        TermPair(
          term: 'defaultdict',
          definition: 'A dict that creates a missing value with a factory function.',
        ),
        TermPair(
          term: 'Shallow copy',
          definition: 'A copy whose container is new but the items inside are shared.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 216000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Containers, condensed. Four built-ins handle almost everything: '
              'list for an ordered sequence you can shuffle, tuple for a fixed record that won\'t budge, '
              'dict for instant key-to-value lookup, and set for "is this in there?" and keeping things unique. '
              'Honestly, picking the right container is 80% of the performance work '
              'you\'ll ever do in Python — it\'s like choosing the right kitchen tool.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Here\'s the rule of thumb: pick your container based on what question you keep asking. '
              'If you\'re constantly asking "is this in the collection?" — you want a set or dict, '
              'because hash lookups are instant, like flipping straight to a page in an index. '
              'If you\'re asking "what\'s at position three?" — a list is your friend. '
              'If the positions mean different things — like latitude and longitude — reach for a tuple.',
          startMs: 44000,
          endMs: 94000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Quick dict tip: they\'ve kept insertion order since Python 3.7, and it\'s a guarantee now, not luck. '
              'Use .get() when a missing key is totally normal — like checking if someone\'s in the phone book. '
              'Use square brackets when a missing key means something is genuinely broken. '
              'And remember: keys must be hashable, which in practice just means immutable. '
              'That\'s why "hello" and (1, 2) can be keys, but [1, 2] cannot.',
          startMs: 94000,
          endMs: 138000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Comprehensions are Python\'s way of saying "build me a new collection from this one" in one clean line. '
              'List, set, and dict forms all exist, following the same pattern. '
              'Drop the brackets inside a function call like sum() and you get a lazy generator expression '
              'that never creates the whole list in memory. Just keep them simple: one for, one if max. '
              'Past that, write a regular loop — future you will thank present you.',
          startMs: 138000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And don\'t sleep on the collections module — it\'s full of specialized tools. '
              'Counter for tallying things up, like counting votes or word frequencies. '
              'defaultdict for grouping — no more "if key not in dict, create empty list" boilerplate. '
              'deque for fast queues and sliding windows. namedtuple for records with named fields. '
              'Each one replaces about five lines of manual bookkeeping you\'d otherwise write by hand.',
          startMs: 182000,
          endMs: 216000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 498000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'This episode is about containers — and honestly, about making choices. '
              'Most Python performance problems I\'ve seen weren\'t the language being slow. '
              'They were using a list where a set belonged — like searching a phone book '
              'page by page instead of using the index. Or rebuilding a string in a loop '
              'like repainting the same wall every time you add a single brushstroke.',
          startMs: 0,
          endMs: 50000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Let\'s start with lists. They\'re ordered, mutable, indexable — your general-purpose workhorse. '
              'Under the hood, it\'s a slightly-over-allocated array, so appending is cheap on average. '
              'That\'s why building a list in a loop with .append() is totally fine. '
              'But inserting or deleting at the front? Every single item behind it shifts — '
              'like removing the first person from a line and everyone else scoots forward. '
              'If you\'re doing that repeatedly, you want a deque — it\'s built for both ends.',
          startMs: 50000,
          endMs: 118000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Slicing deserves a moment because it\'s both elegant and easy to misuse. '
              'The formula is [start:stop:step] — start is inclusive, stop is exclusive, step can go backwards. '
              'Critical detail: slicing always produces a NEW list. It copies the references, not the objects — '
              'cheap, but not free on a million-item list. That\'s why items[::-1] gives you a reversed copy, '
              'not an in-place reversal. If you just want to walk backwards, use reversed() — no copy needed.',
          startMs: 118000,
          endMs: 184000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Dicts are the true workhorse, and there are three access patterns worth knowing cold. '
              'Square brackets: use when a missing key means something is genuinely broken — let it scream. '
              '.get(key, default): use when absence is totally normal, like checking a settings dict. '
              '.setdefault(): use when you want to insert the default AND get it in one shot — '
              'though honestly, defaultdict from collections usually reads cleaner for that pattern.',
          startMs: 184000,
          endMs: 250000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Sets are the unsung heroes that people don\'t reach for enough. '
              'Unique items, lightning-fast membership tests, and a whole algebra built right in: '
              '& for intersection ("in both"), | for union ("in either"), '
              '- for difference ("in first but not second"), ^ for symmetric difference ("in one or the other but not both"). '
              '"Which users are in both groups?" becomes a single & operator. '
              'And it\'s fast — both sides are hashed, so no scanning required.',
          startMs: 250000,
          endMs: 308000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Tuples are for fixed-shape records where each position means something specific: '
              'a latitude-longitude pair, a database row, the three things a function returns. '
              'Since they\'re immutable, they\'re hashable — so they can be dict keys. '
              'That\'s how you build a lookup table indexed by a pair, like a grid or a coordinate system. '
              'Lists are for a variable number of interchangeable items — a shopping cart, not a coordinate.',
          startMs: 308000,
          endMs: 368000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Comprehensions tie everything together beautifully. They say "build me a new collection from this one" '
              'in a single, readable expression. List, set, and dict comprehensions all share the same shape: '
              '[expr for item in source if condition]. Drop the brackets inside a function call like sum() '
              'and you get a generator expression — it streams values one at a time without ever building '
              'the whole list in memory. It\'s the difference between loading every page of a book or reading one at a time.',
          startMs: 368000,
          endMs: 434000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Then there\'s the collections module — Python\'s Swiss Army knife drawer. '
              'Counter for counting things: words in a document, votes in an election. '
              'defaultdict for grouping: no more "if key not in dict, create empty list" dance. '
              'deque for fast operations at both ends, plus maxlen for automatic sliding windows. '
              'namedtuple when a tuple\'s positions deserve actual names. '
              'If you ever catch yourself writing "if key not in d: d[key] = []", '
              'remember: the standard library did that work for you already.',
          startMs: 434000,
          endMs: 498000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 846000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Deep dive on Python\'s containers. We\'re going to pop the hood: '
              'the memory layout of a list, the hash table machinery inside dicts and sets, '
              'what the insertion-order guarantee actually means, comprehension scoping rules, '
              'and the big-O cheat sheet you should tattoo on your brain. '
              'Think of this as the mechanic\'s view — when something feels slow, you\'ll know exactly why.',
          startMs: 0,
          endMs: 62000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'A CPython list is an array of pointers — not an array of actual values. '
              'That\'s the secret to how it holds mixed types: each slot just points to some object. '
              'Indexing is instant because it\'s just pointer arithmetic. When the array fills up, '
              'Python allocates a bigger one — growing by roughly 12% each time — and copies all the pointers over. '
              'Any single append might trigger this resize, which is expensive. But spread across thousands of appends, '
              'the average cost per item is constant. That\'s what "amortized O(1)" means: '
              'like paying rent once a month but spreading the cost over 30 days.',
          startMs: 62000,
          endMs: 154000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Here\'s what to avoid at scale. insert(0, item) and pop(0) move every remaining pointer — '
              'like asking everyone in a line to step back one spot. Do that in a loop and suddenly '
              'your O(n) algorithm becomes O(n²) — a thousand items means a million pointer shifts. '
              'collections.deque solves this: it\'s a doubly-linked list of blocks, so pushing and popping '
              'at either end is always instant. The tradeoff? Indexing into the middle is linear. '
              'No free lunch — pick the tool for your access pattern.',
          startMs: 154000,
          endMs: 238000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Now let\'s walk through how a dict actually finds your value. It\'s an open-addressed hash table. '
              'You hash the key, take the low bits to pick a slot, and look at what\'s there. '
              'First it checks identity — "is this the exact same object?" — as a fast path. Then equality. '
              'If it\'s not a match, it probes the next slot using a deterministic sequence from the remaining hash bits. '
              'When the table hits about two-thirds full, it doubles in size and rehashes everything — '
              'like a restaurant expanding and reassigning every table number.',
          startMs: 238000,
          endMs: 326000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Since Python 3.6, the dict layout has been split into two arrays: '
              'a dense array of entries in insertion order, and a sparse index array pointing into it. '
              'This saved significant memory and, as a happy side effect, made iteration follow insertion order. '
              'In 3.7 that side effect became a guarantee — you can count on dicts preserving insertion order. '
              'And since Counter and defaultdict are dict subclasses, they inherit this behavior for free.',
          startMs: 326000,
          endMs: 412000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'The hashing contract has teeth, especially for your own classes. Rule one: '
              'if two objects compare equal, they MUST hash to the same value — otherwise a set will '
              'happily hold two copies of what you consider the same thing. Rule two: '
              'a hash must never change while the object lives inside a container — that\'s why lists and dicts '
              'are unhashable. If you define __eq__ on a class, Python automatically sets __hash__ to None, '
              'making instances unhashable unless you explicitly define a hash yourself. '
              'It\'s Python\'s way of saying "I\'m not guessing — you tell me how to hash this.',
          startMs: 412000,
          endMs: 502000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Sets use exactly the same hash table machinery as dicts — just without a value next to each key. '
              'So set membership is exactly as fast as dict key lookup. This is why converting a list to a set '
              'before doing a bunch of membership tests is such an enormous win. '
              'Checking "is X in list" N times against a list of M items is O(N×M) — scanning the list every time. '
              'Build a set from the list once: O(M). Check N items: O(N). Total: O(N+M). '
              'It\'s like building an index once instead of re-reading the book for every question.',
          startMs: 502000,
          endMs: 570000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Comprehensions have their own scope — a detail that matters more than you\'d think. '
              'In Python 3, the loop variable inside a comprehension stays inside — it doesn\'t leak out '
              'and pollute your surrounding function. This changed from Python 2, where it was a common footgun. '
              'The comprehension can read variables from outside, but its own iteration variable is completely contained. '
              'That\'s what makes nested comprehensions safe: each one has its own little bubble.',
          startMs: 570000,
          endMs: 648000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'A word on copies, because this catches literally everyone. list(x), x[:], and x.copy() '
              'are ALL shallow copies: you get a new outer container, but it holds the same inner objects. '
              'It\'s like photocopying a table of contents — the page numbers are new, but they point to the same chapters. '
              'Copy a list of dicts this way, and mutating a dict is visible through both copies. '
              'copy.deepcopy walks the entire nested structure and duplicates everything — correct, but potentially very slow. '
              'Be intentional about which one you need.',
          startMs: 648000,
          endMs: 726000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Two more standard library gems beyond the usual four. heapq turns a plain list into a priority queue: '
              'push and pop in O(log n). This is your tool for "give me the top 10 items" or any kind of scheduling. '
              'bisect keeps a sorted list sorted using binary search — O(log n) to find where to insert, '
              'much better than re-sorting the whole list after every addition. '
              'Together, these two solve a surprising number of real-world problems elegantly.',
          startMs: 726000,
          endMs: 794000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Here\'s the cheat sheet to carry with you. List indexing and append: O(1). Front insert: O(n). '
              'Dict and set lookup: O(1) average, keys must be hashable. Dicts preserve insertion order — guaranteed since 3.7. '
              'Tuples are for records, lists for sequences. Comprehensions derive collections cleanly. '
              'And the collections module already wrote all the boilerplate you were about to write — '
              'Counter, defaultdict, deque, namedtuple. Reach for them before you reach for raw loops.',
          startMs: 794000,
          endMs: 846000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Pick the container by the question you ask',
      body:
          'Repeated "is it in there" means set or dict. Positional access means '
          'list. Fixed-shape records with meaningful positions mean tuple. '
          'Getting this choice right is most of Python performance tuning.',
    ),
    SummaryCard(
      title: 'Dicts are ordered and hash-backed',
      body:
          'Average O(1) lookup, insertion and deletion, keys must be hashable, '
          'and insertion order has been guaranteed since Python 3.7. Use d[key] '
          'when missing is a bug, d.get(key, default) when it is not.',
    ),
    SummaryCard(
      title: 'Comprehensions state intent',
      body:
          'A comprehension says "this collection is derived from that one" in '
          'one expression, in list, set, dict and lazy generator forms. Keep to '
          'one for clause and one if; beyond that a loop reads better.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Amortised O(1)',
      definition:
          'The cost of list.append: individual appends occasionally trigger a '
          'reallocation and copy, but the average cost per append over many '
          'operations is constant.',
    ),
    KeyConcept(
      term: 'Hashable',
      definition:
          'An object with a __hash__ that never changes and an __eq__ '
          'consistent with it, so it can be a dict key or set member. Built-in '
          'mutable containers are deliberately unhashable.',
    ),
    KeyConcept(
      term: 'View object',
      definition:
          'What dict.keys(), .values() and .items() return: a live window onto '
          'the dict rather than a snapshot list, so later changes to the dict '
          'are reflected in the view.',
    ),
    KeyConcept(
      term: 'Generator expression',
      definition:
          'A comprehension in parentheses that yields values lazily instead of '
          'building a collection. Inside a single-argument call the '
          'parentheses can be omitted, as in sum(x * x for x in values).',
    ),
    KeyConcept(
      term: 'defaultdict',
      definition:
          'A dict subclass that calls a zero-argument factory to create a value '
          'the first time a missing key is accessed, removing the initialise-'
          'then-append dance from grouping code.',
    ),
    KeyConcept(
      term: 'Shallow copy',
      definition:
          'A copy of a container that shares the objects inside it — list(x), '
          'x[:] and x.copy() are all shallow. Use copy.deepcopy when nested '
          'mutable objects must be independent too.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake: 'Writing best = scores.sort() and getting None.',
      correction:
          'In-place methods (sort, reverse, append, extend, update) return None '
          'by convention. Use sorted(scores) when you want a new list back.',
    ),
    Mistake(
      mistake:
          'Testing membership against a list inside a loop over another list.',
      correction:
          'Each "in" on a list is a linear scan, so the loop is O(n*m). Build a '
          'set from the inner collection once and test against that, making it '
          'O(n+m).',
    ),
    Mistake(
      mistake:
          'Using {} to create an empty set, or assuming set() preserves order.',
      correction:
          '{} is an empty dict — use set(). And sets are unordered; when you '
          'need deduplication that keeps first-seen order, use '
          'list(dict.fromkeys(items)) or a seen-set alongside a result list.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question: 'When would you choose a tuple over a list?',
      answer:
          'When the collection has a fixed shape whose positions mean different '
          'things — a coordinate, a database row, a multi-value return — rather '
          'than a variable number of interchangeable items. Immutability also '
          'makes tuples hashable, so they can serve as dict keys or set '
          'members, and it signals to readers that the value is not meant to '
          'change.',
    ),
    InterviewQuestion(
      question:
          'What makes dict lookup O(1) on average, and when does that break '
          'down?',
      answer:
          'A dict is a hash table: hashing the key computes a slot directly '
          'instead of searching. It degrades toward linear when many keys '
          'collide — either a pathological hash function or deliberately '
          'crafted keys — and any single insert can be expensive when the table '
          'resizes and rehashes. It also requires keys to be hashable, and a '
          'key whose hash changes after insertion becomes unfindable.',
    ),
    InterviewQuestion(
      question:
          'What is the difference between a list comprehension and a generator '
          'expression?',
      answer:
          'The comprehension builds and returns a whole list immediately; the '
          'generator expression returns a lazy iterator that computes each '
          'value on demand and holds no result in memory. Use the generator for '
          'large or infinite sources and for feeding a consumer like sum, any '
          'or a for loop; use the list when you need to index it, keep it, or '
          'iterate more than once — a generator is exhausted after one pass.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: '5. Data Structures — Python Docs',
    url: 'https://docs.python.org/3/tutorial/datastructures.html',
    description:
        'Tutorial chapter on lists, the stack and queue idioms, '
        'comprehensions, tuples, sets and dictionaries.',
  ),
  Source(
    title: 'collections — Container datatypes',
    url: 'https://docs.python.org/3/library/collections.html',
    description:
        'Reference for Counter, defaultdict, deque, namedtuple, OrderedDict '
        'and ChainMap, with recipes for each.',
  ),
];
