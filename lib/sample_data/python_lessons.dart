import '../models/topic.dart';
import 'python/lesson_async.dart';
import 'python/lesson_collections.dart';
import 'python/lesson_control_flow.dart';
import 'python/lesson_environments.dart';
import 'python/lesson_errors.dart';
import 'python/lesson_functions.dart';
import 'python/lesson_generators.dart';
import 'python/lesson_oop.dart';
import 'sample_lesson.dart';

/// The default topic the app opens with: three modules of three lessons each.
///
/// Lesson bodies live one per file under `sample_data/python/`; this file only
/// assembles them into the module and topic hierarchy. Lesson 1 is the
/// original [sampleLesson], which already covers Variables & Data Types.
const Topic pythonTopic = Topic(
  id: 'python',
  title: 'Python',
  description:
      'A practical path through Python, from the object model to the tools '
      'you will use every day.',
  iconName: 'code',
  modules: [foundationsModule, dataAndObjectsModule, workingLikeAProModule],
);

const Module foundationsModule = Module(
  id: 'py-foundations',
  title: 'Foundations',
  description:
      'The core language mechanics every later Python topic builds on: how '
      'values are named, how code branches and loops, and how functions and '
      'their scopes work.',
  lessons: [sampleLesson, controlFlowLesson, functionsLesson],
);

const Module dataAndObjectsModule = Module(
  id: 'py-data-and-objects',
  title: 'Data & Objects',
  description:
      'Structuring data with the built-in containers, modelling it with '
      'classes, and handling the failures that come with real input.',
  lessons: [collectionsLesson, oopLesson, errorsLesson],
);

const Module workingLikeAProModule = Module(
  id: 'py-working-like-a-pro',
  title: 'Working Like a Pro',
  description:
      'The practices that separate scripts from software: isolated '
      'environments, lazy evaluation and concurrency that holds up under '
      'load.',
  lessons: [environmentsLesson, generatorsLesson, asyncLesson],
);
