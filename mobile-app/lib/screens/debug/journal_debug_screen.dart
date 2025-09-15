import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../database/journal_database.dart';
import '../../database/dev_seed_data.dart';
import '../../services/journal_service.dart';
import '../../utils/logger.dart';

final _logger = AppLogger('JournalDebugScreen');

class JournalDebugScreen extends HookConsumerWidget {
  const JournalDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final journalDb = ref.watch(journalDatabaseProvider);

    final statistics = useState<Map<String, int>?>(null);
    final recentEntries = useState<List<JournalEntry>>([]);
    final isLoading = useState(true);
    final seedingStatus = useState<String>('');

    // Load statistics and recent entries
    useEffect(() {
      void loadData() async {
        isLoading.value = true;
        try {
          final stats = await journalDb.getJournalStatistics();
          statistics.value = stats;

          final entries = await journalDb.getJournalEntriesBetween(
            DateTime.now().subtract(const Duration(days: 10)),
            DateTime.now(),
          );
          recentEntries.value = entries;

          _logger.info('Journal Debug - Stats: $stats, Recent entries: ${entries.length}');
        } catch (e) {
          _logger.error('Error loading journal debug data', error: e);
        } finally {
          isLoading.value = false;
        }
      }

      loadData();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Database Debug'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              isLoading.value = true;
              useEffect(() {
                void loadData() async {
                  final stats = await journalDb.getJournalStatistics();
                  statistics.value = stats;

                  final entries = await journalDb.getJournalEntriesBetween(
                    DateTime.now().subtract(const Duration(days: 10)),
                    DateTime.now(),
                  );
                  recentEntries.value = entries;
                  isLoading.value = false;
                }
                loadData();
                return null;
              }, []);
            },
          ),
        ],
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Debug Mode Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug Mode Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                kDebugMode ? Icons.bug_report : Icons.verified,
                                color: kDebugMode ? Colors.orange : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                kDebugMode ? 'DEBUG MODE' : 'RELEASE MODE',
                                style: TextStyle(
                                  color: kDebugMode ? Colors.orange : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kDebugMode
                                ? 'Seeding is enabled and should work automatically'
                                : 'Seeding is disabled in release mode',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Database Statistics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Database Statistics',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (statistics.value != null) ...[
                            _buildStatRow('Total Entries', statistics.value!['total_entries']?.toString() ?? '0'),
                            _buildStatRow('Auto Generated', statistics.value!['auto_generated']?.toString() ?? '0'),
                            _buildStatRow('User Edited', statistics.value!['user_edited']?.toString() ?? '0'),
                            _buildStatRow('This Month', statistics.value!['this_month']?.toString() ?? '0'),
                          ] else
                            const Text('No statistics available'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Seeding Controls (Debug Mode Only)
                  if (kDebugMode) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Development Seeding',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (seedingStatus.value.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  seedingStatus.value,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      seedingStatus.value = 'Checking if seeding is needed...';
                                      try {
                                        final shouldSeed = await DevSeedData.shouldSeedDatabase(journalDb);
                                        if (shouldSeed) {
                                          seedingStatus.value = 'Seeding database with 60 days of test data...';
                                          await DevSeedData.seedDatabase(journalDb);
                                          seedingStatus.value = '✅ Seeding completed successfully!';
                                        } else {
                                          seedingStatus.value = 'Database already has data, seeding not needed.';
                                        }

                                        // Refresh data
                                        final stats = await journalDb.getJournalStatistics();
                                        statistics.value = stats;

                                        final entries = await journalDb.getJournalEntriesBetween(
                                          DateTime.now().subtract(const Duration(days: 10)),
                                          DateTime.now(),
                                        );
                                        recentEntries.value = entries;
                                      } catch (e) {
                                        seedingStatus.value = '❌ Seeding failed: $e';
                                        _logger.error('Manual seeding failed', error: e);
                                      }
                                    },
                                    icon: const Icon(Icons.scatter_plot),
                                    label: const Text('Seed Database'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      seedingStatus.value = 'Checking seeding requirements...';
                                      try {
                                        final shouldSeed = await DevSeedData.shouldSeedDatabase(journalDb);
                                        final stats = await journalDb.getJournalStatistics();
                                        final total = stats['total_entries'] ?? 0;

                                        if (shouldSeed) {
                                          seedingStatus.value = 'ℹ️ Database has $total entries. Seeding would be triggered (threshold: <5 entries).';
                                        } else {
                                          seedingStatus.value = 'ℹ️ Database has $total entries. Seeding would NOT be triggered (threshold: <5 entries).';
                                        }
                                      } catch (e) {
                                        seedingStatus.value = '❌ Check failed: $e';
                                      }
                                    },
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('Check Status'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],

                  // Recent Entries
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Entries (Last 10 Days)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (recentEntries.value.isEmpty)
                            const Text('No recent entries found')
                          else
                            ...recentEntries.value.take(10).map((entry) =>
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(entry.date),
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (entry.isAutoGenerated)
                                              Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                                            if (entry.isEdited)
                                              Icon(Icons.edit, size: 16, color: Colors.green),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.title,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (entry.mood != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mood: ${entry.mood}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}