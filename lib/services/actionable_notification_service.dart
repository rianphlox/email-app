import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/email_message.dart';
import '../models/email_account.dart';
import 'smart_notification_service.dart';

/// Quick action types for notifications
enum QuickActionType {
  reply,        // Quick reply to email
  markRead,     // Mark as read
  archive,      // Archive email
  delete,       // Delete email
  snooze,       // Snooze email
  forward,      // Forward email
}

/// Service for creating actionable notifications with quick actions
class ActionableNotificationService {
  static const String _actionReplyId = 'action_reply';
  static const String _actionMarkReadId = 'action_mark_read';
  static const String _actionArchiveId = 'action_archive';
  static const String _actionDeleteId = 'action_delete';
  static const String _actionSnoozeId = 'action_snooze';
  static const String _actionForwardId = 'action_forward';

  /// Initialize actionable notifications with action categories
  static Future<void> initialize() async {
    await SmartNotificationService.initialize();
    // await _setupActionCategories(); // Temporarily disabled due to compilation issues
  }

  /// Setup notification action categories for iOS and Android
  static Future<void> _setupActionCategories() async {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android action setup is handled in notification details
    // iOS requires category setup
    final iOSActions = [
      DarwinNotificationAction.plain(
        _actionReplyId,
        'Reply',
        options: {DarwinNotificationActionOption.foreground},
      ),
      DarwinNotificationAction.plain(_actionMarkReadId, 'Mark Read'),
      DarwinNotificationAction.plain(_actionArchiveId, 'Archive'),
      DarwinNotificationAction.plain(
        _actionDeleteId,
        'Delete',
        options: {DarwinNotificationActionOption.destructive},
      ),
      DarwinNotificationAction.plain(_actionSnoozeId, 'Snooze'),
    ];

    final emailCategory = DarwinNotificationCategory(
      'email_actions',
      actions: iOSActions,
      options: {DarwinNotificationCategoryOption.customDismissAction},
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.initialize(
          const DarwinInitializationSettings(),
        );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    debugPrint('📱 ActionableNotificationService: Initialized with action categories');
  }

  /// Create an actionable notification with quick action buttons
  static Future<void> createActionableNotification({
    required EmailMessage email,
    required EmailAccount account,
    NotificationCategory category = NotificationCategory.important,
    List<QuickActionType> actions = const [
      QuickActionType.reply,
      QuickActionType.markRead,
      QuickActionType.archive,
    ],
  }) async {
    // Temporarily disabled due to compilation issues
    return;
    /*
    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();

      final senderName = _extractSenderName(email.from);
      final title = email.subject.isNotEmpty
          ? email.subject
          : 'New email from $senderName';
      final body = _generatePreview(email);

      // Android-specific actionable notification
      final androidActions = actions.map((action) =>
        _createAndroidAction(action)).toList();

      final androidDetails = AndroidNotificationDetails(
        'actionable_emails',
        'Actionable Email Notifications',
        channelDescription: 'Email notifications with quick actions',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        ledColor: _getCategoryColor(category),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: senderName,
        ),
        actions: androidActions,
        category: AndroidNotificationCategory.email,
        visibility: NotificationVisibility.private,
        ticker: '$senderName: $title',
        autoCancel: false, // Keep notification until user acts
        ongoing: false,
        showWhen: true,
        when: email.date.millisecondsSinceEpoch,
        color: _getCategoryColor(category),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'email_actions',
        threadIdentifier: 'email_thread',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = email.messageId.hashCode;
      final payload = _createActionPayload(email, account, actions);

      await notificationsPlugin.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );

      debugPrint('📱 Created actionable notification for: ${email.subject}');
    } catch (e) {
      debugPrint('❌ ActionableNotificationService: Error creating notification: $e');
    }
    */
  }

  /// Create expandable notification with rich content
  static Future<void> createExpandableNotification({
    required EmailMessage email,
    required EmailAccount account,
    bool showFullContent = false,
  }) async {
    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();

      final senderName = _extractSenderName(email.from);
      final title = email.subject.isNotEmpty
          ? email.subject
          : 'New email from $senderName';

      final shortBody = _generatePreview(email);
      final fullBody = showFullContent
          ? _generateFullContent(email)
          : shortBody;

      // Create expandable big text style
      final bigTextStyle = BigTextStyleInformation(
        fullBody,
        contentTitle: title,
        summaryText: senderName,
        htmlFormatBigText: true,
        htmlFormatContentTitle: true,
        htmlFormatSummaryText: true,
      );

      final androidDetails = AndroidNotificationDetails(
        'expandable_emails',
        'Expandable Email Notifications',
        channelDescription: 'Rich email notifications with full content',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        styleInformation: bigTextStyle,
        actions: [
          AndroidNotificationAction(
            _actionReplyId,
            'Reply',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_reply'),
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            _actionMarkReadId,
            'Mark Read',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_mark_read'),
          ),
          AndroidNotificationAction(
            _actionArchiveId,
            'Archive',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_archive'),
          ),
        ],
        largeIcon: DrawableResourceAndroidBitmap(_getAvatarIcon(senderName)),
        color: Color(0xFF2196F3),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'email_actions',
      );

      await notificationsPlugin.show(
        email.messageId.hashCode + 1000, // Offset to avoid conflicts
        title,
        shortBody, // iOS doesn't expand, so use short version
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: email.messageId,
      );

      debugPrint('📱 Created expandable notification for: ${email.subject}');
    } catch (e) {
      debugPrint('❌ ActionableNotificationService: Error creating expandable notification: $e');
    }
  }

