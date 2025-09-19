import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../widgets/daily_canvas/timeline_widget.dart';
import '../services/journal_service.dart';
import '../providers/photo_providers.dart';
import '../providers/media_thumbnail_provider.dart' show CachedThumbnailWidget;

/// Event Detail Screen with journal-like editing capabilities
class EventDetailScreen extends HookConsumerWidget {
  final TimelineEvent event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Editing state management
    final isEditing = useState(false);
    final titleController = useTextEditingController(text: event.title);
    final descriptionController = useTextEditingController(text: event.description);
    final notesController = useTextEditingController();
    final isSaving = useState(false);

    // Get event type color
    final eventColor = _getEventColor(event.type, colorScheme);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(isEditing.value ? 'Edit Event' : 'Event Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isEditing.value) ...[
            TextButton(
              onPressed: () {
                isEditing.value = false;
                titleController.text = event.title;
                descriptionController.text = event.description;
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: isSaving.value ? null : () => _saveEvent(
                ref, context,
                titleController.text,
                descriptionController.text,
                notesController.text,
                isSaving,
                isEditing,
              ),
              child: isSaving.value
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : Text('Save'),
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => isEditing.value = true,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Event Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      event.icon,
                      color: eventColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isEditing.value)
                          TextField(
                            controller: titleController,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Event title',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              isDense: true,
                            ),
                            maxLines: 1,
                          )
                        else
                          Text(
                            event.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              DateFormat('MMM d, h:mm a').format(event.time),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: eventColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getEventTypeDisplayName(event.type),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: eventColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (event.isCalendarEvent && event.calendarEventData?.location != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  event.calendarEventData!.location!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Event Description (if editing or exists)
            if (isEditing.value || event.description.isNotEmpty) ...[
              if (isEditing.value)
                TextField(
                  controller: descriptionController,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add a brief description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                  minLines: 2,
                )
              else if (event.description.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    event.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Photo Memories Section (if photos exist)
            _buildPhotoMemoriesSection(ref, context, theme, colorScheme),

            // Journal-Style Notes Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Journal Entry',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (!isEditing.value)
                          TextButton.icon(
                            onPressed: () => _generateAIContent(ref, context, notesController),
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('AI Generate'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capture your thoughts, reflections, and insights about this moment',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: notesController,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What made this moment special? How did you feel? What thoughts came to mind?\n\nStart typing or use AI Generate to create a reflection based on this event...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          height: 1.6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      maxLines: 12,
                      minLines: 8,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            if (isEditing.value)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        isEditing.value = false;
                        titleController.text = event.title;
                        descriptionController.text = event.description;
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isSaving.value ? null : () => _saveEvent(
                        ref, context,
                        titleController.text,
                        descriptionController.text,
                        notesController.text,
                        isSaving,
                        isEditing,
                      ),
                      child: isSaving.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Text('Save Changes'),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => isEditing.value = true,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Event'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _saveNotes(ref, context, notesController.text),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Journal Entry'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEvent(
    WidgetRef ref,
    BuildContext context,
    String title,
    String description,
    String notes,
    ValueNotifier<bool> isSaving,
    ValueNotifier<bool> isEditing,
  ) async {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    isSaving.value = true;

    try {
      final journalService = ref.read(journalServiceProvider);

      // Update the event in the database
      await journalService.updateEvent(
        eventId: _getEventId(event),
        title: title.trim(),
        description: description.trim(),
        notes: notes.trim(),
        timestamp: event.time,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully')),
        );
        isEditing.value = false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating event: $e')),
        );
      }
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _saveNotes(
    WidgetRef ref,
    BuildContext context,
    String notes,
  ) async {
    try {
      final journalService = ref.read(journalServiceProvider);

      // Save just the notes for this event
      await journalService.updateEventNotes(
        eventId: _getEventId(event),
        notes: notes.trim(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving journal entry: $e')),
        );
      }
    }
  }

  Future<void> _generateAIContent(
    WidgetRef ref,
    BuildContext context,
    TextEditingController notesController,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Generating AI reflection...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );

      final journalService = ref.read(journalServiceProvider);

      // Generate AI content based on the event
      final aiEntry = await journalService.generateEventReflection(
        event: event,
        existingNotes: notesController.text,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Update the notes field with AI generated content
        notesController.text = aiEntry;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI reflection generated! You can edit it as needed.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating AI content: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getEventId(TimelineEvent event) {
    // Generate a consistent ID based on event time and title
    return '${event.time.millisecondsSinceEpoch}_${event.title.hashCode}';
  }

  Widget _buildPhotoMemoriesSection(
    WidgetRef ref,
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Get the same photos that would be shown in the timeline
    final photosAsync = ref.watch(timelinePhotosProvider((
      date: DateTime(event.time.year, event.time.month, event.time.day),
      eventTime: event.time
    )));

    return photosAsync.when(
      data: (photos) {
        if (photos.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Photo Memories',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${photos.length} photo${photos.length != 1 ? 's' : ''}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedThumbnailWidget(
                            filePath: photo.filePath ?? '',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }


  Color _getEventColor(EventType type, ColorScheme colorScheme) {
    switch (type) {
      case EventType.routine:
        return colorScheme.primary;
      case EventType.work:
        return Colors.blue;
      case EventType.movement:
        return Colors.orange;
      case EventType.social:
        return Colors.purple;
      case EventType.exercise:
        return Colors.green;
      case EventType.leisure:
        return Colors.teal;
    }
  }

  String _getEventTypeDisplayName(EventType type) {
    switch (type) {
      case EventType.routine:
        return 'Routine';
      case EventType.work:
        return 'Work';
      case EventType.movement:
        return 'Movement';
      case EventType.social:
        return 'Social';
      case EventType.exercise:
        return 'Exercise';
      case EventType.leisure:
        return 'Leisure';
    }
  }

}