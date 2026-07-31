import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/theme_provider.dart';

/// Cycles System → Light → Dark. Used by the desktop top bar and the mobile
/// app bar — one control, mounted twice.
///
/// The icon changes shape per mode (auto / sun / moon), and the tooltip names
/// both the current mode and the next one, so the state is never carried by
/// colour or icon alone.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final mode = themeProvider.themeMode;

    final (IconData icon, String label, String next) = switch (mode) {
      ThemeMode.system => (Icons.brightness_auto_outlined, 'System', 'Light'),
      ThemeMode.light => (Icons.light_mode_outlined, 'Light', 'Dark'),
      ThemeMode.dark => (Icons.dark_mode_outlined, 'Dark', 'System'),
    };

    return IconButton(
      onPressed: context.read<ThemeProvider>().toggle,
      icon: Icon(icon),
      iconSize: 20,
      tooltip: 'Theme: $label. Switch to $next.',
    );
  }
}
