import 'package:flutter/material.dart';
import '../services/ai_pipeline_tester.dart';
import '../database/media_database.dart';
import '../database/location_database.dart';

/// Quick test function to validate AI pipeline functionality
/// Can be called from debug screens or during development
Future<void> testAIPipeline(BuildContext context) async {
  try {
    // Initialize the tester
    final tester = AIPipelineTester();

    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Running AI Pipeline Tests...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Create mock databases for testing
    final mediaDatabase = MediaDatabase();
    final locationDatabase = LocationDatabase();

    // Run quick health check first
    debugPrint('🩺 Running AI Pipeline Health Check...');
    final healthCheck = await tester.quickHealthCheck();

    if (!healthCheck) {
      throw Exception('AI Pipeline Health Check failed');
    }

    debugPrint('✅ Health Check passed');

    // Run comprehensive tests
    debugPrint('🔬 Running Comprehensive AI Pipeline Tests...');
    final results = await tester.runComprehensiveTests(
      mediaDatabase: mediaDatabase,
      locationDatabase: locationDatabase,
    );

    // Display results
    debugPrint('📊 Test Results:');
    debugPrint(results.summary);

    // Show success/failure notification
    if (context.mounted) {
      if (results.allTestsPassed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ AI Pipeline Tests Passed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ AI Pipeline Tests Failed: ${results.extractionErrors.length + results.synthesisErrors.length} errors'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    // Generate detailed report
    final report = tester.generateTestReport(results);
    debugPrint('📋 Detailed Test Report:');
    debugPrint(report);

  } catch (e) {
    debugPrint('❌ AI Pipeline Test Error: $e');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Test Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

/// Widget for testing AI pipeline in debug screens
class AIPipelineTestWidget extends StatelessWidget {
  const AIPipelineTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 AI Pipeline Testing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test the AI feature extraction and daily context synthesis pipeline.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => testAIPipeline(context),
                  icon: const Icon(Icons.science),
                  label: const Text('Run AI Tests'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final tester = AIPipelineTester();
                    final passed = await tester.quickHealthCheck();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(passed ? '✅ Health Check Passed' : '❌ Health Check Failed'),
                          backgroundColor: passed ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Health Check'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}