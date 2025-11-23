import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../models/email_message.dart';
import '../services/attachment_service.dart';

/// A widget that displays email attachments with previews and download functionality
class AttachmentPreview extends StatefulWidget {
  final EmailAttachment attachment;
  final VoidCallback? onTap;

  const AttachmentPreview({
    super.key,
    required this.attachment,
    this.onTap,
  });

  @override
  State<AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<AttachmentPreview> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _localPath = widget.attachment.localPath;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: _isDownloading ? null : _handleTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // File type icon with preview
              _buildFileIcon(),

              const SizedBox(width: 12),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.attachment.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatFileSize(widget.attachment.size),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getFileTypeColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getFileExtension().toUpperCase(),
                            style: TextStyle(
                              color: _getFileTypeColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Download/Open button
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    final color = _getFileTypeColor();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getFileIcon(),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isDownloading) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          children: [
            CircularProgressIndicator(
              value: _downloadProgress,
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            Center(
              child: Text(
                '${(_downloadProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isDownloaded = _localPath != null;

    return IconButton(
      onPressed: _handleTap,
      icon: Icon(
        isDownloaded ? Icons.open_in_new : Icons.download,
        color: Theme.of(context).colorScheme.primary,
      ),
      tooltip: isDownloaded ? 'Open file' : 'Download file',
    );
  }

  IconData _getFileIcon() {
    final fileType = _getFileType();

    switch (fileType) {
      case FileType.image:
        return Icons.image;
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.document:
        return Icons.description;
      case FileType.spreadsheet:
        return Icons.table_chart;
      case FileType.presentation:
        return Icons.slideshow;
      case FileType.archive:
        return Icons.archive;
      case FileType.video:
        return Icons.play_circle;
      case FileType.audio:
        return Icons.audiotrack;
      case FileType.code:
        return Icons.code;
      case FileType.unknown:
        return Icons.attach_file;
    }
  }

  Color _getFileTypeColor() {
    final fileType = _getFileType();

    switch (fileType) {
      case FileType.image:
        return Colors.green;
      case FileType.pdf:
        return Colors.red;
      case FileType.document:
        return Colors.blue;
      case FileType.spreadsheet:
        return Colors.green.shade700;
      case FileType.presentation:
        return Colors.orange;
      case FileType.archive:
        return Colors.purple;
      case FileType.video:
        return Colors.pink;
      case FileType.audio:
        return Colors.indigo;
      case FileType.code:
        return Colors.teal;
      case FileType.unknown:
        return Colors.grey;
    }
  }

  FileType _getFileType() {
    final extension = _getFileExtension().toLowerCase();

    // Image files
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(extension)) {
      return FileType.image;
    }

    // Document files
    if (['pdf'].contains(extension)) {
      return FileType.pdf;
    }
    if (['doc', 'docx', 'txt', 'rtf', 'odt'].contains(extension)) {
      return FileType.document;
    }
    if (['xls', 'xlsx', 'csv', 'ods'].contains(extension)) {
      return FileType.spreadsheet;
    }
    if (['ppt', 'pptx', 'odp'].contains(extension)) {
      return FileType.presentation;
    }

    // Archive files
    if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(extension)) {
      return FileType.archive;
    }

    // Media files
    if (['mp4', 'avi', 'mov', 'mkv', 'flv', 'wmv', 'webm'].contains(extension)) {
      return FileType.video;
    }
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'].contains(extension)) {
      return FileType.audio;
    }

    // Code files
    if (['js', 'ts', 'dart', 'py', 'java', 'cpp', 'c', 'h', 'css', 'html', 'xml', 'json', 'yaml', 'yml'].contains(extension)) {
      return FileType.code;
    }

    return FileType.unknown;
  }

  String _getFileExtension() {
    final name = widget.attachment.name;
    final lastDotIndex = name.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == name.length - 1) {
      return '';
    }
    return name.substring(lastDotIndex + 1);
  }

  String _formatFileSize(int bytes) {
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

  Future<void> _handleTap() async {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    if (_localPath != null) {
      // File is already downloaded, open it
      await _openFile();
    } else {
      // Download the file first
      await _downloadFile();
    }
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final downloadPath = await AttachmentService.downloadAttachment(
        widget.attachment,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (downloadPath != null) {
        setState(() {
          _localPath = downloadPath;
          _isDownloading = false;
        });

        // Update the attachment with local path
        widget.attachment.localPath = downloadPath;

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded ${widget.attachment.name}'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: _openFile,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${widget.attachment.name}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openFile() async {
    if (_localPath == null) return;

    try {
      final result = await OpenFile.open(_localPath!);

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open ${widget.attachment.name}: ${result.message}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open ${widget.attachment.name}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Widget that displays a list of attachments
class AttachmentsList extends StatelessWidget {
  final List<EmailAttachment> attachments;

  const AttachmentsList({
    super.key,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ...attachments.map((attachment) => AttachmentPreview(
            attachment: attachment,
          )),
        ],
      ),
    );
  }
}

enum FileType {
  image,
  pdf,
  document,
  spreadsheet,
  presentation,
  archive,
  video,
  audio,
  code,
  unknown,
}