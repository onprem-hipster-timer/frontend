import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';

/// 일정 상세 정보를 표시하는 Bottom Sheet
///
/// 일정을 탭했을 때 표시되는 상세 정보 화면입니다.
/// - 일반 일정: 제목, 시간, 설명, 태그, 수정/삭제 기능
/// - 휴일: 제목, 날짜만 표시 (수정/삭제 불가)
class ScheduleDetailSheet extends ConsumerWidget {
  /// 표시할 일정 정보 (일반 일정인 경우)
  final ScheduleRead? schedule;

  /// 휴일 정보 (휴일인 경우)
  final HolidayItem? holiday;

  /// 일반 일정용 생성자
  const ScheduleDetailSheet.schedule({
    super.key,
    required this.schedule,
  }) : holiday = null;

  /// 휴일용 생성자
  const ScheduleDetailSheet.holiday({
    super.key,
    required this.holiday,
  }) : schedule = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isHoliday = holiday != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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

              // 헤더 (제목과 아이콘)
              Row(
                children: [
                  Icon(
                    isHoliday ? Icons.celebration : Icons.event,
                    color: isHoliday ? Colors.red : theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isHoliday ? holiday!.dateName : schedule!.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isHoliday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '휴일',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // 시간 정보
              if (isHoliday) ...[
                _buildHolidayInfo(context, holiday!),
              ] else ...[
                _buildScheduleInfo(context, schedule!),
              ],

              const SizedBox(height: 32),

              // 액션 버튼 (일반 일정에만 표시)
              if (!isHoliday) ...[
                _buildActionButtons(context, ref, schedule!),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 휴일 정보 위젯
  Widget _buildHolidayInfo(BuildContext context, HolidayItem holiday) {
    final date = _parseHolidayDate(holiday.locdate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜
        _InfoRow(
          icon: Icons.calendar_today,
          label: '날짜',
          value: date != null
            ? DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(date)
            : holiday.locdate,
        ),

        const SizedBox(height: 16),

        // 종류
        _InfoRow(
          icon: Icons.category,
          label: '종류',
          value: holiday.dateKind,
        ),

        if (holiday.isHoliday) ...[
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.info,
            label: '구분',
            value: '법정공휴일',
          ),
        ],
      ],
    );
  }

  /// 일정 정보 위젯
  Widget _buildScheduleInfo(BuildContext context, ScheduleRead schedule) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시간 정보
        _InfoRow(
          icon: Icons.access_time,
          label: '시간',
          value: _formatScheduleTime(schedule),
        ),

        // 설명 (있는 경우)
        if (schedule.description != null && schedule.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.description,
            label: '설명',
            value: schedule.description!,
            isMultiline: true,
          ),
        ],

        // 태그 (있는 경우)
        if (schedule.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTagsSection(context, schedule.tags.toList()),
        ],

        // 상태
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.flag,
          label: '상태',
          value: _getStatusText(schedule.state.name),
          valueWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(schedule.state.name).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(schedule.state.name),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _getStatusColor(schedule.state.name),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // 반복 일정 (있는 경우)
        if (schedule.recurrenceRule != null) ...[
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.repeat,
            label: '반복',
            value: '반복 일정', // TODO: RRule 파싱하여 사용자 친화적 텍스트로 표시
          ),
        ],

