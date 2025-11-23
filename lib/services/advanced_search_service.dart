import '../models/email_message.dart';

/// Advanced search service with Gmail-style operators
class AdvancedSearchService {
  /// Searches emails with advanced operators
  static List<EmailMessage> searchEmails(
    List<EmailMessage> emails,
    String query,
  ) {
    if (query.trim().isEmpty) return emails;

    final parsedQuery = _parseSearchQuery(query);

    return emails.where((email) {
      return _matchesQuery(email, parsedQuery);
    }).toList();
  }

  /// Parses search query into structured search criteria
  static SearchQuery _parseSearchQuery(String query) {
    final searchQuery = SearchQuery();
    final tokens = _tokenizeQuery(query);

    for (final token in tokens) {
      if (token.startsWith('from:')) {
        searchQuery.from = token.substring(5);
      } else if (token.startsWith('to:')) {
        searchQuery.to = token.substring(3);
      } else if (token.startsWith('subject:')) {
        searchQuery.subject = token.substring(8);
      } else if (token.startsWith('has:')) {
        final value = token.substring(4);
        if (value == 'attachment') {
          searchQuery.hasAttachment = true;
        }
      } else if (token.startsWith('is:')) {
        final value = token.substring(3);
        switch (value) {
          case 'unread':
            searchQuery.isUnread = true;
            break;
          case 'read':
            searchQuery.isRead = true;
            break;
          case 'important':
            searchQuery.isImportant = true;
            break;
          case 'starred':
            searchQuery.isStarred = true;
            break;
        }
      } else if (token.startsWith('in:')) {
        final value = token.substring(3);
        switch (value) {
          case 'inbox':
            searchQuery.folder = EmailFolder.inbox;
            break;
          case 'sent':
            searchQuery.folder = EmailFolder.sent;
            break;
          case 'trash':
            searchQuery.folder = EmailFolder.trash;
            break;
          case 'spam':
            searchQuery.folder = EmailFolder.spam;
            break;
          case 'archive':
            searchQuery.folder = EmailFolder.archive;
            break;
        }
      } else if (token.startsWith('before:')) {
        searchQuery.beforeDate = _parseDate(token.substring(7));
      } else if (token.startsWith('after:')) {
        searchQuery.afterDate = _parseDate(token.substring(6));
      } else if (token.startsWith('older_than:')) {
        searchQuery.olderThan = _parseDuration(token.substring(11));
      } else if (token.startsWith('newer_than:')) {
        searchQuery.newerThan = _parseDuration(token.substring(11));
      } else if (token.startsWith('size:')) {
        final sizeQuery = token.substring(5);
        if (sizeQuery.startsWith('>')) {
          searchQuery.sizeGreaterThan = _parseSize(sizeQuery.substring(1));
        } else if (sizeQuery.startsWith('<')) {
          searchQuery.sizeLessThan = _parseSize(sizeQuery.substring(1));
        }
      } else if (token.startsWith('-')) {
        // Negative search (exclude)
        searchQuery.excludeTerms.add(token.substring(1));
      } else if (token.startsWith('"') && token.endsWith('"')) {
        // Exact phrase search
        searchQuery.exactPhrases.add(token.substring(1, token.length - 1));
      } else {
        // Regular search term
        searchQuery.terms.add(token);
      }
    }

    return searchQuery;
  }

