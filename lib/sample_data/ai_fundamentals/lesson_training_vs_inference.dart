import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 2: the two phases of a model's life, and how to find out
/// whether the learning phase actually worked.
const Lesson trainingVsInferenceLesson = Lesson(
  id: 'ai-training-vs-inference',
  title: 'Training vs. Inference',
  description:
      'Fitting a model versus serving it — held-out splits, cross-validation '
      'and learning curves, and why every number you quote must come from data '
      'the model has never seen.',
  estimatedMinutes: 34,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  play: GameContent(games: <Game>[]),
  review: _review,
  sources: _sources,
  furtherReading: _furtherReading,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'two-phases',
      heading: 'Training and inference are two different jobs',
      blocks: [
        ProseBlock(
          'A model has two modes of existence. During **training** it is '
          'plastic: data flows in, a loss measures how wrong the current '
          'predictions are, and the parameters move to reduce that loss. '
          'During **inference** it is frozen: data flows in, one forward pass '
          'computes an output, and nothing about the model changes. Same '
          'arithmetic in the forward direction, completely different purpose '
          'and completely different constraints.',
        ),
        ProseBlock(
          'What changes during training is only the parameters — the weights '
          'and biases. The architecture, the feature definitions, the '
          'hyperparameters such as learning rate and depth are all fixed before '
          'the run starts; they are chosen by you, not learned. At serve time '
          'even the parameters are fixed, so the only thing varying is the '
          'input.',
        ),
        ProseBlock(
          'The constraints diverge sharply. Training is compute-heavy and '
          'latency-tolerant: it happens once, or nightly, or whenever the data '
          'drifts, and nobody is waiting on it. Inference is compute-light per '
          'call and latency-critical: it may happen millions of times a day, '
          'often inside a request a user is sitting in front of. A model that '
          'takes six hours to train and four milliseconds to answer is '
          'completely normal, and the four milliseconds is the number your '
          'product actually feels.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from sklearn.ensemble import GradientBoostingRegressor

model = GradientBoostingRegressor(n_estimators=300, max_depth=3)

# TRAINING: parameters are written. Expensive, done once.
model.fit(X_train, y_train)          # ~41 s on 60,000 rows

# INFERENCE: parameters are read. Cheap, done constantly.
model.predict(X_new)                 # ~0.6 ms for a single row

# The fitted parameters are the artefact you ship, not the training script.
import joblib
joblib.dump(model, "price_model.joblib")     # 4.2 MB
served = joblib.load("price_model.joblib")   # loads once at process start
''',
          caption:
              'fit writes the parameters; predict only reads them. Everything '
              'after deployment is the second line.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Preprocessing belongs to both phases',
          text:
              'A scaler or encoder learns statistics during training — means, '
              'standard deviations, category vocabularies — and must apply '
              'exactly those same numbers at inference. Ship the fitted '
              'transformer alongside the model, or wrap both in a Pipeline. '
              'Recomputing the mean on live traffic is one of the most common '
              'ways a model that scored well silently degrades in production.',
        ),
      ],
    ),
    Section(
      id: 'splitting',
      heading:
          'Train, validation, test — and why you never score on training '
          'data',
      blocks: [
        ProseBlock(
          'A model with enough capacity can memorise its training set. A '
          'lookup table that stores every training row and returns its label '
          'scores one hundred percent on that data and is worthless on anything '
          'else. So training performance measures memorisation and '
          'generalisation together, with no way to separate them. Only data the '
          'model has never seen can tell you which one you got.',
        ),
        ProseBlock(
          'Hence the three-way split. The **training set** is what the '
          'optimiser fits against. The **validation set** is what you look at '
          'while making decisions — which model family, how deep, which '
          'learning rate, when to stop. The **test set** is untouched until the '
          'very end, and produces the single number you report as your honest '
          'estimate of performance on new data. Typical proportions are 60/20/20 '
          'on modest datasets, moving toward 98/1/1 when you have millions of '
          'rows and one percent is already tens of thousands of examples.',
        ),
        ProseBlock(
          'Why three and not two? Because the moment you use a set to choose '
          'something, you have started fitting to it. Try forty hyperparameter '
          'configurations against a validation set and the winner is partly '
          'genuinely better and partly lucky on those particular rows. The test '
          'set is the control for that selection effect — which only works if '
          'you look at it once, at the end, and change nothing afterwards.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from sklearn.model_selection import train_test_split

# 10,000 rows, 8% positives. Carve the test set off first and leave it alone.
X_rest, X_test, y_rest, y_test = train_test_split(
    X, y, test_size=0.20, stratify=y, random_state=42,
)                                     # 8,000 rest / 2,000 test

# Then take validation out of what is left. 0.25 of 8,000 = 2,000.
X_train, X_val, y_train, y_val = train_test_split(
    X_rest, y_rest, test_size=0.25, stratify=y_rest, random_state=42,
)                                     # 6,000 train / 2,000 val / 2,000 test

print(y_train.mean(), y_val.mean(), y_test.mean())
# 0.0800 0.0800 0.0800   <- stratify kept the positive rate identical

# Without stratify=y on an 8% positive class, a 2,000-row validation split
# can easily land at 6.9% or 9.2% positives, which moves precision and
# recall by more than most model changes do.
''',
          caption:
              'Always pass stratify for classification, and always pass '
              'random_state so the split is reproducible.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Touching the test set destroys it',
          text:
              'If you evaluate on test, see a disappointing number, change a '
              'hyperparameter and evaluate again, that test score is now a '
              'validation score — you selected against it. Report it as such, '
              'or hold out a fresh set. This is not pedantry: teams that tune '
              'against test routinely ship models that land several points '
              'worse in production than the number in the slide deck.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: when a random split lies to you',
          children: [
            ProseBlock(
              'A random split assumes every row is an independent draw from the '
              'same distribution as production traffic. Plenty of real datasets '
              'break that assumption, and when they do, a random split produces '
              'an optimistic score that nobody catches until launch.',
            ),
            ProseBlock(
              'The first case is **time**. If you are predicting the future, '
              'shuffling before splitting puts tomorrow in the training set and '
              'yesterday in the test set, and the model gets to see the outcome '
              'of trends it is supposed to forecast. Split by a cut-off date '
              'instead: train on everything before it, evaluate on everything '
              'after. scikit-learn ships TimeSeriesSplit for the '
              'cross-validation version, where each fold trains on a prefix and '
              'validates on the block immediately following it.',
            ),
            ProseBlock(
              'The second case is **grouping**. If one patient contributes '
              'forty scans, or one user contributes three hundred sessions, a '
              'random split puts near-duplicate rows on both sides and the '
              'model is rewarded for recognising the individual rather than the '
              'pattern. Use GroupKFold or GroupShuffleSplit with the patient or '
              'user id as the group, so every group lands entirely on one side.',
            ),
            ProseBlock(
              'The third case is **leakage through features**. Any column '
              'computed using information that did not exist at prediction time '
              '— an aggregate over the full dataset, a field the downstream '
              'process fills in after the outcome is known — will make '
              'validation look superb and production look broken. The test is '
              'always the same question: at the moment I need this prediction, '
              'would I actually have this value?',
            ),
            CodeBlock(
              language: 'python',
              code: '''
from sklearn.model_selection import GroupKFold, TimeSeriesSplit

# Grouped: all rows for a given user stay on one side of every split.
gkf = GroupKFold(n_splits=5)
for train_idx, val_idx in gkf.split(X, y, groups=user_ids):
    ...     # no user appears in both train_idx and val_idx

# Temporal: never shuffle. Each fold trains on the past, validates on the
# block that comes next.
tss = TimeSeriesSplit(n_splits=4)
for train_idx, val_idx in tss.split(X_sorted_by_date):
    print(len(train_idx), len(val_idx))
# 2000 2000
# 4000 2000
# 6000 2000
# 8000 2000
''',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'cross-validation',
      heading: 'Cross-validation when a single split is too noisy',
      blocks: [
        ProseBlock(
          'A single validation split gives you one number computed on one '
          'arbitrary subset of rows. On a few thousand examples that number '
          'wobbles by several points depending on which rows happened to land '
          'in it, which means small genuine improvements are invisible under '
          'the noise, and small imaginary improvements look real.',
        ),
        ProseBlock(
          '**K-fold cross-validation** removes the arbitrariness. Split the '
          'data into k equal parts, then train k times, each run holding out a '
          'different part for validation and training on the other k minus one. '
          'Every row is validated exactly once, and you end up with k scores '
          'whose mean is a much steadier estimate and whose standard deviation '
          'tells you how much to trust it. Five and ten are the usual values '
          'for k.',
        ),
        ProseBlock(
          'The cost is that you train k models instead of one. That is the '
          'whole decision rule: use cross-validation when data is limited and '
          'training is cheap, and a single large held-out split when data is '
          'plentiful or training is expensive. Nobody cross-validates a model '
          'that takes three days on a GPU cluster; a fifty-thousand-row '
          'gradient boosting fit is a different story.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from sklearn.model_selection import StratifiedKFold, cross_val_score

# Stratified for classification: each fold keeps the class balance.
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)
scores = cross_val_score(pipe, X_rest, y_rest, cv=cv, scoring="f1")

print(scores.round(3))                                  # [0.712 0.688 0.735 0.701 0.664]
print(scores.mean().round(3), scores.std().round(3))    # 0.700 0.024

# Read that as 0.700 plus or minus about 0.024. A rival model scoring 0.71
# on a single split has not beaten it; a rival averaging 0.76 across the
# same folds probably has.
''',
          caption:
              'Report the mean and the spread. A mean without a spread hides '
              'whether the difference you are excited about is real.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Cross-validate the pipeline, not the model',
          text:
              'Pass a Pipeline to cross_val_score so every fold refits the '
              'scaler, the encoder and any feature selection on that fold\'s '
              'training rows only. Fitting them once on the full dataset before '
              'cross-validating leaks the held-out rows into the features and '
              'inflates every fold score.',
        ),
      ],
    ),
    Section(
      id: 'metrics',
      heading: 'Where the metrics get reported',
      blocks: [
        ProseBlock(
          'You already know the metrics: precision, recall, F1 and ROC-AUC for '
          'classification; MAE, RMSE and R² for regression. Nothing about them '
          'changes here. What changes is where you are allowed to compute them.',
        ),
        ProseBlock(
          'Every metric you quote must come from data that played no part in '
          'fitting the thing being measured. Training performance is optimistic '
          'by construction — the optimiser spent its entire run minimising loss '
          'on exactly those rows, so a good training score is evidence that the '
          'optimiser worked, not that the model generalises. It is a debugging '
          'signal, never a result.',
        ),
        ProseBlock(
          'In practice that means: report validation metrics while you are '
          'iterating, report the test metric once at the end, and label clearly '
          'which is which. Report training metrics only alongside validation '
          'ones, because the gap between them is itself the diagnostic — that '
          'gap is the subject of the next section.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from sklearn.metrics import f1_score

train_f1 = f1_score(y_train, model.predict(X_train))
val_f1   = f1_score(y_val,   model.predict(X_val))

print(round(train_f1, 3), round(val_f1, 3))
# 0.983 0.701    <- the 0.983 is not a result, it is a symptom

# Report this pair, never the first number alone. A 0.28 gap says the model
# has memorised far more than it has learned.
''',
          caption:
              'The interesting quantity is almost never a single score; it is '
              'the distance between the training score and the held-out one.',
        ),
      ],
    ),
    Section(
      id: 'learning-curves',
      heading: 'Learning curves, overfitting and underfitting',
      blocks: [
        ProseBlock(
          'A **learning curve** plots training and validation performance side '
          'by side as something increases — the number of training epochs, or '
          'the number of training examples. Two curves on one axis, and the '
          'shape they make is the most informative diagnostic in applied '
          'machine learning, because it tells you not just that the model is '
          'wrong but which direction to move.',
        ),
        ProseBlock(
          '**Overfitting** looks like divergence. The training curve keeps '
          'improving while the validation curve flattens and then turns the '
          'wrong way. The model is still learning, but what it is learning now '
          'is noise specific to the training rows. The epoch where the '
          'validation curve turns is where you should have stopped, and early '
          'stopping is precisely the practice of stopping there automatically.',
        ),
        ProseBlock(
          '**Underfitting** looks like two curves that plateau close together '
          'at a disappointing level. There is no gap to close, so more data '
          'will not help — the model simply is not expressive enough, or the '
          'features do not carry the signal, or training stopped far too early. '
          'A tiny gap with a bad score is a fundamentally different problem from '
          'a large gap with a good training score, and treating them the same '
          'way wastes weeks.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np
from sklearn.model_selection import learning_curve

sizes, train_scores, val_scores = learning_curve(
    model, X_rest, y_rest,
    train_sizes=np.linspace(0.1, 1.0, 5),
    cv=5, scoring="neg_mean_absolute_error",
)

for n, tr, va in zip(sizes, -train_scores.mean(axis=1), -val_scores.mean(axis=1)):
    print(int(n), round(tr, 2), round(va, 2))

#    n    train MAE   val MAE
#  600      0.31        4.92   memorises 600 rows perfectly, useless elsewhere
# 1950      0.44        3.60
# 3300      0.52        2.98
# 4650      0.58        2.71
# 6000      0.61        2.60   gap still ~2.0, and val is still falling
#
# Reading: classic overfitting, but the validation curve has not flattened,
# so collecting more data is still buying accuracy. Compare with a curve
# where both lines sit at 3.9 and stop moving - that is underfitting, and
# more rows of the same data will change nothing.
''',
          caption:
              'learning_curve varies the training-set size; the per-epoch '
              'version varies training time instead.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# The per-epoch version, written by hand: record both losses every epoch.
train_hist, val_hist = [], []

for epoch in range(1, 41):
    model.partial_fit(X_train, y_train)
    train_hist.append(mean_squared_error(y_train, model.predict(X_train)))
    val_hist.append(mean_squared_error(y_val, model.predict(X_val)))

best = min(range(len(val_hist)), key=lambda i: val_hist[i])
print("best epoch", best + 1, "val MSE", round(val_hist[best], 3))

# epoch  train  val
#   5    0.412  0.446
#  10    0.288  0.331
#  15    0.201  0.297
#  18    0.176  0.291   <- best epoch: validation turns here
#  25    0.121  0.318
#  40    0.061  0.404   train still improving, val clearly worse
''',
          caption:
              'Everything after epoch 18 is the model getting better at the '
              'training set and worse at its job.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Which lever to pull',
          text:
              'Overfitting — a large train/validation gap — is fixed by more '
              'training data, by regularisation (weight decay, dropout, '
              'stronger pruning), by early stopping, or by a simpler model. '
              'Underfitting — both curves plateauing at a poor score — is fixed '
              'by more capacity, better or more features, less regularisation, '
              'or simply training for longer. The two lists point in opposite '
              'directions, which is why you diagnose before you act.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-tvi-split',
      title: 'Watch the score move when the split moves',
      prompt: [
        ProseBlock(
          'Fit the same model on the same dataset with ten different values of '
          'random_state in train_test_split, and collect the validation score '
          'each time. Print the ten scores, their mean, their standard '
          'deviation and the gap between the best and the worst.',
        ),
        ProseBlock(
          'The point is not the mean. The point is how far apart the best and '
          'worst runs are, given that nothing about the model changed between '
          'them.',
        ),
      ],
      starterCode: '''
from sklearn.datasets import load_breast_cancer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from sklearn.metrics import f1_score

X, y = load_breast_cancer(return_X_y=True)


def score_with_seed(seed):
    """Split with this seed, fit, and return the validation F1."""
    ...


scores = [score_with_seed(s) for s in range(10)]
# TODO: print the scores, the mean, the standard deviation and the range
''',
      solutionCode: '''
import statistics

from sklearn.datasets import load_breast_cancer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from sklearn.metrics import f1_score

X, y = load_breast_cancer(return_X_y=True)


def score_with_seed(seed):
    """Split with this seed, fit, and return the validation F1."""
    X_tr, X_val, y_tr, y_val = train_test_split(
        X, y, test_size=0.25, stratify=y, random_state=seed,
    )
    # The scaler is inside the pipeline, so it is fitted on X_tr only.
    pipe = make_pipeline(StandardScaler(), LogisticRegression(max_iter=2000))
    pipe.fit(X_tr, y_tr)
    return f1_score(y_val, pipe.predict(X_val))


scores = [score_with_seed(s) for s in range(10)]

print([round(s, 3) for s in scores])
print("mean", round(statistics.mean(scores), 3))
print("stdev", round(statistics.stdev(scores), 3))
print("range", round(max(scores) - min(scores), 3))

# [0.978, 0.983, 0.967, 0.989, 0.972, 0.961, 0.983, 0.978, 0.994, 0.967]
# mean  0.977
# stdev 0.010
# range 0.033
#
# Same data, same model, same hyperparameters. Only the split changed, and
# the reported score swung by more than three points - enough to "prove"
# an improvement that does not exist.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'You change a hyperparameter and the validation F1 rises from '
              '0.972 to 0.979 on your usual split. Have you improved the model?',
          expectedAnswer:
              'There is no evidence either way. The run-to-run spread from the '
              'split alone is about the same size as the change, so the '
              'difference is well inside the noise. To decide, compare both '
              'settings across the same set of cross-validation folds and look '
              'at whether the improvement is consistent fold by fold, not just '
              'in the mean.',
        ),
        SelfCheckQuestion(
          question:
              'Why is the StandardScaler built into the pipeline rather than '
              'applied to X before the loop?',
          expectedAnswer:
              'Because scaling X first would compute the mean and standard '
              'deviation over every row, including the ones about to become the '
              'validation set. Those statistics would then be baked into the '
              'training features, so the model would have been influenced by '
              'data it is supposed to be tested on. Inside a pipeline the '
              'scaler is refitted on each training split, which is exactly what '
              'happens in production, where future rows do not exist yet.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-tvi-kfold',
      title: 'Write a k-fold splitter from scratch',
      prompt: [
        ProseBlock(
          'Implement k_folds(n, k) which returns a list of k pairs of index '
          'lists — (train_indices, validation_indices) — covering the range 0 '
          'to n minus 1. Every index must appear in exactly one validation fold '
          'and in k minus one training sets, and the folds must stay balanced '
          'when n does not divide evenly by k.',
        ),
        ProseBlock(
          'Then run a toy scorer across the folds and report the mean and the '
          'standard deviation, which is what cross_val_score does for you in '
          'real code.',
        ),
      ],
      starterCode: '''
import statistics


def k_folds(n, k):
    """Return k (train_indices, val_indices) pairs covering range(n)."""
    ...


def toy_score(train_idx, val_idx):
    """Stand-in for fit-then-evaluate: a deterministic number per fold."""
    return 0.70 + 0.001 * (sum(val_idx) % 37)


folds = k_folds(23, 5)
# TODO: check every index is validated exactly once, then print mean and stdev
''',
      solutionCode: '''
import statistics


def k_folds(n, k):
    """Return k (train_indices, val_indices) pairs covering range(n)."""
    indices = list(range(n))

    # Spread the remainder over the first folds so sizes differ by at most 1.
    base, extra = divmod(n, k)
    sizes = [base + (1 if i < extra else 0) for i in range(k)]

    folds, start = [], 0
    for size in sizes:
        val_idx = indices[start:start + size]
        train_idx = indices[:start] + indices[start + size:]
        folds.append((train_idx, val_idx))
        start += size
    return folds


def toy_score(train_idx, val_idx):
    """Stand-in for fit-then-evaluate: a deterministic number per fold."""
    return 0.70 + 0.001 * (sum(val_idx) % 37)


folds = k_folds(23, 5)

for train_idx, val_idx in folds:
    print(len(train_idx), val_idx)
# 18 [0, 1, 2, 3, 4]
# 18 [5, 6, 7, 8, 9]
# 18 [10, 11, 12, 13, 14]
# 19 [15, 16, 17, 18]
# 19 [19, 20, 21, 22]

# Every index is validated exactly once, and never appears on both sides.
validated = sorted(i for _, val_idx in folds for i in val_idx)
assert validated == list(range(23))
assert all(set(tr).isdisjoint(va) for tr, va in folds)

scores = [toy_score(tr, va) for tr, va in folds]
print(round(statistics.mean(scores), 4), round(statistics.stdev(scores), 4))
# 0.7178 0.0113
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'This splitter takes the folds in order. When is that wrong, and '
              'when is it exactly what you want?',
          expectedAnswer:
              'It is wrong whenever the row order carries information — data '
              'sorted by class, by customer, or by date — because the folds '
              'then differ systematically rather than randomly. Shuffle the '
              'indices first, or use StratifiedKFold to preserve class balance. '
              'It is exactly right for time-ordered data used with a forward '
              'chaining scheme, where each fold must train only on rows that '
              'precede its validation block.',
        ),
        SelfCheckQuestion(
          question:
              'What does the standard deviation across the folds actually tell '
              'you?',
          expectedAnswer:
              'How stable the estimate is, which is how much of a difference '
              'between two models you can take seriously. A large spread means '
              'the folds disagree — usually a sign of a small dataset, an '
              'imbalanced class, or a group structure that leaks across folds. '
              'It is not an error bar on the true production performance, since '
              'the folds all come from the same dataset and share whatever bias '
              'that dataset has.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-tvi-overfit-epoch',
      title: 'Find the epoch where overfitting starts',
      prompt: [
        ProseBlock(
          'Given per-epoch training and validation losses, write '
          'overfit_epoch(train_losses, val_losses, patience) which returns the '
          '1-based epoch of the lowest validation loss — the point where you '
          'should have stopped — or None if validation loss never stopped '
          'improving.',
        ),
        ProseBlock(
          'Use patience so a single noisy uptick does not trigger the verdict: '
          'only declare overfitting once validation loss has failed to beat its '
          'best for patience consecutive epochs. Also return the train/'
          'validation gap at that epoch, since a turning point with no gap is a '
          'different story.',
        ),
      ],
      starterCode: '''
train_losses = [0.90, 0.61, 0.44, 0.33, 0.26, 0.21, 0.17, 0.13, 0.10, 0.07]
val_losses   = [0.94, 0.68, 0.53, 0.45, 0.41, 0.40, 0.43, 0.47, 0.52, 0.58]


def overfit_epoch(train_losses, val_losses, patience=2):
    """Return (epoch, gap) at the best validation loss, or None."""
    ...


print(overfit_epoch(train_losses, val_losses))
''',
      solutionCode: '''
train_losses = [0.90, 0.61, 0.44, 0.33, 0.26, 0.21, 0.17, 0.13, 0.10, 0.07]
val_losses   = [0.94, 0.68, 0.53, 0.45, 0.41, 0.40, 0.43, 0.47, 0.52, 0.58]


def overfit_epoch(train_losses, val_losses, patience=2):
    """Return (epoch, gap) at the best validation loss, or None."""
    best_epoch = 0
    best_loss = float("inf")
    since_best = 0

    for i, loss in enumerate(val_losses):
        if loss < best_loss:
            best_loss, best_epoch, since_best = loss, i, 0
        else:
            since_best += 1
            if since_best >= patience:
                gap = val_losses[best_epoch] - train_losses[best_epoch]
                return best_epoch + 1, round(gap, 3)

    # Validation never degraded for `patience` epochs in a row: not overfitting
    # yet, and the run probably deserves more epochs.
    return None


print(overfit_epoch(train_losses, val_losses))
# (6, 0.19)   -> best validation loss at epoch 6, gap of 0.19 there

still_improving = [0.90, 0.61, 0.44, 0.33, 0.26]
print(overfit_epoch(still_improving, [0.94, 0.68, 0.53, 0.45, 0.41]))
# None

# Both curves flat and high: no turning point, so this returns None too -
# that is underfitting, and the fix is capacity or features, not stopping.
print(overfit_epoch([0.71, 0.70, 0.70, 0.69], [0.73, 0.72, 0.72, 0.71]))
# None
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why return the epoch of the best validation loss rather than the '
              'epoch where the increase was detected?',
          expectedAnswer:
              'Because the best epoch is the model you actually want to keep. '
              'Detection necessarily lags by the patience window, so by the '
              'time you notice, you have trained past the optimum. This is why '
              'early stopping implementations checkpoint the weights at every '
              'new best validation score and restore that checkpoint when they '
              'stop, rather than keeping the final ones.',
        ),
        SelfCheckQuestion(
          question:
              'The function returns None for a run whose losses are 0.71 and '
              '0.73 and barely moving. What should you do next?',
          expectedAnswer:
              'Treat it as underfitting, not as a healthy run. Both curves have '
              'plateaued at a poor value with almost no gap between them, so '
              'the model has not got the capacity or the features to fit the '
              'data — more rows will not help. Increase capacity, add or '
              'improve features, reduce regularisation, or check that the '
              'learning rate is not so small that training has effectively '
              'stalled.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-tvi-cv-compare',
      title: 'Compare cross-validation scores of two models',
      prompt: [
        ProseBlock(
          'Use cross_val_score to compare a LogisticRegression against a '
          'RandomForestClassifier on the breast cancer dataset using '
          '5-fold stratified cross-validation. Report the mean and '
          'standard deviation of F1 scores. Explain whether the difference '
          'between the means is meaningful given the standard deviations.',
        ),
      ],
      starterCode: '''
from sklearn.datasets import load_breast_cancer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score, StratifiedKFold
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline

X, y = load_breast_cancer(return_X_y=True)
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)

# TODO: build two pipelines, cross-validate both, print means +/- std
...
''',
      solutionCode: '''
from sklearn.datasets import load_breast_cancer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score, StratifiedKFold
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline

X, y = load_breast_cancer(return_X_y=True)
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)

for name, model in [
    ("LogisticRegression", make_pipeline(StandardScaler(),
        LogisticRegression(max_iter=2000))),
    ("RandomForest", make_pipeline(StandardScaler(),
        RandomForestClassifier(n_estimators=100, random_state=0))),
]:
    scores = cross_val_score(model, X, y, cv=cv, scoring="f1")
    print(f"{name}: {scores.mean():.3f} +/- {scores.std():.3f}")

# Typical output:
# LogisticRegression: 0.975 +/- 0.012
# RandomForest:       0.968 +/- 0.014
# The means differ by ~0.007 but the standard deviations overlap.
# With only 5 folds and ~560 examples, this difference is not
# statistically meaningful — either model is fine.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The means differ by 0.007 but the standard deviations are '
              '~0.014. Why is this difference probably not meaningful?',
          expectedAnswer:
              'Because the standard deviation measures the variability of '
              'the score across different random splits of the same data. '
              'If the score can vary by ±0.014 just from which rows land '
              'in which fold, a difference of 0.007 between two models '
              'could easily be an artefact of the particular split rather '
              'than a genuine improvement. This is exactly why cross-'
              'validation reports the spread alongside the mean — it tells '
              'you how seriously to take the comparison. A t-test or '
              'Wilcoxon test across the per-fold scores can quantify it, '
              'but the visual rule is: if the error bars overlap, do not '
              'call a winner without more evidence.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 226000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Think of a restaurant kitchen. Training is the chef '
              'practising — tasting dishes, adjusting seasonings, getting '
              'better with every attempt. That is the training phase: the model '
              'sees data, measures how wrong it is, and tweaks its internal '
              'knobs. Inference is dinner service — the recipes are locked in, '
              'orders fly in, plates go out, nothing about the menu changes. '
              'Training happens once in the back. Inference happens constantly '
              'at the front, and it has to be fast.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'And that split is why evaluation is tricky. If you taste your '
              'own cooking and declare it excellent, nobody is surprised — '
              'you have been adjusting it to your own palate. That is the '
              'training score. To know if strangers will actually like your '
              'food, you need a tasting panel that never saw the kitchen. Only '
              'data the model has never touched tells you whether it learned '
              'to cook or just memorised the one dish you practised.',
          startMs: 44000,
          endMs: 88000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Hence three buckets. Training data is your practice kitchen '
              'where the chef experiments. Validation data is the sous-chef '
              'who tastes and says "more salt" — you make decisions based on '
              'those scores. Test data is the food critic who visits exactly '
              'once at the end. The moment you adjust your recipe in response '
              'to what the critic said, they stop being an honest critic and '
              'become part of your tasting panel.',
          startMs: 88000,
          endMs: 136000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Small dataset? A single taste test with five people could '
              'easily be a weird five. Cross-validation is the fix: split into '
              'five groups, train on four, test on the fifth, rotate who sits '
              'out, average the results. It costs five times the kitchen time '
              'but gives you a much steadier number. Huge dataset? One big '
              'held-out group works fine and is way cheaper.',
          startMs: 136000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Last concept, and it is the most useful. Plot two curves: '
              'training score and validation score. If they are diverging — '
              'you keep getting better at practice but worse at the tasting '
              'panel — you are overfitting. You are memorising the practice '
              'dishes instead of learning to cook. More data or simpler '
              'recipes. If both are flat and bad — underfitting — you need '
              'more practice time or a bigger kitchen.',
          startMs: 182000,
          endMs: 226000,
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
              'Think of training versus inference like the difference between '
              'rehearsing for a play and performing on opening night. During '
              'rehearsals — training — you try things, get notes, adjust. The '
              'fit function is the whole rehearsal process: data goes in, '
              'mistakes get measured, everything gets tweaked. On opening '
              'night — inference — the script is locked. Lines come in, lines '
              'go out, nothing about the performance changes. The predict '
              'function is the show. Millions of people see the show; '
              'only the cast saw the rehearsals.',
          startMs: 0,
          endMs: 52000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'And notice what is frozen even during the rehearsal phase. The '
              'weights move — those are the lines being adjusted. But the '
              'architecture does not: how many actors, what the stage looks '
              'like. The learning rate, the number of layers, the feature '
              'definitions — those are hyperparameters, chosen by you the '
              'director before rehearsals even start. At showtime even the '
              'weights are frozen, so the only variable left is the input.',
          startMs: 52000,
          endMs: 114000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'The constraints are wildly different and that shapes every '
              'engineering decision. Your rehearsal might take six hours on a '
              'GPU cluster — nobody is waiting in the audience. But each '
              'prediction during the show has to happen in four milliseconds '
              'because there is a customer staring at a loading spinner. Nobody '
              'feels the six hours. Everybody feels the four milliseconds. That '
              'latency number, not the training time, is what your product '
              'lives or dies by.',
          startMs: 114000,
          endMs: 178000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Now evaluation. Here is the uncomfortable truth: a model with '
              'enough capacity can memorise. Imagine a student who writes down '
              'every practice problem and its answer on a cheat sheet, then '
              'takes the practice test with the sheet in hand. Perfect score. '
              'Now give them a new problem — disaster. That is what a training '
              'score measures: memorisation plus learning, with no way to '
              'separate them. Only data the model has never laid eyes on can '
              'tell you which one you got.',
          startMs: 178000,
          endMs: 242000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Three-way split. Think of it like developing a vaccine. The '
              'training set is the lab — you formulate it here. The validation '
              'set is the clinical trial — you test it on a group you have not '
              'touched, and if it does not work you go back and reformulate. '
              'The test set is the real-world deployment — you measure '
              'effectiveness in the wild exactly once, and you do not get to '
              'tweak the formula afterwards. The classic split is 60-20-20, '
              'but with millions of patients one percent is already thousands '
              'of people. And always stratify — keep the proportions of sick '
              'and healthy identical across all groups.',
          startMs: 242000,
          endMs: 308000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'The rule people break constantly: tuning against the test set. '
              'You look at your test score, you are disappointed, you tweak a '
              'hyperparameter, you look again. That test score is now a '
              'validation score — you selected against it. You have burned its '
              'honesty. Either report it as validation going forward, or hold '
              'out a fresh batch of data. This is not pedantry. Teams that tune '
              'against test routinely ship models that land several points '
              'worse in production than the slide deck promised.',
          startMs: 308000,
          endMs: 372000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Cross-validation is the fix when your dataset is small enough '
              'that a single split could be a fluke. Imagine tasting five '
              'people\'s opinions on your cooking. That is one noisy number. '
              'Now imagine doing that five times with five different groups and '
              'averaging. The mean is steadier, and the spread across those '
              'five taste tests tells you whether your rival chef is genuinely '
              'better or just got lucky with the panel. It costs five times '
              'the kitchen time, which is why you use it on small data and '
              'skip it when a single training run takes days.',
          startMs: 372000,
          endMs: 436000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And the diagnostic to carry into every project: learning '
              'curves. Big gap between training and validation? Overfitting — '
              'you are getting better at the practice test but not the real '
              'thing. More data, more regularisation, stop earlier. No gap but '
              'both scores are bad? Underfitting — you have not even learned '
              'the practice material. More capacity, better features, train '
              'longer. Those two prescriptions are complete opposites, which is '
              'why diagnosing first genuinely saves you weeks of wasted work.',
          startMs: 436000,
          endMs: 498000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 876000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Deep dive on training versus inference. We are going to walk '
              'through what actually differs between the two phases at the '
              'mechanical level, the discipline of splitting data honestly, the '
              'cases where a naive random split lies to you, cross-validation '
              'and its real costs, learning curves as a diagnostic tool, and '
              'the part nobody teaches early enough — what inference actually '
              'costs once real traffic starts hitting your model.',
          startMs: 0,
          endMs: 66000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Mechanics first. During training you run three things: a forward '
              'pass to compute predictions, a backward pass to compute '
              'gradients for every weight, and an optimizer step to update the '
              'weights using those gradients. At inference you do only the '
              'forward pass. That is why inference is roughly a third of the '
              'computational cost. You can throw away the optimizer state, the '
              'gradients, and the entire training graph when you ship. What you '
              'keep is just the fitted weights — like serving a finished meal '
              'and throwing away the recipe notes and tasting spoons.',
          startMs: 66000,
          endMs: 144000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'And the artefact you ship must include the preprocessing, not '
              'just the model. Here is where teams get hurt in production. Your '
              'scaler learned a mean and standard deviation from the training '
              'data — "houses average 1,800 square feet with a spread of 400". '
              'Those exact numbers have to travel with the model. If you '
              'recompute the mean on live traffic, you have quietly changed the '
              'meaning of every input your model sees. The weights stayed the '
              'same but the model is now doing something different. Ship the '
              'fitted transformer alongside the model, or wrap both in a '
              'Pipeline so they stay glued together.',
          startMs: 144000,
          endMs: 216000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Now evaluation discipline, which is where most projects quietly '
              'overstate their results. Three sets, three entirely separate '
              'jobs. Training is what the optimizer sees — it is the lab bench. '
              'Validation is what your decisions see — model family, depth, '
              'learning rate, when to stop. Every time you look at validation '
              'and change something, you are selecting. Test is what nobody '
              'sees until the end. The reason three beats two is selection '
              'bias: try forty configurations against validation and the winner '
              'is partly genuinely better and partly lucky on those specific '
              'rows. The test set is the control group for that selection '
              'effect, and it only works if you look exactly once.',
          startMs: 216000,
          endMs: 292000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Stratification deserves its moment. Imagine you are looking for '
              'a disease that affects eight percent of the population. You '
              'randomly split 2,000 people into a validation group. Without '
              'stratification, that group could easily have 138 sick people '
              'instead of 160 — or 184. That swing alone shifts your precision '
              'and recall more than most model changes you will make. You would '
              'be comparing different validation sets while believing you are '
              'comparing different models. stratify=y fixes this by keeping the '
              'class balance identical across every split.',
          startMs: 292000,
          endMs: 366000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'And a random split assumes every row is an independent draw from '
              'the same distribution. Two cases where that lie will burn you. '
              'Grouped data: one patient contributes forty MRI scans. Shuffle '
              'randomly and scans from the same brain land on both sides of the '
              'split. The model is not learning to detect tumours — it is '
              'learning to recognize Sarah\'s particular brain shape. Use '
              'GroupKFold with patient ID as the group, so every individual '
              'lands entirely on one side.',
          startMs: 366000,
          endMs: 442000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'The other case is time. If you are forecasting — stock prices, '
              'weather, demand — shuffling puts tomorrow\'s data in the '
              'training set and yesterday\'s in the test set. The model gets to '
              'see the outcome of trends it is supposed to predict. It looks '
              'brilliant in evaluation and useless in production. Split on a '
              'cut-off date. For cross-validation, TimeSeriesSplit trains on '
              'an expanding prefix and validates on the block immediately '
              'after. Never, ever shuffle temporal data.',
          startMs: 442000,
          endMs: 518000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Cross-validation itself. K-fold gives you k scores instead of '
              'one, and the standard deviation across them is what stops you '
              'from chasing noise. Stratified k-fold preserves class balance in '
              'every fold — for imbalanced problems this is not optional. The '
              'one iron rule: cross-validate the entire pipeline, not just the '
              'model. If you fit the scaler once on all the data and then '
              'cross-validate only the model, every fold has leaked information '
              'about the held-out rows through the preprocessing. Fit scaler '
              'and encoder fresh on each training fold.',
          startMs: 518000,
          endMs: 596000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Learning curves. Plot training and validation error together '
              'against epochs. Diverging lines — training keeps falling, '
              'validation flattens then climbs — that is overfitting, and the '
              'turning point is exactly where early stopping should fire. Two '
              'lines plateaued close together at a mediocre level — that is '
              'underfitting, a completely different disease. Same-looking chart '
              'at a glance, opposite remedy. This is why the habit of plotting '
              'both curves on one axis is the cheapest debugger in ML.',
          startMs: 596000,
          endMs: 670000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'The size-based curve answers a question teams pay real money '
              'for: should we buy more data? If validation error is still '
              'dropping at your current dataset size — yes, every additional '
              'batch of labelled examples is buying you accuracy. If it has '
              'flattened but there is still a large gap to training error — '
              'regularisation is a better investment. If it has flattened with '
              'no gap and a bad score — more data changes nothing. You need a '
              'different model architecture or fundamentally better features.',
          startMs: 670000,
          endMs: 746000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Now the economics of inference that nobody talks about in '
              'courses. Latency budgets are per request — bigger models cost '
              'you directly in milliseconds of user-visible waiting time. '
              'Batching amortises the overhead across many requests but adds '
              'queueing delay — your users wait while the batch fills up. '
              'Quantisation runs the model in 8-bit instead of 32-bit, often '
              'cutting memory and latency several-fold for a fraction of a '
              'percent accuracy loss. Distillation trains a small student '
              'model to imitate a large teacher. All of these are inference '
              'optimisations that live in the deployment engineer\'s toolbox.',
          startMs: 746000,
          endMs: 814000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Which reframes the whole lesson into one sentence I wish '
              'everyone heard on day one. Training cost is paid once and is a '
              'project budget decision. Inference cost is paid on every single '
              'request forever and is a product decision. The best model on '
              'your validation set is not automatically the model you ship. '
              'The gap between those two sentences — picking the model that '
              'works well enough while being cheap and fast enough to serve — '
              'is most of what applied ML engineering actually is.',
          startMs: 814000,
          endMs: 876000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Two phases, two sets of constraints',
      body:
          'Training adjusts parameters against a loss using the training data: '
          'compute-heavy, run once or periodically. Inference is a frozen '
          'forward pass on new data: cheap per call, latency-critical, run '
          'constantly. The architecture and hyperparameters are fixed '
          'throughout; at serve time the weights are fixed too.',
    ),
    SummaryCard(
      title: 'Only unseen data proves anything',
      body:
          'Split into train, validation and test. Fit on train, make every '
          'decision against validation, and touch test exactly once at the end. '
          'Stratify for classification, keep groups and time order intact, and '
          'never quote a training score as a result — it is optimistic by '
          'construction.',
    ),
    SummaryCard(
      title: 'Learning curves tell you which lever to pull',
      body:
          'Plot training and validation performance together. A large and '
          'growing gap means overfitting: more data, regularisation, early '
          'stopping or a simpler model. Both curves plateauing at a poor score '
          'means underfitting: more capacity, better features or longer '
          'training. Use cross-validation when data is limited and training is '
          'cheap.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Training phase',
      definition:
          'The phase in which parameters are updated to reduce a loss computed '
          'on the training data. Compute-intensive, latency-tolerant, and run '
          'once or on a schedule rather than per request.',
    ),
    KeyConcept(
      term: 'Inference phase',
      definition:
          'A forward pass through a model whose parameters are frozen, '
          'producing a prediction for new input. Nothing is learned; the cost '
          'that matters is per-call latency and throughput.',
    ),
    KeyConcept(
      term: 'Train/validation/test split',
      definition:
          'Three disjoint subsets: train fits the parameters, validation guides '
          'model and hyperparameter choices, and test provides one final '
          'untouched estimate of generalisation. Common proportions are '
          '60/20/20, shifting toward 98/1/1 on very large datasets.',
    ),
    KeyConcept(
      term: 'K-fold cross-validation',
      definition:
          'Splitting the data into k parts and training k times, each run '
          'validating on a different part. Yields a mean score and a standard '
          'deviation, at the cost of k trainings — worth it when data is '
          'limited.',
    ),
    KeyConcept(
      term: 'Overfitting',
      definition:
          'Learning patterns specific to the training rows rather than the '
          'underlying signal. Recognised by a training score that keeps '
          'improving while the validation score plateaus or worsens.',
    ),
    KeyConcept(
      term: 'Learning curve',
      definition:
          'Training and validation performance plotted together against epochs '
          'or training-set size. The gap between the curves diagnoses '
          'overfitting; a shared plateau at a poor score diagnoses '
          'underfitting.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake: 'Reporting accuracy or loss measured on the training data.',
      correction:
          'That number is optimistic by construction — the optimiser spent the '
          'whole run minimising exactly it. Quote validation figures while '
          'iterating and one test figure at the end, and show the training '
          'score only next to a held-out one, where the gap is the point.',
    ),
    Mistake(
      mistake:
          'Tuning hyperparameters against the test set and then quoting that '
          'same test score.',
      correction:
          'Once you make a decision based on a set, you are fitting to it and '
          'it is a validation set. Tune against validation, or use '
          'cross-validation within the training portion, and keep a test set '
          'that is evaluated once and never influences a choice.',
    ),
    Mistake(
      mistake: 'Shuffling time-ordered data before splitting.',
      correction:
          'Random shuffling puts future rows in training and past rows in test, '
          'so the model is scored on a task it will never face. Split on a '
          'cut-off date, or use TimeSeriesSplit so every fold trains only on '
          'rows that precede its validation block.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Your model scores 0.98 on training data and 0.71 on validation. What '
          'is happening and what do you do?',
      answer:
          'That gap is overfitting: the model has capacity to memorise the '
          'training rows and is using it. I would first rule out the boring '
          'explanations — a tiny training set, or leakage that makes validation '
          'artificially hard — then attack it from three directions. More data '
          'is the most reliable fix if it is available, and a learning curve '
          'against training-set size tells me whether it would still help. '
          'Failing that, regularisation: weight decay, dropout, shallower trees '
          'or stronger pruning depending on the model. And early stopping, '
          'which is free — checkpoint at the best validation score and restore '
          'it. If none of that closes the gap, the model class is simply too '
          'expressive for the data and I would try a simpler one.',
    ),
    InterviewQuestion(
      question:
          'When would you use cross-validation instead of a single held-out '
          'validation set?',
      answer:
          'When the dataset is small enough that a single split is noisy and '
          'training is cheap enough that k runs are affordable. On a few '
          'thousand rows a single validation score can swing three or four '
          'points on the split alone, which makes model comparison meaningless; '
          'five-fold cross-validation gives a mean plus a standard deviation, '
          'and the spread tells me whether a difference is real. I would skip '
          'it when data is plentiful — a hundred thousand held-out rows is '
          'already a stable estimate — or when a single training run takes '
          'hours to days, where the compute is better spent elsewhere. For '
          'grouped or temporal data I would use GroupKFold or TimeSeriesSplit '
          'rather than plain k-fold, since ordinary folds leak in both cases.',
    ),
    InterviewQuestion(
      question:
          'How do you tell overfitting from underfitting, and why does the '
          'distinction matter operationally?',
      answer:
          'I look at training and validation scores together. Overfitting is a '
          'large and widening gap: training keeps improving while validation '
          'plateaus or degrades. Underfitting is both curves settling close '
          'together at a poor score, with no gap to close. The distinction '
          'matters because the fixes are opposite. For overfitting I add data, '
          'add regularisation, stop earlier or simplify the model; for '
          'underfitting I add capacity, add or improve features, reduce '
          'regularisation or train longer. Applying the wrong prescription '
          'actively makes things worse — regularising an underfit model drives '
          'the score down further — so I always plot the learning curve before '
          'changing anything.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'train_test_split — scikit-learn docs',
    url:
        'https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.train_test_split.html',
    description:
        'Reference for the splitting helper used throughout this lesson, '
        'including the stratify and random_state arguments that make a split '
        'balanced and reproducible.',
  ),
  Source(
    title:
        'Cross-validation: evaluating estimator performance — scikit-learn '
        'docs',
    url: 'https://scikit-learn.org/stable/modules/cross_validation.html',
    description:
        'The reference for cross_val_score, KFold and StratifiedKFold, and for '
        'the grouped and time-series splitters this lesson recommends when rows '
        'are not independent.',
  ),
  Source(
    title: 'Underfitting vs. Overfitting — scikit-learn example gallery',
    url:
        'https://scikit-learn.org/stable/auto_examples/model_selection/plot_underfitting_overfitting.html',
    description:
        'A worked example fitting the same data with too little, about right '
        'and far too much model capacity, showing the two failure shapes '
        'described in the learning-curve section.',
  ),
  Source(
    title:
        'Model Fit: Underfitting vs. Overfitting — AWS Machine Learning '
        'Developer Guide',
    url:
        'https://docs.aws.amazon.com/machine-learning/latest/dg/model-fit-underfitting-vs-overfitting.html',
    description:
        'A short practitioner-oriented summary of the two failure modes and the '
        'opposite remedies for each, matching the diagnose-before-you-act '
        'advice in this lesson.',
  ),
];

const List<Source> _furtherReading = <Source>[
  Source(
    title: 'Learning Curves — scikit-learn docs',
    url: 'https://scikit-learn.org/stable/modules/learning_curve.html',
    description:
        'API reference and theory behind learning_curve(), showing how to '
        'diagnose bias and variance from training and validation scores '
        'at varying dataset sizes.',
  ),
  Source(
    title: 'TimeSeriesSplit and GroupKFold — scikit-learn',
    url: 'https://scikit-learn.org/stable/modules/cross_validation.html#cross-validation-iterators',
    description:
        'Reference for the temporal and grouped cross-validation strategies, '
        'with examples showing exactly when to use each instead of '
        'plain KFold.',
  ),
  Source(
    title: 'Model evaluation and selection — scikit-learn User Guide',
    url: 'https://scikit-learn.org/stable/model_selection.html',
    description:
        'Comprehensive guide to cross-validation, hyperparameter tuning, '
        'and the proper workflow from train/validation/test splits to '
        'final model selection.',
  ),
  Source(
    title: 'A Recipe for Training Neural Networks (Karpathy, 2019)',
    url: 'https://karpathy.github.io/2019/04/25/recipe/',
    description:
        'A practitioner\'s guide to the training loop: diagnosing '
        'overfitting/underfitting, tuning learning rates, and the '
        'step-by-step process of making a model train.',
  ),
];
