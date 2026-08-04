import '../models/topic.dart';
import 'agentic_workflows/lesson_agentic_rag_workflows.dart';
import 'agentic_workflows/lesson_multi_agent_systems.dart';
import 'agentic_workflows/lesson_tools_function_calling.dart';
import 'agentic_workflows/lesson_what_are_ai_agents.dart';

/// A fifth topic: what turns a language model into something that acts —
/// the agent loop, the tools it reaches for, and the multi-agent and
/// agentic-retrieval patterns built on top of it.
///
/// Lesson bodies live one per file under `sample_data/agentic_workflows/`;
/// this file only assembles them into the module and topic hierarchy.
const Topic agenticWorkflowsTopic = Topic(
  id: 'agentic-workflows',
  title: 'Agentic Workflows',
  description:
      'The loop underneath every AI agent, how it reaches out into the '
      'world through tools, and the multi-agent orchestration and agentic '
      'retrieval patterns built on top of that loop.',
  iconName: 'agent',
  modules: [agenticFoundationsModule, agenticAdvancedPatternsModule],
);

const Module agenticFoundationsModule = Module(
  id: 'agentic-foundations',
  title: 'Foundations',
  description:
      'What makes something an agent rather than a chatbot or a fixed '
      'prompt chain, and the mechanics of letting a model call tools.',
  lessons: [whatAreAiAgentsLesson, toolsFunctionCallingLesson],
);

const Module agenticAdvancedPatternsModule = Module(
  id: 'agentic-advanced-patterns',
  title: 'Advanced Patterns',
  description:
      'Composing single agents into orchestrators, hierarchies and '
      'debating panels, and letting an agent decide when and how to '
      'retrieve instead of following a fixed RAG pipeline.',
  lessons: [multiAgentSystemsLesson, agenticRagWorkflowsLesson],
);
