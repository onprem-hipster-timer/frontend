import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/dio_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// MoMeet API 루트 클라이언트
///
/// Dio의 baseUrl(`AppConfig.apiBaseUrl`)을 그대로 사용합니다.
/// 개별 sub-client는 [MoMeetClient]의 lazy getter를 통해 접근:
/// ```dart
/// final client = ref.watch(moMeetClientProvider);
/// client.schedules; // SchedulesClient
/// client.timers;    // TimersClient
/// ```
final moMeetClientProvider = Provider<MoMeetClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return MoMeetClient(dio);
});
