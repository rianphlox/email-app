// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmailAccountAdapter extends TypeAdapter<EmailAccount> {
  @override
  final int typeId = 0;

  @override
  EmailAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmailAccount(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      provider: fields[3] as EmailProvider,
      accessToken: fields[4] as String,
      refreshToken: fields[5] as String?,
      lastSync: fields[6] as DateTime,
      imapServer: fields[7] as String?,
      imapPort: fields[8] as int?,
      smtpServer: fields[9] as String?,
      smtpPort: fields[10] as int?,
      isSSL: fields[11] as bool,
      password: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EmailAccount obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.provider)
      ..writeByte(4)
      ..write(obj.accessToken)
      ..writeByte(5)
      ..write(obj.refreshToken)
      ..writeByte(6)
      ..write(obj.lastSync)
      ..writeByte(7)
      ..write(obj.imapServer)
      ..writeByte(8)
      ..write(obj.imapPort)
      ..writeByte(9)
      ..write(obj.smtpServer)
      ..writeByte(10)
      ..write(obj.smtpPort)
      ..writeByte(11)
      ..write(obj.isSSL)
      ..writeByte(12)
      ..write(obj.password);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmailProviderAdapter extends TypeAdapter<EmailProvider> {
  @override
  final int typeId = 1;

  @override
  EmailProvider read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EmailProvider.gmail;
      case 1:
        return EmailProvider.outlook;
      case 2:
        return EmailProvider.yahoo;
      case 3:
        return EmailProvider.custom;
      default:
        return EmailProvider.gmail;
    }
  }

  @override
  void write(BinaryWriter writer, EmailProvider obj) {
    switch (obj) {
      case EmailProvider.gmail:
        writer.writeByte(0);
        break;
      case EmailProvider.outlook:
        writer.writeByte(1);
        break;
      case EmailProvider.yahoo:
        writer.writeByte(2);
        break;
      case EmailProvider.custom:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailProviderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
