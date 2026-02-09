// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_read.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TodoRead {
  String get id;
  String get title;
  @JsonKey(name: 'tag_group_id')
  String get tagGroupId;
  TodoStatus get status;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  List<TagRead> get tags;
  List<ScheduleRead> get schedules;
  @JsonKey(name: 'include_reason')
  TodoIncludeReason get includeReason;
  @JsonKey(name: 'is_shared')
  bool get isShared;
  String? get description;
  DateTime? get deadline;
  @JsonKey(name: 'parent_id')
  String? get parentId;
  @JsonKey(name: 'owner_id')
  String? get ownerId;
  @JsonKey(name: 'visibility_level')
  VisibilityLevel? get visibilityLevel;

  /// Create a copy of TodoRead
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TodoReadCopyWith<TodoRead> get copyWith =>
      _$TodoReadCopyWithImpl<TodoRead>(this as TodoRead, _$identity);

  /// Serializes this TodoRead to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TodoRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            const DeepCollectionEquality().equals(other.schedules, schedules) &&
            (identical(other.includeReason, includeReason) ||
                other.includeReason == includeReason) &&
            (identical(other.isShared, isShared) ||
                other.isShared == isShared) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.visibilityLevel, visibilityLevel) ||
                other.visibilityLevel == visibilityLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      tagGroupId,
      status,
      createdAt,
      const DeepCollectionEquality().hash(tags),
      const DeepCollectionEquality().hash(schedules),
      includeReason,
      isShared,
      description,
      deadline,
      parentId,
      ownerId,
      visibilityLevel);

  @override
  String toString() {
    return 'TodoRead(id: $id, title: $title, tagGroupId: $tagGroupId, status: $status, createdAt: $createdAt, tags: $tags, schedules: $schedules, includeReason: $includeReason, isShared: $isShared, description: $description, deadline: $deadline, parentId: $parentId, ownerId: $ownerId, visibilityLevel: $visibilityLevel)';
  }
}

/// @nodoc
abstract mixin class $TodoReadCopyWith<$Res> {
  factory $TodoReadCopyWith(TodoRead value, $Res Function(TodoRead) _then) =
      _$TodoReadCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'tag_group_id') String tagGroupId,
      TodoStatus status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      List<TagRead> tags,
      List<ScheduleRead> schedules,
      @JsonKey(name: 'include_reason') TodoIncludeReason includeReason,
      @JsonKey(name: 'is_shared') bool isShared,
      String? description,
      DateTime? deadline,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'owner_id') String? ownerId,
      @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel});
}

/// @nodoc
class _$TodoReadCopyWithImpl<$Res> implements $TodoReadCopyWith<$Res> {
  _$TodoReadCopyWithImpl(this._self, this._then);

  final TodoRead _self;
  final $Res Function(TodoRead) _then;

  /// Create a copy of TodoRead
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? tagGroupId = null,
    Object? status = null,
    Object? createdAt = null,
    Object? tags = null,
    Object? schedules = null,
    Object? includeReason = null,
    Object? isShared = null,
    Object? description = freezed,
    Object? deadline = freezed,
    Object? parentId = freezed,
    Object? ownerId = freezed,
    Object? visibilityLevel = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      tagGroupId: null == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TodoStatus,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagRead>,
      schedules: null == schedules
          ? _self.schedules
          : schedules // ignore: cast_nullable_to_non_nullable
              as List<ScheduleRead>,
      includeReason: null == includeReason
          ? _self.includeReason
          : includeReason // ignore: cast_nullable_to_non_nullable
              as TodoIncludeReason,
      isShared: null == isShared
          ? _self.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      deadline: freezed == deadline
          ? _self.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: freezed == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      visibilityLevel: freezed == visibilityLevel
          ? _self.visibilityLevel
          : visibilityLevel // ignore: cast_nullable_to_non_nullable
              as VisibilityLevel?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TodoRead].
