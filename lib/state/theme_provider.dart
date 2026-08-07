import 'dart:async';

import 'package:flutter/material.dart' show ChangeNotifier, ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the selected [ThemeMode]. Persisted via [SharedPreferences] when one
/// is supplied; omitting it (every test's default) keeps this in-memory only.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({this._prefs, ThemeMode initial = ThemeMode.system})
    : _themeMode = initial {
    _load();
  }

  static const String _prefsKey = 'learnflow.theme_mode.v1';

  final SharedPreferences? _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _save();
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

  void _load() {
    final prefs = _prefs;
    if (prefs == null) return;
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => _themeMode,
    );
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(prefs.setString(_prefsKey, _themeMode.name));
  }
}
