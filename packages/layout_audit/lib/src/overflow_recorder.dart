import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'format.dart';
import 'finding.dart';
import 'source_location.dart';

/// body 실행 중 RenderFlex 넘침·ListTile 폭 단언을 기록해 돌려준다.
///
/// [forward]가 true면 기록한 오류도 원래 핸들러에 넘겨 기존 테스트의 성패를 바꾸지 않는다.
/// 넘침이 아닌 오류는 언제나 원래 핸들러로 간다.
Future<List<LayoutFinding>> recordLayoutOverflows(
  Future<void> Function() body, {
  bool forward = false,
}) async {
  final findings = <LayoutFinding>[];
  var layoutAborted = false;
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final finding = _tryOverflowFinding(details);
    if (finding != null) {
      findings.add(finding);
      layoutAborted = layoutAborted || _abortsLayout(details);
    }
    // 레이아웃을 중단시킨 단언 뒤에는 크기 없는 상자 때문에 같은 원인의 오류가 이어진다.
    final consequence =
        finding == null && layoutAborted && _isLayoutConsequence(details);
    if ((finding == null && !consequence) || forward) {
      previous?.call(details);
    }
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return findings;
}

bool _abortsLayout(FlutterErrorDetails details) =>
    details.exceptionAsString().contains('consumes the entire tile width');

bool _isLayoutConsequence(FlutterErrorDetails details) {
  const libraries = {'rendering library', 'scheduler library', 'semantics'};
  final text = details.exceptionAsString();
  return libraries.contains(details.library) ||
      text.contains('was not laid out') ||
      text.contains('hasSize');
}

const _sides = {
  'right': '오른쪽',
  'bottom': '아래쪽',
  'left': '왼쪽',
  'top': '위쪽',
};

final _flexPattern = RegExp(
  r'A (\w+) overflowed by ([\d.]+) pixels on the (right|bottom|left|top)',
);

LayoutFinding? _tryOverflowFinding(FlutterErrorDetails details) {
  // 핸들러에서 던지면 원래 오류가 가려지므로 해석 실패는 넘침이 아닌 것으로 본다.
  try {
    return _overflowFinding(details);
  } catch (_) {
    return null;
  }
}

LayoutFinding? _overflowFinding(FlutterErrorDetails details) {
  final text = details.exceptionAsString();
  final isFlex = text.contains('overflowed by');
  final isListTile = text.contains('consumes the entire tile width');
  if (!isFlex && !isListTile) {
    return null;
  }
  final creator = _debugCreatorOf(details);
  final renderObject = creator?.element.renderObject;
  final location = renderObject == null ? null : sourceLocationOf(renderObject);
  final where = location?.toString() ?? '위치 불명';
  final flex = _flexPattern.firstMatch(text);
  final String body;
  if (isListTile) {
    body = 'ListTile의 위젯이 타일 폭을 전부 차지합니다';
  } else if (flex != null) {
    final widget = creator?.element.widget.runtimeType.toString() ?? flex[1]!;
    final pixels = formatPx(double.parse(flex[2]!));
    body = '$widget가 ${_sides[flex[3]]}으로 ${pixels}px 넘칩니다';
  } else {
    body = text.split('\n').first;
  }
  return LayoutFinding(
    kind: LayoutFindingKind.overflow,
    severity: LayoutSeverity.warning,
    message: '[넘침] $body ($where)',
    locations: [location],
  );
}

DebugCreator? _debugCreatorOf(FlutterErrorDetails details) {
  for (final node
      in details.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
    final value = node is DiagnosticsDebugCreator ? node.value : null;
    if (value is DebugCreator) {
      return value;
    }
  }
  return null;
}
