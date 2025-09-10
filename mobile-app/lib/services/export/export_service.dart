import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'export_schema.dart';
import 'encryption_service.dart';
import 'blossom_service.dart';

/// Service for exporting journal data to various formats and destinations
class ExportService {
  /// Export journal data to a ZIP file in the device's Downloads folder
  static Future<String> exportToLocalFile({
    required String appVersion,
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> journalEntries,
    required List<Map<String, dynamic>> mediaReferences,
    required Map<String, dynamic> metadata,
    required DateTime exportDate,
    List<File>? mediaFiles,
    void Function(double)? onProgress,
  }) async {
    // Request storage permission on Android
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }
    }
    
    // Create the export package
    final exportPackage = ExportSchema.createExportPackage(
      exportDate: exportDate,
      appVersion: appVersion,
      userData: userData,
      journalEntries: journalEntries,
      mediaReferences: mediaReferences,
      metadata: metadata,
    );
    
    // Convert to JSON
    final jsonContent = const JsonEncoder.withIndent('  ').convert(exportPackage);
    
    // Create archive
    final archive = Archive();
    
    // Add journal.json to archive
    final jsonBytes = utf8.encode(jsonContent);
    archive.addFile(ArchiveFile('journal.json', jsonBytes.length, jsonBytes));
    
    // Add README.md to archive
    final readmeBytes = utf8.encode(ExportFormatDocumentation.documentation);
    archive.addFile(ArchiveFile('README.md', readmeBytes.length, readmeBytes));
    
    // Add media files if provided
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      int processedFiles = 0;
      for (final file in mediaFiles) {
        try {
          final bytes = await file.readAsBytes();
          final fileName = path.basename(file.path);
          archive.addFile(ArchiveFile('media/$fileName', bytes.length, bytes));
          
          processedFiles++;
          onProgress?.call((processedFiles / mediaFiles.length) * 0.8 + 0.1);
        } catch (e) {
          print('Failed to add media file ${file.path}: $e');
        }
      }
    }
    
    // Encode archive to ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to create ZIP archive');
    }
    
    // Get appropriate directory
    Directory directory;
    if (Platform.isAndroid) {
      // For Android, use the Downloads directory
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback to app's external storage
        final externalDir = await getExternalStorageDirectory();
        if (externalDir == null) {
          throw Exception('Could not access external storage');
        }
        directory = externalDir;
      }
    } else if (Platform.isIOS) {
      // For iOS, use Documents directory
      directory = await getApplicationDocumentsDirectory();
    } else {
      // For other platforms, use Downloads folder
      directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
    
    // Generate filename with timestamp
    final timestamp = exportDate.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final fileName = 'aura_one_export_$timestamp.zip';
    final filePath = path.join(directory.path, fileName);
    
    // Write ZIP file
    final outputFile = File(filePath);
    await outputFile.writeAsBytes(zipBytes);
    
    onProgress?.call(1.0);
    
    return filePath;
  }
  
  /// Export journal data to an encrypted ZIP file
  static Future<String> exportToEncryptedFile({
    required String appVersion,
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> journalEntries,
    required List<Map<String, dynamic>> mediaReferences,
    required Map<String, dynamic> metadata,
    required DateTime exportDate,
    List<File>? mediaFiles,
    String? password,
    void Function(double)? onProgress,
  }) async {
    // Request storage permission on Android
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }
    }
    
    onProgress?.call(0.05);
    
    // Create the export package
    final exportPackage = ExportSchema.createExportPackage(
      exportDate: exportDate,
      appVersion: appVersion,
      userData: userData,
      journalEntries: journalEntries,
      mediaReferences: mediaReferences,
      metadata: metadata,
    );
    
    // Convert to JSON
    final jsonContent = const JsonEncoder.withIndent('  ').convert(exportPackage);
    
    onProgress?.call(0.1);
    
    // Create archive
    final archive = Archive();
    
    // Add journal.json to archive
    final jsonBytes = utf8.encode(jsonContent);
    archive.addFile(ArchiveFile('journal.json', jsonBytes.length, jsonBytes));
    
    // Add README.md to archive
    final readmeBytes = utf8.encode(ExportFormatDocumentation.documentation);
    archive.addFile(ArchiveFile('README.md', readmeBytes.length, readmeBytes));
    
    onProgress?.call(0.2);
    
    // Add media files if provided
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      int processedFiles = 0;
      for (final file in mediaFiles) {
        try {
          final bytes = await file.readAsBytes();
          final fileName = path.basename(file.path);
          archive.addFile(ArchiveFile('media/$fileName', bytes.length, bytes));
          
          processedFiles++;
          onProgress?.call(0.2 + (processedFiles / mediaFiles.length) * 0.5);
        } catch (e) {
          print('Failed to add media file ${file.path}: $e');
        }
      }
    }
    
    onProgress?.call(0.7);
    
    // Encode archive to ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to create ZIP archive');
    }
    
    onProgress?.call(0.8);
    
    // Encrypt the ZIP file
    final encryptedBytes = await EncryptionService.encryptFile(
      Uint8List.fromList(zipBytes),
      password: password,
    );
    
    onProgress?.call(0.9);
    
    // Get appropriate directory
    Directory directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir == null) {
          throw Exception('Could not access external storage');
        }
        directory = externalDir;
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
    
    // Generate filename with timestamp and .enc extension
    final timestamp = exportDate.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final fileName = 'aura_one_export_${timestamp}_encrypted.zip.enc';
    final filePath = path.join(directory.path, fileName);
    
    // Write encrypted file
    final outputFile = File(filePath);
    await outputFile.writeAsBytes(encryptedBytes);
    
    onProgress?.call(1.0);
    
    return filePath;
  }
  
  /// Export journal data to a specific directory (uncompressed)
  static Future<String> exportToDirectory({
    required String appVersion,
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> journalEntries,
    required List<Map<String, dynamic>> mediaReferences,
    required Map<String, dynamic> metadata,
    required DateTime exportDate,
    required String targetDirectory,
    List<File>? mediaFiles,
    void Function(double)? onProgress,
  }) async {
    // Create export directory
    final timestamp = exportDate.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final exportDirName = 'aura_one_export_$timestamp';
    final exportDir = Directory(path.join(targetDirectory, exportDirName));
    
    if (await exportDir.exists()) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create(recursive: true);
    
    // Create the export package
    final exportPackage = ExportSchema.createExportPackage(
      exportDate: exportDate,
      appVersion: appVersion,
      userData: userData,
      journalEntries: journalEntries,
      mediaReferences: mediaReferences,
      metadata: metadata,
    );
    
    // Write journal.json
    final jsonContent = const JsonEncoder.withIndent('  ').convert(exportPackage);
    final journalFile = File(path.join(exportDir.path, 'journal.json'));
    await journalFile.writeAsString(jsonContent);
    
    onProgress?.call(0.1);
    
    // Write README.md
    final readmeFile = File(path.join(exportDir.path, 'README.md'));
    await readmeFile.writeAsString(ExportFormatDocumentation.documentation);
    
    onProgress?.call(0.2);
    
    // Copy media files if provided
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      final mediaDir = Directory(path.join(exportDir.path, 'media'));
      await mediaDir.create();
      
      int processedFiles = 0;
      for (final file in mediaFiles) {
        try {
          final fileName = path.basename(file.path);
          final targetPath = path.join(mediaDir.path, fileName);
          await file.copy(targetPath);
          
          processedFiles++;
          onProgress?.call(0.2 + (processedFiles / mediaFiles.length) * 0.8);
        } catch (e) {
          print('Failed to copy media file ${file.path}: $e');
        }
      }
    }
    
    onProgress?.call(1.0);
    
    return exportDir.path;
  }
  
  /// Import journal data from a ZIP file (encrypted or unencrypted)
  static Future<Map<String, dynamic>> importFromZipFile(String filePath, {String? password}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Import file not found');
    }
    
    var bytes = await file.readAsBytes();
    
    // Check if file is encrypted (has .enc extension)
    if (filePath.endsWith('.enc')) {
      // Decrypt the file
      bytes = await EncryptionService.decryptFile(
        Uint8List.fromList(bytes),
        password: password,
      );
    }
    
    // Decode ZIP archive
    final archive = ZipDecoder().decodeBytes(bytes);
    
    // Find journal.json
    final journalFile = archive.files.firstWhere(
      (file) => file.name == 'journal.json',
      orElse: () => throw Exception('Invalid export: journal.json not found'),
    );
    
    // Parse JSON content
    final jsonContent = utf8.decode(journalFile.content as List<int>);
    final exportData = json.decode(jsonContent) as Map<String, dynamic>;
    
    // Validate schema version
    final schema = exportData['schema'] as Map<String, dynamic>?;
    if (schema == null || schema['type'] != 'aura_one_journal_export') {
      throw Exception('Invalid export format');
    }
    
    final version = schema['version'] as String?;
    if (version == null || !_isCompatibleVersion(version)) {
      throw Exception('Incompatible export version: $version');
    }
    
    // Extract media files to temporary directory
    final tempDir = await getTemporaryDirectory();
    final mediaDir = Directory(path.join(tempDir.path, 'import_media'));
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }
    await mediaDir.create();
    
    for (final file in archive.files) {
      if (file.name.startsWith('media/') && file.isFile) {
        final fileName = path.basename(file.name);
        final mediaFile = File(path.join(mediaDir.path, fileName));
        await mediaFile.writeAsBytes(file.content as List<int>);
      }
    }
    
    exportData['_mediaDirectory'] = mediaDir.path;
    
    return exportData;
  }
  
  /// Import journal data from a directory
  static Future<Map<String, dynamic>> importFromDirectory(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      throw Exception('Import directory not found');
    }
    
    // Read journal.json
    final journalFile = File(path.join(dir.path, 'journal.json'));
    if (!await journalFile.exists()) {
      throw Exception('Invalid export: journal.json not found');
    }
    
    final jsonContent = await journalFile.readAsString();
    final exportData = json.decode(jsonContent) as Map<String, dynamic>;
    
    // Validate schema version
    final schema = exportData['schema'] as Map<String, dynamic>?;
    if (schema == null || schema['type'] != 'aura_one_journal_export') {
      throw Exception('Invalid export format');
    }
    
    final version = schema['version'] as String?;
    if (version == null || !_isCompatibleVersion(version)) {
      throw Exception('Incompatible export version: $version');
    }
    
    // Add media directory path if it exists
    final mediaDir = Directory(path.join(dir.path, 'media'));
    if (await mediaDir.exists()) {
      exportData['_mediaDirectory'] = mediaDir.path;
    }
    
    return exportData;
  }
  
  /// Export journal data to Blossom decentralized storage
  static Future<BlossomExportResult> exportToBlossom({
    required String appVersion,
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> journalEntries,
    required List<Map<String, dynamic>> mediaReferences,
    required Map<String, dynamic> metadata,
    required DateTime exportDate,
    List<File>? mediaFiles,
    List<String>? servers,
    String? password,
    void Function(double)? onProgress,
    void Function(String, String?)? onServerResult,
  }) async {
    // Create the export package
    final exportPackage = ExportSchema.createExportPackage(
      exportDate: exportDate,
      appVersion: appVersion,
      userData: userData,
      journalEntries: journalEntries,
      mediaReferences: mediaReferences,
      metadata: metadata,
    );
    
    // Convert to JSON
    final jsonContent = const JsonEncoder.withIndent('  ').convert(exportPackage);
    
    onProgress?.call(0.1);
    
    // Create archive
    final archive = Archive();
    
    // Add journal.json to archive
    final jsonBytes = utf8.encode(jsonContent);
    archive.addFile(ArchiveFile('journal.json', jsonBytes.length, jsonBytes));
    
    // Add README.md to archive
    final readmeBytes = utf8.encode(ExportFormatDocumentation.documentation);
    archive.addFile(ArchiveFile('README.md', readmeBytes.length, readmeBytes));
    
    onProgress?.call(0.2);
    
    // Add media files if provided
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      int processedFiles = 0;
      for (final file in mediaFiles) {
        try {
          final bytes = await file.readAsBytes();
          final fileName = path.basename(file.path);
          archive.addFile(ArchiveFile('media/$fileName', bytes.length, bytes));
          
          processedFiles++;
          onProgress?.call(0.2 + (processedFiles / mediaFiles.length) * 0.3);
        } catch (e) {
          print('Failed to add media file ${file.path}: $e');
        }
      }
    }
    
    onProgress?.call(0.5);
    
    // Encode archive to ZIP
    final zipEncoder = ZipEncoder();
    var zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to create ZIP archive');
    }
    
    onProgress?.call(0.6);
    
    // Encrypt if password provided
    if (password != null && password.isNotEmpty) {
      zipBytes = await EncryptionService.encryptFile(
        Uint8List.fromList(zipBytes),
        password: password,
      );
    }
    
    onProgress?.call(0.7);
    
    // Create temporary file for upload
    final tempDir = await getTemporaryDirectory();
    final timestamp = exportDate.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final fileName = password != null 
        ? 'aura_one_export_${timestamp}_encrypted.zip.enc'
        : 'aura_one_export_$timestamp.zip';
    final tempFile = File(path.join(tempDir.path, fileName));
    await tempFile.writeAsBytes(zipBytes);
    
    onProgress?.call(0.8);
    
    try {
      // Upload to Blossom servers
      final result = await BlossomService.uploadFile(
        file: tempFile,
        servers: servers,
        onProgress: (progress) {
          // Map upload progress to 0.8-1.0 range
          onProgress?.call(0.8 + progress * 0.2);
        },
        onServerResult: onServerResult,
      );
      
      onProgress?.call(1.0);
      
      // Clean up temp file
      await tempFile.delete();
      
      return BlossomExportResult(
        hash: result.hash,
        urls: result.urls,
        successfulServers: result.successfulServers,
        failedServers: result.failedServers,
        size: result.size,
        encrypted: password != null,
        exportDate: exportDate,
      );
    } catch (e) {
      // Clean up temp file on error
      await tempFile.delete();
      rethrow;
    }
  }
  
  /// Import journal data from Blossom storage
  static Future<Map<String, dynamic>> importFromBlossom({
    required String hash,
    List<String>? servers,
    String? url,
    String? password,
    void Function(double)? onProgress,
  }) async {
    // Download from Blossom
    final bytes = await BlossomService.downloadFile(
      hash: hash,
      servers: servers,
      url: url,
      onProgress: (progress) {
        // Map download progress to 0-0.5 range
        onProgress?.call(progress * 0.5);
      },
    );
    
    onProgress?.call(0.5);
    
    var zipBytes = bytes;
    
    // Decrypt if password provided
    if (password != null && password.isNotEmpty) {
      zipBytes = await EncryptionService.decryptFile(
        zipBytes,
        password: password,
      );
    }
    
    onProgress?.call(0.7);
    
    // Decode ZIP archive
    final archive = ZipDecoder().decodeBytes(zipBytes);
    
    // Find journal.json
    final journalFile = archive.files.firstWhere(
      (file) => file.name == 'journal.json',
      orElse: () => throw Exception('Invalid export: journal.json not found'),
    );
    
    // Parse JSON content
    final jsonContent = utf8.decode(journalFile.content as List<int>);
    final exportData = json.decode(jsonContent) as Map<String, dynamic>;
    
    onProgress?.call(0.8);
    
    // Validate schema version
    final schema = exportData['schema'] as Map<String, dynamic>?;
    if (schema == null || schema['type'] != 'aura_one_journal_export') {
      throw Exception('Invalid export format');
    }
    
    final version = schema['version'] as String?;
    if (version == null || !_isCompatibleVersion(version)) {
      throw Exception('Incompatible export version: $version');
    }
    
    // Extract media files to temporary directory
    final tempDir = await getTemporaryDirectory();
    final mediaDir = Directory(path.join(tempDir.path, 'blossom_import_media'));
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }
    await mediaDir.create();
    
    for (final file in archive.files) {
      if (file.name.startsWith('media/') && file.isFile) {
        final fileName = path.basename(file.name);
        final mediaFile = File(path.join(mediaDir.path, fileName));
        await mediaFile.writeAsBytes(file.content as List<int>);
      }
    }
    
    exportData['_mediaDirectory'] = mediaDir.path;
    
    onProgress?.call(1.0);
    
    return exportData;
  }
  
  /// Check if export version is compatible
  static bool _isCompatibleVersion(String version) {
    // For now, only support exact version match
    // In future, implement semantic versioning comparison
    return version == ExportSchema.schemaVersion;
  }
  
  /// Get export file size estimate
  static Future<int> estimateExportSize({
    required List<Map<String, dynamic>> journalEntries,
    List<File>? mediaFiles,
  }) async {
    // Estimate JSON size (rough calculation)
    int jsonSize = 0;
    for (final entry in journalEntries) {
      jsonSize += json.encode(entry).length;
    }
    jsonSize += 5000; // Overhead for structure and metadata
    
    // Calculate media files size
    int mediaSize = 0;
    if (mediaFiles != null) {
      for (final file in mediaFiles) {
        if (await file.exists()) {
          mediaSize += await file.length();
        }
      }
    }
    
    // ZIP compression typically achieves 50-70% compression for JSON
    // Media files (images/videos) don't compress much
    return (jsonSize * 0.4).round() + mediaSize;
  }
}

/// Result of a Blossom export operation
class BlossomExportResult {
  final String hash;
  final List<String> urls;
  final List<String> successfulServers;
  final Map<String, String> failedServers;
  final int size;
  final bool encrypted;
  final DateTime exportDate;
  
  BlossomExportResult({
    required this.hash,
    required this.urls,
    required this.successfulServers,
    required this.failedServers,
    required this.size,
    required this.encrypted,
    required this.exportDate,
  });
  
  Map<String, dynamic> toJson() => {
    'hash': hash,
    'urls': urls,
    'successfulServers': successfulServers,
    'failedServers': failedServers,
    'size': size,
    'encrypted': encrypted,
    'exportDate': exportDate.toIso8601String(),
  };
}