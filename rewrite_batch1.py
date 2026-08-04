#!/usr/bin/env python3
"""Rewrite all podcast segments in lesson files to be conversational with analogies."""
import re

BASE = "/Users/kartikjain/Desktop/code/learnflow/lib/sample_data"

def apply_replacements(filepath, replacements):
    """Read file, apply list of (old_text, new_text) replacements, write back."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    applied = 0
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new, 1)
            applied += 1
        else:
            print(f"  WARN: Could not find replacement for: {old[:60]}...")
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    return applied

# ================================================================
# lesson_control_flow.dart
# ================================================================
control_flow = [
    # ---- CONCISE ----
    # c1
    ("""              'Control flow in about three minutes. Python gives you a very '
              'small set of tools here — if, elif, else, for, while, break, '
              'continue and match — and almost all the skill is in picking the '
              'right one rather than in remembering syntax.'""",
     """              'Control flow in about three minutes. Python gives you a tiny toolkit — '
              'if, elif, else, for, while, break, continue, and match. '
              'It\\'s like having seven basic tools in your kitchen drawer. '
              'You can cook almost anything with them, but the real skill '
              'is knowing which one to grab, not memorizing what each looks like.'"""),
    # c2
    ("""              'Start with truthiness, because it shows up in every condition. '
              'False, None, zero, and any empty container or string are falsy. '
              'Everything else is truthy. So "if not items" is the idiomatic '
              'way to ask whether a list is empty — but be careful, because it '
              'also fires when items is None or zero.'""",
     """              'First up: truthiness — it\\'s the bouncer at the door of every if statement. '
              'False, None, zero of any kind, empty strings, empty lists — all get turned away. '
              'Everything else gets in. So "if not items" is the pythonic way to ask "is this list empty?" — '
              'but careful, because it also says yes when items is None or zero, '
              'and zero might be a perfectly valid value in your program.'"""),
    # c3
    ("""              'Then loops. Python\\'s for loop is a foreach: it walks the '
              'objects themselves, not indexes. If you find yourself writing '
              'for i in range of len of something, you almost certainly want '
              'enumerate for positions, or zip to walk two lists together.'""",
     """              'On to loops. Python\\'s for loop is more like a tour guide than a counter — '
              'it walks through the items themselves, not index numbers. '
              'If you catch yourself writing "for i in range of len of something," '
              'stop right there. You probably want enumerate if you need positions, '
              'or zip if you\\'re walking two lists side by side. '
              'It\\'s the difference between counting seats and actually visiting each room.'"""),
    # c4
    ("""              'And the one piece of syntax nobody guesses correctly: a loop '
              'can have an else clause, and it runs when the loop finished '
              'without hitting a break. Read it as "no break". It is the '
              'search idiom — did I get all the way through without finding '
              'what I was looking for.'""",
     """              'And here\\'s the one nobody sees coming: loops in Python can have an else clause. '
              'It doesn\\'t mean "if the loop was empty" — it means "if the loop finished without hitting break." '
              'Mentally read it as "nobreak." It\\'s perfect for search patterns: '
              'you loop through looking for something, break when you find it, '
              'and the else block handles the "not found" case without any extra flags.'"""),
    # c5
    ("""              'Finally, match, from Python 3.10. It matches the shape of data '
              'and binds the pieces, so it shines on parsed JSON and message '
              'dispatch. For plain equality, a dict of handlers is still '
              'shorter. That is the whole toolkit.'""",
     """              'And finally, match — the new kid from Python 3.10. '
              'Think of it as a Swiss Army knife for data shapes. '
              'It\\'s brilliant when you\\'re dealing with parsed JSON or message patterns '
              'where you want to pull apart the structure and react differently. '
              'But for simple equality checks? A dictionary of handlers is still shorter. '
              'That\\'s your whole control flow toolkit, right there.'"""),
]

filepath = f"{BASE}/python/lesson_control_flow.dart"
n = apply_replacements(filepath, control_flow)
print(f"lesson_control_flow.dart: {n}/{len(control_flow)} replacements applied")
