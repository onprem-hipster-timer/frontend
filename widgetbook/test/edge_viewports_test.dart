import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet_widgetbook/edge_viewports.dart';
import 'package:momeet_widgetbook/main.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  test('유난한 비율의 뷰포트는 레이아웃 점검의 화면과 크기·화소 배율이 같다', () {
    const audited = [
      TestViewports.iphoneSe1,
      TestViewports.zFlipMain,
      TestViewports.zFlipCover,
      TestViewports.zFoldInner,
      TestViewports.duoSingle,
      TestViewports.duoSpanned,
      TestViewports.phoneSmallLandscape,
      TestViewports.ultraWide21x9,
    ];

    expect(
      [for (final v in edgeViewports) (v.size, v.pixelRatio)],
      [for (final v in audited) (v.logicalSize, v.devicePixelRatio)],
    );
  });

  test('카탈로그의 뷰포트 고르기에 유난한 비율의 뷰포트가 모두 있다', () {
    final addon = widgetbookAddons.whereType<ViewportAddon>().single;

    expect(addon.viewports, containsAll(edgeViewports));
  });
}
