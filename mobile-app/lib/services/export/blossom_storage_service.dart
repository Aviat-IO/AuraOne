import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for uploading files to Blossom servers
/// Implements NIP-98 HTTP authentication for Nostr
class BlossomStorageService {
  static const _storage = FlutterSecureStorage();
  static const _nsecKey = 'blossom_nsec';
  
  /// Save nsec securely
  static Future<void> saveNsec(String nsec) async {
    await _storage.write(key: _nsecKey, value: nsec);
  }
  
  /// Get stored nsec
  static Future<String?> getNsec() async {
    return await _storage.read(key: _nsecKey);
  }
  
  /// Clear stored nsec
  static Future<void> clearNsec() async {
    await _storage.delete(key: _nsecKey);
  }
  
  /// Upload a file to a Blossom server
  static Future<String?> uploadFile({
    required String serverUrl,
    required String filePath,
    String? nsec,
  }) async {
    try {
      // Get nsec from parameter or secure storage
      final privateKey = nsec ?? await getNsec();
      if (privateKey == null) {
        throw Exception('No Nostr private key available for authentication');
      }
      
      // Read file
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      
      final fileBytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      
      // Calculate file hash
      final hash = sha256.convert(fileBytes).toString();
      
      // Create NIP-98 auth event
      final authEvent = await _createNip98AuthEvent(
        serverUrl: serverUrl,
        method: 'POST',
        privateKey: privateKey,
        fileHash: hash,
      );
      
      // Upload file
      final uri = Uri.parse('$serverUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header
      request.headers['Authorization'] = 'Nostr $authEvent';
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(responseBody);
        return json['url'] ?? json['hash'];
      } else {
        throw Exception('Upload failed: $responseBody');
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Create NIP-98 authentication event
  static Future<String> _createNip98AuthEvent({
    required String serverUrl,
    required String method,
    required String privateKey,
    required String fileHash,
  }) async {
    // This is a simplified version - in production, you'd want to use
    // a proper Nostr library for signing events
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final event = {
      'kind': 27235, // NIP-98 auth event kind
      'created_at': timestamp,
      'tags': [
        ['u', serverUrl],
        ['method', method],
        ['payload', fileHash],
      ],
      'content': '',
    };
    
    // TODO: Proper Nostr event signing with the private key
    // For now, returning a base64 encoded JSON
    // In production, use a library like nostr_tools or implement proper signing
    return base64.encode(utf8.encode(jsonEncode(event)));
  }
  
  /// Test connection to Blossom server
  static Future<bool> testConnection(String serverUrl) async {
    try {
      final response = await http.get(
        Uri.parse(serverUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}