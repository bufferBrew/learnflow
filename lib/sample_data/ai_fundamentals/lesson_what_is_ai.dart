import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 1: what machine learning actually is, and the vocabulary
/// every later lesson assumes.
const Lesson whatIsAiLesson = Lesson(
  id: 'ai-what-is-ai-ml',
  title: 'What Is AI/ML? Core Concepts & Terminology',
  description:
      'How learning from data differs from writing rules, and the vocabulary — '
      'features, labels, models, generalisation — the rest of the field is '
      'built on.',
  estimatedMinutes: 24,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  play: GameContent(games: <Game>[]),
  review: _review,
  sources: _sources,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'rules-vs-learning',
      heading: 'Learning a rule instead of writing one',
      blocks: [
        ProseBlock(
          'Ordinary programming is a chain of rules you author by hand: you '
          'know the logic that turns an input into an output, and you write it '
          'down. Machine learning inverts that. You supply examples of inputs '
          'paired with the outputs you want, and an algorithm searches for a '
          'rule that reproduces them. The program is still a function from '
          'input to output — it is just that its details were fitted rather '
          'than typed.',
        ),
        ProseBlock(
          'This trade is worth making exactly when the rule is easy to '
          'demonstrate and hard to state. You can label ten thousand emails as '
          'spam or not spam far more easily than you can enumerate the '
          'conditions that make an email spam, and any list of conditions you '
          'did write would be stale within a month. Where the rule is crisp and '
          'stable — value-added tax, a date format, a chess move\'s legality — '
          'writing it directly is cheaper, more accurate and easier to debug.',
        ),
        ProseBlock(
          'Artificial intelligence is the wide umbrella: any system that '
          'performs tasks we associate with human intelligence, including '
          'hand-authored search and logic systems that do no learning at all. '
          'Machine learning is the subset that improves from data. Deep '
          'learning is in turn the subset of machine learning that uses '
          'many-layered neural networks. Every deep learning system is machine '
          'learning; not every AI system is.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Rules you write: every condition is explicit, and every gap is yours.
def is_spam_by_rules(email):
    if "wire transfer" in email.body.lower():
        return True
    if email.exclamation_count > 8 and email.sender_is_unknown:
        return True
    return False


# Rules that are fitted: you supply examples, not conditions.
model = SpamClassifier()
model.fit(train_emails, train_labels)   # learn from 10,000 labelled examples
model.predict(new_email)                # -> 0.93 probability of spam
''',
          caption:
              'Same signature, opposite authorship: one rule is written, the '
              'other is inferred.',
        ),
      ],
    ),
    Section(
      id: 'vocabulary',
      heading: 'The five words everything else is built from',
      blocks: [
        ProseBlock(
          'A **feature** is one measured input — the word count of an email, '
          'the square metres of a flat, a pixel\'s brightness. A **label** (or '
          'target) is the answer you want predicted. An **example** is one '
          'row: a feature vector plus, in supervised settings, its label. A '
          '**model** is the function that maps features to a prediction, and '
          'its **parameters** are the numbers inside it that training adjusts.',
        ),
        ProseBlock(
          'Keep parameters and hyperparameters apart, because interviews and '
          'bug reports both hinge on the difference. Parameters are learned '
          'from the data: the weights of a linear model, the entries of a '
          'neural network\'s matrices. Hyperparameters are chosen by you '
          'before training and are not touched by the optimiser: the learning '
          'rate, the number of layers, the tree depth, how long you train.',
        ),
        ProseBlock(
          'The last word is the important one. **Generalisation** is '
          'performance on data the model has never seen. It is the only thing '
          'that matters. A model that reproduces its training set perfectly '
          'and fails on tomorrow\'s inputs has learned the examples rather '
          'than the pattern, and is worth nothing in production.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np

# Three examples, two features each: [rooms, square_metres]
X = np.array([
    [2,  55.0],
    [3,  74.0],
    [4, 102.0],
])

# One label per example: price in thousands
y = np.array([210.0, 295.0, 380.0])

print(X.shape)   # (3, 2)  -> (n_examples, n_features)
print(y.shape)   # (3,)    -> one target per row

# A model is a function with parameters. Here: price = w . x + b
w = np.array([12.0, 2.5])   # parameters, to be learned
b = 20.0                    # parameter (the bias / intercept)

prediction = X @ w + b
print(prediction)   # [181.5 241.  308. ]  - untrained, so quite wrong
''',
          caption:
              'The (n_examples, n_features) matrix is the standard shape of a '
              'dataset.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Features are a design decision, not a given',
          text:
              'Choosing and transforming inputs — feature engineering — often '
              'moves accuracy more than swapping algorithms does. Deep '
              'learning reduces this work by learning representations from raw '
              'signals, but it does not remove it: what you feed the model '
              'still bounds what it can possibly learn.',
        ),
      ],
    ),
    Section(
      id: 'splits',
      heading: 'Train, validation and test: three sets, three jobs',
      blocks: [
        ProseBlock(
          'Because generalisation is what you care about, you must measure it '
          'on data the model has not learned from. The standard arrangement is '
          'three disjoint splits. The **training set** fits the parameters. '
          'The **validation set** compares candidates — architectures, '
          'hyperparameters, how long to train. The **test set** is touched '
          'once, at the end, to estimate performance on new data.',
        ),
        ProseBlock(
          'The reason for a separate validation set is subtle and expensive to '
          'learn the hard way. Every time you look at a score and change '
          'something in response, you leak a little information from that set '
          'into your model. Do it fifty times against the test set and your '
          'final number is an optimistic fiction — you have fitted the test '
          'set with your own hands, one decision at a time.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from sklearn.model_selection import train_test_split

# 60 / 20 / 20 in two steps: carve off the test set first, then split the rest.
X_rest, X_test, y_rest, y_test = train_test_split(
    X, y, test_size=0.2, random_state=0
)
X_train, X_val, y_train, y_val = train_test_split(
    X_rest, y_rest, test_size=0.25, random_state=0   # 0.25 of 80% = 20%
)

model.fit(X_train, y_train)              # parameters come from here
score = model.score(X_val, y_val)        # decisions come from here
final = model.score(X_test, y_test)      # reported once, never optimised against
''',
          caption:
              'random_state fixes the shuffle so the same rows land in the '
              'same split on every run.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Random splits lie about time series and grouped data',
          text:
              'If rows have an order (stock prices, user sessions) a random '
              'split lets the model train on the future and be tested on the '
              'past — an inflated score that evaporates in production. Split '
              'by time for temporal data, and by group (patient, user, '
              'document) whenever several rows share a source.',
        ),
      ],
    ),
    Section(
      id: 'fit',
      heading: 'Underfitting, overfitting and the gap between the curves',
      blocks: [
        ProseBlock(
          'A model **underfits** when it is too simple to capture the pattern: '
          'training error and validation error are both high and close '
          'together. It **overfits** when it has enough capacity to memorise '
          'noise: training error keeps falling while validation error flattens '
          'and then rises. The gap between the two curves is the diagnostic, '
          'not the absolute value of either.',
        ),
        ProseBlock(
          'The traditional framing is the bias–variance trade-off. Bias is '
          'error from wrong assumptions — a straight line fitted to a curve. '
          'Variance is sensitivity to the particular training sample — a model '
          'that would look completely different had you drawn different rows. '
          'Simple models are high bias and low variance; flexible ones are the '
          'reverse, and your job is to find the useful middle.',
        ),
        ProseBlock(
          'The fixes differ by direction, so diagnose before you act. '
          'Underfitting wants more capacity, better features or longer '
          'training. Overfitting wants more data, fewer parameters, '
          'regularisation, or an earlier stop. Reaching for regularisation '
          'when the model is underfitting makes things strictly worse.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# A fitted polynomial of increasing degree on the same 20 noisy points.
for degree in (1, 4, 15):
    model = make_polynomial_model(degree)
    model.fit(X_train, y_train)
    print(
        degree,
        round(mse(y_train, model.predict(X_train)), 3),
        round(mse(y_val, model.predict(X_val)), 3),
    )

# degree   train_mse   val_mse
# 1         8.412       8.907    <- underfit: both high, gap small
# 4         0.930       1.104    <- about right
# 15        0.004      42.660    <- overfit: train near zero, val exploded
''',
          caption:
              'Read the two columns together; either one alone tells you '
              'nothing.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: why more data helps overfitting but not bias',
          children: [
            ProseBlock(
              'Think of training as picking one function out of a set of '
              'candidates your model class can express. Variance is how much '
              'that pick wobbles when the training sample changes; more data '
              'pins the pick down, so variance falls and the train/validation '
              'gap narrows. This is why "get more data" is such reliable '
              'advice for an overfitting model.',
            ),
            ProseBlock(
              'Bias is different in kind. If the true relationship is curved '
              'and your candidate set contains only straight lines, then every '
              'candidate is wrong everywhere, and no amount of extra data adds '
              'a curve to the set. The learning curves show it plainly: with '
              'high bias, training and validation error converge to the same '
              'unacceptable value and then stay flat.',
            ),
            ProseBlock(
              'Modern over-parameterised networks complicate the classical '
              'picture — they can interpolate the training data exactly and '
              'still generalise, an effect known as double descent — but the '
              'diagnostic habit survives intact. Plot error against training '
              'set size and against training time, and let the shape of the '
              'curves tell you which problem you have.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
sizes = [50, 100, 200, 400, 800, 1600]
for n in sizes:
    model.fit(X_train[:n], y_train[:n])
    print(n, mse(y_train[:n], model.predict(X_train[:n])),
             mse(y_val, model.predict(X_val)))

# Curves converge to a high value      -> bias; more data will not help.
# Curves converge, val still falling   -> variance; more data will help.
''',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'lifecycle',
      heading: 'What an ML project actually looks like',
      blocks: [
        ProseBlock(
          'Choosing an algorithm is a small slice of the work. A project '
          'begins by framing the task: what decision will this prediction '
          'change, and what does a mistake cost? Then comes the data — '
          'collecting it, cleaning it, understanding how it was produced, '
          'splitting it honestly. Only then is there a model to train, '
          'evaluate against a sensible baseline, deploy and monitor.',
        ),
        ProseBlock(
          'Always build the dumb baseline first. Predict the mean for a '
          'regression, predict the most common class for a classification, or '
          'reuse whatever rule the business already applies. A baseline turns '
          'an unanchored accuracy figure into a comparison, and it '
          'occasionally reveals that the modelling was never necessary.',
        ),
        ProseBlock(
          'Deployment is not the end, because the world drifts. The '
          'distribution of inputs shifts, the relationship between inputs and '
          'labels shifts, and a model that was excellent in March can be '
          'mediocre by September without a single line of code changing. '
          'Monitoring inputs and outputs in production is part of the system, '
          'not an optional extra.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Pick the metric before you train anything',
          text:
              'On a dataset that is 99% negative, a model that always answers '
              '"negative" scores 99% accuracy and is useless. Decide up front '
              'what you optimise — precision, recall, F1, calibrated '
              'probability, revenue — based on which error hurts more. The '
              'metric is a product decision wearing a statistical costume.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-ai-terms-classify',
      title: 'Sort the vocabulary',
      prompt: [
        ProseBlock(
          'Below is a list of the things floating around a training script. '
          'Classify each one as a feature, a label, a parameter or a '
          'hyperparameter by filling in the dictionary. The test at the bottom '
          'checks your answers.',
        ),
        ProseBlock(
          'The distinction to be careful about: anything the optimiser changes '
          'during training is a parameter; anything you fix before training '
          'starts is a hyperparameter.',
        ),
      ],
      starterCode: '''
items = [
    "square_metres_of_the_flat",
    "sale_price_we_want_to_predict",
    "the_weight_multiplying_square_metres",
    "the_learning_rate",
    "number_of_hidden_layers",
    "the_bias_term",
]

# TODO: map each item to one of: feature, label, parameter, hyperparameter
kinds = {
    "square_metres_of_the_flat": "?",
}

for name, kind in kinds.items():
    print(f"{name:35} {kind}")
''',
      solutionCode: '''
items = [
    "square_metres_of_the_flat",
    "sale_price_we_want_to_predict",
    "the_weight_multiplying_square_metres",
    "the_learning_rate",
    "number_of_hidden_layers",
    "the_bias_term",
]

kinds = {
    "square_metres_of_the_flat": "feature",
    "sale_price_we_want_to_predict": "label",
    "the_weight_multiplying_square_metres": "parameter",
    "the_learning_rate": "hyperparameter",
    "number_of_hidden_layers": "hyperparameter",
    "the_bias_term": "parameter",
}

assert set(kinds) == set(items)
assert sum(k == "parameter" for k in kinds.values()) == 2
assert sum(k == "hyperparameter" for k in kinds.values()) == 2

for name, kind in kinds.items():
    print(f"{name:35} {kind}")
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The bias term and the learning rate are both single numbers. '
              'Why is one a parameter and the other a hyperparameter?',
          expectedAnswer:
              'Because of who sets them. The bias is updated by the optimiser '
              'on every step in order to reduce the loss, so it is learned '
              'from the data. The learning rate is fixed by you before '
              'training and controls how the optimiser behaves; gradient '
              'descent never adjusts it, which is why choosing it well is a '
              'search you run on the validation set.',
        ),
        SelfCheckQuestion(
          question:
              'Could the same quantity be a feature in one problem and a label '
              'in another?',
          expectedAnswer:
              'Yes — feature and label are roles, not properties of the '
              'column. Sale price is the label when you predict prices from '
              'flat attributes, and a feature when you predict, say, how many '
              'days a listing stays on the market. The only thing that changes '
              'is which column you are trying to produce.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-ai-split',
      title: 'Split a dataset honestly',
      prompt: [
        ProseBlock(
          'Write split_three_ways(n, seed) that returns index lists for a '
          '60/20/20 train/validation/test split of n examples. The three lists '
          'must be disjoint, must together cover every index exactly once, and '
          'must be shuffled so that any ordering in the original data does not '
          'survive into the splits.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
train, val, test = split_three_ways(1000, seed=0)
# len(train) == 600, len(val) == 200, len(test) == 200
# no index appears in more than one list
''',
        ),
      ],
      starterCode: '''
import random


def split_three_ways(n, seed=0):
    """Return (train_idx, val_idx, test_idx) as disjoint 60/20/20 lists."""
    # TODO: shuffle the indices with a seeded Random, then slice
    ...


train, val, test = split_three_ways(1000, seed=0)
print(len(train), len(val), len(test))
print(len(set(train) & set(val)), len(set(train) & set(test)))
''',
      solutionCode: '''
import random


def split_three_ways(n, seed=0):
    """Return (train_idx, val_idx, test_idx) as disjoint 60/20/20 lists."""
    indices = list(range(n))
    random.Random(seed).shuffle(indices)     # seeded: reproducible split

    n_train = int(0.6 * n)
    n_val = int(0.2 * n)

    train = indices[:n_train]
    val = indices[n_train:n_train + n_val]
    test = indices[n_train + n_val:]
    return train, val, test


train, val, test = split_three_ways(1000, seed=0)
print(len(train), len(val), len(test))          # 600 200 200
print(len(set(train) & set(val)))               # 0
print(len(set(train) & set(test)))              # 0
print(len(set(train) | set(val) | set(test)))   # 1000
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why seed the shuffle rather than using an unseeded random '
              'order?',
          expectedAnswer:
              'Reproducibility. With a fixed seed, the same rows land in the '
              'same split on every run, so a change in your validation score '
              'can be attributed to the change you made rather than to a '
              'different random partition. Without it you cannot tell '
              'improvement from split noise.',
        ),
        SelfCheckQuestion(
          question:
              'The data is a year of daily sales, sorted by date. What is '
              'wrong with this split, and what would you do instead?',
          expectedAnswer:
              'Shuffling mixes future rows into the training set, so the model '
              'is evaluated on days it has effectively already seen the '
              'context for, and the score will be far better than production. '
              'For temporal data, split by time: train on the earliest months, '
              'validate on the next block, test on the most recent — matching '
              'how the model will actually be used.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-ai-baseline',
      title: 'Beat — or fail to beat — a baseline',
      prompt: [
        ProseBlock(
          'Before any model is worth discussing it must beat a trivial '
          'baseline. Implement majority_class_baseline and mean_baseline, then '
          'compare a "clever" model\'s accuracy against them on an imbalanced '
          'dataset where 95% of labels are 0.',
        ),
      ],
      starterCode: '''
y_true = [0] * 950 + [1] * 50           # 95% negative
model_preds = [0] * 990 + [1] * 10      # a model that rarely predicts 1


def accuracy(y_true, y_pred):
    ...


def majority_class_baseline(y_train):
    """Return the constant prediction a no-skill classifier would make."""
    ...


# TODO: compare the model's accuracy to the baseline's
''',
      solutionCode: '''
from collections import Counter

y_true = [0] * 950 + [1] * 50           # 95% negative
model_preds = [0] * 990 + [1] * 10      # a model that rarely predicts 1


def accuracy(y_true, y_pred):
    correct = sum(t == p for t, p in zip(y_true, y_pred))
    return correct / len(y_true)


def majority_class_baseline(y_train):
    """Return the constant prediction a no-skill classifier would make."""
    return Counter(y_train).most_common(1)[0][0]


def mean_baseline(y_train):
    return sum(y_train) / len(y_train)


constant = majority_class_baseline(y_true)
baseline_preds = [constant] * len(y_true)

print("baseline accuracy:", accuracy(y_true, baseline_preds))   # 0.95
print("model accuracy:   ", accuracy(y_true, model_preds))      # 0.94

# The model is *worse* than predicting the majority class every time.
recall = sum(t == 1 and p == 1 for t, p in zip(y_true, model_preds)) / 50
print("model recall on the positive class:", recall)
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The baseline scores 95% and finds zero positives. What does '
              'that tell you about accuracy as a metric here?',
          expectedAnswer:
              'That it is the wrong metric. Accuracy is dominated by the '
              'majority class, so a model with no ability to detect the thing '
              'you care about still scores highly. On imbalanced data, report '
              'precision and recall on the positive class, or a summary such '
              'as F1 or average precision, and choose between them based on '
              'whether false positives or false negatives cost more.',
        ),
        SelfCheckQuestion(
          question:
              'Why compute the baseline from the training labels rather than '
              'the test labels?',
          expectedAnswer:
              'Because the baseline is itself a model, and a model may only '
              'use information available at training time. Reading the '
              'majority class off the test set leaks the test distribution '
              'into the prediction and produces an optimistic comparison — the '
              'same leakage rule that applies to scaling, imputation and any '
              'other fitted preprocessing step.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 216000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Remember when Netflix recommended a show you ended up loving, '
              'and you thought — how did it know? That is machine learning in a '
              'nutshell. Normal programming is like a recipe: you write down '
              'every step. ML flips that. Instead of writing the rule, you show '
              'thousands of examples — "this person liked these shows" — and an '
              'algorithm figures out the pattern. You do not tell it the taste; '
              'you show it what good taste looks like.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Right, and here is the litmus test. If explaining the rule takes '
              'you two minutes but labelling examples takes two hours, just '
              'write the rule. Think tax calculations — you know the formula, '
              'type it in, done. But spotting spam? You would go mad trying to '
              'list every condition, and spammers would change their tactics '
              'next week. That is where ML earns its keep — when it is way '
              'easier to point at examples than to explain why.',
          startMs: 44000,
          endMs: 92000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Quick vocabulary check. Features are the inputs — like the '
              'square footage and number of bedrooms when predicting house '
              'prices. Labels are the answers — the actual sale price. The '
              'model is the function that connects them. And here is the one '
              'that trips people up: parameters are the knobs the model learns '
              'by itself, like the weight on "number of bedrooms". '
              'Hyperparameters are the knobs you set beforehand — "how many '
              'layers should I use?", "how fast should it learn?". Learned '
              'versus chosen.',
          startMs: 92000,
          endMs: 140000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Now the part that actually matters in practice. '
              'Generalisation — does this model work on examples it has never '
              'seen? Because if it only works on the data you trained it on, '
              'you might as well have written a lookup table. That is why we '
              'hold data back. Think of it like studying for an exam: the '
              'training set is your homework, the validation set is the '
              'practice test you use to see if you are ready, and the test set '
              'is the real final exam — you only get one honest look.',
          startMs: 140000,
          endMs: 190000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And here is the one diagnostic to remember. If your model does '
              'badly on both homework and practice test — you are underfitting, '
              'you need to study harder. If you ace the homework but bomb the '
              'practice test — you memorised the answers instead of '
              'understanding. That is overfitting. And always, always compare '
              'your fancy model against the dumbest possible guess — predicting '
              '"not spam" every single time. You would be shocked how often '
              'that baseline is hard to beat.',
          startMs: 190000,
          endMs: 216000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 498000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Think about the spam folder in your email. For years, engineers '
              'tried to write rules — "if it says wire transfer, flag it", '
              '"if it has eight exclamation marks, flag it". Spammers would '
              'tweak their wording and the rules would break. ML took a '
              'different approach: instead of writing the rules, we showed the '
              'computer millions of emails labelled "spam" or "not spam" and '
              'let it figure out the pattern. That shift — from hand-crafted '
              'rules to patterns learned from examples — is the whole idea.',
          startMs: 0,
          endMs: 54000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'And the terminology gets thrown around loosely, so let me nail '
              'it down. Imagine three concentric circles. The outermost is AI — '
              'artificial intelligence. That includes everything a computer '
              'does that feels smart, even old-school chess engines with '
              'hardcoded strategies and zero learning. The middle circle is '
              'machine learning — the part where the system actually improves '
              'by looking at data. The innermost circle is deep learning — ML '
              'that uses many-layered neural networks. Every deep learning '
              'system is ML, but plenty of AI has nothing to do with learning '
              'at all.',
          startMs: 54000,
          endMs: 118000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Let me ground this with the house-price example. You have '
              'spreadsheet rows — each row is one house. The columns are things '
              'like square metres and number of bedrooms — those are features. '
              'The price you want to predict — that is the label. Together, a '
              'row of features plus its label is an example. And every library '
              'expects the same convention: X is one big matrix, rows are '
              'examples, columns are features. y is a list of labels the same '
              'length. Half of all beginner bugs are a shape mismatch — mixing '
              'up which axis is which.',
          startMs: 118000,
          endMs: 176000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'And picking the right features is where the real skill is. '
              'Hand a model a raw timestamp and it learns almost nothing. '
              'Extract "day of the week" and "hour of the day" from that same '
              'timestamp and suddenly the weekly rhythm of the data becomes '
              'learnable. This is feature engineering — you are translating '
              'raw data into a form the model can actually use. Deep learning '
              'reduces this work because it learns its own features from raw '
              'pixels or text, but the principle never goes away: the model '
              'cannot use information you never gave it.',
          startMs: 176000,
          endMs: 244000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Now the discipline of holding data back, and here is a metaphor '
              'that sticks. Imagine you are studying for a history exam. You '
              'read the textbook and do the homework — that is your training '
              'set. You take a practice test to see if you are ready — that is '
              'your validation set. The real final exam is the test set, and '
              'you only take it once. If after the practice test you peek at '
              'the final exam questions and adjust your studying, that final '
              'grade is no longer honest. ML works the same way: every time you '
              'look at test-set performance and change something in response, '
              'you have contaminated that score.',
          startMs: 244000,
          endMs: 314000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'There is a catch with random splits, and it bites people in '
              'production. A random split assumes every row of your data is '
              'independent — like shuffled cards. But imagine you are '
              'predicting tomorrow\'s stock price. Shuffle the data randomly, '
              'and the model gets to see next week\'s prices while training on '
              'last week\'s — it learns from the future! Or picture medical '
              'data where one patient contributed twenty different scans. '
              'Shuffle those, and some scans from the same patient land in '
              'both training and test. The model just learns to recognise that '
              'specific patient, not the disease. For time data, split by '
              'date. For grouped data, keep each group entirely on one side.',
          startMs: 314000,
          endMs: 380000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Here is the most practical diagnostic in all of ML. Plot two '
              'lines: training error and validation error. If both are high and '
              'close together — like a student who does not understand the '
              'material and scores badly on both homework and practice — you '
              'are underfitting. The model is too simple. Add more capacity. '
              'But if training error is near zero and validation error is '
              'climbing — like the student who memorised every homework answer '
              'but cannot solve a new problem — that is overfitting. The model '
              'learned the noise, not the signal. The gap between those two '
              'curves is the whole diagnostic.',
          startMs: 380000,
          endMs: 444000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And here is my favourite sanity check, the one I wish every '
              'team did before presenting results. Before you train anything '
              'fancy, build the dumbest possible baseline. For a yes-or-no '
              'problem where 95% of the answers are "no", just guess "no" '
              'every single time. That scores 95% accuracy and catches zero '
              'actual problems. If your sophisticated model cannot beat that '
              'trivial baseline, it is worthless — no matter how impressive the '
              'architecture sounds. Choose your metric based on what a mistake '
              'actually costs you, not on what looks good in a slide deck.',
          startMs: 444000,
          endMs: 498000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 846000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Welcome to the deep dive. Picture yourself at a farmers\' '
              'market trying to guess the price of produce just by looking at '
              'it. You see enough tomatoes sell that you start to get a feel '
              'for what size and colour mean for price. That is learning from '
              'data — and in the next forty minutes we are going to unpack '
              'exactly what that means, from the foundational assumptions '
              'through the vocabulary, the bias-variance picture, why modern '
              'networks complicate the classical story, and what actually goes '
              'wrong when models hit the real world.',
          startMs: 0,
          endMs: 62000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Let us start with the assumption that everything else rests on. '
              'When you train an ML model, you are quietly betting that your '
              'training data and future data come from the same hidden '
              'distribution — the same underlying pattern. Your tomato prices '
              'from last summer should be governed by the same rules as this '
              'summer\'s. All of statistical learning theory rests on that bet. '
              'And almost every dramatic production failure — the model that '
              'worked beautifully in the lab and fell apart at launch — is '
              'that assumption quietly ceasing to be true.',
          startMs: 62000,
          endMs: 140000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Given that assumption, learning becomes a search problem. Think '
              'of it like choosing a pair of glasses. You have a drawer full '
              'of lenses — that is your hypothesis space, the family of '
              'functions your model can represent. Maybe it is all straight '
              'lines, or all depth-five decision trees, or all networks of a '
              'given architecture. Training means trying on lenses until you '
              'find the one that makes the data look clearest. Two choices '
              'define your learner: which drawer of lenses you open, and how '
              'you measure whether things look sharp.',
          startMs: 140000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Which brings us to a result that sounds deeply philosophical '
              'but is intensely practical — the no-free-lunch theorem. '
              'Averaged over every possible problem in the universe, no '
              'learning algorithm beats any other. Flip a coin, consult a '
              'fortune cookie — same expected performance. That sounds '
              'nihilistic, but the practical reading is liberating: every '
              'useful algorithm works because it encodes assumptions about '
              'which patterns are likely. Convolutions assume nearby pixels '
              'matter more than faraway ones — that is why they dominate '
              'image tasks and flop on spreadsheet data. The art is matching '
              'your algorithm\'s assumptions to your data\'s structure.',
          startMs: 214000,
          endMs: 292000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Vocabulary time, but with the precision that separates a '
              'conversation from confusion. A feature is one input dimension — '
              'the weight of the tomato, the colour intensity. A label is what '
              'you want predicted — the price. An example is one row: feature '
              'vector plus, in supervised settings, its label. Parameters are '
              'the numbers inside the model that training adjusts — think of '
              'them as the dials the optimiser turns. Hyperparameters are the '
              'dials you turn before training even starts: how many layers, '
              'how fast to learn, how long to keep going. And capacity is how '
              'rich your hypothesis space is — how complicated a relationship '
              'you could possibly represent, given enough data.',
          startMs: 292000,
          endMs: 366000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Now generalisation, properly. Here is the uncomfortable truth: '
              'the training error is the only number you can directly measure. '
              'The generalisation error — how wrong you will be on tomorrow\'s '
              'data — is what you actually care about and can only estimate. '
              'And that estimate is honest exactly once. The very first time '
              'you evaluate a model on data it never saw, your score is an '
              'unbiased guess at real-world performance. The moment you look '
              'at that score and change anything — tweak a hyperparameter, '
              'switch architectures — you have started fitting to that set. It '
              'is now contaminated. Every subsequent decision informed by that '
              'set gradually converts it into just another training set.',
          startMs: 366000,
          endMs: 442000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'And this, right here, is the real argument for three splits '
              'instead of two, and for cross-validation when data is tight. '
              'Imagine you only have twenty tomatoes to learn from. A single '
              'validation split of five tomatoes could be a really weird five — '
              'all the expensive ones, say — and you would never know. K-fold '
              'cross-validation solves this by rotating which tomatoes get held '
              'out: train on sixteen, test on four, repeat five times with '
              'different groups. You get five scores whose average is much more '
              'trustworthy and whose spread tells you how much to trust it. '
              'The cost is training five models instead of one, which is why '
              'we cross-validate on small datasets and skip it when a single '
              'run takes days.',
          startMs: 442000,
          endMs: 516000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Leakage deserves its own moment because it is the silent killer '
              'of ML projects. Picture this: you are training a model to '
              'predict house prices, and you normalise all your data — compute '
              'the average square footage and spread — before splitting. '
              'Congratulations, information about the test houses has leaked '
              'into your training pipeline. Your validation score is now '
              'contaminated before you have even picked a model. The rule is '
              'simple but brutal: any preprocessing step that learns from '
              'data — scaling, imputing missing values, encoding categories — '
              'must be fitted on the training fold only. Fit on train, apply '
              'to everything else. If you fit a scaler on the whole dataset, '
              'you might as well have let the model peek at the answers.',
          startMs: 516000,
          endMs: 596000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'The classical decomposition of error is worth knowing because '
              'it frames every debugging conversation. Expected error splits '
              'into three pieces: bias squared, variance, and irreducible '
              'noise. Bias is being systematically wrong — like trying to fit '
              'a straight line to a curve. No amount of data fixes bias '
              'because every line you try is wrong everywhere. Variance is '
              'being unstable — your model would look completely different if '
              'you had drawn a different training sample. Noise is the floor — '
              'even the perfect model cannot predict better than the inherent '
              'randomness in the data. And knowing that floor exists stops you '
              'from chasing an accuracy that was never physically available.',
          startMs: 596000,
          endMs: 676000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Modern practice complicates this clean picture deliciously. '
              'Very large neural networks — the kind with more parameters than '
              'training examples — can fit their training data perfectly and '
              'still generalise beautifully. That directly contradicts the '
              'classical story where "memorising training data" and '
              '"generalising to new data" were opposites. There is even the '
              'double descent phenomenon: as you make the model bigger, test '
              'error goes down, then up, then down again past the point where '
              'it can memorise everything. So capacity alone is a terrible '
              'predictor of generalisation for modern networks. The practical '
              'habit that survives intact: plot learning curves and let the '
              'shapes tell you what to change, not the folklore.',
          startMs: 676000,
          endMs: 752000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Finally, deployment — where models go to quietly die. Two '
              'things happen. Data drift: the inputs change distribution. '
              'Maybe your customers started using the app differently, or the '
              'camera on the new iPhone captures images your model never '
              'trained on. Concept drift: the relationship between inputs and '
              'labels changes. What counted as spam in 2019 is not what counts '
              'as spam today. Both silently degrade a frozen model with zero '
              'code changes and zero visible errors. And feedback loops are '
              'worse: a recommendation system trained on what it previously '
              'showed narrows the world it observes until it is only learning '
              'from its own past decisions. You have to monitor, retrain, and '
              'never assume yesterday\'s accuracy survives today.',
          startMs: 752000,
          endMs: 822000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'So, the summary to carry forward. Assume your data comes from '
              'a stable hidden pattern — and verify that assumption regularly. '
              'Search a hypothesis family for a member that fits your examples '
              'well. Keep an honest holdout that nobody touches until the end. '
              'Read the gap between training and validation error — it is your '
              'diagnostic, not a number to hide. And monitor production as if '
              'the world will shift under you, because it absolutely will.',
          startMs: 822000,
          endMs: 846000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Fitted rules, not written ones',
      body:
          'Machine learning replaces hand-authored logic with a function '
          'fitted to examples. It pays off when the rule is easy to '
          'demonstrate and hard to state; when the rule is crisp and stable, '
          'writing it directly is cheaper and easier to debug. AI is the '
          'umbrella, ML the data-driven subset, deep learning the '
          'many-layered-network subset of that.',
    ),
    SummaryCard(
      title: 'Generalisation is the only score that counts',
      body:
          'Performance on unseen data is the goal, so hold data back: the '
          'training set fits parameters, the validation set drives your '
          'decisions, and the test set is opened once. Random splits assume '
          'independent rows — split by time or by group when they are not.',
    ),
    SummaryCard(
      title: 'Diagnose from two curves, then act',
      body:
          'Both training and validation error high and close means '
          'underfitting: add capacity or better features. Training error near '
          'zero with validation error rising means overfitting: add data, cut '
          'capacity, regularise or stop earlier. Compare everything against a '
          'trivial baseline and a metric chosen from what errors cost.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Feature / label',
      definition:
          'A feature is one measured input dimension; the label is the target '
          'to be predicted. They are roles rather than intrinsic properties — '
          'the same column can be either, depending on the task.',
    ),
    KeyConcept(
      term: 'Parameter vs hyperparameter',
      definition:
          'Parameters (weights, biases) are learned by the optimiser from the '
          'data. Hyperparameters (learning rate, depth, epochs) are fixed '
          'before training and are searched over using the validation set.',
    ),
    KeyConcept(
      term: 'Generalisation',
      definition:
          'Performance on examples drawn from the same distribution but never '
          'seen during training. The quantity every design decision is '
          'ultimately trying to improve, and the reason for holdout data.',
    ),
    KeyConcept(
      term: 'Overfitting / underfitting',
      definition:
          'Overfitting is fitting noise: low training error, high validation '
          'error, a wide gap. Underfitting is insufficient capacity: both '
          'errors high and close together.',
    ),
    KeyConcept(
      term: 'Bias–variance trade-off',
      definition:
          'Bias is systematic error from a hypothesis space too restricted to '
          'express the truth; variance is instability caused by sensitivity to '
          'the particular training sample. Reducing one typically increases '
          'the other.',
    ),
    KeyConcept(
      term: 'Data leakage',
      definition:
          'Information from outside the training fold influencing the model — '
          'a scaler fitted on all rows, a feature computed from the future, or '
          'duplicated records straddling a split. It inflates validation '
          'scores and collapses in production.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Reporting accuracy on an imbalanced dataset and calling 95% a '
          'success.',
      correction:
          'If 95% of labels are negative, always-negative scores 95% and finds '
          'nothing. Report precision and recall on the class you care about, '
          'or a summary metric such as F1 or average precision, and always '
          'quote the majority-class baseline alongside.',
    ),
    Mistake(
      mistake:
          'Fitting a scaler or imputer on the whole dataset before splitting.',
      correction:
          'Statistics from validation and test rows leak into the training '
          'transformation, so the score is optimistic. Fit every learned '
          'preprocessing step on the training fold and apply it to the others '
          '— a Pipeline makes this the default behaviour.',
    ),
    Mistake(
      mistake:
          'Tuning hyperparameters against the test set until the number looks '
          'good.',
      correction:
          'Each decision made in response to a test score leaks that set into '
          'the model, so the final figure measures your persistence rather '
          'than generalisation. Tune on validation data and evaluate on test '
          'once, at the end.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'When would you not use machine learning for a problem?',
      answer:
          'When the rule is known, stable and cheap to express — tax bands, '
          'validation logic, deterministic business policy — because a written '
          'rule is exact, auditable and free to run. Also when there is no '
          'meaningful labelled data, when the cost of a wrong answer is high '
          'and unexplainable predictions are unacceptable, or when a simple '
          'heuristic already meets the requirement. Machine learning adds a '
          'data pipeline, a monitoring burden and a source of silent failure, '
          'so it should earn its place against a baseline.',
    ),
    InterviewQuestion(
      question:
          'Explain the difference between overfitting and underfitting, and '
          'how you would detect and address each.',
      answer:
          'Underfitting is when the model cannot represent the underlying '
          'pattern: training and validation error are both high and roughly '
          'equal. Overfitting is when it has fitted noise specific to the '
          'training sample: training error is low while validation error is '
          'much higher, and the gap grows with training. You detect both by '
          'tracking the two errors together, ideally as learning curves '
          'against dataset size and epochs. Underfitting is treated with more '
          'capacity, richer features or longer training; overfitting with more '
          'data, regularisation, fewer parameters, augmentation or early '
          'stopping.',
    ),
    InterviewQuestion(
      question:
          'What is data leakage and how do you prevent it?',
      answer:
          'Leakage is any information reaching the model that would not be '
          'available at prediction time, which makes offline scores '
          'unrealistically good. Common forms are fitting preprocessing on all '
          'the data, features derived from the target or from the future, '
          'duplicate or near-duplicate rows spanning splits, and grouped '
          'records — several rows from one user or patient — appearing on both '
          'sides. Prevention is procedural: split first, wrap all fitted '
          'transformations in a pipeline that only sees the training fold, '
          'split by time for temporal data and by group where rows share a '
          'source, and treat a surprisingly high score as a leak hypothesis '
          'until disproved.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'Machine Learning Crash Course',
    url: 'https://developers.google.com/machine-learning/crash-course',
    description:
        'Google\'s introductory course covering framing, features and labels, '
        'training and test splits, generalisation and overfitting.',
  ),
  Source(
    title: 'What is Machine Learning? | IBM',
    url: 'https://www.ibm.com/think/topics/machine-learning',
    description:
        'An overview of how machine learning relates to AI and deep learning, '
        'with the main learning paradigms and where each is applied.',
  ),
];
