import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/explicit_null_interceptor.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart'
    as fmt;
import 'package:momeet/features/calendar/presentation/widgets/schedule_time_range_fields.dart';

/// 일정 생성/수정을 위한 Modal Bottom Sheet 위젯
///
/// FloatingActionButton을 눌렀을 때 올라오는 Bottom Sheet 내부에서 사용됩니다.
/// 제목, 일시(시작/종료), 설명, 종일 옵션을 입력받아 새로운 일정을 생성하거나 기존 일정을 수정합니다.
class ScheduleFormSheet extends ConsumerStatefulWidget {
  /// 초기 시작 시간 (선택사항)
  final DateTime? initialStartTime;

  /// 초기 종료 시간 (선택사항)
  final DateTime? initialEndTime;

  /// 수정할 기존 일정 (수정 모드인 경우)
  final ScheduleRead? existingSchedule;

  const ScheduleFormSheet({
    super.key,
    this.initialStartTime,
    this.initialEndTime,
    this.existingSchedule,
  });

  @override
  ConsumerState<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends ConsumerState<ScheduleFormSheet> {
  // Form 관리
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late ScheduleTimeRange _range;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    // 기존 일정 데이터가 있으면 사용, 없으면 초기값 설정
    if (widget.existingSchedule != null) {
      final schedule = widget.existingSchedule!;

      // 폼 데이터 초기화
      _titleController.text = schedule.title;
      _descriptionController.text = schedule.description ?? '';

      final start = schedule.startTime.toLocal();
      final end = schedule.endTime.toLocal();
      _range = (start: start, end: end, allDay: fmt.isAllDay(start, end));
    } else {
      // 새 일정 생성 모드
      final now = DateTime.now();
      final roundedNow = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        (now.minute ~/ 15) * 15, // 15분 단위로 반올림
      );

      final start = widget.initialStartTime ?? roundedNow;
      _range = (
        start: start,
        end: widget.initialEndTime ?? start.add(const Duration(hours: 1)),
        allDay: false,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.existingSchedule != null
        ? ref.watch(updateScheduleMutation).isPending
        : ref.watch(createScheduleMutation).isPending;

    return AppFormSheet(
      title: widget.existingSchedule != null ? '일정 수정' : '새 일정',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: widget.existingSchedule != null ? '수정' : '저장',
        onSubmit: _handleSubmit,
        busy: isLoading,
      ),
      children: [
        TextFormField(
          controller: _titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '제목',
            hintText: '일정 제목을 입력하세요',
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '제목을 입력해주세요';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        ScheduleTimeRangeFields(
          value: _range,
          onChanged: (range) => setState(() => _range = range),
        ),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '설명 (선택사항)',
            hintText: '일정에 대한 메모를 작성하세요',
            prefixIcon: Icon(Icons.notes),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }

  /// 폼 제출 처리
  Future<void> _handleSubmit() async {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 시간 유효성 검사 (종일이 아닌 경우)
    if (!_range.allDay && _range.end.isBefore(_range.start)) {
      _showErrorSnackBar('종료 시간은 시작 시간보다 늦어야 합니다');
      return;
    }

    // BuildContext를 미리 저장 (async gap 경고 방지)
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (widget.existingSchedule != null) {
        // 수정 모드
        final description = _descriptionController.text.trim();
        final scheduleUpdate = ScheduleUpdate(
          title: _titleController.text.trim(),
          startTime: _range.start.toUtc(),
          endTime: _range.end.toUtc(),
          description: description.isEmpty ? null : description,
        );

        await updateScheduleMutation.run(
          ref,
          (tsx) => tsx
              .get(scheduleMutationsProvider.notifier)
              .updateSchedule(
                widget.existingSchedule!.id,
                scheduleUpdate,
                options: description.isEmpty
                    ? explicitNulls(['description'])
                    : null,
              ),
        );

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '일정이 수정되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      } else {
        // 생성 모드
        final scheduleCreate = ScheduleCreate(
          title: _titleController.text.trim(),
          startTime: _range.start.toUtc(),
          endTime: _range.end.toUtc(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

        await createScheduleMutation.run(
          ref,
          (tsx) => tsx
              .get(scheduleMutationsProvider.notifier)
              .createSchedule(scheduleCreate),
        );

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '일정이 생성되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      }
    } catch (error) {
      // 에러 처리
      final action = widget.existingSchedule != null ? '수정' : '생성';
      debugPrint('일정 $action 에러: $error');
      if (mounted) {
        showAppSnackBar(
          context,
          '일정 $action에 실패했습니다: ${error.toString()}',
          kind: AppNoticeKind.error,
        );
      }
    }
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    showAppSnackBar(context, message, kind: AppNoticeKind.error);
  }
}

/// Modal Bottom Sheet를 보여주는 헬퍼 함수 (일정 생성)
///
/// FloatingActionButton의 onPressed에서 호출하여 사용합니다.
///
/// 사용 예:
/// ```dart
/// FloatingActionButton(
///   onPressed: () => showScheduleFormSheet(context),
///   child: const Icon(Icons.add),
/// )
/// ```
Future<void> showScheduleFormSheet(
  BuildContext context, {
  DateTime? initialStartTime,
  DateTime? initialEndTime,
  DateTime? initialDate, // 특정 날짜 클릭 시 사용
}) {
  // initialDate가 제공되면 해당 날짜의 다음 정각으로 시작 시간 설정
  DateTime? defaultStartTime = initialStartTime;
  DateTime? defaultEndTime = initialEndTime;

  if (initialDate != null && defaultStartTime == null) {
    final now = DateTime.now();
    final targetDate = initialDate;

    // 클릭한 날짜에 현재 시간의 다음 정각으로 설정
    final nextHour = now.hour < 23 ? now.hour + 1 : now.hour;
    defaultStartTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      nextHour,
      0,
    );
    defaultEndTime = defaultStartTime.add(const Duration(hours: 1));
  }

  return showAppSheet<void>(
    context,
    builder: (context) => ScheduleFormSheet(
      initialStartTime: defaultStartTime,
      initialEndTime: defaultEndTime,
    ),
  );
}

/// Modal Bottom Sheet를 보여주는 헬퍼 함수 (일정 수정)
///
/// 기존 일정 데이터를 받아서 수정 폼을 표시합니다.
///
/// 사용 예:
/// ```dart
/// showScheduleEditSheet(context, existingSchedule);
/// ```
Future<void> showScheduleEditSheet(
  BuildContext context,
  ScheduleRead existingSchedule,
) {
  return showAppSheet<void>(
    context,
    builder: (context) => ScheduleFormSheet(existingSchedule: existingSchedule),
  );
}
