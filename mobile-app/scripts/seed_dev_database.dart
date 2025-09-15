#!/usr/bin/env dart
// Development utility script to manually seed the journal database with test data
// Run with: dart scripts/seed_dev_database.dart

import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  print('========================================');
  print('Development Database Seeder');
  print('========================================');
  print('');
  print('This script will seed your local development database with 60 days');
  print('of test journal entries for testing the Search and Calendar features.');
  print('');
  print('⚠️  WARNING: This should ONLY be used in development mode!');
  print('');
  print('To seed the database:');
  print('1. Make sure the app is NOT running');
  print('2. Run the app in debug mode');
  print('3. The database will be automatically seeded on first launch');
  print('');
  print('The seeding happens automatically when:');
  print('- The app is running in debug mode (flutter run)');
  print('- The database has fewer than 5 entries');
  print('');
  print('To reset and re-seed the database:');
  print('1. Delete the app from your device/emulator');
  print('2. Run the app again in debug mode');
  print('');
  print('Note: Seeding will NOT happen in release builds (APK files).');
  print('');
  print('========================================');

  // Check if we're in the right directory
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found.');
    print('   Please run this script from the project root directory.');
    exit(1);
  }

  // Check if Flutter is available
  final flutterResult = await Process.run('which', ['flutter']);
  final fvmResult = await Process.run('which', ['fvm']);

  if (flutterResult.exitCode != 0 && fvmResult.exitCode != 0) {
    print('❌ Error: Flutter not found in PATH.');
    print('   Please install Flutter or FVM.');
    exit(1);
  }

  final usesFvm = fvmResult.exitCode == 0;
  final flutterCmd = usesFvm ? 'fvm flutter' : 'flutter';

  print('');
  print('✅ Ready to use development seeding!');
  print('');
  print('Run the app with: $flutterCmd run');
  print('');
}