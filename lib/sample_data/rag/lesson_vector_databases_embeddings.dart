import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 2: the dense vectors retrieval is built on, how they are
/// compared, and the indexes and databases that make searching billions of
/// them fast.
const Lesson vectorDatabasesEmbeddingsLesson = Lesson(
  id: 'rag-vector-databases-embeddings',
  title: 'Vector Databases & Embeddings',
  description:
      'How embeddings encode meaning as geometry, which similarity metric to '
      'use when, and how HNSW and IVF indexes make nearest-neighbour search '
      'fast at scale.',
  estimatedMinutes: 27,
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
      id: 'embeddings-recap',
      heading: 'Embeddings: geometry standing in for meaning',
      blocks: [
        ProseBlock(
          'Retrieval needs a way to compare a query to a document that does '
          'not depend on the two sharing words, because the whole point of '
          'semantic search is finding the right passage even when the '
          'question is phrased nothing like it. The tool for that is the '
          'embedding: a dense vector of a few hundred to a few thousand real '
          'numbers, produced by an embedding model, positioned so that things '
          'meaning similar things land close together in the space.',
        ),
        ProseBlock(
          'An embedding model is trained, not designed — nobody hand-picks '
          'what each of the 768 or 1536 dimensions means. What is designed is '
          'the training signal: pairs of texts known to be related (a '
          'question and its correct answer, a sentence and its paraphrase, a '
          'search query and the document a user actually clicked) are pulled '
          'together in the space, and unrelated pairs are pushed apart. That '
          'objective is usually called contrastive learning, and it is worth '
          'a moment of intuition even without the underlying loss function.',
        ),
        ProseBlock(
          'Concretely: take a batch of matched pairs — say, a hundred '
          '(question, correct-passage) examples. For each question, its own '
          'passage is the positive, and every other passage in the batch is '
          'treated as a negative. Training nudges the question\'s vector '
          'closer to its positive and further from all the in-batch '
          'negatives, simultaneously, across every example in the batch. '
          'Repeat over millions of pairs and the model has no choice but to '
          'organise its space so that "related" reliably means "nearby".',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Retrieval embeddings are not the same model as generation',
          text:
              'A RAG pipeline typically uses a small, purpose-trained '
              'embedding model for retrieval — optimised purely for '
              'question-to-passage similarity — and a separate, much larger '
              'LLM for generation. Conflating the two is a common '
              'misconception: the model that writes the answer is rarely the '
              'same model, or even the same architecture family, as the one '
              'that found the passage.',
        ),
      ],
    ),
    Section(
      id: 'similarity-metrics',
      heading: 'Cosine, dot product, Euclidean: picking the right ruler',
      blocks: [
        ProseBlock(
          'Once two things are vectors, "similar" needs a precise '
          'definition, and the three candidates behave differently enough '
          'that the choice matters. Cosine similarity measures the angle '
          'between two vectors and ignores their length entirely, which '
          'makes it robust to one document being much longer than another — '
          'a common situation in real corpora, where chunk lengths vary.',
        ),
        ProseBlock(
          'Dot product measures both angle and magnitude at once: two '
          'vectors pointing the same direction but with different lengths '
          'produce different dot products, so it silently rewards larger-'
          'magnitude vectors regardless of whether they are actually a '
          'better match. That sounds like a strict downside until the '
          'vectors are normalised to unit length first — at which point '
          'cosine similarity and dot product become the exact same '
          'computation, and the dot product is faster because it skips the '
          'division. This is why most vector databases normalise at index '
          'time and expose "dot product" or "inner product" as their default '
          'metric rather than computing cosine similarity from scratch on '
          'every query.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np

a = np.array([0.9, 0.1, 0.2])
b = np.array([1.8, 0.2, 0.4])       # same direction as a, twice the length


def cosine_similarity(x, y):
    return float(x @ y / (np.linalg.norm(x) * np.linalg.norm(y)))


def dot(x, y):
    return float(x @ y)


print(round(cosine_similarity(a, b), 3))   # 1.0   -- identical direction
print(round(dot(a, b), 3))                 # 1.71  -- inflated by b's length

# Normalise first, and dot product recovers cosine similarity exactly.
a_unit = a / np.linalg.norm(a)
b_unit = b / np.linalg.norm(b)
print(round(dot(a_unit, b_unit), 3))       # 1.0   -- same as cosine, no division
''',
          caption:
              'Two vectors pointing the same way score a perfect 1.0 on '
              'cosine similarity regardless of length — dot product on '
              'un-normalised vectors would have ranked the longer one '
              'higher purely for being longer.',
        ),
        ProseBlock(
          'Euclidean distance measures straight-line distance in the space '
          'rather than angle, and it is sensitive to magnitude in the same '
          'way raw dot product is, just inverted — smaller distance means '
          'more similar rather than a larger score. It is the natural choice '
          'when a model was specifically trained to make Euclidean distance '
          'meaningful (some embedding models are), and a poor default '
          'otherwise, for the same reason raw dot product is a poor default: '
          'it conflates "similar meaning" with "similar length", and text '
          'length is rarely something you want influencing a relevance '
          'score.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'When in doubt, check the model card',
          text:
              'Every embedding model is trained against one specific metric, '
              'and using a different one at query time silently degrades '
              'results without raising any error. The model\'s documentation '
              'states which metric it expects — usually cosine or dot '
              'product on normalised vectors — and that choice should '
              'propagate directly into how the vector index is configured.',
        ),
      ],
    ),
    Section(
      id: 'why-ann',
      heading: 'Why exact search does not scale',
      blocks: [
        ProseBlock(
          'The most straightforward way to find the best-matching vectors is '
          'exact nearest-neighbour search: compare the query to every single '
          'stored vector and keep the top few. It is simple, it is exact, and '
          'it is completely fine for a corpus of a few thousand chunks. It is '
          'also linear in the size of the corpus — every additional document '
          'adds one more comparison to every single query — which becomes '
          'untenable well before a corpus reaches even a million vectors, let '
          'alone the tens or hundreds of millions many real systems index.',
        ),
        ProseBlock(
          'Approximate nearest-neighbour search, universally shortened to '
          'ANN, is the answer: give up the guarantee of finding the exact '
          'best match in exchange for looking at only a small fraction of the '
          'corpus. A well-tuned ANN index can return the true top-10 (or '
          'something close enough to be indistinguishable to a user) roughly '
          'ninety-five to ninety-nine percent of the time, while touching a '
          'tiny percentage of the stored vectors — a recall/speed tradeoff '
          'that is explicit, tunable, and, crucially, measurable.',
        ),
        CodeBlock(
          language: 'text',
          code: '''
Exact search:      compare query to all N vectors      -> O(N) per query
Approximate search: compare query to a small subset     -> O(log N) or O(sqrt N)
                    chosen by an index structure built once, ahead of time
''',
        ),
        ProseBlock(
          'The tuning question is always the same shape, no matter which '
          'index is behind it: how much recall are you willing to give up '
          'for how much speed? The right way to answer it is empirical, not '
          'theoretical — compute the exact top-k for a sample of real '
          'queries once, use it as ground truth, and tune the index\'s '
          'parameters until recall against that ground truth is high enough '
          'that no user would ever notice the difference.',
        ),
      ],
    ),
    Section(
      id: 'indexing-algorithms',
      heading: 'How an ANN index actually narrows the search',
      blocks: [
        ProseBlock(
          'Two families of index cover the large majority of production '
          'systems, and both are worth understanding at the level of "what '
          'is it doing", even without implementing one from scratch. The '
          'first is cluster-based: an inverted file index, usually called '
          'IVF, runs a clustering step (conceptually like k-means) over the '
          'corpus ahead of time, producing some number of cluster centroids. '
          'At query time, the query is compared only to the centroids — a '
          'small, cheap comparison — and then only the vectors belonging to '
          'the nearest one or few clusters are actually searched.',
        ),
        ProseBlock(
          'The parameter that controls the IVF tradeoff is usually called '
          'nprobe: the number of clusters searched per query. nprobe=1 is '
          'fastest and least accurate, since a query near a cluster boundary '
          'might have its true nearest neighbour sitting just across that '
          'boundary in a cluster never searched. Raising nprobe searches '
          'more clusters, recovering recall at the cost of speed, up to the '
          'point where nprobe equals the total number of clusters and IVF '
          'degenerates back into exact search.',
        ),
        CodeBlock(
          language: 'text',
          code: '''
IVF index, conceptually:

  1. Offline: cluster all vectors into nlist groups, keep the centroids.
  2. Query:   compare query to the nlist centroids only (cheap).
  3. Query:   search inside the nearest `nprobe` clusters (not all nlist).

nprobe = 1        -> fastest, lowest recall
nprobe = nlist    -> equivalent to exact search, no speedup left
''',
        ),
        ProseBlock(
          'The second family is graph-based: HNSW, short for Hierarchical '
          'Navigable Small World, builds a multi-layer graph where each '
          'stored vector is a node connected to a handful of its nearest '
          'neighbours. The top layer is sparse and lets a search jump long '
          'distances quickly; each layer below is progressively denser. A '
          'query starts at the top layer, greedily walks toward the closest '
          'node it can find, drops down a layer, and repeats — arriving near '
          'the true answer in a small number of hops rather than scanning '
          'the corpus.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'HNSW is memory-hungry',
          text:
              'The graph itself — the neighbour links at every layer — is '
              'stored in memory alongside the vectors, and that overhead is '
              'the main reason HNSW indexes cost noticeably more RAM per '
              'vector than IVF indexes of the same corpus. IVF trades some '
              'recall at low nprobe for a much smaller memory footprint, '
              'which is why very large, cost-sensitive corpora sometimes '
              'choose it over HNSW even though HNSW usually wins on raw '
              'recall-per-millisecond.',
        ),
      ],
    ),
    Section(
      id: 'vector-db-landscape',
      heading: 'The vector database landscape',
      blocks: [
        ProseBlock(
          'A vector database wraps one of these index types with '
          'persistence, metadata filtering, incremental updates and an API, '
          'so nobody has to hand-roll index management on top of a bare '
          'library. The differences between the popular options come down to '
          'a small number of practical axes: managed versus self-hosted, how '
          'well filtering and hybrid keyword search are supported, and how '
          'far the system scales.',
        ),
        ProseBlock(
          'Pinecone and Weaviate Cloud are fully managed services: no '
          'servers to run, built-in metadata filtering, and hybrid search '
          'combining vector similarity with keyword matching out of the box, '
          'in exchange for a hosting cost and less control over the '
          'underlying index parameters. Weaviate is also available '
          'self-hosted, for teams that want the same feature set without the '
          'managed billing. Chroma is the lightweight, developer-first '
          'option — trivial to run locally for prototyping, with a smaller '
          'operational footprint, and increasingly used in production as it '
          'matures.',
        ),
        ProseBlock(
          'FAISS is not a database at all — it is a library, from Meta, '
          'implementing the IVF and HNSW-style indexes directly, with no '
          'server, no persistence layer and no metadata filtering built in. '
          'It is the right choice when a team wants raw index performance '
          'and is willing to build the surrounding storage and filtering '
          'themselves, and it is frequently what sits underneath other tools '
          '\' higher-level implementations. pgvector takes the opposite '
          'philosophy: it is a Postgres extension that adds a vector column '
          'type and both IVF and HNSW indexing directly inside a relational '
          'database a team may already be running — the appeal being one '
          'less system to operate, at the cost of typically lagging '
          'purpose-built vector databases on raw scale and search latency.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: what actually differs at very large scale',
          children: [
            ProseBlock(
              'At tens to hundreds of millions of vectors, three things stop '
              'being minor details and start dominating design decisions: '
              'memory footprint per vector (which drives HNSW versus IVF, '
              'and whether quantisation is applied to shrink stored '
              'vectors), how metadata filters interact with the ANN search '
              '(a naive implementation filters after retrieving, which can '
              'return far fewer than k results if a filter is selective), '
              'and how updates and deletes are handled without rebuilding '
              'the whole index from scratch.',
            ),
            ProseBlock(
              'Quantisation — storing each vector component in 8 bits or '
              'fewer instead of 32-bit floats — is the standard lever for '
              'memory at scale, trading a small, usually acceptable, '
              'accuracy loss for a four-times-or-better reduction in index '
              'size. Purpose-built vector databases increasingly bake this '
              'in as a configuration option; a bare FAISS or pgvector setup '
              'requires applying it explicitly.',
            ),
          ],
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-vec-metrics',
      title: 'Cosine vs dot product on unnormalised vectors',
      prompt: [
        ProseBlock(
          'Given a query and three candidate vectors of visibly different '
          'lengths, compute both cosine similarity and raw dot product for '
          'each candidate, and print the ranking each metric produces. Then '
          'normalise every vector to unit length and show that dot product '
          'on the normalised vectors reproduces the cosine ranking exactly.',
        ),
        ProseBlock(
          'Do not use a library similarity function — compute norms and dot '
          'products directly with numpy arithmetic so the relationship stays '
          'visible.',
        ),
      ],
      starterCode: '''
import numpy as np

query = np.array([0.80, 0.10, 0.20])

candidates = {
    "short_but_relevant":  np.array([0.78, 0.12, 0.22]),
    "long_but_relevant":   np.array([3.90, 0.60, 1.10]),   # same direction, 5x longer
    "short_but_unrelated": np.array([0.05, 0.90, 0.40]),
}


def cosine_similarity(a, b):
    ...


def dot(a, b):
    ...


def rank(scores):
    """scores: dict[label, float]. Return labels sorted best-first."""
    ...


cosine_scores = {label: cosine_similarity(query, vec) for label, vec in candidates.items()}
dot_scores = {label: dot(query, vec) for label, vec in candidates.items()}

print("cosine ranking:", rank(cosine_scores))
print("dot ranking:   ", rank(dot_scores))
''',
      solutionCode: '''
import numpy as np

query = np.array([0.80, 0.10, 0.20])

candidates = {
    "short_but_relevant":  np.array([0.78, 0.12, 0.22]),
    "long_but_relevant":   np.array([3.90, 0.60, 1.10]),   # same direction, 5x longer
    "short_but_unrelated": np.array([0.05, 0.90, 0.40]),
}


def cosine_similarity(a, b):
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))


def dot(a, b):
    return float(a @ b)


def rank(scores):
    """scores: dict[label, float]. Return labels sorted best-first."""
    return sorted(scores, key=lambda label: -scores[label])


cosine_scores = {label: cosine_similarity(query, vec) for label, vec in candidates.items()}
dot_scores = {label: dot(query, vec) for label, vec in candidates.items()}

print("cosine ranking:", rank(cosine_scores))
# ['long_but_relevant', 'short_but_relevant', 'short_but_unrelated']
# -- long_but_relevant edges out short_but_relevant only because its
#    direction is marginally more precisely aligned; both score ~0.999

print("dot ranking:   ", rank(dot_scores))
# ['long_but_relevant', 'short_but_relevant', 'short_but_unrelated']
# -- same order here, but the *margin* is wildly different: long_but_relevant
#    wins by a huge numeric gap purely because it is five times longer

# Normalise, and dot product becomes exactly cosine similarity.
def normalise(v):
    return v / np.linalg.norm(v)


normalised = {label: normalise(vec) for label, vec in candidates.items()}
query_unit = normalise(query)
dot_on_unit = {label: dot(query_unit, vec) for label, vec in normalised.items()}

for label in candidates:
    assert round(dot_on_unit[label], 6) == round(cosine_scores[label], 6)
print("dot-on-normalised matches cosine exactly: confirmed")
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'In this particular example cosine and raw dot product happen '
              'to agree on the ranking. Construct a small change to '
              '"short_but_unrelated" that would make dot product rank it '
              'above "short_but_relevant", while cosine still ranks it last.',
          expectedAnswer:
              'Scale short_but_unrelated up by a large factor, for example '
              'multiplying it by 20 to get roughly [1.0, 18.0, 8.0]. Its '
              'direction relative to the query is unchanged, so cosine '
              'similarity is identical to before and it still ranks last. '
              'But its dot product with the query grows with its new '
              'magnitude and can exceed the dot product of the much shorter '
              'short_but_relevant vector, which is exactly the failure mode '
              'the lesson warns about: raw dot product rewards magnitude, '
              'not relevance, whenever vectors are not normalised.',
        ),
        SelfCheckQuestion(
          question:
              'A teammate proposes storing embeddings without normalising '
              'them, and using dot product "because it\'s faster than cosine '
              'similarity." When is that actually safe, and when is it not?',
          expectedAnswer:
              'It is safe only if every stored vector, and every query '
              'vector, is guaranteed to already have (approximately) the '
              'same norm — which is true for embedding models that are '
              'specifically trained to output unit-length vectors, or if '
              'normalisation is applied explicitly at write time and at '
              'query time. It is not safe for an arbitrary embedding model '
              'whose output norms vary with text length or content, because '
              'then dot product silently blends "how similar" with "how '
              'long", exactly as the exercise demonstrates. The fix costs '
              'almost nothing: normalise once when a vector is written to '
              'the index, and dot product becomes cosine similarity for '
              'free from then on.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-vec-ivf-search',
      title: 'A toy IVF index: search clusters, not everything',
      prompt: [
        ProseBlock(
          'Implement search_ivf(query, vectors, centroids, assignments, '
          'nprobe) that first finds the nprobe nearest centroids to the '
          'query, then returns the single closest vector among only the '
          'ones assigned to those clusters — never touching vectors outside '
          'them. Compare its answer against an exhaustive scan at nprobe=1 '
          'and at a higher nprobe.',
        ),
        ProseBlock(
          'The corpus is deliberately built so the true nearest neighbour '
          'sits in a cluster the query is not closest to, to make the '
          'nprobe=1 miss visible rather than theoretical.',
        ),
      ],
      starterCode: '''
import numpy as np

# 8 toy vectors, pre-clustered into 4 groups (cluster id per vector).
vectors = np.array([
    [0.10, 0.90],   # 0 - cluster 0
    [0.15, 0.95],   # 1 - cluster 0
    [0.85, 0.10],   # 2 - cluster 1
    [0.90, 0.05],   # 3 - cluster 1
    [0.50, 0.50],   # 4 - cluster 2
    [0.55, 0.45],   # 5 - cluster 2  <- true nearest neighbour to the query
    [0.05, 0.05],   # 6 - cluster 3
    [0.02, 0.02],   # 7 - cluster 3
])
assignments = np.array([0, 0, 1, 1, 2, 2, 3, 3])
centroids = np.array([
    [0.125, 0.925],   # cluster 0
    [0.875, 0.075],   # cluster 1
    [0.525, 0.475],   # cluster 2
    [0.035, 0.035],   # cluster 3
])

query = np.array([0.48, 0.52])   # closest centroid by a hair is cluster 3


def exact_nearest(query, vectors):
    """Exhaustive scan: return index of the closest vector."""
    ...


def search_ivf(query, vectors, centroids, assignments, nprobe=1):
    """Search only the vectors whose cluster is among the nprobe nearest
    centroids to the query. Return the best index found, or None."""
    ...


print("exact:      ", exact_nearest(query, vectors))
print("ivf nprobe=1:", search_ivf(query, vectors, centroids, assignments, nprobe=1))
print("ivf nprobe=2:", search_ivf(query, vectors, centroids, assignments, nprobe=2))
''',
      solutionCode: '''
import numpy as np

vectors = np.array([
    [0.10, 0.90],   # 0 - cluster 0
    [0.15, 0.95],   # 1 - cluster 0
    [0.85, 0.10],   # 2 - cluster 1
    [0.90, 0.05],   # 3 - cluster 1
    [0.50, 0.50],   # 4 - cluster 2
    [0.55, 0.45],   # 5 - cluster 2  <- true nearest neighbour to the query
    [0.05, 0.05],   # 6 - cluster 3
    [0.02, 0.02],   # 7 - cluster 3
])
assignments = np.array([0, 0, 1, 1, 2, 2, 3, 3])
centroids = np.array([
    [0.125, 0.925],   # cluster 0
    [0.875, 0.075],   # cluster 1
    [0.525, 0.475],   # cluster 2
    [0.035, 0.035],   # cluster 3
])

query = np.array([0.48, 0.52])


def _dist(a, b):
    return float(np.linalg.norm(a - b))


def exact_nearest(query, vectors):
    """Exhaustive scan: return index of the closest vector."""
    dists = [_dist(query, v) for v in vectors]
    return int(np.argmin(dists))


def search_ivf(query, vectors, centroids, assignments, nprobe=1):
    """Search only the vectors whose cluster is among the nprobe nearest
    centroids to the query. Return the best index found, or None."""
    centroid_dists = [_dist(query, c) for c in centroids]
    nearest_clusters = set(np.argsort(centroid_dists)[:nprobe])

    candidate_idx = [i for i, c in enumerate(assignments) if c in nearest_clusters]
    if not candidate_idx:
        return None

    dists = [_dist(query, vectors[i]) for i in candidate_idx]
    return candidate_idx[int(np.argmin(dists))]


print("exact:      ", exact_nearest(query, vectors))              # 5
print("ivf nprobe=1:", search_ivf(query, vectors, centroids, assignments, nprobe=1))
# 7 -- WRONG. Cluster 3's centroid is marginally closer to the query than
#      cluster 2's, so nprobe=1 searches the wrong cluster entirely and
#      returns index 7, missing the true nearest neighbour (index 5).

print("ivf nprobe=2:", search_ivf(query, vectors, centroids, assignments, nprobe=2))
# 5 -- correct. Searching the two nearest clusters includes cluster 2,
#      where the true answer lives.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'nprobe=1 returned the wrong answer even though the query sits '
              'almost exactly between two clusters. Why does that specific '
              'geometry — a query near a cluster boundary — make IVF\'s '
              'recall loss worst?',
          expectedAnswer:
              'IVF commits to searching only the clusters whose centroid is '
              'closest to the query, using centroid distance as a proxy for '
              '"where the true nearest neighbour probably is." That proxy is '
              'most likely to be wrong exactly when the query sits near the '
              'boundary between two clusters\' regions, because then a tiny '
              'difference in centroid distance decides which cluster gets '
              'searched, even though the true nearest individual vector could '
              'easily belong to the cluster that lost that coin flip. Queries '
              'that land solidly in the interior of one cluster are much less '
              'likely to be affected, since their nearest centroid and their '
              'nearest vector are consistent.',
        ),
        SelfCheckQuestion(
          question:
              'This toy corpus has 4 clusters and 8 vectors. At what point '
              'would raising nprobe stop being a meaningful lever at all, '
              'and why does that same ceiling matter more, not less, on a '
              'real corpus with thousands of clusters?',
          expectedAnswer:
              'Once nprobe equals the total number of clusters, IVF searches '
              'every vector in the corpus, which is identical to exact search '
              'and offers no speed advantage left to trade away — here that '
              'happens at nprobe=4. On a real corpus with, say, ten thousand '
              'clusters, that ceiling is far away, which is exactly why IVF '
              'is useful there: nprobe can be tuned anywhere between 1 and '
              'ten thousand, giving fine-grained control over the recall/'
              'speed tradeoff, whereas on this eight-vector toy example the '
              'entire range from "fast and lossy" to "exact" is compressed '
              'into just four steps.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 240000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Vector databases and embeddings in five minutes. Think of an '
              'embedding as giving every piece of text GPS coordinates in '
              '"meaning space." Texts about the same thing get placed near '
              'each other — not because someone hand-designed it, but because '
              'the model was trained to pull related pairs together and push '
              'unrelated ones apart across millions of examples. It\'s like '
              'organizing a massive bookstore by topic, but done automatically '
              'by a neural network.',
          startMs: 0,
          endMs: 40000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Comparing two vectors needs a ruler, and your choice matters. '
              'Cosine similarity is like measuring the angle between two '
              'arrows — it doesn\'t care how long the arrows are, only which '
              'direction they point. That\'s usually what you want, since '
              'longer text shouldn\'t automatically score higher. Raw dot '
              'product cares about both direction AND length, so a long '
              'arrow can beat a shorter, more relevant one — unless you '
              'normalize everything first, at which point dot product and '
              'cosine become the exact same thing.',
          startMs: 40000,
          endMs: 80000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Now imagine searching for one book in a library with a '
              'million volumes. Exact search means checking every single '
              'book — fine for a small shelf, impossible for a massive '
              'collection. Approximate nearest neighbour search, ANN for '
              'short, is the cheat: it only checks a small fraction of the '
              'library, and a well-tuned ANN finds the right shelf about '
              '95 to 99 percent of the time while touching almost none of '
              'the books. You trade a tiny bit of accuracy for massive speed.',
          startMs: 80000,
          endMs: 120000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Two families of indexes do that narrowing. IVF is like '
              'pre-sorting books into sections before anyone arrives — at '
              'search time you only check the nearest few sections, '
              'controlled by a knob called nprobe. HNSW is more like a '
              'clever road map: it builds a multi-layer graph where each '
              'book connects to a few neighbours, and a search can hop '
              'from the highway level down to the local streets, landing '
              'near the answer in just a handful of jumps instead of '
              'driving past every house.',
          startMs: 120000,
          endMs: 160000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And the tools wrapping those indexes: Pinecone and Weaviate '
              'Cloud are like managed storage facilities — someone else runs '
              'them, they come with filtering and hybrid search built in. '
              'Chroma is the easy-to-set-up option for smaller projects. '
              'FAISS is the bare-bones toolkit with no frills. And pgvector '
              'plugs vector search directly into Postgres, for teams who '
              'would rather not manage yet another system.',
          startMs: 160000,
          endMs: 200000,
        ),
        PodcastSegment(
          id: 'c6',
          speaker: 'Guest',
          text:
              'The choice boils down to three questions: managed or '
              'self-hosted, do you need metadata filtering built in, and '
              'how large is your corpus going to get. Match your similarity '
              'metric to what the embedding model was trained for, and the '
              'rest is mainly an operations decision — not a magic formula.',
          startMs: 200000,
          endMs: 240000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 432000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Retrieval lives or dies on how well your embeddings and the '
              'index that searches them are set up, so let\'s go through both '
              'properly. Imagine you\'re organizing a massive bookstore. You '
              'need a system where books about the same topic somehow end up '
              'on the same shelf, automatically. An embedding is that system: '
              'a dense vector — a list of numbers — produced by a model, '
              'positioned so that texts with similar meaning land near each '
              'other in a mathematical space.',
          startMs: 0,
          endMs: 54000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Nobody sits down and designs what each of those 768 or 1536 '
              'dimensions means — it would be like trying to manually decide '
              'what each GPS coordinate "represents." Instead, the training '
              'signal does the work. Take matched pairs — a question and its '
              'correct answer — and pull their vectors together like magnets, '
              'while pushing every unrelated pair apart. Do that across '
              'millions of examples and the space naturally organizes itself '
              'so "related" reliably means "nearby."',
          startMs: 54000,
          endMs: 108000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Then you need a ruler for "nearby," and the three candidates '
              'are NOT interchangeable. Cosine similarity is like measuring '
              'the angle between two arrows — it completely ignores how long '
              'the arrows are. That\'s usually what you want, since longer '
              'text shouldn\'t automatically outrank shorter text. Dot product '
              'is trickier: it cares about angle AND length, so a long arrow '
              'can beat a shorter, more relevant one purely by being longer.',
          startMs: 108000,
          endMs: 162000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'The fix is absurdly cheap. Normalize every vector to unit '
              'length — make all arrows exactly the same size — and dot '
              'product becomes mathematically identical to cosine similarity, '
              'just without the division step. This is precisely why most '
              'vector databases normalize at write time and default to dot '
              'product internally. You get cosine-quality rankings at dot '
              'product speed.',
          startMs: 162000,
          endMs: 216000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Now let\'s talk scale. Exact search means comparing your query '
              'to every single stored vector — like checking every book on '
              'every shelf. Fine for ten thousand books, completely '
              'untenable at ten million. Approximate nearest neighbour '
              'search, ANN, gives up the guarantee of finding the exact best '
              'match and instead looks at only a tiny slice of the corpus. '
              'In practice, a well-tuned ANN finds the right answer 95 to 99 '
              'percent of the time while touching almost nothing. You trade '
              'a measurable, tunable amount of recall for huge speed gains.',
          startMs: 216000,
          endMs: 270000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'IVF is the cluster-based approach — think of it like pre-'
              'sorting books into sections. At query time, you compare '
              'against just the section labels first, then search inside '
              'only the nearest one or few sections. The nprobe parameter '
              'controls how many sections you check. Low nprobe is fast but '
              'risks missing a book sitting just across a section boundary. '
              'Raising it recovers recall at the cost of speed.',
          startMs: 270000,
          endMs: 324000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'HNSW is the graph-based approach — think of it like a road '
              'map with highways and local streets. It builds a multi-layer '
              'navigable graph where each vector connects to a handful of '
              'near neighbours. A search starts on the highway layer, hops '
              'long distances quickly, then drops down to local streets for '
              'fine-grained accuracy, landing near the answer in just a few '
              'hops. HNSW usually beats IVF on recall per millisecond, but '
              'it costs more memory — the road map itself takes up space.',
          startMs: 324000,
          endMs: 378000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And then the landscape of tools built on top: Pinecone and '
              'Weaviate Cloud, managed with filtering and hybrid search '
              'included — think fully serviced storage. Chroma, lightweight '
              'and developer-friendly — the easy self-storage option. FAISS, '
              'a bare library with no server or persistence at all — raw '
              'building materials. pgvector, living inside Postgres for '
              'teams who\'d rather not add a new system. Pick based on '
              'hosting preference, filtering needs, and how far your corpus '
              'is actually going to scale.',
          startMs: 378000,
          endMs: 432000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 880000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Alright, settle in — we\'re going deep on vector databases and '
              'embeddings. Here\'s the roadmap: what an embedding actually is '
              'and how contrastive training shapes the space, the three '
              'similarity metrics and why you can\'t just pick any of them, '
              'why exact search stops scaling beyond small collections, the '
              'IVF and HNSW index families that solve that scaling problem, '
              'and the practical differences across the current vector '
              'database landscape when you actually need to choose one.',
          startMs: 0,
          endMs: 80000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Think of an embedding as GPS coordinates in "meaning space." '
              'It\'s a dense vector — a list of a few hundred to a few '
              'thousand numbers — produced by a model, where geometric '
              'closeness is meant to track semantic closeness. Two texts '
              'about the same idea should land near each other. But nobody '
              'sat down and decided what each coordinate means. What IS '
              'designed is the training objective — the signal the model '
              'optimizes against — and that objective is what actually '
              'shapes the space.',
          startMs: 80000,
          endMs: 160000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'That objective is usually contrastive, and it\'s worth '
              'understanding intuitively even without the math. Imagine '
              'a classroom where the teacher says "for each question, the '
              'correct answer is your only friend — sit next to it. Everyone '
              'else\'s answer? Stay away." Take a batch of known matched '
              'pairs — a question and its correct passage — and for each '
              'question, pull it toward its own passage while pushing it '
              'away from every other passage in the batch, simultaneously. '
              'Do this across millions of pairs and the space has no choice '
              'but to organize itself.',
          startMs: 160000,
          endMs: 240000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Repeat that over millions of pairs and something remarkable '
              'emerges: the space develops a consistent geometric structure '
              'where "related" reliably means "nearby." Not because any '
              'dimension was assigned a meaning by hand, but because the only '
              'way to satisfy millions of simultaneous pull-together, push-'
              'apart constraints is to develop that structure naturally. It\'s '
              'like how a city\'s neighborhoods emerge — nobody planned every '
              'street, but everyone wanting to live near similar things '
              'creates a coherent map.',
          startMs: 240000,
          endMs: 320000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Once you have vectors, "similar" needs a precise ruler, and '
              'the three common choices are genuinely not interchangeable. '
              'Cosine similarity is like measuring the angle between two '
              'arrows — it completely ignores how long the arrows are. This '
              'matters because chunk lengths vary a lot in a real corpus, '
              'and you don\'t want a relevance score quietly tracking '
              'document length rather than actual meaning.',
          startMs: 320000,
          endMs: 400000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Raw dot product is trickier — it folds magnitude back in, so '
              'a longer arrow pointing the same direction scores higher '
              'purely for being longer. That sounds like a clear downside '
              'until you normalize every vector to unit length first, at '
              'which point dot product BECOMES cosine similarity, just '
              'without the division step. That\'s precisely why vector '
              'databases normalize at write time and expose dot product, or '
              '"inner product," as the fast default rather than recomputing '
              'cosine similarity from scratch on every query.',
          startMs: 400000,
          endMs: 480000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Euclidean distance is the third option — straight-line '
              'distance in the space, sensitive to magnitude just like raw '
              'dot product, just inverted so smaller means closer. It\'s the '
              'right choice when a model was specifically trained to make '
              'Euclidean distance meaningful, and a weaker default otherwise '
              'for the same reason: it conflates "similar meaning" with '
              '"similar length" in a way you rarely actually want.',
          startMs: 480000,
          endMs: 560000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Now scale — and this is where things get real. Exact nearest-'
              'neighbour search is linear in corpus size. Every additional '
              'vector adds one more comparison per query. It\'s like checking '
              'every book in a library of ten thousand — fine. At a hundred '
              'million? Absolutely hopeless. Approximate nearest-neighbour '
              'search, ANN, gives up the exact-answer guarantee for a tunable '
              'amount of speed. The tuning question is always the same: how '
              'much recall for how much latency, measured empirically '
              'against an exact-search ground truth on a sample of real '
              'queries, not guessed.',
          startMs: 560000,
          endMs: 640000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'IVF handles scaling by pre-sorting. Think of it like grouping '
              'books into sections ahead of time — conceptually similar to '
              'k-means clustering. At query time, you compare against just '
              'the section labels first, a cheap step, then search inside '
              'only the nearest one or few sections, controlled by nprobe. '
              'Low nprobe is fast but risky: a query near a section boundary '
              'might have its best match sitting just across that boundary in '
              'a section you never checked. Raising nprobe recovers recall at '
              'the cost of speed. At nprobe equal to the total number of '
              'sections, you\'re back to checking everything — no speedup left.',
          startMs: 640000,
          endMs: 720000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'HNSW takes the road-map approach instead. It builds a multi-'
              'layer navigable small-world graph — sparse highways at the '
              'top so a search can jump long distances quickly, denser local '
              'streets at the bottom for fine-grained accuracy. A query '
              'walks greedily from the top layer down, landing near the true '
              'answer in a handful of hops rather than driving past every '
              'house. HNSW typically beats IVF on recall per millisecond, '
              'at the cost of heavier memory — the road map itself, all '
              'those neighbour links at every layer, has to be stored '
              'alongside every vector.',
          startMs: 720000,
          endMs: 800000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'And the tools wrapping those indexes differ mostly on three '
              'axes: hosting, filtering, and scale. Pinecone and Weaviate '
              'Cloud are managed services — someone else runs the servers, '
              'metadata filtering and hybrid search come built in. Chroma is '
              'the lightweight, easy-to-run choice for smaller or earlier-'
              'stage projects — the self-storage unit. FAISS is raw building '
              'material — a library with the indexes and nothing else, no '
              'server, no persistence, no filtering. pgvector bolts vector '
              'search onto a Postgres database a team may already run, at '
              'some cost in raw scale compared to purpose-built systems. '
              'Pick based on those three axes, not on which name sounds '
              'most familiar.',
          startMs: 800000,
          endMs: 880000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Embeddings turn "similar meaning" into "nearby vectors"',
      body:
          'An embedding model is trained with a contrastive objective: pull '
          'matched pairs together, push unrelated pairs apart, across '
          'millions of examples, until geometric closeness in the resulting '
          'space reliably tracks semantic closeness. No dimension is '
          'hand-designed — the training signal alone shapes the space.',
    ),
    SummaryCard(
      title: 'Cosine, dot product and Euclidean are not interchangeable',
      body:
          'Cosine similarity ignores magnitude; raw dot product and '
          'Euclidean distance do not, so both can be skewed by vector length '
          'unless every vector is normalised first — at which point dot '
          'product and cosine similarity become the same computation, and '
          'the faster one. Always match the metric to what the embedding '
          'model was actually trained against.',
    ),
    SummaryCard(
      title: 'ANN indexes trade a little recall for a lot of speed',
      body:
          'Exact search is linear in corpus size and stops scaling well '
          'before a hundred million vectors. IVF narrows the search to a '
          'few clusters via a tunable nprobe; HNSW walks a multi-layer '
          'graph toward the query in a handful of hops. Both trade an '
          'explicit, measurable amount of recall for large speedups, and the '
          'right operating point is found empirically, not assumed.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Contrastive learning',
      definition:
          'The training approach behind most embedding models: pull known '
          'matched pairs together in the vector space and push unrelated '
          'pairs apart, repeated across millions of examples, so geometric '
          'closeness comes to track semantic relatedness.',
    ),
    KeyConcept(
      term: 'Cosine similarity',
      definition:
          'The cosine of the angle between two vectors, ignoring their '
          'magnitude entirely. Robust to differing text lengths, and '
          'identical to dot product once both vectors are normalised to '
          'unit length.',
    ),
    KeyConcept(
      term: 'Approximate nearest neighbour (ANN) search',
      definition:
          'Search that examines only a small subset of a corpus rather than '
          'every stored vector, trading a tunable amount of recall for a '
          'large reduction in query latency compared to exact search.',
    ),
    KeyConcept(
      term: 'IVF (inverted file index)',
      definition:
          'An ANN index that clusters the corpus ahead of time and, at '
          'query time, searches only the nprobe clusters whose centroid is '
          'nearest the query, rather than every vector in the corpus.',
    ),
    KeyConcept(
      term: 'HNSW (Hierarchical Navigable Small World)',
      definition:
          'A graph-based ANN index with multiple layers of decreasing '
          'sparsity; a query greedily walks from the sparse top layer down '
          'to the query\'s true neighbourhood in a small number of hops.',
    ),
    KeyConcept(
      term: 'Vector database',
      definition:
          'A system that wraps an ANN index (typically IVF or HNSW) with '
          'persistence, metadata filtering, incremental updates and an API — '
          'the layer above the bare index that makes it usable in '
          'production.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Using raw dot product or Euclidean distance on embeddings that '
          'were never normalised.',
      correction:
          'Both metrics are sensitive to vector magnitude, so a longer '
          'vector can outrank a shorter, more relevant one for reasons '
          'unrelated to meaning. Normalise every vector to unit length at '
          'write time; dot product on normalised vectors is exactly cosine '
          'similarity, computed faster.',
    ),
    Mistake(
      mistake:
          'Assuming a vector search always returns the true, exact nearest '
          'neighbours.',
      correction:
          'Any ANN index — IVF, HNSW, or the managed index behind a vector '
          'database — trades some recall for speed by design. A query near '
          'a cluster or graph boundary can miss its true nearest neighbour '
          'even at reasonable settings; the fix is measuring recall against '
          'an exact-search baseline and tuning nprobe (or the equivalent '
          'parameter) until the loss is acceptable, not assuming perfection.',
    ),
    Mistake(
      mistake:
          'Choosing a vector database on name recognition rather than its '
          'filtering, hosting and scale characteristics.',
      correction:
          'Pinecone and Weaviate Cloud suit teams wanting managed '
          'infrastructure with filtering and hybrid search included; Chroma '
          'suits lightweight or early-stage projects; FAISS suits teams '
          'building their own storage and filtering around a bare index; '
          'pgvector suits teams that would rather not run a new system at '
          'all. The right choice depends on those axes, not on which tool is '
          'most talked about.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Why do vector databases usually default to dot product rather '
          'than computing cosine similarity directly?',
      answer:
          'Because the two are mathematically identical once every vector '
          'has been normalised to unit length, and dot product is cheaper — '
          'it skips the two norm computations and the division that cosine '
          'similarity requires on every comparison. So the standard design '
          'is to normalise vectors once, at index-write time, and then use '
          'plain dot product (often called "inner product") at query time to '
          'get cosine-equivalent rankings without paying the cosine '
          'computation cost on every single query. The risk is entirely at '
          'the normalisation step: if a vector is written unnormalised, dot '
          'product silently reverts to rewarding magnitude over relevance, '
          'and nothing about the system raises an error to flag it.',
    ),
    InterviewQuestion(
      question:
          'Explain how HNSW finds an approximate nearest neighbour without '
          'scanning the whole corpus.',
      answer:
          'HNSW builds a graph, offline, where each stored vector is a node '
          'connected to a small number of its nearest neighbours, organised '
          'into multiple layers of decreasing density — the top layer is '
          'sparse, with long-range connections that let a search jump far '
          'across the space quickly; lower layers are denser, for '
          'fine-grained precision near the answer. A query starts at the top '
          'layer, greedily moves to whichever neighbour is closest to it, '
          'repeats until no neighbour improves the distance, then drops down '
          'one layer and continues the same greedy walk with a denser set of '
          'connections. By the time it reaches the bottom layer it has '
          'typically arrived in the true neighbourhood of the answer, having '
          'examined only a small fraction of the corpus rather than every '
          'vector. The cost is memory: the neighbour graph at every layer has '
          'to be stored alongside the vectors themselves, which is why HNSW '
          'indexes carry a heavier memory footprint than cluster-based '
          'alternatives like IVF.',
    ),
    InterviewQuestion(
      question:
          'A team is choosing between self-hosting FAISS and using a '
          'managed vector database like Pinecone. What would you actually '
          'ask them before recommending one?',
      answer:
          'First, whether they need metadata filtering or hybrid keyword-'
          'plus-vector search, because FAISS provides neither out of the box — '
          'it is purely an index library, so filtering and persistence would '
          'have to be built around it, whereas managed options bundle both. '
          'Second, how much engineering capacity they have for operating '
          'infrastructure: FAISS demands someone owns storage, backups, '
          'scaling and updates, while a managed service absorbs that at a '
          'recurring cost. Third, how large the corpus will actually get and '
          'how latency-sensitive the workload is, since FAISS gives full '
          'control over index parameters like nprobe or graph construction '
          'that can matter at extreme scale but add complexity most teams '
          'do not need. If they already run Postgres and the corpus is '
          'modest, I would also raise pgvector as a lower-overhead middle '
          'ground before committing to either extreme. There is rarely a '
          'universally right answer — it is a tradeoff between control and '
          'operational cost that depends on the team\'s size and the '
          'corpus\'s scale.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'Nearest Neighbor Indexes for Similarity Search — Pinecone Learn',
    url: 'https://www.pinecone.io/learn/series/faiss/vector-indexes/',
    description:
        'An overview of exact versus approximate search and the major index '
        'families, backing the why-ANN and indexing-algorithms sections of '
        'this lesson.',
  ),
  Source(
    title: 'Hierarchical Navigable Small Worlds (HNSW) — Pinecone Learn',
    url: 'https://www.pinecone.io/learn/series/faiss/hnsw/',
    description:
        'A detailed walkthrough of how HNSW\'s layered graph structure is '
        'built and searched, the source for the greedy-walk description '
        'used here.',
  ),
  Source(
    title: 'Faiss indexes — facebookresearch/faiss Wiki',
    url: 'https://github.com/facebookresearch/faiss/wiki/Faiss-indexes',
    description:
        'The official reference for FAISS\'s IVF and related index types, '
        'including the nprobe parameter this lesson\'s IVF exercise is built '
        'around.',
  ),
  Source(
    title: 'pgvector — open-source vector similarity search for Postgres',
    url: 'https://github.com/pgvector/pgvector',
    description:
        'The project README documenting pgvector\'s IVF and HNSW indexing '
        'support inside Postgres, referenced in the vector database '
        'landscape section.',
  ),
  Source(
    title: 'Getting Started — Chroma Docs',
    url: 'https://docs.trychroma.com/docs/overview/getting-started',
    description:
        'Chroma\'s official quickstart, illustrating the lightweight, '
        'developer-first workflow this lesson contrasts with managed and '
        'bare-library alternatives.',
  ),
];
