import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/email_message.dart';
import '../models/email_account.dart';

/// Notification categories for smart filtering
enum NotificationCategory {
  urgent,           // Critical emails that need immediate attention
  important,        // Important emails that should be seen soon
  meeting,          // Meeting-related notifications
  deadline,         // Deadline reminders
  followUp,         // Follow-up reminders
  digest,           // Bundled notifications
  social,           // Social/personal emails
  promotional,      // Marketing/promotional emails
}

/// Notification delivery timing
enum DeliveryTiming {
  immediate,        // Send right away
  bundled,          // Bundle with others
  scheduled,        // Send at optimal time
  quiet,            // During quiet hours
}

/// Smart notification service that provides intelligent, contextual notifications
class SmartNotificationService {
  static const String _channelId = 'qmail_smart_notifications';
  static const String _channelName = 'QMail Smart Notifications';
  static const String _channelDescription = 'Intelligent email notifications with context-aware actions';

  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static bool _isInitialized = false;

  /// Smart notification settings
  static final Map<NotificationCategory, Map<String, dynamic>> _categorySettings = {
    NotificationCategory.urgent: {
      'priority': 'max',
      'sound': true,
      'vibration': true,
      'led': true,
      'timing': DeliveryTiming.immediate,
      'bundle': false,
    },
    NotificationCategory.important: {
      'priority': 'high',
      'sound': true,
      'vibration': true,
      'led': false,
      'timing': DeliveryTiming.immediate,
      'bundle': false,
    },
    NotificationCategory.meeting: {
      'priority': 'high',
      'sound': true,
      'vibration': true,
      'led': true,
      'timing': DeliveryTiming.immediate,
      'bundle': false,
    },
    NotificationCategory.deadline: {
      'priority': 'high',
      'sound': true,
      'vibration': false,
      'led': true,
      'timing': DeliveryTiming.scheduled,
      'bundle': false,
    },
    NotificationCategory.followUp: {
      'priority': 'default',
      'sound': false,
      'vibration': false,
      'led': true,
      'timing': DeliveryTiming.bundled,
      'bundle': true,
    },
    NotificationCategory.digest: {
      'priority': 'low',
      'sound': false,
      'vibration': false,
      'led': false,
      'timing': DeliveryTiming.scheduled,
      'bundle': true,
    },
    NotificationCategory.social: {
      'priority': 'default',
      'sound': true,
      'vibration': false,
      'led': false,
      'timing': DeliveryTiming.bundled,
      'bundle': true,
    },
    NotificationCategory.promotional: {
      'priority': 'min',
      'sound': false,
      'vibration': false,
      'led': false,
      'timing': DeliveryTiming.bundled,
      'bundle': true,
    },
  };

