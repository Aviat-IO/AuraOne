import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../database/journal_database.dart';
import '../../services/journal_service.dart';

// Provider for tracking which entry is being edited
final editingEntryIdProvider = StateProvider<int?>((ref) => null);

class JournalEntryEditor extends HookConsumerWidget {
  final JournalEntry? entry;
  final DateTime date;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;
  final bool isEditMode;

  const JournalEntryEditor({
    super.key,
    this.entry,
    required this.date,
    this.onSaved,
    this.onCancel,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEditing = useState(isEditMode);
    final isLoading = useState(false);

    // Text controllers
    final titleController = useTextEditingController(text: entry?.title ?? '');
    final contentController = useTextEditingController(text: entry?.content ?? '');

    // Focus nodes
    final titleFocusNode = useFocusNode();
    final contentFocusNode = useFocusNode();

    // Auto-focus title when entering edit mode
    useEffect(() {
      if (isEditing.value) {
        Future.delayed(const Duration(milliseconds: 100), () {
          titleFocusNode.requestFocus();
        });
      }
      return null;
    }, [isEditing.value]);

    if (!isEditing.value) {
      // View mode
      return _buildViewMode(
        context,
        theme,
        ref,
        entry,
        date,
        () => isEditing.value = true,
      );
    } else {
      // Edit mode
      return _buildEditMode(
        context,
        theme,
        ref,
        entry,
        date,
        titleController,
        contentController,
        titleFocusNode,
        contentFocusNode,
        isLoading,
        () async {
          // Save logic
          isLoading.value = true;
          try {
            final journalService = ref.read(journalServiceProvider);

            if (entry == null) {
              // Create new entry
              await journalService.createEntryForDate(date);
              // Get the created entry to update it
              final newEntry = await journalService.getEntryForDate(date);
              if (newEntry != null) {
                await journalService.updateJournalEntry(
                  id: newEntry.id,
                  title: titleController.text.trim().isNotEmpty
                      ? titleController.text.trim()
                      : 'Untitled Entry',
                  content: contentController.text.trim(),
                );
              }
            } else {
              // Update existing entry
              await journalService.updateJournalEntry(
                id: entry!.id,
                title: titleController.text.trim().isNotEmpty
                    ? titleController.text.trim()
                    : 'Untitled Entry',
                content: contentController.text.trim(),
              );
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Journal entry saved!')),
              );
            }

            isEditing.value = false;
            onSaved?.call();
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save: $error'),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          } finally {
            isLoading.value = false;
          }
        },
        () {
          // Cancel logic
          titleController.text = entry?.title ?? '';
          contentController.text = entry?.content ?? '';
          isEditing.value = false;
          onCancel?.call();
        },
      );
    }
  }

  Widget _buildViewMode(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    JournalEntry? journalEntry,
    DateTime selectedDate,
    VoidCallback onEdit,
  ) {
    if (journalEntry == null) {
      // Empty state
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No journal entry for this day',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(selectedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.create),
              label: const Text('Start Writing'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with edit button
          Row(
            children: [
              Expanded(
                child: Text(
                  journalEntry.title.isEmpty ? 'Untitled Entry' : journalEntry.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
                tooltip: 'Edit entry',
              ),
            ],
          ),

          const SizedBox(height: 8),


          // Content
          if (journalEntry.content.isNotEmpty)
            Text(
              journalEntry.content,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            )
          else
            Text(
              'No content',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),

          // Last edited info
          const SizedBox(height: 24),
          Text(
            'Last edited ${_formatLastEdited(journalEntry.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    JournalEntry? entry,
    DateTime date,
    TextEditingController titleController,
    TextEditingController contentController,
    FocusNode titleFocusNode,
    FocusNode contentFocusNode,
    ValueNotifier<bool> isLoading,
    VoidCallback onSave,
    VoidCallback onCancel,
  ) {
    return Column(
      children: [
        // Edit mode toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Editing: ${_formatDate(date)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              // Cancel button
              TextButton(
                onPressed: isLoading.value ? null : onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              // Save button
              ElevatedButton(
                onPressed: isLoading.value ? null : onSave,
                child: isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),

        // Editor content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextField(
                  controller: titleController,
                  focusNode: titleFocusNode,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Journal Title',
                    border: InputBorder.none,
                    hintStyle: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Content field
                TextField(
                  controller: contentController,
                  focusNode: contentFocusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write your thoughts...',
                    border: InputBorder.none,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }



  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatLastEdited(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return 'on ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}