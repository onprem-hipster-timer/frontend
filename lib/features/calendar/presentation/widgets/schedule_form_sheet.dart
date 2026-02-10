import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';

/// 일정 생성을 위한 Modal Bottom Sheet 위젯
///
/// FloatingActionButton을 눌렀을 때 올라오는 Bottom Sheet 내부에서 사용됩니다.
/// 제목, 일시(시작/종료), 설명, 종일 옵션을 입력받아 새로운 일정을 생성합니다.
class ScheduleFormSheet extends ConsumerStatefulWidget {
  /// 초기 시작 시간 (선택사항)
  final DateTime? initialStartTime;

  /// 초기 종료 시간 (선택사항)
  final DateTime? initialEndTime;

  const ScheduleFormSheet({
    super.key,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  ConsumerState<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends ConsumerState<ScheduleFormSheet> {
  // Form 관리
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  // 날짜/시간 상태
  late DateTime _startTime;
  late DateTime _endTime;
  bool _isAllDay = false;

  // 날짜 포맷터
  final DateFormat _dateTimeFormat = DateFormat('M월 d일 (E) HH:mm', 'ko');
  final DateFormat _dateFormat = DateFormat('M월 d일 (E)', 'ko');

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    // 초기 시간 설정 (현재 시간의 다음 정각, 종료는 +1시간)
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1, 0);

    _startTime = widget.initialStartTime ?? nextHour;
    _endTime = widget.initialEndTime ?? _startTime.add(const Duration(hours: 1));
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

    return Padding(
      // 키보드가 올라왔을 때 UI가 가려지지 않도록 처리
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom Sheet 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 헤더
              Text(
                '새 일정',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // 제목 입력
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '제목',
                  hintText: '일정 제목을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
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

              // 종일 토글
              SwitchListTile(
                title: const Text('종일'),
                subtitle: Text(
                  _isAllDay ? '하루 종일 일정으로 설정됩니다' : '시간을 지정할 수 있습니다',
                  style: theme.textTheme.bodySmall,
                ),
                value: _isAllDay,
                onChanged: (value) {
                  setState(() {
                    _isAllDay = value;
                    if (_isAllDay) {
                      // 종일로 설정하면 시간을 00:00과 23:59로 조정
                      final startDate = DateTime(_startTime.year, _startTime.month, _startTime.day);
                      _startTime = startDate;
                      _endTime = DateTime(_endTime.year, _endTime.month, _endTime.day, 23, 59);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 16),

              // 시작 시간
              Text(
                '시작',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(context, isStartTime: true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAllDay ? Icons.calendar_today : Icons.schedule,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isAllDay
                            ? _dateFormat.format(_startTime)
                            : _dateTimeFormat.format(_startTime),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 종료 시간
              Text(
                '종료',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(context, isStartTime: false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAllDay ? Icons.calendar_today : Icons.schedule,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isAllDay
                            ? _dateFormat.format(_endTime)
                            : _dateTimeFormat.format(_endTime),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              // 시간 유효성 검사 에러 표시
              if (!_isAllDay && _endTime.isBefore(_startTime))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '종료 시간은 시작 시간보다 늦어야 합니다',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // 설명 입력
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '설명 (선택사항)',
                  hintText: '일정에 대한 메모를 작성하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),

              const SizedBox(height: 32),

              // 버튼 영역
              Row(
                children: [
                  // 취소 버튼
                  Expanded(
                    child: OutlinedButton(
                      onPressed: mutations.isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 저장 버튼
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: mutations.isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: mutations.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('저장'),
                    ),
                  ),
                ],
              ),

              // 키보드 여백
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 날짜/시간 선택 다이얼로그 표시
  Future<void> _selectDateTime(BuildContext context, {required bool isStartTime}) async {
    final currentTime = isStartTime ? _startTime : _endTime;

    // 날짜 선택
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ko'),
    );

    if (selectedDate == null || !mounted) return;

    DateTime newDateTime = selectedDate;

    // 종일이 아닌 경우 시간도 선택
    if (!_isAllDay) {
      final selectedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentTime),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          );
        },
      );

      if (selectedTime == null || !mounted) return;

      newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    } else {
      // 종일인 경우 시작은 00:00, 종료는 23:59
      if (isStartTime) {
        newDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      } else {
        newDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59);
      }
    }

    if (mounted) {
      setState(() {
        if (isStartTime) {
          _startTime = newDateTime;
          // 시작 시간이 종료 시간보다 늦으면 종료 시간을 조정
          if (_startTime.isAfter(_endTime)) {
            if (_isAllDay) {
              _endTime = DateTime(_startTime.year, _startTime.month, _startTime.day, 23, 59);
            } else {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          }
        } else {
          _endTime = newDateTime;
          // 종료 시간이 시작 시간보다 빠르면 시작 시간을 조정
          if (_endTime.isBefore(_startTime)) {
            if (_isAllDay) {
              _startTime = DateTime(_endTime.year, _endTime.month, _endTime.day);
            } else {
              _startTime = _endTime.subtract(const Duration(hours: 1));
            }
          }
        }
      });
    }
  }

  /// 폼 제출 처리
  Future<void> _handleSubmit() async {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 시간 유효성 검사 (종일이 아닌 경우)
    if (!_isAllDay && _endTime.isBefore(_startTime)) {
      _showErrorSnackBar('종료 시간은 시작 시간보다 늦어야 합니다');
      return;
    }

    // BuildContext를 미리 저장 (async gap 경고 방지)
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // ScheduleCreate 객체 생성
      final scheduleCreate = ScheduleCreate(
        title: _titleController.text.trim(),
        startTime: _startTime.toUtc(), // UTC로 변환
        endTime: _endTime.toUtc(), // UTC로 변환
        description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      );

      // API 호출
      await ref.read(scheduleMutationsProvider.notifier).createSchedule(scheduleCreate);

      // 성공 시 Bottom Sheet 닫기
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('일정이 생성되었습니다'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (error) {
      // 에러 처리
      debugPrint('일정 생성 에러: $error');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('일정 생성에 실패했습니다: ${error.toString()}'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Modal Bottom Sheet를 보여주는 헬퍼 함수
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
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // 키보드가 올라와도 전체 크기 유지
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ScheduleFormSheet(
        initialStartTime: initialStartTime,
        initialEndTime: initialEndTime,
      ),
    ),
  );
}
