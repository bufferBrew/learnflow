import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
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
  play: _play,
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

const GameContent _play = GameContent(
  games: [
    OutputPredictorGame(
      id: 'game-oop-mutable-class-attr',
      title: 'What does this print?',
      instructions: 'Pick what print(b.parts) prints.',
      code: '''
class Robot:
    parts = []

    def __init__(self, name):
        self.name = name


a = Robot("r2")
b = Robot("c3")
a.parts.append("arm")
print(b.parts)
''',
      options: ['[]', "['arm']", 'AttributeError', 'None'],
      correctIndex: 1,
      explanation:
          'parts is a class attribute — one list shared by every instance. '
          'Appending through a mutates that single shared list, so b sees '
          'the change too, exactly like a mutable default argument.',
    ),
    FillBlankGame(
      id: 'game-oop-property',
      title: 'Turn an attribute into a property',
      instructions: 'Type the missing decorator name.',
      code: '''
class Temperature:
    def __init__(self, celsius):
        self.celsius = celsius

    @______
    def celsius(self):
        return self._celsius
''',
      blanks: [Blank(answer: 'property', hint: 'decorator')],
    ),
    BugHuntGame(
      id: 'game-oop-missing-self',
      title: 'Find the missing parameter',
      instructions: 'Tap the line that will raise TypeError when called.',
      code: '''
class Counter:
    def __init__(self):
        self.count = 0

    def increment():
        self.count += 1
''',
      buggyLine: 5,
      explanation:
          'increment is missing self. Python always passes the instance as '
          'the first argument when you call a method through an object, so '
          'counter.increment() raises TypeError: takes 0 positional '
          'arguments but 1 was given.',
      fixedCode: '''
class Counter:
    def __init__(self):
        self.count = 0

    def increment(self):
        self.count += 1
''',
    ),
    SyntaxScrambleGame(
      id: 'game-oop-scramble',
      title: 'Rebuild the Point class',
      instructions: 'Drag or use the arrows to put these lines back in order.',
      lines: [
        'class Point:',
        '    def __init__(self, x, y):',
        '        self.x = x',
        '        self.y = y',
        '    def __repr__(self):',
        '        return f"Point({self.x}, {self.y})"',
      ],
    ),
    TermMatchGame(
      id: 'game-oop-terms',
      title: 'Match the vocabulary',
      instructions: 'Tap a term, then tap its definition.',
      pairs: [
        TermPair(
          term: 'Instance vs class attribute',
          definition: 'Per-object state set via self, versus state shared by all.',
        ),
        TermPair(
          term: 'classmethod',
          definition: 'A method that receives the class itself, not an instance.',
        ),
        TermPair(
          term: 'property',
          definition: 'A descriptor that runs code on plain-looking attribute access.',
        ),
        TermPair(
          term: 'Dunder method',
          definition: 'A specially named method the language calls on your behalf.',
        ),
        TermPair(
          term: 'MRO',
          definition: 'The order Python searches a class and its bases for a name.',
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
              'Object-oriented Python in about four minutes. Think of a class as a blueprint for a house. '
              'The blueprint says what rooms every house has, but each actual house — each instance — '
              'has its own furniture, its own paint color. Calling the class builds a new house; '
              '__init__ is the interior decorator that sets it up. '
              'And self? It\'s just how each room knows which house it belongs to — not a keyword, just a name.',
          startMs: 0,
          endMs: 46000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Watch where you put your stuff. Something defined in the class body is like a community fridge — '
              'every instance shares it. Something assigned through self in __init__ is like a personal fridge — '
              'each instance gets its own. Put a list in the class body and suddenly every instance '
              'is adding to the same shopping cart. Same trap as mutable default arguments, just in a different costume.',
          startMs: 46000,
          endMs: 96000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Python doesn\'t need getters and setters — and that surprises people coming from Java. '
              'The @property decorator is like a trap door: you start with a plain attribute, then later '
              'you can slide validation or computation underneath without changing a single line of caller code. '
              'It\'s like upgrading from a regular door to one that checks IDs — nobody on the outside notices the difference. '
              'Start simple, add @property only when you actually need it.',
          startMs: 96000,
          endMs: 140000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Dunder methods — the ones with double underscores — are how your class becomes a first-class citizen. '
              'Always write __repr__: it\'s what shows up in tracebacks, debuggers, and the REPL. '
              'Add __eq__ and __hash__ together if you want value comparison — like two wallets being equal if they hold the same cash. '
              'The arithmetic dunders like __add__ and __lt__? Only when they genuinely make sense. '
              'Nobody wants to "add" two Customer objects.',
          startMs: 140000,
          endMs: 188000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Finally, the design rules. Inherit when something truly IS a more specific version — '
              'a SavingsAccount IS an Account. Compose when it HAS something — a Car HAS an Engine, it isn\'t one. '
              'And if your class is mostly just data fields — a Point with x and y, a User with name and email — '
              'reach for @dataclass and let Python write __init__, __repr__, and __eq__ for you. '
              'Save the boilerplate for the boiler room.',
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
              'Classes today. And I want to start with the question most people skip: do you even need one? '
              'Python is not Java — you don\'t have to wrap everything in a class. '
              'A module of plain functions is a perfectly respectable design. '
              'A class with one method and no stored data? That\'s just a function wearing a fancy hat. '
              'Before you type "class", ask: am I bundling related state and behavior, or just organizing my code?',
          startMs: 0,
          endMs: 56000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Here\'s the signal that screams "use a class": repetition in your function signatures. '
              'When four different functions all take the same three arguments — user_id, db_connection, config — '
              'those three things are secretly one thing. They\'re begging to be an object. '
              'The other signal: you need many independent copies of state with behavior attached — '
              'like a hundred bank accounts, each with their own balance and their own transaction history.',
          startMs: 56000,
          endMs: 118000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Let\'s look at the mechanics. When you call MyClass(), Python allocates a blank object — '
              'just an empty shell — and then calls __init__ on it, passing it as self. '
              'That\'s the crucial distinction: __init__ is an initializer, not a constructor. The object already exists. '
              'And self is explicit — you have to write it in every method signature — because Python wants you to know '
              'exactly where every attribute comes from. Four extra characters for total clarity. Fair trade.',
          startMs: 118000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Now, class attributes versus instance attributes — a distinction that bites beginners constantly. '
              'When you look up obj.x, Python checks the instance first, then the class, then the parent classes. '
              'So a class attribute acts like a shared default — every instance sees it unless they override it. '
              'Great for constants like DEFAULT_TIMEOUT. Disastrous for mutable things like []. '
              'Because there\'s exactly ONE of that list, shared by every instance in your entire program. '
              'One instance appends, everyone sees it — like a group chat where everyone shares the same to-do list.',
          startMs: 182000,
          endMs: 250000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'There are three flavors of methods, and mixing them up is common. Instance methods: take self — '
              'your standard everyday method. Class methods: take cls instead, decorated with @classmethod — '
              'these are for alternative constructors like from_json or from_string. '
              'Using cls instead of hard-coding the class name means subclasses get back the right type automatically. '
              'Static methods: take neither self nor cls, decorated with @staticmethod — '
              'honestly, they\'re just regular functions that happen to live in a class namespace.',
          startMs: 250000,
          endMs: 320000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Properties are why Python code doesn\'t drown in get_width() and set_width() boilerplate. '
              'obj.width looks and feels like a plain attribute, whether it\'s stored directly or computed on the fly. '
              'You can start simple — just a regular attribute — and later add validation or computation '
              'behind a @property without touching a single line of code that reads obj.width. '
              'One gotcha: the setter must store to a differently-named internal attribute (like _width), '
              'otherwise it calls itself in an infinite loop. Ask me how I know.',
          startMs: 320000,
          endMs: 388000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Dunder methods are what make your custom objects feel like they belong in Python. '
              'len(obj), for item in obj, obj1 + obj2, obj1 == obj2, with obj as x, even obj() — '
              'every one is a protocol you can opt into by defining the right dunder method. '
              'But here\'s the discipline: only opt in when the meaning is obvious. '
              'If you overload + on an Order class, does that mean "merge orders" or "add totals"? '
              'If it\'s ambiguous, write a named method instead. A confusing operator is worse than no operator at all.',
          startMs: 388000,
          endMs: 456000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And finally, inheritance. Use it for genuine "is-a" relationships — a Dog IS an Animal. '
              'Use super() so method delegation follows the method resolution order, not a hard-coded parent name. '
              'Otherwise, compose: give your class an attribute of the other type rather than inheriting from it. '
              'If your class is mostly data fields, reach for @dataclass — it writes __init__, __repr__, and __eq__ automatically. '
              'Use default_factory for mutable defaults so each instance gets its own fresh list, '
              'sidestepping the shared-default trap entirely.',
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
              'The deep dive on Python objects. We\'re going to unpack everything: what a class statement '
              'actually does at runtime, how attribute lookup really works under the hood, '
              'descriptors (which explain properties AND methods), the method resolution order, '
              'the full data model, and — crucially — when to stop writing classes. '
              'You might not touch this machinery directly every day, but you WILL meet its consequences. '
              'Understanding it turns "mysterious behavior" into "oh, that\'s why."',
          startMs: 0,
          endMs: 68000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Let\'s start with what "class" actually does. The class statement executes its body '
              'as a regular code block, collects all the names created into a dictionary, '
              'then calls type(name, bases, namespace_dict) to build the class object. '
              'Yes — a class itself is just another object, built at runtime like everything else. '
              'You could build the same thing manually by calling type(). '
              'This is the foundation of metaclasses: if type() builds classes, you can subclass type '
              'to customize HOW classes get built. Meta, right?',
          startMs: 68000,
          endMs: 156000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Attribute lookup is way more interesting than "check the instance dict." '
              'When you read obj.x, Python runs through a precise priority chain. First: data descriptors — '
              'anything on the type or its bases that defines both __get__ and __set__ (that\'s what @property is). '
              'Data descriptors win over EVERYTHING, including the instance\'s own dictionary. '
              'Then: the instance dict. Then: non-data descriptors and plain class attributes. '
              'Finally, as a last resort: __getattr__. '
              'This whole chain runs every single time you type a dot — and now you know why.',
          startMs: 156000,
          endMs: 254000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Descriptors also explain methods — yes, plain old methods. A function sitting on a class '
              'is actually a non-data descriptor. When you access it through an instance, '
              'its __get__ fires and returns a bound method — a wrapper that has self already baked in. '
              'That\'s the entire mechanism behind "the method knows which instance called it." '
              'And it\'s why MyClass.method(instance) and instance.method() do exactly the same thing — '
              'one is manual binding, the other uses the descriptor protocol to do it automatically.',
          startMs: 254000,
          endMs: 336000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'The method resolution order — or MRO — determines which version of a method gets called '
              'when there\'s multiple inheritance. Python uses the C3 linearization algorithm, '
              'which produces a single consistent ordering. Two key properties: each class appears before its parents, '
              'and the order of bases you wrote in the class statement is preserved. '
              'You can inspect any class\'s __mro__ to see the exact order. '
              'And here\'s the best part: if no consistent order exists, Python raises TypeError at DEFINITION time — '
              'it won\'t let you create an ambiguous class hierarchy in the first place.',
          startMs: 336000,
          endMs: 414000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'This is why super() is NOT "call my parent." super() looks at the MRO of the actual instance, '
              'finds the current class, and calls the NEXT class in line — which might be a sibling, not an ancestor. '
              'For cooperative multiple inheritance to work, everyone in the chain must call super() '
              'and accept compatible keyword arguments. Hard-code a parent class name and you silently skip '
              'every mixin and intermediate class that was supposed to run. '
              'It\'s like a relay race: super() passes the baton to the next runner in the MRO, whoever that is.',
          startMs: 414000,
          endMs: 496000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'The data model is the other half of Python — the set of protocols that make your objects'
              'feel native. __len__, __getitem__, __iter__, __enter__/__exit__, __eq__, __hash__, '
              '__str__, __getattr__, even __call__ — every one is a contract you can sign. '
              'And some contracts have teeth: objects that compare equal MUST hash equal. '
              'That\'s why defining __eq__ automatically sets __hash__ to None — '
              'Python is saying "I can\'t guarantee your hash is consistent with your equality, '
              'so I\'m revoking your hash privileges until you define one yourself."',
          startMs: 496000,
          endMs: 580000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Quick word on __repr__ vs __str__, because most people don\'t realize how important this is. '
              '__repr__ is for developers: it should be unambiguous and ideally look like the code '
              'that would recreate the object. __str__ is for end users — a friendly display. '
              'If you only define one, make it __repr__ — str falls back to it. '
              'Get __repr__ right and EVERY traceback, every log line, every debugger view gets clearer instantly. '
              'It is genuinely the highest-leverage six lines you can write in a class.',
          startMs: 580000,
          endMs: 656000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'A quick note on memory, because at scale it matters. Every normal Python instance '
              'carries its own __dict__ — flexible, but each dict has overhead. '
              '__slots__ replaces that dict with fixed, C-like slots — substantially smaller and faster, '
              'but you can\'t add new attributes at runtime. Dataclasses support slots=True to do this automatically. '
              'When should you care? When you have millions of small objects — think data processing, game entities, '
              'financial ticks. Otherwise? Don\'t prematurely optimize. A clean design beats a memory micro-optimization '
              'in 99% of cases.',
          startMs: 656000,
          endMs: 736000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Two design notes to carry with you. First: prefer composition over inheritance. '
              'Inheritance permanently couples you to your base class\'s internals — change the base and every subclass feels it. '
              'Composition — just holding an object as an attribute — lets you swap implementations like changing batteries. '
              'Second: Python is duck-typed — "if it quacks like a duck, it\'s a duck." '
              'An interface is just a set of methods an object happens to have, not a formal declaration. '
              'When you DO want static checking of those shapes without inheritance, use typing.Protocol — '
              'it lets mypy verify the duck-typing without forcing a class hierarchy.',
          startMs: 736000,
          endMs: 812000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Let\'s wrap up with the big picture. A class is just another object, built at runtime by type(). '
              'Attribute lookup runs through a sophisticated chain — descriptors first, then instance dict, then class dict. '
              'super() follows the MRO, not your parent. Dunder methods are how your class becomes a first-class citizen. '
              'And here\'s the wisdom: the best class is often the one you didn\'t write — '
              'a namedtuple, a dataclass, or just a module of functions. '
              'Classes are a tool, not a religion. Use them when they make your code clearer, not because you feel you should.',
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
