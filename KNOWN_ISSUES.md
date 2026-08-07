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

## Search filters are session-only; everything else now persists

`SearchFilterProvider` (the query text and facet chips) is still a plain
in-memory `ChangeNotifier` — closing the app drops whatever was typed, which is
the right behaviour for a transient query. Progress, bookmarks, recently
viewed, resume points, theme, best Play-mode stars, streaks and achievements
are now backed by `SharedPreferences` (see each provider's `_load`/`_save`).

Every provider takes persistence as an optional constructor parameter that
defaults to `null` — omitting it (every test's default, and any future
provider constructed bare) keeps that provider exactly as in-memory as before,
so no test had to change to accommodate this. Only `main.dart` supplies a real
`SharedPreferences` instance.

**Breaks when:** a provider gains a field that should survive a restart but
its author forgets the corresponding `_save()` call — nothing enforces the
pairing beyond code review.
