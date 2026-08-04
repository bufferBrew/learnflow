#!/usr/bin/env python3
"""Batch 2: control_flow standard + deepDive, plus collections concise"""
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
    return applied

# lesson_control_flow.dart - STANDARD
cf_std = [
    # s1
    ("'Today we are on control flow: the statements that decide what '\n"
     "              'runs next. The syntax fits on a postcard, so we are going to '\n"
     "              'spend the time on judgement instead — which construct says what '\n"
     "              'you actually mean, and where Python quietly differs from the '\n"
     "              'languages people arrive from.'",
     "'Today we are talking about control flow — the statements that decide what runs next. '\n"
     "              'The actual syntax fits on a postcard, honestly. So instead of memorizing, '\n"
     "              'let\\'s spend our time on judgment: which tool says what you really mean, '\n"
     "              'and where Python quietly behaves differently from the languages '\n"
     "              'most of us grew up with.'"),
    # s2
    ("'The first difference is that blocks are defined by indentation. '\n"
     "              'There are no braces, so what you see on screen is exactly what '\n"
     "              'the interpreter sees. A line indented one level too far is a '\n"
     "              'different program, not a formatting quibble — and that is the '\n"
     "              'single most common source of confusion in someone\\'s first '\n"
     "              'week.'",
     "'The first thing that throws people: blocks are defined by indentation, not braces. '\n"
     "              'What you see on screen is exactly what Python sees — there\\'s no hidden punctuation. '\n"
     "              'It\\'s like writing an outline for a paper: the indentation IS the structure. '\n"
     "              'One space too many and you\\'ve written a different program. '\n"
     "              'This trips up almost everyone in their first week, so you\\'re in good company.'"),
    # s3  
    ("'With if and elif, the important property is that the chain '\n"
     "              'stops at the first true condition. Later branches are never '\n"
     "              'evaluated. That means order matters: put the specific cases '\n"
     "              'first, because a broad condition placed early swallows every '\n"
     "              'narrower one underneath it.'",
     "'With if and elif, here\\'s the key insight: the chain stops at the first match. '\n"
     "              'It\\'s like a series of bouncers at a club — the first one who lets you in wins, '\n"
     "              'and nobody else even looks at you. So order matters tremendously. '\n"
     "              'Put your narrow, specific conditions first. A broad condition early on '\n"
     "              'will swallow every narrower case below it — like putting \"age > 0\" '\n"
     "              'before \"age > 65\" and wondering why the senior discount never fires.'"),
    # s4
    ("'Conditions do not have to be booleans, either. Python asks any '\n"
     "              'object whether it is truthy. Empty containers, empty strings, '\n"
     "              'zero of any numeric type, None and False are falsy; everything '\n"
     "              'else is truthy — including the string \"False\" and the list '\n"
     "              'containing a single zero. And the and/or operators return one '\n"
     "              'of their operands rather than a bool, which is why \"name or '\n"
     "              'anonymous\" works as a default value.'",
     "'Here\\'s something surprising: conditions don\\'t need to be booleans. '\n"
     "              'Python asks every object \"are you truthy?\" — like a bouncer checking IDs. '\n"
     "              'Empty things, zero, None, and False get turned away. Everything else gets in — '\n"
     "              'even the string \"False\" (it\\'s not empty!) or a list containing [0] (it\\'s not empty either!). '\n"
     "              'And the and/or operators are shortcut operators — they return one of their operands, not True/False, '\n"
     "              'which is exactly why \"name or anonymous\" works as a default value.'"),
    # s5
    ("'The trap there is treating falsy as a synonym for missing. If '\n"
     "              'you write \"if not count\", you catch None and you also catch a '\n"
     "              'perfectly legitimate zero. When zero is real data, compare '\n"
     "              'against None explicitly. This bug is very quiet and very common '\n"
     "              'in configuration handling.'",
     "'Now the trap: treating falsy as \"missing.\" If you write \"if not count\" you\\'ll catch None — '\n"
     "              'great! — but you\\'ll also catch zero, which might be a perfectly legitimate value. '\n"
     "              'Imagine you\\'re checking a bank balance: zero dollars is very different from \"no data available.\" '\n"
     "              'When zero is real data in your domain, compare against None explicitly. '\n"
     "              'This bug is silent, deadly, and everywhere in configuration code.'"),
    # s6
    ("'Loops next. Python\\'s for asks an object for an iterator and '\n"
     "              'pulls values from it, so it iterates over items rather than '\n"
     "              'positions. enumerate gives you positions when you need them, '\n"
     "              'and takes a start argument so you can number from one. zip '\n"
     "              'walks several sequences in lockstep and stops at the shortest — '\n"
     "              'or raises, if you pass strict equals True on 3.10 and later.'",
     "'On to loops. Python\\'s for loop is like a waiter delivering dishes from the kitchen — '\n"
     "              'it brings you the items themselves, not table numbers. '\n"
     "              'enumerate gives you table numbers when you need them, and it accepts a start argument '\n"
     "              'so you can number from 1 like normal humans do. '\n"
     "              'zip walks several sequences in lockstep like two people walking side by side, '\n"
     "              'stopping when the shorter one runs out — or it can raise an error on 3.10+ '\n"
     "              'if you pass strict=True and they\\'re different lengths.'"),
    # s7
    ("'while is for looping until a condition changes rather than over '\n"
     "              'a known collection. break leaves the innermost loop, continue '\n"
     "              'skips to the next iteration, and both loop types can carry an '\n"
     "              'else clause that runs only when no break happened. Say \"no '\n"
     "              'break\" out loud each time you read it and it stops being '\n"
     "              'confusing.'",
     "'while is for looping until something changes — like stirring a pot until it boils, '\n"
     "              'rather than counting how many stirs you\\'ve done. '\n"
     "              'break bails out of the innermost loop entirely. continue skips to the next lap. '\n"
     "              'And both loop types can carry an else clause — which fires only when no break happened, '\n"
     "              'like a \"plan B\" for when you searched everything and found nothing. '\n"
     "              'Just say \"nobreak\" out loud whenever you see it and it stops being weird.'"),
    # s8
    ("'And keep one rule in your head: do not add or remove items from '\n"
     "              'the thing you are iterating over. Removing from a list while '\n"
     "              'looping makes the loop skip elements, and changing a dict\\'s '\n"
     "              'keys raises RuntimeError. Build a new collection, or iterate '\n"
     "              'over a snapshot such as list of the dict.'",
     "'One golden rule: never add or remove items from the thing you\\'re currently looping over. '\n"
     "              'It\\'s like trying to repaint a road while you\\'re driving on it — things shift under you. '\n"
     "              'Removing from a list mid-loop makes it skip elements (everyone shifts down but your index still advances). '\n"
     "              'Changing a dict\\'s keys mid-iteration raises a RuntimeError — Python catches you red-handed. '\n"
     "              'The fix: build a new collection, or loop over a snapshot like list(my_dict).'"),
]