        // 생성 시간
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.schedule,
          label: '생성',
          value: DateFormat('yyyy.MM.dd HH:mm').format(schedule.createdAt.toLocal()),
        ),
      ],
    );
  }

  /// 태그 섹션 위젯
  Widget _buildTagsSection(BuildContext context, List<TagRead> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              '태그',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => _buildTagChip(context, tag)).toList(),
        ),
      ],
    );
  }

  /// 태그 칩 위젯
  Widget _buildTagChip(BuildContext context, TagRead tag) {
    final color = _parseColor(tag.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        tag.name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 액션 버튼들 (수정/삭제)
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, ScheduleRead schedule) {
    final mutations = ref.watch(scheduleMutationsProvider);

    return Row(
      children: [
        // 수정 버튼
        Expanded(
          child: OutlinedButton.icon(
            onPressed: mutations.isLoading ? null : () => _handleEdit(context, schedule),
            icon: const Icon(Icons.edit),
            label: const Text('수정'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 삭제 버튼
        Expanded(
          child: FilledButton.icon(
            onPressed: mutations.isLoading ? null : () => _handleDelete(context, ref, schedule),
            icon: mutations.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete),
            label: Text(mutations.isLoading ? '삭제 중...' : '삭제'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 수정 버튼 핸들러
  void _handleEdit(BuildContext context, ScheduleRead schedule) {
    // 현재 시트를 닫고 수정 폼을 열기
    Navigator.of(context).pop();

    showScheduleEditSheet(context, schedule);
  }

  /// 삭제 버튼 핸들러
  Future<void> _handleDelete(BuildContext context, WidgetRef ref, ScheduleRead schedule) async {
    // 삭제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('"${schedule.title}" 일정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 삭제 실행
      await ref.read(scheduleMutationsProvider.notifier).deleteSchedule(schedule.id);

      // 성공 시 시트 닫기
      if (context.mounted) {
        Navigator.of(context).pop();

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('일정이 삭제되었습니다'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      // 에러 처리
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('삭제에 실패했습니다: ${error.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 일정 시간을 포맷팅
  String _formatScheduleTime(ScheduleRead schedule) {
    final start = schedule.startTime.toLocal();
    final end = schedule.endTime.toLocal();

    // 종일 이벤트 체크
    if (_isAllDay(start, end)) {
      if (_isSameDay(start, end.subtract(const Duration(days: 1)))) {
        return '${DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(start)} 종일';
      } else {
        return '${DateFormat('yyyy년 MM월 dd일', 'ko').format(start)} ~ ${DateFormat('yyyy년 MM월 dd일', 'ko').format(end.subtract(const Duration(days: 1)))}';
      }
    }

    // 시간이 있는 일정
    if (_isSameDay(start, end)) {
      // 같은 날
      return '${DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(start)}\n${DateFormat('HH:mm', 'ko').format(start)} ~ ${DateFormat('HH:mm', 'ko').format(end)}';
    } else {
      // 다른 날
      return '${DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko').format(start)} ~\n${DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko').format(end)}';
    }
  }

  /// 종일 이벤트 여부 확인
  bool _isAllDay(DateTime start, DateTime end) {
    return start.hour == 0 && start.minute == 0 &&
           end.hour == 0 && end.minute == 0 &&
           end.difference(start).inHours >= 24;
  }

  /// 같은 날인지 확인
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// 상태 텍스트 변환
  String _getStatusText(String status) {
    switch (status) {
      case 'PLANNED':
        return '계획됨';
      case 'CONFIRMED':
        return '확정됨';
      case 'CANCELLED':
        return '취소됨';
      default:
        return status;
    }
  }

  /// 상태 색상 반환
  Color _getStatusColor(String status) {
    switch (status) {
      case 'PLANNED':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Hex 색상 파싱
  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  /// 휴일 날짜 파싱
  DateTime? _parseHolidayDate(String locdate) {
    if (locdate.length != 8) return null;

    try {
      final year = int.parse(locdate.substring(0, 4));
      final month = int.parse(locdate.substring(4, 6));
      final day = int.parse(locdate.substring(6, 8));

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
}

/// 정보 행 위젯
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;
  final bool isMultiline;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isMultiline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: valueWidget ?? Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: valueWidget ?? Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// 일정 상세 시트를 표시하는 헬퍼 함수
Future<void> showScheduleDetailSheet(
  BuildContext context,
  ScheduleRead schedule,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ScheduleDetailSheet.schedule(schedule: schedule),
  );
}

