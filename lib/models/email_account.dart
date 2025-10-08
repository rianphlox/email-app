import 'package:hive/hive.dart';

part 'email_account.g.dart';

@HiveType(typeId: 0)
class EmailAccount extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String email;

  @HiveField(3)
  late EmailProvider provider;

  @HiveField(4)
  late String accessToken;

  @HiveField(5)
  String? refreshToken;

  @HiveField(6)
  late DateTime lastSync;

  @HiveField(7)
  String? imapServer;

  @HiveField(8)
  int? imapPort;

  @HiveField(9)
  String? smtpServer;

  @HiveField(10)
  int? smtpPort;

  @HiveField(11)
  bool isSSL;

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
  });

  EmailAccount.empty()
      : id = '',
        name = '',
        email = '',
        provider = EmailProvider.gmail,
        accessToken = '',
        lastSync = DateTime.now(),
        isSSL = true;
}

@HiveType(typeId: 1)
enum EmailProvider {
  @HiveField(0)
  gmail,
  @HiveField(1)
  outlook,
  @HiveField(2)
  yahoo,
  @HiveField(3)
  custom,
}