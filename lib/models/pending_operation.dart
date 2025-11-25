import 'package:hive/hive.dart';

part 'pending_operation.g.dart';

@HiveType(typeId: 6)
enum OperationType {
  @HiveField(0)
  markRead,
  @HiveField(1)
  markUnread,
  @HiveField(2)
  star,
  @HiveField(3)
  unstar,
  @HiveField(4)
  archive,
  @HiveField(5)
  delete,
  @HiveField(6)
  sendEmail,
  @HiveField(7)
  moveToFolder,
  @HiveField(8)
  addLabel,
  @HiveField(9)
  removeLabel,
  @HiveField(10)
  snooze,
}

@HiveType(typeId: 8)
class PendingOperation extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late OperationType operationType;

  @HiveField(2)
  late String? emailId;

  @HiveField(3)
  late Map<String, dynamic> data;

  @HiveField(4)
  late DateTime timestamp;

  @HiveField(5)
  late int retryCount;

  @HiveField(6)
  late String accountId;

  @HiveField(7)
  late bool isProcessing;

  PendingOperation({
    required this.id,
    required this.operationType,
    this.emailId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    required this.accountId,
    this.isProcessing = false,
  });

  PendingOperation.empty()
      : id = '',
        operationType = OperationType.markRead,
        emailId = null,
        data = {},
        timestamp = DateTime.now(),
        retryCount = 0,
        accountId = '',
        isProcessing = false;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType.index,
      'emailId': emailId,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'accountId': accountId,
      'isProcessing': isProcessing,
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      operationType: OperationType.values[json['operationType']],
      emailId: json['emailId'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      accountId: json['accountId'],
      isProcessing: json['isProcessing'] ?? false,
    );
  }

  bool get canRetry => retryCount < 3;

  void incrementRetry() {
    retryCount++;
  }

  @override
  String toString() {
    return 'PendingOperation{id: $id, type: $operationType, emailId: $emailId, retryCount: $retryCount}';
  }
}