import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// Service for interacting with Blossom protocol for decentralized storage
/// Blossom is a simple protocol for content-addressed storage over HTTP
class BlossomService {
  /// Default Blossom servers to use for redundancy
  static const List<String> defaultServers = [
    'https://blossom.primal.net',
    'https://blossom.satellite.earth',
    'https://blossom.nos.social',
  ];
  
  /// Upload a file to multiple Blossom servers for redundancy
  static Future<BlossomUploadResult> uploadFile({
    required File file,
    List<String>? servers,
    Map<String, String>? authHeaders,
    void Function(double)? onProgress,
    void Function(String server, String? error)? onServerResult,
  }) async {
    servers ??= defaultServers;
    
    // Calculate file hash
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    
    // Track successful uploads
    final successfulServers = <String>[];
    final failedServers = <String, String>{};
    final urls = <String>[];
    
    // Upload to each server
    for (int i = 0; i < servers.length; i++) {
      final server = servers[i];
      
      try {
        final url = await _uploadToServer(
          server: server,
          bytes: bytes,
          hash: hash,
          filename: path.basename(file.path),
          authHeaders: authHeaders,
        );
        
        successfulServers.add(server);
        urls.add(url);
        onServerResult?.call(server, null);
      } catch (e) {
        failedServers[server] = e.toString();
        onServerResult?.call(server, e.toString());
      }
      
      // Update progress
      onProgress?.call((i + 1) / servers.length);
    }
    
    if (successfulServers.isEmpty) {
      throw Exception('Failed to upload to any Blossom server: ${failedServers.values.join(', ')}');
    }
    
    return BlossomUploadResult(
      hash: hash,
      urls: urls,
      successfulServers: successfulServers,
      failedServers: failedServers,
      size: bytes.length,
    );
  }
  
  /// Upload bytes to a specific Blossom server
  static Future<String> _uploadToServer({
    required String server,
    required Uint8List bytes,
    required String hash,
    required String filename,
    Map<String, String>? authHeaders,
  }) async {
    final uri = Uri.parse('$server/upload');
    
    final request = http.MultipartRequest('POST', uri);
    
    // Add auth headers if provided
    if (authHeaders != null) {
      request.headers.addAll(authHeaders);
    }
    
    // Add file
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );
    
    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Parse response
      final responseData = json.decode(response.body);
      
      // Construct URL
      String url;
      if (responseData is Map && responseData.containsKey('url')) {
        url = responseData['url'];
      } else {
        // Construct standard Blossom URL
        final extension = path.extension(filename);
        url = '$server/$hash$extension';
      }
      
