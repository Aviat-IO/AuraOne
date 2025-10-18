import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

enum PersonAvatarSize {
  small(40.0),
  medium(48.0),
  large(64.0),
  xlarge(120.0);

  const PersonAvatarSize(this.size);
  final double size;
}

class PersonAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final PersonAvatarSize size;
  final bool showBorder;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool isUnknown;

  const PersonAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = PersonAvatarSize.medium,
    this.showBorder = false,
    this.borderColor,
    this.onTap,
    this.isUnknown = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final effectiveBorderColor = borderColor ?? 
        (isLight ? AuraColors.lightPrimary : AuraColors.darkPrimary);

    Widget avatar = Container(
      width: size.size,
      height: size.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: effectiveBorderColor,
                width: 2.0,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isLight
                ? AuraColors.lightPrimary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(theme, isLight),
              )
            : _buildPlaceholder(theme, isLight),
      ),
    );

    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size.size / 2),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildPlaceholder(ThemeData theme, bool isLight) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  AuraColors.lightPrimaryContainer,
                  AuraColors.lightSecondaryContainer,
                ]
              : [
                  AuraColors.darkPrimaryContainer,
                  AuraColors.darkSecondaryContainer,
                ],
        ),
      ),
      child: Center(
        child: Icon(
          isUnknown ? Icons.question_mark : Icons.person,
          size: size.size * 0.5,
          color: isLight
              ? AuraColors.lightOnPrimaryContainer
              : AuraColors.darkOnPrimaryContainer,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'.toUpperCase();
  }
}
