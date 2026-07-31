import '../../models/content_block.dart';
import '../../models/exercise.dart';
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
              'Machine learning in about four minutes. Normal programming: you '
              'know the rule, you write it down. Machine learning: you do not '
              'know the rule, but you can show a lot of examples of it, and an '
              'algorithm fits a function that reproduces them. That is the '
              'entire trade.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'And it is only worth taking when the rule is easy to '
              'demonstrate and hard to state. Spam, handwriting, speech — you '
              'can label those all day and never write the conditions. VAT '
              'calculation? Just write the rule. A learned VAT model would be '
              'slower, less accurate, and impossible to audit.',
          startMs: 44000,
          endMs: 92000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Vocabulary. Features are the inputs, labels are the answers, '
              'the model is the function between them. Parameters are the '
              'numbers training adjusts. Hyperparameters are the numbers you '
              'fix before training: learning rate, layer count, tree depth. '
              'Learned versus chosen — that is the split.',
          startMs: 92000,
          endMs: 140000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'The thing that actually matters is generalisation: how it does '
              'on data it has never seen. Which is why you hold data back. '
              'Train set fits the parameters, validation set makes your '
              'decisions, test set gets touched once at the very end. Every '
              'time you tune against a set, you burn a little of its honesty.',
          startMs: 140000,
          endMs: 190000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And the one diagnostic: look at training and validation error '
              'together. Both high means underfitting, add capacity. Training '
              'near zero and validation climbing means overfitting, add data '
              'or regularisation. And always compare against the dumbest '
              'possible baseline before you believe any number.',
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
              'Let us start by deflating the word intelligence. A machine '
              'learning model is a function with a lot of adjustable numbers '
              'in it, and training is a search for numbers that make the '
              'function agree with examples you have collected. That is a '
              'genuinely powerful idea, and it is also all that is happening.',
          startMs: 0,
          endMs: 54000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The nesting is worth getting right because people use the terms '
              'interchangeably and they are not. AI is the outer circle — any '
              'system doing something we consider intelligent, including '
              'hand-written search and logic with no learning at all. Machine '
              'learning is the subset that improves from data. Deep learning '
              'is the subset of that using many-layered neural networks.',
          startMs: 54000,
          endMs: 118000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Then the dataset. Rows are examples, columns are features, and '
              'the column you want predicted is the label. Almost every '
              'library expects an X of shape n-examples by n-features and a y '
              'of length n-examples. Half of all beginner errors are a shape '
              'mismatch, and getting fluent with that convention removes them.',
          startMs: 118000,
          endMs: 176000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Feature choice does more work than people expect. Give a model '
              'a timestamp and it learns very little; give it day-of-week and '
              'hour-of-day and suddenly the weekly rhythm is learnable. Deep '
              'learning reduces this hand-crafting by learning representations '
              'from raw pixels or text, but it never removes the truth '
              'underneath: the model cannot use information you never gave it.',
          startMs: 176000,
          endMs: 244000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Now the discipline of splits. Three sets, three distinct jobs. '
              'Training fits parameters. Validation is where you compare '
              'candidates and tune hyperparameters. Test is a sealed envelope '
              'you open once. If you tune against the test set, your final '
              'number stops being a prediction of production performance and '
              'becomes a description of how hard you tried.',
          startMs: 244000,
          endMs: 314000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'With a caveat: a random split assumes rows are independent. '
              'Time series are not — shuffle them and you train on the future. '
              'Grouped data is not either: if one patient contributes twenty '
              'scans and they land on both sides of the split, you are '
              'measuring how well the model recognises that patient, not the '
              'disease. Split by time, or by group.',
          startMs: 314000,
          endMs: 380000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Underfitting and overfitting are read from two curves, not one '
              'number. Both errors high and close together: the model is too '
              'simple, give it more capacity or better features. Training '
              'error near zero with validation error rising: it is memorising, '
              'so add data, cut capacity, regularise, or stop earlier. The '
              'gap is the signal.',
          startMs: 380000,
          endMs: 444000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And finish where a project should start: the baseline and the '
              'metric. Predict the mean, or the majority class, and see what '
              'that scores. On data that is ninety-five percent negative, '
              'always-negative gets ninety-five percent accuracy and finds '
              'nothing. Choose the metric from what the errors cost, before '
              'you train, and the whole project gets easier to argue about.',
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
              'The long version. We are going to build up from what learning '
              'from data even means, through the assumptions that make it '
              'possible, into the vocabulary, the splitting discipline, the '
              'bias-variance picture, why that picture is incomplete for '
              'modern networks, and what actually goes wrong in deployed '
              'systems.',
          startMs: 0,
          endMs: 62000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with the assumption underneath everything. We assume '
              'there is some fixed but unknown distribution generating our '
              'data, and that training and future examples are drawn from the '
              'same one. All the theory rests on that. Almost every dramatic '
              'production failure is that assumption quietly ceasing to hold.',
          startMs: 62000,
          endMs: 140000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Given the assumption, learning is optimisation over a '
              'hypothesis space. You pick a family of functions — all lines, '
              'all depth-five trees, all networks of a given architecture — '
              'and search within it for the member that best matches your '
              'examples. Two choices define a learner: which family, and how '
              'you measure "best".',
          startMs: 140000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Which brings up the no-free-lunch result: averaged over all '
              'possible problems, no learner beats any other. That sounds '
              'nihilistic but the reading is practical — every useful '
              'algorithm encodes assumptions about which patterns are likely, '
              'and it works when those assumptions match your data. '
              'Convolutions assume locality and translation invariance. That '
              'is why they suit images and not tabular data.',
          startMs: 214000,
          endMs: 292000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Vocabulary, precisely. A feature is one input dimension. A '
              'label is the target. An example is a feature vector plus its '
              'label. Parameters are internal numbers fitted by the optimiser. '
              'Hyperparameters are configuration you fix beforehand. And '
              'capacity is how rich the hypothesis space is — how complicated '
              'a relationship the model could represent if the data demanded '
              'it.',
          startMs: 292000,
          endMs: 366000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Now generalisation properly. Training error is what you can '
              'measure; generalisation error is what you want and can only '
              'estimate. The estimate is unbiased exactly once — the first '
              'time you evaluate on data you have made no decisions from. '
              'Every subsequent decision informed by that set converts it, '
              'gradually, into another training set.',
          startMs: 366000,
          endMs: 442000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'That is the real argument for three splits rather than two, and '
              'for cross-validation when data is scarce. K-fold gives you k '
              'estimates from the same rows by rotating which fold is held '
              'out, which shrinks the variance of your comparison. It costs k '
              'times the compute, and it does not license you to peek at the '
              'test set afterwards.',
          startMs: 442000,
          endMs: 516000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Leakage deserves its own warning because it is the most common '
              'way a project silently fails. Any preprocessing that learns '
              'from data — a scaler\'s mean, an imputer\'s median, a target '
              'encoding — must be fitted on the training fold only and then '
              'applied to the others. Fit a scaler on the whole dataset and '
              'the validation score is contaminated before a model has even '
              'been chosen.',
          startMs: 516000,
          endMs: 596000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'The classical decomposition: expected error splits into bias '
              'squared, variance, and irreducible noise. Bias is being '
              'systematically wrong because your family cannot express the '
              'truth. Variance is being unstable because your fit depends '
              'heavily on which rows you happened to draw. Noise is the floor '
              'nothing removes — and knowing that floor exists stops you '
              'chasing an accuracy that was never available.',
          startMs: 596000,
          endMs: 676000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Modern practice complicates it. Very large networks can fit '
              'training data exactly and still generalise well, and test error '
              'sometimes falls again past the interpolation point — double '
              'descent. So capacity alone is a poor predictor of '
              'generalisation. The practical habit survives, though: plot '
              'learning curves and let the shapes, not the folklore, tell you '
              'what to change.',
          startMs: 676000,
          endMs: 752000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Finally, deployment. Data drift is the inputs changing '
              'distribution; concept drift is the relationship between inputs '
              'and label changing. Both degrade a frozen model with no code '
              'change and no error in the logs. And feedback loops are worse: '
              'a recommender trained on what it previously showed can narrow '
              'the world it observes until it is only learning from itself.',
          startMs: 752000,
          endMs: 822000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'So the summary: assume a stable distribution, search a '
              'hypothesis family for a good fit, keep an honest holdout, read '
              'the gap between training and validation error, and monitor '
              'production as if the distribution will move — because it will.',
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
