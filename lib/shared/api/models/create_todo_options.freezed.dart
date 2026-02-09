// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_todo_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateTodoOptions {
  @JsonKey(name: 'tag_group_id')
  String get tagGroupId;

  /// Create a copy of CreateTodoOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CreateTodoOptionsCopyWith<CreateTodoOptions> get copyWith =>
      _$CreateTodoOptionsCopyWithImpl<CreateTodoOptions>(
          this as CreateTodoOptions, _$identity);

  /// Serializes this CreateTodoOptions to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CreateTodoOptions &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tagGroupId);

  @override
  String toString() {
    return 'CreateTodoOptions(tagGroupId: $tagGroupId)';
  }
}

/// @nodoc
abstract mixin class $CreateTodoOptionsCopyWith<$Res> {
  factory $CreateTodoOptionsCopyWith(
          CreateTodoOptions value, $Res Function(CreateTodoOptions) _then) =
      _$CreateTodoOptionsCopyWithImpl;
  @useResult
  $Res call({@JsonKey(name: 'tag_group_id') String tagGroupId});
}

/// @nodoc
class _$CreateTodoOptionsCopyWithImpl<$Res>
    implements $CreateTodoOptionsCopyWith<$Res> {
  _$CreateTodoOptionsCopyWithImpl(this._self, this._then);

  final CreateTodoOptions _self;
  final $Res Function(CreateTodoOptions) _then;

  /// Create a copy of CreateTodoOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tagGroupId = null,
  }) {
    return _then(_self.copyWith(
      tagGroupId: null == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [CreateTodoOptions].
extension CreateTodoOptionsPatterns on CreateTodoOptions {
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
    TResult Function(_CreateTodoOptions value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CreateTodoOptions() when $default != null:
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
    TResult Function(_CreateTodoOptions value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateTodoOptions():
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
    TResult? Function(_CreateTodoOptions value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateTodoOptions() when $default != null:
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
    TResult Function(@JsonKey(name: 'tag_group_id') String tagGroupId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CreateTodoOptions() when $default != null:
        return $default(_that.tagGroupId);
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
    TResult Function(@JsonKey(name: 'tag_group_id') String tagGroupId) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateTodoOptions():
        return $default(_that.tagGroupId);
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
    TResult? Function(@JsonKey(name: 'tag_group_id') String tagGroupId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateTodoOptions() when $default != null:
        return $default(_that.tagGroupId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CreateTodoOptions implements CreateTodoOptions {
  const _CreateTodoOptions(
      {@JsonKey(name: 'tag_group_id') required this.tagGroupId});
  factory _CreateTodoOptions.fromJson(Map<String, dynamic> json) =>
      _$CreateTodoOptionsFromJson(json);

  @override
  @JsonKey(name: 'tag_group_id')
  final String tagGroupId;

  /// Create a copy of CreateTodoOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CreateTodoOptionsCopyWith<_CreateTodoOptions> get copyWith =>
      __$CreateTodoOptionsCopyWithImpl<_CreateTodoOptions>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CreateTodoOptionsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CreateTodoOptions &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tagGroupId);

  @override
  String toString() {
    return 'CreateTodoOptions(tagGroupId: $tagGroupId)';
  }
}

/// @nodoc
abstract mixin class _$CreateTodoOptionsCopyWith<$Res>
    implements $CreateTodoOptionsCopyWith<$Res> {
  factory _$CreateTodoOptionsCopyWith(
          _CreateTodoOptions value, $Res Function(_CreateTodoOptions) _then) =
      __$CreateTodoOptionsCopyWithImpl;
  @override
  @useResult
  $Res call({@JsonKey(name: 'tag_group_id') String tagGroupId});
}

/// @nodoc
class __$CreateTodoOptionsCopyWithImpl<$Res>
    implements _$CreateTodoOptionsCopyWith<$Res> {
  __$CreateTodoOptionsCopyWithImpl(this._self, this._then);

  final _CreateTodoOptions _self;
  final $Res Function(_CreateTodoOptions) _then;

  /// Create a copy of CreateTodoOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tagGroupId = null,
  }) {
    return _then(_CreateTodoOptions(
      tagGroupId: null == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
