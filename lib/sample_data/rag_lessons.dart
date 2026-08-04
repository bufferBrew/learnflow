import '../models/topic.dart';
import 'rag/lesson_advanced_rag_patterns.dart';
import 'rag/lesson_chunking_strategies.dart';
import 'rag/lesson_vector_databases_embeddings.dart';
import 'rag/lesson_what_is_rag.dart';

/// A fourth topic: retrieval-augmented generation, from why it exists to the
/// indexing and query-time patterns that make it work well in practice.
///
/// Lesson bodies live one per file under `sample_data/rag/`; this file only
/// assembles them into the module and topic hierarchy.
const Topic ragTopic = Topic(
  id: 'rag',
  title: 'RAG',
  description:
      'Why frozen model knowledge needs grounding in retrieved documents, '
      'the embeddings and indexes that make retrieval fast, and the '
      'chunking and query-time patterns that decide whether it actually '
      'works.',
  iconName: 'search',
  modules: [ragFoundationsModule, ragAdvancedTechniquesModule],
);

const Module ragFoundationsModule = Module(
  id: 'rag-foundations',
  title: 'Foundations',
  description:
      'The problem retrieval-augmented generation solves and the dense '
      'vector representations and indexes it is built on.',
  lessons: [whatIsRagLesson, vectorDatabasesEmbeddingsLesson],
);

const Module ragAdvancedTechniquesModule = Module(
  id: 'rag-advanced-techniques',
  title: 'Advanced Techniques',
  description:
      'How source documents are split before they are ever embedded, and '
      'the hybrid search, re-ranking, multi-hop and query-construction '
      'patterns that pick up where naive top-k retrieval runs out of road.',
  lessons: [chunkingStrategiesLesson, advancedRagPatternsLesson],
);
