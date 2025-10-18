import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../services/context_manager_service.dart';
import '../../theme/colors.dart';
import 'components/category_chip.dart';

class PlaceNamingDialog extends HookConsumerWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final String? suggestedCategory;
  final String? initialName;

  const PlaceNamingDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    this.suggestedCategory,
    this.initialName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final nameController = useTextEditingController(text: initialName ?? '');
    final selectedCategory = useState<PlaceCategory?>(
      suggestedCategory != null 
          ? PlaceCategory.findById(suggestedCategory!)
          : null,
    );
    final selectedSignificance = useState<int>(1); // Default to Frequent
    final isSaving = useState(false);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isLight
                      ? [AuraColors.lightPrimary, AuraColors.lightSecondary]
                      : [AuraColors.darkPrimary, AuraColors.darkSecondary],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.place,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Name This Place',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location preview
                    if (address != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Name input
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Place Name',
                        hintText: 'e.g., Sunrise Coffee Co.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 20),

                    // Category selection
                    Text(
                      'What type of place?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildCategorySection(
                      context,
                      theme,
                      'Personal',
                      PlaceCategory.personal,
                      selectedCategory,
                    ),
                    const SizedBox(height: 12),
                    _buildCategorySection(
                      context,
                      theme,
                      'Social',
                      PlaceCategory.social,
                      selectedCategory,
                    ),
                    const SizedBox(height: 12),
                    _buildCategorySection(
                      context,
                      theme,
                      'Activities',
                      PlaceCategory.activities,
                      selectedCategory,
                    ),
                    const SizedBox(height: 20),

                    // Significance level
                    Text(
                      'How often do you visit?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildSignificanceOption(
                      context,
                      theme,
                      isLight,
                      2,
                      '⭐ Primary',
                      'Daily visits (Home, Work)',
                      selectedSignificance,
                    ),
                    const SizedBox(height: 8),
                    _buildSignificanceOption(
                      context,
                      theme,
                      isLight,
                      1,
                      '🔄 Frequent',
                      'Weekly visits (Gym, Cafe)',
                      selectedSignificance,
                    ),
                    const SizedBox(height: 8),
                    _buildSignificanceOption(
                      context,
                      theme,
                      isLight,
                      0,
                      '📍 Occasional',
                      'Sometimes (Restaurants)',
                      selectedSignificance,
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
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
                      onPressed: isSaving.value ||
                              nameController.text.trim().isEmpty ||
                              selectedCategory.value == null
                          ? null
                          : () => _savePlace(
                              context,
                              ref,
                              nameController.text.trim(),
                              selectedCategory.value!,
                              selectedSignificance.value,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    ThemeData theme,
    String title,
    List<PlaceCategory> categories,
    ValueNotifier<PlaceCategory?> selectedCategory,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            return CategoryChip(
              label: category.name,
              icon: category.icon,
              color: category.color,
              isSelected: selectedCategory.value?.id == category.id,
              onTap: () => selectedCategory.value = category,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSignificanceOption(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    int level,
    String title,
    String description,
    ValueNotifier<int> selectedLevel,
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
            Radio<int>(
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
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

  Future<void> _savePlace(
    BuildContext context,
    WidgetRef ref,
    String name,
    PlaceCategory category,
    int significance,
    ValueNotifier<bool> isSaving,
  ) async {
    isSaving.value = true;

    try {
      final contextManager = ContextManagerService();

      final placeId = await contextManager.createPlace(
        PlaceData(
          name: name,
          category: category.id,
          latitude: latitude,
          longitude: longitude,
          radiusMeters: 50.0,
          significanceLevel: significance,
        ),
      );

      final place = await contextManager.getPlaceById(placeId);
      if (context.mounted) {
        Navigator.of(context).pop(place);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving place: $e')),
        );
      }
    } finally {
      isSaving.value = false;
    }
  }
}
