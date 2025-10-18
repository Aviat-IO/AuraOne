import 'package:flutter/material.dart';
import '../../../database/context_database.dart';
import '../../../theme/colors.dart';
import 'category_chip.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final double? distance; // Distance in meters

  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final category = PlaceCategory.findById(place.category) ?? 
        PlaceCategory.practical.last; // Default to "Other"

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildSubtitle(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildSignificanceBadge(theme),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignificanceBadge(ThemeData theme) {
    IconData icon;
    Color color;

    switch (place.significanceLevel) {
      case 2: // Primary
        icon = Icons.star;
        color = Colors.amber;
        break;
      case 1: // Frequent
        icon = Icons.repeat;
        color = theme.colorScheme.primary;
        break;
      default: // Occasional
        icon = Icons.place;
        color = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    }

    return Icon(
      icon,
      size: 18,
      color: color,
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];

    // Add category
    final category = PlaceCategory.findById(place.category);
    if (category != null) {
      parts.add(category.name);
    }

    // Add visit count if > 0
    if (place.visitCount > 0) {
      parts.add('${place.visitCount} visits');
    }

    // Add distance if provided
    if (distance != null) {
      if (distance! < 1000) {
        parts.add('${distance!.round()}m');
      } else {
        parts.add('${(distance! / 1000).toStringAsFixed(1)}km');
      }
    }

    // Add neighborhood or city
    if (place.neighborhood != null && place.neighborhood!.isNotEmpty) {
      parts.add(place.neighborhood!);
    } else if (place.city != null && place.city!.isNotEmpty) {
      parts.add(place.city!);
    }

    return parts.join(' • ');
  }
}
