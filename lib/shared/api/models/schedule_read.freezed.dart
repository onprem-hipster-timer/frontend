// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_read.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleRead {
  String get id;
  String get title;
  @JsonKey(name: 'start_time')
  DateTime get startTime;
  @JsonKey(name: 'end_time')
  DateTime get endTime;
  ScheduleState get state;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  List<TagRead> get tags;
  @JsonKey(name: 'is_shared')
  bool get isShared;
  String? get description;
  @JsonKey(name: 'recurrence_rule')
  String? get recurrenceRule;
  @JsonKey(name: 'recurrence_end')
  DateTime? get recurrenceEnd;
  @JsonKey(name: 'parent_id')
  String? get parentId;
  @JsonKey(name: 'tag_group_id')
  String? get tagGroupId;
  @JsonKey(name: 'source_todo_id')
  String? get sourceTodoId;
  @JsonKey(name: 'owner_id')
  String? get ownerId;
  @JsonKey(name: 'visibility_level')
  VisibilityLevel? get visibilityLevel;

  /// Create a copy of ScheduleRead
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScheduleReadCopyWith<ScheduleRead> get copyWith =>
      _$ScheduleReadCopyWithImpl<ScheduleRead>(
          this as ScheduleRead, _$identity);

  /// Serializes this ScheduleRead to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScheduleRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.isShared, isShared) ||
                other.isShared == isShared) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.recurrenceEnd, recurrenceEnd) ||
                other.recurrenceEnd == recurrenceEnd) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.sourceTodoId, sourceTodoId) ||
                other.sourceTodoId == sourceTodoId) &&
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
      startTime,
      endTime,
      state,
      createdAt,
      const DeepCollectionEquality().hash(tags),
      isShared,
      description,
      recurrenceRule,
      recurrenceEnd,
      parentId,
      tagGroupId,
      sourceTodoId,
      ownerId,
      visibilityLevel);

  @override
  String toString() {
    return 'ScheduleRead(id: $id, title: $title, startTime: $startTime, endTime: $endTime, state: $state, createdAt: $createdAt, tags: $tags, isShared: $isShared, description: $description, recurrenceRule: $recurrenceRule, recurrenceEnd: $recurrenceEnd, parentId: $parentId, tagGroupId: $tagGroupId, sourceTodoId: $sourceTodoId, ownerId: $ownerId, visibilityLevel: $visibilityLevel)';
  }
}

/// @nodoc
abstract mixin class $ScheduleReadCopyWith<$Res> {
  factory $ScheduleReadCopyWith(
          ScheduleRead value, $Res Function(ScheduleRead) _then) =
      _$ScheduleReadCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'end_time') DateTime endTime,
      ScheduleState state,
      @JsonKey(name: 'created_at') DateTime createdAt,
      List<TagRead> tags,
      @JsonKey(name: 'is_shared') bool isShared,
      String? description,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'tag_group_id') String? tagGroupId,
      @JsonKey(name: 'source_todo_id') String? sourceTodoId,
      @JsonKey(name: 'owner_id') String? ownerId,
      @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel});
}

/// @nodoc
class _$ScheduleReadCopyWithImpl<$Res> implements $ScheduleReadCopyWith<$Res> {
  _$ScheduleReadCopyWithImpl(this._self, this._then);

  final ScheduleRead _self;
  final $Res Function(ScheduleRead) _then;

