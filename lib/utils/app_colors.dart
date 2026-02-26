import 'package:flutter/material.dart';

/// Provides theme-aware colors.
///
/// Usage:
///   final ac = AppColors.of(context);
///   Container(color: ac.card, ...)
///   Text('...', style: TextStyle(color: ac.text))
class AppColors {
  final Color bg;
  final Color card;
  final Color text;

  static const purple = Color(0xFF6C63FF);

  const AppColors._({
    required this.bg,
    required this.card,
    required this.text,
  });

  static AppColors of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const AppColors._(
        bg: Color(0xFF0D0D1E),
        card: Color(0xFF1A1A2E),
        text: Colors.white,
      );
    }
    return const AppColors._(
      bg: Color(0xFFF5F5FF),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF1A1A2E),
    );
  }

  Color get textSecondary => text.withValues(alpha: 0.65);
  Color get textMuted => text.withValues(alpha: 0.45);
  Color get textHint => text.withValues(alpha: 0.35);
  Color get divider => text.withValues(alpha: 0.07);
  Color get inputBorder => text.withValues(alpha: 0.1);
  Color get subtleBorder => text.withValues(alpha: 0.07);
}
