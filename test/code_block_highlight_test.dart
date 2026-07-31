import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/content_block.dart';
import 'package:learnflow/widgets/code_block.dart';

/// Every distinct non-null colour in [span] and its descendants.
///
/// `HighlightView` hangs the token colour on the *parent* span and leaves the
/// text-bearing child unstyled, so this walks the whole tree rather than using
/// `visitChildren`, which only reaches spans that carry text.
Set<Color> _colorsIn(InlineSpan span) {
  final Set<Color> colors = <Color>{};
  void walk(InlineSpan node) {
    final TextSpan textSpan = node as TextSpan;
    final Color? color = textSpan.style?.color;
    if (color != null) colors.add(color);
    textSpan.children?.forEach(walk);
  }

  walk(span);
  return colors;
}

void main() {
  /// Pumps a code block and returns the `RichText` that `HighlightView` built.
  /// It is the last one in the tree; the earlier ones are the header label.
  Future<RichText> pumpCode(
    WidgetTester tester, {
    required String language,
    required String code,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CodeBlockView(block: CodeBlock(language: language, code: code)),
        ),
      ),
    );
    return tester.widget<RichText>(find.byType(RichText).last);
  }

  // A block that tokenises produces several token colours. A block that fell
  // back to plaintext produces exactly one — the root colour — which is the
  // failure these guard against.
  testWidgets('python is syntax highlighted', (WidgetTester tester) async {
    final RichText rendered = await pumpCode(
      tester,
      language: 'python',
      code: '# a comment\ndef greet(name):\n    return "hello"\n',
    );

    expect(_colorsIn(rendered.text).length, greaterThan(1));
  });

  testWidgets('bash is syntax highlighted', (WidgetTester tester) async {
    final RichText rendered = await pumpCode(
      tester,
      language: 'bash',
      code: '# set up\npython -m venv .venv\nsource .venv/bin/activate\n',
    );

    expect(_colorsIn(rendered.text).length, greaterThan(1));
  });

  testWidgets('toml is syntax highlighted via its grammar alias', (
    WidgetTester tester,
  ) async {
    final RichText rendered = await pumpCode(
      tester,
      language: 'toml',
      code: '[project]\n'
          'name = "weatherkit"\n'
          'version = "0.1.0"\n'
          'dependencies = [\n'
          '    "requests>=2.31",\n'
          ']\n',
    );

    expect(_colorsIn(rendered.text).length, greaterThan(1));
  });

  testWidgets('the header still names the authored language', (
    WidgetTester tester,
  ) async {
    await pumpCode(tester, language: 'toml', code: '[project]\nname = "x"\n');

    expect(find.text('TOML'), findsOneWidget);
  });
}
