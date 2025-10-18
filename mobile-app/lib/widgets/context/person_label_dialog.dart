import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../services/privacy_sanitizer.dart';
import '../../services/context_manager_service.dart';
import '../../theme/colors.dart';
import 'components/person_avatar.dart';

class PersonLabelDialog extends HookConsumerWidget {
  final String? photoId;
  final int? faceIndex;
  final String? initialName;
  final String? initialRelationship;
  final PrivacyLevel? initialPrivacyLevel;

  const PersonLabelDialog({
    super.key,
    this.photoId,
    this.faceIndex,
    this.initialName,
    this.initialRelationship,
    this.initialPrivacyLevel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    final nameController = useTextEditingController(text: initialName ?? '');
    final selectedRelationship = useState<String?>(initialRelationship);
    final selectedPrivacyLevel = useState<PrivacyLevel>(
      initialPrivacyLevel ?? PrivacyLevel.balanced,
    );
    final isSaving = useState(false);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? [
                    AuraColors.lightSurface,
                    AuraColors.lightSurfaceContainerLow,
                  ]
                : [
                    AuraColors.darkSurface,
                    AuraColors.darkSurfaceContainerLow,
                  ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonAvatar(
                name: nameController.text.isEmpty ? null : nameController.text,
                size: PersonAvatarSize.xlarge,
                showBorder: true,
                isUnknown: nameController.text.isEmpty,
              ),
              const SizedBox(height: 24),
              
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter name...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isLight
                          ? AuraColors.lightPrimary
                          : AuraColors.darkPrimary,
                      width: 2,
                    ),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: () => _showRelationshipPicker(
                  context,
                  selectedRelationship,
                  isLight,
                ),
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Relationship (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    selectedRelationship.value ?? 'Select...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selectedRelationship.value == null
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Privacy in Journal',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              _buildPrivacyOption(
                context,
                theme,
                isLight,
                PrivacyLevel.paranoid,
                '🔒 Don\'t mention',
                '(Excluded from journal)',
                selectedPrivacyLevel,
              ),
              const SizedBox(height: 8),
              _buildPrivacyOption(
                context,
                theme,
                isLight,
                PrivacyLevel.high,
                '👤 First name only',
                nameController.text.isNotEmpty
                    ? '"${nameController.text.split(' ').first}"'
                    : '(e.g., "Sarah")',
                selectedPrivacyLevel,
              ),
              const SizedBox(height: 8),
              _buildPrivacyOption(
                context,
                theme,
                isLight,
                PrivacyLevel.balanced,
                '👥 Full name + relationship',
                nameController.text.isNotEmpty && selectedRelationship.value != null
                    ? '"${nameController.text} (${selectedRelationship.value})"'
                    : '(e.g., "Sarah (Sister)")',
                selectedPrivacyLevel,
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving.value ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isSaving.value || nameController.text.trim().isEmpty
                          ? null
                          : () => _savePerson(
                              context,
                              ref,
                              nameController.text.trim(),
                              selectedRelationship.value,
                              selectedPrivacyLevel.value,
                              isSaving,
                            ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isLight
                            ? AuraColors.lightPrimary
                            : AuraColors.darkPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (photoId != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'This person will be labeled in photos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    PrivacyLevel level,
    String title,
    String example,
    ValueNotifier<PrivacyLevel> selectedLevel,
  ) {
    final isSelected = selectedLevel.value == level;
    
    return InkWell(
      onTap: () => selectedLevel.value = level,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isLight ? AuraColors.lightPrimary : AuraColors.darkPrimary)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? (isLight ? AuraColors.lightPrimary : AuraColors.darkPrimary)
                  .withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Radio<PrivacyLevel>(
              value: level,
              groupValue: selectedLevel.value,
              onChanged: (value) => selectedLevel.value = value!,
              activeColor: isLight
                  ? AuraColors.lightPrimary
                  : AuraColors.darkPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    example,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRelationshipPicker(
    BuildContext context,
    ValueNotifier<String?> selectedRelationship,
    bool isLight,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => RelationshipPicker(
        initialValue: selectedRelationship.value,
        onSelected: (value) {
          selectedRelationship.value = value;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _savePerson(
    BuildContext context,
    WidgetRef ref,
    String name,
    String? relationship,
    PrivacyLevel privacyLevel,
    ValueNotifier<bool> isSaving,
  ) async {
    isSaving.value = true;

    try {
      final contextManager = ContextManagerService();
      
      final parts = name.split(' ');
      final firstName = parts.isNotEmpty ? parts.first : name;
      
      final personId = await contextManager.createPerson(
        PersonData(
          name: name,
          firstName: firstName,
          relationship: relationship ?? '',
          privacyLevel: privacyLevel.index,
        ),
      );

      if (photoId != null && faceIndex != null) {
        await contextManager.linkPhotoToPerson(
          photoId!,
          personId,
          1.0, // confidence
          faceIndex!,
        );
      }

      final person = await contextManager.getPersonById(personId);
      if (context.mounted) {
        Navigator.of(context).pop(person);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving person: $e')),
        );
      }
    } finally {
      isSaving.value = false;
    }
  }
}

class RelationshipPicker extends StatelessWidget {
  final String? initialValue;
  final Function(String) onSelected;

  const RelationshipPicker({
    super.key,
    this.initialValue,
    required this.onSelected,
  });

  static const Map<String, List<String>> relationships = {
    'Family': [
      'Parent',
      'Mother',
      'Father',
      'Brother',
      'Sister',
      'Child',
      'Son',
      'Daughter',
      'Spouse',
      'Partner',
      'Grandparent',
      'Aunt',
      'Uncle',
      'Cousin',
    ],
    'Friends': [
      'Close Friend',
      'Friend',
      'Acquaintance',
    ],
    'Professional': [
      'Colleague',
      'Manager',
      'Boss',
      'Client',
      'Mentor',
    ],
    'Other': [
      'Neighbor',
      'Classmate',
      'Teammate',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select Relationship',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: relationships.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    ...entry.value.map((relationship) => ListTile(
                      title: Text(relationship),
                      selected: initialValue == relationship,
                      onTap: () => onSelected(relationship),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
