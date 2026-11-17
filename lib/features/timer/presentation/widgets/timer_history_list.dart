import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/friend_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/shared_timer_item.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_item.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 타이머 히스토리 목록
///
/// 머리말 아래에서 내 타이머와 친구가 공유한 타이머를 골라 봅니다. 친구 타이머를 고를 때마다 다시 읽습니다.
/// 바텀 시트 안에서는 시트의 [scrollController]로 목록을 스크롤합니다.
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
    final historyAsync = ref.watch(timerHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader('${Terms.timer} 목록'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('내 ${Terms.timer}')),
                ButtonSegment(value: true, label: Text('친구 ${Terms.timer}')),
              ],
              selected: {_shared},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _shared = selection.single);
                if (_shared) ref.invalidate(sharedTimersProvider);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _shared
                ? _SharedTimerList(scrollController: widget.scrollController)
                : historyAsync.when(
                    data: (timers) => timers.isEmpty
                        ? AppEmptyState(
                            icon: Icons.history,
                            title: '${Terms.timer.withJosa('이', '가')} 없습니다',
                            message:
                                '새 ${Terms.timer.withJosa('을', '를')} 시작해보세요',
                          )
                        : _TimerHistoryByDate(
                            timers: timers,
                            controller: widget.scrollController,
                          ),
                    loading: () => const AppLoading(),
                    error: (error, stack) =>
                        AppErrorState(title: '히스토리를 불러올 수 없습니다', error: error),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 날짜별로 묶은 타이머 기록 목록
class _TimerHistoryByDate extends StatelessWidget {
  const _TimerHistoryByDate({required this.timers, this.controller});

  final List<TimerRead> timers;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    // 날짜별로 그룹화
    final groupedTimers = <String, List<TimerRead>>{};
    for (final timer in timers) {
      final date = formatDate(timer.startedAt ?? timer.createdAt);
      groupedTimers.putIfAbsent(date, () => []).add(timer);
    }

    return ListView.builder(
      controller: controller,
      itemCount: groupedTimers.length,
      itemBuilder: (context, index) {
        final date = groupedTimers.keys.elementAt(index);
        final dateTimers = groupedTimers[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                date,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 해당 날짜의 타이머들
            ...dateTimers.map((timer) => TimerHistoryItem(timer: timer)),
          ],
        );
      },
    );
  }
}

/// 친구가 공유한 타이머 목록. 주인 이름은 친구 목록에서 찾는다
class _SharedTimerList extends ConsumerWidget {
  const _SharedTimerList({this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 친구 목록을 읽지 못하면 이름 대신 '다른 사용자'로 보인다
    final friends = {
      for (final friend in ref.watch(friendsProvider).value ?? <FriendRead>[])
        friend.userId: friend,
    };

    return ref
        .watch(sharedTimersProvider)
        .when(
          // 안내가 칸보다 길면 굴려 본다
          data: (timers) => timers.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '공유받은 ${Terms.timer.withJosa('이', '가')} 없습니다',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: timers.length,
                  itemBuilder: (context, index) {
                    final timer = timers[index];
                    final owner = friends[timer.ownerId];
                    return SharedTimerItem(
                      timer: timer,
                      ownerName: owner == null
                          ? '다른 사용자'
                          : owner.displayName ?? '이름 없는 친구',
                    );
                  },
                ),
          loading: () => const AppLoading(),
          // 오류 문구가 칸보다 길면 굴려 본다
          error: (error, stack) => Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '공유받은 ${Terms.timer.withJosa('을', '를')} 불러올 수 없습니다',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
  }
}
