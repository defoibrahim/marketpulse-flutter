import 'package:flutter/material.dart';

class AppLinearProgress extends StatelessWidget {
  final bool isLoading;

  const AppLinearProgress({
    super.key,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return LinearProgressIndicator(
        minHeight: 5,
        semanticsLabel: 'Loading',
        backgroundColor: isDark ? null : Colors.white,
      );
    }
    return const SizedBox.shrink();
  }
}
