// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friendship_read.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FriendshipRead {
  String get id;
  @JsonKey(name: 'requester_id')
  String get requesterId;
  @JsonKey(name: 'addressee_id')
  String get addresseeId;
  FriendshipStatus get status;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @JsonKey(name: 'blocked_by')
  String? get blockedBy;

  /// Create a copy of FriendshipRead
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FriendshipReadCopyWith<FriendshipRead> get copyWith =>
      _$FriendshipReadCopyWithImpl<FriendshipRead>(
          this as FriendshipRead, _$identity);

  /// Serializes this FriendshipRead to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FriendshipRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.requesterId, requesterId) ||
                other.requesterId == requesterId) &&
            (identical(other.addresseeId, addresseeId) ||
                other.addresseeId == addresseeId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.blockedBy, blockedBy) ||
                other.blockedBy == blockedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, requesterId, addresseeId,
      status, createdAt, updatedAt, blockedBy);

  @override
  String toString() {
    return 'FriendshipRead(id: $id, requesterId: $requesterId, addresseeId: $addresseeId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, blockedBy: $blockedBy)';
  }
}

/// @nodoc
abstract mixin class $FriendshipReadCopyWith<$Res> {
  factory $FriendshipReadCopyWith(
          FriendshipRead value, $Res Function(FriendshipRead) _then) =
      _$FriendshipReadCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'requester_id') String requesterId,
      @JsonKey(name: 'addressee_id') String addresseeId,
      FriendshipStatus status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'blocked_by') String? blockedBy});
}

/// @nodoc
class _$FriendshipReadCopyWithImpl<$Res>
    implements $FriendshipReadCopyWith<$Res> {
  _$FriendshipReadCopyWithImpl(this._self, this._then);

  final FriendshipRead _self;
  final $Res Function(FriendshipRead) _then;

  /// Create a copy of FriendshipRead
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requesterId = null,
    Object? addresseeId = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? blockedBy = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      requesterId: null == requesterId
          ? _self.requesterId
          : requesterId // ignore: cast_nullable_to_non_nullable
              as String,
      addresseeId: null == addresseeId
          ? _self.addresseeId
          : addresseeId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as FriendshipStatus,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      blockedBy: freezed == blockedBy
          ? _self.blockedBy
          : blockedBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FriendshipRead].
extension FriendshipReadPatterns on FriendshipRead {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FriendshipRead value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FriendshipRead() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FriendshipRead value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FriendshipRead():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FriendshipRead value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FriendshipRead() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            @JsonKey(name: 'requester_id') String requesterId,
            @JsonKey(name: 'addressee_id') String addresseeId,
            FriendshipStatus status,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            @JsonKey(name: 'blocked_by') String? blockedBy)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FriendshipRead() when $default != null:
        return $default(_that.id, _that.requesterId, _that.addresseeId,
            _that.status, _that.createdAt, _that.updatedAt, _that.blockedBy);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            @JsonKey(name: 'requester_id') String requesterId,
            @JsonKey(name: 'addressee_id') String addresseeId,
            FriendshipStatus status,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            @JsonKey(name: 'blocked_by') String? blockedBy)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FriendshipRead():
        return $default(_that.id, _that.requesterId, _that.addresseeId,
            _that.status, _that.createdAt, _that.updatedAt, _that.blockedBy);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            @JsonKey(name: 'requester_id') String requesterId,
            @JsonKey(name: 'addressee_id') String addresseeId,
            FriendshipStatus status,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            @JsonKey(name: 'blocked_by') String? blockedBy)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FriendshipRead() when $default != null:
        return $default(_that.id, _that.requesterId, _that.addresseeId,
            _that.status, _that.createdAt, _that.updatedAt, _that.blockedBy);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FriendshipRead implements FriendshipRead {
  const _FriendshipRead(
      {required this.id,
      @JsonKey(name: 'requester_id') required this.requesterId,
      @JsonKey(name: 'addressee_id') required this.addresseeId,
      required this.status,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'blocked_by') this.blockedBy});
  factory _FriendshipRead.fromJson(Map<String, dynamic> json) =>
      _$FriendshipReadFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'requester_id')
  final String requesterId;
  @override
  @JsonKey(name: 'addressee_id')
  final String addresseeId;
  @override
  final FriendshipStatus status;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  @JsonKey(name: 'blocked_by')
  final String? blockedBy;

  /// Create a copy of FriendshipRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FriendshipReadCopyWith<_FriendshipRead> get copyWith =>
      __$FriendshipReadCopyWithImpl<_FriendshipRead>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FriendshipReadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FriendshipRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.requesterId, requesterId) ||
                other.requesterId == requesterId) &&
            (identical(other.addresseeId, addresseeId) ||
                other.addresseeId == addresseeId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.blockedBy, blockedBy) ||
                other.blockedBy == blockedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, requesterId, addresseeId,
      status, createdAt, updatedAt, blockedBy);

  @override
  String toString() {
    return 'FriendshipRead(id: $id, requesterId: $requesterId, addresseeId: $addresseeId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, blockedBy: $blockedBy)';
  }
}

/// @nodoc
abstract mixin class _$FriendshipReadCopyWith<$Res>
    implements $FriendshipReadCopyWith<$Res> {
  factory _$FriendshipReadCopyWith(
          _FriendshipRead value, $Res Function(_FriendshipRead) _then) =
      __$FriendshipReadCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'requester_id') String requesterId,
      @JsonKey(name: 'addressee_id') String addresseeId,
      FriendshipStatus status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'blocked_by') String? blockedBy});
}

/// @nodoc
class __$FriendshipReadCopyWithImpl<$Res>
    implements _$FriendshipReadCopyWith<$Res> {
  __$FriendshipReadCopyWithImpl(this._self, this._then);

  final _FriendshipRead _self;
  final $Res Function(_FriendshipRead) _then;

  /// Create a copy of FriendshipRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? requesterId = null,
    Object? addresseeId = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? blockedBy = freezed,
  }) {
    return _then(_FriendshipRead(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      requesterId: null == requesterId
          ? _self.requesterId
          : requesterId // ignore: cast_nullable_to_non_nullable
              as String,
      addresseeId: null == addresseeId
          ? _self.addresseeId
          : addresseeId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as FriendshipStatus,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      blockedBy: freezed == blockedBy
          ? _self.blockedBy
          : blockedBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
