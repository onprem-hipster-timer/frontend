import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

@immutable
class SourceLocation {
  const SourceLocation(this.file, this.line, this.column);

  /// 현재 작업 디렉터리 기준 상대 경로. 예: `lib/foo.dart`.
  final String file;
  final int line;
  final int column;

  @override
  String toString() => '$file:$line';

  @override
  bool operator ==(Object other) =>
      other is SourceLocation &&
      other.file == file &&
      other.line == line &&
      other.column == column;

  @override
  int get hashCode => Object.hash(file, line, column);
}

class _Creator {
  const _Creator(this.location, [this.widget]);

  final SourceLocation? location;

  /// 위치를 구할 때 렌더 객체를 만든 위젯. 다시 그려 바뀌면 위치를 다시 구한다.
  final Widget? widget;
}

final Expando<_Creator> _cache = Expando<_Creator>('layout_audit creator');

/// [object]를 만든 위젯 사슬에서 가장 가까운 로컬(`lib/`, 없으면 `test/`) 생성 위치.
///
/// 위젯 생성 위치 추적(`flutter test` 기본값)이 꺼져 있으면 null.
SourceLocation? sourceLocationOf(RenderObject object) =>
    _creatorOf(object).location;

_Creator _creatorOf(RenderObject object) {
  final cached = _cache[object];
  final creator = object.debugCreator;
  if (cached != null &&
      (creator is! DebugCreator ||
          identical(cached.widget, creator.element.widget))) {
    return cached;
  }
  return _cache[object] = _resolveCreator(object);
}

_Creator _resolveCreator(RenderObject object) {
  final creator = object.debugCreator;
  if (creator is! DebugCreator) {
    return const _Creator(null);
  }
  // ignore: invalid_use_of_visible_for_testing_member
  final delegate = InspectorSerializationDelegate(
    service: WidgetInspectorService.instance,
  );
  final widget = creator.element.widget;
  SourceLocation? firstTest;
  for (final element in creator.element.debugGetDiagnosticChain()) {
    final location = _localLocation(element, delegate);
    if (location == null) {
      continue;
    }
    if (location.file.startsWith('lib/')) {
      return _Creator(location, widget);
    }
    if (firstTest == null && location.file.startsWith('test/')) {
      firstTest = location;
    }
  }
  return _Creator(firstTest, widget);
}

SourceLocation? _localLocation(
  Element element,
  DiagnosticsSerializationDelegate delegate,
) {
  final json = delegate.additionalNodeProperties(
    element.toDiagnosticsNode(),
  )['creationLocation'];
  if (json is! Map) {
    return null;
  }
  final file = json['file'];
  final line = json['line'];
  final column = json['column'];
  if (file is! String || line is! int || column is! int) {
    return null;
  }
  final path = Uri.parse(file).toFilePath();
  final cwd = Directory.current.path;
  if (!path.startsWith('$cwd/')) {
    return null;
  }
  final relative = path.substring(cwd.length + 1);
  // 이 패키지 자신의 위젯은 원인 위치가 아니다.
  final isOwnFile = path.contains('/packages/layout_audit/lib/') ||
      (cwd.endsWith('/layout_audit') && relative.startsWith('lib/'));
  return isOwnFile ? null : SourceLocation(relative, line, column);
}
