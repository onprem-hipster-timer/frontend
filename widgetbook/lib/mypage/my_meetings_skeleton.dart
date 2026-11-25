import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meetings_skeleton.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '내 모임 불러오는 중',
  type: MyMeetingsSkeleton,
  path: '[마이페이지]',
)
Widget myMeetingsSkeleton(BuildContext context) {
  // 앱에서는 '내 모임' 카드 안, 모임 만들기 줄 아래에서 목록 자리를 채운다
  return const SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: double.infinity, child: MyMeetingsSkeleton()),
    ),
  );
}
