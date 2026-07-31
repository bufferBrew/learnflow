import '../../models/content_block.dart';
import '../../models/exercise.dart';
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
              'Iterators and generators, condensed. Every for loop in Python is '
              'the same three steps: call iter on the object, call next '
              'repeatedly, and stop when next raises StopIteration. That is the '
              'entire protocol, and everything else is built on it.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Keep two words apart. An iterable can produce an iterator — a '
              'list is one. An iterator is the thing that actually yields '
              'values and gets used up. A list can be looped over a hundred '
              'times because each loop asks it for a fresh iterator.',
          startMs: 42000,
          endMs: 90000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'A generator is an iterator written as a function. Put yield in '
              'the body and calling it runs nothing — you get a generator '
              'object back. Each next resumes the body until the next yield and '
              'then freezes every local variable exactly where they were.',
          startMs: 90000,
          endMs: 136000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'The payoff is laziness. Memory is proportional to one item '
              'rather than the whole sequence, you can stop consuming as soon '
              'as you have what you need, and infinite sequences become '
              'perfectly reasonable objects. Swap square brackets for round '
              'ones and a comprehension becomes lazy too.',
          startMs: 136000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'One catch: a generator is exhausted after a single pass. If you '
              'need the values twice, keep a list or call the function again. '
              'And learn itertools — chain, islice, groupby and friends are all '
              'lazy and compose into pipelines.',
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
              'Iteration today — and this is one of those topics where the '
              'mechanism is genuinely small and the consequences are enormous. '
              'Once you can see the protocol under the for loop, generators, '
              'itertools and even async stop looking like separate features.',
          startMs: 0,
          endMs: 48000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The protocol is two methods. dunder-iter returns an iterator; '
              'dunder-next returns the next value or raises StopIteration. An '
              'iterable has the first, an iterator has both, and an iterator\'s '
              'dunder-iter returns itself. That last detail is why you can pass '
              'an iterator anywhere an iterable is expected.',
          startMs: 48000,
          endMs: 116000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'The consequence people trip over is exhaustion. A list can be '
              'iterated forever because every loop asks it for a new iterator. '
              'A generator, a file object, a zip or a map is already an '
              'iterator, so a second pass sees nothing at all — usually as a '
              'silent empty result rather than an error, which is worse.',
          startMs: 116000,
          endMs: 186000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'You can implement the protocol with a class, and it is worth '
              'doing once. You keep the position as instance state, return self '
              'from dunder-iter, and raise StopIteration when you are done. But '
              'in practice you write a generator function instead: the same '
              'behaviour, a fifth of the code, and no chance of forgetting the '
              'StopIteration.',
          startMs: 186000,
          endMs: 252000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Here is the mental model for yield. Calling a generator function '
              'executes none of its body — it hands you a generator object. The '
              'first next runs until the first yield, produces that value and '
              'freezes everything: locals, the instruction pointer, any '
              'enclosing try blocks. The next call resumes from exactly there.',
          startMs: 252000,
          endMs: 320000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'That gives you three things you cannot get otherwise. Constant '
              'memory, because only one item exists at a time. Early exit, '
              'because unconsumed values are never computed — any and next stop '
              'the moment they are satisfied. And infinite sequences, which are '
              'perfectly safe as long as something downstream limits them.',
          startMs: 320000,
          endMs: 388000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Generators also compose. Each stage is a generator consuming the '
              'previous one, so a filter-map-limit pipeline moves a single item '
              'through end to end rather than building three intermediate '
              'lists. And yield from delegates an entire sub-iterable, which '
              'makes recursive generators — flattening a tree, walking nested '
              'data — trivial.',
          startMs: 388000,
          endMs: 452000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Finally, itertools. chain to concatenate, islice to slice '
              'anything including an infinite source, groupby for runs of equal '
              'keys — remember to sort first — plus count, cycle, product and '
              'combinations. They are all lazy, they all return iterators, and '
              'they save you writing the fiddly version yourself.',
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
              'The long form on iteration. We are covering the protocol, what a '
              'generator object actually contains, the send and throw channel, '
              'yield from, resource management inside generators, itertools in '
              'anger, and the direct line from all this to async await.',
          startMs: 0,
          endMs: 62000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'The protocol first, precisely. iter of x calls x dot dunder-iter '
              'and, failing that, falls back to the old sequence protocol using '
              'dunder-getitem with integer indexes from zero until IndexError. '
              'That legacy path still works and is why some very old classes '
              'iterate without ever defining dunder-iter.',
          startMs: 62000,
          endMs: 146000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'StopIteration being an exception is an interesting design '
              'choice. It means ending iteration uses the same unwinding '
              'machinery as any error, and it means an accidental '
              'StopIteration leaking out of a generator body used to silently '
              'truncate the caller\'s loop. PEP 479 fixed that: inside a '
              'generator, a StopIteration that escapes is now converted into a '
              'RuntimeError.',
          startMs: 146000,
          endMs: 232000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'What is a generator object made of? A frame — the same structure '
              'a normal call uses — that is kept alive between resumptions '
              'instead of being discarded on return. It holds the locals, the '
              'value stack and the last instruction offset. Resuming is just '
              'restoring that frame and jumping back to the offset, which is '
              'why suspension is cheap.',
          startMs: 232000,
          endMs: 318000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Which leads to the bidirectional channel. yield is an '
              'expression, not just a statement. gen dot send of value resumes '
              'the generator and makes the paused yield evaluate to that value, '
              'so data flows in as well as out. gen dot throw raises an '
              'exception at the yield point, and gen dot close raises '
              'GeneratorExit there.',
          startMs: 318000,
          endMs: 404000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'That close behaviour is what makes cleanup work. A try-finally '
              'or a with block wrapping a yield will run its teardown when the '
              'generator is closed or collected — the GeneratorExit unwinds it. '
              'It also means the with statement for a file belongs inside the '
              'generator, because the body has not run at all when the function '
              'is called.',
          startMs: 404000,
          endMs: 486000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'yield from is more than a loop shorthand. It delegates the full '
              'protocol to a sub-generator: values pass out, sent values pass '
              'in, thrown exceptions pass through, and the sub-generator\'s '
              'return value becomes the result of the yield from expression. '
              'That last piece is what made generator-based coroutines '
              'composable, and PEP 380 was written largely for it.',
          startMs: 486000,
          endMs: 570000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'On itertools, a few patterns worth internalising. islice is your '
              'slice for anything that is not a sequence. tee duplicates one '
              'iterator into several — but it buffers, so if one branch races '
              'ahead you pay memory for the gap. groupby only groups '
              'consecutive items, so it is a streaming operation and you must '
              'sort by the same key first if you want true grouping.',
          startMs: 570000,
          endMs: 656000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'There are real costs to weigh too. Laziness moves work to the '
              'consumption site, so exceptions surface far from the call that '
              'created the generator and tracebacks get harder to read. You '
              'cannot take the length of a generator or index into it. And a '
              'deep pipeline of tiny generators has per-item overhead that a '
              'single loop does not — for small collections a list '
              'comprehension is often both clearer and faster.',
          startMs: 656000,
          endMs: 748000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'And the payoff for understanding all of it: async. A native '
              'coroutine is essentially a generator whose suspension points are '
              'awaits instead of yields, driven by an event loop that resumes '
              'it when a result is ready. Before async def existed, asyncio '
              'literally used generators and send. Everything you just learned '
              'about frozen frames is the same machinery.',
          startMs: 748000,
          endMs: 830000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Summary: iterable produces iterator, iterator yields until '
              'StopIteration, generators write that in a fifth of the code, '
              'laziness buys memory and early exit at the cost of one-shot '
              'consumption, and itertools already has the piece you were about '
              'to write.',
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
