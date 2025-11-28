import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/email_message.dart';

/// Manages email conversations and threading functionality
class ConversationManager {
  static const String _conversationsBoxName = 'conversations';
  Box<Conversation>? _conversationsBox;

  static final ConversationManager _instance = ConversationManager._internal();
  factory ConversationManager() => _instance;
  ConversationManager._internal();

  /// Initialize the conversation manager
  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(ConversationAdapter());
    }

    _conversationsBox = await Hive.openBox<Conversation>(_conversationsBoxName);
  }

  /// Groups a list of email messages into conversations
  Future<List<Conversation>> groupIntoConversations(List<EmailMessage> messages, String accountId) async {
    await initialize();

    final Map<String, Conversation> conversationMap = {};
    final Map<String, List<EmailMessage>> threadGroups = {};

    // Step 1: Group messages by thread ID or generate thread IDs
    for (final message in messages) {
      String threadId = _determineThreadId(message, messages);

      // Update message with thread ID if not set
      if (message.threadId != threadId) {
        message.threadId = threadId;
      }

      threadGroups.putIfAbsent(threadId, () => []).add(message);
    }

    // Step 2: Create or update conversations
    for (final entry in threadGroups.entries) {
      final threadId = entry.key;
      final threadMessages = entry.value;

      // Sort messages chronologically
      threadMessages.sort((a, b) => a.date.compareTo(b.date));

      // Check if conversation already exists
      Conversation? existingConversation = _conversationsBox?.get('${accountId}_$threadId');

      if (existingConversation != null) {
        // Update existing conversation
        existingConversation.updateFromMessages(threadMessages);
        conversationMap[threadId] = existingConversation;
      } else {
        // Create new conversation
        final conversation = _createConversationFromMessages(threadId, threadMessages, accountId);
        conversationMap[threadId] = conversation;
      }

      // Save to cache
      await _conversationsBox?.put('${accountId}_$threadId', conversationMap[threadId]!);
    }

    // Step 3: Filter out conversations with zero messages and return sorted conversations
    final conversations = conversationMap.values.where((conversation) {
      if (conversation.messageCount == 0 || conversation.messageIds.isEmpty) {
        debugPrint('⚠️ ConversationManager: Filtering out empty conversation: ${conversation.id}');
        return false;
      }
      return true;
    }).toList();

    conversations.sort((a, b) => b.lastMessageDate.compareTo(a.lastMessageDate));

    debugPrint('📊 ConversationManager: Returning ${conversations.length} valid conversations');
    return conversations;
  }

  /// Determines the thread ID for a message
  String _determineThreadId(EmailMessage message, List<EmailMessage> allMessages) {
    // If message already has a thread ID, use it
    if (message.threadId != null && message.threadId!.isNotEmpty) {
      return message.threadId!;
    }

    // Check if this is a reply (has In-Reply-To or References)
    if (message.inReplyTo != null || (message.references != null && message.references!.isNotEmpty)) {
      // Find the original message this is replying to
      for (final otherMessage in allMessages) {
        if (otherMessage.messageId == message.inReplyTo ||
            (message.references != null && message.references!.contains(otherMessage.messageId))) {
          return otherMessage.threadId ?? _generateThreadId(otherMessage);
        }
      }
    }

    // Check for subject-based threading
    final cleanedSubject = _cleanSubject(message.subject);
    if (cleanedSubject.isNotEmpty) {
      for (final otherMessage in allMessages) {
        if (otherMessage.messageId != message.messageId) {
          final otherSubject = _cleanSubject(otherMessage.subject);
          if (otherSubject == cleanedSubject) {
            // Check if they share common participants
            final participants1 = _extractParticipants(message);
            final participants2 = _extractParticipants(otherMessage);
            final commonParticipants = participants1.where((p) => participants2.contains(p)).length;

            // If they share at least one participant and have the same cleaned subject
            if (commonParticipants > 0) {
              return otherMessage.threadId ?? _generateThreadId(otherMessage);
            }
          }
        }
      }
    }

    // Generate new thread ID
    return _generateThreadId(message);
  }

  /// Generates a thread ID for a message
  String _generateThreadId(EmailMessage message) {
    final cleanedSubject = _cleanSubject(message.subject);
    final participants = _extractParticipants(message);
    final participantHash = participants.join('|').hashCode;
    return 'thread_${cleanedSubject.hashCode}_$participantHash';
  }

  /// Creates a conversation from a group of messages
  Conversation _createConversationFromMessages(String threadId, List<EmailMessage> messages, String accountId) {
    if (messages.isEmpty) {
      debugPrint('⚠️ ConversationManager: Cannot create conversation from empty message list for thread $threadId');
      throw ArgumentError('Cannot create conversation from empty message list');
    }

    // Use the first message as the base
    final firstMessage = messages.first;
    final conversation = Conversation.fromMessage(firstMessage);
    conversation.id = threadId;

    // Add remaining messages
    for (int i = 1; i < messages.length; i++) {
      conversation.addMessage(messages[i]);
    }

    // Final update to ensure all metadata is correct
    conversation.updateFromMessages(messages);

    return conversation;
  }

  /// Gets all conversations for an account
  Future<List<Conversation>> getConversationsForAccount(String accountId) async {
    await initialize();

    final conversations = _conversationsBox?.values
        .where((conversation) => conversation.accountId == accountId)
        .toList() ?? [];

    conversations.sort((a, b) => b.lastMessageDate.compareTo(a.lastMessageDate));
    return conversations;
  }

  /// Gets a specific conversation
  Future<Conversation?> getConversation(String accountId, String threadId) async {
    await initialize();
    return _conversationsBox?.get('${accountId}_$threadId');
  }

  /// Adds a new message to conversations
  Future<void> addMessageToConversations(EmailMessage message) async {
    await initialize();

    final threadId = _determineThreadId(message, [message]);
    final conversationKey = '${message.accountId}_$threadId';

    Conversation? conversation = _conversationsBox?.get(conversationKey);

    if (conversation != null) {
      conversation.addMessage(message);
    } else {
      conversation = Conversation.fromMessage(message);
      conversation.id = threadId;
    }

    // Update message with thread ID
    message.threadId = threadId;

    // Save conversation
    await _conversationsBox?.put(conversationKey, conversation);
  }

  /// Removes a message from conversations
  Future<void> removeMessageFromConversations(String accountId, String messageId, String threadId) async {
    await initialize();

    final conversationKey = '${accountId}_$threadId';
    final conversation = _conversationsBox?.get(conversationKey);

    if (conversation != null) {
      conversation.removeMessage(messageId);

      if (conversation.messageCount == 0) {
        // Remove empty conversation
        await _conversationsBox?.delete(conversationKey);
      } else {
        // Update conversation
        await _conversationsBox?.put(conversationKey, conversation);
      }
    }
  }

  /// Clears all conversations for an account
  Future<void> clearConversationsForAccount(String accountId) async {
    await initialize();

    final keysToDelete = _conversationsBox?.keys
        .where((key) => key.toString().startsWith('${accountId}_'))
        .toList() ?? [];

    for (final key in keysToDelete) {
      await _conversationsBox?.delete(key);
    }
  }

  /// Updates conversation read status
  Future<void> updateConversationReadStatus(String accountId, String threadId, bool isRead) async {
    await initialize();

    final conversationKey = '${accountId}_$threadId';
    final conversation = _conversationsBox?.get(conversationKey);

    if (conversation != null) {
      conversation.hasUnreadMessages = !isRead;
      await _conversationsBox?.put(conversationKey, conversation);
    }
  }

  /// Searches conversations
  Future<List<Conversation>> searchConversations(String accountId, String query) async {
    await initialize();

    final allConversations = await getConversationsForAccount(accountId);
    final lowercaseQuery = query.toLowerCase();

    return allConversations.where((conversation) {
      final searchableText = [
        conversation.subject.toLowerCase(),
        conversation.previewText?.toLowerCase() ?? '',
        ...conversation.participants.map((p) => p.toLowerCase()),
      ].join(' ');

      return searchableText.contains(lowercaseQuery);
    }).toList();
  }

  /// Gets conversation statistics
  Future<Map<String, int>> getConversationStats(String accountId) async {
    await initialize();

    final conversations = await getConversationsForAccount(accountId);

    return {
      'total': conversations.length,
      'unread': conversations.where((c) => c.hasUnreadMessages).length,
      'important': conversations.where((c) => c.hasImportantMessages).length,
      'multiMessage': conversations.where((c) => c.messageCount > 1).length,
    };
  }

  /// Helper method to clean email subjects for threading
  String _cleanSubject(String subject) {
    String cleaned = subject.trim();

    // Remove common reply/forward prefixes
    final prefixes = ['re:', 'fwd:', 'fw:', 'forward:', 'reply:'];
    for (final prefix in prefixes) {
      while (cleaned.toLowerCase().startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length).trim();
      }
    }

    // Remove brackets like [SPAM], [External], etc.
    cleaned = cleaned.replaceAll(RegExp(r'^\[[^\]]*\]\s*'), '');

    return cleaned;
  }

  /// Helper method to extract participants from a message
  List<String> _extractParticipants(EmailMessage message) {
    final participants = <String>[];

    // Add sender
    participants.add(message.from.toLowerCase());

    // Add recipients
    for (final recipient in message.to) {
      participants.add(recipient.toLowerCase());
    }

    // Add CC recipients if any
    if (message.cc != null) {
      for (final ccRecipient in message.cc!) {
        participants.add(ccRecipient.toLowerCase());
      }
    }

    return participants.toSet().toList(); // Remove duplicates
  }
}