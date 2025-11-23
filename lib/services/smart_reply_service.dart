import 'package:flutter/foundation.dart';
import '../models/email_message.dart';

/// Smart Reply service that generates contextual response suggestions
class SmartReplyService {
  // Common response patterns based on email analysis
  static const Map<String, List<String>> _responsePatterns = {
    'meeting': [
      'I\'ll be there!',
      'What time works best?',
      'Can we reschedule?',
      'I\'ll check my calendar',
      'Send me the agenda',
    ],
    'question': [
      'Let me check and get back to you',
      'I\'ll look into this',
      'Thanks for asking',
      'I need more information',
      'I\'ll forward this to the team',
    ],
    'request': [
      'I\'ll take care of it',
      'No problem!',
      'I can help with this',
      'When do you need this by?',
      'I\'ll get started on this',
    ],
    'thanks': [
      'You\'re welcome!',
      'Happy to help!',
      'Anytime!',
      'Glad I could assist',
      'No problem at all',
    ],
    'urgent': [
      'On it now',
      'I\'ll handle this immediately',
      'Thanks for the heads up',
      'I\'ll make this a priority',
      'I\'ll expedite this',
    ],
    'follow_up': [
      'Thanks for following up',
      'I\'ll check on the status',
      'Let me get an update',
      'I\'ll circle back soon',
      'I\'ll have an answer shortly',
    ],
    'approval': [
      'Approved!',
      'Looks good to me',
      'I approve this request',
      'Go ahead with this',
      'I\'ll review and approve',
    ],
    'social': [
      'Sounds great!',
      'Count me in',
      'I\'d love to join',
      'Thanks for including me',
      'Looking forward to it',
    ],
    'default': [
      'Thanks for your email',
      'I\'ll get back to you soon',
      'Thanks for reaching out',
      'I\'ll review this',
      'I appreciate you letting me know',
    ],
  };

  /// Keywords that help identify email context and intent
  static const Map<String, List<String>> _contextKeywords = {
    'meeting': [
      'meeting', 'schedule', 'calendar', 'appointment', 'call', 'zoom',
      'conference', 'discuss', 'presentation', 'agenda', 'invite'
    ],
    'question': [
      'question', '?', 'how', 'what', 'when', 'where', 'why', 'which',
      'could you', 'can you', 'would you', 'do you know', 'clarify'
    ],
    'request': [
      'please', 'could you', 'can you', 'would you', 'need', 'require',
      'request', 'ask', 'help', 'assist', 'send', 'provide', 'share'
    ],
    'thanks': [
      'thank', 'thanks', 'grateful', 'appreciate', 'acknowledgment',
      'gratitude', 'kudos', 'well done', 'great job', 'excellent'
    ],
    'urgent': [
      'urgent', 'asap', 'immediately', 'priority', 'rush', 'critical',
      'important', 'deadline', 'time-sensitive', 'emergency', 'now'
    ],
    'follow_up': [
      'follow up', 'following up', 'checking in', 'update', 'status',
      'progress', 'any news', 'heard back', 'still waiting', 'reminder'
    ],
    'approval': [
      'approve', 'approval', 'sign off', 'authorize', 'confirm',
      'permission', 'green light', 'go ahead', 'okay', 'consent'
    ],
    'social': [
      'party', 'lunch', 'dinner', 'coffee', 'drinks', 'celebration',
      'birthday', 'event', 'gathering', 'social', 'fun', 'weekend'
    ],
  };

  /// Time-based response suggestions
  static const Map<String, List<String>> _timeBasedResponses = {
    'morning': [
      'Good morning!',
      'Thanks for the early update',
      'I\'ll review this today',
    ],
    'afternoon': [
      'Thanks for the update',
      'I\'ll look at this this afternoon',
      'I\'ll get back to you today',
    ],
    'evening': [
      'Thanks for sending this',
      'I\'ll review first thing tomorrow',
      'I\'ll handle this in the morning',
    ],
    'weekend': [
      'Thanks! I\'ll review on Monday',
      'I\'ll get to this next week',
      'Enjoy your weekend!',
    ],
  };

