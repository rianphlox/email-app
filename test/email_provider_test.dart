import 'package:flutter_test/flutter_test.dart';
import 'package:email_mobile_application/models/email.dart';
import 'package:email_mobile_application/providers/email_provider.dart';

void main() {
  group('EmailProvider Tests', () {
    test('should initialize with empty email list', () {
      final provider = EmailProvider();
      expect(provider.emails, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('should filter emails correctly', () {
      final provider = EmailProvider();

      // Create test emails
      final testEmails = [
        Email(
          id: '1',
          userName: 'John Doe',
          subject: 'Test Subject',
          body: 'This is a test email',
          email: 'john@example.com',
        ),
        Email(
          id: '2',
          userName: 'Jane Smith',
          subject: 'Meeting Tomorrow',
          body: 'Let\'s meet tomorrow',
          email: 'jane@example.com',
        ),
      ];

      // Manually set emails for testing
      provider.emails.clear();
      provider.emails.addAll(testEmails);

      // Test search functionality
      provider.searchEmails('john');
      expect(provider.emails.length, 1);
      expect(provider.emails.first.userName, 'John Doe');

      // Clear search
      provider.clearSearch();
      expect(provider.emails.length, 2);
    });

    test('should toggle star status correctly', () {
      final provider = EmailProvider();

      final testEmail = Email(
        id: '1',
        userName: 'Test User',
        isStarred: false,
      );

      // Manually add email for testing
      provider.emails.add(testEmail);
      expect(testEmail.isStarred, false);

      // Toggle star
      provider.toggleStar('1');
      expect(testEmail.isStarred, true);

      // Toggle again
      provider.toggleStar('1');
      expect(testEmail.isStarred, false);
    });
  });
}