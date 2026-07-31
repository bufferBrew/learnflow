/// Theme-agnostic design tokens.
///
/// Nothing in this file knows about light or dark mode — colours live in
/// `color_schemes.dart` and the assembled `ThemeData` lives in `app_theme.dart`.
/// The values follow a Swiss / International Typographic Style brief: a strict
/// modular grid, precise whitespace, restrained decoration, hairline rules
/// instead of shadows, and a compact high-contrast type hierarchy.
library;

// `material` is imported only for `TextTheme`, which is the shape `ThemeData`
// expects the type scale in. No colours or component styles are decided here.
import 'package:flutter/material.dart';

/// The 8-step spacing scale. Every gap, pad and inset in the app should come
/// from here so the vertical rhythm stays on one grid.
abstract final class AppSpacing {
  /// 4 — hairline gaps, icon-to-label spacing.
  static const double xxs = 4;

  /// 8 — tight grouping inside a component.
  static const double xs = 8;

  /// 12 — related items in a list.
  static const double sm = 12;

  /// 16 — the default gutter.
  static const double md = 16;

  /// 20 — comfortable inner padding for cards and panels.
  static const double lg = 20;

  /// 24 — separation between component groups.
  static const double xl = 24;

  /// 32 — separation between sections on a page.
  static const double xxl = 32;

  /// 48 — page-level breathing room, top of a screen.
  static const double xxxl = 48;

  /// The full scale, ascending. Useful for tests and documentation.
  static const List<double> scale = <double>[xxs, xs, sm, md, lg, xl, xxl, xxxl];
}

/// Corner radii. Swiss design keeps corners close to square; 16 is the
/// absolute ceiling and is reserved for large surfaces.
abstract final class AppRadius {
  /// 4 — buttons, inputs, chips, indicators.
  static const double xs = 4;

  /// 8 — cards and list rows.
  static const double sm = 8;

  /// 12 — panels and sheets.
  static const double md = 12;

  /// 16 — full-bleed containers only.
  static const double lg = 16;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));

  /// The full scale, ascending.
  static const List<double> scale = <double>[xs, sm, md, lg];
}

/// Stroke widths. Rules do the work that shadows do in a Material-default app.
abstract final class AppStroke {
  /// 1 — dividers, card outlines, input borders.
  static const double hairline = 1;

  /// 2 — active tab indicator, focus ring, selected rail marker.
  static const double emphasis = 2;
}

/// Elevation is deliberately near-flat. Only transient overlays (menus,
/// dialogs) lift off the page at all; everything else separates with a rule.
abstract final class AppElevation {
  /// 0 — app bars, cards, drawers, navigation bars. The default.
  static const double flat = 0;

  /// 1 — a surface that must read as temporarily above the page.
  static const double raised = 1;

  /// 3 — menus, dialogs, popovers. The maximum this app uses.
  static const double overlay = 3;

  /// A single restrained shadow for [overlay]-level surfaces. Low opacity, no
  /// spread, small offset — enough to detach, not enough to look skeuomorphic.
  static List<BoxShadow> overlayShadow(Color shadowColor) => <BoxShadow>[
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.10),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

/// The compact type scale.
///
/// Sizes sit well below Flutter's Material defaults (body is 13-14 rather than
/// 14-16, labels are 11-13) because this app shows dense study material. Colour
/// is intentionally absent: `AppTheme` applies it from the [ColorScheme] so one
/// scale serves both modes. Headings use tight negative tracking, small labels
/// use positive tracking — the classic Swiss pairing.
abstract final class AppTypeScale {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 40,
    height: 1.06,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 34,
    height: 1.08,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 30,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    height: 1.55,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.05,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  /// Used for the small all-caps eyebrow labels above sections.
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  /// Monospaced numerals for list indices and durations. Falls back to the
  /// platform monospace face — no font package is bundled.
  static const TextStyle mono = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    fontFamily: 'monospace',
    fontFamilyFallback: <String>['Menlo', 'Consolas', 'Roboto Mono', 'monospace'],
  );

  /// The colourless [TextTheme] handed to `ThemeData`, which then paints it
  /// with the active scheme's `onSurface`.
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}

/// Layout breakpoints. One threshold, because the shell only has two states.
abstract final class AppBreakpoints {
  /// At or above this width the shell shows a persistent sidebar; below it the
  /// same tree moves into a drawer.
  static const double desktop = 1000;

  /// Above this width topic cards lay out in two columns.
  static const double wideContent = 720;

  static bool isDesktop(double width) => width >= desktop;
}

/// Fixed component dimensions used by the shell.
abstract final class AppDimensions {
  /// Persistent sidebar / drawer width.
  static const double sidebarWidth = 272;

  /// Desktop top bar height.
  static const double topBarHeight = 56;

  /// Mobile bottom navigation height.
  static const double bottomNavHeight = 64;

  /// The search field never grows past this, so it stays a field and not a
  /// banner on very wide screens.
  static const double searchFieldMaxWidth = 320;

  /// Measure cap for reading columns — roughly 90 characters at body size.
  static const double contentMaxWidth = 960;

  /// Minimum interactive size. Anything tappable must reach this.
  static const double minTouchTarget = 44;
}

/// Motion tokens. Short, linear-ish, no bounce. Callers must still honour
/// `MediaQuery.disableAnimations` for reduced-motion users.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve standard = Curves.easeOutCubic;
}
