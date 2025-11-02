import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:email_mobile_application/models/email.dart';

class CacheService {
  static const String _emailsBoxName = 'emails';
  static const String _settingsBoxName = 'settings';

  static Box<String>? _emailsBox;
  static Box<String>? _settingsBox;

  static Future<void> initialize() async {
    _emailsBox = await Hive.openBox<String>(_emailsBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
  }

  // Email caching
  static Future<void> cacheEmails(int tabIndex, List<Email> emails) async {
    if (_emailsBox == null) return;

    final emailsJson = emails.map((e) => _emailToJson(e)).toList();
    await _emailsBox!.put('tab_$tabIndex', jsonEncode(emailsJson));
    await _emailsBox!.put('tab_${tabIndex}_timestamp', DateTime.now().toIso8601String());
  }

  static List<Email>? getCachedEmails(int tabIndex) {
    if (_emailsBox == null) return null;

    final cachedData = _emailsBox!.get('tab_$tabIndex');
    if (cachedData == null) return null;

    try {
      final List<dynamic> emailsJson = jsonDecode(cachedData);
      return emailsJson.map((e) => Email.fromJson(e)).toList();
    } catch (e) {
      return null;
    }
  }

  static bool isCacheValid(int tabIndex, {Duration maxAge = const Duration(minutes: 30)}) {
    if (_emailsBox == null) return false;

    final timestampStr = _emailsBox!.get('tab_${tabIndex}_timestamp');
    if (timestampStr == null) return false;

    try {
      final timestamp = DateTime.parse(timestampStr);
      return DateTime.now().difference(timestamp) < maxAge;
    } catch (e) {
      return false;
    }
  }

  // Settings caching
  static Future<void> setSetting(String key, String value) async {
    if (_settingsBox == null) return;
    await _settingsBox!.put(key, value);
  }

  static String? getSetting(String key) {
    if (_settingsBox == null) return null;
    return _settingsBox!.get(key);
  }

  // Clear cache
  static Future<void> clearEmailCache() async {
    if (_emailsBox == null) return;
    await _emailsBox!.clear();
  }

  static Future<void> clearAllCache() async {
    await clearEmailCache();
    if (_settingsBox != null) {
      await _settingsBox!.clear();
    }
  }

  // Helper method to convert Email to JSON
  static Map<String, dynamic> _emailToJson(Email email) {
    return {
      'id': email.id,
      'profileImage': email.profileImage,
      'userName': email.userName,
      'subject': email.subject,
      'body': email.body,
      'dateTime': email.dateTime?.toIso8601String(),
      'email': email.email,
      'isStarred': email.isStarred,
    };
  }
}