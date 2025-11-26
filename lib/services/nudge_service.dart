import 'package:flutter/foundation.dart';
import '../models/email_message.dart';
import '../models/email_account.dart';

/// Types of nudges that can be generated
enum NudgeType {
  followUpReminder,     // Remind to follow up on sent emails
  replyReminder,        // Remind to reply to important incoming emails
  deadlineReminder,     // Remind about emails with deadlines
  importantUnread,      // Nudge about unread important emails
  meetingFollowUp,      // Follow up after meetings
  weeklyDigest,         // Weekly summary of pending items
}

/// Priority levels for nudges
enum NudgePriority {
  low,
  medium,
  high,
  critical,
}

/// Service for generating nudges about important emails that need attention
class NudgeService {

  /// Keywords that indicate importance
  static const List<String> _importanceKeywords = [
    'urgent', 'asap', 'important', 'critical', 'priority', 'deadline',
    'meeting', 'conference', 'call', 'interview', 'presentation',
    'contract', 'agreement', 'invoice', 'payment', 'budget',
    'review', 'approval', 'sign', 'authorize', 'confirm',
    'project', 'milestone', 'deliverable', 'launch', 'release',
  ];

  /// Keywords that indicate action is needed
  static const List<String> _actionKeywords = [
    'please', 'could you', 'can you', 'would you', 'need you to',
    'request', 'require', 'action needed', 'follow up', 'next steps',
    'waiting for', 'pending', 'response needed', 'feedback',
    'decision', 'choose', 'select', 'pick', 'decide',
  ];


