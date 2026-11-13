import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

/// 공유한 사람 [ownerId]를 알리는 글자. 친구 목록에서 이름을 찾는다
///
/// 이름을 알면 '영희님이 공유', 이름 없는 친구면 '친구가 공유', 친구 목록에 없거나
/// 목록을 아직 모르면 '공유받음'이다. [prefix]를 주면 그 뒤에 붙인다.
///
/// 테스트: test/features/visibility/presentation/widgets/shared_by_text_test.dart
class SharedByText extends ConsumerWidget {
  const SharedByText({
    super.key,
    required this.ownerId,
    this.prefix = '',
    this.style,
    this.maxLines = 2,
  });

  final String? ownerId;
  final String prefix;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider).value;
    return Text(
      '$prefix${sharedByLabel(friends, ownerId)}',
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// [SharedByText]가 보이는 글자
String sharedByLabel(List<FriendRead>? friends, String? ownerId) {
  final owner = friends?.where((f) => f.userId == ownerId).firstOrNull;
  if (owner == null) return '공유받음';
  final name = owner.displayName;
  return name == null || name.isEmpty ? '친구가 공유' : '$name님이 공유';
}
