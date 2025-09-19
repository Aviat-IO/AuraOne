import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A container that groups list items with proper corner rounding.
/// The entire group has rounded corners and consistent styling.
class GroupedListContainer extends StatelessWidget {
  final List<Widget> children;
  final bool isLight;

  const GroupedListContainer({
    super.key,
    required this.children,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
            ? AuraColors.lightCardGradient
            : AuraColors.darkCardGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
              ? AuraColors.lightPrimary.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: List.generate(children.length, (index) {
            final isLast = index == children.length - 1;

            return Column(
              children: [
                children[index],
                // Add divider between items (but not after the last one)
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}