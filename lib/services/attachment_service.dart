import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/email_message.dart';

/// Service for handling email attachment downloads and management
class AttachmentService {
  static const String _attachmentsDir = 'attachments';

  /// Downloads an attachment and returns the local file path
  static Future<String?> downloadAttachment(
    EmailAttachment attachment, {
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('📎 Downloading attachment: ${attachment.name}');

      // Create attachments directory if it doesn't exist
      final attachmentsPath = await _getAttachmentsDirectory();
      final attachmentsDir = Directory(attachmentsPath);
      if (!attachmentsDir.existsSync()) {
        await attachmentsDir.create(recursive: true);
      }

      // Generate safe filename
      final safeFileName = _generateSafeFileName(attachment.name);
      final filePath = path.join(attachmentsPath, safeFileName);

      // Check if file already exists
      final file = File(filePath);
      if (file.existsSync()) {
        final existingSize = await file.length();
        if (existingSize == attachment.size) {
          debugPrint('📎 Attachment already exists: $filePath');
          return filePath;
        } else {
          // File exists but size is different, delete and re-download
          await file.delete();
        }
      }

      // TODO: Download attachment from email service
      // For now, create a placeholder implementation
      final attachmentData = await _downloadAttachmentData(attachment, onProgress);

      if (attachmentData != null) {
        await file.writeAsBytes(attachmentData);
        debugPrint('📎 Successfully downloaded: $filePath');
        return filePath;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error downloading attachment: $e');
      rethrow;
    }
  }

  /// Gets all downloaded attachments
  static Future<List<File>> getDownloadedAttachments() async {
    try {
      final attachmentsPath = await _getAttachmentsDirectory();
      final attachmentsDir = Directory(attachmentsPath);

      if (!attachmentsDir.existsSync()) {
        return [];
      }

      final files = await attachmentsDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      return files;
    } catch (e) {
      debugPrint('❌ Error getting downloaded attachments: $e');
      return [];
    }
  }

  /// Clears all downloaded attachments
  static Future<void> clearDownloadedAttachments() async {
    try {
      final attachmentsPath = await _getAttachmentsDirectory();
      final attachmentsDir = Directory(attachmentsPath);

      if (attachmentsDir.existsSync()) {
        await attachmentsDir.delete(recursive: true);
        debugPrint('📎 Cleared all downloaded attachments');
      }
    } catch (e) {
      debugPrint('❌ Error clearing downloaded attachments: $e');
    }
  }

  /// Gets the total size of downloaded attachments
  static Future<int> getDownloadedAttachmentsSize() async {
    try {
      final files = await getDownloadedAttachments();
      int totalSize = 0;

      for (final file in files) {
        totalSize += await file.length();
      }

      return totalSize;
    } catch (e) {
      debugPrint('❌ Error calculating downloaded attachments size: $e');
      return 0;
    }
  }

  /// Deletes a specific downloaded attachment
  static Future<bool> deleteAttachment(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        debugPrint('📎 Deleted attachment: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting attachment: $e');
      return false;
    }
  }

  /// Checks if an attachment is already downloaded
  static Future<bool> isAttachmentDownloaded(EmailAttachment attachment) async {
    try {
      final attachmentsPath = await _getAttachmentsDirectory();
      final safeFileName = _generateSafeFileName(attachment.name);
      final filePath = path.join(attachmentsPath, safeFileName);
      final file = File(filePath);

      if (file.existsSync()) {
        final existingSize = await file.length();
        return existingSize == attachment.size;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking if attachment is downloaded: $e');
      return false;
    }
  }

  /// Gets the local path for an attachment if it's downloaded
  static Future<String?> getLocalPath(EmailAttachment attachment) async {
    try {
      final isDownloaded = await isAttachmentDownloaded(attachment);
      if (isDownloaded) {
        final attachmentsPath = await _getAttachmentsDirectory();
        final safeFileName = _generateSafeFileName(attachment.name);
        return path.join(attachmentsPath, safeFileName);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting local path: $e');
      return null;
    }
  }

  /// Gets the attachments directory path
  static Future<String> _getAttachmentsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, _attachmentsDir);
  }

  /// Generates a safe filename from the original filename
  static String _generateSafeFileName(String originalName) {
    // Remove or replace unsafe characters
    String safeName = originalName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    // Ensure the filename isn't too long
    if (safeName.length > 200) {
      final extension = path.extension(safeName);
      final nameWithoutExt = path.basenameWithoutExtension(safeName);
      safeName = '${nameWithoutExt.substring(0, 200 - extension.length)}$extension';
    }

    return safeName;
  }

  /// Downloads attachment data from the email service
  static Future<List<int>?> _downloadAttachmentData(
    EmailAttachment attachment,
    Function(double progress)? onProgress,
  ) async {
    try {
      // TODO: Implement actual download from Gmail/Yahoo APIs
      // This is a placeholder implementation

      // Simulate download progress
      if (onProgress != null) {
        for (int i = 0; i <= 10; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          onProgress(i / 10.0);
        }
      }

      // For demo purposes, create a simple text file
      if (attachment.name.endsWith('.txt')) {
        final content = 'This is a sample attachment: ${attachment.name}';
        return content.codeUnits;
      }

      // Return null for other file types until real implementation
      return null;
    } catch (e) {
      debugPrint('❌ Error downloading attachment data: $e');
      return null;
    }
  }

  /// Creates a preview image for image attachments
  static Future<String?> createImagePreview(
    EmailAttachment attachment,
    String localPath,
  ) async {
    try {
      if (!_isImageFile(attachment.name)) {
        return null;
      }

      // TODO: Implement image preview generation
      // This would create thumbnails for image attachments
      return null;
    } catch (e) {
      debugPrint('❌ Error creating image preview: $e');
      return null;
    }
  }

  /// Checks if a file is an image
  static bool _isImageFile(String filename) {
    final extension = path.extension(filename).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  /// Gets file type from filename
  static String getFileType(String filename) {
    final extension = path.extension(filename).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'].contains(extension)) {
      return 'Image';
    } else if (['.pdf'].contains(extension)) {
      return 'PDF';
    } else if (['.doc', '.docx'].contains(extension)) {
      return 'Document';
    } else if (['.xls', '.xlsx', '.csv'].contains(extension)) {
      return 'Spreadsheet';
    } else if (['.ppt', '.pptx'].contains(extension)) {
      return 'Presentation';
    } else if (['.zip', '.rar', '.7z', '.tar', '.gz'].contains(extension)) {
      return 'Archive';
    } else if (['.mp4', '.avi', '.mov', '.mkv'].contains(extension)) {
      return 'Video';
    } else if (['.mp3', '.wav', '.flac', '.aac'].contains(extension)) {
      return 'Audio';
    } else if (['.txt', '.rtf'].contains(extension)) {
      return 'Text';
    } else {
      return 'File';
    }
  }

  /// Formats file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Checks if device has enough storage for download
  static Future<bool> hasEnoughStorage(int requiredBytes) async {
    try {
      // Add 100MB buffer for safety
      final bufferBytes = 100 * 1024 * 1024;
      final totalRequired = requiredBytes + bufferBytes;

      // TODO: Implement actual storage check using totalRequired
      // For now, assume there's enough storage
      debugPrint('📎 Storage check: ${formatFileSize(totalRequired)} required');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking storage: $e');
      return false;
    }
  }
}