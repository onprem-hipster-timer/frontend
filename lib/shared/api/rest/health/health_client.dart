// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'health_client.g.dart';

@RestApi()
abstract class HealthClient {
  factory HealthClient(Dio dio, {String? baseUrl}) = _HealthClient;

  /// Health Check.
  ///
  /// 애플리케이션 상태 확인.
  ///
  /// 로드밸런서, Kubernetes, ECS 등에서 사용하는 health check 엔드포인트.
  /// 인증 없이 접근 가능합니다.
  @GET('/health')
  Future<void> healthCheckHealthGet({
    @DioOptions() RequestOptions? options,
  });
}
