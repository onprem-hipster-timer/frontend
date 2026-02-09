// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timer_read.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimerRead {
  String get id;
  @JsonKey(name: 'allocated_duration')
  int get allocatedDuration;
  @JsonKey(name: 'elapsed_time')
  int get elapsedTime;
  String get status;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @JsonKey(name: 'pause_history')
  List<dynamic> get pauseHistory;
  List<TagRead> get tags;
  @JsonKey(name: 'is_shared')
  bool get isShared;
  @JsonKey(name: 'schedule_id')
  String? get scheduleId;
  @JsonKey(name: 'todo_id')
  String? get todoId;
  String? get title;
  String? get description;
  @JsonKey(name: 'started_at')
  DateTime? get startedAt;
  @JsonKey(name: 'paused_at')
  DateTime? get pausedAt;
  @JsonKey(name: 'ended_at')
  DateTime? get endedAt;
  ScheduleRead? get schedule;
  TodoRead? get todo;
  @JsonKey(name: 'owner_id')
  String? get ownerId;
  @JsonKey(name: 'visibility_level')
  VisibilityLevel? get visibilityLevel;

  /// Create a copy of TimerRead
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TimerReadCopyWith<TimerRead> get copyWith =>
      _$TimerReadCopyWithImpl<TimerRead>(this as TimerRead, _$identity);

  /// Serializes this TimerRead to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TimerRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.allocatedDuration, allocatedDuration) ||
                other.allocatedDuration == allocatedDuration) &&
            (identical(other.elapsedTime, elapsedTime) ||
                other.elapsedTime == elapsedTime) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality()
                .equals(other.pauseHistory, pauseHistory) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.isShared, isShared) ||
                other.isShared == isShared) &&
            (identical(other.scheduleId, scheduleId) ||
                other.scheduleId == scheduleId) &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.pausedAt, pausedAt) ||
                other.pausedAt == pausedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.schedule, schedule) ||
                other.schedule == schedule) &&
            (identical(other.todo, todo) || other.todo == todo) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.visibilityLevel, visibilityLevel) ||
                other.visibilityLevel == visibilityLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        allocatedDuration,
        elapsedTime,
        status,
        createdAt,
        updatedAt,
        const DeepCollectionEquality().hash(pauseHistory),
        const DeepCollectionEquality().hash(tags),
        isShared,
        scheduleId,
        todoId,
        title,
        description,
        startedAt,
        pausedAt,
        endedAt,
        schedule,
        todo,
        ownerId,
        visibilityLevel
      ]);

  @override
  String toString() {
    return 'TimerRead(id: $id, allocatedDuration: $allocatedDuration, elapsedTime: $elapsedTime, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, pauseHistory: $pauseHistory, tags: $tags, isShared: $isShared, scheduleId: $scheduleId, todoId: $todoId, title: $title, description: $description, startedAt: $startedAt, pausedAt: $pausedAt, endedAt: $endedAt, schedule: $schedule, todo: $todo, ownerId: $ownerId, visibilityLevel: $visibilityLevel)';
  }
}

/// @nodoc
abstract mixin class $TimerReadCopyWith<$Res> {
  factory $TimerReadCopyWith(TimerRead value, $Res Function(TimerRead) _then) =
      _$TimerReadCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'allocated_duration') int allocatedDuration,
      @JsonKey(name: 'elapsed_time') int elapsedTime,
      String status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'pause_history') List<dynamic> pauseHistory,
      List<TagRead> tags,
      @JsonKey(name: 'is_shared') bool isShared,
      @JsonKey(name: 'schedule_id') String? scheduleId,
      @JsonKey(name: 'todo_id') String? todoId,
      String? title,
      String? description,
      @JsonKey(name: 'started_at') DateTime? startedAt,
      @JsonKey(name: 'paused_at') DateTime? pausedAt,
      @JsonKey(name: 'ended_at') DateTime? endedAt,
      ScheduleRead? schedule,
      TodoRead? todo,
      @JsonKey(name: 'owner_id') String? ownerId,
      @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel});

  $ScheduleReadCopyWith<$Res>? get schedule;
  $TodoReadCopyWith<$Res>? get todo;
}

/// @nodoc
class _$TimerReadCopyWithImpl<$Res> implements $TimerReadCopyWith<$Res> {
  _$TimerReadCopyWithImpl(this._self, this._then);

  final TimerRead _self;
  final $Res Function(TimerRead) _then;

