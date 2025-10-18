import 'package:flutter/material.dart';
import '../../../database/context_database.dart';
import '../../../services/privacy_sanitizer.dart';
import '../../../theme/colors.dart';
import 'person_avatar.dart';
import 'privacy_indicator.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final int photoCount;
  final DateTime? lastSeen;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPrivacyChange;

  const PersonCard({
    super.key,
    required this.person,
    this.photoCount = 0,
    this.lastSeen,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onPrivacyChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

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
                PersonAvatar(
                  name: person.name,
                  size: PersonAvatarSize.medium,
                  showBorder: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              person.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PrivacyIndicator(
                            level: PrivacyLevel.values[person.privacyLevel],
                            iconSize: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildSubtitle(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
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

  String _buildSubtitle() {
    final parts = <String>[];
    
    if (person.relationship.isNotEmpty) {
      parts.add(person.relationship);
    }
    
    parts.add('$photoCount photos');
    
    if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);
      
      if (difference.inDays == 0) {
        parts.add('Today');
      } else if (difference.inDays == 1) {
        parts.add('Yesterday');
      } else if (difference.inDays < 7) {
        parts.add('${difference.inDays} days ago');
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        parts.add('$weeks ${weeks == 1 ? 'week' : 'weeks'} ago');
      } else {
        final months = (difference.inDays / 30).floor();
        parts.add('$months ${months == 1 ? 'month' : 'months'} ago');
      }
    }
    
    return parts.join(' • ');
  }
}