      return url;
    } else {
      throw Exception('Upload failed: ${response.statusCode} ${response.body}');
    }
  }
  
  /// Download a file from Blossom servers
  static Future<Uint8List> downloadFile({
    required String hash,
    List<String>? servers,
    String? url,
    void Function(double)? onProgress,
  }) async {
    // If URL is provided, try that first
    if (url != null) {
      try {
        return await _downloadFromUrl(url, onProgress: onProgress);
      } catch (e) {
        print('Failed to download from provided URL: $e');
      }
    }
    
    // Try each server
    servers ??= defaultServers;
    
    for (final server in servers) {
      try {
        // Try common extensions
        for (final ext in ['', '.zip', '.enc', '.json']) {
          final url = '$server/$hash$ext';
          try {
            final data = await _downloadFromUrl(url, onProgress: onProgress);
            
            // Verify hash
            final downloadedHash = sha256.convert(data).toString();
            if (downloadedHash == hash) {
              return data;
            } else {
              print('Hash mismatch: expected $hash, got $downloadedHash');
            }
          } catch (e) {
            // Try next extension
            continue;
          }
        }
      } catch (e) {
        print('Failed to download from $server: $e');
      }
    }
    
    throw Exception('Failed to download file from any server');
  }
  
  /// Download from a specific URL
  static Future<Uint8List> _downloadFromUrl(
    String url, {
    void Function(double)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();
    
    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.statusCode}');
    }
    
    final contentLength = response.contentLength ?? 0;
    final bytes = <int>[];
    var downloaded = 0;
    
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      downloaded += chunk.length;
      
      if (contentLength > 0) {
        onProgress?.call(downloaded / contentLength);
      }
    }
    
    return Uint8List.fromList(bytes);
  }
  
  /// List files on a Blossom server
  static Future<List<BlossomFileInfo>> listFiles({
    required String server,
    String? pubkey,
    Map<String, String>? authHeaders,
  }) async {
    final uri = pubkey != null 
        ? Uri.parse('$server/list/$pubkey')
        : Uri.parse('$server/list');
    
    final headers = <String, String>{};
    if (authHeaders != null) {
      headers.addAll(authHeaders);
    }
    
    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => BlossomFileInfo.fromJson(item)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to list files: ${response.statusCode}');
    }
  }
  
  /// Delete a file from a Blossom server
  static Future<bool> deleteFile({
    required String server,
    required String hash,
    Map<String, String>? authHeaders,
  }) async {
    final uri = Uri.parse('$server/$hash');
    
    final headers = <String, String>{};
    if (authHeaders != null) {
      headers.addAll(authHeaders);
    }
    
    final response = await http.delete(uri, headers: headers);
    
    return response.statusCode == 200 || response.statusCode == 204;
  }
  
  /// Check if a file exists on a server
  static Future<bool> fileExists({
    required String server,
    required String hash,
  }) async {
    final uri = Uri.parse('$server/$hash');
    
    final response = await http.head(uri);
    
    return response.statusCode == 200;
  }
  
  /// Mirror a file from one server to others
  static Future<void> mirrorFile({
    required String sourceUrl,
    required List<String> targetServers,
    Map<String, String>? authHeaders,
    void Function(String server, bool success)? onServerResult,
  }) async {
    // Download from source
    final bytes = await _downloadFromUrl(sourceUrl);
    final hash = sha256.convert(bytes).toString();
    
    // Extract filename from URL
    final filename = path.basename(sourceUrl);
    
    // Upload to each target server
    for (final server in targetServers) {
      try {
        await _uploadToServer(
          server: server,
          bytes: bytes,
          hash: hash,
          filename: filename,
          authHeaders: authHeaders,
        );
        onServerResult?.call(server, true);
      } catch (e) {
        onServerResult?.call(server, false);
      }
    }
  }
  
  /// Get hash from a Blossom URL
  static String? getHashFromUrl(String url) {
    // Match standard Blossom URL pattern: server/hash.extension
    final regex = RegExp(r'/([a-f0-9]{64})(?:\.[a-zA-Z0-9]+)?(?:\?|$|#)');
    final match = regex.firstMatch(url);
    
    if (match != null) {
      return match.group(1);
    }
    
    return null;
  }
  
  /// Create a standard Blossom URL
  static String createBlossomUrl(String server, String hash, String? extension) {
    if (extension != null && !extension.startsWith('.')) {
      extension = '.$extension';
    }
    return '$server/$hash${extension ?? ''}';
  }
}

/// Result of a Blossom upload operation
class BlossomUploadResult {
  final String hash;
  final List<String> urls;
  final List<String> successfulServers;
  final Map<String, String> failedServers;
  final int size;
  
  BlossomUploadResult({
    required this.hash,
    required this.urls,
    required this.successfulServers,
    required this.failedServers,
    required this.size,
  });
  
  Map<String, dynamic> toJson() => {
    'hash': hash,
    'urls': urls,
    'successfulServers': successfulServers,
    'failedServers': failedServers,
    'size': size,
  };
}

/// Information about a file on a Blossom server
class BlossomFileInfo {
  final String hash;
  final int size;
  final String? type;
  final DateTime? uploaded;
  final String? url;
  
  BlossomFileInfo({
    required this.hash,
    required this.size,
    this.type,
    this.uploaded,
    this.url,
  });
  
  factory BlossomFileInfo.fromJson(Map<String, dynamic> json) {
    return BlossomFileInfo(
      hash: json['hash'] ?? json['sha256'],
      size: json['size'] ?? 0,
      type: json['type'] ?? json['mime_type'],
      uploaded: json['uploaded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['uploaded'] * 1000)
          : null,
      url: json['url'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'hash': hash,
    'size': size,
    if (type != null) 'type': type,
    if (uploaded != null) 'uploaded': uploaded!.millisecondsSinceEpoch ~/ 1000,
    if (url != null) 'url': url,
  };
}