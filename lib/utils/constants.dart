class Constants {
  // OAuth Client IDs - Replace with your actual client IDs
  static const String googleClientId = '968928828097-lh79bdv88j7quj5e2eh30tujskqts17b.apps.googleusercontent.com';
  static const String outlookClientId = 'YOUR_OUTLOOK_CLIENT_ID';
  static const String yahooClientId = 'YOUR_YAHOO_CLIENT_ID';
  static const String yahooClientSecret = 'YOUR_YAHOO_CLIENT_SECRET';

  // OAuth Redirect URIs
  static const String googleRedirectUri = 'urn:ietf:wg:oauth:2.0:oob';
  static const String outlookRedirectUri = 'https://login.microsoftonline.com/common/oauth2/nativeclient';
  static const String yahooRedirectUri = 'oob';

  // Hive Box Names
  static const String accountsBox = 'accounts';
  static const String messagesBox = 'messages';
  static const String attachmentsBox = 'attachments';

  // Default IMAP/SMTP Settings
  static const Map<String, Map<String, dynamic>> defaultEmailSettings = {
    'gmail.com': {
      'imap': {'server': 'imap.gmail.com', 'port': 993, 'ssl': true},
      'smtp': {'server': 'smtp.gmail.com', 'port': 587, 'ssl': true},
    },
    'outlook.com': {
      'imap': {'server': 'outlook.office365.com', 'port': 993, 'ssl': true},
      'smtp': {'server': 'smtp-mail.outlook.com', 'port': 587, 'ssl': true},
    },
    'hotmail.com': {
      'imap': {'server': 'outlook.office365.com', 'port': 993, 'ssl': true},
      'smtp': {'server': 'smtp-mail.outlook.com', 'port': 587, 'ssl': true},
    },
    'yahoo.com': {
      'imap': {'server': 'imap.mail.yahoo.com', 'port': 993, 'ssl': true},
      'smtp': {'server': 'smtp.mail.yahoo.com', 'port': 587, 'ssl': true},
    },
    'icloud.com': {
      'imap': {'server': 'imap.mail.me.com', 'port': 993, 'ssl': true},
      'smtp': {'server': 'smtp.mail.me.com', 'port': 587, 'ssl': true},
    },
  };

  // App Settings
  static const int messagesPerPage = 50;
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxAttachmentSize = 25 * 1024 * 1024; // 25MB
}