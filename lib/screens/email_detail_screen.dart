import 'package:flutter/material.dart';
import '../models/email_message.dart';
import '../services/html_email_renderer.dart';
import 'compose_screen.dart';

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
          IconButton(
            onPressed: () => _showMoreActions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildEmailContent(context),
            ),
          ),
          _buildActionButtons(context),
        ],
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

  Widget _buildActionButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF333333) : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _replyToEmail(context),
                icon: const Icon(Icons.reply),
                label: const Text('Reply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF333333) : Colors.grey[200],
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _forwardEmail(context),
                icon: const Icon(Icons.forward),
                label: const Text('Forward'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF333333) : Colors.grey[200],
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF333333) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _showMoreActions(context),
                icon: const Icon(Icons.more_horiz),
                color: isDark ? Colors.white : Colors.black87,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF4A5568) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Top section with sender info and time
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? const Color(0xFF4A5568) : Colors.grey[400],
                  child: Text(
                    _getInitials(message.from),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _extractSenderName(message.from),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            _formatRelativeDate(message.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'to ${message.to.isNotEmpty ? _extractNameFromEmail(message.to.first) : 'Unknown'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'unsubscribe':
                        _showUnsubscribeDialog(context);
                        break;
                      case 'report_spam':
                        _reportSpam(context);
                        break;
                      case 'block_sender':
                        _blockSender(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'unsubscribe',
                      child: Text('Unsubscribe'),
                    ),
                    const PopupMenuItem(
                      value: 'report_spam',
                      child: Text('Report spam'),
                    ),
                    const PopupMenuItem(
                      value: 'block_sender',
                      child: Text('Block sender'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expandable detailed header section
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const SizedBox.shrink(),
              trailing: Icon(
                Icons.keyboard_arrow_down,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A202C) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // From
                      _buildDetailRow(
                        context,
                        'From',
                        '${_extractSenderName(message.from)} • ${_extractEmailFromHeader(message.from)}',
                        isDark,
                      ),
                      const SizedBox(height: 12),

                      // Reply-to (if different from From)
                      if (_extractEmailFromHeader(message.from) != message.from)
                        _buildDetailRow(
                          context,
                          'Reply-to',
                          '${_extractSenderName(message.from)} • ${_extractEmailFromHeader(message.from)}',
                          isDark,
                        ),

                      // To
                      _buildDetailRow(
                        context,
                        'To',
                        '${_extractNameFromEmail(message.to.isNotEmpty ? message.to.first : '')} • ${message.to.isNotEmpty ? message.to.first : 'Unknown'}',
                        isDark,
                      ),
                      const SizedBox(height: 12),

                      // Date
                      _buildDetailRow(
                        context,
                        'Date',
                        _formatFullDate(message.date),
                        isDark,
                      ),
                      const SizedBox(height: 12),

                      // Security info
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Standard encryption (TLS).',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showSecurityDetails(context),
                                  child: Text(
                                    'View security details',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? const Color(0xFF66B3FF) : Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          useDarkMode: Theme.of(context).brightness == Brightness.dark,
          attachments: message.attachments,
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

  Widget _buildDetailRow(BuildContext context, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String fromHeader) {
    final name = _extractSenderName(fromHeader);
    if (name.isEmpty) return '?';

    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _extractSenderName(String fromHeader) {
    if (fromHeader.isEmpty) return 'Unknown';

    // Extract name from "Display Name <email@domain.com>" format
    final match = RegExp(r'^(.*?)\s*<(.+?)>$').firstMatch(fromHeader.trim());
    if (match != null) {
      final name = match.group(1)?.trim().replaceAll('"', '') ?? '';
      if (name.isNotEmpty) {
        return name;
      }
      return _extractNameFromEmail(match.group(2) ?? '');
    }

    return _extractNameFromEmail(fromHeader.trim());
  }

  String _extractEmailFromHeader(String fromHeader) {
    final match = RegExp(r'<(.+?)>$').firstMatch(fromHeader.trim());
    if (match != null) {
      return match.group(1) ?? fromHeader;
    }
    return fromHeader.trim();
  }

  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return 'Unknown';

    final localPart = email.split('@').first;
    return localPart
        .replaceAll(RegExp(r'[._-]'), ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ')
        .trim();
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 7) {
      return '${difference.inDays ~/ 7} week${difference.inDays ~/ 7 > 1 ? 's' : ''} ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatFullDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${months[date.month - 1]} ${date.day}, ${date.year}, $time PM';
  }



  void _replyToEmail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          replyToMessage: message,
          isReply: true,
        ),
      ),
    );
  }

  void _forwardEmail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          forwardMessage: message,
          isForward: true,
        ),
      ),
    );
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

  void _showUnsubscribeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsubscribe'),
        content: const Text('Do you want to unsubscribe from emails from this sender?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement unsubscribe functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unsubscribe request sent')),
              );
            },
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );
  }

  void _reportSpam(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Spam'),
        content: const Text('Report this email as spam and block future emails from this sender?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement spam reporting functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email reported as spam')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _blockSender(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Sender'),
        content: Text('Block all future emails from ${_extractSenderName(message.from)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement block sender functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${_extractSenderName(message.from)} blocked')),
              );
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This message was encrypted using Transport Layer Security (TLS).',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Encryption:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Text(
              '• Message encrypted in transit\n• Standard TLS encryption\n• Sender identity verified',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Star'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email starred')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Add label'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement label functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email archived')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteEmail(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report spam'),
              onTap: () {
                Navigator.pop(context);
                _reportSpam(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}