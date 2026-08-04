import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 2: the dense vectors that attention operates over, and how
/// geometry in that space came to stand in for meaning.
const Lesson embeddingsLesson = Lesson(
  id: 'dl-embeddings-basics',
  title: 'Embeddings Basics',
  description:
      'Dense vector representations of words, sentences and items — from '
      'word2vec analogies to contextual vectors and semantic search.',
  estimatedMinutes: 29,
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
      id: 'what-is-an-embedding',
      heading: 'An embedding is a learned position in space',
      blocks: [
        ProseBlock(
          'An embedding is a dense, fixed-length vector of real numbers that '
          'stands in for a discrete thing: a word, a sentence, an image, a '
          'user, a product. Nothing about the vector is hand-designed. It is '
          'learned, and it is learned under a single guiding constraint — '
          'items that mean similar things should end up close together, so '
          'that geometric closeness in the space can be read as semantic '
          'closeness.',
        ),
        ProseBlock(
          '"Close" almost always means cosine similarity or a plain dot '
          'product. Cosine similarity is the cosine of the angle between two '
          'vectors: it ignores magnitude and asks only whether they point the '
          'same way, which is what you want when one document is ten times '
          'longer than another but about the same subject. It runs from 1 for '
          'identical directions, through 0 for orthogonal, to -1 for opposite.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np


def cosine_similarity(a, b):
    """Cosine of the angle between two vectors: magnitude-independent."""
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))


# Toy three-dimensional "embeddings". Real ones have 384-4096 dimensions
# and no human-readable axes, but the geometry works the same way.
cat  = np.array([0.91, 0.24, 0.08])
dog  = np.array([0.88, 0.31, 0.05])
bank = np.array([0.10, 0.05, 0.95])

print(round(cosine_similarity(cat, dog), 3))    # 0.996  same neighbourhood
print(round(cosine_similarity(cat, bank), 3))   # 0.198  unrelated
''',
          caption:
              'The whole trick: a distance function over vectors becomes a '
              'similarity function over meanings.',
        ),
        ProseBlock(
          'The contrast that makes this worth doing is one-hot encoding. With '
          'a vocabulary of 50,000 words, a one-hot vector has 50,000 slots, '
          '49,999 zeros and a single one. It is sparse, enormous, and — the '
          'fatal part — it encodes no relationships at all. Every pair of '
          'distinct words is exactly as far apart as every other pair, so '
          '"cat" is no closer to "dog" than it is to "bankruptcy". A 384-'
          'dimensional embedding is smaller by two orders of magnitude and '
          'carries structure the one-hot vector cannot express.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
vocab = ["cat", "dog", "bank"]
one_hot = np.eye(len(vocab))            # identity matrix: one row per word

print(cosine_similarity(one_hot[0], one_hot[1]))   # 0.0  cat vs dog
print(cosine_similarity(one_hot[0], one_hot[2]))   # 0.0  cat vs bank

# Every distinct pair scores 0.0. The representation knows the words are
# different and nothing else, which is why the model has to learn all
# semantics from scratch on top of it.
''',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Embeddings are not a preprocessing step you choose',
          text:
              'An embedding table is a weight matrix — one learned row per '
              'vocabulary entry — and a one-hot vector multiplied by that '
              'matrix is exactly a row lookup. So "one-hot then dense layer" '
              'and "embedding lookup" are the same operation, and the second '
              'is just the version that does not waste time multiplying by '
              'zeros.',
        ),
      ],
    ),
    Section(
      id: 'word2vec',
      heading: 'word2vec and the distributional idea',
      blocks: [
        ProseBlock(
          'The insight underneath every learned embedding is older than deep '
          'learning: "you shall know a word by the company it keeps". If two '
          'words appear in the same kinds of contexts, they probably mean '
          'similar things. Nobody has to define "similar" — the corpus does '
          'it, by showing which words are substitutable for one another.',
        ),
        ProseBlock(
          'word2vec turns that into a training objective. It is a shallow '
          'network with one hidden layer and two setups. **CBOW** hides the '
          'centre word and predicts it from the surrounding window. '
          '**Skip-gram** does the reverse: given the centre word, predict the '
          'words around it. Either way the prediction task is a pretext. '
          'Nobody deploys the classifier. What you keep is the hidden weight '
          'matrix, whose rows are the vectors that had to become '
          'well-organised for the prediction task to work at all.',
        ),
        ProseBlock(
          'The famous result is that the organisation turns out to be partly '
          'linear. Directions in the space correspond to consistent semantic '
          'and syntactic relationships, so relationships can be done with '
          'arithmetic: king minus man plus woman lands near queen, and Paris '
          'minus France plus Italy lands near Rome. The gender direction and '
          'the capital-city direction were never asked for; they fell out of '
          'predicting context words.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# ILLUSTRATIVE ONLY. Real word2vec vectors have ~300 dimensions and come
# from training on billions of tokens. These three axes were hand-picked
# so the arithmetic is visible: [royalty, maleness, femaleness].
words = {
    "king":   np.array([0.95, 0.90, 0.05]),
    "queen":  np.array([0.88, 0.15, 0.82]),
    "man":    np.array([0.10, 0.92, 0.05]),
    "woman":  np.array([0.10, 0.08, 0.93]),
    "prince": np.array([0.80, 0.85, 0.05]),
}

result = words["king"] - words["man"] + words["woman"]
print(result)                           # [0.95 0.06 0.93]

for word, vec in words.items():
    print(word, round(cosine_similarity(result, vec), 3))

# queen  0.997   <- nearest
# woman  0.772
# king   0.576
# prince 0.552
# man    0.159
''',
          caption:
              'Subtracting "man" strips the gender component; adding "woman" '
              'puts the other one back, leaving royalty untouched.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'The analogy demo is tidier than the reality',
          text:
              'Published analogy results conventionally exclude the three '
              'input words from the candidate set — without that exclusion '
              'the query vector often lands nearest to "king" itself, because '
              'it barely moved. The linear structure is real and measurable, '
              'but it is a tendency across many word pairs, not a guarantee '
              'for any single one, and it degrades quickly for rare words.',
        ),
      ],
    ),
    Section(
      id: 'polysemy',
      heading: 'Where static embeddings break: one word, several senses',
      blocks: [
        ProseBlock(
          'word2vec and GloVe produce a lookup table: one row per word, fixed '
          'once training ends. That is fast and cheap, and it is also the '
          'limitation. A word with several senses gets one vector for all of '
          'them, and because the vector was fitted to every context the word '
          'ever appeared in, it settles somewhere in the middle — a blend that '
          'is not a good representation of any individual sense.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# A static table is a pure lookup. The sentence is not an argument.
river_bank = static_embeddings["bank"]
money_bank = static_embeddings["bank"]

print(cosine_similarity(river_bank, money_bank))   # 1.0, by construction

# "we moored the boat on the river bank"
# "the bank rejected the mortgage application"
#
# Same 300 numbers in both. Anything downstream that needs to tell these
# apart - retrieval, disambiguation, translation - has to do it without
# help from the representation.
''',
        ),
        ProseBlock(
          'The same problem shows up in less obvious places. "Apple" the fruit '
          'and "Apple" the company; "lead" the metal and "lead" the verb, '
          'which are not even pronounced alike; "light" as weight and "light" '
          'as illumination. Static embeddings also cannot represent negation '
          'or word order, so "not good" and "good" sit next to each other, and '
          '"dog bites man" is indistinguishable from "man bites dog" once you '
          'average the vectors.',
        ),
        ProseBlock(
          'What is needed is a representation that is a function of the '
          'sentence, not just of the word — which is exactly what the '
          'transformer from the previous lesson provides.',
        ),
      ],
    ),
    Section(
      id: 'contextual',
      heading: 'Contextual embeddings: BERT and friends',
      blocks: [
        ProseBlock(
          'A contextual embedding model produces a different vector for the '
          'same token depending on what surrounds it. The mechanism is the '
          'self-attention from the previous lesson: before the model emits a '
          'representation for position i, attention has already mixed in a '
          'weighted blend of every other position in the sequence. By the '
          'final layer, the vector at "bank" has absorbed "river" or '
          '"mortgage" and is no longer the same vector.',
        ),
        ProseBlock(
          'BERT trains this with a masked language modelling objective — hide '
          '15% of the tokens and predict them from both directions at once, '
          'which is what "bidirectional" means and what forces every position '
          'to encode its full context rather than only its left-hand history. '
          'The result is that "the embedding of a word" stops being a row you '
          'look up and becomes the output of a forward pass over the whole '
          'sentence.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from transformers import AutoTokenizer, AutoModel

tok = AutoTokenizer.from_pretrained("bert-base-uncased")
model = AutoModel.from_pretrained("bert-base-uncased")


def token_vector(sentence, index):
    """Contextual vector for one token: a forward pass, not a lookup."""
    batch = tok(sentence, return_tensors="pt")
    hidden = model(**batch).last_hidden_state        # (1, seq_len, 768)
    return hidden[0, index].detach().numpy()


# Index 0 is [CLS], so the counting starts at 1.
river = token_vector("we moored the boat on the river bank", 8)
money = token_vector("the bank rejected the mortgage application", 2)

print(round(cosine_similarity(river, money), 3))     # ~0.5, not 1.0
''',
          caption:
              'Same surface token, same model, two different vectors — the '
              'sentence is now part of the input.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Static embeddings are not obsolete',
          text:
              'A lookup table costs one memory access; a BERT forward pass '
              'costs millions of multiply-accumulates. If you are embedding '
              'product ids, user ids or categorical features — things with no '
              'context to speak of — a learned static table is the right tool '
              'and always was. Context-dependence is only worth paying for '
              'when the meaning genuinely depends on context.',
        ),
      ],
    ),
    Section(
      id: 'sentence-embeddings',
      heading: 'From tokens to sentences, and from sentences to search',
      blocks: [
        ProseBlock(
          'A transformer gives you one vector per token, but most applications '
          'want one vector per sentence or per document. Pooling collapses the '
          'sequence: mean-pooling averages the token vectors (masking out '
          'padding first, or the padding drags every vector toward the same '
          'place), while some models expose a dedicated [CLS] or pooler output '
          'trained to summarise the sequence. Models in the '
          'sentence-transformers family go further and fine-tune specifically '
          'so that pooled vectors of paraphrases end up close together, which '
          'off-the-shelf BERT does surprisingly badly.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def mean_pool(token_vectors, attention_mask):
    """(batch, seq, dim) -> (batch, dim), ignoring padding positions."""
    mask = attention_mask[:, :, None]
    return (token_vectors * mask).sum(axis=1) / mask.sum(axis=1)


# In practice a sentence-embedding library does the pooling for you.
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("all-MiniLM-L6-v2")
doc_vectors = model.encode(documents)    # (n_docs, 384), already pooled
''',
        ),
        ProseBlock(
          'Once a whole document is one vector, similarity search becomes '
          'nearest-neighbour search, and that single move is what powers '
          'semantic search, near-duplicate detection, clustering, '
          'recommendation and the retrieval step of retrieval-augmented '
          'generation. The difference from keyword and TF-IDF matching is that '
          'the query and the document no longer have to share any words: they '
          'only have to land in the same region of the space.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Toy [food, code, travel] "sentence embeddings" - illustrative numbers.
corpus = [
    ("how to boil pasta",              np.array([0.92, 0.05, 0.10])),
    ("best pasta recipes in rome",     np.array([0.70, 0.03, 0.62])),
    ("python list comprehension guide", np.array([0.04, 0.95, 0.08])),
    ("cheap flights to italy",         np.array([0.08, 0.04, 0.94])),
    ("debugging numpy broadcasting",   np.array([0.06, 0.90, 0.05])),
]


def top_k(query, corpus, k=3):
    """Rank the corpus by cosine similarity to the query vector."""
    labels = [label for label, _ in corpus]
    matrix = np.array([vec for _, vec in corpus])
    scores = matrix @ query / (
        np.linalg.norm(matrix, axis=1) * np.linalg.norm(query)
    )
    order = np.argsort(-scores)[:k]
    return [(labels[i], round(float(scores[i]), 3)) for i in order]


query = np.array([0.88, 0.06, 0.15])     # "how do I cook spaghetti"

for label, score in top_k(query, corpus):
    print(score, label)

# 0.998 how to boil pasta
# 0.849 best pasta recipes in rome
# 0.253 cheap flights to italy
''',
          caption:
              'The top hit shares no content word with the query. Keyword '
              'search would have returned nothing.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: dimensionality, and searching a billion vectors',
          children: [
            ProseBlock(
              'Embedding dimension is a real engineering dial, not a detail. '
              'Common sizes run from 384 (MiniLM) through 768 (BERT-base) to '
              '1536 or 3072 for large commercial models. More dimensions mean '
              'more capacity to separate fine distinctions; fewer mean cheaper '
              'storage, faster comparisons and less index memory. Ten million '
              'documents at 1536 float32 dimensions is about 61 GB before any '
              'index overhead, and the same corpus at 384 dimensions is about '
              '15 GB.',
            ),
            ProseBlock(
              'The cost is not only storage. Every similarity comparison is a '
              'dot product of that length, so query latency scales with '
              'dimension too. Two techniques bend the curve: quantisation, '
              'which stores each component in 8 bits or fewer and accepts a '
              'small accuracy loss for a 4x memory saving, and Matryoshka-style '
              'training, which arranges the model so the leading 256 '
              'dimensions of a 1024-dimensional vector are themselves a usable '
              'embedding you can truncate to.',
            ),
            ProseBlock(
              'Exact nearest-neighbour search compares the query to every '
              'stored vector, which is fine for ten thousand documents and '
              'hopeless for a hundred million. Approximate nearest neighbour '
              'search trades a small, tunable amount of recall for orders of '
              'magnitude in speed. FAISS is the canonical library: an inverted '
              'file index clusters the vectors and searches only the few '
              'nearest clusters, while HNSW builds a navigable multi-layer '
              'graph and walks it greedily toward the query. Vector databases '
              'wrap those indexes with persistence, metadata filtering and '
              'incremental updates.',
            ),
            ProseBlock(
              'The tuning question is always the same shape: how much recall '
              'are you willing to lose for how much latency? An ANN index that '
              'returns 95% of the true top-10 is usually indistinguishable '
              'from exact search to a user, and ten times faster. Measure it — '
              'build the exact result set once on a sample of queries and use '
              'it as ground truth for recall@k while you tune the index '
              'parameters.',
            ),
          ],
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Vectors from different models do not compare',
          text:
              'An embedding is only meaningful relative to the model that '
              'produced it. Indexing your corpus with one model and querying '
              'with another — or with a later version of the same one — '
              'produces numbers that look like similarities and are noise. '
              'Store the model name and version alongside the index, and '
              're-embed the entire corpus whenever either changes.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-emb-cosine',
      title: 'Cosine similarity from scratch',
      prompt: [
        ProseBlock(
          'Implement cosine_similarity(a, b) using only numpy arithmetic — no '
          'scipy, no sklearn — then use it to find which of four candidate '
          'vectors is closest to a query vector. Print every score so you can '
          'see the ordering, not just the winner.',
        ),
        ProseBlock(
          'Do not use np.linalg.norm for the norm; compute it from the dot '
          'product of the vector with itself, so the definition stays visible.',
        ),
      ],
      starterCode: '''
import numpy as np

query = np.array([0.70, 0.10, 0.60])

candidates = {
    "espresso": np.array([0.72, 0.05, 0.58]),
    "keyboard": np.array([0.10, 0.85, 0.20]),
    "latte":    np.array([0.60, 0.15, 0.70]),
    "compiler": np.array([0.05, 0.90, 0.12]),
}


def cosine_similarity(a, b):
    """Return the cosine of the angle between a and b."""
    ...


def most_similar(query, candidates):
    """Return (label, score) for the closest candidate."""
    ...


print(most_similar(query, candidates))
''',
      solutionCode: '''
import numpy as np

query = np.array([0.70, 0.10, 0.60])

candidates = {
    "espresso": np.array([0.72, 0.05, 0.58]),
    "keyboard": np.array([0.10, 0.85, 0.20]),
    "latte":    np.array([0.60, 0.15, 0.70]),
    "compiler": np.array([0.05, 0.90, 0.12]),
}


def cosine_similarity(a, b):
    """Return the cosine of the angle between a and b."""
    norm_a = np.sqrt(a @ a)
    norm_b = np.sqrt(b @ b)
    if norm_a == 0 or norm_b == 0:      # undefined direction
        return 0.0
    return float(a @ b / (norm_a * norm_b))


def most_similar(query, candidates):
    """Return (label, score) for the closest candidate."""
    scored = [
        (label, round(cosine_similarity(query, vec), 3))
        for label, vec in candidates.items()
    ]
    scored.sort(key=lambda pair: -pair[1])
    for label, score in scored:
        print(score, label)
    return scored[0]


print(most_similar(query, candidates))

# 0.998 espresso     <- returned
# 0.987 latte
# 0.337 keyboard
# 0.234 compiler
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'You multiply every candidate vector by 10. Which scores change, '
              'and what would have changed if you had used a raw dot product '
              'instead?',
          expectedAnswer:
              'None of the cosine scores change, because scaling a vector '
              'changes its magnitude and not its direction, and cosine '
              'similarity divides the magnitudes out. A raw dot product would '
              'multiply every score by 10 and, more importantly, would rank '
              'long vectors above short ones regardless of direction — which '
              'is why dot product is only interchangeable with cosine when the '
              'vectors have already been L2-normalised.',
        ),
        SelfCheckQuestion(
          question:
              'Why guard against a zero norm rather than letting numpy divide '
              'by zero?',
          expectedAnswer:
              'A zero vector has no direction, so the angle to it is '
              'genuinely undefined. Numpy would return nan and quietly '
              'poison every downstream comparison — a nan neither sorts nor '
              'compares sensibly, so the bad row would appear at an arbitrary '
              'rank rather than raising. Returning 0.0 makes an all-zero '
              'embedding, which usually means a failed encode or an empty '
              'document, simply rank last.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-emb-analogy',
      title: 'Vector arithmetic on a toy analogy',
      prompt: [
        ProseBlock(
          'Given the hand-picked word vectors below, compute king - man + '
          'woman and report which candidate word the result is closest to. '
          'Follow the published convention and exclude the three input words '
          'from the candidate set.',
        ),
        ProseBlock(
          'Then print the ranking with the exclusion switched off, and note '
          'what changes.',
        ),
      ],
      starterCode: '''
import numpy as np

words = {
    "king":   np.array([0.95, 0.90, 0.05]),
    "queen":  np.array([0.88, 0.15, 0.82]),
    "man":    np.array([0.10, 0.92, 0.05]),
    "woman":  np.array([0.10, 0.08, 0.93]),
    "prince": np.array([0.80, 0.85, 0.05]),
}


def analogy(a, b, c, words, exclude_inputs=True):
    """Solve a is to b as c is to ?, returning ranked (word, score) pairs."""
    ...


print(analogy("king", "man", "woman", words))
''',
      solutionCode: '''
import numpy as np

words = {
    "king":   np.array([0.95, 0.90, 0.05]),
    "queen":  np.array([0.88, 0.15, 0.82]),
    "man":    np.array([0.10, 0.92, 0.05]),
    "woman":  np.array([0.10, 0.08, 0.93]),
    "prince": np.array([0.80, 0.85, 0.05]),
}


def cosine_similarity(a, b):
    return float(a @ b / (np.sqrt(a @ a) * np.sqrt(b @ b)))


def analogy(a, b, c, words, exclude_inputs=True):
    """Solve a is to b as c is to ?, returning ranked (word, score) pairs."""
    target = words[a] - words[b] + words[c]
    skip = {a, b, c} if exclude_inputs else set()

    scored = [
        (word, round(cosine_similarity(target, vec), 3))
        for word, vec in words.items()
        if word not in skip
    ]
    scored.sort(key=lambda pair: -pair[1])
    return scored


print(analogy("king", "man", "woman", words))
# [('queen', 0.997), ('prince', 0.552)]

print(analogy("king", "man", "woman", words, exclude_inputs=False))
# [('queen', 0.997), ('woman', 0.772), ('king', 0.576),
#  ('prince', 0.552), ('man', 0.159)]
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'These vectors have three readable axes. What is different about '
              'a real 300-dimensional word2vec space?',
          expectedAnswer:
              'No individual axis means anything. The gender or royalty '
              'information is spread across many dimensions as a direction '
              'rather than sitting in one coordinate, and the axes themselves '
              'are an arbitrary basis fixed by initialisation. What survives '
              'is the relational structure: the offset between king and queen '
              'is roughly parallel to the offset between man and woman, even '
              'though neither offset is aligned with any single dimension.',
        ),
        SelfCheckQuestion(
          question:
              'The result vector scored 0.576 against "king" with the '
              'exclusion off. Why is a similar-looking number a problem for '
              'evaluating analogies honestly?',
          expectedAnswer:
              'Because subtracting one word and adding another moves the query '
              'only a short distance, the input words are naturally among the '
              'nearest neighbours of the result. If they are left in the '
              'candidate set the task frequently answers itself with an input '
              'word, so benchmarks exclude them — which means reported analogy '
              'accuracy is measured under a rule that quietly helps, and the '
              'headline number overstates how cleanly the linear structure '
              'works.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-emb-search',
      title: 'A top-k semantic search',
      prompt: [
        ProseBlock(
          'Write top_k(query, corpus, k) that takes a query vector and a list '
          'of (label, vector) pairs, and returns the k most similar labels '
          'with their scores, highest first. Score the whole corpus at once '
          'with a single matrix-vector product rather than looping — that is '
          'how a real index does it.',
        ),
        ProseBlock(
          'Run it with the query below and check that the top hit is the one a '
          'human would pick, even though it shares almost no vocabulary with '
          'the query.',
        ),
      ],
      starterCode: '''
import numpy as np

# Toy [weather, sport, finance] sentence embeddings.
corpus = [
    ("tomorrow will be rainy and cold", np.array([0.94, 0.06, 0.03])),
    ("storm warning for the coast",     np.array([0.88, 0.04, 0.10])),
    ("united won the cup final",        np.array([0.05, 0.93, 0.08])),
    ("interest rates held steady",      np.array([0.04, 0.07, 0.95])),
    ("match postponed due to snow",     np.array([0.55, 0.70, 0.05])),
]

query = np.array([0.60, 0.66, 0.05])   # "is the game called off for weather?"


def top_k(query, corpus, k=3):
    """Return the k nearest (label, score) pairs by cosine similarity."""
    ...


for label, score in top_k(query, corpus):
    print(score, label)
''',
      solutionCode: '''
import numpy as np

# Toy [weather, sport, finance] sentence embeddings.
corpus = [
    ("tomorrow will be rainy and cold", np.array([0.94, 0.06, 0.03])),
    ("storm warning for the coast",     np.array([0.88, 0.04, 0.10])),
    ("united won the cup final",        np.array([0.05, 0.93, 0.08])),
    ("interest rates held steady",      np.array([0.04, 0.07, 0.95])),
    ("match postponed due to snow",     np.array([0.55, 0.70, 0.05])),
]

query = np.array([0.60, 0.66, 0.05])   # "is the game called off for weather?"


def top_k(query, corpus, k=3):
    """Return the k nearest (label, score) pairs by cosine similarity."""
    labels = [label for label, _ in corpus]
    matrix = np.array([vec for _, vec in corpus])

    # Normalise once, then a single matrix-vector product scores everything.
    matrix = matrix / np.linalg.norm(matrix, axis=1, keepdims=True)
    scores = matrix @ (query / np.linalg.norm(query))

    order = np.argsort(-scores)[:k]
    return [(labels[i], round(float(scores[i]), 3)) for i in order]


for label, score in top_k(query, corpus):
    print(score, label)

# 0.997 match postponed due to snow
# 0.776 united won the cup final
# 0.719 tomorrow will be rainy and cold
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The solution normalises the corpus matrix once, up front. Why '
              'does that matter beyond tidiness?',
          expectedAnswer:
              'Because the corpus is scored against many queries over its '
              'lifetime, and the norms never change. Normalising at index time '
              'turns every later query into a plain matrix-vector product with '
              'no division at all, which is both faster and exactly the dot '
              'product an ANN index expects. It is the standard reason vector '
              'databases store unit-length vectors and offer "inner product" '
              'as their similarity metric.',
        ),
        SelfCheckQuestion(
          question:
              'Your corpus grows to 50 million documents and this function '
              'takes seconds per query. What changes, and what does it cost?',
          expectedAnswer:
              'You replace the exhaustive scan with an approximate '
              'nearest-neighbour index — a FAISS inverted-file index that only '
              'searches the few nearest clusters, or an HNSW graph walked '
              'greedily toward the query. Queries drop to milliseconds, at the '
              'cost of recall: the index may miss some true top-k results. The '
              'loss is tunable, so you measure recall@k against an exact scan '
              'on a sample of queries and pick the operating point where the '
              'miss rate is invisible to users.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 228000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Embeddings in five minutes. Imagine a map of a city where every '
              'restaurant is a dot. Italian restaurants cluster together in '
              'one neighbourhood. Sushi places cluster in another. Nobody '
              'labelled the neighbourhoods — the dots just ended up close '
              'because similar places share similar vibes. An embedding is '
              'exactly that: a learned position in a high-dimensional space '
              'where closeness equals similarity. Words, sentences, products, '
              'users — each gets a vector, and the distance between vectors '
              'tells you how related they are.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'Compare this to the naive alternative: one-hot encoding. '
              'Imagine giving every restaurant in the city its own unique '
              'dimension — one column for Joe\'s Pizza, one for Sushi Palace, '
              'fifty thousand columns in total. Each restaurant gets a 1 in '
              'its own column and zeros everywhere else. Every pair of '
              'restaurants is exactly the same distance apart. Joe\'s Pizza '
              'is no closer to Pizza Hut than to a bank. All the structure — '
              'that pizzerias are similar, that Italian and French are both '
              'European — has to be learned from scratch, from nothing but '
              'those isolated ones.',
          startMs: 44000,
          endMs: 90000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'word2vec was the breakthrough in 2013. Train a shallow network '
              'to play a simple game: predict a word from the words around '
              'it. "The cat sat on the ___" — guess "mat". The network learns '
              'to make that prediction, but nobody cares about the prediction. '
              'What they keep are the hidden weights — the vectors that had to '
              'become well-organised for the prediction game to work at all. '
              'Those vectors turn out to have linear structure: king minus man '
              'plus woman lands near queen. Nobody programmed a royalty axis. '
              'It fell out of predicting context words.',
          startMs: 90000,
          endMs: 136000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'The catch: word2vec gives each word one fixed vector for all '
              'time. "Bank" — river bank and investment bank — get the same '
              'set of numbers. Those numbers are a compromise averaged over '
              'every sentence the word ever appeared in, representing neither '
              'sense well. Transformer models fixed this: self-attention '
              'mixes in the surrounding words before producing each token\'s '
              'vector. The embedding becomes a function of the whole sentence, '
              'not a table lookup. "Bank" near "river" and "bank" near '
              '"mortgage" are now different vectors.',
          startMs: 136000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And the payoff is search. Turn every document into one vector '
              'by averaging its word vectors. Turn the search query into a '
              'vector the same way. Rank by cosine similarity — are these '
              'arrows pointing in similar directions? The query "how do I '
              'cook spaghetti" matches "pasta boiling instructions" even '
              'though they share zero words. That is semantic search, and it '
              'is also the retrieval step in retrieval-augmented generation — '
              'the technology behind every modern AI chatbot that can look '
              'things up.',
          startMs: 182000,
          endMs: 228000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 496000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Last time we pulled apart self-attention. Today we go one '
              'level deeper and ask what attention is actually operating on, '
              'because the answer is embeddings — dense vectors standing in '
              'for words, sentences, and concepts, arranged so that geometry '
              'carries meaning. Imagine a map of ideas where "king" lives '
              'near "queen", "Paris" near "France", and you can navigate by '
              'direction: from "man" to "woman" is the same direction as '
              'from "king" to something near "queen".',
          startMs: 0,
          endMs: 52000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Start with why it is necessary. A computer cannot multiply '
              'the word "cat". The obvious fix is one-hot encoding: one slot '
              'per vocabulary word, a single 1, zeros everywhere. It works and '
              'it is terrible. Fifty thousand dimensions to encode one word, '
              'and every distinct pair is orthogonal — cosine similarity zero, '
              'forever. "Cat" is no closer to "dog" than to "bankruptcy". The '
              'model has to learn all semantics from absolute scratch on top '
              'of these isolated atoms.',
          startMs: 52000,
          endMs: 118000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'An embedding replaces that with maybe 300 learned numbers '
              'where the values mean something relative to each other. And '
              'worth knowing: an embedding table is literally a weight matrix '
              'with one row per vocabulary entry. Multiply a one-hot vector '
              'by this matrix and you just select a row — it is a lookup. '
              'The embedding layer is the efficient version that skips '
              'multiplying by all those zeros. Same operation, different '
              'framing, dramatically less wasted computation.',
          startMs: 118000,
          endMs: 182000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'How do the numbers get learned? The distributional hypothesis '
              'from linguistics: you shall know a word by the company it '
              'keeps. If two words appear in the same kinds of contexts, they '
              'probably mean similar things. word2vec turned this into a '
              'training objective. CBOW hides the centre word and predicts '
              'it from the surrounding window. Skip-gram does the reverse: '
              'given the centre, predict the neighbours. Nobody deploys the '
              'predictor. You keep the hidden layer — the vectors that had '
              'to organise themselves for the prediction task to work.',
          startMs: 182000,
          endMs: 248000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'And the surprise was that the organisation turns out to be '
              'partly linear. Consistent relationships become consistent '
              'vector offsets. King minus man plus woman is nearest to queen. '
              'Paris minus France plus Italy is nearest to Rome. Nobody '
              'designed a gender axis or a capital-city direction. These '
              'directions fell out of one simple objective: predicting which '
              'words appear together. The linear structure is real and '
              'measurable, though the famous demo is tidier than reality — '
              'benchmarks exclude the input words from the candidate set, '
              'without which the answer is often one of the inputs itself.',
          startMs: 248000,
          endMs: 314000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'The limitation is polysemy — one word, several meanings. '
              'word2vec is a lookup table frozen after training. One row per '
              'word. "Bank" — the river bank and the financial bank — share '
              'the same 300 numbers, blended into a compromise position that '
              'represents neither well. And there is no word order and no '
              'negation. Average the vectors of "not good" and you land near '
              '"good". Average "dog bites man" and "man bites dog" and you '
              'get the identical bag of words.',
          startMs: 314000,
          endMs: 378000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Which is exactly what contextual models solve using the '
              'machinery from the last lesson. Before a transformer emits a '
              'representation for any word, self-attention has already mixed '
              'in a weighted blend of every other word in the sentence. By '
              'the final layer, the vector at "bank" has absorbed "river" or '
              '"mortgage" from its surroundings. The embedding is now a '
              'forward pass over the whole sentence, not a row you look up. '
              'Same word, different context, completely different vector.',
          startMs: 378000,
          endMs: 440000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Pooling takes you from token vectors to document vectors. '
              'Average the token vectors — ignoring padding positions, or '
              'they drag everything toward the same point — and suddenly '
              'every document is one point in space. Rank documents by cosine '
              'similarity to a query vector and you have semantic search, '
              'deduplication, clustering, and RAG retrieval, all using the '
              'same primitive. The one non-negotiable rule: query and corpus '
              'must be embedded with the same model, or the similarity '
              'numbers are meaningless noise. Store the model version '
              'alongside your index.',
          startMs: 440000,
          endMs: 496000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 868000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Deep dive on embeddings. Picture a library where every book '
              'has been placed on a shelf based purely on its content — not '
              'by author name, not by Dewey decimal, but by what it is '
              'actually about. Books about cooking sit together regardless '
              'of whether they mention "recipe" or "cuisine" or "braising". '
              'That is the promise of embeddings, and in the next forty '
              'minutes we will walk from one-hot encoding through word2vec '
              'and its famous analogy result, to contextual vectors, to the '
              'infrastructure that makes vector search work at the scale of '
              'billions of documents.',
          startMs: 0,
          endMs: 62000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'The root problem: neural networks do arithmetic on numbers, '
              'and language is made of symbols. You need a bridge. The naive '
              'bridge is one-hot encoding, and it has three crippling costs. '
              'One: it is enormous — one dimension per vocabulary entry, '
              '50,000 or more. Two: it is sparse — almost all the computation '
              'is multiplying by zero. Three, and most damning: it is '
              'relationally empty. The cosine similarity between any two '
              'distinct words is exactly zero. The representation encodes '
              'identity and absolutely nothing else.',
          startMs: 62000,
          endMs: 140000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'An embedding fixes all three simultaneously. Dense — a few '
              'hundred dimensions instead of tens of thousands. Learned — '
              'the values are fitted from data rather than assigned by fiat. '
              'And continuous — this is the subtle one. A continuous space '
              'has directions, neighbourhoods, and smooth changes. Gradient '
              'descent can nudge a vector a little bit in response to a '
              'training signal. You cannot nudge a symbol. You can absolutely '
              'nudge a point in a high-dimensional space.',
          startMs: 140000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'On the metric: cosine similarity is the default because it '
              'ignores magnitude. Two documents about the same topic, one '
              'ten times longer than the other, should score as highly '
              'similar. The angle between their vectors captures that; raw '
              'Euclidean distance does not — the longer document would be '
              'much further from the shorter one. If you L2-normalise your '
              'vectors first, cosine similarity and the dot product become '
              'the exact same computation. That is why vector databases '
              'normalise at write time and then only ever do inner products.',
          startMs: 214000,
          endMs: 292000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'word2vec. The distributional hypothesis from 1950s linguistics '
              'says words appearing in similar contexts have similar '
              'meanings. Mikolov and colleagues at Google turned this into '
              'two shallow architectures. CBOW averages the context word '
              'vectors and predicts the centre word — fast, and better on '
              'frequent words. Skip-gram goes the other way: predict each '
              'context word from the centre, one at a time. More training '
              'signal per sentence, works better on rare words and small '
              'corpora. The engineering trick that made both tractable was '
              'negative sampling — instead of a softmax over 50,000 words, '
              'treat it as "is this a real pair or one of these five fake '
              'ones?"',
          startMs: 292000,
          endMs: 368000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'And the negative sampling trick is worth appreciating because '
              'it is why word2vec trained on a billion words on 2013 '
              'hardware. A full softmax over 50,000 words per training step '
              'is ruinously expensive. The binary classification framing — '
              'this is a real context pair, these five are random noise — '
              'turns an enormous normalisation into a handful of cheap '
              'logistic regressions. It is one of those algorithmic insights '
              'that made a beautiful idea actually practical.',
          startMs: 368000,
          endMs: 444000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'The analogy result deserves an honest framing. The linear '
              'structure is genuine — offsets between related word pairs '
              'really are roughly parallel across many pairs. But the '
              'standard evaluation is carefully rigged in the model\'s '
              'favour: the three input words are excluded from the candidate '
              'set. Without that exclusion, the query vector frequently lands '
              'nearest to "king" itself, because subtracting "man" and adding '
              '"woman" barely moved it. The linear structure is a strong '
              'tendency dressed up as a clean mathematical law.',
          startMs: 444000,
          endMs: 518000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'And the structural limit is polysemy. One row per word means '
              'one vector for every sense, and training averaged over all '
              'contexts. The vector for "bank" settles in a compromise '
              'position — somewhere between the river and the financial '
              'institution, representing neither cleanly. Same for "apple" '
              '(fruit and company), "lead" (metal and verb), "light" (weight '
              'and illumination). Add that averaging token vectors destroys '
              'word order, and static embeddings simply cannot distinguish '
              '"dog bites man" from "man bites dog".',
          startMs: 518000,
          endMs: 594000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Contextual embeddings are the repair, and they are the '
              'self-attention from last time doing its job. Before a '
              'transformer emits a representation for any position, attention '
              'has already mixed in a weighted blend of every other position '
              'in the sequence. BERT trains this by masking 15% of tokens '
              'and predicting them from both directions at once — which '
              'forces every position to encode its full surrounding context '
              'rather than just what came before. The result: "the embedding '
              'of a word" is no longer a row you look up. It is the output '
              'of a forward pass over the entire sentence.',
          startMs: 594000,
          endMs: 668000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Pooling. A transformer gives you one vector per token; most '
              'applications want one vector per document. Mean-pooling '
              'averages the token vectors — but mask out padding positions '
              'first, or the pad tokens drag everything toward a common dead '
              'centre. Some models expose a dedicated [CLS] or pooler output '
              'trained to summarise the sequence. Off-the-shelf BERT pools '
              'surprisingly badly for similarity tasks; the '
              'sentence-transformers family is fine-tuned specifically so '
              'that paraphrases land close together in the pooled space.',
          startMs: 668000,
          endMs: 742000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Which brings the dimensionality question — a real engineering '
              'knob, not a detail. Common sizes: 384 (MiniLM), 768 '
              '(BERT-base), 1536 to 3072 for large commercial models. More '
              'dimensions separate finer distinctions. Fewer mean cheaper '
              'storage, faster comparisons, and less index memory. Ten '
              'million documents at 1536 float32 dimensions is about 61 GB '
              'before index overhead. Quantisation to 8-bit cuts that '
              'fourfold. Matryoshka-trained models let you simply keep only '
              'the first 256 dimensions and still have a usable embedding.',
          startMs: 742000,
          endMs: 810000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'And at that scale you stop comparing against every vector '
              'exhaustively. Approximate nearest neighbour search — FAISS '
              'inverted-file indexes scanning only the nearest clusters, or '
              'HNSW graphs walked greedily toward the query — trades a '
              'tunable slice of recall for orders of magnitude in speed. '
              'Measure it properly: compute the exact top-k once on a sample '
              'of queries as ground truth, then tune the index until recall '
              'at k is high enough that users cannot tell the difference. '
              'Store the model name and version alongside the index. '
              'Re-embed everything when either changes.',
          startMs: 810000,
          endMs: 868000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Geometry stands in for meaning',
      body:
          'An embedding is a dense, fixed-length, learned vector representing '
          'a discrete item, positioned so that cosine similarity or dot '
          'product tracks semantic similarity. One-hot encoding is the '
          'alternative it replaces: sparse, vocabulary-sized, and orthogonal '
          'between every pair of distinct items, so it encodes identity and no '
          'relationships at all.',
    ),
    SummaryCard(
      title: 'Static vectors, then contextual ones',
      body:
          'word2vec learns embeddings from a pretext task — predict the word '
          'from its context (CBOW) or the context from the word (skip-gram) — '
          'and the resulting space has enough linear structure that king minus '
          'man plus woman lands near queen. But one row per word means one '
          'vector per word, so polysemy breaks it. Transformer models produce '
          'a different vector per occurrence, because self-attention mixes the '
          'surrounding sentence in first.',
    ),
    SummaryCard(
      title: 'Pooling turns embeddings into search',
      body:
          'Mean-pooling or a trained pooler output collapses token vectors '
          'into one vector per sentence or document, and comparing those by '
          'cosine similarity gives semantic search, deduplication, clustering '
          'and RAG retrieval without any shared keywords. At scale, '
          'approximate nearest-neighbour indexes such as FAISS trade a tunable '
          'amount of recall for large speedups.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Embedding',
      definition:
          'A dense, fixed-length vector of learned real numbers representing a '
          'discrete item, trained so that distance or angle in the vector '
          'space corresponds to semantic relatedness.',
    ),
    KeyConcept(
      term: 'One-hot encoding',
      definition:
          'The contrasting representation: a vector as long as the vocabulary '
          'with a single one and the rest zeros. Sparse, high-dimensional, and '
          'equidistant between every pair of distinct items, so it carries no '
          'similarity information.',
    ),
    KeyConcept(
      term: 'word2vec',
      definition:
          'A shallow model that learns static word embeddings from a context-'
          'prediction pretext task, in CBOW or skip-gram form. The prediction '
          'head is discarded; the learned hidden weight matrix is the '
          'embedding table.',
    ),
    KeyConcept(
      term: 'Polysemy',
      definition:
          'One word carrying several distinct senses. A fatal case for static '
          'embeddings, which assign a single vector per word and therefore '
          'blend all senses into one compromise position.',
    ),
    KeyConcept(
      term: 'Contextual embedding',
      definition:
          'A token representation produced by a transformer forward pass, so '
          'the same word receives different vectors in different sentences. '
          'Self-attention mixes information from the whole sequence before '
          'each position emits its representation.',
    ),
    KeyConcept(
      term: 'Cosine similarity',
      definition:
          'The cosine of the angle between two vectors, from 1 through 0 to '
          '-1. Magnitude-independent, which makes it robust to differences in '
          'document length; identical to the dot product once both vectors are '
          'L2-normalised.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Expecting static word2vec or GloVe vectors to distinguish word '
          'senses.',
      correction:
          'A static table has exactly one row per surface form, so every sense '
          'of "bank" or "lead" shares a vector fitted to the average of all '
          'their contexts. If sense matters to your task, you need contextual '
          'embeddings from a transformer, where the vector is a function of '
          'the surrounding sentence.',
    ),
    Mistake(
      mistake:
          'Comparing vectors produced by two different models, or two versions '
          'of one model.',
      correction:
          'Each model defines its own coordinate system, and the axes are '
          'fixed by initialisation rather than by anything shared. The scores '
          'will still be numbers between -1 and 1, which is what makes the bug '
          'so quiet. Record the model name and version with the index and '
          're-embed the whole corpus whenever either changes.',
    ),
    Mistake(
      mistake:
          'Ranking with raw Euclidean distance on vectors that were never '
          'normalised.',
      correction:
          'Euclidean distance is sensitive to magnitude, so long documents and '
          'high-norm vectors get penalised for reasons unrelated to topic. '
          'Either use cosine similarity, or L2-normalise once at index time '
          'and use the dot product — on unit vectors the two rankings are '
          'identical, and the second is faster.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Why are embeddings better than one-hot encoding for representing '
          'words?',
      answer:
          'Three reasons, in increasing order of importance. They are dense, '
          'so a few hundred dimensions replace a vocabulary-sized vector and '
          'the model has far fewer parameters downstream. They are continuous, '
          'so gradient descent can move a representation a small amount — you '
          'cannot nudge a symbol, but you can nudge a point. And most '
          'importantly they encode relationships: with one-hot every pair of '
          'distinct words is orthogonal, so "cat" is exactly as far from "dog" '
          'as from "bankruptcy", and the model has to learn all of semantics '
          'from scratch. An embedding gives it a head start where similar '
          'words already sit near each other. Worth adding that an embedding '
          'lookup and a one-hot vector times a weight matrix are the same '
          'operation, so this is not a different architecture, just the '
          'version that skips the zeros.',
    ),
    InterviewQuestion(
      question:
          'What does a contextual embedding give you that word2vec does not, '
          'and when would you still prefer word2vec?',
      answer:
          'word2vec produces a lookup table: one fixed vector per word, so '
          'every sense of "bank" shares a row and the vector ends up a blend '
          'of contexts that fits none of them. A transformer produces a '
          'different vector per occurrence, because self-attention mixes the '
          'surrounding tokens into each position before the final layer, so '
          '"river bank" and "investment bank" separate. That matters for '
          'disambiguation, retrieval quality and anything sensitive to word '
          'order. The cost is that the embedding is now a forward pass rather '
          'than a memory access — several orders of magnitude more compute per '
          'item. So static tables are still correct for things with no context '
          'to speak of: product ids, user ids, categorical features. And a '
          'cached static table remains a reasonable baseline when latency '
          'budgets are tight and the vocabulary is domain-specific enough that '
          'polysemy is rare.',
    ),
    InterviewQuestion(
      question:
          'Walk me through building semantic search over ten million '
          'documents.',
      answer:
          'Chunk the documents to something the encoder can actually see — '
          'roughly a paragraph, with a little overlap so a sentence spanning a '
          'boundary is not lost. Encode each chunk with a sentence-embedding '
          'model, pick the dimension deliberately since ten million vectors at '
          '1536 float32 dimensions is around sixty gigabytes before index '
          'overhead, and L2-normalise at write time so queries are pure inner '
          'products. Then index with an approximate nearest-neighbour '
          'structure — a FAISS inverted-file index, or HNSW if you need '
          'incremental inserts — and accept a tunable recall loss for orders '
          'of magnitude in latency. I would store the model name and version '
          'with the index, because mixing embedding versions produces '
          'plausible-looking nonsense. For evaluation I would compute exact '
          'top-k on a sample of queries as ground truth and tune the index '
          'until recall@10 is high enough to be invisible, and in production I '
          'would almost certainly add a keyword or BM25 channel alongside, '
          'because embeddings are weak on exact identifiers, product codes and '
          'rare proper nouns.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title:
        'Efficient Estimation of Word Representations in Vector Space '
        '(Mikolov et al., 2013)',
    url: 'https://arxiv.org/abs/1301.3781',
    description:
        'The word2vec paper, introducing the CBOW and skip-gram objectives and '
        'the analogy evaluation used in this lesson.',
  ),
  Source(
    title:
        'BERT: Pre-training of Deep Bidirectional Transformers for Language '
        'Understanding (Devlin et al., 2018)',
    url: 'https://arxiv.org/abs/1810.04805',
    description:
        'The masked language modelling recipe behind the contextual '
        'embeddings section, where a token\'s vector depends on its whole '
        'sentence.',
  ),
  Source(
    title: 'Semantic search with FAISS — Hugging Face LLM Course',
    url: 'https://huggingface.co/learn/llm-course/en/chapter5/6',
    description:
        'A worked walkthrough of pooling sentence embeddings and searching '
        'them with a FAISS index, the practical form of the top-k search built '
        'here.',
  ),
];
