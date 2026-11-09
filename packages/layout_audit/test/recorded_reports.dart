import 'package:layout_audit/layout_audit.dart';

/// flutter_test_config.dart가 설치한 바인딩이 이 패키지 테스트마다 남긴 보고서.
final recordedReports = <LayoutReport>[];

/// true인 동안 자동 감사의 `ignore`가 던진다.
bool throwInIgnore = false;
