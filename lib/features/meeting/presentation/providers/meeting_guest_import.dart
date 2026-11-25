import 'dart:async';

import 'package:dio/dio.dart' show DioException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/analytics/usage_analytics.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/kept_guest_session_store.dart';
import 'package:momeet/features/meeting/domain/meeting_guest_import_phase.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

export 'package:momeet/features/meeting/domain/meeting_guest_import_phase.dart';

part 'meeting_guest_import.g.dart';

/// 회원이 모임 [meetingId]를 열었을 때 그 모임에 따로 둔 게스트 세션([KeptGuestSessionStore])이 있으면 한 번
/// 저절로 게스트 시간을 회원 계정으로 옮긴다(`guest-import`). 게스트 JWT는 따로 둔 세션으로 새로 받는다.
///
/// - 옮기면 받은 내 참여자로 화면을 바꾸고, 따로 둔 세션을 끝내고 지운다.
/// - 게스트가 없다(404 `GuestNotFoundError`, 또는 게스트 JWT를 받지 못함)면 가능 시간을 다시 읽어 내 시간이
///   있으면 옮긴 것으로 본다(앞선 요청이 옮겼는데 응답을 잃은 경우). 없으면 따로 둔 세션을 지우고, 그것이 첫
///   시도였을 때만 찾지 못했다고 한다.
/// - 게스트 JWT가 거절되면(422 `GuestTokenInvalidError`) 한 번 새로 받아 다시 보낸다.
/// - 그 밖(연결 문제, 5xx, 겹침 409, 모임을 볼 수 없음 등)이면 따로 둔 세션은 두고 [_retryDelays]만큼 기다리며
///   몇 번 더 해 본 뒤 멈춘다([retry]는 누를 때마다 한 번이다). 약관 동의 등으로 떠났다 돌아오면 다시 한다.
///
/// 테스트: test/features/meeting/presentation/pages/meeting_guest_import_test.dart
@riverpod
class MeetingGuestImport extends _$MeetingGuestImport {
  /// 저절로 다시 하기 전에 기다리는 시간(처음 시도 뒤 차례로)
  static const _retryDelays = [Duration(seconds: 1), Duration(seconds: 2)];

  /// 앞선 시도가 끝을 모르게 끝났다(그 요청이 서버에서 옮겼을 수 있다)
  var _lostBefore = false;
  var _running = false;

  @override
  Future<MeetingGuestImportPhase> build(String meetingId) async {
    final kept = await ref.read(keptGuestSessionStoreProvider).read(meetingId);
    if (kept == null) return MeetingGuestImportPhase.none;
    unawaited(Future.microtask(() => _run(_retryDelays)));
    return MeetingGuestImportPhase.importing;
  }

  /// 옮기지 못한 뒤 다시 한 번 해 본다
  Future<void> retry() async {
    if (_running || state.value != MeetingGuestImportPhase.failed) return;
    state = const AsyncData(MeetingGuestImportPhase.importing);
    await _run(const []);
  }

  /// 한 번 해 보고, 끝을 모르면 [delays]마다 기다렸다 다시 한다
  Future<void> _run(List<Duration> delays) async {
    _running = true;
    try {
      for (var i = 0; i <= delays.length; i++) {
        if (i > 0) await Future<void>.delayed(delays[i - 1]);
        if (!ref.mounted) return;
        final outcome = await _attempt();
        if (!ref.mounted) return;
        if (outcome != null) {
          state = AsyncData(outcome);
          return;
        }
        _lostBefore = true;
      }
      state = const AsyncData(MeetingGuestImportPhase.failed);
    } finally {
      _running = false;
    }
  }

  /// 한 번 옮겨 본다(게스트 JWT가 거절되면 한 번 새로 받아). 결과가 정해지면 그 단계, 아니면 null
  Future<MeetingGuestImportPhase?> _attempt() async {
    final auth = ref.read(authProvider.notifier);
    try {
      // 받은 내 참여자를 불러온 화면에 넣는다
      await ref.read(meetingBoardProvider(meetingId).future);
      for (var minted = 0; ; minted++) {
        final token = await auth.keptGuestAccessToken(meetingId);
        if (token == null) return await _gone();
        try {
          final mine = await ref
              .read(meetingsApiProvider)
              .importGuestV1MeetingsMeetingIdGuestImportPost(
                meetingId: meetingId,
                body: GuestImport(guestToken: token),
              );
          ref
              .read(meetingBoardProvider(meetingId).notifier)
              .applyImported(mine);
          return await _moved();
        } on DioException catch (error) {
          final response = error.response;
          final data = response?.data;
          final type = data is Map ? data['error_type'] : null;
          if (response?.statusCode == 404 && type == 'GuestNotFoundError') {
            return await _gone();
          }
          if (response?.statusCode == 422 &&
              type == 'GuestTokenInvalidError' &&
              minted == 0) {
            continue;
          }
          if (response?.statusCode == 422 && type == 'GuestTokenInvalidError') {
            return await _gone();
          }
          return null;
        }
      }
    } on Exception {
      return null;
    }
  }

  /// 게스트가 없다. 내 시간이 있으면 옮긴 것, 없으면 따로 둔 세션을 지운다(첫 시도면 찾지 못한 것)
  Future<MeetingGuestImportPhase?> _gone() async {
    final List<AvailabilityRead> availability;
    try {
      availability = await ref
          .read(meetingsApiProvider)
          .getAvailabilityV1MeetingsMeetingIdAvailabilityGet(
            meetingId: meetingId,
          );
    } on Exception {
      return null;
    }
    final userId = ref.read(currentUserProvider)?.id;
    final mine = availability.any(
      (entry) =>
          userId != null &&
          entry.participant.userId == userId &&
          entry.timeSlots.isNotEmpty,
    );
    if (mine) {
      unawaited(ref.read(meetingBoardProvider(meetingId).notifier).reload());
      return _moved();
    }
    await ref.read(authProvider.notifier).dropKeptGuest(meetingId);
    return _lostBefore
        ? MeetingGuestImportPhase.none
        : MeetingGuestImportPhase.notFound;
  }

  Future<MeetingGuestImportPhase> _moved() async {
    await ref
        .read(authProvider.notifier)
        .dropKeptGuest(meetingId, endSession: true);
    ref.read(usageAnalyticsProvider).event(UsageEvent.meetingGuestConverted);
    return MeetingGuestImportPhase.moved;
  }
}

/// 이 기기에 모임 [meetingId]의 게스트 세션을 따로 두었는지('게스트로 계속하기')
final keptGuestSessionExistsProvider = FutureProvider.autoDispose
    .family<bool, String>(
      (ref, meetingId) async =>
          await ref.read(keptGuestSessionStoreProvider).read(meetingId) != null,
    );
