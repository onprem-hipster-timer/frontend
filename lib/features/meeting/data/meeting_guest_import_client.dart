import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/dio_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 게스트의 시간을 회원 참여자로 옮기는 요청(`POST /v1/meetings/{meeting_id}/guest-import`). 생성된 클라이언트와
/// 같은 Dio(baseUrl, 회원 JWT)로 보낸다.
class MeetingGuestImportClient {
  const MeetingGuestImportClient(this._dio);

  final Dio _dio;

  /// 모임 [meetingId]의 게스트(JWT [guestToken])를 지금 회원의 참여자로 옮긴다. 회원의 참여자와 합친 시간을
  /// 돌려주고, 서버는 그 게스트를 지운다. 거절(401·403·404·422)과 연결 오류는 [DioException]으로 던진다
  Future<AvailabilityRead> importGuest({
    required String meetingId,
    required String guestToken,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/v1/meetings/$meetingId/guest-import',
      data: {'guest_token': guestToken},
    );
    return AvailabilityRead.fromJson(response.data!);
  }
}

final meetingGuestImportApiProvider = Provider<MeetingGuestImportClient>(
  (ref) => MeetingGuestImportClient(ref.watch(dioClientProvider)),
);
