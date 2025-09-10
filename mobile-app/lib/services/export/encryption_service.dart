import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for encrypting and decrypting export data using AES-256-GCM
class EncryptionService {
  static const String _keyStorageKey = 'aura_one_export_key';
  static const String _saltStorageKey = 'aura_one_export_salt';
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _saltLength = 32; // 256 bits salt
  static const int _ivLength = 12; // 96 bits for GCM
  static const int _tagLength = 16; // 128 bits for GCM
  static const int _iterationCount = 100000; // PBKDF2 iterations
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  /// Generate a secure random key for encryption
  static Uint8List generateKey() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(256)))));
    
    return secureRandom.nextBytes(_keyLength);
  }
  
  /// Generate a secure random salt for key derivation
  static Uint8List generateSalt() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(256)))));
    
    return secureRandom.nextBytes(_saltLength);
  }
  
  /// Generate a secure random IV for encryption
  static Uint8List generateIV() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(256)))));
    
    return secureRandom.nextBytes(_ivLength);
  }
  
  /// Derive a key from a password using PBKDF2
  static Uint8List deriveKeyFromPassword(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterationCount, _keyLength));
    
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }
  
  /// Store encryption key securely
  static Future<void> storeKey(Uint8List key) async {
    await _secureStorage.write(
      key: _keyStorageKey,
      value: base64.encode(key),
    );
  }
  
  /// Store salt securely
  static Future<void> storeSalt(Uint8List salt) async {
    await _secureStorage.write(
      key: _saltStorageKey,
      value: base64.encode(salt),
    );
  }
  
  /// Retrieve stored encryption key
  static Future<Uint8List?> getStoredKey() async {
    final encodedKey = await _secureStorage.read(key: _keyStorageKey);
    if (encodedKey != null) {
      return base64.decode(encodedKey);
    }
    return null;
  }
  
  /// Retrieve stored salt
  static Future<Uint8List?> getStoredSalt() async {
    final encodedSalt = await _secureStorage.read(key: _saltStorageKey);
    if (encodedSalt != null) {
      return base64.decode(encodedSalt);
    }
    return null;
  }
  
  /// Clear stored encryption key and salt
  static Future<void> clearStoredKeys() async {
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _saltStorageKey);
  }
  
  /// Encrypt data using AES-256-GCM
  static EncryptedData encryptData(Uint8List plaintext, Uint8List key) {
    if (key.length != _keyLength) {
      throw ArgumentError('Key must be $_keyLength bytes for AES-256');
    }
    
    // Generate random IV
    final iv = generateIV();
    
    // Create GCM cipher
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true, // forEncryption
        AEADParameters(
          KeyParameter(key),
          _tagLength * 8, // tag length in bits
          iv,
          Uint8List(0), // no additional authenticated data
        ),
      );
    
    // Encrypt the data
    final ciphertext = cipher.process(plaintext);
    
    return EncryptedData(
      ciphertext: ciphertext,
      iv: iv,
    );
  }
  
  /// Decrypt data using AES-256-GCM
  static Uint8List decryptData(EncryptedData encryptedData, Uint8List key) {
    if (key.length != _keyLength) {
      throw ArgumentError('Key must be $_keyLength bytes for AES-256');
    }
    
    // Create GCM cipher
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false, // forDecryption
        AEADParameters(
          KeyParameter(key),
          _tagLength * 8, // tag length in bits
          encryptedData.iv,
          Uint8List(0), // no additional authenticated data
        ),
      );
    
    // Decrypt the data
    return cipher.process(encryptedData.ciphertext);
  }
  
  /// Encrypt a string and return base64 encoded result
  static Future<String> encryptString(String plaintext, {String? password}) async {
    Uint8List key;
    Uint8List? salt;
    
    if (password != null) {
      // Use password-based encryption
      salt = generateSalt();
      key = deriveKeyFromPassword(password, salt);
    } else {
      // Use stored key or generate new one
      key = await getStoredKey() ?? generateKey();
      if (await getStoredKey() == null) {
        await storeKey(key);
      }
    }
    
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    final encryptedData = encryptData(plaintextBytes, key);
    
    // Combine salt (if using password), IV, and ciphertext
    final combined = BytesBuilder();
    if (salt != null) {
      combined.add([1]); // Flag: password-based encryption
      combined.add(salt);
    } else {
      combined.add([0]); // Flag: key-based encryption
    }
    combined.add(encryptedData.iv);
    combined.add(encryptedData.ciphertext);
    
    return base64.encode(combined.toBytes());
  }
  
  /// Decrypt a base64 encoded string
  static Future<String> decryptString(String encryptedBase64, {String? password}) async {
    final combined = base64.decode(encryptedBase64);
    
    if (combined.isEmpty) {
      throw ArgumentError('Invalid encrypted data');
    }
    
    final isPasswordBased = combined[0] == 1;
    int offset = 1;
    
    Uint8List key;
    if (isPasswordBased) {
      if (password == null) {
        throw ArgumentError('Password required for decryption');
      }
      if (combined.length < 1 + _saltLength + _ivLength + _tagLength) {
        throw ArgumentError('Invalid encrypted data format');
      }
      
      final salt = Uint8List.fromList(combined.sublist(offset, offset + _saltLength));
      offset += _saltLength;
      key = deriveKeyFromPassword(password, salt);
    } else {
      final storedKey = await getStoredKey();
      if (storedKey == null) {
        throw StateError('No encryption key found');
      }
      key = storedKey;
    }
    
    // Extract IV and ciphertext
    final iv = Uint8List.fromList(combined.sublist(offset, offset + _ivLength));
    offset += _ivLength;
    final ciphertext = Uint8List.fromList(combined.sublist(offset));
    
    final encryptedData = EncryptedData(ciphertext: ciphertext, iv: iv);
    final decryptedBytes = decryptData(encryptedData, key);
    
    return utf8.decode(decryptedBytes);
  }
  
  /// Encrypt a file and return encrypted bytes
  static Future<Uint8List> encryptFile(Uint8List fileBytes, {String? password}) async {
    Uint8List key;
    Uint8List? salt;
    
    if (password != null) {
      salt = generateSalt();
      key = deriveKeyFromPassword(password, salt);
    } else {
      key = await getStoredKey() ?? generateKey();
      if (await getStoredKey() == null) {
        await storeKey(key);
      }
    }
    
    final encryptedData = encryptData(fileBytes, key);
    
    // Combine salt (if using password), IV, and ciphertext
    final combined = BytesBuilder();
    if (salt != null) {
      combined.add([1]); // Flag: password-based encryption
      combined.add(salt);
    } else {
      combined.add([0]); // Flag: key-based encryption
    }
    combined.add(encryptedData.iv);
    combined.add(encryptedData.ciphertext);
    
    return combined.toBytes();
  }
  
  /// Decrypt a file and return decrypted bytes
  static Future<Uint8List> decryptFile(Uint8List encryptedBytes, {String? password}) async {
    if (encryptedBytes.isEmpty) {
      throw ArgumentError('Invalid encrypted data');
    }
    
    final isPasswordBased = encryptedBytes[0] == 1;
    int offset = 1;
    
    Uint8List key;
    if (isPasswordBased) {
      if (password == null) {
        throw ArgumentError('Password required for decryption');
      }
      if (encryptedBytes.length < 1 + _saltLength + _ivLength + _tagLength) {
        throw ArgumentError('Invalid encrypted data format');
      }
      
      final salt = Uint8List.fromList(encryptedBytes.sublist(offset, offset + _saltLength));
      offset += _saltLength;
      key = deriveKeyFromPassword(password, salt);
    } else {
      final storedKey = await getStoredKey();
      if (storedKey == null) {
        throw StateError('No encryption key found');
      }
      key = storedKey;
    }
    
    // Extract IV and ciphertext
    final iv = Uint8List.fromList(encryptedBytes.sublist(offset, offset + _ivLength));
    offset += _ivLength;
    final ciphertext = Uint8List.fromList(encryptedBytes.sublist(offset));
    
    final encryptedData = EncryptedData(ciphertext: ciphertext, iv: iv);
    return decryptData(encryptedData, key);
  }
  
  /// Check if encryption is configured (key exists)
  static Future<bool> isEncryptionConfigured() async {
    return await getStoredKey() != null;
  }
  
  /// Generate and store a new encryption key
  static Future<void> setupEncryption() async {
    final key = generateKey();
    await storeKey(key);
  }
}

/// Container for encrypted data with its IV
class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List iv;
  
  EncryptedData({
    required this.ciphertext,
    required this.iv,
  });
}