// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmailMessageAdapter extends TypeAdapter<EmailMessage> {
  @override
  final int typeId = 2;

  @override
  EmailMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmailMessage(
      messageId: fields[0] as String,
      accountId: fields[1] as String,
      subject: fields[2] as String,
      from: fields[3] as String,
      to: (fields[4] as List).cast<String>(),
      cc: (fields[5] as List?)?.cast<String>(),
      bcc: (fields[6] as List?)?.cast<String>(),
      date: fields[7] as DateTime,
      textBody: fields[8] as String,
      htmlBody: fields[9] as String?,
      isRead: fields[10] as bool,
      isImportant: fields[11] as bool,
      folder: fields[12] as EmailFolder,
      attachments: (fields[13] as List?)?.cast<EmailAttachment>(),
      uid: fields[14] as int,
      category: fields[15] as EmailCategory,
      previewText: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EmailMessage obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.from)
      ..writeByte(4)
      ..write(obj.to)
      ..writeByte(5)
      ..write(obj.cc)
      ..writeByte(6)
      ..write(obj.bcc)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.textBody)
      ..writeByte(9)
      ..write(obj.htmlBody)
      ..writeByte(10)
      ..write(obj.isRead)
      ..writeByte(11)
      ..write(obj.isImportant)
      ..writeByte(12)
      ..write(obj.folder)
      ..writeByte(13)
      ..write(obj.attachments)
      ..writeByte(14)
      ..write(obj.uid)
      ..writeByte(15)
      ..write(obj.category)
      ..writeByte(16)
      ..write(obj.previewText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmailAttachmentAdapter extends TypeAdapter<EmailAttachment> {
  @override
  final int typeId = 4;

  @override
  EmailAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmailAttachment(
      name: fields[0] as String,
      mimeType: fields[1] as String,
      size: fields[2] as int,
      localPath: fields[3] as String?,
      contentId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EmailAttachment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.mimeType)
      ..writeByte(2)
      ..write(obj.size)
      ..writeByte(3)
      ..write(obj.localPath)
      ..writeByte(4)
      ..write(obj.contentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailAttachmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmailFolderAdapter extends TypeAdapter<EmailFolder> {
  @override
  final int typeId = 3;

  @override
  EmailFolder read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EmailFolder.inbox;
      case 1:
        return EmailFolder.sent;
      case 2:
        return EmailFolder.drafts;
      case 3:
        return EmailFolder.trash;
      case 4:
        return EmailFolder.spam;
      case 5:
        return EmailFolder.archive;
      case 6:
        return EmailFolder.custom;
      default:
        return EmailFolder.inbox;
    }
  }

  @override
  void write(BinaryWriter writer, EmailFolder obj) {
    switch (obj) {
      case EmailFolder.inbox:
        writer.writeByte(0);
        break;
      case EmailFolder.sent:
        writer.writeByte(1);
        break;
      case EmailFolder.drafts:
        writer.writeByte(2);
        break;
      case EmailFolder.trash:
        writer.writeByte(3);
        break;
      case EmailFolder.spam:
        writer.writeByte(4);
        break;
      case EmailFolder.archive:
        writer.writeByte(5);
        break;
      case EmailFolder.custom:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailFolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmailCategoryAdapter extends TypeAdapter<EmailCategory> {
  @override
  final int typeId = 5;

  @override
  EmailCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EmailCategory.primary;
      case 1:
        return EmailCategory.promotions;
      case 2:
        return EmailCategory.social;
      case 3:
        return EmailCategory.updates;
      default:
        return EmailCategory.primary;
    }
  }

  @override
  void write(BinaryWriter writer, EmailCategory obj) {
    switch (obj) {
      case EmailCategory.primary:
        writer.writeByte(0);
        break;
      case EmailCategory.promotions:
        writer.writeByte(1);
        break;
      case EmailCategory.social:
        writer.writeByte(2);
        break;
      case EmailCategory.updates:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
