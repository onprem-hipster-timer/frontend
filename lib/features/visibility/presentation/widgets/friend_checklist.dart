import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 공유할 친구를 고르는 체크 목록
class FriendChecklist extends StatelessWidget {
  const FriendChecklist({
    super.key,
    required this.friends,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    required this.onRetry,
  });

  final AsyncValue<List<FriendRead>> friends;
  final Set<String> selected;
  final bool enabled;
  final void Function(String userId, bool checked) onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: friends.when(
        loading: () =>
            const Padding(padding: EdgeInsets.all(16), child: AppLoading()),
        error: (error, _) => ListTile(
          title: const Text('친구 목록을 불러오지 못했습니다'),
          trailing: TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ),
        data: (friends) => friends.isEmpty
            ? const ListTile(
                title: Text('친구가 없습니다'),
                subtitle: Text('친구를 맺으면 여기서 고를 수 있습니다'),
              )
            : Column(
                children: [
                  for (final friend in friends)
                    CheckboxListTile(
                      value: selected.contains(friend.userId),
                      enabled: enabled,
                      onChanged: (checked) =>
                          onChanged(friend.userId, checked ?? false),
                      title: Text(
                        friend.displayName ?? '이름 없는 친구',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
