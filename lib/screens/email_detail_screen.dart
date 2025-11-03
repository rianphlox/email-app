import 'package:flutter/material.dart';
import '../models/email_message.dart';
import '../services/email_categorizer.dart';
import '../services/html_email_renderer.dart';

class EmailDetailScreen extends StatelessWidget {
  final EmailMessage message;

  const EmailDetailScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(message.subject.isNotEmpty ? message.subject : 'No Subject'),
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
        child: _buildEmailContent(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _replyToEmail(context),
        child: const Icon(Icons.reply),
      ),
    );
  }

  Widget _buildEmailContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email header
        _buildEmailHeader(context),

        const SizedBox(height: 16),

        // Email body
        _buildEmailBody(context),

        const SizedBox(height: 20),

        // Attachments (if any)
        if (message.attachments?.isNotEmpty == true) _buildAttachments(context),
      ],
    );
  }

  Widget _buildEmailHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Text(
            message.subject.isNotEmpty ? message.subject : 'No Subject',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // From
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'From: ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  message.from,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // To
          if (message.to.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.send,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'To: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    message.to.join(', '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Date and Category
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(message.date),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(message.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  EmailCategorizer.getCategoryDisplayName(message.category),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getCategoryColor(message.category),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailBody(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlEmailRenderer().renderEmailContent(
          htmlContent: message.htmlBody,
          textContent: message.textBody,
          context: context,
        ),
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...message.attachments?.map((attachment) =>
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attachment.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${(attachment.size / 1024).toStringAsFixed(1)} KB',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ) ?? [],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDate = DateTime(date.year, date.month, date.day);

    if (emailDate == today) {
      // Today - show time
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (emailDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (date.year == now.year) {
      // This year - show month and day
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    } else {
      // Different year - show full date
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getCategoryColor(EmailCategory category) {
    switch (category) {
      case EmailCategory.primary:
        return Colors.blue;
      case EmailCategory.promotions:
        return Colors.orange;
      case EmailCategory.social:
        return Colors.green;
      case EmailCategory.updates:
        return Colors.purple;
    }
  }


  void _replyToEmail(BuildContext context) {
    // TODO: Navigate to compose screen with reply data
    debugPrint('Reply functionality not implemented yet');
  }

  void _forwardEmail(BuildContext context) {
    // TODO: Navigate to compose screen with forward data
    debugPrint('Forward functionality not implemented yet');
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