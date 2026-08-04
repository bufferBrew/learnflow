import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 3, lesson 2: the iteration protocol and lazy evaluation.
const Lesson generatorsLesson = Lesson(
  id: 'py-iterators-and-generators',
  title: 'Iterators & Generators',
  description:
      'The protocol behind every for loop, and how yield turns a function into '
      'a lazy stream of values.',
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
      id: 'protocol',
      heading: 'The iteration protocol',
      blocks: [
        ProseBlock(
          'Two roles look similar and are not. An iterable is anything that can '
          'produce an iterator: it implements __iter__. An iterator is the '
          'thing that actually produces values: it implements __next__, and its '
          '__iter__ returns itself. A list is iterable but is not an iterator, '
          'which is why you can loop over the same list twice.',
        ),
        ProseBlock(
          'A for loop is sugar over that protocol. It calls iter() on the '
          'object once, then next() repeatedly, and stops when next() raises '
          'StopIteration. Nothing in the loop knows about lists or indexes, '
          'which is why the same statement works over files, dicts, database '
          'cursors and anything else you make iterable.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
numbers = [1, 2, 3]

it = iter(numbers)              # a list_iterator
print(next(it), next(it), next(it))   # 1 2 3
# next(it)                      -> StopIteration

print(iter(it) is it)           # True: an iterator is its own iterator

# The for loop, written out by hand:
it = iter(numbers)
while True:
    try:
        value = next(it)
    except StopIteration:
        break
    print(value)

# An iterator is consumed once; the underlying list is not.
it = iter(numbers)
print(list(it))                 # [1, 2, 3]
print(list(it))                 # []  - exhausted
print(list(numbers))            # [1, 2, 3] - the list is fine
''',
          caption: 'iter() then next() until StopIteration. That is all.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Exhaustion is the defining property',
          text:
              'An iterator can only be walked once. If a function takes an '
              'iterable and needs two passes, either document that it requires '
              'a sequence or materialise it with list() first — otherwise it '
              'will silently see nothing on the second pass.',
        ),
      ],
    ),
    Section(
      id: 'custom-iterator',
      heading: 'Writing an iterator by hand',
      blocks: [
        ProseBlock(
          'Implementing the protocol directly is instructive once, and rarely '
          'the right choice afterwards. You have to hold the position as state, '
          'return self from __iter__, and remember to raise StopIteration. '
          'Keeping the iterable and the iterator as separate objects — as list '
          'does — is what allows several independent loops over the same '
          'collection.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class Countdown:
    """Iterable: each call to iter() gets a fresh, independent iterator."""

    def __init__(self, start):
        self.start = start

    def __iter__(self):
        return CountdownIterator(self.start)


class CountdownIterator:
    def __init__(self, current):
        self.current = current

    def __iter__(self):
        return self

    def __next__(self):
        if self.current <= 0:
            raise StopIteration
        self.current -= 1
        return self.current + 1


c = Countdown(3)
print(list(c))     # [3, 2, 1]
print(list(c))     # [3, 2, 1] again - a new iterator each time
print(max(c), sum(c))   # 3 6
''',
          caption: 'Separate the iterable from its iterator to allow re-use.',
        ),
      ],
    ),
    Section(
      id: 'generators',
      heading: 'Generators: the same thing, without the ceremony',
      blocks: [
        ProseBlock(
          'A function containing yield is a generator function. Calling it runs '
          'no code at all — it returns a generator object, which is an '
          'iterator. Each next() resumes the body until the next yield, hands '
          'back that value and freezes the function\'s entire state: local '
          'variables, the instruction pointer, the try blocks it is inside. '
          'When the body returns, StopIteration is raised automatically.',
        ),
        ProseBlock(
          'That is the same protocol as the class above in a fifth of the code, '
          'and it composes: a generator can consume another generator, forming '
          'a pipeline where each stage pulls one value at a time. yield from '
          'delegates the whole of another iterable, which flattens nested '
          'sources without a manual loop.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def countdown(start):
    while start > 0:
        yield start
        start -= 1


gen = countdown(3)
print(gen)                # <generator object countdown at 0x...>
print(next(gen))          # 3 - the body runs only now
print(list(gen))          # [2, 1] - resumes where it left off


def read_lines(text):
    for line in text.splitlines():
        yield line


def non_empty(lines):
    for line in lines:
        if line.strip():
            yield line


def numbered(lines):
    for i, line in enumerate(lines, start=1):
        yield f"{i}: {line}"


# A pipeline: no intermediate lists, one line in memory at a time.
document = "alpha\\n\\nbeta\\ngamma\\n"
for row in numbered(non_empty(read_lines(document))):
    print(row)            # 1: alpha / 2: beta / 3: gamma


def flatten(nested):
    for item in nested:
        if isinstance(item, list):
            yield from flatten(item)      # delegate to the inner generator
        else:
            yield item


print(list(flatten([1, [2, [3, 4]], 5])))   # [1, 2, 3, 4, 5]
''',
          caption: 'Generator functions, pipelines and yield from.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'A generator is exhausted after one pass',
          text:
              'list(gen) a second time gives []. If you need the values twice, '
              'store them in a list, or call the generator function again to '
              'get a fresh generator — the function is reusable even though the '
              'generator object is not.',
        ),
      ],
    ),
    Section(
      id: 'laziness',
      heading: 'Laziness is the point',
      blocks: [
        ProseBlock(
          'A generator computes values on demand, so memory use is proportional '
          'to one item rather than to the whole sequence. That is what makes it '
          'possible to process a file larger than RAM, to stop reading a stream '
          'as soon as you have found what you need, and to represent an '
          'infinite sequence at all.',
        ),
        ProseBlock(
          'Laziness also changes when work happens, and that has a sharp edge. '
          'Nothing runs until something consumes the generator, so an exception '
          'in the body surfaces at the consumption site, not at the call. '
          'Generators that touch a file or a lock therefore need care: the '
          'resource must stay open for the whole consumption, which usually '
          'means the with statement belongs inside the generator.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import sys


def naturals():
    n = 1
    while True:              # infinite: fine, because it is lazy
        yield n
        n += 1


def take(iterable, count):
    for i, value in enumerate(iterable):
        if i >= count:
            return
        yield value


print(list(take(naturals(), 5)))       # [1, 2, 3, 4, 5]

squares_list = [n * n for n in range(1_000_000)]
squares_gen = (n * n for n in range(1_000_000))
print(sys.getsizeof(squares_list))     # ~8 MB
print(sys.getsizeof(squares_gen))      # ~200 bytes

# Short-circuits: any() stops at the first True, so only 3 values are computed.
print(any(n > 2 for n in naturals()))  # True


def read_config(path):
    with open(path) as handle:         # the with is INSIDE the generator,
        for line in handle:            # so the file lives as long as the loop
            if not line.startswith("#"):
                yield line.rstrip()
''',
          caption: 'Constant memory, infinite sequences, early exit.',
        ),
      ],
    ),
    Section(
      id: 'itertools',
      heading: 'itertools: the standard toolkit',
      blocks: [
        ProseBlock(
          'itertools is a library of lazy building blocks, all of which return '
          'iterators. chain concatenates without copying; islice slices any '
          'iterable including an infinite one; groupby groups consecutive '
          'equal-keyed items — which is why you sort first; count, cycle and '
          'repeat generate endlessly; and product, permutations and '
          'combinations enumerate the combinatorics you would otherwise write '
          'badly by hand.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from itertools import chain, islice, groupby, count, product, pairwise

print(list(chain([1, 2], (3, 4), "ab")))    # [1, 2, 3, 4, 'a', 'b']
print(list(islice(count(10), 3)))           # [10, 11, 12]
print(list(islice(count(0, 5), 2, 5)))      # [10, 15, 20]

people = [("eng", "ada"), ("eng", "alan"), ("ops", "grace")]
for key, group in groupby(people, key=lambda pair: pair[0]):
    print(key, [name for _, name in group])
# eng ['ada', 'alan'] / ops ['grace']

print(list(product([0, 1], repeat=2)))      # [(0,0), (0,1), (1,0), (1,1)]
print(list(pairwise([1, 2, 3, 4])))         # [(1,2), (2,3), (3,4)]
''',
          caption: 'Composable lazy iterators from the standard library.',
        ),
        CollapsibleBlock(
          title: 'Advanced usage: send, throw, close and coroutines',
          children: [
            ProseBlock(
              'A generator is bidirectional. gen.send(value) resumes it and '
              'makes the paused yield expression evaluate to that value, so the '
              'consumer can push data back in. gen.throw raises an exception at '
              'the yield point, and gen.close raises GeneratorExit there — '
              'which is what lets a finally block inside a generator run its '
              'cleanup when the consumer walks away.',
            ),
            ProseBlock(
              'This two-way channel is the mechanism that async/await was built '
              'on: before native coroutines existed, asyncio drove '
              'generator-based coroutines by sending results back into them. '
              'You rarely write send() by hand today, but knowing it exists '
              'explains why suspending a coroutine at await is not magic.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
def accumulator():
    total = 0
    try:
        while True:
            value = yield total     # the yield expression receives sent values
            total += value
    finally:
        print("closing with total", total)


acc = accumulator()
print(next(acc))        # 0 - run up to the first yield
print(acc.send(10))     # 10
print(acc.send(5))      # 15
acc.close()             # closing with total 15
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
      id: 'ex-gen-convert',
      title: 'Make an eager function lazy',
      prompt: [
        ProseBlock(
          'The function below reads an entire file into memory, builds a list '
          'of every matching line and only then returns. Rewrite it as a '
          'generator so that memory use stays constant regardless of file size '
          'and the caller can stop early. Keep the file open for exactly as '
          'long as the caller is iterating.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def find_lines(path, needle):
    results = []
    with open(path) as handle:
        for line in handle.readlines():
            if needle in line:
                results.append(line.rstrip())
    return results
''',
        ),
      ],
      starterCode: '''
def find_lines(path, needle):
    results = []
    with open(path) as handle:
        for line in handle.readlines():
            if needle in line:
                results.append(line.rstrip())
    return results


# Should work with a huge file, and stop reading after the first match:
# first = next(find_lines("huge.log", "ERROR"))
''',
      solutionCode: '''
def find_lines(path, needle):
    with open(path) as handle:        # the with stays inside the generator
        for line in handle:           # a file object is already an iterator
            if needle in line:
                yield line.rstrip()


# Constant memory, and reading stops as soon as the caller does.
first = next(find_lines("huge.log", "ERROR"), None)
print(first)

for line in find_lines("huge.log", "ERROR"):
    print(line)
    break                             # file is closed when the generator is
                                      # garbage collected or closed
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why must the with statement stay inside the generator rather '
              'than wrapping the call?',
          expectedAnswer:
              'Because the body does not run until the caller iterates. If the '
              'with block were outside, the file would be closed before the '
              'first value was ever requested. Inside the generator, the block '
              'stays open across suspensions and is closed when the generator '
              'finishes or is closed.',
        ),
        SelfCheckQuestion(
          question:
              'The caller breaks out of the loop after one line. What happens '
              'to the open file?',
          expectedAnswer:
              'When the generator object is collected — or when close() is '
              'called on it — GeneratorExit is raised at the paused yield, '
              'which unwinds the with block and closes the file. Relying on '
              'collection timing is why contextlib.closing or an explicit '
              'close() is worth it in long-running programs.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-gen-custom-iterator',
      title: 'Implement the protocol by hand, then replace it',
      prompt: [
        ProseBlock(
          'Write a class Fibonacci(limit) whose instances are iterable and '
          'yield Fibonacci numbers below limit, implementing __iter__ and '
          '__next__ yourself. Then write the same thing as a generator function '
          'and compare the line counts. Both must support being iterated more '
          'than once.',
        ),
      ],
      starterCode: '''
class Fibonacci:
    def __init__(self, limit):
        self.limit = limit

    def __iter__(self):
        # TODO: return an iterator that yields values below self.limit
        ...


def fibonacci(limit):
    # TODO: the generator version
    ...


print(list(Fibonacci(20)))
print(list(fibonacci(20)))
''',
      solutionCode: '''
class Fibonacci:
    def __init__(self, limit):
        self.limit = limit

    def __iter__(self):
        return FibonacciIterator(self.limit)


class FibonacciIterator:
    def __init__(self, limit):
        self.limit = limit
        self.current, self.following = 0, 1

    def __iter__(self):
        return self

    def __next__(self):
        if self.current >= self.limit:
            raise StopIteration
        value = self.current
        self.current, self.following = self.following, self.current + self.following
        return value


def fibonacci(limit):
    current, following = 0, 1
    while current < limit:
        yield current
        current, following = following, current + following


f = Fibonacci(20)
print(list(f))            # [0, 1, 1, 2, 3, 5, 8, 13]
print(list(f))            # same again: __iter__ builds a new iterator
print(list(fibonacci(20)))  # identical output, four lines
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The generator function is reusable but the generator object is '
              'not. What does that mean for the second list() call?',
          expectedAnswer:
              'list(fibonacci(20)) calls the function again and gets a fresh '
              'generator, so it works. Holding on to one generator object and '
              'listing it twice would give the values then an empty list, '
              'because that single iterator is exhausted after one pass.',
        ),
        SelfCheckQuestion(
          question:
              'Why does the class version need a separate iterator class at '
              'all?',
          expectedAnswer:
              'If the Fibonacci object were its own iterator it would carry the '
              'position as state, so a second loop would resume from wherever '
              'the first stopped — and nested loops over the same object would '
              'interfere. Returning a fresh iterator from __iter__ keeps each '
              'traversal independent, which is what list, str and dict do.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-gen-pipeline',
      title: 'Build a lazy pipeline with itertools',
      prompt: [
        ProseBlock(
          'Given an infinite generator of log lines, write a pipeline that '
          'keeps only lines containing "ERROR", strips them, and returns the '
          'first three as a list — without ever materialising the full stream. '
          'Use a generator expression for the filtering and itertools.islice '
          'for the limit.',
        ),
      ],
      starterCode: '''
from itertools import islice


def log_stream():
    levels = ["INFO", "ERROR", "DEBUG"]
    i = 0
    while True:
        yield f"  {levels[i % 3]} event {i}  "
        i += 1


def first_errors(stream, count):
    # TODO: filter to ERROR lines, strip them, take only `count`
    ...


print(first_errors(log_stream(), 3))
''',
      solutionCode: '''
from itertools import islice


def log_stream():
    levels = ["INFO", "ERROR", "DEBUG"]
    i = 0
    while True:
        yield f"  {levels[i % 3]} event {i}  "
        i += 1


def first_errors(stream, count):
    errors = (line.strip() for line in stream if "ERROR" in line)
    return list(islice(errors, count))


print(first_errors(log_stream(), 3))
# ['ERROR event 1', 'ERROR event 4', 'ERROR event 7']
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why does this terminate even though log_stream() never ends?',
          expectedAnswer:
              'Every stage is lazy and demand-driven: islice pulls exactly '
              'three values through the generator expression, which pulls only '
              'as many lines from log_stream as it needs. Nothing iterates the '
              'source to completion, so an infinite source is harmless.',
        ),
        SelfCheckQuestion(
          question:
              'What would happen if you wrote a list comprehension instead of a '
              'generator expression for the filtering step?',
          expectedAnswer:
              'It would hang. A list comprehension is eager: it tries to '
              'consume the entire infinite stream before islice ever runs. The '
              'square brackets versus parentheses distinction is the whole '
              'difference between a program that returns in microseconds and '
              'one that never returns.',
        ),
      ],
    ),
  ],
);

const GameContent _play = GameContent(
  games: [
    OutputPredictorGame(
      id: 'game-generators-exhaustion',
      title: 'What does this print?',
      instructions: 'Pick what the final print statement prints.',
      code: '''
def countdown(start):
    while start > 0:
        yield start
        start -= 1


gen = countdown(3)
next(gen)
print(list(gen))
''',
      options: ['[3, 2, 1]', '[2, 1]', '[3, 2]', '[]'],
      correctIndex: 1,
      explanation:
          'next(gen) resumes the generator to its first yield and consumes '
          '3. list(gen) then drains whatever is left — 2 and 1 — the value '
          'already taken is gone for good.',
    ),
    FillBlankGame(
      id: 'game-generators-yield',
      title: 'Turn a function into a generator',
      instructions: 'Type the missing keyword.',
      code: '''
def countdown(start):
    while start > 0:
        ______ start
        start -= 1
''',
      blanks: [Blank(answer: 'yield', hint: 'freezes the function and hands back a value')],
    ),
    BugHuntGame(
      id: 'game-generators-off-by-one',
      title: 'Find the off-by-one',
      instructions: 'Tap the line that lets one extra value through.',
      code: '''
class CountdownIterator:
    def __init__(self, current):
        self.current = current

    def __iter__(self):
        return self

    def __next__(self):
        if self.current < 0:
            raise StopIteration
        self.current -= 1
        return self.current + 1
''',
      buggyLine: 9,
      explanation:
          'The guard should stop at zero, not below it. With "< 0", current '
          'can reach exactly 0 and still pass the check, so __next__ '
          'produces one extra, incorrect value before StopIteration finally '
          'fires.',
      fixedCode: '''
class CountdownIterator:
    def __init__(self, current):
        self.current = current

    def __iter__(self):
        return self

    def __next__(self):
        if self.current <= 0:
            raise StopIteration
        self.current -= 1
        return self.current + 1
''',
    ),
    SyntaxScrambleGame(
      id: 'game-generators-scramble',
      title: 'Rebuild the filtering generator',
      instructions: 'Drag or use the arrows to put these lines back in order.',
      lines: [
        'def non_empty(lines):',
        '    for line in lines:',
        '        if line.strip():',
        '            yield line',
      ],
    ),
    TermMatchGame(
      id: 'game-generators-terms',
      title: 'Match the vocabulary',
      instructions: 'Tap a term, then tap its definition.',
      pairs: [
        TermPair(
          term: 'Iterable vs iterator',
          definition: 'Can produce iterators, versus actually produces values.',
        ),
        TermPair(
          term: 'StopIteration',
          definition: 'The exception an iterator raises to signal it is exhausted.',
        ),
        TermPair(
          term: 'Generator function',
          definition: 'A function containing yield, which returns a generator object.',
        ),
        TermPair(
          term: 'yield from',
          definition: 'Delegates the whole iteration protocol to a sub-iterable.',
        ),
        TermPair(
          term: 'itertools',
          definition: 'The standard library of lazy iterator building blocks.',
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
              'Iterators and generators, condensed. Here\'s the mental model that makes everything click: '
              'imagine a water tap versus a bucket. A bucket stores all the water at once — you need a '
              'big bucket for a big job. A tap gives you water on demand, one drop at a time, and you '
              'only pay for what you use. That\'s the difference between a list and a generator. Every '
              'for loop in Python follows the same three-step dance: call iter() on the object, call '
              'next() repeatedly, and stop when next() raises StopIteration. That\'s the entire protocol.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Two words to keep separate, and mixing them up causes real bugs. An iterable is like a '
              'recipe book — it can produce an iterator, but it isn\'t one itself. A list is iterable: '
              'you can ask it for a fresh iterator a hundred times. An iterator is the thing actually '
              'dishing out values — like a chef reading from that recipe, one dish at a time, and once '
              'the chef finishes the recipe, they\'re done. That\'s exhaustion: you can loop over a list '
              'forever because each loop gets a new chef, but an iterator is a one-way trip.',
          startMs: 42000,
          endMs: 90000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'A generator is an iterator that you write as a function instead of a class. The magic word '
              'is yield. Put yield in a function body and calling that function runs absolutely nothing — '
              'you get a generator object back, like getting a remote control before the TV is even on. '
              'Each next() press resumes the body until the next yield, then freezes every local variable '
              'exactly where they were. It\'s like pausing a movie: the frame freezes, and when you hit '
              'play, it resumes from exactly that spot with everything intact.',
          startMs: 90000,
          endMs: 136000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'The payoff is laziness, and laziness here is a superpower. Memory use is proportional to '
              'one item rather than the whole collection — like reading a book one page at a time instead '
              'of photocopying the entire thing before you start. You can stop consuming the moment you '
              'find what you need, and infinite sequences become perfectly reasonable objects. Swap square '
              'brackets for parentheses and a list comprehension becomes a lazy generator — one character, '
              'completely different memory profile.',
          startMs: 136000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'One catch that bites everyone at least once: a generator is exhausted after a single pass. '
              'Call list() on the same generator twice and the second call gives you an empty list — '
              'silently. It\'s like a bag of chips: once you eat them, they\'re gone. If you need the values '
              'twice, store them in a list or call the generator function again for a fresh batch. And '
              'learn itertools — chain, islice, groupby and friends are all lazy building blocks that '
              'compose into elegant pipelines without writing a single loop by hand.',
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
              'Iteration today — and this is one of those topics where the mechanism is genuinely tiny '
              'but the consequences are enormous. Let me give you the analogy that makes everything click: '
              'think of a generator like a lazy friend who only does work when you specifically ask. '
              'You say "give me the next thing" and they go do one unit of work and hand it back. '
              'They don\'t do all the work upfront — they wait until you ask. That\'s exactly how '
              'yield works. Once you can see the iteration protocol hiding under every for loop, '
              'generators, itertools, and even async all start looking like the same idea dressed '
              'in slightly different clothes.',
          startMs: 0,
          endMs: 48000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The protocol is just two methods. __iter__ returns an iterator; __next__ returns the next '
              'value or raises StopIteration. An iterable has the first, an iterator has both, and here\'s '
              'the key detail: an iterator\'s __iter__ returns itself. That means you can pass an iterator '
              'anywhere an iterable is expected — it\'s like a tool that is also its own instruction manual. '
              'A list has __iter__ but not __next__, which is why you can loop over it forever. A generator '
              'has both, which is why it burns out after one pass.',
          startMs: 48000,
          endMs: 116000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'The consequence that trips people up is exhaustion. A list can be iterated forever because '
              'every for loop asks it for a brand new iterator — like a vending machine that never runs out '
              'because each customer gets their own fresh supply. A generator, a file object, a zip or a '
              'map is already an iterator, so a second pass sees absolutely nothing. And here\'s the cruel '
              'part: it fails silently — an empty result instead of an error. You\'ll scratch your head '
              'wondering where all your data went when the generator simply finished its one and only lap.',
          startMs: 116000,
          endMs: 186000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'You can implement the iteration protocol with a class, and it\'s absolutely worth doing once — '
              'like learning to drive stick before driving automatic. You keep the position as instance '
              'state, return self from __iter__, and raise StopIteration when you\'re done. But in practice '
              'you write a generator function instead: the same behavior, about a fifth of the code, and '
              'absolutely no chance of forgetting to raise StopIteration. Going from a 20-line class to '
              'a 4-line generator function is one of those moments where Python feels like cheating.',
          startMs: 186000,
          endMs: 252000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Here\'s the mental model for yield that I want you to tattoo on your brain. Calling a '
              'generator function executes exactly none of its body — it hands you a generator object, '
              'like being handed a wrapped present that you haven\'t opened yet. The first next() call '
              'runs the body until the first yield, produces that value, and freezes everything: all '
              'local variables, the exact instruction pointer, any enclosing try blocks. The next call '
              'resumes from precisely that frozen moment. It\'s like hitting pause on a movie — the '
              'frame is preserved perfectly, and play resumes from that exact spot.',
          startMs: 252000,
          endMs: 320000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'That freezing mechanism gives you three superpowers you simply cannot get otherwise. First, '
              'constant memory — only one item exists at a time, like reading a book with a bookmark instead '
              'of photocopying the whole thing. Second, early exit — unconsumed values are never computed, '
              'so any() and next() stop the instant they\'re satisfied. Third, infinite sequences — you can '
              'have a generator that counts to infinity and it\'s perfectly safe as long as something '
              'downstream limits it. It\'s like having a tap connected to an infinite water supply: it only '
              'flows when you turn the handle.',
          startMs: 320000,
          endMs: 388000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Generators also compose beautifully, like Lego bricks snapping together. Each stage is a '
              'generator consuming the previous one, so a filter-map-limit pipeline moves one item through '
              'end to end — no intermediate lists built along the way. And yield from is the secret weapon: '
              'it delegates an entire sub-iterable, which makes recursive generators — flattening a deeply '
              'nested tree, walking through JSON — almost trivially short. It\'s like telling a coworker '
              '"handle this whole sub-task and give me the results" instead of micromanaging every step.',
          startMs: 388000,
          endMs: 452000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Finally, itertools — your standard toolkit of lazy building blocks. chain to concatenate '
              'without copying anything, like linking train cars together. islice to slice anything including '
              'an infinite source — yes, you can take items 1000 to 1010 from an infinite counter. groupby '
              'for runs of equal keys — but remember to sort first, because it only groups consecutive '
              'matches, like a bouncer checking IDs one at a time at the door. Plus count, cycle, product, '
              'and combinations. They\'re all lazy, they all return iterators, and they save you from '
              'writing the fiddly, bug-prone version yourself.',
          startMs: 452000,
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
              'The long form on iteration — pull up a chair, we\'re going deep. Here\'s the big picture '
              'I want you to hold: everything from a simple for loop to async/await is built on the same '
              'frozen-function trick. Think of a generator like a TV episode on pause — the show freezes '
              'mid-frame, all the actors, props, and lighting exactly where they were. When you hit play, '
              'it resumes from that precise moment. That\'s yield. Today we\'re covering the protocol in '
              'microscopic detail, what a generator object actually contains under the hood, the send/throw '
              'two-way channel, yield from, resource management inside generators, itertools put to real '
              'work, and the direct evolutionary line from all of this to async/await.',
          startMs: 0,
          endMs: 62000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'The protocol first, with surgical precision. iter(x) calls x.__iter__ and, if that fails, '
              'falls back to the ancient sequence protocol: it calls x.__getitem__ with integer indexes '
              'starting from zero until IndexError is raised. That legacy path still works today, which is '
              'why some very old classes iterate without ever defining __iter__. It\'s like an old house '
              'that still has a coal chute — nobody uses it anymore, but it\'s still there and technically '
              'functional. Knowing this explains mysterious iteration behavior in codebases that predate '
              'the modern protocol.',
          startMs: 62000,
          endMs: 146000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'StopIteration being an exception is a fascinating design choice with real consequences. '
              'It means ending iteration piggybacks on the same stack-unwinding machinery as any error. '
              'And it used to have a nasty footgun: if a StopIteration accidentally leaked out of a '
              'generator body — say, from calling next() on something inside the generator — it would '
              'silently truncate the caller\'s loop with zero warning. PEP 479 fixed that in Python 3.5: '
              'inside a generator, a StopIteration that tries to escape is now automatically converted '
              'into a RuntimeError. It\'s like putting a safety gate at the top of the stairs.',
          startMs: 146000,
          endMs: 232000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'What is a generator object made of under the hood? A frame — the exact same data structure '
              'a normal function call uses — but instead of being discarded when the function returns, it\'s '
              'kept alive between resumptions. The frame holds all the local variables, the value stack, '
              'and the last instruction offset. Resuming is literally just restoring that frame and jumping '
              'back to the saved offset. This is why suspension is cheap: there\'s no serialization, no '
              'copying — it\'s just keeping a data structure alive that would normally be garbage collected. '
              'It\'s like putting a bookmark in a book instead of photocopying every page you\'ve read so far.',
          startMs: 232000,
          endMs: 318000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Which leads us to the bidirectional channel — the part that surprises most people. yield '
              'isn\'t just a statement; it\'s an expression. gen.send(value) resumes the generator and makes '
              'the paused yield evaluate to that value, so data flows in as well as out. It\'s like a '
              'two-way radio instead of a broadcast tower. gen.throw(exc) raises an exception at the exact '
              'yield point, and gen.close() raises GeneratorExit there. This two-way channel is the '
              'mechanism that made generator-based coroutines possible before async/await existed — the '
              'event loop would send results back into generators to drive them forward.',
          startMs: 318000,
          endMs: 404000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'That close behavior is what makes cleanup actually work. A try/finally or a with block '
              'wrapping a yield will run its teardown when the generator is closed or garbage collected — '
              'the GeneratorExit exception unwinds it just like any other exception. This is also why '
              'the with statement for opening a file absolutely must live inside the generator, not '
              'outside. When you call the generator function, the body hasn\'t run at all yet — so if '
              'the with were outside, the file would be opened and closed before a single value was '
              'ever yielded. It\'s like setting up a tent before the camping trip actually starts.',
          startMs: 404000,
          endMs: 486000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'yield from is far more than a loop shortcut — it delegates the entire iteration protocol '
              'to a sub-generator. Values pass out, sent values pass in, thrown exceptions pass through, '
              'and here\'s the killer feature: the sub-generator\'s return value becomes the result of '
              'the yield from expression. That last piece is what made generator-based coroutines '
              'composable, and PEP 380 was written largely to enable it. It\'s like a manager delegating '
              'an entire project to a team lead — communication flows both ways, and when the team lead '
              'finishes, they hand back a final report.',
          startMs: 486000,
          endMs: 570000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'On itertools, a few patterns worth cementing in your brain. islice is your slice operator '
              'for anything that isn\'t a sequence — including infinite generators. tee duplicates one '
              'iterator into several, but here\'s the catch: it buffers internally, so if one branch races '
              'far ahead of the others, you pay in memory for the gap between them. It\'s like two people '
              'reading the same book at different speeds — the library has to keep photocopies of the pages '
              'the faster reader has already passed. groupby only groups consecutive items, so it\'s a '
              'streaming operation, not a database GROUP BY — you must sort by the same key first if you '
              'want true grouping behavior.',
          startMs: 570000,
          endMs: 656000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'There are real costs to weigh too — generators aren\'t magic fairy dust. Laziness moves work '
              'to the consumption site, so exceptions surface far from the call that created the generator, '
              'and tracebacks become harder to read. You can\'t take len() of a generator or index into it — '
              'it\'s a one-way stream, not a random-access array. And a deep pipeline of tiny generators has '
              'per-item overhead that a single tight loop doesn\'t have. For small collections, a plain list '
              'comprehension is often both clearer and faster. The rule of thumb: use generators when the '
              'data might be large, infinite, or you might stop early. Use lists when the data is small and '
              'you need it more than once.',
          startMs: 656000,
          endMs: 748000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'And the payoff for understanding all of this: async. A native coroutine is essentially a '
              'generator whose suspension points are awaits instead of yields, driven by an event loop '
              'that resumes it when a result is ready. Before async def existed, asyncio literally used '
              'generators decorated with @asyncio.coroutine, and the event loop would call .send() to '
              'push results back in. Everything you just learned about frozen frames, the instruction '
              'pointer, and the value stack — that\'s the exact same machinery powering every async web '
              'server you\'ve ever used. Generators aren\'t just a feature; they\'re the foundation that '
              'async Python was built on top of.',
          startMs: 748000,
          endMs: 830000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Summary: iterable produces iterator, iterator yields until StopIteration, generators write '
              'that in a fifth of the code by freezing their frame at every yield, laziness buys you '
              'constant memory and early exit at the cost of one-shot consumption and no random access, '
              'and itertools already has the building block you were about to write from scratch. Master '
              'these and you\'ve mastered the engine under every for loop in the language.',
          startMs: 830000,
          endMs: 846000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'One protocol under every loop',
      body:
          'for calls iter() once, then next() until StopIteration. An iterable '
          'can produce an iterator; an iterator produces values and is consumed '
          'in the process. That distinction explains why a list can be looped '
          'twice and a generator cannot.',
    ),
    SummaryCard(
      title: 'yield freezes the function',
      body:
          'Calling a generator function runs none of its body — it returns a '
          'generator object. Each next() resumes until the next yield, then '
          'freezes locals and position. Return from the body raises '
          'StopIteration automatically.',
    ),
    SummaryCard(
      title: 'Lazy means constant memory and early exit',
      body:
          'Values are computed on demand, so a generator handles files larger '
          'than RAM, supports infinite sequences, and never computes what a '
          'consumer does not ask for. The cost is a single pass and no len() or '
          'indexing.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Iterable vs iterator',
      definition:
          'An iterable implements __iter__ and can produce iterators; an '
          'iterator implements __next__ and returns itself from __iter__. Lists '
          'are iterable; generators, file objects, zip and map are iterators.',
    ),
    KeyConcept(
      term: 'StopIteration',
      definition:
          'The exception an iterator raises to signal exhaustion, which the for '
          'loop catches to terminate. A generator body returning raises it '
          'automatically.',
    ),
    KeyConcept(
      term: 'Generator function',
      definition:
          'A function containing yield. Calling it executes no body code and '
          'returns a generator object whose frame — locals and instruction '
          'pointer — is preserved between resumptions.',
    ),
    KeyConcept(
      term: 'yield from',
      definition:
          'Delegates the entire iteration protocol to a sub-iterable: values '
          'out, sent values in, exceptions through, and the sub-generator\'s '
          'return value as the expression result. The basis of recursive '
          'generators.',
    ),
    KeyConcept(
      term: 'Generator expression',
      definition:
          'A comprehension written with parentheses, producing a lazy iterator '
          'rather than a materialised collection. The one-character difference '
          'from a list comprehension decides eager versus lazy.',
    ),
    KeyConcept(
      term: 'itertools',
      definition:
          'The standard library of lazy iterator building blocks — chain, '
          'islice, groupby, count, cycle, product, pairwise — all returning '
          'iterators that compose into pipelines.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Iterating a generator twice and getting nothing the second time.',
      correction:
          'An iterator is exhausted after one pass. Materialise the values with '
          'list() if you need them again, or call the generator function again '
          'for a fresh generator — the function is reusable, the object is '
          'not.',
    ),
    Mistake(
      mistake:
          'Opening a file with "with" around the call to a generator function '
          'rather than inside it.',
      correction:
          'The body has not run yet when the call returns, so the file closes '
          'before the first value is requested. Put the with statement inside '
          'the generator so it stays open across suspensions.',
    ),
    Mistake(
      mistake:
          'Using a list comprehension over an infinite or very large source.',
      correction:
          'A list comprehension is eager and will consume everything before '
          'anything downstream runs. Use a generator expression — parentheses '
          'instead of brackets — and bound it with itertools.islice or next().',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question: 'What is the difference between an iterable and an iterator?',
      answer:
          'An iterable implements __iter__ and can hand out iterators; an '
          'iterator implements __next__ to produce values one at a time and '
          'returns itself from __iter__. A list is iterable but not an '
          'iterator, so each for loop gets a fresh, independent traversal. A '
          'generator, a file object, zip and map are iterators, so they are '
          'consumed by the first pass and appear empty afterwards.',
    ),
    InterviewQuestion(
      question:
          'What happens, step by step, when you call a generator function?',
      answer:
          'None of the body executes. Python sees yield at compile time, marks '
          'the code object as a generator, and calling it builds a generator '
          'object holding a suspended frame. The first next() runs the body up '
          'to the first yield, produces that value and freezes the frame — '
          'locals, value stack and instruction offset intact. Each subsequent '
          'next() resumes at that offset. When the body returns, StopIteration '
          'is raised with the return value attached.',
    ),
    InterviewQuestion(
      question:
          'When would you choose a list comprehension over a generator '
          'expression?',
      answer:
          'When you need the result more than once, need len() or indexing, or '
          'the collection is small enough that materialising it costs nothing '
          'and reads more plainly. Also when the work must happen now rather '
          'than at consumption time — for example when the source is about to '
          'be closed or mutated. Otherwise prefer the generator expression, '
          'especially when feeding a consumer such as sum, any or a for loop '
          'that may stop early.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'itertools — Python Docs',
    url: 'https://docs.python.org/3/library/itertools.html',
    description:
        'Reference for the lazy iterator building blocks, plus the recipes '
        'section showing how they compose into larger tools.',
  ),
  Source(
    title: 'Functional Programming HOWTO — Python Docs',
    url: 'https://docs.python.org/3/howto/functional.html',
    description:
        'A guided tour of iterators, generators, generator expressions and '
        'passing values into generators with send().',
  ),
];
