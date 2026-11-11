import 'dart:async';

import 'package:layout_audit/layout_audit.dart';

import 'recorded_reports.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LayoutAuditBinding.ensureInitialized(
    config: LayoutAuditConfig(
      environment: const {},
      policy: testPolicy,
      // 파일·콘솔 없이 메모리에만 남긴다.
      sink: LayoutReportSink(
        environment: const {},
        writeLine: (_) {},
        onReport: recordedReports.add,
      ),
      skipTests: RegExp('자동 감사 제외'),
    ),
  );
  await testMain();
}