  /// Tokenizes search query while preserving quoted strings
  static List<String> _tokenizeQuery(String query) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < query.length; i++) {
      final char = query[i];

      if (char == '"') {
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if (char == ' ' && !inQuotes) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  /// Checks if email matches the parsed search query
  static bool _matchesQuery(EmailMessage email, SearchQuery query) {
    // Check sender
    if (query.from != null && !_matchesField(email.from, query.from!)) {
      return false;
    }

    // Check recipients
    if (query.to != null) {
      final allRecipients = [
        ...email.to,
        ...(email.cc ?? []),
        ...(email.bcc ?? []),
      ];
      if (!allRecipients.any((recipient) => _matchesField(recipient, query.to!))) {
        return false;
      }
    }

    // Check subject
    if (query.subject != null && !_matchesField(email.subject, query.subject!)) {
      return false;
    }

    // Check folder
    if (query.folder != null && email.folder != query.folder) {
      return false;
    }

    // Check attachment
    if (query.hasAttachment == true) {
      if (email.attachments == null || email.attachments!.isEmpty) {
        return false;
      }
    }

    // Check read status
    if (query.isRead == true && !email.isRead) {
      return false;
    }
    if (query.isUnread == true && email.isRead) {
      return false;
    }

    // Check important status
    if (query.isImportant == true && !email.isImportant) {
      return false;
    }

    // Check date ranges
    if (query.beforeDate != null && email.date.isAfter(query.beforeDate!)) {
      return false;
    }
    if (query.afterDate != null && email.date.isBefore(query.afterDate!)) {
      return false;
    }

    // Check relative dates
    if (query.olderThan != null) {
      final cutoffDate = DateTime.now().subtract(query.olderThan!);
      if (email.date.isAfter(cutoffDate)) {
        return false;
      }
    }
    if (query.newerThan != null) {
      final cutoffDate = DateTime.now().subtract(query.newerThan!);
      if (email.date.isBefore(cutoffDate)) {
        return false;
      }
    }

    // Check size constraints
    if (query.sizeGreaterThan != null) {
      final emailSize = _estimateEmailSize(email);
      if (emailSize <= query.sizeGreaterThan!) {
        return false;
      }
    }
    if (query.sizeLessThan != null) {
      final emailSize = _estimateEmailSize(email);
      if (emailSize >= query.sizeLessThan!) {
        return false;
      }
    }

    // Check search terms in content
    final emailContent = '${email.subject} ${email.textBody} ${email.from}'.toLowerCase();

    // All terms must be present
    for (final term in query.terms) {
      if (!emailContent.contains(term.toLowerCase())) {
        return false;
      }
    }

    // Exact phrases must be present
    for (final phrase in query.exactPhrases) {
      if (!emailContent.contains(phrase.toLowerCase())) {
        return false;
      }
    }

    // Excluded terms must not be present
    for (final excludeTerm in query.excludeTerms) {
      if (emailContent.contains(excludeTerm.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  /// Checks if a field matches a search term (supports wildcards)
  static bool _matchesField(String field, String searchTerm) {
    final fieldLower = field.toLowerCase();
    final termLower = searchTerm.toLowerCase();

    if (termLower.contains('*')) {
      // Convert wildcard to regex
      final regexPattern = termLower
          .replaceAll('*', '.*')
          .replaceAll('?', '.');
      return RegExp(regexPattern).hasMatch(fieldLower);
    }

    return fieldLower.contains(termLower);
  }

  /// Parses date in various formats
  static DateTime? _parseDate(String dateStr) {
    try {
      // Try YYYY-MM-DD format
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        return DateTime.parse(dateStr);
      }

      // Try relative dates
      if (dateStr == 'today') {
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day);
      } else if (dateStr == 'yesterday') {
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day - 1);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parses duration strings like "7d", "1w", "1m", "1y"
  static Duration? _parseDuration(String durationStr) {
    final match = RegExp(r'^(\d+)([dwmy])$').firstMatch(durationStr);
    if (match == null) return null;

    final value = int.tryParse(match.group(1)!) ?? 0;
    final unit = match.group(2)!;

    switch (unit) {
      case 'd':
        return Duration(days: value);
      case 'w':
        return Duration(days: value * 7);
      case 'm':
        return Duration(days: value * 30);
      case 'y':
        return Duration(days: value * 365);
      default:
        return null;
    }
  }

  /// Parses size strings like "10MB", "5KB"
  static int? _parseSize(String sizeStr) {
    final match = RegExp(r'^(\d+)(KB|MB|GB)?$', caseSensitive: false).firstMatch(sizeStr);
    if (match == null) return null;

    final value = int.tryParse(match.group(1)!) ?? 0;
    final unit = match.group(2)?.toUpperCase() ?? 'B';

    switch (unit) {
      case 'KB':
        return value * 1024;
      case 'MB':
        return value * 1024 * 1024;
      case 'GB':
        return value * 1024 * 1024 * 1024;
      default:
        return value;
    }
  }

  /// Estimates email size including attachments
  static int _estimateEmailSize(EmailMessage email) {
    int size = email.textBody.length;
    if (email.htmlBody != null) {
      size += email.htmlBody!.length;
    }
    if (email.attachments != null) {
      size += email.attachments!.fold(0, (sum, attachment) => sum + attachment.size);
    }
    return size;
  }

  /// Gets search suggestions based on recent searches and email content
  static List<String> getSearchSuggestions(
    List<EmailMessage> emails,
    String partialQuery,
  ) {
    final suggestions = <String>{};

    // Add operator suggestions
    if (partialQuery.isEmpty || 'from:'.startsWith(partialQuery)) {
      suggestions.add('from:');
    }
    if (partialQuery.isEmpty || 'to:'.startsWith(partialQuery)) {
      suggestions.add('to:');
    }
    if (partialQuery.isEmpty || 'subject:'.startsWith(partialQuery)) {
      suggestions.add('subject:');
    }
    if (partialQuery.isEmpty || 'has:attachment'.startsWith(partialQuery)) {
      suggestions.add('has:attachment');
    }
    if (partialQuery.isEmpty || 'is:unread'.startsWith(partialQuery)) {
      suggestions.add('is:unread');
    }

    // Add frequent senders
    final senders = emails.map((e) => e.from).toSet();
    for (final sender in senders.take(5)) {
      final email = _extractEmail(sender);
      if (email.contains(partialQuery.toLowerCase())) {
        suggestions.add('from:$email');
      }
    }

    return suggestions.toList()..sort();
  }

  /// Extracts email address from "Name <email>" format
  static String _extractEmail(String fromField) {
    final match = RegExp(r'<(.+?)>').firstMatch(fromField);
    return match?.group(1) ?? fromField;
  }
}

/// Represents a parsed search query with various criteria
class SearchQuery {
  String? from;
  String? to;
  String? subject;
  EmailFolder? folder;
  bool? hasAttachment;
  bool? isRead;
  bool? isUnread;
  bool? isImportant;
  bool? isStarred;
  DateTime? beforeDate;
  DateTime? afterDate;
  Duration? olderThan;
  Duration? newerThan;
  int? sizeGreaterThan;
  int? sizeLessThan;

  final List<String> terms = [];
  final List<String> exactPhrases = [];
  final List<String> excludeTerms = [];

  @override
  String toString() {
    final parts = <String>[];

    if (from != null) parts.add('from:$from');
    if (to != null) parts.add('to:$to');
    if (subject != null) parts.add('subject:$subject');
    if (folder != null) parts.add('in:${folder.toString().split('.').last}');
    if (hasAttachment == true) parts.add('has:attachment');
    if (isUnread == true) parts.add('is:unread');
    if (isRead == true) parts.add('is:read');
    if (isImportant == true) parts.add('is:important');

    parts.addAll(terms);
    parts.addAll(exactPhrases.map((p) => '"$p"'));
    parts.addAll(excludeTerms.map((t) => '-$t'));

    return parts.join(' ');
  }
}