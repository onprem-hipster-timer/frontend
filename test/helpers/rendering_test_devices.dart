import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flutter 렌더링 테스트에서 사용할 화면 사양.
///
/// [logicalSize]는 Flutter 위젯이 보는 logical pixel 크기이고,
/// [physicalSize]는 테스트 뷰에 주입할 physical pixel 크기입니다.
class TestViewport {
  const TestViewport(this.name, this.logicalSize, {this.devicePixelRatio = 1});

  final String name;
  final Size logicalSize;
  final double devicePixelRatio;

  Size get physicalSize => Size(
    logicalSize.width * devicePixelRatio,
    logicalSize.height * devicePixelRatio,
  );

  double get aspectRatio => logicalSize.width / logicalSize.height;

  TestViewport rotated([String? rotatedName]) {
    return TestViewport(
      rotatedName ?? '$name-rotated',
      Size(logicalSize.height, logicalSize.width),
      devicePixelRatio: devicePixelRatio,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TestViewport &&
        other.name == name &&
        other.logicalSize == logicalSize &&
        other.devicePixelRatio == devicePixelRatio;
  }

  @override
  int get hashCode => Object.hash(name, logicalSize, devicePixelRatio);

  @override
  String toString() =>
      '$name ${logicalSize.width.toInt()}x${logicalSize.height.toInt()} @${devicePixelRatio}x';
}

/// 앱 전체 렌더링 테스트에서 공유하는 대표 화면 크기.
///
/// 새 위젯 렌더링 테스트는 보통 [renderSmoke]부터 쓰고, 레이아웃 리스크가
/// 큰 컴포넌트만 [phones], [tablets], [desktops] 중 필요한 세트를 추가합니다.
abstract final class TestViewports {
  // 실제 모바일 logical viewport에 가까운 값들.
  static const phoneSmall = TestViewport(
    'phone-small',
    Size(360, 800),
    devicePixelRatio: 3,
  );
  static const phoneStandard = TestViewport(
    'phone-standard',
    Size(390, 844),
    devicePixelRatio: 3,
  );
  static const phoneLarge = TestViewport(
    'phone-large',
    Size(430, 932),
    devicePixelRatio: 3,
  );
  static const androidLarge = TestViewport(
    'android-large',
    Size(412, 915),
    devicePixelRatio: 2.625,
  );

  // 태블릿 portrait/landscape 대표값.
  static const tabletPortrait = TestViewport(
    'tablet-portrait-4:3',
    Size(768, 1024),
    devicePixelRatio: 2,
  );
  static const tabletLandscape = TestViewport(
    'tablet-landscape-4:3',
    Size(1024, 768),
    devicePixelRatio: 2,
  );
  static const tabletLargeLandscape = TestViewport(
    'tablet-large-landscape-4:3',
    Size(1366, 1024),
    devicePixelRatio: 2,
  );

  // 데스크탑/모니터 대표 비율.
  static const desktop4x3 = TestViewport('desktop-4:3', Size(1024, 768));
  static const desktop16x10 = TestViewport('desktop-16:10', Size(1280, 800));
  static const desktopHd16x9 = TestViewport('desktop-hd-16:9', Size(1366, 768));
  static const desktopFhd16x9 = TestViewport(
    'desktop-fhd-16:9',
    Size(1920, 1080),
  );
  static const desktopQhd16x9 = TestViewport(
    'desktop-qhd-16:9',
    Size(2560, 1440),
  );
  static const ultraWide21x9 = TestViewport(
    'desktop-ultrawide-21:9',
    Size(2560, 1080),
  );

  static final phones = <TestViewport>{
    phoneSmall,
    phoneStandard,
    phoneLarge,
    androidLarge,
  };

  static final tablets = <TestViewport>{
    tabletPortrait,
    tabletLandscape,
    tabletLargeLandscape,
  };

  static final desktops = <TestViewport>{
    desktop4x3,
    desktop16x10,
    desktopHd16x9,
    desktopFhd16x9,
    desktopQhd16x9,
    ultraWide21x9,
  };

  static final commonRatios = <TestViewport>{
    desktop4x3,
    desktop16x10,
    desktopFhd16x9,
    ultraWide21x9,
  };

  static final renderSmoke = <TestViewport>{
    phoneSmall,
    phoneLarge,
    tabletPortrait,
    tabletLandscape,
    desktop4x3,
    desktop16x10,
    desktopFhd16x9,
    ultraWide21x9,
  };
}

abstract final class TestViewportVariants {
  static final phones = ValueVariant<TestViewport>(TestViewports.phones);
  static final tablets = ValueVariant<TestViewport>(TestViewports.tablets);
  static final desktops = ValueVariant<TestViewport>(TestViewports.desktops);
  static final commonRatios = ValueVariant<TestViewport>(
    TestViewports.commonRatios,
  );
  static final renderSmoke = ValueVariant<TestViewport>(
    TestViewports.renderSmoke,
  );
}

extension TestViewportWidgetTester on WidgetTester {
  void setTestViewport(TestViewport viewport) {
    view.devicePixelRatio = viewport.devicePixelRatio;
    view.physicalSize = viewport.physicalSize;
    addTearDown(view.reset);
  }

  Future<void> pumpStableFrames({
    int count = 2,
    Duration frame = const Duration(milliseconds: 16),
  }) async {
    for (var i = 0; i < count; i++) {
      await pump(frame);
    }
  }
}

void expectNoFlutterError(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}
