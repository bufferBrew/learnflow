import '../../models/content_block.dart';
import '../../models/exercise.dart';
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
              'Containers, condensed. Four built-ins do almost everything: '
              'list for an ordered mutable sequence, tuple for a fixed record, '
              'dict for key-to-value lookup, and set for membership and '
              'uniqueness. Picking the right one is most of the performance '
              'work you will ever do in Python.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'The rule of thumb is about the question you are asking. If you '
              'ask "is this in there" repeatedly, you want a set or a dict, '
              'because that is a hash lookup instead of a scan. If you ask '
              '"what is at position three", you want a list. If the positions '
              'have distinct meanings, you want a tuple.',
          startMs: 44000,
          endMs: 94000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Dictionaries have kept insertion order since 3.7, and that is a '
              'language guarantee now, not an accident. Use get when a missing '
              'key is normal, plain square brackets when a missing key is a '
              'bug, and remember that keys must be hashable — which in practice '
              'means immutable.',
          startMs: 94000,
          endMs: 138000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Comprehensions are the idiomatic way to derive one collection '
              'from another. List, set and dict forms all exist, and dropping '
              'the brackets inside a function call gives you a lazy generator '
              'expression instead. Keep them to one for and one if — past that, '
              'write the loop.',
          startMs: 138000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And learn the collections module: Counter for tallies, '
              'defaultdict for grouping, deque for queues and bounded history, '
              'namedtuple for readable records. Each replaces about five lines '
              'of bookkeeping you would otherwise write by hand.',
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
              'This episode is about containers — and really about choosing '
              'between them. Most Python performance problems I have seen were '
              'not about the language being slow; they were a list being used '
              'where a set belonged, or a string being rebuilt in a loop.',
          startMs: 0,
          endMs: 50000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Lists first. Ordered, mutable, indexable, and backed by an '
              'over-allocated array. Appending is amortised constant time, '
              'which is why append-in-a-loop is fine. Inserting or deleting at '
              'the front is linear because everything after it shifts, so if '
              'you are doing that repeatedly you want a deque instead.',
          startMs: 50000,
          endMs: 118000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Slicing is worth being precise about. Start is inclusive, stop '
              'is exclusive, step can be negative, and the result is always a '
              'new list. That last part means a slice of a big list copies the '
              'references — cheap, but not free — and it is why '
              'items-colon-colon-minus-one gives you a reversed copy rather '
              'than reversing in place.',
          startMs: 118000,
          endMs: 184000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Dicts are the workhorse, and there are three access idioms. '
              'Square brackets when a missing key is genuinely a bug — let it '
              'raise KeyError. get with a default when absence is normal. And '
              'setdefault when you want to insert the default at the same time, '
              'though defaultdict usually reads better for that.',
          startMs: 184000,
          endMs: 250000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Sets are the ones people under-use. Uniqueness, membership, and '
              'the whole algebra: ampersand for intersection, pipe for union, '
              'minus for difference, caret for symmetric difference. "Which '
              'users are in both groups" is one operator, and it is fast '
              'because both sides are hashed.',
          startMs: 250000,
          endMs: 308000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Tuples are for fixed-shape records: a coordinate, a row, the two '
              'things a function returns. They are immutable, so they are '
              'hashable, so they can be dict keys — which is how you build a '
              'lookup table indexed by a pair. Lists are for a variable number '
              'of interchangeable items.',
          startMs: 308000,
          endMs: 368000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Comprehensions tie it together. A comprehension says "this new '
              'collection is derived from that one" in a single expression, and '
              'the list, set and dict forms all follow the same shape. Drop the '
              'brackets inside a call like sum or any and you get a generator '
              'expression that never materialises the intermediate list.',
          startMs: 368000,
          endMs: 434000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Then the collections module. Counter for frequency, defaultdict '
              'for grouping, deque for both-ends work and for maxlen-bounded '
              'buffers, namedtuple when a tuple\'s positions deserve names. If '
              'you find yourself writing "if key not in d: d of key equals '
              'empty list", the standard library already has that.',
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
              'Deep dive on Python\'s containers. We will do the memory layout '
              'of a list, the hash table behind dicts and sets, what the '
              'ordering guarantee actually promises, comprehension scoping, and '
              'the complexity table you should carry around in your head.',
          startMs: 0,
          endMs: 62000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'A CPython list is an array of pointers, not an array of values. '
              'That is why it can hold mixed types, and why indexing is '
              'constant time. When it fills up, it allocates a larger block — '
              'growing by roughly an eighth each time — and copies the pointers '
              'across. Any single append can therefore be expensive, but '
              'averaged over many appends the cost per item is constant. That '
              'is what amortised means.',
          startMs: 62000,
          endMs: 154000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'The corollary is the operations you should avoid at scale. '
              'insert at zero and pop from zero are linear because every '
              'remaining pointer shifts. In a loop that is quadratic. '
              'collections.deque is implemented as a doubly linked list of '
              'blocks, so appends and pops at both ends are constant time — at '
              'the cost of indexing in the middle being linear.',
          startMs: 154000,
          endMs: 238000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Now dicts. A dict is an open-addressed hash table. Hash the key, '
              'take the low bits to choose a slot, and compare what is there — '
              'identity first as a fast path, then equality. If it does not '
              'match, probe another slot using a sequence derived from the '
              'remaining hash bits. When the table is about two-thirds full it '
              'grows and everything is rehashed.',
          startMs: 238000,
          endMs: 326000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Since 3.6 the layout is split in two: a dense array of entries '
              'in insertion order, plus a sparse array of indexes into it. That '
              'saved a lot of memory, and it made iteration follow insertion '
              'order as a side effect. In 3.7 that side effect was promoted to '
              'a language guarantee — so you may now rely on it, and Counter '
              'and defaultdict inherit it too.',
          startMs: 326000,
          endMs: 412000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'The hashing contract has real consequences for your own classes. '
              'Objects that compare equal must hash equal, otherwise a set will '
              'happily hold two things you consider identical. And a hash must '
              'not change while the object is in a container, which is exactly '
              'why lists and dicts are unhashable. Define dunder eq on a class '
              'and Python sets dunder hash to None, making instances '
              'unhashable, unless you define it yourself.',
          startMs: 412000,
          endMs: 502000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Sets use the same machinery with no value alongside the key. '
              'That is why set membership and dict key membership have the same '
              'cost, and why converting a list to a set before a batch of '
              'membership tests is such a reliable win — it turns an '
              'n-times-m scan into n-plus-m hashing.',
          startMs: 502000,
          endMs: 570000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Comprehensions deserve a note on scoping. In Python 3 a '
              'comprehension runs in its own scope, so the loop variable does '
              'not leak into the surrounding function — that changed from '
              'Python 2. It also means a comprehension can read enclosing '
              'variables but its iteration variable is entirely its own, which '
              'is what makes them safe to nest.',
          startMs: 570000,
          endMs: 648000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'And a word on copies, because it catches everyone. list of x, '
              'x-colon and x dot copy are all shallow: you get a new outer list '
              'holding the same inner objects. Copy a list of dicts that way '
              'and mutating one of those dicts is still visible through both '
              'lists. copy.deepcopy walks the whole structure, which is correct '
              'and can be very slow.',
          startMs: 648000,
          endMs: 726000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'On the standard library, two more worth knowing beyond the usual '
              'four. heapq turns a list into a priority queue with push and pop '
              'in log n — that is your "smallest n items" and scheduling tool. '
              'bisect keeps a sorted list sorted with binary insertion, which '
              'beats re-sorting after every insert.',
          startMs: 726000,
          endMs: 794000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'The summary to carry: list indexing and append are constant, '
              'front insertion is linear; dict and set lookup is constant on '
              'average and requires hashable keys; dicts keep insertion order; '
              'tuples are records; comprehensions derive collections; and the '
              'collections module already wrote the bookkeeping you were about '
              'to write.',
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
