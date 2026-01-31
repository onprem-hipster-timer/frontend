/// Presentation 계층 템플릿 - 사용 예시

/// 1. Riverpod Provider 예시
/// import 'package:flutter_riverpod/flutter_riverpod.dart';
/// import 'package:riverpod_annotation/riverpod_annotation.dart';
///
/// part 'schedule_provider.g.dart';
///
/// @riverpod
/// Future<List<ScheduleEntity>> schedules(SchedulesRef ref) async {
///   final repository = ref.watch(scheduleRepositoryProvider);
///   return repository.getSchedules();
/// }

/// 2. StateNotifier 예시 (복잡한 상태 관리용)
/// @riverpod
/// class ScheduleListNotifier extends _$ScheduleListNotifier {
///   @override
///   Future<List<ScheduleEntity>> build() async {
///     final repository = ref.watch(scheduleRepositoryProvider);
///     return repository.getSchedules();
///   }
///
///   Future<void> addSchedule(ScheduleEntity schedule) async {
///     final repository = ref.watch(scheduleRepositoryProvider);
///     await repository.createSchedule(schedule);
///     ref.invalidateSelf();
///   }
///
///   Future<void> deleteSchedule(String id) async {
///     final repository = ref.watch(scheduleRepositoryProvider);
///     await repository.deleteSchedule(id);
///     ref.invalidateSelf();
///   }
/// }

/// 3. UI State (Freezed) 예시
/// @freezed
/// class ScheduleUiState with _$ScheduleUiState {
///   const factory ScheduleUiState({
///     required CalendarViewMode viewMode,
///     required DateTime selectedDate,
///     DateTime? startDateFilter,
///     DateTime? endDateFilter,
///   }) = _ScheduleUiState;
///
///   factory ScheduleUiState.initial() => ScheduleUiState(
///     viewMode: CalendarViewMode.month,
///     selectedDate: DateTime.now(),
///   );
/// }

/// 4. ConsumerWidget 페이지 예시
/// import 'package:flutter/material.dart';
/// import 'package:flutter_riverpod/flutter_riverpod.dart';
///
/// class SchedulePage extends ConsumerWidget {
///   const SchedulePage({Key? key}) : super(key: key);
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final schedulesAsync = ref.watch(schedulesProvider);
///
///     return schedulesAsync.when(
///       data: (schedules) => ScheduleList(schedules: schedules),
///       loading: () => const Center(child: CircularProgressIndicator()),
///       error: (error, stackTrace) => Center(
///         child: Text('Error: $error'),
///       ),
///     );
///   }
/// }

/// 5. UI 위젯 예시
/// class ScheduleList extends StatelessWidget {
///   final List<ScheduleEntity> schedules;
///
///   const ScheduleList({
///     Key? key,
///     required this.schedules,
///   }) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) {
///     return ListView.builder(
///       itemCount: schedules.length,
///       itemBuilder: (context, index) {
///         final schedule = schedules[index];
///         return ListTile(
///           title: Text(schedule.title),
///           subtitle: Text(
///             '${schedule.startTime.hour}:${schedule.startTime.minute}',
///           ),
///         );
///       },
///     );
///   }
/// }
