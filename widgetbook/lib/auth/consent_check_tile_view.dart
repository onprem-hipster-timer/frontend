import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/consent_check_tile.dart';
import 'package:momeet/features/auth/presentation/widgets/consent_check_tile_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_account.dart';

/// 약관 동의 화면의 항목. (문구, 보기 있음, 설명, 굵게)
const _items = <(String, bool, String?, bool)>[
  (ConsentLabels.all, false, null, true),
  (ConsentLabels.ageOver14, false, null, false),
  (ConsentLabels.terms, true, null, false),
  (ConsentLabels.privacy, true, null, false),
  (
    '[선택] 화면 개선을 위한 사용성 분석 동의',
    false,
    '화면 이용 기록이 Microsoft Clarity(미국)로 전송되어 최대 9개월 보관됩니다. '
        '입력한 내용은 가려지고, 거부해도 이용에 제한이 없습니다.',
    false,
  ),
];

@widgetbook.UseCase(
  name: '약관 동의 항목',
  type: ConsentCheckTileView,
  path: '[로그인·회원가입]',
)
Widget consentCheckTileView(BuildContext context) {
  final item = context.knobs.object.dropdown(
    label: '항목',
    options: _items,
    labelBuilder: (item) => item.$1,
    initialOption: _items[2],
    description: '전체 동의는 굵게, 약관은 옆에 보기를, 선택 항목은 아래에 설명을 둔다',
  );
  final (label, link, description, emphasized) = item;
  // 앱에서는 약관 동의 화면과 모임의 게스트 입장에서 항목을 위아래로 잇는다. 보기를 누르면 약관을 새 창으로 연다
  return authScreenFrame(
    _Tile(
      key: ValueKey(item),
      label: label,
      link: link,
      description: description,
      emphasized: emphasized,
    ),
  );
}

/// 누른 체크가 바로 보이도록 값을 들고 있는다
class _Tile extends StatefulWidget {
  const _Tile({
    super.key,
    required this.label,
    required this.link,
    required this.description,
    required this.emphasized,
  });

  final String label;
  final bool link;
  final String? description;
  final bool emphasized;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  var _checked = false;

  @override
  Widget build(BuildContext context) {
    return ConsentCheckTileView(
      label: widget.label,
      value: _checked,
      onChanged: (checked) => setState(() => _checked = checked),
      onOpenLink: widget.link ? () {} : null,
      description: widget.description,
      emphasized: widget.emphasized,
    );
  }
}
