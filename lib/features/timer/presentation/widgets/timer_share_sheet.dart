import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/visibility/domain/resource_visibility.dart';
import 'package:momeet/features/visibility/presentation/widgets/visibility_button.dart';
import 'package:momeet/features/visibility/presentation/widgets/visibility_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 내 타이머 [timer]의 공유 범위 아이콘 버튼. 누르면 [showTimerShareSheet]를 연다
class TimerShareButton extends StatelessWidget {
  const TimerShareButton({super.key, required this.timer});

  final TimerRead timer;

  @override
  Widget build(BuildContext context) {
    return VisibilityButton(
      level: timer.visibilityLevel,
      onPressed: () => showTimerShareSheet(context, timer: timer),
    );
  }
}

/// 타이머의 공유 범위 선택지. 타이머의 실시간 변경은 주인의 친구에게만 가므로 이 셋만 고른다
const _levels = [
  VisibilityLevel.private,
  VisibilityLevel.friends,
  VisibilityLevel.selected,
];

/// 내 타이머 [timer]의 공유 범위를 고르는 시트([showVisibilitySheet])를 연다
///
/// 저장하면 그 타이머를 다시 읽어 대시보드와 타이머 목록에 반영한다.
///
/// 테스트: test/features/timer/presentation/widgets/timer_share_sheet_test.dart
Future<void> showTimerShareSheet(
  BuildContext context, {
  required TimerRead timer,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showVisibilitySheet(
    context,
    target: _TimerVisibility(container.read(timerRepositoryProvider), timer.id),
    levels: _levels,
    onSaved: (container) => _reloadTimer(container, timer.id),
  );
}

/// [TimerRepository]로 타이머 [_timerId]의 공유 설정을 읽고 바꾼다
class _TimerVisibility implements ResourceVisibility {
  const _TimerVisibility(this._repository, this._timerId);

  final TimerRepository _repository;
  final String _timerId;

  @override
  Future<VisibilityRead?> load() => _repository.getVisibility(_timerId);

  @override
  Future<void> save(VisibilityUpdate update) =>
      _repository.setVisibility(_timerId, update);

  @override
  Future<void> clear() => _repository.clearVisibility(_timerId);
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
