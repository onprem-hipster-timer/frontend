// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag_stat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TagStat {
  @JsonKey(name: 'tag_id')
  String get tagId;
  @JsonKey(name: 'tag_name')
  String get tagName;
  int get count;

  /// Create a copy of TagStat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TagStatCopyWith<TagStat> get copyWith =>
      _$TagStatCopyWithImpl<TagStat>(this as TagStat, _$identity);

  /// Serializes this TagStat to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TagStat &&
            (identical(other.tagId, tagId) || other.tagId == tagId) &&
            (identical(other.tagName, tagName) || other.tagName == tagName) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tagId, tagName, count);

  @override
  String toString() {
    return 'TagStat(tagId: $tagId, tagName: $tagName, count: $count)';
  }
}

/// @nodoc
abstract mixin class $TagStatCopyWith<$Res> {
  factory $TagStatCopyWith(TagStat value, $Res Function(TagStat) _then) =
      _$TagStatCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'tag_id') String tagId,
      @JsonKey(name: 'tag_name') String tagName,
      int count});
}

/// @nodoc
class _$TagStatCopyWithImpl<$Res> implements $TagStatCopyWith<$Res> {
  _$TagStatCopyWithImpl(this._self, this._then);

  final TagStat _self;
  final $Res Function(TagStat) _then;

  /// Create a copy of TagStat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tagId = null,
    Object? tagName = null,
    Object? count = null,
  }) {
    return _then(_self.copyWith(
      tagId: null == tagId
          ? _self.tagId
          : tagId // ignore: cast_nullable_to_non_nullable
              as String,
      tagName: null == tagName
          ? _self.tagName
          : tagName // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [TagStat].
extension TagStatPatterns on TagStat {
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
    TResult Function(_TagStat value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagStat() when $default != null:
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
    TResult Function(_TagStat value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagStat():
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
    TResult? Function(_TagStat value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagStat() when $default != null:
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
    TResult Function(@JsonKey(name: 'tag_id') String tagId,
            @JsonKey(name: 'tag_name') String tagName, int count)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TagStat() when $default != null:
        return $default(_that.tagId, _that.tagName, _that.count);
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
    TResult Function(@JsonKey(name: 'tag_id') String tagId,
            @JsonKey(name: 'tag_name') String tagName, int count)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagStat():
        return $default(_that.tagId, _that.tagName, _that.count);
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
    TResult? Function(@JsonKey(name: 'tag_id') String tagId,
            @JsonKey(name: 'tag_name') String tagName, int count)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TagStat() when $default != null:
        return $default(_that.tagId, _that.tagName, _that.count);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TagStat implements TagStat {
  const _TagStat(
      {@JsonKey(name: 'tag_id') required this.tagId,
      @JsonKey(name: 'tag_name') required this.tagName,
      required this.count});
  factory _TagStat.fromJson(Map<String, dynamic> json) =>
      _$TagStatFromJson(json);

  @override
  @JsonKey(name: 'tag_id')
  final String tagId;
  @override
  @JsonKey(name: 'tag_name')
  final String tagName;
  @override
  final int count;

  /// Create a copy of TagStat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TagStatCopyWith<_TagStat> get copyWith =>
      __$TagStatCopyWithImpl<_TagStat>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TagStatToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TagStat &&
            (identical(other.tagId, tagId) || other.tagId == tagId) &&
            (identical(other.tagName, tagName) || other.tagName == tagName) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tagId, tagName, count);

  @override
  String toString() {
    return 'TagStat(tagId: $tagId, tagName: $tagName, count: $count)';
  }
}

/// @nodoc
abstract mixin class _$TagStatCopyWith<$Res> implements $TagStatCopyWith<$Res> {
  factory _$TagStatCopyWith(_TagStat value, $Res Function(_TagStat) _then) =
      __$TagStatCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'tag_id') String tagId,
      @JsonKey(name: 'tag_name') String tagName,
      int count});
}

/// @nodoc
class __$TagStatCopyWithImpl<$Res> implements _$TagStatCopyWith<$Res> {
  __$TagStatCopyWithImpl(this._self, this._then);

  final _TagStat _self;
  final $Res Function(_TagStat) _then;

  /// Create a copy of TagStat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tagId = null,
    Object? tagName = null,
    Object? count = null,
  }) {
    return _then(_TagStat(
      tagId: null == tagId
          ? _self.tagId
          : tagId // ignore: cast_nullable_to_non_nullable
              as String,
      tagName: null == tagName
          ? _self.tagName
          : tagName // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
