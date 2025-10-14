
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/voice_editing_service.dart';
import '../../services/nlp_command_parser.dart';
import '../../services/journal_service.dart';
import '../../database/journal_database.dart';
import '../voice_permission_fallback.dart';

// Provider for journal entry using the journal service
// Using distinct() to prevent rebuilds when data hasn't changed
final journalEntryProvider = StreamProvider.family<JournalEntry?, DateTime>((ref, date) {
  final journalService = ref.watch(journalServiceProvider);
  return journalService.watchEntryForDate(date).distinct((prev, next) {
    // Only rebuild if the entry actually changed
    if (prev == null && next == null) return true;
    if (prev == null || next == null) return false;
    return prev.id == next.id &&
        prev.title == next.title &&
        prev.content == next.content &&
        prev.updatedAt == next.updatedAt;
  });
});

// Provider for edit mode
final journalEditModeProvider = StateProvider<bool>((ref) => false);

// Provider for loading state
final journalLoadingProvider = StateProvider<bool>((ref) => false);

class JournalEditorWidget extends HookConsumerWidget {
  final DateTime date;

  const JournalEditorWidget({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final journalEntryAsync = ref.watch(journalEntryProvider(date));
    final isEditMode = ref.watch(journalEditModeProvider);
    final isLoading = ref.watch(journalLoadingProvider);

    return journalEntryAsync.when(
      data: (journalEntry) => _buildContent(
        context,
        ref,
        theme,
        journalEntry,
        isEditMode,
        isLoading,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading journal entry',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    JournalEntry? journalEntry,
    bool isEditMode,
    bool isLoading,
  ) {
    // Text controllers
    final titleController = useTextEditingController(text: journalEntry?.title ?? '');
    final contentController = useTextEditingController(text: journalEntry?.content ?? '');

    // Focus nodes
    final titleFocusNode = useFocusNode();
    final contentFocusNode = useFocusNode();

    // Voice editing states
    final voiceService = ref.read(voiceEditingServiceProvider);
    final isListening = useState(false);
    final voiceTranscription = useState('');
    final isSpeaking = useState(false);

    // Initialize voice service
    useEffect(() {
      voiceService.onSpeechResult = (result) {
        voiceTranscription.value = result;
      };

      voiceService.onListeningStateChanged = (listening) {
        isListening.value = listening;
      };

      voiceService.onError = (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      };

      return () {
        voiceService.stopListening();
        voiceService.stopSpeaking();
      };
    }, []);

    return Skeletonizer(
      enabled: isLoading,
      child: Column(
        children: [
          // Editor toolbar
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
                // Word count
                if (journalEntry != null)
                  Text(
                    '${journalEntry.content.split(' ').length} words',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                const Spacer(),

                // Voice controls (only in edit mode)
                if (isEditMode) ...[
                  // Voice input button with permission handling
                  VoiceInputButton(
                    isListening: isListening.value,
                    onTextReceived: (text) {
                      voiceTranscription.value = text;
                      _handleVoiceCommand(
                        context,
                        contentController,
                        text,
                        voiceService,
                      );
                    },
                    onListeningStateChanged: () async {
                      if (isListening.value) {
                        await voiceService.stopListening();
                        if (voiceTranscription.value.isNotEmpty && context.mounted) {
                          _handleVoiceCommand(
                            context,
                            contentController,
                            voiceTranscription.value,
                            voiceService,
                          );
                        }
                      } else {
                        if (context.mounted) {
                          await voiceService.startListening(context: context);
                        }
                      }
                    },
                  ),

                  // Text-to-speech button
                  IconButton(
                    icon: Icon(
                      isSpeaking.value ? Icons.volume_off : Icons.volume_up,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    onPressed: () async {
                      if (isSpeaking.value) {
                        await voiceService.stopSpeaking();
                        isSpeaking.value = false;
                      } else {
                        final textToRead = contentController.text.isEmpty
                          ? 'No content to read'
                          : contentController.text;
                        isSpeaking.value = true;
                        await voiceService.speak(textToRead);
                        isSpeaking.value = false;
                      }
                    },
                    tooltip: isSpeaking.value ? 'Stop reading' : 'Read content',
                  ),

                  const SizedBox(width: 8),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 8),
                ],

                // Formatting buttons (only in edit mode)
                if (isEditMode) ...[
                  _buildFormatButton(
                    icon: Icons.format_bold,
                    onPressed: () => _insertMarkdown(contentController, '**', '**'),
                    tooltip: 'Bold',
                    theme: theme,
                  ),
                  const SizedBox(width: 4),
                  _buildFormatButton(
                    icon: Icons.format_italic,
                    onPressed: () => _insertMarkdown(contentController, '_', '_'),
                    tooltip: 'Italic',
                    theme: theme,
                  ),
                  const SizedBox(width: 4),
                  _buildFormatButton(
                    icon: Icons.format_list_bulleted,
                    onPressed: () => _insertMarkdown(contentController, '- ', ''),
                    tooltip: 'Bullet list',
                    theme: theme,
                  ),
                  const SizedBox(width: 4),
                  _buildFormatButton(
                    icon: Icons.format_quote,
                    onPressed: () => _insertMarkdown(contentController, '> ', ''),
                    tooltip: 'Quote',
                    theme: theme,
                  ),
                  const SizedBox(width: 12),
                ],

                // Edit/Save button
                IconButton(
                  icon: Icon(isEditMode ? Icons.check : Icons.edit),
                  onPressed: () async {
                    if (isEditMode) {
                      // Save the journal entry using the journal service
                      ref.read(journalLoadingProvider.notifier).state = true;

                      try {
                        final journalService = ref.read(journalServiceProvider);

                        if (journalEntry == null) {
                          // Create new entry (shouldn't happen since we auto-create, but just in case)
                          await journalService.createEntryForDate(date);
                        } else {
                          // Update existing entry
                          await journalService.updateJournalEntry(
                            id: journalEntry.id,
                            title: titleController.text.trim().isNotEmpty
                                ? titleController.text.trim()
                                : null,
                            content: contentController.text.trim().isNotEmpty
                                ? contentController.text.trim()
                                : null,
                          );
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Journal entry saved!')),
                          );
                        }
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
                        ref.read(journalLoadingProvider.notifier).state = false;
                      }
                    }
                    ref.read(journalEditModeProvider.notifier).state = !isEditMode;
                  },
                  tooltip: isEditMode ? 'Save' : 'Edit',
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          // Voice transcription indicator
          if (isListening.value && voiceTranscription.value.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voiceTranscription.value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Journal content
          Expanded(
            child: journalEntry == null && !isEditMode
                ? _buildEmptyState(theme, ref, context)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        if (isEditMode)
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
                          )
                        else if (journalEntry != null)
                          Text(
                            journalEntry.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        const SizedBox(height: 8),


                        // Content
                        if (isEditMode)
                          TextField(
                            controller: contentController,
                            focusNode: contentFocusNode,
                            maxLines: null,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write your thoughts...\n\nYou can use Markdown formatting:\n- **Bold** text\n- _Italic_ text\n- # Headers\n- Lists and more',
                              border: InputBorder.none,
                              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                height: 1.6,
                              ),
                            ),
                          )
                        else if (journalEntry != null)
                          MarkdownWidget(
                            data: journalEntry.content,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            config: MarkdownConfig(
                              configs: [
                                PConfig(
                                  textStyle: theme.textTheme.bodyLarge?.copyWith(height: 1.6) ?? const TextStyle(height: 1.6),
                                ),
                                H1Config(
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.8,
                                  ) ?? const TextStyle(fontWeight: FontWeight.bold, height: 1.8),
                                ),
                                H2Config(
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.6,
                                  ) ?? const TextStyle(fontWeight: FontWeight.bold, height: 1.6),
                                ),
                                H3Config(
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.5,
                                  ) ?? const TextStyle(fontWeight: FontWeight.bold, height: 1.5),
                                ),
                                const BlockquoteConfig(),
                              ],
                            ),
                          ),

                        // Last edited info
                        if (journalEntry != null && !isEditMode) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Last edited ${_formatLastEdited(journalEntry.updatedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, WidgetRef ref, BuildContext context) {
    return Center(
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
            'Start writing to capture your thoughts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              ref.read(journalLoadingProvider.notifier).state = true;
              try {
                final journalService = ref.read(journalServiceProvider);
                await journalService.createEntryForDate(date);
                ref.read(journalEditModeProvider.notifier).state = true;
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create entry: $error'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              } finally {
                ref.read(journalLoadingProvider.notifier).state = false;
              }
            },
            icon: const Icon(Icons.create),
            label: const Text('Start Writing'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required ThemeData theme,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: 20,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      tooltip: tooltip,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );
  }

  void _insertMarkdown(TextEditingController controller, String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.start == selection.end) {
      // No selection, just insert at cursor
      final newText = text.substring(0, selection.start) +
          prefix +
          suffix +
          text.substring(selection.start);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    } else {
      // Wrap selected text
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.substring(0, selection.start) +
          prefix +
          selectedText +
          suffix +
          text.substring(selection.end);
      controller.text = newText;
      controller.selection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.end + prefix.length,
      );
    }
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

  void _handleVoiceCommand(
    BuildContext context,
    TextEditingController controller,
    String voiceInput,
    VoiceEditingService voiceService,
  ) {
    // Parse the voice command
    final command = NLPCommandParser.parse(voiceInput);

    // Apply the command to the text
    final currentText = controller.text;
    final updatedText = NLPCommandParser.applyCommand(currentText, command);

    // Update the controller if text changed
    if (updatedText != currentText) {
      controller.text = updatedText;

      // Provide feedback
      String feedback = '';
      switch (command.type) {
        case EditingCommandType.rewrite:
          feedback = 'Rewriting ${command.target ?? "text"}';
          break;
        case EditingCommandType.addDetail:
          feedback = 'Adding details';
          break;
        case EditingCommandType.removeSection:
          feedback = 'Removing ${command.target ?? "section"}';
          break;
        case EditingCommandType.replaceText:
          feedback = 'Replacing text';
          break;
        case EditingCommandType.insertText:
          feedback = 'Inserting text';
          break;
        case EditingCommandType.summarize:
          feedback = 'Summarizing content';
          break;
        case EditingCommandType.expand:
          feedback = 'Expanding content';
          break;
        case EditingCommandType.correct:
          feedback = 'Correcting text';
          break;
        case EditingCommandType.unknown:
          feedback = 'Command not recognized: $voiceInput';
          break;
      }

      // Show feedback and optionally speak it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedback)),
      );

      // Speak the feedback
      voiceService.speak(feedback);
    } else {
      // No changes made
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes made for: $voiceInput')),
      );
    }
  }
}
