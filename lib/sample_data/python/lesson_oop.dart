import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 2: classes, instances and the protocols that make objects
/// feel built in.
const Lesson oopLesson = Lesson(
  id: 'py-object-oriented-programming',
  title: 'Object-Oriented Programming',
  description:
      'Classes, instances, dunder methods and inheritance — and how to decide '
      'when a class is the right answer at all.',
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
      id: 'classes',
      heading: 'Classes bundle state with the behaviour that uses it',
      blocks: [
        ProseBlock(
          'A class is a factory for objects that share behaviour. Calling the '
          'class creates an instance: Python allocates it, passes it to '
          '__init__ as self, and __init__ attaches the instance\'s state. '
          '__init__ is an initialiser, not a constructor — the object already '
          'exists by the time it runs.',
        ),
        ProseBlock(
          'self is not a keyword. It is simply the first parameter of an '
          'instance method, and Python passes the instance into it '
          'automatically when you call the method through an object. Writing '
          'it out is deliberate: attribute access is always explicit, so you '
          'can never confuse a local variable with a field.',
        ),
        ProseBlock(
          'Reach for a class when several functions keep taking the same bundle '
          'of data as arguments, or when you need many independent copies of '
          'that state. A module of functions is often the better answer, and a '
          'class with one method and no state is a function wearing a hat.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class Account:
    """A bank account with a balance and a transaction log."""

    def __init__(self, owner, balance=0):
        self.owner = owner          # instance attribute
        self.balance = balance
        self.history = []

    def deposit(self, amount):
        if amount <= 0:
            raise ValueError("deposit must be positive")
        self.balance += amount
        self.history.append(("deposit", amount))
        return self.balance

    def withdraw(self, amount):
        if amount > self.balance:
            raise ValueError("insufficient funds")
        self.balance -= amount
        self.history.append(("withdraw", amount))
        return self.balance


acct = Account("ada", 100)
acct.deposit(50)
acct.withdraw(30)
print(acct.owner, acct.balance, acct.history)
# ada 120 [('deposit', 50), ('withdraw', 30)]
''',
          caption: '__init__ attaches state; methods act on it through self.',
        ),
      ],
    ),
    Section(
      id: 'attributes',
      heading: 'Class attributes vs instance attributes',
      blocks: [
        ProseBlock(
          'A name assigned in the class body belongs to the class and is shared '
          'by every instance. A name assigned through self belongs to that one '
          'instance. Attribute lookup checks the instance first, then the '
          'class, then its bases — so a class attribute acts as a default that '
          'an instance can shadow.',
        ),
        ProseBlock(
          'The trap is a mutable class attribute. Every instance sees the same '
          'list, so appending through one instance is visible through all of '
          'them — the same shared-default bug as a mutable parameter default, '
          'in a different costume. Mutable per-instance state belongs in '
          '__init__.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class Robot:
    species = "robot"     # class attribute: shared
    parts = []            # DANGER: shared mutable state

    def __init__(self, name):
        self.name = name  # instance attribute: per object


a = Robot("r2")
b = Robot("c3")

a.parts.append("arm")
print(b.parts)            # ['arm'] - the same list!

print(a.species, b.species)   # robot robot
a.species = "droid"           # shadows the class attribute on a only
print(a.species, b.species)   # droid robot
print(Robot.species)          # robot


class FixedRobot:
    species = "robot"

    def __init__(self, name):
        self.name = name
        self.parts = []       # a fresh list per instance
''',
          caption: 'Shared defaults are fine until they are mutable.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Never put a list or dict in the class body as state',
          text:
              'It is created once, when the class is defined, and shared by '
              'every instance for the lifetime of the process. Constants and '
              'immutable defaults in the class body are fine; anything you '
              'intend to mutate goes in __init__.',
        ),
      ],
    ),
    Section(
      id: 'methods-properties',
      heading: 'Method kinds and properties',
      blocks: [
        ProseBlock(
          'Instance methods receive the instance. A classmethod receives the '
          'class instead and is the standard way to write alternative '
          'constructors — from_string, from_json — which keep working correctly '
          'in subclasses because cls is whatever class was actually called. A '
          'staticmethod receives nothing special and is just a function that '
          'lives in the class namespace for organisational reasons.',
        ),
        ProseBlock(
          'Python has no need for getters and setters, because @property lets '
          'you turn an attribute into a computed value later without changing '
          'a single call site. Start with a plain attribute; add a property '
          'only when you genuinely need validation or derivation.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class Temperature:
    def __init__(self, celsius):
        self.celsius = celsius        # goes through the setter below

    @classmethod
    def from_fahrenheit(cls, degrees):
        return cls((degrees - 32) * 5 / 9)

    @staticmethod
    def is_freezing(celsius):
        return celsius <= 0

    @property
    def celsius(self):
        return self._celsius

    @celsius.setter
    def celsius(self, value):
        if value < -273.15:
            raise ValueError("below absolute zero")
        self._celsius = value

    @property
    def fahrenheit(self):             # computed, read-only
        return self._celsius * 9 / 5 + 32


t = Temperature.from_fahrenheit(212)
print(t.celsius, t.fahrenheit)    # 100.0 212.0
print(Temperature.is_freezing(-4))  # True
# t.celsius = -300                -> ValueError: below absolute zero
''',
          caption:
              'classmethod for alternative constructors, property for '
              'validation.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'A single underscore is a convention, not a lock',
          text:
              '_celsius means "internal, do not rely on this". Nothing prevents '
              'access. A double underscore triggers name mangling to '
              '_ClassName__attr, which exists to avoid collisions in '
              'subclasses, not to provide privacy.',
        ),
      ],
    ),
    Section(
      id: 'dunder',
      heading: 'Dunder methods: making objects feel built in',
      blocks: [
        ProseBlock(
          'Python\'s operators and built-in functions are protocols. len(x) '
          'calls x.__len__(), x + y calls x.__add__(y), print(x) calls '
          '__str__, and the interactive echo uses __repr__. Implement the '
          'relevant dunder methods and your class works with the language '
          'instead of alongside it.',
        ),
        ProseBlock(
          'The one to write every time is __repr__: it should be unambiguous '
          'and, ideally, look like the code that would recreate the object. It '
          'is what you see in tracebacks, debuggers and inside containers, and '
          'a good one saves more debugging time than any other single method. '
          'If you also implement __eq__, implement __hash__ or the type becomes '
          'unhashable.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class Money:
    def __init__(self, amount, currency="GBP"):
        self.amount = amount
        self.currency = currency

    def __repr__(self):
        return f"Money({self.amount!r}, {self.currency!r})"

    def __str__(self):
        return f"{self.amount:.2f} {self.currency}"

    def __eq__(self, other):
        if not isinstance(other, Money):
            return NotImplemented
        return (self.amount, self.currency) == (other.amount, other.currency)

    def __hash__(self):
        return hash((self.amount, self.currency))

    def __add__(self, other):
        if self.currency != other.currency:
            raise ValueError("currency mismatch")
        return Money(self.amount + other.amount, self.currency)

    def __lt__(self, other):
        return self.amount < other.amount


wallet = [Money(5), Money(2.5), Money(10)]
print(sorted(wallet))                 # uses __lt__, shows __repr__
print(Money(5) + Money(2.5))          # Money(7.5, 'GBP')
print(str(Money(7.5)))                # 7.50 GBP
print(Money(5) == Money(5))           # True
print(len({Money(5), Money(5)}))      # 1
''',
          caption: 'Implement the protocols and the language does the rest.',
        ),
      ],
    ),
    Section(
      id: 'inheritance',
      heading: 'Inheritance, composition and the MRO',
      blocks: [
        ProseBlock(
          'A subclass inherits its base\'s attributes and methods and may '
          'override them. super() delegates to the next class in the method '
          'resolution order — not simply "the parent" — which is what makes '
          'cooperative multiple inheritance work. Use it rather than naming the '
          'base class explicitly.',
        ),
        ProseBlock(
          'Inheritance models "is a": every Manager is an Employee, so a '
          'Manager can be used wherever an Employee is expected. When the '
          'relationship is really "has a" or "uses a", compose instead — hold '
          'the other object as an attribute. Deep hierarchies age badly; a '
          'class that inherits only to reuse one method is usually asking for a '
          'function.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class Employee:
    def __init__(self, name, salary):
        self.name = name
        self.salary = salary

    def describe(self):
        return f"{self.name} earns {self.salary}"


class Manager(Employee):
    def __init__(self, name, salary, reports):
        super().__init__(name, salary)     # let the base initialise its part
        self.reports = reports

    def describe(self):
        base = super().describe()
        return f"{base} and manages {len(self.reports)} people"


m = Manager("grace", 90000, ["ada", "alan"])
print(m.describe())          # grace earns 90000 and manages 2 people
print(isinstance(m, Employee))   # True
print(Manager.__mro__)
# (Manager, Employee, object)
''',
          caption: 'super() follows the MRO, not a hard-coded parent.',
        ),
        CollapsibleBlock(
          title: 'Under the hood: attribute lookup, __dict__ and __slots__',
          children: [
            ProseBlock(
              'Instance attributes live in a per-object dictionary, __dict__. '
              'Reading obj.x checks the type first for a data descriptor (a '
              'property is one), then the instance dictionary, then the type '
              'and its bases in MRO order, then falls back to __getattr__ if '
              'the class defines one. Because instance state is a dict, you can '
              'add attributes to most objects at any time.',
            ),
            ProseBlock(
              'That flexibility costs memory: every instance carries a hash '
              'table. Declaring __slots__ replaces it with a fixed set of slots '
              '— much smaller and slightly faster, at the cost of not being '
              'able to add unlisted attributes. It matters when you have '
              'millions of small objects and almost never otherwise.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
class Loose:
    def __init__(self, x):
        self.x = x


class Tight:
    __slots__ = ("x",)

    def __init__(self, x):
        self.x = x


a = Loose(1)
a.y = 2                 # fine: instance __dict__ accepts anything
print(a.__dict__)       # {'x': 1, 'y': 2}

b = Tight(1)
# b.y = 2               -> AttributeError: 'Tight' object has no attribute 'y'
print(Tight.__slots__)  # ('x',)
''',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'dataclasses',
      heading: 'Dataclasses: classes that are mostly data',
      blocks: [
        ProseBlock(
          'A great many classes exist only to hold a few fields. The '
          '@dataclass decorator writes __init__, __repr__ and __eq__ from the '
          'annotated class attributes, so the class body states the shape of '
          'the data and nothing else. frozen=True additionally makes instances '
          'immutable and hashable.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class Point:
    x: float
    y: float

    def distance_to(self, other):
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5


@dataclass
class Order:
    customer: str
    items: list[str] = field(default_factory=list)   # not items: list = []
    priority: int = 3


p = Point(0, 0)
print(p, p.distance_to(Point(3, 4)))     # Point(x=0, y=0) 5.0
print(Point(1, 2) == Point(1, 2))        # True - generated __eq__
print({Point(1, 2)})                     # frozen, so hashable

o = Order("ada")
o.items.append("book")
print(o)          # Order(customer='ada', items=['book'], priority=3)
print(Order("grace").items)   # [] - default_factory made a new list
''',
          caption:
              'default_factory is the dataclass answer to mutable defaults.',
        ),
        ProseBlock(
          'Use a dataclass when the class is a record with a little behaviour, '
          'a plain class when behaviour dominates, and a NamedTuple or a plain '
          'dict when it is genuinely just data being passed through. The '
          'decision is about what you want readers to notice.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-oop-repr-eq',
      title: 'Give a class a usable identity',
      prompt: [
        ProseBlock(
          'The Card class below prints uselessly and compares by identity, so '
          'two aces of spades are not equal and a set of cards never '
          'deduplicates. Add __repr__, __eq__ and __hash__ so that Card("A", '
          '"spades") equals another one, a set collapses duplicates, and the '
          'repr shows both fields.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class Card:
    def __init__(self, rank, suit):
        self.rank = rank
        self.suit = suit
''',
        ),
      ],
      starterCode: '''
class Card:
    def __init__(self, rank, suit):
        self.rank = rank
        self.suit = suit

    # TODO: __repr__, __eq__ and __hash__


hand = [Card("A", "spades"), Card("A", "spades"), Card("7", "hearts")]
print(hand[0])
print(hand[0] == hand[1])
print(len(set(hand)))
''',
      solutionCode: '''
class Card:
    def __init__(self, rank, suit):
        self.rank = rank
        self.suit = suit

    def __repr__(self):
        return f"Card({self.rank!r}, {self.suit!r})"

    def __eq__(self, other):
        if not isinstance(other, Card):
            return NotImplemented
        return (self.rank, self.suit) == (other.rank, other.suit)

    def __hash__(self):
        return hash((self.rank, self.suit))


hand = [Card("A", "spades"), Card("A", "spades"), Card("7", "hearts")]
print(hand[0])           # Card('A', 'spades')
print(hand[0] == hand[1])  # True
print(len(set(hand)))    # 2
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why return NotImplemented rather than False when other is not a '
              'Card?',
          expectedAnswer:
              'NotImplemented tells Python that this type cannot answer, so it '
              'tries the reflected operation on the other operand before '
              'falling back to identity comparison. Returning False claims the '
              'objects are definitely unequal and prevents a cooperating type '
              'from ever matching.',
        ),
        SelfCheckQuestion(
          question:
              'What happens if you define __eq__ but not __hash__, and why is '
              'that the default?',
          expectedAnswer:
              'Python sets __hash__ to None, so instances become unhashable and '
              'cannot go in a set or be dict keys. That is deliberate: objects '
              'that compare equal must hash equal, and the inherited '
              'identity-based hash would violate that as soon as you define '
              'value equality.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-oop-property',
      title: 'Add validation without breaking callers',
      prompt: [
        ProseBlock(
          'Rectangle currently exposes a plain width attribute, and code all '
          'over the codebase already does rect.width = 5. Add validation so a '
          'negative width raises ValueError, and add a read-only area — without '
          'changing a single existing call site.',
        ),
      ],
      starterCode: '''
class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height


r = Rectangle(3, 4)
r.width = 5          # existing call sites look like this - keep them working
print(r.area)        # should be 20
# r.width = -1       # should raise ValueError
''',
      solutionCode: '''
class Rectangle:
    def __init__(self, width, height):
        self.width = width          # runs through the setter
        self.height = height

    @property
    def width(self):
        return self._width

    @width.setter
    def width(self, value):
        if value < 0:
            raise ValueError("width must not be negative")
        self._width = value

    @property
    def area(self):
        return self._width * self.height


r = Rectangle(3, 4)
r.width = 5
print(r.area)        # 20

try:
    r.width = -1
except ValueError as exc:
    print("rejected:", exc)   # rejected: width must not be negative
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why is it safe to start with a plain attribute and add a '
              'property later?',
          expectedAnswer:
              'Because the syntax at every call site is identical: rect.width '
              'reads and rect.width = 5 writes, whether width is stored data or '
              'a descriptor that runs code. This is why Python code does not '
              'need speculative getters and setters the way Java does.',
        ),
        SelfCheckQuestion(
          question:
              'What would happen if the setter assigned to self.width instead '
              'of self._width?',
          expectedAnswer:
              'Infinite recursion. Assigning to self.width invokes the setter '
              'again, which assigns to self.width again, until Python raises '
              'RecursionError. The property must store its value under a '
              'different name.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-oop-inherit',
      title: 'Extend a class with super()',
      prompt: [
        ProseBlock(
          'Given the Shape base class below, write Circle and Square '
          'subclasses. Each takes its own dimensions plus a name, must call '
          'super().__init__ to set the name, and must override area(). Then '
          'print the total area of a mixed list of shapes without any isinstance '
          'checks.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
class Shape:
    def __init__(self, name):
        self.name = name

    def area(self):
        raise NotImplementedError

    def __repr__(self):
        return f"{self.name}(area={self.area():.2f})"
''',
        ),
      ],
      starterCode: '''
class Shape:
    def __init__(self, name):
        self.name = name

    def area(self):
        raise NotImplementedError

    def __repr__(self):
        return f"{self.name}(area={self.area():.2f})"


class Circle(Shape):
    # TODO: __init__ taking radius, call super(), override area()
    ...


class Square(Shape):
    # TODO: __init__ taking side, call super(), override area()
    ...


shapes = [Circle(1), Square(2)]
print(shapes, sum(s.area() for s in shapes))
''',
      solutionCode: '''
import math


class Shape:
    def __init__(self, name):
        self.name = name

    def area(self):
        raise NotImplementedError

    def __repr__(self):
        return f"{self.name}(area={self.area():.2f})"


class Circle(Shape):
    def __init__(self, radius):
        super().__init__("circle")
        self.radius = radius

    def area(self):
        return math.pi * self.radius ** 2


class Square(Shape):
    def __init__(self, side):
        super().__init__("square")
        self.side = side

    def area(self):
        return self.side ** 2


shapes = [Circle(1), Square(2)]
print(shapes)                            # [circle(area=3.14), square(area=4.00)]
print(sum(s.area() for s in shapes))     # 7.141592653589793
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The total is computed without checking any types. What is that '
              'relying on?',
          expectedAnswer:
              'Polymorphism through a shared interface: each subclass provides '
              'its own area(), so the caller only needs the promise that the '
              'method exists. Adding a Triangle later requires no change to the '
              'summing code — which is the whole point of overriding rather '
              'than branching on type.',
        ),
        SelfCheckQuestion(
          question:
              'Why call super().__init__() rather than Shape.__init__(self, '
              '...)?',
          expectedAnswer:
              'super() follows the method resolution order of the actual class '
              'being constructed, so it keeps working if the hierarchy changes '
              'or another base is mixed in. Hard-coding the base name skips any '
              'class that was inserted between them and breaks cooperative '
              'multiple inheritance.',
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
              'Object-oriented Python in about four minutes. A class bundles '
              'state with the behaviour that operates on it. Calling the class '
              'makes an instance, dunder-init attaches that instance\'s data, '
              'and self is just the first parameter of every instance method — '
              'not a keyword.',
          startMs: 0,
          endMs: 46000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Watch where you put state. A name assigned in the class body is '
              'shared by every instance; a name assigned through self belongs '
              'to one object. Put a list in the class body and every instance '
              'mutates the same list — the same bug as a mutable default '
              'argument.',
          startMs: 46000,
          endMs: 96000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Python does not need getters and setters, because the property '
              'decorator lets you turn a plain attribute into a computed one '
              'later without touching a single call site. Start plain, add a '
              'property only when validation or derivation actually arrives.',
          startMs: 96000,
          endMs: 140000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Dunder methods are how your class joins the language. Write '
              'dunder-repr every time — it is what tracebacks and debuggers '
              'show. Add dunder-eq and dunder-hash together if value equality '
              'matters, and the comparison and arithmetic dunders only when '
              'they genuinely make sense.',
          startMs: 140000,
          endMs: 188000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Finally: inherit for "is a", compose for "has a", and if the '
              'class is really just fields, reach for a dataclass and let it '
              'write dunder-init, dunder-repr and dunder-eq for you.',
          startMs: 188000,
          endMs: 222000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 516000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Classes today. And I want to start with the question people '
              'skip, which is whether you need one at all. Python is not Java: a '
              'module full of functions is a perfectly respectable design, and '
              'a class with a single method and no state is a function that has '
              'been made harder to call.',
          startMs: 0,
          endMs: 56000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The signal to watch for is repetition in your signatures. When '
              'four functions all take the same three arguments, those three '
              'things are one thing, and that thing wants to be an object. The '
              'other signal is needing many independent copies of some state '
              'with behaviour attached.',
          startMs: 56000,
          endMs: 118000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Mechanically: calling the class allocates an instance and passes '
              'it to dunder-init as self. Note that dunder-init initialises, it '
              'does not construct — the object already exists. And self is '
              'explicit because Python would rather you always see where an '
              'attribute comes from than save four characters.',
          startMs: 118000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Then the class-versus-instance attribute distinction. Lookup '
              'checks the instance first, then the class, then the bases. So a '
              'class attribute is a shared default that an instance can shadow. '
              'That is useful for constants and dangerous for anything mutable, '
              'because there is exactly one of it for the whole program.',
          startMs: 182000,
          endMs: 250000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Method flavours are worth getting straight. Instance methods '
              'take self. Class methods take cls, and they are how you write '
              'alternative constructors like from-string — using cls rather '
              'than the class name means subclasses get the right type back. '
              'Static methods take neither and are really just namespaced '
              'functions.',
          startMs: 250000,
          endMs: 320000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Properties are the reason Python code has so few getters. '
              'obj.width reads the same whether width is stored or computed, so '
              'you can start with a plain attribute and introduce validation '
              'later with zero changes at call sites. Just remember the setter '
              'must store to a differently-named attribute or it will recurse '
              'forever.',
          startMs: 320000,
          endMs: 388000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Dunder methods make your objects feel native. Length, iteration, '
              'addition, comparison, the with statement, even calling the '
              'object — every one is a protocol you can opt into. But opt in '
              'only where the semantics are obvious. Overloading plus on a type '
              'where addition has no natural meaning is a puzzle, not an API.',
          startMs: 388000,
          endMs: 456000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And inheritance. Use it for genuine is-a relationships and use '
              'super so delegation follows the method resolution order rather '
              'than a hard-coded parent. Otherwise, compose. If the class is '
              'mostly fields, the dataclass decorator writes dunder-init, '
              'dunder-repr and dunder-eq for you — and default-factory is how '
              'you give each instance its own list.',
          startMs: 456000,
          endMs: 516000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 858000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'The long form on Python objects. We will cover what a class '
              'statement actually does, how attribute lookup really works, '
              'descriptors, the method resolution order, the data model, and '
              'when to stop writing classes. Some of this is machinery you will '
              'rarely touch directly, but all of it explains behaviour you will '
              'definitely meet.',
          startMs: 0,
          endMs: 68000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with the class statement. It executes its body like any '
              'other block, collects the resulting namespace into a dictionary, '
              'and hands that to the type constructor to build a class object. '
              'So a class is an object too, created at runtime, and you could '
              'build the same thing by calling type with a name, bases and a '
              'dict. That is the whole basis of metaclasses.',
          startMs: 68000,
          endMs: 156000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Attribute lookup is more interesting than most people assume. '
              'Reading obj dot x does not just check the instance dictionary. '
              'It first looks through the type and its bases for a data '
              'descriptor — something defining both get and set, which is what '
              'a property is — and that wins over the instance dictionary. Only '
              'then does it check the instance, then non-data descriptors and '
              'plain class attributes, then dunder-getattr as a last resort.',
          startMs: 156000,
          endMs: 254000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Descriptors also explain methods themselves. A function stored '
              'on a class is a non-data descriptor: accessing it through an '
              'instance calls its get, which returns a bound method with self '
              'already attached. That is why the method knows its instance, and '
              'why grabbing the function off the class and passing the instance '
              'manually works identically.',
          startMs: 254000,
          endMs: 336000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Now the method resolution order. Python uses C3 linearisation, '
              'which produces one consistent ordering that preserves each '
              'class\'s own base order and puts every class before its parents. '
              'You can read it off any class\'s dunder-mro. If no consistent '
              'order exists, the class statement itself raises a TypeError, at '
              'definition time.',
          startMs: 336000,
          endMs: 414000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'That is why super is not "call the parent". super finds the next '
              'class after the current one in the MRO of the actual instance, '
              'which may be a sibling rather than an ancestor. For cooperative '
              'multiple inheritance to work, every class in the chain has to '
              'call super and accept compatible arguments. Hard-code a base '
              'class name and you silently skip anything mixed in between.',
          startMs: 414000,
          endMs: 496000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'The data model is the other half of the language. Length, '
              'indexing, iteration, context managers, comparison, hashing, '
              'string conversion, attribute access, even calling — all are '
              'dunder protocols. And there is a real contract between some of '
              'them: objects that compare equal must hash equal, which is why '
              'defining dunder-eq sets dunder-hash to None unless you supply '
              'one.',
          startMs: 496000,
          endMs: 580000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'On repr versus str: repr should be unambiguous and ideally look '
              'like the constructor call that would recreate the object; str is '
              'for end users and defaults to repr if you do not define it. Get '
              'repr right and every traceback, log line and debugger view gets '
              'better at once. It is the highest-leverage six lines in a class.',
          startMs: 580000,
          endMs: 656000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Memory is worth a mention. Every instance normally carries its '
              'own dictionary, which is flexible and not tiny. Declaring '
              'dunder-slots replaces it with fixed slots, cutting memory '
              'substantially and blocking attribute additions. Dataclasses take '
              'a slots argument to do this for you. Reach for it when you have '
              'millions of small objects, and essentially never otherwise.',
          startMs: 656000,
          endMs: 736000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Two design notes to finish. First, prefer composition: '
              'inheritance couples you to a base class\'s internals forever, '
              'while holding an object as an attribute lets you swap it. '
              'Second, Python is duck typed, so an interface is a set of '
              'methods, not a declaration — use typing.Protocol when you want a '
              'static checker to verify that shape without inheritance.',
          startMs: 736000,
          endMs: 812000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Summary: a class is an object built at runtime, attribute lookup '
              'consults descriptors before the instance dictionary, super '
              'follows the MRO, dunder methods opt you into the language, and '
              'the best class is often the one you did not write.',
          startMs: 812000,
          endMs: 858000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'State plus the behaviour that uses it',
      body:
          'Write a class when several functions keep passing the same bundle of '
          'data around, or when you need many independent copies of that state. '
          '__init__ initialises an object that already exists, and self is just '
          'the first parameter of an instance method.',
    ),
    SummaryCard(
      title: 'Class body is shared, self is per instance',
      body:
          'Attribute lookup checks the instance, then the class, then the '
          'bases, so class attributes act as shared defaults. Never put a '
          'mutable value there as state — every instance would mutate the same '
          'object. Mutable state belongs in __init__.',
    ),
    SummaryCard(
      title: 'Protocols over plumbing',
      body:
          '@property turns an attribute into computed behaviour without '
          'changing call sites, and dunder methods let operators, len(), '
          'iteration and sorting work on your type. Always write __repr__; pair '
          '__eq__ with __hash__.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Instance vs class attribute',
      definition:
          'A name assigned through self exists per object; a name assigned in '
          'the class body is shared by every instance and can be shadowed by an '
          'instance attribute of the same name.',
    ),
    KeyConcept(
      term: 'classmethod',
      definition:
          'A method that receives the class as its first argument rather than '
          'an instance. The standard way to write alternative constructors, '
          'because cls is the class actually called, so subclasses get their '
          'own type back.',
    ),
    KeyConcept(
      term: 'property',
      definition:
          'A descriptor that makes attribute access run code, so a stored '
          'attribute can gain validation or become computed without changing '
          'any call site.',
    ),
    KeyConcept(
      term: 'Dunder method',
      definition:
          'A specially named method such as __repr__, __eq__ or __len__ that '
          'the language calls on your behalf, letting an object take part in '
          'operators, built-in functions and statements.',
    ),
    KeyConcept(
      term: 'MRO (method resolution order)',
      definition:
          'The linear order, computed by C3 linearisation, in which Python '
          'searches a class and its bases for an attribute. super() delegates '
          'to the next class in this order, not necessarily a parent.',
    ),
    KeyConcept(
      term: 'Dataclass',
      definition:
          'A class decorated with @dataclass, whose annotated fields generate '
          '__init__, __repr__ and __eq__. frozen=True makes instances immutable '
          'and hashable; field(default_factory=list) gives each instance its '
          'own container.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Declaring a mutable attribute in the class body, e.g. items = [].',
      correction:
          'That list is created once and shared by every instance, so one '
          'object\'s append is visible from all of them. Create it per instance '
          'in __init__, or use field(default_factory=list) in a dataclass.',
    ),
    Mistake(
      mistake:
          'Defining __eq__ and then wondering why instances cannot go in a '
          'set.',
      correction:
          'Defining __eq__ sets __hash__ to None to protect the equal-implies-'
          'same-hash contract. Define __hash__ over the same fields, or use '
          '@dataclass(frozen=True), which generates both.',
    ),
    Mistake(
      mistake:
          'A property setter that assigns to the property\'s own name, e.g. '
          'self.width = value inside the width setter.',
      correction:
          'That re-invokes the setter and recurses until RecursionError. Store '
          'the value under a different attribute name, conventionally '
          'self._width.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'What is the difference between a classmethod and a staticmethod, and '
          'when do you use each?',
      answer:
          'A classmethod receives the class as its first argument, so it can '
          'construct instances of whatever class it was called on — that makes '
          'it the right tool for alternative constructors such as '
          'Date.from_string, which keeps working correctly in subclasses. A '
          'staticmethod receives nothing implicit and is just a plain function '
          'placed in the class namespace for organisation; if it never touches '
          'the class or its instances, a module-level function is usually the '
          'more honest choice.',
    ),
    InterviewQuestion(
      question:
          'What does super() actually do, and why is it better than naming the '
          'base class?',
      answer:
          'super() returns a proxy that dispatches to the next class after the '
          'current one in the MRO of the instance being operated on — which may '
          'be a sibling class in a multiple-inheritance hierarchy, not an '
          'ancestor of the class you wrote. Naming the base class directly '
          'skips any class inserted between them, so cooperative mixins break '
          'and, in diamond hierarchies, a shared base can end up initialised '
          'twice.',
    ),
    InterviewQuestion(
      question:
          'When would you use a dataclass instead of a plain class or a '
          'dictionary?',
      answer:
          'Use a dataclass when the object is primarily a record of named '
          'fields with a little behaviour: you get __init__, __repr__ and '
          '__eq__ generated, annotations that document and type-check the '
          'fields, and optional immutability with frozen=True. A plain class is '
          'better when behaviour dominates and the generated methods would be '
          'wrong; a dict is better for genuinely dynamic keys or data merely '
          'passing through, at the cost of typo-safety and discoverability.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: '9. Classes — Python Docs',
    url: 'https://docs.python.org/3/tutorial/classes.html',
    description:
        'Tutorial chapter on class syntax, scopes and namespaces, instance and '
        'class variables, inheritance and private-by-convention names.',
  ),
  Source(
    title: '3. Data model — Python Docs',
    url: 'https://docs.python.org/3/reference/datamodel.html',
    description:
        'The reference for every special method: object creation, attribute '
        'access, descriptors, __slots__, operators and the MRO.',
  ),
];
