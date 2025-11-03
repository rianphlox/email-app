
import '../models/email_message.dart';

/// A service class for automatically categorizing emails.
///
/// This class uses a set of keywords and sender patterns to categorize emails
/// into one of the following categories: Promotions, Social, Updates, or Primary.
class EmailCategorizer {
  // --- Private Keyword and Sender Lists ---

  static const _promotionKeywords = [
    'sale', 'discount', 'offer', 'coupon', 'promo', 'promotion',
    'shopping', 'buy now', 'limited time', 'special offer', 'free shipping',
    'unsubscribe', 'newsletter', 'marketing', 'advertisement'
  ];

  static const _socialKeywords = [
    'facebook', 'twitter', 'instagram', 'linkedin', 'snapchat', 'tiktok',
    'youtube', 'notification', 'mentioned', 'tagged', 'liked', 'commented',
    'friend request', 'follow', 'message', 'chat'
  ];

  static const _updateKeywords = [
    'update', 'news', 'newsletter', 'blog', 'announcement',
    'release', 'security', 'policy', 'terms', 'notification', 'alert',
    'reminder', 'report', 'summary', 'digest'
  ];

  static const _promotionSenders = [
    'marketing', 'sales', 'promo', 'offers', 'deals', 'shop', 'store',
    'amazon', 'ebay', 'walmart', 'target', 'bestbuy', 'groupon',
    'noreply', 'no-reply', 'donotreply', 'newsletter'
  ];

  static const _socialSenders = [
    'facebook', 'twitter', 'instagram', 'linkedin', 'snapchat', 'tiktok',
    'youtube', 'whatsapp', 'telegram', 'discord', 'slack', 'teams',
    'zoom', 'meet', 'social', 'community'
  ];

  static const _updateSenders = [
    'news', 'update', 'notification', 'alerts', 'security', 'support',
    'admin', 'system', 'service', 'team', 'blog', 'digest', 'report',
    'github', 'gitlab', 'jira', 'confluence', 'medium', 'substack'
  ];

  // --- Public Methods ---

  /// Categorizes an email based on its sender, subject, and content.
  static EmailCategory categorizeEmail(EmailMessage email) {
    final sender = email.from.toLowerCase();
    final subject = email.subject.toLowerCase();
    final content = email.textBody.toLowerCase();

    if (_isPromotional(sender, subject, content)) {
      return EmailCategory.promotions;
    }

    if (_isSocial(sender, subject, content)) {
      return EmailCategory.social;
    }

    if (_isUpdate(sender, subject, content)) {
      return EmailCategory.updates;
    }

    // If no other category matches, default to Primary.
    return EmailCategory.primary;
  }

  /// Categorizes a list of emails in batch.
  static List<EmailMessage> categorizeEmails(List<EmailMessage> emails) {
    for (final email in emails) {
      email.category = categorizeEmail(email);
    }
    return emails;
  }

  // --- Private Helper Methods ---

  /// Checks if an email is promotional.
  static bool _isPromotional(String sender, String subject, String content) {
    for (final pattern in _promotionSenders) {
      if (sender.contains(pattern)) return true;
    }

    final promotionScore = _calculateKeywordScore(_promotionKeywords, '$subject $content');
    return promotionScore >= 2;
  }

  /// Checks if an email is social.
  static bool _isSocial(String sender, String subject, String content) {
    for (final pattern in _socialSenders) {
      if (sender.contains(pattern)) return true;
    }

    final socialScore = _calculateKeywordScore(_socialKeywords, '$subject $content');
    return socialScore >= 1;
  }

  /// Checks if an email is an update.
  static bool _isUpdate(String sender, String subject, String content) {
    for (final pattern in _updateSenders) {
      if (sender.contains(pattern)) return true;
    }

    final updateScore = _calculateKeywordScore(_updateKeywords, '$subject $content');
    if (subject.contains('digest') || subject.contains('weekly') || subject.contains('newsletter') || subject.contains('update')) {
      return true;
    }

    return updateScore >= 2;
  }

  /// Calculates a score based on the number of keywords found in a text.
  static int _calculateKeywordScore(List<String> keywords, String text) {
    int score = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        score++;
      }
    }
    return score;
  }

  /// Get category display name
  static String getCategoryDisplayName(EmailCategory category) {
    switch (category) {
      case EmailCategory.primary:
        return 'Primary';
      case EmailCategory.promotions:
        return 'Promotions';
      case EmailCategory.social:
        return 'Social';
      case EmailCategory.updates:
        return 'Updates';
    }
  }

  /// Get category icon
  static String getCategoryIcon(EmailCategory category) {
    switch (category) {
      case EmailCategory.primary:
        return '📧';
      case EmailCategory.promotions:
        return '🏷️';
      case EmailCategory.social:
        return '👥';
      case EmailCategory.updates:
        return '📄';
    }
  }

  /// Get unread count for a specific category
  static int getUnreadCount(List<EmailMessage> emails, EmailCategory category) {
    return emails
        .where((email) => email.category == category && !email.isRead)
        .length;
  }

  /// Filter emails by category
  static List<EmailMessage> getEmailsByCategory(
    List<EmailMessage> emails,
    EmailCategory category
  ) {
    return emails.where((email) => email.category == category).toList();
  }
}
