import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 카탈로그가 날마다 같게 보이도록 예시의 날짜·시각은 고정한다
final planStamp = DateTime(2026, 2, 20, 9, 30);

TagRead planTag(String id, String name, String color) => TagRead(
  id: id,
  name: name,
  color: color,
  groupId: 'tag-group-life',
  createdAt: planStamp,
  updatedAt: planStamp,
);

final planTags = [
  planTag('tag-work', '업무', '#3F51B5'),
  planTag('tag-study', '공부', '#2E7D32'),
  planTag('tag-health', '운동', '#E64A19'),
  planTag('tag-hobby', '취미', '#8E24AA'),
  planTag('tag-family', '가족', '#00897B'),
  planTag('tag-money', '가계부', '#F9A825'),
  planTag('tag-trip', '여행', '#1E88E5'),
  planTag('tag-read', '독서', '#6D4C41'),
];

final planLongTag = planTag('tag-long', '분기 마감 전에 꼭 끝내야 하는 업무', '#C62828');

ScheduleRead planSchedule({
  required String id,
  required String title,
  required DateTime start,
  required DateTime end,
  ScheduleState state = ScheduleState.confirmed,
  List<TagRead> tags = const [],
  String? description,
  String? recurrenceRule,
}) => ScheduleRead(
  id: id,
  title: title,
  startTime: start,
  endTime: end,
  state: state,
  createdAt: planStamp,
  tags: tags,
  description: description,
  recurrenceRule: recurrenceRule,
);

/// 화면 아래에서 올라온 하단 시트 모양(어두운 바탕·둥근 윗모서리·끌기 손잡이).
/// 앱은 showAppSheet로 띄우지만 카탈로그에서는 그 안의 위젯만 그린다.
class PlanSheetFrame extends StatelessWidget {
  const PlanSheetFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheet = theme.bottomSheetTheme;
    return ColoredBox(
      color: Colors.black54,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: sheet.backgroundColor,
          shape: sheet.shape,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
