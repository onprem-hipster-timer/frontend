// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'holiday_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HolidayItem {
  String get locdate;
  int get seq;
  String get dateKind;
  String get dateName;
  bool get isHoliday;

  /// Create a copy of HolidayItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HolidayItemCopyWith<HolidayItem> get copyWith =>
      _$HolidayItemCopyWithImpl<HolidayItem>(this as HolidayItem, _$identity);

  /// Serializes this HolidayItem to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HolidayItem &&
            (identical(other.locdate, locdate) || other.locdate == locdate) &&
            (identical(other.seq, seq) || other.seq == seq) &&
            (identical(other.dateKind, dateKind) ||
                other.dateKind == dateKind) &&
            (identical(other.dateName, dateName) ||
                other.dateName == dateName) &&
            (identical(other.isHoliday, isHoliday) ||
                other.isHoliday == isHoliday));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, locdate, seq, dateKind, dateName, isHoliday);

  @override
  String toString() {
    return 'HolidayItem(locdate: $locdate, seq: $seq, dateKind: $dateKind, dateName: $dateName, isHoliday: $isHoliday)';
  }
}

/// @nodoc
abstract mixin class $HolidayItemCopyWith<$Res> {
  factory $HolidayItemCopyWith(
          HolidayItem value, $Res Function(HolidayItem) _then) =
      _$HolidayItemCopyWithImpl;
  @useResult
  $Res call(
      {String locdate,
      int seq,
      String dateKind,
      String dateName,
      bool isHoliday});
}

/// @nodoc
class _$HolidayItemCopyWithImpl<$Res> implements $HolidayItemCopyWith<$Res> {
  _$HolidayItemCopyWithImpl(this._self, this._then);

  final HolidayItem _self;
  final $Res Function(HolidayItem) _then;

  /// Create a copy of HolidayItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? locdate = null,
    Object? seq = null,
    Object? dateKind = null,
    Object? dateName = null,
    Object? isHoliday = null,
  }) {
    return _then(_self.copyWith(
      locdate: null == locdate
          ? _self.locdate
          : locdate // ignore: cast_nullable_to_non_nullable
              as String,
      seq: null == seq
          ? _self.seq
          : seq // ignore: cast_nullable_to_non_nullable
              as int,
      dateKind: null == dateKind
          ? _self.dateKind
          : dateKind // ignore: cast_nullable_to_non_nullable
              as String,
      dateName: null == dateName
          ? _self.dateName
          : dateName // ignore: cast_nullable_to_non_nullable
              as String,
      isHoliday: null == isHoliday
          ? _self.isHoliday
          : isHoliday // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [HolidayItem].
extension HolidayItemPatterns on HolidayItem {
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
    TResult Function(_HolidayItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HolidayItem() when $default != null:
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
    TResult Function(_HolidayItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HolidayItem():
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
    TResult? Function(_HolidayItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HolidayItem() when $default != null:
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
    TResult Function(String locdate, int seq, String dateKind, String dateName,
            bool isHoliday)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HolidayItem() when $default != null:
        return $default(_that.locdate, _that.seq, _that.dateKind,
            _that.dateName, _that.isHoliday);
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
    TResult Function(String locdate, int seq, String dateKind, String dateName,
            bool isHoliday)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HolidayItem():
        return $default(_that.locdate, _that.seq, _that.dateKind,
            _that.dateName, _that.isHoliday);
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
    TResult? Function(String locdate, int seq, String dateKind, String dateName,
            bool isHoliday)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HolidayItem() when $default != null:
        return $default(_that.locdate, _that.seq, _that.dateKind,
            _that.dateName, _that.isHoliday);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HolidayItem implements HolidayItem {
  const _HolidayItem(
      {required this.locdate,
      required this.seq,
      required this.dateKind,
      required this.dateName,
      required this.isHoliday});
  factory _HolidayItem.fromJson(Map<String, dynamic> json) =>
      _$HolidayItemFromJson(json);

  @override
  final String locdate;
  @override
  final int seq;
  @override
  final String dateKind;
  @override
  final String dateName;
  @override
  final bool isHoliday;

  /// Create a copy of HolidayItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HolidayItemCopyWith<_HolidayItem> get copyWith =>
      __$HolidayItemCopyWithImpl<_HolidayItem>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HolidayItemToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HolidayItem &&
            (identical(other.locdate, locdate) || other.locdate == locdate) &&
            (identical(other.seq, seq) || other.seq == seq) &&
            (identical(other.dateKind, dateKind) ||
                other.dateKind == dateKind) &&
            (identical(other.dateName, dateName) ||
                other.dateName == dateName) &&
            (identical(other.isHoliday, isHoliday) ||
                other.isHoliday == isHoliday));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, locdate, seq, dateKind, dateName, isHoliday);

  @override
  String toString() {
    return 'HolidayItem(locdate: $locdate, seq: $seq, dateKind: $dateKind, dateName: $dateName, isHoliday: $isHoliday)';
  }
}

/// @nodoc
abstract mixin class _$HolidayItemCopyWith<$Res>
    implements $HolidayItemCopyWith<$Res> {
  factory _$HolidayItemCopyWith(
          _HolidayItem value, $Res Function(_HolidayItem) _then) =
      __$HolidayItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String locdate,
      int seq,
      String dateKind,
      String dateName,
      bool isHoliday});
}

/// @nodoc
class __$HolidayItemCopyWithImpl<$Res> implements _$HolidayItemCopyWith<$Res> {
  __$HolidayItemCopyWithImpl(this._self, this._then);

  final _HolidayItem _self;
  final $Res Function(_HolidayItem) _then;

  /// Create a copy of HolidayItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? locdate = null,
    Object? seq = null,
    Object? dateKind = null,
    Object? dateName = null,
    Object? isHoliday = null,
  }) {
    return _then(_HolidayItem(
      locdate: null == locdate
          ? _self.locdate
          : locdate // ignore: cast_nullable_to_non_nullable
              as String,
      seq: null == seq
          ? _self.seq
          : seq // ignore: cast_nullable_to_non_nullable
              as int,
      dateKind: null == dateKind
          ? _self.dateKind
          : dateKind // ignore: cast_nullable_to_non_nullable
              as String,
      dateName: null == dateName
          ? _self.dateName
          : dateName // ignore: cast_nullable_to_non_nullable
              as String,
      isHoliday: null == isHoliday
          ? _self.isHoliday
          : isHoliday // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
