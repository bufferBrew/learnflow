/// Assembles [ThemeData] from the tokens in `design_tokens.dart` and the
/// palettes in `color_schemes.dart`.
///
/// House rules encoded here, so screens never have to restate them:
/// * elevation is 0 almost everywhere; separation comes from hairline rules,
/// * corners are near-square (4 for controls, 8 for cards),
/// * type is the compact scale, left-aligned (app bar titles are not centred),
/// * the accent colour appears only on indicators and primary actions.
library;

import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'design_tokens.dart';

/// Scrubber track thickness. Twice [AppStroke.emphasis] — a 2px rule is a
/// divider, and this one has to be grabbable.
const double _scrubberTrackHeight = 4;

abstract final class AppTheme {
  /// Built once — `ThemeData` construction is not cheap and these never change.
  static final ThemeData light = _build(AppColorSchemes.light, CalloutPalette.light);

  static final ThemeData dark = _build(AppColorSchemes.dark, CalloutPalette.dark);

  static ThemeData _build(ColorScheme scheme, CalloutPalette callouts) {
    final TextTheme text = AppTypeScale.textTheme;

    // Reused shapes.
    final controlShape = RoundedRectangleBorder(
      borderRadius: AppRadius.allXs,
      side: BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline),
    );
    const indicatorShape = RoundedRectangleBorder(borderRadius: AppRadius.allXs);
    final hairline = BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      shadowColor: scheme.shadow,
      // Standard density keeps hit targets at 48px even on desktop, where
      // Flutter would otherwise pick `compact`.
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      extensions: <ThemeExtension<dynamic>>[callouts],

      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 20),

      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: AppElevation.flat,
        scrolledUnderElevation: AppElevation.flat,
        // Swiss: titles start at the left margin, never centred.
        centerTitle: false,
        titleSpacing: AppSpacing.md,
        toolbarHeight: AppDimensions.topBarHeight,
        titleTextStyle: text.titleLarge!.copyWith(color: scheme.onSurface),
        toolbarTextStyle: text.bodyMedium!.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 20),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 20),
        // A rule, not a shadow.
        shape: Border(bottom: hairline),
      ),

      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: AppElevation.flat,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allSm,
          side: BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: AppStroke.hairline,
        space: AppStroke.hairline,
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: AppElevation.flat,
        width: AppDimensions.sidebarWidth,
        // Square edge: the drawer reads as the same panel the desktop sidebar
        // is, not as a floating sheet.
        shape: const RoundedRectangleBorder(),
        scrimColor: scheme.scrim.withValues(alpha: 0.42),
      ),

      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: AppElevation.flat,
        tileHeight: AppDimensions.minTouchTarget,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: indicatorShape,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          text.labelLarge!.copyWith(color: scheme.onSurface),
        ),
        iconTheme: WidgetStatePropertyAll<IconThemeData>(
          IconThemeData(color: scheme.onSurfaceVariant, size: 20),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: AppElevation.flat,
        height: AppDimensions.bottomNavHeight,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: indicatorShape,
        // Labels always visible: an icon alone is not a sufficient cue.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? text.labelSmall!.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700)
              : text.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            size: 20,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w500),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: scheme.outlineVariant,
        dividerHeight: AppStroke.hairline,
        splashBorderRadius: AppRadius.allXs,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: AppElevation.flat,
          minimumSize: const Size(64, AppDimensions.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLowest,
          foregroundColor: scheme.onSurface,
          // Flat by design: the outline carries the affordance.
          elevation: AppElevation.flat,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          minimumSize: const Size(64, AppDimensions.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: text.labelLarge,
          shape: controlShape,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, AppDimensions.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline, width: AppStroke.hairline),
          minimumSize: const Size(64, AppDimensions.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size.square(AppDimensions.minTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        hintStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: AppRadius.allXs,
          borderSide: BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allXs,
          borderSide: BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline),
        ),
        // Focus is signalled by a thicker rule as well as a colour change, so
        // it survives a colour-blind or greyscale reading.
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allXs,
          borderSide: BorderSide(color: scheme.primary, width: AppStroke.emphasis),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allXs,
          borderSide: BorderSide(color: scheme.error, width: AppStroke.hairline),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allXs,
          borderSide: BorderSide(color: scheme.error, width: AppStroke.emphasis),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: text.titleSmall!.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
        horizontalTitleGap: AppSpacing.sm,
        minVerticalPadding: AppSpacing.xs,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
      ),

      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: EdgeInsets.zero,
        // Kill the default top/bottom borders an expanded tile draws.
        shape: const Border(),
        collapsedShape: const Border(),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.secondaryContainer,
        labelStyle: text.labelMedium!.copyWith(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
      ),

      // The 3-way script-length switcher in Listen mode. Squared off and
      // hairlined like every other control, rather than M3's default stadium.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLowest,
          foregroundColor: scheme.onSurfaceVariant,
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          visualDensity: VisualDensity.standard,
        ),
      ),

      // The podcast scrubber. Explicit shapes rather than the M3 defaults: a
      // flat rounded track and a plain round thumb read as one continuous rule
      // through the player, which the gapped default does not.
      sliderTheme: SliderThemeData(
        trackHeight: _scrubberTrackHeight,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHigh,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        // 22 rather than a tighter ring on purpose: the overlay diameter is
        // what gives the scrubber its 44px touch height.
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: AppDimensions.minTouchTarget / 2,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: scheme.surfaceContainerHigh,
        linearMinHeight: AppStroke.emphasis,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: AppRadius.allXs,
        ),
        textStyle: text.bodySmall!.copyWith(color: scheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        waitDuration: AppMotion.slow,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.overlay,
        titleTextStyle: text.headlineSmall!.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyMedium!.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allMd,
          side: BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        elevation: AppElevation.raised,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
      ),
    );
  }
}
