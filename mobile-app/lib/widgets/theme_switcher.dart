import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme.dart';
import '../theme/colors.dart';

class ThemeSwitcher extends ConsumerStatefulWidget {
  const ThemeSwitcher({super.key});

  @override
  ConsumerState<ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends ConsumerState<ThemeSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: const Offset(1, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: AuraColors.lightPrimary,
      end: AuraColors.darkPrimary,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Set initial state
    final brightness = ref.read(brightnessProvider);
    if (brightness == Brightness.dark) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = ref.watch(brightnessProvider);
    final isDark = brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        final newBrightness = isDark ? Brightness.light : Brightness.dark;
        ref.read(brightnessProvider.notifier).state = newBrightness;
        
        if (newBrightness == Brightness.dark) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      },
      child: Container(
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: (_colorAnimation.value ?? AuraColors.lightPrimary).withValues(alpha: 0.15),
          border: Border.all(
            color: (_colorAnimation.value ?? AuraColors.lightPrimary).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background track
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    AuraColors.lightSurfaceContainerHigh.withValues(alpha: 0.5),
                    AuraColors.lightSurface.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            
            // Moving thumb
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation.value.dx * 12, 0),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colorAnimation.value ?? AuraColors.lightPrimary,
                      boxShadow: [
                        BoxShadow(
                          color: (_colorAnimation.value ?? AuraColors.lightPrimary)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}