  /// Generate nudges for a list of emails
  static List<EmailNudge> generateNudges(
    List<EmailMessage> emails,
    EmailAccount account,
  ) {
    final nudges = <EmailNudge>[];

    try {
      // Group emails by type for different nudge strategies
      final sentEmails = emails.where((e) => e.folder == EmailFolder.sent).toList();
      final inboxEmails = emails.where((e) => e.folder == EmailFolder.inbox).toList();

      // Generate follow-up reminders for sent emails
      nudges.addAll(_generateFollowUpNudges(sentEmails, account));

      // Generate reply reminders for incoming emails
      nudges.addAll(_generateReplyNudges(inboxEmails, account));

      // Generate deadline reminders
      nudges.addAll(_generateDeadlineNudges(emails, account));

      // Generate important unread nudges
      nudges.addAll(_generateImportantUnreadNudges(inboxEmails, account));

      // Generate meeting follow-up nudges
      nudges.addAll(_generateMeetingFollowUpNudges(emails, account));

      // Sort by priority and date
      nudges.sort((a, b) {
        final priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) return priorityCompare;
        return b.suggestedAction.compareTo(a.suggestedAction);
      });

      debugPrint('🔔 NudgeService: Generated ${nudges.length} nudges for ${account.email}');
      return nudges.take(5).toList(); // Limit to 5 most important nudges
    } catch (e) {
      debugPrint('❌ NudgeService: Error generating nudges: $e');
      return [];
    }
  }

  /// Generate follow-up nudges for sent emails without responses
  static List<EmailNudge> _generateFollowUpNudges(
    List<EmailMessage> sentEmails,
    EmailAccount account,
  ) {
    final nudges = <EmailNudge>[];
    final now = DateTime.now();

    for (final email in sentEmails) {
      final daysSinceSent = now.difference(email.date).inDays;

      // Skip if too recent or too old
      if (daysSinceSent < 1 || daysSinceSent > 14) continue;

      // Check if this email might need follow-up
      final needsFollowUp = _emailNeedsFollowUp(email);
      if (!needsFollowUp) continue;

      NudgePriority priority = NudgePriority.low;
      String suggestion = 'Consider following up on this email';

      // Determine priority based on content and age
      if (_containsImportantKeywords(email)) {
        priority = daysSinceSent > 7 ? NudgePriority.high : NudgePriority.medium;
        suggestion = daysSinceSent > 7
            ? 'This important email hasn\'t been answered in over a week'
            : 'Follow up on this important email';
      } else if (daysSinceSent > 5) {
        priority = NudgePriority.medium;
        suggestion = 'No response received for $daysSinceSent days';
      }

      nudges.add(EmailNudge(
        id: 'followup_${email.messageId}',
        email: email,
        type: NudgeType.followUpReminder,
        priority: priority,
        title: 'Follow up on sent email',
        message: suggestion,
        suggestedAction: 'Send a follow-up email',
        createdAt: now,
        actionData: {
          'originalSubject': email.subject,
          'recipient': email.to.isNotEmpty ? email.to.first : '',
          'daysSinceSent': daysSinceSent,
        },
      ));
    }

    return nudges;
  }

  /// Generate reply nudges for important incoming emails
  static List<EmailNudge> _generateReplyNudges(
    List<EmailMessage> inboxEmails,
    EmailAccount account,
  ) {
    final nudges = <EmailNudge>[];
    final now = DateTime.now();

    for (final email in inboxEmails) {
      // Skip if already read or too old
      if (email.isRead || now.difference(email.date).inDays > 7) continue;

      // Check if email needs a reply
      final needsReply = _emailNeedsReply(email);
      if (!needsReply) continue;

      final daysSinceReceived = now.difference(email.date).inDays;
      final hoursSinceReceived = now.difference(email.date).inHours;

      NudgePriority priority = NudgePriority.low;
      String title = 'Reply to email';
      String message = 'This email may need a response';

      // Determine priority based on content and age
      if (_containsUrgentKeywords(email)) {
        priority = NudgePriority.high;
        title = 'Urgent email needs reply';
        message = 'This urgent email requires immediate attention';
      } else if (_containsImportantKeywords(email)) {
        priority = daysSinceReceived > 2 ? NudgePriority.high : NudgePriority.medium;
        message = daysSinceReceived > 2
            ? 'Important email pending for $daysSinceReceived days'
            : 'Important email may need a response';
      } else if (daysSinceReceived > 3) {
        priority = NudgePriority.medium;
        message = 'Email pending for $daysSinceReceived days';
      } else if (hoursSinceReceived > 24) {
        priority = NudgePriority.low;
        message = 'Email received yesterday';
      }

      nudges.add(EmailNudge(
        id: 'reply_${email.messageId}',
        email: email,
        type: NudgeType.replyReminder,
        priority: priority,
        title: title,
        message: message,
        suggestedAction: 'Reply to email',
        createdAt: now,
        actionData: {
          'sender': email.from,
          'daysSinceReceived': daysSinceReceived,
          'hasActionWords': _containsActionKeywords(email),
        },
      ));
    }

    return nudges;
  }

  /// Generate deadline reminders
  static List<EmailNudge> _generateDeadlineNudges(
    List<EmailMessage> emails,
    EmailAccount account,
  ) {
    final nudges = <EmailNudge>[];
    final now = DateTime.now();

    for (final email in emails) {
      // Skip old emails
      if (now.difference(email.date).inDays > 30) continue;

      final deadline = _extractDeadlineFromEmail(email);
      if (deadline == null) continue;

      final daysUntilDeadline = deadline.difference(now).inDays;

      // Skip if deadline has passed by more than 3 days
      if (daysUntilDeadline < -3) continue;

      NudgePriority priority;
      String title;
      String message;

      if (daysUntilDeadline < 0) {
        priority = NudgePriority.critical;
        title = 'Deadline passed';
        message = 'Deadline was ${daysUntilDeadline.abs()} days ago';
      } else if (daysUntilDeadline == 0) {
        priority = NudgePriority.critical;
        title = 'Deadline today';
        message = 'This deadline is today!';
      } else if (daysUntilDeadline == 1) {
        priority = NudgePriority.high;
        title = 'Deadline tomorrow';
        message = 'Deadline is tomorrow';
      } else if (daysUntilDeadline <= 3) {
        priority = NudgePriority.high;
        title = 'Deadline approaching';
        message = 'Deadline in $daysUntilDeadline days';
      } else if (daysUntilDeadline <= 7) {
        priority = NudgePriority.medium;
        title = 'Upcoming deadline';
        message = 'Deadline in $daysUntilDeadline days';
      } else {
        continue; // Too far away
      }

      nudges.add(EmailNudge(
        id: 'deadline_${email.messageId}',
        email: email,
        type: NudgeType.deadlineReminder,
        priority: priority,
        title: title,
        message: message,
        suggestedAction: daysUntilDeadline < 0 ? 'Follow up on missed deadline' : 'Work on this task',
        createdAt: now,
        actionData: {
          'deadline': deadline.toIso8601String(),
          'daysUntilDeadline': daysUntilDeadline,
        },
      ));
    }

    return nudges;
  }

  /// Generate nudges for important unread emails
  static List<EmailNudge> _generateImportantUnreadNudges(
    List<EmailMessage> inboxEmails,
    EmailAccount account,
  ) {
    final nudges = <EmailNudge>[];
    final now = DateTime.now();

    final importantUnread = inboxEmails
        .where((e) => !e.isRead && (e.isImportant || _containsImportantKeywords(e)))
        .toList();

    for (final email in importantUnread) {
      final daysSinceReceived = now.difference(email.date).inDays;

      // Skip if too recent
      if (daysSinceReceived < 1) continue;

      final priority = daysSinceReceived > 3 ? NudgePriority.high : NudgePriority.medium;

      nudges.add(EmailNudge(
        id: 'unread_${email.messageId}',
        email: email,
        type: NudgeType.importantUnread,
        priority: priority,
        title: 'Unread important email',
        message: 'You have an unread important email from ${_extractSenderName(email.from)}',
        suggestedAction: 'Read email',
        createdAt: now,
        actionData: {
          'sender': email.from,
          'daysSinceReceived': daysSinceReceived,
        },
      ));
    }

    return nudges;
  }

  /// Generate meeting follow-up nudges
  static List<EmailNudge> _generateMeetingFollowUpNudges(
    List<EmailMessage> emails,
    EmailAccount account,
  ) {
    final nudges = <EmailNudge>[];
    final now = DateTime.now();

    for (final email in emails) {
      // Look for meeting-related emails
      if (!_isMeetingRelated(email)) continue;

      // Check if this is a past meeting that might need follow-up
      final meetingDate = _extractMeetingDateFromEmail(email);
      if (meetingDate == null || meetingDate.isAfter(now)) continue;

      final daysSinceMeeting = now.difference(meetingDate).inDays;

      // Follow up 1-3 days after meeting
      if (daysSinceMeeting < 1 || daysSinceMeeting > 7) continue;

      nudges.add(EmailNudge(
        id: 'meeting_followup_${email.messageId}',
        email: email,
        type: NudgeType.meetingFollowUp,
        priority: NudgePriority.medium,
        title: 'Meeting follow-up',
        message: 'Consider following up on the meeting from $daysSinceMeeting days ago',
        suggestedAction: 'Send meeting recap or action items',
        createdAt: now,
        actionData: {
          'meetingDate': meetingDate.toIso8601String(),
          'daysSinceMeeting': daysSinceMeeting,
        },
      ));
    }

    return nudges;
  }

  /// Helper methods for email analysis

  static bool _emailNeedsFollowUp(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();

    // Look for question words or requests
    final questionWords = ['?', 'what', 'when', 'where', 'how', 'why', 'which', 'could you', 'can you'];
    final hasQuestions = questionWords.any((word) => content.contains(word));

    // Look for action requests
    final hasActionRequests = _containsActionKeywords(email);

    // Look for important keywords
    final isImportant = _containsImportantKeywords(email);

    return hasQuestions || hasActionRequests || isImportant;
  }

  static bool _emailNeedsReply(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();

    // Skip automated emails
    final automatedSenders = ['noreply', 'no-reply', 'donotreply', 'notifications', 'alerts'];
    if (automatedSenders.any((sender) => email.from.toLowerCase().contains(sender))) {
      return false;
    }

    // Look for questions
    final hasQuestions = content.contains('?') ||
        ['what', 'when', 'where', 'how', 'why', 'which'].any((word) => content.contains(word));

    // Look for action requests
    final hasActionRequests = _containsActionKeywords(email);

    // Look for meeting invites
    final isMeetingInvite = _isMeetingRelated(email);

    return hasQuestions || hasActionRequests || isMeetingInvite;
  }

  static bool _containsImportantKeywords(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();
    return _importanceKeywords.any((keyword) => content.contains(keyword));
  }

  static bool _containsActionKeywords(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();
    return _actionKeywords.any((keyword) => content.contains(keyword));
  }

  static bool _containsUrgentKeywords(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();
    final urgentWords = ['urgent', 'asap', 'immediately', 'critical', 'emergency', 'rush'];
    return urgentWords.any((word) => content.contains(word));
  }

  static DateTime? _extractDeadlineFromEmail(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();

    // Simple deadline extraction - could be enhanced with more sophisticated parsing
    final now = DateTime.now();

    if (content.contains('today')) {
      return DateTime(now.year, now.month, now.day, 17); // 5 PM today
    }
    if (content.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1, 17);
    }
    if (content.contains('this week') || content.contains('end of week') || content.contains('friday')) {
      // Find next Friday
      final daysUntilFriday = (5 - now.weekday) % 7;
      return DateTime(now.year, now.month, now.day + daysUntilFriday, 17);
    }
    if (content.contains('next week') || content.contains('monday')) {
      // Find next Monday
      final daysUntilMonday = (8 - now.weekday) % 7;
      return DateTime(now.year, now.month, now.day + daysUntilMonday, 17);
    }

    // Look for specific date patterns (could be enhanced)
    final deadlineMatch = RegExp(r'\\b(deadline|due)\\s+(\\w+\\s+\\d{1,2})\\b').firstMatch(content);
    if (deadlineMatch != null) {
      // Could parse specific dates here
      return DateTime(now.year, now.month, now.day + 7); // Default to one week
    }

    return null;
  }

  static bool _isMeetingRelated(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();
    final meetingWords = ['meeting', 'call', 'conference', 'zoom', 'teams', 'webinar', 'discussion', 'sync'];
    return meetingWords.any((word) => content.contains(word));
  }

  static DateTime? _extractMeetingDateFromEmail(EmailMessage email) {
    // For simplicity, assume meeting was on the email date
    // In a real implementation, this could parse calendar invites or meeting times
    return email.date;
  }

  static String _extractSenderName(String fromField) {
    if (fromField.isEmpty) return 'Unknown';

    // Extract name from "Name <email>" or just use the email
    final match = RegExp(r'^(.*?)\\s*<(.+?)>$').firstMatch(fromField.trim());
    if (match != null) {
      final name = match.group(1)?.trim().replaceAll('"', '') ?? '';
      if (name.isNotEmpty) {
        return name;
      }
      return match.group(2)?.split('@').first ?? 'Unknown';
    }

    // Just email, extract the part before @
    return fromField.split('@').first;
  }
}

/// Represents a nudge about an important email
class EmailNudge {
  final String id;
  final EmailMessage email;
  final NudgeType type;
  final NudgePriority priority;
  final String title;
  final String message;
  final String suggestedAction;
  final DateTime createdAt;
  final Map<String, dynamic> actionData;

  const EmailNudge({
    required this.id,
    required this.email,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.suggestedAction,
    required this.createdAt,
    this.actionData = const {},
  });

  @override
  String toString() => 'EmailNudge(title: $title, priority: $priority, type: $type)';
}