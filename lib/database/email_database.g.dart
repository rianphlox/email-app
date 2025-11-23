// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accessTokenMeta =
      const VerificationMeta('accessToken');
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
      'access_token', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _refreshTokenMeta =
      const VerificationMeta('refreshToken');
  @override
  late final GeneratedColumn<String> refreshToken = GeneratedColumn<String>(
      'refresh_token', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _historyIdMeta =
      const VerificationMeta('historyId');
  @override
  late final GeneratedColumn<String> historyId = GeneratedColumn<String>(
      'history_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncTimeMeta =
      const VerificationMeta('lastSyncTime');
  @override
  late final GeneratedColumn<DateTime> lastSyncTime = GeneratedColumn<DateTime>(
      'last_sync_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        email,
        displayName,
        provider,
        accessToken,
        refreshToken,
        historyId,
        lastSyncTime,
        createdAt,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<AccountData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('access_token')) {
      context.handle(
          _accessTokenMeta,
          accessToken.isAcceptableOrUnknown(
              data['access_token']!, _accessTokenMeta));
    }
    if (data.containsKey('refresh_token')) {
      context.handle(
          _refreshTokenMeta,
          refreshToken.isAcceptableOrUnknown(
              data['refresh_token']!, _refreshTokenMeta));
    }
    if (data.containsKey('history_id')) {
      context.handle(_historyIdMeta,
          historyId.isAcceptableOrUnknown(data['history_id']!, _historyIdMeta));
    }
    if (data.containsKey('last_sync_time')) {
      context.handle(
          _lastSyncTimeMeta,
          lastSyncTime.isAcceptableOrUnknown(
              data['last_sync_time']!, _lastSyncTimeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      accessToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}access_token']),
      refreshToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}refresh_token']),
      historyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}history_id']),
      lastSyncTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_sync_time']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountData extends DataClass implements Insertable<AccountData> {
  final String id;
  final String email;
  final String? displayName;
  final String provider;
  final String? accessToken;
  final String? refreshToken;
  final String? historyId;
  final DateTime? lastSyncTime;
  final DateTime createdAt;
  final bool isActive;
  const AccountData(
      {required this.id,
      required this.email,
      this.displayName,
      required this.provider,
      this.accessToken,
      this.refreshToken,
      this.historyId,
      this.lastSyncTime,
      required this.createdAt,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['provider'] = Variable<String>(provider);
    if (!nullToAbsent || accessToken != null) {
      map['access_token'] = Variable<String>(accessToken);
    }
    if (!nullToAbsent || refreshToken != null) {
      map['refresh_token'] = Variable<String>(refreshToken);
    }
    if (!nullToAbsent || historyId != null) {
      map['history_id'] = Variable<String>(historyId);
    }
    if (!nullToAbsent || lastSyncTime != null) {
      map['last_sync_time'] = Variable<DateTime>(lastSyncTime);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      email: Value(email),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      provider: Value(provider),
      accessToken: accessToken == null && nullToAbsent
          ? const Value.absent()
          : Value(accessToken),
      refreshToken: refreshToken == null && nullToAbsent
          ? const Value.absent()
          : Value(refreshToken),
      historyId: historyId == null && nullToAbsent
          ? const Value.absent()
          : Value(historyId),
      lastSyncTime: lastSyncTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncTime),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
    );
  }

  factory AccountData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountData(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      provider: serializer.fromJson<String>(json['provider']),
      accessToken: serializer.fromJson<String?>(json['accessToken']),
      refreshToken: serializer.fromJson<String?>(json['refreshToken']),
      historyId: serializer.fromJson<String?>(json['historyId']),
      lastSyncTime: serializer.fromJson<DateTime?>(json['lastSyncTime']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String?>(displayName),
      'provider': serializer.toJson<String>(provider),
      'accessToken': serializer.toJson<String?>(accessToken),
      'refreshToken': serializer.toJson<String?>(refreshToken),
      'historyId': serializer.toJson<String?>(historyId),
      'lastSyncTime': serializer.toJson<DateTime?>(lastSyncTime),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  AccountData copyWith(
          {String? id,
          String? email,
          Value<String?> displayName = const Value.absent(),
          String? provider,
          Value<String?> accessToken = const Value.absent(),
          Value<String?> refreshToken = const Value.absent(),
          Value<String?> historyId = const Value.absent(),
          Value<DateTime?> lastSyncTime = const Value.absent(),
          DateTime? createdAt,
          bool? isActive}) =>
      AccountData(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName.present ? displayName.value : this.displayName,
        provider: provider ?? this.provider,
        accessToken: accessToken.present ? accessToken.value : this.accessToken,
        refreshToken:
            refreshToken.present ? refreshToken.value : this.refreshToken,
        historyId: historyId.present ? historyId.value : this.historyId,
        lastSyncTime:
            lastSyncTime.present ? lastSyncTime.value : this.lastSyncTime,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );
  AccountData copyWithCompanion(AccountsCompanion data) {
    return AccountData(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      provider: data.provider.present ? data.provider.value : this.provider,
      accessToken:
          data.accessToken.present ? data.accessToken.value : this.accessToken,
      refreshToken: data.refreshToken.present
          ? data.refreshToken.value
          : this.refreshToken,
      historyId: data.historyId.present ? data.historyId.value : this.historyId,
      lastSyncTime: data.lastSyncTime.present
          ? data.lastSyncTime.value
          : this.lastSyncTime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountData(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('provider: $provider, ')
          ..write('accessToken: $accessToken, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('historyId: $historyId, ')
          ..write('lastSyncTime: $lastSyncTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, email, displayName, provider, accessToken,
      refreshToken, historyId, lastSyncTime, createdAt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountData &&
          other.id == this.id &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.provider == this.provider &&
          other.accessToken == this.accessToken &&
          other.refreshToken == this.refreshToken &&
          other.historyId == this.historyId &&
          other.lastSyncTime == this.lastSyncTime &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive);
}

class AccountsCompanion extends UpdateCompanion<AccountData> {
  final Value<String> id;
  final Value<String> email;
  final Value<String?> displayName;
  final Value<String> provider;
  final Value<String?> accessToken;
  final Value<String?> refreshToken;
  final Value<String?> historyId;
  final Value<DateTime?> lastSyncTime;
  final Value<DateTime> createdAt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.provider = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.refreshToken = const Value.absent(),
    this.historyId = const Value.absent(),
    this.lastSyncTime = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String email,
    this.displayName = const Value.absent(),
    required String provider,
    this.accessToken = const Value.absent(),
    this.refreshToken = const Value.absent(),
    this.historyId = const Value.absent(),
    this.lastSyncTime = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        email = Value(email),
        provider = Value(provider);
  static Insertable<AccountData> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? provider,
    Expression<String>? accessToken,
    Expression<String>? refreshToken,
    Expression<String>? historyId,
    Expression<DateTime>? lastSyncTime,
    Expression<DateTime>? createdAt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (provider != null) 'provider': provider,
      if (accessToken != null) 'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (historyId != null) 'history_id': historyId,
      if (lastSyncTime != null) 'last_sync_time': lastSyncTime,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? email,
      Value<String?>? displayName,
      Value<String>? provider,
      Value<String?>? accessToken,
      Value<String?>? refreshToken,
      Value<String?>? historyId,
      Value<DateTime?>? lastSyncTime,
      Value<DateTime>? createdAt,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return AccountsCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      provider: provider ?? this.provider,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      historyId: historyId ?? this.historyId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (refreshToken.present) {
      map['refresh_token'] = Variable<String>(refreshToken.value);
    }
    if (historyId.present) {
      map['history_id'] = Variable<String>(historyId.value);
    }
    if (lastSyncTime.present) {
      map['last_sync_time'] = Variable<DateTime>(lastSyncTime.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('provider: $provider, ')
          ..write('accessToken: $accessToken, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('historyId: $historyId, ')
          ..write('lastSyncTime: $lastSyncTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmailHeadersTable extends EmailHeaders
    with TableInfo<$EmailHeadersTable, EmailHeaderData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmailHeadersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _threadIdMeta =
      const VerificationMeta('threadId');
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
      'thread_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromMeta = const VerificationMeta('from');
  @override
  late final GeneratedColumn<String> from = GeneratedColumn<String>(
      'from', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toMeta = const VerificationMeta('to');
  @override
  late final GeneratedColumn<String> to = GeneratedColumn<String>(
      'to', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ccMeta = const VerificationMeta('cc');
  @override
  late final GeneratedColumn<String> cc = GeneratedColumn<String>(
      'cc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bccMeta = const VerificationMeta('bcc');
  @override
  late final GeneratedColumn<String> bcc = GeneratedColumn<String>(
      'bcc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
      'folder', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelsMeta = const VerificationMeta('labels');
  @override
  late final GeneratedColumn<String> labels = GeneratedColumn<String>(
      'labels', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isStarredMeta =
      const VerificationMeta('isStarred');
  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
      'is_starred', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_starred" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isImportantMeta =
      const VerificationMeta('isImportant');
  @override
  late final GeneratedColumn<bool> isImportant = GeneratedColumn<bool>(
      'is_important', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_important" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasAttachmentsMeta =
      const VerificationMeta('hasAttachments');
  @override
  late final GeneratedColumn<bool> hasAttachments = GeneratedColumn<bool>(
      'has_attachments', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_attachments" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _snippetMeta =
      const VerificationMeta('snippet');
  @override
  late final GeneratedColumn<String> snippet = GeneratedColumn<String>(
      'snippet', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _lastAccessedMeta =
      const VerificationMeta('lastAccessed');
  @override
  late final GeneratedColumn<DateTime> lastAccessed = GeneratedColumn<DateTime>(
      'last_accessed', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  @override
  List<GeneratedColumn> get $columns => [
        messageId,
        accountId,
        threadId,
        subject,
        from,
        to,
        cc,
        bcc,
        date,
        folder,
        labels,
        isRead,
        isStarred,
        isImportant,
        hasAttachments,
        size,
        snippet,
        createdAt,
        lastAccessed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'email_headers';
  @override
  VerificationContext validateIntegrity(Insertable<EmailHeaderData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('thread_id')) {
      context.handle(_threadIdMeta,
          threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('from')) {
      context.handle(
          _fromMeta, from.isAcceptableOrUnknown(data['from']!, _fromMeta));
    } else if (isInserting) {
      context.missing(_fromMeta);
    }
    if (data.containsKey('to')) {
      context.handle(_toMeta, to.isAcceptableOrUnknown(data['to']!, _toMeta));
    } else if (isInserting) {
      context.missing(_toMeta);
    }
    if (data.containsKey('cc')) {
      context.handle(_ccMeta, cc.isAcceptableOrUnknown(data['cc']!, _ccMeta));
    }
    if (data.containsKey('bcc')) {
      context.handle(
          _bccMeta, bcc.isAcceptableOrUnknown(data['bcc']!, _bccMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(_folderMeta,
          folder.isAcceptableOrUnknown(data['folder']!, _folderMeta));
    } else if (isInserting) {
      context.missing(_folderMeta);
    }
    if (data.containsKey('labels')) {
      context.handle(_labelsMeta,
          labels.isAcceptableOrUnknown(data['labels']!, _labelsMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('is_starred')) {
      context.handle(_isStarredMeta,
          isStarred.isAcceptableOrUnknown(data['is_starred']!, _isStarredMeta));
    }
    if (data.containsKey('is_important')) {
      context.handle(
          _isImportantMeta,
          isImportant.isAcceptableOrUnknown(
              data['is_important']!, _isImportantMeta));
    }
    if (data.containsKey('has_attachments')) {
      context.handle(
          _hasAttachmentsMeta,
          hasAttachments.isAcceptableOrUnknown(
              data['has_attachments']!, _hasAttachmentsMeta));
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    }
    if (data.containsKey('snippet')) {
      context.handle(_snippetMeta,
          snippet.isAcceptableOrUnknown(data['snippet']!, _snippetMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_accessed')) {
      context.handle(
          _lastAccessedMeta,
          lastAccessed.isAcceptableOrUnknown(
              data['last_accessed']!, _lastAccessedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, accountId};
  @override
  EmailHeaderData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmailHeaderData(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      threadId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thread_id']),
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      from: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from'])!,
      to: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to'])!,
      cc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cc']),
      bcc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bcc']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      folder: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder'])!,
      labels: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}labels']),
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      isStarred: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_starred'])!,
      isImportant: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_important'])!,
      hasAttachments: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_attachments'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size']),
      snippet: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snippet']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastAccessed: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed'])!,
    );
  }

  @override
  $EmailHeadersTable createAlias(String alias) {
    return $EmailHeadersTable(attachedDatabase, alias);
  }
}

class EmailHeaderData extends DataClass implements Insertable<EmailHeaderData> {
  final String messageId;
  final String accountId;
  final String? threadId;
  final String subject;
  final String from;
  final String to;
  final String? cc;
  final String? bcc;
  final DateTime date;
  final String folder;
  final String? labels;
  final bool isRead;
  final bool isStarred;
  final bool isImportant;
  final bool hasAttachments;
  final int? size;
  final String? snippet;
  final DateTime createdAt;
  final DateTime lastAccessed;
  const EmailHeaderData(
      {required this.messageId,
      required this.accountId,
      this.threadId,
      required this.subject,
      required this.from,
      required this.to,
      this.cc,
      this.bcc,
      required this.date,
      required this.folder,
      this.labels,
      required this.isRead,
      required this.isStarred,
      required this.isImportant,
      required this.hasAttachments,
      this.size,
      this.snippet,
      required this.createdAt,
      required this.lastAccessed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || threadId != null) {
      map['thread_id'] = Variable<String>(threadId);
    }
    map['subject'] = Variable<String>(subject);
    map['from'] = Variable<String>(from);
    map['to'] = Variable<String>(to);
    if (!nullToAbsent || cc != null) {
      map['cc'] = Variable<String>(cc);
    }
    if (!nullToAbsent || bcc != null) {
      map['bcc'] = Variable<String>(bcc);
    }
    map['date'] = Variable<DateTime>(date);
    map['folder'] = Variable<String>(folder);
    if (!nullToAbsent || labels != null) {
      map['labels'] = Variable<String>(labels);
    }
    map['is_read'] = Variable<bool>(isRead);
    map['is_starred'] = Variable<bool>(isStarred);
    map['is_important'] = Variable<bool>(isImportant);
    map['has_attachments'] = Variable<bool>(hasAttachments);
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<int>(size);
    }
    if (!nullToAbsent || snippet != null) {
      map['snippet'] = Variable<String>(snippet);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_accessed'] = Variable<DateTime>(lastAccessed);
    return map;
  }

  EmailHeadersCompanion toCompanion(bool nullToAbsent) {
    return EmailHeadersCompanion(
      messageId: Value(messageId),
      accountId: Value(accountId),
      threadId: threadId == null && nullToAbsent
          ? const Value.absent()
          : Value(threadId),
      subject: Value(subject),
      from: Value(from),
      to: Value(to),
      cc: cc == null && nullToAbsent ? const Value.absent() : Value(cc),
      bcc: bcc == null && nullToAbsent ? const Value.absent() : Value(bcc),
      date: Value(date),
      folder: Value(folder),
      labels:
          labels == null && nullToAbsent ? const Value.absent() : Value(labels),
      isRead: Value(isRead),
      isStarred: Value(isStarred),
      isImportant: Value(isImportant),
      hasAttachments: Value(hasAttachments),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      snippet: snippet == null && nullToAbsent
          ? const Value.absent()
          : Value(snippet),
      createdAt: Value(createdAt),
      lastAccessed: Value(lastAccessed),
    );
  }

  factory EmailHeaderData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmailHeaderData(
      messageId: serializer.fromJson<String>(json['messageId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      threadId: serializer.fromJson<String?>(json['threadId']),
      subject: serializer.fromJson<String>(json['subject']),
      from: serializer.fromJson<String>(json['from']),
      to: serializer.fromJson<String>(json['to']),
      cc: serializer.fromJson<String?>(json['cc']),
      bcc: serializer.fromJson<String?>(json['bcc']),
      date: serializer.fromJson<DateTime>(json['date']),
      folder: serializer.fromJson<String>(json['folder']),
      labels: serializer.fromJson<String?>(json['labels']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
      isImportant: serializer.fromJson<bool>(json['isImportant']),
      hasAttachments: serializer.fromJson<bool>(json['hasAttachments']),
      size: serializer.fromJson<int?>(json['size']),
      snippet: serializer.fromJson<String?>(json['snippet']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAccessed: serializer.fromJson<DateTime>(json['lastAccessed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'accountId': serializer.toJson<String>(accountId),
      'threadId': serializer.toJson<String?>(threadId),
      'subject': serializer.toJson<String>(subject),
      'from': serializer.toJson<String>(from),
      'to': serializer.toJson<String>(to),
      'cc': serializer.toJson<String?>(cc),
      'bcc': serializer.toJson<String?>(bcc),
      'date': serializer.toJson<DateTime>(date),
      'folder': serializer.toJson<String>(folder),
      'labels': serializer.toJson<String?>(labels),
      'isRead': serializer.toJson<bool>(isRead),
      'isStarred': serializer.toJson<bool>(isStarred),
      'isImportant': serializer.toJson<bool>(isImportant),
      'hasAttachments': serializer.toJson<bool>(hasAttachments),
      'size': serializer.toJson<int?>(size),
      'snippet': serializer.toJson<String?>(snippet),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAccessed': serializer.toJson<DateTime>(lastAccessed),
    };
  }

  EmailHeaderData copyWith(
          {String? messageId,
          String? accountId,
          Value<String?> threadId = const Value.absent(),
          String? subject,
          String? from,
          String? to,
          Value<String?> cc = const Value.absent(),
          Value<String?> bcc = const Value.absent(),
          DateTime? date,
          String? folder,
          Value<String?> labels = const Value.absent(),
          bool? isRead,
          bool? isStarred,
          bool? isImportant,
          bool? hasAttachments,
          Value<int?> size = const Value.absent(),
          Value<String?> snippet = const Value.absent(),
          DateTime? createdAt,
          DateTime? lastAccessed}) =>
      EmailHeaderData(
        messageId: messageId ?? this.messageId,
        accountId: accountId ?? this.accountId,
        threadId: threadId.present ? threadId.value : this.threadId,
        subject: subject ?? this.subject,
        from: from ?? this.from,
        to: to ?? this.to,
        cc: cc.present ? cc.value : this.cc,
        bcc: bcc.present ? bcc.value : this.bcc,
        date: date ?? this.date,
        folder: folder ?? this.folder,
        labels: labels.present ? labels.value : this.labels,
        isRead: isRead ?? this.isRead,
        isStarred: isStarred ?? this.isStarred,
        isImportant: isImportant ?? this.isImportant,
        hasAttachments: hasAttachments ?? this.hasAttachments,
        size: size.present ? size.value : this.size,
        snippet: snippet.present ? snippet.value : this.snippet,
        createdAt: createdAt ?? this.createdAt,
        lastAccessed: lastAccessed ?? this.lastAccessed,
      );
  EmailHeaderData copyWithCompanion(EmailHeadersCompanion data) {
    return EmailHeaderData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      subject: data.subject.present ? data.subject.value : this.subject,
      from: data.from.present ? data.from.value : this.from,
      to: data.to.present ? data.to.value : this.to,
      cc: data.cc.present ? data.cc.value : this.cc,
      bcc: data.bcc.present ? data.bcc.value : this.bcc,
      date: data.date.present ? data.date.value : this.date,
      folder: data.folder.present ? data.folder.value : this.folder,
      labels: data.labels.present ? data.labels.value : this.labels,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      isStarred: data.isStarred.present ? data.isStarred.value : this.isStarred,
      isImportant:
          data.isImportant.present ? data.isImportant.value : this.isImportant,
      hasAttachments: data.hasAttachments.present
          ? data.hasAttachments.value
          : this.hasAttachments,
      size: data.size.present ? data.size.value : this.size,
      snippet: data.snippet.present ? data.snippet.value : this.snippet,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAccessed: data.lastAccessed.present
          ? data.lastAccessed.value
          : this.lastAccessed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmailHeaderData(')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('threadId: $threadId, ')
          ..write('subject: $subject, ')
          ..write('from: $from, ')
          ..write('to: $to, ')
          ..write('cc: $cc, ')
          ..write('bcc: $bcc, ')
          ..write('date: $date, ')
          ..write('folder: $folder, ')
          ..write('labels: $labels, ')
          ..write('isRead: $isRead, ')
          ..write('isStarred: $isStarred, ')
          ..write('isImportant: $isImportant, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('size: $size, ')
          ..write('snippet: $snippet, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessed: $lastAccessed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      messageId,
      accountId,
      threadId,
      subject,
      from,
      to,
      cc,
      bcc,
      date,
      folder,
      labels,
      isRead,
      isStarred,
      isImportant,
      hasAttachments,
      size,
      snippet,
      createdAt,
      lastAccessed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmailHeaderData &&
          other.messageId == this.messageId &&
          other.accountId == this.accountId &&
          other.threadId == this.threadId &&
          other.subject == this.subject &&
          other.from == this.from &&
          other.to == this.to &&
          other.cc == this.cc &&
          other.bcc == this.bcc &&
          other.date == this.date &&
          other.folder == this.folder &&
          other.labels == this.labels &&
          other.isRead == this.isRead &&
          other.isStarred == this.isStarred &&
          other.isImportant == this.isImportant &&
          other.hasAttachments == this.hasAttachments &&
          other.size == this.size &&
          other.snippet == this.snippet &&
          other.createdAt == this.createdAt &&
          other.lastAccessed == this.lastAccessed);
}

class EmailHeadersCompanion extends UpdateCompanion<EmailHeaderData> {
  final Value<String> messageId;
  final Value<String> accountId;
  final Value<String?> threadId;
  final Value<String> subject;
  final Value<String> from;
  final Value<String> to;
  final Value<String?> cc;
  final Value<String?> bcc;
  final Value<DateTime> date;
  final Value<String> folder;
  final Value<String?> labels;
  final Value<bool> isRead;
  final Value<bool> isStarred;
  final Value<bool> isImportant;
  final Value<bool> hasAttachments;
  final Value<int?> size;
  final Value<String?> snippet;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastAccessed;
  final Value<int> rowid;
  const EmailHeadersCompanion({
    this.messageId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.threadId = const Value.absent(),
    this.subject = const Value.absent(),
    this.from = const Value.absent(),
    this.to = const Value.absent(),
    this.cc = const Value.absent(),
    this.bcc = const Value.absent(),
    this.date = const Value.absent(),
    this.folder = const Value.absent(),
    this.labels = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isImportant = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.size = const Value.absent(),
    this.snippet = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmailHeadersCompanion.insert({
    required String messageId,
    required String accountId,
    this.threadId = const Value.absent(),
    required String subject,
    required String from,
    required String to,
    this.cc = const Value.absent(),
    this.bcc = const Value.absent(),
    required DateTime date,
    required String folder,
    this.labels = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isImportant = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.size = const Value.absent(),
    this.snippet = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        accountId = Value(accountId),
        subject = Value(subject),
        from = Value(from),
        to = Value(to),
        date = Value(date),
        folder = Value(folder);
  static Insertable<EmailHeaderData> custom({
    Expression<String>? messageId,
    Expression<String>? accountId,
    Expression<String>? threadId,
    Expression<String>? subject,
    Expression<String>? from,
    Expression<String>? to,
    Expression<String>? cc,
    Expression<String>? bcc,
    Expression<DateTime>? date,
    Expression<String>? folder,
    Expression<String>? labels,
    Expression<bool>? isRead,
    Expression<bool>? isStarred,
    Expression<bool>? isImportant,
    Expression<bool>? hasAttachments,
    Expression<int>? size,
    Expression<String>? snippet,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAccessed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (accountId != null) 'account_id': accountId,
      if (threadId != null) 'thread_id': threadId,
      if (subject != null) 'subject': subject,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (cc != null) 'cc': cc,
      if (bcc != null) 'bcc': bcc,
      if (date != null) 'date': date,
      if (folder != null) 'folder': folder,
      if (labels != null) 'labels': labels,
      if (isRead != null) 'is_read': isRead,
      if (isStarred != null) 'is_starred': isStarred,
      if (isImportant != null) 'is_important': isImportant,
      if (hasAttachments != null) 'has_attachments': hasAttachments,
      if (size != null) 'size': size,
      if (snippet != null) 'snippet': snippet,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAccessed != null) 'last_accessed': lastAccessed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmailHeadersCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? accountId,
      Value<String?>? threadId,
      Value<String>? subject,
      Value<String>? from,
      Value<String>? to,
      Value<String?>? cc,
      Value<String?>? bcc,
      Value<DateTime>? date,
      Value<String>? folder,
      Value<String?>? labels,
      Value<bool>? isRead,
      Value<bool>? isStarred,
      Value<bool>? isImportant,
      Value<bool>? hasAttachments,
      Value<int?>? size,
      Value<String?>? snippet,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastAccessed,
      Value<int>? rowid}) {
    return EmailHeadersCompanion(
      messageId: messageId ?? this.messageId,
      accountId: accountId ?? this.accountId,
      threadId: threadId ?? this.threadId,
      subject: subject ?? this.subject,
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      date: date ?? this.date,
      folder: folder ?? this.folder,
      labels: labels ?? this.labels,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      isImportant: isImportant ?? this.isImportant,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      size: size ?? this.size,
      snippet: snippet ?? this.snippet,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (from.present) {
      map['from'] = Variable<String>(from.value);
    }
    if (to.present) {
      map['to'] = Variable<String>(to.value);
    }
    if (cc.present) {
      map['cc'] = Variable<String>(cc.value);
    }
    if (bcc.present) {
      map['bcc'] = Variable<String>(bcc.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (labels.present) {
      map['labels'] = Variable<String>(labels.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (isStarred.present) {
      map['is_starred'] = Variable<bool>(isStarred.value);
    }
    if (isImportant.present) {
      map['is_important'] = Variable<bool>(isImportant.value);
    }
    if (hasAttachments.present) {
      map['has_attachments'] = Variable<bool>(hasAttachments.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (snippet.present) {
      map['snippet'] = Variable<String>(snippet.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAccessed.present) {
      map['last_accessed'] = Variable<DateTime>(lastAccessed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmailHeadersCompanion(')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('threadId: $threadId, ')
          ..write('subject: $subject, ')
          ..write('from: $from, ')
          ..write('to: $to, ')
          ..write('cc: $cc, ')
          ..write('bcc: $bcc, ')
          ..write('date: $date, ')
          ..write('folder: $folder, ')
          ..write('labels: $labels, ')
          ..write('isRead: $isRead, ')
          ..write('isStarred: $isStarred, ')
          ..write('isImportant: $isImportant, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('size: $size, ')
          ..write('snippet: $snippet, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmailBodiesTable extends EmailBodies
    with TableInfo<$EmailBodiesTable, EmailBodyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmailBodiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _textBodyMeta =
      const VerificationMeta('textBody');
  @override
  late final GeneratedColumn<String> textBody = GeneratedColumn<String>(
      'text_body', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _htmlBodyMeta =
      const VerificationMeta('htmlBody');
  @override
  late final GeneratedColumn<String> htmlBody = GeneratedColumn<String>(
      'html_body', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _processedHtmlMeta =
      const VerificationMeta('processedHtml');
  @override
  late final GeneratedColumn<String> processedHtml = GeneratedColumn<String>(
      'processed_html', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hasQuotedTextMeta =
      const VerificationMeta('hasQuotedText');
  @override
  late final GeneratedColumn<bool> hasQuotedText = GeneratedColumn<bool>(
      'has_quoted_text', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_quoted_text" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasSignatureMeta =
      const VerificationMeta('hasSignature');
  @override
  late final GeneratedColumn<bool> hasSignature = GeneratedColumn<bool>(
      'has_signature', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_signature" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _bodySizeMeta =
      const VerificationMeta('bodySize');
  @override
  late final GeneratedColumn<int> bodySize = GeneratedColumn<int>(
      'body_size', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _lastAccessedMeta =
      const VerificationMeta('lastAccessed');
  @override
  late final GeneratedColumn<DateTime> lastAccessed = GeneratedColumn<DateTime>(
      'last_accessed', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  @override
  List<GeneratedColumn> get $columns => [
        messageId,
        accountId,
        textBody,
        htmlBody,
        processedHtml,
        hasQuotedText,
        hasSignature,
        bodySize,
        createdAt,
        lastAccessed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'email_bodies';
  @override
  VerificationContext validateIntegrity(Insertable<EmailBodyData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('text_body')) {
      context.handle(_textBodyMeta,
          textBody.isAcceptableOrUnknown(data['text_body']!, _textBodyMeta));
    }
    if (data.containsKey('html_body')) {
      context.handle(_htmlBodyMeta,
          htmlBody.isAcceptableOrUnknown(data['html_body']!, _htmlBodyMeta));
    }
    if (data.containsKey('processed_html')) {
      context.handle(
          _processedHtmlMeta,
          processedHtml.isAcceptableOrUnknown(
              data['processed_html']!, _processedHtmlMeta));
    }
    if (data.containsKey('has_quoted_text')) {
      context.handle(
          _hasQuotedTextMeta,
          hasQuotedText.isAcceptableOrUnknown(
              data['has_quoted_text']!, _hasQuotedTextMeta));
    }
    if (data.containsKey('has_signature')) {
      context.handle(
          _hasSignatureMeta,
          hasSignature.isAcceptableOrUnknown(
              data['has_signature']!, _hasSignatureMeta));
    }
    if (data.containsKey('body_size')) {
      context.handle(_bodySizeMeta,
          bodySize.isAcceptableOrUnknown(data['body_size']!, _bodySizeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_accessed')) {
      context.handle(
          _lastAccessedMeta,
          lastAccessed.isAcceptableOrUnknown(
              data['last_accessed']!, _lastAccessedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, accountId};
  @override
  EmailBodyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmailBodyData(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      textBody: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_body']),
      htmlBody: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}html_body']),
      processedHtml: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}processed_html']),
      hasQuotedText: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_quoted_text'])!,
      hasSignature: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_signature'])!,
      bodySize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}body_size']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastAccessed: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed'])!,
    );
  }

  @override
  $EmailBodiesTable createAlias(String alias) {
    return $EmailBodiesTable(attachedDatabase, alias);
  }
}

class EmailBodyData extends DataClass implements Insertable<EmailBodyData> {
  final String messageId;
  final String accountId;
  final String? textBody;
  final String? htmlBody;
  final String? processedHtml;
  final bool hasQuotedText;
  final bool hasSignature;
  final int? bodySize;
  final DateTime createdAt;
  final DateTime lastAccessed;
  const EmailBodyData(
      {required this.messageId,
      required this.accountId,
      this.textBody,
      this.htmlBody,
      this.processedHtml,
      required this.hasQuotedText,
      required this.hasSignature,
      this.bodySize,
      required this.createdAt,
      required this.lastAccessed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || textBody != null) {
      map['text_body'] = Variable<String>(textBody);
    }
    if (!nullToAbsent || htmlBody != null) {
      map['html_body'] = Variable<String>(htmlBody);
    }
    if (!nullToAbsent || processedHtml != null) {
      map['processed_html'] = Variable<String>(processedHtml);
    }
    map['has_quoted_text'] = Variable<bool>(hasQuotedText);
    map['has_signature'] = Variable<bool>(hasSignature);
    if (!nullToAbsent || bodySize != null) {
      map['body_size'] = Variable<int>(bodySize);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_accessed'] = Variable<DateTime>(lastAccessed);
    return map;
  }

  EmailBodiesCompanion toCompanion(bool nullToAbsent) {
    return EmailBodiesCompanion(
      messageId: Value(messageId),
      accountId: Value(accountId),
      textBody: textBody == null && nullToAbsent
          ? const Value.absent()
          : Value(textBody),
      htmlBody: htmlBody == null && nullToAbsent
          ? const Value.absent()
          : Value(htmlBody),
      processedHtml: processedHtml == null && nullToAbsent
          ? const Value.absent()
          : Value(processedHtml),
      hasQuotedText: Value(hasQuotedText),
      hasSignature: Value(hasSignature),
      bodySize: bodySize == null && nullToAbsent
          ? const Value.absent()
          : Value(bodySize),
      createdAt: Value(createdAt),
      lastAccessed: Value(lastAccessed),
    );
  }

  factory EmailBodyData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmailBodyData(
      messageId: serializer.fromJson<String>(json['messageId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      textBody: serializer.fromJson<String?>(json['textBody']),
      htmlBody: serializer.fromJson<String?>(json['htmlBody']),
      processedHtml: serializer.fromJson<String?>(json['processedHtml']),
      hasQuotedText: serializer.fromJson<bool>(json['hasQuotedText']),
      hasSignature: serializer.fromJson<bool>(json['hasSignature']),
      bodySize: serializer.fromJson<int?>(json['bodySize']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAccessed: serializer.fromJson<DateTime>(json['lastAccessed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'accountId': serializer.toJson<String>(accountId),
      'textBody': serializer.toJson<String?>(textBody),
      'htmlBody': serializer.toJson<String?>(htmlBody),
      'processedHtml': serializer.toJson<String?>(processedHtml),
      'hasQuotedText': serializer.toJson<bool>(hasQuotedText),
      'hasSignature': serializer.toJson<bool>(hasSignature),
      'bodySize': serializer.toJson<int?>(bodySize),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAccessed': serializer.toJson<DateTime>(lastAccessed),
    };
  }

  EmailBodyData copyWith(
          {String? messageId,
          String? accountId,
          Value<String?> textBody = const Value.absent(),
          Value<String?> htmlBody = const Value.absent(),
          Value<String?> processedHtml = const Value.absent(),
          bool? hasQuotedText,
          bool? hasSignature,
          Value<int?> bodySize = const Value.absent(),
          DateTime? createdAt,
          DateTime? lastAccessed}) =>
      EmailBodyData(
        messageId: messageId ?? this.messageId,
        accountId: accountId ?? this.accountId,
        textBody: textBody.present ? textBody.value : this.textBody,
        htmlBody: htmlBody.present ? htmlBody.value : this.htmlBody,
        processedHtml:
            processedHtml.present ? processedHtml.value : this.processedHtml,
        hasQuotedText: hasQuotedText ?? this.hasQuotedText,
        hasSignature: hasSignature ?? this.hasSignature,
        bodySize: bodySize.present ? bodySize.value : this.bodySize,
        createdAt: createdAt ?? this.createdAt,
        lastAccessed: lastAccessed ?? this.lastAccessed,
      );
  EmailBodyData copyWithCompanion(EmailBodiesCompanion data) {
    return EmailBodyData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      textBody: data.textBody.present ? data.textBody.value : this.textBody,
      htmlBody: data.htmlBody.present ? data.htmlBody.value : this.htmlBody,
      processedHtml: data.processedHtml.present
          ? data.processedHtml.value
          : this.processedHtml,
      hasQuotedText: data.hasQuotedText.present
          ? data.hasQuotedText.value
          : this.hasQuotedText,
      hasSignature: data.hasSignature.present
          ? data.hasSignature.value
          : this.hasSignature,
      bodySize: data.bodySize.present ? data.bodySize.value : this.bodySize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAccessed: data.lastAccessed.present
          ? data.lastAccessed.value
          : this.lastAccessed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmailBodyData(')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('textBody: $textBody, ')
          ..write('htmlBody: $htmlBody, ')
          ..write('processedHtml: $processedHtml, ')
          ..write('hasQuotedText: $hasQuotedText, ')
          ..write('hasSignature: $hasSignature, ')
          ..write('bodySize: $bodySize, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessed: $lastAccessed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      messageId,
      accountId,
      textBody,
      htmlBody,
      processedHtml,
      hasQuotedText,
      hasSignature,
      bodySize,
      createdAt,
      lastAccessed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmailBodyData &&
          other.messageId == this.messageId &&
          other.accountId == this.accountId &&
          other.textBody == this.textBody &&
          other.htmlBody == this.htmlBody &&
          other.processedHtml == this.processedHtml &&
          other.hasQuotedText == this.hasQuotedText &&
          other.hasSignature == this.hasSignature &&
          other.bodySize == this.bodySize &&
          other.createdAt == this.createdAt &&
          other.lastAccessed == this.lastAccessed);
}

class EmailBodiesCompanion extends UpdateCompanion<EmailBodyData> {
  final Value<String> messageId;
  final Value<String> accountId;
  final Value<String?> textBody;
  final Value<String?> htmlBody;
  final Value<String?> processedHtml;
  final Value<bool> hasQuotedText;
  final Value<bool> hasSignature;
  final Value<int?> bodySize;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastAccessed;
  final Value<int> rowid;
  const EmailBodiesCompanion({
    this.messageId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.textBody = const Value.absent(),
    this.htmlBody = const Value.absent(),
    this.processedHtml = const Value.absent(),
    this.hasQuotedText = const Value.absent(),
    this.hasSignature = const Value.absent(),
    this.bodySize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmailBodiesCompanion.insert({
    required String messageId,
    required String accountId,
    this.textBody = const Value.absent(),
    this.htmlBody = const Value.absent(),
    this.processedHtml = const Value.absent(),
    this.hasQuotedText = const Value.absent(),
    this.hasSignature = const Value.absent(),
    this.bodySize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        accountId = Value(accountId);
  static Insertable<EmailBodyData> custom({
    Expression<String>? messageId,
    Expression<String>? accountId,
    Expression<String>? textBody,
    Expression<String>? htmlBody,
    Expression<String>? processedHtml,
    Expression<bool>? hasQuotedText,
    Expression<bool>? hasSignature,
    Expression<int>? bodySize,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAccessed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (accountId != null) 'account_id': accountId,
      if (textBody != null) 'text_body': textBody,
      if (htmlBody != null) 'html_body': htmlBody,
      if (processedHtml != null) 'processed_html': processedHtml,
      if (hasQuotedText != null) 'has_quoted_text': hasQuotedText,
      if (hasSignature != null) 'has_signature': hasSignature,
      if (bodySize != null) 'body_size': bodySize,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAccessed != null) 'last_accessed': lastAccessed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmailBodiesCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? accountId,
      Value<String?>? textBody,
      Value<String?>? htmlBody,
      Value<String?>? processedHtml,
      Value<bool>? hasQuotedText,
      Value<bool>? hasSignature,
      Value<int?>? bodySize,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastAccessed,
      Value<int>? rowid}) {
    return EmailBodiesCompanion(
      messageId: messageId ?? this.messageId,
      accountId: accountId ?? this.accountId,
      textBody: textBody ?? this.textBody,
      htmlBody: htmlBody ?? this.htmlBody,
      processedHtml: processedHtml ?? this.processedHtml,
      hasQuotedText: hasQuotedText ?? this.hasQuotedText,
      hasSignature: hasSignature ?? this.hasSignature,
      bodySize: bodySize ?? this.bodySize,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (textBody.present) {
      map['text_body'] = Variable<String>(textBody.value);
    }
    if (htmlBody.present) {
      map['html_body'] = Variable<String>(htmlBody.value);
    }
    if (processedHtml.present) {
      map['processed_html'] = Variable<String>(processedHtml.value);
    }
    if (hasQuotedText.present) {
      map['has_quoted_text'] = Variable<bool>(hasQuotedText.value);
    }
    if (hasSignature.present) {
      map['has_signature'] = Variable<bool>(hasSignature.value);
    }
    if (bodySize.present) {
      map['body_size'] = Variable<int>(bodySize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAccessed.present) {
      map['last_accessed'] = Variable<DateTime>(lastAccessed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmailBodiesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('textBody: $textBody, ')
          ..write('htmlBody: $htmlBody, ')
          ..write('processedHtml: $processedHtml, ')
          ..write('hasQuotedText: $hasQuotedText, ')
          ..write('hasSignature: $hasSignature, ')
          ..write('bodySize: $bodySize, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, AttachmentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
      'data', aliasedName, true,
      type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _downloadUrlMeta =
      const VerificationMeta('downloadUrl');
  @override
  late final GeneratedColumn<String> downloadUrl = GeneratedColumn<String>(
      'download_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isInlineMeta =
      const VerificationMeta('isInline');
  @override
  late final GeneratedColumn<bool> isInline = GeneratedColumn<bool>(
      'is_inline', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_inline" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _contentIdMeta =
      const VerificationMeta('contentId');
  @override
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
      'content_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _lastAccessedMeta =
      const VerificationMeta('lastAccessed');
  @override
  late final GeneratedColumn<DateTime> lastAccessed = GeneratedColumn<DateTime>(
      'last_accessed', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        messageId,
        accountId,
        filename,
        mimeType,
        size,
        data,
        localPath,
        downloadUrl,
        isInline,
        contentId,
        createdAt,
        lastAccessed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(Insertable<AttachmentData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('download_url')) {
      context.handle(
          _downloadUrlMeta,
          downloadUrl.isAcceptableOrUnknown(
              data['download_url']!, _downloadUrlMeta));
    }
    if (data.containsKey('is_inline')) {
      context.handle(_isInlineMeta,
          isInline.isAcceptableOrUnknown(data['is_inline']!, _isInlineMeta));
    }
    if (data.containsKey('content_id')) {
      context.handle(_contentIdMeta,
          contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_accessed')) {
      context.handle(
          _lastAccessedMeta,
          lastAccessed.isAcceptableOrUnknown(
              data['last_accessed']!, _lastAccessedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}data']),
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      downloadUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}download_url']),
      isInline: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_inline'])!,
      contentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastAccessed: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed'])!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class AttachmentData extends DataClass implements Insertable<AttachmentData> {
  final String id;
  final String messageId;
  final String accountId;
  final String filename;
  final String mimeType;
  final int size;
  final Uint8List? data;
  final String? localPath;
  final String? downloadUrl;
  final bool isInline;
  final String? contentId;
  final DateTime createdAt;
  final DateTime lastAccessed;
  const AttachmentData(
      {required this.id,
      required this.messageId,
      required this.accountId,
      required this.filename,
      required this.mimeType,
      required this.size,
      this.data,
      this.localPath,
      this.downloadUrl,
      required this.isInline,
      this.contentId,
      required this.createdAt,
      required this.lastAccessed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['message_id'] = Variable<String>(messageId);
    map['account_id'] = Variable<String>(accountId);
    map['filename'] = Variable<String>(filename);
    map['mime_type'] = Variable<String>(mimeType);
    map['size'] = Variable<int>(size);
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<Uint8List>(data);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || downloadUrl != null) {
      map['download_url'] = Variable<String>(downloadUrl);
    }
    map['is_inline'] = Variable<bool>(isInline);
    if (!nullToAbsent || contentId != null) {
      map['content_id'] = Variable<String>(contentId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_accessed'] = Variable<DateTime>(lastAccessed);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      accountId: Value(accountId),
      filename: Value(filename),
      mimeType: Value(mimeType),
      size: Value(size),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      downloadUrl: downloadUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadUrl),
      isInline: Value(isInline),
      contentId: contentId == null && nullToAbsent
          ? const Value.absent()
          : Value(contentId),
      createdAt: Value(createdAt),
      lastAccessed: Value(lastAccessed),
    );
  }

  factory AttachmentData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentData(
      id: serializer.fromJson<String>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      filename: serializer.fromJson<String>(json['filename']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      size: serializer.fromJson<int>(json['size']),
      data: serializer.fromJson<Uint8List?>(json['data']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      downloadUrl: serializer.fromJson<String?>(json['downloadUrl']),
      isInline: serializer.fromJson<bool>(json['isInline']),
      contentId: serializer.fromJson<String?>(json['contentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAccessed: serializer.fromJson<DateTime>(json['lastAccessed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messageId': serializer.toJson<String>(messageId),
      'accountId': serializer.toJson<String>(accountId),
      'filename': serializer.toJson<String>(filename),
      'mimeType': serializer.toJson<String>(mimeType),
      'size': serializer.toJson<int>(size),
      'data': serializer.toJson<Uint8List?>(data),
      'localPath': serializer.toJson<String?>(localPath),
      'downloadUrl': serializer.toJson<String?>(downloadUrl),
      'isInline': serializer.toJson<bool>(isInline),
      'contentId': serializer.toJson<String?>(contentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAccessed': serializer.toJson<DateTime>(lastAccessed),
    };
  }

  AttachmentData copyWith(
          {String? id,
          String? messageId,
          String? accountId,
          String? filename,
          String? mimeType,
          int? size,
          Value<Uint8List?> data = const Value.absent(),
          Value<String?> localPath = const Value.absent(),
          Value<String?> downloadUrl = const Value.absent(),
          bool? isInline,
          Value<String?> contentId = const Value.absent(),
          DateTime? createdAt,
          DateTime? lastAccessed}) =>
      AttachmentData(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        accountId: accountId ?? this.accountId,
        filename: filename ?? this.filename,
        mimeType: mimeType ?? this.mimeType,
        size: size ?? this.size,
        data: data.present ? data.value : this.data,
        localPath: localPath.present ? localPath.value : this.localPath,
        downloadUrl: downloadUrl.present ? downloadUrl.value : this.downloadUrl,
        isInline: isInline ?? this.isInline,
        contentId: contentId.present ? contentId.value : this.contentId,
        createdAt: createdAt ?? this.createdAt,
        lastAccessed: lastAccessed ?? this.lastAccessed,
      );
  AttachmentData copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentData(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      filename: data.filename.present ? data.filename.value : this.filename,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      size: data.size.present ? data.size.value : this.size,
      data: data.data.present ? data.data.value : this.data,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      downloadUrl:
          data.downloadUrl.present ? data.downloadUrl.value : this.downloadUrl,
      isInline: data.isInline.present ? data.isInline.value : this.isInline,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAccessed: data.lastAccessed.present
          ? data.lastAccessed.value
          : this.lastAccessed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentData(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('data: $data, ')
          ..write('localPath: $localPath, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('isInline: $isInline, ')
          ..write('contentId: $contentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessed: $lastAccessed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      messageId,
      accountId,
      filename,
      mimeType,
      size,
      $driftBlobEquality.hash(data),
      localPath,
      downloadUrl,
      isInline,
      contentId,
      createdAt,
      lastAccessed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentData &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.accountId == this.accountId &&
          other.filename == this.filename &&
          other.mimeType == this.mimeType &&
          other.size == this.size &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.localPath == this.localPath &&
          other.downloadUrl == this.downloadUrl &&
          other.isInline == this.isInline &&
          other.contentId == this.contentId &&
          other.createdAt == this.createdAt &&
          other.lastAccessed == this.lastAccessed);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentData> {
  final Value<String> id;
  final Value<String> messageId;
  final Value<String> accountId;
  final Value<String> filename;
  final Value<String> mimeType;
  final Value<int> size;
  final Value<Uint8List?> data;
  final Value<String?> localPath;
  final Value<String?> downloadUrl;
  final Value<bool> isInline;
  final Value<String?> contentId;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastAccessed;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.filename = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.size = const Value.absent(),
    this.data = const Value.absent(),
    this.localPath = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.isInline = const Value.absent(),
    this.contentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String messageId,
    required String accountId,
    required String filename,
    required String mimeType,
    required int size,
    this.data = const Value.absent(),
    this.localPath = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.isInline = const Value.absent(),
    this.contentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        messageId = Value(messageId),
        accountId = Value(accountId),
        filename = Value(filename),
        mimeType = Value(mimeType),
        size = Value(size);
  static Insertable<AttachmentData> custom({
    Expression<String>? id,
    Expression<String>? messageId,
    Expression<String>? accountId,
    Expression<String>? filename,
    Expression<String>? mimeType,
    Expression<int>? size,
    Expression<Uint8List>? data,
    Expression<String>? localPath,
    Expression<String>? downloadUrl,
    Expression<bool>? isInline,
    Expression<String>? contentId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAccessed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (accountId != null) 'account_id': accountId,
      if (filename != null) 'filename': filename,
      if (mimeType != null) 'mime_type': mimeType,
      if (size != null) 'size': size,
      if (data != null) 'data': data,
      if (localPath != null) 'local_path': localPath,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (isInline != null) 'is_inline': isInline,
      if (contentId != null) 'content_id': contentId,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAccessed != null) 'last_accessed': lastAccessed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? messageId,
      Value<String>? accountId,
      Value<String>? filename,
      Value<String>? mimeType,
      Value<int>? size,
      Value<Uint8List?>? data,
      Value<String?>? localPath,
      Value<String?>? downloadUrl,
      Value<bool>? isInline,
      Value<String?>? contentId,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastAccessed,
      Value<int>? rowid}) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      accountId: accountId ?? this.accountId,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      data: data ?? this.data,
      localPath: localPath ?? this.localPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isInline: isInline ?? this.isInline,
      contentId: contentId ?? this.contentId,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (downloadUrl.present) {
      map['download_url'] = Variable<String>(downloadUrl.value);
    }
    if (isInline.present) {
      map['is_inline'] = Variable<bool>(isInline.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAccessed.present) {
      map['last_accessed'] = Variable<DateTime>(lastAccessed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('data: $data, ')
          ..write('localPath: $localPath, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('isInline: $isInline, ')
          ..write('contentId: $contentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, ConversationData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _participantsMeta =
      const VerificationMeta('participants');
  @override
  late final GeneratedColumn<String> participants = GeneratedColumn<String>(
      'participants', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageCountMeta =
      const VerificationMeta('messageCount');
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
      'message_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _lastMessageDateMeta =
      const VerificationMeta('lastMessageDate');
  @override
  late final GeneratedColumn<DateTime> lastMessageDate =
      GeneratedColumn<DateTime>('last_message_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _hasUnreadMessagesMeta =
      const VerificationMeta('hasUnreadMessages');
  @override
  late final GeneratedColumn<bool> hasUnreadMessages = GeneratedColumn<bool>(
      'has_unread_messages', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_unread_messages" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasStarredMessagesMeta =
      const VerificationMeta('hasStarredMessages');
  @override
  late final GeneratedColumn<bool> hasStarredMessages = GeneratedColumn<bool>(
      'has_starred_messages', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_starred_messages" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasImportantMessagesMeta =
      const VerificationMeta('hasImportantMessages');
  @override
  late final GeneratedColumn<bool> hasImportantMessages = GeneratedColumn<bool>(
      'has_important_messages', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_important_messages" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _latestSnippetMeta =
      const VerificationMeta('latestSnippet');
  @override
  late final GeneratedColumn<String> latestSnippet = GeneratedColumn<String>(
      'latest_snippet', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
      'folder', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _lastAccessedMeta =
      const VerificationMeta('lastAccessed');
  @override
  late final GeneratedColumn<DateTime> lastAccessed = GeneratedColumn<DateTime>(
      'last_accessed', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        accountId,
        subject,
        participants,
        messageCount,
        lastMessageDate,
        hasUnreadMessages,
        hasStarredMessages,
        hasImportantMessages,
        latestSnippet,
        folder,
        createdAt,
        lastAccessed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(Insertable<ConversationData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('participants')) {
      context.handle(
          _participantsMeta,
          participants.isAcceptableOrUnknown(
              data['participants']!, _participantsMeta));
    } else if (isInserting) {
      context.missing(_participantsMeta);
    }
    if (data.containsKey('message_count')) {
      context.handle(
          _messageCountMeta,
          messageCount.isAcceptableOrUnknown(
              data['message_count']!, _messageCountMeta));
    }
    if (data.containsKey('last_message_date')) {
      context.handle(
          _lastMessageDateMeta,
          lastMessageDate.isAcceptableOrUnknown(
              data['last_message_date']!, _lastMessageDateMeta));
    } else if (isInserting) {
      context.missing(_lastMessageDateMeta);
    }
    if (data.containsKey('has_unread_messages')) {
      context.handle(
          _hasUnreadMessagesMeta,
          hasUnreadMessages.isAcceptableOrUnknown(
              data['has_unread_messages']!, _hasUnreadMessagesMeta));
    }
    if (data.containsKey('has_starred_messages')) {
      context.handle(
          _hasStarredMessagesMeta,
          hasStarredMessages.isAcceptableOrUnknown(
              data['has_starred_messages']!, _hasStarredMessagesMeta));
    }
    if (data.containsKey('has_important_messages')) {
      context.handle(
          _hasImportantMessagesMeta,
          hasImportantMessages.isAcceptableOrUnknown(
              data['has_important_messages']!, _hasImportantMessagesMeta));
    }
    if (data.containsKey('latest_snippet')) {
      context.handle(
          _latestSnippetMeta,
          latestSnippet.isAcceptableOrUnknown(
              data['latest_snippet']!, _latestSnippetMeta));
    }
    if (data.containsKey('folder')) {
      context.handle(_folderMeta,
          folder.isAcceptableOrUnknown(data['folder']!, _folderMeta));
    } else if (isInserting) {
      context.missing(_folderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_accessed')) {
      context.handle(
          _lastAccessedMeta,
          lastAccessed.isAcceptableOrUnknown(
              data['last_accessed']!, _lastAccessedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConversationData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      participants: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}participants'])!,
      messageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}message_count'])!,
      lastMessageDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_message_date'])!,
      hasUnreadMessages: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}has_unread_messages'])!,
      hasStarredMessages: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}has_starred_messages'])!,
      hasImportantMessages: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}has_important_messages'])!,
      latestSnippet: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}latest_snippet']),
      folder: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastAccessed: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed'])!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class ConversationData extends DataClass
    implements Insertable<ConversationData> {
  final String id;
  final String accountId;
  final String subject;
  final String participants;
  final int messageCount;
  final DateTime lastMessageDate;
  final bool hasUnreadMessages;
  final bool hasStarredMessages;
  final bool hasImportantMessages;
  final String? latestSnippet;
  final String folder;
  final DateTime createdAt;
  final DateTime lastAccessed;
  const ConversationData(
      {required this.id,
      required this.accountId,
      required this.subject,
      required this.participants,
      required this.messageCount,
      required this.lastMessageDate,
      required this.hasUnreadMessages,
      required this.hasStarredMessages,
      required this.hasImportantMessages,
      this.latestSnippet,
      required this.folder,
      required this.createdAt,
      required this.lastAccessed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['subject'] = Variable<String>(subject);
    map['participants'] = Variable<String>(participants);
    map['message_count'] = Variable<int>(messageCount);
    map['last_message_date'] = Variable<DateTime>(lastMessageDate);
    map['has_unread_messages'] = Variable<bool>(hasUnreadMessages);
    map['has_starred_messages'] = Variable<bool>(hasStarredMessages);
    map['has_important_messages'] = Variable<bool>(hasImportantMessages);
    if (!nullToAbsent || latestSnippet != null) {
      map['latest_snippet'] = Variable<String>(latestSnippet);
    }
    map['folder'] = Variable<String>(folder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_accessed'] = Variable<DateTime>(lastAccessed);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      subject: Value(subject),
      participants: Value(participants),
      messageCount: Value(messageCount),
      lastMessageDate: Value(lastMessageDate),
      hasUnreadMessages: Value(hasUnreadMessages),
      hasStarredMessages: Value(hasStarredMessages),
      hasImportantMessages: Value(hasImportantMessages),
      latestSnippet: latestSnippet == null && nullToAbsent
          ? const Value.absent()
          : Value(latestSnippet),
      folder: Value(folder),
      createdAt: Value(createdAt),
      lastAccessed: Value(lastAccessed),
    );
  }

  factory ConversationData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationData(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      subject: serializer.fromJson<String>(json['subject']),
      participants: serializer.fromJson<String>(json['participants']),
      messageCount: serializer.fromJson<int>(json['messageCount']),
      lastMessageDate: serializer.fromJson<DateTime>(json['lastMessageDate']),
      hasUnreadMessages: serializer.fromJson<bool>(json['hasUnreadMessages']),
      hasStarredMessages: serializer.fromJson<bool>(json['hasStarredMessages']),
      hasImportantMessages:
          serializer.fromJson<bool>(json['hasImportantMessages']),
      latestSnippet: serializer.fromJson<String?>(json['latestSnippet']),
      folder: serializer.fromJson<String>(json['folder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAccessed: serializer.fromJson<DateTime>(json['lastAccessed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'subject': serializer.toJson<String>(subject),
      'participants': serializer.toJson<String>(participants),
      'messageCount': serializer.toJson<int>(messageCount),
      'lastMessageDate': serializer.toJson<DateTime>(lastMessageDate),
      'hasUnreadMessages': serializer.toJson<bool>(hasUnreadMessages),
      'hasStarredMessages': serializer.toJson<bool>(hasStarredMessages),
      'hasImportantMessages': serializer.toJson<bool>(hasImportantMessages),
      'latestSnippet': serializer.toJson<String?>(latestSnippet),
      'folder': serializer.toJson<String>(folder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAccessed': serializer.toJson<DateTime>(lastAccessed),
    };
  }

  ConversationData copyWith(
          {String? id,
          String? accountId,
          String? subject,
          String? participants,
          int? messageCount,
          DateTime? lastMessageDate,
          bool? hasUnreadMessages,
          bool? hasStarredMessages,
          bool? hasImportantMessages,
          Value<String?> latestSnippet = const Value.absent(),
          String? folder,
          DateTime? createdAt,
          DateTime? lastAccessed}) =>
      ConversationData(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        subject: subject ?? this.subject,
        participants: participants ?? this.participants,
        messageCount: messageCount ?? this.messageCount,
        lastMessageDate: lastMessageDate ?? this.lastMessageDate,
        hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
        hasStarredMessages: hasStarredMessages ?? this.hasStarredMessages,
        hasImportantMessages: hasImportantMessages ?? this.hasImportantMessages,
        latestSnippet:
            latestSnippet.present ? latestSnippet.value : this.latestSnippet,
        folder: folder ?? this.folder,
        createdAt: createdAt ?? this.createdAt,
        lastAccessed: lastAccessed ?? this.lastAccessed,
      );
  ConversationData copyWithCompanion(ConversationsCompanion data) {
    return ConversationData(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      subject: data.subject.present ? data.subject.value : this.subject,
      participants: data.participants.present
          ? data.participants.value
          : this.participants,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      lastMessageDate: data.lastMessageDate.present
          ? data.lastMessageDate.value
          : this.lastMessageDate,
      hasUnreadMessages: data.hasUnreadMessages.present
          ? data.hasUnreadMessages.value
          : this.hasUnreadMessages,
      hasStarredMessages: data.hasStarredMessages.present
          ? data.hasStarredMessages.value
          : this.hasStarredMessages,
      hasImportantMessages: data.hasImportantMessages.present
          ? data.hasImportantMessages.value
          : this.hasImportantMessages,
      latestSnippet: data.latestSnippet.present
          ? data.latestSnippet.value
          : this.latestSnippet,
      folder: data.folder.present ? data.folder.value : this.folder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAccessed: data.lastAccessed.present
          ? data.lastAccessed.value
          : this.lastAccessed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationData(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('subject: $subject, ')
          ..write('participants: $participants, ')
          ..write('messageCount: $messageCount, ')
          ..write('lastMessageDate: $lastMessageDate, ')
          ..write('hasUnreadMessages: $hasUnreadMessages, ')
          ..write('hasStarredMessages: $hasStarredMessages, ')
          ..write('hasImportantMessages: $hasImportantMessages, ')
          ..write('latestSnippet: $latestSnippet, ')
          ..write('folder: $folder, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessed: $lastAccessed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      accountId,
      subject,
      participants,
      messageCount,
      lastMessageDate,
      hasUnreadMessages,
      hasStarredMessages,
      hasImportantMessages,
      latestSnippet,
      folder,
      createdAt,
      lastAccessed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationData &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.subject == this.subject &&
          other.participants == this.participants &&
          other.messageCount == this.messageCount &&
          other.lastMessageDate == this.lastMessageDate &&
          other.hasUnreadMessages == this.hasUnreadMessages &&
          other.hasStarredMessages == this.hasStarredMessages &&
          other.hasImportantMessages == this.hasImportantMessages &&
          other.latestSnippet == this.latestSnippet &&
          other.folder == this.folder &&
          other.createdAt == this.createdAt &&
          other.lastAccessed == this.lastAccessed);
}

class ConversationsCompanion extends UpdateCompanion<ConversationData> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> subject;
  final Value<String> participants;
  final Value<int> messageCount;
  final Value<DateTime> lastMessageDate;
  final Value<bool> hasUnreadMessages;
  final Value<bool> hasStarredMessages;
  final Value<bool> hasImportantMessages;
  final Value<String?> latestSnippet;
  final Value<String> folder;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastAccessed;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.subject = const Value.absent(),
    this.participants = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.lastMessageDate = const Value.absent(),
    this.hasUnreadMessages = const Value.absent(),
    this.hasStarredMessages = const Value.absent(),
    this.hasImportantMessages = const Value.absent(),
    this.latestSnippet = const Value.absent(),
    this.folder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    required String accountId,
    required String subject,
    required String participants,
    this.messageCount = const Value.absent(),
    required DateTime lastMessageDate,
    this.hasUnreadMessages = const Value.absent(),
    this.hasStarredMessages = const Value.absent(),
    this.hasImportantMessages = const Value.absent(),
    this.latestSnippet = const Value.absent(),
    required String folder,
    this.createdAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        accountId = Value(accountId),
        subject = Value(subject),
        participants = Value(participants),
        lastMessageDate = Value(lastMessageDate),
        folder = Value(folder);
  static Insertable<ConversationData> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? subject,
    Expression<String>? participants,
    Expression<int>? messageCount,
    Expression<DateTime>? lastMessageDate,
    Expression<bool>? hasUnreadMessages,
    Expression<bool>? hasStarredMessages,
    Expression<bool>? hasImportantMessages,
    Expression<String>? latestSnippet,
    Expression<String>? folder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAccessed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (subject != null) 'subject': subject,
      if (participants != null) 'participants': participants,
      if (messageCount != null) 'message_count': messageCount,
      if (lastMessageDate != null) 'last_message_date': lastMessageDate,
      if (hasUnreadMessages != null) 'has_unread_messages': hasUnreadMessages,
      if (hasStarredMessages != null)
        'has_starred_messages': hasStarredMessages,
      if (hasImportantMessages != null)
        'has_important_messages': hasImportantMessages,
      if (latestSnippet != null) 'latest_snippet': latestSnippet,
      if (folder != null) 'folder': folder,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAccessed != null) 'last_accessed': lastAccessed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? accountId,
      Value<String>? subject,
      Value<String>? participants,
      Value<int>? messageCount,
      Value<DateTime>? lastMessageDate,
      Value<bool>? hasUnreadMessages,
      Value<bool>? hasStarredMessages,
      Value<bool>? hasImportantMessages,
      Value<String?>? latestSnippet,
      Value<String>? folder,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastAccessed,
      Value<int>? rowid}) {
    return ConversationsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      subject: subject ?? this.subject,
      participants: participants ?? this.participants,
      messageCount: messageCount ?? this.messageCount,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      hasStarredMessages: hasStarredMessages ?? this.hasStarredMessages,
      hasImportantMessages: hasImportantMessages ?? this.hasImportantMessages,
      latestSnippet: latestSnippet ?? this.latestSnippet,
      folder: folder ?? this.folder,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (participants.present) {
      map['participants'] = Variable<String>(participants.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (lastMessageDate.present) {
      map['last_message_date'] = Variable<DateTime>(lastMessageDate.value);
    }
    if (hasUnreadMessages.present) {
      map['has_unread_messages'] = Variable<bool>(hasUnreadMessages.value);
    }
    if (hasStarredMessages.present) {
      map['has_starred_messages'] = Variable<bool>(hasStarredMessages.value);
    }
    if (hasImportantMessages.present) {
      map['has_important_messages'] =
          Variable<bool>(hasImportantMessages.value);
    }
    if (latestSnippet.present) {
      map['latest_snippet'] = Variable<String>(latestSnippet.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAccessed.present) {
      map['last_accessed'] = Variable<DateTime>(lastAccessed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('subject: $subject, ')
          ..write('participants: $participants, ')
          ..write('messageCount: $messageCount, ')
          ..write('lastMessageDate: $lastMessageDate, ')
          ..write('hasUnreadMessages: $hasUnreadMessages, ')
          ..write('hasStarredMessages: $hasStarredMessages, ')
          ..write('hasImportantMessages: $hasImportantMessages, ')
          ..write('latestSnippet: $latestSnippet, ')
          ..write('folder: $folder, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabelsTable extends Labels with TableInfo<$LabelsTable, LabelData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isVisibleMeta =
      const VerificationMeta('isVisible');
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
      'is_visible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_visible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  @override
  List<GeneratedColumn> get $columns =>
      [id, accountId, name, type, color, isVisible, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'labels';
  @override
  VerificationContext validateIntegrity(Insertable<LabelData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('is_visible')) {
      context.handle(_isVisibleMeta,
          isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, accountId};
  @override
  LabelData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LabelData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color']),
      isVisible: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_visible'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LabelsTable createAlias(String alias) {
    return $LabelsTable(attachedDatabase, alias);
  }
}

class LabelData extends DataClass implements Insertable<LabelData> {
  final String id;
  final String accountId;
  final String name;
  final String type;
  final int? color;
  final bool isVisible;
  final DateTime createdAt;
  const LabelData(
      {required this.id,
      required this.accountId,
      required this.name,
      required this.type,
      this.color,
      required this.isVisible,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['is_visible'] = Variable<bool>(isVisible);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LabelsCompanion toCompanion(bool nullToAbsent) {
    return LabelsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      name: Value(name),
      type: Value(type),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      isVisible: Value(isVisible),
      createdAt: Value(createdAt),
    );
  }

  factory LabelData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LabelData(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      color: serializer.fromJson<int?>(json['color']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'color': serializer.toJson<int?>(color),
      'isVisible': serializer.toJson<bool>(isVisible),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LabelData copyWith(
          {String? id,
          String? accountId,
          String? name,
          String? type,
          Value<int?> color = const Value.absent(),
          bool? isVisible,
          DateTime? createdAt}) =>
      LabelData(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        name: name ?? this.name,
        type: type ?? this.type,
        color: color.present ? color.value : this.color,
        isVisible: isVisible ?? this.isVisible,
        createdAt: createdAt ?? this.createdAt,
      );
  LabelData copyWithCompanion(LabelsCompanion data) {
    return LabelData(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      color: data.color.present ? data.color.value : this.color,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LabelData(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('color: $color, ')
          ..write('isVisible: $isVisible, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, accountId, name, type, color, isVisible, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabelData &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.type == this.type &&
          other.color == this.color &&
          other.isVisible == this.isVisible &&
          other.createdAt == this.createdAt);
}

class LabelsCompanion extends UpdateCompanion<LabelData> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> name;
  final Value<String> type;
  final Value<int?> color;
  final Value<bool> isVisible;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LabelsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.color = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LabelsCompanion.insert({
    required String id,
    required String accountId,
    required String name,
    required String type,
    this.color = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        accountId = Value(accountId),
        name = Value(name),
        type = Value(type);
  static Insertable<LabelData> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? color,
    Expression<bool>? isVisible,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (color != null) 'color': color,
      if (isVisible != null) 'is_visible': isVisible,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LabelsCompanion copyWith(
      {Value<String>? id,
      Value<String>? accountId,
      Value<String>? name,
      Value<String>? type,
      Value<int?>? color,
      Value<bool>? isVisible,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LabelsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isVisible.present) {
      map['is_visible'] = Variable<bool>(isVisible.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabelsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('color: $color, ')
          ..write('isVisible: $isVisible, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchIndexTable extends SearchIndex
    with TableInfo<$SearchIndexTable, SearchIndexData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
      'sender', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recipientsMeta =
      const VerificationMeta('recipients');
  @override
  late final GeneratedColumn<String> recipients = GeneratedColumn<String>(
      'recipients', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
      'folder', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelsMeta = const VerificationMeta('labels');
  @override
  late final GeneratedColumn<String> labels = GeneratedColumn<String>(
      'labels', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        messageId,
        accountId,
        content,
        subject,
        sender,
        recipients,
        folder,
        labels,
        date
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_index';
  @override
  VerificationContext validateIntegrity(Insertable<SearchIndexData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(_senderMeta,
          sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('recipients')) {
      context.handle(
          _recipientsMeta,
          recipients.isAcceptableOrUnknown(
              data['recipients']!, _recipientsMeta));
    } else if (isInserting) {
      context.missing(_recipientsMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(_folderMeta,
          folder.isAcceptableOrUnknown(data['folder']!, _folderMeta));
    } else if (isInserting) {
      context.missing(_folderMeta);
    }
    if (data.containsKey('labels')) {
      context.handle(_labelsMeta,
          labels.isAcceptableOrUnknown(data['labels']!, _labelsMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, accountId};
  @override
  SearchIndexData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchIndexData(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender'])!,
      recipients: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipients'])!,
      folder: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder'])!,
      labels: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}labels']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
    );
  }

  @override
  $SearchIndexTable createAlias(String alias) {
    return $SearchIndexTable(attachedDatabase, alias);
  }
}

class SearchIndexData extends DataClass implements Insertable<SearchIndexData> {
  final String messageId;
  final String accountId;
  final String content;
  final String subject;
  final String sender;
  final String recipients;
  final String folder;
  final String? labels;
  final DateTime date;
  const SearchIndexData(
      {required this.messageId,
      required this.accountId,
      required this.content,
      required this.subject,
      required this.sender,
      required this.recipients,
      required this.folder,
      this.labels,
      required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['account_id'] = Variable<String>(accountId);
    map['content'] = Variable<String>(content);
    map['subject'] = Variable<String>(subject);
    map['sender'] = Variable<String>(sender);
    map['recipients'] = Variable<String>(recipients);
    map['folder'] = Variable<String>(folder);
    if (!nullToAbsent || labels != null) {
      map['labels'] = Variable<String>(labels);
    }
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  SearchIndexCompanion toCompanion(bool nullToAbsent) {
    return SearchIndexCompanion(
      messageId: Value(messageId),
      accountId: Value(accountId),
      content: Value(content),
      subject: Value(subject),
      sender: Value(sender),
      recipients: Value(recipients),
      folder: Value(folder),
      labels:
          labels == null && nullToAbsent ? const Value.absent() : Value(labels),
      date: Value(date),
    );
  }

  factory SearchIndexData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchIndexData(
      messageId: serializer.fromJson<String>(json['messageId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      content: serializer.fromJson<String>(json['content']),
      subject: serializer.fromJson<String>(json['subject']),
      sender: serializer.fromJson<String>(json['sender']),
      recipients: serializer.fromJson<String>(json['recipients']),
      folder: serializer.fromJson<String>(json['folder']),
      labels: serializer.fromJson<String?>(json['labels']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'accountId': serializer.toJson<String>(accountId),
      'content': serializer.toJson<String>(content),
      'subject': serializer.toJson<String>(subject),
      'sender': serializer.toJson<String>(sender),
      'recipients': serializer.toJson<String>(recipients),
      'folder': serializer.toJson<String>(folder),
      'labels': serializer.toJson<String?>(labels),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  SearchIndexData copyWith(
          {String? messageId,
          String? accountId,
          String? content,
          String? subject,
          String? sender,
          String? recipients,
          String? folder,
          Value<String?> labels = const Value.absent(),
          DateTime? date}) =>
      SearchIndexData(
        messageId: messageId ?? this.messageId,
        accountId: accountId ?? this.accountId,
        content: content ?? this.content,
        subject: subject ?? this.subject,
        sender: sender ?? this.sender,
        recipients: recipients ?? this.recipients,
        folder: folder ?? this.folder,
        labels: labels.present ? labels.value : this.labels,
        date: date ?? this.date,
      );
  SearchIndexData copyWithCompanion(SearchIndexCompanion data) {
    return SearchIndexData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      content: data.content.present ? data.content.value : this.content,
      subject: data.subject.present ? data.subject.value : this.subject,
      sender: data.sender.present ? data.sender.value : this.sender,
      recipients:
          data.recipients.present ? data.recipients.value : this.recipients,
      folder: data.folder.present ? data.folder.value : this.folder,
      labels: data.labels.present ? data.labels.value : this.labels,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexData(')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('content: $content, ')
          ..write('subject: $subject, ')
          ..write('sender: $sender, ')
          ..write('recipients: $recipients, ')
          ..write('folder: $folder, ')
          ..write('labels: $labels, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, accountId, content, subject,
      sender, recipients, folder, labels, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchIndexData &&
          other.messageId == this.messageId &&
          other.accountId == this.accountId &&
          other.content == this.content &&
          other.subject == this.subject &&
          other.sender == this.sender &&
          other.recipients == this.recipients &&
          other.folder == this.folder &&
          other.labels == this.labels &&
          other.date == this.date);
}

class SearchIndexCompanion extends UpdateCompanion<SearchIndexData> {
  final Value<String> messageId;
  final Value<String> accountId;
  final Value<String> content;
  final Value<String> subject;
  final Value<String> sender;
  final Value<String> recipients;
  final Value<String> folder;
  final Value<String?> labels;
  final Value<DateTime> date;
  final Value<int> rowid;
  const SearchIndexCompanion({
    this.messageId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.content = const Value.absent(),
    this.subject = const Value.absent(),
    this.sender = const Value.absent(),
    this.recipients = const Value.absent(),
    this.folder = const Value.absent(),
    this.labels = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchIndexCompanion.insert({
    required String messageId,
    required String accountId,
    required String content,
    required String subject,
    required String sender,
    required String recipients,
    required String folder,
    this.labels = const Value.absent(),
    required DateTime date,
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        accountId = Value(accountId),
        content = Value(content),
        subject = Value(subject),
        sender = Value(sender),
        recipients = Value(recipients),
        folder = Value(folder),
        date = Value(date);
  static Insertable<SearchIndexData> custom({
    Expression<String>? messageId,
    Expression<String>? accountId,
    Expression<String>? content,
    Expression<String>? subject,
    Expression<String>? sender,
    Expression<String>? recipients,
    Expression<String>? folder,
    Expression<String>? labels,
    Expression<DateTime>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (accountId != null) 'account_id': accountId,
      if (content != null) 'content': content,
      if (subject != null) 'subject': subject,
      if (sender != null) 'sender': sender,
      if (recipients != null) 'recipients': recipients,
      if (folder != null) 'folder': folder,
      if (labels != null) 'labels': labels,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchIndexCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? accountId,
      Value<String>? content,
      Value<String>? subject,
      Value<String>? sender,
      Value<String>? recipients,
      Value<String>? folder,
      Value<String?>? labels,
      Value<DateTime>? date,
      Value<int>? rowid}) {
    return SearchIndexCompanion(
      messageId: messageId ?? this.messageId,
      accountId: accountId ?? this.accountId,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      sender: sender ?? this.sender,
      recipients: recipients ?? this.recipients,
      folder: folder ?? this.folder,
      labels: labels ?? this.labels,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (recipients.present) {
      map['recipients'] = Variable<String>(recipients.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (labels.present) {
      map['labels'] = Variable<String>(labels.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexCompanion(')
          ..write('messageId: $messageId, ')
          ..write('accountId: $accountId, ')
          ..write('content: $content, ')
          ..write('subject: $subject, ')
          ..write('sender: $sender, ')
          ..write('recipients: $recipients, ')
          ..write('folder: $folder, ')
          ..write('labels: $labels, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
      'folder', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _historyIdMeta =
      const VerificationMeta('historyId');
  @override
  late final GeneratedColumn<String> historyId = GeneratedColumn<String>(
      'history_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextPageTokenMeta =
      const VerificationMeta('nextPageToken');
  @override
  late final GeneratedColumn<String> nextPageToken = GeneratedColumn<String>(
      'next_page_token', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastFullSyncMeta =
      const VerificationMeta('lastFullSync');
  @override
  late final GeneratedColumn<DateTime> lastFullSync = GeneratedColumn<DateTime>(
      'last_full_sync', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastIncrementalSyncMeta =
      const VerificationMeta('lastIncrementalSync');
  @override
  late final GeneratedColumn<DateTime> lastIncrementalSync =
      GeneratedColumn<DateTime>('last_incremental_sync', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isSyncingMeta =
      const VerificationMeta('isSyncing');
  @override
  late final GeneratedColumn<bool> isSyncing = GeneratedColumn<bool>(
      'is_syncing', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_syncing" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncErrorMeta =
      const VerificationMeta('syncError');
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
      'sync_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        accountId,
        folder,
        historyId,
        nextPageToken,
        lastFullSync,
        lastIncrementalSync,
        isSyncing,
        syncError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(_folderMeta,
          folder.isAcceptableOrUnknown(data['folder']!, _folderMeta));
    } else if (isInserting) {
      context.missing(_folderMeta);
    }
    if (data.containsKey('history_id')) {
      context.handle(_historyIdMeta,
          historyId.isAcceptableOrUnknown(data['history_id']!, _historyIdMeta));
    }
    if (data.containsKey('next_page_token')) {
      context.handle(
          _nextPageTokenMeta,
          nextPageToken.isAcceptableOrUnknown(
              data['next_page_token']!, _nextPageTokenMeta));
    }
    if (data.containsKey('last_full_sync')) {
      context.handle(
          _lastFullSyncMeta,
          lastFullSync.isAcceptableOrUnknown(
              data['last_full_sync']!, _lastFullSyncMeta));
    }
    if (data.containsKey('last_incremental_sync')) {
      context.handle(
          _lastIncrementalSyncMeta,
          lastIncrementalSync.isAcceptableOrUnknown(
              data['last_incremental_sync']!, _lastIncrementalSyncMeta));
    }
    if (data.containsKey('is_syncing')) {
      context.handle(_isSyncingMeta,
          isSyncing.isAcceptableOrUnknown(data['is_syncing']!, _isSyncingMeta));
    }
    if (data.containsKey('sync_error')) {
      context.handle(_syncErrorMeta,
          syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, folder};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      folder: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder'])!,
      historyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}history_id']),
      nextPageToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}next_page_token']),
      lastFullSync: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_full_sync']),
      lastIncrementalSync: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_incremental_sync']),
      isSyncing: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_syncing'])!,
      syncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_error']),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String accountId;
  final String folder;
  final String? historyId;
  final String? nextPageToken;
  final DateTime? lastFullSync;
  final DateTime? lastIncrementalSync;
  final bool isSyncing;
  final String? syncError;
  const SyncStateData(
      {required this.accountId,
      required this.folder,
      this.historyId,
      this.nextPageToken,
      this.lastFullSync,
      this.lastIncrementalSync,
      required this.isSyncing,
      this.syncError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['folder'] = Variable<String>(folder);
    if (!nullToAbsent || historyId != null) {
      map['history_id'] = Variable<String>(historyId);
    }
    if (!nullToAbsent || nextPageToken != null) {
      map['next_page_token'] = Variable<String>(nextPageToken);
    }
    if (!nullToAbsent || lastFullSync != null) {
      map['last_full_sync'] = Variable<DateTime>(lastFullSync);
    }
    if (!nullToAbsent || lastIncrementalSync != null) {
      map['last_incremental_sync'] = Variable<DateTime>(lastIncrementalSync);
    }
    map['is_syncing'] = Variable<bool>(isSyncing);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      accountId: Value(accountId),
      folder: Value(folder),
      historyId: historyId == null && nullToAbsent
          ? const Value.absent()
          : Value(historyId),
      nextPageToken: nextPageToken == null && nullToAbsent
          ? const Value.absent()
          : Value(nextPageToken),
      lastFullSync: lastFullSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFullSync),
      lastIncrementalSync: lastIncrementalSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastIncrementalSync),
      isSyncing: Value(isSyncing),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      accountId: serializer.fromJson<String>(json['accountId']),
      folder: serializer.fromJson<String>(json['folder']),
      historyId: serializer.fromJson<String?>(json['historyId']),
      nextPageToken: serializer.fromJson<String?>(json['nextPageToken']),
      lastFullSync: serializer.fromJson<DateTime?>(json['lastFullSync']),
      lastIncrementalSync:
          serializer.fromJson<DateTime?>(json['lastIncrementalSync']),
      isSyncing: serializer.fromJson<bool>(json['isSyncing']),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'folder': serializer.toJson<String>(folder),
      'historyId': serializer.toJson<String?>(historyId),
      'nextPageToken': serializer.toJson<String?>(nextPageToken),
      'lastFullSync': serializer.toJson<DateTime?>(lastFullSync),
      'lastIncrementalSync': serializer.toJson<DateTime?>(lastIncrementalSync),
      'isSyncing': serializer.toJson<bool>(isSyncing),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  SyncStateData copyWith(
          {String? accountId,
          String? folder,
          Value<String?> historyId = const Value.absent(),
          Value<String?> nextPageToken = const Value.absent(),
          Value<DateTime?> lastFullSync = const Value.absent(),
          Value<DateTime?> lastIncrementalSync = const Value.absent(),
          bool? isSyncing,
          Value<String?> syncError = const Value.absent()}) =>
      SyncStateData(
        accountId: accountId ?? this.accountId,
        folder: folder ?? this.folder,
        historyId: historyId.present ? historyId.value : this.historyId,
        nextPageToken:
            nextPageToken.present ? nextPageToken.value : this.nextPageToken,
        lastFullSync:
            lastFullSync.present ? lastFullSync.value : this.lastFullSync,
        lastIncrementalSync: lastIncrementalSync.present
            ? lastIncrementalSync.value
            : this.lastIncrementalSync,
        isSyncing: isSyncing ?? this.isSyncing,
        syncError: syncError.present ? syncError.value : this.syncError,
      );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      folder: data.folder.present ? data.folder.value : this.folder,
      historyId: data.historyId.present ? data.historyId.value : this.historyId,
      nextPageToken: data.nextPageToken.present
          ? data.nextPageToken.value
          : this.nextPageToken,
      lastFullSync: data.lastFullSync.present
          ? data.lastFullSync.value
          : this.lastFullSync,
      lastIncrementalSync: data.lastIncrementalSync.present
          ? data.lastIncrementalSync.value
          : this.lastIncrementalSync,
      isSyncing: data.isSyncing.present ? data.isSyncing.value : this.isSyncing,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('accountId: $accountId, ')
          ..write('folder: $folder, ')
          ..write('historyId: $historyId, ')
          ..write('nextPageToken: $nextPageToken, ')
          ..write('lastFullSync: $lastFullSync, ')
          ..write('lastIncrementalSync: $lastIncrementalSync, ')
          ..write('isSyncing: $isSyncing, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, folder, historyId, nextPageToken,
      lastFullSync, lastIncrementalSync, isSyncing, syncError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.accountId == this.accountId &&
          other.folder == this.folder &&
          other.historyId == this.historyId &&
          other.nextPageToken == this.nextPageToken &&
          other.lastFullSync == this.lastFullSync &&
          other.lastIncrementalSync == this.lastIncrementalSync &&
          other.isSyncing == this.isSyncing &&
          other.syncError == this.syncError);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> accountId;
  final Value<String> folder;
  final Value<String?> historyId;
  final Value<String?> nextPageToken;
  final Value<DateTime?> lastFullSync;
  final Value<DateTime?> lastIncrementalSync;
  final Value<bool> isSyncing;
  final Value<String?> syncError;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.accountId = const Value.absent(),
    this.folder = const Value.absent(),
    this.historyId = const Value.absent(),
    this.nextPageToken = const Value.absent(),
    this.lastFullSync = const Value.absent(),
    this.lastIncrementalSync = const Value.absent(),
    this.isSyncing = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String accountId,
    required String folder,
    this.historyId = const Value.absent(),
    this.nextPageToken = const Value.absent(),
    this.lastFullSync = const Value.absent(),
    this.lastIncrementalSync = const Value.absent(),
    this.isSyncing = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : accountId = Value(accountId),
        folder = Value(folder);
  static Insertable<SyncStateData> custom({
    Expression<String>? accountId,
    Expression<String>? folder,
    Expression<String>? historyId,
    Expression<String>? nextPageToken,
    Expression<DateTime>? lastFullSync,
    Expression<DateTime>? lastIncrementalSync,
    Expression<bool>? isSyncing,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (folder != null) 'folder': folder,
      if (historyId != null) 'history_id': historyId,
      if (nextPageToken != null) 'next_page_token': nextPageToken,
      if (lastFullSync != null) 'last_full_sync': lastFullSync,
      if (lastIncrementalSync != null)
        'last_incremental_sync': lastIncrementalSync,
      if (isSyncing != null) 'is_syncing': isSyncing,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith(
      {Value<String>? accountId,
      Value<String>? folder,
      Value<String?>? historyId,
      Value<String?>? nextPageToken,
      Value<DateTime?>? lastFullSync,
      Value<DateTime?>? lastIncrementalSync,
      Value<bool>? isSyncing,
      Value<String?>? syncError,
      Value<int>? rowid}) {
    return SyncStateCompanion(
      accountId: accountId ?? this.accountId,
      folder: folder ?? this.folder,
      historyId: historyId ?? this.historyId,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      lastFullSync: lastFullSync ?? this.lastFullSync,
      lastIncrementalSync: lastIncrementalSync ?? this.lastIncrementalSync,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (historyId.present) {
      map['history_id'] = Variable<String>(historyId.value);
    }
    if (nextPageToken.present) {
      map['next_page_token'] = Variable<String>(nextPageToken.value);
    }
    if (lastFullSync.present) {
      map['last_full_sync'] = Variable<DateTime>(lastFullSync.value);
    }
    if (lastIncrementalSync.present) {
      map['last_incremental_sync'] =
          Variable<DateTime>(lastIncrementalSync.value);
    }
    if (isSyncing.present) {
      map['is_syncing'] = Variable<bool>(isSyncing.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('accountId: $accountId, ')
          ..write('folder: $folder, ')
          ..write('historyId: $historyId, ')
          ..write('nextPageToken: $nextPageToken, ')
          ..write('lastFullSync: $lastFullSync, ')
          ..write('lastIncrementalSync: $lastIncrementalSync, ')
          ..write('isSyncing: $isSyncing, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheStatsTable extends CacheStats
    with TableInfo<$CacheStatsTable, CacheStatsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailCountMeta =
      const VerificationMeta('emailCount');
  @override
  late final GeneratedColumn<int> emailCount = GeneratedColumn<int>(
      'email_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _attachmentCountMeta =
      const VerificationMeta('attachmentCount');
  @override
  late final GeneratedColumn<int> attachmentCount = GeneratedColumn<int>(
      'attachment_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalSizeBytesMeta =
      const VerificationMeta('totalSizeBytes');
  @override
  late final GeneratedColumn<int> totalSizeBytes = GeneratedColumn<int>(
      'total_size_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _oldestEmailMeta =
      const VerificationMeta('oldestEmail');
  @override
  late final GeneratedColumn<DateTime> oldestEmail = GeneratedColumn<DateTime>(
      'oldest_email', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _newestEmailMeta =
      const VerificationMeta('newestEmail');
  @override
  late final GeneratedColumn<DateTime> newestEmail = GeneratedColumn<DateTime>(
      'newest_email', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastCleanupMeta =
      const VerificationMeta('lastCleanup');
  @override
  late final GeneratedColumn<DateTime> lastCleanup = GeneratedColumn<DateTime>(
      'last_cleanup', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        accountId,
        emailCount,
        attachmentCount,
        totalSizeBytes,
        oldestEmail,
        newestEmail,
        lastCleanup
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_stats';
  @override
  VerificationContext validateIntegrity(Insertable<CacheStatsData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('email_count')) {
      context.handle(
          _emailCountMeta,
          emailCount.isAcceptableOrUnknown(
              data['email_count']!, _emailCountMeta));
    }
    if (data.containsKey('attachment_count')) {
      context.handle(
          _attachmentCountMeta,
          attachmentCount.isAcceptableOrUnknown(
              data['attachment_count']!, _attachmentCountMeta));
    }
    if (data.containsKey('total_size_bytes')) {
      context.handle(
          _totalSizeBytesMeta,
          totalSizeBytes.isAcceptableOrUnknown(
              data['total_size_bytes']!, _totalSizeBytesMeta));
    }
    if (data.containsKey('oldest_email')) {
      context.handle(
          _oldestEmailMeta,
          oldestEmail.isAcceptableOrUnknown(
              data['oldest_email']!, _oldestEmailMeta));
    }
    if (data.containsKey('newest_email')) {
      context.handle(
          _newestEmailMeta,
          newestEmail.isAcceptableOrUnknown(
              data['newest_email']!, _newestEmailMeta));
    }
    if (data.containsKey('last_cleanup')) {
      context.handle(
          _lastCleanupMeta,
          lastCleanup.isAcceptableOrUnknown(
              data['last_cleanup']!, _lastCleanupMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  CacheStatsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheStatsData(
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      emailCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}email_count'])!,
      attachmentCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attachment_count'])!,
      totalSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_size_bytes'])!,
      oldestEmail: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}oldest_email']),
      newestEmail: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}newest_email']),
      lastCleanup: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_cleanup']),
    );
  }

  @override
  $CacheStatsTable createAlias(String alias) {
    return $CacheStatsTable(attachedDatabase, alias);
  }
}

class CacheStatsData extends DataClass implements Insertable<CacheStatsData> {
  final String accountId;
  final int emailCount;
  final int attachmentCount;
  final int totalSizeBytes;
  final DateTime? oldestEmail;
  final DateTime? newestEmail;
  final DateTime? lastCleanup;
  const CacheStatsData(
      {required this.accountId,
      required this.emailCount,
      required this.attachmentCount,
      required this.totalSizeBytes,
      this.oldestEmail,
      this.newestEmail,
      this.lastCleanup});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['email_count'] = Variable<int>(emailCount);
    map['attachment_count'] = Variable<int>(attachmentCount);
    map['total_size_bytes'] = Variable<int>(totalSizeBytes);
    if (!nullToAbsent || oldestEmail != null) {
      map['oldest_email'] = Variable<DateTime>(oldestEmail);
    }
    if (!nullToAbsent || newestEmail != null) {
      map['newest_email'] = Variable<DateTime>(newestEmail);
    }
    if (!nullToAbsent || lastCleanup != null) {
      map['last_cleanup'] = Variable<DateTime>(lastCleanup);
    }
    return map;
  }

  CacheStatsCompanion toCompanion(bool nullToAbsent) {
    return CacheStatsCompanion(
      accountId: Value(accountId),
      emailCount: Value(emailCount),
      attachmentCount: Value(attachmentCount),
      totalSizeBytes: Value(totalSizeBytes),
      oldestEmail: oldestEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(oldestEmail),
      newestEmail: newestEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(newestEmail),
      lastCleanup: lastCleanup == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCleanup),
    );
  }

  factory CacheStatsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheStatsData(
      accountId: serializer.fromJson<String>(json['accountId']),
      emailCount: serializer.fromJson<int>(json['emailCount']),
      attachmentCount: serializer.fromJson<int>(json['attachmentCount']),
      totalSizeBytes: serializer.fromJson<int>(json['totalSizeBytes']),
      oldestEmail: serializer.fromJson<DateTime?>(json['oldestEmail']),
      newestEmail: serializer.fromJson<DateTime?>(json['newestEmail']),
      lastCleanup: serializer.fromJson<DateTime?>(json['lastCleanup']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'emailCount': serializer.toJson<int>(emailCount),
      'attachmentCount': serializer.toJson<int>(attachmentCount),
      'totalSizeBytes': serializer.toJson<int>(totalSizeBytes),
      'oldestEmail': serializer.toJson<DateTime?>(oldestEmail),
      'newestEmail': serializer.toJson<DateTime?>(newestEmail),
      'lastCleanup': serializer.toJson<DateTime?>(lastCleanup),
    };
  }

  CacheStatsData copyWith(
          {String? accountId,
          int? emailCount,
          int? attachmentCount,
          int? totalSizeBytes,
          Value<DateTime?> oldestEmail = const Value.absent(),
          Value<DateTime?> newestEmail = const Value.absent(),
          Value<DateTime?> lastCleanup = const Value.absent()}) =>
      CacheStatsData(
        accountId: accountId ?? this.accountId,
        emailCount: emailCount ?? this.emailCount,
        attachmentCount: attachmentCount ?? this.attachmentCount,
        totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
        oldestEmail: oldestEmail.present ? oldestEmail.value : this.oldestEmail,
        newestEmail: newestEmail.present ? newestEmail.value : this.newestEmail,
        lastCleanup: lastCleanup.present ? lastCleanup.value : this.lastCleanup,
      );
  CacheStatsData copyWithCompanion(CacheStatsCompanion data) {
    return CacheStatsData(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      emailCount:
          data.emailCount.present ? data.emailCount.value : this.emailCount,
      attachmentCount: data.attachmentCount.present
          ? data.attachmentCount.value
          : this.attachmentCount,
      totalSizeBytes: data.totalSizeBytes.present
          ? data.totalSizeBytes.value
          : this.totalSizeBytes,
      oldestEmail:
          data.oldestEmail.present ? data.oldestEmail.value : this.oldestEmail,
      newestEmail:
          data.newestEmail.present ? data.newestEmail.value : this.newestEmail,
      lastCleanup:
          data.lastCleanup.present ? data.lastCleanup.value : this.lastCleanup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheStatsData(')
          ..write('accountId: $accountId, ')
          ..write('emailCount: $emailCount, ')
          ..write('attachmentCount: $attachmentCount, ')
          ..write('totalSizeBytes: $totalSizeBytes, ')
          ..write('oldestEmail: $oldestEmail, ')
          ..write('newestEmail: $newestEmail, ')
          ..write('lastCleanup: $lastCleanup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, emailCount, attachmentCount,
      totalSizeBytes, oldestEmail, newestEmail, lastCleanup);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheStatsData &&
          other.accountId == this.accountId &&
          other.emailCount == this.emailCount &&
          other.attachmentCount == this.attachmentCount &&
          other.totalSizeBytes == this.totalSizeBytes &&
          other.oldestEmail == this.oldestEmail &&
          other.newestEmail == this.newestEmail &&
          other.lastCleanup == this.lastCleanup);
}

class CacheStatsCompanion extends UpdateCompanion<CacheStatsData> {
  final Value<String> accountId;
  final Value<int> emailCount;
  final Value<int> attachmentCount;
  final Value<int> totalSizeBytes;
  final Value<DateTime?> oldestEmail;
  final Value<DateTime?> newestEmail;
  final Value<DateTime?> lastCleanup;
  final Value<int> rowid;
  const CacheStatsCompanion({
    this.accountId = const Value.absent(),
    this.emailCount = const Value.absent(),
    this.attachmentCount = const Value.absent(),
    this.totalSizeBytes = const Value.absent(),
    this.oldestEmail = const Value.absent(),
    this.newestEmail = const Value.absent(),
    this.lastCleanup = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheStatsCompanion.insert({
    required String accountId,
    this.emailCount = const Value.absent(),
    this.attachmentCount = const Value.absent(),
    this.totalSizeBytes = const Value.absent(),
    this.oldestEmail = const Value.absent(),
    this.newestEmail = const Value.absent(),
    this.lastCleanup = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId);
  static Insertable<CacheStatsData> custom({
    Expression<String>? accountId,
    Expression<int>? emailCount,
    Expression<int>? attachmentCount,
    Expression<int>? totalSizeBytes,
    Expression<DateTime>? oldestEmail,
    Expression<DateTime>? newestEmail,
    Expression<DateTime>? lastCleanup,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (emailCount != null) 'email_count': emailCount,
      if (attachmentCount != null) 'attachment_count': attachmentCount,
      if (totalSizeBytes != null) 'total_size_bytes': totalSizeBytes,
      if (oldestEmail != null) 'oldest_email': oldestEmail,
      if (newestEmail != null) 'newest_email': newestEmail,
      if (lastCleanup != null) 'last_cleanup': lastCleanup,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheStatsCompanion copyWith(
      {Value<String>? accountId,
      Value<int>? emailCount,
      Value<int>? attachmentCount,
      Value<int>? totalSizeBytes,
      Value<DateTime?>? oldestEmail,
      Value<DateTime?>? newestEmail,
      Value<DateTime?>? lastCleanup,
      Value<int>? rowid}) {
    return CacheStatsCompanion(
      accountId: accountId ?? this.accountId,
      emailCount: emailCount ?? this.emailCount,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      oldestEmail: oldestEmail ?? this.oldestEmail,
      newestEmail: newestEmail ?? this.newestEmail,
      lastCleanup: lastCleanup ?? this.lastCleanup,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (emailCount.present) {
      map['email_count'] = Variable<int>(emailCount.value);
    }
    if (attachmentCount.present) {
      map['attachment_count'] = Variable<int>(attachmentCount.value);
    }
    if (totalSizeBytes.present) {
      map['total_size_bytes'] = Variable<int>(totalSizeBytes.value);
    }
    if (oldestEmail.present) {
      map['oldest_email'] = Variable<DateTime>(oldestEmail.value);
    }
    if (newestEmail.present) {
      map['newest_email'] = Variable<DateTime>(newestEmail.value);
    }
    if (lastCleanup.present) {
      map['last_cleanup'] = Variable<DateTime>(lastCleanup.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheStatsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('emailCount: $emailCount, ')
          ..write('attachmentCount: $attachmentCount, ')
          ..write('totalSizeBytes: $totalSizeBytes, ')
          ..write('oldestEmail: $oldestEmail, ')
          ..write('newestEmail: $newestEmail, ')
          ..write('lastCleanup: $lastCleanup, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$EmailDatabase extends GeneratedDatabase {
  _$EmailDatabase(QueryExecutor e) : super(e);
  $EmailDatabaseManager get managers => $EmailDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $EmailHeadersTable emailHeaders = $EmailHeadersTable(this);
  late final $EmailBodiesTable emailBodies = $EmailBodiesTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $LabelsTable labels = $LabelsTable(this);
  late final $SearchIndexTable searchIndex = $SearchIndexTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $CacheStatsTable cacheStats = $CacheStatsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        accounts,
        emailHeaders,
        emailBodies,
        attachments,
        conversations,
        labels,
        searchIndex,
        syncState,
        cacheStats
      ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String email,
  Value<String?> displayName,
  required String provider,
  Value<String?> accessToken,
  Value<String?> refreshToken,
  Value<String?> historyId,
  Value<DateTime?> lastSyncTime,
  Value<DateTime> createdAt,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> email,
  Value<String?> displayName,
  Value<String> provider,
  Value<String?> accessToken,
  Value<String?> refreshToken,
  Value<String?> historyId,
  Value<DateTime?> lastSyncTime,
  Value<DateTime> createdAt,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$AccountsTableFilterComposer
    extends Composer<_$EmailDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accessToken => $composableBuilder(
      column: $table.accessToken, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refreshToken => $composableBuilder(
      column: $table.refreshToken, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncTime => $composableBuilder(
      column: $table.lastSyncTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$AccountsTableOrderingComposer
    extends Composer<_$EmailDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accessToken => $composableBuilder(
      column: $table.accessToken, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refreshToken => $composableBuilder(
      column: $table.refreshToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncTime => $composableBuilder(
      column: $table.lastSyncTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$EmailDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get accessToken => $composableBuilder(
      column: $table.accessToken, builder: (column) => column);

  GeneratedColumn<String> get refreshToken => $composableBuilder(
      column: $table.refreshToken, builder: (column) => column);

  GeneratedColumn<String> get historyId =>
      $composableBuilder(column: $table.historyId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncTime => $composableBuilder(
      column: $table.lastSyncTime, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$AccountsTableTableManager extends RootTableManager<
    _$EmailDatabase,
    $AccountsTable,
    AccountData,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (AccountData, BaseReferences<_$EmailDatabase, $AccountsTable, AccountData>),
    AccountData,
    PrefetchHooks Function()> {
  $$AccountsTableTableManager(_$EmailDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<String?> accessToken = const Value.absent(),
            Value<String?> refreshToken = const Value.absent(),
            Value<String?> historyId = const Value.absent(),
            Value<DateTime?> lastSyncTime = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            email: email,
            displayName: displayName,
            provider: provider,
            accessToken: accessToken,
            refreshToken: refreshToken,
            historyId: historyId,
            lastSyncTime: lastSyncTime,
            createdAt: createdAt,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String email,
            Value<String?> displayName = const Value.absent(),
            required String provider,
            Value<String?> accessToken = const Value.absent(),
            Value<String?> refreshToken = const Value.absent(),
            Value<String?> historyId = const Value.absent(),
            Value<DateTime?> lastSyncTime = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            email: email,
            displayName: displayName,
            provider: provider,
            accessToken: accessToken,
            refreshToken: refreshToken,
            historyId: historyId,
            lastSyncTime: lastSyncTime,
            createdAt: createdAt,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$EmailDatabase,
    $AccountsTable,
    AccountData,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (AccountData, BaseReferences<_$EmailDatabase, $AccountsTable, AccountData>),
    AccountData,
    PrefetchHooks Function()>;
typedef $$EmailHeadersTableCreateCompanionBuilder = EmailHeadersCompanion
    Function({
  required String messageId,
  required String accountId,
  Value<String?> threadId,
  required String subject,
  required String from,
  required String to,
  Value<String?> cc,
  Value<String?> bcc,
  required DateTime date,
  required String folder,
  Value<String?> labels,
  Value<bool> isRead,
  Value<bool> isStarred,
  Value<bool> isImportant,
  Value<bool> hasAttachments,
  Value<int?> size,
  Value<String?> snippet,
  Value<DateTime> createdAt,
  Value<DateTime> lastAccessed,
  Value<int> rowid,
});
typedef $$EmailHeadersTableUpdateCompanionBuilder = EmailHeadersCompanion
    Function({
  Value<String> messageId,
  Value<String> accountId,
  Value<String?> threadId,
  Value<String> subject,
  Value<String> from,
  Value<String> to,
  Value<String?> cc,
  Value<String?> bcc,
  Value<DateTime> date,
  Value<String> folder,
  Value<String?> labels,
  Value<bool> isRead,
  Value<bool> isStarred,
  Value<bool> isImportant,
  Value<bool> hasAttachments,
  Value<int?> size,
  Value<String?> snippet,
  Value<DateTime> createdAt,
  Value<DateTime> lastAccessed,
  Value<int> rowid,
});

class $$EmailHeadersTableFilterComposer
    extends Composer<_$EmailDatabase, $EmailHeadersTable> {
  $$EmailHeadersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get threadId => $composableBuilder(
      column: $table.threadId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get from => $composableBuilder(
      column: $table.from, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get to => $composableBuilder(
      column: $table.to, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cc => $composableBuilder(
      column: $table.cc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bcc => $composableBuilder(
      column: $table.bcc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folder => $composableBuilder(
      column: $table.folder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get labels => $composableBuilder(
      column: $table.labels, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isStarred => $composableBuilder(
      column: $table.isStarred, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isImportant => $composableBuilder(
      column: $table.isImportant, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasAttachments => $composableBuilder(
      column: $table.hasAttachments,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snippet => $composableBuilder(
      column: $table.snippet, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => ColumnFilters(column));
}

class $$EmailHeadersTableOrderingComposer
    extends Composer<_$EmailDatabase, $EmailHeadersTable> {
  $$EmailHeadersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get threadId => $composableBuilder(
      column: $table.threadId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get from => $composableBuilder(
      column: $table.from, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get to => $composableBuilder(
      column: $table.to, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cc => $composableBuilder(
      column: $table.cc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bcc => $composableBuilder(
      column: $table.bcc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folder => $composableBuilder(
      column: $table.folder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get labels => $composableBuilder(
      column: $table.labels, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStarred => $composableBuilder(
      column: $table.isStarred, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isImportant => $composableBuilder(
      column: $table.isImportant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasAttachments => $composableBuilder(
      column: $table.hasAttachments,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snippet => $composableBuilder(
      column: $table.snippet, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed,
      builder: (column) => ColumnOrderings(column));
}

class $$EmailHeadersTableAnnotationComposer
    extends Composer<_$EmailDatabase, $EmailHeadersTable> {
  $$EmailHeadersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get from =>
      $composableBuilder(column: $table.from, builder: (column) => column);

  GeneratedColumn<String> get to =>
      $composableBuilder(column: $table.to, builder: (column) => column);

  GeneratedColumn<String> get cc =>
      $composableBuilder(column: $table.cc, builder: (column) => column);

  GeneratedColumn<String> get bcc =>
      $composableBuilder(column: $table.bcc, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get labels =>
      $composableBuilder(column: $table.labels, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get isStarred =>
      $composableBuilder(column: $table.isStarred, builder: (column) => column);

  GeneratedColumn<bool> get isImportant => $composableBuilder(
      column: $table.isImportant, builder: (column) => column);

  GeneratedColumn<bool> get hasAttachments => $composableBuilder(
      column: $table.hasAttachments, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get snippet =>
      $composableBuilder(column: $table.snippet, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => column);
}

class $$EmailHeadersTableTableManager extends RootTableManager<
    _$EmailDatabase,
    $EmailHeadersTable,
    EmailHeaderData,
    $$EmailHeadersTableFilterComposer,
    $$EmailHeadersTableOrderingComposer,
    $$EmailHeadersTableAnnotationComposer,
    $$EmailHeadersTableCreateCompanionBuilder,
    $$EmailHeadersTableUpdateCompanionBuilder,
    (
      EmailHeaderData,
      BaseReferences<_$EmailDatabase, $EmailHeadersTable, EmailHeaderData>
    ),
    EmailHeaderData,
    PrefetchHooks Function()> {
  $$EmailHeadersTableTableManager(_$EmailDatabase db, $EmailHeadersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmailHeadersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmailHeadersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmailHeadersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> messageId = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String?> threadId = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String> from = const Value.absent(),
            Value<String> to = const Value.absent(),
            Value<String?> cc = const Value.absent(),
            Value<String?> bcc = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> folder = const Value.absent(),
            Value<String?> labels = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<bool> isStarred = const Value.absent(),
            Value<bool> isImportant = const Value.absent(),
            Value<bool> hasAttachments = const Value.absent(),
            Value<int?> size = const Value.absent(),
            Value<String?> snippet = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastAccessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmailHeadersCompanion(
            messageId: messageId,
            accountId: accountId,
            threadId: threadId,
            subject: subject,
            from: from,
            to: to,
            cc: cc,
            bcc: bcc,
            date: date,
            folder: folder,
            labels: labels,
            isRead: isRead,
            isStarred: isStarred,
            isImportant: isImportant,
            hasAttachments: hasAttachments,
            size: size,
            snippet: snippet,
            createdAt: createdAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String messageId,
            required String accountId,
            Value<String?> threadId = const Value.absent(),
            required String subject,
            required String from,
            required String to,
            Value<String?> cc = const Value.absent(),
            Value<String?> bcc = const Value.absent(),
            required DateTime date,
            required String folder,
            Value<String?> labels = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<bool> isStarred = const Value.absent(),
            Value<bool> isImportant = const Value.absent(),
            Value<bool> hasAttachments = const Value.absent(),
            Value<int?> size = const Value.absent(),
            Value<String?> snippet = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastAccessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmailHeadersCompanion.insert(
            messageId: messageId,
            accountId: accountId,
            threadId: threadId,
            subject: subject,
            from: from,
            to: to,
            cc: cc,
            bcc: bcc,
            date: date,
            folder: folder,
            labels: labels,
            isRead: isRead,
            isStarred: isStarred,
            isImportant: isImportant,
            hasAttachments: hasAttachments,
            size: size,
            snippet: snippet,
            createdAt: createdAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EmailHeadersTableProcessedTableManager = ProcessedTableManager<
    _$EmailDatabase,
    $EmailHeadersTable,
    EmailHeaderData,
    $$EmailHeadersTableFilterComposer,
    $$EmailHeadersTableOrderingComposer,
    $$EmailHeadersTableAnnotationComposer,
    $$EmailHeadersTableCreateCompanionBuilder,
    $$EmailHeadersTableUpdateCompanionBuilder,
    (
      EmailHeaderData,
      BaseReferences<_$EmailDatabase, $EmailHeadersTable, EmailHeaderData>
    ),
    EmailHeaderData,
    PrefetchHooks Function()>;
typedef $$EmailBodiesTableCreateCompanionBuilder = EmailBodiesCompanion
    Function({
  required String messageId,
  required String accountId,
  Value<String?> textBody,
  Value<String?> htmlBody,
  Value<String?> processedHtml,
  Value<bool> hasQuotedText,
  Value<bool> hasSignature,
  Value<int?> bodySize,
  Value<DateTime> createdAt,
  Value<DateTime> lastAccessed,
  Value<int> rowid,
});
typedef $$EmailBodiesTableUpdateCompanionBuilder = EmailBodiesCompanion
    Function({
  Value<String> messageId,
  Value<String> accountId,
  Value<String?> textBody,
  Value<String?> htmlBody,
  Value<String?> processedHtml,
  Value<bool> hasQuotedText,
  Value<bool> hasSignature,
  Value<int?> bodySize,
  Value<DateTime> createdAt,
  Value<DateTime> lastAccessed,
  Value<int> rowid,
});

class $$EmailBodiesTableFilterComposer
    extends Composer<_$EmailDatabase, $EmailBodiesTable> {
  $$EmailBodiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textBody => $composableBuilder(
      column: $table.textBody, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get htmlBody => $composableBuilder(
      column: $table.htmlBody, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get processedHtml => $composableBuilder(
      column: $table.processedHtml, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasQuotedText => $composableBuilder(
      column: $table.hasQuotedText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasSignature => $composableBuilder(
      column: $table.hasSignature, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bodySize => $composableBuilder(
      column: $table.bodySize, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => ColumnFilters(column));
}

class $$EmailBodiesTableOrderingComposer
    extends Composer<_$EmailDatabase, $EmailBodiesTable> {
  $$EmailBodiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textBody => $composableBuilder(
      column: $table.textBody, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get htmlBody => $composableBuilder(
      column: $table.htmlBody, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get processedHtml => $composableBuilder(
      column: $table.processedHtml,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasQuotedText => $composableBuilder(
      column: $table.hasQuotedText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasSignature => $composableBuilder(
      column: $table.hasSignature,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bodySize => $composableBuilder(
      column: $table.bodySize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed,
      builder: (column) => ColumnOrderings(column));
}

class $$EmailBodiesTableAnnotationComposer
    extends Composer<_$EmailDatabase, $EmailBodiesTable> {
  $$EmailBodiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get textBody =>
      $composableBuilder(column: $table.textBody, builder: (column) => column);

  GeneratedColumn<String> get htmlBody =>
      $composableBuilder(column: $table.htmlBody, builder: (column) => column);

  GeneratedColumn<String> get processedHtml => $composableBuilder(
      column: $table.processedHtml, builder: (column) => column);

  GeneratedColumn<bool> get hasQuotedText => $composableBuilder(
      column: $table.hasQuotedText, builder: (column) => column);

  GeneratedColumn<bool> get hasSignature => $composableBuilder(
      column: $table.hasSignature, builder: (column) => column);

  GeneratedColumn<int> get bodySize =>
      $composableBuilder(column: $table.bodySize, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => column);
}

class $$EmailBodiesTableTableManager extends RootTableManager<
    _$EmailDatabase,
    $EmailBodiesTable,
    EmailBodyData,
    $$EmailBodiesTableFilterComposer,
    $$EmailBodiesTableOrderingComposer,
    $$EmailBodiesTableAnnotationComposer,
    $$EmailBodiesTableCreateCompanionBuilder,
    $$EmailBodiesTableUpdateCompanionBuilder,
    (
      EmailBodyData,
      BaseReferences<_$EmailDatabase, $EmailBodiesTable, EmailBodyData>
    ),
    EmailBodyData,
    PrefetchHooks Function()> {
  $$EmailBodiesTableTableManager(_$EmailDatabase db, $EmailBodiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmailBodiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmailBodiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmailBodiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> messageId = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String?> textBody = const Value.absent(),
            Value<String?> htmlBody = const Value.absent(),
            Value<String?> processedHtml = const Value.absent(),
            Value<bool> hasQuotedText = const Value.absent(),
            Value<bool> hasSignature = const Value.absent(),
            Value<int?> bodySize = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastAccessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmailBodiesCompanion(
            messageId: messageId,
            accountId: accountId,
            textBody: textBody,
            htmlBody: htmlBody,
            processedHtml: processedHtml,
            hasQuotedText: hasQuotedText,
            hasSignature: hasSignature,
            bodySize: bodySize,
            createdAt: createdAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String messageId,
            required String accountId,
            Value<String?> textBody = const Value.absent(),
            Value<String?> htmlBody = const Value.absent(),
            Value<String?> processedHtml = const Value.absent(),
            Value<bool> hasQuotedText = const Value.absent(),
            Value<bool> hasSignature = const Value.absent(),
            Value<int?> bodySize = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastAccessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmailBodiesCompanion.insert(
            messageId: messageId,
            accountId: accountId,
            textBody: textBody,
            htmlBody: htmlBody,
            processedHtml: processedHtml,
            hasQuotedText: hasQuotedText,
            hasSignature: hasSignature,
            bodySize: bodySize,
            createdAt: createdAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EmailBodiesTableProcessedTableManager = ProcessedTableManager<
    _$EmailDatabase,
    $EmailBodiesTable,
    EmailBodyData,
    $$EmailBodiesTableFilterComposer,
    $$EmailBodiesTableOrderingComposer,
    $$EmailBodiesTableAnnotationComposer,
    $$EmailBodiesTableCreateCompanionBuilder,
    $$EmailBodiesTableUpdateCompanionBuilder,
    (
      EmailBodyData,
      BaseReferences<_$EmailDatabase, $EmailBodiesTable, EmailBodyData>
    ),
    EmailBodyData,
    PrefetchHooks Function()>;
typedef $$AttachmentsTableCreateCompanionBuilder = AttachmentsCompanion
    Function({
  required String id,
  required String messageId,
  required String accountId,
  required String filename,
  required String mimeType,
  required int size,
  Value<Uint8List?> data,
  Value<String?> localPath,
  Value<String?> downloadUrl,
  Value<bool> isInline,
  Value<String?> contentId,
  Value<DateTime> createdAt,
  Value<DateTime> lastAccessed,
  Value<int> rowid,
});
typedef $$AttachmentsTableUpdateCompanionBuilder = AttachmentsCompanion
    Function({
  Value<String> id,
  Value<String> messageId,
  Value<String> accountId,
  Value<String> filename,
  Value<String> mimeType,
  Value<int> size,
  Value<Uint8List?> data,
  Value<String?> localPath,
  Value<String?> downloadUrl,
  Value<bool> isInline,
  Value<String?> contentId,
  Value<DateTime> createdAt,
  Value<DateTime> lastAccessed,
  Value<int> rowid,
});

class $$AttachmentsTableFilterComposer
    extends Composer<_$EmailDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isInline => $composableBuilder(
      column: $table.isInline, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentId => $composableBuilder(
      column: $table.contentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => ColumnFilters(column));
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$EmailDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isInline => $composableBuilder(
      column: $table.isInline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentId => $composableBuilder(
      column: $table.contentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed,
      builder: (column) => ColumnOrderings(column));
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$EmailDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => column);

  GeneratedColumn<bool> get isInline =>
      $composableBuilder(column: $table.isInline, builder: (column) => column);

  GeneratedColumn<String> get contentId =>
      $composableBuilder(column: $table.contentId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => column);
}

class $$AttachmentsTableTableManager extends RootTableManager<
    _$EmailDatabase,
    $AttachmentsTable,
    AttachmentData,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (
      AttachmentData,
      BaseReferences<_$EmailDatabase, $AttachmentsTable, AttachmentData>
    ),
    AttachmentData,
    PrefetchHooks Function()> {
  $$AttachmentsTableTableManager(_$EmailDatabase db, $AttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> filename = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<Uint8List?> data = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> downloadUrl = const Value.absent(),
            Value<bool> isInline = const Value.absent(),
            Value<String?> contentId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastAccessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion(
            id: id,
            messageId: messageId,
            accountId: accountId,
            filename: filename,
            mimeType: mimeType,
            size: size,
            data: data,
            localPath: localPath,
            downloadUrl: downloadUrl,
            isInline: isInline,
            contentId: contentId,
            createdAt: createdAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String messageId,
            required String accountId,
            required String filename,
            required String mimeType,
            required int size,
            Value<Uint8List?> data = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> downloadUrl = const Value.absent(),
            Value<bool> isInline = const Value.absent(),
            Value<String?> contentId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastAccessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion.insert(
            id: id,
            messageId: messageId,
            accountId: accountId,
            filename: filename,
            mimeType: mimeType,
            size: size,
            data: data,
            localPath: localPath,
            downloadUrl: downloadUrl,
            isInline: isInline,
            contentId: contentId,
            createdAt: createdAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttachmentsTableProcessedTableManager = ProcessedTableManager<
    _$EmailDatabase,
    $AttachmentsTable,
    AttachmentData,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (
      AttachmentData,
      BaseReferences<_$EmailDatabase, $AttachmentsTable, AttachmentData>
    ),
    AttachmentData,
    PrefetchHooks Function()>;
typedef $$ConversationsTableCreateCompanionBuilder = ConversationsCompanion
    Function({
  required String id,
  required String accountId,
  required String subject,
  required String participants,
  Value<int> messageCount,
  required DateTime lastMessageDate,
  Value<bool> hasUnreadMessages,
  Value<bool> hasStarredMessages,
  Value<bool> hasImportantMessages,
  Value<String?> latestSnippet,
  required String folder,
  Value<DateTime> createdAt,
  Value<DateTime> lastAccessed,
  Value<int> rowid,
});
typedef $$ConversationsTableUpdateCompanionBuilder = ConversationsCompanion
    Function({
  Value<String> id,
  Value<String> accountId,
  Value<String> subject,
  Value<String> participants,
  Value<int> messageCount,
  Value<DateTime> lastMessageDate,
  Value<bool> hasUnreadMessages,
  Value<bool> hasStarredMessages,
  Value<bool> hasImportantMessages,
  Value<String?> latestSnippet,
  Value<String> folder,
  Value<DateTime> createdAt,
  Value<DateTime> lastAccessed,
  Value<int> rowid,
});

class $$ConversationsTableFilterComposer
    extends Composer<_$EmailDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get participants => $composableBuilder(
      column: $table.participants, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get messageCount => $composableBuilder(
      column: $table.messageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastMessageDate => $composableBuilder(
      column: $table.lastMessageDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasUnreadMessages => $composableBuilder(
      column: $table.hasUnreadMessages,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasStarredMessages => $composableBuilder(
      column: $table.hasStarredMessages,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasImportantMessages => $composableBuilder(
      column: $table.hasImportantMessages,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get latestSnippet => $composableBuilder(
      column: $table.latestSnippet, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folder => $composableBuilder(
      column: $table.folder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => ColumnFilters(column));
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$EmailDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get participants => $composableBuilder(
      column: $table.participants,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get messageCount => $composableBuilder(
      column: $table.messageCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastMessageDate => $composableBuilder(
      column: $table.lastMessageDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasUnreadMessages => $composableBuilder(
      column: $table.hasUnreadMessages,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasStarredMessages => $composableBuilder(
      column: $table.hasStarredMessages,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasImportantMessages => $composableBuilder(
      column: $table.hasImportantMessages,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get latestSnippet => $composableBuilder(
      column: $table.latestSnippet,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folder => $composableBuilder(
      column: $table.folder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed,
      builder: (column) => ColumnOrderings(column));
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$EmailDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get participants => $composableBuilder(
      column: $table.participants, builder: (column) => column);

  GeneratedColumn<int> get messageCount => $composableBuilder(
      column: $table.messageCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageDate => $composableBuilder(
      column: $table.lastMessageDate, builder: (column) => column);

  GeneratedColumn<bool> get hasUnreadMessages => $composableBuilder(
      column: $table.hasUnreadMessages, builder: (column) => column);

  GeneratedColumn<bool> get hasStarredMessages => $composableBuilder(
      column: $table.hasStarredMessages, builder: (column) => column);

  GeneratedColumn<bool> get hasImportantMessages => $composableBuilder(
      column: $table.hasImportantMessages, builder: (column) => column);

  GeneratedColumn<String> get latestSnippet => $composableBuilder(
      column: $table.latestSnippet, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessed => $composableBuilder(
      column: $table.lastAccessed, builder: (column) => column);
}

class $$ConversationsTableTableManager extends RootTableManager<
    _$EmailDatabase,
    $ConversationsTable,
    ConversationData,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (
      ConversationData,
      BaseReferences<_$EmailDatabase, $ConversationsTable, ConversationData>
    ),
    ConversationData,
    PrefetchHooks Function()> {
  $$ConversationsTableTableManager(
      _$EmailDatabase db, $ConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String> participants = const Value.absent(),
            Value<int> messageCount = const Value.absent(),
            Value<DateTime> lastMessageDate = const Value.absent(),
            Value<bool> hasUnreadMessages = const Value.absent(),
            Value<bool> hasStarredMessages = const Value.absent(),
            Value<bool> hasImportantMessages = const Value.absent(),
            Value<String?> latestSnippet = const Value.absent(),
            Value<String> folder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastAccessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion(
            id: id,
            accountId: accountId,
            subject: subject,
            participants: participants,
            messageCount: messageCount,
            lastMessageDate: lastMessageDate,
            hasUnreadMessages: hasUnreadMessages,
            hasStarredMessages: hasStarredMessages,
            hasImportantMessages: hasImportantMessages,
            latestSnippet: latestSnippet,
            folder: folder,
            createdAt: createdAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String accountId,
            required String subject,
            required String participants,
            Value<int> messageCount = const Value.absent(),
            required DateTime lastMessageDate,
            Value<bool> hasUnreadMessages = const Value.absent(),
            Value<bool> hasStarredMessages = const Value.absent(),
            Value<bool> hasImportantMessages = const Value.absent(),
            Value<String?> latestSnippet = const Value.absent(),
            required String folder,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastAccessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion.insert(
            id: id,
            accountId: accountId,
            subject: subject,
            participants: participants,
            messageCount: messageCount,
            lastMessageDate: lastMessageDate,
            hasUnreadMessages: hasUnreadMessages,
            hasStarredMessages: hasStarredMessages,
            hasImportantMessages: hasImportantMessages,
            latestSnippet: latestSnippet,
            folder: folder,
            createdAt: createdAt,
            lastAccessed: lastAccessed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConversationsTableProcessedTableManager = ProcessedTableManager<
    _$EmailDatabase,
    $ConversationsTable,
    ConversationData,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (
      ConversationData,
      BaseReferences<_$EmailDatabase, $ConversationsTable, ConversationData>
    ),
    ConversationData,
    PrefetchHooks Function()>;
typedef $$LabelsTableCreateCompanionBuilder = LabelsCompanion Function({
  required String id,
  required String accountId,
  required String name,
  required String type,
  Value<int?> color,
  Value<bool> isVisible,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$LabelsTableUpdateCompanionBuilder = LabelsCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<String> name,
  Value<String> type,
  Value<int?> color,
  Value<bool> isVisible,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LabelsTableFilterComposer
    extends Composer<_$EmailDatabase, $LabelsTable> {
  $$LabelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVisible => $composableBuilder(
      column: $table.isVisible, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LabelsTableOrderingComposer
    extends Composer<_$EmailDatabase, $LabelsTable> {
  $$LabelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVisible => $composableBuilder(
      column: $table.isVisible, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LabelsTableAnnotationComposer
    extends Composer<_$EmailDatabase, $LabelsTable> {
  $$LabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LabelsTableTableManager extends RootTableManager<
    _$EmailDatabase,
    $LabelsTable,
    LabelData,
    $$LabelsTableFilterComposer,
    $$LabelsTableOrderingComposer,
    $$LabelsTableAnnotationComposer,
    $$LabelsTableCreateCompanionBuilder,
    $$LabelsTableUpdateCompanionBuilder,
    (LabelData, BaseReferences<_$EmailDatabase, $LabelsTable, LabelData>),
    LabelData,
    PrefetchHooks Function()> {
  $$LabelsTableTableManager(_$EmailDatabase db, $LabelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int?> color = const Value.absent(),
            Value<bool> isVisible = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LabelsCompanion(
            id: id,
            accountId: accountId,
            name: name,
            type: type,
            color: color,
            isVisible: isVisible,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String accountId,
            required String name,
            required String type,
            Value<int?> color = const Value.absent(),
            Value<bool> isVisible = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LabelsCompanion.insert(
            id: id,
            accountId: accountId,
            name: name,
            type: type,
            color: color,
            isVisible: isVisible,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LabelsTableProcessedTableManager = ProcessedTableManager<
    _$EmailDatabase,
    $LabelsTable,
    LabelData,
    $$LabelsTableFilterComposer,
    $$LabelsTableOrderingComposer,
    $$LabelsTableAnnotationComposer,
    $$LabelsTableCreateCompanionBuilder,
    $$LabelsTableUpdateCompanionBuilder,
    (LabelData, BaseReferences<_$EmailDatabase, $LabelsTable, LabelData>),
    LabelData,
    PrefetchHooks Function()>;
typedef $$SearchIndexTableCreateCompanionBuilder = SearchIndexCompanion
    Function({
  required String messageId,
  required String accountId,
  required String content,
  required String subject,
  required String sender,
  required String recipients,
  required String folder,
  Value<String?> labels,
  required DateTime date,
  Value<int> rowid,
});
typedef $$SearchIndexTableUpdateCompanionBuilder = SearchIndexCompanion
    Function({
  Value<String> messageId,
  Value<String> accountId,
  Value<String> content,
  Value<String> subject,
  Value<String> sender,
  Value<String> recipients,
  Value<String> folder,
  Value<String?> labels,
  Value<DateTime> date,
  Value<int> rowid,
});

class $$SearchIndexTableFilterComposer
    extends Composer<_$EmailDatabase, $SearchIndexTable> {
  $$SearchIndexTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recipients => $composableBuilder(
      column: $table.recipients, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folder => $composableBuilder(
      column: $table.folder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get labels => $composableBuilder(
      column: $table.labels, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));
}

class $$SearchIndexTableOrderingComposer
    extends Composer<_$EmailDatabase, $SearchIndexTable> {
  $$SearchIndexTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recipients => $composableBuilder(
      column: $table.recipients, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folder => $composableBuilder(
      column: $table.folder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get labels => $composableBuilder(
      column: $table.labels, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));
}

class $$SearchIndexTableAnnotationComposer
    extends Composer<_$EmailDatabase, $SearchIndexTable> {
  $$SearchIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get recipients => $composableBuilder(
      column: $table.recipients, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get labels =>
      $composableBuilder(column: $table.labels, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$SearchIndexTableTableManager extends RootTableManager<
    _$EmailDatabase,
    $SearchIndexTable,
    SearchIndexData,
    $$SearchIndexTableFilterComposer,
    $$SearchIndexTableOrderingComposer,
    $$SearchIndexTableAnnotationComposer,
    $$SearchIndexTableCreateCompanionBuilder,
    $$SearchIndexTableUpdateCompanionBuilder,
    (
      SearchIndexData,
      BaseReferences<_$EmailDatabase, $SearchIndexTable, SearchIndexData>
    ),
    SearchIndexData,
    PrefetchHooks Function()> {
  $$SearchIndexTableTableManager(_$EmailDatabase db, $SearchIndexTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> messageId = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String> sender = const Value.absent(),
            Value<String> recipients = const Value.absent(),
            Value<String> folder = const Value.absent(),
            Value<String?> labels = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SearchIndexCompanion(
            messageId: messageId,
            accountId: accountId,
            content: content,
            subject: subject,
            sender: sender,
            recipients: recipients,
            folder: folder,
            labels: labels,
            date: date,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String messageId,
            required String accountId,
            required String content,
            required String subject,
            required String sender,
            required String recipients,
            required String folder,
            Value<String?> labels = const Value.absent(),
            required DateTime date,
            Value<int> rowid = const Value.absent(),
          }) =>
              SearchIndexCompanion.insert(
            messageId: messageId,
            accountId: accountId,
            content: content,
            subject: subject,
            sender: sender,
            recipients: recipients,
            folder: folder,
            labels: labels,
            date: date,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SearchIndexTableProcessedTableManager = ProcessedTableManager<
    _$EmailDatabase,
    $SearchIndexTable,
    SearchIndexData,
    $$SearchIndexTableFilterComposer,
    $$SearchIndexTableOrderingComposer,
    $$SearchIndexTableAnnotationComposer,
    $$SearchIndexTableCreateCompanionBuilder,
    $$SearchIndexTableUpdateCompanionBuilder,
    (
      SearchIndexData,
      BaseReferences<_$EmailDatabase, $SearchIndexTable, SearchIndexData>
    ),
    SearchIndexData,
    PrefetchHooks Function()>;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String accountId,
  required String folder,
  Value<String?> historyId,
  Value<String?> nextPageToken,
  Value<DateTime?> lastFullSync,
  Value<DateTime?> lastIncrementalSync,
  Value<bool> isSyncing,
  Value<String?> syncError,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> accountId,
  Value<String> folder,
  Value<String?> historyId,
  Value<String?> nextPageToken,
  Value<DateTime?> lastFullSync,
  Value<DateTime?> lastIncrementalSync,
  Value<bool> isSyncing,
  Value<String?> syncError,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$EmailDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folder => $composableBuilder(
      column: $table.folder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextPageToken => $composableBuilder(
      column: $table.nextPageToken, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastFullSync => $composableBuilder(
      column: $table.lastFullSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastIncrementalSync => $composableBuilder(
      column: $table.lastIncrementalSync,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSyncing => $composableBuilder(
      column: $table.isSyncing, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnFilters(column));
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$EmailDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folder => $composableBuilder(
      column: $table.folder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextPageToken => $composableBuilder(
      column: $table.nextPageToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastFullSync => $composableBuilder(
      column: $table.lastFullSync,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastIncrementalSync => $composableBuilder(
      column: $table.lastIncrementalSync,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSyncing => $composableBuilder(
      column: $table.isSyncing, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnOrderings(column));
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$EmailDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get historyId =>
      $composableBuilder(column: $table.historyId, builder: (column) => column);

  GeneratedColumn<String> get nextPageToken => $composableBuilder(
      column: $table.nextPageToken, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFullSync => $composableBuilder(
      column: $table.lastFullSync, builder: (column) => column);

  GeneratedColumn<DateTime> get lastIncrementalSync => $composableBuilder(
      column: $table.lastIncrementalSync, builder: (column) => column);

  GeneratedColumn<bool> get isSyncing =>
      $composableBuilder(column: $table.isSyncing, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$SyncStateTableTableManager extends RootTableManager<
    _$EmailDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$EmailDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()> {
  $$SyncStateTableTableManager(_$EmailDatabase db, $SyncStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> accountId = const Value.absent(),
            Value<String> folder = const Value.absent(),
            Value<String?> historyId = const Value.absent(),
            Value<String?> nextPageToken = const Value.absent(),
            Value<DateTime?> lastFullSync = const Value.absent(),
            Value<DateTime?> lastIncrementalSync = const Value.absent(),
            Value<bool> isSyncing = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion(
            accountId: accountId,
            folder: folder,
            historyId: historyId,
            nextPageToken: nextPageToken,
            lastFullSync: lastFullSync,
            lastIncrementalSync: lastIncrementalSync,
            isSyncing: isSyncing,
            syncError: syncError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String accountId,
            required String folder,
            Value<String?> historyId = const Value.absent(),
            Value<String?> nextPageToken = const Value.absent(),
            Value<DateTime?> lastFullSync = const Value.absent(),
            Value<DateTime?> lastIncrementalSync = const Value.absent(),
            Value<bool> isSyncing = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion.insert(
            accountId: accountId,
            folder: folder,
            historyId: historyId,
            nextPageToken: nextPageToken,
            lastFullSync: lastFullSync,
            lastIncrementalSync: lastIncrementalSync,
            isSyncing: isSyncing,
            syncError: syncError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStateTableProcessedTableManager = ProcessedTableManager<
    _$EmailDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$EmailDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()>;
typedef $$CacheStatsTableCreateCompanionBuilder = CacheStatsCompanion Function({
  required String accountId,
  Value<int> emailCount,
  Value<int> attachmentCount,
  Value<int> totalSizeBytes,
  Value<DateTime?> oldestEmail,
  Value<DateTime?> newestEmail,
  Value<DateTime?> lastCleanup,
  Value<int> rowid,
});
typedef $$CacheStatsTableUpdateCompanionBuilder = CacheStatsCompanion Function({
  Value<String> accountId,
  Value<int> emailCount,
  Value<int> attachmentCount,
  Value<int> totalSizeBytes,
  Value<DateTime?> oldestEmail,
  Value<DateTime?> newestEmail,
  Value<DateTime?> lastCleanup,
  Value<int> rowid,
});

class $$CacheStatsTableFilterComposer
    extends Composer<_$EmailDatabase, $CacheStatsTable> {
  $$CacheStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get emailCount => $composableBuilder(
      column: $table.emailCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attachmentCount => $composableBuilder(
      column: $table.attachmentCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSizeBytes => $composableBuilder(
      column: $table.totalSizeBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get oldestEmail => $composableBuilder(
      column: $table.oldestEmail, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get newestEmail => $composableBuilder(
      column: $table.newestEmail, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastCleanup => $composableBuilder(
      column: $table.lastCleanup, builder: (column) => ColumnFilters(column));
}

class $$CacheStatsTableOrderingComposer
    extends Composer<_$EmailDatabase, $CacheStatsTable> {
  $$CacheStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get emailCount => $composableBuilder(
      column: $table.emailCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attachmentCount => $composableBuilder(
      column: $table.attachmentCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSizeBytes => $composableBuilder(
      column: $table.totalSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get oldestEmail => $composableBuilder(
      column: $table.oldestEmail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get newestEmail => $composableBuilder(
      column: $table.newestEmail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastCleanup => $composableBuilder(
      column: $table.lastCleanup, builder: (column) => ColumnOrderings(column));
}

class $$CacheStatsTableAnnotationComposer
    extends Composer<_$EmailDatabase, $CacheStatsTable> {
  $$CacheStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get emailCount => $composableBuilder(
      column: $table.emailCount, builder: (column) => column);

  GeneratedColumn<int> get attachmentCount => $composableBuilder(
      column: $table.attachmentCount, builder: (column) => column);

  GeneratedColumn<int> get totalSizeBytes => $composableBuilder(
      column: $table.totalSizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get oldestEmail => $composableBuilder(
      column: $table.oldestEmail, builder: (column) => column);

  GeneratedColumn<DateTime> get newestEmail => $composableBuilder(
      column: $table.newestEmail, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCleanup => $composableBuilder(
      column: $table.lastCleanup, builder: (column) => column);
}

class $$CacheStatsTableTableManager extends RootTableManager<
    _$EmailDatabase,
    $CacheStatsTable,
    CacheStatsData,
    $$CacheStatsTableFilterComposer,
    $$CacheStatsTableOrderingComposer,
    $$CacheStatsTableAnnotationComposer,
    $$CacheStatsTableCreateCompanionBuilder,
    $$CacheStatsTableUpdateCompanionBuilder,
    (
      CacheStatsData,
      BaseReferences<_$EmailDatabase, $CacheStatsTable, CacheStatsData>
    ),
    CacheStatsData,
    PrefetchHooks Function()> {
  $$CacheStatsTableTableManager(_$EmailDatabase db, $CacheStatsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> accountId = const Value.absent(),
            Value<int> emailCount = const Value.absent(),
            Value<int> attachmentCount = const Value.absent(),
            Value<int> totalSizeBytes = const Value.absent(),
            Value<DateTime?> oldestEmail = const Value.absent(),
            Value<DateTime?> newestEmail = const Value.absent(),
            Value<DateTime?> lastCleanup = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CacheStatsCompanion(
            accountId: accountId,
            emailCount: emailCount,
            attachmentCount: attachmentCount,
            totalSizeBytes: totalSizeBytes,
            oldestEmail: oldestEmail,
            newestEmail: newestEmail,
            lastCleanup: lastCleanup,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String accountId,
            Value<int> emailCount = const Value.absent(),
            Value<int> attachmentCount = const Value.absent(),
            Value<int> totalSizeBytes = const Value.absent(),
            Value<DateTime?> oldestEmail = const Value.absent(),
            Value<DateTime?> newestEmail = const Value.absent(),
            Value<DateTime?> lastCleanup = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CacheStatsCompanion.insert(
            accountId: accountId,
            emailCount: emailCount,
            attachmentCount: attachmentCount,
            totalSizeBytes: totalSizeBytes,
            oldestEmail: oldestEmail,
            newestEmail: newestEmail,
            lastCleanup: lastCleanup,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CacheStatsTableProcessedTableManager = ProcessedTableManager<
    _$EmailDatabase,
    $CacheStatsTable,
    CacheStatsData,
    $$CacheStatsTableFilterComposer,
    $$CacheStatsTableOrderingComposer,
    $$CacheStatsTableAnnotationComposer,
    $$CacheStatsTableCreateCompanionBuilder,
    $$CacheStatsTableUpdateCompanionBuilder,
    (
      CacheStatsData,
      BaseReferences<_$EmailDatabase, $CacheStatsTable, CacheStatsData>
    ),
    CacheStatsData,
    PrefetchHooks Function()>;

class $EmailDatabaseManager {
  final _$EmailDatabase _db;
  $EmailDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$EmailHeadersTableTableManager get emailHeaders =>
      $$EmailHeadersTableTableManager(_db, _db.emailHeaders);
  $$EmailBodiesTableTableManager get emailBodies =>
      $$EmailBodiesTableTableManager(_db, _db.emailBodies);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$LabelsTableTableManager get labels =>
      $$LabelsTableTableManager(_db, _db.labels);
  $$SearchIndexTableTableManager get searchIndex =>
      $$SearchIndexTableTableManager(_db, _db.searchIndex);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$CacheStatsTableTableManager get cacheStats =>
      $$CacheStatsTableTableManager(_db, _db.cacheStats);
}
