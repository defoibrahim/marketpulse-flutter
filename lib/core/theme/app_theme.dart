import 'package:flutter/material.dart';

/// Gain and loss colours, tuned per brightness so text on the theme's
/// surfaces meets WCAG AA contrast (4.5:1).
@immutable
class MarketColors extends ThemeExtension<MarketColors> {
  const MarketColors({required this.gain, required this.loss});

  final Color gain;
  final Color loss;

  static const light = MarketColors(
    gain: Color(0xFF2E7D32),
    loss: Color(0xFFC62828),
  );

  static const dark = MarketColors(
    gain: Color(0xFF66BB6A),
    loss: Color(0xFFEF5350),
  );

  /// Gain colour for a non-negative [value], loss colour otherwise.
  Color forChange(num value) => value >= 0 ? gain : loss;

  @override
  MarketColors copyWith({Color? gain, Color? loss}) =>
      MarketColors(gain: gain ?? this.gain, loss: loss ?? this.loss);

  @override
  MarketColors lerp(ThemeExtension<MarketColors>? other, double t) {
    if (other is! MarketColors) return this;
    return MarketColors(
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
    );
  }
}

extension MarketThemeContext on BuildContext {
  MarketColors get marketColors =>
      Theme.of(this).extension<MarketColors>() ?? MarketColors.dark;
}

class AppTheme {
  AppTheme._();

  /// The brand colour every theme is seeded from.
  static const brand = Color(0xFF6C5CE7);

  /// The gradient of the portfolio balance card.
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _darkBackground = Color(0xFF121212);
  static const _darkSurface = Color(0xFF1E1E1E);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    extensions: const [MarketColors.light],
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: _darkBackground,
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2D2D2D)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    extensions: const [MarketColors.dark],
  );
}
