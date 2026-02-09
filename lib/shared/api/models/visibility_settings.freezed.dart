// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'visibility_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VisibilitySettings {
  @JsonKey(name: 'allowed_user_ids')
  List<String>? get allowedUserIds;
  VisibilityLevel get level;

  /// Create a copy of VisibilitySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VisibilitySettingsCopyWith<VisibilitySettings> get copyWith =>
      _$VisibilitySettingsCopyWithImpl<VisibilitySettings>(
          this as VisibilitySettings, _$identity);

  /// Serializes this VisibilitySettings to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VisibilitySettings &&
            const DeepCollectionEquality()
                .equals(other.allowedUserIds, allowedUserIds) &&
            (identical(other.level, level) || other.level == level));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(allowedUserIds), level);

  @override
  String toString() {
    return 'VisibilitySettings(allowedUserIds: $allowedUserIds, level: $level)';
  }
}

/// @nodoc
abstract mixin class $VisibilitySettingsCopyWith<$Res> {
  factory $VisibilitySettingsCopyWith(
          VisibilitySettings value, $Res Function(VisibilitySettings) _then) =
      _$VisibilitySettingsCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'allowed_user_ids') List<String>? allowedUserIds,
      VisibilityLevel level});
}

/// @nodoc
class _$VisibilitySettingsCopyWithImpl<$Res>
    implements $VisibilitySettingsCopyWith<$Res> {
  _$VisibilitySettingsCopyWithImpl(this._self, this._then);

  final VisibilitySettings _self;
  final $Res Function(VisibilitySettings) _then;

  /// Create a copy of VisibilitySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allowedUserIds = freezed,
    Object? level = null,
  }) {
    return _then(_self.copyWith(
      allowedUserIds: freezed == allowedUserIds
          ? _self.allowedUserIds
          : allowedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      level: null == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as VisibilityLevel,
    ));
  }
}

/// Adds pattern-matching-related methods to [VisibilitySettings].
extension VisibilitySettingsPatterns on VisibilitySettings {
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
    TResult Function(_VisibilitySettings value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VisibilitySettings() when $default != null:
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
    TResult Function(_VisibilitySettings value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisibilitySettings():
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
    TResult? Function(_VisibilitySettings value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisibilitySettings() when $default != null:
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
            @JsonKey(name: 'allowed_user_ids') List<String>? allowedUserIds,
            VisibilityLevel level)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VisibilitySettings() when $default != null:
        return $default(_that.allowedUserIds, _that.level);
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
            @JsonKey(name: 'allowed_user_ids') List<String>? allowedUserIds,
            VisibilityLevel level)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisibilitySettings():
        return $default(_that.allowedUserIds, _that.level);
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
            @JsonKey(name: 'allowed_user_ids') List<String>? allowedUserIds,
            VisibilityLevel level)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisibilitySettings() when $default != null:
        return $default(_that.allowedUserIds, _that.level);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _VisibilitySettings implements VisibilitySettings {
  const _VisibilitySettings(
      {@JsonKey(name: 'allowed_user_ids') final List<String>? allowedUserIds,
      this.level = VisibilityLevel.private})
      : _allowedUserIds = allowedUserIds;
  factory _VisibilitySettings.fromJson(Map<String, dynamic> json) =>
      _$VisibilitySettingsFromJson(json);

  final List<String>? _allowedUserIds;
  @override
  @JsonKey(name: 'allowed_user_ids')
  List<String>? get allowedUserIds {
    final value = _allowedUserIds;
    if (value == null) return null;
    if (_allowedUserIds is EqualUnmodifiableListView) return _allowedUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final VisibilityLevel level;

  /// Create a copy of VisibilitySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VisibilitySettingsCopyWith<_VisibilitySettings> get copyWith =>
      __$VisibilitySettingsCopyWithImpl<_VisibilitySettings>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$VisibilitySettingsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VisibilitySettings &&
            const DeepCollectionEquality()
                .equals(other._allowedUserIds, _allowedUserIds) &&
            (identical(other.level, level) || other.level == level));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_allowedUserIds), level);

  @override
  String toString() {
    return 'VisibilitySettings(allowedUserIds: $allowedUserIds, level: $level)';
  }
}

/// @nodoc
abstract mixin class _$VisibilitySettingsCopyWith<$Res>
    implements $VisibilitySettingsCopyWith<$Res> {
  factory _$VisibilitySettingsCopyWith(
          _VisibilitySettings value, $Res Function(_VisibilitySettings) _then) =
      __$VisibilitySettingsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'allowed_user_ids') List<String>? allowedUserIds,
      VisibilityLevel level});
}

/// @nodoc
class __$VisibilitySettingsCopyWithImpl<$Res>
    implements _$VisibilitySettingsCopyWith<$Res> {
  __$VisibilitySettingsCopyWithImpl(this._self, this._then);

  final _VisibilitySettings _self;
  final $Res Function(_VisibilitySettings) _then;

  /// Create a copy of VisibilitySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? allowedUserIds = freezed,
    Object? level = null,
  }) {
    return _then(_VisibilitySettings(
      allowedUserIds: freezed == allowedUserIds
          ? _self._allowedUserIds
          : allowedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      level: null == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as VisibilityLevel,
    ));
  }
}

// dart format on
