import 'package:flutter/services.dart';
import 'package:momeet/shared/ui/theme/app_theme.dart';

/// 첫 화면 뒤에 불러오는 앱 글꼴의 굵기(500·600·700) 파일. pubspec.yaml의 assets에 있다. 굵기는 파일에 들어 있다
const appFontLateAssets = [
  'assets/fonts/Pretendard-Medium.subset.woff2',
  'assets/fonts/Pretendard-SemiBold.subset.woff2',
  'assets/fonts/Pretendard-Bold.subset.woff2',
];

/// 앱 글꼴의 나머지 굵기를 [AppTheme.fontFamily]로 등록한다. 첫 화면을 붙잡지 않도록 첫 프레임 뒤에 부른다.
/// 그전에는 그 굵기의 글자를 있는 글꼴로 그리고, 불러오지 못한 굵기는 그대로 둔다. [package]를 주면 그 패키지의
/// 파일과 패키지 이름을 붙인 글꼴 이름으로 등록한다(위젯 카탈로그)
///
/// 테스트: test/shared/ui/theme/app_theme_test.dart
Future<void> loadAppFontWeights({AssetBundle? bundle, String? package}) async {
  final prefix = package == null ? '' : 'packages/$package/';
  final assets = bundle ?? rootBundle;
  Future<void> load(String asset) async {
    try {
      await (FontLoader(
        '$prefix${AppTheme.fontFamily}',
      )..addFont(assets.load('$prefix$asset'))).load();
    } on Object {
      // 받지 못하거나 읽지 못한 굵기는 있는 글꼴로 계속 그린다
    }
  }

  await Future.wait([for (final asset in appFontLateAssets) load(asset)]);
}
