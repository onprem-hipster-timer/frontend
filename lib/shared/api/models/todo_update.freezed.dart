// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TodoUpdate {
  String? get title;
  String? get description;
  @JsonKey(name: 'tag_group_id')
  String? get tagGroupId;
  @JsonKey(name: 'tag_ids')
  List<String>? get tagIds;
  DateTime? get deadline;
  @JsonKey(name: 'parent_id')
  String? get parentId;
  TodoStatus? get status;
  VisibilitySettings? get visibility;

  /// Create a copy of TodoUpdate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TodoUpdateCopyWith<TodoUpdate> get copyWith =>
      _$TodoUpdateCopyWithImpl<TodoUpdate>(this as TodoUpdate, _$identity);

  /// Serializes this TodoUpdate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TodoUpdate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            const DeepCollectionEquality().equals(other.tagIds, tagIds) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      tagGroupId,
      const DeepCollectionEquality().hash(tagIds),
      deadline,
      parentId,
      status,
      visibility);

  @override
  String toString() {
    return 'TodoUpdate(title: $title, description: $description, tagGroupId: $tagGroupId, tagIds: $tagIds, deadline: $deadline, parentId: $parentId, status: $status, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class $TodoUpdateCopyWith<$Res> {
  factory $TodoUpdateCopyWith(
          TodoUpdate value, $Res Function(TodoUpdate) _then) =
      _$TodoUpdateCopyWithImpl;
  @useResult
  $Res call(
      {String? title,
      String? description,
      @JsonKey(name: 'tag_group_id') String? tagGroupId,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      DateTime? deadline,
      @JsonKey(name: 'parent_id') String? parentId,
      TodoStatus? status,
      VisibilitySettings? visibility});

  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class _$TodoUpdateCopyWithImpl<$Res> implements $TodoUpdateCopyWith<$Res> {
  _$TodoUpdateCopyWithImpl(this._self, this._then);

  final TodoUpdate _self;
  final $Res Function(TodoUpdate) _then;

  /// Create a copy of TodoUpdate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? tagGroupId = freezed,
    Object? tagIds = freezed,
    Object? deadline = freezed,
    Object? parentId = freezed,
    Object? status = freezed,
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
      tagGroupId: freezed == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      tagIds: freezed == tagIds
          ? _self.tagIds
          : tagIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      deadline: freezed == deadline
          ? _self.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TodoStatus?,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of TodoUpdate
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

/// Adds pattern-matching-related methods to [TodoUpdate].
extension TodoUpdatePatterns on TodoUpdate {
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
    TResult Function(_TodoUpdate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TodoUpdate() when $default != null:
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
    TResult Function(_TodoUpdate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoUpdate():
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
    TResult? Function(_TodoUpdate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoUpdate() when $default != null:
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
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            DateTime? deadline,
            @JsonKey(name: 'parent_id') String? parentId,
            TodoStatus? status,
            VisibilitySettings? visibility)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TodoUpdate() when $default != null:
        return $default(
            _that.title,
            _that.description,
            _that.tagGroupId,
            _that.tagIds,
            _that.deadline,
            _that.parentId,
            _that.status,
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
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            DateTime? deadline,
            @JsonKey(name: 'parent_id') String? parentId,
            TodoStatus? status,
            VisibilitySettings? visibility)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoUpdate():
        return $default(
            _that.title,
            _that.description,
            _that.tagGroupId,
            _that.tagIds,
            _that.deadline,
            _that.parentId,
            _that.status,
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
            @JsonKey(name: 'tag_group_id') String? tagGroupId,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            DateTime? deadline,
            @JsonKey(name: 'parent_id') String? parentId,
            TodoStatus? status,
            VisibilitySettings? visibility)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoUpdate() when $default != null:
        return $default(
            _that.title,
            _that.description,
            _that.tagGroupId,
            _that.tagIds,
            _that.deadline,
            _that.parentId,
            _that.status,
            _that.visibility);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TodoUpdate implements TodoUpdate {
  const _TodoUpdate(
      {this.title,
      this.description,
      @JsonKey(name: 'tag_group_id') this.tagGroupId,
      @JsonKey(name: 'tag_ids') final List<String>? tagIds,
      this.deadline,
      @JsonKey(name: 'parent_id') this.parentId,
      this.status,
      this.visibility})
      : _tagIds = tagIds;
  factory _TodoUpdate.fromJson(Map<String, dynamic> json) =>
      _$TodoUpdateFromJson(json);

  @override
  final String? title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'tag_group_id')
  final String? tagGroupId;
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
  final DateTime? deadline;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @override
  final TodoStatus? status;
  @override
  final VisibilitySettings? visibility;

  /// Create a copy of TodoUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TodoUpdateCopyWith<_TodoUpdate> get copyWith =>
      __$TodoUpdateCopyWithImpl<_TodoUpdate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TodoUpdateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TodoUpdate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            const DeepCollectionEquality().equals(other._tagIds, _tagIds) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      tagGroupId,
      const DeepCollectionEquality().hash(_tagIds),
      deadline,
      parentId,
      status,
      visibility);

  @override
  String toString() {
    return 'TodoUpdate(title: $title, description: $description, tagGroupId: $tagGroupId, tagIds: $tagIds, deadline: $deadline, parentId: $parentId, status: $status, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class _$TodoUpdateCopyWith<$Res>
    implements $TodoUpdateCopyWith<$Res> {
  factory _$TodoUpdateCopyWith(
          _TodoUpdate value, $Res Function(_TodoUpdate) _then) =
      __$TodoUpdateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? title,
      String? description,
      @JsonKey(name: 'tag_group_id') String? tagGroupId,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      DateTime? deadline,
      @JsonKey(name: 'parent_id') String? parentId,
      TodoStatus? status,
      VisibilitySettings? visibility});

  @override
  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class __$TodoUpdateCopyWithImpl<$Res> implements _$TodoUpdateCopyWith<$Res> {
  __$TodoUpdateCopyWithImpl(this._self, this._then);

  final _TodoUpdate _self;
  final $Res Function(_TodoUpdate) _then;

  /// Create a copy of TodoUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? tagGroupId = freezed,
    Object? tagIds = freezed,
    Object? deadline = freezed,
    Object? parentId = freezed,
    Object? status = freezed,
    Object? visibility = freezed,
  }) {
    return _then(_TodoUpdate(
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      tagGroupId: freezed == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      tagIds: freezed == tagIds
          ? _self._tagIds
          : tagIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      deadline: freezed == deadline
          ? _self.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TodoStatus?,
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of TodoUpdate
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