  /// Generate smart reply suggestions for an email
  static List<SmartReply> generateReplies(EmailMessage email) {
    try {
      final context = _analyzeEmailContext(email);
      final sentiment = _analyzeSentiment(email);
      final urgency = _analyzeUrgency(email);
      final timeContext = _getTimeContext();

      final replies = <SmartReply>[];

      // Add context-based replies
      if (context.isNotEmpty) {
        final contextReplies = _responsePatterns[context] ?? _responsePatterns['default']!;
        for (int i = 0; i < contextReplies.length && i < 3; i++) {
          replies.add(SmartReply(
            text: contextReplies[i],
            confidence: _calculateConfidence(context, sentiment, email),
            category: context,
            type: SmartReplyType.contextual,
          ));
        }
      }

      // Add time-based replies if appropriate
      if (timeContext.isNotEmpty) {
        final timeReplies = _timeBasedResponses[timeContext] ?? [];
        if (timeReplies.isNotEmpty && replies.length < 3) {
          replies.add(SmartReply(
            text: timeReplies.first,
            confidence: 0.7,
            category: 'time_based',
            type: SmartReplyType.timeBased,
          ));
        }
      }

      // Add urgency-based replies
      if (urgency == 'high' && replies.length < 3) {
        replies.add(SmartReply(
          text: 'I\'ll prioritize this',
          confidence: 0.8,
          category: 'urgent',
          type: SmartReplyType.urgencyBased,
        ));
      }

      // Add generic helpful replies if we don't have enough
      if (replies.length < 3) {
        final defaultReplies = _responsePatterns['default']!;
        for (final reply in defaultReplies) {
          if (replies.length >= 3) break;
          if (!replies.any((r) => r.text == reply)) {
            replies.add(SmartReply(
              text: reply,
              confidence: 0.6,
              category: 'default',
              type: SmartReplyType.generic,
            ));
          }
        }
      }

      // Sort by confidence and return top 3
      replies.sort((a, b) => b.confidence.compareTo(a.confidence));
      return replies.take(3).toList();
    } catch (e) {
      debugPrint('❌ SmartReplyService: Error generating replies: $e');
      return _getFallbackReplies();
    }
  }

  /// Analyze email content to determine context/intent
  static String _analyzeEmailContext(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();

    int maxMatches = 0;
    String bestContext = 'default';

    for (final entry in _contextKeywords.entries) {
      int matches = 0;
      for (final keyword in entry.value) {
        if (content.contains(keyword)) {
          matches++;
        }
      }

      if (matches > maxMatches) {
        maxMatches = matches;
        bestContext = entry.key;
      }
    }

    return maxMatches > 0 ? bestContext : 'default';
  }

  /// Analyze sentiment of the email
  static String _analyzeSentiment(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();

    final positiveWords = ['thank', 'great', 'excellent', 'good', 'wonderful', 'amazing', 'perfect'];
    final negativeWords = ['problem', 'issue', 'error', 'wrong', 'failed', 'urgent', 'critical'];

    int positiveCount = 0;
    int negativeCount = 0;

    for (final word in positiveWords) {
      if (content.contains(word)) positiveCount++;
    }

    for (final word in negativeWords) {
      if (content.contains(word)) negativeCount++;
    }

    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }

  /// Analyze urgency level of the email
  static String _analyzeUrgency(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();
    final urgentKeywords = _contextKeywords['urgent'] ?? [];

    int urgencyScore = 0;
    for (final keyword in urgentKeywords) {
      if (content.contains(keyword)) urgencyScore++;
    }

    if (urgencyScore >= 2) return 'high';
    if (urgencyScore == 1) return 'medium';
    return 'low';
  }

  /// Get time-based context for responses
  static String _getTimeContext() {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;

    // Weekend check
    if (weekday >= 6) return 'weekend';

    // Time of day
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 || hour < 6) return 'evening';

