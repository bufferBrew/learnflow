import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 1: from a single weighted sum to a multi-layer network.
const Lesson neuralNetworksLesson = Lesson(
  id: 'ai-neural-network-basics',
  title: 'Neural Network Basics',
  description:
      'Neurons, layers, weights and non-linearity — how stacking weighted sums '
      'produces a model that can represent curves, and why the activation '
      'function is the part that makes it work.',
  estimatedMinutes: 28,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  review: _review,
  sources: _sources,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'neuron',
      heading: 'A neuron is a weighted sum with a decision attached',
      blocks: [
        ProseBlock(
          'The unit everything is built from is unglamorous: multiply each '
          'input by a weight, add them up, add a bias, and pass the result '
          'through a non-linear function. That is the whole neuron. The '
          'weighted sum measures how strongly the input matches a pattern the '
          'weights encode, the bias shifts how much evidence is needed before '
          'the unit responds, and the activation function turns the raw score '
          'into the unit\'s output.',
        ),
        ProseBlock(
          'Without the activation function, the unit is exactly linear '
          'regression. That matters more than it sounds: composing linear '
          'functions gives you another linear function, so a hundred stacked '
          'layers of pure weighted sums collapse algebraically into a single '
          'weighted sum. Depth would buy nothing at all. The non-linearity is '
          'what makes stacking meaningful.',
        ),
        ProseBlock(
          'Historically the activation was a step function, giving the '
          'perceptron: fire or do not fire. Steps have zero gradient '
          'everywhere they are defined, which makes gradient-based training '
          'impossible, so they were replaced by smooth functions and later by '
          'ReLU. The biological analogy is loose and best held lightly — these '
          'are function approximators, not simulated brains.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np


def relu(z):
    return np.maximum(0.0, z)


def neuron(x, w, b, activation=relu):
    """One unit: dot product, bias, non-linearity."""
    z = np.dot(w, x) + b      # pre-activation, sometimes called the logit
    return activation(z)


x = np.array([0.6, -1.2, 0.3])     # one example, three features
w = np.array([1.5, 0.8, -2.0])     # learned parameters
b = 0.1

print(np.dot(w, x) + b)   # -0.65   -> the raw score
print(neuron(x, w, b))    # 0.0     -> ReLU clipped it: this unit is silent
''',
          caption:
              'Pre-activation z, then the activation. Almost every network is '
              'this line repeated.',
        ),
      ],
    ),
    Section(
      id: 'layers',
      heading: 'Layers are matrix multiplications',
      blocks: [
        ProseBlock(
          'A layer is many neurons applied to the same input, so instead of a '
          'weight vector you have a weight matrix with one row per unit. The '
          'entire layer is then a single matrix–vector product plus a bias '
          'vector, followed by an element-wise activation. Batching several '
          'examples turns it into a matrix–matrix product, which is precisely '
          'the operation GPUs are built to do quickly.',
        ),
        ProseBlock(
          'Getting shapes right is most of the practical skill. With a batch X '
          'of shape (batch, in_features) and a weight matrix W of shape '
          '(in_features, out_features), the product X @ W has shape (batch, '
          'out_features) and the bias of length out_features broadcasts across '
          'rows. The output width of one layer must equal the input width of '
          'the next; nearly every runtime error in a fresh network is this '
          'chain being broken somewhere.',
        ),
        ProseBlock(
          'Stack a few such layers and you have a multi-layer perceptron: an '
          'input layer whose width is fixed by your features, one or more '
          'hidden layers whose widths you choose, and an output layer whose '
          'width and activation are fixed by the task. Depth and width are '
          'hyperparameters; the input and output shapes are not negotiable.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np

rng = np.random.default_rng(0)

batch, n_in, n_hidden, n_out = 4, 3, 5, 2

X  = rng.normal(size=(batch, n_in))          # (4, 3)
W1 = rng.normal(size=(n_in, n_hidden)) * 0.1 # (3, 5)
b1 = np.zeros(n_hidden)                      # (5,)
W2 = rng.normal(size=(n_hidden, n_out)) * 0.1
b2 = np.zeros(n_out)


def relu(z):
    return np.maximum(0.0, z)


H = relu(X @ W1 + b1)       # (4, 3) @ (3, 5) -> (4, 5)
logits = H @ W2 + b2        # (4, 5) @ (5, 2) -> (4, 2)

print(H.shape, logits.shape)     # (4, 5) (4, 2)
''',
          caption:
              'Two layers, five lines. Everything else in deep learning is '
              'variations on this.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Debug shapes before you debug learning',
          text:
              'Print the shape after every layer on a batch of two examples. '
              'A network that runs but learns nothing is often silently '
              'broadcasting where you meant to multiply, and the shapes will '
              'tell you in seconds what an hour of staring at the loss curve '
              'will not.',
        ),
      ],
    ),
    Section(
      id: 'activations',
      heading: 'Activation functions and what they cost',
      blocks: [
        ProseBlock(
          '**Sigmoid** squashes any real number into the range zero to one, '
          'which made it the natural choice for probabilities and for early '
          'hidden layers. Its problem is saturation: for inputs far from zero '
          'the curve is nearly flat, so its gradient is nearly zero, and in a '
          'deep stack those small factors multiply until the earliest layers '
          'receive essentially no learning signal. **Tanh** is the same shape '
          'centred on zero, which helps but does not cure it.',
        ),
        ProseBlock(
          '**ReLU** — output the input if positive, otherwise zero — is the '
          'modern default for hidden layers. Its gradient is exactly one for '
          'positive inputs, so signal passes through deep stacks without '
          'shrinking; it is trivially cheap to compute; and it produces sparse '
          'activations. The failure mode is the "dying ReLU": a unit pushed '
          'permanently negative has zero gradient forever and never recovers. '
          'Leaky ReLU and GELU give a small non-zero slope for negatives to '
          'avoid this.',
        ),
        ProseBlock(
          'The output layer is not a free choice — it is determined by the '
          'task. Regression uses no activation at all, so the network can '
          'produce any real number. Binary classification uses a single unit '
          'with sigmoid. Multi-class classification uses one unit per class '
          'with **softmax**, which exponentiates the scores and normalises '
          'them to sum to one.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np


def sigmoid(z):
    return 1.0 / (1.0 + np.exp(-z))


def tanh(z):
    return np.tanh(z)


def relu(z):
    return np.maximum(0.0, z)


def leaky_relu(z, slope=0.01):
    return np.where(z > 0, z, slope * z)


def softmax(z):
    # Subtract the max for numerical stability: exp(1000) overflows.
    shifted = z - np.max(z, axis=-1, keepdims=True)
    e = np.exp(shifted)
    return e / np.sum(e, axis=-1, keepdims=True)


z = np.array([-3.0, 0.0, 3.0])
print(sigmoid(z).round(3))     # [0.047 0.5   0.953]
print(relu(z))                 # [0. 0. 3.]
print(leaky_relu(z))           # [-0.03  0.    3.  ]

logits = np.array([2.0, 1.0, 0.1])
print(softmax(logits).round(3))    # [0.659 0.242 0.099]  -> sums to 1.0
''',
          caption:
              'Always subtract the max inside softmax; it changes nothing '
              'mathematically and prevents overflow.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Softmax on hidden layers is a bug',
          text:
              'Softmax couples every unit in a layer into a competition that '
              'sums to one, which destroys the independent feature detectors a '
              'hidden layer is supposed to learn. It belongs on the output of '
              'a multi-class classifier and essentially nowhere else — except '
              'inside attention, where the competition is exactly the point.',
        ),
      ],
    ),
    Section(
      id: 'representation',
      heading: 'Why depth buys representation',
      blocks: [
        ProseBlock(
          'The universal approximation theorem says a single hidden layer, '
          'given enough units, can approximate any continuous function on a '
          'bounded domain to arbitrary precision. That sounds like it settles '
          'the matter, but it says nothing about how many units "enough" is, '
          'and nothing about whether gradient descent can find those weights '
          'from data. In practice, the required width can be astronomically '
          'large.',
        ),
        ProseBlock(
          'Depth is the more efficient way to buy expressiveness. Each layer '
          'transforms the representation the previous one produced, so '
          'features compose: edges become textures, textures become parts, '
          'parts become objects. Functions with that compositional structure — '
          'which real-world data overwhelmingly has — can be represented by a '
          'deep network with exponentially fewer units than a shallow one '
          'would need.',
        ),
        ProseBlock(
          'This is the honest sense in which networks "learn features". The '
          'hidden layers are not black magic; they are a learned change of '
          'coordinates, chosen so that the final linear layer can separate the '
          'classes with a plane. The classic demonstration is XOR, which no '
          'straight line can separate in the original space — but one hidden '
          'layer bends the space until a line suffices.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np

# XOR: not linearly separable in the original two dimensions.
X = np.array([[0, 0], [0, 1], [1, 0], [1, 1]], dtype=float)
y = np.array([0, 1, 1, 0], dtype=float)

# Hand-set weights: h1 fires for OR, h2 fires only for AND, and the output
# subtracts enough AND to cancel the both-inputs-on case.
W1 = np.array([[1.0, 1.0],
               [1.0, 1.0]])
b1 = np.array([-0.5, -1.5])       # thresholds for OR and AND
W2 = np.array([[2.0], [-6.0]])
b2 = np.array([-0.5])


def relu(z):
    return np.maximum(0.0, z)


H = relu(X @ W1 + b1)             # the new coordinates
out = H @ W2 + b2

print(H)
# [[0.  0. ]   (0,0) -> neither OR nor AND
#  [0.5 0. ]   (0,1) -> OR only
#  [0.5 0. ]   (1,0) -> OR only
#  [1.5 0.5]]  (1,1) -> both

print(out.ravel())          # [-0.5  0.5  0.5 -0.5]
print((out.ravel() > 0).astype(int))   # [0 1 1 0]  -> XOR, from a linear output
''',
          caption:
              'The hidden layer is a change of coordinates that makes the '
              'problem linear.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: initialisation, and why zeros do not work',
          children: [
            ProseBlock(
              'Initialise every weight to zero and every unit in a layer '
              'computes the same output, receives the same gradient, and takes '
              'the same update. They stay identical forever, so a layer of '
              'five hundred units has the representational power of one. '
              'Breaking this symmetry is the first job of random '
              'initialisation.',
            ),
            ProseBlock(
              'The scale of that randomness matters as much as its presence. '
              'Too large and activations grow layer over layer until they '
              'saturate or overflow; too small and the signal shrinks toward '
              'zero and the early layers learn nothing. The goal is to keep '
              'the variance of activations roughly constant with depth.',
            ),
            ProseBlock(
              'Two standard schemes achieve that. Xavier (Glorot) '
              'initialisation scales the variance by one over the average of '
              'fan-in and fan-out, derived assuming a symmetric activation '
              'like tanh. He initialisation scales by two over fan-in, the '
              'factor of two compensating for ReLU zeroing out half its '
              'inputs. Use He with ReLU-family activations and Xavier with '
              'tanh or sigmoid — this is exactly what PyTorch\'s default '
              'initialisers implement.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
import numpy as np

rng = np.random.default_rng(0)
fan_in, fan_out = 256, 256

# He / Kaiming: variance 2 / fan_in, matched to ReLU.
W_he = rng.normal(0, np.sqrt(2.0 / fan_in), size=(fan_in, fan_out))

# Xavier / Glorot: variance 2 / (fan_in + fan_out), matched to tanh.
W_xavier = rng.normal(0, np.sqrt(2.0 / (fan_in + fan_out)), size=(fan_in, fan_out))

# Propagate a signal through 20 ReLU layers with each scheme.
for name, W in (("he", W_he), ("xavier", W_xavier)):
    h = rng.normal(size=(64, fan_in))
    for _ in range(20):
        h = np.maximum(0.0, h @ W)
    print(name, round(float(h.std()), 5))

# he      0.58203   -> signal preserved at a usable scale
# xavier  0.00057   -> halved every layer; almost nothing survives 20 of them
''',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'framework',
      heading: 'The same network in a framework',
      blocks: [
        ProseBlock(
          'Writing the matrix multiplications by hand is the best way to '
          'understand them and a poor way to build anything. A framework gives '
          'you layer objects that own their parameters, automatic '
          'differentiation so you never derive a gradient by hand, and '
          'GPU execution for free. The forward pass, though, is still the same '
          'five lines you wrote above.',
        ),
        ProseBlock(
          'Two conventions are worth internalising early. First, layers '
          'declare shapes as (in_features, out_features), and the chain must '
          'line up end to end. Second, classification models normally output '
          'raw logits rather than probabilities, because the standard loss '
          'functions apply the softmax or sigmoid internally in a '
          'numerically stable way. Applying softmax yourself and then using '
          'cross-entropy is a common and quietly damaging mistake.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import torch
import torch.nn as nn

model = nn.Sequential(
    nn.Linear(3, 5),    # in_features=3, out_features=5
    nn.ReLU(),
    nn.Linear(5, 2),    # 5 must match the previous layer's output
)                       # no softmax here: the loss applies it

x = torch.randn(4, 3)   # a batch of 4 examples with 3 features
logits = model(x)

print(logits.shape)                 # torch.Size([4, 2])
print(sum(p.numel() for p in model.parameters()))   # 32 = (3*5+5) + (5*2+2)

probs = torch.softmax(logits, dim=1)    # only for inspection / inference
print(probs.sum(dim=1))                 # tensor([1., 1., 1., 1.])
''',
          caption:
              'nn.Sequential composes layers; the parameter count is just '
              'weights plus biases.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-nn-forward',
      title: 'Write a forward pass from scratch',
      prompt: [
        ProseBlock(
          'Implement a two-layer network\'s forward pass with NumPy only: a '
          'hidden layer with ReLU and an output layer with softmax. It must '
          'work on a batch, so every operation needs to be shape-correct for '
          'input of shape (batch, n_features).',
        ),
        ProseBlock(
          'Remember to subtract the row maximum inside softmax, and to keep '
          'dimensions when summing so broadcasting divides row-wise.',
        ),
      ],
      starterCode: '''
import numpy as np


def relu(z):
    ...


def softmax(z):
    """Row-wise softmax over the last axis, numerically stable."""
    ...


def forward(X, W1, b1, W2, b2):
    """Return class probabilities of shape (batch, n_classes)."""
    ...


rng = np.random.default_rng(0)
X  = rng.normal(size=(4, 3))
W1 = rng.normal(size=(3, 5)) * 0.5
b1 = np.zeros(5)
W2 = rng.normal(size=(5, 2)) * 0.5
b2 = np.zeros(2)

probs = forward(X, W1, b1, W2, b2)
print(probs.shape)
print(probs.sum(axis=1))
''',
      solutionCode: '''
import numpy as np


def relu(z):
    return np.maximum(0.0, z)


def softmax(z):
    """Row-wise softmax over the last axis, numerically stable."""
    shifted = z - np.max(z, axis=-1, keepdims=True)
    e = np.exp(shifted)
    return e / np.sum(e, axis=-1, keepdims=True)


def forward(X, W1, b1, W2, b2):
    """Return class probabilities of shape (batch, n_classes)."""
    H = relu(X @ W1 + b1)       # (batch, n_hidden)
    logits = H @ W2 + b2        # (batch, n_classes)
    return softmax(logits)


rng = np.random.default_rng(0)
X  = rng.normal(size=(4, 3))
W1 = rng.normal(size=(3, 5)) * 0.5
b1 = np.zeros(5)
W2 = rng.normal(size=(5, 2)) * 0.5
b2 = np.zeros(2)

probs = forward(X, W1, b1, W2, b2)
print(probs.shape)          # (4, 2)
print(probs.sum(axis=1))    # [1. 1. 1. 1.]
assert np.allclose(probs.sum(axis=1), 1.0)
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why does softmax subtract the maximum, given that it does not '
              'change the result?',
          expectedAnswer:
              'Numerical stability. exp of a large logit overflows to infinity '
              'in floating point, producing NaN when divided. Subtracting the '
              'row maximum makes the largest exponent exp(0) = 1 and every '
              'other term smaller, so nothing overflows — and because softmax '
              'is invariant to adding a constant to all inputs, the '
              'probabilities are unchanged.',
        ),
        SelfCheckQuestion(
          question:
              'What breaks if you use axis=-1 without keepdims=True when '
              'summing?',
          expectedAnswer:
              'The sum collapses to shape (batch,) instead of (batch, 1), so '
              'NumPy broadcasts it against the last axis of the (batch, '
              'n_classes) array. When batch happens to equal n_classes it runs '
              'silently and divides by the wrong values; otherwise it raises a '
              'shape error. keepdims preserves the trailing axis so each row '
              'is divided by its own sum.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-nn-xor',
      title: 'Solve XOR by hand',
      prompt: [
        ProseBlock(
          'XOR cannot be separated by any single straight line, so a network '
          'with no hidden layer cannot represent it. Set the weights of a '
          'two-unit hidden layer by hand so that the network outputs a value '
          'above 0.5 for (0,1) and (1,0) and below 0.5 for (0,0) and (1,1).',
        ),
        ProseBlock(
          'Hint: make one hidden unit fire for OR and the other fire only for '
          'AND, then have the output layer subtract a large enough multiple of '
          'the AND unit to cancel the both-inputs-on case.',
        ),
      ],
      starterCode: '''
import numpy as np

X = np.array([[0, 0], [0, 1], [1, 0], [1, 1]], dtype=float)
y = np.array([0, 1, 1, 0], dtype=float)


def relu(z):
    return np.maximum(0.0, z)


W1 = np.zeros((2, 2))    # TODO: column 0 -> OR, column 1 -> AND
b1 = np.zeros(2)
W2 = np.zeros((2, 1))    # TODO
b2 = np.zeros(1)


def forward(X):
    H = relu(X @ W1 + b1)
    return (H @ W2 + b2).ravel()


print(forward(X))
''',
      solutionCode: '''
import numpy as np

X = np.array([[0, 0], [0, 1], [1, 0], [1, 1]], dtype=float)
y = np.array([0, 1, 1, 0], dtype=float)


def relu(z):
    return np.maximum(0.0, z)


# Hidden unit 0 fires when at least one input is 1  (x1 + x2 - 0.5 > 0)
# Hidden unit 1 fires only when both inputs are 1   (x1 + x2 - 1.5 > 0)
W1 = np.array([[1.0, 1.0],
               [1.0, 1.0]])
b1 = np.array([-0.5, -1.5])

# A first attempt: OR minus twice AND.
W2 = np.array([[1.0], [-2.0]])
b2 = np.array([0.0])


def forward(X):
    H = relu(X @ W1 + b1)
    return (H @ W2 + b2).ravel()


out = forward(X)
print(out)                       # [0.  0.5 0.5 0.5]
print((out > 0.25).astype(int))  # [0 1 1 1]  <- (1,1) still leaks through

# The AND unit is not subtracted hard enough. Sharpen it:
W2 = np.array([[2.0], [-6.0]])
b2 = np.array([-0.5])
out = forward(X)
print(out)                       # [-0.5  0.5  0.5 -0.5]
print((out > 0).astype(int))     # [0 1 1 0]  <- XOR
assert list((out > 0).astype(float)) == list(y)
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why can no network without a hidden layer represent XOR, no '
              'matter how it is trained?',
          expectedAnswer:
              'A single layer computes a weighted sum followed by a monotonic '
              'activation, so its decision boundary is a hyperplane — in two '
              'dimensions, a straight line. XOR\'s positive cases (0,1) and '
              '(1,0) sit diagonally opposite each other, with the negatives on '
              'the other diagonal, and no line separates one diagonal pair '
              'from the other. It is a limitation of the function class, not '
              'of the training procedure.',
        ),
        SelfCheckQuestion(
          question:
              'What does the hidden layer do to the input space that makes a '
              'line sufficient?',
          expectedAnswer:
              'It re-coordinates the points. In the new space the axes are '
              '"how much OR" and "how much AND", and in those coordinates the '
              'two positive cases land at the same point while the negatives '
              'land elsewhere — now linearly separable. That is the general '
              'principle: hidden layers learn a representation in which the '
              'final linear layer\'s job becomes easy.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-nn-shapes',
      title: 'Fix a broken network',
      prompt: [
        ProseBlock(
          'The model below is meant to take 16 features and classify into 3 '
          'classes, but it has three separate faults: a shape mismatch, a '
          'missing non-linearity that makes the depth pointless, and a softmax '
          'that will be applied twice once a cross-entropy loss is attached. '
          'Fix all three.',
        ),
      ],
      starterCode: '''
import torch
import torch.nn as nn

model = nn.Sequential(
    nn.Linear(16, 32),
    nn.Linear(32, 64),
    nn.Linear(60, 3),
    nn.Softmax(dim=1),
)

x = torch.randn(8, 16)
print(model(x).shape)     # expected torch.Size([8, 3])
''',
      solutionCode: '''
import torch
import torch.nn as nn

model = nn.Sequential(
    nn.Linear(16, 32),
    nn.ReLU(),           # fault 2: without this, three Linears collapse to one
    nn.Linear(32, 64),
    nn.ReLU(),
    nn.Linear(64, 3),    # fault 1: 60 -> 64, must match the previous output
)                        # fault 3: no Softmax; CrossEntropyLoss expects logits

x = torch.randn(8, 16)
logits = model(x)
print(logits.shape)      # torch.Size([8, 3])

loss_fn = nn.CrossEntropyLoss()          # applies log-softmax internally
targets = torch.tensor([0, 2, 1, 1, 0, 2, 1, 0])
print(loss_fn(logits, targets).item())   # a finite loss, correctly scaled

# For inference only, convert logits to probabilities explicitly:
print(torch.softmax(logits, dim=1).sum(dim=1))   # tensor([1., 1., ...])
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why does removing the ReLUs make the three Linear layers '
              'equivalent to one?',
          expectedAnswer:
              'Because the composition of linear maps is a linear map: '
              '(x @ W1 + b1) @ W2 + b2 equals x @ (W1 @ W2) + (b1 @ W2 + b2), '
              'which is a single layer with weights W1 @ W2. The extra '
              'parameters change the optimisation landscape but not the set of '
              'functions the model can represent, so depth without a '
              'non-linearity buys no expressiveness.',
        ),
        SelfCheckQuestion(
          question:
              'What actually goes wrong if you leave nn.Softmax before '
              'nn.CrossEntropyLoss?',
          expectedAnswer:
              'CrossEntropyLoss expects raw logits and applies log-softmax '
              'itself, so the softmax gets applied twice. The doubly-softmaxed '
              'distribution is far flatter, which shrinks the gradients and '
              'makes training slow and unstable, and you also lose the '
              'numerically stable fused implementation. Either output logits '
              'with CrossEntropyLoss, or output log-probabilities with '
              'NLLLoss.',
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
              'A neuron, honestly described: multiply each input by a weight, '
              'sum them, add a bias, push the result through a non-linear '
              'function. That is it. The weights encode a pattern, the bias '
              'sets how much evidence is needed, and the non-linearity is what '
              'stops the whole thing from collapsing.',
          startMs: 0,
          endMs: 46000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'That collapse point deserves emphasis. Stack a hundred layers '
              'of pure weighted sums and algebra flattens them into one '
              'weighted sum. Depth would be worthless. The activation '
              'function is not a detail on top of the architecture — it is '
              'the thing that makes architecture matter.',
          startMs: 46000,
          endMs: 94000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'A layer is just many neurons sharing an input, which makes it a '
              'matrix multiply plus a bias vector plus an element-wise '
              'activation. Batch your examples and it is a matrix times a '
              'matrix — exactly the operation a GPU does absurdly fast. That '
              'is the whole reason this field runs on graphics hardware.',
          startMs: 94000,
          endMs: 142000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Activations: ReLU for hidden layers, because its gradient is '
              'exactly one on the positive side so signal survives depth. '
              'Output layer is dictated by the task — nothing for regression, '
              'sigmoid for binary, softmax for multi-class. And softmax on a '
              'hidden layer is a bug, not a style choice.',
          startMs: 142000,
          endMs: 190000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Why depth helps: each layer re-coordinates what the last one '
              'produced, so features compose. XOR is the tiny classic — no '
              'line can separate it, but one hidden layer bends the space '
              'until a line can. That is all "learning features" means.',
          startMs: 190000,
          endMs: 228000,
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
              'Neural networks, built from the bottom. And I want to start by '
              'dropping the brain metaphor, because it does more harm than '
              'good. These are function approximators made of matrix '
              'multiplications and non-linear squashes. The biology inspired '
              'the name in the nineteen forties and has been essentially '
              'irrelevant since.',
          startMs: 0,
          endMs: 56000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The single unit is a dot product between the input and a weight '
              'vector, plus a bias, then an activation. The dot product is '
              'literally a similarity score: it is largest when the input '
              'points the same way as the weights. So each unit is a pattern '
              'detector, and the bias is its threshold for caring.',
          startMs: 56000,
          endMs: 122000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'A layer is many of those detectors on the same input, so the '
              'weight vector becomes a weight matrix. Get comfortable with the '
              'shapes: batch by in-features, times in-features by out-features, '
              'gives batch by out-features. The bias broadcasts across rows. '
              'Almost every early error is this chain being misaligned by one '
              'layer.',
          startMs: 122000,
          endMs: 188000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'On activations, the history is instructive. Sigmoid was '
              'standard for years, and it saturates — the curve goes flat, the '
              'gradient goes to nearly zero, and in a deep network those tiny '
              'factors multiply until the first layers receive nothing. That '
              'is the vanishing gradient problem, and it is a big part of why '
              'deep networks did not work for so long.',
          startMs: 188000,
          endMs: 258000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'ReLU fixed it almost embarrassingly simply. Max of zero and the '
              'input. Gradient exactly one when positive, so the signal passes '
              'through depth undiminished, and it costs one comparison to '
              'compute. The catch is dying units — pushed permanently '
              'negative, gradient zero forever — which leaky ReLU and GELU '
              'address with a small negative slope.',
          startMs: 258000,
          endMs: 326000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'The output activation is not a preference, it is determined by '
              'the task. Regression: nothing, you need the full real line. '
              'Binary: one unit with sigmoid. Multi-class: softmax over one '
              'unit per class. And in practice you usually emit raw logits and '
              'let the loss function apply the squash, because the fused '
              'version is numerically stable.',
          startMs: 326000,
          endMs: 394000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Why go deep at all? A single wide hidden layer is a universal '
              'approximator in theory. But the theorem says nothing about how '
              'wide, or whether gradient descent can find those weights. Depth '
              'lets features compose — edges to textures to parts to objects — '
              'and compositional functions need exponentially fewer units deep '
              'than wide.',
          startMs: 394000,
          endMs: 462000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'One last practical thing: initialisation. All zeros and every '
              'unit in a layer computes the same thing forever, so your '
              'five-hundred-unit layer has the power of one. And the scale '
              'matters too — He initialisation for ReLU, Xavier for tanh, both '
              'chosen to keep the variance of activations stable as depth '
              'increases. Frameworks default to sensible choices, which is '
              'why you rarely think about it until something will not train.',
          startMs: 462000,
          endMs: 516000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 870000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'The extended tour of neural network fundamentals. We will go '
              'through the unit, the geometry of what a layer does, the full '
              'activation zoo with the reasoning behind each, universal '
              'approximation and why it is less useful than it sounds, the '
              'depth-versus-width question, initialisation theory, and the '
              'representation-learning view that ties it together.',
          startMs: 0,
          endMs: 66000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Geometrically, one unit with a threshold defines a hyperplane. '
              'The weight vector is the normal — the direction perpendicular '
              'to the boundary — and the bias moves the plane away from the '
              'origin. So a single layer partitions space with flat cuts, and '
              'a network with ReLUs carves space into a very large number of '
              'polyhedral regions, being linear inside each one.',
          startMs: 66000,
          endMs: 152000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'That view explains a lot. A ReLU network is a piecewise-linear '
              'function, and the number of linear regions grows roughly '
              'exponentially with depth but only polynomially with width. That '
              'is one of the cleanest formal statements of why depth is more '
              'economical than width for the same parameter budget.',
          startMs: 152000,
          endMs: 230000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Now activations in detail. Sigmoid outputs zero to one and has '
              'maximum derivative one quarter, at zero. Chain ten sigmoid '
              'layers and even in the best case the gradient is scaled by a '
              'quarter to the tenth — about one in a million. Tanh is '
              'zero-centred with maximum derivative one, which is better, but '
              'it still saturates at both ends.',
          startMs: 230000,
          endMs: 310000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'ReLU has derivative one for positive input and zero otherwise, '
              'so it neither shrinks nor amplifies gradient on the active '
              'path. It is not differentiable at exactly zero, which nobody '
              'cares about — frameworks just define the subgradient as zero. '
              'The genuine cost is that a unit whose pre-activation is always '
              'negative receives zero gradient and is permanently dead.',
          startMs: 310000,
          endMs: 388000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Hence the variants. Leaky ReLU gives a small constant slope for '
              'negatives so a dead unit can revive. ELU and GELU are smooth, '
              'with GELU weighting the input by its probability under a normal '
              'distribution — that is the standard in transformers, and the '
              'smoothness seems to help optimisation in very deep stacks. '
              'Swish is similar in spirit and was found by architecture '
              'search.',
          startMs: 388000,
          endMs: 468000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Softmax deserves care because it is not element-wise. It '
              'exponentiates every score and divides by the total, so every '
              'output depends on every input and they sum to one. Two '
              'consequences: it is only meaningful when the outputs really are '
              'mutually exclusive alternatives, and you must subtract the '
              'maximum before exponentiating or large logits overflow to '
              'infinity.',
          startMs: 468000,
          endMs: 548000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'On universal approximation: Cybenko and Hornik showed in the '
              'late eighties that one hidden layer with a squashing '
              'non-linearity can approximate any continuous function on a '
              'compact domain arbitrarily well. It is an existence result. It '
              'gives no bound on the number of units, no construction, and no '
              'promise that gradient descent finds the weights. Treat it as '
              'reassurance, not as guidance.',
          startMs: 548000,
          endMs: 628000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Initialisation is where theory earns its keep. Zeros give '
              'perfect symmetry: identical outputs, identical gradients, '
              'identical updates, forever. Random breaks it, but the variance '
              'must be tuned. Glorot derived one over the average of fan-in '
              'and fan-out to keep activation variance constant for symmetric '
              'activations; He doubled it for ReLU, because ReLU zeroes half '
              'the distribution and so halves the variance.',
          startMs: 628000,
          endMs: 712000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'And this is not academic. Get the scale wrong by a factor of '
              'two per layer and after thirty layers you are off by a billion '
              'in one direction or the other — activations saturating, or a '
              'signal indistinguishable from zero. Modern normalisation layers '
              'make networks more forgiving about this, but they do not make '
              'initialisation irrelevant.',
          startMs: 712000,
          endMs: 782000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'The unifying idea is representation learning. Everything except '
              'the final layer exists to change coordinates so that the final '
              'layer\'s linear separation becomes easy. That is why the '
              'penultimate layer\'s activations are so useful as embeddings, '
              'why transfer learning works, and why you can freeze a '
              'pre-trained backbone and retrain only the head on a few hundred '
              'examples.',
          startMs: 782000,
          endMs: 850000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Summary: a unit is a dot product plus a bias plus a '
              'non-linearity; a layer is a matrix multiply; depth composes '
              'representations; the activation is what makes depth mean '
              'anything; and initialisation decides whether any of it trains '
              'at all.',
          startMs: 850000,
          endMs: 870000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Dot product, bias, non-linearity',
      body:
          'A neuron scores how well the input matches the pattern its weights '
          'encode, shifts that score by a bias, and passes it through an '
          'activation. A layer does this for many units at once, which makes '
          'it a matrix multiplication — the operation GPUs accelerate.',
    ),
    SummaryCard(
      title: 'Without non-linearity, depth is free of meaning',
      body:
          'Composing linear maps yields a linear map, so stacked Linear layers '
          'with no activation collapse into one. ReLU is the hidden-layer '
          'default because its gradient is exactly one on the positive side; '
          'the output activation is fixed by the task (none, sigmoid or '
          'softmax).',
    ),
    SummaryCard(
      title: 'Hidden layers are learned coordinates',
      body:
          'Each layer re-represents the previous one\'s output so that the '
          'final linear layer can separate the classes. XOR is the minimal '
          'demonstration: unsolvable by a line in the input space, trivial '
          'after one hidden layer. Random, well-scaled initialisation (He for '
          'ReLU, Xavier for tanh) is what makes any of it trainable.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Pre-activation (logit)',
      definition:
          'The raw weighted sum plus bias, before the activation function is '
          'applied. Classification models usually output logits and let the '
          'loss apply softmax or sigmoid internally for numerical stability.',
    ),
    KeyConcept(
      term: 'ReLU',
      definition:
          'max(0, z). The default hidden-layer activation: cheap, sparse, and '
          'with gradient exactly 1 for positive inputs so signal survives '
          'depth. Its failure mode is a unit stuck at zero output with zero '
          'gradient — a dying ReLU.',
    ),
    KeyConcept(
      term: 'Softmax',
      definition:
          'Exponentiates a vector of scores and normalises them to sum to one, '
          'producing a distribution over mutually exclusive classes. Not '
          'element-wise, so it belongs on the output layer, not hidden layers.',
    ),
    KeyConcept(
      term: 'Vanishing gradient',
      definition:
          'The shrinking of gradient signal as it is multiplied through many '
          'saturating layers, leaving early layers effectively untrained. The '
          'main historical obstacle to depth, mitigated by ReLU, careful '
          'initialisation, normalisation and residual connections.',
    ),
    KeyConcept(
      term: 'Universal approximation',
      definition:
          'The theorem that one sufficiently wide hidden layer can approximate '
          'any continuous function on a bounded domain. An existence result '
          'only: it bounds neither the width required nor whether training can '
          'find the weights.',
    ),
    KeyConcept(
      term: 'He / Xavier initialisation',
      definition:
          'Schemes that set the initial weight variance from the layer widths '
          'so activation variance stays roughly constant with depth. He (2 / '
          'fan_in) matches ReLU; Xavier (2 / (fan_in + fan_out)) matches tanh '
          'and sigmoid.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Stacking nn.Linear layers with no activation between them.',
      correction:
          'The composition is mathematically a single linear layer, so the '
          'extra depth adds parameters and compute but no expressive power. '
          'Insert a non-linearity — normally ReLU — after every hidden Linear.',
    ),
    Mistake(
      mistake:
          'Applying softmax in the model and then using CrossEntropyLoss.',
      correction:
          'CrossEntropyLoss applies log-softmax itself, so the squash happens '
          'twice: gradients shrink and training stalls. Output raw logits with '
          'CrossEntropyLoss, or output log-probabilities and use NLLLoss.',
    ),
    Mistake(
      mistake:
          'Initialising all weights to zero "for reproducibility".',
      correction:
          'Every unit in a layer would then compute the same output and '
          'receive the same gradient, so they stay identical forever and the '
          'layer has the capacity of a single unit. Use random initialisation '
          'with a fixed seed instead.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Why do neural networks need non-linear activation functions?',
      answer:
          'Because a composition of linear functions is itself linear. If '
          'every layer were just a weighted sum, a network of any depth would '
          'be algebraically equivalent to a single matrix multiplication, so '
          'it could only represent linear decision boundaries and depth would '
          'add nothing. A non-linearity between layers makes the composition '
          'strictly more expressive than any single layer, allowing the '
          'network to approximate curved decision boundaries and to build '
          'hierarchical features — each layer transforming the previous '
          'representation rather than merely rescaling it.',
    ),
    InterviewQuestion(
      question:
          'What is the vanishing gradient problem and how do modern networks '
          'avoid it?',
      answer:
          'Backpropagation multiplies derivatives layer by layer, so if each '
          'factor is well below one the gradient reaching early layers shrinks '
          'exponentially with depth and those layers stop learning. Sigmoid is '
          'the classic culprit: its derivative peaks at 0.25 and approaches '
          'zero when saturated. Mitigations are ReLU-family activations whose '
          'positive-side derivative is exactly one; variance-preserving '
          'initialisation such as He; normalisation layers like batch or layer '
          'norm that keep pre-activations in a healthy range; and residual '
          'connections, which give gradients an additive identity path that '
          'skips the multiplication entirely — the reason networks of hundreds '
          'of layers became trainable.',
    ),
    InterviewQuestion(
      question:
          'If one hidden layer is a universal approximator, why build deep '
          'networks?',
      answer:
          'The theorem is an existence result with no bound on width, no '
          'construction, and no guarantee that gradient descent will find the '
          'weights — the required width can grow exponentially with the '
          'complexity of the target function. Depth is a more parameter-'
          'efficient way to buy expressiveness for the compositional functions '
          'real data tends to exhibit: for ReLU networks the number of linear '
          'regions grows exponentially with depth but only polynomially with '
          'width. Depth also gives the hierarchical feature structure that '
          'makes transfer learning work, since intermediate layers learn '
          'reusable representations.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'Neural networks — Google ML Crash Course',
    url:
        'https://developers.google.com/machine-learning/crash-course/introduction-to-neural-networks/video-lecture',
    description:
        'Introductory treatment of hidden layers, activation functions and '
        'why non-linearity is required, with interactive examples.',
  ),
  Source(
    title: 'Deep Learning (Goodfellow et al.)',
    url: 'https://www.deeplearningbook.org/',
    description:
        'Chapter 6, "Deep Feedforward Networks", covers units, activations, '
        'architecture design and the universal approximation results in '
        'depth.',
  ),
];
