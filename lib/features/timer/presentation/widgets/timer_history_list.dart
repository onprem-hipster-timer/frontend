import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/friend_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/shared_timer_item.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_item.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_list_view.dart';

/// 타이머 히스토리 목록. 모양은 [TimerHistoryListView]
///
/// 친구 타이머를 고를 때마다 다시 읽고, 친구 타이머와 친구 목록은 고른 동안만 읽습니다.
class TimerHistoryList extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const TimerHistoryList({super.key, this.scrollController});

  @override
  ConsumerState<TimerHistoryList> createState() => _TimerHistoryListState();
}

class _TimerHistoryListState extends ConsumerState<TimerHistoryList> {
  /// 친구가 공유한 타이머를 보는 중
  bool _shared = false;

  @override
  Widget build(BuildContext context) {
    return TimerHistoryListView(
      scrollController: widget.scrollController,
      shared: _shared,
      onSharedChanged: (shared) {
        setState(() => _shared = shared);
        if (_shared) ref.invalidate(sharedTimersProvider);
      },
      history: ref.watch(timerHistoryProvider),
      sharedTimers: _shared
          ? ref.watch(sharedTimersProvider)
          : const AsyncLoading(),
      friends: _shared
          ? ref.watch(friendsProvider).value ?? const <FriendRead>[]
          : const [],
      historyItemBuilder: (timer) => TimerHistoryItem(timer: timer),
      sharedItemBuilder: (timer, ownerName) =>
          SharedTimerItem(timer: timer, ownerName: ownerName),
    );
  }
}
