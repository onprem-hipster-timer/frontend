import 'dart:async';

import 'package:dio/dio.dart' show DioException;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_headcount.dart';
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

/// 로그인하지 않은 방문자가 보는 모임: 결과(`GET /result`)의 칸마다 사람 수와 참여자 수. 공개 모임만 받는다
final meetingHeadcountProvider = FutureProvider.autoDispose
    .family<MeetingHeadcount, String>(
      (ref, meetingId) async => MeetingHeadcount(
        await ref
            .watch(meetingsApiProvider)
            .getMeetingResultV1MeetingsMeetingIdResultGet(meetingId: meetingId),
      ),
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
/// 칠하면 잠시 뒤 `PUT /availability`로 저장한다([MeetingAutosave]). 회원은 아직 참여하지 않았으면 저장 전에
/// 계정 이름으로 참여하고, 게스트는 처음 불러올 때 게스트 이름으로 참여한다(이미 참여했으면 그 참여자를
/// 돌려받는다). 저장한 뒤에는 가능 시간을 다시 받아 다른 참여자의 변경도 반영한다.
/// 저장하지 못한 것이 있는 동안에는 화면을 떠나도 값을 버리지 않고, 기다리던 저장은 그대로 보낸다.
///
/// 주인이 참여자를 빼면([remove]) 화면에서 바로 빼되 요청은 [confirmRemove]까지 미룬다. 게스트를 빼면
/// 그 게스트 계정이 지워지고 backend에는 되돌리기가 없어서다. 빼기를 기다리거나 보내는 동안에도 화면을
/// 떠나도 값을 버리지 않는다.
///
/// 테스트: test/features/meeting/presentation/providers/meeting_board_provider_test.dart
@riverpod
class MeetingBoardNotifier extends _$MeetingBoardNotifier {
  late MeetingAutosave _autosave;
  KeepAliveLink? _hold;

  /// 빼기를 기다리는(되돌릴 수 있는) 참여자 id
  final _pendingRemovals = <String>{};

  /// 보내는 중인 빼기 요청
  final _sendingRemovals = <String, Future<void>>{};

  @override
  Future<MeetingBoardState> build(String meetingId) async {
    final autosave = _autosave = MeetingAutosave(
      save: _save,
      onStatus: _setStatus,
    );
    ref.onDispose(() {
      autosave.dispose();
      _pendingRemovals.clear();
      _hold?.close();
      _hold = null;
    });
    final (userId, name) = ref.watch(
      currentUserProvider.select((user) => (user?.id, user?.name)),
    );
    final guestId = ref.watch(currentGuestProvider.select((g) => g?.id));
    final meeting = await ref.watch(meetingProvider(meetingId).future);
    final api = ref.read(meetingsApiProvider);
    final joined = guestId == null
        ? null
        : await api.createParticipantV1MeetingsMeetingIdParticipatePost(
            meetingId: meetingId,
            body: ParticipantCreate(
              displayName: meetingDisplayName(
                ref.read(currentGuestProvider)?.name,
              ),
            ),
          );
    final availability = await api
        .getAvailabilityV1MeetingsMeetingIdAvailabilityGet(
          meetingId: meetingId,
        );
    final board = MeetingBoard(
      meeting: meeting,
      availability: availability,
      userId: userId,
      selfId: joined?.id,
      selfName: meetingDisplayName(joined?.displayName ?? name),
    );
    return MeetingBoardState(
      joined == null || board.me != null ? board : board.withSelf(joined),
    );
  }

  /// 가능 시간을 다시 받는다(게스트가 이름을 바꾼 뒤 참여자 이름을 새로 보인다)
  Future<void> reload() => _refresh();

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

  /// [participantId] 참여자를 화면에서 바로 뺀다. 요청은 [confirmRemove]가 보내고 [undoRemove]는 되돌린다
  void remove(String participantId) {
    if (state.value == null) return;
    _pendingRemovals.add(participantId);
    _updateBoard(
      (board) => board.withRemoving({...board.removing, participantId}),
    );
    _hold ??= ref.keepAlive();
  }

  /// 기다리던 빼기를 되돌려 그 참여자를 다시 보인다
  void undoRemove(String participantId) {
    if (!_pendingRemovals.remove(participantId)) return;
    _showAgain(participantId);
    _releaseIfIdle();
  }

  /// 기다리던 빼기를 보낸다(`DELETE /participants/{id}`). 이미 보냈으면 그 요청을 기다린다.
  ///
  /// 이미 없는 참여자(404)면 뺀 것으로 본다. 그 밖에 실패하면 그 참여자를 다시 보이고 오류를 던진다.
  Future<void> confirmRemove(String participantId) {
    final sending = _sendingRemovals[participantId];
    if (sending != null) return sending;
    if (!_pendingRemovals.remove(participantId)) return Future.value();
    return _sendingRemovals[participantId] = _sendRemoval(participantId)
        .whenComplete(() {
          _sendingRemovals.remove(participantId);
          _releaseIfIdle();
        });
  }

  Future<void> _sendRemoval(String participantId) async {
    try {
      await ref
          .read(meetingsApiProvider)
          .removeParticipantV1MeetingsMeetingIdParticipantsParticipantIdDelete(
            meetingId: meetingId,
            participantId: participantId,
          );
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        if (ref.mounted) _showAgain(participantId);
        rethrow;
      }
    } catch (_) {
      if (ref.mounted) _showAgain(participantId);
      rethrow;
    }
    if (ref.mounted) unawaited(_refresh());
  }

  void _showAgain(String participantId) {
    if (state.value == null) return;
    _updateBoard(
      (board) => board.withRemoving({...board.removing}..remove(participantId)),
    );
  }

  /// 저장할 것도, 빼기를 기다리거나 보내는 것도 없으면 화면을 떠났을 때 값을 버리게 둔다
  void _releaseIfIdle() {
    if (_autosave.busy ||
        _pendingRemovals.isNotEmpty ||
        _sendingRemovals.isNotEmpty) {
      return;
    }
    _hold?.close();
    _hold = null;
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
    if (status == MeetingSaveStatus.saved) _releaseIfIdle();
  }

  void _updateBoard(MeetingBoard Function(MeetingBoard board) change) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(board: change(current.board)));
  }
}

/// 이 모임에서 내 이름 바꾸기
final renameInMeetingMutation = Mutation<void>(label: 'renameInMeeting');
