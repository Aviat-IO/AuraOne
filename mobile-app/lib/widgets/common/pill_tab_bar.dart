import 'package:flutter/material.dart';

class PillTabItem {
  final IconData icon;
  final String label;

  const PillTabItem({required this.icon, required this.label});
}

/// A reusable, pill-indicator tab bar that visually matches the bottom nav.
///
/// - Uses a sliding rounded indicator behind the selected item
/// - Supports swipe animations by listening to the provided TabController
class PillTabBar extends StatelessWidget {
  final TabController controller;
  final List<PillTabItem> items;
  final EdgeInsetsGeometry padding;

  const PillTabBar({
    super.key,
    required this.controller,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use full inner width; the parent padding is already excluded.
              final itemWidth = constraints.maxWidth / items.length;
              final indicatorWidth = itemWidth; // fill the whole slot

              // Use controller.animation when available, otherwise a stopped
              // animation at the current index to avoid nullability issues.
              final Animation<double> animation = controller.animation ??
                  AlwaysStoppedAnimation<double>(controller.index.toDouble());

              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final double t = animation.value; // fractional index during swipe

                  final left = t * itemWidth;

                  return SizedBox(
                    height: 48,
                    child: Stack(
                      children: [
                        // Sliding pill indicator
                        Positioned(
                          left: left,
                          top: 2,
                          bottom: 2,
                          width: indicatorWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary.withValues(alpha: 0.18),
                                  theme.colorScheme.primary.withValues(alpha: 0.10),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Tab items
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(items.length, (index) {
                            final isSelected = controller.index == index;
                            final item = items[index];

                            return Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => controller.index = index,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: 18,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.label,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
