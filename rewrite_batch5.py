#!/usr/bin/env python3
"""Batch 5: functions standard + deep, environments concise + standard"""
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
# lesson_functions.dart - STANDARD (s1-s8)
# ============================================================
func_std = [
    # s1
    ("""              'Functions today — and specifically the two halves people tend to '
              'learn separately: how arguments get in, and how names get '
              'resolved once you are inside. Get both right and a surprising '
              'amount of Python stops being mysterious, including decorators, '
              'callbacks and most import-time bugs.'""",
     """              'Functions today — and we\\'re tackling the two halves people usually learn years apart: '
              'how arguments get into a function, and how names get resolved once you\\'re inside the body. '
              'Get both of these right and a shocking amount of Python stops feeling like magic — '
              'decorators make sense, callbacks become obvious, and those weird import-time bugs just evaporate.'"""),
    # s2
    ("""              'The framing that helps most is that def is an assignment. It '
              'creates a function object at runtime and binds it to a name. '
              'Nothing about it is special: you can put function objects in a '
              'list, use them as dict values for dispatch, or hand them to '
              'sorted as a key. Every callable-based pattern in Python comes '
              'from that.'""",
     """              'Here\\'s the mental model that changes everything: def is just an assignment. '
              'At runtime, Python creates a function object — a real thing in memory — '
              'and binds a name to it. Nothing magical. You can put function objects in a list, '
              'use them as dict values for a dispatch table, or pass them to sorted() as the key. '
              'It\\'s like having a toolbox where the tools themselves are also objects you can sort, label, and hand around. '
              'Every callback, every decorator, every higher-order function pattern flows from this one insight.'"""),
    # s3
    ("""              'On the parameter side, Python is unusually expressive. You have '
              'positional parameters, defaults, star-args for surplus '
              'positionals, double-star-kwargs for surplus keywords, and two '
              'markers: a bare star meaning "keyword-only from here" and a '
              'slash meaning "positional-only up to here".'""",
     """              'On parameters, Python gives you an unusually rich vocabulary. Positional parameters, defaults, '
              '*args for catching extra positional arguments, **kwargs for catching extra keyword arguments. '
              'And two special markers: a bare * that says \"everything after this must be named\" '
              'and a / that says \"everything before this must be positional.\" '
              'Between these two markers you can design an API that\\'s impossible to call wrong.'"""),
    # s4
    ("""              'Keyword-only is the one to adopt today. Any call site that reads '
              'like a function name followed by True, False, False has lost the '
              'argument. Force those flags to be named and the call becomes '
              'self-documenting — and you can reorder or add options later '
              'without breaking anyone.'""",
     """              'Keyword-only arguments are the pattern to adopt today. If your call site looks like '
              '\"process(data, True, False, False)\" — you\\'ve already lost. Nobody knows what those booleans mean. '
              'Force them to be keyword-only with a bare *, and suddenly the call reads like English: '
              '\"process(data, validate=True, cache=False, async_mode=False).\" '
              'Self-documenting, and you can reorder or add options later without breaking any existing calls.'"""),
    # s5
    ("""              'Then defaults, and the classic trap. Default values are '
              'evaluated once, when the def executes, and stored on the '
              'function object. So a default of empty-list is a single list '
              'shared by every call that omits the argument. It accumulates. '
              'The fix is always the same: default to None, then build the real '
              'value inside the body.'""",
     """              'Now defaults, and the classic trap that catches every Python developer at least once. '
              'Default values are evaluated exactly once — when the def statement runs — '
              'and they\\'re stored right on the function object. So an empty list default is ONE list '
              'shared by every single call that doesn\\'t provide that argument. It accumulates across calls '
              'like a shared shopping cart that nobody ever empties. '
              'The fix never changes: default to None, then create the real value inside the function body.'"""),
    # s6
    ("""              'Now scope. Python searches local, then enclosing functions, then '
              'module globals, then builtins — LEGB — and stops at the first '
              'match. Note what does not create a scope: if statements, for '
              'loops and with blocks. A name bound inside a loop body is '
              'perfectly visible after the loop.'""",
     """              'Now scope — the LEGB rule. Python searches Local, then Enclosing functions, then Global module, '
              'then Builtins — and stops at the very first match. Simple and predictable. '
              'But here\\'s what trips people up: lots of things that LOOK like they should create a scope... don\\'t. '
              'If statements, for loops, with blocks — none of them create a new scope. '
              'A variable defined inside a loop is perfectly visible after the loop ends. '
              'Only functions (and comprehensions, and class bodies) create new scopes in Python.'"""),
    # s7
    ("""              'The compile-time part trips everyone up once. If a function '
              'assigns to a name anywhere in its body, that name is local for '
              'the entire body, decided before the function ever runs. So '
              'printing a global on line one and assigning to it on line two '
              'gives you UnboundLocalError on line one. Declaring global fixes '
              'it — or better, pass the value in and return the new one.'""",
     """              'The compile-time rule trips up everyone exactly once. If a function assigns to a name ANYWHERE '
              'in its body, Python decides BEFORE the function runs that this name is local for the ENTIRE body. '
              'So if you print a global on line 1 and assign to it on line 2 — UnboundLocalError on line 1. '
              'Python already decided it\\'s local, and nothing is in it yet. You can fix it with the global keyword — '
              'but honestly, the better fix is passing the value in as a parameter and returning the new one. '
              'Cleaner, testable, no surprises.'"""),
    # s8
    ("""              'Closures round it off. An inner function keeps access to the '
              'enclosing function\\'s variables even after the outer call has '
              'returned, and nonlocal lets it rebind them. That is how you get '
              'counters, memoisers and decorators without a class. Just '
              'remember closures capture variables, not values — a lambda made '
              'in a loop sees the loop variable\\'s final value.'""",
     """              'Closures bring it all together. An inner function keeps access to its enclosing function\\'s variables '
              'even after the outer function has returned — it\\'s like having a key to a room that no longer exists. '
              'nonlocal lets the inner function rebind those variables, enabling counters, memoizers, and decorators '
              'without writing a single class. One critical detail: closures capture VARIABLES, not VALUES. '
              'Make three lambdas in a loop and all three will see the loop variable\\'s final value — '
              'not the value it had when each lambda was created. This is the classic \"late binding\" trap.'"""),
]
apply(f"{BASE}/python/lesson_functions.dart", func_std)

