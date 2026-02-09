// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timer_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimerUpdate {
  String? get title;
  String? get description;
  @JsonKey(name: 'tag_ids')
  List<String>? get tagIds;
  @JsonKey(name: 'todo_id')
  String? get todoId;
  @JsonKey(name: 'schedule_id')
  String? get scheduleId;
  VisibilitySettings? get visibility;

  /// Create a copy of TimerUpdate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TimerUpdateCopyWith<TimerUpdate> get copyWith =>
      _$TimerUpdateCopyWithImpl<TimerUpdate>(this as TimerUpdate, _$identity);

  /// Serializes this TimerUpdate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TimerUpdate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other.tagIds, tagIds) &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.scheduleId, scheduleId) ||
                other.scheduleId == scheduleId) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      const DeepCollectionEquality().hash(tagIds),
      todoId,
      scheduleId,
      visibility);

  @override
  String toString() {
    return 'TimerUpdate(title: $title, description: $description, tagIds: $tagIds, todoId: $todoId, scheduleId: $scheduleId, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class $TimerUpdateCopyWith<$Res> {
  factory $TimerUpdateCopyWith(
          TimerUpdate value, $Res Function(TimerUpdate) _then) =
      _$TimerUpdateCopyWithImpl;
  @useResult
  $Res call(
      {String? title,
      String? description,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      @JsonKey(name: 'todo_id') String? todoId,
      @JsonKey(name: 'schedule_id') String? scheduleId,
      VisibilitySettings? visibility});

  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class _$TimerUpdateCopyWithImpl<$Res> implements $TimerUpdateCopyWith<$Res> {
  _$TimerUpdateCopyWithImpl(this._self, this._then);

  final TimerUpdate _self;
  final $Res Function(TimerUpdate) _then;

  /// Create a copy of TimerUpdate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? tagIds = freezed,
    Object? todoId = freezed,
    Object? scheduleId = freezed,
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
      tagIds: freezed == tagIds
          ? _self.tagIds
          : tagIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      todoId: freezed == todoId
          ? _self.todoId
          : todoId // ignore: cast_nullable_to_non_nullable
              as String?,
      scheduleId: freezed == scheduleId
          ? _self.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String?,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of TimerUpdate
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

/// Adds pattern-matching-related methods to [TimerUpdate].
extension TimerUpdatePatterns on TimerUpdate {
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
    TResult Function(_TimerUpdate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TimerUpdate() when $default != null:
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
    TResult Function(_TimerUpdate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TimerUpdate():
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
    TResult? Function(_TimerUpdate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TimerUpdate() when $default != null:
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
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            @JsonKey(name: 'todo_id') String? todoId,
            @JsonKey(name: 'schedule_id') String? scheduleId,
            VisibilitySettings? visibility)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TimerUpdate() when $default != null:
        return $default(_that.title, _that.description, _that.tagIds,
            _that.todoId, _that.scheduleId, _that.visibility);
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
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            @JsonKey(name: 'todo_id') String? todoId,
            @JsonKey(name: 'schedule_id') String? scheduleId,
            VisibilitySettings? visibility)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TimerUpdate():
        return $default(_that.title, _that.description, _that.tagIds,
            _that.todoId, _that.scheduleId, _that.visibility);
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
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            @JsonKey(name: 'todo_id') String? todoId,
            @JsonKey(name: 'schedule_id') String? scheduleId,
            VisibilitySettings? visibility)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TimerUpdate() when $default != null:
        return $default(_that.title, _that.description, _that.tagIds,
            _that.todoId, _that.scheduleId, _that.visibility);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TimerUpdate implements TimerUpdate {
  const _TimerUpdate(
      {this.title,
      this.description,
      @JsonKey(name: 'tag_ids') final List<String>? tagIds,
      @JsonKey(name: 'todo_id') this.todoId,
      @JsonKey(name: 'schedule_id') this.scheduleId,
      this.visibility})
      : _tagIds = tagIds;
  factory _TimerUpdate.fromJson(Map<String, dynamic> json) =>
      _$TimerUpdateFromJson(json);

  @override
  final String? title;
  @override
  final String? description;
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
  @JsonKey(name: 'todo_id')
  final String? todoId;
  @override
  @JsonKey(name: 'schedule_id')
  final String? scheduleId;
  @override
  final VisibilitySettings? visibility;

  /// Create a copy of TimerUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TimerUpdateCopyWith<_TimerUpdate> get copyWith =>
      __$TimerUpdateCopyWithImpl<_TimerUpdate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TimerUpdateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TimerUpdate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._tagIds, _tagIds) &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.scheduleId, scheduleId) ||
                other.scheduleId == scheduleId) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      const DeepCollectionEquality().hash(_tagIds),
      todoId,
      scheduleId,
      visibility);

  @override
  String toString() {
    return 'TimerUpdate(title: $title, description: $description, tagIds: $tagIds, todoId: $todoId, scheduleId: $scheduleId, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class _$TimerUpdateCopyWith<$Res>
    implements $TimerUpdateCopyWith<$Res> {
  factory _$TimerUpdateCopyWith(
          _TimerUpdate value, $Res Function(_TimerUpdate) _then) =
      __$TimerUpdateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? title,
      String? description,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      @JsonKey(name: 'todo_id') String? todoId,
      @JsonKey(name: 'schedule_id') String? scheduleId,
      VisibilitySettings? visibility});

  @override
  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class __$TimerUpdateCopyWithImpl<$Res> implements _$TimerUpdateCopyWith<$Res> {
  __$TimerUpdateCopyWithImpl(this._self, this._then);

  final _TimerUpdate _self;
  final $Res Function(_TimerUpdate) _then;

  /// Create a copy of TimerUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? tagIds = freezed,
    Object? todoId = freezed,
    Object? scheduleId = freezed,
    Object? visibility = freezed,
  }) {
    return _then(_TimerUpdate(
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      tagIds: freezed == tagIds
          ? _self._tagIds
          : tagIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      todoId: freezed == todoId
          ? _self.todoId
          : todoId // ignore: cast_nullable_to_non_nullable
              as String?,
      scheduleId: freezed == scheduleId
          ? _self.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String?,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of TimerUpdate
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
