import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/settings_providers.dart';
import '../theme/colors.dart';

class FontSizeSettingsScreen extends ConsumerWidget {
  const FontSizeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final fontSize = ref.watch(fontSizeProvider);
    final fontSizeNotifier = ref.read(fontSizeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Size'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                        ? AuraColors.lightPrimary.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This is how your journal entries will look with the current font size setting.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: theme.textTheme.bodyMedium!.fontSize! * fontSizeNotifier.scaleFactor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The quick brown fox jumps over the lazy dog.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: theme.textTheme.bodySmall!.fontSize! * fontSizeNotifier.scaleFactor,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Font size options
              Text(
                'Select Font Size',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              ...FontSize.values.map((size) {
                final isSelected = fontSize == size;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => fontSizeNotifier.setFontSize(size),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected 
                          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                          : null,
                      ),
                      child: Row(
                        children: [
                          Radio<FontSize>(
                            value: size,
                            groupValue: fontSize,
                            onChanged: (FontSize? value) {
                              if (value != null) {
                                fontSizeNotifier.setFontSize(value);
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getSizeName(size),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: _getPreviewSize(size),
                                  ),
                                ),
                                Text(
                                  _getSizeDescription(size),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: _getPreviewSize(size) * 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Information card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Adjusting the font size will affect all text throughout the app, making it easier to read based on your preference.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSizeName(FontSize size) {
    return switch (size) {
      FontSize.small => 'Small (Default)',
      FontSize.medium => 'Medium',
      FontSize.large => 'Large',
    };
  }

  String _getSizeDescription(FontSize size) {
    return switch (size) {
      FontSize.small => 'Standard reading size',
      FontSize.medium => 'Easier reading',
      FontSize.large => 'Maximum readability',
    };
  }

  double _getPreviewSize(FontSize size) {
    return switch (size) {
      FontSize.small => 16,
      FontSize.medium => 18.5,
      FontSize.large => 21,
    };
  }
}