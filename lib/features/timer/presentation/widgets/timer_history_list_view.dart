import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/utils/timer_history_format.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 타이머 히스토리 목록
///
/// 머리말 아래에서 내 타이머와 친구가 공유한 타이머를 골라 봅니다([shared]).
/// 항목은 내 타이머면 [historyItemBuilder], 친구 타이머면 주인 이름과 함께 [sharedItemBuilder]로 그립니다.
/// 바텀 시트 안에서는 시트의 [scrollController]로 목록을 스크롤합니다.
class TimerHistoryListView extends StatelessWidget {
  const TimerHistoryListView({
    super.key,
    this.scrollController,
    required this.shared,
    required this.onSharedChanged,
    required this.history,
    required this.sharedTimers,
    required this.friends,
    required this.historyItemBuilder,
    required this.sharedItemBuilder,
  });

  final ScrollController? scrollController;

  /// 친구가 공유한 타이머를 보는 중
  final bool shared;
  final ValueChanged<bool> onSharedChanged;

  /// 내 타이머 기록
  final AsyncValue<List<TimerRead>> history;

  /// 친구가 공유한 타이머. [shared]일 때만 보인다
  final AsyncValue<List<TimerRead>> sharedTimers;

  /// 친구 타이머의 주인 이름을 찾는 친구 목록
  final List<FriendRead> friends;
  final Widget Function(TimerRead timer) historyItemBuilder;
  final Widget Function(TimerRead timer, String ownerName) sharedItemBuilder;

  @override
  Widget build(BuildContext context) {
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
              selected: {shared},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  onSharedChanged(selection.single),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: shared
                ? _SharedTimerList(
                    timers: sharedTimers,
                    friends: friends,
                    itemBuilder: sharedItemBuilder,
                    scrollController: scrollController,
                  )
                : history.when(
                    data: (timers) => timers.isEmpty
                        ? AppEmptyState(
                            icon: Icons.history,
                            title: '${Terms.timer.withJosa('이', '가')} 없습니다',
                            message:
                                '새 ${Terms.timer.withJosa('을', '를')} 시작해보세요',
                          )
                        : _TimerHistoryByDate(
                            timers: timers,
                            itemBuilder: historyItemBuilder,
                            controller: scrollController,
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
  const _TimerHistoryByDate({
    required this.timers,
    required this.itemBuilder,
    this.controller,
  });

  final List<TimerRead> timers;
  final Widget Function(TimerRead timer) itemBuilder;
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
            ...dateTimers.map(itemBuilder),
          ],
        );
      },
    );
  }
}

/// 친구가 공유한 타이머 목록. 주인 이름은 친구 목록에서 찾는다
class _SharedTimerList extends StatelessWidget {
  const _SharedTimerList({
    required this.timers,
    required this.friends,
    required this.itemBuilder,
    this.scrollController,
  });

  final AsyncValue<List<TimerRead>> timers;
  final List<FriendRead> friends;
  final Widget Function(TimerRead timer, String ownerName) itemBuilder;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 친구 목록을 읽지 못하면 이름 대신 '다른 사용자'로 보인다
    final friends = {for (final friend in this.friends) friend.userId: friend};

    return timers.when(
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
                return itemBuilder(
                  timer,
                  owner == null ? '다른 사용자' : owner.displayName ?? '이름 없는 친구',
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
