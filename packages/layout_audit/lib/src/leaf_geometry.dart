import 'package:flutter/rendering.dart';

/// 화면에 실제로 그려지는 텍스트·이미지 render object 하나와 그 전역 기하.
class ContentLeaf {
  const ContentLeaf({
    required this.box,
    required this.rawBoxes,
    required this.visibleBoxes,
    required this.clipRect,
    required this.contentClipRect,
    required this.hasClipAncestor,
    required this.ancestors,
    required this.text,
  });

  final RenderBox box;

  /// 글자 줄마다 하나(이미지는 하나)인 전역 사각형. 클립 전.
  final List<Rect> rawBoxes;

  /// [rawBoxes]를 조상 클립과 화면으로 자른 것.
  final List<Rect> visibleBoxes;

  /// 모든 조상 클립의 교집합.
  final Rect? clipRect;

  /// 스크롤 뷰포트를 뺀 조상 클립의 교집합. 스크롤로 가려진 부분은 잘라냄이 아니다.
  final Rect? contentClipRect;

  final bool hasClipAncestor;

  /// 부모부터 루트까지.
  final List<RenderObject> ancestors;

  /// 이미지는 빈 문자열.
  final String text;

  Rect get bounds => visibleBoxes.reduce((a, b) => a.expandToInclude(b));

  double get visibleArea =>
      visibleBoxes.fold(0, (sum, rect) => sum + rect.width * rect.height);
}

List<ContentLeaf> collectContentLeaves(
  Iterable<RenderObject> roots,
  Rect viewRect,
) {
  final leaves = <ContentLeaf>[];
  void visit(RenderObject object) {
    if (object is RenderParagraph || object is RenderImage) {
      final leaf = _leafOf(object as RenderBox, viewRect);
      if (leaf != null) {
        leaves.add(leaf);
      }
    }
    object.visitChildren(visit);
  }

  for (final root in roots) {
    visit(root);
  }
  return leaves;
}

ContentLeaf? _leafOf(RenderBox box, Rect viewRect) {
  if (!box.attached || !box.hasSize || box.debugNeedsLayout) {
    return null;
  }
  final ancestors = <RenderObject>[];
  Rect? clipRect;
  Rect? contentClipRect;
  RenderObject child = box;
  var parent = box.parent;
  while (parent != null) {
    if (!parent.paintsChild(child)) {
      return null;
    }
    if (parent is RenderIndexedStack && !_isShownChild(parent, child)) {
      return null;
    }
    final localClip = parent.describeApproximatePaintClip(child);
    if (localClip != null) {
      final clip = MatrixUtils.transformRect(
        parent.getTransformTo(null),
        localClip,
      );
      clipRect = clipRect?.intersect(clip) ?? clip;
      // SingleChildScrollView의 뷰포트는 RenderViewportBase가 아니라 인터페이스로 가른다.
      if (parent is! RenderAbstractViewport) {
        contentClipRect = contentClipRect?.intersect(clip) ?? clip;
      }
    }
    ancestors.add(parent);
    child = parent;
    parent = parent.parent;
  }

  final transform = box.getTransformTo(null);
  final rawBoxes = [
    for (final rect in _localBoxes(box))
      MatrixUtils.transformRect(transform, rect),
  ];
  final visibleBoxes = <Rect>[];
  for (final raw in rawBoxes) {
    var visible = raw.intersect(viewRect);
    if (clipRect != null) {
      visible = visible.intersect(clipRect);
    }
    if (visible.width > 1 && visible.height > 1) {
      visibleBoxes.add(visible);
    }
  }
  if (visibleBoxes.isEmpty) {
    return null;
  }
  return ContentLeaf(
    box: box,
    rawBoxes: rawBoxes,
    visibleBoxes: visibleBoxes,
    clipRect: clipRect,
    contentClipRect: contentClipRect,
    hasClipAncestor: clipRect != null,
    ancestors: ancestors,
    text: box is RenderParagraph ? _plainText(box) : '',
  );
}

bool _isShownChild(RenderIndexedStack stack, RenderObject child) {
  final index = stack.index;
  if (index == null) {
    return false;
  }
  var shown = stack.firstChild;
  for (var i = 0; i < index && shown != null; i++) {
    shown = stack.childAfter(shown);
  }
  return identical(shown, child);
}

String _plainText(RenderParagraph paragraph) => paragraph.text.toPlainText(
      includeSemanticsLabels: false,
      includePlaceholders: true,
    );

/// 문단 상자가 아니라 글자가 놓인 줄마다 사각형 하나. 줄 옆 빈 공간과 줄 끝 공백은
/// 그려지는 것이 없으므로 겹침·잘라냄으로 보지 않는다.
List<Rect> _localBoxes(RenderBox box) {
  if (box is! RenderParagraph) {
    return [box.paintBounds];
  }
  final textBoxes = [
    for (final run in RegExp(r'\S+').allMatches(_plainText(box)))
      ...box.getBoxesForSelection(
        TextSelection(baseOffset: run.start, extentOffset: run.end),
      ),
  ];
  final lines = <Rect>[];
  for (final textBox in textBoxes) {
    final rect = textBox.toRect();
    final index = lines.indexWhere(
      (line) => line.top == rect.top && line.bottom == rect.bottom,
    );
    if (index < 0) {
      lines.add(rect);
    } else {
      lines[index] = lines[index].expandToInclude(rect);
    }
  }
  return lines.isEmpty ? [box.paintBounds] : lines;
}