n = apply(f"{BASE}/python/lesson_control_flow.dart", cf_std)
print(f"control_flow standard: {n}/{len(cf_std)} applied")

# lesson_control_flow.dart - DEEP DIVE (10 segments d1-d10 + remaining)
cf_deep = [
    # d1
    ("'The long version of control flow. We will go through branching, '\n"
     "              'truthiness, the iterator protocol behind the for loop, the else '\n"
     "              'clause, structural pattern matching, and finish on how to keep '\n"
     "              'deeply branched code readable. Some of this is mechanism you '\n"
     "              'will only need once, but it is exactly the mechanism that '\n"
     "              'explains the surprises.'",
     "'Welcome to the deep dive on control flow. We\\'re going to peel back every layer: '\n"
     "              'branching, the truthiness machinery, the iterator protocol that powers for loops, '\n"
     "              'the mysterious else clause, structural pattern matching, and how to keep deeply nested code sane. '\n"
     "              'Some of this you might only need once — but it\\'s exactly the stuff that explains '\n"
     "              'those \"why did my code do THAT?\" moments we\\'ve all had.'"),
    # d2
    ("'Start underneath the if statement. The interpreter does not '\n"
     "              'require a bool; it calls the object\\'s dunder bool method to ask '\n"
     "              'for a truth value. If the type does not define one, Python falls '\n"
     "              'back to dunder len and treats length zero as false. If neither '\n"
     "              'exists, the object is unconditionally true. That is the entire '\n"
     "              'rule, and it explains why empty containers are falsy without '\n"
     "              'anyone special-casing them.'",
     "'Let\\'s go under the if statement. Python doesn\\'t actually require a bool — it asks the object politely. '\n"
     "              'First it calls __bool__. If that doesn\\'t exist, it tries __len__ — zero means false. '\n"
     "              'If neither exists, the object is unconditionally true. That\\'s the whole rule! '\n"
     "              'It\\'s like asking a restaurant \"are you open?\" — first check the sign, '\n"
     "              'if there\\'s no sign, count the customers. No customers and no sign? Assume open. '\n"
     "              'This elegant fallback chain is why empty containers are falsy without anyone special-casing them.'"),
    # d3
    ("'It also explains a class of bug in numeric libraries. A NumPy '\n"
     "              'array with more than one element raises when you ask it for a '\n"
     "              'truth value, because element-wise comparison makes \"is this '\n"
     "              'array true\" genuinely ambiguous. The interpreter is not being '\n"
     "              'awkward; the type is declining to guess.'",
     "'This also explains a bug that bites data scientists. A NumPy array with multiple elements '\n"
     "              'refuses to give a truth value — it raises an error instead. Why? '\n"
     "              'Because \"is this array true?\" is genuinely ambiguous — does it mean \"are ALL elements true\" '\n"
     "              'or \"is ANY element true\"? NumPy says \"I\\'m not guessing — you tell me with .any() or .all().\" '\n"
     "              'The interpreter isn\\'t being difficult; the type is wisely refusing to pick for you.'"),
    # d4
    ("'Short-circuiting is worth being precise about too. \"a and b\" '\n"
     "              'evaluates a, and if a is falsy it returns a itself without '\n"
     "              'touching b. \"a or b\" returns a if a is truthy. So these '\n"
     "              'operators return operands, not booleans — which is both the '\n"
     "              'trick behind default values and the reason \"x or 0\" quietly '\n"
     "              'replaces a legitimate empty string.'",
     "'Short-circuiting deserves precision because it\\'s both brilliant and treacherous. '\n"
     "              '\"a and b\" checks a first — if a is falsy, it returns a immediately without even glancing at b. '\n"
     "              'It\\'s like checking if you have your keys before checking if the car has gas — no point looking further. '\n"
     "              '\"a or b\" returns a if truthy, b otherwise. These return the actual operand, not True/False. '\n"
     "              'That\\'s the magic behind \"name or \\'anonymous\\'\" — and the curse behind \"x or 0\" silently replacing '\n"
     "              'a legitimate empty string or zero with a default you didn\\'t mean.'"),
    # d5
    ("'Now the for loop. It is pure syntax over the iterator protocol: '\n"
     "              'Python calls iter on the object to get an iterator, then calls '\n"
     "              'next repeatedly until StopIteration is raised, and that '\n"
     "              'exception is what ends the loop. Nothing about the loop knows '\n"
     "              'about lists or indexes, which is why the same statement works '\n"
     "              'over files, dicts, generators and anything else you make '\n"
     "              'iterable.'",
     "'Now the for loop — and this is beautiful once you see it. It\\'s just syntax sugar over three steps: '\n"
     "              'call iter() on the object, call next() repeatedly, and stop when StopIteration is raised. '\n"
     "              'That\\'s it. The loop itself knows nothing about lists or indexes — it\\'s like a universal remote '\n"
     "              'that works with any device that speaks the same protocol. '\n"
     "              'That\\'s why the same for statement works on lists, files, dicts, generators, '\n"
     "              'and anything you make iterable. No special cases, just a clean contract.'"),
    # d6
    ("'That protocol also explains the mutation bug. A list iterator '\n"
     "              'keeps an integer index. Remove an item and everything after it '\n"
     "              'shifts down, but the index still advances, so exactly one '\n"
     "              'element gets skipped for each removal. Dicts take a different '\n"
     "              'approach: they track a version counter and raise RuntimeError '\n"
     "              'if the size changes mid-iteration, which is a much kinder '\n"
     "              'failure.'",
     "'This protocol also explains why mutating while iterating goes wrong — but differently for different types. '\n"
     "              'A list iterator keeps an integer index. Remove item 3, everything after shifts down, '\n"
     "              'but the index still ticks to 4 — skipping exactly one element. It\\'s like removing a rung '\n"
     "              'from a ladder while climbing: you miss the next step entirely. '\n"
     "              'Dicts are smarter: they track a version counter and raise RuntimeError the moment the size changes. '\n"
     "              'Much kinder — at least it screams instead of silently skipping your data.'"),
    # d7
    ("'The loop else clause makes most sense once you know it exists '\n"
     "              'for search. You loop looking for something; you break when you '\n"
     "              'find it; the else runs when you did not. The alternative is a '\n"
     "              'found flag you set in two places and test in a third. The '\n"
     "              'clause is genuinely poorly named — Donald Knuth would have '\n"
     "              'called it \"nobreak\" — but it removes real bookkeeping.'",
     "'The else clause on loops finally makes sense when you see it as a search pattern. '\n"
     "              'You\\'re looking through items. You break when you find what you want. '\n"
     "              'The else runs when you searched everything and came up empty. '\n"
     "              'Without it, you\\'d need a \"found\" flag — set in one place when you find it, '\n"
     "              'test in another place after the loop. It\\'s poorly named, I\\'ll grant you — '\n"
     "              'Knuth would have called it \"nobreak\" — but it eliminates real bookkeeping.'"),
    # d8
    ("'On to match, added in 3.10. The critical thing to internalise '\n"
     "              'is that a bare name inside a pattern is a binding, not a '\n"
     "              'comparison. \"case x\" matches anything and names it x. If you '\n"
     "              'want to compare against a constant you need a dotted name, like '\n"
     "              'Colour.RED, or a literal. People write \"case CONSTANT\" expecting '\n"
     "              'equality and get a catch-all that shadows every case below it.'",
     "'Now match, the feature that arrived in Python 3.10. Here\\'s the thing everyone gets wrong: '\n"
     "              'a bare name in a case pattern is a BINDING, not a comparison. \"case x\" matches literally anything '\n"
     "              'and names it x — it\\'s like saying \"I\\'ll take whatever you give me and call it Bob.\" '\n"
     "              'If you want to compare against a constant, you need a dotted name like Colour.RED, or a literal value. '\n"
     "              'I\\'ve seen people write \"case MY_CONSTANT\" expecting a comparison and instead creating '\n"
     "              'a catch-all that silently shadows every case below it. Painful.'"),
]

n = apply(f"{BASE}/python/lesson_control_flow.dart", cf_deep)
print(f"control_flow deepDive: {n}/{len(cf_deep)} applied")
