import 'package:flutter/material.dart';

/// Inline error shown above data that is still on screen, e.g. when a
/// refresh fails after an earlier load succeeded.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  final String message;
  final VoidCallback onRetry;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Semantics(
        liveRegion: true,
        child: Material(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: colors.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$message Showing the last data that loaded.',
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onErrorContainer,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
