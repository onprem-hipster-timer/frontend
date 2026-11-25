import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart'
    as fmt;
import 'package:momeet/features/calendar/presentation/widgets/schedule_time_range_fields.dart';

/// 일정 생성/수정을 위한 Modal Bottom Sheet 위젯
///
/// FloatingActionButton을 눌렀을 때 올라오는 Bottom Sheet 내부에서 사용됩니다.
/// 제목, 일시(시작/종료), 설명, 종일 옵션을 입력받아 새로운 일정을 생성하거나 기존 일정을 수정합니다.
/// 칸과 시간을 검사한 뒤 다듬은 제목·설명과 고른 시간으로 [onSubmit]을 부르고, [busy]인 동안은 버튼에 진행 표시를 둔다.
class ScheduleFormSheetView extends StatefulWidget {
  /// 초기 시작 시간 (선택사항)
  final DateTime? initialStartTime;

  /// 초기 종료 시간 (선택사항)
  final DateTime? initialEndTime;

  /// 초기 제목 (선택사항)
  final String? initialTitle;

  /// 수정할 기존 일정 (수정 모드인 경우)
  final ScheduleRead? existingSchedule;

  final bool busy;
  final void Function(String title, String description, ScheduleTimeRange range)
  onSubmit;

  const ScheduleFormSheetView({
    super.key,
    this.initialStartTime,
    this.initialEndTime,
    this.initialTitle,
    this.existingSchedule,
    required this.busy,
    required this.onSubmit,
  });

  @override
  State<ScheduleFormSheetView> createState() => _ScheduleFormSheetViewState();
}

class _ScheduleFormSheetViewState extends State<ScheduleFormSheetView> {
  // Form 관리
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late ScheduleTimeRange _range;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.initialTitle);
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
      final end = widget.initialEndTime ?? start.add(const Duration(hours: 1));
      // 받은 시각이 그날 00:00부터 마지막 날 23:59까지면 종일로 연다
      _range = (start: start, end: end, allDay: fmt.isAllDay(start, end));
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
    return AppFormSheet(
      title: widget.existingSchedule != null ? '일정 수정' : '새 일정',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: widget.existingSchedule != null ? '수정' : '저장',
        onSubmit: _submit,
        busy: widget.busy,
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

  /// 칸과 시간을 검사한 뒤 [ScheduleFormSheetView.onSubmit]을 부른다
  void _submit() {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 시간 유효성 검사 (종일이 아닌 경우)
    if (!_range.allDay && _range.end.isBefore(_range.start)) {
      _showErrorSnackBar('종료 시간은 시작 시간보다 늦어야 합니다');
      return;
    }

    widget.onSubmit(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _range,
    );
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    showAppSnackBar(context, message, kind: AppNoticeKind.error);
  }
}