  /// Create a copy of ScheduleRead
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? state = null,
    Object? createdAt = null,
    Object? tags = null,
    Object? isShared = null,
    Object? description = freezed,
    Object? recurrenceRule = freezed,
    Object? recurrenceEnd = freezed,
    Object? parentId = freezed,
    Object? tagGroupId = freezed,
    Object? sourceTodoId = freezed,
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
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as ScheduleState,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagRead>,
      isShared: null == isShared
          ? _self.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceRule: freezed == recurrenceRule
          ? _self.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceEnd: freezed == recurrenceEnd
          ? _self.recurrenceEnd
          : recurrenceEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      tagGroupId: freezed == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceTodoId: freezed == sourceTodoId
          ? _self.sourceTodoId
          : sourceTodoId // ignore: cast_nullable_to_non_nullable
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

/// Adds pattern-matching-related methods to [ScheduleRead].
extension ScheduleReadPatterns on ScheduleRead {
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
    TResult Function(_ScheduleRead value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleRead() when $default != null:
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
    TResult Function(_ScheduleRead value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleRead():
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
    TResult? Function(_ScheduleRead value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleRead() when $default != null:
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
            @JsonKey(name: 'start_time') DateTime startTime,
            @JsonKey(name: 'end_time') DateTime endTime,
            ScheduleState state,
            @JsonKey(name: 'created_at') DateTime createdAt,
            List<TagRead> tags,
            @JsonKey(name: 'is_shared') bool isShared,
            String? description,
            @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
            @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
            @JsonKey(name: 'parent_id') String? parentId,
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'source_todo_id') String? sourceTodoId,
            @JsonKey(name: 'owner_id') String? ownerId,
            @JsonKey(name: 'visibility_level')
            VisibilityLevel? visibilityLevel)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleRead() when $default != null:
        return $default(
            _that.id,
            _that.title,
            _that.startTime,
            _that.endTime,
            _that.state,
            _that.createdAt,
            _that.tags,
            _that.isShared,
            _that.description,
            _that.recurrenceRule,
            _that.recurrenceEnd,
            _that.parentId,
            _that.tagGroupId,
            _that.sourceTodoId,
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
            @JsonKey(name: 'start_time') DateTime startTime,
            @JsonKey(name: 'end_time') DateTime endTime,
            ScheduleState state,
            @JsonKey(name: 'created_at') DateTime createdAt,
            List<TagRead> tags,
            @JsonKey(name: 'is_shared') bool isShared,
            String? description,
            @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
            @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
            @JsonKey(name: 'parent_id') String? parentId,
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'source_todo_id') String? sourceTodoId,
            @JsonKey(name: 'owner_id') String? ownerId,
            @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleRead():
        return $default(
            _that.id,
            _that.title,
            _that.startTime,
            _that.endTime,
            _that.state,
            _that.createdAt,
            _that.tags,
            _that.isShared,
            _that.description,
            _that.recurrenceRule,
            _that.recurrenceEnd,
            _that.parentId,
            _that.tagGroupId,
            _that.sourceTodoId,
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
            @JsonKey(name: 'start_time') DateTime startTime,
            @JsonKey(name: 'end_time') DateTime endTime,
            ScheduleState state,
            @JsonKey(name: 'created_at') DateTime createdAt,
            List<TagRead> tags,
            @JsonKey(name: 'is_shared') bool isShared,
            String? description,
            @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
            @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
            @JsonKey(name: 'parent_id') String? parentId,
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'source_todo_id') String? sourceTodoId,
            @JsonKey(name: 'owner_id') String? ownerId,
            @JsonKey(name: 'visibility_level')
            VisibilityLevel? visibilityLevel)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleRead() when $default != null:
        return $default(
            _that.id,
            _that.title,
            _that.startTime,
            _that.endTime,
            _that.state,
            _that.createdAt,
            _that.tags,
            _that.isShared,
            _that.description,
            _that.recurrenceRule,
            _that.recurrenceEnd,
            _that.parentId,
            _that.tagGroupId,
            _that.sourceTodoId,
            _that.ownerId,
            _that.visibilityLevel);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ScheduleRead implements ScheduleRead {
  const _ScheduleRead(
      {required this.id,
      required this.title,
      @JsonKey(name: 'start_time') required this.startTime,
      @JsonKey(name: 'end_time') required this.endTime,
      required this.state,
      @JsonKey(name: 'created_at') required this.createdAt,
      final List<TagRead> tags = const [],
      @JsonKey(name: 'is_shared') this.isShared = false,
      this.description,
      @JsonKey(name: 'recurrence_rule') this.recurrenceRule,
      @JsonKey(name: 'recurrence_end') this.recurrenceEnd,
      @JsonKey(name: 'parent_id') this.parentId,
      @JsonKey(name: 'tag_group_id') this.tagGroupId,
      @JsonKey(name: 'source_todo_id') this.sourceTodoId,
      @JsonKey(name: 'owner_id') this.ownerId,
      @JsonKey(name: 'visibility_level') this.visibilityLevel})
      : _tags = tags;
  factory _ScheduleRead.fromJson(Map<String, dynamic> json) =>
      _$ScheduleReadFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @override
  @JsonKey(name: 'end_time')
  final DateTime endTime;
  @override
  final ScheduleState state;
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

  @override
  @JsonKey(name: 'is_shared')
  final bool isShared;
  @override
  final String? description;
  @override
  @JsonKey(name: 'recurrence_rule')
  final String? recurrenceRule;
  @override
  @JsonKey(name: 'recurrence_end')
  final DateTime? recurrenceEnd;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @override
  @JsonKey(name: 'tag_group_id')
  final String? tagGroupId;
  @override
  @JsonKey(name: 'source_todo_id')
  final String? sourceTodoId;
  @override
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  @override
  @JsonKey(name: 'visibility_level')
  final VisibilityLevel? visibilityLevel;

  /// Create a copy of ScheduleRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScheduleReadCopyWith<_ScheduleRead> get copyWith =>
      __$ScheduleReadCopyWithImpl<_ScheduleRead>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ScheduleReadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScheduleRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.isShared, isShared) ||
                other.isShared == isShared) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.recurrenceEnd, recurrenceEnd) ||
                other.recurrenceEnd == recurrenceEnd) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.sourceTodoId, sourceTodoId) ||
                other.sourceTodoId == sourceTodoId) &&
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
      startTime,
      endTime,
      state,
      createdAt,
      const DeepCollectionEquality().hash(_tags),
      isShared,
      description,
      recurrenceRule,
      recurrenceEnd,
      parentId,
      tagGroupId,
      sourceTodoId,
      ownerId,
      visibilityLevel);

  @override
  String toString() {
    return 'ScheduleRead(id: $id, title: $title, startTime: $startTime, endTime: $endTime, state: $state, createdAt: $createdAt, tags: $tags, isShared: $isShared, description: $description, recurrenceRule: $recurrenceRule, recurrenceEnd: $recurrenceEnd, parentId: $parentId, tagGroupId: $tagGroupId, sourceTodoId: $sourceTodoId, ownerId: $ownerId, visibilityLevel: $visibilityLevel)';
  }
}

