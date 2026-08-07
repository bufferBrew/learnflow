import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the first-run intro has been shown.
///
/// Without persistence (every test's default, since a test has no way to have
/// "seen" anything before) this defaults to already-complete, so the shell
/// renders immediately and no test has to drive through the intro screen. The
/// real app always supplies [SharedPreferences], so a genuine first launch
/// defaults to incomplete and shows the intro exactly once.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({SharedPreferences? prefs}) : _prefs = prefs {
    _completed = prefs == null ? true : (prefs.getBool(_prefsKey) ?? false);
  }

  static const String _prefsKey = 'learnflow.onboarding_complete.v1';

  final SharedPreferences? _prefs;
  late bool _completed;

  bool get completed => _completed;

  void complete() {
    if (_completed) return;
    _completed = true;
    final prefs = _prefs;
    if (prefs != null) unawaited(prefs.setBool(_prefsKey, true));
    notifyListeners();
  }
}
