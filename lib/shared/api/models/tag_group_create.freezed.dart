// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag_group_create.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TagGroupCreate {
  String get name;
  String get color;
  @JsonKey(name: 'is_todo_group')
  bool get isTodoGroup;
  String? get description;
  @JsonKey(name: 'goal_ratios')
  Map<String, num>? get goalRatios;

  /// Create a copy of TagGroupCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TagGroupCreateCopyWith<TagGroupCreate> get copyWith =>
      _$TagGroupCreateCopyWithImpl<TagGroupCreate>(
          this as TagGroupCreate, _$identity);

  /// Serializes this TagGroupCreate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TagGroupCreate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isTodoGroup, isTodoGroup) ||
                other.isTodoGroup == isTodoGroup) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other.goalRatios, goalRatios));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, color, isTodoGroup,
      description, const DeepCollectionEquality().hash(goalRatios));

  @override
  String toString() {
    return 'TagGroupCreate(name: $name, color: $color, isTodoGroup: $isTodoGroup, description: $description, goalRatios: $goalRatios)';
  }
}

/// @nodoc
abstract mixin class $TagGroupCreateCopyWith<$Res> {
  factory $TagGroupCreateCopyWith(
          TagGroupCreate value, $Res Function(TagGroupCreate) _then) =
      _$TagGroupCreateCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String color,
      @JsonKey(name: 'is_todo_group') bool isTodoGroup,
      String? description,
      @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios});
}

/// @nodoc
class _$TagGroupCreateCopyWithImpl<$Res>
    implements $TagGroupCreateCopyWith<$Res> {
  _$TagGroupCreateCopyWithImpl(this._self, this._then);

  final TagGroupCreate _self;
  final $Res Function(TagGroupCreate) _then;

  /// Create a copy of TagGroupCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? color = null,
    Object? isTodoGroup = null,
    Object? description = freezed,
    Object? goalRatios = freezed,
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
      isTodoGroup: null == isTodoGroup
          ? _self.isTodoGroup
          : isTodoGroup // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      goalRatios: freezed == goalRatios
          ? _self.goalRatios
          : goalRatios // ignore: cast_nullable_to_non_nullable
              as Map<String, num>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TagGroupCreate].
extension TagGroupCreatePatterns on TagGroupCreate {
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
    TResult Function(_TagGroupCreate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagGroupCreate() when $default != null:
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
    TResult Function(_TagGroupCreate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupCreate():
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
    TResult? Function(_TagGroupCreate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupCreate() when $default != null:
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
            String name,
            String color,
            @JsonKey(name: 'is_todo_group') bool isTodoGroup,
            String? description,
            @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagGroupCreate() when $default != null:
        return $default(_that.name, _that.color, _that.isTodoGroup,
            _that.description, _that.goalRatios);
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
            String name,
            String color,
            @JsonKey(name: 'is_todo_group') bool isTodoGroup,
            String? description,
            @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupCreate():
        return $default(_that.name, _that.color, _that.isTodoGroup,
            _that.description, _that.goalRatios);
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
            String name,
            String color,
            @JsonKey(name: 'is_todo_group') bool isTodoGroup,
            String? description,
            @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupCreate() when $default != null:
        return $default(_that.name, _that.color, _that.isTodoGroup,
            _that.description, _that.goalRatios);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TagGroupCreate implements TagGroupCreate {
  const _TagGroupCreate(
      {required this.name,
      required this.color,
      @JsonKey(name: 'is_todo_group') this.isTodoGroup = false,
      this.description,
      @JsonKey(name: 'goal_ratios') final Map<String, num>? goalRatios})
      : _goalRatios = goalRatios;
  factory _TagGroupCreate.fromJson(Map<String, dynamic> json) =>
      _$TagGroupCreateFromJson(json);

  @override
  final String name;
  @override
  final String color;
  @override
  @JsonKey(name: 'is_todo_group')
  final bool isTodoGroup;
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

  /// Create a copy of TagGroupCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TagGroupCreateCopyWith<_TagGroupCreate> get copyWith =>
      __$TagGroupCreateCopyWithImpl<_TagGroupCreate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TagGroupCreateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TagGroupCreate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isTodoGroup, isTodoGroup) ||
                other.isTodoGroup == isTodoGroup) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._goalRatios, _goalRatios));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, color, isTodoGroup,
      description, const DeepCollectionEquality().hash(_goalRatios));

  @override
  String toString() {
    return 'TagGroupCreate(name: $name, color: $color, isTodoGroup: $isTodoGroup, description: $description, goalRatios: $goalRatios)';
  }
}

/// @nodoc
abstract mixin class _$TagGroupCreateCopyWith<$Res>
    implements $TagGroupCreateCopyWith<$Res> {
  factory _$TagGroupCreateCopyWith(
          _TagGroupCreate value, $Res Function(_TagGroupCreate) _then) =
      __$TagGroupCreateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String color,
      @JsonKey(name: 'is_todo_group') bool isTodoGroup,
      String? description,
      @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios});
}

/// @nodoc
class __$TagGroupCreateCopyWithImpl<$Res>
    implements _$TagGroupCreateCopyWith<$Res> {
  __$TagGroupCreateCopyWithImpl(this._self, this._then);

  final _TagGroupCreate _self;
  final $Res Function(_TagGroupCreate) _then;

  /// Create a copy of TagGroupCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? color = null,
    Object? isTodoGroup = null,
    Object? description = freezed,
    Object? goalRatios = freezed,
  }) {
    return _then(_TagGroupCreate(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      isTodoGroup: null == isTodoGroup
          ? _self.isTodoGroup
          : isTodoGroup // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      goalRatios: freezed == goalRatios
          ? _self._goalRatios
          : goalRatios // ignore: cast_nullable_to_non_nullable
              as Map<String, num>?,
    ));
  }
}

// dart format on
