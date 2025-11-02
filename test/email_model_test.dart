import 'package:flutter_test/flutter_test.dart';
import 'package:email_mobile_application/models/email.dart';

void main() {
  group('Email Model Tests', () {
    test('should create email from JSON correctly', () {
      final json = {
        'id': 'test123',
        'name': 'John Doe',
        'subject': 'Test Email',
        'body': 'This is a test email body',
        'email': 'john@example.com',
        'datetime': '2023-12-01T10:30:00+05:30',
        'image': 'https://example.com/avatar.jpg',
        'isStarred': true,
      };

      final email = Email.fromJson(json);

      expect(email.id, 'test123');
      expect(email.userName, 'John Doe');
      expect(email.subject, 'Test Email');
      expect(email.body, 'This is a test email body');
      expect(email.email, 'john@example.com');
      expect(email.profileImage, 'https://example.com/avatar.jpg');
      expect(email.isStarred, true);
      expect(email.dateTime, isNotNull);
    });

    test('should handle missing fields gracefully', () {
      final json = {
        'id': 'test123',
      };

      final email = Email.fromJson(json);

      expect(email.id, 'test123');
      expect(email.userName, null);
      expect(email.subject, null);
      expect(email.body, null);
      expect(email.email, null);
      expect(email.profileImage, null);
      expect(email.isStarred, false);
    });

    test('should handle different datetime formats', () {
      // Test ISO format
      final json1 = {
        'id': 'test1',
        'datetime': '2023-12-01T10:30:00Z',
      };
      final email1 = Email.fromJson(json1);
      expect(email1.dateTime, isNotNull);

      // Test timestamp format
      final json2 = {
        'id': 'test2',
        'datetime': '1701424200000', // milliseconds
      };
      final email2 = Email.fromJson(json2);
      expect(email2.dateTime, isNotNull);

      // Test invalid format (should fallback to current time)
      final json3 = {
        'id': 'test3',
        'datetime': 'invalid-date',
      };
      final email3 = Email.fromJson(json3);
      expect(email3.dateTime, isNotNull);
    });
  });
}