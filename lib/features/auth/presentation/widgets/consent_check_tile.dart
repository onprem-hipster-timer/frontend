import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/features/auth/presentation/widgets/consent_check_tile_view.dart';

/// 필수 약관 동의 세 항목의 문구. 회원 동의와 게스트 입장이 같은 문구를 쓴다
abstract final class ConsentLabels {
  static const all = '전체 동의';
  static const ageOver14 = '[필수] 만 14세 이상입니다';
  static const terms = '[필수] 이용약관 동의';
  static const privacy = '[필수] 개인정보 수집·이용 동의';
}

/// 동의 항목 하나. [link]를 주면 옆에 '보기'를 두고, 누르면 그 주소를 연다. 모양은 [ConsentCheckTileView]
class ConsentCheckTile extends ConsumerWidget {
  const ConsentCheckTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.link,
    this.description,
    this.emphasized = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Uri? link;
  final String? description;
  final bool emphasized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = this.link;
    return ConsentCheckTileView(
      label: label,
      value: value,
      onChanged: onChanged,
      onOpenLink: link == null ? null : () => ref.read(openLinkProvider)(link),
      description: description,
      emphasized: emphasized,
    );
  }
}
