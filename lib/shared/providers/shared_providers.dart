// 공유 Riverpod 프로바이더
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/dio_provider.dart';
import 'package:momeet/shared/api/export.dart';

// MoMeet API 클라이언트 프로바이더
// API 기본 URL은 환경에 따라 설정해야 합니다
final moMeetClientProvider = Provider<MoMeetClient>((ref) {
  final dio = ref.watch(dioClientProvider);

  // TODO: 환경에 맞게 API 기본 URL 설정
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  return MoMeetClient(dio, baseUrl: baseUrl);
});
