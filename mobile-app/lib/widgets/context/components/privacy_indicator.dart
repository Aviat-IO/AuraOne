import 'package:flutter/material.dart';
import '../../../services/privacy_sanitizer.dart';
import '../../../theme/colors.dart';

class PrivacyIndicator extends StatelessWidget {
  final PrivacyLevel level;
  final bool showLabel;
  final double iconSize;

  const PrivacyIndicator({
    super.key,
    required this.level,
    this.showLabel = false,
    this.iconSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final icon = _getIcon();
    final label = _getLabel();
    final color = _getColor(isLight);

    if (!showLabel) {
      return Icon(
        icon,
        size: iconSize,
        color: color,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getIcon() {
    switch (level) {
      case PrivacyLevel.paranoid:
        return Icons.lock;
      case PrivacyLevel.high:
        return Icons.person;
      case PrivacyLevel.balanced:
        return Icons.people;
      case PrivacyLevel.minimal:
        return Icons.public;
    }
  }

  String _getLabel() {
    switch (level) {
      case PrivacyLevel.paranoid:
        return 'Excluded';
      case PrivacyLevel.high:
        return 'First Name';
      case PrivacyLevel.balanced:
        return 'Balanced';
      case PrivacyLevel.minimal:
        return 'Full Details';
    }
  }

  Color _getColor(bool isLight) {
    switch (level) {
      case PrivacyLevel.paranoid:
        return isLight ? AuraColors.lightError : AuraColors.darkError;
      case PrivacyLevel.high:
        return isLight ? Colors.orange.shade700 : Colors.orange.shade400;
      case PrivacyLevel.balanced:
        return isLight ? AuraColors.lightPrimary : AuraColors.darkPrimary;
      case PrivacyLevel.minimal:
        return isLight ? Colors.green.shade700 : Colors.green.shade400;
    }
  }
}
