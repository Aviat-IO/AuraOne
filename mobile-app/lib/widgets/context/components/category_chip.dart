import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;

  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final effectiveColor = color ?? 
        (isLight ? AuraColors.lightPrimary : AuraColors.darkPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? effectiveColor
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? effectiveColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? effectiveColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Predefined place categories with icons
class PlaceCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const PlaceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<PlaceCategory> personal = [
    PlaceCategory(
      id: 'home',
      name: 'Home',
      icon: Icons.home,
      color: Color(0xFFE8A87C),
    ),
    PlaceCategory(
      id: 'work',
      name: 'Work',
      icon: Icons.work,
      color: Color(0xFF8AAEE0),
    ),
    PlaceCategory(
      id: 'school',
      name: 'School',
      icon: Icons.school,
      color: Color(0xFF8AAEE0),
    ),
    PlaceCategory(
      id: 'family',
      name: 'Family & Friends',
      icon: Icons.people,
      color: Color(0xFFE8A87C),
    ),
    PlaceCategory(
      id: 'health',
      name: 'Health',
      icon: Icons.local_hospital,
      color: Color(0xFFE88A8A),
    ),
  ];

  static const List<PlaceCategory> social = [
    PlaceCategory(
      id: 'cafe',
      name: 'Cafe',
      icon: Icons.local_cafe,
      color: Color(0xFFD4A574),
    ),
    PlaceCategory(
      id: 'restaurant',
      name: 'Restaurant',
      icon: Icons.restaurant,
      color: Color(0xFFE88A8A),
    ),
    PlaceCategory(
      id: 'bar',
      name: 'Bar',
      icon: Icons.local_bar,
      color: Color(0xFFB88AE8),
    ),
    PlaceCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.theater_comedy,
      color: Color(0xFFB88AE8),
    ),
    PlaceCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Color(0xFFF4C2A1),
    ),
  ];

  static const List<PlaceCategory> activities = [
    PlaceCategory(
      id: 'fitness',
      name: 'Fitness',
      icon: Icons.fitness_center,
      color: Color(0xFF8AE8B8),
    ),
    PlaceCategory(
      id: 'nature',
      name: 'Nature',
      icon: Icons.park,
      color: Color(0xFF8AE88A),
    ),
    PlaceCategory(
      id: 'arts',
      name: 'Arts & Culture',
      icon: Icons.palette,
      color: Color(0xFFB88AE8),
    ),
    PlaceCategory(
      id: 'travel',
      name: 'Travel',
      icon: Icons.flight,
      color: Color(0xFF8AAEE0),
    ),
  ];

  static const List<PlaceCategory> practical = [
    PlaceCategory(
      id: 'service',
      name: 'Service',
      icon: Icons.business,
      color: Color(0xFF8AAEE0),
    ),
    PlaceCategory(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_bus,
      color: Color(0xFF8AAEE0),
    ),
    PlaceCategory(
      id: 'other',
      name: 'Other',
      icon: Icons.place,
      color: Color(0xFFBCAA97),
    ),
  ];

  static List<PlaceCategory> get all => [
    ...personal,
    ...social,
    ...activities,
    ...practical,
  ];

  static PlaceCategory? findById(String id) {
    try {
      return all.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}
