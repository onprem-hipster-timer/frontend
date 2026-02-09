// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_request_read.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingRequestRead {
  String get id;
  @JsonKey(name: 'requester_id')
  String get requesterId;
  @JsonKey(name: 'addressee_id')
  String get addresseeId;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of PendingRequestRead
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PendingRequestReadCopyWith<PendingRequestRead> get copyWith =>
      _$PendingRequestReadCopyWithImpl<PendingRequestRead>(
          this as PendingRequestRead, _$identity);

  /// Serializes this PendingRequestRead to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PendingRequestRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.requesterId, requesterId) ||
                other.requesterId == requesterId) &&
            (identical(other.addresseeId, addresseeId) ||
                other.addresseeId == addresseeId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, requesterId, addresseeId, createdAt);

  @override
  String toString() {
    return 'PendingRequestRead(id: $id, requesterId: $requesterId, addresseeId: $addresseeId, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $PendingRequestReadCopyWith<$Res> {
  factory $PendingRequestReadCopyWith(
          PendingRequestRead value, $Res Function(PendingRequestRead) _then) =
      _$PendingRequestReadCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'requester_id') String requesterId,
      @JsonKey(name: 'addressee_id') String addresseeId,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$PendingRequestReadCopyWithImpl<$Res>
    implements $PendingRequestReadCopyWith<$Res> {
  _$PendingRequestReadCopyWithImpl(this._self, this._then);

  final PendingRequestRead _self;
  final $Res Function(PendingRequestRead) _then;

  /// Create a copy of PendingRequestRead
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requesterId = null,
    Object? addresseeId = null,
    Object? createdAt = null,
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
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [PendingRequestRead].
extension PendingRequestReadPatterns on PendingRequestRead {
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
    TResult Function(_PendingRequestRead value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PendingRequestRead() when $default != null:
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
    TResult Function(_PendingRequestRead value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingRequestRead():
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
    TResult? Function(_PendingRequestRead value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingRequestRead() when $default != null:
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
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PendingRequestRead() when $default != null:
        return $default(
            _that.id, _that.requesterId, _that.addresseeId, _that.createdAt);
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
            @JsonKey(name: 'created_at') DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingRequestRead():
        return $default(
            _that.id, _that.requesterId, _that.addresseeId, _that.createdAt);
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
            @JsonKey(name: 'created_at') DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PendingRequestRead() when $default != null:
        return $default(
            _that.id, _that.requesterId, _that.addresseeId, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PendingRequestRead implements PendingRequestRead {
  const _PendingRequestRead(
      {required this.id,
      @JsonKey(name: 'requester_id') required this.requesterId,
      @JsonKey(name: 'addressee_id') required this.addresseeId,
      @JsonKey(name: 'created_at') required this.createdAt});
  factory _PendingRequestRead.fromJson(Map<String, dynamic> json) =>
      _$PendingRequestReadFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'requester_id')
  final String requesterId;
  @override
  @JsonKey(name: 'addressee_id')
  final String addresseeId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Create a copy of PendingRequestRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PendingRequestReadCopyWith<_PendingRequestRead> get copyWith =>
      __$PendingRequestReadCopyWithImpl<_PendingRequestRead>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PendingRequestReadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PendingRequestRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.requesterId, requesterId) ||
                other.requesterId == requesterId) &&
            (identical(other.addresseeId, addresseeId) ||
                other.addresseeId == addresseeId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, requesterId, addresseeId, createdAt);

  @override
  String toString() {
    return 'PendingRequestRead(id: $id, requesterId: $requesterId, addresseeId: $addresseeId, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$PendingRequestReadCopyWith<$Res>
    implements $PendingRequestReadCopyWith<$Res> {
  factory _$PendingRequestReadCopyWith(
          _PendingRequestRead value, $Res Function(_PendingRequestRead) _then) =
      __$PendingRequestReadCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'requester_id') String requesterId,
      @JsonKey(name: 'addressee_id') String addresseeId,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$PendingRequestReadCopyWithImpl<$Res>
    implements _$PendingRequestReadCopyWith<$Res> {
  __$PendingRequestReadCopyWithImpl(this._self, this._then);

  final _PendingRequestRead _self;
  final $Res Function(_PendingRequestRead) _then;

  /// Create a copy of PendingRequestRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? requesterId = null,
    Object? addresseeId = null,
    Object? createdAt = null,
  }) {
    return _then(_PendingRequestRead(
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
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
