// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TagUpdate {
  String? get name;
  String? get color;
  String? get description;

  /// Create a copy of TagUpdate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TagUpdateCopyWith<TagUpdate> get copyWith =>
      _$TagUpdateCopyWithImpl<TagUpdate>(this as TagUpdate, _$identity);

  /// Serializes this TagUpdate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TagUpdate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, color, description);

  @override
  String toString() {
    return 'TagUpdate(name: $name, color: $color, description: $description)';
  }
}

/// @nodoc
abstract mixin class $TagUpdateCopyWith<$Res> {
  factory $TagUpdateCopyWith(TagUpdate value, $Res Function(TagUpdate) _then) =
      _$TagUpdateCopyWithImpl;
  @useResult
  $Res call({String? name, String? color, String? description});
}

/// @nodoc
class _$TagUpdateCopyWithImpl<$Res> implements $TagUpdateCopyWith<$Res> {
  _$TagUpdateCopyWithImpl(this._self, this._then);

  final TagUpdate _self;
  final $Res Function(TagUpdate) _then;

  /// Create a copy of TagUpdate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? color = freezed,
    Object? description = freezed,
  }) {
    return _then(_self.copyWith(
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      color: freezed == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TagUpdate].
extension TagUpdatePatterns on TagUpdate {
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
    TResult Function(_TagUpdate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagUpdate() when $default != null:
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
    TResult Function(_TagUpdate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagUpdate():
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
    TResult? Function(_TagUpdate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagUpdate() when $default != null:
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
    TResult Function(String? name, String? color, String? description)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagUpdate() when $default != null:
        return $default(_that.name, _that.color, _that.description);
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
    TResult Function(String? name, String? color, String? description) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagUpdate():
        return $default(_that.name, _that.color, _that.description);
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
    TResult? Function(String? name, String? color, String? description)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagUpdate() when $default != null:
        return $default(_that.name, _that.color, _that.description);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TagUpdate implements TagUpdate {
  const _TagUpdate({this.name, this.color, this.description});
  factory _TagUpdate.fromJson(Map<String, dynamic> json) =>
      _$TagUpdateFromJson(json);

  @override
  final String? name;
  @override
  final String? color;
  @override
  final String? description;

  /// Create a copy of TagUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TagUpdateCopyWith<_TagUpdate> get copyWith =>
      __$TagUpdateCopyWithImpl<_TagUpdate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TagUpdateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TagUpdate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, color, description);

  @override
  String toString() {
    return 'TagUpdate(name: $name, color: $color, description: $description)';
  }
}

/// @nodoc
abstract mixin class _$TagUpdateCopyWith<$Res>
    implements $TagUpdateCopyWith<$Res> {
  factory _$TagUpdateCopyWith(
          _TagUpdate value, $Res Function(_TagUpdate) _then) =
      __$TagUpdateCopyWithImpl;
  @override
  @useResult
  $Res call({String? name, String? color, String? description});
}

/// @nodoc
class __$TagUpdateCopyWithImpl<$Res> implements _$TagUpdateCopyWith<$Res> {
  __$TagUpdateCopyWithImpl(this._self, this._then);

  final _TagUpdate _self;
  final $Res Function(_TagUpdate) _then;

  /// Create a copy of TagUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = freezed,
    Object? color = freezed,
    Object? description = freezed,
  }) {
    return _then(_TagUpdate(
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      color: freezed == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
