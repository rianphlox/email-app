import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/email_message.dart';
import '../utils/date_utils.dart';

/// A widget that displays a conversation (thread) in Gmail-like style
class ConversationItem extends StatefulWidget {
  final Conversation conversation;
  final List<EmailMessage> messages;
  final Function(EmailMessage)? onMessageTap;
  final Function(Conversation)? onConversationTap;
  final Function(String)? onAvatarTap;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const ConversationItem({
    super.key,
    required this.conversation,
    required this.messages,
    this.onMessageTap,
    this.onConversationTap,
    this.onAvatarTap,
    this.isSelected = false,
    this.onLongPress,
  });

  @override
  State<ConversationItem> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<ConversationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _isExpanded = widget.conversation.isExpanded;
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latestMessage = _getLatestMessage();
    final messageCount = widget.conversation.messageCount;
    final hasMultipleMessages = messageCount > 1;

    return Container(
      decoration: BoxDecoration(
        color: widget.isSelected
            ? (isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1))
            : null,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF333333) : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Conversation header (always visible)
          _buildConversationHeader(context, latestMessage, hasMultipleMessages, isDark),

          // Expanded conversation messages
          if (hasMultipleMessages && _isExpanded)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: _buildExpandedMessages(context, isDark),
            ),
        ],
      ),
    );
  }

  /// Builds the conversation header (collapsed view)
  Widget _buildConversationHeader(
    BuildContext context,
    EmailMessage latestMessage,
    bool hasMultipleMessages,
    bool isDark,
  ) {
    return InkWell(
      onTap: hasMultipleMessages ? _toggleExpanded : () => widget.onMessageTap?.call(latestMessage),
      onLongPress: widget.onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender avatar with message count indicator
            _buildAvatarWithCount(latestMessage, hasMultipleMessages, isDark),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First row: Sender names and time
                  Row(
                    children: [
                      Expanded(
                        child: _buildSenderNames(isDark),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatUtils.formatRelativeDate(latestMessage.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Subject line
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.conversation.subject.isNotEmpty
                              ? widget.conversation.subject
                              : 'No Subject',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: widget.conversation.hasUnreadMessages
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Important indicator
                      if (widget.conversation.hasImportantMessages)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.yellow[600],
                          ),
                        ),

                      // Expansion indicator for multi-message conversations
                      if (hasMultipleMessages)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Preview text
                  if (widget.conversation.previewText != null && widget.conversation.previewText!.isNotEmpty)
                    Text(
                      widget.conversation.previewText!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: widget.conversation.hasUnreadMessages
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Unread indicator
            if (widget.conversation.hasUnreadMessages)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF66B3FF) : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the avatar with message count indicator
  Widget _buildAvatarWithCount(EmailMessage message, bool hasMultipleMessages, bool isDark) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => widget.onAvatarTap?.call(message.from),
          child: CircleAvatar(
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
        ),

        // Message count indicator for conversations
        if (hasMultipleMessages)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF66B3FF) : Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                widget.conversation.messageCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the sender names display
  Widget _buildSenderNames(bool isDark) {
    // Get unique senders from the conversation participants
    final senders = <String>[];
    for (final message in widget.messages) {
      final senderName = _extractSenderName(message.from);
      if (!senders.contains(senderName)) {
        senders.add(senderName);
      }
    }

    String displayText;
    if (senders.length == 1) {
      displayText = senders.first;
    } else if (senders.length == 2) {
      displayText = '${senders.first} & ${senders.last}';
    } else {
      displayText = '${senders.first} & ${senders.length - 1} others';
    }

    return Text(
      displayText,
      style: TextStyle(
        fontSize: 15,
        fontWeight: widget.conversation.hasUnreadMessages
            ? FontWeight.w600
            : FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the expanded message list
  Widget _buildExpandedMessages(BuildContext context, bool isDark) {
    // Sort messages chronologically
    final sortedMessages = List<EmailMessage>.from(widget.messages);
    sortedMessages.sort((a, b) => a.date.compareTo(b.date));

    return Container(
      margin: const EdgeInsets.only(left: 52, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A202C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: sortedMessages.asMap().entries.map((entry) {
          final index = entry.key;
          final message = entry.value;
          final isLast = index == sortedMessages.length - 1;

          return _buildIndividualMessage(context, message, isDark, isLast);
        }).toList(),
      ),
    );
  }

  /// Builds an individual message in the expanded view
  Widget _buildIndividualMessage(BuildContext context, EmailMessage message, bool isDark, bool isLast) {
    return InkWell(
      onTap: () => widget.onMessageTap?.call(message),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message header
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isDark ? const Color(0xFF4A5568) : Colors.grey[400],
                  child: Text(
                    _getInitials(message.from),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    _extractSenderName(message.from),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                Text(
                  DateFormatUtils.formatRelativeDate(message.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),

                if (!message.isRead)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF66B3FF) : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),

            // Message preview
            if (message.previewText != null && message.previewText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 28),
                child: Text(
                  message.previewText!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Attachments indicator
            if (message.attachments != null && message.attachments!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 28),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${message.attachments!.length} attachment${message.attachments!.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Gets the latest message from the conversation
  EmailMessage _getLatestMessage() {
    if (widget.messages.isEmpty) {
      throw StateError('Conversation has no messages');
    }

    // Sort messages by date and return the latest
    final sortedMessages = List<EmailMessage>.from(widget.messages);
    sortedMessages.sort((a, b) => b.date.compareTo(a.date));
    return sortedMessages.first;
  }

  /// Toggles the expanded state of the conversation
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      widget.conversation.isExpanded = _isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    widget.onConversationTap?.call(widget.conversation);
  }

  /// Extracts initials from an email address or name
  String _getInitials(String emailOrName) {
    final name = _extractSenderName(emailOrName);
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }

  /// Extracts the sender name from email header
  String _extractSenderName(String from) {
    // Extract name from "Name <email@domain.com>" format
    final nameMatch = RegExp(r'^(.*?)\s*<').firstMatch(from);
    if (nameMatch != null) {
      final name = nameMatch.group(1)?.trim() ?? '';
      if (name.isNotEmpty) {
        return name.replaceAll('"', '').replaceAll("'", ''); // Remove quotes
      }
    }

    // Extract name from email address (before @)
    final emailMatch = RegExp(r'([^<\s]+@[^>\s]+)').firstMatch(from);
    if (emailMatch != null) {
      final email = emailMatch.group(1)!;
      final localPart = email.split('@')[0];
      return localPart.split('.').map((part) => part.isEmpty ? part : part[0].toUpperCase() + part.substring(1)).join(' ');
    }

    return from.trim();
  }
}