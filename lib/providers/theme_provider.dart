import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light/dark theme choice. Follows the system until the user picks one,
/// then remembers the pick across launches.
class ThemeProvider with ChangeNotifier {
  /// [initialMode] overrides the saved choice for this run without saving
  /// it (used by the demo launch options).
  ThemeProvider([this._prefs, ThemeMode? initialMode])
      : _themeMode = initialMode ?? _read(_prefs);

  static const storageKey = 'theme_mode';

  final SharedPreferences? _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _read(SharedPreferences? prefs) {
    final stored = prefs?.getString(storageKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  /// Switches to the opposite of what is on screen ([current] is the
  /// brightness the app shows now, which matters when following the system).
  void toggle(Brightness current) {
    setThemeMode(
      current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _prefs?.setString(storageKey, mode.name);
  }
}
