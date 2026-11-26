import 'dart:math' as math;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/config/legal_links.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 시트 아래 여백
const _sheetBottomPadding = 16.0;

/// 로그인하지 않은 사람이 모임을 만들려 할 때 까닭과 함께 로그인을 묻는다. [wide]면 대화상자, 아니면 하단 시트다.
/// '로그인하고 계속하기'를 고르면 true, 닫으면 false.
///
/// 안심 문구 아래에 개인정보 보호 조치 안내 링크를 두고, 누르면 묻기를 닫지 않고 새 탭으로 연다. 링크를 더하면
/// 시트를 굴려야 하거나 대화상자가 넘치는 크기에서는 링크를 빼고 그린다([_LinkIfRoom]).
Future<bool> askLoginToCreateMeeting(
  BuildContext context, {
  required bool wide,
}) async {
  final openLink = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(openLinkProvider);
  final link = Padding(
    padding: const EdgeInsets.only(top: 8),
    child: AppTextLink(
      label: '내 정보는 어떻게 지키나요?',
      onPressed: () => openLink(LegalLinks.trust),
    ),
  );
  final reason = '${Terms.meeting.withJosa('을', '를')} 만들고 나중에 고치려면 로그인이 필요해요';
  const reassurance = '입력한 내용은 그대로 남아요';
  const login = '로그인하고 계속하기';
  if (wide) {
    final chosen = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog(
        title: Text(reason),
        content: _LinkIfRoom(above: const Text(reassurance), link: link),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(login),
          ),
        ],
      ),
    );
    return chosen ?? false;
  }
  final chosen = await showAppSheet<bool>(
    context,
    animationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            // 낮은 화면·큰 글자에서는 시트 안에서 굴린다
            padding: const EdgeInsets.fromLTRB(24, 0, 24, _sheetBottomPadding),
            child: _LinkIfRoom(
              room: constraints.maxHeight - _sheetBottomPadding,
              above: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reason,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reassurance,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              link: link,
              below: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text(login),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  return chosen ?? false;
}

/// [above], [link], [below]를 위에서부터 쌓는다. 셋이 [room]과 받은 높이 안에 다 들어가지 않으면 [link]를 빼고
/// [above]와 [below]만 그린다. [above]·[below]는 폭을 다 쓰고, [link]는 앞쪽 끝에 둔다.
///
/// 굴림 영역 안에서는 받은 높이에 끝이 없으므로 보이는 높이를 [room]으로 받는다.
class _LinkIfRoom extends MultiChildRenderObjectWidget {
  _LinkIfRoom({
    required Widget above,
    required Widget link,
    Widget below = const SizedBox.shrink(),
    this.room = double.infinity,
  }) : super(children: [above, link, below]);

  final double room;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLinkIfRoom(room, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLinkIfRoom renderObject,
  ) {
    renderObject
      ..room = room
      ..textDirection = Directionality.of(context);
  }
}

class _LinkIfRoomParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderLinkIfRoom extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _LinkIfRoomParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _LinkIfRoomParentData> {
  _RenderLinkIfRoom(this._room, this._textDirection);

  double _room;
  set room(double value) {
    if (value == _room) return;
    _room = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  bool _showLink = false;

  RenderBox get _above => firstChild!;
  RenderBox get _link => childAfter(_above)!;
  RenderBox get _below => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _LinkIfRoomParentData) {
      child.parentData = _LinkIfRoomParentData();
    }
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final full = BoxConstraints.tightFor(width: width);
    _above.layout(full, parentUsesSize: true);
    _below.layout(full, parentUsesSize: true);
    _link.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
    final base = _above.size.height + _below.size.height;
    final withLink = base + _link.size.height;
    _showLink =
        withLink <=
        math.min(_room, constraints.maxHeight) + precisionErrorTolerance;
    final linkHeight = _showLink ? _link.size.height : 0.0;
    _offsetOf(_above, Offset.zero);
    _offsetOf(
      _link,
      Offset(
        _textDirection == TextDirection.rtl ? width - _link.size.width : 0,
        _above.size.height,
      ),
    );
    _offsetOf(_below, Offset(0, _above.size.height + linkHeight));
    size = constraints.constrain(Size(width, base + linkHeight));
  }

  void _offsetOf(RenderBox child, Offset offset) =>
      (child.parentData! as _LinkIfRoomParentData).offset = offset;

  @override
  double computeMinIntrinsicWidth(double height) => [
    for (final child in getChildrenAsList()) child.getMinIntrinsicWidth(height),
  ].reduce(math.max);

  @override
  double computeMaxIntrinsicWidth(double height) => [
    for (final child in getChildrenAsList()) child.getMaxIntrinsicWidth(height),
  ].reduce(math.max);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _above.getMinIntrinsicHeight(width) + _below.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _above.getMaxIntrinsicHeight(width) + _below.getMaxIntrinsicHeight(width);

  @override
  bool paintsChild(RenderBox child) => child != _link || _showLink;

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in getChildrenAsList()) {
      if (paintsChild(child)) {
        final childOffset = (child.parentData! as _LinkIfRoomParentData).offset;
        context.paintChild(child, offset + childOffset);
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in getChildrenAsList().reversed) {
      if (!paintsChild(child)) continue;
      final childOffset = (child.parentData! as _LinkIfRoomParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: childOffset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (final child in getChildrenAsList()) {
      if (paintsChild(child)) visitor(child);
    }
  }
}
