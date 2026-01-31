/// Riverpod provider setup
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/http_client_config.dart';

/// HTTP 클라이언트 프로바이더
final httpClientProvider = Provider<Dio>((ref) {
  return HttpClientConfig.createDioClient();
});
