import 'package:flutter/material.dart' show ChangeNotifier, ThemeMode;

/// Holds the selected [ThemeMode]. The actual `ThemeData` arrives with the UI
/// milestone.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider([this._themeMode = ThemeMode.system]);

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  /// Cycles system -> light -> dark -> system.
  void toggle() {
    setThemeMode(switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    });
  }
}
