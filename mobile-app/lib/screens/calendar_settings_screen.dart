import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/calendar_service.dart';
import '../providers/settings_providers.dart';
import '../widgets/page_header.dart';
import '../widgets/grouped_list_container.dart';
import '../theme/colors.dart';

class CalendarSettingsScreen extends ConsumerStatefulWidget {
  const CalendarSettingsScreen({super.key});

  @override
  ConsumerState<CalendarSettingsScreen> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends ConsumerState<CalendarSettingsScreen> {
  final CalendarService _calendarService = CalendarService();
  List<CalendarMetadata> _calendars = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check permissions first
    _hasPermission = await _calendarService.hasPermissions();

    if (!_hasPermission) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Force refresh to ensure we get the latest calendars
      final calendars = await _calendarService.getCalendars(forceRefresh: true);

      // Enable all calendars by default on first load
      final calendarIds = calendars.map((c) => c.id).toList();
      await ref.read(calendarSettingsProvider.notifier).enableAllCalendarsIfFirstTime(calendarIds);

      setState(() {
        _calendars = calendars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load calendars';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _calendarService.requestPermissions();
    if (granted) {
      await _loadCalendars();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calendar permission is required to use this feature'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final calendarSettings = ref.watch(calendarSettingsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight ? [
              AuraColors.lightSurface,
              AuraColors.lightSurface.withValues(alpha: 0.95),
              AuraColors.lightSurfaceContainerLow.withValues(alpha: 0.9),
            ] : [
              AuraColors.darkSurface,
              AuraColors.darkSurface.withValues(alpha: 0.98),
              AuraColors.darkSurfaceContainerLow.withValues(alpha: 0.95),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageHeader(
                        icon: Icons.calendar_month,
                        title: 'Calendar Settings',
                        subtitle: 'Choose which calendars to include in your journal',
                      ),
                      const SizedBox(height: 32),

                      if (_isLoading)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48.0),
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      else if (!_hasPermission)
                        _buildPermissionRequest(theme, isLight)
                      else if (_errorMessage != null)
                        _buildErrorMessage(theme, isLight)
                      else if (_calendars.isEmpty)
                        _buildNoCalendarsMessage(theme, isLight)
                      else
                        _buildCalendarsList(theme, isLight, calendarSettings),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRequest(ThemeData theme, bool isLight) {
    return GroupedListContainer(
      isLight: isLight,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Calendar Access Required',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Grant calendar access to sync your events with your journal timeline',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.lock_open),
                label: const Text('Grant Access'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(ThemeData theme, bool isLight) {
    return GroupedListContainer(
      isLight: isLight,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadCalendars,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoCalendarsMessage(ThemeData theme, bool isLight) {
    return GroupedListContainer(
      isLight: isLight,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Calendars Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No calendars were found on this device.\nMake sure you have at least one calendar account configured in your device settings.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      await _loadCalendars();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () async {
                      // Open system calendar settings
                      await _calendarService.requestPermissions();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarsList(ThemeData theme, bool isLight, CalendarSettings settings) {
    // Check if all calendars are enabled
    final allCalendarIds = _calendars.map((c) => c.id).toList();
    final allEnabled = allCalendarIds.every((id) => settings.enabledCalendarIds.contains(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info text
        Text(
          'Select Calendars',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which calendars to include in your timeline and AI-generated journal entries. Disabled calendars will be excluded from all features.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),

        // Select all toggle
        GroupedListContainer(
          isLight: isLight,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.select_all,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'All Calendars',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Enable or disable all calendars at once',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              trailing: Switch(
                value: allEnabled,
                onChanged: (value) {
                  ref.read(calendarSettingsProvider.notifier)
                      .setAllCalendarsEnabled(allCalendarIds, value);
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Individual calendars
        Text(
          'Individual Calendars',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        GroupedListContainer(
          isLight: isLight,
          children: _calendars.map((calendar) {
            final isEnabled = settings.enabledCalendarIds.contains(calendar.id);

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (calendar.color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.circle,
                  color: calendar.color ?? theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                calendar.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (calendar.accountName != null)
                    Text(
                      calendar.accountName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  if (calendar.isReadOnly)
                    Text(
                      'Read-only',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              trailing: Switch(
                value: isEnabled,
                onChanged: (value) {
                  ref.read(calendarSettingsProvider.notifier)
                      .setCalendarEnabled(calendar.id, value);
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            );
          }).toList(),
        ),
      ],
    );
  }
}