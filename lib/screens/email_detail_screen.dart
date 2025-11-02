import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../models/email_message.dart';
import '../services/gmail_email_renderer.dart';

class EmailDetailScreen extends StatelessWidget {
  final EmailMessage message;

  const EmailDetailScreen({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reply':
                  _replyToEmail(context);
                  break;
                case 'forward':
                  _forwardEmail(context);
                  break;
                case 'delete':
                  _deleteEmail(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reply',
                child: Row(
                  children: [
                    Icon(Icons.reply),
                    SizedBox(width: 8),
                    Text('Reply'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'forward',
                child: Row(
                  children: [
                    Icon(Icons.forward),
                    SizedBox(width: 8),
                    Text('Forward'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject
                    Text(
                      message.subject,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // From
                    _buildInfoRow(
                      'From:',
                      message.from,
                      Icons.person,
                    ),

                    // To
                    _buildInfoRow(
                      'To:',
                      message.to.join(', '),
                      Icons.email,
                    ),

                    // CC (if present)
                    if (message.cc != null && message.cc!.isNotEmpty)
                      _buildInfoRow(
                        'CC:',
                        message.cc!.join(', '),
                        Icons.copy,
                      ),

                    // Date
                    _buildInfoRow(
                      'Date:',
                      _formatDateTime(message.date),
                      Icons.access_time,
                    ),

                    // Attachments (if present)
                    if (message.attachments != null && message.attachments!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.attach_file),
                          const SizedBox(width: 8),
                          Text(
                            'Attachments (${message.attachments!.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: message.attachments!
                            .map((attachment) => _buildAttachmentChip(attachment))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Email body - Gmail-style rendering
            GmailEmailRenderer.renderEmail(message, context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _replyToEmail(context),
        child: const Icon(Icons.reply),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentChip(EmailAttachment attachment) {
    return ActionChip(
      avatar: Icon(_getFileIcon(attachment.mimeType)),
      label: Text(
        attachment.name,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () => _openAttachment(attachment),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('document') || mimeType.contains('msword')) {
      return Icons.description;
    } else if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
      return Icons.table_chart;
    } else if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Icons.slideshow;
    } else {
      return Icons.attach_file;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$month $day, $year at $displayHour:$minute $ampm';
  }

  void _openAttachment(EmailAttachment attachment) async {
    if (attachment.localPath != null) {
      await OpenFile.open(attachment.localPath!);
    } else {
      // TODO: Download attachment first
      print('Attachment download not implemented yet');
    }
  }

  void _replyToEmail(BuildContext context) {
    // TODO: Navigate to compose screen with reply data
    print('Reply functionality not implemented yet');
  }

  void _forwardEmail(BuildContext context) {
    // TODO: Navigate to compose screen with forward data
    print('Forward functionality not implemented yet');
  }

  void _deleteEmail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Email'),
        content: const Text('Are you sure you want to delete this email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
              // TODO: Delete email from provider
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}