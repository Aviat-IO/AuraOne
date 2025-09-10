import 'package:flutter/material.dart';
import '../theme/colors.dart';

class PageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color>? gradientColors;
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.gradientColors,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    // Use provided gradient colors or default to logo gradient
    final gradient = gradientColors ?? (isLight 
      ? AuraColors.lightLogoGradient
      : AuraColors.darkLogoGradient);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight 
                  ? AuraColors.lightPrimary.withValues(alpha: 0.2)
                  : AuraColors.darkPrimary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}