/// @nodoc
abstract mixin class _$ScheduleReadCopyWith<$Res>
    implements $ScheduleReadCopyWith<$Res> {
  factory _$ScheduleReadCopyWith(
          _ScheduleRead value, $Res Function(_ScheduleRead) _then) =
      __$ScheduleReadCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'end_time') DateTime endTime,
      ScheduleState state,
      @JsonKey(name: 'created_at') DateTime createdAt,
      List<TagRead> tags,
      @JsonKey(name: 'is_shared') bool isShared,
      String? description,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'tag_group_id') String? tagGroupId,
      @JsonKey(name: 'source_todo_id') String? sourceTodoId,
      @JsonKey(name: 'owner_id') String? ownerId,
      @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel});
}

/// @nodoc
class __$ScheduleReadCopyWithImpl<$Res>
    implements _$ScheduleReadCopyWith<$Res> {
  __$ScheduleReadCopyWithImpl(this._self, this._then);

  final _ScheduleRead _self;
  final $Res Function(_ScheduleRead) _then;

  /// Create a copy of ScheduleRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? state = null,
    Object? createdAt = null,
    Object? tags = null,
    Object? isShared = null,
    Object? description = freezed,
    Object? recurrenceRule = freezed,
    Object? recurrenceEnd = freezed,
    Object? parentId = freezed,
    Object? tagGroupId = freezed,
    Object? sourceTodoId = freezed,
    Object? ownerId = freezed,
    Object? visibilityLevel = freezed,
  }) {
    return _then(_ScheduleRead(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as ScheduleState,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagRead>,
      isShared: null == isShared
          ? _self.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceRule: freezed == recurrenceRule
          ? _self.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceEnd: freezed == recurrenceEnd
          ? _self.recurrenceEnd
          : recurrenceEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      tagGroupId: freezed == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceTodoId: freezed == sourceTodoId
          ? _self.sourceTodoId
          : sourceTodoId // ignore: cast_nullable_to_non_nullable
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
