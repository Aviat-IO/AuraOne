import 'package:flutter/material.dart';
import 'pill_tab_bar.dart';

/// Bottom navigation bar that visually/behaviorally matches `PillTabBar`.
class PillNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<PillTabItem> items;
  final ValueChanged<int> onItemSelected;
  final EdgeInsetsGeometry padding;

  const PillNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use the inner width reported by LayoutBuilder. Padding has
              // already been applied, so don't subtract it again.
              final itemWidth = constraints.maxWidth / items.length;
              final indicatorWidth = itemWidth; // fill the whole slot
              final left = selectedIndex * itemWidth;

              return SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    // Sliding pill indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
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
                    // Items
                    Row(
                      children: List.generate(items.length, (index) {
                        final isSelected = index == selectedIndex;
                        final item = items[index];

                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => onItemSelected(index),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
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
          ),
        ),
      ),
    );
  }
}
