// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationAdapter extends TypeAdapter<Conversation> {
  @override
  final int typeId = 7;

  @override
  Conversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Conversation(
      id: fields[0] as String,
      subject: fields[1] as String,
      messageIds: (fields[2] as List).cast<String>(),
      lastMessageDate: fields[3] as DateTime,
      accountId: fields[4] as String,
      hasUnreadMessages: fields[5] as bool,
      hasImportantMessages: fields[6] as bool,
      messageCount: fields[7] as int,
      participants: (fields[8] as List).cast<String>(),
      previewText: fields[9] as String?,
      isExpanded: fields[10] as bool,
      folder: fields[11] as EmailFolder,
    );
  }

  @override
  void write(BinaryWriter writer, Conversation obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subject)
      ..writeByte(2)
      ..write(obj.messageIds)
      ..writeByte(3)
      ..write(obj.lastMessageDate)
      ..writeByte(4)
      ..write(obj.accountId)
      ..writeByte(5)
      ..write(obj.hasUnreadMessages)
      ..writeByte(6)
      ..write(obj.hasImportantMessages)
      ..writeByte(7)
      ..write(obj.messageCount)
      ..writeByte(8)
      ..write(obj.participants)
      ..writeByte(9)
      ..write(obj.previewText)
      ..writeByte(10)
      ..write(obj.isExpanded)
      ..writeByte(11)
      ..write(obj.folder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
