import 'dart:async';

import 'package:layout_audit/layout_audit.dart';

import 'helpers/layout_audit_policy.dart';

/// 모든 위젯 테스트가 끝나면 화면에 남은 글자·이미지의 겹침·넘침·잘림을 점검해 보고한다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LayoutAuditBinding.ensureInitialized(
    config: LayoutAuditConfig(policy: appLayoutAuditPolicy),
  );
  await testMain();
}
