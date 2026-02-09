// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TodoStats {
  @JsonKey(name: 'total_count')
  int get totalCount;
  @JsonKey(name: 'by_tag')
  List<TagStat> get byTag;
  @JsonKey(name: 'group_id')
  String? get groupId;

  /// Create a copy of TodoStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TodoStatsCopyWith<TodoStats> get copyWith =>
      _$TodoStatsCopyWithImpl<TodoStats>(this as TodoStats, _$identity);

  /// Serializes this TodoStats to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TodoStats &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            const DeepCollectionEquality().equals(other.byTag, byTag) &&
            (identical(other.groupId, groupId) || other.groupId == groupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, totalCount,
      const DeepCollectionEquality().hash(byTag), groupId);

  @override
  String toString() {
    return 'TodoStats(totalCount: $totalCount, byTag: $byTag, groupId: $groupId)';
  }
}

/// @nodoc
abstract mixin class $TodoStatsCopyWith<$Res> {
  factory $TodoStatsCopyWith(TodoStats value, $Res Function(TodoStats) _then) =
      _$TodoStatsCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'total_count') int totalCount,
      @JsonKey(name: 'by_tag') List<TagStat> byTag,
      @JsonKey(name: 'group_id') String? groupId});
}

/// @nodoc
class _$TodoStatsCopyWithImpl<$Res> implements $TodoStatsCopyWith<$Res> {
  _$TodoStatsCopyWithImpl(this._self, this._then);

  final TodoStats _self;
  final $Res Function(TodoStats) _then;

  /// Create a copy of TodoStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalCount = null,
    Object? byTag = null,
    Object? groupId = freezed,
  }) {
    return _then(_self.copyWith(
      totalCount: null == totalCount
          ? _self.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      byTag: null == byTag
          ? _self.byTag
          : byTag // ignore: cast_nullable_to_non_nullable
              as List<TagStat>,
      groupId: freezed == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TodoStats].
extension TodoStatsPatterns on TodoStats {
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
    TResult Function(_TodoStats value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TodoStats() when $default != null:
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
    TResult Function(_TodoStats value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoStats():
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
    TResult? Function(_TodoStats value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoStats() when $default != null:
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
            @JsonKey(name: 'total_count') int totalCount,
            @JsonKey(name: 'by_tag') List<TagStat> byTag,
            @JsonKey(name: 'group_id') String? groupId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TodoStats() when $default != null:
        return $default(_that.totalCount, _that.byTag, _that.groupId);
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
            @JsonKey(name: 'total_count') int totalCount,
            @JsonKey(name: 'by_tag') List<TagStat> byTag,
            @JsonKey(name: 'group_id') String? groupId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoStats():
        return $default(_that.totalCount, _that.byTag, _that.groupId);
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
            @JsonKey(name: 'total_count') int totalCount,
            @JsonKey(name: 'by_tag') List<TagStat> byTag,
            @JsonKey(name: 'group_id') String? groupId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TodoStats() when $default != null:
        return $default(_that.totalCount, _that.byTag, _that.groupId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TodoStats implements TodoStats {
  const _TodoStats(
      {@JsonKey(name: 'total_count') required this.totalCount,
      @JsonKey(name: 'by_tag') required final List<TagStat> byTag,
      @JsonKey(name: 'group_id') this.groupId})
      : _byTag = byTag;
  factory _TodoStats.fromJson(Map<String, dynamic> json) =>
      _$TodoStatsFromJson(json);

  @override
  @JsonKey(name: 'total_count')
  final int totalCount;
  final List<TagStat> _byTag;
  @override
  @JsonKey(name: 'by_tag')
  List<TagStat> get byTag {
    if (_byTag is EqualUnmodifiableListView) return _byTag;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_byTag);
  }

  @override
  @JsonKey(name: 'group_id')
  final String? groupId;

  /// Create a copy of TodoStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TodoStatsCopyWith<_TodoStats> get copyWith =>
      __$TodoStatsCopyWithImpl<_TodoStats>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TodoStatsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TodoStats &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            const DeepCollectionEquality().equals(other._byTag, _byTag) &&
            (identical(other.groupId, groupId) || other.groupId == groupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, totalCount,
      const DeepCollectionEquality().hash(_byTag), groupId);

  @override
  String toString() {
    return 'TodoStats(totalCount: $totalCount, byTag: $byTag, groupId: $groupId)';
  }
}

/// @nodoc
abstract mixin class _$TodoStatsCopyWith<$Res>
    implements $TodoStatsCopyWith<$Res> {
  factory _$TodoStatsCopyWith(
          _TodoStats value, $Res Function(_TodoStats) _then) =
      __$TodoStatsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'total_count') int totalCount,
      @JsonKey(name: 'by_tag') List<TagStat> byTag,
      @JsonKey(name: 'group_id') String? groupId});
}

/// @nodoc
class __$TodoStatsCopyWithImpl<$Res> implements _$TodoStatsCopyWith<$Res> {
  __$TodoStatsCopyWithImpl(this._self, this._then);

  final _TodoStats _self;
  final $Res Function(_TodoStats) _then;

  /// Create a copy of TodoStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? totalCount = null,
    Object? byTag = null,
    Object? groupId = freezed,
  }) {
    return _then(_TodoStats(
      totalCount: null == totalCount
          ? _self.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      byTag: null == byTag
          ? _self._byTag
          : byTag // ignore: cast_nullable_to_non_nullable
              as List<TagStat>,
      groupId: freezed == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
