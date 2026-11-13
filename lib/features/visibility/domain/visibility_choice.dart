import 'package:momeet/features/visibility/domain/email_allow_list.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 공유 설정 시트에서 고르는 중인 값. 범위를 바꿔도 다른 범위의 목록은 그대로 둔다
///
/// 테스트: test/features/visibility/presentation/widgets/visibility_sheet_test.dart
class VisibilityChoice {
  /// 저장된 설정 [saved]로 시작한다. 없으면 비공개
  VisibilityChoice.from(VisibilityRead? saved)
    : level = saved?.level ?? VisibilityLevel.private,
      friendIds = {...?saved?.allowedUserIds},
      allowList = EmailAllowList(
        emails: saved?.allowedEmails ?? const [],
        domains: saved?.allowedDomains ?? const [],
      );

  VisibilityLevel level;

  /// 선택한 친구의 사용자 ID
  final Set<String> friendIds;

  /// 허용할 이메일·도메인
  final EmailAllowList allowList;

  /// 고른 친구 중 [friends]에 있는 사람. 친구 목록이 없으면 비어 있다
  List<String> selectedFriendIds(List<FriendRead>? friends) => [
    for (final friend in friends ?? const <FriendRead>[])
      if (friendIds.contains(friend.userId)) friend.userId,
  ];

  /// 선택한 친구는 친구를 하나 이상 골라야 저장한다
  bool canSave(List<FriendRead>? friends) => switch (level) {
    VisibilityLevel.selected => selectedFriendIds(friends).isNotEmpty,
    VisibilityLevel.$unknown => false,
    _ => true,
  };

  /// 저장할 공유 설정. 그 범위가 쓰는 목록만 담는다. 비공개면 null (설정을 지운다)
  VisibilityUpdate? update(List<FriendRead>? friends) => switch (level) {
    VisibilityLevel.private => null,
    VisibilityLevel.selected => VisibilityUpdate(
      level: level,
      allowedUserIds: selectedFriendIds(friends),
    ),
    VisibilityLevel.allowedEmails => VisibilityUpdate(
      level: level,
      allowedEmails: allowList.emails,
      allowedDomains: allowList.domains,
    ),
    _ => VisibilityUpdate(level: level),
  };
}
