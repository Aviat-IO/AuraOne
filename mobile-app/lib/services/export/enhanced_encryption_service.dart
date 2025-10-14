import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:math' as math;
import 'dart:io';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Enhanced encryption service specifically designed for secure backup encryption
/// with device keychain/keystore integration and device-specific key derivation
class EnhancedEncryptionService {
  static const String _backupKeyStorageKey = 'aura_one_backup_master_key';
  static const String _backupSaltStorageKey = 'aura_one_backup_salt';
  static const String _deviceKeyStorageKey = 'aura_one_device_key';
  static const String _keyRecoveryInfoKey = 'aura_one_key_recovery';
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _saltLength = 32; // 256 bits salt
  static const int _ivLength = 12; // 96 bits for GCM
  static const int _tagLength = 16; // 128 bits for GCM
  static const int _deviceKeyIterations = 50000; // Device-specific iterations
  
  /// Enhanced secure storage with backup-specific options
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Use Android Keystore hardware-backed keys when available
      preferencesKeyPrefix: 'aura_backup_',
      sharedPreferencesName: 'aura_backup_secure',
    ),
    iOptions: IOSOptions(
      // Use iOS Keychain with highest security level
      accessibility: KeychainAccessibility.first_unlock_this_device,
      groupId: null, // App-specific keychain access
    ),
  );

  /// Generate a secure random key for encryption
  static Uint8List generateSecureKey() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(256)))));
    
    return secureRandom.nextBytes(_keyLength);
  }

  /// Generate a secure random salt
  static Uint8List generateSecureSalt() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(256)))));
    
    return secureRandom.nextBytes(_saltLength);
  }

  /// Generate a secure random IV
  static Uint8List generateSecureIV() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(256)))));
    
    return secureRandom.nextBytes(_ivLength);
  }

  /// Generate device-specific identifier for key derivation
  static Future<String> _generateDeviceIdentifier() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Create device-specific identifier using available platform information
      final deviceData = StringBuffer();
      deviceData.write(packageInfo.packageName);
      deviceData.write(Platform.operatingSystem);
      deviceData.write(Platform.operatingSystemVersion);
      
      // Add platform-specific identifiers
      if (Platform.isAndroid) {
        // On Android, we can use the app's data directory path which is unique per install
        deviceData.write(Platform.resolvedExecutable);
      } else if (Platform.isIOS) {
        // On iOS, use bundle identifier and version
        deviceData.write(packageInfo.version);
        deviceData.write(packageInfo.buildNumber);
      }
      
      // Hash the collected data for consistent length and format
      final hash = sha256.convert(utf8.encode(deviceData.toString()));
      return base64.encode(hash.bytes);
      
    } catch (e) {
      // Fallback to a secure random identifier stored in keychain
      const fallbackKey = 'aura_device_fallback_id';
      String? existingId = await _secureStorage.read(key: fallbackKey);
      
      if (existingId == null) {
        final randomBytes = generateSecureKey();
        existingId = base64.encode(randomBytes);
        await _secureStorage.write(key: fallbackKey, value: existingId);
      }
      
      return existingId;
    }
  }

  /// Derive device-specific encryption key
  static Future<Uint8List> deriveDeviceSpecificKey(String basePassword, Uint8List salt) async {
    final deviceId = await _generateDeviceIdentifier();
    
    // Combine password with device identifier
    final combinedPassword = '$basePassword:$deviceId';
    
    // Use PBKDF2 with device-specific iterations
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _deviceKeyIterations, _keyLength));
    
    return pbkdf2.process(Uint8List.fromList(utf8.encode(combinedPassword)));
  }

  /// Generate and store secure backup password automatically
  static Future<BackupKeyInfo> generateSecureBackupPassword() async {
    // Generate a strong password using cryptographically secure random
    final passwordBytes = generateSecureKey();
    final password = base64.encode(passwordBytes).substring(0, 24); // Use first 24 chars
    
    // Generate salt for this backup password
    final salt = generateSecureSalt();
    
    // Derive the actual encryption key using device-specific derivation
    final encryptionKey = await deriveDeviceSpecificKey(password, salt);
    
    // Store password and salt securely in device keychain/keystore
    await _secureStorage.write(key: _backupKeyStorageKey, value: password);
    await _secureStorage.write(key: _backupSaltStorageKey, value: base64.encode(salt));
    
    // Create recovery information for device transfers
    final recoveryInfo = BackupKeyRecoveryInfo(
      passwordHash: sha256.convert(utf8.encode(password)).toString(),
      saltBase64: base64.encode(salt),
      derivationMethod: 'PBKDF2-SHA256-DeviceSpecific',
      iterations: _deviceKeyIterations,
      createdAt: DateTime.now(),
      deviceIdentifier: await _generateDeviceIdentifier(),
    );
    
    // Store recovery info
    await _secureStorage.write(
      key: _keyRecoveryInfoKey,
      value: jsonEncode(recoveryInfo.toJson()),
    );
    
    return BackupKeyInfo(
      password: password,
      encryptionKey: encryptionKey,
      salt: salt,
      recoveryInfo: recoveryInfo,
    );
  }

  /// Retrieve existing backup encryption key
  static Future<BackupKeyInfo?> getStoredBackupKey() async {
    final storedPassword = await _secureStorage.read(key: _backupKeyStorageKey);
    final storedSalt = await _secureStorage.read(key: _backupSaltStorageKey);
    
    if (storedPassword == null || storedSalt == null) {
      return null;
    }
    
    final salt = base64.decode(storedSalt);
    final encryptionKey = await deriveDeviceSpecificKey(storedPassword, salt);
    
    // Try to get recovery info
    BackupKeyRecoveryInfo? recoveryInfo;
    try {
      final recoveryData = await _secureStorage.read(key: _keyRecoveryInfoKey);
      if (recoveryData != null) {
        recoveryInfo = BackupKeyRecoveryInfo.fromJson(jsonDecode(recoveryData));
      }
    } catch (e) {
      // Recovery info not available or corrupted
    }
    
    return BackupKeyInfo(
      password: storedPassword,
      encryptionKey: encryptionKey,
      salt: salt,
      recoveryInfo: recoveryInfo,
    );
  }

  /// Encrypt backup metadata with additional privacy protection
  static Future<EncryptedBackupMetadata> encryptBackupMetadata(
    Map<String, dynamic> metadata,
    {BackupKeyInfo? customKey}
  ) async {
    final keyInfo = customKey ?? await getStoredBackupKey() ?? await generateSecureBackupPassword();
    
    // Add privacy-preserving metadata
    final enhancedMetadata = Map<String, dynamic>.from(metadata);
    enhancedMetadata['encrypted_at'] = DateTime.now().toIso8601String();
    enhancedMetadata['encryption_version'] = '2.0'; // Enhanced version
    enhancedMetadata['device_id_hash'] = sha256.convert(
      utf8.encode(await _generateDeviceIdentifier())
    ).toString();
    
    // Convert to JSON and encrypt
    final jsonData = jsonEncode(enhancedMetadata);
    final plaintextBytes = Uint8List.fromList(utf8.encode(jsonData));
    
    final encryptedData = _encryptDataWithKey(plaintextBytes, keyInfo.encryptionKey);
    
    return EncryptedBackupMetadata(
      encryptedData: encryptedData,
      keyInfo: keyInfo,
    );
  }

  /// Decrypt backup metadata
  static Future<Map<String, dynamic>> decryptBackupMetadata(
    EncryptedBackupMetadata encryptedMetadata,
  ) async {
    final decryptedBytes = _decryptDataWithKey(
      encryptedMetadata.encryptedData,
      encryptedMetadata.keyInfo.encryptionKey,
    );
    
    final jsonString = utf8.decode(decryptedBytes);
    return Map<String, dynamic>.from(jsonDecode(jsonString));
  }

  /// Encrypt large files with optimized performance
  static Future<Uint8List> encryptLargeFile(
    Uint8List fileBytes,
    {BackupKeyInfo? customKey, Function(double)? onProgress}
  ) async {
    final keyInfo = customKey ?? await getStoredBackupKey() ?? await generateSecureBackupPassword();
    
    // For large files, we might want to implement chunked encryption
    // For now, use the standard encryption but with progress reporting
    const chunkSize = 1024 * 1024; // 1MB chunks
    
    if (fileBytes.length <= chunkSize) {
      // Small file, encrypt normally
      onProgress?.call(0.5);
      final result = _encryptFileWithKey(fileBytes, keyInfo.encryptionKey);
      onProgress?.call(1.0);
      return result;
    }
    
    // Large file chunked encryption
    final encryptedChunks = <Uint8List>[];
    final totalChunks = (fileBytes.length / chunkSize).ceil();
    
    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = math.min((i + 1) * chunkSize, fileBytes.length);
      final chunk = fileBytes.sublist(start, end);
      
      final encryptedChunk = _encryptDataWithKey(chunk, keyInfo.encryptionKey);
      encryptedChunks.add(_packEncryptedChunk(encryptedChunk));
      
      onProgress?.call((i + 1) / totalChunks);
    }
    
    // Combine all encrypted chunks with header
    return _combineEncryptedChunks(encryptedChunks, keyInfo);
  }

  /// Decrypt large files with optimized performance
  static Future<Uint8List> decryptLargeFile(
    Uint8List encryptedBytes,
    BackupKeyInfo keyInfo,
    {Function(double)? onProgress}
  ) async {
    // Check if this is a chunked file
    if (_isChunkedEncryption(encryptedBytes)) {
      return _decryptChunkedFile(encryptedBytes, keyInfo, onProgress: onProgress);
    } else {
      // Standard decryption
      onProgress?.call(0.5);
      final result = _decryptFileWithKey(encryptedBytes, keyInfo.encryptionKey);
      onProgress?.call(1.0);
      return result;
    }
  }

  /// Implement secure key recovery for device transfers
  static Future<BackupKeyInfo?> recoverKeyFromRecoveryInfo(
    BackupKeyRecoveryInfo recoveryInfo,
    String originalPassword,
  ) async {
    try {
      // Verify password hash
      final passwordHash = sha256.convert(utf8.encode(originalPassword)).toString();
      if (passwordHash != recoveryInfo.passwordHash) {
        throw Exception('Invalid recovery password');
      }
      
      final salt = base64.decode(recoveryInfo.saltBase64);
      
      // Derive encryption key using the original device identifier
      final combinedPassword = '$originalPassword:${recoveryInfo.deviceIdentifier}';
      
      final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
        ..init(Pbkdf2Parameters(salt, recoveryInfo.iterations, _keyLength));
      
      final encryptionKey = pbkdf2.process(Uint8List.fromList(utf8.encode(combinedPassword)));
      
      // Store the recovered key in new device
      await _secureStorage.write(key: _backupKeyStorageKey, value: originalPassword);
      await _secureStorage.write(key: _backupSaltStorageKey, value: recoveryInfo.saltBase64);
      await _secureStorage.write(key: _keyRecoveryInfoKey, value: jsonEncode(recoveryInfo.toJson()));
      
      return BackupKeyInfo(
        password: originalPassword,
        encryptionKey: encryptionKey,
        salt: salt,
        recoveryInfo: recoveryInfo,
      );
      
    } catch (e) {
      return null;
    }
  }

  /// Clear all backup encryption keys
  static Future<void> clearAllBackupKeys() async {
    await _secureStorage.delete(key: _backupKeyStorageKey);
    await _secureStorage.delete(key: _backupSaltStorageKey);
    await _secureStorage.delete(key: _deviceKeyStorageKey);
    await _secureStorage.delete(key: _keyRecoveryInfoKey);
  }

  /// Check if backup encryption is properly configured
  static Future<bool> isBackupEncryptionConfigured() async {
    final keyInfo = await getStoredBackupKey();
    return keyInfo != null;
  }

  // Private helper methods
  
  static EncryptedData _encryptDataWithKey(Uint8List plaintext, Uint8List key) {
    if (key.length != _keyLength) {
      throw ArgumentError('Key must be $_keyLength bytes for AES-256');
    }
    
    final iv = generateSecureIV();
    
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          _tagLength * 8,
          iv,
          Uint8List(0),
        ),
      );
    
    final ciphertext = cipher.process(plaintext);
    
    return EncryptedData(ciphertext: ciphertext, iv: iv);
  }

  static Uint8List _decryptDataWithKey(EncryptedData encryptedData, Uint8List key) {
    if (key.length != _keyLength) {
      throw ArgumentError('Key must be $_keyLength bytes for AES-256');
    }
    
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          _tagLength * 8,
          encryptedData.iv,
          Uint8List(0),
        ),
      );
    
    return cipher.process(encryptedData.ciphertext);
  }

  static Uint8List _encryptFileWithKey(Uint8List fileBytes, Uint8List key) {
    final encryptedData = _encryptDataWithKey(fileBytes, key);
    
    final combined = BytesBuilder();
    combined.add([2]); // Flag: enhanced encryption v2
    combined.add(encryptedData.iv);
    combined.add(encryptedData.ciphertext);
    
    return combined.toBytes();
  }

  static Uint8List _decryptFileWithKey(Uint8List encryptedBytes, Uint8List key) {
    if (encryptedBytes.isEmpty) {
      throw ArgumentError('Invalid encrypted data');
    }
    
    final version = encryptedBytes[0];
    if (version != 2) {
      throw ArgumentError('Unsupported encryption version: $version');
    }
    
    int offset = 1;
    final iv = Uint8List.fromList(encryptedBytes.sublist(offset, offset + _ivLength));
    offset += _ivLength;
    final ciphertext = Uint8List.fromList(encryptedBytes.sublist(offset));
    
    final encryptedData = EncryptedData(ciphertext: ciphertext, iv: iv);
    return _decryptDataWithKey(encryptedData, key);
  }

  static Uint8List _packEncryptedChunk(EncryptedData encryptedData) {
    final packed = BytesBuilder();
    packed.add(encryptedData.iv);
    packed.add(encryptedData.ciphertext);
    return packed.toBytes();
  }

  static Uint8List _combineEncryptedChunks(List<Uint8List> chunks, BackupKeyInfo keyInfo) {
    final combined = BytesBuilder();
    combined.add([3]); // Flag: chunked encryption v3
    combined.add(_uint32ToBytes(chunks.length)); // Number of chunks
    
    for (final chunk in chunks) {
      combined.add(_uint32ToBytes(chunk.length)); // Chunk length
      combined.add(chunk); // Chunk data
    }
    
    return combined.toBytes();
  }

  static bool _isChunkedEncryption(Uint8List data) {
    return data.isNotEmpty && data[0] == 3;
  }

  static Future<Uint8List> _decryptChunkedFile(
    Uint8List encryptedBytes,
    BackupKeyInfo keyInfo,
    {Function(double)? onProgress}
  ) async {
    int offset = 1; // Skip version flag
    final numChunks = _bytesToUint32(encryptedBytes.sublist(offset, offset + 4));
    offset += 4;
    
    final decryptedChunks = <Uint8List>[];
    
    for (int i = 0; i < numChunks; i++) {
      final chunkLength = _bytesToUint32(encryptedBytes.sublist(offset, offset + 4));
      offset += 4;
      
      final chunkData = encryptedBytes.sublist(offset, offset + chunkLength);
      offset += chunkLength;
      
      // Unpack chunk
      final iv = chunkData.sublist(0, _ivLength);
      final ciphertext = chunkData.sublist(_ivLength);
      
      final encryptedData = EncryptedData(ciphertext: ciphertext, iv: iv);
      final decryptedChunk = _decryptDataWithKey(encryptedData, keyInfo.encryptionKey);
      
      decryptedChunks.add(decryptedChunk);
      onProgress?.call((i + 1) / numChunks);
    }
    
    // Combine all decrypted chunks
    final combined = BytesBuilder();
    for (final chunk in decryptedChunks) {
      combined.add(chunk);
    }
    
    return combined.toBytes();
  }

  static Uint8List _uint32ToBytes(int value) {
    return Uint8List.fromList([
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ]);
  }

  static int _bytesToUint32(Uint8List bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }
}

