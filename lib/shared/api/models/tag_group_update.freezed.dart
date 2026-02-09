// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag_group_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TagGroupUpdate {
  String? get name;
  String? get color;
  String? get description;
  @JsonKey(name: 'goal_ratios')
  Map<String, num>? get goalRatios;
  @JsonKey(name: 'is_todo_group')
  bool? get isTodoGroup;

  /// Create a copy of TagGroupUpdate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TagGroupUpdateCopyWith<TagGroupUpdate> get copyWith =>
      _$TagGroupUpdateCopyWithImpl<TagGroupUpdate>(
          this as TagGroupUpdate, _$identity);

  /// Serializes this TagGroupUpdate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TagGroupUpdate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other.goalRatios, goalRatios) &&
            (identical(other.isTodoGroup, isTodoGroup) ||
                other.isTodoGroup == isTodoGroup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, color, description,
      const DeepCollectionEquality().hash(goalRatios), isTodoGroup);

  @override
  String toString() {
    return 'TagGroupUpdate(name: $name, color: $color, description: $description, goalRatios: $goalRatios, isTodoGroup: $isTodoGroup)';
  }
}

/// @nodoc
abstract mixin class $TagGroupUpdateCopyWith<$Res> {
  factory $TagGroupUpdateCopyWith(
          TagGroupUpdate value, $Res Function(TagGroupUpdate) _then) =
      _$TagGroupUpdateCopyWithImpl;
  @useResult
  $Res call(
      {String? name,
      String? color,
      String? description,
      @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios,
      @JsonKey(name: 'is_todo_group') bool? isTodoGroup});
}

/// @nodoc
class _$TagGroupUpdateCopyWithImpl<$Res>
    implements $TagGroupUpdateCopyWith<$Res> {
  _$TagGroupUpdateCopyWithImpl(this._self, this._then);

  final TagGroupUpdate _self;
  final $Res Function(TagGroupUpdate) _then;

  /// Create a copy of TagGroupUpdate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? color = freezed,
    Object? description = freezed,
    Object? goalRatios = freezed,
    Object? isTodoGroup = freezed,
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
      goalRatios: freezed == goalRatios
          ? _self.goalRatios
          : goalRatios // ignore: cast_nullable_to_non_nullable
              as Map<String, num>?,
      isTodoGroup: freezed == isTodoGroup
          ? _self.isTodoGroup
          : isTodoGroup // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TagGroupUpdate].
extension TagGroupUpdatePatterns on TagGroupUpdate {
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
    TResult Function(_TagGroupUpdate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagGroupUpdate() when $default != null:
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
    TResult Function(_TagGroupUpdate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupUpdate():
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
    TResult? Function(_TagGroupUpdate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupUpdate() when $default != null:
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
            String? name,
            String? color,
            String? description,
            @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios,
            @JsonKey(name: 'is_todo_group') bool? isTodoGroup)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagGroupUpdate() when $default != null:
        return $default(_that.name, _that.color, _that.description,
            _that.goalRatios, _that.isTodoGroup);
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
            String? name,
            String? color,
            String? description,
            @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios,
            @JsonKey(name: 'is_todo_group') bool? isTodoGroup)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupUpdate():
        return $default(_that.name, _that.color, _that.description,
            _that.goalRatios, _that.isTodoGroup);
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
            String? name,
            String? color,
            String? description,
            @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios,
            @JsonKey(name: 'is_todo_group') bool? isTodoGroup)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupUpdate() when $default != null:
        return $default(_that.name, _that.color, _that.description,
            _that.goalRatios, _that.isTodoGroup);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TagGroupUpdate implements TagGroupUpdate {
  const _TagGroupUpdate(
      {this.name,
      this.color,
      this.description,
      @JsonKey(name: 'goal_ratios') final Map<String, num>? goalRatios,
      @JsonKey(name: 'is_todo_group') this.isTodoGroup})
      : _goalRatios = goalRatios;
  factory _TagGroupUpdate.fromJson(Map<String, dynamic> json) =>
      _$TagGroupUpdateFromJson(json);

  @override
  final String? name;
  @override
  final String? color;
  @override
  final String? description;
  final Map<String, num>? _goalRatios;
  @override
  @JsonKey(name: 'goal_ratios')
  Map<String, num>? get goalRatios {
    final value = _goalRatios;
    if (value == null) return null;
    if (_goalRatios is EqualUnmodifiableMapView) return _goalRatios;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'is_todo_group')
  final bool? isTodoGroup;

  /// Create a copy of TagGroupUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TagGroupUpdateCopyWith<_TagGroupUpdate> get copyWith =>
      __$TagGroupUpdateCopyWithImpl<_TagGroupUpdate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TagGroupUpdateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TagGroupUpdate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._goalRatios, _goalRatios) &&
            (identical(other.isTodoGroup, isTodoGroup) ||
                other.isTodoGroup == isTodoGroup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, color, description,
      const DeepCollectionEquality().hash(_goalRatios), isTodoGroup);

  @override
  String toString() {
    return 'TagGroupUpdate(name: $name, color: $color, description: $description, goalRatios: $goalRatios, isTodoGroup: $isTodoGroup)';
  }
}

/// @nodoc
abstract mixin class _$TagGroupUpdateCopyWith<$Res>
    implements $TagGroupUpdateCopyWith<$Res> {
  factory _$TagGroupUpdateCopyWith(
          _TagGroupUpdate value, $Res Function(_TagGroupUpdate) _then) =
      __$TagGroupUpdateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? name,
      String? color,
      String? description,
      @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios,
      @JsonKey(name: 'is_todo_group') bool? isTodoGroup});
}

/// @nodoc
class __$TagGroupUpdateCopyWithImpl<$Res>
    implements _$TagGroupUpdateCopyWith<$Res> {
  __$TagGroupUpdateCopyWithImpl(this._self, this._then);

  final _TagGroupUpdate _self;
  final $Res Function(_TagGroupUpdate) _then;

  /// Create a copy of TagGroupUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = freezed,
    Object? color = freezed,
    Object? description = freezed,
    Object? goalRatios = freezed,
    Object? isTodoGroup = freezed,
  }) {
    return _then(_TagGroupUpdate(
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
      goalRatios: freezed == goalRatios
          ? _self._goalRatios
          : goalRatios // ignore: cast_nullable_to_non_nullable
              as Map<String, num>?,
      isTodoGroup: freezed == isTodoGroup
          ? _self.isTodoGroup
          : isTodoGroup // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

// dart format on
