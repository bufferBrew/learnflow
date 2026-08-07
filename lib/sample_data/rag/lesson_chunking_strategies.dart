import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 2, lesson 1: how source documents get split into the units that
/// actually get embedded and retrieved, and why that offline decision quietly
/// caps the quality of every query that comes after it.
const Lesson chunkingStrategiesLesson = Lesson(
  id: 'rag-chunking-strategies',
  title: 'Chunking Strategies',
  description:
      'Fixed-size, recursive and semantic splitting, why overlap exists and '
      'what it costs, and how to choose and evaluate a chunk size instead of '
      'guessing one.',
  estimatedMinutes: 36,
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
      id: 'why-chunk',
      heading: 'Why nothing gets embedded whole',
      blocks: [
        ProseBlock(
          'The last two lessons took the retrieval half of a RAG pipeline '
          'almost for granted: a query comes in, gets embedded, gets '
          'compared against a store of chunk vectors, and the closest '
          'matches come back. This lesson steps back one stage further and '
          'asks where those chunk vectors actually came from — specifically, '
          'what decided the boundaries of a "chunk" in the first place. That '
          'decision was made once, offline, before a single query ever '
          'arrived, and every later retrieval inherits whatever it got right '
          'or wrong.',
        ),
        ProseBlock(
          'Part of the answer is a hard constraint: embedding models cannot '
          'accept an arbitrary document. Classic BERT-family encoders cap '
          'out around 512 tokens; even generous modern retrieval-embedding '
          'models top out somewhere in the low thousands. Text beyond that '
          'limit is either truncated outright — everything past the cutoff '
          'is simply discarded — or pooled into one vector that now has to '
          'represent a far longer span than the model was trained to '
          'represent well. Either way, a multi-page document cannot be a '
          'single retrievable unit, so something upstream of embedding has '
          'to decide what the unit actually is. That something is chunking.',
        ),
        ProseBlock(
          'But the limit alone would only demand chunking as a formality — '
          'chop the document at the token ceiling and move on. The reason '
          'chunk size is a genuine design decision, not a technicality, is '
          'that retrieval quality degrades in both directions away from some '
          'sweet spot. Make chunks too large and the embedding for a chunk '
          'becomes an average over however many distinct ideas the chunk '
          'happens to contain, so it stops sitting close to any single query '
          'in the vector space — a chunk covering five different topics is '
          'a mediocre match for all five. And every time that chunk is '
          'retrieved, all of its irrelevant surrounding text rides along '
          'into the LLM\'s prompt, spending real context budget — and real '
          'money, since most LLM APIs bill per token — on prose the question '
          'never needed.',
        ),
        ProseBlock(
          'Make chunks too small and the failure looks different but is '
          'equally damaging. A fragment can lose the antecedent its pronoun '
          'refers to, the header row a data row depends on, or the function '
          'signature a code snippet was defined under. Retrieval can find '
          'the exactly-right sentence and still hand the generator something '
          'that reads as ambiguous, or flatly wrong, once it is separated '
          'from the context that made it interpretable. Both failure modes '
          'point at the same underlying idea: a chunk is supposed to be a '
          'coherent, self-contained unit of meaning, and choosing its size '
          'is choosing how ambitious that coherence claim is allowed to be.',
        ),
        CalloutBlock(
          type: CalloutType.info,
          title: 'One vector, one idea',
          text:
              'An embedding is a single point in space representing '
              'everything inside the chunk it was computed from. If a chunk '
              'contains several unrelated ideas, the model has no way to '
              'output several vectors for it — it must compress all of them '
              'into one point, and that point ends up close to none of the '
              'individual ideas particularly well. Chunking is the step that '
              'decides, in advance, what a single vector is actually being '
              'asked to represent.',
        ),
      ],
    ),
    Section(
      id: 'fixed-size-and-overlap',
      heading: 'Fixed-size chunking and the overlap it needs',
      blocks: [
        ProseBlock(
          'The simplest possible chunker counts characters or tokens and '
          'cuts the document into consecutive pieces of that length. It '
          'costs essentially nothing computationally, it is trivial to '
          'implement, and it is a completely reasonable baseline to start '
          'from — which is exactly why it is usually the first thing anyone '
          'reaches for. Its failure mode is just as simple: the cut point '
          'lands wherever the running character count says to, with zero '
          'awareness of what is actually sitting at that position in the '
          'text.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
text = (
    "RAG retrieves relevant passages before generating an answer. "
    "Chunking decides what a passage means. Overlap between neighbouring "
    "chunks exists so information straddling a boundary is not lost."
)


def chunk_fixed(text, chunk_size, overlap=0):
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        if end >= len(text):
            break
        start = end - overlap
    return chunks


for c in chunk_fixed(text, 80, overlap=0):
    print(repr(c))

# 'RAG retrieves relevant passages before generating an answer. Chunking decides wh'
# 'at a passage means. Overlap between neighbouring chunks exists so information st'
# 'raddling a boundary is not lost.'
#
# Two of the three chunks end mid-word: "wh|at" and "st|raddling". The
# splitter has no idea it just cut a word in half -- it was only counting.
''',
          caption:
              'On real prose, a boundary landing mid-word is not a rare edge '
              'case — it happens at nearly every cut, because word lengths '
              'have no relationship to the chosen chunk size.',
        ),
        ProseBlock(
          'The same blindness applies to anything with internal structure. '
          'A cut can fall in the middle of a table row, splitting a value '
          'from the column header that gives it meaning. It can fall inside '
          'a code block, leaving one chunk with an unclosed bracket and the '
          'next with a dangling function body that means nothing on its '
          'own. Fixed-size chunking treats a Markdown table, a Python '
          'function and a paragraph of prose identically — as an undifferentiated '
          'run of characters — because that is the only thing it is looking '
          'at.',
        ),
        ProseBlock(
          'Overlap is the standard patch for the specific failure of a '
          'boundary landing directly on top of information that matters. '
          'Instead of starting each new chunk exactly where the previous one '
          'ended, the new chunk starts some distance earlier — repeating the '
          'tail of the previous chunk as the head of the next — so a '
          'sentence or fact that straddles the cut point survives intact '
          'inside at least one of the two chunks. A typical overlap is '
          'roughly ten to twenty percent of the chunk size: large enough to '
          'catch most straddling content, small enough not to dominate the '
          'chunk.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
for c in chunk_fixed(text, 80, overlap=20):
    print(repr(c))

# 'RAG retrieves relevant passages before generating an answer. Chunking decides wh'
# ' Chunking decides what a passage means. Overlap between neighbouring chunks exis'
# 'hbouring chunks exists so information straddling a boundary is not lost.'
#
# "straddling" now survives whole in the third chunk instead of being cut,
# because the second chunk's tail carries forward into it. Notice the price:
# "Chunking decides" and "hbouring chunks exists" each now appear, in full or
# in part, in two chunks instead of one.
''',
          caption:
              'Overlap does not eliminate mid-word cuts in general — it only '
              'guarantees that whatever sits near a boundary shows up whole '
              'in at least one neighbouring chunk.',
        ),
        ProseBlock(
          'That guarantee is not free. Every overlapped span is now stored, '
          'and later embedded and indexed, twice — a corpus chunked with '
          '20% overlap has roughly 20% more vectors to store and search than '
          'the same corpus chunked with no overlap at all. Worse than the '
          'storage cost, two overlapping chunks that both contain the answer '
          'to a query can both surface as top-k results, quietly consuming '
          'two slots of a fixed retrieval budget — say, top-4 — for what is '
          'effectively one piece of information stated twice. Overlap trades '
          'a real, measurable cost for a real, but partial, fix: it protects '
          'content that happens to straddle exactly one boundary, and does '
          'nothing for a chunk that is simply too small to make sense on its '
          'own regardless of what is next to it.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Overlap fixes a boundary problem, not a granularity problem',
          text:
              'It is tempting to reach for more overlap whenever retrieval '
              'quality is disappointing, but overlap only helps information '
              'that straddles a single chunk boundary. If a chunk is simply '
              'too small to contain a coherent idea — a table row with no '
              'header, a sentence with no antecedent — no amount of overlap '
              'restores that context, because the missing information was '
              'never adjacent to the chunk in the first place. That failure '
              'needs a bigger chunk or a smarter split, not more overlap.',
        ),
      ],
    ),
    Section(
      id: 'recursive-splitting',
      heading: 'Recursive splitting: honour structure before length',
      blocks: [
        ProseBlock(
          'Recursive splitting is the structural upgrade over blind '
          'character counting, and LangChain\'s RecursiveCharacterTextSplitter '
          'is the implementation most people mean when they use the term. '
          'It holds a prioritised list of separators — by default something '
          'like paragraph breaks, then single newlines, then spaces, and '
          'finally the empty string as an absolute last resort — and it '
          'tries the first separator, merging the resulting pieces back '
          'together into a running chunk for as long as the merged length '
          'stays under the chunk-size limit. Only when a single piece is '
          'still too big on its own does it recurse into that one piece '
          'using the next separator down the list.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
def recursive_split(text, chunk_size, separators):
    sep = separators[0]
    rest = separators[1:]
    pieces = list(text) if sep == "" else text.split(sep)

    chunks = []
    current = ""
    for piece in pieces:
        candidate = current + (sep if current else "") + piece
        if len(candidate) <= chunk_size:
            current = candidate
        else:
            if current:
                chunks.append(current)
            if len(piece) > chunk_size and rest:
                chunks.extend(recursive_split(piece, chunk_size, rest))
                current = ""
            else:
                current = piece
    if current:
        chunks.append(current)
    return chunks


text = """Chunking splits a document into passages small enough to embed and retrieve individually. The simplest approach counts characters or tokens and cuts at a fixed length, ignoring what the text actually says at that point.

Recursive splitting fixes the worst of that by trying a list of separators in priority order. It first tries to split on paragraph breaks. If a resulting piece is still too big, it recurses into that piece using the next separator down the list -- typically single newlines, then sentence boundaries, then spaces, then finally individual characters as a last resort."""

separators = ["\\n\\n", "\\n", ". ", " ", ""]
for i, c in enumerate(recursive_split(text, 220, separators)):
    print(i, len(c), repr(c[:50]) + "...")

# 0 219 'Chunking splits a document into passages small en'...   <- whole paragraph 1, untouched
# 1 137 'Recursive splitting fixes the worst of that by tr'...   <- two full sentences merged
# 2 219 'If a resulting piece is still too big, it recurse'...   <- sentence 3 was 227 chars, fell
# 3 7   'resort.'...                                              back to a WORD-level split
''',
          caption:
              'Paragraph one fits under the limit and is never touched. '
              'Paragraph two does not, so recursion drops one level to '
              'sentences; its third sentence is still too long even alone, '
              'so recursion drops again to word-level splitting — only for '
              'that one sentence, not the whole document.',
        ),
        ProseBlock(
          'That behaviour is worth sitting with, because it is not obvious '
          'from the description alone: recursive splitting does not apply '
          'one uniform rule to the whole document. A short paragraph that '
          'comfortably fits under the size limit survives completely '
          'untouched, while only the long paragraph next to it gets pushed '
          'down into sentence-level or word-level splitting. Force is '
          'applied exactly where it is needed and nowhere else, which is a '
          'meaningfully better default than fixed-size splitting for almost '
          'no extra engineering cost — and it is why recursive splitting is '
          'the default most RAG tooling reaches for first.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: what recursive splitting still does not solve',
          children: [
            ProseBlock(
              'Recursive splitting is still, underneath all of it, governed '
              'by a length threshold and a fixed list of separator '
              'characters. It has no notion of what the text actually '
              'means — only where whitespace and punctuation happen to sit. '
              'Two adjacent sentences about completely unrelated topics get '
              'merged into the same chunk just as readily as two sentences '
              'that are genuinely part of one idea, as long as the character '
              'count allows it. The splitter cannot tell the difference, '
              'because it never looked at meaning in the first place.',
            ),
            ProseBlock(
              'The separator list also has to be told about structure it '
              'was not designed for. The default separators are tuned for '
              'prose; pointed at a Markdown document they will happily cut '
              'through the middle of a table, and pointed at source code '
              'they will cut through the middle of a function, because '
              '"\\n\\n" and ". " mean nothing special inside a table row or a '
              'function body. LangChain and similar libraries ship separate, '
              'purpose-built splitters for exactly this reason — a Markdown '
              'header splitter, a language-aware code splitter — rather than '
              'trying to make one generic separator list handle every '
              'format. The lesson\'s next section covers what those '
              'purpose-built rules actually look like.',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'semantic-and-structured',
      heading: 'Semantic chunking and structured content',
      blocks: [
        ProseBlock(
          'Semantic chunking closes the meaning gap directly instead of '
          'relying on punctuation as a proxy for it. Embed each sentence, or '
          'a small sliding window of a few sentences, and compute the '
          'similarity between every pair of adjacent units. Where two '
          'neighbours are highly similar, they almost certainly belong to '
          'the same idea; where similarity drops sharply, that is a real '
          'topic boundary, and that is where the chunk splits. The '
          'mechanism is the same cosine-similarity comparison the previous '
          'lesson used to rank retrieved chunks — just applied between '
          'adjacent sentences at indexing time instead of between a query '
          'and a corpus at query time.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import numpy as np

sentences = [
    "Chunk size controls how much text one embedding has to represent.",
    "A chunk that is too large blends several ideas into one vector.",
    "A chunk that is too small loses the context a reader needs.",
    "HNSW indexes trade memory for faster approximate nearest neighbour search.",
    "Quantizing stored vectors to eight bits cuts index memory substantially.",
    "IVF indexes cluster vectors ahead of time and search only nearby clusters.",
]

# Toy 4-dim embeddings standing in for a real embedding model's output.
# Sentences 0-1 are about chunk size, 2-... wait, sentences 0-2 are about
# chunk size, sentences 3-5 are about vector indexes -- a real topic shift.
vectors = np.array([
    [0.90, 0.10, 0.05, 0.00],
    [0.85, 0.15, 0.05, 0.00],
    [0.88, 0.12, 0.05, 0.00],
    [0.05, 0.05, 0.85, 0.10],
    [0.05, 0.10, 0.80, 0.15],
    [0.10, 0.05, 0.82, 0.12],
])


def cosine_similarity(a, b):
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))


sims = [cosine_similarity(vectors[i], vectors[i + 1]) for i in range(len(vectors) - 1)]
print([round(s, 3) for s in sims])
# [0.998, 0.999, 0.121, 0.996, 0.996]
#
# One number collapses relative to the rest: similarity between sentence 2
# and sentence 3 drops to 0.121 while every other adjacent pair stays above
# 0.99. That is the topic boundary -- a threshold of, say, 0.5 splits the
# corpus into exactly the two groups a human would draw by hand.
''',
          caption:
              'The discontinuity is unambiguous here because the toy '
              'sentences were written to demonstrate it; real prose produces '
              'noisier similarity sequences, which is why production systems '
              'use a percentile-based cutoff rather than one fixed number.',
        ),
        ProseBlock(
          'The cost is direct: deciding where to cut now requires an '
          'embedding-model call for every sentence in the corpus, before '
          'those same chunks get embedded again for the actual retrieval '
          'index. On a million-sentence corpus that is a million extra calls '
          'spent purely on the segmentation decision, which is significantly '
          'more expensive — in both latency and API cost — than the pure '
          'string manipulation recursive splitting requires. Semantic '
          'chunking earns that cost on documents with real, unpredictable '
          'topic drift: long reports, meeting transcripts, forum threads, '
          'anything where a fixed-size or recursive cut is likely to land '
          'mid-topic by bad luck. It buys almost nothing on a corpus that is '
          'already one clean topic per file — API reference pages, a '
          'well-organised wiki — where recursive splitting on paragraph and '
          'heading boundaries already produces coherent chunks for free.',
        ),
        ProseBlock(
          'Structured content deserves dedicated handling regardless of '
          'which text splitter is doing the rest of the work, because none '
          'of character-count, recursive, or plain semantic splitting '
          'understands code, tables, or Markdown as anything more than a '
          'string. Code should be split at logical boundaries — function or '
          'class definitions — using a language-aware splitter (most text-'
          'splitting libraries ship one, built on the target language\'s '
          'actual grammar), never at an arbitrary character count that can '
          'sever a function mid-body and leave two chunks that are each '
          'syntactically broken on their own. Tables should be chunked row '
          'by row with the header row repeated into every chunk, so a '
          'single row retrieved in isolation still carries the column names '
          'that make its numbers meaningful. Markdown should split at '
          'heading boundaries and carry the full heading path forward as a '
          'prefix on every chunk beneath it, so a chunk retrieved on its own '
          'still announces which section of the document it came from.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Prepend the context a fragment cannot carry by itself',
          text:
              'A cheap, high-leverage trick applies to nearly every '
              'structured-content case above: prepend the context that '
              'gives a fragment meaning directly into the chunk\'s text, not '
              'just its metadata. Prefixing a table row with its column '
              'names, or a Markdown section with its heading path, costs a '
              'few extra tokens per chunk and turns a fragment that only '
              'made sense in place into one that reads correctly wherever '
              'it lands — including inside the LLM\'s prompt after '
              'retrieval.',
        ),
      ],
    ),
    Section(
      id: 'choosing-and-evaluating',
      heading: 'Choosing a chunk size and proving it was right',
      blocks: [
        ProseBlock(
          'None of the strategies above answers the question a team '
          'actually has to answer for their corpus: how big should a chunk '
          'be? A reasonable starting point is a few hundred tokens — roughly '
          'three hundred to five hundred — with ten to twenty percent '
          'overlap, and that starting point should shift with what the '
          'corpus actually looks like. A help-centre FAQ\'s natural unit is a '
          'short question-and-answer pair; a legal contract\'s natural unit '
          'might be an entire clause running to a thousand tokens that '
          'genuinely should not be split mid-clause regardless of what a '
          'generic default says. The right chunk size is a property of the '
          'content\'s natural granularity, not a universal constant.',
        ),
        ProseBlock(
          'The only way to know whether a specific chunking decision was '
          'actually a good one is a retrieval evaluation, not a demo that '
          'happened to look fine on three hand-picked questions. Build a '
          'small labelled set of real queries paired with the chunk (or '
          'source passage) that should answer each one — a few dozen pairs '
          'is enough to start distinguishing configurations. Run that set '
          'against every chunking configuration under consideration, and '
          'measure recall@k (did the right chunk appear anywhere in the '
          'top-k results?) and mean reciprocal rank, or MRR (how close to '
          'rank one did it land, on average, across all the queries where it '
          'was found?). A configuration that only wins on recall while '
          'consistently ranking the right answer at position three is often '
          'worse in practice than one with slightly lower recall but a '
          'rank-one hit, because most systems only pass a handful of top '
          'results into the LLM\'s prompt.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
# Two chunking configs evaluated against the same 4 labelled queries.
# Each entry: the chunk id that should have answered the query, and the
# ranked list of chunk ids actually retrieved (best match first).
configs = {
    "small_chunks_200tok": {
        "q1": {"relevant": "c14", "retrieved": ["c14", "c02", "c31"]},
        "q2": {"relevant": "c07", "retrieved": ["c22", "c07", "c03"]},
        "q3": {"relevant": "c19", "retrieved": ["c05", "c11", "c02"]},
        "q4": {"relevant": "c26", "retrieved": ["c26", "c09", "c15"]},
    },
    "large_chunks_800tok": {
        "q1": {"relevant": "c04", "retrieved": ["c01", "c12", "c04"]},
        "q2": {"relevant": "c02", "retrieved": ["c07", "c02", "c01"]},
        "q3": {"relevant": "c06", "retrieved": ["c01", "c06", "c03"]},
        "q4": {"relevant": "c09", "retrieved": ["c02", "c09", "c04"]},
    },
}


def recall_at_k(results):
    hits = sum(1 for r in results.values() if r["relevant"] in r["retrieved"])
    return hits / len(results)


def mrr(results):
    total = 0.0
    for r in results.values():
        if r["relevant"] in r["retrieved"]:
            rank = r["retrieved"].index(r["relevant"]) + 1
            total += 1.0 / rank
    return total / len(results)


for name, results in configs.items():
    print(name, "recall@3 =", round(recall_at_k(results), 2), "MRR =", round(mrr(results), 3))

# small_chunks_200tok recall@3 = 0.75 MRR = 0.625
# large_chunks_800tok recall@3 = 1.0  MRR = 0.458
#
# Large chunks technically win on recall -- the right chunk always shows up
# somewhere in the top 3 -- but it usually lands at rank 2 or 3, diluted by
# topically-adjacent content in the same oversized chunk. Small chunks miss
# one query outright but rank the right answer first far more often. Which
# config is "better" depends on how many top-k results the prompt actually
# uses -- exactly the kind of tradeoff eyeballing a chat transcript won't
# reveal.
''',
          caption:
              'Recall@k and MRR can disagree about which configuration is '
              'better — that disagreement is the whole point of measuring '
              'both rather than picking one number and calling it done.',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Don\'t tune chunking by grading the final answer',
          text:
              'Judging chunk size only by whether the LLM\'s final answer '
              'looked right conflates two separate systems: the retriever, '
              'which decides what the LLM sees, and the generator, which '
              'decides what to do with it. A strong generator can produce a '
              'correct-sounding answer even from a mediocre chunk by leaning '
              'on its own parametric knowledge — which defeats the purpose '
              'of retrieval and hides a real chunking problem behind an '
              'answer that happens to look fine. Measuring recall and rank '
              'directly against a labelled set isolates the retrieval step '
              'so it can be evaluated on its own.',
        ),
        CollapsibleBlock(
          title: 'Deep dive: chunking decisions interact with the retrieval index',
          children: [
            ProseBlock(
              'Chunk size does not only affect what one chunk contains — it '
              'affects how many vectors the index must store and search. A '
              'corpus of 100,000 documents chunked into 300-token pieces '
              'might produce 500,000 vectors; the same corpus at 800-token '
              'chunks might produce 200,000. Fewer vectors means a smaller, '
              'faster index, but each vector now represents a broader span '
              'of text, so individual retrieval precision drops. This is a '
              'deeper tradeoff than "what size produces coherent chunks" — '
              'it is a direct lever on the recall/latency tradeoff of the '
              'ANN index underneath.',
            ),
            ProseBlock(
              'For production systems, the chunking strategy also interacts '
              'with the metadata filtering layer. If chunks carry metadata '
              '(document title, section, date), a well-crafted filter can '
              'narrow the search space before similarity scoring runs. This '
              'changes the calculus: with strong metadata filtering, you can '
              'use smaller chunks because the filter already ensures topical '
              'relevance, and the embedding only needs to fine-rank within a '
              'narrow band. Without filtering, larger chunks are safer '
              'because the retriever\'s only signal is the embedding itself. '
              'This is why vector databases that support hybrid filtering '
              '(Pinecone, Weaviate) tend to work better with smaller chunks '
              'than bare FAISS indexes.',
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
      id: 'ex-chunk-fixed-overlap',
      title: 'Fixed-size chunking with overlap',
      prompt: [
        ProseBlock(
          'Implement chunk_fixed(text, chunk_size, overlap=0) so that it '
          'splits text into chunks of at most chunk_size characters, where '
          'each chunk after the first begins overlap characters before the '
          'previous chunk ended. Guard against overlap being greater than or '
          'equal to chunk_size before the loop runs, rather than letting it '
          'fail silently.',
        ),
        ProseBlock(
          'Run the function on the given passage with overlap=0 and again '
          'with overlap=20, and compare where words land relative to chunk '
          'boundaries in each case.',
        ),
      ],
      starterCode: '''
text = (
    "RAG retrieves relevant passages before generating an answer. "
    "Chunking decides what a passage means. Overlap between neighbouring "
    "chunks exists so information straddling a boundary is not lost."
)


def chunk_fixed(text, chunk_size, overlap=0):
    """Split text into chunks of at most chunk_size characters, where each
    chunk after the first starts `overlap` characters before the previous
    one ended. Raise ValueError if overlap >= chunk_size."""
    ...


for c in chunk_fixed(text, 80, overlap=0):
    print(repr(c))

print("--- with overlap ---")
for c in chunk_fixed(text, 80, overlap=20):
    print(repr(c))
''',
      solutionCode: '''
text = (
    "RAG retrieves relevant passages before generating an answer. "
    "Chunking decides what a passage means. Overlap between neighbouring "
    "chunks exists so information straddling a boundary is not lost."
)


def chunk_fixed(text, chunk_size, overlap=0):
    """Split text into chunks of at most chunk_size characters, where each
    chunk after the first starts `overlap` characters before the previous
    one ended. Raise ValueError if overlap >= chunk_size."""
    if overlap >= chunk_size:
        raise ValueError("overlap must be smaller than chunk_size")

    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        if end >= len(text):
            break
        start = end - overlap
    return chunks


for c in chunk_fixed(text, 80, overlap=0):
    print(repr(c))
# 'RAG retrieves relevant passages before generating an answer. Chunking decides wh'
# 'at a passage means. Overlap between neighbouring chunks exists so information st'
# 'raddling a boundary is not lost.'

print("--- with overlap ---")
for c in chunk_fixed(text, 80, overlap=20):
    print(repr(c))
# 'RAG retrieves relevant passages before generating an answer. Chunking decides wh'
# ' Chunking decides what a passage means. Overlap between neighbouring chunks exis'
# 'hbouring chunks exists so information straddling a boundary is not lost.'
#
# "straddling" is now whole in chunk 3 instead of being cut in half -- but
# "Chunking decides" and "hbouring chunks exists" each now appear, in full
# or in part, in two chunks instead of one.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why does slicing text[start:end] on raw character counts '
              'routinely cut a chunk mid-word, and why doesn\'t simply '
              'raising chunk_size fix that in general?',
          expectedAnswer:
              'Raw character counting has no notion of a word or sentence '
              'boundary — it counts characters up to chunk_size and stops '
              'wherever that lands, whether or not that position happens to '
              'be inside a word. Raising chunk_size only moves the cut point '
              'further along the text; some boundary will still fall inside '
              'a word for essentially any fixed size, unless the source '
              'text\'s natural unit lengths happen to divide evenly into '
              'that size, which cannot be relied on for real prose. Fixing '
              'this requires a structural approach — recursive or semantic '
              'splitting — not a bigger number.',
        ),
        SelfCheckQuestion(
          question:
              'What happens if overlap is set equal to chunk_size, and what '
              'does the ValueError guard in the solution actually prevent?',
          expectedAnswer:
              'The loop advances with `start = end - overlap`. If overlap '
              'equals chunk_size, that becomes `start = (start + chunk_size) '
              '- chunk_size = start` — start never advances, end never '
              'changes relative to it, and the function emits the exact '
              'same chunk forever, an infinite loop that would hang whatever '
              'called it. The guard raises immediately instead of letting '
              'the function run until something external kills it, which is '
              'exactly the kind of invariant check the lesson\'s fixed-size '
              'section flags as necessary before shipping a chunker.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-chunk-recursive',
      title: 'Recursive splitting with separator fallback',
      prompt: [
        ProseBlock(
          'Implement recursive_split(text, chunk_size, separators) that '
          'tries the first separator in the list, merges consecutive pieces '
          'into a running chunk for as long as the merged length stays '
          'under chunk_size, and recurses into any single piece that is '
          'still too big on its own using the next separator down the list.',
        ),
        ProseBlock(
          'Test it against the given two-paragraph passage with '
          'chunk_size=150 and separators=["\\n\\n", "\\n", ". ", " ", ""], and '
          'confirm the short first paragraph survives as one untouched '
          'chunk while the longer second paragraph gets pushed down to a '
          'word-level split.',
        ),
      ],
      starterCode: '''
text = """Vector indexes trade recall for speed. IVF clusters vectors ahead of time and searches only the nearest few clusters at query time.

HNSW builds a multi-layer graph instead and walks it greedily from a sparse top layer down to a dense bottom layer, usually beating IVF on recall per millisecond at the cost of a larger memory footprint for the graph itself."""

separators = ["\\n\\n", "\\n", ". ", " ", ""]


def recursive_split(text, chunk_size, separators):
    """Split text using the first separator; recurse into any piece that
    is still too big on its own using the next separator down the list."""
    ...


for i, c in enumerate(recursive_split(text, 150, separators)):
    print(i, len(c), repr(c))
''',
      solutionCode: '''
text = """Vector indexes trade recall for speed. IVF clusters vectors ahead of time and searches only the nearest few clusters at query time.

HNSW builds a multi-layer graph instead and walks it greedily from a sparse top layer down to a dense bottom layer, usually beating IVF on recall per millisecond at the cost of a larger memory footprint for the graph itself."""

separators = ["\\n\\n", "\\n", ". ", " ", ""]


def recursive_split(text, chunk_size, separators):
    """Split text using the first separator; recurse into any piece that
    is still too big on its own using the next separator down the list."""
    sep = separators[0]
    rest = separators[1:]
    pieces = list(text) if sep == "" else text.split(sep)

    chunks = []
    current = ""
    for piece in pieces:
        candidate = current + (sep if current else "") + piece
        if len(candidate) <= chunk_size:
            current = candidate
        else:
            if current:
                chunks.append(current)
            if len(piece) > chunk_size and rest:
                chunks.extend(recursive_split(piece, chunk_size, rest))
                current = ""
            else:
                current = piece
    if current:
        chunks.append(current)
    return chunks


for i, c in enumerate(recursive_split(text, 150, separators)):
    print(i, len(c), repr(c))

# 0 131 'Vector indexes trade recall for speed. IVF clusters vectors ahead of time and searches only the nearest few clusters at query time.'
# 1 149 'HNSW builds a multi-layer graph instead and walks it greedily from a sparse top layer down to a dense bottom layer, usually beating IVF on recall per'
# 2 74  'millisecond at the cost of a larger memory footprint for the graph itself.'
#
# Paragraph 1 (131 chars) fits under 150 and is never touched. Paragraph 2
# has no ". " break at all until its very end, so recursion falls all the
# way to word-level splitting for it -- and only for it.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'The final separator in the list is the empty string "", '
              'which splits into individual characters. Why is that a '
              'necessary fallback rather than a wasted case that never '
              'triggers?',
          expectedAnswer:
              'A single "word" can itself exceed chunk_size — a long URL, a '
              'hash, a run-on identifier with no internal spaces — and every '
              'separator above it in the list (paragraph, sentence, word) '
              'would fail to produce anything smaller than the offending '
              'piece, since none of those characters appear inside it. '
              'Falling back to individual characters guarantees the '
              'function terminates with every chunk at or under chunk_size '
              'no matter what the input contains, even though character-'
              'level splitting is exactly the crude behaviour recursive '
              'splitting exists to avoid in the common case.',
        ),
        SelfCheckQuestion(
          question:
              'Paragraph one fit inside a single chunk untouched. What '
              'would have to be true about it for that not to happen, and '
              'should it be split in that case?',
          expectedAnswer:
              'It would have to exceed chunk_size on its own — true for any '
              'paragraph long enough, which is entirely possible in real '
              'documents. In that case yes, it should be split, because the '
              'whole point of recursive splitting is keeping every chunk '
              'under the size the embedding model and retrieval budget can '
              'handle, regardless of which paragraph it came from. The '
              'algorithm handles this correctly by construction: it only '
              'recurses into a piece when that piece alone does not fit, so '
              'a short paragraph is left alone and a long one is pushed down '
              'to the next separator automatically.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-chunk-semantic',
      title: 'Finding chunk boundaries from a similarity discontinuity',
      prompt: [
        ProseBlock(
          'Given six toy sentence embeddings that form three topic groups, '
          'compute the cosine similarity between every adjacent pair, then '
          'implement semantic_boundaries(vectors, threshold) that returns '
          'the indices after which similarity drops below threshold — the '
          'points a semantic chunker would cut.',
        ),
        ProseBlock(
          'Use those boundary indices to assemble the three groups of '
          'sentence indices, and confirm that a single fixed threshold of '
          '0.5 cleanly recovers all three topics from this toy corpus.',
        ),
      ],
      starterCode: '''
import numpy as np

sentences = [
    "Chunk size determines how many ideas end up in one embedding.",       # 0 - sizing
    "Bigger chunks blur several topics into a single averaged vector.",    # 1 - sizing
    "Overlap repeats a chunk's tail at the start of the next chunk.",      # 2 - overlap
    "Repeating text this way protects facts sitting near a boundary.",     # 3 - overlap
    "A retrieval eval measures recall at k against labelled queries.",     # 4 - evaluation
    "Mean reciprocal rank checks how high the right chunk actually lands.",# 5 - evaluation
]

vectors = np.array([
    [0.90, 0.05, 0.05, 0.00],
    [0.88, 0.08, 0.04, 0.00],
    [0.10, 0.85, 0.05, 0.00],
    [0.12, 0.83, 0.05, 0.00],
    [0.05, 0.05, 0.10, 0.85],
    [0.06, 0.04, 0.10, 0.88],
])


def cosine_similarity(a, b):
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))


def semantic_boundaries(vectors, threshold):
    """Return the list of indices i such that similarity(vectors[i], vectors[i+1])
    is below threshold -- a boundary falls right after sentence i."""
    ...


def group_sentences(n, boundaries):
    """Turn boundary indices into a list of contiguous index groups."""
    ...


boundaries = semantic_boundaries(vectors, threshold=0.5)
print("boundaries:", boundaries)
print("groups:", group_sentences(len(sentences), boundaries))
''',
      solutionCode: '''
import numpy as np

sentences = [
    "Chunk size determines how many ideas end up in one embedding.",       # 0 - sizing
    "Bigger chunks blur several topics into a single averaged vector.",    # 1 - sizing
    "Overlap repeats a chunk's tail at the start of the next chunk.",      # 2 - overlap
    "Repeating text this way protects facts sitting near a boundary.",     # 3 - overlap
    "A retrieval eval measures recall at k against labelled queries.",     # 4 - evaluation
    "Mean reciprocal rank checks how high the right chunk actually lands.",# 5 - evaluation
]

vectors = np.array([
    [0.90, 0.05, 0.05, 0.00],
    [0.88, 0.08, 0.04, 0.00],
    [0.10, 0.85, 0.05, 0.00],
    [0.12, 0.83, 0.05, 0.00],
    [0.05, 0.05, 0.10, 0.85],
    [0.06, 0.04, 0.10, 0.88],
])


def cosine_similarity(a, b):
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))


