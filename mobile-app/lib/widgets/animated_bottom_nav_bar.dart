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
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 32) / items.length; // Account for padding

    // Animation controller for the sliding indicator
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // Track the previous index for smooth transitions
    final previousIndex = useRef(selectedIndex);

    // Create the slide animation
    final slideTween = useMemoized(
      () => Tween<double>(
        begin: selectedIndex.toDouble(),
        end: selectedIndex.toDouble(),
      ),
      [],
    );

    final slideAnimation = slideTween.animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    ));

    // Update animation when selection changes
    useEffect(() {
      slideTween.begin = previousIndex.value.toDouble();
      slideTween.end = selectedIndex.toDouble();
      animationController.forward(from: 0).then((_) {
        previousIndex.value = selectedIndex;
      });
      return null;
    }, [selectedIndex]);

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
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Stack(
            children: [
              // Animated background indicator
              AnimatedBuilder(
                animation: slideAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: slideAnimation.value * itemWidth,
                    top: 4,
                    bottom: 4,
                    width: itemWidth,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.primary.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Tab items
              Row(
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
            ],
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
      duration: const Duration(milliseconds: 250),
    );

    // Icon scale animation (subtle zoom effect when selected)
    final iconScaleAnimation = useMemoized(
      () => Tween<double>(
        begin: 1.0,
        end: 1.15,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutCubic,
      )),
      [animationController],
    );

    // Title opacity animation for smooth fade
    final titleOpacityAnimation = useMemoized(
      () => Tween<double>(
        begin: 0.7,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      )),
      [animationController],
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

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon with subtle zoom effect
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
                // Animated title with opacity
                AnimatedOpacity(
                  opacity: titleOpacityAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    item.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Removed AnimatedCenterTabItem as all tabs now use the same format
