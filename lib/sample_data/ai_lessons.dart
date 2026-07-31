import '../models/topic.dart';
import 'ai_fundamentals/lesson_neural_networks.dart';
import 'ai_fundamentals/lesson_supervised_unsupervised.dart';
import 'ai_fundamentals/lesson_training_vs_inference.dart';
import 'ai_fundamentals/lesson_what_is_ai.dart';

/// A second topic: the vocabulary and mechanics every ML conversation
/// assumes, from "what is a model" to how one is trained and served.
///
/// Lesson bodies live one per file under `sample_data/ai_fundamentals/`; this
/// file only assembles them into the module and topic hierarchy.
const Topic aiFundamentalsTopic = Topic(
  id: 'ai-fundamentals',
  title: 'AI Fundamentals',
  description:
      'From "what is a model" to a working mental picture of how one is '
      'trained and evaluated — the concepts the rest of machine learning is '
      'written on top of.',
  iconName: 'science',
  modules: [aiFoundationsModule, aiModelsInPracticeModule],
);

const Module aiFoundationsModule = Module(
  id: 'ai-foundations',
  title: 'Foundations',
  description:
      'What it means to learn a rule from data instead of writing one, and '
      'how the paradigms — supervised, unsupervised and everything between — '
      'differ in what they need and what they can deliver.',
  lessons: [whatIsAiLesson, supervisedUnsupervisedLesson],
);

const Module aiModelsInPracticeModule = Module(
  id: 'ai-models-in-practice',
  title: 'Models in Practice',
  description:
      'The machinery underneath a working model — neurons and layers as '
      'matrix arithmetic — and the discipline of proving it actually '
      'generalises before it ever sees production traffic.',
  lessons: [neuralNetworksLesson, trainingVsInferenceLesson],
);
