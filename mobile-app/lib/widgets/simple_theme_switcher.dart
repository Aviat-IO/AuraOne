import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme.dart';
import '../theme/colors.dart';

class SimpleThemeSwitcher extends ConsumerWidget {
  const SimpleThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(brightnessProvider);
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        final newBrightness = isDark ? Brightness.light : Brightness.dark;
        ref.read(brightnessProvider.notifier).state = newBrightness;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark
            ? AuraColors.darkPrimary.withValues(alpha: 0.15)
            : AuraColors.lightPrimary.withValues(alpha: 0.15),
          border: Border.all(
            color: isDark
              ? AuraColors.darkPrimary.withValues(alpha: 0.3)
              : AuraColors.lightPrimary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Animated thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AuraColors.darkPrimary : AuraColors.lightPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                        ? AuraColors.darkPrimary.withValues(alpha: 0.3)
                        : AuraColors.lightPrimary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
