import 'package:flutter/widgets.dart';

class MotionTokens {
  MotionTokens({
    required this.short,
    required this.medium,
    required this.highlightDuration,
  });

  final Duration short;
  final Duration medium;
  final Duration highlightDuration;

  factory MotionTokens.normal() {
    return MotionTokens(
      short: const Duration(milliseconds: 180),
      medium: const Duration(milliseconds: 320),
      highlightDuration: const Duration(milliseconds: 1100),
    );
  }

  factory MotionTokens.reduced() {
    return MotionTokens(
      short: const Duration(milliseconds: 80),
      medium: const Duration(milliseconds: 140),
      highlightDuration: const Duration(milliseconds: 500),
    );
  }

  factory MotionTokens.fromContext(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final reduce = media?.disableAnimations ?? false;
    return reduce ? MotionTokens.reduced() : MotionTokens.normal();
  }
}
