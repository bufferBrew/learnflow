#!/usr/bin/env python3
"""Batch 6: OOP all variants + environments concise"""
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
            print(f"  MISS: {repr(old[:60])}")
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"  {filepath.split('/')[-1]}: {applied}/{len(replacements)}")
    return applied

# ============================================================
# lesson_oop.dart - CONCISE (c1-c5)
# ============================================================
oop_c = [
    # c1
    ("""              'Object-oriented Python in about four minutes. A class bundles '
              'state with the behaviour that operates on it. Calling the class '
              'makes an instance, dunder-init attaches that instance\\'s data, '
              'and self is just the first parameter of every instance method — '
              'not a keyword.'""",
     """              'Object-oriented Python in about four minutes. Think of a class as a blueprint for a house. '
              'The blueprint says what rooms every house has, but each actual house — each instance — '
              'has its own furniture, its own paint color. Calling the class builds a new house; '
              '__init__ is the interior decorator that sets it up. '
              'And self? It\\'s just how each room knows which house it belongs to — not a keyword, just a name.'"""),
    # c2
    ("""              'Watch where you put state. A name assigned in the class body is '
              'shared by every instance; a name assigned through self belongs '
              'to one object. Put a list in the class body and every instance '
              'mutates the same list — the same bug as a mutable default '
              'argument.'""",
     """              'Watch where you put your stuff. Something defined in the class body is like a community fridge — '
              'every instance shares it. Something assigned through self in __init__ is like a personal fridge — '
              'each instance gets its own. Put a list in the class body and suddenly every instance '
              'is adding to the same shopping cart. Same trap as mutable default arguments, just in a different costume.'"""),
    # c3
    ("""              'Python does not need getters and setters, because the property '
              'decorator lets you turn a plain attribute into a computed one '
              'later without touching a single call site. Start plain, add a '
              'property only when validation or derivation actually arrives.'""",
     """              'Python doesn\\'t need getters and setters — and that surprises people coming from Java. '
              'The @property decorator is like a trap door: you start with a plain attribute, then later '
              'you can slide validation or computation underneath without changing a single line of caller code. '
              'It\\'s like upgrading from a regular door to one that checks IDs — nobody on the outside notices the difference. '
              'Start simple, add @property only when you actually need it.'"""),
    # c4
    ("""              'Dunder methods are how your class joins the language. Write '
              'dunder-repr every time — it is what tracebacks and debuggers '
              'show. Add dunder-eq and dunder-hash together if value equality '
              'matters, and the comparison and arithmetic dunders only when '
              'they genuinely make sense.'""",
     """              'Dunder methods — the ones with double underscores — are how your class becomes a first-class citizen. '
              'Always write __repr__: it\\'s what shows up in tracebacks, debuggers, and the REPL. '
              'Add __eq__ and __hash__ together if you want value comparison — like two wallets being equal if they hold the same cash. '
              'The arithmetic dunders like __add__ and __lt__? Only when they genuinely make sense. '
              'Nobody wants to \"add\" two Customer objects.'"""),
    # c5
    ("""              'Finally: inherit for "is a", compose for "has a", and if the '
              'class is really just fields, reach for a dataclass and let it '
              'write dunder-init, dunder-repr and dunder-eq for you.'""",
     """              'Finally, the design rules. Inherit when something truly IS a more specific version — '
              'a SavingsAccount IS an Account. Compose when it HAS something — a Car HAS an Engine, it isn\\'t one. '
              'And if your class is mostly just data fields — a Point with x and y, a User with name and email — '
              'reach for @dataclass and let Python write __init__, __repr__, and __eq__ for you. '
              'Save the boilerplate for the boiler room.'"""),
]
apply(f"{BASE}/python/lesson_oop.dart", oop_c)

