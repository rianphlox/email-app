
import 'package:hive/hive.dart';

part 'email_account.g.dart';

/// A data model that represents a user's email account.
///
/// This class is used to store all the necessary information about an email
/// account, including credentials, provider details, and server settings.
/// It is also a HiveObject, which means it can be stored in a Hive database.
@HiveType(typeId: 0)
class EmailAccount extends HiveObject {
  /// A unique identifier for the email account.
  @HiveField(0)
  late String id;

  /// The name of the account holder.
  @HiveField(1)
  late String name;

  /// The email address associated with the account.
  @HiveField(2)
  late String email;

  /// The email provider for this account (e.g., Gmail, Outlook).
  @HiveField(3)
  late EmailProvider provider;

  /// The access token for OAuth 2.0 authentication.
  @HiveField(4)
  late String accessToken;

  /// The refresh token for OAuth 2.0 authentication.
  @HiveField(5)
  String? refreshToken;

  /// The last time the account was synced with the server.
  @HiveField(6)
  late DateTime lastSync;

  /// The IMAP server address for custom email providers.
  @HiveField(7)
  String? imapServer;

  /// The IMAP server port for custom email providers.
  @HiveField(8)
  int? imapPort;

  /// The SMTP server address for custom email providers.
  @HiveField(9)
  String? smtpServer;

  /// The SMTP server port for custom email providers.
  @HiveField(10)
  int? smtpPort;

  /// Whether to use SSL for the connection.
  @HiveField(11)
  bool isSSL;

  /// The password for custom email accounts (stored securely).
  @HiveField(12)
  String? password;

  /// Creates a new instance of the [EmailAccount] class.
  EmailAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.provider,
    required this.accessToken,
    this.refreshToken,
    required this.lastSync,
    this.imapServer,
    this.imapPort,
    this.smtpServer,
    this.smtpPort,
    this.isSSL = true,
    this.password,
  });

  /// Creates an empty [EmailAccount] object.
  EmailAccount.empty()
      : id = '',
        name = '',
        email = '',
        provider = EmailProvider.gmail,
        accessToken = '',
        lastSync = DateTime.now(),
        isSSL = true;
}

/// An enum that represents the different email providers supported by the application.
@HiveType(typeId: 1)
enum EmailProvider {
  /// Google's Gmail service.
  @HiveField(0)
  gmail,

  /// Microsoft's Outlook service.
  @HiveField(1)
  outlook,

  /// Yahoo's email service.
  @HiveField(2)
  yahoo,

  /// A custom email provider with IMAP and SMTP settings.
  @HiveField(3)
  custom,
}
