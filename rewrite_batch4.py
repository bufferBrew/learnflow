#!/usr/bin/env python3
"""Massive batch: finish collections, all functions, environments"""
import re

BASE = "/Users/kartikjain/Desktop/code/learnflow/lib/sample_data"

def apply(filepath, replacements):
    with open(filepath, 'r') as f:
        content = f.read()
    applied = 0
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new, 1)
            applied += 1
        else:
            print(f"  MISS: {old[:50]}...")
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"  {filepath.split('/')[-1]}: {applied}/{len(replacements)}")
    return applied

# ============================================================
# lesson_collections.dart - STANDARD (s1-s8)
# ============================================================
col_std = [
    # s1
    ("""              'This episode is about containers — and really about choosing '
              'between them. Most Python performance problems I have seen were '
              'not about the language being slow; they were a list being used '
              'where a set belonged, or a string being rebuilt in a loop.'""",
     """              'This episode is about containers — and honestly, about making choices. '
              'Most Python performance problems I\\'ve seen weren\\'t the language being slow. '
              'They were using a list where a set belonged — like searching a phone book '
              'page by page instead of using the index. Or rebuilding a string in a loop '
              'like repainting the same wall every time you add a single brushstroke.'"""),
    # s2
    ("""              'Lists first. Ordered, mutable, indexable, and backed by an '
              'over-allocated array. Appending is amortised constant time, '
              'which is why append-in-a-loop is fine. Inserting or deleting at '
              'the front is linear because everything after it shifts, so if '
              'you are doing that repeatedly you want a deque instead.'""",
     """              'Let\\'s start with lists. They\\'re ordered, mutable, indexable — your general-purpose workhorse. '
              'Under the hood, it\\'s a slightly-over-allocated array, so appending is cheap on average. '
              'That\\'s why building a list in a loop with .append() is totally fine. '
              'But inserting or deleting at the front? Every single item behind it shifts — '
              'like removing the first person from a line and everyone else scoots forward. '
              'If you\\'re doing that repeatedly, you want a deque — it\\'s built for both ends.'"""),
    # s3
    ("""              'Slicing is worth being precise about. Start is inclusive, stop '
              'is exclusive, step can be negative, and the result is always a '
              'new list. That last part means a slice of a big list copies the '
              'references — cheap, but not free — and it is why '
              'items-colon-colon-minus-one gives you a reversed copy rather '
              'than reversing in place.'""",
     """              'Slicing deserves a moment because it\\'s both elegant and easy to misuse. '
              'The formula is [start:stop:step] — start is inclusive, stop is exclusive, step can go backwards. '
              'Critical detail: slicing always produces a NEW list. It copies the references, not the objects — '
              'cheap, but not free on a million-item list. That\\'s why items[::-1] gives you a reversed copy, '
              'not an in-place reversal. If you just want to walk backwards, use reversed() — no copy needed.'"""),
    # s4
    ("""              'Dicts are the workhorse, and there are three access idioms. '
              'Square brackets when a missing key is genuinely a bug — let it '
              'raise KeyError. get with a default when absence is normal. And '
              'setdefault when you want to insert the default at the same time, '
              'though defaultdict usually reads better for that.'""",
     """              'Dicts are the true workhorse, and there are three access patterns worth knowing cold. '
              'Square brackets: use when a missing key means something is genuinely broken — let it scream. '
              '.get(key, default): use when absence is totally normal, like checking a settings dict. '
              '.setdefault(): use when you want to insert the default AND get it in one shot — '
              'though honestly, defaultdict from collections usually reads cleaner for that pattern.'"""),
    # s5
    ("""              'Sets are the ones people under-use. Uniqueness, membership, and '
              'the whole algebra: ampersand for intersection, pipe for union, '
              'minus for difference, caret for symmetric difference. "Which '
              'users are in both groups" is one operator, and it is fast '
              'because both sides are hashed.'""",
     """              'Sets are the unsung heroes that people don\\'t reach for enough. '
              'Unique items, lightning-fast membership tests, and a whole algebra built right in: '
              '& for intersection (\"in both\"), | for union (\"in either\"), '
              '- for difference (\"in first but not second\"), ^ for symmetric difference (\"in one or the other but not both\"). '
              '\"Which users are in both groups?\" becomes a single & operator. '
              'And it\\'s fast — both sides are hashed, so no scanning required.'"""),
    # s6
    ("""              'Tuples are for fixed-shape records: a coordinate, a row, the two '
              'things a function returns. They are immutable, so they are '
              'hashable, so they can be dict keys — which is how you build a '
              'lookup table indexed by a pair. Lists are for a variable number '
              'of interchangeable items.'""",
     """              'Tuples are for fixed-shape records where each position means something specific: '
              'a latitude-longitude pair, a database row, the three things a function returns. '
              'Since they\\'re immutable, they\\'re hashable — so they can be dict keys. '
              'That\\'s how you build a lookup table indexed by a pair, like a grid or a coordinate system. '
              'Lists are for a variable number of interchangeable items — a shopping cart, not a coordinate.'"""),
    # s7
    ("""              'Comprehensions tie it together. A comprehension says "this new '
              'collection is derived from that one" in a single expression, and '
              'the list, set and dict forms all follow the same shape. Drop the '
              'brackets inside a call like sum or any and you get a generator '
              'expression that never materialises the intermediate list.'""",
     """              'Comprehensions tie everything together beautifully. They say \"build me a new collection from this one\" '
              'in a single, readable expression. List, set, and dict comprehensions all share the same shape: '
              '[expr for item in source if condition]. Drop the brackets inside a function call like sum() '
              'and you get a generator expression — it streams values one at a time without ever building '
              'the whole list in memory. It\\'s the difference between loading every page of a book or reading one at a time.'"""),
    # s8
    ("""              'Then the collections module. Counter for frequency, defaultdict '
              'for grouping, deque for both-ends work and for maxlen-bounded '
              'buffers, namedtuple when a tuple\\'s positions deserve names. If '
              'you find yourself writing "if key not in d: d of key equals '
              'empty list", the standard library already has that.'""",
     """              'Then there\\'s the collections module — Python\\'s Swiss Army knife drawer. '
              'Counter for counting things: words in a document, votes in an election. '
              'defaultdict for grouping: no more \"if key not in dict, create empty list\" dance. '
              'deque for fast operations at both ends, plus maxlen for automatic sliding windows. '
              'namedtuple when a tuple\\'s positions deserve actual names. '
              'If you ever catch yourself writing \"if key not in d: d[key] = []\", '
              'remember: the standard library did that work for you already.'"""),
]
apply(f"{BASE}/python/lesson_collections.dart", col_std)

