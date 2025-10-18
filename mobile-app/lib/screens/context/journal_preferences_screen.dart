import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../widgets/page_header.dart';
import '../../widgets/grouped_list_container.dart';
import '../../theme/colors.dart';
import '../../services/context_manager_service.dart';

class JournalPreferencesScreen extends ConsumerStatefulWidget {
  const JournalPreferencesScreen({super.key});

  @override
  ConsumerState<JournalPreferencesScreen> createState() =>
      _JournalPreferencesScreenState();
}

class _JournalPreferencesScreenState
    extends ConsumerState<JournalPreferencesScreen> {
  final _contextManager = ContextManagerService();

  String _detailLevel = 'medium';
  String _tone = 'reflective';
  String _length = 'medium';
  String _privacyLevel = 'balanced';
  int _locationSpecificity = 2;
  bool _includeHealthData = true;
  bool _includeWeather = true;
  bool _includeUnknownPeople = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final detailLevel = await _contextManager.getPreference('detail_level');
      final tone = await _contextManager.getPreference('tone');
      final length = await _contextManager.getPreference('length');
      final privacyLevel = await _contextManager.getPreference('privacy_level');
      final locationSpecificity =
          await _contextManager.getPreference('location_specificity');
      final includeHealthData =
          await _contextManager.getPreference('include_health_data');
      final includeWeather =
          await _contextManager.getPreference('include_weather');
      final includeUnknownPeople =
          await _contextManager.getPreference('include_unknown_people');

      setState(() {
        _detailLevel = detailLevel ?? 'medium';
        _tone = tone ?? 'reflective';
        _length = length ?? 'medium';
        _privacyLevel = privacyLevel ?? 'balanced';
        _locationSpecificity = int.tryParse(locationSpecificity ?? '2') ?? 2;
        _includeHealthData = includeHealthData != 'false';
        _includeWeather = includeWeather != 'false';
        _includeUnknownPeople = includeUnknownPeople == 'true';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _contextManager.setPreference('detail_level', _detailLevel);
      await _contextManager.setPreference('tone', _tone);
      await _contextManager.setPreference('length', _length);
      await _contextManager.setPreference('privacy_level', _privacyLevel);
      await _contextManager.setPreference(
          'location_specificity', _locationSpecificity.toString());
      await _contextManager.setPreference(
          'include_health_data', _includeHealthData.toString());
      await _contextManager.setPreference(
          'include_weather', _includeWeather.toString());
      await _contextManager.setPreference(
          'include_unknown_people', _includeUnknownPeople.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? [
                      AuraColors.lightSurface,
                      AuraColors.lightSurface.withValues(alpha: 0.95),
                      AuraColors.lightSurfaceContainerLow
                          .withValues(alpha: 0.9),
                    ]
                  : [
                      AuraColors.darkSurface,
                      AuraColors.darkSurface.withValues(alpha: 0.98),
                      AuraColors.darkSurfaceContainerLow
                          .withValues(alpha: 0.95),
                    ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? [
                    AuraColors.lightSurface,
                    AuraColors.lightSurface.withValues(alpha: 0.95),
                    AuraColors.lightSurfaceContainerLow.withValues(alpha: 0.9),
                  ]
                : [
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Expanded(
                            child: PageHeader(
                              icon: Icons.tune,
                              title: 'Journal Preferences',
                              subtitle: 'Customize how your journal is generated',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Detail Level
                      Text(
                        'Detail Level',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How much detail should your journal include?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GroupedListContainer(
                        isLight: isLight,
                        children: [
                          _buildRadioOption(
                            title: 'Low',
                            subtitle: 'Brief summaries, main highlights only',
                            value: 'low',
                            groupValue: _detailLevel,
                            onChanged: (value) =>
                                setState(() => _detailLevel = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'Medium',
                            subtitle:
                                'Balanced detail with key moments and context',
                            value: 'medium',
                            groupValue: _detailLevel,
                            onChanged: (value) =>
                                setState(() => _detailLevel = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'High',
                            subtitle: 'Comprehensive entries with rich details',
                            value: 'high',
                            groupValue: _detailLevel,
                            onChanged: (value) =>
                                setState(() => _detailLevel = value!),
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tone
                      Text(
                        'Writing Tone',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What style should your journal use?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GroupedListContainer(
                        isLight: isLight,
                        children: [
                          _buildRadioOption(
                            title: 'Casual',
                            subtitle: 'Friendly and conversational',
                            value: 'casual',
                            groupValue: _tone,
                            onChanged: (value) =>
                                setState(() => _tone = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'Reflective',
                            subtitle: 'Thoughtful and introspective',
                            value: 'reflective',
                            groupValue: _tone,
                            onChanged: (value) =>
                                setState(() => _tone = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'Professional',
                            subtitle: 'Structured and objective',
                            value: 'professional',
                            groupValue: _tone,
                            onChanged: (value) =>
                                setState(() => _tone = value!),
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Length
                      Text(
                        'Entry Length',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How long should each journal entry be?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GroupedListContainer(
                        isLight: isLight,
                        children: [
                          _buildRadioOption(
                            title: 'Short',
                            subtitle: 'Quick summaries (1-2 paragraphs)',
                            value: 'short',
                            groupValue: _length,
                            onChanged: (value) =>
                                setState(() => _length = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'Medium',
                            subtitle: 'Standard entries (3-4 paragraphs)',
                            value: 'medium',
                            groupValue: _length,
                            onChanged: (value) =>
                                setState(() => _length = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'Long',
                            subtitle: 'Detailed narratives (5+ paragraphs)',
                            value: 'long',
                            groupValue: _length,
                            onChanged: (value) =>
                                setState(() => _length = value!),
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Privacy Level
                      Text(
                        'Default Privacy Level',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How much personal information to include by default?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GroupedListContainer(
                        isLight: isLight,
                        children: [
                          _buildRadioOption(
                            title: 'Minimal',
                            subtitle:
                                'First names only, general locations',
                            value: 'minimal',
                            groupValue: _privacyLevel,
                            onChanged: (value) =>
                                setState(() => _privacyLevel = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'Balanced',
                            subtitle:
                                'Full names for known people, specific locations',
                            value: 'balanced',
                            groupValue: _privacyLevel,
                            onChanged: (value) =>
                                setState(() => _privacyLevel = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'Detailed',
                            subtitle:
                                'All context including relationships and addresses',
                            value: 'detailed',
                            groupValue: _privacyLevel,
                            onChanged: (value) =>
                                setState(() => _privacyLevel = value!),
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Location Specificity
                      Text(
                        'Location Detail',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How specific should location information be?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GroupedListContainer(
                        isLight: isLight,
                        children: [
                          _buildRadioOption(
                            title: 'City Only',
                            subtitle: 'Just mention the city name',
                            value: 0,
                            groupValue: _locationSpecificity,
                            onChanged: (value) =>
                                setState(() => _locationSpecificity = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'Neighborhood',
                            subtitle: 'Include neighborhood or district',
                            value: 1,
                            groupValue: _locationSpecificity,
                            onChanged: (value) =>
                                setState(() => _locationSpecificity = value!),
                            theme: theme,
                          ),
                          _buildRadioOption(
                            title: 'Named Places',
                            subtitle:
                                'Use custom place names when available',
                            value: 2,
                            groupValue: _locationSpecificity,
                            onChanged: (value) =>
                                setState(() => _locationSpecificity = value!),
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Additional Settings
                      Text(
                        'Include in Journal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose what types of data to include',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GroupedListContainer(
                        isLight: isLight,
                        children: [
                          _buildSwitchOption(
                            icon: Icons.favorite,
                            title: 'Health & Activity Data',
                            subtitle:
                                'Steps, workouts, and wellness metrics',
                            value: _includeHealthData,
                            onChanged: (value) =>
                                setState(() => _includeHealthData = value),
                            theme: theme,
                          ),
                          _buildSwitchOption(
                            icon: Icons.wb_sunny,
                            title: 'Weather Information',
                            subtitle: 'Temperature, conditions, and forecasts',
                            value: _includeWeather,
                            onChanged: (value) =>
                                setState(() => _includeWeather = value),
                            theme: theme,
                          ),
                          _buildSwitchOption(
                            icon: Icons.person_outline,
                            title: 'Unknown People',
                            subtitle:
                                'Mention detected faces not yet labeled',
                            value: _includeUnknownPeople,
                            onChanged: (value) =>
                                setState(() => _includeUnknownPeople = value),
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Save Button (sticky at bottom)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLight
                      ? AuraColors.lightSurface
                      : AuraColors.darkSurface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _savePreferences,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8A87C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    required ThemeData theme,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFFE8A87C),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFFE8A87C)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
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

  Widget _buildSwitchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFE8A87C),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}
