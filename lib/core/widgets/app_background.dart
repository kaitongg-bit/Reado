import 'package:flutter/material.dart';

/// Unifying background for the entire app.
/// Provides a consistent top-to-bottom gradient.
/// Light mode: Soft Orange Gradient
/// Dark mode: Deep Gray/Black Gradient
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF121212),
                  ]
                : [
                    const Color(0xFFFFF7ED), // Orange 50
                    const Color(0xFFFFEDD5), // Orange 100
                  ],
          ),
        ),
      ),
    );
  }
}
