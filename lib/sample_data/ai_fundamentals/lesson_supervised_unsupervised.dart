import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 2: the learning paradigms, and how to tell which one a
/// problem actually is.
const Lesson supervisedUnsupervisedLesson = Lesson(
  id: 'ai-supervised-vs-unsupervised',
  title: 'Supervised vs. Unsupervised Learning',
  description:
      'Classification, regression, clustering and dimensionality reduction — '
      'what each paradigm needs from your data and how each one is evaluated.',
  estimatedMinutes: 33,
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
      id: 'paradigms',
      heading: 'The dividing line is whether you have labels',
      blocks: [
        ProseBlock(
          'Supervised learning starts with examples that already carry the '
          'right answer. Each row is a pair — features and a label — and the '
          'algorithm searches for a function that maps one to the other well '
          'enough to work on rows it has never seen. Photographs tagged with '
          'the animal in them, transactions marked fraudulent or not, flats '
          'with the price they eventually sold for.',
        ),
        ProseBlock(
          'Unsupervised learning has features and no answers. There is nothing '
          'to predict, so instead the algorithm describes structure: which '
          'rows resemble each other, which directions in the data carry most '
          'of the variation, which points are unlike everything else. The '
          'output is a summary of the data\'s shape rather than a prediction.',
        ),
        ProseBlock(
          'Two paradigms sit between and beyond them. Semi-supervised learning '
          'uses a small labelled set alongside a large unlabelled one, which '
          'matches the common situation where data is abundant and annotation '
          'is expensive. Self-supervised learning manufactures labels from the '
          'data itself — hide a word and predict it, hide a patch of an image '
          'and reconstruct it — and is how modern language and vision models '
          'are pre-trained. Reinforcement learning is different again: an '
          'agent acts in an environment and learns from a reward signal rather '
          'than from labelled examples.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Supervised: fit(X, y) - the y is the supervision.
from sklearn.ensemble import RandomForestClassifier

clf = RandomForestClassifier()
clf.fit(X_train, y_train)            # needs labels
print(clf.predict(X_new))            # -> ['fraud', 'ok', 'ok']

# Unsupervised: fit(X) - no y anywhere in the API.
from sklearn.cluster import KMeans

km = KMeans(n_clusters=4, n_init=10)
km.fit(X_train)                      # no labels exist
print(km.predict(X_new))             # -> [2, 0, 0]  cluster ids, not meanings
''',
          caption:
              'The scikit-learn API makes the distinction visible: supervised '
              'estimators take y, unsupervised ones do not.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Cluster ids are not classes',
          text:
              'K-means returning 2 does not mean "fraud". It means "this point '
              'is in the group the algorithm happened to number 2". The '
              'numbering changes between runs, and interpreting a cluster is a '
              'human job done afterwards by inspecting its members.',
        ),
      ],
    ),
    Section(
      id: 'supervised-tasks',
      heading: 'Classification and regression',
      blocks: [
        ProseBlock(
          'Supervised problems split by the type of the label. '
          '**Classification** predicts a category from a fixed set: spam or '
          'ham, one of ten digits, one of three species. **Regression** '
          'predicts a continuous quantity: a price, a temperature, a duration. '
          'The distinction determines the loss you train against and the '
          'metrics you report, so it is the first thing to settle.',
        ),
        ProseBlock(
          'Classifiers usually output a probability per class rather than a '
          'bare label, and the label comes from applying a threshold. That '
          'threshold is yours to choose, and choosing it is a business '
          'decision: a fraud system that must not miss anything lowers the '
          'threshold and tolerates false alarms; a system that must not annoy '
          'good customers raises it. The model can be excellent while the '
          'threshold is wrong.',
        ),
        ProseBlock(
          'The metrics differ accordingly. Classification is judged with '
          'accuracy, precision, recall, F1 and ROC-AUC — and on imbalanced '
          'data, accuracy is close to useless. Regression is judged with mean '
          'absolute error, mean squared error or its square root, and R². MSE '
          'squares the errors, so it punishes a few large mistakes far harder '
          'than MAE does; pick the one whose shape matches what actually '
          'hurts.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from sklearn.linear_model import LogisticRegression, LinearRegression
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score,
    mean_absolute_error, mean_squared_error, r2_score,
)

# Classification: discrete label, probabilistic output.
clf = LogisticRegression().fit(X_train, y_train)
probs = clf.predict_proba(X_val)[:, 1]        # P(positive class)
preds = (probs > 0.30).astype(int)            # your threshold, your call

print(accuracy_score(y_val, preds))
print(precision_score(y_val, preds))          # of those flagged, how many were right
print(recall_score(y_val, preds))             # of the real positives, how many we caught

# Regression: continuous label.
reg = LinearRegression().fit(X_train, y_train)
yhat = reg.predict(X_val)

print(mean_absolute_error(y_val, yhat))       # average size of the miss
print(mean_squared_error(y_val, yhat) ** 0.5) # RMSE: large misses dominate
print(r2_score(y_val, yhat))                  # 1.0 perfect, 0.0 = predicting the mean
''',
          caption:
              'Precision and recall answer different questions; quoting only '
              'one hides the trade.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Read precision and recall as sentences',
          text:
              'Precision: "of the items I flagged, what fraction were '
              'genuinely positive?" Recall: "of the genuinely positive items, '
              'what fraction did I flag?" Lowering the threshold always raises '
              'recall and lowers precision. F1 is their harmonic mean, useful '
              'as a single number when neither error clearly dominates.',
        ),
      ],
    ),
    Section(
      id: 'unsupervised-tasks',
      heading: 'Clustering, dimensionality reduction and anomaly detection',
      blocks: [
        ProseBlock(
          '**Clustering** groups similar rows. K-means is the workhorse: it '
          'picks k centres and iterates between assigning each point to the '
          'nearest centre and moving each centre to the mean of its points. It '
          'is fast and assumes roughly spherical, similarly sized groups. '
          'DBSCAN instead grows clusters from dense regions, which lets it '
          'find arbitrary shapes, choose its own cluster count and label '
          'sparse points as noise.',
        ),
        ProseBlock(
          '**Dimensionality reduction** compresses many features into a few '
          'that retain most of the information. PCA finds the orthogonal '
          'directions of greatest variance and projects onto the leading ones; '
          'it is linear, fast and reversible, and doubles as a denoiser and a '
          'preprocessing step for models that struggle in high dimensions. '
          't-SNE and UMAP are non-linear and built for visualisation — '
          'excellent for looking at data, unwise as features, because '
          'distances between clusters in their output are not meaningful.',
        ),
        ProseBlock(
          '**Anomaly detection** asks which points do not belong. It is '
          'usually unsupervised because anomalies are rare and unlabelled by '
          'nature — you learn what normal looks like and flag deviations. '
          'Isolation Forest, one-class SVMs and simple density estimates all '
          'take this shape.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from sklearn.cluster import KMeans, DBSCAN
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler

# Distance-based methods need comparable scales, or the largest-unit
# column silently becomes the only feature that matters.
X_scaled = StandardScaler().fit_transform(X_train)

km = KMeans(n_clusters=4, n_init=10, random_state=0).fit(X_scaled)
print(km.labels_[:10])          # [2 0 3 0 1 ...]
print(km.inertia_)              # total within-cluster squared distance

db = DBSCAN(eps=0.5, min_samples=5).fit(X_scaled)
print(set(db.labels_))          # {-1, 0, 1, 2}   -1 means "noise"

pca = PCA(n_components=2).fit(X_scaled)
print(pca.explained_variance_ratio_)        # [0.62 0.21] -> 83% kept in 2D
X_2d = pca.transform(X_scaled)              # ready to plot
''',
          caption:
              'Standardise before any distance-based method, including k-means '
              'and PCA.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: choosing k when nothing tells you k',
          children: [
            ProseBlock(
              'K-means requires the number of clusters up front, and the '
              'objective it minimises — total within-cluster squared distance, '
              'called inertia — always improves as k grows. At k equal to the '
              'number of points, inertia is zero and the result is '
              'meaningless. So inertia can never choose k for you on its own.',
            ),
            ProseBlock(
              'The elbow method plots inertia against k and looks for the bend '
              'where extra clusters stop buying much. It is genuinely useful '
              'and genuinely subjective — often there is no clean elbow. The '
              'silhouette score is a better-behaved alternative: for each '
              'point it compares the mean distance to its own cluster with the '
              'mean distance to the nearest other cluster, giving a value in '
              'the range minus one to one that can be maximised over k.',
            ),
            ProseBlock(
              'The deeper point is that "the right k" is often a property of '
              'your purpose, not of the data. If the clusters are becoming '
              'marketing segments, the number of campaigns you can actually '
              'run is a legitimate constraint. And if the natural groups are '
              'elongated or vary in density, the honest answer is that k-means '
              'is the wrong tool and DBSCAN or a Gaussian mixture will fit '
              'better.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
from sklearn.metrics import silhouette_score

for k in range(2, 9):
    km = KMeans(n_clusters=k, n_init=10, random_state=0).fit(X_scaled)
    print(k, round(km.inertia_, 1), round(silhouette_score(X_scaled, km.labels_), 3))

# k  inertia  silhouette
# 2   4820.3     0.412
# 3   3110.7     0.507
# 4   2404.1     0.561   <- best silhouette
# 5   2180.9     0.498
# 6   2011.4     0.451   inertia keeps falling; silhouette does not
''',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'evaluation',
      heading: 'Evaluation without an answer key',
      blocks: [
        ProseBlock(
          'Supervised evaluation is comparatively easy: hold out labelled '
          'data, predict, compare to the truth. Unsupervised evaluation has no '
          'truth to compare against, which is the single hardest thing about '
          'the paradigm and the reason unsupervised results need more '
          'scepticism than their tidy output suggests.',
        ),
        ProseBlock(
          'What is left are internal measures, stability checks and downstream '
          'usefulness. Internal measures like silhouette score how compact and '
          'well-separated the clusters are, using only the data itself. '
          'Stability asks whether you get similar groupings from different '
          'seeds or subsamples — an unstable clustering is describing noise. '
          'Downstream usefulness is the most honest test of all: do the '
          'clusters improve a decision, a model, or a human\'s understanding?',
        ),
        ProseBlock(
          'A useful pattern is combining the two paradigms. Use clustering or '
          'PCA to explore and compress, then use the result inside a '
          'supervised pipeline where you can measure a real score. Unlabelled '
          'data is also the fuel for self-supervised pre-training, where a '
          'model learns general representations from raw text or images and is '
          'then fine-tuned on a small labelled set for the actual task.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import cross_val_score

# Unsupervised step inside a supervised pipeline: now it has a real score.
pipe = make_pipeline(
    StandardScaler(),
    PCA(n_components=20),          # fitted on the training fold only
    LogisticRegression(max_iter=1000),
)

scores = cross_val_score(pipe, X, y, cv=5, scoring="f1_macro")
print(scores.mean().round(3), scores.std().round(3))

# Compare against the same pipeline without PCA to see whether the
# compression helped, hurt, or merely made training faster.
''',
          caption:
              'A Pipeline refits every step per fold, which is what keeps the '
              'unsupervised step from leaking.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Never fit PCA or a scaler on the full dataset',
          text:
              'Both learn statistics from the rows they see. Fitting them '
              'before splitting lets validation and test data influence the '
              'transformation, which inflates your score in a way that '
              'disappears in production. Putting them inside a Pipeline makes '
              'correct behaviour automatic.',
        ),
      ],
    ),
    Section(
      id: 'choosing',
      heading: 'Framing a real problem',
      blocks: [
        ProseBlock(
          'Start from the decision the output will drive, then work backwards. '
          '"Which customers will churn next month" is supervised '
          'classification, and it needs a labelled history of who actually '
          'churned. "What kinds of customers do we have" is clustering, and it '
          'needs no labels but also delivers no predictions. Asking which '
          'sentence you are trying to complete usually settles the paradigm '
          'faster than looking at the data.',
        ),
        ProseBlock(
          'Then ask what labels would cost. Labels rarely arrive free: someone '
          'annotates, or you wait for the outcome, or you accept a noisy '
          'proxy. If labelling is expensive, look for the shortcuts — a '
          'self-supervised pre-trained model fine-tuned on a few hundred '
          'examples now beats a from-scratch supervised model on most text and '
          'image tasks, and semi-supervised methods can exploit the unlabelled '
          'bulk directly.',
        ),
        ProseBlock(
          'Beware the proxy label. If you cannot observe what you care about, '
          'it is tempting to substitute something you can — clicks for '
          'usefulness, arrests for crime, purchases for satisfaction. The '
          'model will faithfully optimise the proxy, including all the ways '
          'the proxy diverges from your intent. That divergence, not the '
          'algorithm, is where most harmful ML systems come from.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-sup-frame',
      title: 'Frame six problems',
      prompt: [
        ProseBlock(
          'For each problem below, decide the paradigm and task type: '
          'supervised classification, supervised regression, clustering, '
          'dimensionality reduction or anomaly detection. Then state, in one '
          'phrase, what the label would have to be if it is supervised.',
        ),
      ],
      starterCode: '''
problems = {
    "predict tomorrow's electricity demand in megawatts": "?",
    "decide whether a credit card charge is fraudulent": "?",
    "group 50,000 news articles into themes nobody has named": "?",
    "compress 300 sensor readings to 10 inputs for a smaller model": "?",
    "flag server metrics that look nothing like normal operation": "?",
    "route an incoming support ticket to one of 8 teams": "?",
}

# TODO: fill in each value, e.g. "supervised regression (label: MW used)"
for question, answer in problems.items():
    print(f"{question}\\n    -> {answer}")
''',
      solutionCode: '''
problems = {
    "predict tomorrow's electricity demand in megawatts":
        "supervised regression (label: megawatts actually used that day)",
    "decide whether a credit card charge is fraudulent":
        "supervised classification (label: confirmed fraud / not fraud)",
    "group 50,000 news articles into themes nobody has named":
        "unsupervised clustering (no label exists)",
    "compress 300 sensor readings to 10 inputs for a smaller model":
        "unsupervised dimensionality reduction (e.g. PCA)",
    "flag server metrics that look nothing like normal operation":
        "anomaly detection (usually unsupervised: learn normal, flag deviation)",
    "route an incoming support ticket to one of 8 teams":
        "supervised classification (label: the team that resolved it)",
}

for question, answer in problems.items():
    print(f"{question}\\n    -> {answer}")
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Fraud detection appears as supervised classification here, but '
              'is often built as anomaly detection. What decides which?',
          expectedAnswer:
              'Whether you have enough confirmed fraud labels. With a decent '
              'history of verified fraudulent transactions, supervised '
              'classification learns the specific patterns and performs '
              'better. With almost no confirmed cases, or with novel attacks '
              'that look nothing like past ones, modelling normal behaviour '
              'and flagging deviations generalises to fraud types you have '
              'never seen.',
        ),
        SelfCheckQuestion(
          question:
              'Ticket routing uses "the team that resolved it" as the label. '
              'What could go wrong with that proxy?',
          expectedAnswer:
              'It encodes historical routing behaviour, including its '
              'mistakes: tickets bounced between teams, misrouted and then '
              'quietly fixed, or handled by whoever had capacity. The model '
              'will reproduce those patterns rather than the ideal routing, so '
              'the label needs cleaning — for example only using tickets '
              'resolved by the first team assigned.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-sup-threshold',
      title: 'Move the threshold, watch the trade',
      prompt: [
        ProseBlock(
          'A classifier has produced probabilities for 10 validation examples. '
          'Write precision_recall_at(threshold) that converts the '
          'probabilities into predictions and returns the precision and recall '
          'of the positive class, then print the trade-off across several '
          'thresholds.',
        ),
        ProseBlock(
          'Handle the degenerate case: when nothing is predicted positive, '
          'precision is undefined — return 0.0 rather than dividing by zero.',
        ),
      ],
      starterCode: '''
probs  = [0.95, 0.88, 0.71, 0.62, 0.55, 0.41, 0.33, 0.22, 0.11, 0.04]
labels = [   1,    1,    0,    1,    0,    1,    0,    0,    0,    0]


def precision_recall_at(threshold):
    """Return (precision, recall) for the positive class at this threshold."""
    ...


for t in (0.9, 0.7, 0.5, 0.3, 0.1):
    print(t, precision_recall_at(t))
''',
      solutionCode: '''
probs  = [0.95, 0.88, 0.71, 0.62, 0.55, 0.41, 0.33, 0.22, 0.11, 0.04]
labels = [   1,    1,    0,    1,    0,    1,    0,    0,    0,    0]


def precision_recall_at(threshold):
    """Return (precision, recall) for the positive class at this threshold."""
    preds = [1 if p >= threshold else 0 for p in probs]

    tp = sum(l == 1 and p == 1 for l, p in zip(labels, preds))
    fp = sum(l == 0 and p == 1 for l, p in zip(labels, preds))
    fn = sum(l == 1 and p == 0 for l, p in zip(labels, preds))

    precision = tp / (tp + fp) if tp + fp else 0.0
    recall = tp / (tp + fn) if tp + fn else 0.0
    return round(precision, 2), round(recall, 2)


for t in (0.9, 0.7, 0.5, 0.3, 0.1):
    p, r = precision_recall_at(t)
    print(f"threshold {t}: precision {p}  recall {r}")

# threshold 0.9: precision 1.0   recall 0.25
# threshold 0.7: precision 1.0   recall 0.5
# threshold 0.5: precision 0.75  recall 0.75
# threshold 0.3: precision 0.57  recall 1.0
# threshold 0.1: precision 0.44  recall 1.0
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The model never changed across those five rows. What does that '
              'say about "the accuracy of a classifier"?',
          expectedAnswer:
              'That it is not a property of the model alone. A probabilistic '
              'classifier plus a threshold is what produces labels, and moving '
              'the threshold trades precision against recall without '
              'retraining anything. Threshold-free measures such as ROC-AUC or '
              'average precision describe the model itself; a single accuracy '
              'figure describes one particular operating point.',
        ),
        SelfCheckQuestion(
          question:
              'For a screening test that must not miss a disease, which end of '
              'the threshold range do you want, and what does it cost?',
          expectedAnswer:
              'A low threshold, which maximises recall so almost no true case '
              'is missed. The cost is precision: many healthy people are '
              'flagged and must go through a confirmatory test, which consumes '
              'resources and causes anxiety. That is the correct trade when a '
              'missed case is far more harmful than a false alarm.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-sup-kmeans',
      title: 'Implement k-means and watch it converge',
      prompt: [
        ProseBlock(
          'Implement the k-means loop by hand on 2-D points: assign every '
          'point to its nearest centre, move each centre to the mean of its '
          'assigned points, repeat until the assignments stop changing. Print '
          'the total within-cluster squared distance after each iteration and '
          'confirm it never increases.',
        ),
      ],
      starterCode: '''
points = [(1, 1), (1.5, 2), (3, 4), (5, 7), (3.5, 5), (4.5, 5), (3.5, 4.5)]
centres = [(1, 1), (5, 7)]      # k = 2, initialised from two data points


def nearest(point, centres):
    """Return the index of the closest centre."""
    ...


def kmeans(points, centres, max_iters=10):
    """Run assign/update until assignments stop changing."""
    ...


print(kmeans(points, centres))
''',
      solutionCode: '''
points = [(1, 1), (1.5, 2), (3, 4), (5, 7), (3.5, 5), (4.5, 5), (3.5, 4.5)]
centres = [(1, 1), (5, 7)]      # k = 2, initialised from two data points


def sq_dist(a, b):
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2


def nearest(point, centres):
    """Return the index of the closest centre."""
    return min(range(len(centres)), key=lambda i: sq_dist(point, centres[i]))


def inertia(points, centres, labels):
    return sum(sq_dist(p, centres[c]) for p, c in zip(points, labels))


def kmeans(points, centres, max_iters=10):
    """Run assign/update until assignments stop changing."""
    centres = list(centres)
    labels = None

    for step in range(max_iters):
        new_labels = [nearest(p, centres) for p in points]
        if new_labels == labels:
            break                                  # converged
        labels = new_labels

        for c in range(len(centres)):
            members = [p for p, l in zip(points, labels) if l == c]
            if members:                            # never divide by zero
                centres[c] = (
                    sum(p[0] for p in members) / len(members),
                    sum(p[1] for p in members) / len(members),
                )
        print(step, [round(x, 2) for pair in centres for x in pair],
              round(inertia(points, centres, labels), 3))

    return centres, labels


final_centres, final_labels = kmeans(points, centres)
print(final_labels)     # [0, 0, 1, 1, 1, 1, 1]
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why is k-means guaranteed to converge, and why is that not the '
              'same as finding the best clustering?',
          expectedAnswer:
              'Both steps can only decrease the inertia — reassigning to the '
              'nearest centre cannot increase a point\'s distance, and moving '
              'a centre to its members\' mean minimises their squared '
              'distances — and there are finitely many assignments, so the '
              'process must stop. But it stops at a local minimum determined '
              'by the initialisation; a different start can give a different '
              'and better clustering, which is why implementations run several '
              'restarts and keep the best.',
        ),
        SelfCheckQuestion(
          question:
              'One feature is measured in metres and another in millimetres. '
              'What happens to k-means, and what fixes it?',
          expectedAnswer:
              'Euclidean distance is dominated by the large-magnitude feature, '
              'so the millimetre column effectively decides every assignment '
              'and the metre column is ignored. Standardise the features — '
              'subtract the mean and divide by the standard deviation — before '
              'clustering, fitting the scaler on the training data only.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-sup-pca-variance',
      title: 'Find how many PCA components keep 95% variance',
      prompt: [
        ProseBlock(
          'Given the digits dataset (64 features), write a function that '
          'returns the smallest number of PCA components that retain at '
          'least 95% of the variance. Use explained_variance_ratio_ and '
          'cumulative sum. Then explain what information the discarded '
          'components carried.',
        ),
      ],
      starterCode: '''
from sklearn.datasets import load_digits
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler

X, _ = load_digits(return_X_y=True)
X_scaled = StandardScaler().fit_transform(X)


def pca_components_for_variance(X, threshold=0.95):
    """Return the smallest n_components retaining >= threshold variance."""
    # TODO: fit PCA with all components, cumsum the explained ratios
    ...


n = pca_components_for_variance(X_scaled)
print(f"Components for 95% variance: {n}")
''',
      solutionCode: '''
import numpy as np
from sklearn.datasets import load_digits
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler

X, _ = load_digits(return_X_y=True)
X_scaled = StandardScaler().fit_transform(X)


def pca_components_for_variance(X, threshold=0.95):
    """Return the smallest n_components retaining >= threshold variance."""
    pca = PCA().fit(X)     # fit all 64 components
    cumsum = np.cumsum(pca.explained_variance_ratio_)
    # cumsum[i] = variance retained by the first i+1 components
    n = int(np.searchsorted(cumsum, threshold) + 1)
    return n, cumsum[n - 1]


n, var = pca_components_for_variance(X_scaled)
print(f"Components for 95% variance: {n} (retains {var:.3f})")
# Typically around 29-32 components out of 64.
# The discarded ~35 components carry only 5% of the variance — likely
# noise, fine pixel-level variation, or empty border regions. Keeping
# them adds dimensionality without adding signal.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'PCA(n_components=10) on this dataset would discard ~30% of '
              'the variance. When is that acceptable?',
          expectedAnswer:
              'When you are using PCA as a preprocessing step for a model '
              'that benefits from lower dimensionality (e.g. a kNN '
              'classifier, or when memory is tight) and the discarded '
              'variance is mostly noise rather than signal. The cross-'
              'validated downstream metric is the arbiter: if classification '
              'accuracy does not drop meaningfully with 10 components, '
              'the discarded directions were not carrying class-relevant '
              'information. PCA minimises reconstruction error, which is '
              'not the same as maximising discriminability — directions '
              'with low variance can still carry the class signal.',
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
              'Supervised versus unsupervised in five minutes. Imagine '
              'teaching a child. Supervised learning is flashcards — you show a '
              'picture of a cat, you say "cat". The answer is right there on '
              'the card. Unsupervised learning is handing the child a pile of '
              'animal photos with no labels and saying "sort these into groups '
              'that belong together." No answers provided — just structure to '
              'be found.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Supervised splits by label type. Classification is multiple '
              'choice — is this email spam or not, what animal is in this '
              'photo. Regression is a number line — what price will this house '
              'sell for, what will the temperature be. This sounds obvious but '
              'it determines your loss function and every metric, so settle it '
              'before you write any code. And remember: classifiers output '
              'probabilities, not labels. You pick the cutoff.',
          startMs: 42000,
          endMs: 88000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'On the unsupervised side, three tools cover most of the ground. '
              'Clustering groups similar rows — like sorting a messy Lego pile '
              'by colour with no bins labelled. Dimensionality reduction '
              'squeezes fifty measurements into three that capture the gist — '
              'like summarising a novel into a single page. Anomaly detection '
              'learns what "normal" looks like and rings an alarm on anything '
              'weird. All three describe the data rather than predict anything '
              'about it.',
          startMs: 88000,
          endMs: 134000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'The hard part of unsupervised work is that there is no answer '
              'key. No ground truth means no accuracy score. You lean on '
              'internal measures like silhouette — are my groups tight and '
              'well-separated? You check stability — do I get the same clusters '
              'if I rerun with a different random seed? And the most honest '
              'test: does using these clusters or components make a downstream '
              'task better? If not, the pretty groupings might just be noise.',
          startMs: 134000,
          endMs: 180000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Two practical warnings to close. First, standardise your '
              'features before any distance-based method — k-means, PCA, '
              'anything that uses "closeness". Otherwise the column measured in '
              'the biggest units silently dominates and your results are '
              'garbage. Second, beware the proxy label. If you cannot observe '
              'what you actually care about and substitute something you can '
              'measure, the model will optimise your proxy with terrifying '
              'precision — including all the ways the proxy is wrong.',
          startMs: 180000,
          endMs: 222000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 504000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Let me open with an image that makes the whole taxonomy click. '
              'Walk into a kitchen. On one counter are labelled jars — flour, '
              'sugar, salt. You know exactly what each one is because someone '
              'put a label on it. That is supervised learning: every example '
              'comes with the answer attached. On the other counter are '
              'unlabelled jars. You cannot name them, but you can sort them — '
              'these three smell sweet, those two feel grainy. That is '
              'unsupervised learning. The single question is: do you have '
              'labels?',
          startMs: 0,
          endMs: 50000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'And labels are more expensive than people realise. Sometimes a '
              'human annotates every row — a radiologist looking at scans, a '
              'lawyer reviewing contracts. Sometimes you wait months for the '
              'outcome to reveal itself — did this customer actually churn, '
              'did this loan actually default. Sometimes you take a proxy you '
              'can measure instead of the truth you want — clicks instead of '
              'satisfaction, arrests instead of crime. That cost of labels is '
              'the entire reason the middle ground exists: semi-supervised '
              'learning with a few labelled examples and mountains of '
              'unlabelled ones.',
          startMs: 50000,
          endMs: 116000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Within supervised learning, the split is by what comes out. '
              'Classification gives you a category — spam or not spam, which of '
              'ten digits, fraud or legitimate. Regression gives you a number — '
              'a price, a temperature, a duration. And here is a subtlety that '
              'matters: classifiers do not output labels, they output '
              'probabilities. The model says "I am 73% sure this is fraud". '
              'You decide the cutoff. Flag everything above 30% if missing '
              'fraud is catastrophic. Flag only above 90% if blocking a '
              'legitimate customer is the real disaster. That threshold is a '
              'business decision wearing a statistical mask.',
          startMs: 116000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Which is exactly why quoting "95% accuracy" without context is '
              'misleading. Think of airport security. Precision says: of the '
              'bags I flagged, how many actually had contraband? Recall says: '
              'of the bags that actually had contraband, how many did I catch? '
              'Lower the threshold and recall goes up — you catch more — but '
              'precision drops — you also flag more innocent bags. Every time. '
              'You decide which error costs more. The model just gives you the '
              'probabilities; the trade-off is yours.',
          startMs: 182000,
          endMs: 250000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Regression metrics have the same shape. Mean absolute error '
              'treats every dollar of error equally — be off by ten dollars '
              'ten times, that is a hundred. Mean squared error squares the '
              'errors first, so one catastrophic miss of a hundred dollars '
              'weighs as much as a hundred tiny misses of ten dollars each. If '
              'your business truly cannot tolerate one enormous underestimation '
              '— a hospital predicting bed demand, say — the squaring is a '
              'feature. If not, MAE is easier to explain to stakeholders and '
              'less thrown off by a single weird row.',
          startMs: 250000,
          endMs: 318000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Over to unsupervised. K-means is the workhorse: pick K, scatter '
              'K centres randomly, assign every point to the nearest centre, '
              'move each centre to the average of its members, repeat until '
              'stable. It is fast and it assumes your groups are roughly '
              'spherical blobs of similar size. DBSCAN takes a different '
              'approach — it grows clusters from dense neighbourhoods, so it '
              'finds arbitrary shapes, figures out its own number of clusters, '
              'and can label sparse points as noise rather than forcing them '
              'into a group. PCA is the linear compressor: find the directions '
              'with the most spread in your data and project everything onto '
              'just the top few.',
          startMs: 318000,
          endMs: 388000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'The evaluation problem with unsupervised methods is real and '
              'uncomfortable. No answer key means no accuracy score. You fall '
              'back on three things. Internal measures like silhouette that '
              'score whether your clusters are tight and well-separated — '
              'but they reward whatever shape the algorithm naturally '
              'produces. Stability across random seeds and subsamples — if '
              'rerunning gives you different groups, you are describing noise. '
              'And the most honest test: downstream usefulness. Put those '
              'clusters or compressed features into a supervised pipeline. '
              'Does the score improve? If not, your beautiful clusters might '
              'be an expensive way of doing nothing.',
          startMs: 388000,
          endMs: 452000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'One rule to leave with, and it connects back to everything we '
              'have said about honest evaluation. Any unsupervised step that '
              'learns statistics — a scaler, PCA, an imputer — must be fitted '
              'inside the cross-validation loop, on the training fold only. '
              'Fit PCA on the entire dataset before splitting and you have '
              'leaked information from the test set into your features before '
              'you have even picked a model. Your validation score is now '
              'inflated in a way that disappears the moment you deploy. Wrap '
              'everything in a Pipeline and this correct behaviour is free.',
          startMs: 452000,
          endMs: 504000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 864000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Deep dive on learning paradigms. Picture a detective\'s desk. '
              'On the left are case files where the culprit is already circled '
              'in red — that is supervised learning. On the right are piles of '
              'evidence with no conclusions drawn — that is unsupervised. And '
              'in the middle, a clever trick: the detective takes the unlabelled '
              'evidence and creates puzzles from it — hide a detail, guess what '
              'was hidden — that is self-supervised learning, and it is how '
              'every modern language model gets its start.',
          startMs: 0,
          endMs: 64000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Let me say something uncomfortable that frames the whole '
              'discussion. A supervised model does not learn the truth. It '
              'learns whatever the labels encode — faithfully, including every '
              'error, every bias, every lazy shortcut the annotators took. If '
              'your labels are "who was convicted of the crime", the model '
              'learns to predict convictions, not crimes. If your labels are '
              '"clicks", the model learns to predict what gets clicked, not '
              'what is useful. The model is a mirror held up to your labelling '
              'process. It reflects, it does not correct.',
          startMs: 64000,
          endMs: 142000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Which makes label provenance a first-class question that '
              'deserves more attention than architecture choice. Who produced '
              'these labels? Under what instructions? With what agreement rate '
              'between different annotators? If two radiologists disagree on '
              'twenty percent of scans, your model cannot meaningfully exceed '
              'eighty percent — the remaining gap is not modelling error, it '
              'is annotator noise. Chasing those last few points is chasing '
              'the variance in human judgment, and no amount of GPU time '
              'resolves a genuine ambiguity in the task itself.',
          startMs: 142000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Classification metrics deserve a proper unpacking. Every metric '
              'is built from four cells in a 2x2 table. True positives: you '
              'flagged it, it was real. False positives: you flagged it, it '
              'was innocent. True negatives: you ignored it, correctly. False '
              'negatives: you ignored it, and should not have. Precision is TP '
              'divided by everything you flagged. Recall is TP divided by '
              'everything that was actually positive. F1 is their harmonic '
              'mean — which punishes lopsidedness more than a regular average '
              'would, so you cannot cheat by gaming one at the expense of the '
              'other.',
          startMs: 214000,
          endMs: 292000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Then the curves. The ROC curve plots true positive rate against '
              'false positive rate as you sweep the threshold, and its area '
              'under the curve — ROC-AUC — summarises ranking quality. But '
              'here is the catch: on heavily imbalanced data where positives '
              'are rare, the false positive rate has an enormous denominator '
              'of true negatives, so the curve looks flattering. The '
              'precision-recall curve is far more honest when positives are '
              'rare, because it ignores the overwhelming sea of true negatives '
              'and focuses on what happens among the things you actually '
              'flagged.',
          startMs: 292000,
          endMs: 372000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'And calibration — the metric everyone forgets until production. '
              'A model can rank perfectly and still have garbage probabilities. '
              'Saying "90% confidence" when it is actually right 70% of the '
              'time means downstream systems that multiply that number by a '
              'dollar cost are making systematically wrong decisions. You '
              'check calibration with a reliability diagram — a simple plot of '
              'predicted probability versus actual frequency — and fix it with '
              'Platt scaling or isotonic regression on a held-out calibration '
              'set. It is the difference between a model that is directionally '
              'correct and a model whose numbers you can actually trust.',
          startMs: 372000,
          endMs: 450000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Over to unsupervised. K-means minimizes total within-cluster '
              'squared distance — every point wants to be near its cluster '
              'centre. This implicitly assumes spherical, equally sized, '
              'equally dense groups. Hand it two interlocking crescent shapes '
              'and it draws a straight line right through the middle. Gaussian '
              'mixture models relax this with per-cluster covariance — '
              'elongated shapes are fine. DBSCAN drops parametric assumptions '
              'entirely: it defines clusters as regions of high density '
              'separated by regions of low density. That is why it handles '
              'crescents and rings that destroy k-means.',
          startMs: 450000,
          endMs: 534000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Dimensionality reduction splits cleanly by purpose. PCA is '
              'linear, orthogonal, fast, and reversible — you can project down '
              'to 20 dimensions and back up to 500, and the reconstruction '
              'error tells you exactly what you lost. Use it as preprocessing '
              'for models that struggle in high dimensions, or as a denoiser. '
              't-SNE and UMAP are for visualization only. They preserve local '
              'neighbourhoods beautifully while deliberately distorting global '
              'distances, so cluster sizes and gaps between clusters in those '
              'plots mean far less than they appear to. Do not use them as '
              'features in a downstream model.',
          startMs: 534000,
          endMs: 618000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'The evaluation gap is structural and honest people acknowledge '
              'it. Internal indices — silhouette, Davies-Bouldin, '
              'Calinski-Harabasz — score geometric properties like compactness '
              'and separation. But they reward whatever shape the algorithm '
              'naturally produces. A k-means run scores well by its own '
              'criterion because the criterion is what k-means was optimising. '
              'External indices like adjusted Rand need ground truth labels, '
              'which you do not have. So stability analysis — rerunning on '
              'bootstrapped subsamples and measuring partition consistency — '
              'and downstream utility carry most of the weight in practice.',
          startMs: 618000,
          endMs: 694000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Now the paradigm that reshaped the entire field. Self-supervised '
              'learning manufactures supervision from unlabelled data. Mask a '
              'word in a sentence and predict it. Predict the next token. Take '
              'two differently cropped views of the same photo and train the '
              'model to recognise they are the same object. There is zero '
              'annotation cost, so you can train on the entire internet. The '
              'representations that fall out transfer to downstream tasks with '
              'remarkably few labelled examples — sometimes just a few hundred. '
              'This is the engine behind BERT, GPT, CLIP, and essentially '
              'every modern foundation model.',
          startMs: 694000,
          endMs: 774000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Which completely inverts the practical advice from a decade ago. '
              'The default for text and images today is not "train a supervised '
              'model from scratch". It is "grab a pre-trained model from the '
              'Hugging Face hub and fine-tune it". That changes what a small '
              'labelled dataset is worth by an order of magnitude — a few '
              'hundred examples can now do what used to require tens of '
              'thousands. The honourable exception is structured tabular data '
              'like spreadsheets, where gradient-boosted trees remain '
              'stubbornly hard to beat, and self-supervised pre-training has '
              'had far less impact.',
          startMs: 774000,
          endMs: 838000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Closing thought: framing is where ML projects are truly won or '
              'lost, and it happens before any code is written. Write down the '
              'decision the output will change. Then the label that decision '
              'implies. Then what that label costs to obtain. If the honest '
              'answer is that the label does not exist — you have an '
              'unsupervised or self-supervised problem. Pretending otherwise '
              'with a convenient proxy — clicks for usefulness, arrests for '
              'crime — is how systems end up optimising the wrong thing with '
              'devastating efficiency. The algorithm is not the dangerous part. '
              'The proxy is.',
          startMs: 838000,
          endMs: 864000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Labels decide the paradigm',
      body:
          'Supervised learning maps features to known answers; unsupervised '
          'learning describes structure when no answers exist. '
          'Semi-supervised mixes a small labelled set with a large unlabelled '
          'one, and self-supervised manufactures labels from the data itself — '
          'which is how modern text and vision models are pre-trained.',
    ),
    SummaryCard(
      title: 'Task type drives loss and metric',
      body:
          'Classification predicts a category and is scored with precision, '
          'recall, F1 and ROC-AUC; regression predicts a number and is scored '
          'with MAE, RMSE and R². A classifier outputs probabilities, so the '
          'threshold — and therefore the precision/recall trade — is your '
          'decision, not the model\'s.',
    ),
    SummaryCard(
      title: 'Unsupervised results need more scepticism',
      body:
          'With no ground truth, evaluate with internal measures such as '
          'silhouette, with stability across seeds and subsamples, and above '
          'all with downstream usefulness. Standardise before any '
          'distance-based method, and fit scalers and PCA inside the '
          'cross-validation loop to avoid leakage.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Supervised learning',
      definition:
          'Learning a mapping from features to a known target using labelled '
          'examples. Splits into classification (categorical target) and '
          'regression (continuous target).',
    ),
    KeyConcept(
      term: 'Unsupervised learning',
      definition:
          'Finding structure in unlabelled data: clustering similar rows, '
          'reducing dimensionality, or identifying anomalies. There is no '
          'prediction target and therefore no direct accuracy measure.',
    ),
    KeyConcept(
      term: 'Precision vs recall',
      definition:
          'Precision is the fraction of predicted positives that were '
          'correct; recall is the fraction of actual positives that were '
          'found. Lowering the decision threshold raises recall and lowers '
          'precision.',
    ),
    KeyConcept(
      term: 'K-means',
      definition:
          'A clustering algorithm that alternates assigning points to the '
          'nearest of k centres and moving each centre to its members\' mean. '
          'It converges to a local minimum of within-cluster squared distance '
          'and assumes roughly spherical, similarly sized clusters.',
    ),
    KeyConcept(
      term: 'PCA',
      definition:
          'Principal component analysis: an orthogonal linear projection onto '
          'the directions of greatest variance. Used to compress features, '
          'denoise, and visualise, with explained_variance_ratio_ reporting '
          'how much information each component retains.',
    ),
    KeyConcept(
      term: 'Self-supervised learning',
      definition:
          'Generating training signal from unlabelled data by hiding part of '
          'the input and predicting it. Yields general-purpose '
          'representations that can be fine-tuned on small labelled datasets.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Treating k-means cluster ids as class labels with inherent '
          'meaning.',
      correction:
          'Cluster numbering is arbitrary and changes between runs. A cluster '
          'means whatever its members turn out to have in common, which you '
          'establish afterwards by inspecting them — not by reading the '
          'integer the algorithm assigned.',
    ),
    Mistake(
      mistake:
          'Running k-means or PCA on raw, unscaled features.',
      correction:
          'Both are distance- and variance-based, so a column measured in '
          'large units dominates and the others are effectively ignored. '
          'Standardise first, fitting the scaler on the training fold only.',
    ),
    Mistake(
      mistake:
          'Reporting one accuracy figure for a probabilistic classifier.',
      correction:
          'That figure describes a single threshold, not the model. Report '
          'precision and recall at the operating point you will actually ship, '
          'plus a threshold-free measure such as average precision or ROC-AUC '
          'for the model itself.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'How would you decide whether to frame a churn problem as supervised '
          'classification or as clustering?',
      answer:
          'It depends on the decision the output supports. If the business '
          'wants to intervene with individual customers likely to leave, that '
          'is supervised classification and it needs a labelled history of who '
          'actually churned within a defined window, plus features available '
          'before that window. If the business wants to understand what kinds '
          'of customers exist so it can design distinct propositions, that is '
          'clustering and no labels are required. In practice teams often do '
          'both — cluster to understand the population, then train a '
          'classifier per segment or add the segment as a feature — but the '
          'two answer different questions and only one produces a prediction '
          'you can act on per customer.',
    ),
    InterviewQuestion(
      question:
          'Your fraud classifier reports 99.4% accuracy. Are you satisfied?',
      answer:
          'No, because accuracy is meaningless on data where fraud might be '
          '0.5% of transactions — predicting "not fraud" always would score '
          '99.5% and catch nothing. I would look at the confusion matrix, then '
          'precision and recall on the fraud class, and the precision-recall '
          'curve rather than ROC-AUC because the negative class is so large '
          'that the false positive rate stays flattering. I would also want to '
          'know the operating threshold, the cost of a missed fraud versus a '
          'blocked legitimate transaction, and whether the evaluation split '
          'respected time and cardholder grouping — random splitting across '
          'those leaks and inflates every number.',
    ),
    InterviewQuestion(
      question:
          'How do you evaluate a clustering when there is no ground truth?',
      answer:
          'Three complementary approaches. Internal validity measures — '
          'silhouette, Davies-Bouldin, Calinski-Harabasz — score compactness '
          'and separation using only the data, but they reward the geometry '
          'the algorithm was optimising, so they are weak evidence on their '
          'own. Stability analysis re-runs the clustering on bootstrapped '
          'subsamples or different seeds and measures how consistent the '
          'partitions are; an unstable clustering is describing noise. Best of '
          'all is extrinsic usefulness: does adding the cluster assignment '
          'improve a downstream supervised model, or does a domain expert '
          'recognise the groups as meaningful and actionable? I would also '
          'sanity-check cluster sizes and inspect representative members '
          'before presenting anything.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'Supervised learning — scikit-learn docs',
    url: 'https://scikit-learn.org/stable/supervised_learning.html',
    description:
        'Reference for the supervised estimators: linear models, SVMs, trees '
        'and ensembles, with the fit/predict API used throughout this lesson.',
  ),
  Source(
    title: 'Unsupervised learning — scikit-learn docs',
    url: 'https://scikit-learn.org/stable/unsupervised_learning.html',
    description:
        'Reference for clustering, decomposition and outlier detection, '
        'including the assumptions and failure modes of each algorithm.',
  ),
];

const List<Source> _furtherReading = <Source>[
  Source(
    title: 'A Tutorial on PCA (Shlens, 2014)',
    url: 'https://arxiv.org/abs/1404.1100',
    description:
        'Clear derivation of PCA from maximum variance and minimum '
        'reconstruction error perspectives, with practical guidance on '
        'choosing the number of components.',
  ),
  Source(
    title: 'How to Use t-SNE Effectively — Distill.pub',
    url: 'https://distill.pub/2016/misread-tsne/',
    description:
        'Interactive guide to t-SNE: what it preserves, what it distorts '
        '(cluster sizes, global distances), and how to avoid misreading '
        'its output.',
  ),
  Source(
    title: 'Clustering — scikit-learn User Guide',
    url: 'https://scikit-learn.org/stable/modules/clustering.html',
    description:
        'Comprehensive comparison of k-means, DBSCAN, hierarchical and '
        'Gaussian mixture clustering with their assumptions and failure modes.',
  ),
  Source(
    title: 'Deep Transfer Learning for NLP — Hugging Face Course',
    url: 'https://huggingface.co/learn/nlp-course/chapter1/1',
    description:
        'Practical introduction to loading pre-trained transformers and '
        'fine-tuning on small labelled datasets, plus parameter-efficient '
        'alternatives like adapters and LoRA.',
  ),
];
