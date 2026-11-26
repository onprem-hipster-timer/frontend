import 'package:flutter/semantics.dart';
import 'package:layout_audit/layout_audit.dart';

/// 이 앱이 설계상 허용하는 배치. 레이아웃 점검의 예외는 모두 여기에만 둔다.
///
/// `test/flutter_test_config.dart`가 바인딩에 넣고, 자동 점검과 `testLayoutAudit`이 같이 쓴다.
final appLayoutAuditPolicy = LayoutAuditPolicy(
  // 뒤 내용 위에 떠서 덮는 것이 설계인 위젯. 목록 끝 여백은 화면 테스트가 따로 본다. 모임 화면의 유리 머리띠는
  // 굴린 내용이 그 아래로 지나간다(처음 위치는 meeting_glass_scaffold_test가 본다).
  floatingWidgets: const {
    'FloatingActionButton',
    'Drawer',
    'NavigationDrawer',
    'MeetingGlassBar',
  },
  // Overlay 위 라우트(다이얼로그·시트)가 뒤 화면을 덮는 층
  coveringLayers: const {'_RenderTheater'},
  isUnscaledText: _isIconGlyph,
  // 눌러서 닫는 장벽(시트·다이얼로그 뒤 배경)
  isBackdrop: (data) => data.hasAction(SemanticsAction.dismiss),
  ignore: (finding) =>
      _isFoldedSchedule(finding) ||
      _isTagName(finding) ||
      _isOptionalTrustLink(finding),
);

/// 아이콘 글꼴의 글리프(사용자 정의 영역)만으로 된 문단. 아이콘은 글자 배율을 따르지 않는다.
bool _isIconGlyph(String text) =>
    text.isNotEmpty &&
    text.runes.every((r) => (r >= 0xE000 && r <= 0xF8FF) || r >= 0xF0000);

/// 달력 칸에 다 들어가지 않는 일정 제목은 +N으로 접히는 것이 설계다.
/// 접혀도 빠진 일정이 없는지는 test/layout_audit/calendar_screens_layout_test.dart의
/// expectNoHiddenSchedule이 센다.
bool _isFoldedSchedule(LayoutFinding finding) =>
    finding.kind == LayoutFindingKind.scaleVanished &&
    _inFile(finding, const [
      'schedule_appointment_block.dart',
      'marquee_text.dart',
    ]);

/// 태그 통계의 태그 이름은 사용자가 정하므로 큰 배율에서 말줄임될 수 있다.
bool _isTagName(LayoutFinding finding) =>
    finding.kind == LayoutFindingKind.scaleTruncation &&
    _inFile(finding, const ['tag_stats_section.dart']);

/// 모임을 만들 때 로그인을 묻는 시트·대화상자의 개인정보 보호 조치 안내 링크는 자리가 없으면 빠지는 것이 설계다.
/// 빠져도 묻기가 굴러가지 않고 두 버튼이 다 보이는지는
/// test/features/meeting/presentation/widgets/meeting_create_login_prompt_test.dart가 본다.
bool _isOptionalTrustLink(LayoutFinding finding) =>
    (finding.kind == LayoutFindingKind.scaleVanished ||
        finding.kind == LayoutFindingKind.scaleUnreachable) &&
    finding.texts.contains('내 정보는 어떻게 지키나요?');

bool _inFile(LayoutFinding finding, List<String> files) => finding.locations
    .any((l) => l != null && files.any((file) => l.file.endsWith(file)));
