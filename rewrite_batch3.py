#!/usr/bin/env python3
"""Batch 3: Finish control_flow, do collections, start functions"""
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
    filename = filepath.split('/')[-1]
    print(f"  {filename}: {applied}/{len(replacements)} applied")
    return applied

# ============================================================
# control_flow - remaining d9, d10, d11
# ============================================================
cf_rest = [
    # d9
    ("""              'Beyond that, patterns compose. You can match a mapping with '
              'particular keys, a sequence of a given length, a class with '
              'specific attributes, or alternatives separated by a vertical '
              'bar. You can add a guard — an if after the pattern — for '
              'conditions that are about values rather than shape. And '
              'underscore is the wildcard that matches without binding.'""",
     """              'Beyond the basics, patterns compose beautifully. You can match a dict with specific keys, '
              'a sequence of a certain length, a class with particular attribute values, '
              'or alternatives separated by a vertical bar — like saying "match this OR that." '
              'You can add a guard — an if after the pattern — for conditions about values, not shapes. '
              'And underscore is your wildcard: it matches anything without capturing it, '
              'like a trash can that says "I don\\'t care what this is, just move on."'"""),
    # d10
    ("""              'When should you use it? When you are dispatching on the shape '
              'of data — parsed JSON, an abstract syntax tree, a protocol '
              'message. When you are dispatching on a single value, a '
              'dictionary mapping values to functions is usually shorter and '
              'faster to read. And when the decision is not about structure at '
              'all, if/elif is still the honest answer.'""",
     """              'So when should you actually reach for match? When your decision depends on the SHAPE of data — '
              'parsed JSON from an API, an abstract syntax tree, a protocol message with different variants. '
              'For dispatching on a single value? A dictionary mapping values to functions is usually shorter and clearer. '
              'And when the decision isn\\'t about structure at all — just a chain of conditions? '
              'Good old if/elif is still the honest, readable answer. Match is a precision tool, not a hammer.'"""),
    # d11
    ("""              'Close on readability. Deep nesting is the real enemy: prefer '
              'guard clauses that return early on the invalid cases so the '
              'happy path stays at one indentation level. Keep conditions '
              'short enough to name. And remember the summary: conditions ask '
              'objects for truthiness, for loops consume iterators, else means '
              'no break, and match matches structure.'""",
     """              'Let\\'s close on readability, because ultimately that\\'s what control flow is about. '
              'Deep nesting is the real enemy — it\\'s like a Russian doll where you need to open seven layers '
              'to find the actual logic. Prefer guard clauses: check the invalid cases first and return early, '
              'so the happy path stays at one indentation level. Keep conditions short enough to name. '
              'And here\\'s your mental cheat sheet: conditions ask objects for truthiness, '
              'for loops consume iterators, else means \"no break happened,\" and match matches structure. '
              'That\\'s the whole game.'"""),
]
apply(f"{BASE}/python/lesson_control_flow.dart", cf_rest)

# ============================================================
# lesson_collections.dart - ALL VARIANTS
# ============================================================
collections = [
    # ---- CONCISE ----
    # c1
    ("""              'Containers, condensed. Four built-ins do almost everything: '
              'list for an ordered mutable sequence, tuple for a fixed record, '
              'dict for key-to-value lookup, and set for membership and '
              'uniqueness. Picking the right one is most of the performance '
              'work you will ever do in Python.'""",
     """              'Containers, condensed. Four built-ins handle almost everything: '
              'list for an ordered sequence you can shuffle, tuple for a fixed record that won\\'t budge, '
              'dict for instant key-to-value lookup, and set for \"is this in there?\" and keeping things unique. '
              'Honestly, picking the right container is 80% of the performance work '
              'you\\'ll ever do in Python — it\\'s like choosing the right kitchen tool.'"""),
    # c2
    ("""              'The rule of thumb is about the question you are asking. If you '
              'ask "is this in there" repeatedly, you want a set or a dict, '
              'because that is a hash lookup instead of a scan. If you ask '
              '"what is at position three", you want a list. If the positions '
              'have distinct meanings, you want a tuple.'""",
     """              'Here\\'s the rule of thumb: pick your container based on what question you keep asking. '
              'If you\\'re constantly asking \"is this in the collection?\" — you want a set or dict, '
              'because hash lookups are instant, like flipping straight to a page in an index. '
              'If you\\'re asking \"what\\'s at position three?\" — a list is your friend. '
              'If the positions mean different things — like latitude and longitude — reach for a tuple.'"""),
    # c3
    ("""              'Dictionaries have kept insertion order since 3.7, and that is a '
              'language guarantee now, not an accident. Use get when a missing '
              'key is normal, plain square brackets when a missing key is a '
              'bug, and remember that keys must be hashable — which in practice '
              'means immutable.'""",
     """              'Quick dict tip: they\\'ve kept insertion order since Python 3.7, and it\\'s a guarantee now, not luck. '
              'Use .get() when a missing key is totally normal — like checking if someone\\'s in the phone book. '
              'Use square brackets when a missing key means something is genuinely broken. '
              'And remember: keys must be hashable, which in practice just means immutable. '
              'That\\'s why \"hello\" and (1, 2) can be keys, but [1, 2] cannot.'"""),
    # c4
    ("""              'Comprehensions are the idiomatic way to derive one collection '
              'from another. List, set and dict forms all exist, and dropping '
              'the brackets inside a function call gives you a lazy generator '
              'expression instead. Keep them to one for and one if — past that, '
              'write the loop.'""",
     """              'Comprehensions are Python\\'s way of saying \"build me a new collection from this one\" in one clean line. '
              'List, set, and dict forms all exist, following the same pattern. '
              'Drop the brackets inside a function call like sum() and you get a lazy generator expression '
              'that never creates the whole list in memory. Just keep them simple: one for, one if max. '
              'Past that, write a regular loop — future you will thank present you.'"""),
    # c5
    ("""              'And learn the collections module: Counter for tallies, '
              'defaultdict for grouping, deque for queues and bounded history, '
              'namedtuple for readable records. Each replaces about five lines '
              'of bookkeeping you would otherwise write by hand.'""",
     """              'And don\\'t sleep on the collections module — it\\'s full of specialized tools. '
              'Counter for tallying things up, like counting votes or word frequencies. '
              'defaultdict for grouping — no more \"if key not in dict, create empty list\" boilerplate. '
              'deque for fast queues and sliding windows. namedtuple for records with named fields. '
              'Each one replaces about five lines of manual bookkeeping you\\'d otherwise write by hand.'"""),
]

apply(f"{BASE}/python/lesson_collections.dart", collections)
print("Batch 3 done")
