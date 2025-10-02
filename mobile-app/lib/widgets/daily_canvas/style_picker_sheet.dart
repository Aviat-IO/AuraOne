import 'package:flutter/material.dart';

/// Narrative style options for AI summary generation
enum NarrativeStyle {
  reflective,  // Thoughtful, introspective, philosophical tone
  casual,      // Relaxed, conversational, natural tone
  poetic,      // Lyrical, descriptive, evocative language
  concise,     // Brief, direct, factual style
  detailed,    // Comprehensive, thorough, expansive narrative
}

extension NarrativeStyleExtension on NarrativeStyle {
  String get name {
    switch (this) {
      case NarrativeStyle.reflective:
        return 'Reflective';
      case NarrativeStyle.casual:
        return 'Casual';
      case NarrativeStyle.poetic:
        return 'Poetic';
      case NarrativeStyle.concise:
        return 'Concise';
      case NarrativeStyle.detailed:
        return 'Detailed';
    }
  }

  String get description {
    switch (this) {
      case NarrativeStyle.reflective:
        return 'Thoughtful and introspective, exploring the deeper meaning of your day';
      case NarrativeStyle.casual:
        return 'Relaxed and conversational, like chatting with a friend';
      case NarrativeStyle.poetic:
        return 'Lyrical and evocative, painting a vivid picture of your experiences';
      case NarrativeStyle.concise:
        return 'Brief and direct, highlighting the key moments';
      case NarrativeStyle.detailed:
        return 'Comprehensive and thorough, capturing every nuance';
    }
  }

  IconData get icon {
    switch (this) {
      case NarrativeStyle.reflective:
        return Icons.psychology;
      case NarrativeStyle.casual:
        return Icons.chat_bubble_outline;
      case NarrativeStyle.poetic:
        return Icons.auto_awesome;
      case NarrativeStyle.concise:
        return Icons.notes;
      case NarrativeStyle.detailed:
        return Icons.menu_book;
    }
  }

  Color get color {
    switch (this) {
      case NarrativeStyle.reflective:
        return Colors.deepPurple;
      case NarrativeStyle.casual:
        return Colors.blue;
      case NarrativeStyle.poetic:
        return Colors.pink;
      case NarrativeStyle.concise:
        return Colors.orange;
      case NarrativeStyle.detailed:
        return Colors.teal;
    }
  }
}

/// Bottom sheet for selecting narrative style
class StylePickerSheet extends StatefulWidget {
  final NarrativeStyle? initialStyle;
  final Function(NarrativeStyle) onStyleSelected;

  const StylePickerSheet({
    super.key,
    this.initialStyle,
    required this.onStyleSelected,
  });

  @override
  State<StylePickerSheet> createState() => _StylePickerSheetState();

  /// Show the style picker sheet
  static Future<NarrativeStyle?> show({
    required BuildContext context,
    NarrativeStyle? currentStyle,
  }) async {
    return showModalBottomSheet<NarrativeStyle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StylePickerSheet(
        initialStyle: currentStyle,
        onStyleSelected: (style) => Navigator.pop(context, style),
      ),
    );
  }
}

class _StylePickerSheetState extends State<StylePickerSheet> {
  late NarrativeStyle _selectedStyle;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle ?? NarrativeStyle.reflective;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  Icon(Icons.palette, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Choose Narrative Style',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Style options
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: NarrativeStyle.values.map((style) {
                  return _buildStyleOption(theme, style);
                }).toList(),
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: () => widget.onStyleSelected(_selectedStyle),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Apply Style'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleOption(ThemeData theme, NarrativeStyle style) {
    final isSelected = _selectedStyle == style;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? style.color.withValues(alpha: 0.15)
          : theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? style.color
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedStyle = style),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  style.icon,
                  color: style.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? style.color : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      style.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: style.color,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
