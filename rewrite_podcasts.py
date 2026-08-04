#!/usr/bin/env python3
"""Rewrite podcast segments in 9 lesson files to be conversational with analogies."""
import re
import os

BASE = "/Users/kartikjain/Desktop/code/learnflow/lib/sample_data"

# Maps filename -> list of (old_text, new_text) replacements for podcast segments
# We match on the exact text string between text: and startMs:
REPLACEMENTS = {}

# ============================================================
# sample_lesson.dart (Variables & Data Types)
# ============================================================
REPLACEMENTS["sample_lesson.dart"] = [
    # ---- CONCISE ----
    (
        "'Ninety seconds on Python variables. The one idea to take away: '\n"
        "              'a variable is a name, not a box.'",
        "'Ninety seconds on Python variables — and here's the big idea. '\n"
        "              'Imagine you have a sticky note with \"42\" on it. '\n"
        "              'You can move that sticky note from your monitor to your fridge — '\n"
        "              'the note stays the same, you're just changing where it lives. '\n"
        "              'That's exactly how Python variables work: they're labels, not boxes.'"
    ),
    (
        "'Right. Assignment binds a name to an object that already '\n"
        "              'exists on the heap. Nothing is copied, and the name itself has '\n"
        "              'no type — the object does.'",
        "'Exactly. When you say x equals 5, Python creates the number 5 somewhere in memory, '\n"
        "              'then sticks the label \"x\" on it. The label has no type — it's just a name. '\n"
        "              'The number 5 is what knows it's an integer. '\n"
        "              'And if you later point x at a string, no problem — you just moved the label.'"
    ),
    (
        "'The built-ins worth memorising are int, float, str, bool and '\n"
        "              'None, plus the containers: list, tuple, dict and set.'",
        "'Here are the types you'll actually use every day. Numbers: int for whole numbers, float for decimals. '\n"
        "              'Text: str. True or False: bool. \"There's nothing here\": None. '\n"
        "              'Then the containers — list, tuple, dict, and set. '\n"
        "              'Think of them like kitchen storage: list is a drawer you can rearrange, '\n"
        "              'dict is a labelled cabinet, set is a bowl that won't hold duplicates.'"
    ),
    (
        "'And sort them by mutability. Strings and tuples are immutable, '\n"
        "              'lists and dicts are not. That single distinction explains most '\n"
        "              'surprises beginners hit.'",
        "'And here's the key that unlocks almost all confusion: mutability. '\n"
        "              'Some things you can change after creating them — lists and dicts are like a whiteboard. '\n"
        "              'Others are set in stone — strings and tuples are more like a printed book. '\n"
        "              'Once you know which is which, most Python surprises just disappear.'"
    ),
    (
        "'Names bind, objects have types, mutability decides. Done.'",
        "'So remember: names are sticky notes, objects know their own types, '\n"
        "              'and mutability tells you what can change and what can't. '\n"
        "              'That's it — you've got the foundation everything else builds on.'"
    ),
    # ---- STANDARD ----
    (
        "'Welcome back. Today: variables and data types in Python. It '\n"
        "              'looks like the easiest topic in the language, and it is the one '\n"
        "              'that quietly causes the most bugs six months later.'",
        "'Welcome back! Today we're talking about something that seems almost too simple: '\n"
        "              'variables and data types. You know, it's like learning to walk — '\n"
        "              'everyone assumes they already know how, '\n"
        "              'but if your footing is slightly off, you'll stumble months later '\n"
        "              'and have no idea why. Trust me, this one's worth the attention.'"
    ),
    (
        "'Because people carry over a mental model from C or Java. There, '\n"
        "              'a variable is storage of a declared type and assignment copies '\n"
        "              'bytes into it. In Python the object lives on the heap and the '\n"
        "              'variable is a label you stick on it.'",
        "'Most of us come in carrying mental baggage from other languages. '\n"
        "              'In Java or C, a variable is like a parking space — it has a fixed size, '\n"
        "              'a specific type, and when you assign, you're copying a car into that spot. '\n"
        "              'Python is completely different. The value lives wherever it wants in memory, '\n"
        "              'and the variable? It's just a sticky note you slap on it. '\n"
        "              'No copying, no fixed size, no type on the label.'"
    ),
    (
        "'Which is why you can write count equals forty-two, then count '\n"
        "              'equals the string \"forty-two\", and Python does not complain. '\n"
        "              'You moved the label; you did not change a box.'",
        "'And this is where it gets fun. You can write count equals 42, '\n"
        "              'then literally the next line write count equals \"forty-two\" as a string, '\n"
        "              'and Python just nods. No complaints, no type errors. '\n"
        "              'Because you didn't change what's inside count — you just peeled the label off one object '\n"
        "              'and stuck it on another. Totally different from a language that would scream at you.'"
    ),
    (
        "'The flip side is aliasing. If b equals a, and a is a list, both '\n"
        "              'names point at one list. Append through b and a sees it. That '\n"
        "              'is not a bug in Python, it is the direct consequence of names '\n"
        "              'binding rather than copying.'",
        "'But here's the catch — and it's bitten every Python programmer at least once. '\n"
        "              'Say you have a shopping list taped to your fridge, '\n"
        "              'and you tell your roommate \"hey, the list is on the fridge.\" '\n"
        "              'If your roommate adds \"ice cream\" — you both see it, because there's only one list. '\n"
        "              'That's aliasing. b equals a doesn't make a copy; '\n"
        "              'it just gives the same object a second name.'"
    ),
    (
        "'Let us do the type tour. int is arbitrary precision, so no '\n"
        "              'overflow. float is a normal IEEE double, with all the usual '\n"
        "              'rounding surprises. str is immutable Unicode text. bool is '\n"
        "              'True and False, and it is technically a subclass of int. None '\n"
        "              'is the single value meaning \"nothing here\".'",
        "'Alright, quick tour of the type family. int is your whole number — '\n"
        "              'and unlike some languages, it'll never overflow no matter how big it gets. '\n"
        "              'float handles decimals, but fair warning: it uses binary under the hood, '\n"
        "              'so 0.1 plus 0.2 isn't exactly 0.3. str is text, always Unicode, never changes after creation. '\n"
        "              'bool is just True and False — fun fact, it's actually a subclass of int, '\n"
        "              'so True is really 1 wearing a fancy hat. And None? '\n"
        "              'That's the polite way of saying \"nothing here, move along.\"'"
    ),
    (
        "'Then the containers. list is ordered and mutable, tuple is '\n"
        "              'ordered and immutable, dict maps keys to values, and set holds '\n"
        "              'unique members. Keys and set members must be hashable, which in '\n"
        "              'practice means immutable — that is why a tuple can be a key and '\n"
        "              'a list cannot.'",
        "'Now the containers — think of them as different ways to organize a desk. '\n"
        "              'A list is like a stack of papers you can shuffle, add to, or remove from. '\n"
        "              'A tuple is like a museum display — once it's set, nothing moves. '\n"
        "              'A dict is your filing cabinet: every folder has a label, and you go straight to it. '\n"
        "              'A set is like a guest list at a club — no duplicates allowed, '\n"
        "              'and checking who's inside is lightning fast. '\n"
        "              'Oh, and dict keys and set items need to be hashable — which mostly just means immutable. '\n"
        "              'That's why a tuple can be a key but a list can't.'"
    ),
    (
        "'So the checklist: what object does this name point at, what '\n"
        "              'type is that object, and can anyone else mutate it. Answer '\n"
        "              'those three and Python stops being surprising.'",
        "'So here's your mental checklist for any Python variable you encounter: '\n"
        "              'One — what actual object is this name pointing at right now? '\n"
        "              'Two — what type is that object? '\n"
        "              'Three — can someone else change it out from under me? '\n"
        "              'Answer those three questions and Python goes from mysterious to predictable overnight.'"
    ),
    # ---- DEEP DIVE ----
    (
        "'This is the long version, so we are going below the surface: '\n"
        "              'reference semantics, the object model, and the places where '\n"
        "              'CPython implementation details leak into code you will write.'",
        "'Welcome to the deep dive! We're going under the hood today — '\n"
        "              'reference semantics, Python's object model, and those sneaky CPython details '\n"
        "              'that quietly affect code you'll actually write. '\n"
        "              'Think of this as the factory tour — you'll see how the machinery works, '\n"
        "              'so when it makes a funny noise, you'll know exactly why.'"
    ),
    (
        "'Start with the object header. Every Python object carries a '\n"
        "              'type pointer and a reference count. A name in a scope is an '\n"
        "              'entry in a namespace dictionary, or a slot in a function frame, '\n"
        "              'holding a pointer to that object. Assignment writes the '\n"
        "              'pointer and bumps the count.'",
        "'Let's start at the very bottom. Every single Python object — even the number 1 — '\n"
        "              'has a tiny ID card attached to it: a type pointer saying \"I'm an int\" '\n"
        "              'and a reference count tracking how many names are pointing at it. '\n"
        "              'When you assign a variable, you're not copying data — you're just '\n"
        "              'writing a pointer in a namespace and bumping that counter by one. '\n"
        "              'It's like a coat check system: the object is the coat, '\n"
        "              'the variable is the claim ticket.'"
    ),
    (
        "'That explains the identity operator. \"is\" compares pointers, '\n"
        "              'while \"==\" calls __eq__. Beginners hit this when small integers '\n"
        "              'and short strings appear to be identical objects — CPython '\n"
        "              'caches ints from minus five to two hundred fifty six and '\n"
        "              'interns some strings. Never rely on it; compare with == unless '\n"
        "              'you genuinely mean identity, as with None.'",
        "'This sets up one of the classic gotchas: \"is\" versus double equals. '\n"
        "              '\"is\" asks \"are these the exact same coat check ticket?\" — it compares memory addresses. '\n"
        "              'Double equals asks \"do these coats look the same?\" — it calls the __eq__ method. '\n"
        "              'Here's where it gets tricky: CPython recycles small integers from -5 to 256, '\n"
        "              'and sometimes interns short strings. So \"a is b\" might accidentally be True '\n"
        "              'when they're small numbers, and False when they're big ones. '\n"
        "              'The rule: only use \"is\" for None, and use double equals for everything else.'"
    ),
    (
        "'Mutability deserves the same depth. An immutable object can be '\n"
        "              'shared freely because nobody can change it underneath you. That '\n"
        "              'is what makes hashing safe: hash values must stay stable for '\n"
        "              'the lifetime of a dict key. Mutate a key in place and you '\n"
        "              'corrupt the table — which is exactly why list is unhashable.'",
        "'Let's dig deeper on mutability — it's the concept that explains half of Python's design choices. '\n"
        "              'Imagine you're at a potluck. An immutable dish is one that's already plated — '\n"
        "              'you can share it freely because nobody can take a bite out of your portion. '\n"
        "              'A mutable dish is a communal bowl — if someone adds hot sauce, everyone tastes it. '\n"
        "              'This is why dict keys must be hashable: the hash is like a table number, '\n"
        "              'and if your dish changes after being placed, nobody can find it anymore. '\n"
        "              'That's exactly why lists can't be dict keys — they're mutable.'"
    ),
    (
        "'The classic trap is the mutable default argument. Write def f, '\n"
        "              'items equals empty list, and that list is created once when the '\n"
        "              'function is defined, then reused on every call. The fix is a '\n"
        "              'default of None and building a fresh list inside the body.'",
        "'Now, the trap that catches literally everyone. Say you write a function with items equals an empty list as default. '\n"
        "              'Here's the thing: that empty list is created once, when Python reads your def statement, '\n"
        "              'not each time you call the function. It's like a shared office stapler — '\n"
        "              'everyone who comes to the desk uses the same one, and it accumulates everyone's staples. '\n"
        "              'The fix is beautifully simple: default to None, then inside the function, '\n"
        "              'create a fresh list if items is still None.'"
    ),
    (
        "'And numeric precision. float is binary, so 0.1 plus 0.2 is not '\n"
        "              'exactly 0.3. For money use decimal.Decimal constructed from '\n"
        "              'strings; for exact ratios use fractions.Fraction; for tolerance '\n"
        "              'comparisons use math.isclose. Reaching for round() as a fix '\n"
        "              'usually just moves the error somewhere less visible.'",
        "'And a quick word on floating point, because this one drives people crazy. '\n"
        "              'Floats use binary, and some decimal numbers — like 0.1 — are repeating fractions in binary, '\n"
        "              'just like one-third is 0.33333... in decimal. So 0.1 plus 0.2 equals 0.30000000000000004. '\n"
        "              'For money, reach for Decimal — but construct it from strings, not floats. '\n"
        "              'For exact fractions, there's Fraction. And for comparisons, use math.isclose. '\n"
        "              'Throwing round() at the problem just sweeps the dust under the rug.'"
    ),
    (
        "'Worth saying that type hints change none of this. Annotating x '\n"
        "              'as int is documentation plus a signal to a static checker; the '\n"
        "              'interpreter does not enforce it at runtime. Dynamic typing '\n"
        "              'stays dynamic.'",
        "'One last thing about type hints, since people often wonder if they change the game. '\n"
        "              'They don't. If you write x colon int, you're leaving a note for your IDE and for mypy — '\n"
        "              'it's like writing \"fragile\" on a box. The interpreter reads it, shrugs, and moves on. '\n"
        "              'At runtime, Python stays as dynamically typed as ever. '\n"
        "              'The hints are documentation that a machine can check, not enforcement.'"
    ),
    (
        "'To close: names bind to objects, objects own their type, and '\n"
        "              'mutability determines who can be surprised by a change. Every '\n"
        "              'later topic — functions, classes, closures, concurrency — is '\n"
        "              'built on those three facts.'",
        "'So let's wrap up with the three pillars. Names are sticky notes — they don't hold data, they point to it. '\n"
        "              'Objects own their type — the value knows what it is, not the label. '\n"
        "              'And mutability is the great divider — it determines whether change is a shared surprise or a local affair. '\n"
        "              'Everything coming up — functions, classes, closures, async — sits squarely on these three ideas. '\n"
        "              'Get comfortable with them now and everything else clicks faster.'"
    ),
]

