import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 1: the attention-based architecture that replaced
/// recurrence and now underpins every large language model.
const Lesson transformersLesson = Lesson(
  id: 'dl-transformers-overview',
  title: 'Transformers Overview',
  description:
      'Self-attention, queries/keys/values, multi-head attention and '
      'positional encoding — how a sequence model became fully parallel.',
  estimatedMinutes: 38,
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
      id: 'why-transformers',
      heading: 'What recurrence cost us',
      blocks: [
        ProseBlock(
          'Before 2017, sequence models were recurrent. An RNN or LSTM read '
          'one token, updated a hidden state, read the next token, updated '
          'again. The hidden state was the model\'s entire memory of '
          'everything that came before, compressed into a fixed-size vector '
          'and rewritten at every step.',
        ),
        ProseBlock(
          'That design has two structural problems, and neither is fixed by a '
          'bigger model. The first is that computation is inherently '
          'sequential: step forty cannot begin until step thirty-nine has '
          'finished, so a GPU full of parallel cores sits mostly idle while a '
          'sentence is processed one word at a time. The second is distance. '
          'Information from token one reaches token four hundred only by '
          'surviving four hundred rewrites of the hidden state, and gradients '
          'travelling back along that path shrink or explode. LSTMs and GRUs '
          'added gates to slow the decay, but they did not remove it.',
        ),
        ProseBlock(
          'Attention was originally bolted onto recurrent encoder-decoder '
          'translation models as a patch for exactly this: let the decoder '
          'peek back at all the encoder states instead of relying on one '
          'summary vector. The transformer paper asked the obvious follow-up '
          'question. If the peeking is what helps, what happens if we delete '
          'the recurrence and keep only the peeking — if every position can '
          'look directly at every other position, all at once?',
        ),
        ProseBlock(
          'The answer turned out to be: everything gets better. The path '
          'length between any two tokens becomes one hop instead of many, so '
          'long-range dependencies are no harder to learn than short ones. And '
          'because every position is computed from the same fixed set of '
          'inputs rather than from its predecessor, the whole sequence is one '
          'big matrix multiplication — which is precisely the operation '
          'accelerators are built for.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Parallel in training, still sequential in generation',
          text:
              'A decoder-only transformer processes an entire training '
              'sequence in one forward pass, because the target tokens are '
              'already known. Generating text at inference time is still '
              'one token at a time — each new token must exist before it can '
              'be attended to. The parallelism is a training-time win, and it '
              'is what made models this large affordable to train at all.',
        ),
      ],
    ),
    Section(
      id: 'attention-intuition',
      heading: 'Attention, before any maths',
      blocks: [
        ProseBlock(
          'Take the sentence "the animal did not cross the street because it '
          'was too tired". What does "it" refer to? A human resolves this '
          'instantly: "tired" applies to animals, not to streets, so "it" is '
          'the animal. Notice what you did — you looked at other words in the '
          'sentence and weighted them by relevance. "Animal" mattered a lot, '
          '"street" mattered a little, "because" barely mattered at all.',
        ),
        ProseBlock(
          'That is attention. For each position, the model produces a new '
          'representation which is a weighted average of the representations '
          'of every position in the sequence, including itself. The weights '
          'are not fixed and are not a function of position — they are '
          'computed from the content of the vectors themselves, on every '
          'forward pass, for every input. When the sentence changes to '
          '"because it was too wide", the weights shift towards "street" '
          'without anything in the model changing.',
        ),
        ProseBlock(
          'The word "self" in self-attention means the queries, keys and '
          'values all come from the same sequence: the sentence is looking at '
          'itself. Cross-attention is the same operation with the queries from '
          'one sequence and the keys and values from another, which is how a '
          'translation decoder consults the encoded source sentence. Same '
          'mechanism, different wiring.',
        ),
        ProseBlock(
          'Two consequences follow immediately and are worth holding onto. '
          'Attention is a set operation — shuffle the input tokens and the '
          'output tokens shuffle with them, but nothing else changes, so the '
          'mechanism has no idea what order the words came in. And every '
          'position attends to every other, so the cost grows with the square '
          'of the sequence length. The rest of the architecture is largely '
          'about living with those two facts.',
        ),
      ],
    ),
    Section(
      id: 'self-attention',
      heading: 'Queries, keys and values',
      blocks: [
        ProseBlock(
          'The retrieval metaphor is the standard one and it earns its keep. '
          'Each token emits a **query**: "here is what I am looking for". Each '
          'token also emits a **key**: "here is what I offer". The '
          'compatibility between a query and a key — their dot product — says '
          'how much that pair should interact. Each token finally emits a '
          '**value**: the content actually passed on when it is attended to. '
          'All three are produced from the same input vector by three separate '
          'learned linear projections, which is what lets a token advertise '
          'something different from what it is looking for.',
        ),
        ProseBlock(
          'The full operation is scaled dot-product attention. Multiply the '
          'query matrix by the transpose of the key matrix to get a score for '
          'every ordered pair of positions. Divide by the square root of the '
          'key dimension. Softmax each row so the scores become weights that '
          'sum to one. Multiply by the value matrix. Four lines of numpy, and '
          'it is the whole mechanism.',
        ),
        ProseBlock(
          'The division by the square root of the key dimension is not '
          'cosmetic. Dot products of two vectors with independent unit-'
          'variance entries have variance equal to the dimension, so in a '
          '64-dimensional head the raw scores would routinely reach ±8 or '
          'more. Softmax on values that spread out saturates: one weight goes '
          'to nearly one, the rest to nearly zero, and the gradient through '
          'the softmax collapses. Scaling keeps the scores in the range where '
          'softmax still has a useful derivative.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np

# Four tokens, four dimensions each. Pretend these are embedded tokens.
x = np.array([
    [1.0, 0.0, 1.0, 0.0],    # "the"
    [0.0, 1.0, 0.0, 1.0],    # "animal"
    [1.0, 1.0, 0.0, 0.0],    # "was"
    [0.0, 0.0, 1.0, 1.0],    # "tired"
])


def softmax(z):
    z = z - z.max(axis=-1, keepdims=True)     # stability; changes nothing else
    e = np.exp(z)
    return e / e.sum(axis=-1, keepdims=True)


def attention(q, k, v):
    d_k = q.shape[-1]
    scores = q @ k.T / np.sqrt(d_k)           # (tokens, tokens)
    weights = softmax(scores)                 # each row sums to 1
    return weights @ v, weights


# In a real layer these are learned. Fixed to the identity here so that the
# only thing on display is the mechanism itself.
w_q = w_k = w_v = np.eye(4)
out, w = attention(x @ w_q, x @ w_k, x @ w_v)

print(w.round(3))
# [[0.387 0.143 0.235 0.235]     row i = how much token i attends to each token
#  [0.143 0.387 0.235 0.235]
#  [0.235 0.235 0.387 0.143]
#  [0.235 0.235 0.143 0.387]]

print(w.sum(axis=1))             # [1. 1. 1. 1.]

print(out.round(3))
# [[0.622 0.378 0.622 0.378]     each row is a blend of all four value vectors
#  [0.378 0.622 0.378 0.622]
#  [0.622 0.622 0.378 0.378]
#  [0.378 0.378 0.622 0.622]]
''',
          caption:
              'With identity projections every token attends most to itself '
              'and least to the token it shares nothing with — the diagonal '
              'dominance is the dot product measuring similarity.',
        ),
        ProseBlock(
          'Read the weight matrix as a directed graph. Row two, column one is '
          'how much "animal" contributes to the new representation of "was". '
          'It is not symmetric in general — here it happens to be, because the '
          'identity projections make queries and keys identical, but once '
          'separate weights are learned "it" can attend heavily to "animal" '
          'while "animal" largely ignores "it".',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Softmax is per row, not over the whole matrix',
          text:
              'Every row of the weight matrix must sum to one, because each '
              'row is one token distributing its fixed attention budget across '
              'the sequence. Applying softmax over the flattened matrix, or '
              'along the wrong axis, produces something that still trains '
              'without error and still converges to something — just far '
              'worse. Assert that the row sums equal one; it is the cheapest '
              'bug check in the whole layer.',
        ),
      ],
    ),
    Section(
      id: 'multi-head',
      heading: 'Multi-head attention',
      blocks: [
        ProseBlock(
          'One attention operation produces one weighted average per position, '
          'which forces every kind of relationship in the sentence through a '
          'single set of weights. But "it" needs to attend to "animal" for '
          'coreference and to "was" for grammatical agreement at the same '
          'time, and one distribution cannot peak in two places without '
          'blurring both.',
        ),
        ProseBlock(
          'Multi-head attention runs several attention computations in '
          'parallel, each with its own learned query, key and value '
          'projections. Each head therefore builds its own similarity metric '
          'over the same tokens and produces its own weight matrix. Trained '
          'models really do specialise: probing studies find heads that track '
          'syntactic dependencies, heads that resolve coreference, heads that '
          'attend to the previous token, and — famously — a number of heads '
          'that do almost nothing and can be pruned.',
        ),
        ProseBlock(
          'The bookkeeping is the part worth internalising, because it is '
          'where the shape bugs live. The model dimension is split rather than '
          'multiplied: with a model dimension of 512 and eight heads, each '
          'head works in 64 dimensions, so multi-head attention costs roughly '
          'the same as single-head attention at full width. The heads are '
          'concatenated back to the model dimension and passed through one '
          'final output projection, which lets the layer mix what the '
          'different heads found rather than leaving them in separate lanes.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np

n_tokens, d_model, n_heads = 4, 8, 2
d_k = d_model // n_heads             # 4 dims per head, not 8 per head

rng = np.random.default_rng(0)
x = rng.normal(size=(n_tokens, d_model))
w_q = rng.normal(size=(d_model, d_model))
w_o = rng.normal(size=(d_model, d_model))

# One big projection, then split the last axis into heads.
q = x @ w_q                                     # (4, 8)
q = q.reshape(n_tokens, n_heads, d_k)           # (4, 2, 4)
q = q.transpose(1, 0, 2)                        # (2, 4, 4)  heads first
print(q.shape)                                  # (2, 4, 4)

# k and v get identical treatment, then attention runs per head, giving
# one (tokens, d_k) output per head.
head_out = np.zeros((n_heads, n_tokens, d_k))   # (2, 4, 4)

# "Concatenate the heads" is a transpose and a reshape, nothing more.
merged = head_out.transpose(1, 0, 2).reshape(n_tokens, d_model)
print(merged.shape)                             # (4, 8)

print((merged @ w_o).shape)                     # (4, 8)  back to d_model
''',
          caption:
              'The transpose before the reshape is load-bearing: reshaping '
              'straight from (heads, tokens, d_k) interleaves the heads into '
              'the wrong positions and fails silently.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Assert shapes, not just outputs',
          text:
              'Attention code is unusually good at producing plausible '
              'garbage. A wrong transpose, a softmax on the wrong axis or a '
              'mask broadcast into the wrong dimension all yield finite '
              'numbers of the right shape and a loss that decreases. Sprinkle '
              'shape assertions through the layer and check that the attention '
              'weights sum to one along the key axis.',
        ),
      ],
    ),
    Section(
      id: 'positional-encoding',
      heading: 'Putting order back in',
      blocks: [
        ProseBlock(
          'Attention has no notion of sequence. Every position is treated as '
          'an unordered element of a set, so "the dog bit the man" and "the '
          'man bit the dog" produce the same multiset of representations. For '
          'a language model that is fatal, and the fix is to add position '
          'information to the embeddings before the first attention layer.',
        ),
        ProseBlock(
          'The original paper used a fixed sinusoidal encoding. Each embedding '
          'dimension pair gets its own frequency, geometrically spaced from '
          'one full cycle every few tokens down to one cycle every tens of '
          'thousands of tokens. The early dimensions therefore change quickly '
          'from position to position while the later ones barely move — like '
          'the digits of a binary counter, but continuous. Any position is '
          'uniquely identified by the combination.',
        ),
        ProseBlock(
          'The reason for sinusoids specifically is relative position. Because '
          'a sine and cosine at the same frequency can be rotated by a fixed '
          'angle to give the sine and cosine at an offset position, the '
          'encoding of position plus k is a linear function of the encoding of '
          'position — a relationship a linear projection can learn to exploit. '
          'The encoding is also parameter-free and defined for every integer, '
          'so it extends past the longest training sequence, at least in '
          'principle.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np


def positional_encoding(n_positions, d_model):
    pos = np.arange(n_positions)[:, None]          # (positions, 1)
    i = np.arange(0, d_model, 2)[None, :]          # even dimension indices
    freq = 1.0 / (10000 ** (i / d_model))          # one frequency per pair
    pe = np.zeros((n_positions, d_model))
    pe[:, 0::2] = np.sin(pos * freq)
    pe[:, 1::2] = np.cos(pos * freq)
    return pe


print(positional_encoding(4, 8).round(3))
# [[ 0.     1.     0.     1.     0.     1.     0.     1.   ]
#  [ 0.841  0.54   0.1    0.995  0.01   1.     0.001  1.   ]
#  [ 0.909 -0.416  0.199  0.98   0.02   1.     0.002  1.   ]
#  [ 0.141 -0.99   0.296  0.955  0.03   1.     0.003  1.   ]]
#
# Left columns swing widely between rows; right columns are nearly constant
# over four positions and only separate over hundreds.

# Position is added to the token embedding, not concatenated.
embeddings = np.zeros((4, 8))
inputs = embeddings + positional_encoding(4, 8)
''',
          caption:
              'The encoding is added to the embedding, so the model must learn '
              'to keep content and position readable from the same vector.',
        ),
        ProseBlock(
          'Practice has moved on. BERT and GPT-2 used learned absolute '
          'position embeddings — just another lookup table — which train '
          'easily but cannot generalise past the trained length at all. '
          'Current models mostly use relative schemes: rotary embeddings '
          '(RoPE), which rotate queries and keys by an angle proportional to '
          'position so that the dot product depends only on the offset, or '
          'ALiBi, which simply subtracts a distance-proportional penalty from '
          'the attention scores. Both extrapolate to longer contexts far '
          'better than absolute schemes, which is why context windows have '
          'grown so quickly.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: encoder-only, decoder-only, encoder-decoder',
          children: [
            ProseBlock(
              'The original transformer was an encoder-decoder built for '
              'translation. The encoder reads the source sentence with full '
              'bidirectional self-attention; the decoder generates the target '
              'one token at a time, using masked self-attention over what it '
              'has produced so far plus cross-attention into the encoder '
              'output. Three attention blocks in total, two of them '
              'self-attention and one cross.',
            ),
            ProseBlock(
              'Encoder-only models — BERT and its descendants — keep just the '
              'first half. Every token sees every other token in both '
              'directions, which produces excellent contextual '
              'representations, and they are trained by masking out random '
              'tokens and predicting them. That bidirectionality is exactly '
              'why they cannot generate text: predicting the next token is '
              'trivial if you are allowed to look at it. They are the right '
              'choice for classification, entity extraction, retrieval '
              'embeddings and reranking.',
            ),
            ProseBlock(
              'Decoder-only models — GPT and essentially every current large '
              'language model — keep just the second half and drop the '
              'cross-attention, leaving one stack of causally masked '
              'self-attention layers. The mask is an upper-triangular block of '
              'negative infinity added to the scores before the softmax, so '
              'position i can attend only to positions up to and including i. '
              'That single constraint is what makes the architecture '
              'autoregressive, and it is also what makes training efficient: '
              'one forward pass over a sequence yields a next-token prediction '
              'at every position simultaneously.',
            ),
            ProseBlock(
              'Encoder-decoder models like T5 and BART survive where the input '
              'and output are genuinely different sequences — translation, '
              'summarisation, speech transcription. Their advantage is clean '
              'separation: the encoder can read the input bidirectionally '
              'while the decoder generates causally. The trend has '
              'nonetheless been towards decoder-only, largely because a single '
              'stack scales more simply and because framing every task as text '
              'continuation turned out to be enough.',
            ),
            ProseBlock(
              'One cost is shared by all three. Full attention computes a '
              'score for every pair of positions, so memory and compute grow '
              'with the square of sequence length: doubling the context '
              'quadruples the attention cost. FlashAttention removes the '
              'memory blow-up by never materialising the full matrix, and '
              'sparse, sliding-window and linear-attention variants attack the '
              'compute, but the quadratic term is the reason long context was '
              'a research problem rather than a configuration flag.',
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
      id: 'ex-tfm-attention',
      title: 'Scaled dot-product attention from scratch',
      prompt: [
        ProseBlock(
          'Implement softmax and scaled dot-product attention with numpy '
          'only. Given query, key and value matrices, compute '
          'softmax(QKᵀ / √d_k)V and return both the output and the attention '
          'weights.',
        ),
        ProseBlock(
          'Subtract the row maximum before exponentiating — it leaves the '
          'result unchanged mathematically and prevents overflow on large '
          'scores. Then assert that every row of the weight matrix sums to '
          'one, which is the invariant that catches a softmax applied along '
          'the wrong axis.',
        ),
      ],
      starterCode: '''
import numpy as np

q = np.array([[1.0, 0.0],
              [0.0, 1.0],
              [1.0, 1.0]])
k = q.copy()
v = np.array([[10.0,  0.0],
              [ 0.0, 10.0],
              [ 5.0,  5.0]])


def softmax(z):
    """Row-wise softmax, numerically stable."""
    ...


def attention(q, k, v):
    """Return (output, weights) for scaled dot-product attention."""
    ...


out, w = attention(q, k, v)
print(w.round(3))
print(out.round(3))
''',
      solutionCode: '''
import numpy as np

q = np.array([[1.0, 0.0],
              [0.0, 1.0],
              [1.0, 1.0]])
k = q.copy()
v = np.array([[10.0,  0.0],
              [ 0.0, 10.0],
              [ 5.0,  5.0]])


def softmax(z):
    """Row-wise softmax, numerically stable."""
    z = z - z.max(axis=-1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=-1, keepdims=True)


def attention(q, k, v):
    """Return (output, weights) for scaled dot-product attention."""
    d_k = q.shape[-1]
    scores = q @ k.T / np.sqrt(d_k)
    weights = softmax(scores)
    assert np.allclose(weights.sum(axis=-1), 1.0)
    return weights @ v, weights


out, w = attention(q, k, v)

print(w.round(3))
# [[0.401 0.198 0.401]
#  [0.198 0.401 0.401]
#  [0.248 0.248 0.503]]

print(out.round(3))
# [[6.017 3.983]
#  [3.983 6.017]
#  [5.    5.   ]]

# Token 2 queries in both directions equally, so it lands on the midpoint
# of the two extreme value vectors.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Remove the division by the square root of d_k and imagine d_k '
              'is 64 rather than 2. What breaks?',
          expectedAnswer:
              'With unit-variance entries the dot product has variance equal '
              'to d_k, so scores spread over roughly ±8 instead of ±1. '
              'Softmax on that range is nearly one-hot: one weight sits at '
              'almost 1, the rest at almost 0, so the output copies a single '
              'value vector and the softmax gradient is close to zero '
              'everywhere. Training stalls in the early layers. The scaling '
              'keeps the score variance near one regardless of head width.',
        ),
        SelfCheckQuestion(
          question:
              'Why do queries and keys come from separate projections when '
              'this exercise sets k equal to q?',
          expectedAnswer:
              'Separate projections let the relation be asymmetric. With '
              'k = q the score matrix is symmetric, so "it" must attend to '
              '"animal" exactly as much as "animal" attends to "it". Real '
              'linguistic relations are directional — a pronoun needs its '
              'antecedent far more than the antecedent needs the pronoun — and '
              'independent W_q and W_k are what allow a token to advertise '
              'something different from what it is searching for.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-tfm-causal-mask',
      title: 'Build the causal mask',
      prompt: [
        ProseBlock(
          'A decoder-only model must never let position i use information from '
          'position j > i, or it learns to predict the next token by reading '
          'it. Add an upper-triangular mask of negative infinity to the scores '
          'before the softmax so those weights become exactly zero.',
        ),
        ProseBlock(
          'Use the same four-token toy sequence as the lesson. Print the '
          'unmasked and masked weight matrices side by side and confirm three '
          'things: the masked matrix is lower-triangular, its rows still sum '
          'to one, and the final row is unchanged because it was already '
          'allowed to see everything.',
        ),
      ],
      starterCode: '''
import numpy as np

x = np.array([
    [1.0, 0.0, 1.0, 0.0],
    [0.0, 1.0, 0.0, 1.0],
    [1.0, 1.0, 0.0, 0.0],
    [0.0, 0.0, 1.0, 1.0],
])


def softmax(z):
    z = z - z.max(axis=-1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=-1, keepdims=True)


def causal_mask(n):
    """Return an (n, n) additive mask: 0 where allowed, -inf where not."""
    ...


def attention(q, k, v, mask=None):
    """Scaled dot-product attention, with mask added to the scores."""
    ...


print(attention(x, x, x)[1].round(3))
print(attention(x, x, x, mask=causal_mask(4))[1].round(3))
''',
      solutionCode: '''
import numpy as np

x = np.array([
    [1.0, 0.0, 1.0, 0.0],
    [0.0, 1.0, 0.0, 1.0],
    [1.0, 1.0, 0.0, 0.0],
    [0.0, 0.0, 1.0, 1.0],
])


def softmax(z):
    z = z - z.max(axis=-1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=-1, keepdims=True)


def causal_mask(n):
    """Return an (n, n) additive mask: 0 where allowed, -inf where not."""
    mask = np.zeros((n, n))
    mask[np.triu_indices(n, k=1)] = -np.inf     # strictly above the diagonal
    return mask


def attention(q, k, v, mask=None):
    """Scaled dot-product attention, with mask added to the scores."""
    d_k = q.shape[-1]
    scores = q @ k.T / np.sqrt(d_k)
    if mask is not None:
        scores = scores + mask                  # -inf survives the max shift
    weights = softmax(scores)
    return weights @ v, weights


unmasked = attention(x, x, x)[1]
masked = attention(x, x, x, mask=causal_mask(4))[1]

print(unmasked.round(3))
# [[0.387 0.143 0.235 0.235]
#  [0.143 0.387 0.235 0.235]
#  [0.235 0.235 0.387 0.143]
#  [0.235 0.235 0.143 0.387]]

print(masked.round(3))
# [[1.    0.    0.    0.   ]     token 0 can only see itself
#  [0.269 0.731 0.    0.   ]
#  [0.274 0.274 0.452 0.   ]
#  [0.235 0.235 0.143 0.387]]    unchanged: nothing was in its future

assert np.allclose(masked.sum(axis=-1), 1.0)
assert np.allclose(np.triu(masked, k=1), 0.0)
assert np.allclose(masked[-1], unmasked[-1])
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why add negative infinity before the softmax rather than '
              'zeroing the weights after it?',
          expectedAnswer:
              'Because the softmax must renormalise over the surviving '
              'positions only. Zeroing afterwards leaves rows that sum to less '
              'than one, so early positions produce systematically '
              'smaller-magnitude outputs than late ones and you would have to '
              'renormalise by hand anyway. Adding negative infinity to the '
              'scores makes exp of that term exactly zero and the denominator '
              'automatically covers just the allowed keys.',
        ),
        SelfCheckQuestion(
          question:
              'A model trains to a suspiciously low loss and then generates '
              'incoherent text. How would the causal mask be a suspect?',
          expectedAnswer:
              'A missing or wrongly oriented mask lets each position see the '
              'token it is being asked to predict, so training loss collapses '
              'towards zero — the task is copying, not prediction. At '
              'inference the future does not exist, the model faces an input '
              'distribution it never trained on, and output degenerates. The '
              'diagnostic signature is an implausibly low training loss '
              'alongside poor generation; the check is to print the attention '
              'weight matrix and assert its strict upper triangle is zero.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-tfm-positional',
      title: 'Give identical tokens different identities',
      prompt: [
        ProseBlock(
          'Build a four-token sequence in which tokens 0 and 2 have exactly '
          'the same embedding — the repeated word "the", say. Implement the '
          'sinusoidal positional encoding, add it to the embeddings, and show '
          'that the two rows are identical before the addition and distinct '
          'after it.',
        ),
        ProseBlock(
          'Then check the last two dimensions across all four positions and '
          'note how little they move. That slowness is deliberate: the '
          'low-frequency dimensions are what distinguish position 5 from '
          'position 5000, and they are useless over a span of four.',
        ),
      ],
      starterCode: '''
import numpy as np

embeddings = np.array([
    [1.0, 0.0, 1.0, 0.0],    # "the"
    [0.0, 1.0, 0.0, 1.0],    # "cat"
    [1.0, 0.0, 1.0, 0.0],    # "the"  <- identical to position 0
    [0.5, 0.5, 0.5, 0.5],    # "mat"
])


def positional_encoding(n_positions, d_model):
    """Sinusoidal encoding: sin on even dims, cos on odd dims."""
    ...


print(np.allclose(embeddings[0], embeddings[2]))
# TODO: add the encoding and compare again
''',
      solutionCode: '''
import numpy as np

embeddings = np.array([
    [1.0, 0.0, 1.0, 0.0],    # "the"
    [0.0, 1.0, 0.0, 1.0],    # "cat"
    [1.0, 0.0, 1.0, 0.0],    # "the"  <- identical to position 0
    [0.5, 0.5, 0.5, 0.5],    # "mat"
])


def positional_encoding(n_positions, d_model):
    """Sinusoidal encoding: sin on even dims, cos on odd dims."""
    pos = np.arange(n_positions)[:, None]
    i = np.arange(0, d_model, 2)[None, :]
    freq = 1.0 / (10000 ** (i / d_model))
    pe = np.zeros((n_positions, d_model))
    pe[:, 0::2] = np.sin(pos * freq)
    pe[:, 1::2] = np.cos(pos * freq)
    return pe


pe = positional_encoding(4, 4)
print(pe.round(3))
# [[ 0.     1.     0.     1.   ]
#  [ 0.841  0.54   0.01   1.   ]
#  [ 0.909 -0.416  0.02   1.   ]
#  [ 0.141 -0.99   0.03   1.   ]]

inputs = embeddings + pe
print(inputs.round(3))
# [[ 1.     1.     1.     1.   ]
#  [ 0.841  1.54   0.01   2.   ]
#  [ 1.909 -0.416  1.02   1.   ]
#  [ 0.641 -0.49   0.53   1.5  ]]

print(np.allclose(embeddings[0], embeddings[2]))    # True  - same word
print(np.allclose(inputs[0], inputs[2]))            # False - different slot

# The high-frequency pair moves a lot across four positions; the
# low-frequency pair barely moves at all.
print(pe[:, 0:2].ptp(axis=0).round(3))    # [0.909 1.99 ]
print(pe[:, 2:4].ptp(axis=0).round(3))    # [0.03  0.   ]
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Positional encodings are added to the embeddings rather than '
              'concatenated. Does that not corrupt the content?',
          expectedAnswer:
              'It mixes them into one vector, but the model can still separate '
              'them because the query, key and value projections are learned '
              'and can allocate directions in the space to content and to '
              'position. Adding keeps the model dimension fixed and costs no '
              'extra parameters, whereas concatenation would either shrink the '
              'budget available for content or widen every downstream matrix. '
              'In practice addition works, which is the argument that '
              'ultimately settled it.',
        ),
        SelfCheckQuestion(
          question:
              'What would you expect if you trained with sequences of 512 '
              'tokens and then ran inference on 4000?',
          expectedAnswer:
              'Sinusoidal encodings are defined for any position, so nothing '
              'errors, but quality degrades sharply: the model has never seen '
              'the encoding patterns beyond 512 and attention scores drift out '
              'of the distribution it learned to interpret. Learned absolute '
              'position embeddings are worse still — there is simply no row in '
              'the table for position 4000. Relative schemes such as RoPE and '
              'ALiBi, which depend on the offset between two positions rather '
              'than their absolute index, extrapolate considerably better.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-tfm-causal-mask',
      title: 'Build the causal attention mask',
      prompt: [
        ProseBlock(
          'Implement causal_mask(n) that returns an n×n mask matrix '
          'where position i can attend to positions 0 through i '
          '(inclusive). Use -inf for forbidden positions. Then use it '
          'with the attention function from the earlier exercise to '
          'verify that position 0 only attends to itself while position '
          'n-1 attends to everything.',
        ),
      ],
      starterCode: '''
import numpy as np


def causal_mask(n):
    """Return (n, n) mask: mask[i, j] = 0 if j <= i, else -inf."""
    ...


def softmax(z):
    z = z - z.max(axis=-1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=-1, keepdims=True)


def attention(q, k, v, mask=None):
    d_k = q.shape[-1]
    scores = q @ k.T / np.sqrt(d_k)
    if mask is not None:
        scores = scores + mask    # -inf in forbidden positions
    weights = softmax(scores)
    return weights @ v, weights


# Test with 4 random tokens, 4 dimensions each.
rng = np.random.default_rng(0)
x = rng.normal(size=(4, 4))
out, w = attention(x, x, x, mask=causal_mask(4))
print("Attention weights (should be lower-triangular):")
print(w.round(3))
# TODO: verify row 0 only attends to position 0
# TODO: verify row 3 attends to all 4 positions
''',
      solutionCode: '''
import numpy as np


def causal_mask(n):
    """Return (n, n) mask: mask[i, j] = 0 if j <= i, else -inf."""
    mask = np.zeros((n, n))
    for i in range(n):
        for j in range(n):
            if j > i:            # position i cannot see position j
                mask[i, j] = -np.inf
    return mask


def softmax(z):
    z = z - z.max(axis=-1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=-1, keepdims=True)


def attention(q, k, v, mask=None):
    d_k = q.shape[-1]
    scores = q @ k.T / np.sqrt(d_k)
    if mask is not None:
        scores = scores + mask
    weights = softmax(scores)
    return weights @ v, weights


rng = np.random.default_rng(0)
x = rng.normal(size=(4, 4))
out, w = attention(x, x, x, mask=causal_mask(4))
print("Attention weights (lower-triangular):")
print(w.round(3))

# Row 0: only position 0 has non-zero weight (sums to 1.0)
assert w[0, 0] > 0.99, "Position 0 should only attend to itself"
# Row 3: all positions 0-3 have non-zero weight
assert np.all(w[3] > 0), "Position 3 should attend to all tokens"
# Upper triangle (j > i) should be zero
assert np.allclose(w[0, 1:], 0), "Upper triangle must be zero"
print("All assertions passed!")
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'What happens if you forget the causal mask in a decoder-only '
              'transformer during training?',
          expectedAnswer:
              'Without the mask, every position can attend to every other '
              'position including future ones. During training the model '
              'can simply copy the correct next token from the input — '
              'the training loss drops to nearly zero, but the model has '
              'learned nothing about prediction. At inference time, when '
              'future tokens are not available, it produces random or '
              'degenerate output because it never actually learned to '
              'predict the next token from the prefix alone. The mask is '
              'not an optimisation detail; it is the structural constraint '
              'that makes the autoregressive objective meaningful.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 234000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Transformers in six minutes. Picture reading a long email. '
              'A human skims it — your eye jumps back to the subject line, '
              'connects "she" on line twelve to "Alice" on line two, and '
              'understands it all at once. Old recurrent networks could not do '
              'that. They read one word at a time like someone sounding out '
              'each syllable, carrying everything they had ever read in '
              'one tiny memory that got overwritten at every step. Information '
              'from the first sentence had to survive hundreds of rewrites to '
              'reach the last — and usually did not.',
          startMs: 0,
          endMs: 40000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'The transformer replaced that with self-attention — every word '
              'looking directly at every other word at the same time. It is '
              'like upgrading from a whisper-down-the-lane game to a '
              'conference call where everyone can hear everyone else '
              'simultaneously. Any two words become one hop apart, no matter '
              'how far apart they are in the text. And the entire sequence '
              'becomes one giant matrix multiplication — exactly the thing '
              'GPUs are built to do fast.',
          startMs: 40000,
          endMs: 78000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'The mechanism is beautifully clean. Each word projects into '
              'three roles: a query asking "what information do I need?", a '
              'key advertising "here is what I know", and a value containing '
              'the actual content to share. Every query checks in with every '
              'key, gets a compatibility score, and those scores become mixing '
              'weights for blending the values. It is like each word in a '
              'sentence walking around the room asking everyone else "do you '
              'have anything relevant?", then building its understanding from '
              'the most useful answers.',
          startMs: 78000,
          endMs: 118000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Multi-head just runs several of these conversations in parallel '
              'with different question styles. One head might track grammar — '
              '"what\'s the subject of this verb?" — while another resolves '
              'pronouns — "who does \'she\' refer to?" — and another just '
              'looks at the previous word. You split the model dimension across '
              'heads rather than multiplying it, so the cost stays the same, '
              'then merge everything back together with one final projection.',
          startMs: 118000,
          endMs: 158000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'One catch: attention has no clue about word order. It treats '
              'the sentence like a bag of words. "The dog bit the man" and '
              '"the man bit the dog" look identical to pure attention. '
              'Positional encoding fixes this by stamping each word with a '
              'unique pattern based on where it sits — like giving every word '
              'a different-sounding chime when it enters the room. The '
              'original paper used sine waves at different frequencies, and '
              'modern models mostly use rotary encodings that care about '
              'relative distances between words rather than absolute slot '
              'numbers.',
          startMs: 158000,
          endMs: 198000,
        ),
        PodcastSegment(
          id: 'c6',
          speaker: 'Guest',
          text:
              'And one cost to carry forward: every pair of words computes a '
              'score, so attention is quadratic in sequence length. Double the '
              'context and you quadruple the work. That single fact is why '
              'long context windows were a research problem for years rather '
              'than just a setting you turned up. FlashAttention, sparse '
              'patterns, and clever approximations all attack this same '
              'quadratic wall from different angles.',
          startMs: 198000,
          endMs: 234000,
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
              'Let us start with what was actually painful about the old way. '
              'Imagine trying to understand a novel by reading it one word at '
              'a time, keeping a single sticky note as your only memory. Every '
              'time you read a new word, you have to throw away the old note '
              'and write a new summary that somehow captures everything you '
              'have read so far. By chapter ten, that sticky note is a mess. '
              'That is exactly how recurrent networks worked — one hidden '
              'state, overwritten at every token, asked to carry the meaning '
              'of an entire paragraph.',
          startMs: 0,
          endMs: 58000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'And the sequential bottleneck was arguably worse for practical '
              'use. Step forty cannot start until step thirty-nine finishes, '
              'so your expensive GPU with thousands of parallel cores sits '
              'mostly idle, processing one word at a time like a typist from '
              'the 1950s. Attention had already been invented as a band-aid '
              'for this — let the decoder peek back at all the encoder\'s '
              'hidden states instead of relying on one summary. The '
              'transformer paper asked the obvious next question: what if we '
              'throw away the recurrence entirely and keep only the peeking?',
          startMs: 58000,
          endMs: 122000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Intuition first, with the classic example. "The animal did not '
              'cross the street because it was too tired." What is "it"? Your '
              'brain instantly connects "tired" to "animal" — streets do not '
              'get tired. You just did attention: you looked at every word in '
              'the sentence, weighted them by relevance, and built your '
              'understanding from the most relevant ones. That is exactly what '
              'self-attention computes — a weighted blend of every word\'s '
              'meaning, with weights determined fresh for each input.',
          startMs: 122000,
          endMs: 186000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Mechanically, three learned projections per word. The query '
              'asks "what am I looking for?" The key advertises "here is what '
              'I know." The value is the payload — the actual content handed '
              'over when someone attends to you. Query dot key gives a '
              'compatibility score for every pair of words. Softmax turns '
              'those scores into mixing weights that sum to one. Multiply by '
              'the values. Four matrix operations and you have self-attention. '
              'The whole thing fits in a few lines of NumPy.',
          startMs: 186000,
          endMs: 252000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'The scaling factor by the square root of the key dimension '
              'looks like a minor detail. It is not. In a 64-dimensional '
              'attention head, the raw dot products routinely spread across '
              '±8 or more. Softmax on that range becomes nearly one-hot — '
              'one word gets almost all the weight, the rest get almost zero, '
              'and the gradient through the softmax vanishes. Dividing by '
              '√64 = 8 keeps scores in the range where attention is '
              'genuinely distributed and gradients flow. One square root '
              'separates a trainable layer from a broken one.',
          startMs: 252000,
          endMs: 316000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Then multi-head. One attention pattern per word is not enough. '
              'A pronoun like "it" needs to attend to "animal" for meaning and '
              'to "was" for grammar at the same time. One softmax distribution '
              'cannot peak in two places without blurring both. Run several '
              'attention operations in parallel with independent projections. '
              'With 512 model dimensions and 8 heads, each head works in 64 '
              'dimensions — you split the width, you do not multiply it. '
              'Concatenate the head outputs back together and project once '
              'more.',
          startMs: 316000,
          endMs: 378000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Now the thing everyone forgets: attention does not know word '
              'order at all. Shuffle the input sentence and you get the same '
              'output vectors, just shuffled. "The dog bit the man" and "the '
              'man bit the dog" are identical to pure attention. Positional '
              'encoding stamps each word with where it sits — the original '
              'paper used sine waves at geometrically spaced frequencies, '
              'like a continuous binary counter. Fast-changing dimensions '
              'distinguish neighbours; slow ones tell position 5 from '
              'position 5000.',
          startMs: 378000,
          endMs: 440000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Practice has moved on: rotary embeddings (RoPE) and ALiBi '
              'encode the distance between two words rather than their '
              'absolute position, and they extrapolate to longer contexts '
              'far better. But the principle is unchanged. Attention gives '
              'you content-based routing with zero notion of sequence. '
              'Something else has to inject the order. That something is '
              'positional encoding, in one form or another, and it is added '
              'before the very first attention layer touches anything.',
          startMs: 440000,
          endMs: 498000,
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
              'Deep dive on transformers. Picture trying to coordinate a '
              'conversation where every speaker can look at every other speaker '
              'simultaneously, deciding in real time who has the most relevant '
              'thing to say. That is self-attention, and in the next forty '
              'minutes we will walk through why recurrence had to go, the '
              'mechanism of attention in full detail, multi-head parallelism, '
              'positional encoding, the three architectural families, and the '
              'quadratic cost that has shaped every efficiency innovation.',
          startMs: 0,
          endMs: 62000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with the failure of recurrence. An LSTM compresses '
              'everything it has read into one hidden vector and overwrites '
              'that vector at every single token. It is like writing your '
              'entire life story on one Post-it note, erasing and rewriting it '
              'thousands of times. The gates in an LSTM slow the forgetting '
              'but do not stop it. And gradients travelling from a late word '
              'back to an early one must pass through every intermediate '
              'computation — each one multiplying the signal by some number '
              'less than one. After a few hundred steps, the gradient reaching '
              'the early layers is effectively zero.',
          startMs: 62000,
          endMs: 136000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'And the parallelism problem is arguably the bigger one for '
              'practical impact. Sequential computation means your GPU with '
              'thousands of cores runs like a single-file queue. When the '
              'transformer turned an entire training sequence into one giant '
              'batch of matrix multiplications, it did not just improve model '
              'quality. It changed the economics of scale. Training that used '
              'to be limited by wall-clock time became limited by how much '
              'compute you could afford to throw at it. That economic shift '
              'is why models grew by orders of magnitude in the years after '
              '2017.',
          startMs: 136000,
          endMs: 212000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Attention itself: for each word, a weighted average of every '
              'word, with weights computed from the vectors themselves. The '
              'retrieval metaphor is the clearest frame. Each word emits a '
              'query — "here is what I need to know." Each word also emits a '
              'key — "here is what I can tell you." And a value — "here is '
              'the actual content I will share." Three separate learned '
              'projections from the same input vector. That separation is '
              'crucial: it lets a word advertise something completely '
              'different from what it is looking for. A pronoun needs its '
              'antecedent far more than the antecedent needs the pronoun.',
          startMs: 212000,
          endMs: 286000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Read the attention weight matrix as a directed graph over '
              'words. Row i, column j tells you how much word i draws from '
              'word j. It is not symmetric once the projections are learned — '
              'and that asymmetry is exactly the point. Each row sums to one: '
              'every word has a fixed attention budget to spend across the '
              'sequence. A word cannot pay more attention overall; it can only '
              'redistribute where it focuses. That budget constraint is built '
              'into the softmax.',
          startMs: 286000,
          endMs: 360000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'On scaling: dot products of independent unit-variance vectors '
              'have variance equal to the dimension. In a 64-dimensional '
              'attention head, raw scores routinely hit ±8. Softmax on ±8 '
              'pushes nearly all probability mass onto one key — the output '
              'becomes a copy of one value vector, and the gradient through '
              'the softmax collapses. Divide by √d_k and the score variance '
              'returns to about one regardless of head width. One square root '
              'stands between a layer that trains and a layer that stares '
              'blankly at one word.',
          startMs: 360000,
          endMs: 432000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Multi-head: one softmax distribution cannot peak in two places '
              'without blurring both. But a word frequently needs several '
              'kinds of context at once — grammatical agreement with the verb, '
              'coreference with the noun, proximity to the previous word. '
              'Independent projections per head give each head its own '
              'similarity metric over the same tokens. Probing studies confirm '
              'heads do specialise — some track syntax, some track entities, '
              'some just attend to the previous token. And many heads do '
              'almost nothing and can be pruned away with no loss.',
          startMs: 432000,
          endMs: 506000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Positional encoding closes the gap between a set operation and '
              'a sequence model. Pure attention treats the input as an '
              'unordered bag — "dog bites man" and "man bites dog" are '
              'identical. Sinusoidal encoding at geometrically spaced '
              'frequencies solves this elegantly: fast-changing dimensions '
              'tell words apart locally, slow-changing ones distinguish '
              'distant positions like a continuous counter. And the key '
              'property: the encoding at position p+k is a fixed linear '
              'transform of the encoding at position p, so the model can '
              'learn to recognise relative offsets.',
          startMs: 506000,
          endMs: 580000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Three architectural families. Encoder-only — BERT — uses '
              'bidirectional attention everywhere, trained by masking tokens '
              'and predicting them from both sides. Brilliant for '
              'understanding, cannot generate — because if you can look at '
              'the next word, predicting it is not a task. Classification, '
              'entity extraction, retrieval, and reranking are where these '
              'still dominate.',
          startMs: 580000,
          endMs: 652000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Decoder-only — GPT and essentially every modern LLM — keeps '
              'one stack with a causal mask: an upper-triangular block of '
              'negative infinity added to scores before softmax, so word i '
              'can only see words up to i. That single constraint makes it '
              'autoregressive — generating one token at a time — and '
              'simultaneously makes training efficient, since one forward pass '
              'gives a next-token prediction at every position at once. The '
              'mask is what separates a language model from a cheating '
              'document reader.',
          startMs: 652000,
          endMs: 726000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Encoder-decoder — the original design — survives where input '
              'and output are genuinely different sequences: translation, '
              'summarisation, speech transcription. The decoder uses '
              'cross-attention instead of self-attention: queries come from '
              'the target side, keys and values from the encoded source. '
              'Self-attention is a sequence looking at itself. Cross-attention '
              'is one sequence looking at another. Same mechanism, different '
              'wiring, and that distinction is what people most often muddle.',
          startMs: 726000,
          endMs: 800000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Close on the cost. Every pair of words computes a score, so '
              'attention is quadratic in sequence length. Double the context '
              'and you quadruple the compute and memory. FlashAttention '
              'removes the memory blow-up by never materialising the full '
              'N×N matrix. Sparse, sliding-window, and linear-attention '
              'variants chip away at the compute. But the quadratic term is '
              'the single constraint that has shaped long-context research '
              'since 2017. Carry it forward into every later lesson: the '
              'transformer\'s greatest strength — direct access between any '
              'two positions — is also its greatest cost.',
          startMs: 800000,
          endMs: 868000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Attention replaced recurrence for two reasons',
      body:
          'Recurrent models are sequential, so they cannot exploit parallel '
          'hardware across a sequence, and information must survive a rewrite '
          'of the hidden state at every step. Self-attention makes any two '
          'positions one hop apart and turns the whole sequence into a matrix '
          'multiplication, which is what made training at scale affordable.',
    ),
    SummaryCard(
      title: 'The mechanism is four operations',
      body:
          'Project each token into a query, a key and a value. Score every '
          'query against every key with a dot product, divide by the square '
          'root of the key dimension, softmax each row into weights that sum '
          'to one, and take the weighted sum of values. Multi-head runs '
          'several of these in parallel over slices of the model dimension and '
          'projects the concatenation back down.',
    ),
    SummaryCard(
      title: 'Order and cost are the two things attention does not give you',
      body:
          'Attention is a set operation, so position must be added explicitly — '
          'sinusoidal or learned absolute encodings originally, rotary or '
          'ALiBi relative schemes now. And because every pair of positions is '
          'scored, compute and memory grow with the square of sequence length, '
          'which is the constraint behind all long-context work.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Self-attention',
      definition:
          'An operation that rebuilds each position\'s representation as a '
          'weighted average of all positions in the same sequence, where the '
          'weights are computed from the content of the vectors rather than '
          'fixed by position or distance.',
    ),
    KeyConcept(
      term: 'Query, key, value',
      definition:
          'Three vectors produced from each token by separate learned linear '
          'projections. Query dot key gives the attention score for a pair; '
          'the softmax-normalised scores weight the value vectors, which carry '
          'the content actually passed on.',
    ),
    KeyConcept(
      term: 'Scaled dot-product attention',
      definition:
          'softmax(QKᵀ / √d_k)V. The division by the square root of the key '
          'dimension keeps score variance near one, which stops the softmax '
          'from saturating and killing the gradient in wide heads.',
    ),
    KeyConcept(
      term: 'Multi-head attention',
      definition:
          'Several attention computations run in parallel with independent '
          'projections, each operating on d_model divided by the number of '
          'heads. Results are concatenated and passed through one output '
          'projection, letting different heads capture different relations.',
    ),
    KeyConcept(
      term: 'Positional encoding',
      definition:
          'Position information added to token embeddings before the first '
          'attention layer, because attention itself is order-blind. '
          'Sinusoidal encodings use geometrically spaced frequencies so that '
          'relative offsets correspond to a fixed linear transform.',
    ),
    KeyConcept(
      term: 'Causal mask',
      definition:
          'An upper-triangular block of negative infinity added to the '
          'attention scores before the softmax, so position i can attend only '
          'to positions up to i. It is what makes a decoder-only model '
          'autoregressive.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Assuming attention has some inherent sense of order or distance.',
      correction:
          'It has none. Attention is permutation-equivariant: shuffle the '
          'inputs and the outputs shuffle identically, with no other change. '
          'Order exists only because a positional encoding was added to the '
          'embeddings, and if that step is missing the model cannot tell "dog '
          'bites man" from "man bites dog".',
    ),
    Mistake(
      mistake: 'Using "self-attention" and "cross-attention" interchangeably.',
      correction:
          'Self-attention draws queries, keys and values from one sequence — a '
          'sentence attending to itself. Cross-attention takes queries from '
          'one sequence and keys and values from another, which is how a '
          'translation decoder consults the encoded source. Same maths, '
          'different inputs, and only cross-attention connects two sequences.',
    ),
    Mistake(
      mistake:
          'Omitting or misorienting the causal mask in a decoder-only model.',
      correction:
          'Without it each position sees the token it is meant to predict, so '
          'training loss collapses towards zero while generation is '
          'incoherent — the model learned to copy, not to predict. Add '
          'negative infinity strictly above the diagonal before the softmax, '
          'and assert that the strict upper triangle of the weight matrix is '
          'exactly zero.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Why divide the attention scores by the square root of the key '
          'dimension?',
      answer:
          'To keep the softmax out of its saturated regime. If query and key '
          'entries are roughly independent with unit variance, their dot '
          'product has variance equal to the key dimension, so a 64-'
          'dimensional head produces raw scores spread over roughly plus or '
          'minus eight. Softmax on that range puts almost all the mass on one '
          'key and the gradient through it is nearly zero, so the layer stops '
          'learning. Dividing by the square root of d_k restores score '
          'variance to about one independently of head width, which is why the '
          'same constant works whether the head is 32 or 128 dimensions wide. '
          'It is a variance-normalisation argument, not an arbitrary '
          'hyperparameter.',
    ),
    InterviewQuestion(
      question:
          'What does multi-head attention buy you over one wide attention '
          'head with the same parameter count?',
      answer:
          'Several independent attention distributions instead of one. A '
          'single softmax over the sequence has to spend one budget, so a '
          'token needing both its coreferent noun and its governing verb ends '
          'up blurring across both rather than attending sharply to each. '
          'Separate heads with separate projections give separate similarity '
          'metrics, and probing studies show heads specialising in positional '
          'offsets, syntactic dependencies and coreference. The cost is close '
          'to neutral because d_model is split across heads rather than '
          'duplicated. The tradeoffs are that very narrow heads lose '
          'expressiveness per head, and that a substantial fraction of heads '
          'in trained models turn out to be prunable, so more heads is not '
          'monotonically better.',
    ),
    InterviewQuestion(
      question:
          'When would you pick an encoder-only model over a decoder-only one, '
          'and what does that choice cost?',
      answer:
          'Encoder-only when the task consumes text rather than producing it — '
          'classification, entity extraction, retrieval embeddings, reranking. '
          'Bidirectional attention lets every token see both left and right '
          'context, which produces better representations for a fixed model '
          'size, and these models are typically far smaller and cheaper to '
          'serve than a generative model doing the same job. The cost is that '
          'they cannot generate at all: bidirectionality makes next-token '
          'prediction trivial, so there is no coherent way to sample from '
          'them. You also give up the in-context flexibility of a large '
          'decoder — a fine-tuned encoder needs labelled data for each new '
          'task, where an instruction-tuned decoder can often be prompted. In '
          'practice I would use an encoder for a high-throughput, fixed, '
          'well-specified task and a decoder when the output is open-ended or '
          'the task set keeps changing.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'Attention Is All You Need (Vaswani et al., 2017)',
    url: 'https://arxiv.org/abs/1706.03762',
    description:
        'The original paper, source of the scaled dot-product formulation, the '
        'multi-head split of d_model and the sinusoidal positional encoding '
        'reproduced in this lesson.',
  ),
  Source(
    title: 'Attention mechanisms — Hugging Face Transformers docs',
    url: 'https://huggingface.co/docs/transformers/main/en/attention',
    description:
        'Reference for how attention masks and the sparse and sliding-window '
        'attention variants are implemented in production libraries, behind '
        'the quadratic-cost discussion here.',
  ),
  Source(
    title: 'How do Transformers work? — Hugging Face LLM Course',
    url: 'https://huggingface.co/learn/llm-course/en/chapter1/4',
    description:
        'A practical walkthrough of the encoder-only, decoder-only and '
        'encoder-decoder families and which tasks each suits, matching the '
        'deep-dive section of this lesson.',
  ),
];

const List<Source> _furtherReading = <Source>[
  Source(
    title: 'The Illustrated Transformer (Alammar, 2018)',
    url: 'https://jalammar.github.io/illustrated-transformer/',
    description:
        'Widely-cited visual walkthrough of self-attention, multi-head '
        'attention and positional encoding with step-by-step diagrams '
        'that directly complement the code in this lesson.',
  ),
  Source(
    title: 'FlashAttention: Fast and Memory-Efficient Exact Attention',
    url: 'https://arxiv.org/abs/2205.14135',
    description:
        'The paper that removed the memory bottleneck of standard attention '
        'by tiling the computation to avoid materialising the full N×N '
        'matrix, making long-context training practical.',
  ),
  Source(
    title: 'RoFormer: Enhanced Transformer with Rotary Position Embedding',
    url: 'https://arxiv.org/abs/2104.09864',
    description:
        'Introduces RoPE, the relative position encoding used in LLaMA '
        'and most modern open-weight models, which encodes position as '
        'a rotation of the query and key vectors.',
  ),
  Source(
    title: 'The Annotated Transformer — Harvard NLP',
    url: 'https://nlp.seas.harvard.edu/annotated-transformer/',
    description:
        'Line-by-line annotated implementation of the original transformer '
        'paper in PyTorch, with detailed commentary on every component '
        'from attention to the training loop.',
  ),
];
