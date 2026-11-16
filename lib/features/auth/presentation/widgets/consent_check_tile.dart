import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/browser_provider.dart';

/// 필수 약관 동의 세 항목의 문구. 회원 동의와 게스트 입장이 같은 문구를 쓴다
abstract final class ConsentLabels {
  static const all = '전체 동의';
  static const ageOver14 = '[필수] 만 14세 이상입니다';
  static const terms = '[필수] 이용약관 동의';
  static const privacy = '[필수] 개인정보 수집·이용 동의';
}

/// 동의 항목 하나. [link]를 주면 옆에 '보기'를 둔다. [emphasized]는 '전체 동의'처럼 굵게 쓴다
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
    final description = this.description;
    final onChanged = this.onChanged;
    return CheckboxListTile(
      value: value,
      onChanged: onChanged == null
          ? null
          : (checked) => onChanged(checked ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        label,
        style: emphasized
            ? Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : null,
      ),
      subtitle: description == null ? null : Text(description),
      secondary: link == null
          ? null
          : TextButton(
              onPressed: () => ref.read(openLinkProvider)(link),
              // 항목 글자가 쓸 폭을 남기도록 기본 최소 폭(64) 대신 터치 영역(48)만 둔다
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('보기'),
            ),
    );
  }
}
