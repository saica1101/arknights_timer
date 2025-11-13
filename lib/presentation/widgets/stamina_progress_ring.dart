import 'package:flutter/material.dart';

class StaminaProgressRing extends StatelessWidget {
  final double value;
  final String staminaText;
  final String countdownText;

  const StaminaProgressRing({
    super.key,
    required this.value,
    required this.staminaText,
    required this.countdownText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // progress ring の色はカスタム: 前景=primaryに合わせた色ではなく指定色を使う
    final isDark = scheme.brightness == Brightness.dark;
    final foreground = isDark
        ? const Color(0xFF0085FF) // AppColors.progressRingDark
        : const Color(0xFF71C4EF); // AppColors.progressRingLight
    final bgcolor = isDark
        ? const Color(0xFF9E9E9E) // AppColors.progressRingDark
        : const Color(0xFFB6CCD8); // AppColors.progressRingLight
    final track = Theme.of(context).cardColor.withValues(alpha: 0.3);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            builder: (context, v, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation(track),
                  ),
                  CircularProgressIndicator(
                    value: v,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation(foreground),
                    backgroundColor: bgcolor,
                  ),
                ],
              );
            },
          ),
        ),
        Column(
          children: [
            if (staminaText.isNotEmpty)
              Text(
                staminaText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              countdownText,
              style: TextStyle(fontSize: 12, color: scheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}
