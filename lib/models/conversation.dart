import 'package:hive/hive.dart';
import 'email_message.dart';

part 'conversation.g.dart';

/// A conversation model that groups related emails together (like Gmail)
@HiveType(typeId: 7)
class Conversation extends HiveObject {
  /// Unique identifier for the conversation
  @HiveField(0)
  late String id;

  /// Subject of the conversation (cleaned up)
  @HiveField(1)
  late String subject;

  /// List of message IDs in this conversation, ordered chronologically
  @HiveField(2)
  late List<String> messageIds;

  /// The latest message date in the conversation
  @HiveField(3)
  late DateTime lastMessageDate;

  /// The account ID this conversation belongs to
  @HiveField(4)
  late String accountId;

  /// Whether any message in the conversation is unread
  @HiveField(5)
  late bool hasUnreadMessages;

  /// Whether any message in the conversation is important
  @HiveField(6)
  late bool hasImportantMessages;

  /// Number of messages in the conversation
  @HiveField(7)
  late int messageCount;

  /// Primary participants (senders/recipients) in the conversation
  @HiveField(8)
  late List<String> participants;

  /// Preview text from the latest message
  @HiveField(9)
  String? previewText;

  /// Whether the conversation is expanded in the UI
  @HiveField(10)
  bool isExpanded = false;

  /// Folder where the conversation is displayed (based on latest message)
  @HiveField(11)
  late EmailFolder folder;

  /// Creates a new conversation
  Conversation({
    required this.id,
    required this.subject,
    required this.messageIds,
    required this.lastMessageDate,
    required this.accountId,
    this.hasUnreadMessages = false,
    this.hasImportantMessages = false,
    required this.messageCount,
    required this.participants,
    this.previewText,
    this.isExpanded = false,
    required this.folder,
  });

  /// Creates an empty conversation (used for default values)
  factory Conversation.empty() {
    return Conversation(
      id: '',
      subject: '',
      messageIds: [],
      lastMessageDate: DateTime.now(),
      accountId: '',
      messageCount: 0,
      participants: [],
      folder: EmailFolder.inbox,
    );
  }

  /// Creates a conversation from a single email message
  factory Conversation.fromMessage(EmailMessage message) {
    return Conversation(
      id: message.threadId ?? _generateThreadId(message),
      subject: _cleanSubject(message.subject),
      messageIds: [message.messageId],
      lastMessageDate: message.date,
      accountId: message.accountId,
      hasUnreadMessages: !message.isRead,
      hasImportantMessages: message.isImportant,
      messageCount: 1,
      participants: _extractParticipants(message),
      previewText: message.previewText ?? _generatePreview(message.textBody),
      folder: message.folder,
    );
  }

  /// Adds a message to this conversation
  void addMessage(EmailMessage message) {
    if (!messageIds.contains(message.messageId)) {
      messageIds.add(message.messageId);
      messageIds.sort(); // Keep chronological order

      // Update conversation metadata
      if (message.date.isAfter(lastMessageDate)) {
        lastMessageDate = message.date;
        previewText = message.previewText ?? _generatePreview(message.textBody);
      }

      messageCount = messageIds.length;
      hasUnreadMessages = hasUnreadMessages || !message.isRead;
      hasImportantMessages = hasImportantMessages || message.isImportant;

      // Add new participants
      final newParticipants = _extractParticipants(message);
      for (final participant in newParticipants) {
        if (!participants.contains(participant)) {
          participants.add(participant);
        }
      }
    }
  }

  /// Removes a message from this conversation
  void removeMessage(String messageId) {
    messageIds.remove(messageId);
    messageCount = messageIds.length;
  }

  /// Updates conversation metadata based on current messages
  void updateFromMessages(List<EmailMessage> messages) {
    if (messages.isEmpty) return;

    // Sort messages by date
    messages.sort((a, b) => a.date.compareTo(b.date));

    // Update basic properties
    final latestMessage = messages.last;
    lastMessageDate = latestMessage.date;
    previewText = latestMessage.previewText ?? _generatePreview(latestMessage.textBody);
    messageCount = messages.length;

    // Check for unread/important messages
    hasUnreadMessages = messages.any((msg) => !msg.isRead);
    hasImportantMessages = messages.any((msg) => msg.isImportant);

    // Update participants
    participants.clear();
    for (final message in messages) {
      final messageParticipants = _extractParticipants(message);
      for (final participant in messageParticipants) {
        if (!participants.contains(participant)) {
          participants.add(participant);
        }
      }
    }
  }

  /// Generates a thread ID from message properties
  static String _generateThreadId(EmailMessage message) {
    // Use existing threadId if available
    if (message.threadId != null && message.threadId!.isNotEmpty) {
      return message.threadId!;
    }

    // Generate based on cleaned subject and initial participants
    final cleanedSubject = _cleanSubject(message.subject);
    final participantHash = _extractParticipants(message).join('|').hashCode;
    return '${cleanedSubject.hashCode}_$participantHash';
  }

  /// Cleans the subject line for threading (removes Re:, Fwd:, etc.)
  static String _cleanSubject(String subject) {
    String cleaned = subject.trim();

    // Remove common reply/forward prefixes
    final prefixes = ['re:', 'fwd:', 'fw:', 'aw:', 'sv:', 'vs:', 'wg:'];
    for (final prefix in prefixes) {
      final pattern = RegExp('^$prefix\\s*', caseSensitive: false);
      cleaned = cleaned.replaceFirst(pattern, '');
    }

    // Remove sequence numbers like [2], (3), etc.
    cleaned = cleaned.replaceAll(RegExp(r'\s*\[\d+\]\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*\(\d+\)\s*'), '');

    return cleaned.trim();
  }

  /// Extracts participants from an email message
  static List<String> _extractParticipants(EmailMessage message) {
    final participants = <String>[];

    participants.add(message.from);
    participants.addAll(message.to);
    if (message.cc != null) participants.addAll(message.cc!);

    // Clean and deduplicate
    return participants
        .map((email) => _extractEmailAddress(email))
        .where((email) => email.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Extracts email address from "Name &lt;email@domain.com&gt;" format
  static String _extractEmailAddress(String emailString) {
    final emailRegex = RegExp(r'<([^>]+)>');
    final match = emailRegex.firstMatch(emailString);

    if (match != null) {
      return match.group(1) ?? emailString;
    }

    // If no angle brackets, assume the whole string is an email
    return emailString.trim();
  }

  /// Generates a preview from text body
  static String _generatePreview(String textBody, {int maxLength = 100}) {
    if (textBody.isEmpty) return '';

    // Remove extra whitespace and newlines
    String preview = textBody.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Truncate if needed
    if (preview.length > maxLength) {
      preview = '${preview.substring(0, maxLength)}...';
    }

    return preview;
  }
}