import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/widgets/deferred_widget.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

enum _Load { loading, failed, done }

@widgetbook.UseCase(name: '화면 여는 중 표시', type: DeferredWidget, path: '[공통]/화면 틀')
Widget deferredWidget(BuildContext context) {
  final load = context.knobs.object.dropdown(
    label: '상태',
    description: '웹에서 탭 화면을 처음 열 때 그 화면 코드를 받는 동안·받지 못했을 때·받은 뒤',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.loading => '받는 중',
      _Load.failed => '받지 못함',
      _Load.done => '다 받음',
    },
  );
  // 받기는 처음 한 번만 하므로 상태를 바꾸면 새로 만든다
  return DeferredWidget(
    key: ValueKey(load),
    loader: () => switch (load) {
      _Load.loading => Completer<void>().future,
      _Load.failed => Future<void>.error(Exception('불러오기 실패')),
      _Load.done => Future<void>.value(),
    },
    builder: (context) => Scaffold(
      appBar: AppBar(title: const Text('태그')),
      body: AppEmptyState(
        icon: Icons.label_outline,
        title: '아직 태그가 없습니다',
        message: '태그 그룹을 만들어 태그를 정리해보세요',
        actionLabel: '첫 태그 그룹 만들기',
        onAction: () {},
      ),
    ),
  );
}
