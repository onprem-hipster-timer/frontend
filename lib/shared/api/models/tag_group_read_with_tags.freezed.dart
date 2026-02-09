// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag_group_read_with_tags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TagGroupReadWithTags {
  String get id;
  String get name;
  String get color;
  @JsonKey(name: 'is_todo_group')
  bool get isTodoGroup;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  List<TagRead> get tags;
  String? get description;
  @JsonKey(name: 'goal_ratios')
  Map<String, num>? get goalRatios;

  /// Create a copy of TagGroupReadWithTags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TagGroupReadWithTagsCopyWith<TagGroupReadWithTags> get copyWith =>
      _$TagGroupReadWithTagsCopyWithImpl<TagGroupReadWithTags>(
          this as TagGroupReadWithTags, _$identity);

  /// Serializes this TagGroupReadWithTags to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TagGroupReadWithTags &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isTodoGroup, isTodoGroup) ||
                other.isTodoGroup == isTodoGroup) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other.goalRatios, goalRatios));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      color,
      isTodoGroup,
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(tags),
      description,
      const DeepCollectionEquality().hash(goalRatios));

  @override
  String toString() {
    return 'TagGroupReadWithTags(id: $id, name: $name, color: $color, isTodoGroup: $isTodoGroup, createdAt: $createdAt, updatedAt: $updatedAt, tags: $tags, description: $description, goalRatios: $goalRatios)';
  }
}

/// @nodoc
abstract mixin class $TagGroupReadWithTagsCopyWith<$Res> {
  factory $TagGroupReadWithTagsCopyWith(TagGroupReadWithTags value,
          $Res Function(TagGroupReadWithTags) _then) =
      _$TagGroupReadWithTagsCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String color,
      @JsonKey(name: 'is_todo_group') bool isTodoGroup,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      List<TagRead> tags,
      String? description,
      @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios});
}

/// @nodoc
class _$TagGroupReadWithTagsCopyWithImpl<$Res>
    implements $TagGroupReadWithTagsCopyWith<$Res> {
  _$TagGroupReadWithTagsCopyWithImpl(this._self, this._then);

  final TagGroupReadWithTags _self;
  final $Res Function(TagGroupReadWithTags) _then;

  /// Create a copy of TagGroupReadWithTags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = null,
    Object? isTodoGroup = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? tags = null,
    Object? description = freezed,
    Object? goalRatios = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagRead>,
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

/// Adds pattern-matching-related methods to [TagGroupReadWithTags].
extension TagGroupReadWithTagsPatterns on TagGroupReadWithTags {
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
    TResult Function(_TagGroupReadWithTags value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagGroupReadWithTags() when $default != null:
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
    TResult Function(_TagGroupReadWithTags value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupReadWithTags():
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
    TResult? Function(_TagGroupReadWithTags value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupReadWithTags() when $default != null:
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
            String name,
            String color,
            @JsonKey(name: 'is_todo_group') bool isTodoGroup,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            List<TagRead> tags,
            String? description,
            @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagGroupReadWithTags() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.color,
            _that.isTodoGroup,
            _that.createdAt,
            _that.updatedAt,
            _that.tags,
            _that.description,
            _that.goalRatios);
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
            String name,
            String color,
            @JsonKey(name: 'is_todo_group') bool isTodoGroup,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            List<TagRead> tags,
            String? description,
            @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupReadWithTags():
        return $default(
            _that.id,
            _that.name,
            _that.color,
            _that.isTodoGroup,
            _that.createdAt,
            _that.updatedAt,
            _that.tags,
            _that.description,
            _that.goalRatios);
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
            String name,
            String color,
            @JsonKey(name: 'is_todo_group') bool isTodoGroup,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            List<TagRead> tags,
            String? description,
            @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagGroupReadWithTags() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.color,
            _that.isTodoGroup,
            _that.createdAt,
            _that.updatedAt,
            _that.tags,
            _that.description,
            _that.goalRatios);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TagGroupReadWithTags implements TagGroupReadWithTags {
  const _TagGroupReadWithTags(
      {required this.id,
      required this.name,
      required this.color,
      @JsonKey(name: 'is_todo_group') required this.isTodoGroup,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      final List<TagRead> tags = const [],
      this.description,
      @JsonKey(name: 'goal_ratios') final Map<String, num>? goalRatios})
      : _tags = tags,
        _goalRatios = goalRatios;
  factory _TagGroupReadWithTags.fromJson(Map<String, dynamic> json) =>
      _$TagGroupReadWithTagsFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String color;
  @override
  @JsonKey(name: 'is_todo_group')
  final bool isTodoGroup;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final List<TagRead> _tags;
  @override
  @JsonKey()
  List<TagRead> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

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

  /// Create a copy of TagGroupReadWithTags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TagGroupReadWithTagsCopyWith<_TagGroupReadWithTags> get copyWith =>
      __$TagGroupReadWithTagsCopyWithImpl<_TagGroupReadWithTags>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TagGroupReadWithTagsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TagGroupReadWithTags &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isTodoGroup, isTodoGroup) ||
                other.isTodoGroup == isTodoGroup) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._goalRatios, _goalRatios));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      color,
      isTodoGroup,
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(_tags),
      description,
      const DeepCollectionEquality().hash(_goalRatios));

  @override
  String toString() {
    return 'TagGroupReadWithTags(id: $id, name: $name, color: $color, isTodoGroup: $isTodoGroup, createdAt: $createdAt, updatedAt: $updatedAt, tags: $tags, description: $description, goalRatios: $goalRatios)';
  }
}

/// @nodoc
abstract mixin class _$TagGroupReadWithTagsCopyWith<$Res>
    implements $TagGroupReadWithTagsCopyWith<$Res> {
  factory _$TagGroupReadWithTagsCopyWith(_TagGroupReadWithTags value,
          $Res Function(_TagGroupReadWithTags) _then) =
      __$TagGroupReadWithTagsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String color,
      @JsonKey(name: 'is_todo_group') bool isTodoGroup,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      List<TagRead> tags,
      String? description,
      @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios});
}

/// @nodoc
class __$TagGroupReadWithTagsCopyWithImpl<$Res>
    implements _$TagGroupReadWithTagsCopyWith<$Res> {
  __$TagGroupReadWithTagsCopyWithImpl(this._self, this._then);

  final _TagGroupReadWithTags _self;
  final $Res Function(_TagGroupReadWithTags) _then;

  /// Create a copy of TagGroupReadWithTags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = null,
    Object? isTodoGroup = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? tags = null,
    Object? description = freezed,
    Object? goalRatios = freezed,
  }) {
    return _then(_TagGroupReadWithTags(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagRead>,
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
