import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 1, lesson 2: why a network that trains well still fails on new data,
/// and the standard toolkit for closing that gap.
const Lesson overfittingLesson = Lesson(
  id: 'dl-overfitting-regularization',
  title: 'Overfitting & Regularization',
  description:
      'Diagnosing the gap between training and validation loss, and the four '
      'standard fixes — dropout, weight decay, early stopping and data '
      'augmentation.',
  estimatedMinutes: 29,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  review: _review,
  sources: _sources,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'diagnosis',
      heading: 'What overfitting looks like in a deep net',
      blocks: [
        ProseBlock(
          'Gradient descent minimises the loss on the training set. Nothing in '
          'that procedure asks the network to work on data it has not seen — '
          'that is your problem, not the optimiser\'s. A network with enough '
          'parameters can drive training loss towards zero by memorising the '
          'training examples one by one, noise and mislabelled rows included, '
          'and it will happily do so if you let it.',
        ),
        ProseBlock(
          'The symptom is visible in two curves plotted together. Training loss '
          'keeps falling. Validation loss falls with it for a while, flattens, '
          'and then starts climbing. The epoch where validation loss turns is '
          'the moment the network stopped learning generalisable structure and '
          'started learning the training set itself. Everything after that '
          'point makes the model worse at the only job that matters.',
        ),
        ProseBlock(
          'Underfitting is the opposite failure and looks different: both '
          'curves plateau high and close together. The network is not capable '
          'enough, or not trained long enough, or the learning rate is wrong. '
          'The fix there is more capacity or more training, which is exactly '
          'the opposite of what you do for overfitting — so read the curves '
          'before reaching for a remedy.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
train_loss = [0.92, 0.61, 0.44, 0.33, 0.26, 0.21, 0.17, 0.14, 0.11, 0.09]
val_loss   = [0.95, 0.68, 0.52, 0.45, 0.43, 0.44, 0.47, 0.52, 0.58, 0.65]


def overfitting_onset(val_loss):
    """Epoch at which validation loss first turns upward, or None."""
    best_epoch = val_loss.index(min(val_loss))
    if best_epoch == len(val_loss) - 1:
        return None                      # still improving; train longer
    return best_epoch + 1


print(overfitting_onset(val_loss))       # 5
print(train_loss[4], val_loss[4])        # 0.26 0.43  <- best model lives here
print(train_loss[9], val_loss[9])        # 0.09 0.65  <- memorised, and worse
''',
          caption:
              'Training loss alone tells you nothing about generalisation. The '
              'gap between the two curves is the whole signal.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'A gap is not automatically a problem',
          text:
              'Training loss below validation loss is normal — the model has '
              'seen one set and not the other. What matters is the direction '
              'of the validation curve. A widening gap where validation loss '
              'is still falling is fine; a widening gap where it is rising is '
              'overfitting.',
        ),
      ],
    ),
    Section(
      id: 'dropout',
      heading: 'Dropout: stop units from co-adapting',
      blocks: [
        ProseBlock(
          'Dropout randomly zeroes a fraction p of the activations in a layer '
          'on every forward pass during training. A different random subset '
          'disappears each time, so no unit can count on any particular other '
          'unit being present. That is the mechanism: it breaks up '
          'co-adaptation, where a group of units learns a jointly clever '
          'feature detector that only fires when all of them agree — precisely '
          'the kind of over-specific detector that fits training noise.',
        ),
        ProseBlock(
          'One useful way to read it is as cheap ensembling. Each forward pass '
          'trains a different thinned subnetwork drawn from the same weights, '
          'and at inference the full network approximates the average of that '
          'exponentially large ensemble. Each unit is pushed to be '
          'independently useful rather than a member of a fragile committee.',
        ),
        ProseBlock(
          'At inference dropout must be off — you want the full, deterministic '
          'network. PyTorch handles the bookkeeping: `nn.Dropout` scales the '
          'surviving activations by 1/(1-p) during training, so the expected '
          'sum reaching the next layer is unchanged and evaluation needs no '
          'compensating rescale. All you have to do is put the module in the '
          'right mode.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import torch
from torch import nn

model = nn.Sequential(
    nn.Linear(784, 512),
    nn.ReLU(),
    nn.Dropout(p=0.5),      # half the activations zeroed, resampled every pass
    nn.Linear(512, 256),
    nn.ReLU(),
    nn.Dropout(p=0.3),      # gentler nearer the output
    nn.Linear(256, 10),
)

model.train()               # dropout ON, survivors scaled by 1 / (1 - p)
logits = model(x_batch)
loss = criterion(logits, y_batch)
loss.backward()

model.eval()                # dropout OFF, full deterministic network
with torch.no_grad():
    val_logits = model(x_val)
''',
          caption:
              'The same module behaves differently in train and eval mode; the '
              'mode flag is the only thing you control.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Forgetting model.eval() is the classic dropout bug',
          text:
              'A model left in train mode at inference still drops random '
              'activations, so predictions become noisy and validation scores '
              'come out mysteriously worse than training ones — the exact '
              'shape you would misread as overfitting. Batch normalisation '
              'misbehaves in the same way, updating its running statistics on '
              'validation data. Call model.eval() before every evaluation '
              'block and model.train() at the top of every training epoch.',
        ),
      ],
    ),
    Section(
      id: 'weight-decay',
      heading: 'Weight decay and the L2 penalty',
      blocks: [
        ProseBlock(
          'Weight decay pushes every weight towards zero on every step. The '
          'classical framing adds a term proportional to the squared magnitude '
          'of the weights to the loss — L2 regularisation — so the optimiser '
          'now has to justify every large weight with a matching reduction in '
          'prediction error. Weights that only exist to fit one awkward '
          'training example cannot pay for themselves and shrink away.',
        ),
        ProseBlock(
          'The effect is a bias towards smoother, simpler functions. Large '
          'weights let a network produce sharp, high-curvature responses to '
          'small input changes, which is how it carves out individual training '
          'points; constraining their magnitude limits how wiggly the learned '
          'function can be. The strength coefficient is a hyperparameter, '
          'typically between 1e-5 and 1e-1, and it genuinely needs tuning.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from torch import optim

# Plain SGD: weight_decay adds the L2 gradient term for you.
optimizer = optim.SGD(model.parameters(), lr=0.01, weight_decay=1e-4)

# For adaptive optimisers, prefer AdamW, which decays the weights directly
# instead of routing the penalty through the adaptive gradient machinery.
optimizer = optim.AdamW(model.parameters(), lr=3e-4, weight_decay=0.01)

# Biases and normalisation scales are usually excluded: shrinking them
# constrains the model without buying any smoothness.
decay, no_decay = [], []
for param in model.parameters():
    (no_decay if param.ndim <= 1 else decay).append(param)

optimizer = optim.AdamW(
    [
        {"params": decay, "weight_decay": 0.01},
        {"params": no_decay, "weight_decay": 0.0},
    ],
    lr=3e-4,
)
''',
          caption:
              'One keyword argument, but which optimiser it sits on changes '
              'what it actually does.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: why AdamW exists',
          children: [
            ProseBlock(
              'With plain SGD, adding a penalty on squared weights to the loss '
              'and multiplying the weights by a shrink factor on every step '
              'are the same operation. The gradient of the penalty is '
              'proportional to the weight, so it lands on the parameter '
              'scaled by the learning rate either way. The two names — L2 '
              'regularisation and weight decay — are used interchangeably for '
              'good reason there.',
            ),
            ProseBlock(
              'Adam breaks the equivalence. Adam divides each parameter\'s '
              'update by a running estimate of its gradient magnitude, so '
              'parameters with consistently large gradients take '
              'proportionally smaller steps. If the L2 term arrives as part of '
              'the gradient, it goes through that same division: weights whose '
              'gradients are large get their decay damped, and weights whose '
              'gradients are tiny get decayed hard. The amount of '
              'regularisation a weight receives ends up depending on its '
              'gradient history, which is not what anyone intended.',
            ),
            ProseBlock(
              'Loshchilov and Hutter\'s fix is to decouple the two: compute '
              'the Adam update from the data gradient alone, then subtract a '
              'fixed fraction of the weight afterwards. That is AdamW. It '
              'restores uniform decay across parameters, makes the learning '
              'rate and the decay coefficient roughly independent to tune, and '
              'closed a long-standing generalisation gap between Adam and SGD '
              'with momentum on image benchmarks. In PyTorch, optim.Adam with '
              'weight_decay is the naive coupled version and optim.AdamW is '
              'the decoupled one — for anything modern, reach for AdamW.',
            ),
            CodeBlock(
              language: 'python',
              code: '''
# Sketch of the difference, one parameter, one step.

# Adam with weight_decay: penalty enters through the gradient, then gets
# divided by the adaptive denominator along with everything else.
grad = data_grad + wd * w
w -= lr * grad / (sqrt(v_hat) + eps)

# AdamW: adaptive step from the data gradient only, decay applied straight
# to the weight and untouched by v_hat.
w -= lr * data_grad / (sqrt(v_hat) + eps)
w -= lr * wd * w
''',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'early-stopping',
      heading: 'Early stopping: let validation choose the epoch',
      blocks: [
        ProseBlock(
          'If validation loss bottoms out at epoch 14 and rises thereafter, '
          'the best model you will ever have during that run existed at epoch '
          '14. Early stopping is the discipline of noticing that and keeping '
          'it, rather than training for a round number of epochs and shipping '
          'whatever came out at the end.',
        ),
        ProseBlock(
          'The mechanism is a patience counter. Track the best validation loss '
          'seen so far; every epoch that fails to beat it increments a '
          'counter, and any epoch that does beat it resets the counter to '
          'zero. When the counter reaches the patience threshold, stop. '
          'Patience exists because validation loss is noisy — a single bad '
          'epoch is not a trend, and stopping on the first uptick throws away '
          'runs that would have recovered.',
        ),
        ProseBlock(
          'Crucially, stopping is not enough on its own. By the time patience '
          'runs out you are several epochs past the best weights, so keep a '
          'snapshot of the best state and restore it at the end. This costs '
          'one extra copy of the parameters and turns early stopping from '
          '"train slightly too long" into "return the best model".',
        ),
        CodeBlock(
          language: 'python',
          code: '''
best_val_loss = float("inf")
best_state = None
patience, wait = 5, 0

for epoch in range(200):
    model.train()
    train_one_epoch(model, train_loader, optimizer)

    model.eval()
    val = evaluate(model, val_loader)

    if val < best_val_loss - 1e-4:        # a real improvement, not noise
        best_val_loss, wait = val, 0
        best_state = {k: v.detach().clone()
                      for k, v in model.state_dict().items()}
    else:
        wait += 1
        if wait >= patience:
            print(f"stopped at epoch {epoch}, best val {best_val_loss:.4f}")
            break

model.load_state_dict(best_state)         # roll back to the best epoch
''',
          caption:
              'The min-delta of 1e-4 stops trivial fluctuations from counting '
              'as improvements and resetting patience forever.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'The validation set is now a hyperparameter',
          text:
              'Early stopping selects the epoch using validation loss, which '
              'means the validation set has influenced the final model. Its '
              'score is therefore slightly optimistic. If you need an honest '
              'estimate of generalisation — and for anything you will publish '
              'or ship, you do — keep a separate test set that is touched once '
              'at the very end.',
        ),
      ],
    ),
    Section(
      id: 'augmentation',
      heading: 'Data augmentation: regularise the data, not the model',
      blocks: [
        ProseBlock(
          'Dropout, weight decay and early stopping all constrain the model. '
          'Data augmentation attacks the same problem from the other side: it '
          'manufactures more training data by applying label-preserving '
          'transformations to the examples you already have. A cat rotated ten '
          'degrees, cropped differently, or flipped horizontally is still a '
          'cat, so each transformed copy is a legitimate new training example '
          'the network has never seen.',
        ),
        ProseBlock(
          'What this buys is invariance. The network sees the same object '
          'under variation and cannot memorise exact pixel arrangements, '
          'because the exact arrangement changes every epoch. In effect you '
          'are telling the model which changes to the input should not change '
          'the output — a strong piece of domain knowledge that no amount of '
          'weight penalty could express.',
        ),
        ProseBlock(
          'The transformations must genuinely preserve the label, which is '
          'domain-specific. A horizontal flip is fine for cats and wrong for '
          'handwritten digits and road signs. Aggressive colour jitter is fine '
          'for object recognition and destructive for medical imaging where '
          'intensity carries meaning. Text has synonym replacement and '
          'back-translation; audio has time stretching, pitch shifting and '
          'noise injection — same idea, different invariances.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from torchvision import transforms

train_tf = transforms.Compose([
    transforms.RandomResizedCrop(224, scale=(0.7, 1.0)),
    transforms.RandomHorizontalFlip(),
    transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225]),
])

# Validation and test get one deterministic view. Random transforms here
# would make the score a lottery and stop it comparing across epochs.
eval_tf = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225]),
])
''',
          caption:
              'Augment the training pipeline only; the evaluation pipeline '
              'keeps just the deterministic resize and normalise.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'These four are complementary, not alternatives',
          text:
              'A typical modern image model uses augmentation, weight decay '
              'via AdamW, dropout in the classifier head, and early stopping '
              'on validation loss, all at once — they constrain different '
              'things and stack. Add them one at a time so you can see what '
              'each one bought. And keep the ordering right: confirm you are '
              'actually overfitting first, then regularise. If more real '
              'labelled data is available, that beats every technique on this '
              'list, because it fixes the cause rather than compensating for '
              'it.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-of-onset',
      title: 'Find the epoch where it went wrong',
      prompt: [
        ProseBlock(
          'You are given per-epoch training and validation losses from three '
          'runs. Write diagnose(train, val) that returns one of "overfitting", '
          '"underfitting" or "healthy", along with the epoch of the best '
          'validation loss.',
        ),
        ProseBlock(
          'Call it overfitting when validation loss has risen meaningfully '
          'above its minimum by the final epoch. Call it underfitting when '
          'both curves are still high and close together at the end. Otherwise '
          'the run is healthy and could use more epochs.',
        ),
      ],
      starterCode: '''
runs = {
    "a": ([0.92, 0.61, 0.44, 0.33, 0.26, 0.21, 0.17, 0.14, 0.11, 0.09],
          [0.95, 0.68, 0.52, 0.45, 0.43, 0.44, 0.47, 0.52, 0.58, 0.65]),
    "b": ([0.94, 0.88, 0.84, 0.82, 0.81, 0.80, 0.80, 0.79, 0.79, 0.78],
          [0.96, 0.90, 0.86, 0.84, 0.83, 0.82, 0.82, 0.81, 0.81, 0.80]),
    "c": ([0.90, 0.66, 0.51, 0.42, 0.36, 0.31, 0.28, 0.25, 0.23, 0.21],
          [0.93, 0.71, 0.57, 0.49, 0.44, 0.40, 0.37, 0.35, 0.33, 0.32]),
}


def diagnose(train, val, rise_tol=0.02, high_loss=0.5):
    """Return (verdict, best_epoch) for one run."""
    ...


for name, (train, val) in runs.items():
    print(name, diagnose(train, val))
''',
      solutionCode: '''
runs = {
    "a": ([0.92, 0.61, 0.44, 0.33, 0.26, 0.21, 0.17, 0.14, 0.11, 0.09],
          [0.95, 0.68, 0.52, 0.45, 0.43, 0.44, 0.47, 0.52, 0.58, 0.65]),
    "b": ([0.94, 0.88, 0.84, 0.82, 0.81, 0.80, 0.80, 0.79, 0.79, 0.78],
          [0.96, 0.90, 0.86, 0.84, 0.83, 0.82, 0.82, 0.81, 0.81, 0.80]),
    "c": ([0.90, 0.66, 0.51, 0.42, 0.36, 0.31, 0.28, 0.25, 0.23, 0.21],
          [0.93, 0.71, 0.57, 0.49, 0.44, 0.40, 0.37, 0.35, 0.33, 0.32]),
}


def diagnose(train, val, rise_tol=0.02, high_loss=0.5):
    """Return (verdict, best_epoch) for one run."""
    best_val = min(val)
    best_epoch = val.index(best_val)

    if val[-1] - best_val > rise_tol:
        return "overfitting", best_epoch

    # Both curves stuck high and hugging each other: not enough capacity or
    # not enough training, which is the opposite problem.
    if train[-1] > high_loss and val[-1] - train[-1] < rise_tol:
        return "underfitting", best_epoch

    return "healthy", best_epoch


for name, (train, val) in runs.items():
    print(name, diagnose(train, val))

# a ('overfitting', 4)   val bottoms at epoch 4, then climbs to 0.65
# b ('underfitting', 9)  both curves flat near 0.8, gap almost zero
# c ('healthy', 9)       still improving at the last epoch; train longer
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Run c has the smallest train/validation gap of the three. Why '
              'is that not evidence that it is the best model?',
          expectedAnswer:
              'A small gap only means the model generalises what it has '
              'learned; it says nothing about how much it has learned. Run c '
              'ends at 0.32 validation loss while run a reached 0.43 at its '
              'best — so on this evidence run a is still worse, but run c has '
              'not finished converging and the comparison is premature. Judge '
              'models by best validation loss, and use the gap only to decide '
              'which direction to move: more capacity, or more regularisation.',
        ),
        SelfCheckQuestion(
          question:
              'Why does the function use min(val) rather than checking whether '
              'validation loss rose between consecutive epochs?',
          expectedAnswer:
              'Because validation loss is noisy. Any single epoch can be worse '
              'than the one before it by chance — different batch ordering, '
              'dropout masks, or just a small validation set — so a '
              'consecutive-pair test fires constantly on runs that are still '
              'improving. Comparing the final loss to the running minimum with '
              'a tolerance looks at the trend instead, which is the same '
              'reasoning behind the patience counter in early stopping.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-of-early-stopping',
      title: 'Build an early-stopping tracker',
      prompt: [
        ProseBlock(
          'Implement EarlyStopper with a patience parameter and a min_delta '
          'threshold. Each epoch you call step(val_loss); it returns True when '
          'training should stop. It should also record the epoch and value of '
          'the best loss seen, so the caller knows which checkpoint to restore.',
        ),
        ProseBlock(
          'An improvement counts only if it beats the best so far by more than '
          'min_delta. Any improvement resets the counter to zero; anything '
          'else increments it.',
        ),
      ],
      starterCode: '''
val_losses = [0.95, 0.68, 0.52, 0.45, 0.43, 0.44, 0.43, 0.47, 0.52, 0.58]


class EarlyStopper:
    def __init__(self, patience=3, min_delta=1e-4):
        ...

    def step(self, val_loss):
        """Record this epoch's loss; return True if training should stop."""
        ...


stopper = EarlyStopper(patience=3)
for epoch, loss in enumerate(val_losses):
    if stopper.step(loss):
        print("stop at epoch", epoch)
        break

print("restore epoch", stopper.best_epoch, "loss", stopper.best_loss)
''',
      solutionCode: '''
val_losses = [0.95, 0.68, 0.52, 0.45, 0.43, 0.44, 0.43, 0.47, 0.52, 0.58]


class EarlyStopper:
    def __init__(self, patience=3, min_delta=1e-4):
        self.patience = patience
        self.min_delta = min_delta
        self.best_loss = float("inf")
        self.best_epoch = -1
        self.wait = 0
        self.epoch = -1

    def step(self, val_loss):
        """Record this epoch's loss; return True if training should stop."""
        self.epoch += 1

        if val_loss < self.best_loss - self.min_delta:
            self.best_loss = val_loss
            self.best_epoch = self.epoch
            self.wait = 0
        else:
            self.wait += 1

        return self.wait >= self.patience


stopper = EarlyStopper(patience=3)
for epoch, loss in enumerate(val_losses):
    if stopper.step(loss):
        print("stop at epoch", epoch)
        break

print("restore epoch", stopper.best_epoch, "loss", stopper.best_loss)

# epoch 4 sets the best (0.43); epoch 5 is worse so wait = 1; epoch 6 ties
# 0.43, which does not beat it by min_delta, so wait = 2; epoch 7 pushes
# wait to 3 and training stops.
# stop at epoch 7
# restore epoch 4 loss 0.43
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Epoch 6 has a validation loss of 0.43, exactly matching the '
              'best. Why does the tracker treat that as a failure rather than '
              'a success?',
          expectedAnswer:
              'Because it did not beat the best by more than min_delta. The '
              'threshold exists so that repeated near-identical values cannot '
              'keep resetting patience and hold a plateaued run open forever. '
              'Tying the best is a plateau, not progress — and the checkpoint '
              'you would restore is unchanged either way, so nothing is lost '
              'by counting it against the budget.',
        ),
        SelfCheckQuestion(
          question:
              'What goes wrong if you stop training but forget to restore the '
              'best checkpoint?',
          expectedAnswer:
              'You ship the weights from the epoch where patience ran out, '
              'which by construction is `patience` epochs past the best one '
              'and therefore measurably worse — in this run, epoch 7 at 0.47 '
              'instead of epoch 4 at 0.43. Early stopping without checkpoint '
              'restoration only limits how far past the optimum you go; '
              'saving and reloading the best state is what actually delivers '
              'the best model.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-of-weight-decay',
      title: 'Watch weight decay shrink the weights',
      prompt: [
        ProseBlock(
          'Simulate 100 SGD steps on four independent weights, each with a '
          'constant gradient, and compare a run with decoupled weight decay '
          'against one without. The update rule with decay is '
          'w := w - lr * g - lr * wd * w; without decay, drop the last term.',
        ),
        ProseBlock(
          'Pay attention to the two weights whose gradient is zero. The data '
          'gives them no reason to move at all — see what decay does to them, '
          'and to the weights that do have a gradient pushing back.',
        ),
      ],
      starterCode: '''
weights = [2.0, -1.5, 0.8, 0.05]
grads   = [0.10, -0.05, 0.0, 0.0]     # held constant for every step

lr, wd, steps = 0.1, 0.05, 100


def run(weights, grads, lr, wd, steps):
    """Return the weights after `steps` updates with decoupled decay."""
    ...


print("with decay:   ", run(weights, grads, lr, wd, steps))
print("without decay:", run(weights, grads, lr, 0.0, steps))
''',
      solutionCode: '''
weights = [2.0, -1.5, 0.8, 0.05]
grads   = [0.10, -0.05, 0.0, 0.0]     # held constant for every step

lr, wd, steps = 0.1, 0.05, 100


def run(weights, grads, lr, wd, steps):
    """Return the weights after `steps` updates with decoupled decay."""
    w = list(weights)
    for _ in range(steps):
        w = [wi - lr * gi - lr * wd * wi for wi, gi in zip(w, grads)]
    return [round(wi, 4) for wi in w]


def total_magnitude(w):
    return round(sum(abs(wi) for wi in w), 4)


with_decay = run(weights, grads, lr, wd, steps)
without_decay = run(weights, grads, lr, 0.0, steps)

print("with decay:   ", with_decay,    total_magnitude(with_decay))
print("without decay:", without_decay, total_magnitude(without_decay))

# with decay:    [0.4231, -0.5144, 0.4846, 0.0303]  1.4524
# without decay: [1.0, -1.0, 0.8, 0.05]             2.85
#
# Every step multiplies the weight by (1 - lr * wd) = 0.995, so after 100
# steps an ungradiented weight retains 0.995 ** 100 = 0.606 of its size.
# The two weights that do have a gradient settle towards -g / wd, where the
# pull from the data exactly balances the pull towards zero.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The third and fourth weights have zero gradient, so the '
              'training data is indifferent to them. Why is shrinking them a '
              'good idea?',
          expectedAnswer:
              'A weight the data does not constrain is a free parameter, and '
              'free parameters are where memorisation and instability live: '
              'its value is whatever initialisation left behind, and it still '
              'contributes to the output on inputs unlike the training set. '
              'Decay resolves the tie in favour of the simpler function by '
              'driving unconstrained weights towards zero, which is exactly '
              'the smoothness bias L2 regularisation is meant to provide.',
        ),
        SelfCheckQuestion(
          question:
              'The first weight ends near 0.42 rather than at zero. What sets '
              'that resting point, and what happens if you double wd?',
          expectedAnswer:
              'It is heading for the equilibrium where the gradient pull and '
              'the decay pull cancel, at w = -g / wd = -0.10 / 0.05 = -2.0, '
              'and after 100 steps it is still travelling towards it. Doubling '
              'wd halves that equilibrium magnitude and reaches it faster, so '
              'the weights end up smaller. That is the tuning knob: too little '
              'decay does nothing, too much drags weights below what the data '
              'supports and you underfit.',
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
              'Overfitting in one sentence: your training loss keeps falling '
              'while your validation loss flattens out and then starts rising. '
              'At that turning point the network stopped learning patterns and '
              'started memorising examples, noise and all. Plot both curves '
              'every run — training loss alone tells you nothing.',
          startMs: 0,
          endMs: 44000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'First tool: dropout. During training you randomly zero a '
              'fraction of the activations in a layer, a different random set '
              'each pass. No unit can rely on any other unit being there, so '
              'you break up those over-specific co-adapted feature detectors. '
              'At inference it turns off, and PyTorch handles the rescaling '
              'for you.',
          startMs: 44000,
          endMs: 88000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Second: weight decay, also called L2 regularisation. You '
              'penalise large weights, which biases the network towards '
              'smoother functions. In PyTorch it is one keyword on the '
              'optimiser — and for Adam you want AdamW, which applies the '
              'decay properly rather than routing it through the adaptive '
              'gradient machinery.',
          startMs: 88000,
          endMs: 134000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Third: early stopping. Instead of training for a fixed number '
              'of epochs, watch validation loss, keep a snapshot of the best '
              'weights, and stop when it has failed to improve for a set '
              'patience number of epochs. Then restore that snapshot — '
              'stopping without restoring only limits how far past the optimum '
              'you drift.',
          startMs: 134000,
          endMs: 180000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Fourth: data augmentation. Random crops, flips, colour jitter — '
              'label-preserving transformations that give the network more '
              'variation than your raw dataset contains. That one regularises '
              'the data rather than the model. All four stack, and the one '
              'that beats all of them is more real data, when you can get it.',
          startMs: 180000,
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
              'Last time we got a network training. Today: why a network that '
              'trains beautifully can still be useless. Gradient descent '
              'minimises loss on the training set, and that is all it does. '
              'Nothing in the algorithm asks for performance on data it has '
              'not seen. That part is entirely on you.',
          startMs: 0,
          endMs: 52000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'And a big network has more than enough capacity to just '
              'memorise. Modern architectures can fit randomly shuffled labels '
              'to near-zero training loss — there is a famous experiment '
              'showing exactly that. So the fact that your loss went down is '
              'not evidence of learning anything. The diagnostic is two curves '
              'on one axis: training loss falling, validation loss flattening '
              'and then turning upward.',
          startMs: 52000,
          endMs: 116000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'Worth naming the opposite failure too, because people reach for '
              'the wrong fix. Underfitting looks like both curves plateauing '
              'high and close together — the network is not capable enough or '
              'has not trained long enough. That wants more capacity. '
              'Overfitting wants less. Read the curves before you pick.',
          startMs: 116000,
          endMs: 180000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Right, so tool one, dropout. Every forward pass you zero out a '
              'random fraction of a layer\'s activations — fifty percent is '
              'the classic setting for a fully connected layer. A different '
              'subnetwork trains each pass, so the units cannot form fragile '
              'committees where a feature only works when four specific '
              'partners all agree. Each one has to be independently useful.',
          startMs: 180000,
          endMs: 246000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'And the practical trap: model dot train and model dot eval. '
              'Dropout must be off at inference. PyTorch scales the surviving '
              'activations by one over one minus p during training so the '
              'expected magnitudes match and eval needs no compensation — but '
              'only if you actually flip the mode. Leaving a model in train '
              'mode during evaluation is probably the single most common bug '
              'in this whole area.',
          startMs: 246000,
          endMs: 312000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Tool two, weight decay. Add a penalty on the squared magnitude '
              'of the weights, and now every large weight has to justify '
              'itself with reduced error. Large weights are what let a network '
              'produce sharp responses that carve out individual training '
              'points, so constraining them buys smoothness. One caveat: for '
              'Adam, use AdamW. Naive L2 through the gradient gets distorted '
              'by Adam\'s per-parameter scaling; AdamW decays the weight '
              'directly.',
          startMs: 312000,
          endMs: 378000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Tool three, early stopping, which is almost free. Track the '
              'best validation loss, keep a patience counter, reset it on any '
              'genuine improvement and increment it otherwise. When patience '
              'runs out, stop. And save the best state dict as you go, because '
              'by the time you stop you are several epochs past the good one. '
              'Restoring the snapshot is what makes it worth doing.',
          startMs: 378000,
          endMs: 440000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Tool four, augmentation, and it is the odd one out — it changes '
              'the data instead of the model. Random resized crops, horizontal '
              'flips, colour jitter, all through torchvision transforms, on '
              'the training pipeline only. Never on validation or test, or '
              'your score becomes a lottery. And these four are complementary, '
              'not competing: real image pipelines run all of them at once.',
          startMs: 440000,
          endMs: 496000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 856000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Long form on generalisation. The plan: what overfitting '
              'actually is and how to see it, dropout and the co-adaptation '
              'story it came from, weight decay and the surprisingly subtle '
              'business of what decay means for an adaptive optimiser, early '
              'stopping done properly, augmentation, and then how to combine '
              'the lot without fooling yourself.',
          startMs: 0,
          endMs: 66000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with the framing. Training is empirical risk '
              'minimisation: you minimise average loss over a finite sample '
              'and hope it stands in for the loss over the real distribution. '
              'Overfitting is that hope failing. The sample carries structure '
              'that generalises and idiosyncrasy that does not, and a '
              'sufficiently flexible model has no way to tell them apart. It '
              'fits both, because both reduce the training loss.',
          startMs: 66000,
          endMs: 140000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'The diagnostic is unglamorous and non-negotiable: plot training '
              'and validation loss per epoch. Training loss keeps descending, '
              'validation bottoms out and turns. The turning epoch is where '
              'the marginal thing being learned stopped being signal. And note '
              'the gap itself is not the alarm — a gap is normal, since one '
              'set was optimised on and the other was not. The direction of '
              'the validation curve is the alarm.',
          startMs: 140000,
          endMs: 214000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Contrast that with underfitting, where both curves plateau high '
              'and hug each other. Same-looking chart at a glance, opposite '
              'remedy: more parameters, more epochs, a better learning rate. '
              'Reaching for dropout on an underfit network makes it strictly '
              'worse, and people do this constantly because regularisation '
              'feels like the responsible thing to do.',
          startMs: 214000,
          endMs: 288000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'On to dropout. The original 2012 paper by Hinton and colleagues '
              'is titled "Improving neural networks by preventing '
              'co-adaptation of feature detectors", and that title is the '
              'entire mechanism. Units conspire: a detector emerges that works '
              'only because three particular other units behave a particular '
              'way. That conspiracy is brittle and heavily tuned to the '
              'training set. Randomly deleting units at every pass makes such '
              'arrangements unsustainable.',
          startMs: 288000,
          endMs: 360000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'The other reading is ensembling. Each forward pass trains a '
              'different thinned subnetwork sampled from shared weights, and '
              'at test time the full network approximates an average over that '
              'exponentially large family. Ensembles generalise better than '
              'their members, and here you get one at essentially no cost. '
              'Practically: point five in dense classifier heads, much lower '
              'or absent in convolutional stacks, and modern transformer code '
              'often prefers point one with heavy augmentation instead.',
          startMs: 360000,
          endMs: 432000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Implementation detail that bites everyone. PyTorch uses '
              'so-called inverted dropout: during training it zeroes with '
              'probability p and multiplies the survivors by one over one '
              'minus p, so expected activation is preserved and eval mode is a '
              'plain forward pass. That is why model dot eval is sufficient. '
              'It is also why forgetting it is so insidious — the model still '
              'runs, still returns plausible numbers, and quietly scores '
              'worse, which you then misdiagnose as overfitting.',
          startMs: 432000,
          endMs: 504000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Weight decay next. Classically you add lambda times the sum of '
              'squared weights to the loss. Take the gradient and you get a '
              'term proportional to the weight itself, so each step nudges '
              'every weight towards zero in proportion to its size. For plain '
              'SGD, adding that penalty to the loss and multiplying weights by '
              'a shrink factor are literally the same update. Two names, one '
              'operation.',
          startMs: 504000,
          endMs: 576000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'And then Adam breaks the equivalence, which is the AdamW story. '
              'Adam divides each update by a running estimate of that '
              'parameter\'s gradient magnitude. If the L2 term arrives inside '
              'the gradient, it goes through the same division — so a weight '
              'with large gradients gets its decay damped, and a weight with '
              'tiny gradients gets hammered. How much regularisation a '
              'parameter receives ends up depending on its gradient history. '
              'Nobody wanted that.',
          startMs: 576000,
          endMs: 648000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Loshchilov and Hutter\'s 2017 paper decouples them: compute the '
              'adaptive step from the data gradient alone, then subtract a '
              'fixed fraction of the weight separately. That is AdamW. It '
              'restores uniform decay, makes learning rate and decay roughly '
              'independent to tune, and closed a real generalisation gap '
              'between Adam and SGD with momentum. In PyTorch, Adam with '
              'weight decay is the coupled version, AdamW is the decoupled '
              'one. Use AdamW.',
          startMs: 648000,
          endMs: 720000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'Early stopping and augmentation round it out. Early stopping is '
              'a patience counter plus a saved best state dict — and the saved '
              'state is the part people skip, which wastes most of the '
              'benefit. Augmentation is different in kind: it encodes which '
              'input changes should not change the output. Flips for cats yes, '
              'for digits and road signs no. Colour jitter for objects yes, '
              'for medical scans where intensity is the diagnosis absolutely '
              'not.',
          startMs: 720000,
          endMs: 790000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Closing frame. Regularisation looks like a bag of unrelated '
              'tricks — deleting activations, penalising magnitudes, stopping '
              'early, distorting images — and they share one goal: reduce the '
              'effective capacity the model can spend on memorising, without '
              'losing the capacity it needs for real structure. They stack, so '
              'add them one at a time and measure. And know the ceiling: none '
              'of this beats more real labelled data, because everything here '
              'is compensation for not having it.',
          startMs: 790000,
          endMs: 856000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'The two curves are the diagnostic',
      body:
          'Overfitting is training loss still falling while validation loss '
          'flattens or rises — the network has started memorising training '
          'examples and their noise. Underfitting is both curves plateauing '
          'high and close together, and wants the opposite remedy. Plot them '
          'together every run, because training loss alone is uninformative.',
    ),
    SummaryCard(
      title: 'Four tools, three on the model and one on the data',
      body:
          'Dropout zeroes random activations to break co-adaptation. Weight '
          'decay penalises large weights to bias towards smoother functions. '
          'Early stopping lets validation loss choose the epoch. Data '
          'augmentation manufactures label-preserving variation. They are '
          'complementary and routinely used together.',
    ),
    SummaryCard(
      title: 'The details that actually bite',
      body:
          'Call model.eval() before evaluating or dropout stays active. Use '
          'AdamW rather than Adam with weight_decay, because coupled L2 is '
          'distorted by adaptive scaling. Restore the best checkpoint after '
          'early stopping, not just stop. Augment training data only. And '
          'confirm you are overfitting before regularising at all.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Overfitting',
      definition:
          'Fitting idiosyncrasies of the training set — including noise and '
          'mislabelled examples — rather than generalisable structure. '
          'Recognised by training loss continuing to fall while validation '
          'loss flattens or rises.',
    ),
    KeyConcept(
      term: 'Dropout',
      definition:
          'Randomly zeroing a fraction p of a layer\'s activations on each '
          'training forward pass, so no unit can depend on any specific other '
          'unit. Disabled at inference; PyTorch rescales survivors by 1/(1-p) '
          'during training so eval needs no compensation.',
    ),
    KeyConcept(
      term: 'Weight decay (L2 regularisation)',
      definition:
          'Penalising the squared magnitude of the weights, which pulls every '
          'weight towards zero each step and biases the network towards '
          'smoother functions. Exposed as the weight_decay argument on a '
          'PyTorch optimiser.',
    ),
    KeyConcept(
      term: 'Decoupled weight decay (AdamW)',
      definition:
          'Applying the decay directly to the weights instead of adding an L2 '
          'term to the gradient. For adaptive optimisers the two are not '
          'equivalent, because the adaptive denominator distorts a '
          'gradient-borne penalty; AdamW is the decoupled variant.',
    ),
    KeyConcept(
      term: 'Early stopping',
      definition:
          'Halting training once validation loss has failed to improve for a '
          'set patience number of epochs, and restoring the best-so-far '
          'checkpoint, rather than training for a fixed epoch count.',
    ),
    KeyConcept(
      term: 'Data augmentation',
      definition:
          'Generating label-preserving transformed copies of training '
          'examples — crops, flips, colour jitter for images — to expose the '
          'network to more variation than the raw dataset contains. '
          'Regularises through the data rather than the model.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Evaluating without calling model.eval(), leaving dropout active.',
      correction:
          'Predictions become stochastic and validation scores come out worse '
          'than they should — the exact pattern you would misread as '
          'overfitting. Batch normalisation compounds it by updating running '
          'statistics on validation data. Call model.eval() before every '
          'evaluation block and model.train() at the top of every epoch.',
    ),
    Mistake(
      mistake:
          'Adding weight decay and dropout to a network before checking '
          'whether it overfits at all.',
      correction:
          'Regularisation reduces effective capacity, so on an underfitting '
          'network it makes things strictly worse. Train first, plot both '
          'curves, and only regularise once validation loss is visibly '
          'diverging from training loss. If both are plateaued high, add '
          'capacity instead.',
    ),
    Mistake(
      mistake:
          'Applying the training augmentation pipeline to validation or test '
          'data.',
      correction:
          'Random crops and jitter make the evaluation score a lottery that '
          'cannot be compared across epochs or runs. Build two pipelines: a '
          'random one for training, and a deterministic resize-and-normalise '
          'one for evaluation. Test-time augmentation is a deliberate, '
          'separate technique that averages over several fixed views.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Your training loss is at 0.02 and your validation loss has been '
          'climbing for the last ten epochs. What do you do?',
      answer:
          'First I would confirm the diagnosis is real rather than an '
          'artefact — check that model.eval() is being called before '
          'validation, and that no augmentation or dropout is active during '
          'it. Assuming it is genuine overfitting, the cheapest fix is early '
          'stopping with checkpoint restoration, which immediately recovers '
          'the best epoch I already trained past. Then I would add '
          'regularisation one change at a time so I can attribute the effect: '
          'augmentation first if it is image or audio data, since it usually '
          'gives the largest gain, then weight decay via AdamW, then dropout '
          'in the classifier head. If a large amount more labelled data is '
          'obtainable, that outranks all of it, and I would also check for '
          'leakage or duplicates between the splits before assuming the model '
          'is the problem.',
    ),
    InterviewQuestion(
      question: 'How does dropout reduce overfitting, and what is the cost?',
      answer:
          'It zeroes a random fraction of activations on each training forward '
          'pass, so a unit cannot rely on any particular other unit being '
          'present. That prevents co-adaptation — brittle feature detectors '
          'that only work when a specific group of units fires together, which '
          'is a common shape for memorised training detail. Equivalently, each '
          'pass trains a different thinned subnetwork and inference '
          'approximates an ensemble average over them. The costs are that '
          'training gets noisier and typically needs more epochs to converge, '
          'that the dropout rate is another hyperparameter, and that on an '
          'underfit network it just hurts. There is also the operational cost '
          'that you must remember model.eval(), which is one of the most '
          'frequent bugs in practice.',
    ),
    InterviewQuestion(
      question:
          'Is weight decay the same thing as L2 regularisation? Why does '
          'AdamW exist?',
      answer:
          'For plain SGD they are the same update: the gradient of the '
          'squared-weight penalty is proportional to the weight, so adding it '
          'to the loss is identical to multiplying the weight by a shrink '
          'factor each step. For adaptive optimisers they diverge. Adam '
          'divides each update by a running estimate of that parameter\'s '
          'gradient magnitude, so an L2 term riding inside the gradient gets '
          'divided too — parameters with large gradients receive damped decay '
          'and parameters with small ones get decayed hard, making the '
          'effective regularisation depend on gradient history. AdamW, from '
          'Loshchilov and Hutter, decouples them: the adaptive step uses the '
          'data gradient alone and the decay is subtracted from the weight '
          'afterwards. It restores uniform decay, makes learning rate and '
          'decay strength roughly independent to tune, and closed a measured '
          'generalisation gap between Adam and SGD with momentum.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title:
        'Improving neural networks by preventing co-adaptation of feature '
        'detectors (Hinton et al., 2012)',
    url: 'https://arxiv.org/abs/1207.0580',
    description:
        'The paper that introduced dropout, and the source of the '
        'co-adaptation argument this lesson uses to explain why randomly '
        'deleting units helps.',
  ),
  Source(
    title: 'Dropout — PyTorch docs',
    url: 'https://docs.pytorch.org/docs/stable/generated/torch.nn.Dropout.html',
    description:
        'API reference for nn.Dropout, including the 1/(1-p) rescaling during '
        'training that makes the train/eval mode switch shown here sufficient.',
  ),
  Source(
    title: 'Decoupled Weight Decay Regularization (Loshchilov & Hutter, 2017)',
    url: 'https://arxiv.org/abs/1711.05101',
    description:
        'The paper behind AdamW, explaining why L2-through-the-gradient and '
        'true weight decay differ for adaptive optimisers as covered in the '
        'weight decay deep dive.',
  ),
];
