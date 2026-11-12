import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketpulse/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('follows the system until the user picks a theme', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider(await SharedPreferences.getInstance());

    expect(provider.themeMode, ThemeMode.system);
  });

  test('toggles relative to what is on screen and remembers it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs);

    provider.toggle(Brightness.dark);

    expect(provider.themeMode, ThemeMode.light);
    expect(prefs.getString(ThemeProvider.storageKey), 'light');
    expect(ThemeProvider(prefs).themeMode, ThemeMode.light);
  });

  test('ignores an unknown stored value', () async {
    SharedPreferences.setMockInitialValues({
      ThemeProvider.storageKey: 'sepia',
    });
    final provider = ThemeProvider(await SharedPreferences.getInstance());

    expect(provider.themeMode, ThemeMode.system);
  });

  test('works without storage', () {
    final provider = ThemeProvider();
    provider.toggle(Brightness.light);
    expect(provider.themeMode, ThemeMode.dark);
  });
}