# ============================================================
# lesson_collections.dart - DEEP DIVE (d1-d11)
# ============================================================
col_deep = [
    # d1
    ("""              'Deep dive on Python\\'s containers. We will do the memory layout '
              'of a list, the hash table behind dicts and sets, what the '
              'ordering guarantee actually promises, comprehension scoping, and '
              'the complexity table you should carry around in your head.'""",
     """              'Deep dive on Python\\'s containers. We\\'re going to pop the hood: '
              'the memory layout of a list, the hash table machinery inside dicts and sets, '
              'what the insertion-order guarantee actually means, comprehension scoping rules, '
              'and the big-O cheat sheet you should tattoo on your brain. '
              'Think of this as the mechanic\\'s view — when something feels slow, you\\'ll know exactly why.'"""),
    # d2
    ("""              'A CPython list is an array of pointers, not an array of values. '
              'That is why it can hold mixed types, and why indexing is '
              'constant time. When it fills up, it allocates a larger block — '
              'growing by roughly an eighth each time — and copies the pointers '
              'across. Any single append can therefore be expensive, but '
              'averaged over many appends the cost per item is constant. That '
              'is what amortised means.'""",
     """              'A CPython list is an array of pointers — not an array of actual values. '
              'That\\'s the secret to how it holds mixed types: each slot just points to some object. '
              'Indexing is instant because it\\'s just pointer arithmetic. When the array fills up, '
              'Python allocates a bigger one — growing by roughly 12% each time — and copies all the pointers over. '
              'Any single append might trigger this resize, which is expensive. But spread across thousands of appends, '
              'the average cost per item is constant. That\\'s what \"amortized O(1)\" means: '
              'like paying rent once a month but spreading the cost over 30 days.'"""),
    # d3
    ("""              'The corollary is the operations you should avoid at scale. '
              'insert at zero and pop from zero are linear because every '
              'remaining pointer shifts. In a loop that is quadratic. '
              'collections.deque is implemented as a doubly linked list of '
              'blocks, so appends and pops at both ends are constant time — at '
              'the cost of indexing in the middle being linear.'""",
     """              'Here\\'s what to avoid at scale. insert(0, item) and pop(0) move every remaining pointer — '
              'like asking everyone in a line to step back one spot. Do that in a loop and suddenly '
              'your O(n) algorithm becomes O(n²) — a thousand items means a million pointer shifts. '
              'collections.deque solves this: it\\'s a doubly-linked list of blocks, so pushing and popping '
              'at either end is always instant. The tradeoff? Indexing into the middle is linear. '
              'No free lunch — pick the tool for your access pattern.'"""),
    # d4
    ("""              'Now dicts. A dict is an open-addressed hash table. Hash the key, '
              'take the low bits to choose a slot, and compare what is there — '
              'identity first as a fast path, then equality. If it does not '
              'match, probe another slot using a sequence derived from the '
              'remaining hash bits. When the table is about two-thirds full it '
              'grows and everything is rehashed.'""",
     """              'Now let\\'s walk through how a dict actually finds your value. It\\'s an open-addressed hash table. '
              'You hash the key, take the low bits to pick a slot, and look at what\\'s there. '
              'First it checks identity — \"is this the exact same object?\" — as a fast path. Then equality. '
              'If it\\'s not a match, it probes the next slot using a deterministic sequence from the remaining hash bits. '
              'When the table hits about two-thirds full, it doubles in size and rehashes everything — '
              'like a restaurant expanding and reassigning every table number.'"""),
    # d5
    ("""              'Since 3.6 the layout is split in two: a dense array of entries '
              'in insertion order, plus a sparse array of indexes into it. That '
              'saved a lot of memory, and it made iteration follow insertion '
              'order as a side effect. In 3.7 that side effect was promoted to '
              'a language guarantee — so you may now rely on it, and Counter '
              'and defaultdict inherit it too.'""",
     """              'Since Python 3.6, the dict layout has been split into two arrays: '
              'a dense array of entries in insertion order, and a sparse index array pointing into it. '
              'This saved significant memory and, as a happy side effect, made iteration follow insertion order. '
              'In 3.7 that side effect became a guarantee — you can count on dicts preserving insertion order. '
              'And since Counter and defaultdict are dict subclasses, they inherit this behavior for free.'"""),
    # d6
    ("""              'The hashing contract has real consequences for your own classes. '
              'Objects that compare equal must hash equal, otherwise a set will '
              'happily hold two things you consider identical. And a hash must '
              'not change while the object is in a container, which is exactly '
              'why lists and dicts are unhashable. Define dunder eq on a class '
              'and Python sets dunder hash to None, making instances '
              'unhashable, unless you define it yourself.'""",
     """              'The hashing contract has teeth, especially for your own classes. Rule one: '
              'if two objects compare equal, they MUST hash to the same value — otherwise a set will '
              'happily hold two copies of what you consider the same thing. Rule two: '
              'a hash must never change while the object lives inside a container — that\\'s why lists and dicts '
              'are unhashable. If you define __eq__ on a class, Python automatically sets __hash__ to None, '
              'making instances unhashable unless you explicitly define a hash yourself. '
              'It\\'s Python\\'s way of saying \"I\\'m not guessing — you tell me how to hash this.'"""),
    # d7
    ("""              'Sets use the same machinery with no value alongside the key. '
              'That is why set membership and dict key membership have the same '
              'cost, and why converting a list to a set before a batch of '
              'membership tests is such a reliable win — it turns an '
              'n-times-m scan into n-plus-m hashing.'""",
     """              'Sets use exactly the same hash table machinery as dicts — just without a value next to each key. '
              'So set membership is exactly as fast as dict key lookup. This is why converting a list to a set '
              'before doing a bunch of membership tests is such an enormous win. '
              'Checking \"is X in list\" N times against a list of M items is O(N×M) — scanning the list every time. '
              'Build a set from the list once: O(M). Check N items: O(N). Total: O(N+M). '
              'It\\'s like building an index once instead of re-reading the book for every question.'"""),
    # d8
    ("""              'Comprehensions deserve a note on scoping. In Python 3 a '
              'comprehension runs in its own scope, so the loop variable does '
              'not leak into the surrounding function — that changed from '
              'Python 2. It also means a comprehension can read enclosing '
              'variables but its iteration variable is entirely its own, which '
              'is what makes them safe to nest.'""",
     """              'Comprehensions have their own scope — a detail that matters more than you\\'d think. '
              'In Python 3, the loop variable inside a comprehension stays inside — it doesn\\'t leak out '
              'and pollute your surrounding function. This changed from Python 2, where it was a common footgun. '
              'The comprehension can read variables from outside, but its own iteration variable is completely contained. '
              'That\\'s what makes nested comprehensions safe: each one has its own little bubble.'"""),
    # d9
    ("""              'And a word on copies, because it catches everyone. list of x, '
              'x-colon and x dot copy are all shallow: you get a new outer list '
              'holding the same inner objects. Copy a list of dicts that way '
              'and mutating one of those dicts is still visible through both '
              'lists. copy.deepcopy walks the whole structure, which is correct '
              'and can be very slow.'""",
     """              'A word on copies, because this catches literally everyone. list(x), x[:], and x.copy() '
              'are ALL shallow copies: you get a new outer container, but it holds the same inner objects. '
              'It\\'s like photocopying a table of contents — the page numbers are new, but they point to the same chapters. '
              'Copy a list of dicts this way, and mutating a dict is visible through both copies. '
              'copy.deepcopy walks the entire nested structure and duplicates everything — correct, but potentially very slow. '
              'Be intentional about which one you need.'"""),
    # d10
    ("""              'On the standard library, two more worth knowing beyond the usual '
              'four. heapq turns a list into a priority queue with push and pop '
              'in log n — that is your "smallest n items" and scheduling tool. '
              'bisect keeps a sorted list sorted with binary insertion, which '
              'beats re-sorting after every insert.'""",
     """              'Two more standard library gems beyond the usual four. heapq turns a plain list into a priority queue: '
              'push and pop in O(log n). This is your tool for \"give me the top 10 items\" or any kind of scheduling. '
              'bisect keeps a sorted list sorted using binary search — O(log n) to find where to insert, '
              'much better than re-sorting the whole list after every addition. '
              'Together, these two solve a surprising number of real-world problems elegantly.'"""),
    # d11
    ("""              'The summary to carry: list indexing and append are constant, '
              'front insertion is linear; dict and set lookup is constant on '
              'average and requires hashable keys; dicts keep insertion order; '
              'tuples are records; comprehensions derive collections; and the '
              'collections module already wrote the bookkeeping you were about '
              'to write.'""",
     """              'Here\\'s the cheat sheet to carry with you. List indexing and append: O(1). Front insert: O(n). '
              'Dict and set lookup: O(1) average, keys must be hashable. Dicts preserve insertion order — guaranteed since 3.7. '
              'Tuples are for records, lists for sequences. Comprehensions derive collections cleanly. '
              'And the collections module already wrote all the boilerplate you were about to write — '
              'Counter, defaultdict, deque, namedtuple. Reach for them before you reach for raw loops.'"""),
]
apply(f"{BASE}/python/lesson_collections.dart", col_deep)
print("Collections DONE.")

