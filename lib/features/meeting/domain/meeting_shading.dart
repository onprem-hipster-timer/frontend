import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';

/// 격자가 칸마다 칠하는 값: 내 칸의 답과, 칸마다 되는(안 되는) 다른 사람 수.
///
/// 로그인한 참여자는 [MeetingBoard](이름과 내 시간이 있다), 로그인하지 않은 방문자는 사람 수만 있는 값이다.
abstract interface class MeetingShading {
  MeetingGrid get grid;

  /// 보는 사람이 내 시간을 가질 수 있는지(로그인했는지). 아니면 모든 참여자가 '다른 사람'이다
  bool get hasSelf;

  /// 농도를 나누는 기준이 되는 다른 사람 수
  int get othersTotal;

  /// [cell]이 되는 다른 사람 수
  int othersCountAt(MeetingCell cell);

  /// [cell]이 안 된다고 한 다른 사람 수
  int othersUnavailableCountAt(MeetingCell cell);

  /// [cell]의 내 답. 내 시간이 없으면 늘 답하지 않은 칸이다
  MeetingAnswer answerAt(MeetingCell cell);
}
