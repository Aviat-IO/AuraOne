import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../export/enhanced_encryption_service.dart';
import 'backup_manager.dart';
import '../../utils/logger.dart';

/// Test class for backup encryption functionality
/// This class provides methods to test and validate the enhanced encryption system
class BackupEncryptionTest {
  /// Test basic encryption key generation and storage
  static Future<Map<String, dynamic>> testKeyGeneration() async {
    final result = <String, dynamic>{};
    
    try {
      // Test automatic key generation
      final keyInfo = await EnhancedEncryptionService.generateSecureBackupPassword();
      
      result['success'] = true;
      result['password_length'] = keyInfo.password.length;
      result['key_length'] = keyInfo.encryptionKey.length;
      result['salt_length'] = keyInfo.salt.length;
      result['recovery_info_available'] = keyInfo.recoveryInfo != null;
      
      if (keyInfo.recoveryInfo != null) {
        result['device_identifier_length'] = keyInfo.recoveryInfo!.deviceIdentifier.length;
        result['derivation_method'] = keyInfo.recoveryInfo!.derivationMethod;
        result['iterations'] = keyInfo.recoveryInfo!.iterations;
      }
      
    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
    }
    
    return result;
  }

  /// Test metadata encryption and decryption
  static Future<Map<String, dynamic>> testMetadataEncryption() async {
    final result = <String, dynamic>{};
    
    try {
      // Test data
      final testMetadata = {
        'version': '1.0',
        'entry_count': 150,
        'media_count': 25,
        'created_at': DateTime.now().toIso8601String(),
        'test_data': 'This is sensitive backup metadata',
      };
      
      // Generate key
      final keyInfo = await EnhancedEncryptionService.generateSecureBackupPassword();
      
      // Encrypt metadata
      final encryptedMetadata = await EnhancedEncryptionService.encryptBackupMetadata(
        testMetadata,
        customKey: keyInfo,
      );
      
      // Decrypt metadata
      final decryptedMetadata = await EnhancedEncryptionService.decryptBackupMetadata(
        encryptedMetadata,
      );
      
      // Verify data integrity
      final originalJson = jsonEncode(testMetadata);
      final decryptedFiltered = Map<String, dynamic>.from(decryptedMetadata);
      
      // Remove added encryption metadata for comparison
      decryptedFiltered.remove('encrypted_at');
      decryptedFiltered.remove('encryption_version');
      decryptedFiltered.remove('device_id_hash');
      
      final decryptedJson = jsonEncode(decryptedFiltered);
      
      result['success'] = originalJson == decryptedJson;
      result['original_size'] = originalJson.length;
      result['encrypted_size'] = encryptedMetadata.encryptedData.ciphertext.length;
      result['has_iv'] = encryptedMetadata.encryptedData.iv.length == 12; // GCM IV size
      result['integrity_verified'] = originalJson == decryptedJson;
      
    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
    }
    
    return result;
  }

  /// Test large file encryption performance
  static Future<Map<String, dynamic>> testLargeFileEncryption() async {
    final result = <String, dynamic>{};
    
    try {
      // Create test data of various sizes
      final testSizes = [1024, 10240, 102400]; // 1KB, 10KB, 100KB
      
      for (int i = 0; i < testSizes.length; i++) {
        final size = testSizes[i];
        final testData = List.generate(size, (index) => index % 256);
        final testBytes = Uint8List.fromList(testData);
        
        final keyInfo = await EnhancedEncryptionService.generateSecureBackupPassword();
        
        // Test encryption
        final encryptionStopwatch = Stopwatch()..start();
        final encryptedBytes = await EnhancedEncryptionService.encryptLargeFile(
          testBytes,
          customKey: keyInfo,
        );
        encryptionStopwatch.stop();
        
        // Test decryption
        final decryptionStopwatch = Stopwatch()..start();
        final decryptedBytes = await EnhancedEncryptionService.decryptLargeFile(
          encryptedBytes,
          keyInfo,
        );
        decryptionStopwatch.stop();
        
        // Verify integrity
        final integrityOk = testBytes.length == decryptedBytes.length;
        if (integrityOk) {
          for (int j = 0; j < testBytes.length; j++) {
            if (testBytes[j] != decryptedBytes[j]) {
              result['integrity_error_$size'] = 'Byte mismatch at position $j';
              break;
            }
          }
        }
        
        result['size_${size}_bytes'] = {
          'original_size': testBytes.length,
          'encrypted_size': encryptedBytes.length,
          'encryption_time_ms': encryptionStopwatch.elapsedMilliseconds,
          'decryption_time_ms': decryptionStopwatch.elapsedMilliseconds,
          'integrity_ok': integrityOk,
        };
      }
      
      result['success'] = true;
      
    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
    }
    
    return result;
  }

