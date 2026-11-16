import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

part 'meeting_providers.g.dart';

/// 미팅 하나 (GET /v1/meetings/{meeting_id})
final meetingProvider = FutureProvider.autoDispose.family<MeetingRead, String>(
  (ref, meetingId) => ref
      .watch(meetingsApiProvider)
      .readMeetingV1MeetingsMeetingIdGet(meetingId: meetingId),
);

/// 미팅 만들기. 화면의 작업 상태는 [createMeetingMutation]이 담는다.
///
/// 사용 예: `createMeetingMutation.run(ref, (tsx) =>
/// tsx.get(meetingMutationsProvider.notifier).create(body, isPublic: true, allowGuests: true))`
@riverpod
class MeetingMutations extends _$MeetingMutations {
  @override
  void build() {}

  /// [body]로 미팅을 만든다. [isPublic]이면 링크가 있는 누구나 볼 수 있게 열고, 그다음 [allowGuests]면
  /// 게스트 로그인을 켠다(`PATCH allow_guests`). backend는 공개 미팅에서만 게스트를 켜므로 이 순서다.
  ///
  /// 공개로 열거나 게스트를 켜지 못하면 만든 미팅을 지우고 그 오류를 던진다. 다시 눌러도 미팅이 둘 생기지 않는다.
  Future<MeetingRead> create(
    MeetingCreate body, {
    required bool isPublic,
    required bool allowGuests,
  }) async {
    final meetings = ref.read(meetingsApiProvider);
    final meeting = await meetings.createMeetingV1MeetingsPost(body: body);
    if (!isPublic) return meeting;
    try {
      await ref
          .read(visibilityApiProvider)
          .setVisibilityV1VisibilityResourceTypeResourceIdPut(
            resourceType: ResourceType.meeting,
            resourceId: meeting.id,
            body: const VisibilityUpdate(level: VisibilityLevel.public),
          );
      if (!allowGuests) return meeting;
      return await meetings.updateMeetingV1MeetingsMeetingIdPatch(
        meetingId: meeting.id,
        body: const MeetingUpdate(allowGuests: true),
      );
    } catch (_) {
      await meetings
          .deleteMeetingV1MeetingsMeetingIdDelete(meetingId: meeting.id)
          .then<void>((_) {}, onError: (_) {});
      rethrow;
    }
  }
}

final createMeetingMutation = Mutation<MeetingRead>(label: 'createMeeting');

/// 모임 화면의 값과 내 가능 시간의 저장 상태
@immutable
class MeetingBoardState {
  const MeetingBoardState(this.board, {this.status = MeetingSaveStatus.idle});

  final MeetingBoard board;
  final MeetingSaveStatus status;

  MeetingBoardState copyWith({
    MeetingBoard? board,
    MeetingSaveStatus? status,
  }) => MeetingBoardState(board ?? this.board, status: status ?? this.status);
}

/// 모임 화면: 미팅과 모든 참여자의 가능 시간(GET), 내 가능 시간 칠하기와 저장.
///
/// 칠하면 잠시 뒤 `PUT /availability`로 저장한다([MeetingAutosave]). 아직 참여하지 않았으면 저장 전에
/// 계정 이름으로 참여한다. 저장한 뒤에는 가능 시간을 다시 받아 다른 참여자의 변경도 반영한다.
/// 저장하지 못한 것이 있는 동안에는 화면을 떠나도 값을 버리지 않고, 기다리던 저장은 그대로 보낸다.
///
/// 테스트: test/features/meeting/presentation/providers/meeting_board_provider_test.dart
@riverpod
class MeetingBoardNotifier extends _$MeetingBoardNotifier {
  late MeetingAutosave _autosave;
  KeepAliveLink? _hold;

  @override
  Future<MeetingBoardState> build(String meetingId) async {
    final autosave = _autosave = MeetingAutosave(
      save: _save,
      onStatus: _setStatus,
    );
    ref.onDispose(() {
      autosave.dispose();
      _hold?.close();
      _hold = null;
    });
    final (userId, name) = ref.watch(
      currentUserProvider.select((user) => (user?.id, user?.name)),
    );
    final meeting = await ref.watch(meetingProvider(meetingId).future);
    final availability = await ref
        .read(meetingsApiProvider)
        .getAvailabilityV1MeetingsMeetingIdAvailabilityGet(
          meetingId: meetingId,
        );
    return MeetingBoardState(
      MeetingBoard(
        meeting: meeting,
        availability: availability,
        userId: userId,
        selfName: meetingDisplayName(name),
      ),
    );
  }

  /// [cells]를 칠하거나([available]) 지우고 저장을 맡긴다
  void paint(List<MeetingCell> cells, {required bool available}) {
    if (cells.isEmpty || state.value == null) return;
    _updateBoard(
      (board) => board.withMine(
        board.mine.paint([
          for (final cell in cells) cell.span,
        ], available: available),
      ),
    );
    _hold ??= ref.keepAlive();
    _autosave.changed();
  }

  /// 저장하지 못한 내 가능 시간을 바로 다시 보낸다
  void retrySave() => _autosave.retry();

  /// 이 모임에서 내 이름을 [name]으로 바꾼다. 참여 요청을 새 이름으로 다시 보내면 backend가 이름만 바꾼다
  Future<void> rename(String name) async {
    final participant = await ref
        .read(meetingsApiProvider)
        .createParticipantV1MeetingsMeetingIdParticipatePost(
          meetingId: meetingId,
          body: ParticipantCreate(displayName: name.trim()),
        );
    if (ref.mounted) _updateBoard((board) => board.withSelf(participant));
  }

  Future<void> _save() async {
    final api = ref.read(meetingsApiProvider);
    var me = state.requireValue.board.me;
    if (me == null) {
      final joined = me = await api
          .createParticipantV1MeetingsMeetingIdParticipatePost(
            meetingId: meetingId,
            body: ParticipantCreate(
              displayName: state.requireValue.board.selfName,
            ),
          );
      _updateBoard((board) => board.withSelf(joined));
    }
    await api.setAvailabilityV1MeetingsMeetingIdAvailabilityPut(
      meetingId: meetingId,
      participantId: me.id,
      body: [
        for (final slot in state.requireValue.board.mine.slots)
          TimeSlotCreate(startTime: slot.start, endTime: slot.end),
      ],
    );
    unawaited(_refresh());
  }

  /// 가능 시간을 다시 받는다. 받지 못해도 저장은 끝났으므로 지금 값을 그대로 둔다
  Future<void> _refresh() async {
    try {
      final availability = await ref
          .read(meetingsApiProvider)
          .getAvailabilityV1MeetingsMeetingIdAvailabilityGet(
            meetingId: meetingId,
          );
      if (ref.mounted) {
        _updateBoard((board) => board.withAvailability(availability));
      }
    } on Exception {
      // 다른 참여자의 변경은 다음에 불러올 때 보인다
    }
  }

  void _setStatus(MeetingSaveStatus status) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(status: status));
    if (status == MeetingSaveStatus.saved && !_autosave.busy) {
      _hold?.close();
      _hold = null;
    }
  }

  void _updateBoard(MeetingBoard Function(MeetingBoard board) change) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(board: change(current.board)));
  }
}

/// 이 모임에서 내 이름 바꾸기
final renameInMeetingMutation = Mutation<void>(label: 'renameInMeeting');