  /// Create conversation notification for email threads
  static Future<void> createConversationNotification({
    required List<EmailMessage> emailThread,
    required EmailAccount account,
    String? conversationTitle,
  }) async {
    if (emailThread.isEmpty) return;

    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();

      final latestEmail = emailThread.first; // Assuming sorted by date
      final threadCount = emailThread.length;

      final title = conversationTitle ??
          (latestEmail.subject.isNotEmpty
              ? latestEmail.subject
              : 'Email conversation');

      // Create messaging style for conversation
      final messagingStyle = MessagingStyleInformation(
        Person(
          name: account.name,
          key: account.id,
        ),
        groupConversation: threadCount > 2,
        conversationTitle: threadCount > 2 ? title : null,
        htmlFormatTitle: true,
        htmlFormatContent: true,
        messages: emailThread.take(5).map((email) =>
          Message(
            _generatePreview(email),
            email.date,
            Person(
              name: _extractSenderName(email.from),
              key: email.from,
            ),
          )
        ).toList(),
      );

      final androidDetails = AndroidNotificationDetails(
        'conversation_emails',
        'Email Conversations',
        channelDescription: 'Email thread notifications',
        importance: Importance.high,
        styleInformation: messagingStyle,
        actions: [
          AndroidNotificationAction(
            _actionReplyId,
            'Reply',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_reply'),
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            _actionMarkReadId,
            'Mark All Read',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_mark_read'),
          ),
        ],
        groupKey: 'conversation_${latestEmail.subject.hashCode}',
        color: const Color(0xFF2196F3),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'email_actions',
        threadIdentifier: 'conversation_thread',
      );

      await notificationsPlugin.show(
        'conversation_${latestEmail.messageId}'.hashCode,
        title,
        '$threadCount messages in conversation',
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'conversation:${emailThread.map((e) => e.messageId).join(',')}',
      );

      debugPrint('📱 Created conversation notification: $title ($threadCount messages)');
    } catch (e) {
      debugPrint('❌ ActionableNotificationService: Error creating conversation notification: $e');
    }
  }

  /// Create high-priority urgent notification with special styling
  static Future<void> createUrgentNotification({
    required EmailMessage email,
    required EmailAccount account,
  }) async {
    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();

      final senderName = _extractSenderName(email.from);
      final title = 'URGENT: ${email.subject}';
      final body = 'This email requires immediate attention.\n\n${_generatePreview(email)}';

      final androidDetails = AndroidNotificationDetails(
        'urgent_emails',
        'Urgent Email Notifications',
        channelDescription: 'Critical emails requiring immediate attention',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF0000),
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'From $senderName',
        ),
        actions: [
          AndroidNotificationAction(
            'urgent_open',
            'Open Now',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_urgent'),
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            _actionReplyId,
            'Reply',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_reply'),
            showsUserInterface: true,
          ),
        ],
        fullScreenIntent: true, // Shows as heads-up notification
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ticker: 'URGENT EMAIL: $title',
        autoCancel: false,
        ongoing: true, // Keep visible until acted upon
        color: Color(0xFFFF0000),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'email_actions',
        interruptionLevel: InterruptionLevel.critical,
      );

      await notificationsPlugin.show(
        email.messageId.hashCode + 2000, // Offset for urgent
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'urgent:${email.messageId}',
      );

      debugPrint('📱 Created urgent notification for: ${email.subject}');
    } catch (e) {
      debugPrint('❌ ActionableNotificationService: Error creating urgent notification: $e');
    }
  }

  /// Handle notification actions
  static Future<void> handleNotificationAction({
    required String actionId,
    required String payload,
    String? userInput,
  }) async {
    debugPrint('📱 Handling notification action: $actionId for $payload');

    switch (actionId) {
      case _actionReplyId:
        await _handleQuickReply(payload, userInput);
        break;
      case _actionMarkReadId:
        await _handleMarkAsRead(payload);
        break;
      case _actionArchiveId:
        await _handleArchive(payload);
        break;
      case _actionDeleteId:
        await _handleDelete(payload);
        break;
      case _actionSnoozeId:
        await _handleSnooze(payload);
        break;
      case _actionForwardId:
        await _handleForward(payload);
        break;
      case 'urgent_open':
        await _handleUrgentOpen(payload);
        break;
      default:
        debugPrint('⚠️ Unknown notification action: $actionId');
        break;
    }
  }

  // Helper methods for creating actions
  static AndroidNotificationAction _createAndroidAction(QuickActionType action) {
    switch (action) {
      case QuickActionType.reply:
        return const AndroidNotificationAction(
          _actionReplyId,
          'Reply',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_reply'),
          showsUserInterface: true,
          inputs: [AndroidNotificationActionInput(
            label: 'Type your reply...',
            allowFreeFormInput: true,
          )],
        );
      case QuickActionType.markRead:
        return const AndroidNotificationAction(
          _actionMarkReadId,
          'Mark Read',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_mark_read'),
        );
      case QuickActionType.archive:
        return const AndroidNotificationAction(
          _actionArchiveId,
          'Archive',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_archive'),
        );
      case QuickActionType.delete:
        return const AndroidNotificationAction(
          _actionDeleteId,
          'Delete',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_delete'),
        );
      case QuickActionType.snooze:
        return const AndroidNotificationAction(
          _actionSnoozeId,
          'Snooze',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_snooze'),
        );
      case QuickActionType.forward:
        return const AndroidNotificationAction(
          _actionForwardId,
          'Forward',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_forward'),
          showsUserInterface: true,
        );
    }
  }

  // Action handlers
  static Future<void> _handleQuickReply(String payload, String? userInput) async {
    if (userInput?.isNotEmpty == true) {
      debugPrint('📤 Quick reply: $userInput for email: $payload');
      // TODO: Implement actual reply functionality
      // This would integrate with the email provider to send the reply
    } else {
      debugPrint('📱 Opening reply screen for: $payload');
      // TODO: Open compose screen with reply context
    }
  }

  static Future<void> _handleMarkAsRead(String payload) async {
    debugPrint('📬 Marking as read: $payload');
    // TODO: Integrate with email provider to mark as read
    // Cancel the notification since it's been acted upon
    await _clearNotificationById(payload);
  }

  static Future<void> _handleArchive(String payload) async {
    debugPrint('📁 Archiving email: $payload');
    // TODO: Integrate with email provider to archive
    await _clearNotificationById(payload);
  }

  static Future<void> _handleDelete(String payload) async {
    debugPrint('🗑️ Deleting email: $payload');
    // TODO: Integrate with email provider to delete
    await _clearNotificationById(payload);
  }

  static Future<void> _handleSnooze(String payload) async {
    debugPrint('😴 Snoozing email: $payload');
    // TODO: Integrate with email provider to snooze
    await _clearNotificationById(payload);
  }

  static Future<void> _handleForward(String payload) async {
    debugPrint('↗️ Opening forward for: $payload');
    // TODO: Open compose screen with forward context
  }

  static Future<void> _handleUrgentOpen(String payload) async {
    debugPrint('🚨 Opening urgent email: $payload');
    // TODO: Open email detail screen immediately
    await _clearNotificationById(payload);
  }

  // Helper methods
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
      return email.previewText!.length > 120
        ? '${email.previewText!.substring(0, 120)}...'
        : email.previewText!;
    }

    final text = email.textBody.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length > 120 ? '${text.substring(0, 120)}...' : text;
  }

  static String _generateFullContent(EmailMessage email) {
    final content = email.textBody.trim();
    return content.length > 500 ? '${content.substring(0, 500)}...' : content;
  }

  static Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.urgent:
        return const Color(0xFFFF0000);
      case NotificationCategory.important:
        return const Color(0xFFFF9800);
      case NotificationCategory.meeting:
        return const Color(0xFF2196F3);
      case NotificationCategory.deadline:
        return const Color(0xFF9C27B0);
      case NotificationCategory.followUp:
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF2196F3);
    }
  }

  static String _getAvatarIcon(String senderName) {
    // Return default avatar icon
    return '@drawable/ic_person';
  }

  static String _createActionPayload(
    EmailMessage email,
    EmailAccount account,
    List<QuickActionType> actions,
  ) {
    return '${email.messageId}|${account.id}|${actions.map((a) => a.toString()).join(',')}';
  }

  static Future<void> _clearNotificationById(String payload) async {
    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      final notificationId = payload.hashCode;
      await notificationsPlugin.cancel(notificationId);
      debugPrint('🔔 Cleared notification: $payload');
    } catch (e) {
      debugPrint('❌ Failed to clear notification: $e');
    }
  }

  static Future<void> _onLegacyNotificationReceived(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // Handle legacy iOS notifications
    debugPrint('📱 Legacy notification received: $title');
  }

  /// Clear all actionable notifications
  static Future<void> clearAllActionableNotifications() async {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    await notificationsPlugin.cancelAll();
    debugPrint('🔔 Cleared all actionable notifications');
  }
}