  /// Create a copy of TimerRead
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? allocatedDuration = null,
    Object? elapsedTime = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? pauseHistory = null,
    Object? tags = null,
    Object? isShared = null,
    Object? scheduleId = freezed,
    Object? todoId = freezed,
    Object? title = freezed,
    Object? description = freezed,
    Object? startedAt = freezed,
    Object? pausedAt = freezed,
    Object? endedAt = freezed,
    Object? schedule = freezed,
    Object? todo = freezed,
    Object? ownerId = freezed,
    Object? visibilityLevel = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      allocatedDuration: null == allocatedDuration
          ? _self.allocatedDuration
          : allocatedDuration // ignore: cast_nullable_to_non_nullable
              as int,
      elapsedTime: null == elapsedTime
          ? _self.elapsedTime
          : elapsedTime // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      pauseHistory: null == pauseHistory
          ? _self.pauseHistory
          : pauseHistory // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagRead>,
      isShared: null == isShared
          ? _self.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      scheduleId: freezed == scheduleId
          ? _self.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String?,
      todoId: freezed == todoId
          ? _self.todoId
          : todoId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pausedAt: freezed == pausedAt
          ? _self.pausedAt
          : pausedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endedAt: freezed == endedAt
          ? _self.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      schedule: freezed == schedule
          ? _self.schedule
          : schedule // ignore: cast_nullable_to_non_nullable
              as ScheduleRead?,
      todo: freezed == todo
          ? _self.todo
          : todo // ignore: cast_nullable_to_non_nullable
              as TodoRead?,
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

  /// Create a copy of TimerRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScheduleReadCopyWith<$Res>? get schedule {
    if (_self.schedule == null) {
      return null;
    }

    return $ScheduleReadCopyWith<$Res>(_self.schedule!, (value) {
      return _then(_self.copyWith(schedule: value));
    });
  }

  /// Create a copy of TimerRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TodoReadCopyWith<$Res>? get todo {
    if (_self.todo == null) {
      return null;
    }

    return $TodoReadCopyWith<$Res>(_self.todo!, (value) {
      return _then(_self.copyWith(todo: value));
    });
  }
}