# ============================================================
# lesson_oop.dart - STANDARD (s1-s8)
# ============================================================
oop_s = [
    # s1
    ("""              'Classes today. And I want to start with the question people '
              'skip, which is whether you need one at all. Python is not Java: a '
              'module full of functions is a perfectly respectable design, and '
              'a class with a single method and no state is a function that has '
              'been made harder to call.'""",
     """              'Classes today. And I want to start with the question most people skip: do you even need one? '
              'Python is not Java — you don\\'t have to wrap everything in a class. '
              'A module of plain functions is a perfectly respectable design. '
              'A class with one method and no stored data? That\\'s just a function wearing a fancy hat. '
              'Before you type \"class\", ask: am I bundling related state and behavior, or just organizing my code?'"""),
    # s2
    ("""              'The signal to watch for is repetition in your signatures. When '
              'four functions all take the same three arguments, those three '
              'things are one thing, and that thing wants to be an object. The '
              'other signal is needing many independent copies of some state '
              'with behaviour attached.'""",
     """              'Here\\'s the signal that screams \"use a class\": repetition in your function signatures. '
              'When four different functions all take the same three arguments — user_id, db_connection, config — '
              'those three things are secretly one thing. They\\'re begging to be an object. '
              'The other signal: you need many independent copies of state with behavior attached — '
              'like a hundred bank accounts, each with their own balance and their own transaction history.'"""),
    # s3
    ("""              'Mechanically: calling the class allocates an instance and passes '
              'it to dunder-init as self. Note that dunder-init initialises, it '
              'does not construct — the object already exists. And self is '
              'explicit because Python would rather you always see where an '
              'attribute comes from than save four characters.'""",
     """              'Let\\'s look at the mechanics. When you call MyClass(), Python allocates a blank object — '
              'just an empty shell — and then calls __init__ on it, passing it as self. '
              'That\\'s the crucial distinction: __init__ is an initializer, not a constructor. The object already exists. '
              'And self is explicit — you have to write it in every method signature — because Python wants you to know '
              'exactly where every attribute comes from. Four extra characters for total clarity. Fair trade.'"""),
    # s4
    ("""              'Then the class-versus-instance attribute distinction. Lookup '
              'checks the instance first, then the class, then the bases. So a '
              'class attribute is a shared default that an instance can shadow. '
              'That is useful for constants and dangerous for anything mutable, '
              'because there is exactly one of it for the whole program.'""",
     """              'Now, class attributes versus instance attributes — a distinction that bites beginners constantly. '
              'When you look up obj.x, Python checks the instance first, then the class, then the parent classes. '
              'So a class attribute acts like a shared default — every instance sees it unless they override it. '
              'Great for constants like DEFAULT_TIMEOUT. Disastrous for mutable things like []. '
              'Because there\\'s exactly ONE of that list, shared by every instance in your entire program. '
              'One instance appends, everyone sees it — like a group chat where everyone shares the same to-do list.'"""),
    # s5
    ("""              'Method flavours are worth getting straight. Instance methods '
              'take self. Class methods take cls, and they are how you write '
              'alternative constructors like from-string — using cls rather '
              'than the class name means subclasses get the right type back. '
              'Static methods take neither and are really just namespaced '
              'functions.'""",
     """              'There are three flavors of methods, and mixing them up is common. Instance methods: take self — '
              'your standard everyday method. Class methods: take cls instead, decorated with @classmethod — '
              'these are for alternative constructors like from_json or from_string. '
              'Using cls instead of hard-coding the class name means subclasses get back the right type automatically. '
              'Static methods: take neither self nor cls, decorated with @staticmethod — '
              'honestly, they\\'re just regular functions that happen to live in a class namespace.'"""),
    # s6
    ("""              'Properties are the reason Python code has so few getters. '
              'obj.width reads the same whether width is stored or computed, so '
              'you can start with a plain attribute and introduce validation '
              'later with zero changes at call sites. Just remember the setter '
              'must store to a differently-named attribute or it will recurse '
              'forever.'""",
     """              'Properties are why Python code doesn\\'t drown in get_width() and set_width() boilerplate. '
              'obj.width looks and feels like a plain attribute, whether it\\'s stored directly or computed on the fly. '
              'You can start simple — just a regular attribute — and later add validation or computation '
              'behind a @property without touching a single line of code that reads obj.width. '
              'One gotcha: the setter must store to a differently-named internal attribute (like _width), '
              'otherwise it calls itself in an infinite loop. Ask me how I know.'"""),
    # s7
    ("""              'Dunder methods make your objects feel native. Length, iteration, '
              'addition, comparison, the with statement, even calling the '
              'object — every one is a protocol you can opt into. But opt in '
              'only where the semantics are obvious. Overloading plus on a type '
              'where addition has no natural meaning is a puzzle, not an API.'""",
     """              'Dunder methods are what make your custom objects feel like they belong in Python. '
              'len(obj), for item in obj, obj1 + obj2, obj1 == obj2, with obj as x, even obj() — '
              'every one is a protocol you can opt into by defining the right dunder method. '
              'But here\\'s the discipline: only opt in when the meaning is obvious. '
              'If you overload + on an Order class, does that mean \"merge orders\" or \"add totals\"? '
              'If it\\'s ambiguous, write a named method instead. A confusing operator is worse than no operator at all.'"""),
    # s8
    ("""              'And inheritance. Use it for genuine is-a relationships and use '
              'super so delegation follows the method resolution order rather '
              'than a hard-coded parent. Otherwise, compose. If the class is '
              'mostly fields, the dataclass decorator writes dunder-init, '
              'dunder-repr and dunder-eq for you — and default-factory is how '
              'you give each instance its own list.'""",
     """              'And finally, inheritance. Use it for genuine \"is-a\" relationships — a Dog IS an Animal. '
              'Use super() so method delegation follows the method resolution order, not a hard-coded parent name. '
              'Otherwise, compose: give your class an attribute of the other type rather than inheriting from it. '
              'If your class is mostly data fields, reach for @dataclass — it writes __init__, __repr__, and __eq__ automatically. '
              'Use default_factory for mutable defaults so each instance gets its own fresh list, '
              'sidestepping the shared-default trap entirely.'"""),
]
apply(f"{BASE}/python/lesson_oop.dart", oop_s)

