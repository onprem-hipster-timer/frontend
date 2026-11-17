import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';

/// 추천 시간 카드 하나가 덮는 칸: 격자 칸 자리([MeetingCell.index])의 처음과 끝. 카드의 칸은 이 사이에 이어진다
typedef MeetingRunKey = ({int first, int last});

/// [run]의 칸 자리
MeetingRunKey meetingRunKey(MeetingRun run) =>
    (first: run.first.index, last: run.last.index);

/// 격자에 강조할 추천 시간 카드. 마우스를 올린 카드([hovered])가 있으면 그것을, 없으면 고정한 카드([pinned])를
/// 강조한다. 고정은 한 번에 하나다
class MeetingRunHighlight extends ChangeNotifier {
  MeetingRunKey? _hovered;
  MeetingRunKey? _pinned;

  MeetingRunKey? get hovered => _hovered;
  MeetingRunKey? get pinned => _pinned;

  /// 지금 강조할 카드
  MeetingRunKey? get shown => _hovered ?? _pinned;

  void hover(MeetingRunKey? key) {
    if (_hovered == key) return;
    _hovered = key;
    notifyListeners();
  }

  /// [key] 카드를 고정하거나, 이미 고정했으면 푼다. 다른 카드를 고정하면 앞의 것은 풀린다
  void toggle(MeetingRunKey key) {
    _pinned = _pinned == key ? null : key;
    notifyListeners();
  }

  /// 고정을 푼다(칠하기 시작했거나 그 카드가 없어졌을 때)
  void unpin() {
    if (_pinned == null) return;
    _pinned = null;
    notifyListeners();
  }
}
