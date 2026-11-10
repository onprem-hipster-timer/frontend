import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

/// 공유 범위 [level]의 아이콘. 설정이 없으면(null) 비공개
IconData visibilityLevelIcon(VisibilityLevel? level) => switch (level) {
  VisibilityLevel.friends => Icons.group_outlined,
  VisibilityLevel.selected => Icons.how_to_reg_outlined,
  VisibilityLevel.allowedEmails => Icons.alternate_email,
  VisibilityLevel.public => Icons.public,
  _ => Icons.lock_outline,
};

/// 내 타이머 [timer]의 공유 범위 아이콘 버튼. 누르면 [showTimerShareSheet]를 연다
class TimerShareButton extends StatelessWidget {
  const TimerShareButton({super.key, required this.timer});

  final TimerRead timer;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(visibilityLevelIcon(timer.visibilityLevel)),
      tooltip: '공유 설정',
      onPressed: () => showTimerShareSheet(context, timer: timer),
    );
  }
}

/// 공유 범위 선택지. 타이머의 실시간 변경은 주인의 친구에게만 가므로 이 셋만 고른다
const _options = [
  (level: VisibilityLevel.private, label: '비공개', description: '나만 봄'),
  (level: VisibilityLevel.friends, label: '친구 공개', description: '모든 친구'),
  (level: VisibilityLevel.selected, label: '선택한 친구', description: '고른 친구만'),
];

/// 내 타이머 [timer]의 공유 범위를 고르는 바텀 시트를 연다
///
/// 지금 설정을 읽어 고른 상태로 보여 준다. 저장하면 비공개는 설정을 지우고(DELETE),
/// 그 외는 그 범위가 쓰는 목록만 보낸다(PUT).
/// 저장하면 시트를 닫고 그 타이머를 다시 읽어
/// 대시보드와 타이머 목록에 반영한다. 저장에 실패하면 알리고 고른 값을 둔 채 머문다.
///
/// 테스트: test/features/timer/presentation/widgets/timer_share_sheet_test.dart
Future<void> showTimerShareSheet(
  BuildContext context, {
  required TimerRead timer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _TimerShareSheet(timer: timer),
  );
}

class _TimerShareSheet extends ConsumerStatefulWidget {
  const _TimerShareSheet({required this.timer});

  final TimerRead timer;

  @override
  ConsumerState<_TimerShareSheet> createState() => _TimerShareSheetState();
}

class _TimerShareSheetState extends ConsumerState<_TimerShareSheet> {
  /// 지금 설정을 읽는 중
  bool _loading = true;

  /// 지금 설정을 읽지 못한 오류
  Object? _loadError;

  bool _saving = false;

  VisibilityLevel _level = VisibilityLevel.private;

