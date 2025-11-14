import 'package:flutter/material.dart';
import '../models/email_message.dart';

/// Processes email attachments similar to Thunderbird's AttachmentResolver
class AttachmentProcessor {

  /// Processes inline attachments and replaces cid: references in HTML
  static String processInlineAttachments({
    required String htmlContent,
    required List<EmailAttachment>? attachments,
  }) {
    if (attachments == null || attachments.isEmpty) {
      return htmlContent;
    }

    String processedHtml = htmlContent;

    for (final attachment in attachments) {
      if (attachment.contentId.isNotEmpty) {
        // Replace cid: references with data URLs or local paths
        final cidPattern = 'cid:${attachment.contentId}';

        if (attachment.localPath != null) {
          // Use local file path
          processedHtml = processedHtml.replaceAll(
            cidPattern,
            'file://${attachment.localPath}',
          );
        } else {
          // For now, replace with placeholder
          processedHtml = processedHtml.replaceAll(
            cidPattern,
            _getAttachmentPlaceholder(attachment),
          );
        }
      }
    }

    return processedHtml;
  }

  /// Gets a placeholder for attachments that haven't been downloaded
  static String _getAttachmentPlaceholder(EmailAttachment attachment) {
    if (_isImageAttachment(attachment)) {
      return 'data:image/svg+xml;base64,${_getImagePlaceholderSvg()}';
    }

    return '#'; // Default placeholder for non-image attachments
  }

  /// Checks if an attachment is an image
  static bool _isImageAttachment(EmailAttachment attachment) {
    final imageMimeTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/bmp',
      'image/webp',
      'image/svg+xml',
    ];

    return imageMimeTypes.contains(attachment.mimeType.toLowerCase());
  }

  /// Gets a base64 encoded SVG placeholder for images
  static String _getImagePlaceholderSvg() {
    // Return base64 encoded SVG placeholder
    return 'PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjE1MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjE1MCIgZmlsbD0iI2YwZjBmMCIgc3Ryb2tlPSIjZGRkIiBzdHJva2Utd2lkdGg9IjIiLz4KICA8dGV4dCB4PSIxMDAiIHk9Ijc1IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSIjOTk5IiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMTQiPgogICAgPHRzcGFuIHg9IjEwMCIgeT0iNjUiPkltYWdlPC90c3Bhbj4KICAgIDx0c3BhbiB4PSIxMDAiIHk9Ijg1Ij5Mb2FkaW5nLi4uPC90c3Bhbj4KICA8L3RleHQ+Cjwvc3ZnPg==';
  }

  /// Gets icon for different attachment types
  static IconData getAttachmentIcon(EmailAttachment attachment) {
    final mimeType = attachment.mimeType.toLowerCase();

    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    } else if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart;
    } else if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Icons.slideshow;
    } else if (mimeType.contains('zip') || mimeType.contains('archive')) {
      return Icons.archive;
    } else if (mimeType.startsWith('text/')) {
      return Icons.text_snippet;
    } else {
      return Icons.attach_file;
    }
  }

  /// Formats file size for display
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

  /// Gets color for attachment based on type
  static Color getAttachmentColor(EmailAttachment attachment) {
    final mimeType = attachment.mimeType.toLowerCase();

    if (mimeType.startsWith('image/')) {
      return Colors.green;
    } else if (mimeType.startsWith('video/')) {
      return Colors.red;
    } else if (mimeType.startsWith('audio/')) {
      return Colors.purple;
    } else if (mimeType.contains('pdf')) {
      return Colors.red.shade700;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Colors.blue;
    } else if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Colors.green.shade700;
    } else if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Colors.orange;
    } else if (mimeType.contains('zip') || mimeType.contains('archive')) {
      return Colors.grey.shade600;
    } else {
      return Colors.grey;
    }
  }

  /// Checks if attachment can be previewed inline
  static bool canPreviewInline(EmailAttachment attachment) {
    final mimeType = attachment.mimeType.toLowerCase();

    return mimeType.startsWith('image/') ||
           mimeType.startsWith('text/') ||
           mimeType.contains('pdf');
  }

  /// Gets a safe filename for the attachment
  static String getSafeFilename(String originalName) {
    // Remove potentially dangerous characters
    String safeName = originalName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // Limit length
    if (safeName.length > 100) {
      final extension = safeName.split('.').last;
      final nameWithoutExt = safeName.substring(0, safeName.lastIndexOf('.'));
      safeName = '${nameWithoutExt.substring(0, 96 - extension.length)}.$extension';
    }

    return safeName;
  }

  /// Creates attachment metadata for display
  static Map<String, dynamic> getAttachmentMetadata(EmailAttachment attachment) {
    return {
      'name': attachment.name,
      'safeName': getSafeFilename(attachment.name),
      'size': formatFileSize(attachment.size),
      'icon': getAttachmentIcon(attachment),
      'color': getAttachmentColor(attachment),
      'canPreview': canPreviewInline(attachment),
      'isImage': _isImageAttachment(attachment),
      'mimeType': attachment.mimeType,
    };
  }
}