# ============================================================
# lesson_functions.dart - DEEP DIVE (d1-d10)
# ============================================================
func_deep = [
    # d1
    ("""              'The long form on functions. We are going to cover the function '
              'object itself, the full argument protocol, how CPython resolves '
              'names at compile time, closures and cells, and then some '
              'signature design. By the end, decorators should look like an '
              'obvious consequence rather than magic.'""",
     """              'The deep dive on functions. We\\'re going to explore the function object itself — '
              'what it actually contains — the full argument passing protocol, how CPython resolves names '
              'at compile time (before your code even runs!), closures and cells, and some signature design wisdom. '
              'By the end, decorators should feel like an obvious consequence of everything we\\'ve discussed, '
              'not some arcane wizardry.'"""),
    # d2
    ("""              'Start with what def leaves behind. You get an object with a '
              'dunder code attribute holding the compiled bytecode, a dunder '
              'defaults tuple, a dunder globals reference to the defining '
              'module\\'s namespace, a dunder closure tuple, and a mutable dunder '
              'dict you can hang attributes on. Every one of those is '
              'inspectable at runtime, which is what makes tools like '
              'functools.wraps and inspect.signature possible.'""",
     """              'Let\\'s look at what a def statement actually leaves behind. You get a function object with: '
              '__code__ — the compiled bytecode. __defaults__ — a tuple of default values. '
              '__globals__ — a reference to the module\\'s namespace. __closure__ — captured variables from enclosing scopes. '
              'And __dict__ — a mutable dictionary where you can hang arbitrary attributes. '
              'Every one of these is inspectable at runtime! That\\'s how tools like functools.wraps and inspect.signature work: '
              'they just read these attributes. A function is a regular object you can poke and prod.'"""),
    # d3
    ("""              'The defaults tuple is the whole explanation for the mutable '
              'default bug. It is built once, at def time, and it lives on the '
              'function. Nothing re-evaluates it. So a list default is one '
              'object for the process lifetime — and you can actually watch it '
              'grow by printing the function\\'s dunder defaults between calls.'""",
     """              'The __defaults__ tuple explains the mutable default bug completely. '
              'It\\'s built once, at def time, and lives on the function object forever. Nothing re-evaluates it. '
              'So if your default is [], that\\'s ONE list for the entire lifetime of your program. '
              'You can literally watch it grow by printing the_function.__defaults__ between calls — '
              'each call that appends adds to the same list, and you can see the damage accumulate. '
              'It\\'s not a bug in Python; it\\'s a direct consequence of how function objects store their defaults.'"""),
    # d4
    ("""              'On to argument passing, which people describe wrongly all the '
              'time. Python is neither pass-by-value nor pass-by-reference in '
              'the C++ sense. It passes object references by value: the callee '
              'gets its own name bound to the caller\\'s object. Rebinding the '
              'parameter does nothing to the caller; mutating the object is '
              'visible everywhere. That single sentence resolves most arguments '
              'about it.'""",
     """              'Now argument passing — a topic people argue about endlessly because they use the wrong framework. '
              'Python is neither pass-by-value nor pass-by-reference in the C++ sense. '
              'It\\'s \"pass object reference by value\": the callee gets its own local name bound to the same object '
              'the caller passed. Rebinding that name inside the function? Caller never sees it. '
              'Mutating the object through that name? Caller sees it immediately — because it\\'s the same object. '
              'Think of it like sharing a Google Doc: you each have your own link, but edits are visible to everyone.'"""),
    # d5
    ("""              'Then there is the shape of the parameter list. Positional-only '
              'parameters, marked with a slash, exist because the standard '
              'library has functions whose parameter names were never meant to '
              'be part of the contract. If you write a library, a slash lets '
              'you rename parameters later without breaking callers, and a '
              'bare star lets you add options without disturbing positional '
              'order.'""",
     """              'Let\\'s talk parameter list design — the / and * markers that most people skip over. '
              'The slash makes parameters before it positional-only. Why would you want that? '
              'The standard library has functions whose parameter names were never meant to be public API — '
              'allowing keyword calls would lock those names in forever. With /, you can rename them later. '
              'The bare * makes parameters after it keyword-only — letting you add options without disturbing '
              'positional order. Together they let you design an API that\\'s both flexible and stable.'"""),
    # d6
    ("""              'Name resolution is where CPython does something genuinely '
              'clever. The compiler decides for each name whether it is local, '
              'a free variable from an enclosing scope, or global — before the '
              'function ever runs. Locals are then not dictionary lookups at '
              'all; they are numbered slots in the frame, loaded with the '
              'LOAD_FAST instruction. Globals stay dictionary lookups. That is '
              'why locals are measurably faster.'""",
     """              'Name resolution is where CPython shows its clever side. At compile time — BEFORE your function runs — '
              'the compiler scans the entire function body and tags every name: local, free variable (from an enclosing scope), '
              'or global. Locals get special treatment: they become numbered slots in the stack frame, '
              'accessed with the LOAD_FAST instruction — no dictionary lookup needed. '
              'Globals stay as dictionary lookups. This is why accessing a local variable is measurably faster '
              'than accessing a global. The compiler did the hard work before you even hit \"run.\"'"""),
    # d7
    ("""              'And that compile-time decision is exactly why UnboundLocalError '
              'exists as a distinct error from NameError. The compiler saw an '
              'assignment somewhere in the body, so it allocated a local slot '
              'for the whole function. Reading it before anything is stored '
              'there is a different failure from a name that does not exist at '
              'all.'""",
     """              'This compile-time classification explains why UnboundLocalError is a distinct error from NameError. '
              'The compiler saw an assignment somewhere in the function body, so it said \"this name is local\" '
              'and allocated a numbered slot for it. When you try to read that slot before anything is stored in it, '
              'you get UnboundLocalError — \"I have a slot for this, but it\\'s empty.\" '
              'NameError is different: it means \"I have no idea what this name refers to at all.\" '
              'Two different errors, two different problems — and the compiler decided which one you\\'d get before execution.'"""),
    # d8
    ("""              'Closures use a third storage class. A variable that an inner '
              'function needs is promoted to a cell — a small box holding one '
              'reference. Both functions point at that cell, so the outer '
              'frame can be destroyed and the value survives. You can see it: '
              'the inner function\\'s dunder closure is a tuple of cells, each '
              'with a cell_contents attribute.'""",
     """              'Closures introduce a third kind of variable storage: the cell. '
              'When an inner function needs a variable from an enclosing scope, Python promotes that variable '
              'into a cell — a tiny box that holds exactly one reference. Both the outer and inner functions '
              'point to this same cell. The outer frame can be garbage collected, but the cell survives, '
              'keeping the value alive. You can inspect this: the inner function\\'s __closure__ attribute '
              'is a tuple of cells, each with a .cell_contents you can read. '
              'It\\'s like a safety deposit box that outlives the bank that issued it.'"""),
    # d9
    ("""              'The shared cell is why late binding bites. Build three lambdas '
              'in a loop over range three and call them afterwards and all '
              'three return two, because they share one cell that the loop left '
              'at two. The usual fix is a default argument capturing the '
              'current value, which works precisely because defaults are '
              'evaluated eagerly at definition time.'""",
     """              'The shared cell explains the late binding trap perfectly. Build three lambdas in a loop '
              'and call them afterward — all three return the loop variable\\'s final value. Why? '
              'All three lambdas share the SAME cell. The loop updates that cell, and by the time you call them, '
              'the cell holds the final value. The fix: capture the current value in a default argument — '
              'lambda x=i: x. This works because defaults are evaluated eagerly at definition time, '
              'snapshotting the value before the loop moves on. It\\'s a clever trick that exploits '
              'the very behavior we just learned about mutable defaults, but in a good way this time.'"""),
]
apply(f"{BASE}/python/lesson_functions.dart", func_deep)

# Also need d10 - let me read what it says first
# d10 from earlier read starts at line 910
print("Functions DONE (wait, need d10 still...)")
