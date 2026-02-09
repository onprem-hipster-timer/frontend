// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag_create.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TagCreate {
  String get name;
  String get color;
  @JsonKey(name: 'group_id')
  String get groupId;
  String? get description;

  /// Create a copy of TagCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TagCreateCopyWith<TagCreate> get copyWith =>
      _$TagCreateCopyWithImpl<TagCreate>(this as TagCreate, _$identity);

  /// Serializes this TagCreate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TagCreate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, color, groupId, description);

  @override
  String toString() {
    return 'TagCreate(name: $name, color: $color, groupId: $groupId, description: $description)';
  }
}

/// @nodoc
abstract mixin class $TagCreateCopyWith<$Res> {
  factory $TagCreateCopyWith(TagCreate value, $Res Function(TagCreate) _then) =
      _$TagCreateCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String color,
      @JsonKey(name: 'group_id') String groupId,
      String? description});
}

/// @nodoc
class _$TagCreateCopyWithImpl<$Res> implements $TagCreateCopyWith<$Res> {
  _$TagCreateCopyWithImpl(this._self, this._then);

  final TagCreate _self;
  final $Res Function(TagCreate) _then;

  /// Create a copy of TagCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? color = null,
    Object? groupId = null,
    Object? description = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TagCreate].
extension TagCreatePatterns on TagCreate {
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
    TResult Function(_TagCreate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagCreate() when $default != null:
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
    TResult Function(_TagCreate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagCreate():
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
    TResult? Function(_TagCreate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagCreate() when $default != null:
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
    TResult Function(String name, String color,
            @JsonKey(name: 'group_id') String groupId, String? description)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagCreate() when $default != null:
        return $default(
            _that.name, _that.color, _that.groupId, _that.description);
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
    TResult Function(String name, String color,
            @JsonKey(name: 'group_id') String groupId, String? description)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagCreate():
        return $default(
            _that.name, _that.color, _that.groupId, _that.description);
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
    TResult? Function(String name, String color,
            @JsonKey(name: 'group_id') String groupId, String? description)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagCreate() when $default != null:
        return $default(
            _that.name, _that.color, _that.groupId, _that.description);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TagCreate implements TagCreate {
  const _TagCreate(
      {required this.name,
      required this.color,
      @JsonKey(name: 'group_id') required this.groupId,
      this.description});
  factory _TagCreate.fromJson(Map<String, dynamic> json) =>
      _$TagCreateFromJson(json);

  @override
  final String name;
  @override
  final String color;
  @override
  @JsonKey(name: 'group_id')
  final String groupId;
  @override
  final String? description;

  /// Create a copy of TagCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TagCreateCopyWith<_TagCreate> get copyWith =>
      __$TagCreateCopyWithImpl<_TagCreate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TagCreateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TagCreate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, color, groupId, description);

  @override
  String toString() {
    return 'TagCreate(name: $name, color: $color, groupId: $groupId, description: $description)';
  }
}

/// @nodoc
abstract mixin class _$TagCreateCopyWith<$Res>
    implements $TagCreateCopyWith<$Res> {
  factory _$TagCreateCopyWith(
          _TagCreate value, $Res Function(_TagCreate) _then) =
      __$TagCreateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String color,
      @JsonKey(name: 'group_id') String groupId,
      String? description});
}

/// @nodoc
class __$TagCreateCopyWithImpl<$Res> implements _$TagCreateCopyWith<$Res> {
  __$TagCreateCopyWithImpl(this._self, this._then);

  final _TagCreate _self;
  final $Res Function(_TagCreate) _then;

  /// Create a copy of TagCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? color = null,
    Object? groupId = null,
    Object? description = freezed,
  }) {
    return _then(_TagCreate(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