# ============================================================
# lesson_functions.dart - CONCISE (c1-c5)
# ============================================================
func_concise = [
    # c1
    ("""              'Functions and scope, short version. A def statement builds a '
              'function object and binds it to a name — that is all it does. '
              'Functions are values, so you can pass them around, store them in '
              'dicts and return them from other functions.'""",
     """              'Functions and scope, the short version. A def statement does exactly one thing: '
              'it builds a function object and slaps a name on it. That\\'s it. No magic. '
              'And since functions are just values — like numbers or strings — you can pass them around, '
              'store them in dicts, or return them from other functions. '
              'It\\'s like having a recipe card you can hand to anyone, photocopy, or pin to a bulletin board.'"""),
    # c2
    ("""              'On arguments: defaults make parameters optional, star-args '
              'collects extra positional arguments into a tuple, and '
              'double-star-kwargs collects extra keyword arguments into a dict. '
              'A bare star in the parameter list forces everything after it to '
              'be passed by keyword, which is the cheapest readability win in '
              'the language.'""",
     """              'Quick tour of arguments. Defaults make parameters optional — classic and essential. '
              '*args collects extra positional arguments into a tuple. **kwargs collects extra keyword arguments into a dict. '
              'But the real gem is a bare * in the parameter list: it forces everything after it to be keyword-only. '
              'This is the cheapest readability win in all of Python. No more call sites that look like '
              '\"process(data, True, False, 42)\" where nobody knows what True and False mean.'"""),
    # c3
    ("""              'The one rule you must not forget: never use a mutable default. '
              'The default is evaluated once when the function is defined, so '
              'every call shares the same list. Default to None and create the '
              'list inside the body.'""",
     """              'One rule you absolutely must remember: never use a mutable default value. '
              'That default is evaluated once, when Python reads the def line — not each time you call. '
              'It\\'s like an office coffee pot that was brewed once and everyone drinks from the same batch. '
              'Default to None, then build your fresh list or dict inside the function body. '
              'This single rule prevents a whole class of sneaky, hard-to-debug errors.'"""),
    # c4
    ("""              'Scope follows LEGB: local, enclosing, global, builtins, first '
              'match wins. And assigning to a name anywhere in a function makes '
              'that name local for the whole function, which is why reading a '
              'global before assigning it raises UnboundLocalError.'""",
     """              'Scope follows the LEGB rule: Local, Enclosing, Global, Builtins — first match wins. '
              'Like searching for your keys: check your pockets first, then your desk, then the whole room, then the entire house. '
              'Critical gotcha: if you assign to a name ANYWHERE in a function, that name is local EVERYWHERE in that function — '
              'even on lines before the assignment. So reading a global on line 1 and assigning to it on line 2? '
              'UnboundLocalError. Python already decided it\\'s local, and you haven\\'t put anything in it yet.'"""),
    # c5
    ("""              'Use global and nonlocal only when you really mean to rebind an '
              'outer name. Everything else is closures — inner functions '
              'remembering the environment they were built in. That is the '
              'foundation for decorators.'""",
     """              'Use global and nonlocal sparingly — only when you genuinely need to rebind a name in an outer scope. '
              'Everything else is closures: inner functions that remember the environment they were born in, '
              'like a snapshot of the room at the moment of creation. '
              'Closures are the foundation for decorators, factories, and half the elegant patterns in Python. '
              'Master them and a whole category of problems becomes trivial.'"""),
]
apply(f"{BASE}/python/lesson_functions.dart", func_concise)
print("Functions concise DONE.")
