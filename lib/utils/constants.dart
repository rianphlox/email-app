
/// A class to hold all the constant values used throughout the application.
///
/// This class centralizes all the important and configurable values, making it
/// easy to manage and update them from one place.
class Constants {
  // --- OAuth Client IDs ---
  // These IDs are required for authenticating with the respective email providers.
  // Replace the placeholder values with your actual client IDs.

  /// The client ID for Google OAuth 2.0 authentication.
  static const String googleClientId = '968928828097-lh79bdv88j7quj5e2eh30tujskqts17b.apps.googleusercontent.com';

  /// The client ID for Outlook OAuth 2.0 authentication.
  static const String outlookClientId = 'YOUR_OUTLOOK_CLIENT_ID';

  /// The client ID for Yahoo OAuth 2.0 authentication.
  static const String yahooClientId = 'YOUR_YAHOO_CLIENT_ID';

  /// The client secret for Yahoo OAuth 2.0 authentication.
  static const String yahooClientSecret = 'YOUR_YAHOO_CLIENT_SECRET';

  // --- OAuth Redirect URIs ---
  // These URIs are used by the OAuth 2.0 flow to redirect the user back to the application.

  /// The redirect URI for Google OAuth 2.0.
  static const String googleRedirectUri = 'urn:ietf:wg:oauth:2.0:oob';

  /// The redirect URI for Outlook OAuth 2.0.
  static const String outlookRedirectUri = 'https://login.microsoftonline.com/common/oauth2/nativeclient';

  /// The redirect URI for Yahoo OAuth 2.0.
  static const String yahooRedirectUri = 'oob';

  // --- Hive Box Names ---
  // These are the names of the boxes used in the Hive local database.

  /// The name of the box for storing email accounts.
  static const String accountsBox = 'accounts';

  /// The name of the box for storing email messages.
  static const String messagesBox = 'messages';

  /// The name of the box for storing email attachments.
  static const String attachmentsBox = 'attachments';

  // --- Default IMAP/SMTP Settings ---
  // A map of default IMAP and SMTP settings for popular email providers.

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

  // --- App Settings ---
  // General settings for the application.

  /// The number of messages to fetch per page.
  static const int messagesPerPage = 50;

  /// The interval at which to sync emails in the background.
  static const Duration syncInterval = Duration(minutes: 15);

  /// The maximum size of an attachment that can be downloaded (in bytes).
  static const int maxAttachmentSize = 25 * 1024 * 1024; // 25MB
}