# ============================================================
# lesson_oop.dart - DEEP DIVE (d1-d11)
# ============================================================
oop_d = [
    # d1
    ("""              'The long form on Python objects. We will cover what a class '
              'statement actually does, how attribute lookup really works, '
              'descriptors, the method resolution order, the data model, and '
              'when to stop writing classes. Some of this is machinery you will '
              'rarely touch directly, but all of it explains behaviour you will '
              'definitely meet.'""",
     """              'The deep dive on Python objects. We\\'re going to unpack everything: what a class statement '
              'actually does at runtime, how attribute lookup really works under the hood, '
              'descriptors (which explain properties AND methods), the method resolution order, '
              'the full data model, and — crucially — when to stop writing classes. '
              'You might not touch this machinery directly every day, but you WILL meet its consequences. '
              'Understanding it turns \"mysterious behavior\" into \"oh, that\\'s why.\"'"""),
    # d2
    ("""              'Start with the class statement. It executes its body like any '
              'other block, collects the resulting namespace into a dictionary, '
              'and hands that to the type constructor to build a class object. '
              'So a class is an object too, created at runtime, and you could '
              'build the same thing by calling type with a name, bases and a '
              'dict. That is the whole basis of metaclasses.'""",
     """              'Let\\'s start with what \"class\" actually does. The class statement executes its body '
              'as a regular code block, collects all the names created into a dictionary, '
              'then calls type(name, bases, namespace_dict) to build the class object. '
              'Yes — a class itself is just another object, built at runtime like everything else. '
              'You could build the same thing manually by calling type(). '
              'This is the foundation of metaclasses: if type() builds classes, you can subclass type '
              'to customize HOW classes get built. Meta, right?'"""),
    # d3
    ("""              'Attribute lookup is more interesting than most people assume. '
              'Reading obj dot x does not just check the instance dictionary. '
              'It first looks through the type and its bases for a data '
              'descriptor — something defining both get and set, which is what '
              'a property is — and that wins over the instance dictionary. Only '
              'then does it check the instance, then non-data descriptors and '
              'plain class attributes, then dunder-getattr as a last resort.'""",
     """              'Attribute lookup is way more interesting than \"check the instance dict.\" '
              'When you read obj.x, Python runs through a precise priority chain. First: data descriptors — '
              'anything on the type or its bases that defines both __get__ and __set__ (that\\'s what @property is). '
              'Data descriptors win over EVERYTHING, including the instance\\'s own dictionary. '
              'Then: the instance dict. Then: non-data descriptors and plain class attributes. '
              'Finally, as a last resort: __getattr__. '
              'This whole chain runs every single time you type a dot — and now you know why.'"""),
    # d4
    ("""              'Descriptors also explain methods themselves. A function stored '
              'on a class is a non-data descriptor: accessing it through an '
              'instance calls its get, which returns a bound method with self '
              'already attached. That is why the method knows its instance, and '
              'why grabbing the function off the class and passing the instance '
              'manually works identically.'""",
     """              'Descriptors also explain methods — yes, plain old methods. A function sitting on a class '
              'is actually a non-data descriptor. When you access it through an instance, '
              'its __get__ fires and returns a bound method — a wrapper that has self already baked in. '
              'That\\'s the entire mechanism behind \"the method knows which instance called it.\" '
              'And it\\'s why MyClass.method(instance) and instance.method() do exactly the same thing — '
              'one is manual binding, the other uses the descriptor protocol to do it automatically.'"""),
    # d5
    ("""              'Now the method resolution order. Python uses C3 linearisation, '
              'which produces one consistent ordering that preserves each '
              'class\\'s own base order and puts every class before its parents. '
              'You can read it off any class\\'s dunder-mro. If no consistent '
              'order exists, the class statement itself raises a TypeError, at '
              'definition time.'""",
     """              'The method resolution order — or MRO — determines which version of a method gets called '
              'when there\\'s multiple inheritance. Python uses the C3 linearization algorithm, '
              'which produces a single consistent ordering. Two key properties: each class appears before its parents, '
              'and the order of bases you wrote in the class statement is preserved. '
              'You can inspect any class\\'s __mro__ to see the exact order. '
              'And here\\'s the best part: if no consistent order exists, Python raises TypeError at DEFINITION time — '
              'it won\\'t let you create an ambiguous class hierarchy in the first place.'"""),
    # d6
    ("""              'That is why super is not "call the parent". super finds the next '
              'class after the current one in the MRO of the actual instance, '
              'which may be a sibling rather than an ancestor. For cooperative '
              'multiple inheritance to work, every class in the chain has to '
              'call super and accept compatible arguments. Hard-code a base '
              'class name and you silently skip anything mixed in between.'""",
     """              'This is why super() is NOT \"call my parent.\" super() looks at the MRO of the actual instance, '
              'finds the current class, and calls the NEXT class in line — which might be a sibling, not an ancestor. '
              'For cooperative multiple inheritance to work, everyone in the chain must call super() '
              'and accept compatible keyword arguments. Hard-code a parent class name and you silently skip '
              'every mixin and intermediate class that was supposed to run. '
              'It\\'s like a relay race: super() passes the baton to the next runner in the MRO, whoever that is.'"""),
    # d7
    ("""              'The data model is the other half of the language. Length, '
              'indexing, iteration, context managers, comparison, hashing, '
              'string conversion, attribute access, even calling — all are '
              'dunder protocols. And there is a real contract between some of '
              'them: objects that compare equal must hash equal, which is why '
              'defining dunder-eq sets dunder-hash to None unless you supply '
              'one.'""",
     """              'The data model is the other half of Python — the set of protocols that make your objects'
              'feel native. __len__, __getitem__, __iter__, __enter__/__exit__, __eq__, __hash__, '
              '__str__, __getattr__, even __call__ — every one is a contract you can sign. '
              'And some contracts have teeth: objects that compare equal MUST hash equal. '
              'That\\'s why defining __eq__ automatically sets __hash__ to None — '
              'Python is saying \"I can\\'t guarantee your hash is consistent with your equality, '
              'so I\\'m revoking your hash privileges until you define one yourself.\"'"""),
    # d8
    ("""              'On repr versus str: repr should be unambiguous and ideally look '
              'like the constructor call that would recreate the object; str is '
              'for end users and defaults to repr if you do not define it. Get '
              'repr right and every traceback, log line and debugger view gets '
              'better at once. It is the highest-leverage six lines in a class.'""",
     """              'Quick word on __repr__ vs __str__, because most people don\\'t realize how important this is. '
              '__repr__ is for developers: it should be unambiguous and ideally look like the code '
              'that would recreate the object. __str__ is for end users — a friendly display. '
              'If you only define one, make it __repr__ — str falls back to it. '
              'Get __repr__ right and EVERY traceback, every log line, every debugger view gets clearer instantly. '
              'It is genuinely the highest-leverage six lines you can write in a class.'"""),
    # d9
    ("""              'Memory is worth a mention. Every instance normally carries its '
              'own dictionary, which is flexible and not tiny. Declaring '
              'dunder-slots replaces it with fixed slots, cutting memory '
              'substantially and blocking attribute additions. Dataclasses take '
              'a slots argument to do this for you. Reach for it when you have '
              'millions of small objects, and essentially never otherwise.'""",
     """              'A quick note on memory, because at scale it matters. Every normal Python instance '
              'carries its own __dict__ — flexible, but each dict has overhead. '
              '__slots__ replaces that dict with fixed, C-like slots — substantially smaller and faster, '
              'but you can\\'t add new attributes at runtime. Dataclasses support slots=True to do this automatically. '
              'When should you care? When you have millions of small objects — think data processing, game entities, '
              'financial ticks. Otherwise? Don\\'t prematurely optimize. A clean design beats a memory micro-optimization '
              'in 99% of cases.'"""),
    # d10
    ("""              'Two design notes to finish. First, prefer composition: '
              'inheritance couples you to a base class\\'s internals forever, '
              'while holding an object as an attribute lets you swap it. '
              'Second, Python is duck typed, so an interface is a set of '
              'methods, not a declaration — use typing.Protocol when you want a '
              'static checker to verify that shape without inheritance.'""",
     """              'Two design notes to carry with you. First: prefer composition over inheritance. '
              'Inheritance permanently couples you to your base class\\'s internals — change the base and every subclass feels it. '
              'Composition — just holding an object as an attribute — lets you swap implementations like changing batteries. '
              'Second: Python is duck-typed — \"if it quacks like a duck, it\\'s a duck.\" '
              'An interface is just a set of methods an object happens to have, not a formal declaration. '
              'When you DO want static checking of those shapes without inheritance, use typing.Protocol — '
              'it lets mypy verify the duck-typing without forcing a class hierarchy.'"""),
    # d11
    ("""              'Summary: a class is an object built at runtime, attribute lookup '
              'consults descriptors before the instance dictionary, super '
              'follows the MRO, dunder methods opt you into the language, and '
              'the best class is often the one you did not write.'""",
     """              'Let\\'s wrap up with the big picture. A class is just another object, built at runtime by type(). '
              'Attribute lookup runs through a sophisticated chain — descriptors first, then instance dict, then class dict. '
              'super() follows the MRO, not your parent. Dunder methods are how your class becomes a first-class citizen. '
              'And here\\'s the wisdom: the best class is often the one you didn\\'t write — '
              'a namedtuple, a dataclass, or just a module of functions. '
              'Classes are a tool, not a religion. Use them when they make your code clearer, not because you feel you should.'"""),
]
apply(f"{BASE}/python/lesson_oop.dart", oop_d)

print("OOP DONE.")
