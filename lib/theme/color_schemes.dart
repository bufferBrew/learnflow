/// The LearnFlow palette.
///
/// Swiss-inspired: a neutral paper/ink base carries almost the whole interface,
/// and exactly one confident accent (a signal red) marks the things that matter
/// — the active tab, the primary action, progress. Semantic callout colours are
/// kept out of the [ColorScheme] and shipped as a [CalloutPalette] theme
/// extension so info / warning / tip stay distinct from "primary" and "error".
library;

import 'package:flutter/material.dart';

import '../models/content_block.dart';

/// Light and dark [ColorScheme]s.
abstract final class AppColorSchemes {
  /// Off-white paper, near-black ink, signal red accent.
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,

    // Accent — used sparingly: primary actions, active indicators, progress.
    primary: Color(0xFFC8102E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFBE3E6),
    onPrimaryContainer: Color(0xFF5C0714),

    // Secondary is ink, not a second hue. Swiss restraint.
    secondary: Color(0xFF1F1F23),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE7E7E1),
    onSecondaryContainer: Color(0xFF1F1F23),

    // Tertiary doubles as the "informational" blue for links and info chips.
    tertiary: Color(0xFF16447D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDCE7F7),
    onTertiaryContainer: Color(0xFF0B2547),

    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),

    surface: Color(0xFFFAFAF7),
    onSurface: Color(0xFF16161A),
    surfaceDim: Color(0xFFEDEDE7),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF6F6F2),
    surfaceContainer: Color(0xFFF1F1EC),
    surfaceContainerHigh: Color(0xFFEAEAE4),
    surfaceContainerHighest: Color(0xFFE4E4DC),
    onSurfaceVariant: Color(0xFF52524C),

    outline: Color(0xFF8E8E86),
    // Rules carry the separation in this design, so the hairline is a little
    // darker than Material's default to stay legible on paper-toned surfaces.
    outlineVariant: Color(0xFFC9C9C1),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2A2A2E),
    onInverseSurface: Color(0xFFF4F4EF),
    inversePrimary: Color(0xFFFF8A93),
    surfaceTint: Color(0x00000000),
  );

  /// Deep charcoal (never pure black — pure black crushes the type hierarchy
  /// and flares on OLED), warm off-white ink, a lifted red that still clears
  /// contrast on the dark ground.
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,

    primary: Color(0xFFF0555F),
    onPrimary: Color(0xFF2A0007),
    primaryContainer: Color(0xFF6E0F1E),
    onPrimaryContainer: Color(0xFFFFDBDE),

    secondary: Color(0xFFD7D7D0),
    onSecondary: Color(0xFF1B1B1E),
    secondaryContainer: Color(0xFF2C2C30),
    onSecondaryContainer: Color(0xFFE6E6E0),

    tertiary: Color(0xFF8FB8F5),
    onTertiary: Color(0xFF0A2547),
    tertiaryContainer: Color(0xFF1E3A63),
    onTertiaryContainer: Color(0xFFD7E4FA),

    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),

    surface: Color(0xFF121214),
    onSurface: Color(0xFFEDEDE7),
    surfaceDim: Color(0xFF0F0F11),
    surfaceBright: Color(0xFF313135),
    surfaceContainerLowest: Color(0xFF0B0B0D),
    surfaceContainerLow: Color(0xFF17171A),
    surfaceContainer: Color(0xFF1B1B1E),
    surfaceContainerHigh: Color(0xFF232326),
    surfaceContainerHighest: Color(0xFF2B2B2F),
    onSurfaceVariant: Color(0xFFB6B6AE),

    outline: Color(0xFF6E6E68),
    outlineVariant: Color(0xFF3A3A41),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFEDEDE7),
    onInverseSurface: Color(0xFF1B1B1E),
    inversePrimary: Color(0xFFC8102E),
    surfaceTint: Color(0x00000000),
  );
}

/// The three colours one callout style needs: a foreground for the icon and
/// title, a tinted ground, and a rule.
@immutable
class CalloutColors {
  const CalloutColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  /// Icon and title colour. Contrast-checked against [background].
  final Color foreground;

  /// The callout's ground. Body text uses the surrounding `onSurface`.
  final Color background;

  /// The rule down the leading edge — the non-colour cue that a callout is a
  /// callout, so the type is never signalled by hue alone.
  final Color border;

  static CalloutColors lerp(CalloutColors a, CalloutColors b, double t) {
    return CalloutColors(
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      background: Color.lerp(a.background, b.background, t)!,
      border: Color.lerp(a.border, b.border, t)!,
    );
  }
}

/// Semantic colours for [CalloutBlock], carried on `ThemeData.extensions` so
/// Read-mode renderers can pull them with
/// `Theme.of(context).extension<CalloutPalette>()`.
@immutable
class CalloutPalette extends ThemeExtension<CalloutPalette> {
  const CalloutPalette({
    required this.info,
    required this.warning,
    required this.tip,
  });

  final CalloutColors info;
  final CalloutColors warning;
  final CalloutColors tip;

  /// Blue — neutral supporting detail.
  /// Amber — something that will bite you.
  /// Green — an optional shortcut or good habit.
  static const CalloutPalette light = CalloutPalette(
    info: CalloutColors(
      foreground: Color(0xFF16447D),
      background: Color(0xFFEDF2FA),
      border: Color(0xFF7FA3D6),
    ),
    warning: CalloutColors(
      foreground: Color(0xFF7A4A05),
      background: Color(0xFFFCF3E3),
      border: Color(0xFFD9A54A),
    ),
    tip: CalloutColors(
      foreground: Color(0xFF14562C),
      background: Color(0xFFECF5EF),
      border: Color(0xFF6FA982),
    ),
  );

  static const CalloutPalette dark = CalloutPalette(
    info: CalloutColors(
      foreground: Color(0xFFA9C8F5),
      background: Color(0xFF161D28),
      border: Color(0xFF34537F),
    ),
    warning: CalloutColors(
      foreground: Color(0xFFE7C078),
      background: Color(0xFF262014),
      border: Color(0xFF6E5525),
    ),
    tip: CalloutColors(
      foreground: Color(0xFF9BD0AC),
      background: Color(0xFF152219),
      border: Color(0xFF335C3E),
    ),
  );

  CalloutColors resolve(CalloutType type) => switch (type) {
    CalloutType.info => info,
    CalloutType.warning => warning,
    CalloutType.tip => tip,
  };

  @override
  CalloutPalette copyWith({
    CalloutColors? info,
    CalloutColors? warning,
    CalloutColors? tip,
  }) {
    return CalloutPalette(
      info: info ?? this.info,
      warning: warning ?? this.warning,
      tip: tip ?? this.tip,
    );
  }

  @override
  CalloutPalette lerp(ThemeExtension<CalloutPalette>? other, double t) {
    if (other is! CalloutPalette) return this;
    return CalloutPalette(
      info: CalloutColors.lerp(info, other.info, t),
      warning: CalloutColors.lerp(warning, other.warning, t),
      tip: CalloutColors.lerp(tip, other.tip, t),
    );
  }
}
