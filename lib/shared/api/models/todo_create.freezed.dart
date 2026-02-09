// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_create.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TodoCreate {
  String get title;
  @JsonKey(name: 'tag_group_id')
  String get tagGroupId;
  TodoStatus? get status;
  String? get description;
  @JsonKey(name: 'tag_ids')
  List<String>? get tagIds;
  DateTime? get deadline;
  @JsonKey(name: 'parent_id')
  String? get parentId;
  VisibilitySettings? get visibility;

  /// Create a copy of TodoCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TodoCreateCopyWith<TodoCreate> get copyWith =>
      _$TodoCreateCopyWithImpl<TodoCreate>(this as TodoCreate, _$identity);

  /// Serializes this TodoCreate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TodoCreate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other.tagIds, tagIds) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      tagGroupId,
      status,
      description,
      const DeepCollectionEquality().hash(tagIds),
      deadline,
      parentId,
      visibility);

  @override
  String toString() {
    return 'TodoCreate(title: $title, tagGroupId: $tagGroupId, status: $status, description: $description, tagIds: $tagIds, deadline: $deadline, parentId: $parentId, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class $TodoCreateCopyWith<$Res> {
  factory $TodoCreateCopyWith(
          TodoCreate value, $Res Function(TodoCreate) _then) =
      _$TodoCreateCopyWithImpl;
  @useResult
  $Res call(
      {String title,
      @JsonKey(name: 'tag_group_id') String tagGroupId,
      TodoStatus? status,
      String? description,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      DateTime? deadline,
      @JsonKey(name: 'parent_id') String? parentId,
      VisibilitySettings? visibility});

  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class _$TodoCreateCopyWithImpl<$Res> implements $TodoCreateCopyWith<$Res> {
  _$TodoCreateCopyWithImpl(this._self, this._then);

  final TodoCreate _self;
  final $Res Function(TodoCreate) _then;

  /// Create a copy of TodoCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? tagGroupId = null,
    Object? status = freezed,
    Object? description = freezed,
    Object? tagIds = freezed,
    Object? deadline = freezed,
    Object? parentId = freezed,
    Object? visibility = freezed,
  }) {
    return _then(_self.copyWith(
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      tagGroupId: null == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TodoStatus?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
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
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of TodoCreate
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

/// Adds pattern-matching-related methods to [TodoCreate].
extension TodoCreatePatterns on TodoCreate {
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
    TResult Function(_TodoCreate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TodoCreate() when $default != null:
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
    TResult Function(_TodoCreate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoCreate():
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
    TResult? Function(_TodoCreate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoCreate() when $default != null:
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
            @JsonKey(name: 'tag_group_id') String tagGroupId,
            TodoStatus? status,
            String? description,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            DateTime? deadline,
            @JsonKey(name: 'parent_id') String? parentId,
            VisibilitySettings? visibility)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TodoCreate() when $default != null:
        return $default(
            _that.title,
            _that.tagGroupId,
            _that.status,
            _that.description,
            _that.tagIds,
            _that.deadline,
            _that.parentId,
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
            @JsonKey(name: 'tag_group_id') String tagGroupId,
            TodoStatus? status,
            String? description,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            DateTime? deadline,
            @JsonKey(name: 'parent_id') String? parentId,
            VisibilitySettings? visibility)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoCreate():
        return $default(
            _that.title,
            _that.tagGroupId,
            _that.status,
            _that.description,
            _that.tagIds,
            _that.deadline,
            _that.parentId,
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
            @JsonKey(name: 'tag_group_id') String tagGroupId,
            TodoStatus? status,
            String? description,
            @JsonKey(name: 'tag_ids') List<String>? tagIds,
            DateTime? deadline,
            @JsonKey(name: 'parent_id') String? parentId,
            VisibilitySettings? visibility)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoCreate() when $default != null:
        return $default(
            _that.title,
            _that.tagGroupId,
            _that.status,
            _that.description,
            _that.tagIds,
            _that.deadline,
            _that.parentId,
            _that.visibility);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TodoCreate implements TodoCreate {
  const _TodoCreate(
      {required this.title,
      @JsonKey(name: 'tag_group_id') required this.tagGroupId,
      this.status = TodoStatus.unscheduled,
      this.description,
      @JsonKey(name: 'tag_ids') final List<String>? tagIds,
      this.deadline,
      @JsonKey(name: 'parent_id') this.parentId,
      this.visibility})
      : _tagIds = tagIds;
  factory _TodoCreate.fromJson(Map<String, dynamic> json) =>
      _$TodoCreateFromJson(json);

  @override
  final String title;
  @override
  @JsonKey(name: 'tag_group_id')
  final String tagGroupId;
  @override
  @JsonKey()
  final TodoStatus? status;
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
  final DateTime? deadline;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @override
  final VisibilitySettings? visibility;

  /// Create a copy of TodoCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TodoCreateCopyWith<_TodoCreate> get copyWith =>
      __$TodoCreateCopyWithImpl<_TodoCreate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TodoCreateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TodoCreate &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.tagGroupId, tagGroupId) ||
                other.tagGroupId == tagGroupId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._tagIds, _tagIds) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      tagGroupId,
      status,
      description,
      const DeepCollectionEquality().hash(_tagIds),
      deadline,
      parentId,
      visibility);

  @override
  String toString() {
    return 'TodoCreate(title: $title, tagGroupId: $tagGroupId, status: $status, description: $description, tagIds: $tagIds, deadline: $deadline, parentId: $parentId, visibility: $visibility)';
  }
}

/// @nodoc
abstract mixin class _$TodoCreateCopyWith<$Res>
    implements $TodoCreateCopyWith<$Res> {
  factory _$TodoCreateCopyWith(
          _TodoCreate value, $Res Function(_TodoCreate) _then) =
      __$TodoCreateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String title,
      @JsonKey(name: 'tag_group_id') String tagGroupId,
      TodoStatus? status,
      String? description,
      @JsonKey(name: 'tag_ids') List<String>? tagIds,
      DateTime? deadline,
      @JsonKey(name: 'parent_id') String? parentId,
      VisibilitySettings? visibility});

  @override
  $VisibilitySettingsCopyWith<$Res>? get visibility;
}

/// @nodoc
class __$TodoCreateCopyWithImpl<$Res> implements _$TodoCreateCopyWith<$Res> {
  __$TodoCreateCopyWithImpl(this._self, this._then);

  final _TodoCreate _self;
  final $Res Function(_TodoCreate) _then;

  /// Create a copy of TodoCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = null,
    Object? tagGroupId = null,
    Object? status = freezed,
    Object? description = freezed,
    Object? tagIds = freezed,
    Object? deadline = freezed,
    Object? parentId = freezed,
    Object? visibility = freezed,
  }) {
    return _then(_TodoCreate(
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      tagGroupId: null == tagGroupId
          ? _self.tagGroupId
          : tagGroupId // ignore: cast_nullable_to_non_nullable
              as String,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TodoStatus?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
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
      visibility: freezed == visibility
          ? _self.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as VisibilitySettings?,
    ));
  }

  /// Create a copy of TodoCreate
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
