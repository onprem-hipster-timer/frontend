import 'package:material_ui/material_ui.dart';

/// 아래의 모임 상자(MeetingPanel, 계정 줄)를 상자 없는 조용한 모양으로 그린다
class MeetingQuietPanels extends InheritedWidget {
  const MeetingQuietPanels({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MeetingQuietPanels>() != null;

  @override
  bool updateShouldNotify(MeetingQuietPanels oldWidget) => false;
}
