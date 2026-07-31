import '../models/topic.dart';
import 'deep_learning/lesson_embeddings.dart';
import 'deep_learning/lesson_gradient_descent.dart';
import 'deep_learning/lesson_overfitting.dart';
import 'deep_learning/lesson_transformers.dart';

/// A third topic: under the hood of modern neural networks, from how they
/// learn to the architectures behind today's language and vision models.
///
/// Lesson bodies live one per file under `sample_data/deep_learning/`; this
/// file only assembles them into the module and topic hierarchy.
const Topic deepLearningTopic = Topic(
  id: 'deep-learning',
  title: 'Deep Learning',
  description:
      'How neural networks actually learn, how they avoid merely memorising '
      'their training data, and the attention-based architectures behind '
      'today\'s language and vision models.',
  iconName: 'data',
  modules: [dlOptimizationModule, dlModernArchitecturesModule],
);

const Module dlOptimizationModule = Module(
  id: 'dl-optimization',
  title: 'Optimization & Generalization',
  description:
      'The loop that turns random weights into a useful function — gradient '
      'descent and its variants — and the toolkit for keeping a network from '
      'merely memorising the data it was trained on.',
  lessons: [gradientDescentLesson, overfittingLesson],
);

const Module dlModernArchitecturesModule = Module(
  id: 'dl-modern-architectures',
  title: 'Modern Architectures',
  description:
      'Attention as the mechanism behind nearly every modern language and '
      'vision-language model, and the dense vector representations it '
      'operates over.',
  lessons: [transformersLesson, embeddingsLesson],
);
