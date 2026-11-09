import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'format.dart';
import 'auditor.dart';
import 'finding.dart';
import 'overflow_recorder.dart';
import 'report.dart';

class LayoutAuditConfig {
  const LayoutAuditConfig({
    this.enabled = true,
    this.options = const LayoutAuditOptions(),
    this.skipTests,
    this.sink = const LayoutReportSink(),
    this.environment,
  });

  /// false면 아무것도 하지 않는다.
  final bool enabled;
  final LayoutAuditOptions options;

  /// 설명이 맞는 테스트는 감사하지 않는다.
  final RegExp? skipTests;
  final LayoutReportSink sink;

  /// null이면 [Platform.environment]. `LAYOUT_AUDIT`(`off`면 끔),
  /// `LAYOUT_AUDIT_TEXT_SCALE`(예 `2.0`), `LAYOUT_AUDIT_VIEWPORT`(예 `320x568`,
  /// `320x568@2.0`처럼 기기 픽셀 비율을 붙일 수 있다)를 읽는다.
  final Map<String, String>? environment;
}

/// 모든 `testWidgets`가 끝날 때 화면에 남은 트리를 감사해 보고한다. 테스트를 실패시키지 않는다.
///
/// `test/flutter_test_config.dart`의 `testExecutable`에서 [ensureInitialized]로 설치한다.
class LayoutAuditBinding extends AutomatedTestWidgetsFlutterBinding {
  LayoutAuditBinding._(this.config);

  final LayoutAuditConfig config;

  static LayoutAuditBinding get instance =>
      BindingBase.checkInstance(_instance);
  static LayoutAuditBinding? _instance;

  static LayoutAuditBinding ensureInitialized({
    LayoutAuditConfig config = const LayoutAuditConfig(),
  }) {
    if (_instance == null) {
      final existing = BindingBase.debugBindingType();
      if (existing != null) {
        throw StateError(
          '이미 $existing 바인딩이 설치되어 있어 LayoutAuditBinding으로 바꿀 수 없습니다. '
          'flutter_test_config.dart에서 다른 바인딩보다 먼저 설치하세요.',
        );
      }
      _instance = LayoutAuditBinding._(config);
    }
    return _instance!;
  }

  static bool isDisabled(Map<String, String> env) =>
      env['LAYOUT_AUDIT'] == 'off';

  /// 형식이 틀리거나 0 이하인 값은 null.
  static ({Size? logicalSize, double? dpr, double? textScale})
      parseMatrixEnvironment(Map<String, String> env) {
    Size? logicalSize;
    double? dpr;
    final viewport =
        RegExp(r'^(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)(?:@(\d+(?:\.\d+)?))?$')
            .firstMatch(env['LAYOUT_AUDIT_VIEWPORT'] ?? '');
    if (viewport != null) {
      final width = double.parse(viewport[1]!);
      final height = double.parse(viewport[2]!);
      final ratio = viewport[3] == null ? null : double.parse(viewport[3]!);
      if (width > 0 && height > 0 && (ratio == null || ratio > 0)) {
        logicalSize = Size(width, height);
        dpr = ratio;
      }
    }
    final scale = double.tryParse(env['LAYOUT_AUDIT_TEXT_SCALE'] ?? '');
    return (
      logicalSize: logicalSize,
      dpr: dpr,
      textScale: scale != null && scale > 0 ? scale : null,
    );
  }

  Map<String, String> get _env => config.environment ?? Platform.environment;

  LayoutReport? _pending;
  bool _skipCurrent = false;

  /// 지금 테스트는 이미 명시 모드로 보고했으니 끝날 때 다시 감사하지 않는다.
  void skipAutoAudit() => _skipCurrent = true;
  bool _matrixApplied = false;

  @override
  Future<void> runTest(
    Future<void> Function() testBody,
    VoidCallback invariantTester, {
    String description = '',
  }) {
    _pending = null;
    _skipCurrent = false;
    final active = config.enabled &&
        !isDisabled(_env) &&
        !(config.skipTests?.hasMatch(description) ?? false);
    if (!active) {
      return super.runTest(testBody, invariantTester, description: description);
    }
    _applyMatrix();
    // 상위 runTest는 body가 끝나면 곧바로 트리를 비우므로 감사는 body 안에서 한다.
    return super.runTest(
      () async {
        final overflows = await recordLayoutOverflows(testBody, forward: true);
        _pending = _skipCurrent ? null : _audit(description, overflows);
      },
      invariantTester,
      description: description,
    );
  }

  // 출력은 fake async 밖인 postTest에서 해 테스트 쪽에 타이머를 남기지 않는다.
  @override
  void postTest() {
    final report = _pending;
    _pending = null;
    try {
      if (report != null) {
        emitLayoutReport(report, strict: false, sink: config.sink);
      }
    } on Object catch (error) {
      _reportFailure(report!.name, report.caseLabel, error);
    } finally {
      if (_matrixApplied) {
        _matrixApplied = false;
        platformDispatcher.clearTextScaleFactorTestValue();
        platformDispatcher.implicitView?.reset();
      }
      super.postTest();
    }
  }

  void _applyMatrix() {
    final matrix = parseMatrixEnvironment(_env);
    final view = platformDispatcher.implicitView;
    if (matrix.logicalSize != null && view != null) {
      final dpr = matrix.dpr ?? view.devicePixelRatio;
      view.devicePixelRatio = dpr;
      view.physicalSize = matrix.logicalSize! * dpr;
      _matrixApplied = true;
    }
    if (matrix.textScale != null) {
      platformDispatcher.textScaleFactorTestValue = matrix.textScale!;
      _matrixApplied = true;
    }
  }

  LayoutReport? _audit(String description, List<LayoutFinding> overflows) {
    final name = slugify(description);
    var caseLabel = '';
    try {
      final views = renderViews.where((v) => v.child != null);
      if (views.isEmpty) {
        return null;
      }
      final renderView = views.first;
      final view = renderView.flutterView;
      final logical = view.physicalSize / view.devicePixelRatio;
      caseLabel =
          '${formatCompact(logical.width)}x${formatCompact(logical.height)}'
          '@${formatCompact(view.devicePixelRatio)}, '
          '글자 ${formatCompact(platformDispatcher.textScaleFactor)}배';
      return LayoutReport(
        name: name,
        caseLabel: caseLabel,
        viewSize: logical,
        findings: [
          ...overflows,
          ...auditRenderTree(
            [renderView],
            viewRect: Offset.zero & logical,
            hitTest: (position) {
              final result = HitTestResult();
              hitTestInView(result, position, view.viewId);
              return result;
            },
            options: config.options,
          ),
        ],
      );
    } on Object catch (error) {
      return LayoutReport(
        name: name,
        caseLabel: caseLabel,
        findings: [LayoutFinding.auditFailed(error)],
      );
    }
  }

  void _reportFailure(String name, String caseLabel, Object error) {
    try {
      final report = LayoutReport(
        name: name,
        caseLabel: caseLabel,
        findings: [LayoutFinding.auditFailed(error)],
      );
      config.sink.onReport?.call(report);
      (config.sink.writeLine ?? debugPrint)(report.describe());
    } on Object {
      // 보고 대상까지 실패하면 더 알릴 곳이 없다.
    }
  }
}
