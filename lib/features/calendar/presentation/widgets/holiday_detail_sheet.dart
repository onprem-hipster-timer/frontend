import 'package:flutter/material.dart';
import 'package:momeet/shared/api/export.dart';

/// 휴일 상세 정보를 보여주는 Bottom Sheet
///
/// 공휴일을 클릭했을 때 휴일 정보를 간단하게 표시합니다.
class HolidayDetailSheet extends StatelessWidget {
  final HolidayItem holiday;

  const HolidayDetailSheet({
    super.key,
    required this.holiday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 휴일 아이콘
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.red,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 16),

                // 휴일 이름
                Text(
                  holiday.dateName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // 날짜 표시
                Text(
                  _formatDate(holiday.locdate),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 24),

                // 닫기 버튼
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('닫기'),
                  ),
                ),

                // 안전 영역 확보
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 날짜 포맷팅 (locdate: "20241225" -> "2024년 12월 25일")
  String _formatDate(String locdate) {
    if (locdate.length != 8) return locdate;

    try {
      final year = locdate.substring(0, 4);
      final month = locdate.substring(4, 6);
      final day = locdate.substring(6, 8);

      return '$year년 ${int.parse(month)}월 ${int.parse(day)}일';
    } catch (e) {
      return locdate;
    }
  }
}

/// 휴일 상세 시트를 표시하는 헬퍼 함수
///
/// 사용 예:
/// ```dart
/// showHolidayDetailSheet(context, holiday);
/// ```
Future<void> showHolidayDetailSheet(
  BuildContext context,
  HolidayItem holiday,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => HolidayDetailSheet(holiday: holiday),
  );
}