/// Container for encrypted data with IV
class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List iv;
  
  EncryptedData({
    required this.ciphertext,
    required this.iv,
  });
}

/// Information about backup encryption key
class BackupKeyInfo {
  final String password;
  final Uint8List encryptionKey;
  final Uint8List salt;
  final BackupKeyRecoveryInfo? recoveryInfo;
  
  BackupKeyInfo({
    required this.password,
    required this.encryptionKey,
    required this.salt,
    this.recoveryInfo,
  });
}

/// Recovery information for device transfers
class BackupKeyRecoveryInfo {
  final String passwordHash;
  final String saltBase64;
  final String derivationMethod;
  final int iterations;
  final DateTime createdAt;
  final String deviceIdentifier;
  
  BackupKeyRecoveryInfo({
    required this.passwordHash,
    required this.saltBase64,
    required this.derivationMethod,
    required this.iterations,
    required this.createdAt,
    required this.deviceIdentifier,
  });
  
  Map<String, dynamic> toJson() => {
    'passwordHash': passwordHash,
    'saltBase64': saltBase64,
    'derivationMethod': derivationMethod,
    'iterations': iterations,
    'createdAt': createdAt.toIso8601String(),
    'deviceIdentifier': deviceIdentifier,
  };
  
  factory BackupKeyRecoveryInfo.fromJson(Map<String, dynamic> json) => BackupKeyRecoveryInfo(
    passwordHash: json['passwordHash'] as String,
    saltBase64: json['saltBase64'] as String,
    derivationMethod: json['derivationMethod'] as String,
    iterations: json['iterations'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    deviceIdentifier: json['deviceIdentifier'] as String,
  );
}

/// Encrypted backup metadata container
class EncryptedBackupMetadata {
  final EncryptedData encryptedData;
  final BackupKeyInfo keyInfo;
  
  EncryptedBackupMetadata({
    required this.encryptedData,
    required this.keyInfo,
  });
}