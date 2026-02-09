// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleUpdate {
  String? get title;
  String? get description;
  @JsonKey(name: 'start_time')
  DateTime? get startTime;
  @JsonKey(name: 'end_time')
  DateTime? get endTime;
  @JsonKey(name: 'recurrence_rule')
  String? get recurrenceRule;
  @JsonKey(name: 'recurrence_end')
  DateTime? get recurrenceEnd;
  @JsonKey(name: 'tag_ids')
  List<String>? get tagIds;
  @JsonKey(name: 'tag_group_id')
  String? get tagGroupId;
  @JsonKey(name: 'source_todo_id')
  String? get sourceTodoId;
  ScheduleState? get state;
  VisibilitySettings? get visibility;

  /// Create a copy of ScheduleUpdate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScheduleUpdateCopyWith<ScheduleUpdate> get copyWith =>
      _$ScheduleUpdateCopyWithImpl<ScheduleUpdate>(
          this as ScheduleUpdate, _$identity);

  /// Serializes this ScheduleUpdate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScheduleUpdate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.recurrenceEnd, recurrenceEnd) ||
                other.recurrenceEnd == recurrenceEnd) &&
            const DeepCollectionEquality().equals(other.tagIds, tagIds) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.sourceTodoId, sourceTodoId) ||
                other.sourceTodoId == sourceTodoId) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      startTime,
      endTime,
      recurrenceRule,
      recurrenceEnd,
      const DeepCollectionEquality().hash(tagIds),
      tagGroupId,
      sourceTodoId,
      state,
      visibility);

  @override
  String toString() {
    return 'ScheduleUpdate(title: $title, description: $description, startTime: $startTime, endTime: $endTime, recurrenceRule: $recurrenceRule, recurrenceEnd: $recurrenceEnd, tagIds: $tagIds, tagGroupId: $tagGroupId, sourceTodoId: $sourceTodoId, state: $state, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class $ScheduleUpdateCopyWith<$Res> {
  factory $ScheduleUpdateCopyWith(
          ScheduleUpdate value, $Res Function(ScheduleUpdate) _then) =
      _$ScheduleUpdateCopyWithImpl;
  @useResult
  $Res call(
      {String? title,
      String? description,
      @JsonKey(name: 'start_time') DateTime? startTime,
      @JsonKey(name: 'end_time') DateTime? endTime,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      @JsonKey(name: 'tag_group_id') String? tagGroupId,
      @JsonKey(name: 'source_todo_id') String? sourceTodoId,
      ScheduleState? state,
      VisibilitySettings? visibility});

  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class _$ScheduleUpdateCopyWithImpl<$Res>
    implements $ScheduleUpdateCopyWith<$Res> {
  _$ScheduleUpdateCopyWithImpl(this._self, this._then);

  final ScheduleUpdate _self;
  final $Res Function(ScheduleUpdate) _then;

  /// Create a copy of ScheduleUpdate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? recurrenceRule = freezed,
    Object? recurrenceEnd = freezed,
    Object? tagIds = freezed,
    Object? tagGroupId = freezed,
    Object? sourceTodoId = freezed,
    Object? state = freezed,
    Object? visibility = freezed,
  }) {
    return _then(_self.copyWith(
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: freezed == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      recurrenceRule: freezed == recurrenceRule
          ? _self.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceEnd: freezed == recurrenceEnd
          ? _self.recurrenceEnd
          : recurrenceEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tagIds: freezed == tagIds
          ? _self.tagIds
          : tagIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tagGroupId: freezed == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceTodoId: freezed == sourceTodoId
          ? _self.sourceTodoId
          : sourceTodoId // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as ScheduleState?,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of ScheduleUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VisibilitySettingsCopyWith<$Res>? get visibility {
    if (_self.visibility == null) {
      return null;
    }

    return $VisibilitySettingsCopyWith<$Res>(_self.visibility!, (value) {
      return _then(_self.copyWith(visibility: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ScheduleUpdate].
extension ScheduleUpdatePatterns on ScheduleUpdate {
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
    TResult Function(_ScheduleUpdate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleUpdate() when $default != null:
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
    TResult Function(_ScheduleUpdate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleUpdate():
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
    TResult? Function(_ScheduleUpdate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleUpdate() when $default != null:
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
            String? title,
            String? description,
            @JsonKey(name: 'start_time') DateTime? startTime,
            @JsonKey(name: 'end_time') DateTime? endTime,
            @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
            @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'source_todo_id') String? sourceTodoId,
            ScheduleState? state,
            VisibilitySettings? visibility)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleUpdate() when $default != null:
        return $default(
            _that.title,
            _that.description,
            _that.startTime,
            _that.endTime,
            _that.recurrenceRule,
            _that.recurrenceEnd,
            _that.tagIds,
            _that.tagGroupId,
            _that.sourceTodoId,
            _that.state,
            _that.visibility);
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
            String? title,
            String? description,
            @JsonKey(name: 'start_time') DateTime? startTime,
            @JsonKey(name: 'end_time') DateTime? endTime,
            @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
            @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'source_todo_id') String? sourceTodoId,
            ScheduleState? state,
            VisibilitySettings? visibility)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleUpdate():
        return $default(
            _that.title,
            _that.description,
            _that.startTime,
            _that.endTime,
            _that.recurrenceRule,
            _that.recurrenceEnd,
            _that.tagIds,
            _that.tagGroupId,
            _that.sourceTodoId,
            _that.state,
            _that.visibility);
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
            String? title,
            String? description,
            @JsonKey(name: 'start_time') DateTime? startTime,
            @JsonKey(name: 'end_time') DateTime? endTime,
            @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
            @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'source_todo_id') String? sourceTodoId,
            ScheduleState? state,
            VisibilitySettings? visibility)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleUpdate() when $default != null:
        return $default(
            _that.title,
            _that.description,
            _that.startTime,
            _that.endTime,
            _that.recurrenceRule,
            _that.recurrenceEnd,
            _that.tagIds,
            _that.tagGroupId,
            _that.sourceTodoId,
            _that.state,
            _that.visibility);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ScheduleUpdate implements ScheduleUpdate {
  const _ScheduleUpdate(
      {this.title,
      this.description,
      @JsonKey(name: 'start_time') this.startTime,
      @JsonKey(name: 'end_time') this.endTime,
      @JsonKey(name: 'recurrence_rule') this.recurrenceRule,
      @JsonKey(name: 'recurrence_end') this.recurrenceEnd,
      @JsonKey(name: 'tag_ids') final List<String>? tagIds,
      @JsonKey(name: 'tag_group_id') this.tagGroupId,
      @JsonKey(name: 'source_todo_id') this.sourceTodoId,
      this.state,
      this.visibility})
      : _tagIds = tagIds;
  factory _ScheduleUpdate.fromJson(Map<String, dynamic> json) =>
      _$ScheduleUpdateFromJson(json);

  @override
  final String? title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  @override
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  @override
  @JsonKey(name: 'recurrence_rule')
  final String? recurrenceRule;
  @override
  @JsonKey(name: 'recurrence_end')
  final DateTime? recurrenceEnd;
  final List<String>? _tagIds;
  @override
  @JsonKey(name: 'tag_ids')
  List<String>? get tagIds {
    final value = _tagIds;
    if (value == null) return null;
    if (_tagIds is EqualUnmodifiableListView) return _tagIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'tag_group_id')
  final String? tagGroupId;
  @override
  @JsonKey(name: 'source_todo_id')
  final String? sourceTodoId;
  @override
  final ScheduleState? state;
  @override
  final VisibilitySettings? visibility;

  /// Create a copy of ScheduleUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScheduleUpdateCopyWith<_ScheduleUpdate> get copyWith =>
      __$ScheduleUpdateCopyWithImpl<_ScheduleUpdate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ScheduleUpdateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScheduleUpdate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.recurrenceEnd, recurrenceEnd) ||
                other.recurrenceEnd == recurrenceEnd) &&
            const DeepCollectionEquality().equals(other._tagIds, _tagIds) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.sourceTodoId, sourceTodoId) ||
                other.sourceTodoId == sourceTodoId) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      startTime,
      endTime,
      recurrenceRule,
      recurrenceEnd,
      const DeepCollectionEquality().hash(_tagIds),
      tagGroupId,
      sourceTodoId,
      state,
      visibility);

  @override
  String toString() {
    return 'ScheduleUpdate(title: $title, description: $description, startTime: $startTime, endTime: $endTime, recurrenceRule: $recurrenceRule, recurrenceEnd: $recurrenceEnd, tagIds: $tagIds, tagGroupId: $tagGroupId, sourceTodoId: $sourceTodoId, state: $state, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class _$ScheduleUpdateCopyWith<$Res>
    implements $ScheduleUpdateCopyWith<$Res> {
  factory _$ScheduleUpdateCopyWith(
          _ScheduleUpdate value, $Res Function(_ScheduleUpdate) _then) =
      __$ScheduleUpdateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? title,
      String? description,
      @JsonKey(name: 'start_time') DateTime? startTime,
      @JsonKey(name: 'end_time') DateTime? endTime,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      @JsonKey(name: 'tag_group_id') String? tagGroupId,
      @JsonKey(name: 'source_todo_id') String? sourceTodoId,
      ScheduleState? state,
      VisibilitySettings? visibility});

  @override
  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class __$ScheduleUpdateCopyWithImpl<$Res>
    implements _$ScheduleUpdateCopyWith<$Res> {
  __$ScheduleUpdateCopyWithImpl(this._self, this._then);

  final _ScheduleUpdate _self;
  final $Res Function(_ScheduleUpdate) _then;

  /// Create a copy of ScheduleUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? recurrenceRule = freezed,
    Object? recurrenceEnd = freezed,
    Object? tagIds = freezed,
    Object? tagGroupId = freezed,
    Object? sourceTodoId = freezed,
    Object? state = freezed,
    Object? visibility = freezed,
  }) {
    return _then(_ScheduleUpdate(
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: freezed == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      recurrenceRule: freezed == recurrenceRule
          ? _self.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceEnd: freezed == recurrenceEnd
          ? _self.recurrenceEnd
          : recurrenceEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tagIds: freezed == tagIds
          ? _self._tagIds
          : tagIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tagGroupId: freezed == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceTodoId: freezed == sourceTodoId
          ? _self.sourceTodoId
          : sourceTodoId // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as ScheduleState?,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of ScheduleUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VisibilitySettingsCopyWith<$Res>? get visibility {
    if (_self.visibility == null) {
      return null;
    }

    return $VisibilitySettingsCopyWith<$Res>(_self.visibility!, (value) {
      return _then(_self.copyWith(visibility: value));
    });
  }
}

// dart format on