extension TodoReadPatterns on TodoRead {
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
    TResult Function(_TodoRead value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TodoRead() when $default != null:
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
    TResult Function(_TodoRead value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoRead():
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
    TResult? Function(_TodoRead value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoRead() when $default != null:
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
            String title,
            @JsonKey(name: 'tag_group_id') String tagGroupId,
            TodoStatus status,
            @JsonKey(name: 'created_at') DateTime createdAt,
            List<TagRead> tags,
            List<ScheduleRead> schedules,
            @JsonKey(name: 'include_reason') TodoIncludeReason includeReason,
            @JsonKey(name: 'is_shared') bool isShared,
            String? description,
            DateTime? deadline,
            @JsonKey(name: 'parent_id') String? parentId,
            @JsonKey(name: 'owner_id') String? ownerId,
            @JsonKey(name: 'visibility_level')
            VisibilityLevel? visibilityLevel)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TodoRead() when $default != null:
        return $default(
            _that.id,
            _that.title,
            _that.tagGroupId,
            _that.status,
            _that.createdAt,
            _that.tags,
            _that.schedules,
            _that.includeReason,
            _that.isShared,
            _that.description,
            _that.deadline,
            _that.parentId,
            _that.ownerId,
            _that.visibilityLevel);
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
            String title,
            @JsonKey(name: 'tag_group_id') String tagGroupId,
            TodoStatus status,
            @JsonKey(name: 'created_at') DateTime createdAt,
            List<TagRead> tags,
            List<ScheduleRead> schedules,
            @JsonKey(name: 'include_reason') TodoIncludeReason includeReason,
            @JsonKey(name: 'is_shared') bool isShared,
            String? description,
            DateTime? deadline,
            @JsonKey(name: 'parent_id') String? parentId,
            @JsonKey(name: 'owner_id') String? ownerId,
            @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoRead():
        return $default(
            _that.id,
            _that.title,
            _that.tagGroupId,
            _that.status,
            _that.createdAt,
            _that.tags,
            _that.schedules,
            _that.includeReason,
            _that.isShared,
            _that.description,
            _that.deadline,
            _that.parentId,
            _that.ownerId,
            _that.visibilityLevel);
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
            String title,
            @JsonKey(name: 'tag_group_id') String tagGroupId,
            TodoStatus status,
            @JsonKey(name: 'created_at') DateTime createdAt,
            List<TagRead> tags,
            List<ScheduleRead> schedules,
            @JsonKey(name: 'include_reason') TodoIncludeReason includeReason,
            @JsonKey(name: 'is_shared') bool isShared,
            String? description,
            DateTime? deadline,
            @JsonKey(name: 'parent_id') String? parentId,
            @JsonKey(name: 'owner_id') String? ownerId,
            @JsonKey(name: 'visibility_level')
            VisibilityLevel? visibilityLevel)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoRead() when $default != null:
        return $default(
            _that.id,
            _that.title,
            _that.tagGroupId,
            _that.status,
            _that.createdAt,
            _that.tags,
            _that.schedules,
            _that.includeReason,
            _that.isShared,
            _that.description,
            _that.deadline,
            _that.parentId,
            _that.ownerId,
            _that.visibilityLevel);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TodoRead implements TodoRead {
  const _TodoRead(
      {required this.id,
      required this.title,
      @JsonKey(name: 'tag_group_id') required this.tagGroupId,
      required this.status,
      @JsonKey(name: 'created_at') required this.createdAt,
      final List<TagRead> tags = const [],
      final List<ScheduleRead> schedules = const [],
      @JsonKey(name: 'include_reason')
      this.includeReason = TodoIncludeReason.match,
      @JsonKey(name: 'is_shared') this.isShared = false,
      this.description,
      this.deadline,
      @JsonKey(name: 'parent_id') this.parentId,
      @JsonKey(name: 'owner_id') this.ownerId,
      @JsonKey(name: 'visibility_level') this.visibilityLevel})
      : _tags = tags,
        _schedules = schedules;
  factory _TodoRead.fromJson(Map<String, dynamic> json) =>
      _$TodoReadFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(name: 'tag_group_id')
  final String tagGroupId;
  @override
  final TodoStatus status;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final List<TagRead> _tags;
  @override
  @JsonKey()
  List<TagRead> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<ScheduleRead> _schedules;
  @override
  @JsonKey()
  List<ScheduleRead> get schedules {
    if (_schedules is EqualUnmodifiableListView) return _schedules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_schedules);
  }

  @override
  @JsonKey(name: 'include_reason')
  final TodoIncludeReason includeReason;
  @override
  @JsonKey(name: 'is_shared')
  final bool isShared;
  @override
  final String? description;
  @override
  final DateTime? deadline;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @override
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  @override
  @JsonKey(name: 'visibility_level')
  final VisibilityLevel? visibilityLevel;

  /// Create a copy of TodoRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TodoReadCopyWith<_TodoRead> get copyWith =>
      __$TodoReadCopyWithImpl<_TodoRead>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TodoReadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TodoRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._schedules, _schedules) &&
            (identical(other.includeReason, includeReason) ||
                other.includeReason == includeReason) &&
            (identical(other.isShared, isShared) ||
                other.isShared == isShared) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.visibilityLevel, visibilityLevel) ||
                other.visibilityLevel == visibilityLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      tagGroupId,
      status,
      createdAt,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_schedules),
      includeReason,
      isShared,
      description,
      deadline,
      parentId,
      ownerId,
      visibilityLevel);

  @override
  String toString() {
    return 'TodoRead(id: $id, title: $title, tagGroupId: $tagGroupId, status: $status, createdAt: $createdAt, tags: $tags, schedules: $schedules, includeReason: $includeReason, isShared: $isShared, description: $description, deadline: $deadline, parentId: $parentId, ownerId: $ownerId, visibilityLevel: $visibilityLevel)';
  }
}