/// Adds pattern-matching-related methods to [TimerRead].
extension TimerReadPatterns on TimerRead {
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
    TResult Function(_TimerRead value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TimerRead() when $default != null:
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
    TResult Function(_TimerRead value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TimerRead():
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
    TResult? Function(_TimerRead value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TimerRead() when $default != null:
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
            @JsonKey(name: 'allocated_duration') int allocatedDuration,
            @JsonKey(name: 'elapsed_time') int elapsedTime,
            String status,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            @JsonKey(name: 'pause_history') List<dynamic> pauseHistory,
            List<TagRead> tags,
            @JsonKey(name: 'is_shared') bool isShared,
            @JsonKey(name: 'schedule_id') String? scheduleId,
            @JsonKey(name: 'todo_id') String? todoId,
            String? title,
            String? description,
            @JsonKey(name: 'started_at') DateTime? startedAt,
            @JsonKey(name: 'paused_at') DateTime? pausedAt,
            @JsonKey(name: 'ended_at') DateTime? endedAt,
            ScheduleRead? schedule,
            TodoRead? todo,
            @JsonKey(name: 'owner_id') String? ownerId,
            @JsonKey(name: 'visibility_level')
            VisibilityLevel? visibilityLevel)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TimerRead() when $default != null:
        return $default(
            _that.id,
            _that.allocatedDuration,
            _that.elapsedTime,
            _that.status,
            _that.createdAt,
            _that.updatedAt,
            _that.pauseHistory,
            _that.tags,
            _that.isShared,
            _that.scheduleId,
            _that.todoId,
            _that.title,
            _that.description,
            _that.startedAt,
            _that.pausedAt,
            _that.endedAt,
            _that.schedule,
            _that.todo,
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
            @JsonKey(name: 'allocated_duration') int allocatedDuration,
            @JsonKey(name: 'elapsed_time') int elapsedTime,
            String status,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            @JsonKey(name: 'pause_history') List<dynamic> pauseHistory,
            List<TagRead> tags,
            @JsonKey(name: 'is_shared') bool isShared,
            @JsonKey(name: 'schedule_id') String? scheduleId,
            @JsonKey(name: 'todo_id') String? todoId,
            String? title,
            String? description,
            @JsonKey(name: 'started_at') DateTime? startedAt,
            @JsonKey(name: 'paused_at') DateTime? pausedAt,
            @JsonKey(name: 'ended_at') DateTime? endedAt,
            ScheduleRead? schedule,
            TodoRead? todo,
            @JsonKey(name: 'owner_id') String? ownerId,
            @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TimerRead():
        return $default(
            _that.id,
            _that.allocatedDuration,
            _that.elapsedTime,
            _that.status,
            _that.createdAt,
            _that.updatedAt,
            _that.pauseHistory,
            _that.tags,
            _that.isShared,
            _that.scheduleId,
            _that.todoId,
            _that.title,
            _that.description,
            _that.startedAt,
            _that.pausedAt,
            _that.endedAt,
            _that.schedule,
            _that.todo,
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
            @JsonKey(name: 'allocated_duration') int allocatedDuration,
            @JsonKey(name: 'elapsed_time') int elapsedTime,
            String status,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime updatedAt,
            @JsonKey(name: 'pause_history') List<dynamic> pauseHistory,
            List<TagRead> tags,
            @JsonKey(name: 'is_shared') bool isShared,
            @JsonKey(name: 'schedule_id') String? scheduleId,
            @JsonKey(name: 'todo_id') String? todoId,
            String? title,
            String? description,
            @JsonKey(name: 'started_at') DateTime? startedAt,
            @JsonKey(name: 'paused_at') DateTime? pausedAt,
            @JsonKey(name: 'ended_at') DateTime? endedAt,
            ScheduleRead? schedule,
            TodoRead? todo,
            @JsonKey(name: 'owner_id') String? ownerId,
            @JsonKey(name: 'visibility_level')
            VisibilityLevel? visibilityLevel)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TimerRead() when $default != null:
        return $default(
            _that.id,
            _that.allocatedDuration,
            _that.elapsedTime,
            _that.status,
            _that.createdAt,
            _that.updatedAt,
            _that.pauseHistory,
            _that.tags,
            _that.isShared,
            _that.scheduleId,
            _that.todoId,
            _that.title,
            _that.description,
            _that.startedAt,
            _that.pausedAt,
            _that.endedAt,
            _that.schedule,
            _that.todo,
            _that.ownerId,
            _that.visibilityLevel);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TimerRead implements TimerRead {
  const _TimerRead(
      {required this.id,
      @JsonKey(name: 'allocated_duration') required this.allocatedDuration,
      @JsonKey(name: 'elapsed_time') required this.elapsedTime,
      required this.status,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'pause_history')
      final List<dynamic> pauseHistory = const [],
      final List<TagRead> tags = const [],
      @JsonKey(name: 'is_shared') this.isShared = false,
      @JsonKey(name: 'schedule_id') this.scheduleId,
      @JsonKey(name: 'todo_id') this.todoId,
      this.title,
      this.description,
      @JsonKey(name: 'started_at') this.startedAt,
      @JsonKey(name: 'paused_at') this.pausedAt,
      @JsonKey(name: 'ended_at') this.endedAt,
      this.schedule,
      this.todo,
      @JsonKey(name: 'owner_id') this.ownerId,
      @JsonKey(name: 'visibility_level') this.visibilityLevel})
      : _pauseHistory = pauseHistory,
        _tags = tags;
  factory _TimerRead.fromJson(Map<String, dynamic> json) =>
      _$TimerReadFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'allocated_duration')
  final int allocatedDuration;
  @override
  @JsonKey(name: 'elapsed_time')
  final int elapsedTime;
  @override
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final List<dynamic> _pauseHistory;
  @override
  @JsonKey(name: 'pause_history')
  List<dynamic> get pauseHistory {
    if (_pauseHistory is EqualUnmodifiableListView) return _pauseHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pauseHistory);
  }

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
  @JsonKey(name: 'schedule_id')
  final String? scheduleId;
  @override
  @JsonKey(name: 'todo_id')
  final String? todoId;
  @override
  final String? title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @override
  @JsonKey(name: 'paused_at')
  final DateTime? pausedAt;
  @override
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;
  @override
  final ScheduleRead? schedule;
  @override
  final TodoRead? todo;
  @override
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  @override
  @JsonKey(name: 'visibility_level')
  final VisibilityLevel? visibilityLevel;

  /// Create a copy of TimerRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TimerReadCopyWith<_TimerRead> get copyWith =>
      __$TimerReadCopyWithImpl<_TimerRead>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TimerReadToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TimerRead &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.allocatedDuration, allocatedDuration) ||
                other.allocatedDuration == allocatedDuration) &&
            (identical(other.elapsedTime, elapsedTime) ||
                other.elapsedTime == elapsedTime) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality()
                .equals(other._pauseHistory, _pauseHistory) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.isShared, isShared) ||
                other.isShared == isShared) &&
            (identical(other.scheduleId, scheduleId) ||
                other.scheduleId == scheduleId) &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.pausedAt, pausedAt) ||
                other.pausedAt == pausedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.schedule, schedule) ||
                other.schedule == schedule) &&
            (identical(other.todo, todo) || other.todo == todo) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.visibilityLevel, visibilityLevel) ||
                other.visibilityLevel == visibilityLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        allocatedDuration,
        elapsedTime,
        status,
        createdAt,
        updatedAt,
        const DeepCollectionEquality().hash(_pauseHistory),
        const DeepCollectionEquality().hash(_tags),
        isShared,
        scheduleId,
        todoId,
        title,
        description,
        startedAt,
        pausedAt,
        endedAt,
        schedule,
        todo,
        ownerId,
        visibilityLevel
      ]);

  @override
  String toString() {
    return 'TimerRead(id: $id, allocatedDuration: $allocatedDuration, elapsedTime: $elapsedTime, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, pauseHistory: $pauseHistory, tags: $tags, isShared: $isShared, scheduleId: $scheduleId, todoId: $todoId, title: $title, description: $description, startedAt: $startedAt, pausedAt: $pausedAt, endedAt: $endedAt, schedule: $schedule, todo: $todo, ownerId: $ownerId, visibilityLevel: $visibilityLevel)';
  }
}

