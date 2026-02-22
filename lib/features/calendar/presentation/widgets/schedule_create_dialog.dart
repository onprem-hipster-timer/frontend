import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';

/// 새로운 일정 생성 다이얼로그
///
/// Material 3 디자인을 사용하여 일정 생성 폼을 제공합니다.
/// 제목, 설명, 시작/종료 시간을 입력받아 새로운 일정을 생성할 수 있습니다.
class ScheduleCreateDialog extends ConsumerStatefulWidget {
  /// 기본 시작 시간 (선택사항)
  final DateTime? defaultStartTime;

  /// 기본 종료 시간 (선택사항)
  final DateTime? defaultEndTime;

  const ScheduleCreateDialog({
    super.key,
    this.defaultStartTime,
    this.defaultEndTime,
  });

  @override
  ConsumerState<ScheduleCreateDialog> createState() =>
      _ScheduleCreateDialogState();
}

class _ScheduleCreateDialogState extends ConsumerState<ScheduleCreateDialog> {
  // Form 관리
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  // 날짜/시간 상태
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    // 기본 시간 설정 (현재 시간 + 1시간 간격)
    final now = DateTime.now();
    final roundedNow = DateTime(
      now.year, now.month, now.day, now.hour,
      (now.minute ~/ 15) * 15, // 15분 단위로 반올림
    );

    _startTime = widget.defaultStartTime ?? roundedNow;
    _endTime =
        widget.defaultEndTime ?? _startTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutations = ref.watch(scheduleMutationsProvider);

    return AlertDialog(
      title: const Text('새 일정 만들기'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 입력
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '제목',
                    hintText: '일정 제목을 입력하세요',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // 설명 입력
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '설명 (선택사항)',
                    hintText: '일정 설명을 입력하세요',
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),

                const SizedBox(height: 16),

                // 시작 시간
                Text(
                  '시작 시간',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDateTime(context, isStartTime: true),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDateTime(_startTime),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 종료 시간
                Text(
                  '종료 시간',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDateTime(context, isStartTime: false),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDateTime(_endTime),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),

                // 시간 유효성 검사 에러 표시
                if (_endTime.isBefore(_startTime) ||
                    _endTime.isAtSameMomentAs(_startTime))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '종료 시간은 시작 시간보다 늦어야 합니다',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // 취소 버튼
        TextButton(
          onPressed:
              mutations.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),

        // 저장 버튼
        FilledButton(
          onPressed: mutations.isLoading ? null : _handleSave,
          child: mutations.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('저장'),
        ),
      ],
    );
  }

  /// 날짜/시간 선택 다이얼로그 표시
  Future<void> _selectDateTime(BuildContext context,
      {required bool isStartTime}) async {
    final currentTime = isStartTime ? _startTime : _endTime;

    // 날짜 선택
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (selectedDate == null || !mounted) return;

    // 시간 선택
    final selectedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentTime),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true, // 24시간 형식 사용
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null || !mounted) return;

    // 선택된 날짜와 시간 결합
    final newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (mounted) {
      setState(() {
        if (isStartTime) {
          _startTime = newDateTime;
          // 시작 시간이 종료 시간보다 늦으면 종료 시간을 1시간 뒤로 조정
          if (_startTime.isAfter(_endTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = newDateTime;
          // 종료 시간이 시작 시간보다 빠르면 시작 시간을 1시간 앞으로 조정
          if (_endTime.isBefore(_startTime)) {
            _startTime = _endTime.subtract(const Duration(hours: 1));
          }
        }
      });
    }
  }

  /// 날짜/시간을 한국어 형식으로 포맷
  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[dateTime.weekday];

    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ($weekday) '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 폼 유효성 검사 및 저장 처리
  Future<void> _handleSave() async {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 시간 유효성 검사
    if (_endTime.isBefore(_startTime) ||
        _endTime.isAtSameMomentAs(_startTime)) {
      _showErrorSnackBar('종료 시간은 시작 시간보다 늦어야 합니다');
      return;
    }

    // BuildContext를 먼저 저장 (async gap 경고 해결)
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      // ScheduleCreate 객체 생성
      final scheduleCreate = ScheduleCreate(
        title: _titleController.text.trim(),
        startTime: _startTime.toUtc(), // UTC로 변환
        endTime: _endTime.toUtc(), // UTC로 변환
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        // 기본값들은 API 모델에서 처리
      );

      // API 호출
      await ref
          .read(scheduleMutationsProvider.notifier)
          .createSchedule(scheduleCreate);

      // 성공 시 다이얼로그 닫기
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('일정이 생성되었습니다'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      }
    } catch (error) {
      // 에러 처리
      debugPrint('일정 생성 에러: $error');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('일정 생성에 실패했습니다: ${error.toString()}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// 다이얼로그를 표시하는 헬퍼 함수
///
/// 사용 예:
/// ```dart
/// showScheduleCreateDialog(
///   context,
///   defaultStartTime: DateTime.now(),
/// );
/// ```
Future<void> showScheduleCreateDialog(
  BuildContext context, {
  DateTime? defaultStartTime,
  DateTime? defaultEndTime,
}) {
  return showDialog(
    context: context,
    builder: (context) => ScheduleCreateDialog(
      defaultStartTime: defaultStartTime,
      defaultEndTime: defaultEndTime,
    ),
  );
}