def semantic_boundaries(vectors, threshold):
    """Return the list of indices i such that similarity(vectors[i], vectors[i+1])
    is below threshold -- a boundary falls right after sentence i."""
    sims = [cosine_similarity(vectors[i], vectors[i + 1]) for i in range(len(vectors) - 1)]
    return [i for i, s in enumerate(sims) if s < threshold]


def group_sentences(n, boundaries):
    """Turn boundary indices into a list of contiguous index groups."""
    groups = []
    start = 0
    for b in boundaries:
        groups.append(list(range(start, b + 1)))
        start = b + 1
    groups.append(list(range(start, n)))
    return groups


boundaries = semantic_boundaries(vectors, threshold=0.5)
print("boundaries:", boundaries)
# boundaries: [1, 3]

print("groups:", group_sentences(len(sentences), boundaries))
# groups: [[0, 1], [2, 3], [4, 5]]
#
# Sizing (0-1), overlap (2-3) and evaluation (4-5) come back as exactly the
# three clusters a human would draw, because adjacent-pair similarity within
# each topic is ~0.999-1.0 while across topics it drops to ~0.07-0.21.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'This toy example uses a single fixed similarity threshold of '
              '0.5 and it works cleanly. Why might a single fixed threshold '
              'be fragile on a real, heterogeneous corpus, and what does the '
              'lesson suggest instead?',
          expectedAnswer:
              'A fixed absolute threshold assumes every adjacent-sentence '
              'similarity in the corpus lives on the same scale, but that '
              'scale depends on the embedding model, the domain, and even '
              'the writing style of a particular document — a threshold '
              'tuned on formal technical prose can be far too strict or far '
              'too loose on a conversational transcript, where "normal" '
              'adjacent-sentence similarity is lower to begin with even '
              'within one topic. The lesson\'s alternative is a relative, '
              'percentile-based cutoff: compute the distribution of '
              'adjacent-pair similarities within a document and split at, '
              'say, the largest few percent of drops, which adapts to '
              'whatever "normal" looks like for that specific document '
              'instead of assuming one global number works everywhere.',
        ),
        SelfCheckQuestion(
          question:
              'Semantic chunking requires an embedding call for every '
              'sentence before a single chunk boundary is decided. What '
              'does that cost compared to recursive splitting, and when is '
              'it worth paying?',
          expectedAnswer:
              'Recursive splitting is pure string manipulation — no model '
              'calls, effectively instant even on a huge corpus. Semantic '
              'chunking needs one embedding-model call per sentence (or '
              'small window) purely to decide where to cut, before those '
              'same chunks get embedded again for the retrieval index — on '
              'a million-sentence corpus that is a million extra calls '
              'spent only on segmentation. It is worth paying for documents '
              'with real, unpredictable topic shifts — long reports, '
              'meeting transcripts, mixed FAQ dumps — where a fixed-size or '
              'recursive cut is likely to land mid-topic. It is wasted cost '
              'on already well-structured content, like API reference pages '
              'or a one-topic-per-file wiki, where recursive splitting on '
              'headings already produces coherent chunks for free.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-chunk-metadata-header',
      title: 'Prepend metadata to chunks for structured content',
      prompt: [
        ProseBlock(
          'Given a list of table rows (each as a dict) and a list of column '
          'headers, implement chunk_with_headers(rows, headers) that '
          'converts each row into a text string that prepends the header '
          'names to the values. For example, row {"city": "Paris", "pop": 2.1} '
          'with headers ["city", "pop"] becomes "city: Paris | pop: 2.1".',
        ),
        ProseBlock(
          'This is the simplest version of the "prepend context" trick from '
          'the lesson: each row is now a self-contained chunk that reads '
          'correctly in isolation, rather than a disconnected value list.',
        ),
      ],
      starterCode: '''
headers = ["product", "price", "in_stock", "category"]
rows = [
    {"product": "Widget A", "price": 9.99, "in_stock": True, "category": "tools"},
    {"product": "Widget B", "price": 14.50, "in_stock": False, "category": "tools"},
    {"product": "Gadget X", "price": 29.99, "in_stock": True, "category": "electronics"},
]


def chunk_with_headers(rows, headers):
    """Return a list of text strings, one per row, with headers prepended."""
    ...


chunks = chunk_with_headers(rows, headers)
for i, c in enumerate(chunks):
    print(f"chunk {i}: {c}")
''',
      solutionCode: '''
headers = ["product", "price", "in_stock", "category"]
rows = [
    {"product": "Widget A", "price": 9.99, "in_stock": True, "category": "tools"},
    {"product": "Widget B", "price": 14.50, "in_stock": False, "category": "tools"},
    {"product": "Gadget X", "price": 29.99, "in_stock": True, "category": "electronics"},
]


def chunk_with_headers(rows, headers):
    return [
        " | ".join(f"{h}: {row[h]}" for h in headers)
        for row in rows
    ]


chunks = chunk_with_headers(rows, headers)
for i, c in enumerate(chunks):
    print(f"chunk {i}: {c}")

# chunk 0: product: Widget A | price: 9.99 | in_stock: True | category: tools
# chunk 1: product: Widget B | price: 14.5 | in_stock: False | category: tools
# chunk 2: product: Gadget X | price: 29.99 | in_stock: True | category: electronics
#
# Each chunk now reads as a complete sentence that makes sense without
# the surrounding table or column headers for context.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why does prepending headers to each row produce better '
              'retrieval than embedding rows as bare value lists?',
          expectedAnswer:
              'An embedding of a bare value list like "Widget A | 9.99 | '
              'True | tools" loses all semantic connection between the '
              'values and their meaning — the embedding model sees it as a '
              'random string. Prepending headers ("product: Widget A | '
              'price: 9.99") gives the embedding model structured prose it '
              'was actually trained to understand, so "price: 9.99" embeds '
              'near other price-related queries and "category: tools" '
              'embeds near category-related queries. The header acts as a '
              'bridge between the value and the semantic concept.',
        ),
        SelfCheckQuestion(
          question:
              'Each chunk now repeats the header names. For a table with '
              '10,000 rows, that is 10,000 copies of "product | price | '
              'in_stock | category". Is that a real cost, and when is it '
              'worth paying?',
          expectedAnswer:
              'Yes, it is a real cost — the header tokens are stored, '
              'embedded, and indexed with every row, inflating the index '
              'size. For a 10k-row table with 30-character headers, that '
              'is roughly 300k extra characters in the index. It is worth '
              'it when rows are likely to be retrieved individually and '
              'the header context is what makes them interpretable — '
              'nearly always in RAG, since a row retrieved alone without '
              'its headers is useless to the generator. The alternative '
              '(stripping headers to save tokens) saves index space but '
              'guarantees every retrieved row is ambiguous, defeating the '
              'purpose of retrieval entirely.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 240000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Chunking strategies, in about four minutes. Imagine you have '
              'a 500-page cookbook and you need to find every recipe '
              'involving chocolate. You wouldn\'t read the whole book cover '
              'to cover — you\'d flip to the dessert section. Chunking is '
              'deciding where those section boundaries go. Get it wrong and '
              'two things break: chunks too big, and one search result '
              'blends chocolate cake and chicken soup together into a blurry '
              'average; chunks too small, and you find "add the butter" '
              'with no clue which recipe it belongs to.',
          startMs: 0,
          endMs: 40000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'The simplest approach is fixed-size chunking — just count '
              'characters and cut every N characters. It\'s like using a '
              'ruler to slice a loaf of bread: fast and cheap, but blind to '
              'where the crust ends and the soft middle begins. It splits '
              'mid-sentence, mid-table, mid-code-block all the time. Overlap '
              'helps: repeat the last bite of one chunk at the start of the '
              'next, so nothing straddling the cut gets lost. Cost? Bigger '
              'index, and near-duplicate chunks fighting for the same top '
              'spot.',
          startMs: 40000,
          endMs: 80000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Recursive splitting is smarter: try to cut at paragraph breaks '
              'first, then sentences, then words — and only split individual '
              'characters as a last resort. It\'s like cutting a pizza along '
              'natural slice lines instead of with a ruler. LangChain\'s '
              'RecursiveCharacterTextSplitter is the go-to implementation. '
              'The catch? It\'s still just following a length limit — it has '
              'no idea what the text is actually about.',
          startMs: 80000,
          endMs: 120000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'Semantic chunking actually pays attention to meaning. Embed '
              'each sentence, compare adjacent ones by similarity, and cut '
              'where similarity drops sharply — because that\'s where the '
              'topic actually changes. Like noticing when a conversation '
              'switches from sports to politics. The cost? An embedding '
              'call for every sentence before any chunk even exists. Worth '
              'it for messy documents with real topic shifts, overkill for '
              'a corpus that\'s already one clean topic per file.',
          startMs: 120000,
          endMs: 160000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'Structured content — code, tables, Markdown — needs its own '
              'rules entirely. You wouldn\'t slice a Python function in half '
              'just because you hit your character limit, would you? Split '
              'code at function or class boundaries. Split tables row by '
              'row with the header repeated in every chunk. Split Markdown '
              'at headings and carry the heading path forward so a lone '
              'chunk still announces what section it belongs to.',
          startMs: 160000,
          endMs: 200000,
        ),
        PodcastSegment(
          id: 'c6',
          speaker: 'Guest',
          text:
              'Most importantly: don\'t guess your chunk size by eye. Build '
              'a small set of real queries paired with the chunk that '
              'should answer each one. Run them against different chunking '
              'configs and measure recall at k and where the right answer '
              'lands in the ranking. Let data decide, not a demo that '
              'happened to look fine on three hand-picked questions.',
          startMs: 200000,
          endMs: 240000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 480000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'The last two lessons covered what RAG is and how embeddings '
              'and vector search work. Now let\'s zoom into a step that '
              'happens before any of that magic: chunking — splitting '
              'source documents into the units that actually get embedded '
              'and retrieved. Think of it as deciding where to put the '
              'chapter breaks in a giant, unformatted manuscript. Every '
              'retrieval decision downstream inherits whatever chunking '
              'already got right or wrong.',
          startMs: 0,
          endMs: 60000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'Why chunk at all? Simple: embedding models have hard input '
              'limits. Imagine trying to photocopy a whole encyclopedia onto '
              'one sheet of paper — you\'d get a blurry mess. Classic BERT '
              'models cap around 512 tokens; even generous modern retrieval '
              'models top out at a few thousand. Stuff a whole document into '
              'one embedding and you get one blurry average of everything in '
              'it. So something upstream has to decide: what should each '
              'unit actually be?',
          startMs: 60000,
          endMs: 120000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'The granularity tradeoff cuts both ways. Chunks too big? '
              'It\'s like summarizing five different book chapters in one '
              'sentence — the embedding becomes an average over several '
              'unrelated ideas, so it stops being close to any single query '
              'in the vector space. Plus, every retrieval drags surrounding '
              'irrelevant text into the LLM\'s prompt, burning tokens on '
              'stuff nobody asked for. Chunks too small? You find the '
              'exact right sentence but it\'s a dangling pronoun or a table '
              'row with no header — useless without its surrounding context.',
          startMs: 120000,
          endMs: 180000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Fixed-size chunking is the ruler approach: count characters '
              'or tokens, cut, repeat. Cheapest possible option, the natural '
              'first thing anyone reaches for. But it\'s blind — the cut '
              'lands wherever the count says, mid-sentence, mid-table-row, '
              'mid-function-body, with zero regard for what\'s actually '
              'there. It works just often enough to feel fine until you '
              'notice it\'s silently butchering your content.',
          startMs: 180000,
          endMs: 240000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'Overlap patches the worst of that: repeat the tail of one '
              'chunk as the head of the next — typically ten to twenty '
              'percent of chunk size. It\'s like having two camera shots that '
              'slightly overlap so you don\'t miss anything at the seam. '
              'Cost? Every overlapped span is stored and indexed twice, '
              'so your index grows, and near-duplicate chunks can both '
              'surface for the same query, quietly eating two top-k slots '
              'for what\'s effectively the same information.',
          startMs: 240000,
          endMs: 300000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Recursive splitting — LangChain\'s RecursiveCharacterTextSplitter '
              'approach — is the structural upgrade. It tries a prioritised '
              'list of separators: paragraph breaks first, then single '
              'newlines, then sentences, then words, then raw characters as '
              'a last resort. It merges pieces together as long as the '
              'running chunk stays under the size limit, and only recurses '
              'into a single piece when that piece alone is still too big. '
              'Much more structurally coherent than blind counting, but '
              'still fundamentally governed by the same length ceiling.',
          startMs: 300000,
          endMs: 360000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Semantic chunking goes further and actually looks at meaning. '
              'Embed each sentence, compute similarity between every '
              'adjacent pair, and cut wherever similarity drops sharply — '
              'using a percentile threshold rather than one fixed number, '
              'since "normal" similarity varies by document. That\'s a real '
              'embedding call per sentence before a single chunk exists. '
              'Worth it for heterogeneous, topic-shifting documents like '
              'meeting transcripts. Not worth it for a corpus that\'s already '
              'one clean topic per file, where recursive splitting on '
              'headings already does the job for free.',
          startMs: 360000,
          endMs: 420000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'Structured content and picking the actual number go together. '
              'Code, tables and Markdown each deserve dedicated handling — '
              'split by logical unit, not character count. And for choosing '
              'chunk size: start around three hundred to five hundred tokens '
              'with ten to twenty percent overlap, but the number that '
              'actually matters is what a retrieval eval tells you. Run your '
              'queries against a labelled set, measure recall at k and where '
              'the right chunk lands in the ranking. A size that looked fine '
              'in a demo means nothing if the right answer consistently '
              'lands at rank eight.',
          startMs: 420000,
          endMs: 480000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 910000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'Alright, deep dive on chunking strategies. The route: why '
              'chunking exists at all given embedding model limits and the '
              'granularity tradeoff, fixed-size chunking and why overlap exists '
              'and what it costs, recursive splitting and how LangChain\'s '
              'implementation actually decides where to cut, semantic chunking '
              'based on similarity discontinuities and its cost, dedicated '
              'handling for code, tables and Markdown, and finally how to '
              'actually choose and prove a chunk-size decision with a '
              'retrieval eval rather than by eyeballing it.',
          startMs: 0,
          endMs: 65000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start from the hard constraint. Embedding models have a '
              'maximum input length baked into their architecture — like a '
              'scanner that can only handle one page at a time. Classic '
              'BERT-family encoders cap around 512 tokens. Even the generous '
              'modern ones top out in the low thousands. Text longer than '
              'that either gets silently truncated — everything past the '
              'limit is thrown away — or gets pooled into one vector that '
              'has to represent a far longer span than it was trained for. '
              'Either way, a multi-page document cannot be a single '
              'retrievable unit. So something upstream has to decide what '
              'the unit is. That something is chunking.',
          startMs: 65000,
          endMs: 130000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'And it\'s a real tradeoff, not some formality. Chunks too '
              'large, and two things go wrong at once. First, the embedding '
              'becomes an average over several distinct ideas — like trying '
              'to summarize an entire book chapter in one sentence — so it '
              'stops being close to any single query. Second, every time '
              'that chunk is retrieved, all its irrelevant surrounding text '
              'rides along into the LLM\'s prompt, burning real money and '
              'context budget on stuff the question never needed.',
          startMs: 130000,
          endMs: 195000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'Make chunks too small and the failure looks different but '
              'is just as damaging. A fragment can lose its antecedent '
              'pronoun, the header row its data row depends on, the function '
              'signature a code snippet was defined under — so even when '
              'retrieval finds the exactly-right fragment, the LLM receives '
              'something that reads as ambiguous or flatly wrong without '
              'its context. Both failure directions point at the same truth: '
              'a chunk is supposed to be a coherent, self-contained unit of '
              'meaning, and picking its size is picking how ambitious that '
              'coherence claim is allowed to be.',
          startMs: 195000,
          endMs: 260000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'The simplest implementation is fixed-size chunking: pick a '
              'number, slice the document into consecutive pieces, done. '
              'It\'s like using a ruler to cut a loaf of bread — costs '
              'nothing computationally, trivial to implement, a completely '
              'reasonable baseline. Its failure mode is equally simple: the '
              'cut lands wherever the count says, with zero awareness of '
              'what\'s at that position — mid-word, mid-sentence, halfway '
              'through a table row or a function body. On real prose this '
              'happens at nearly every boundary, not as a rare edge case.',
          startMs: 260000,
          endMs: 325000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Overlap is the standard patch: repeat the tail of chunk N — '
              'typically ten to twenty percent — as the head of chunk N+1, '
              'so anything straddling the boundary survives intact somewhere. '
              'Like having two panoramic photos with a slight overlap so '
              'nothing falls through the crack. Not free: every overlapped '
              'span is stored, embedded and indexed twice, inflating index '
              'size, and two overlapping chunks covering the same underlying '
              'fact can both surface for a query, silently consuming two '
              'slots of a fixed top-k budget for duplicate information.',
          startMs: 325000,
          endMs: 390000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'Recursive splitting is the structural upgrade, and LangChain\'s '
              'RecursiveCharacterTextSplitter is the reference implementation. '
              'It holds a prioritised list of separators — paragraph breaks, '
              'then single newlines, then sentence-ish breaks, then spaces, '
              'and finally the empty string as last resort. It tries the '
              'first separator, merges pieces back together into a running '
              'chunk as long as it stays under the size limit. Only when a '
              'single piece is still too big on its own does it recurse into '
              'that one piece using the next separator down. It\'s like '
              'cutting along natural folds in the paper instead of with a '
              'ruler.',
          startMs: 390000,
          endMs: 455000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'The behaviour that falls out is worth appreciating. A short '
              'paragraph that fits under the limit survives completely '
              'untouched. Only the long paragraph next to it gets pushed '
              'down into sentence-level or word-level splitting. Recursive '
              'splitting applies just enough force, in just the place that '
              'needs it, to keep every chunk under the ceiling. Meaningfully '
              'better than fixed-size for almost no extra engineering cost — '
              'which is exactly why it\'s the default most tooling reaches '
              'for first.',
          startMs: 455000,
          endMs: 520000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'It\'s still, underneath all of that, governed by a length '
              'threshold and a fixed list of separator characters — no '
              'notion of what the text actually means, only where whitespace '
              'and punctuation happen to sit. Two adjacent sentences about '
              'completely unrelated topics can get merged into one chunk '
              'just as readily as two that genuinely belong together, as '
              'long as the character count allows it. That gap is what '
              'semantic chunking addresses.',
          startMs: 520000,
          endMs: 585000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Semantic chunking embeds each sentence and computes similarity '
              'between every adjacent pair. Where two neighbours are highly '
              'similar, they almost certainly belong in the same chunk. '
              'Where similarity drops sharply, that\'s a real topic boundary. '
              'It\'s like noticing when a podcast conversation suddenly '
              'switches from sports to politics — there\'s a natural break '
              'point. The threshold is usually a percentile of the similarity '
              'drops rather than one fixed number, since "normal" similarity '
              'varies by embedding model and document style.',
          startMs: 585000,
          endMs: 650000,
        ),
        PodcastSegment(
          id: 'd11',
          speaker: 'Host',
          text:
              'The cost is direct and unavoidable: deciding where to cut '
              'now requires an embedding-model call for every sentence in '
              'the corpus, before those same chunks get embedded again for '
              'the actual retrieval index. On a million-sentence corpus '
              'that\'s a million extra calls purely for segmentation. It '
              'earns that cost on documents with real, unpredictable topic '
              'drift — long reports, meeting transcripts, forum threads. It '
              'buys almost nothing on a corpus that\'s already one clean '
              'topic per file, where recursive splitting on headings already '
              'produces coherent chunks for free.',
          startMs: 650000,
          endMs: 715000,
        ),
        PodcastSegment(
          id: 'd12',
          speaker: 'Guest',
          text:
              'Structured content deserves dedicated handling regardless of '
              'which splitter does the rest of the work. None of '
              'character-count, recursive, or plain semantic splitting '
              'understands code, tables, or Markdown as anything but raw '
              'strings. You wouldn\'t slice a Python function in half '
              'mid-body just because you hit 500 characters — split code at '
              'function or class boundaries. Tables? Chunk row by row with '
              'the header repeated into every chunk so a single retrieved '
              'row still carries the column names that make it meaningful. '
              'Markdown? Split at heading boundaries and carry the full '
              'heading path as a prefix on every chunk beneath it.',
          startMs: 715000,
          endMs: 780000,
        ),
        PodcastSegment(
          id: 'd13',
          speaker: 'Host',
          text:
              'None of this matters if the chunk size and overlap were '
              'picked by eye. A reasonable starting point is roughly three '
              'hundred to five hundred tokens with ten to twenty percent '
              'overlap, and that number should shift with the corpus — a '
              'FAQ\'s natural unit is a short Q&A pair, while a legal '
              'contract\'s natural unit might be an entire clause running '
              'to a thousand tokens that genuinely shouldn\'t be split '
              'mid-clause no matter what a generic default says.',
          startMs: 780000,
          endMs: 845000,
        ),
        PodcastSegment(
          id: 'd14',
          speaker: 'Guest',
          text:
              'The only way to know whether a chunking decision was '
              'actually good is a retrieval eval, not a demo that looked '
              'fine on three hand-picked questions. Build a small labelled '
              'set of real queries paired with the chunk that should answer '
              'each one. Run against every config under consideration and '
              'measure recall at k and where the correct chunk lands in '
              'the ranking — not just whether it appears somewhere in the '
              'top ten, but whether it\'s landing near rank one, where the '
              'LLM actually pays attention. Higher recall with a '
              'consistently worse rank can be the worse choice once you '
              'account for what the generator reads first — a tradeoff '
              'eyeballing a transcript will never reveal.',
          startMs: 845000,
          endMs: 910000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'Chunk size is a tradeoff, not a formality',
      body:
          'Embedding models cap the input they can accept, which forces '
          'chunking to exist at all, but the harder problem is granularity: '
          'chunks too large average several ideas into one vector and bloat '
          'the LLM\'s context on retrieval; chunks too small lose the '
          'surrounding context that makes them interpretable. Chunk size is '
          'choosing how coherent and how self-contained each retrievable '
          'unit is allowed to be.',
    ),
    SummaryCard(
      title: 'Splitting strategy decides what survives a boundary',
      body:
          'Fixed-size chunking cuts on raw character or token counts and '
          'ignores structure entirely. Recursive splitting tries paragraph, '
          'then sentence, then word separators in order, applying force only '
          'where a piece is actually too big. Semantic chunking cuts at '
          'embedding-similarity discontinuities between adjacent sentences, '
          'at the cost of an embedding call per sentence. Overlap protects '
          'content straddling a boundary, at the cost of duplicated storage '
          'and near-duplicate retrieval.',
    ),
    SummaryCard(
      title:
          'Structured content needs its own rule, and the right size is measured',
      body:
          'Code, tables and Markdown should be chunked by logical unit — '
          'function, row-with-header, heading section — not by raw length. '
          'The right chunk size and overlap for a corpus should come from a '
          'retrieval eval measuring recall@k and MRR against a labelled '
          'query set, not from picking a default and checking that a few '
          'demo questions look fine.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'Chunk',
      definition:
          'A contiguous span of a source document treated as one '
          'retrievable unit: embedded once, stored once, and retrieved or '
          'skipped as a whole. Its boundaries are decided once, offline, '
          'before any query arrives.',
    ),
    KeyConcept(
      term: 'Chunk overlap',
      definition:
          'A deliberate repetition of text between the end of one chunk and '
          'the start of the next, so information straddling the boundary '
          'survives whole in at least one chunk. Typically ten to twenty '
          'percent of the chunk size; costs extra storage and can produce '
          'near-duplicate retrieval results.',
    ),
    KeyConcept(
      term: 'Recursive character/token splitting',
      definition:
          'A splitting strategy that tries a prioritised list of separators '
          '(paragraphs, then sentences, then words, then characters), '
          'merging pieces up to a size limit and recursing into only the '
          'pieces that are still too big. LangChain\'s '
          'RecursiveCharacterTextSplitter is the standard implementation.',
    ),
    KeyConcept(
      term: 'Semantic chunking',
      definition:
          'A splitting strategy that embeds adjacent sentences (or small '
          'windows) and cuts where similarity between neighbours drops '
          'sharply, treating that discontinuity as a topic boundary. More '
          'expensive than recursive splitting because it requires an '
          'embedding call per sentence at indexing time.',
    ),
    KeyConcept(
      term: 'Structure-aware chunking',
      definition:
          'Chunking that respects the logical units of non-prose content — '
          'splitting code at function or class boundaries, tables row by '
          'row with the header repeated into each chunk, and Markdown at '
          'heading boundaries with the heading path carried forward as '
          'context.',
    ),
    KeyConcept(
      term: 'Recall@k and MRR',
      definition:
          'Retrieval evaluation metrics used to compare chunking '
          'configurations objectively: recall@k measures whether the '
          'correct chunk appears anywhere in the top-k results; mean '
          'reciprocal rank (MRR) measures how close to rank one it lands on '
          'average, which recall@k alone cannot distinguish.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake:
          'Copying a chunk-size default from a blog post or library example '
          'without testing it against the actual corpus.',
      correction:
          'A default like 300-500 tokens with 10-20% overlap is a '
          'reasonable starting point, not a universal answer — a FAQ '
          'corpus\'s natural unit is a short Q&A pair, a legal corpus\'s '
          'might be a full clause. Validate any starting default against a '
          'labelled retrieval eval for the specific corpus before treating '
          'it as final.',
    ),
    Mistake(
      mistake:
          'Increasing chunk overlap whenever retrieval quality disappoints, '
          'treating it as a free lever.',
      correction:
          'Overlap only protects information straddling a single chunk '
          'boundary — it does nothing for a chunk that is simply too small '
          'to be coherent on its own. Meanwhile every added percentage '
          'point of overlap increases index size and the odds that two '
          'overlapping chunks both occupy top-k slots for the same '
          'underlying fact. Diagnose whether the real problem is boundary '
          'placement or chunk granularity before reaching for overlap.',
    ),
    Mistake(
      mistake:
          'Running code, tables or Markdown through the same character-'
          'count or recursive prose splitter used for everything else.',
      correction:
          'Generic separators like blank lines and periods mean nothing '
          'inside a function body or a table row, so a generic splitter '
          'will cut through both. Use a language-aware code splitter, chunk '
          'tables row by row with the header repeated into each chunk, and '
          'split Markdown at heading boundaries with the heading path '
          'carried forward as a prefix.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question:
          'Why does chunk size matter to a RAG system\'s final answer '
          'quality, not just to indexing throughput?',
      answer:
          'Chunk size controls two things retrieval quality depends on '
          'directly. First, what a single embedding represents: a chunk '
          'spanning several ideas produces an averaged vector that sits '
          'close to none of the individual queries that should have matched '
          'it, so oversized chunks quietly lower recall even though nothing '
          'about the retrieval algorithm changed. Second, what the LLM '
          'actually receives after retrieval: an oversized chunk drags '
          'irrelevant text into the prompt alongside the relevant sentence, '
          'spending context budget and money on text the question did not '
          'need, while an undersized chunk can strip away the context — an '
          'antecedent, a header, a function signature — that made the '
          'retrieved fragment interpretable in the first place. Chunk size '
          'is therefore not a preprocessing detail; it directly shapes both '
          'whether the right information gets found and whether the '
          'generator can actually use it once it has.',
    ),
    InterviewQuestion(
      question:
          'Walk through how a recursive character splitter decides where '
          'to cut a paragraph that exceeds the chunk-size limit.',
      answer:
          'It starts with a prioritised list of separators — typically '
          'paragraph breaks, then single newlines, then sentence-level '
          'breaks, then spaces, then the empty string as a last resort. It '
          'splits the input on the first separator and tries to merge the '
          'resulting pieces back together into a running chunk, adding one '
          'piece at a time as long as the merged length stays under the '
          'chunk-size limit. If a single piece is still too big on its own '
          'even before merging — say, one paragraph longer than the limit — '
          'the splitter does not just cut it at the limit; it recurses into '
          'that one piece using the next separator down the list, splitting '
          'it into sentences and repeating the same merge-until-full logic '
          'at that finer granularity. This continues, dropping to word-'
          'level and finally character-level splitting only if nothing '
          'coarser produces a piece small enough. The key behavior is that '
          'this recursion is applied selectively — a short paragraph is '
          'left completely untouched while only the oversized paragraph '
          'next to it gets pushed down to a finer separator, so the '
          'splitter applies just enough force in just the place it is '
          'needed.',
    ),
    InterviewQuestion(
      question:
          'When would you choose semantic chunking over recursive '
          'splitting, and what does that choice actually cost?',
      answer:
          'Semantic chunking earns its cost on documents where topic '
          'boundaries do not line up with punctuation — long reports that '
          'drift across subjects within a single paragraph, meeting '
          'transcripts, forum threads, or any corpus where a fixed-size or '
          'recursive cut is likely to land mid-topic simply because nothing '
          'in the surface structure signalled the shift. It buys very '
          'little on already well-structured content — API reference pages, '
          'a wiki with one topic per file — where recursive splitting on '
          'paragraph and heading boundaries already produces coherent '
          'chunks for free. The cost is concrete and unavoidable: semantic '
          'chunking requires an embedding-model call for every sentence, or '
          'every small window of sentences, purely to decide where to cut, '
          'before those same chunks get embedded again for the actual '
          'retrieval index. On a large corpus that doubles the embedding '
          'workload at indexing time and adds real latency to the indexing '
          'pipeline, compared to recursive splitting, which is pure string '
          'manipulation and effectively free. I would default to recursive '
          'splitting and only reach for semantic chunking after confirming, '
          'via a retrieval eval, that boundary placement is actually the '
          'bottleneck.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title:
        'Splitting recursively — Text splitter integration guide, LangChain Docs',
    url:
        'https://docs.langchain.com/oss/python/integrations/splitters/recursive_text_splitter',
    description:
        'LangChain\'s own documentation for RecursiveCharacterTextSplitter, '
        'including the default separator list and the chunk_size / '
        'chunk_overlap parameters this lesson\'s recursive-splitting section '
        'and exercise are modelled on.',
  ),
  Source(
    title: 'Chunking Strategies for LLM Applications — Pinecone Learn',
    url: 'https://www.pinecone.io/learn/chunking-strategies/',
    description:
        'A practitioner survey of fixed-size, recursive and semantic '
        'chunking approaches for RAG, used to cross-check the tradeoffs and '
        'default overlap ratios described across this lesson.',
  ),
  Source(
    title:
        'Meta-Chunking: Learning Text Segmentation and Semantic Completion '
        'via Logical Perception (Zhao et al., 2024)',
    url: 'https://arxiv.org/abs/2410.12788',
    description:
        'An arXiv paper analysing similarity-based semantic chunking and '
        'its limitations, backing the semantic-chunking mechanism and cost '
        'discussion in this lesson.',
  ),
];

const List<Source> _furtherReading = <Source>[
  Source(
    title: 'Chunking Strategies for RAG: A Deep Dive — LlamaIndex Blog',
    url: 'https://www.llamaindex.ai/blog/evaluating-the-ideal-chunk-size-for-a-rag-system-using-llamaindex',
    description:
        'Empirical evaluation of chunk sizes (256, 512, 1024 tokens) across retrieval benchmarks, '
        'showing how chunk size affects faithfulness and relevancy metrics in production RAG.',
  ),
  Source(
    title: 'LangChain Text Splitters: Semantics, Markdown, and Code',
    url: 'https://python.langchain.com/docs/how_to/#text-splitters',
    description:
        'Official LangChain guide to all built-in text splitters including Markdown-header-aware, '
        'code-language-aware, and semantic chunking options used in real pipelines.',
  ),
  Source(
    title: 'Semantic Chunking for RAG — Weaviate Blog',
    url: 'https://weaviate.io/blog/semantic-chunking-for-rag',
    description:
        'Step-by-step guide to implementing semantic chunking with embedding similarity, '
        'including percentile-based thresholding and adaptive breakpoint detection.',
  ),
  Source(
    title: 'Llamaindex Node Parser: Structured Content Chunking',
    url: 'https://docs.llamaindex.ai/en/stable/module_guides/loading/node_parsers/',
    description:
        'Documentation on LlamaIndex\'s node parsers for HTML, JSON, and Markdown, '
        'showing structured-content-aware chunking patterns for tables and code.',
  ),
];
