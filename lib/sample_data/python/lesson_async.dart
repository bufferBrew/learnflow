import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 3, lesson 3: cooperative concurrency with asyncio.
const Lesson asyncLesson = Lesson(
  id: 'py-async-and-concurrency',
  title: 'Async & Concurrency (asyncio)',
  description:
      'Coroutines, the event loop and structured concurrency — plus when '
      'threads or processes are the right answer instead.',
  estimatedMinutes: 26,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  review: _review,
  sources: _sources,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'why-async',
      heading: 'Concurrency, parallelism and the GIL',
      blocks: [
        ProseBlock(
          'Concurrency is dealing with many things at once; parallelism is '
          'doing many things at once. A single-threaded program can be highly '
          'concurrent — while one request waits for the network, another can be '
          'served — without ever using two CPU cores. Choosing the right tool '
          'starts with deciding which of the two you actually need.',
        ),
        ProseBlock(
          'CPython\'s global interpreter lock allows only one thread to execute '
          'Python bytecode at a time, so threads do not speed up CPU-bound '
          'work. They do help with I/O, because the lock is released while a '
          'thread waits on a socket or a file. Multiprocessing sidesteps the '
          'lock with separate interpreters, at the cost of copying data between '
          'them.',
        ),
        ProseBlock(
          'asyncio takes the third route: one thread, one event loop, and tasks '
          'that voluntarily yield control at every await. There is no '
          'pre-emption, so you never need a lock to protect a block of code '
          'with no await in it — and equally, one task that refuses to yield '
          'stops everything.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Rough guide to picking a model:
#
#   Waiting on network, disk or a database   -> asyncio (or threads)
#   Heavy computation across many cores      -> multiprocessing
#   Blocking library with no async version   -> threads, or asyncio.to_thread
#   One thing at a time, fast enough already -> plain synchronous code

import asyncio
import time


async def fetch(name, seconds):
    print(f"start {name}")
    await asyncio.sleep(seconds)     # yields control; does NOT block the loop
    print(f"done {name}")
    return name


async def main():
    started = time.perf_counter()
    results = await asyncio.gather(
        fetch("a", 1),
        fetch("b", 1),
        fetch("c", 1),
    )
    print(results, f"{time.perf_counter() - started:.1f}s")


asyncio.run(main())
# start a / start b / start c / done a / done b / done c
# ['a', 'b', 'c'] 1.0s   - not 3.0s
''',
          caption: 'Three one-second waits overlap into one second.',
        ),
      ],
    ),
    Section(
      id: 'coroutines',
      heading: 'Coroutines and the event loop',
      blocks: [
        ProseBlock(
          'async def defines a coroutine function. Calling it runs no code — it '
          'returns a coroutine object, exactly as calling a generator function '
          'returns a generator. Something has to drive it, and that something '
          'is the event loop, started by asyncio.run() at the top of your '
          'program.',
        ),
        ProseBlock(
          'await does two things: it suspends the current coroutine, handing '
          'control back to the loop, and it resumes with the result when the '
          'awaited operation completes. The loop spends its time waiting on the '
          'operating system for readable sockets and expired timers, then '
          'resumes whichever coroutines are ready. Everything runs in one '
          'thread.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import asyncio


async def work():
    return 42


# Calling a coroutine function does not run it.
coro = work()
print(coro)                     # <coroutine object work at 0x...>
# RuntimeWarning: coroutine 'work' was never awaited  (if you drop it here)

print(asyncio.run(work()))      # 42 - run() starts a loop, drives it, closes it


async def main():
    # await runs it to completion and gives back the value
    value = await work()

    # A Task schedules the coroutine on the loop and runs it concurrently
    task = asyncio.create_task(asyncio.sleep(0.1, result="later"))
    print(value, await task)    # 42 later


asyncio.run(main())
''',
          caption: 'Coroutines are inert; the loop is what runs them.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'One blocking call freezes everything',
          text:
              'time.sleep, requests.get, or a heavy loop inside a coroutine '
              'blocks the single thread, so every other task stops too. Use '
              'asyncio.sleep, an async client such as httpx or aiohttp, or push '
              'the blocking call to a thread with asyncio.to_thread.',
        ),
      ],
    ),
    Section(
      id: 'concurrency',
      heading: 'Running things concurrently',
      blocks: [
        ProseBlock(
          'Awaiting coroutines one after another is just sequential code with '
          'extra keywords. Concurrency starts when several operations are in '
          'flight at once: create_task schedules a coroutine immediately and '
          'returns a handle, gather awaits a collection of them and returns '
          'their results in order, and TaskGroup — added in 3.11 — does the '
          'same with proper failure semantics.',
        ),
        ProseBlock(
          'Prefer TaskGroup. With gather, one failure leaves the others running '
          'unless you remember return_exceptions, and cleanup is your problem. '
          'A TaskGroup guarantees that when the block exits, every task inside '
          'it has finished or been cancelled — which is what "structured '
          'concurrency" means: task lifetimes nest like scopes.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import asyncio


async def fetch(name, seconds):
    await asyncio.sleep(seconds)
    if name == "bad":
        raise ValueError("upstream refused")
    return f"{name}-ok"


async def sequential():
    a = await fetch("a", 1)
    b = await fetch("b", 1)         # starts only after a finishes: 2 seconds
    return [a, b]


async def concurrent():
    return await asyncio.gather(fetch("a", 1), fetch("b", 1))   # 1 second


async def structured():
    results = []
    async with asyncio.TaskGroup() as group:       # Python 3.11+
        tasks = [group.create_task(fetch(n, 1)) for n in ("a", "b", "bad")]
    # unreachable: leaving the block raises ExceptionGroup, and "a" and "b"
    # were cancelled the moment "bad" failed
    results = [t.result() for t in tasks]
    return results


asyncio.run(concurrent())

try:
    asyncio.run(structured())
except* ValueError as group:                        # except* handles groups
    print("failed:", group.exceptions)
''',
          caption: 'gather for results, TaskGroup for lifetimes you can reason '
              'about.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Awaiting in a loop is not concurrency',
          text:
              'for url in urls: await fetch(url) is strictly sequential. Create '
              'the tasks first, or pass the coroutines to gather, so they '
              'overlap.',
        ),
      ],
    ),
    Section(
      id: 'timeouts',
      heading: 'Cancellation and timeouts',
      blocks: [
        ProseBlock(
          'Cancellation is cooperative and works by exception. Cancelling a '
          'task raises CancelledError at its current await point, which unwinds '
          'through finally blocks and async context managers so cleanup runs '
          'normally. Never swallow CancelledError in a broad except — if you '
          'catch it to clean up, re-raise it.',
        ),
        ProseBlock(
          'asyncio.timeout is the modern way to bound an operation: it cancels '
          'whatever is inside the block and converts the cancellation into a '
          'TimeoutError. Because the timeout applies to the whole block, not a '
          'single call, it composes with everything inside it.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import asyncio


async def slow():
    try:
        await asyncio.sleep(10)
    except asyncio.CancelledError:
        print("cleaning up")
        raise                        # always re-raise cancellation
    finally:
        print("finally runs too")


async def main():
    try:
        async with asyncio.timeout(0.5):     # Python 3.11+
            await slow()
    except TimeoutError:
        print("gave up after 0.5s")

    task = asyncio.create_task(slow())
    await asyncio.sleep(0)                   # let it start
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        print("cancelled cleanly")


asyncio.run(main())
''',
          caption: 'Cancellation is an exception; timeouts are cancellation.',
        ),
      ],
    ),
    Section(
      id: 'async-protocols',
      heading: 'Async iteration, context managers and blocking code',
      blocks: [
        ProseBlock(
          'The synchronous protocols all have asynchronous twins. '
          '__aiter__/__anext__ power async for, so a paginated API or a '
          'streaming response can be consumed one item at a time while other '
          'tasks run. __aenter__/__aexit__ power async with, which is how '
          'connection pools and transactions are managed.',
        ),
        ProseBlock(
          'When you must call a blocking function — a legacy database driver, '
          'an image library — asyncio.to_thread runs it in a worker thread and '
          'gives you an awaitable, so the loop stays responsive. For CPU-bound '
          'work, a ProcessPoolExecutor via loop.run_in_executor is the honest '
          'answer, because threads cannot escape the GIL.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import asyncio
import time


async def paginate(pages):
    for page in range(pages):
        await asyncio.sleep(0.1)        # pretend network call
        yield f"page-{page}"            # async generator


async def main():
    async for page in paginate(3):
        print(page)

    # Blocking call, kept off the event loop:
    result = await asyncio.to_thread(time.sleep, 0.2)
    print("blocking call finished", result)


class Pool:
    async def __aenter__(self):
        print("connect")
        return self

    async def __aexit__(self, exc_type, exc, tb):
        print("disconnect")
        return False


async def use_pool():
    async with Pool() as pool:
        await asyncio.sleep(0)
        print("using", pool)


asyncio.run(main())
asyncio.run(use_pool())
''',
          caption: 'async for, async with, and escaping to a thread.',
        ),
        CollapsibleBlock(
          title: 'Under the hood: what the event loop actually does',
          children: [
            ProseBlock(
              'The loop keeps a queue of callbacks that are ready to run and a '
              'heap of timers. One iteration takes every ready callback and '
              'runs it to completion, then asks the operating system — via '
              'epoll, kqueue or IOCP — which file descriptors have become '
              'readable or writable, waiting no longer than the nearest timer. '
              'Anything that becomes ready is turned into a callback for the '
              'next iteration.',
            ),
            ProseBlock(
              'A coroutine suspends by yielding a Future up to the Task driving '
              'it; the Task registers a callback to resume when that Future is '
              'resolved. That is the same frozen-frame mechanism generators '
              'use — a native coroutine is a generator whose suspension points '
              'are awaits. It is also why a blocking call is catastrophic: the '
              'loop is a plain function call stack, and while your code runs, '
              'nothing else can.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
import asyncio


async def hog():
    total = 0
    for i in range(50_000_000):     # no await: the loop cannot interleave
        total += i
    return total


async def ticker():
    for _ in range(5):
        print("tick")
        await asyncio.sleep(0.1)


async def main():
    # ticker is starved until hog() finishes, despite being a separate task.
    await asyncio.gather(hog(), ticker())

    # The fix: move CPU-bound work off the loop entirely.
    await asyncio.gather(asyncio.to_thread(sum, range(50_000_000)), ticker())


asyncio.run(main())
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
      id: 'ex-async-gather',
      title: 'Turn sequential awaits into concurrency',
      prompt: [
        ProseBlock(
          'The function below awaits each fetch in turn, so three 200ms calls '
          'take 600ms. Rewrite it so all three run concurrently and the results '
          'still come back in the original order. Then say what the total time '
          'becomes and why.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
async def fetch_all(names):
    results = []
    for name in names:
        results.append(await fetch(name))
    return results
''',
        ),
      ],
      starterCode: '''
import asyncio
import time


async def fetch(name):
    await asyncio.sleep(0.2)
    return f"{name}-ok"


async def fetch_all(names):
    results = []
    for name in names:
        results.append(await fetch(name))
    return results


async def main():
    started = time.perf_counter()
    print(await fetch_all(["a", "b", "c"]))
    print(f"{time.perf_counter() - started:.2f}s")


asyncio.run(main())
''',
      solutionCode: '''
import asyncio
import time


async def fetch(name):
    await asyncio.sleep(0.2)
    return f"{name}-ok"


async def fetch_all(names):
    # gather preserves argument order in its results, regardless of
    # which coroutine finishes first.
    return await asyncio.gather(*(fetch(name) for name in names))


async def main():
    started = time.perf_counter()
    print(await fetch_all(["a", "b", "c"]))
    print(f"{time.perf_counter() - started:.2f}s")


asyncio.run(main())
# ['a-ok', 'b-ok', 'c-ok']
# 0.20s   - the three waits overlap instead of queueing
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The original code already used await. Why was it not '
              'concurrent?',
          expectedAnswer:
              'await means "suspend until this finishes and give me the '
              'result". Only one operation was ever in flight, so the loop had '
              'nothing else to run during each wait. Concurrency requires '
              'scheduling several coroutines — with gather, create_task or a '
              'TaskGroup — before awaiting them.',
        ),
        SelfCheckQuestion(
          question:
              'gather returns results in argument order even though "c" might '
              'finish first. How, and what happens if one of them raises?',
          expectedAnswer:
              'gather keeps a result slot per awaitable and fills each one as '
              'it completes, so ordering is positional rather than temporal. By '
              'default the first exception propagates immediately while the '
              'other tasks keep running in the background; '
              'return_exceptions=True instead returns exception objects in '
              'place of results. TaskGroup avoids the loose-ends problem '
              'entirely.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-async-timeout',
      title: 'Bound an operation and clean up after it',
      prompt: [
        ProseBlock(
          'Write fetch_with_limit(name, seconds) that awaits slow_fetch(name) '
          'but gives up after seconds, returning None instead of raising. '
          'slow_fetch must be able to run its cleanup when cancelled. Use '
          'asyncio.timeout, and make sure CancelledError is re-raised inside '
          'slow_fetch rather than swallowed.',
        ),
      ],
      starterCode: '''
import asyncio


async def slow_fetch(name):
    try:
        await asyncio.sleep(5)
        return f"{name}-ok"
    except asyncio.CancelledError:
        # TODO: clean up, then let the cancellation continue
        ...


async def fetch_with_limit(name, seconds):
    # TODO: bound slow_fetch with asyncio.timeout, return None on timeout
    ...


async def main():
    print(await fetch_with_limit("a", 0.3))


asyncio.run(main())
''',
      solutionCode: '''
import asyncio


async def slow_fetch(name):
    try:
        await asyncio.sleep(5)
        return f"{name}-ok"
    except asyncio.CancelledError:
        print(f"releasing connection for {name}")
        raise                     # never swallow cancellation
    finally:
        print(f"{name}: done or abandoned")


async def fetch_with_limit(name, seconds):
    try:
        async with asyncio.timeout(seconds):
            return await slow_fetch(name)
    except TimeoutError:
        return None


async def main():
    print(await fetch_with_limit("a", 0.3))
# releasing connection for a
# a: done or abandoned
# None


asyncio.run(main())
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question: 'Why must CancelledError be re-raised?',
          expectedAnswer:
              'Cancellation is a request that the task actually stop. '
              'Swallowing it makes the task carry on as though nothing '
              'happened, so timeouts silently fail to take effect and a '
              'TaskGroup or shutdown routine waits forever for a task that '
              'refuses to die. Catch it only to clean up, then re-raise.',
        ),
        SelfCheckQuestion(
          question:
              'asyncio.timeout raises TimeoutError, not CancelledError, at the '
              'call site. Why the conversion?',
          expectedAnswer:
              'Because from the caller\'s point of view the operation timed '
              'out; it was not itself cancelled. Converting keeps the caller '
              'able to distinguish "my inner work ran out of time" from "I am '
              'being shut down", which would otherwise look identical and '
              'silently cancel the wrong thing.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-async-blocking',
      title: 'Get a blocking call off the event loop',
      prompt: [
        ProseBlock(
          'The coroutine below calls a synchronous, blocking library function. '
          'While it runs, no other task can make progress — the ticker stops. '
          'Fix it with asyncio.to_thread so the ticks keep flowing, and explain '
          'why a thread is acceptable here even with the GIL.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
async def process():
    return blocking_call()      # time.sleep-style: holds the thread
''',
        ),
      ],
      starterCode: '''
import asyncio
import time


def blocking_call():
    time.sleep(1)               # a legacy library with no async version
    return "processed"


async def process():
    return blocking_call()      # TODO: stop this blocking the event loop


async def ticker():
    for _ in range(4):
        print("tick")
        await asyncio.sleep(0.25)


async def main():
    print(await asyncio.gather(process(), ticker()))


asyncio.run(main())
''',
      solutionCode: '''
import asyncio
import time


def blocking_call():
    time.sleep(1)
    return "processed"


async def process():
    # Runs in a worker thread; the event loop stays free to run other tasks.
    return await asyncio.to_thread(blocking_call)


async def ticker():
    for _ in range(4):
        print("tick")
        await asyncio.sleep(0.25)


async def main():
    print(await asyncio.gather(process(), ticker()))


asyncio.run(main())
# tick / tick / tick / tick  interleaved during the second of blocking work
# ['processed', None]
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The GIL means only one thread runs Python at a time. Why does a '
              'thread help here?',
          expectedAnswer:
              'Because this work is not executing Python bytecode — it is '
              'waiting. time.sleep, socket reads and most C library calls '
              'release the GIL while they block, so the main thread carries on '
              'running the event loop. A thread would not help if the blocking '
              'function were a tight pure-Python computation; that needs a '
              'process pool.',
        ),
        SelfCheckQuestion(
          question:
              'What would happen if blocking_call were a CPU-bound loop instead '
              'of a sleep?',
          expectedAnswer:
              'The thread would hold the GIL for most of its run, so the event '
              'loop would be starved almost as badly as before — ticks would '
              'stutter rather than stop. The fix there is '
              'loop.run_in_executor with a ProcessPoolExecutor, which uses a '
              'separate interpreter and therefore a separate GIL, at the cost '
              'of pickling arguments and results.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 222000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'asyncio in four minutes. Start with the distinction that decides '
              'everything: concurrency is dealing with many things at once, '
              'parallelism is doing many things at once. asyncio gives you the '
              'first, in a single thread, and nothing at all of the second.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'So use it when you are waiting — on networks, databases, disks. '
              'Use multiprocessing when you are computing and want more cores, '
              'because the global interpreter lock means threads cannot run '
              'Python bytecode in parallel anyway.',
          startMs: 44000,
          endMs: 88000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Mechanically: async def creates a coroutine function, calling it '
              'runs nothing and returns a coroutine object, and asyncio dot run '
              'starts the event loop that drives it. Every await is a point '
              'where your coroutine suspends and the loop goes and runs '
              'somebody else.',
          startMs: 88000,
          endMs: 134000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'The mistake everyone makes first is awaiting in a loop and '
              'calling it concurrent. It is not — that is sequential code with '
              'extra keywords. You need several operations in flight: gather, '
              'or create-task, or better, a TaskGroup, which guarantees every '
              'task is finished or cancelled when the block exits.',
          startMs: 134000,
          endMs: 184000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And one rule above all: never block the loop. No time dot sleep, '
              'no synchronous HTTP client, no heavy computation inside a '
              'coroutine. Use the async equivalent, or push it to a thread with '
              'asyncio dot to-thread.',
          startMs: 184000,
          endMs: 222000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 510000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Async Python today. I want to be blunt at the start: async is '
              'not a performance feature you sprinkle on. It is a different '
              'execution model, it is contagious through your call stack, and '
              'if your program is not waiting on something external it will '
              'make things slower, not faster.',
          startMs: 0,
          endMs: 54000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The decision rule is I/O bound versus CPU bound. If your program '
              'spends its time waiting for networks, disks or databases, '
              'asyncio lets one thread juggle thousands of those waits. If it '
              'spends its time computing, you want multiple processes, because '
              'the global interpreter lock permits only one thread to run '
              'Python bytecode at a time.',
          startMs: 54000,
          endMs: 124000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'The pieces are simple. async def makes a coroutine function. '
              'Calling it executes nothing and hands back a coroutine object — '
              'exactly like a generator. asyncio dot run starts an event loop, '
              'drives that coroutine to completion, and shuts the loop down. '
              'One asyncio dot run at the top of your program, ideally.',
          startMs: 124000,
          endMs: 190000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'await is the interesting keyword. It suspends the current '
              'coroutine and returns control to the loop, which is then free to '
              'resume anything else that has become ready. When the awaited '
              'operation completes, your coroutine picks up exactly where it '
              'left off with the result in hand.',
          startMs: 190000,
          endMs: 250000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Now the trap. Writing "for url in urls, await fetch url" is '
              'perfectly sequential — one request at a time, just with more '
              'syntax. To overlap them you must schedule them first: pass the '
              'coroutines to gather, or create tasks. Awaiting is how you '
              'collect results, not how you start work.',
          startMs: 250000,
          endMs: 316000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'And prefer TaskGroup over gather where you can. With gather, if '
              'one coroutine raises, the others carry on running unattended and '
              'you have to clean them up yourself. A TaskGroup is structured '
              'concurrency: when the async with block exits, every task inside '
              'is guaranteed finished or cancelled, and failures come out as an '
              'ExceptionGroup you handle with except-star.',
          startMs: 316000,
          endMs: 392000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Cancellation deserves attention because it is how timeouts work. '
              'Cancelling a task raises CancelledError at its current await '
              'point, which unwinds finally blocks and async context managers '
              'so cleanup runs. Catch it if you must release something, then '
              're-raise — swallowing it means your task ignores shutdown '
              'entirely.',
          startMs: 392000,
          endMs: 456000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Last rule, and the one that causes the most confusing bugs: '
              'never block the loop. It is one thread. A synchronous HTTP call '
              'or a big computation inside a coroutine stops every other task '
              'dead. Use the async client, or wrap the blocking call in asyncio '
              'dot to-thread and await that instead.',
          startMs: 456000,
          endMs: 510000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 870000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'The long version on concurrency. We will do the three models and '
              'where each belongs, the GIL as it actually is rather than as '
              'folklore, what the event loop does on each iteration, coroutines '
              'as generators, structured concurrency, cancellation semantics, '
              'and the failure modes you will meet in production.',
          startMs: 0,
          endMs: 68000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'The GIL first, precisely. It is a mutex around the interpreter '
              'state, so exactly one thread executes Python bytecode at a time. '
              'Crucially it is released around blocking I/O and inside many C '
              'extensions — NumPy drops it for array operations. So threads do '
              'give you real overlap for I/O and for heavy C work, and give you '
              'nothing for pure-Python computation.',
          startMs: 68000,
          endMs: 156000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Worth adding that this is changing. Python 3.13 shipped an '
              'experimental free-threaded build with no GIL, and 3.12 added '
              'per-interpreter GILs for subinterpreters. Neither is the default '
              'yet, and both come with caveats, but the assumption that CPython '
              'can never run Python code in parallel is no longer permanently '
              'true.',
          startMs: 156000,
          endMs: 238000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Now the loop itself. Each iteration it runs every callback '
              'currently ready, then asks the operating system which sockets '
              'have become readable or writable — epoll on Linux, kqueue on '
              'BSD, IOCP on Windows — blocking no longer than the nearest '
              'scheduled timer. Anything that fires becomes a callback for the '
              'next pass. It is a single-threaded loop over ready events.',
          startMs: 238000,
          endMs: 330000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'And a coroutine is a generator with different syntax. It has a '
              'frame that survives suspension — locals, instruction pointer, '
              'enclosing try blocks — and await is a suspension point where it '
              'yields a Future up to the Task driving it. The Task adds a '
              'callback to resume when that Future resolves. Everything you '
              'know about generators transfers directly.',
          startMs: 330000,
          endMs: 418000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Which explains why blocking is fatal rather than merely slow. '
              'The loop is an ordinary function call stack. While your code '
              'runs without awaiting, the loop is not running, so no timers '
              'fire, no sockets are read, and no other task advances. A one '
              'second synchronous call in a web handler adds a second of '
              'latency to every concurrent request, not just its own.',
          startMs: 418000,
          endMs: 504000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Structured concurrency is the biggest recent improvement. The '
              'problem with fire-and-forget tasks is that they outlive the code '
              'that created them, exceptions inside them can be swallowed '
              'entirely, and shutdown becomes guesswork. TaskGroup makes task '
              'lifetime nest like a block scope: nothing escapes the async with '
              'still running.',
          startMs: 504000,
          endMs: 586000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'And it forced a genuinely new language feature. If five tasks '
              'run concurrently and three fail differently, no single exception '
              'is the truth. So 3.11 added ExceptionGroup and the except-star '
              'syntax, which handles every exception of a given type inside the '
              'group and lets the rest keep propagating as a smaller group.',
          startMs: 586000,
          endMs: 664000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Cancellation is worth getting exactly right. It is delivered as '
              'CancelledError at the task\'s current await, and since 3.8 it '
              'inherits from BaseException specifically so a broad except '
              'Exception does not eat it. Catch it only to clean up and then '
              're-raise. If you genuinely have a critical section, '
              'asyncio.shield exists — and is almost always the wrong answer.',
          startMs: 664000,
          endMs: 752000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'On escaping the loop: asyncio dot to-thread for blocking I/O '
              'libraries, and run-in-executor with a ProcessPoolExecutor for '
              'CPU-bound work, which pays pickling costs but gets you real '
              'cores. Also remember async has no free lunch on ordering — you '
              'still need asyncio\'s own Lock and Semaphore when a sequence of '
              'awaits must not interleave.',
          startMs: 752000,
          endMs: 838000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'To close: async is for waiting, processes are for computing, '
              'await collects rather than starts, TaskGroup beats gather, '
              'cancellation is an exception you must re-raise, and one blocking '
              'call ruins the entire program.',
          startMs: 838000,
          endMs: 870000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'asyncio is for waiting, not for computing',
      body:
          'One thread, one event loop, tasks that yield at every await. It '
          'overlaps I/O beautifully and does nothing for CPU-bound work — the '
          'GIL means threads will not help there either, so reach for processes '
          'instead.',
    ),
    SummaryCard(
      title: 'await collects; it does not start',
      body:
          'Awaiting coroutines one at a time is sequential code with extra '
          'keywords. Schedule work first with create_task, gather or a '
          'TaskGroup, then await the handles to collect results.',
    ),
    SummaryCard(
      title: 'Never block the loop',
      body:
          'time.sleep, a synchronous HTTP client or a heavy computation inside '
          'a coroutine stops every other task, because there is only one '
          'thread. Use an async equivalent, asyncio.to_thread for blocking I/O, '
          'or a process pool for CPU work.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Concurrency vs parallelism',
      definition:
          'Concurrency is interleaving many in-flight operations, which one '
          'thread can do; parallelism is executing several at the same instant, '
          'which needs multiple cores. asyncio provides only the former.',
    ),
    KeyConcept(
      term: 'GIL',
      definition:
          'CPython\'s global interpreter lock, which lets only one thread '
          'execute bytecode at a time. It is released during blocking I/O and '
          'in many C extensions, so threads help with waiting and not with '
          'pure-Python computation.',
    ),
    KeyConcept(
      term: 'Coroutine',
      definition:
          'What an async def function returns when called: an object that runs '
          'no code until something awaits it or schedules it on the loop. '
          'Mechanically a generator whose suspension points are awaits.',
    ),
    KeyConcept(
      term: 'Task',
      definition:
          'A coroutine wrapped and scheduled on the event loop by '
          'create_task or a TaskGroup, so it runs concurrently with whatever '
          'created it rather than only when awaited.',
    ),
    KeyConcept(
      term: 'Structured concurrency',
      definition:
          'The guarantee, provided by asyncio.TaskGroup, that every task '
          'started inside a block has finished or been cancelled when the block '
          'exits, so task lifetimes nest like scopes and errors surface as an '
          'ExceptionGroup.',
    ),
    KeyConcept(
      term: 'CancelledError',
      definition:
          'The exception raised at a task\'s current await point when it is '
          'cancelled. It inherits from BaseException so broad handlers do not '
          'swallow it; catch it only to clean up, then re-raise.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Writing "for item in items: await process(item)" and expecting '
          'concurrency.',
      correction:
          'That awaits each call to completion before starting the next. Use '
          'asyncio.gather(*(process(i) for i in items)) or a TaskGroup so the '
          'operations are actually in flight together.',
    ),
    Mistake(
      mistake:
          'Calling a blocking function — time.sleep, requests.get, a big loop '
          '— inside a coroutine.',
      correction:
          'It holds the single thread, so every other task stalls. Use the '
          'async equivalent (asyncio.sleep, httpx, aiohttp), or await '
          'asyncio.to_thread(fn, ...) for blocking I/O, or a ProcessPoolExecutor '
          'for CPU-bound work.',
    ),
    Mistake(
      mistake:
          'Catching CancelledError in a broad handler and not re-raising it.',
      correction:
          'The task then ignores cancellation, so timeouts never take effect '
          'and shutdown hangs waiting for it. Catch it only to release '
          'resources, then re-raise — and prefer try/finally, which needs no '
          'catch at all.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'When would you choose asyncio over threads, and threads over '
          'multiprocessing?',
      answer:
          'asyncio for large numbers of I/O-bound operations, because thousands '
          'of coroutines cost far less than thousands of threads and the '
          'scheduling points are explicit at each await, which makes reasoning '
          'about shared state easier. Threads when the work is I/O-bound but the '
          'library is synchronous and has no async version, since blocking calls '
          'release the GIL. Multiprocessing when the work is CPU-bound, because '
          'only separate interpreters give real parallelism — paying for '
          'pickling arguments and results in exchange.',
    ),
    InterviewQuestion(
      question:
          'What is the difference between calling a coroutine function, '
          'awaiting it, and wrapping it in create_task?',
      answer:
          'Calling it merely builds a coroutine object and runs no code; if '
          'nothing ever awaits it you get a "coroutine was never awaited" '
          'warning. Awaiting it runs it to completion inline and yields its '
          'result, which is sequential. create_task schedules it on the event '
          'loop immediately and returns a handle, so it progresses alongside '
          'the caller and you await the handle later to collect the result.',
    ),
    InterviewQuestion(
      question:
          'Why is asyncio.TaskGroup preferred over asyncio.gather in new code?',
      answer:
          'Because it provides structured concurrency: when the async with '
          'block exits, every task created inside it is guaranteed to have '
          'finished or been cancelled, so no task outlives the scope that '
          'started it. If one task fails, the rest are cancelled and the '
          'failures surface together as an ExceptionGroup, handled with '
          'except*. With gather, a failure leaves siblings running unattended '
          'unless you write the cleanup yourself, and return_exceptions=True '
          'hides errors in the results list where they are easy to ignore.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'asyncio — Python Docs',
    url: 'https://docs.python.org/3/library/asyncio.html',
    description:
        'Top-level reference for the asyncio package: the event loop, streams, '
        'synchronisation primitives, subprocesses and queues.',
  ),
  Source(
    title: 'Coroutines and tasks — Python Docs',
    url: 'https://docs.python.org/3/library/asyncio-task.html',
    description:
        'The page covering async/await, creating tasks, gather, TaskGroup, '
        'timeouts and cancellation semantics.',
  ),
];
