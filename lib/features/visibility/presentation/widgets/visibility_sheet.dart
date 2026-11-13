import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/visibility/domain/resource_visibility.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

/// 공유 범위 선택지의 이름과 설명
const _options = {
  VisibilityLevel.private: (label: '비공개', description: '나만 봄'),
  VisibilityLevel.friends: (label: '친구 공개', description: '모든 친구'),
  VisibilityLevel.selected: (label: '선택한 친구', description: '고른 친구만'),
};

/// [target]의 공유 범위를 고르는 바텀 시트를 연다. 선택지는 [levels]를 이 순서로 보인다
///
/// 지금 설정을 읽어 고른 상태로 보여 준다. 저장하면 비공개는 설정을 지우고(DELETE),
/// 그 외는 그 범위가 쓰는 목록만 보낸다(PUT).
/// 저장하면 시트를 닫고 알린 뒤 [onSaved]로 화면에 반영한다. 저장하는 사이 시트가 닫혀도 그렇게 한다.
/// 저장에 실패하면 알리고 고른 값을 둔 채 머문다.
///
/// 테스트: test/features/timer/presentation/widgets/timer_share_sheet_test.dart
Future<void> showVisibilitySheet(
  BuildContext context, {
  required ResourceVisibility target,
  required List<VisibilityLevel> levels,
  required Future<void> Function(ProviderContainer container) onSaved,
}) {
  return showAppSheet<void>(
    context,
    builder: (_) =>
        _VisibilitySheet(target: target, levels: levels, onSaved: onSaved),
  );
}

class _VisibilitySheet extends ConsumerStatefulWidget {
  const _VisibilitySheet({
    required this.target,
    required this.levels,
    required this.onSaved,
  });

  final ResourceVisibility target;
  final List<VisibilityLevel> levels;
  final Future<void> Function(ProviderContainer container) onSaved;

  @override
  ConsumerState<_VisibilitySheet> createState() => _VisibilitySheetState();
}

class _VisibilitySheetState extends ConsumerState<_VisibilitySheet> {
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
      final visibility = await widget.target.load();
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

  /// 저장하면 누가 볼 수 있는지. [friends]가 null이면 친구 목록을 아직 모른다
  String _audience(List<FriendRead>? friends) {
    switch (_level) {
      case VisibilityLevel.friends when friends != null && friends.isEmpty:
        return '아직 친구가 없어 저장해도 나만 볼 수 있습니다';
      case VisibilityLevel.friends:
        return '저장하면 내 친구 모두가 볼 수 있습니다';
      case VisibilityLevel.selected:
        final count = _selectedFriendIds(friends).length;
        return count == 0
            ? '친구를 한 명 이상 고르면 저장할 수 있습니다'
            : '저장하면 고른 친구 $count명만 볼 수 있습니다';
      default:
        return '저장하면 나만 볼 수 있습니다';
    }
  }

  Future<void> _save(List<FriendRead>? friends) async {
    // 다시 그리기 전에 연달아 누른 저장은 보내지 않는다
    if (_saving) return;
    final update = _update(friends);
    final target = widget.target;
    final onSaved = widget.onSaved;
    // 저장하는 사이 시트가 닫혀도 결과를 알리고 반영한다
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _saving = true);
    try {
      if (update == null) {
        await target.clear();
      } else {
        await target.save(update);
      }
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      messenger.showAppSnackBar('${Terms.visibility} 저장 실패: $error');
      return;
    }
    // 저장하는 사이 시트를 닫았으면 그 아래 화면은 닫지 않는다
    if (mounted && (ModalRoute.isCurrentOf(context) ?? false)) {
      Navigator.of(context).pop();
    }
    messenger.showAppSnackBar('${Terms.visibility.withJosa('을', '를')} 저장했습니다');
    await onSaved(container);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(padding: EdgeInsets.all(32), child: AppLoading());
    }

    if (_loadError != null) {
      return AppErrorState(
        title: '${Terms.visibility.withJosa('을', '를')} 불러오지 못했습니다',
        onRetry: _retry,
      );
    }

    // 친구 공개도 친구가 있는지 알아야 볼 수 있는 사람을 알린다
    final friends =
        _level == VisibilityLevel.friends || _level == VisibilityLevel.selected
        ? ref.watch(friendsProvider)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Terms.visibility,
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
                for (final level in widget.levels)
                  RadioListTile<VisibilityLevel>(
                    value: level,
                    enabled: !_saving,
                    title: Text(_options[level]!.label),
                    subtitle: Text(_options[level]!.description),
                  ),
              ],
            ),
          ),
          if (friends != null && _level == VisibilityLevel.selected)
            _FriendChecklist(
              friends: friends,
              selected: _friendIds,
              enabled: !_saving,
              onChanged: (id, checked) => setState(() {
                if (checked) {
                  _friendIds.add(id);
                } else {
                  _friendIds.remove(id);
                }
              }),
              onRetry: () => ref.invalidate(friendsProvider),
            ),
          const SizedBox(height: 16),
          _Audience(_audience(friends?.value)),
          const SizedBox(height: 8),
          AppFormActionBar(
            submitLabel: '저장',
            onSubmit: _canSave(friends?.value)
                ? () => _save(friends?.value)
                : null,
            busy: _saving,
          ),
        ],
      ),
    );
  }
}

/// 공유할 친구를 고르는 체크 목록
class _FriendChecklist extends StatelessWidget {
  const _FriendChecklist({
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

/// 저장하면 볼 수 있는 사람을 알리는 줄
class _Audience extends StatelessWidget {
  const _Audience(this.sentence);

  final String sentence;

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
        Expanded(child: Text(sentence, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
