# Known issues

Deliberate simplifications with a real ceiling. Each entry says what was done,
why, and what would break it.

## The "Includes" mode facet cannot discriminate the shipped catalogue

`Lesson.hasMode` defines a mode as *present* when its payload is non-empty
(`practice.exercises.isNotEmpty`, and so on). That is the only signal the model
currently carries — there is no per-lesson "modes offered" field.

`lib/sample_data/sample_lesson.dart` ships one lesson, and it populates all four
modes. So in the running app the mode chips are always a no-op: selecting
"Practice" narrows nothing, because nothing lacks practice content. The facet is
correct and unit-tested against synthetic lessons
(`test/search_filter_test.dart`), but it is untested against real content.

**Breaks when:** the catalogue grows and someone assumes an empty payload means
"mode deliberately withheld" rather than "content not written yet". If that
distinction ever matters, `Lesson` needs an explicit `availableModes` field and
`hasMode` should read that instead of inferring from emptiness.

## Search is not debounced

`ShellSearchField` calls `SearchFilterProvider.setQuery` on every keystroke, and
`TopicListScreen` re-walks the whole catalogue on every notify. That is free at
the current size (one topic, one lesson) and stays fine into the low thousands
of lessons.

**Breaks when:** the library moves off in-memory Dart to anything with I/O, or
grows large enough that a full linear scan per keystroke drops frames. The fix
is a `Timer`-based debounce inside `_ShellSearchFieldState`; no other code
changes.

## TOML blocks are highlighted with the `properties` grammar

`lib/widgets/code_block.dart:14` — `highlight` 0.7.0 resolves `toml` to its `ini`
grammar, whose top-level `illegal: \S` rejects the `key = value` lines that make
up most of a `pyproject.toml`. One such line aborts the parse and the whole block
renders as unstyled plaintext. `_grammarAliases` therefore hands `properties` to
`HighlightView` instead; it tokenises sections, keys, strings and comments, which
covers everything the two shipped TOML blocks use. The header label still says
TOML.

**Ceiling:** `properties` knows nothing about TOML-only syntax — inline tables,
dotted keys as distinct tokens, datetimes, multi-line basic strings. Those render
readably but uncoloured, not wrongly coloured.

**Upgrade when:** `highlight` ships a real `toml` grammar (or fixes `ini`), or the
content starts leaning on the syntax above. Then delete the `_grammarAliases`
entry and the `toml` case in `test/code_block_highlight_test.dart` goes back to
asserting the native grammar.

## Search, filter, bookmark, recent and resume state is session-only

Every one of these providers is a plain in-memory `ChangeNotifier` with no
persistence — closing the app loses all of it. This is pre-existing and
intentional; the provider doc comments already flag persistence as a later
milestone. Noted here because the Bookmarks and Recent screens now look like
durable storage to a user, and they are not.