/// @nodoc
abstract mixin class _$TimerReadCopyWith<$Res>
    implements $TimerReadCopyWith<$Res> {
  factory _$TimerReadCopyWith(
          _TimerRead value, $Res Function(_TimerRead) _then) =
      __$TimerReadCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'allocated_duration') int allocatedDuration,
      @JsonKey(name: 'elapsed_time') int elapsedTime,
      String status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'pause_history') List<dynamic> pauseHistory,
      List<TagRead> tags,
      @JsonKey(name: 'is_shared') bool isShared,
      @JsonKey(name: 'schedule_id') String? scheduleId,
      @JsonKey(name: 'todo_id') String? todoId,
      String? title,
      String? description,
      @JsonKey(name: 'started_at') DateTime? startedAt,
      @JsonKey(name: 'paused_at') DateTime? pausedAt,
      @JsonKey(name: 'ended_at') DateTime? endedAt,
      ScheduleRead? schedule,
      TodoRead? todo,
      @JsonKey(name: 'owner_id') String? ownerId,
      @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel});

  @override
  $ScheduleReadCopyWith<$Res>? get schedule;
  @override
  $TodoReadCopyWith<$Res>? get todo;
}

/// @nodoc
class __$TimerReadCopyWithImpl<$Res> implements _$TimerReadCopyWith<$Res> {
  __$TimerReadCopyWithImpl(this._self, this._then);

  final _TimerRead _self;
  final $Res Function(_TimerRead) _then;

  /// Create a copy of TimerRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? allocatedDuration = null,
    Object? elapsedTime = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? pauseHistory = null,
    Object? tags = null,
    Object? isShared = null,
    Object? scheduleId = freezed,
    Object? todoId = freezed,
    Object? title = freezed,
    Object? description = freezed,
    Object? startedAt = freezed,
    Object? pausedAt = freezed,
    Object? endedAt = freezed,
    Object? schedule = freezed,
    Object? todo = freezed,
    Object? ownerId = freezed,
    Object? visibilityLevel = freezed,
  }) {
    return _then(_TimerRead(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      allocatedDuration: null == allocatedDuration
          ? _self.allocatedDuration
          : allocatedDuration // ignore: cast_nullable_to_non_nullable
              as int,
      elapsedTime: null == elapsedTime
          ? _self.elapsedTime
          : elapsedTime // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      pauseHistory: null == pauseHistory
          ? _self._pauseHistory
          : pauseHistory // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagRead>,
      isShared: null == isShared
          ? _self.isShared
          : isShared // ignore: cast_nullable_to_non_nullable
              as bool,
      scheduleId: freezed == scheduleId
          ? _self.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String?,
      todoId: freezed == todoId
          ? _self.todoId
          : todoId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pausedAt: freezed == pausedAt
          ? _self.pausedAt
          : pausedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endedAt: freezed == endedAt
          ? _self.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      schedule: freezed == schedule
          ? _self.schedule
          : schedule // ignore: cast_nullable_to_non_nullable
              as ScheduleRead?,
      todo: freezed == todo
          ? _self.todo
          : todo // ignore: cast_nullable_to_non_nullable
              as TodoRead?,
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

  /// Create a copy of TimerRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScheduleReadCopyWith<$Res>? get schedule {
    if (_self.schedule == null) {
      return null;
    }

    return $ScheduleReadCopyWith<$Res>(_self.schedule!, (value) {
      return _then(_self.copyWith(schedule: value));
    });
  }

  /// Create a copy of TimerRead
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TodoReadCopyWith<$Res>? get todo {
    if (_self.todo == null) {
      return null;
    }

    return $TodoReadCopyWith<$Res>(_self.todo!, (value) {
      return _then(_self.copyWith(todo: value));
    });
  }
}

// dart format on
