
import 'package:hive/hive.dart';

part 'email_message.g.dart';

/// A data model that represents a single email message.
///
/// This class stores all the details of an email, such as the sender, recipients,
/// subject, body, and attachments. It is also a HiveObject, which means it can
/// be stored in a Hive database for offline access.
@HiveType(typeId: 2)
class EmailMessage extends HiveObject {
  /// The unique identifier for the email message.
  @HiveField(0)
  late String messageId;

  /// The ID of the account this message belongs to.
  @HiveField(1)
  late String accountId;

  /// The subject of the email.
  @HiveField(2)
  late String subject;

  /// The sender of the email.
  @HiveField(3)
  late String from;

  /// A list of recipients of the email.
  @HiveField(4)
  late List<String> to;

  /// A list of carbon copy (CC) recipients.
  @HiveField(5)
  List<String>? cc;

  /// A list of blind carbon copy (BCC) recipients.
  @HiveField(6)
  List<String>? bcc;

  /// The date and time the email was sent.
  @HiveField(7)
  late DateTime date;

  /// The plain text body of the email.
  @HiveField(8)
  late String textBody;

  /// The HTML body of the email, if available.
  @HiveField(9)
  String? htmlBody;

  /// Whether the email has been read.
  @HiveField(10)
  late bool isRead;

  /// Whether the email is marked as important.
  @HiveField(11)
  late bool isImportant;

  /// The folder this email belongs to (e.g., Inbox, Sent).
  @HiveField(12)
  late EmailFolder folder;

  /// A list of attachments included in the email.
  @HiveField(13)
  List<EmailAttachment>? attachments;

  /// The unique identifier (UID) of the email on the server.
  @HiveField(14)
  late int uid;

  /// The category of the email (e.g., Primary, Promotions).
  @HiveField(15)
  EmailCategory category = EmailCategory.primary;

  /// Auto-generated preview text for the email.
  @HiveField(16)
  String? previewText;

  /// Thread ID for grouping related emails (conversation threading)
  @HiveField(17)
  String? threadId;

  /// Reference IDs for reply tracking (In-Reply-To and References headers)
  @HiveField(18)
  List<String>? references;

  /// In-Reply-To header for direct reply relationship
  @HiveField(19)
  String? inReplyTo;

  /// Snooze until date - when the email should reappear in inbox
  @HiveField(20)
  DateTime? snoozeUntil;

  /// Whether this email is currently snoozed
  bool get isSnoozed => snoozeUntil != null && snoozeUntil!.isAfter(DateTime.now());

  /// Creates a new instance of the [EmailMessage] class.
  EmailMessage({
    required this.messageId,
    required this.accountId,
    required this.subject,
    required this.from,
    required this.to,
    this.cc,
    this.bcc,
    required this.date,
    required this.textBody,
    this.htmlBody,
    this.isRead = false,
    this.isImportant = false,
    required this.folder,
    this.attachments,
    required this.uid,
    this.category = EmailCategory.primary,
    this.previewText,
    this.threadId,
    this.references,
    this.inReplyTo,
    this.snoozeUntil,
  });
}

/// An enum that represents the different folders an email can be in.
@HiveType(typeId: 3)
enum EmailFolder {
  /// The inbox folder.
  @HiveField(0)
  inbox,

  /// The sent folder.
  @HiveField(1)
  sent,

  /// The drafts folder.
  @HiveField(2)
  drafts,

  /// The trash folder.
  @HiveField(3)
  trash,

  /// The spam folder.
  @HiveField(4)
  spam,

  /// The archive folder.
  @HiveField(5)
  archive,

  /// A custom folder.
  @HiveField(6)
  custom,
}

/// An enum that represents the different categories an email can be classified into.
@HiveType(typeId: 5)
enum EmailCategory {
  /// The primary category for important emails.
  @HiveField(0)
  primary,

  /// The promotions category for marketing emails.
  @HiveField(1)
  promotions,

  /// The social category for social media notifications.
  @HiveField(2)
  social,

  /// The updates category for notifications and updates.
  @HiveField(3)
  updates,
}

/// A data model that represents an email attachment.
///
/// This class stores information about an email attachment, such as its name,
/// MIME type, size, and local path if it has been downloaded.
@HiveType(typeId: 4)
class EmailAttachment extends HiveObject {
  /// The name of the attachment file.
  @HiveField(0)
  late String name;

  /// The MIME type of the attachment.
  @HiveField(1)
  late String mimeType;

  /// The size of the attachment in bytes.
  @HiveField(2)
  late int size;

  /// The local path where the attachment is stored after being downloaded.
  @HiveField(3)
  String? localPath;

  /// The content ID of the attachment, used for inline images.
  @HiveField(4)
  late String contentId;

  /// Creates a new instance of the [EmailAttachment] class.
  EmailAttachment({
    required this.name,
    required this.mimeType,
    required this.size,
    this.localPath,
    required this.contentId,
  });
}