    return '';
  }

  /// Calculate confidence score for a reply suggestion
  static double _calculateConfidence(String context, String sentiment, EmailMessage email) {
    double confidence = 0.7; // Base confidence

    // Boost confidence for clear context matches
    if (context != 'default') {
      confidence += 0.2;
    }

    // Boost confidence for important emails
    if (email.isImportant) {
      confidence += 0.1;
    }

    // Adjust for sender relationship (could be enhanced with contact analysis)
    if (email.from.contains(email.to.isNotEmpty ? email.to.first.split('@').first : '')) {
      confidence += 0.1; // Internal email
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Get fallback replies when analysis fails
  static List<SmartReply> _getFallbackReplies() {
    return [
      SmartReply(
        text: 'Thanks for your email',
        confidence: 0.6,
        category: 'default',
        type: SmartReplyType.generic,
      ),
      SmartReply(
        text: 'I\'ll get back to you soon',
        confidence: 0.6,
        category: 'default',
        type: SmartReplyType.generic,
      ),
      SmartReply(
        text: 'I appreciate you reaching out',
        confidence: 0.6,
        category: 'default',
        type: SmartReplyType.generic,
      ),
    ];
  }

  /// Generate contextual reply based on specific trigger words
  static SmartReply? generateContextualReply(EmailMessage email, String triggerPhrase) {
    final triggerLower = triggerPhrase.toLowerCase();

    final contextualReplies = {
      'meeting': 'I\'ll check my calendar and get back to you',
      'deadline': 'When do you need this completed?',
      'budget': 'I\'ll review the budget requirements',
      'approval': 'I\'ll review and provide approval',
      'feedback': 'I\'ll provide feedback by end of day',
      'schedule': 'Let me check my availability',
      'urgent': 'I\'ll prioritize this immediately',
      'question': 'Let me research this and get back to you',
    };

    for (final entry in contextualReplies.entries) {
      if (triggerLower.contains(entry.key)) {
        return SmartReply(
          text: entry.value,
          confidence: 0.85,
          category: entry.key,
          type: SmartReplyType.contextual,
        );
      }
    }

    return null;
  }

  /// Get smart replies for quick actions
  static List<SmartReply> getQuickActionReplies() {
    return [
      SmartReply(
        text: 'Got it, thanks!',
        confidence: 0.9,
        category: 'acknowledgment',
        type: SmartReplyType.quickAction,
      ),
      SmartReply(
        text: 'Will do',
        confidence: 0.9,
        category: 'confirmation',
        type: SmartReplyType.quickAction,
      ),
      SmartReply(
        text: 'Thanks for the update',
        confidence: 0.9,
        category: 'appreciation',
        type: SmartReplyType.quickAction,
      ),
    ];
  }
}

/// Represents a smart reply suggestion
class SmartReply {
  final String text;
  final double confidence;
  final String category;
  final SmartReplyType type;

  const SmartReply({
    required this.text,
    required this.confidence,
    required this.category,
    required this.type,
  });

  @override
  String toString() => 'SmartReply(text: "$text", confidence: $confidence, category: $category)';
}

/// Types of smart replies
enum SmartReplyType {
  contextual,     // Based on email content analysis
  timeBased,      // Based on time of day/week
  urgencyBased,   // Based on urgency analysis
  quickAction,    // Quick one-tap responses
  generic,        // Fallback responses
}

/// Smart reply analytics for improving suggestions
class SmartReplyAnalytics {
  static final Map<String, int> _usageStats = {};
  static final Map<String, double> _effectivenessScores = {};

  /// Track when a smart reply is used
  static void trackUsage(SmartReply reply) {
    final key = '${reply.category}:${reply.text}';
    _usageStats[key] = (_usageStats[key] ?? 0) + 1;

    debugPrint('📊 SmartReply: Tracked usage for "${reply.text}" (${_usageStats[key]} times)');
  }

  /// Track effectiveness based on whether user modifies the suggestion
  static void trackEffectiveness(SmartReply reply, bool wasModified) {
    final key = '${reply.category}:${reply.text}';
    final currentScore = _effectivenessScores[key] ?? 0.5;

    // Simple learning: increase score if used as-is, decrease if modified
    final newScore = wasModified
        ? (currentScore * 0.9).clamp(0.0, 1.0)
        : (currentScore * 1.1).clamp(0.0, 1.0);

    _effectivenessScores[key] = newScore;

    debugPrint('📈 SmartReply: Updated effectiveness for "${reply.text}": $newScore');
  }

  /// Get usage statistics
  static Map<String, dynamic> getAnalytics() {
    final totalUsage = _usageStats.values.fold(0, (sum, count) => sum + count);
    final avgEffectiveness = _effectivenessScores.values.isNotEmpty
        ? _effectivenessScores.values.reduce((a, b) => a + b) / _effectivenessScores.length
        : 0.0;

    return {
      'totalUsage': totalUsage,
      'avgEffectiveness': avgEffectiveness,
      'topReplies': _getTopReplies(),
      'categoryBreakdown': _getCategoryBreakdown(),
    };
  }

  static List<Map<String, dynamic>> _getTopReplies() {
    final sorted = _usageStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((entry) => {
      'reply': entry.key.split(':').last,
      'category': entry.key.split(':').first,
      'usage': entry.value,
      'effectiveness': _effectivenessScores[entry.key] ?? 0.5,
    }).toList();
  }

  static Map<String, int> _getCategoryBreakdown() {
    final breakdown = <String, int>{};

    for (final entry in _usageStats.entries) {
      final category = entry.key.split(':').first;
      breakdown[category] = (breakdown[category] ?? 0) + entry.value;
    }

    return breakdown;
  }
}