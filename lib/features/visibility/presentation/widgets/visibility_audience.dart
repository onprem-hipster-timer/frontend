import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/visibility/domain/visibility_choice.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 고른 공유 설정 [choice]로 저장하면 누가 볼 수 있는지 알리는 줄
///
/// [friends]가 null이면 친구 목록을 아직 모른다.
class VisibilityAudience extends StatelessWidget {
  const VisibilityAudience({
    super.key,
    required this.choice,
    required this.friends,
  });

  final VisibilityChoice choice;
  final List<FriendRead>? friends;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.visibility_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _sentence(choice, friends),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

String _sentence(VisibilityChoice choice, List<FriendRead>? friends) {
  final allowList = choice.allowList;
  switch (choice.level) {
    case VisibilityLevel.friends when friends != null && friends.isEmpty:
      return '아직 친구가 없어 저장해도 나만 볼 수 있습니다';
    case VisibilityLevel.friends:
      return '저장하면 내 친구 모두가 볼 수 있습니다';
    case VisibilityLevel.selected:
      final count = choice.selectedFriendIds(friends).length;
      return count == 0
          ? '친구를 한 명 이상 고르면 저장할 수 있습니다'
          : '저장하면 고른 친구 $count명만 볼 수 있습니다';
    case VisibilityLevel.allowedEmails when allowList.isEmpty:
      return '허용할 이메일이나 도메인이 없어 저장해도 나만 볼 수 있습니다';
    case VisibilityLevel.allowedEmails:
      final counts = [
        if (allowList.emails.isNotEmpty) '이메일 ${allowList.emails.length}개',
        if (allowList.domains.isNotEmpty) '도메인 ${allowList.domains.length}개',
      ].join('·');
      return '저장하면 이메일 인증을 마친 사용자 중 $counts에 해당하는 사람이 볼 수 있습니다';
    default:
      return '저장하면 나만 볼 수 있습니다';
  }
}
