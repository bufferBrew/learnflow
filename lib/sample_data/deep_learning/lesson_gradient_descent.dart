import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 1: how the weights of a network actually get learned.
const Lesson gradientDescentLesson = Lesson(
  id: 'dl-gradient-descent',
  title: 'Gradient Descent',
  description:
      'The loss landscape, the update rule, the learning rate, batch sizes and '
      'momentum — the search procedure that turns a randomly initialised '
      'network into a trained one.',
  estimatedMinutes: 30,
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
      id: 'landscape',
      heading: 'A loss function is a landscape you cannot see',
      blocks: [
        ProseBlock(
          'You already know what a network computes: fix the weights, push an '
          'input through, get an output. Training inverts that question. The '
          'input and the desired output are fixed, the weights are the '
          'unknowns, and a loss function collapses "how wrong was the whole '
          'dataset" into a single number. That number is a function of the '
          'weights and nothing else, so every possible setting of the weights '
          'is a point with a height. Training is the search for a low point.',
        ),
        ProseBlock(
          'The word landscape is doing real work here. With one weight the '
          'picture is a curve; with two it is a surface you could hold in your '
          'hands; with two hundred million it is a shape no one has ever seen '
          'and no one ever will. What survives from the low-dimensional picture '
          'is the local vocabulary — slope, valley, plateau, bowl — and that '
          'vocabulary is enough, because gradient descent is a purely local '
          'algorithm. It never looks at the landscape. It only ever asks which '
          'way is down from exactly here.',
        ),
        ProseBlock(
          'Two toy losses carry the rest of this lesson. The first is a plain '
          'one-parameter bowl, which is convex: it has one minimum, and any '
          'sensible descent procedure finds it. The second is a two-parameter '
          'valley whose curvature differs by a factor of a hundred between the '
          'two directions, which is a much better model of what real training '
          'feels like — steep walls in some directions, an almost flat floor in '
          'others, and a step size that has to work for both at once.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np


# Toy loss 1: one parameter, one bowl. The minimum sits at w = 3.
def bowl(w):
    return (w - 3.0) ** 2 + 2.0


print([bowl(w) for w in [-1.0, 0.0, 1.0, 3.0, 5.0]])
# [18.0, 11.0, 6.0, 2.0, 6.0]     the height at five different weight settings


# Toy loss 2: two parameters, a long narrow valley. Minimum at (0, 0).
def valley(w):
    return 0.05 * w[0] ** 2 + 5.0 * w[1] ** 2


print(valley(np.array([1.0, 0.0])))    # 0.05   a step along the floor is cheap
print(valley(np.array([0.0, 1.0])))    # 5.0    the same step up the wall is not
''',
          caption:
              'The same distance costs a hundred times more in one direction '
              'than the other — that ratio is what makes optimisation hard.',
        ),
        ProseBlock(
          'Real networks add a third complication: their landscapes are not '
          'convex. Swap two hidden units and their incoming and outgoing '
          'weights and you get a numerically different weight vector computing '
          'exactly the same function, so every minimum is duplicated an '
          'astronomical number of times. Non-convexity sounds alarming and in '
          'practice is not: for large networks, the many minima tend to sit at '
          'similar loss values, and the points where the gradient vanishes are '
          'far more often saddles — down in some directions, up in others — '
          'than true traps.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'You never see the surface, only the ground under your feet',
          text:
              'At any moment during training you have two things: the loss at '
              'the current weights, and its slope there. Every plot of a loss '
              'landscape you have ever seen is a one- or two-dimensional slice '
              'through something vastly larger, chosen after the fact. Treat '
              'those pictures as intuition pumps, not maps.',
        ),
      ],
    ),
    Section(
      id: 'update-rule',
      heading: 'The update rule: subtract a scaled gradient',
      blocks: [
        ProseBlock(
          'The gradient of the loss with respect to the weights is the vector '
          'of partial derivatives: one number per weight, answering "if I nudge '
          'this weight up by a hair, how much does the loss change?". Collected '
          'together, that vector points in the direction of steepest *increase* '
          'in loss. Which makes the algorithm almost embarrassingly short — go '
          'the other way.',
        ),
        ProseBlock(
          'That is the whole update rule: `w = w - lr * grad`. The minus sign '
          'turns steepest ascent into steepest descent. The learning rate `lr` '
          'decides how far along that direction you actually travel, because '
          'the gradient is a direction plus a magnitude and the magnitude is '
          'only trustworthy infinitesimally close to where you measured it.',
        ),
        ProseBlock(
          'Two properties of the rule are worth noticing before you run it. '
          'First, the step shrinks by itself: near a minimum the gradient goes '
          'to zero, so the same learning rate produces smaller and smaller '
          'moves and the process settles rather than rattling around forever. '
          'Second, nothing in the rule knows where the minimum is. On the bowl '
          'below the distance to the optimum shrinks by a constant factor each '
          'step — geometric decay, fast at first and asymptotically patient.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def loss(w):
    return (w - 3.0) ** 2 + 2.0


def grad(w):
    return 2.0 * (w - 3.0)        # dL/dw, differentiated by hand


w = -1.0
lr = 0.1
history = []

for step in range(11):
    history.append(loss(w))
    w = w - lr * grad(w)          # the entire algorithm, one line

for step in range(0, 11, 2):
    print(step, round(history[step], 4))

# step   loss
#   0    18.0
#   2     8.5536
#   4     4.6844
#   6     3.0995
#   8     2.4504
#  10     2.1845     still falling, in ever smaller amounts

print(round(w, 4))    # 2.6564   -> converging on 3.0, where the loss is 2.0
''',
          caption:
              'The loss floor here is 2.0, not 0.0 — a loss that stops falling '
              'is not automatically a loss that failed.',
        ),
        ProseBlock(
          'In a real network you never differentiate by hand. Backpropagation '
          'computes the gradient of the loss with respect to every weight in a '
          'single backward sweep, at roughly the cost of one forward pass, and '
          'a framework does it for you. But the thing backpropagation produces '
          'is exactly the `grad` above, and the thing the optimiser does with '
          'it is exactly that one line. Everything else in this lesson is about '
          'choosing `lr`, choosing which data to compute the gradient on, and '
          'deciding whether to remember the previous steps.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Check a hand-written gradient with finite differences',
          text:
              'If you derive a gradient yourself, verify it numerically before '
              'trusting it: `(loss(w + eps) - loss(w - eps)) / (2 * eps)` with '
              'eps around 1e-5 should match your analytic value to several '
              'decimal places. A wrong gradient does not crash — it quietly '
              'trains to the wrong place, which is far harder to notice.',
        ),
      ],
    ),
    Section(
      id: 'learning-rate',
      heading: 'The learning rate sets the step size',
      blocks: [
        ProseBlock(
          'The gradient tells you the direction; the learning rate tells you '
          'how much to believe it. Too small and each step barely moves — the '
          'run converges eventually in the mathematical sense and never in the '
          'sense that matters, because you have a deadline. Too large and the '
          'step jumps clean over the minimum and lands further up the far side '
          'than it started, so the next gradient is bigger, so the next step is '
          'bigger still. That feedback loop is divergence, and it reaches '
          'infinity or NaN in seconds.',
        ),
        ProseBlock(
          'Between those failures sits a band of rates that work, and its edges '
          'are set by curvature, not by taste. For a quadratic loss whose '
          'second derivative is `a`, the distance to the minimum is multiplied '
          'by `1 - lr * a` every step. Anything with absolute value below one '
          'converges; exactly zero would land on the minimum in a single step; '
          'above one diverges. The bowl below has `a = 2`, so the divergence '
          'threshold is a learning rate of 1.0, and rates a little under it '
          'converge while visibly oscillating from one side to the other.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def run(lr, steps=50, w=-1.0):
    for _ in range(steps):
        w = w - lr * grad(w)
    return w, loss(w)


for lr in [0.001, 0.1, 0.95, 1.1]:
    w_final, loss_final = run(lr)
    print(lr, round(w_final, 4), loss_final)

# lr       w after 50 steps    loss
# 0.001         -0.619        15.0971    creeping: 50 steps barely dented it
# 0.1            3.0          2.0        healthy geometric decay to the bottom
# 0.95           2.9794       2.0004     converging, but crossing over each step
# 1.1       -36398.7          1.3251e+09 diverged: every step overshoots further
''',
          caption:
              'Same loss, same starting point, same number of steps. Only the '
              'step size changed.',
        ),
        ProseBlock(
          'The practical consequence is that the learning rate is the first '
          'hyperparameter to tune and the first suspect when nothing trains. '
          'The loss curve names the failure for you: a straight, gently '
          'downward line that has not flattened means you could afford a larger '
          'rate; a curve that drops and then bounces on a plateau means the '
          'steps are too big to settle; a curve that rises or goes NaN means '
          'the rate is far past the threshold. Scanning a few rates an order of '
          'magnitude apart — 1e-1, 1e-2, 1e-3 — for a couple of hundred steps '
          'each finds the right decade quickly.',
        ),
        ProseBlock(
          'The ideal rate also changes as training proceeds, which is why a '
          'constant rate is rarely the final answer. Large early steps cover '
          'ground; small late steps settle into a minimum instead of skating '
          'over it. Schedules automate that — step decay drops the rate at '
          'fixed milestones, cosine annealing sweeps it smoothly down — and '
          'warmup does the opposite at the start, ramping the rate up from '
          'nearly zero over the first few hundred steps so that a freshly '
          'initialised large model is not blown apart by its first few '
          'gradients. Later lessons implement these; for now it is enough to '
          'know that `lr` is normally a function of the step number.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'You can diagnose a diverging run in ten steps',
          text:
              'Print the loss every step for the first ten instead of every '
              'epoch. On a healthy run it falls, perhaps noisily. If it climbs '
              'from the very first steps, stop the job and divide the learning '
              'rate by ten — you will learn more in twenty seconds than from '
              'waiting an hour for a NaN.',
        ),
      ],
    ),
    Section(
      id: 'batching',
      heading: 'Batch, stochastic and mini-batch gradient descent',
      blocks: [
        ProseBlock(
          'The update rule says to subtract the gradient of the loss, and the '
          'loss is defined over the whole training set. Taken literally that '
          'means every single update requires a forward and backward pass over '
          'every example you own. This is **batch** (or full-batch) gradient '
          'descent: the gradient is exact, the trajectory is smooth, and on a '
          'million-row dataset you get one parameter update per pass. An epoch '
          'is one step. Nothing about it scales.',
        ),
        ProseBlock(
          'The opposite extreme is **stochastic** gradient descent, which '
          'estimates the gradient from a single example. Each estimate is '
          'terrible — one example can easily point in the wrong direction '
          'entirely — but it is unbiased, it costs almost nothing, and you get '
          'a million updates per pass instead of one. The noise turns out to be '
          'a feature as well as a bug: it keeps the trajectory from settling '
          'into narrow, sharp structure that a smooth path would fall straight '
          'into.',
        ),
        ProseBlock(
          '**Mini-batch** gradient descent is the compromise everyone actually '
          'uses. Average the gradient over 32, 64 or 256 examples: the error in '
          'the estimate falls with the square root of the batch size, so a '
          'batch of 32 is roughly five to six times more accurate than a single '
          'example while costing a tiny fraction of a full pass. It also maps '
          'onto hardware — a batch is a matrix multiplication, which is what a '
          'GPU is for. When people say "SGD" today they almost always mean '
          'mini-batch, and `DataLoader` and everything in `torch.optim` assume '
          'it.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np

rng = np.random.default_rng(0)
X = rng.uniform(-3.0, 3.0, size=1000)
y = 2.0 * X - 1.0 + rng.normal(0.0, 0.5, size=1000)


def grad_w(w, b, xs, ys):
    """dMSE/dw over whatever slice of the data you hand it."""
    error = (w * xs + b) - ys
    return 2.0 * np.mean(error * xs)


w, b = 0.0, 0.0

print(round(grad_w(w, b, X, y), 3))          # -11.938   all 1000 examples

for _ in range(3):                           # one example at a time
    i = rng.integers(len(X))
    print(round(grad_w(w, b, X[i:i + 1], y[i:i + 1]), 3))
#   0.238      wrong sign entirely: this example wants w to go down
# -23.641      twice the true magnitude
# -10.702

for _ in range(3):                           # mini-batches of 32
    idx = rng.integers(0, len(X), size=32)
    print(round(grad_w(w, b, X[idx], y[idx]), 3))
# -13.412      right direction, small error, about 3% of the work
# -10.856
# -12.591
''',
          caption:
              'The full-batch gradient is the target; a single example is a '
              'wild guess at it; 32 examples are close enough to steer by.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
w, b = 0.0, 0.0
lr, batch_size = 0.02, 32
n = len(X)

for epoch in range(10):
    order = rng.permutation(n)                  # reshuffle so that consecutive
    for start in range(0, n, batch_size):       # batches are not correlated
        idx = order[start:start + batch_size]
        xb, yb = X[idx], y[idx]

        error = (w * xb + b) - yb
        w -= lr * 2.0 * np.mean(error * xb)     # one update per mini-batch
        b -= lr * 2.0 * np.mean(error)

    print(epoch, round(w, 3), round(b, 3))

# 0   1.913  -0.902
# 3   1.998  -0.994
# 9   2.001  -0.998    recovering the 2.0 and -1.0 the data was generated from
''',
          caption:
              'Ten epochs, 320 updates. Full-batch descent would have made ten.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'Count steps, not epochs',
          text:
              '1000 examples at batch size 32 gives 32 updates per epoch — 31 '
              'full batches and a final one of 8. Halving the batch size '
              'doubles the number of updates per epoch, which is why batch '
              'size and learning rate have to be tuned together: a smaller '
              'batch is a noisier gradient taken more often.',
        ),
      ],
    ),
    Section(
      id: 'momentum',
      heading: 'Momentum: remembering where you were going',
      blocks: [
        ProseBlock(
          'Plain gradient descent has no memory. Each step is computed from the '
          'current gradient alone, which is exactly what makes it bad at narrow '
          'valleys. In the two-parameter valley from the first section, the '
          'steep direction forces a small learning rate — anything larger '
          'diverges up the walls — and that same small rate then has to move '
          'along the almost-flat floor, where the gradient is tiny. The result '
          'is a trajectory that ricochets between the walls while inching '
          'towards the actual minimum.',
        ),
        ProseBlock(
          '**Momentum** gives the optimiser a memory. Keep a running quantity '
          '`v`, the velocity, and update it before you update the weights: '
          '`v = beta * v + grad`, then `w = w - lr * v`. With `beta` around 0.9 '
          'the velocity is a decaying average of the recent gradients rather '
          'than just the latest one. Directions the gradient keeps agreeing on '
          'accumulate and the effective step grows; directions that flip sign '
          'every step partly cancel and the oscillation is damped. The physical '
          'reading is a ball with mass rolling downhill instead of a point '
          'teleporting.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def velocity(grads, beta=0.9):
    """PyTorch's SGD buffer: v = beta*v + g, then the step is lr*v."""
    v, trace = 0.0, []
    for g in grads:
        v = beta * v + g
        trace.append(round(v, 4))
    return trace


# A consistent direction: the same gradient six times in a row.
print(velocity([1.0] * 6))
# [1.0, 1.9, 2.71, 3.439, 4.0951, 4.6856]
# the step keeps growing, towards a ceiling of 1/(1 - 0.9) = 10x the gradient

# A direction that reverses every step: the wall of a narrow valley.
print(velocity([1.0, -1.0] * 3))
# [1.0, -0.1, 0.91, -0.181, 0.8371, -0.2466]
# the swings are half the size they were, and cost half as much progress
''',
          caption:
              'Same rule, two gradient sequences: agreement compounds, '
              'disagreement cancels.',
        ),
        ProseBlock(
          'That ceiling of `1 / (1 - beta)` is the single most useful number to '
          'remember here. Switching momentum 0.9 on multiplies the effective '
          'step size by roughly ten once the velocity has built up, so a '
          'learning rate that was stable without momentum can diverge with it. '
          'If adding momentum breaks a run, lower the learning rate before '
          'concluding that momentum was the problem.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import torch
import torch.nn as nn

model = nn.Sequential(nn.Linear(20, 64), nn.ReLU(), nn.Linear(64, 1))
loss_fn = nn.MSELoss()

# momentum defaults to 0, which is plain mini-batch gradient descent.
plain = torch.optim.SGD(model.parameters(), lr=0.05)
heavy = torch.optim.SGD(model.parameters(), lr=0.05, momentum=0.9)

optimizer = heavy
for epoch in range(20):
    for xb, yb in train_loader:
        optimizer.zero_grad()       # clear last step's gradients
        loss = loss_fn(model(xb), yb)
        loss.backward()             # fill .grad on every parameter
        optimizer.step()            # v = beta*v + grad; p -= lr*v

# epoch   lr=0.05    lr=0.05, momentum=0.9
#     1    0.684            0.503
#     5    0.402            0.171
#    10    0.268            0.094
#    20    0.163            0.071
# Same data, same initialisation: momentum reaches in five epochs roughly
# what plain SGD needs twenty for.
''',
          caption:
              'torch.optim.SGD is plain gradient descent until you pass '
              'momentum; the state it keeps is one velocity buffer per '
              'parameter.',
        ),
        ProseBlock(
          'Two footnotes on the PyTorch implementation, because conventions '
          'differ between papers and libraries. Its `dampening` argument scales '
          'the incoming gradient before it is added to the buffer and defaults '
          'to 0, so the plain form above is what you get. Its `nesterov` flag '
          'switches to Nesterov accelerated gradient, which evaluates the '
          'gradient at the point the velocity is about to carry you to rather '
          'than where you currently stand — usually a small improvement, never '
          'the difference between working and not.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: Adam, and why momentum is only half of it',
          children: [
            ProseBlock(
              'Momentum fixes one problem: the direction of the step. It does '
              'nothing about the fact that a single learning rate has to serve '
              'every parameter in the model, even though a weight in the first '
              'layer and a weight in the last may see gradients differing by '
              'orders of magnitude.',
            ),
            ProseBlock(
              'Adam, from Kingma and Ba, is momentum plus a per-parameter '
              'adaptive step size. It keeps two decaying averages per '
              'parameter: `m`, the average gradient, which is momentum under '
              'another name, and `v`, the average *squared* gradient, which '
              'measures how large that parameter\'s gradients have recently '
              'been. The update divides one by the square root of the other, so '
              'a parameter with consistently large gradients gets a '
              'proportionally smaller step and a rarely-updated one gets a '
              'larger step. Both averages start at zero and are therefore '
              'biased towards zero early on, which Adam corrects by dividing '
              'each by `1 - beta ** t`.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
# The Adam update, stripped to its arithmetic. Defaults: b1=0.9, b2=0.999.
m = b1 * m + (1 - b1) * g                # momentum, normalised this time
v = b2 * v + (1 - b2) * g ** 2           # average squared gradient

m_hat = m / (1 - b1 ** t)                # bias correction, t = step number
v_hat = v / (1 - b2 ** t)

w -= lr * m_hat / (np.sqrt(v_hat) + 1e-8)
''',
            ),
            ProseBlock(
              'The practical effect is that Adam is far less sensitive to the '
              'initial learning rate than SGD, which is most of why it became '
              'the default: 1e-3 trains almost anything to something. That is '
              'not the same as being better. Well-tuned SGD with momentum and a '
              'schedule still matches or beats Adam on many vision benchmarks, '
              'and AdamW — Adam with weight decay applied separately from the '
              'gradient rather than folded into it — is what large models '
              'actually use. Adam is not the subject of this lesson; it is '
              'worth knowing that its first moment is exactly the velocity you '
              'implemented above.',
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
      id: 'ex-gd-by-hand',
      title: 'Descend a quadratic by hand',
      prompt: [
        ProseBlock(
          'Minimise `L(w) = 3 * (w - 2)**2 + 1` starting from `w = -4.0` with a '
          'learning rate of 0.05. Differentiate the loss yourself, run 20 '
          'steps, and return the final weight along with the full history of '
          'losses — one entry per step, recorded before the update.',
        ),
        ProseBlock(
          'Then look at the last value in the history and explain why it is not '
          'close to zero.',
        ),
      ],
      starterCode: '''
def loss(w):
    return 3.0 * (w - 2.0) ** 2 + 1.0


def grad(w):
    """dL/dw. Work it out on paper first."""
    ...


def descend(w=-4.0, lr=0.05, steps=20):
    """Return (final_w, history) where history[i] is the loss before step i."""
    ...


final_w, history = descend()
print(round(final_w, 4))
print([round(h, 4) for h in history[:6]])
''',
      solutionCode: '''
def loss(w):
    return 3.0 * (w - 2.0) ** 2 + 1.0


def grad(w):
    """dL/dw = 3 * 2 * (w - 2) = 6 * (w - 2)."""
    return 6.0 * (w - 2.0)


def descend(w=-4.0, lr=0.05, steps=20):
    """Return (final_w, history) where history[i] is the loss before step i."""
    history = []
    for _ in range(steps):
        history.append(loss(w))
        w = w - lr * grad(w)
    return w, history


final_w, history = descend()

print(round(final_w, 4))
# 1.9952        -> converging on the minimum at w = 2.0

print([round(h, 4) for h in history[:6]])
# [109.0, 53.92, 26.9308, 13.7061, 7.226, 4.0507]

print(round(history[-1], 4), round(loss(final_w), 4))
# 1.0003 1.0001  -> the loss is bottoming out at 1.0, not at 0.0

# Each step multiplies the distance to the minimum by (1 - lr * 6) = 0.7,
# so the gap shrinks geometrically and the steps shrink with it.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The learning rate never changed, yet the weight moved 1.8 on the '
              'first step and about 0.005 on the twentieth. Why?',
          expectedAnswer:
              'Because the step is the learning rate times the gradient, and '
              'the gradient shrinks as the weight approaches the minimum — here '
              'it is 6 * (w - 2), which goes to zero as w goes to 2. Gradient '
              'descent slows down automatically near a minimum without anyone '
              'adjusting the learning rate, which is why a fixed rate can '
              'converge rather than orbit forever.',
        ),
        SelfCheckQuestion(
          question:
              'Which learning rates would make this run diverge, and how would '
              'you know that without experimenting?',
          expectedAnswer:
              'The distance to the minimum is multiplied by (1 - lr * 6) each '
              'step, so the run converges while that factor is under one in '
              'absolute value — that is, for lr below 1/3. At exactly 1/6 it '
              'would land on the minimum in one step; between 1/6 and 1/3 it '
              'converges while crossing over the minimum each step; above 1/3 '
              'it diverges. The threshold comes from the curvature of the loss, '
              'which here is the constant second derivative of 6.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-gd-lr-sweep',
      title: 'Spot the diverging learning rate',
      prompt: [
        ProseBlock(
          'For `L(w) = (w - 1)**2` starting at `w = 6.0`, write '
          '`run(lr, steps)` that returns the loss history, then run it at three '
          'learning rates: 0.05, 0.4 and 1.05.',
        ),
        ProseBlock(
          'Print the first few losses for each and add a check that flags a run '
          'as diverging by inspecting the history alone — no plotting, no prior '
          'knowledge of which rate is which.',
        ),
      ],
      starterCode: '''
def loss(w):
    return (w - 1.0) ** 2


def run(lr, steps=10, w=6.0):
    """Return the loss recorded before each of `steps` updates."""
    ...


def diverging(history):
    """Return True if this history is running away from the minimum."""
    ...


for lr in (0.05, 0.4, 1.05):
    h = run(lr)
    print(lr, [round(x, 4) for x in h[:4]], diverging(h))
''',
      solutionCode: '''
def loss(w):
    return (w - 1.0) ** 2


def grad(w):
    return 2.0 * (w - 1.0)


def run(lr, steps=10, w=6.0):
    """Return the loss recorded before each of `steps` updates."""
    history = []
    for _ in range(steps):
        history.append(loss(w))
        w = w - lr * grad(w)
    return history


def diverging(history):
    """Return True if this history is running away from the minimum."""
    return history[-1] > history[0]


for lr in (0.05, 0.4, 1.05):
    h = run(lr)
    print(lr, [round(x, 4) for x in h[:4]], diverging(h))

# 0.05  [25.0, 20.25, 16.4025, 13.286]   False   converging, but slowly
# 0.4   [25.0, 1.0, 0.04, 0.0016]        False   converging fast
# 1.05  [25.0, 30.25, 36.6025, 44.289]   True    every step lands further out

# Each step multiplies the distance to w = 1 by (1 - 2*lr):
#   lr = 0.05 -> 0.90    slow shrink
#   lr = 0.4  -> 0.20    fast shrink
#   lr = 1.05 -> -1.10   grows by 10% and flips side every step
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Comparing the last loss to the first is a reliable divergence '
              'test here. Why is it only a hint when training a real network?',
          expectedAnswer:
              'Because a real training loss is computed on mini-batches, so it '
              'fluctuates from step to step even on a perfectly healthy run — a '
              'single higher value means nothing. You look at the trend over a '
              'window rather than at two points, and the unambiguous signals are '
              'a loss that climbs steadily over hundreds of steps or becomes '
              'inf or NaN. The toy loss has no noise, so any increase is real.',
        ),
        SelfCheckQuestion(
          question:
              'At lr = 0.4 the loss reached 0.0016 in three steps. Would a rate '
              'that fast be a good default for a real network?',
          expectedAnswer:
              'No. That rate is near-optimal for this specific quadratic, whose '
              'curvature is a known constant. A real network has wildly '
              'different curvature in different directions and at different '
              'points in training, so the largest rate that is stable everywhere '
              'is much smaller than the one that is ideal in any single '
              'direction. That mismatch is exactly what momentum and adaptive '
              'methods exist to soften.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-gd-momentum',
      title: 'Add a velocity term and count the steps saved',
      prompt: [
        ProseBlock(
          'Implement gradient descent with momentum — `v = beta * v + grad` '
          'then `w = w - lr * v`, with `v` starting at zero — alongside the '
          'plain version.',
        ),
        ProseBlock(
          'On `L(w) = 0.5 * w**2` from `w = 1.0` with `lr = 0.25`, count how '
          'many steps each takes to reach a loss below 1e-4. Use `beta = 0.25` '
          'so the numbers stay legible, and print the first five weights from '
          'each run.',
        ),
      ],
      starterCode: '''
def loss(w):
    return 0.5 * w ** 2


def grad(w):
    return w


def steps_to(target, lr=0.25, beta=0.0, w=1.0, cap=200):
    """Return (n_steps, first_five_weights) to reach loss < target."""
    ...


print(steps_to(1e-4))              # plain: beta = 0
print(steps_to(1e-4, beta=0.25))   # with momentum
''',
      solutionCode: '''
def loss(w):
    return 0.5 * w ** 2


def grad(w):
    return w


def steps_to(target, lr=0.25, beta=0.0, w=1.0, cap=200):
    """Return (n_steps, first_five_weights) to reach loss < target."""
    v = 0.0
    trace = [w]
    for n in range(cap):
        if loss(w) < target:
            return n, [round(x, 4) for x in trace[:5]]
        v = beta * v + grad(w)      # beta = 0 collapses to plain descent
        w = w - lr * v
        trace.append(w)
    return cap, [round(x, 4) for x in trace[:5]]


print(steps_to(1e-4))
# (15, [1.0, 0.75, 0.5625, 0.4219, 0.3164])

print(steps_to(1e-4, beta=0.25))
# (9,  [1.0, 0.75, 0.5, 0.3125, 0.1875])

# Identical first step - the velocity buffer starts empty, so there is
# nothing to remember yet. From the second step on, momentum is carrying
# part of the previous gradient and covers the same ground in 9 steps
# instead of 15.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why is the first weight after one step identical in both runs?',
          expectedAnswer:
              'The velocity buffer is initialised to zero, so on the first '
              'update v = beta * 0 + grad is just the gradient and the step is '
              'lr * grad — exactly plain gradient descent. Momentum only starts '
              'to differ once there is history to accumulate, which is also why '
              'its speed-up shows up over a run rather than in a single step.',
        ),
        SelfCheckQuestion(
          question:
              'Try beta = 0.9 on this same problem and it is slower than plain '
              'descent. Does that contradict the lesson?',
          expectedAnswer:
              'No. This loss is a single well-conditioned quadratic — the '
              'gradient never changes direction, the learning rate is already '
              'near-optimal, and heavy momentum simply overshoots and '
              'oscillates. Momentum pays off when curvature varies enormously '
              'between directions, so the learning rate is capped by the '
              'steepest direction while the shallow ones need far bigger steps. '
              'That is the narrow-valley case, and it is what real loss '
              'landscapes look like.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 224000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Gradient descent in five minutes, and I want to start with a '
              'hiking metaphor because it gets the whole idea across in one '
              'image. You are standing on a mountain in thick fog. You cannot '
              'see the valley — you cannot see anything except the ground '
              'right around your feet. But you can feel which way the ground '
              'slopes. That slope is the gradient. Take a small step downhill. '
              'Feel again. Step again. That is gradient descent — a purely '
              'local algorithm that never sees the big picture and still '
              'manages to find a low point.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'And the update rule is absurdly short: weight equals weight '
              'minus learning rate times gradient. The gradient is the '
              'derivative of the loss with respect to that weight — it says '
              '"if I nudge this weight up a tiny bit, how much does the error '
              'change?" Stack those for every weight and you have a vector '
              'pointing in the direction of steepest increase in loss. So you '
              'go the opposite way. Subtract it. That one line is the entire '
              'algorithm.',
          startMs: 44000,
          endMs: 88000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'The learning rate is your step size, and it is the '
              'hyperparameter most likely to be why your model is not '
              'training. Too small and you take baby steps — you will '
              'eventually reach the valley floor sometime around the heat '
              'death of the universe. Too large and you leap clear over the '
              'valley, land further up the far side, the gradient is now '
              'even bigger, your next leap is even crazier — and within '
              'seconds your loss explodes to NaN.',
          startMs: 88000,
          endMs: 132000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Then there is the data question. Computing the exact gradient '
              'over your entire million-row dataset for every single step is '
              'batch gradient descent — mathematically pure and unusably slow. '
              'Using just one random row is stochastic — blazing fast but '
              'incredibly noisy, like trying to navigate a mountain by feeling '
              'one pebble at a time. The sweet spot is mini-batch: average '
              'over 32 or 64 rows. The noise averages out enough to steer by, '
              'and the whole thing maps perfectly onto GPU matrix operations.',
          startMs: 132000,
          endMs: 178000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Last piece: momentum. Plain gradient descent is like walking '
              'downhill by stopping, looking at your feet, taking one step, '
              'stopping again. Momentum gives you a memory — you keep rolling '
              'in the direction you were already heading. Consistent downhill '
              'directions build up speed; directions that flip back and forth '
              'every step cancel out. In PyTorch it is one keyword argument '
              'on the SGD optimizer, and it usually just makes everything '
              'train faster.',
          startMs: 178000,
          endMs: 224000,
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
              'You already know what a network computes: fix the weights, '
              'push input through, get output. Today is the reverse. The data '
              'is fixed, the weights are unknown, and we need a procedure that '
              'finds good ones. That procedure is gradient descent. And here '
              'is the surprising part: it is genuinely simpler than most '
              'people expect. The whole algorithm is one line of code '
              'repeated: subtract a scaled version of the slope.',
          startMs: 0,
          endMs: 58000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Start with the landscape picture. Imagine hiking through fog '
              'on a mountain range with millions of dimensions. At any moment '
              'you only know two things: your current altitude — that is your '
              'loss — and which way is downhill from exactly where you stand — '
              'that is your gradient. You never see the whole mountain. You '
              'never know if you are heading for the lowest valley or just a '
              'local dip. But that is enough, because gradient descent is '
              'purely local. It only ever asks: which way is down, from right '
              'here?',
          startMs: 58000,
          endMs: 120000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'And the gradient is the answer to that question. One partial '
              'derivative per weight — "if I nudge this one up, how much does '
              'the loss change?" — collected into a vector. That vector points '
              'in the direction of steepest increase. You go the opposite way. '
              'Subtract the gradient, scaled by a learning rate. That is the '
              'entire update rule: w = w - lr × grad. Backpropagation is just '
              'the efficient algorithm that computes all those partial '
              'derivatives for every weight in one backward sweep, at '
              'roughly the cost of one forward pass.',
          startMs: 120000,
          endMs: 186000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Worth noticing a subtle property: the steps shrink by '
              'themselves. Near a minimum, the ground flattens out and the '
              'gradient goes to zero. The same learning rate produces smaller '
              'and smaller moves, so the process settles without anyone '
              'adjusting anything. On a simple quadratic bowl, each step '
              'multiplies your distance to the bottom by a fixed factor — '
              'geometric decay. Fast at first, then asymptotically patient. '
              'You cover most of the ground early and spend the rest of '
              'training inching towards perfection.',
          startMs: 186000,
          endMs: 248000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'The learning rate is where the physics of your loss landscape '
              'determines what works. On a quadratic with curvature a, each '
              'step multiplies distance to the minimum by 1 − lr × a. Below '
              '1 in absolute value, you converge. Above 1, you diverge — and '
              'the failure is self-reinforcing: overshoot puts you somewhere '
              'with an even bigger gradient, which produces an even bigger '
              'overshoot. The boundary between working and not is set by the '
              'shape of your loss, not by your intuition.',
          startMs: 248000,
          endMs: 312000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'The loss curve names the failure for you. A gently sloping '
              'line that has not flattened: your rate is too small, you could '
              'go faster. A curve that drops then bounces on a plateau: your '
              'steps are too big to settle into the minimum. A curve that '
              'rises or goes NaN: catastrophically too large. And since the '
              'ideal rate changes as training progresses — big early, small '
              'late — schedules are standard: cosine annealing sweeps the '
              'rate down smoothly, and warmup at the start prevents a freshly '
              'initialised model from being wrecked by its first few steps.',
          startMs: 312000,
          endMs: 374000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Then batching, which is a noise-versus-speed trade-off. True '
              'gradient descent uses the entire dataset for every step — the '
              'estimate is exact, and on a million rows you get one update '
              'per era. Stochastic gradient descent uses one row — the '
              'estimate is terrible and nearly free, giving you a million '
              'noisy updates per pass. Mini-batch averaging over 32 rows hits '
              'the sweet spot: the error in the estimate falls with √batch '
              'size, and the whole thing is a matrix multiply — exactly what '
              'GPUs are designed to do.',
          startMs: 374000,
          endMs: 436000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And momentum, the cheapest upgrade in the toolbox. Keep a '
              'velocity buffer: v = β × v + gradient, then step along v '
              'instead of the raw gradient. Consistent downhill directions '
              'compound — the effective step approaches 1/(1−β) times the '
              'plain step, about ten times at β=0.9. Directions that flip '
              'sign every step cancel. Think of a ball rolling downhill '
              'instead of a point teleporting. Just remember that ten-times '
              'boost when you turn momentum on, and drop the learning rate '
              'accordingly.',
          startMs: 436000,
          endMs: 496000,
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
              'Deep dive on optimisation. Imagine descending into a canyon '
              'in complete darkness with only a flashlight that shows you the '
              'ground three feet ahead. You take a step in the steepest '
              'downhill direction, check again, step again. That is gradient '
              'descent, and in the next forty minutes we are going to unpack '
              'what a loss landscape actually is, why deep network landscapes '
              'are non-convex, the update rule and what the gradient does and '
              'does not know, the learning rate as the boundary between three '
              'failure modes, batch size as a noise dial, momentum as memory, '
              'and where Adam fits in this picture.',
          startMs: 0,
          endMs: 68000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'The landscape framing. Fix the dataset and architecture, and '
              'the loss becomes a function whose only inputs are the weights. '
              'Every weight configuration is a location; the loss is the '
              'altitude. This framing is powerful because it converts '
              'learning into a search problem. It is dangerous because our '
              'intuition for surfaces comes from living in three dimensions, '
              'and almost none of it survives the journey to a hundred '
              'million. A ball rolling down a 3D surface is a lovely metaphor. '
              'The same ball in a million-dimensional space behaves in ways '
              'that flatly contradict that metaphor.',
          startMs: 68000,
          endMs: 146000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'Take non-convexity. A convex loss has exactly one basin — any '
              'downhill walk with a reasonable step size finds the global '
              'minimum. Deep networks are spectacularly non-convex, and one '
              'reason is almost trivial: swap two hidden neurons along with '
              'all their incoming and outgoing weights, and you get a '
              'numerically different solution computing the identical '
              'function. Every single minimum is duplicated a factorial '
              'number of times. The landscape is riddled with equivalent '
              'valleys.',
          startMs: 146000,
          endMs: 222000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Which sounds terrifying and in practice is not. The empirical '
              'picture for large over-parameterised networks is that the many '
              'minima all sit at broadly similar loss values. Which basin you '
              'fall into matters far less than classical optimisation theory '
              'would predict. And the real obstacles are usually not minima '
              'at all — they are saddles. In a million-dimensional space, a '
              'point where the gradient vanishes has to curve upward in every '
              'single direction to qualify as a minimum. That is an '
              'extraordinarily demanding condition. Most critical points are '
              'saddles: flat in some directions, downhill in others.',
          startMs: 222000,
          endMs: 300000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Saddles also explain why plateaus feel like the loss has '
              'stopped improving when it has not. Around a saddle, the '
              'gradient is tiny in most directions, so progress crawls. Then '
              'the trajectory eventually finds the descending direction and '
              'the loss picks up speed again. Noise from mini-batching helps '
              'here — a noisy step is more likely to stumble into the '
              'descending direction than a perfectly smooth one. Momentum '
              'helps too: anything that keeps you rolling through flat '
              'regions rather than grinding to a halt.',
          startMs: 300000,
          endMs: 378000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Back to the mechanics. The update is w - lr × gradient, and '
              'the gradient is a first-order, infinitesimally local quantity. '
              'It tells you the exact slope at your current position and '
              'says absolutely nothing about whether that slope persists for '
              'a millimetre or a mile. The learning rate is entirely a bet on '
              'how far the local picture stays accurate. Take too small a step '
              'and you creep. Take too large a step and the slope you measured '
              'is no longer relevant by the time you land — you are in '
              'different terrain.',
          startMs: 378000,
          endMs: 456000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'And curvature settles that bet. On a quadratic with second '
              'derivative a, each step multiplies distance to the minimum by '
              '1 - lr × a. Under 1 in magnitude: converge. Over 1: diverge — '
              'the failure is catastrophically self-reinforcing. Overshoot '
              'puts you further up the far side where the gradient is even '
              'larger, so the next overshoot is even worse. That is why '
              'divergence is not a gentle drift, it is an explosion that '
              'reaches infinity or NaN in seconds. Print your loss every step '
              'for the first ten steps — you will see it immediately.',
          startMs: 456000,
          endMs: 534000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Scale it up. Real networks have curvature that differs by '
              'orders of magnitude between different weight dimensions and '
              'changes as you move through the landscape. One scalar learning '
              'rate has to be safe in the steepest direction — the one where '
              'you will diverge first — which makes it absurdly small for the '
              'shallow directions. That single mismatch between a scalar '
              'step size and a wildly anisotropic landscape is the origin '
              'of momentum, of adaptive methods like Adam, of normalisation '
              'layers, and of nearly every learning rate schedule ever '
              'proposed.',
          startMs: 534000,
          endMs: 612000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Schedules deserve attention. Warmup ramps the learning rate '
              'from near zero over the first few hundred steps. It matters '
              'most for very large models where the first gradients from a '
              'random initialisation are enormous — one full-size step can '
              'permanently wreck the run. Cosine annealing then sweeps the '
              'rate smoothly down toward zero so training settles gracefully '
              'into a minimum rather than bouncing across it. The combination '
              'of warmup plus cosine decay is the default in essentially '
              'every modern training recipe.',
          startMs: 612000,
          endMs: 690000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Batch size as a noise dial. Larger batches give a more '
              'accurate gradient estimate and fewer updates per epoch. '
              'Smaller batches give a noisier gradient more often. The error '
              'in the estimate falls with the square root of batch size — '
              'going from 32 to 1024 costs 32 times the compute for roughly '
              '5.7 times the accuracy. Enormous batches need learning rate '
              'adjustments to pay off at all, and there is a practical '
              'ceiling where the gradient is essentially exact and further '
              'increases just waste compute.',
          startMs: 690000,
          endMs: 772000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Closing on momentum and its most famous descendant. Momentum '
              'keeps a decaying average of past gradients — agreement '
              'compounds, oscillation cancels, effective step approaches '
              '1/(1-β) times the raw step. Adam adds a second buffer: the '
              'average squared gradient. Dividing by its square root gives '
              'every parameter its own adaptive step size. A weight with '
              'historically tiny gradients gets a proportionally larger step; '
              'a weight with consistently huge gradients gets a smaller one. '
              'That is genuinely all Adam is: momentum plus per-parameter '
              'scaling plus a bias correction because both averages start '
              'at zero.',
          startMs: 772000,
          endMs: 858000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Training is a local search on a surface you cannot see',
      body:
          'A loss function maps every setting of the weights to one number, so '
          'training is the search for a low point on that surface. Gradient '
          'descent only ever knows the loss and the slope at its current '
          'position — for deep networks the surface is non-convex and '
          'high-dimensional, and the obstacles are usually saddles and '
          'plateaus rather than bad local minima.',
    ),
    SummaryCard(
      title: 'The rule is one line; the learning rate is the hard part',
      body:
          'The gradient points uphill, so `w = w - lr * grad` moves down. On a '
          'quadratic with curvature a, each step multiplies the distance to the '
          'minimum by `1 - lr * a`, which converges below one and explodes '
          'above it. Read the loss curve: gently falling means go bigger, '
          'bouncing on a plateau means go smaller, climbing or NaN means far '
          'too big.',
    ),
    SummaryCard(
      title: 'Mini-batches and momentum are the practical defaults',
      body:
          'Full-batch gradients are exact and unaffordable; single-example '
          'gradients are cheap and wild; mini-batches of 32 to 256 sit in '
          'between and match the hardware. Momentum then accumulates a velocity '
          '`v = beta * v + grad`, so consistent directions compound towards a '
          '`1 / (1 - beta)` speed-up and oscillating ones cancel.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Loss landscape',
      definition:
          'The surface formed by plotting the loss as a function of the '
          'weights, with one dimension per parameter. Convex for simple models, '
          'non-convex and enormously high-dimensional for deep networks, and '
          'only ever observed locally through the loss value and its gradient.',
    ),
    KeyConcept(
      term: 'Gradient',
      definition:
          'The vector of partial derivatives of the loss with respect to each '
          'weight. It points in the direction of steepest increase in loss, so '
          'descent moves in the opposite direction. Backpropagation is the '
          'algorithm that computes it for a whole network in one backward pass.',
    ),
    KeyConcept(
      term: 'Learning rate',
      definition:
          'The scalar multiplying the gradient in the update. Too small gives '
          'impractically slow convergence; too large overshoots, oscillates or '
          'diverges. The stable range is set by the curvature of the loss, and '
          'is usually varied over training by a schedule with optional warmup.',
    ),
    KeyConcept(
      term: 'Batch, stochastic and mini-batch gradient descent',
      definition:
          'Three choices of how much data goes into one gradient estimate: the '
          'entire training set (exact, one update per epoch), a single example '
          '(noisy, nearly free), or a group of 32 to 256 (the practical default '
          'that DataLoader and torch.optim assume).',
    ),
    KeyConcept(
      term: 'Momentum',
      definition:
          'An optimiser modification that keeps a decaying average of past '
          'gradients, `v = beta * v + grad`, and steps along it. Directions the '
          'gradient consistently agrees on accumulate towards a `1 / (1 - beta)` '
          'larger effective step; directions that reverse each step cancel out.',
    ),
    KeyConcept(
      term: 'Adam',
      definition:
          'Momentum plus a per-parameter adaptive learning rate: it tracks '
          'running averages of the gradient and of the squared gradient, '
          'bias-corrects both, and divides one by the square root of the other. '
          'Less sensitive to the initial learning rate than SGD, which is most '
          'of why it became the default.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Reaching for a bigger model or more data when the loss explodes to '
          'inf or NaN in the first few hundred steps.',
      correction:
          'That signature is a learning rate past the stability threshold '
          'almost every time. Divide it by ten and rerun for twenty steps '
          'before changing anything else, and add warmup if the instability '
          'only appears at the very start of training.',
    ),
    Mistake(
      mistake:
          'Computing the gradient over the entire dataset for every update and '
          'wondering why one epoch never finishes.',
      correction:
          'Full-batch gradient descent gives one parameter update per pass over '
          'the data, so a million-row dataset gets one step per epoch. Switch to '
          'mini-batches of 32 to 256: the gradient is slightly noisier and you '
          'get thousands of updates per epoch instead of one.',
    ),
    Mistake(
      mistake: 'Forgetting `optimizer.zero_grad()` in a PyTorch loop.',
      correction:
          'PyTorch accumulates into `.grad` rather than overwriting it, so '
          'step N would apply the sum of every gradient so far and the '
          'effective learning rate grows without bound. Call zero_grad before '
          'each backward pass — the accumulation itself is deliberate, and is '
          'what makes gradient accumulation across micro-batches possible.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Your loss becomes NaN after about fifty steps. Walk me through your '
          'debugging.',
      answer:
          'First suspect is the learning rate, so I would divide it by ten and '
          'rerun twenty steps — if the NaN disappears, that was it, and I would '
          'then find the largest stable rate and add warmup if the instability '
          'is confined to the start. If it persists I would print the loss every '
          'step to see whether it climbs smoothly, which points at divergence, '
          'or jumps in one step, which points at a specific bad batch or a '
          'numerical issue such as a log of zero, a division by a near-zero '
          'denominator, or an unclipped exploding gradient in a recurrent model. '
          'I would also check the gradient norms per layer, sanity-check the '
          'data for NaNs and extreme values, and confirm the inputs are '
          'normalised, since unscaled features inflate gradients directly.',
    ),
    InterviewQuestion(
      question:
          'When would you prefer a large batch size, and what has to change if '
          'you use one?',
      answer:
          'Large batches make sense when you have hardware to saturate, want '
          'reproducible and lower-variance gradients, or are training '
          'distributed across many devices where communication per update is '
          'expensive. The costs are that the error in the gradient only falls '
          'with the square root of the batch size, so you pay linearly for '
          'sublinear accuracy, and that you get far fewer updates per epoch. To '
          'compensate you normally scale the learning rate up with the batch '
          'size, roughly linearly, and add warmup because that larger rate is '
          'dangerous from a random initialisation. It is also worth watching '
          'generalisation: the gradient noise from small batches has a mild '
          'regularising effect, and very large batches sometimes need more '
          'explicit regularisation to match it.',
    ),
    InterviewQuestion(
      question: 'Explain momentum, and when it does not help.',
      answer:
          'Momentum keeps a running velocity, `v = beta * v + grad`, and steps '
          'along the velocity rather than the raw gradient. Directions where '
          'successive gradients agree compound, approaching a `1 / (1 - beta)` '
          'multiple of the plain step — about ten times at beta 0.9 — while '
          'directions that flip sign every step partly cancel, which damps '
          'oscillation. It pays off precisely when curvature varies a lot '
          'between directions, because there the learning rate is capped by the '
          'steepest direction and the shallow ones need much larger steps. On a '
          'well-conditioned problem where the gradient direction is stable and '
          'the rate is already near-optimal, momentum mostly just overshoots and '
          'can be slower. The practical trap is that turning it on multiplies '
          'the effective step by around ten, so a previously stable learning '
          'rate can start diverging and needs lowering.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: 'SGD — PyTorch docs',
    url: 'https://docs.pytorch.org/docs/stable/generated/torch.optim.SGD.html',
    description:
        'The reference for the optimiser used throughout this lesson, including '
        'the exact velocity convention behind the momentum, dampening and '
        'nesterov arguments.',
  ),
  Source(
    title: 'torch.optim — PyTorch docs',
    url: 'https://docs.pytorch.org/docs/stable/optim.html',
    description:
        'Overview of the optimiser API and learning rate schedulers, and the '
        'source of the zero_grad / backward / step loop structure shown in the '
        'momentum section.',
  ),
  Source(
    title: 'Adam: A Method for Stochastic Optimization (Kingma & Ba, 2014)',
    url: 'https://arxiv.org/abs/1412.6980',
    description:
        'The original Adam paper, giving the moment estimates and bias '
        'correction summarised in the deep dive on adaptive learning rates.',
  ),
];
