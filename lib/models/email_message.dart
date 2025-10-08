import 'package:hive/hive.dart';

part 'email_message.g.dart';

@HiveType(typeId: 2)
class EmailMessage extends HiveObject {
  @HiveField(0)
  late String messageId;

  @HiveField(1)
  late String accountId;

  @HiveField(2)
  late String subject;

  @HiveField(3)
  late String from;

  @HiveField(4)
  late List<String> to;

  @HiveField(5)
  List<String>? cc;

  @HiveField(6)
  List<String>? bcc;

  @HiveField(7)
  late DateTime date;

  @HiveField(8)
  late String textBody;

  @HiveField(9)
  String? htmlBody;

  @HiveField(10)
  late bool isRead;

  @HiveField(11)
  late bool isImportant;

  @HiveField(12)
  late EmailFolder folder;

  @HiveField(13)
  List<EmailAttachment>? attachments;

  @HiveField(14)
  late int uid;

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
  });
}

@HiveType(typeId: 3)
enum EmailFolder {
  @HiveField(0)
  inbox,
  @HiveField(1)
  sent,
  @HiveField(2)
  drafts,
  @HiveField(3)
  trash,
  @HiveField(4)
  spam,
  @HiveField(5)
  archive,
  @HiveField(6)
  custom,
}

@HiveType(typeId: 4)
class EmailAttachment extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late String mimeType;

  @HiveField(2)
  late int size;

  @HiveField(3)
  String? localPath;

  @HiveField(4)
  late String contentId;

  EmailAttachment({
    required this.name,
    required this.mimeType,
    required this.size,
    this.localPath,
    required this.contentId,
  });
}