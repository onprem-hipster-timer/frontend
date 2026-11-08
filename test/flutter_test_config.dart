import 'dart:async';

import 'package:layout_audit/layout_audit.dart';

/// 모든 위젯 테스트가 끝나면 화면에 남은 글자·이미지의 겹침·넘침·잘림을 점검해 보고한다.
/// 명시 모드(`*_layout_test.dart`)는 스스로 보고하므로 겹치지 않게 뺀다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LayoutAuditBinding.ensureInitialized(
    config: LayoutAuditConfig(skipTests: RegExp(r'겹침·넘침·잘림을 보고한다')),
  );
  await testMain();
}
