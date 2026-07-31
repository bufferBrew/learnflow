import '../../models/content_block.dart';
import '../../models/exercise.dart';
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
              'The paradigms, quickly. Supervised learning has labels: every '
              'training row comes with the right answer, and the model learns '
              'the mapping from inputs to answers. Unsupervised learning has '
              'no labels at all, so instead of predicting it describes '
              'structure in the data.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Supervised splits by label type. Categorical label, that is '
              'classification. Continuous number, that is regression. It '
              'sounds trivial but it determines your loss function and every '
              'metric you will report, so settle it before you write any code.',
          startMs: 42000,
          endMs: 88000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'On the unsupervised side: clustering groups similar rows, '
              'dimensionality reduction squeezes many features into a few, and '
              'anomaly detection learns what normal looks like so it can flag '
              'what is not. All three describe the data rather than predicting '
              'anything about it.',
          startMs: 88000,
          endMs: 134000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'The hard part of unsupervised work is that there is no answer '
              'key, so nothing tells you whether the output is right. You lean '
              'on internal measures like silhouette, on stability across '
              'random seeds, and mostly on whether the result is actually '
              'useful downstream.',
          startMs: 134000,
          endMs: 180000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And two practical warnings. Standardise your features before '
              'anything distance-based, or the biggest-unit column wins by '
              'accident. And if you cannot observe the thing you care about, '
              'think hard before substituting a proxy label — the model will '
              'optimise the proxy exactly, including where it diverges from '
              'what you meant.',
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
              'The cleanest way into this topic is the API. In scikit-learn, '
              'supervised estimators are fit of X comma y, and unsupervised '
              'ones are fit of X. That single difference is the whole '
              'taxonomy: is there a column of correct answers, or is there '
              'not?',
          startMs: 0,
          endMs: 50000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'And labels are more expensive than beginners assume. Sometimes '
              'a human annotates every row. Sometimes you wait months for the '
              'outcome — did this loan default, did this customer churn. '
              'Sometimes you take a proxy you can measure instead of the thing '
              'you want. That cost is why the middle ground exists at all.',
          startMs: 50000,
          endMs: 116000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Within supervised, classification versus regression. Predicting '
              'which of five categories: classification. Predicting a number '
              'on a continuous scale: regression. And note that classifiers '
              'really output probabilities — the hard label comes from a '
              'threshold that you choose, and that choice is a product '
              'decision, not a modelling one.',
          startMs: 116000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Which is why quoting a single accuracy number is so '
              'misleading. Precision is: of the things I flagged, how many '
              'were real. Recall is: of the real ones, how many did I catch. '
              'Drop the threshold and recall rises while precision falls, '
              'every time. Decide which error costs more before you pick an '
              'operating point.',
          startMs: 182000,
          endMs: 250000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Regression metrics have the same character. Mean absolute error '
              'treats every pound of error equally. Mean squared error squares '
              'them, so one enormous miss outweighs many small ones. If a '
              'single catastrophic underestimate is what actually hurts your '
              'business, that squaring is a feature. If not, MAE is easier to '
              'explain and more robust to outliers.',
          startMs: 250000,
          endMs: 318000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Unsupervised side. K-means is fast and assumes roughly '
              'spherical, similar-sized clusters, and it makes you pick k. '
              'DBSCAN grows clusters from dense regions, finds arbitrary '
              'shapes, picks its own count and can label points as noise. PCA '
              'is the linear compressor: it finds the directions of greatest '
              'variance and keeps the leading ones.',
          startMs: 318000,
          endMs: 388000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'The evaluation problem is real. With no ground truth you fall '
              'back on three things: internal measures like silhouette that '
              'score compactness and separation, stability across seeds and '
              'subsamples, and downstream usefulness. That last one is the '
              'honest test — put the clusters or components into a supervised '
              'pipeline and see whether the score improves.',
          startMs: 388000,
          endMs: 452000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'One rule to leave with: any unsupervised step that learns '
              'statistics — a scaler, PCA — must be fitted inside the '
              'cross-validation loop, on the training fold only. Fit PCA on '
              'the whole dataset first and you have leaked the validation set '
              'into your features before choosing a model. Wrap it in a '
              'Pipeline and the correct behaviour is free.',
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
              'Long form on learning paradigms. The plan: what supervision '
              'actually is, why the label is the expensive part, the full '
              'supervised metric landscape, the unsupervised toolkit and its '
              'evaluation problem, the self-supervised revolution, and how to '
              'frame a real problem without picking the wrong paradigm '
              'entirely.',
          startMs: 0,
          endMs: 64000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Supervision means an external signal telling the algorithm what '
              'the right output was. That signal defines the loss, and the '
              'loss defines everything the model becomes. So it is worth '
              'saying plainly: a supervised model does not learn the truth. It '
              'learns whatever the labels encode, faithfully, including their '
              'errors and their biases.',
          startMs: 64000,
          endMs: 142000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Which is why label provenance is a first-class question. Who '
              'produced these labels, under what instructions, with what '
              'agreement rate between annotators? If two humans disagree '
              'twenty percent of the time, your model cannot meaningfully '
              'exceed eighty percent, and chasing the last few points is '
              'chasing annotator noise.',
          startMs: 142000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Classification metrics deserve unpacking. Start with the '
              'confusion matrix — true positives, false positives, true '
              'negatives, false negatives — because every metric is a ratio '
              'built from those four cells. Precision is TP over predicted '
              'positive. Recall is TP over actual positive. F1 is their '
              'harmonic mean, which punishes imbalance between them more than '
              'an average would.',
          startMs: 214000,
          endMs: 292000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Then the curves. ROC plots true positive rate against false '
              'positive rate across all thresholds, and its area summarises '
              'ranking quality. But on heavily imbalanced data ROC-AUC looks '
              'flattering, because the false positive rate has an enormous '
              'denominator. The precision-recall curve and average precision '
              'are far more informative when positives are rare.',
          startMs: 292000,
          endMs: 372000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'And calibration is the metric people forget. A model can rank '
              'perfectly and still have meaningless probabilities — saying '
              'zero point nine when it is right seventy percent of the time. '
              'If a downstream system multiplies that probability by a cost, '
              'you need calibration, which you check with a reliability '
              'diagram and fix with Platt scaling or isotonic regression.',
          startMs: 372000,
          endMs: 450000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Over to unsupervised. K-means minimises within-cluster squared '
              'distance, which implicitly assumes spherical, equally sized, '
              'equally dense groups. Gaussian mixtures relax that with '
              'per-cluster covariance and give soft assignments. DBSCAN drops '
              'the parametric assumption entirely and defines clusters as '
              'dense regions, which is why it handles crescents and rings that '
              'defeat k-means.',
          startMs: 450000,
          endMs: 534000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Dimensionality reduction splits by purpose. PCA is linear, '
              'orthogonal, fast and invertible — good as preprocessing, good '
              'for denoising, and its explained-variance ratio tells you '
              'exactly what you kept. t-SNE and UMAP are for looking at data, '
              'not for feature engineering: they preserve local neighbourhoods '
              'while distorting global distances, so cluster sizes and '
              'inter-cluster gaps in those plots mean much less than they '
              'appear to.',
          startMs: 534000,
          endMs: 618000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'The evaluation gap is structural. Internal indices — '
              'silhouette, Davies-Bouldin — score geometric properties, which '
              'is not the same as scoring correctness, and they favour '
              'whatever shape the algorithm produces. External indices like '
              'adjusted Rand need labels, which you do not have. So stability '
              'analysis and downstream utility carry most of the weight in '
              'practice.',
          startMs: 618000,
          endMs: 694000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Now the paradigm that reshaped the field: self-supervised '
              'learning. You manufacture supervision from unlabelled data — '
              'mask a token and predict it, predict the next token, match two '
              'augmented views of the same image. There is no annotation cost, '
              'so you can train on enormous corpora, and the representations '
              'transfer to tasks with only a few hundred labels.',
          startMs: 694000,
          endMs: 774000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'That inverts the practical advice. The default for text and '
              'images is no longer "train supervised from scratch" but '
              '"fine-tune a pre-trained model", which changes what a small '
              'labelled dataset is worth by an order of magnitude. Structured '
              'tabular data is the honourable exception, where gradient-boosted '
              'trees remain extremely hard to beat.',
          startMs: 774000,
          endMs: 838000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Closing thought: framing is where projects are won or lost. '
              'Write down the decision the output will change, then the label '
              'that decision implies, then what that label costs to obtain. If '
              'the honest answer is that the label does not exist, you have an '
              'unsupervised or self-supervised problem — and pretending '
              'otherwise with a convenient proxy is how systems end up '
              'optimising the wrong thing very efficiently.',
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
