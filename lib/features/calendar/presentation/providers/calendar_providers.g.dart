// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 캘린더 UI 설정 상태 관리
///
/// 뷰 타입, 선택된 날짜, 표시 설정 등을 관리합니다.

@ProviderFor(CalendarSettings)
final calendarSettingsProvider = CalendarSettingsProvider._();

/// 캘린더 UI 설정 상태 관리
///
/// 뷰 타입, 선택된 날짜, 표시 설정 등을 관리합니다.
final class CalendarSettingsProvider
    extends $NotifierProvider<CalendarSettings, CalendarSettingsState> {
  /// 캘린더 UI 설정 상태 관리
  ///
  /// 뷰 타입, 선택된 날짜, 표시 설정 등을 관리합니다.
  CalendarSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarSettingsHash();

  @$internal
  @override
  CalendarSettings create() => CalendarSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarSettingsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarSettingsState>(value),
    );
  }
}

String _$calendarSettingsHash() => r'9bf6ef7601588676fe9107dec57c5bf750c16063';

/// 캘린더 UI 설정 상태 관리
///
/// 뷰 타입, 선택된 날짜, 표시 설정 등을 관리합니다.

abstract class _$CalendarSettings extends $Notifier<CalendarSettingsState> {
  CalendarSettingsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CalendarSettingsState, CalendarSettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarSettingsState, CalendarSettingsState>,
              CalendarSettingsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 캘린더 필터 상태 관리
///
/// 태그 필터, 사용자 필터 등을 관리합니다.

@ProviderFor(CalendarFilter)
final calendarFilterProvider = CalendarFilterProvider._();

/// 캘린더 필터 상태 관리
///
/// 태그 필터, 사용자 필터 등을 관리합니다.
final class CalendarFilterProvider
    extends $NotifierProvider<CalendarFilter, CalendarFilterState> {
  /// 캘린더 필터 상태 관리
  ///
  /// 태그 필터, 사용자 필터 등을 관리합니다.
  CalendarFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarFilterHash();

  @$internal
  @override
  CalendarFilter create() => CalendarFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarFilterState>(value),
    );
  }
}

String _$calendarFilterHash() => r'63729d7acbb9edbbf3c17e773283677d3ff8921c';

/// 캘린더 필터 상태 관리
///
/// 태그 필터, 사용자 필터 등을 관리합니다.

abstract class _$CalendarFilter extends $Notifier<CalendarFilterState> {
  CalendarFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CalendarFilterState, CalendarFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarFilterState, CalendarFilterState>,
              CalendarFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 현재 표시 범위의 일정 조회
///
/// CalendarSettings의 displayDate를 기반으로 적절한 범위의 일정을 조회합니다.

@ProviderFor(currentSchedules)
final currentSchedulesProvider = CurrentSchedulesProvider._();

/// 현재 표시 범위의 일정 조회
///
/// CalendarSettings의 displayDate를 기반으로 적절한 범위의 일정을 조회합니다.

final class CurrentSchedulesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ScheduleRead>>,
          List<ScheduleRead>,
          FutureOr<List<ScheduleRead>>
        >
    with
        $FutureModifier<List<ScheduleRead>>,
        $FutureProvider<List<ScheduleRead>> {
  /// 현재 표시 범위의 일정 조회
  ///
  /// CalendarSettings의 displayDate를 기반으로 적절한 범위의 일정을 조회합니다.
  CurrentSchedulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSchedulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSchedulesHash();

  @$internal
  @override
  $FutureProviderElement<List<ScheduleRead>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ScheduleRead>> create(Ref ref) {
    return currentSchedules(ref);
  }
}

String _$currentSchedulesHash() => r'217577344a61b80ec70bdd05128e994be00e6c91';

/// 필터링된 일정 목록
///
/// 현재 일정에 필터를 적용한 결과를 반환합니다.

@ProviderFor(filteredSchedules)
final filteredSchedulesProvider = FilteredSchedulesProvider._();

/// 필터링된 일정 목록
///
/// 현재 일정에 필터를 적용한 결과를 반환합니다.

final class FilteredSchedulesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ScheduleRead>>,
          List<ScheduleRead>,
          FutureOr<List<ScheduleRead>>
        >
    with
        $FutureModifier<List<ScheduleRead>>,
        $FutureProvider<List<ScheduleRead>> {
  /// 필터링된 일정 목록
  ///
  /// 현재 일정에 필터를 적용한 결과를 반환합니다.
  FilteredSchedulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredSchedulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredSchedulesHash();

  @$internal
  @override
  $FutureProviderElement<List<ScheduleRead>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ScheduleRead>> create(Ref ref) {
    return filteredSchedules(ref);
  }
}

String _$filteredSchedulesHash() => r'222e777a951b4657a2f8d51037179a774f07e1fa';

/// 캘린더 데이터 소스 Provider
///
/// 필터링된 일정을 Syncfusion CalendarDataSource로 변환합니다.

@ProviderFor(calendarDataSource)
final calendarDataSourceProvider = CalendarDataSourceProvider._();

/// 캘린더 데이터 소스 Provider
///
/// 필터링된 일정을 Syncfusion CalendarDataSource로 변환합니다.

final class CalendarDataSourceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ScheduleCalendarDataSource>,
          ScheduleCalendarDataSource,
          FutureOr<ScheduleCalendarDataSource>
        >
    with
        $FutureModifier<ScheduleCalendarDataSource>,
        $FutureProvider<ScheduleCalendarDataSource> {
  /// 캘린더 데이터 소스 Provider
  ///
  /// 필터링된 일정을 Syncfusion CalendarDataSource로 변환합니다.
  CalendarDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarDataSourceHash();

  @$internal
  @override
  $FutureProviderElement<ScheduleCalendarDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ScheduleCalendarDataSource> create(Ref ref) {
    return calendarDataSource(ref);
  }
}

String _$calendarDataSourceHash() =>
    r'b550a63b46e822cc037c8c6a59b7769ac49d43f4';

/// 일정 생성/수정/삭제 관리

@ProviderFor(ScheduleMutations)
final scheduleMutationsProvider = ScheduleMutationsProvider._();

/// 일정 생성/수정/삭제 관리
final class ScheduleMutationsProvider
    extends $AsyncNotifierProvider<ScheduleMutations, void> {
  /// 일정 생성/수정/삭제 관리
  ScheduleMutationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleMutationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleMutationsHash();

  @$internal
  @override
  ScheduleMutations create() => ScheduleMutations();
}

String _$scheduleMutationsHash() => r'fcbe1f86c817438481e154f8f47aefe37466ac7a';

/// 일정 생성/수정/삭제 관리

abstract class _$ScheduleMutations extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
