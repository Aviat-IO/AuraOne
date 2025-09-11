import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../theme/colors.dart';

/// Animated bottom navigation bar with smooth icon and title animations
/// Features spring physics animations for delightful user experience
class AnimatedBottomNavBar extends HookWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<AnimatedTabItem> items;
  final bool isLight;

  const AnimatedBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.items,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLight
              ? [
                  AuraColors.lightSurface.withValues(alpha: 0.95),
                  AuraColors.lightSurface,
                ]
              : [
                  AuraColors.darkSurface.withValues(alpha: 0.95),
                  AuraColors.darkSurface,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? AuraColors.lightPrimary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return AnimatedTabBarItem(
                index: index,
                selectedIndex: selectedIndex,
                item: item,
                theme: theme,
                onTap: () => onItemTapped(index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Data model for tab items
class AnimatedTabItem {
  final IconData icon;
  final String label;

  const AnimatedTabItem({
    required this.icon,
    required this.label,
  });
}

/// Individual animated tab bar item widget
class AnimatedTabBarItem extends HookWidget {
  final int index;
  final int selectedIndex;
  final AnimatedTabItem item;
  final ThemeData theme;
  final VoidCallback onTap;

  const AnimatedTabBarItem({
    super.key,
    required this.index,
    required this.selectedIndex,
    required this.item,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;

    // Animation controller for smooth transitions
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // Icon scale animation (zoom effect when selected)
    final iconScaleAnimation = useMemoized(
      () => Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.elasticOut,
      )),
      [animationController],
    );

    // Title scale animation for emphasis when selected
    final titleScaleAnimation = useMemoized(
      () => Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.elasticOut,
      )),
      [animationController],
    );

    // Title color animation for smooth color transition
    final titleColorAnimation = useMemoized(
      () => ColorTween(
        begin: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        end: theme.colorScheme.primary,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      )),
      [animationController, theme],
    );

    // Background color animation
    final backgroundColorAnimation = useMemoized(
      () => ColorTween(
        begin: Colors.transparent,
        end: theme.colorScheme.primary.withValues(alpha: 0.1),
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      )),
      [animationController, theme],
    );

    // Control animation based on selection state
    useEffect(() {
      if (isSelected) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [isSelected, animationController]);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: backgroundColorAnimation.value,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon with zoom effect
                Transform.scale(
                  scale: iconScaleAnimation.value,
                  child: Icon(
                    item.icon,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),

                const SizedBox(height: 4),
                // Animated title (always visible with color and scale animation)
                Transform.scale(
                  scale: titleScaleAnimation.value,
                  child: Text(
                    item.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: titleColorAnimation.value,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Removed AnimatedCenterTabItem as all tabs now use the same format
