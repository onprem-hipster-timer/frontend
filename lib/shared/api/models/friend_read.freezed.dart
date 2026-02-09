// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_read.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FriendRead {
  @JsonKey(name: 'user_id')
  String get userId;
  @JsonKey(name: 'friendship_id')
  String get friendshipId;
  DateTime get since;

  /// Create a copy of FriendRead
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FriendReadCopyWith<FriendRead> get copyWith =>
      _$FriendReadCopyWithImpl<FriendRead>(this as FriendRead, _$identity);

  /// Serializes this FriendRead to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FriendRead &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.friendshipId, friendshipId) ||
                other.friendshipId == friendshipId) &&
            (identical(other.since, since) || other.since == since));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, friendshipId, since);

  @override
  String toString() {
    return 'FriendRead(userId: $userId, friendshipId: $friendshipId, since: $since)';
  }
}

/// @nodoc
abstract mixin class $FriendReadCopyWith<$Res> {
  factory $FriendReadCopyWith(
          FriendRead value, $Res Function(FriendRead) _then) =
      _$FriendReadCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'friendship_id') String friendshipId,
      DateTime since});
}

/// @nodoc
class _$FriendReadCopyWithImpl<$Res> implements $FriendReadCopyWith<$Res> {
  _$FriendReadCopyWithImpl(this._self, this._then);

  final FriendRead _self;
  final $Res Function(FriendRead) _then;

  /// Create a copy of FriendRead
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? friendshipId = null,
    Object? since = null,
  }) {
    return _then(_self.copyWith(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      friendshipId: null == friendshipId
          ? _self.friendshipId
          : friendshipId // ignore: cast_nullable_to_non_nullable
              as String,
      since: null == since
          ? _self.since
          : since // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [FriendRead].
extension FriendReadPatterns on FriendRead {
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
    TResult Function(_FriendRead value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FriendRead() when $default != null:
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
    TResult Function(_FriendRead value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FriendRead():
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
    TResult? Function(_FriendRead value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FriendRead() when $default != null:
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
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'friendship_id') String friendshipId,
            DateTime since)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FriendRead() when $default != null:
        return $default(_that.userId, _that.friendshipId, _that.since);
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
    TResult Function(@JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'friendship_id') String friendshipId, DateTime since)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FriendRead():
        return $default(_that.userId, _that.friendshipId, _that.since);
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
            @JsonKey(name: 'user_id') String userId,
            @JsonKey(name: 'friendship_id') String friendshipId,
            DateTime since)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FriendRead() when $default != null:
        return $default(_that.userId, _that.friendshipId, _that.since);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FriendRead implements FriendRead {
  const _FriendRead(
      {@JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'friendship_id') required this.friendshipId,
      required this.since});
  factory _FriendRead.fromJson(Map<String, dynamic> json) =>
      _$FriendReadFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'friendship_id')
  final String friendshipId;
  @override
  final DateTime since;

  /// Create a copy of FriendRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FriendReadCopyWith<_FriendRead> get copyWith =>
      __$FriendReadCopyWithImpl<_FriendRead>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FriendReadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FriendRead &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.friendshipId, friendshipId) ||
                other.friendshipId == friendshipId) &&
            (identical(other.since, since) || other.since == since));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, friendshipId, since);

  @override
  String toString() {
    return 'FriendRead(userId: $userId, friendshipId: $friendshipId, since: $since)';
  }
}

/// @nodoc
abstract mixin class _$FriendReadCopyWith<$Res>
    implements $FriendReadCopyWith<$Res> {
  factory _$FriendReadCopyWith(
          _FriendRead value, $Res Function(_FriendRead) _then) =
      __$FriendReadCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'friendship_id') String friendshipId,
      DateTime since});
}

/// @nodoc
class __$FriendReadCopyWithImpl<$Res> implements _$FriendReadCopyWith<$Res> {
  __$FriendReadCopyWithImpl(this._self, this._then);

  final _FriendRead _self;
  final $Res Function(_FriendRead) _then;

  /// Create a copy of FriendRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? userId = null,
    Object? friendshipId = null,
    Object? since = null,
  }) {
    return _then(_FriendRead(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      friendshipId: null == friendshipId
          ? _self.friendshipId
          : friendshipId // ignore: cast_nullable_to_non_nullable
              as String,
      since: null == since
          ? _self.since
          : since // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