  /// Keywords for categorizing emails
  static final Map<NotificationCategory, List<String>> _categoryKeywords = {
    NotificationCategory.urgent: [
      'urgent', 'asap', 'immediately', 'critical', 'emergency', 'rush', 'crisis',
      'deadline today', 'overdue', 'time sensitive', 'action required now'
    ],
    NotificationCategory.important: [
      'important', 'priority', 'significant', 'crucial', 'essential', 'key',
      'decision needed', 'approval required', 'review needed', 'feedback needed'
    ],
    NotificationCategory.meeting: [
      'meeting', 'call', 'conference', 'zoom', 'teams', 'webinar', 'appointment',
      'invite', 'calendar', 'schedule', 'sync', 'standup', 'interview'
    ],
    NotificationCategory.deadline: [
      'deadline', 'due', 'expires', 'ends', 'closing', 'final date', 'cutoff',
      'submit by', 'deliver by', 'complete by', 'finish by'
    ],
    NotificationCategory.followUp: [
      'follow up', 'following up', 'checking in', 'update', 'status',
      'progress', 'reminder', 'ping', 'touching base'
    ],
  };

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint('📱 SmartNotificationService: Initialized');
  }

  /// Create notification channels for different categories
  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Main smart notifications channel
      const mainChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF2196F3),
      );

      // Urgent notifications channel
      const urgentChannel = AndroidNotificationChannel(
        'urgent_notifications',
        'Urgent Emails',
        description: 'Critical emails requiring immediate attention',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF0000),
      );

      // Bundled notifications channel
      const bundledChannel = AndroidNotificationChannel(
        'bundled_notifications',
        'Email Summary',
        description: 'Bundled email notifications',
        importance: Importance.defaultImportance,
        enableVibration: false,
        enableLights: true,
        ledColor: Color(0xFF2196F3),
      );

      await androidPlugin.createNotificationChannel(mainChannel);
      await androidPlugin.createNotificationChannel(urgentChannel);
      await androidPlugin.createNotificationChannel(bundledChannel);
    }
  }

  /// Process new emails and send smart notifications
  static Future<void> processNewEmails(
    List<EmailMessage> newEmails,
    EmailAccount account,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint('🔔 Processing ${newEmails.length} new emails for notifications');

      final notifications = <SmartNotification>[];

      for (final email in newEmails) {
        final category = _categorizeEmail(email);
        final notification = await _createSmartNotification(email, category, account);

        if (notification != null) {
          notifications.add(notification);
        }
      }

      // Group notifications by delivery timing
      final immediateNotifications = notifications
          .where((n) => _categorySettings[n.category]!['timing'] == DeliveryTiming.immediate)
          .toList();

      final bundledNotifications = notifications
          .where((n) => _categorySettings[n.category]!['timing'] == DeliveryTiming.bundled)
          .toList();

      // Send immediate notifications
      for (final notification in immediateNotifications) {
        await _sendNotification(notification);
      }

      // Handle bundled notifications
      if (bundledNotifications.isNotEmpty) {
        await _handleBundledNotifications(bundledNotifications, account);
      }

    } catch (e) {
      debugPrint('❌ SmartNotificationService: Error processing emails: $e');
    }
  }

  /// Categorize an email for notification purposes
  static NotificationCategory _categorizeEmail(EmailMessage email) {
    final content = '${email.subject} ${email.textBody}'.toLowerCase();

    // Check for urgent keywords first
    if (_containsKeywords(content, NotificationCategory.urgent)) {
      return NotificationCategory.urgent;
    }

    // Check for meeting-related content
    if (_containsKeywords(content, NotificationCategory.meeting)) {
      return NotificationCategory.meeting;
    }

    // Check for deadline content
    if (_containsKeywords(content, NotificationCategory.deadline)) {
      return NotificationCategory.deadline;
    }

    // Check for important keywords
    if (_containsKeywords(content, NotificationCategory.important) || email.isImportant) {
      return NotificationCategory.important;
    }

    // Check for follow-up content
    if (_containsKeywords(content, NotificationCategory.followUp)) {
      return NotificationCategory.followUp;
    }

    // Check sender patterns for social vs promotional
    if (_isSocialEmail(email)) {
      return NotificationCategory.social;
    }

    if (_isPromotionalEmail(email)) {
      return NotificationCategory.promotional;
    }

    // Default to important for personal emails
    return NotificationCategory.important;
  }

  /// Create a smart notification for an email
  static Future<SmartNotification?> _createSmartNotification(
    EmailMessage email,
    NotificationCategory category,
    EmailAccount account,
  ) async {
    try {
      final senderName = _extractSenderName(email.from);
      final preview = _generatePreview(email);

      // Skip promotional emails during work hours or if too many
      if (category == NotificationCategory.promotional && await _shouldSkipPromo()) {
        return null;
      }

      return SmartNotification(
        id: email.messageId.hashCode,
        emailId: email.messageId,
        category: category,
        title: _generateTitle(email, category, senderName),
        body: _generateBody(email, category, preview),
        senderName: senderName,
        accountId: account.id,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ SmartNotificationService: Error creating notification: $e');
      return null;
    }
  }

  /// Send a notification to the system
  static Future<void> _sendNotification(SmartNotification notification) async {
    try {
      final categorySettings = _categorySettings[notification.category]!;

      // Determine channel based on category
      String channelId = _channelId;
      if (notification.category == NotificationCategory.urgent) {
        channelId = 'urgent_notifications';
      } else if (categorySettings['bundle'] == true) {
        channelId = 'bundled_notifications';
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: _getImportance(categorySettings['priority']),
        priority: _getPriority(categorySettings['priority']),
        enableVibration: categorySettings['vibration'] ?? false,
        enableLights: categorySettings['led'] ?? false,
        ledColor: _getCategoryColor(notification.category),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          notification.body,
          contentTitle: notification.title,
          summaryText: notification.senderName,
        ),
        category: AndroidNotificationCategory.email,
        visibility: NotificationVisibility.private,
        ticker: '${notification.senderName}: ${notification.title}',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'email_category',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin!.show(
        notification.id,
        notification.title,
        notification.body,
        details,
        payload: notification.emailId,
      );

      debugPrint('📱 Sent notification: ${notification.title}');
    } catch (e) {
      debugPrint('❌ SmartNotificationService: Error sending notification: $e');
    }
  }

  /// Handle bundled notifications
  static Future<void> _handleBundledNotifications(
    List<SmartNotification> notifications,
    EmailAccount account,
  ) async {
    if (notifications.isEmpty) return;

    try {
      // Group by category
      final grouped = <NotificationCategory, List<SmartNotification>>{};
      for (final notification in notifications) {
        grouped.putIfAbsent(notification.category, () => []).add(notification);
      }

      // Create bundle notifications
      for (final entry in grouped.entries) {
        await _createBundleNotification(entry.value, entry.key, account);
      }
    } catch (e) {
      debugPrint('❌ SmartNotificationService: Error handling bundled notifications: $e');
    }
  }

  /// Create a bundled notification for multiple emails
  static Future<void> _createBundleNotification(
    List<SmartNotification> notifications,
    NotificationCategory category,
    EmailAccount account,
  ) async {
    if (notifications.isEmpty) return;

    final count = notifications.length;
    final title = _getBundleTitle(category, count);
    final body = _getBundleBody(notifications, category);

    final bundleId = 'bundle_${category.toString()}_${DateTime.now().millisecondsSinceEpoch}';

    final androidDetails = AndroidNotificationDetails(
      'bundled_notifications',
      'Email Summary',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: false,
      enableLights: true,
      ledColor: _getCategoryColor(category),
      styleInformation: InboxStyleInformation(
        notifications.map((n) => '${n.senderName}: ${n.title}').toList(),
        contentTitle: title,
        summaryText: '${account.name} • $count new emails',
      ),
      groupKey: 'email_group',
      setAsGroupSummary: true,
      category: AndroidNotificationCategory.email,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    await _notificationsPlugin!.show(
      bundleId.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'bundle:${notifications.map((n) => n.emailId).join(',')}',
    );

    debugPrint('📱 Sent bundle notification: $title ($count emails)');
  }

  // Helper methods
  static bool _containsKeywords(String content, NotificationCategory category) {
    final keywords = _categoryKeywords[category] ?? [];
    return keywords.any((keyword) => content.contains(keyword));
  }

  static bool _isSocialEmail(EmailMessage email) {
    final socialDomains = ['facebook', 'twitter', 'instagram', 'linkedin', 'snapchat'];
    return socialDomains.any((domain) => email.from.toLowerCase().contains(domain));
  }

  static bool _isPromotionalEmail(EmailMessage email) {
    final promoKeywords = ['unsubscribe', 'promotional', 'marketing', 'offer', 'deal', 'sale'];
    final content = '${email.subject} ${email.textBody}'.toLowerCase();
    return promoKeywords.any((keyword) => content.contains(keyword)) ||
           email.from.toLowerCase().contains('noreply') ||
           email.from.toLowerCase().contains('no-reply');
  }

  static Future<bool> _shouldSkipPromo() async {
    // Skip promotional emails during work hours or if too many already sent
    final now = DateTime.now();
    final isWorkHours = now.hour >= 9 && now.hour <= 17 && now.weekday <= 5;
    return isWorkHours; // Simple logic - could be enhanced
  }

  static String _extractSenderName(String fromField) {
    if (fromField.isEmpty) return 'Unknown';
    final match = RegExp(r'^(.*?)\s*<(.+?)>$').firstMatch(fromField.trim());
    if (match != null) {
      final name = match.group(1)?.trim().replaceAll('"', '') ?? '';
      if (name.isNotEmpty) return name;
      return match.group(2)?.split('@').first ?? 'Unknown';
    }
    return fromField.split('@').first;
  }

  static String _generatePreview(EmailMessage email) {
    if (email.previewText?.isNotEmpty == true) {
      return email.previewText!.length > 100
        ? '${email.previewText!.substring(0, 100)}...'
        : email.previewText!;
    }

    final text = email.textBody.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }

  static String _generateTitle(EmailMessage email, NotificationCategory category, String senderName) {
    switch (category) {
      case NotificationCategory.urgent:
        return 'URGENT: ${email.subject}';
      case NotificationCategory.meeting:
        return 'Meeting: ${email.subject}';
      case NotificationCategory.deadline:
        return 'Deadline: ${email.subject}';
      case NotificationCategory.followUp:
        return 'Follow-up: ${email.subject}';
      default:
        return email.subject.isNotEmpty ? email.subject : 'New email from $senderName';
    }
  }

  static String _generateBody(EmailMessage email, NotificationCategory category, String preview) {
    switch (category) {
      case NotificationCategory.urgent:
        return 'This urgent email needs your immediate attention. $preview';
      case NotificationCategory.meeting:
        return 'Meeting invitation or update. $preview';
      case NotificationCategory.deadline:
        return 'This email contains important deadline information. $preview';
      default:
        return preview;
    }
  }

  static String _getBundleTitle(NotificationCategory category, int count) {
    switch (category) {
      case NotificationCategory.social:
        return '$count new social updates';
      case NotificationCategory.promotional:
        return '$count promotional emails';
      case NotificationCategory.followUp:
        return '$count follow-up reminders';
      default:
        return '$count new emails';
    }
  }

  static String _getBundleBody(List<SmartNotification> notifications, NotificationCategory category) {
    final senders = notifications.map((n) => n.senderName).take(3).join(', ');
    final remaining = notifications.length - 3;

    String sendersText = senders;
    if (remaining > 0) {
      sendersText += ' and $remaining more';
    }

    return 'From $sendersText';
  }

  static Importance _getImportance(String priority) {
    switch (priority) {
      case 'max':
        return Importance.max;
      case 'high':
        return Importance.high;
      case 'default':
        return Importance.defaultImportance;
      case 'low':
        return Importance.low;
      case 'min':
        return Importance.min;
      default:
        return Importance.defaultImportance;
    }
  }

  static Priority _getPriority(String priority) {
    switch (priority) {
      case 'max':
        return Priority.max;
      case 'high':
        return Priority.high;
      case 'default':
        return Priority.defaultPriority;
      case 'low':
        return Priority.low;
      case 'min':
        return Priority.min;
      default:
        return Priority.defaultPriority;
    }
  }

  static Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.urgent:
        return const Color(0xFFFF0000); // Red
      case NotificationCategory.important:
        return const Color(0xFFFF9800); // Orange
      case NotificationCategory.meeting:
        return const Color(0xFF2196F3); // Blue
      case NotificationCategory.deadline:
        return const Color(0xFF9C27B0); // Purple
      case NotificationCategory.followUp:
        return const Color(0xFF4CAF50); // Green
      case NotificationCategory.social:
        return const Color(0xFF00BCD4); // Cyan
      case NotificationCategory.promotional:
        return const Color(0xFF795548); // Brown
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  /// Handle notification taps
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    debugPrint('🔔 Notification tapped: ${response.actionId} - $payload');

    // Handle different action types
    switch (response.actionId) {
      case 'reply':
        _handleReplyAction(payload);
        break;
      case 'mark_read':
        _handleMarkReadAction(payload);
        break;
      case 'open':
        _handleOpenAction(payload);
        break;
      default:
        _handleDefaultAction(payload);
        break;
    }
  }

  static void _handleReplyAction(String payload) {
    // Navigate to compose screen with reply context
    debugPrint('🔔 Opening reply for: $payload');
  }

  static void _handleMarkReadAction(String payload) {
    // Mark email as read
    debugPrint('🔔 Marking as read: $payload');
  }

  static void _handleOpenAction(String payload) {
    // Open email detail screen
    debugPrint('🔔 Opening email: $payload');
  }

  static void _handleDefaultAction(String payload) {
    // Default action - open app
    debugPrint('🔔 Opening app for: $payload');
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _notificationsPlugin?.cancelAll();
    debugPrint('🔔 Cleared all notifications');
  }

  /// Clear notifications for a specific email
  static Future<void> clearNotification(String emailId) async {
    await _notificationsPlugin?.cancel(emailId.hashCode);
    debugPrint('🔔 Cleared notification for: $emailId');
  }
}

/// Represents a smart notification
class SmartNotification {
  final int id;
  final String emailId;
  final NotificationCategory category;
  final String title;
  final String body;
  final String senderName;
  final String accountId;
  final DateTime createdAt;

  const SmartNotification({
    required this.id,
    required this.emailId,
    required this.category,
    required this.title,
    required this.body,
    required this.senderName,
    required this.accountId,
    required this.createdAt,
  });
}