/// @nodoc
abstract mixin class _$TodoReadCopyWith<$Res>
    implements $TodoReadCopyWith<$Res> {
  factory _$TodoReadCopyWith(_TodoRead value, $Res Function(_TodoRead) _then) =
      __$TodoReadCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'tag_group_id') String tagGroupId,
      TodoStatus status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      List<TagRead> tags,
      List<ScheduleRead> schedules,
      @JsonKey(name: 'include_reason') TodoIncludeReason includeReason,
      @JsonKey(name: 'is_shared') bool isShared,
      String? description,
      DateTime? deadline,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'owner_id') String? ownerId,
      @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel});
}

/// @nodoc
class __$TodoReadCopyWithImpl<$Res> implements _$TodoReadCopyWith<$Res> {
  __$TodoReadCopyWithImpl(this._self, this._then);

  final _TodoRead _self;
  final $Res Function(_TodoRead) _then;

  /// Create a copy of TodoRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? tagGroupId = null,
    Object? status = null,
    Object? createdAt = null,
    Object? tags = null,
    Object? schedules = null,
    Object? includeReason = null,
    Object? isShared = null,
    Object? description = freezed,
    Object? deadline = freezed,
    Object? parentId = freezed,
    Object? ownerId = freezed,
    Object? visibilityLevel = freezed,
  }) {
    return _then(_TodoRead(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      tagGroupId: null == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TodoStatus,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagRead>,
      schedules: null == schedules
          ? _self._schedules
          : schedules // ignore: cast_nullable_to_non_nullable
              as List<ScheduleRead>,
      includeReason: null == includeReason
          ? _self.includeReason
          : includeReason // ignore: cast_nullable_to_non_nullable
              as TodoIncludeReason,
      isShared: null == isShared
          ? _self.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      deadline: freezed == deadline
          ? _self.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: freezed == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      visibilityLevel: freezed == visibilityLevel
          ? _self.visibilityLevel
          : visibilityLevel // ignore: cast_nullable_to_non_nullable
              as VisibilityLevel?,
    ));
  }
}

// dart format on
