import 'package:test/test.dart';
import 'package:momeet_api/momeet_api.dart';


/// tests for HealthApi
void main() {
  final instance = MomeetApi().getHealthApi();

  group(HealthApi, () {
    // Health Check
    //
    // 애플리케이션 상태 확인  로드밸런서, Kubernetes, ECS 등에서 사용하는 health check 엔드포인트. 인증 없이 접근 가능합니다.
    //
    //Future<JsonObject> healthCheckHealthGet() async
    test('test healthCheckHealthGet', () async {
      // TODO
    });

  });
}