# ============================================================
# lesson_control_flow.dart
# ============================================================
REPLACEMENTS["python/lesson_control_flow.dart"] = [
    # ---- CONCISE ----
    (
        "'Control flow in about three minutes. Python gives you a very '\n"
        "              'small set of tools here — if, elif, else, for, while, break, '\n"
        "              'continue and match — and almost all the skill is in picking the '\n"
        "              'right one rather than in remembering syntax.'",
        "'Control flow in about three minutes. Python gives you a tiny toolkit — '\n"
        "              'if, elif, else, for, while, break, continue, and match. '\n"
        "              'It's like having seven basic tools in your kitchen drawer. '\n"
        "              'You can cook almost anything with them, but the real skill '\n"
        "              'is knowing which one to grab, not memorizing what each looks like.'"
    ),
    (
        "'Start with truthiness, because it shows up in every condition. '\n"
        "              'False, None, zero, and any empty container or string are falsy. '\n"
        "              'Everything else is truthy. So \"if not items\" is the idiomatic '\n"
        "              'way to ask whether a list is empty — but be careful, because it '\n"
        "              'also fires when items is None or zero.'",
        "'First up: truthiness — it's the bouncer at the door of every if statement. '\n"
        "              'False, None, zero of any kind, empty strings, empty lists — all get turned away. '\n"
        "              'Everything else gets in. So \"if not items\" is the pythonic way to ask \"is this list empty?\" — '\n"
        "              'but careful, because it also says yes when items is None or zero, '\n"
        "              'and zero might be a perfectly valid value in your program.'"
    ),
    (
        "'Then loops. Python\\'s for loop is a foreach: it walks the '\n"
        "              'objects themselves, not indexes. If you find yourself writing '\n"
        "              'for i in range of len of something, you almost certainly want '\n"
        "              'enumerate for positions, or zip to walk two lists together.'",
        "'On to loops. Python's for loop is more like a tour guide than a counter — '\n"
        "              'it walks through the items themselves, not index numbers. '\n"
        "              'If you catch yourself writing \"for i in range of len of something,\" '\n"
        "              'stop right there. You probably want enumerate if you need positions, '\n"
        "              'or zip if you're walking two lists side by side. '\n"
        "              'It's the difference between counting seats and actually visiting each room.'"
    ),
    (
        "'And the one piece of syntax nobody guesses correctly: a loop '\n"
        "              'can have an else clause, and it runs when the loop finished '\n"
        "              'without hitting a break. Read it as \"no break\". It is the '\n"
        "              'search idiom — did I get all the way through without finding '\n"
        "              'what I was looking for.'",
        "'And here's the one nobody sees coming: loops in Python can have an else clause. '\n"
        "              'It doesn't mean \"if the loop was empty\" — it means \"if the loop finished without hitting break.\" '\n"
        "              'Mentally read it as \"nobreak.\" It's perfect for search patterns: '\n"
        "              'you loop through looking for something, break when you find it, '\n"
        "              'and the else block handles the \"not found\" case without any extra flags.'"
    ),
    (
        "'Finally, match, from Python 3.10. It matches the shape of data '\n"
        "              'and binds the pieces, so it shines on parsed JSON and message '\n"
        "              'dispatch. For plain equality, a dict of handlers is still '\n"
        "              'shorter. That is the whole toolkit.'",
        "'And finally, match — the new kid from Python 3.10. '\n"
        "              'Think of it as a Swiss Army knife for data shapes. '\n"
        "              'It's brilliant when you're dealing with parsed JSON or message patterns '\n"
        "              'where you want to pull apart the structure and react differently. '\n"
        "              'But for simple equality checks? A dictionary of handlers is still shorter. '\n"
        "              'That's your whole control flow toolkit, right there.'"
    ),
]

print(f"Defined {sum(len(v) for v in REPLACEMENTS.values())} replacements across {len(REPLACEMENTS)} files.")
print("Files:", list(REPLACEMENTS.keys()))
