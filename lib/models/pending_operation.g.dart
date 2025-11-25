// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_operation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingOperationAdapter extends TypeAdapter<PendingOperation> {
  @override
  final int typeId = 8;

  @override
  PendingOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingOperation(
      id: fields[0] as String,
      operationType: fields[1] as OperationType,
      emailId: fields[2] as String?,
      data: (fields[3] as Map).cast<String, dynamic>(),
      timestamp: fields[4] as DateTime,
      retryCount: fields[5] as int,
      accountId: fields[6] as String,
      isProcessing: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PendingOperation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.operationType)
      ..writeByte(2)
      ..write(obj.emailId)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.accountId)
      ..writeByte(7)
      ..write(obj.isProcessing);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OperationTypeAdapter extends TypeAdapter<OperationType> {
  @override
  final int typeId = 6;

  @override
  OperationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OperationType.markRead;
      case 1:
        return OperationType.markUnread;
      case 2:
        return OperationType.star;
      case 3:
        return OperationType.unstar;
      case 4:
        return OperationType.archive;
      case 5:
        return OperationType.delete;
      case 6:
        return OperationType.sendEmail;
      case 7:
        return OperationType.moveToFolder;
      case 8:
        return OperationType.addLabel;
      case 9:
        return OperationType.removeLabel;
      case 10:
        return OperationType.snooze;
      default:
        return OperationType.markRead;
    }
  }

  @override
  void write(BinaryWriter writer, OperationType obj) {
    switch (obj) {
      case OperationType.markRead:
        writer.writeByte(0);
        break;
      case OperationType.markUnread:
        writer.writeByte(1);
        break;
      case OperationType.star:
        writer.writeByte(2);
        break;
      case OperationType.unstar:
        writer.writeByte(3);
        break;
      case OperationType.archive:
        writer.writeByte(4);
        break;
      case OperationType.delete:
        writer.writeByte(5);
        break;
      case OperationType.sendEmail:
        writer.writeByte(6);
        break;
      case OperationType.moveToFolder:
        writer.writeByte(7);
        break;
      case OperationType.addLabel:
        writer.writeByte(8);
        break;
      case OperationType.removeLabel:
        writer.writeByte(9);
        break;
      case OperationType.snooze:
        writer.writeByte(10);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