  /// 선택한 친구의 사용자 ID
  final _friendIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final visibility = await ref
          .read(timerRepositoryProvider)
          .getVisibility(widget.timer.id);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _level = visibility?.level ?? VisibilityLevel.private;
        _friendIds.addAll(visibility?.allowedUserIds ?? const []);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  void _retry() {
    // 다시 그리기 전에 연달아 누른 다시 시도는 읽지 않는다. 두 번 읽으면 항목이 겹친다
    if (_loadError == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  /// 고른 친구 중 [friends]에 있는 사람. 친구 목록이 없으면 비어 있다
  List<String> _selectedFriendIds(List<FriendRead>? friends) => [
    for (final friend in friends ?? const <FriendRead>[])
      if (_friendIds.contains(friend.userId)) friend.userId,
  ];

  /// 선택한 친구는 친구를 하나 이상 골라야 저장한다
  bool _canSave(List<FriendRead>? friends) => switch (_level) {
    VisibilityLevel.selected => _selectedFriendIds(friends).isNotEmpty,
    VisibilityLevel.$unknown => false,
    _ => true,
  };

  /// 저장할 공유 설정. 비공개면 null (설정을 지운다)
  VisibilityUpdate? _update(List<FriendRead>? friends) => switch (_level) {
    VisibilityLevel.private => null,
    VisibilityLevel.selected => VisibilityUpdate(
      level: _level,
      allowedUserIds: _selectedFriendIds(friends),
    ),
    _ => VisibilityUpdate(level: _level),
  };

  Future<void> _save(List<FriendRead>? friends) async {
    // 다시 그리기 전에 연달아 누른 저장은 보내지 않는다
    if (_saving) return;
    final update = _update(friends);
    final timerId = widget.timer.id;
    // 저장하는 사이 시트가 닫혀도 결과를 알리고 반영한다
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final repository = container.read(timerRepositoryProvider);
    setState(() => _saving = true);
    try {
      if (update == null) {
        await repository.clearVisibility(timerId);
      } else {
        await repository.setVisibility(timerId, update);
      }
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('공유 설정 저장 실패: $error')));
      return;
    }
    // 저장하는 사이 시트를 닫았으면 그 아래 화면은 닫지 않는다
    if (mounted && (ModalRoute.isCurrentOf(context) ?? false)) {
      Navigator.of(context).pop();
    }
    messenger.showSnackBar(const SnackBar(content: Text('공유 설정을 저장했습니다')));
    await _reloadTimer(container, timerId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(heightFactor: 1, child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('공유 설정을 불러오지 못했습니다', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: _retry, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final friends = _level == VisibilityLevel.selected
        ? ref.watch(friendsProvider)
        : null;

    // 키보드가 올라오면 시트를 그만큼 올려 굴리는 영역이 키보드 위에 남게 한다
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '공유 설정',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            RadioGroup<VisibilityLevel>(
              groupValue: _level,
              onChanged: (level) {
                if (level != null) setState(() => _level = level);
              },
              child: Column(
                children: [
                  for (final option in _options)
                    RadioListTile<VisibilityLevel>(
                      value: option.level,
                      enabled: !_saving,
                      title: Text(option.label),
                      subtitle: Text(option.description),
                    ),
                ],
              ),
            ),
            if (friends != null) _friendList(friends),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: !_saving && _canSave(friends?.value)
                  ? () => _save(friends?.value)
                  : null,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _friendList(AsyncValue<List<FriendRead>> friends) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: friends.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => ListTile(
          title: const Text('친구 목록을 불러오지 못했습니다'),
          trailing: TextButton(
            onPressed: () => ref.invalidate(friendsProvider),
            child: const Text('다시 시도'),
          ),
        ),
        data: (friends) => friends.isEmpty
            ? const ListTile(title: Text('친구가 없습니다'))
            : Column(
                children: [
                  for (final friend in friends)
                    CheckboxListTile(
                      value: _friendIds.contains(friend.userId),
                      enabled: !_saving,
                      onChanged: (checked) => setState(() {
                        if (checked ?? false) {
                          _friendIds.add(friend.userId);
                        } else {
                          _friendIds.remove(friend.userId);
                        }
                      }),
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

/// 공유 설정을 바꾼 [timerId]를 다시 읽어 대시보드(활성 타이머)와 타이머 목록에 반영한다. 읽지 못하면 그대로 둔다
///
/// 공유 설정은 타이머의 `updated_at`을 바꾸지 않으므로 목록보다 먼저 보일 값([timerViewsProvider])도 바꾼다.
Future<void> _reloadTimer(ProviderContainer container, String timerId) async {
  try {
    final timer = await container
        .read(timerRepositoryProvider)
        .getTimer(timerId);
    container.read(timerViewsProvider.notifier).show(timer);
    if (container.exists(myActiveTimersProvider)) {
      final timers = container.read(myActiveTimersProvider.notifier);
      if (timers.timer(timerId) != null) timers.apply(timer);
    }
  } catch (error) {
    debugPrint('타이머 조회 실패: $error');
  }
  container.invalidate(timerHistoryProvider);
}
