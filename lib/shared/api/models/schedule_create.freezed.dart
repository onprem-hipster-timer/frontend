// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_create.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleCreate {
  String get title;
  @JsonKey(name: 'start_time')
  DateTime get startTime;
  @JsonKey(name: 'end_time')
  DateTime get endTime;
  ScheduleState? get state;
  String? get description;
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
  @JsonKey(name: 'create_todo_options')
  CreateTodoOptions? get createTodoOptions;
  VisibilitySettings? get visibility;

  /// Create a copy of ScheduleCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScheduleCreateCopyWith<ScheduleCreate> get copyWith =>
      _$ScheduleCreateCopyWithImpl<ScheduleCreate>(
          this as ScheduleCreate, _$identity);

  /// Serializes this ScheduleCreate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScheduleCreate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.recurrenceEnd, recurrenceEnd) ||
                other.recurrenceEnd == recurrenceEnd) &&
            const DeepCollectionEquality().equals(other.tagIds, tagIds) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.sourceTodoId, sourceTodoId) ||
                other.sourceTodoId == sourceTodoId) &&
            (identical(other.createTodoOptions, createTodoOptions) ||
                other.createTodoOptions == createTodoOptions) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      startTime,
      endTime,
      state,
      description,
      recurrenceRule,
      recurrenceEnd,
      const DeepCollectionEquality().hash(tagIds),
      tagGroupId,
      sourceTodoId,
      createTodoOptions,
      visibility);

  @override
  String toString() {
    return 'ScheduleCreate(title: $title, startTime: $startTime, endTime: $endTime, state: $state, description: $description, recurrenceRule: $recurrenceRule, recurrenceEnd: $recurrenceEnd, tagIds: $tagIds, tagGroupId: $tagGroupId, sourceTodoId: $sourceTodoId, createTodoOptions: $createTodoOptions, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class $ScheduleCreateCopyWith<$Res> {
  factory $ScheduleCreateCopyWith(
          ScheduleCreate value, $Res Function(ScheduleCreate) _then) =
      _$ScheduleCreateCopyWithImpl;
  @useResult
  $Res call(
      {String title,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'end_time') DateTime endTime,
      ScheduleState? state,
      String? description,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      @JsonKey(name: 'tag_group_id') String? tagGroupId,
      @JsonKey(name: 'source_todo_id') String? sourceTodoId,
      @JsonKey(name: 'create_todo_options')
      CreateTodoOptions? createTodoOptions,
      VisibilitySettings? visibility});

  $CreateTodoOptionsCopyWith<$Res>? get createTodoOptions;
  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class _$ScheduleCreateCopyWithImpl<$Res>
    implements $ScheduleCreateCopyWith<$Res> {
  _$ScheduleCreateCopyWithImpl(this._self, this._then);

  final ScheduleCreate _self;
  final $Res Function(ScheduleCreate) _then;

  /// Create a copy of ScheduleCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? state = freezed,
    Object? description = freezed,
    Object? recurrenceRule = freezed,
    Object? recurrenceEnd = freezed,
    Object? tagIds = freezed,
    Object? tagGroupId = freezed,
    Object? sourceTodoId = freezed,
    Object? createTodoOptions = freezed,
    Object? visibility = freezed,
  }) {
    return _then(_self.copyWith(
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
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as ScheduleState?,
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
      createTodoOptions: freezed == createTodoOptions
          ? _self.createTodoOptions
          : createTodoOptions // ignore: cast_nullable_to_non_nullable
              as CreateTodoOptions?,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of ScheduleCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreateTodoOptionsCopyWith<$Res>? get createTodoOptions {
    if (_self.createTodoOptions == null) {
      return null;
    }

    return $CreateTodoOptionsCopyWith<$Res>(_self.createTodoOptions!, (value) {
      return _then(_self.copyWith(createTodoOptions: value));
    });
  }

  /// Create a copy of ScheduleCreate
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

/// Adds pattern-matching-related methods to [ScheduleCreate].
extension ScheduleCreatePatterns on ScheduleCreate {
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
    TResult Function(_ScheduleCreate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleCreate() when $default != null:
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
    TResult Function(_ScheduleCreate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleCreate():
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
    TResult? Function(_ScheduleCreate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleCreate() when $default != null:
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
            String title,
            @JsonKey(name: 'start_time') DateTime startTime,
            @JsonKey(name: 'end_time') DateTime endTime,
            ScheduleState? state,
            String? description,
            @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
            @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'source_todo_id') String? sourceTodoId,
            @JsonKey(name: 'create_todo_options')
            CreateTodoOptions? createTodoOptions,
            VisibilitySettings? visibility)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleCreate() when $default != null:
        return $default(
            _that.title,
            _that.startTime,
            _that.endTime,
            _that.state,
            _that.description,
            _that.recurrenceRule,
            _that.recurrenceEnd,
            _that.tagIds,
            _that.tagGroupId,
            _that.sourceTodoId,
            _that.createTodoOptions,
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
            String title,
            @JsonKey(name: 'start_time') DateTime startTime,
            @JsonKey(name: 'end_time') DateTime endTime,
            ScheduleState? state,
            String? description,
            @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
            @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'source_todo_id') String? sourceTodoId,
            @JsonKey(name: 'create_todo_options')
            CreateTodoOptions? createTodoOptions,
            VisibilitySettings? visibility)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleCreate():
        return $default(
            _that.title,
            _that.startTime,
            _that.endTime,
            _that.state,
            _that.description,
            _that.recurrenceRule,
            _that.recurrenceEnd,
            _that.tagIds,
            _that.tagGroupId,
            _that.sourceTodoId,
            _that.createTodoOptions,
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
            String title,
            @JsonKey(name: 'start_time') DateTime startTime,
            @JsonKey(name: 'end_time') DateTime endTime,
            ScheduleState? state,
            String? description,
            @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
            @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'source_todo_id') String? sourceTodoId,
            @JsonKey(name: 'create_todo_options')
            CreateTodoOptions? createTodoOptions,
            VisibilitySettings? visibility)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleCreate() when $default != null:
        return $default(
            _that.title,
            _that.startTime,
            _that.endTime,
            _that.state,
            _that.description,
            _that.recurrenceRule,
            _that.recurrenceEnd,
            _that.tagIds,
            _that.tagGroupId,
            _that.sourceTodoId,
            _that.createTodoOptions,
            _that.visibility);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ScheduleCreate implements ScheduleCreate {
  const _ScheduleCreate(
      {required this.title,
      @JsonKey(name: 'start_time') required this.startTime,
      @JsonKey(name: 'end_time') required this.endTime,
      this.state = ScheduleState.planned,
      this.description,
      @JsonKey(name: 'recurrence_rule') this.recurrenceRule,
      @JsonKey(name: 'recurrence_end') this.recurrenceEnd,
      @JsonKey(name: 'tag_ids') final List<String>? tagIds,
      @JsonKey(name: 'tag_group_id') this.tagGroupId,
      @JsonKey(name: 'source_todo_id') this.sourceTodoId,
      @JsonKey(name: 'create_todo_options') this.createTodoOptions,
      this.visibility})
      : _tagIds = tagIds;
  factory _ScheduleCreate.fromJson(Map<String, dynamic> json) =>
      _$ScheduleCreateFromJson(json);

  @override
  final String title;
  @override
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @override
  @JsonKey(name: 'end_time')
  final DateTime endTime;
  @override
  @JsonKey()
  final ScheduleState? state;
  @override
  final String? description;
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
  @JsonKey(name: 'create_todo_options')
  final CreateTodoOptions? createTodoOptions;
  @override
  final VisibilitySettings? visibility;

  /// Create a copy of ScheduleCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScheduleCreateCopyWith<_ScheduleCreate> get copyWith =>
      __$ScheduleCreateCopyWithImpl<_ScheduleCreate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ScheduleCreateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScheduleCreate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.recurrenceEnd, recurrenceEnd) ||
                other.recurrenceEnd == recurrenceEnd) &&
            const DeepCollectionEquality().equals(other._tagIds, _tagIds) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.sourceTodoId, sourceTodoId) ||
                other.sourceTodoId == sourceTodoId) &&
            (identical(other.createTodoOptions, createTodoOptions) ||
                other.createTodoOptions == createTodoOptions) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      startTime,
      endTime,
      state,
      description,
      recurrenceRule,
      recurrenceEnd,
      const DeepCollectionEquality().hash(_tagIds),
      tagGroupId,
      sourceTodoId,
      createTodoOptions,
      visibility);

  @override
  String toString() {
    return 'ScheduleCreate(title: $title, startTime: $startTime, endTime: $endTime, state: $state, description: $description, recurrenceRule: $recurrenceRule, recurrenceEnd: $recurrenceEnd, tagIds: $tagIds, tagGroupId: $tagGroupId, sourceTodoId: $sourceTodoId, createTodoOptions: $createTodoOptions, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class _$ScheduleCreateCopyWith<$Res>
    implements $ScheduleCreateCopyWith<$Res> {
  factory _$ScheduleCreateCopyWith(
          _ScheduleCreate value, $Res Function(_ScheduleCreate) _then) =
      __$ScheduleCreateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String title,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'end_time') DateTime endTime,
      ScheduleState? state,
      String? description,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      @JsonKey(name: 'tag_group_id') String? tagGroupId,
      @JsonKey(name: 'source_todo_id') String? sourceTodoId,
      @JsonKey(name: 'create_todo_options')
      CreateTodoOptions? createTodoOptions,
      VisibilitySettings? visibility});

  @override
  $CreateTodoOptionsCopyWith<$Res>? get createTodoOptions;
  @override
  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class __$ScheduleCreateCopyWithImpl<$Res>
    implements _$ScheduleCreateCopyWith<$Res> {
  __$ScheduleCreateCopyWithImpl(this._self, this._then);

  final _ScheduleCreate _self;
  final $Res Function(_ScheduleCreate) _then;

  /// Create a copy of ScheduleCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? state = freezed,
    Object? description = freezed,
    Object? recurrenceRule = freezed,
    Object? recurrenceEnd = freezed,
    Object? tagIds = freezed,
    Object? tagGroupId = freezed,
    Object? sourceTodoId = freezed,
    Object? createTodoOptions = freezed,
    Object? visibility = freezed,
  }) {
    return _then(_ScheduleCreate(
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
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as ScheduleState?,
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
      createTodoOptions: freezed == createTodoOptions
          ? _self.createTodoOptions
          : createTodoOptions // ignore: cast_nullable_to_non_nullable
              as CreateTodoOptions?,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of ScheduleCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreateTodoOptionsCopyWith<$Res>? get createTodoOptions {
    if (_self.createTodoOptions == null) {
      return null;
    }

    return $CreateTodoOptionsCopyWith<$Res>(_self.createTodoOptions!, (value) {
      return _then(_self.copyWith(createTodoOptions: value));
    });
  }

  /// Create a copy of ScheduleCreate
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