  /// Test key recovery functionality
  static Future<Map<String, dynamic>> testKeyRecovery() async {
    final result = <String, dynamic>{};
    
    try {
      // Generate original key
      final originalKeyInfo = await EnhancedEncryptionService.generateSecureBackupPassword();
      
      if (originalKeyInfo.recoveryInfo == null) {
        throw Exception('Recovery info not generated');
      }
      
      // Clear keys to simulate device transfer
      await EnhancedEncryptionService.clearAllBackupKeys();
      
      // Verify keys are cleared
      final keysCleared = !await EnhancedEncryptionService.isBackupEncryptionConfigured();
      
      // Recover keys using recovery info and password
      final recoveredKeyInfo = await EnhancedEncryptionService.recoverKeyFromRecoveryInfo(
        originalKeyInfo.recoveryInfo!,
        originalKeyInfo.password,
      );
      
      if (recoveredKeyInfo == null) {
        throw Exception('Key recovery failed');
      }
      
      // Test that recovered key can encrypt/decrypt data
      final testData = 'Recovery test data for validation';
      final testBytes = Uint8List.fromList(utf8.encode(testData));
      
      final encryptedBytes = await EnhancedEncryptionService.encryptLargeFile(
        testBytes,
        customKey: recoveredKeyInfo,
      );
      
      final decryptedBytes = await EnhancedEncryptionService.decryptLargeFile(
        encryptedBytes,
        recoveredKeyInfo,
      );
      
      final recoveredText = utf8.decode(decryptedBytes);
      
      result['success'] = true;
      result['keys_cleared'] = keysCleared;
      result['password_matches'] = originalKeyInfo.password == recoveredKeyInfo.password;
      result['data_recovery_works'] = testData == recoveredText;
      result['original_device_id'] = '${originalKeyInfo.recoveryInfo!.deviceIdentifier.substring(0, 8)}...';
      
    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
    }
    
    return result;
  }

  /// Test full BackupManager integration
  static Future<Map<String, dynamic>> testBackupManagerIntegration() async {
    final result = <String, dynamic>{};
    
    try {
      final backupManager = BackupManager.instance;
      
      // Initialize backup manager (this should set up encryption)
      await backupManager.initialize();
      
      // Check if encryption is configured
      final encryptionConfigured = await EnhancedEncryptionService.isBackupEncryptionConfigured();
      
      // Get encryption info
      final keyInfo = await backupManager.getBackupEncryptionInfo();
      
      result['success'] = true;
      result['encryption_configured'] = encryptionConfigured;
      result['key_info_available'] = keyInfo != null;
      
      if (keyInfo != null) {
        result['password_length'] = keyInfo.password.length;
        result['has_recovery_info'] = keyInfo.recoveryInfo != null;
      }
      
      // Test key regeneration
      final newKeyInfo = await backupManager.regenerateBackupEncryption();
      result['regeneration_successful'] = newKeyInfo.password != keyInfo?.password;
      
    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
    }
    
    return result;
  }

  /// Run all tests and return comprehensive results
  static Future<Map<String, dynamic>> runAllTests() async {
    final logger = AppLogger('BackupEncryptionTest');
    final allResults = <String, dynamic>{};

    logger.info('🔐 Running Backup Encryption Tests...\n');
    
    // Test 1: Key Generation
    logger.info('1. Testing Key Generation...');
    final keyGenResults = await testKeyGeneration();
    allResults['key_generation'] = keyGenResults;
    logger.info('   ${keyGenResults['success'] ? '✅' : '❌'} ${keyGenResults['success'] ? 'PASSED' : 'FAILED: ${keyGenResults['error']}'}');

    // Test 2: Metadata Encryption
    logger.info('2. Testing Metadata Encryption...');
    final metadataResults = await testMetadataEncryption();
    allResults['metadata_encryption'] = metadataResults;
    logger.info('   ${metadataResults['success'] ? '✅' : '❌'} ${metadataResults['success'] ? 'PASSED' : 'FAILED: ${metadataResults['error']}'}');

    // Test 3: Large File Encryption
    logger.info('3. Testing Large File Encryption...');
    final fileEncResults = await testLargeFileEncryption();
    allResults['large_file_encryption'] = fileEncResults;
    logger.info('   ${fileEncResults['success'] ? '✅' : '❌'} ${fileEncResults['success'] ? 'PASSED' : 'FAILED: ${fileEncResults['error']}'}');

    // Test 4: Key Recovery
    logger.info('4. Testing Key Recovery...');
    final recoveryResults = await testKeyRecovery();
    allResults['key_recovery'] = recoveryResults;
    logger.info('   ${recoveryResults['success'] ? '✅' : '❌'} ${recoveryResults['success'] ? 'PASSED' : 'FAILED: ${recoveryResults['error']}'}');

    // Test 5: BackupManager Integration
    logger.info('5. Testing BackupManager Integration...');
    final integrationResults = await testBackupManagerIntegration();
    allResults['backup_manager_integration'] = integrationResults;
    logger.info('   ${integrationResults['success'] ? '✅' : '❌'} ${integrationResults['success'] ? 'PASSED' : 'FAILED: ${integrationResults['error']}'}');
    
    // Overall summary
    final totalTests = 5;
    final passedTests = [
      keyGenResults['success'],
      metadataResults['success'],
      fileEncResults['success'],
      recoveryResults['success'],
      integrationResults['success'],
    ].where((test) => test == true).length;
    
    allResults['summary'] = {
      'total_tests': totalTests,
      'passed_tests': passedTests,
      'failed_tests': totalTests - passedTests,
      'success_rate': '${(passedTests / totalTests * 100).toStringAsFixed(1)}%',
    };
    
    logger.info('\n📊 Test Summary:');
    logger.info('   Passed: $passedTests/$totalTests tests');
    logger.info('   Success Rate: ${allResults['summary']['success_rate']}');
    logger.info('   ${passedTests == totalTests ? '🎉 All tests passed!' : '⚠️  Some tests failed'}');
    
    return allResults;
  }
}