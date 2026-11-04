// 실행 환경(브라우저) 정보와 동작. 테스트에서 덮어쓸 수 있게 프로바이더로 둔다.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 웹에서 실행 중인지
final isWebProvider = Provider<bool>((ref) => kIsWeb);

/// 웹 앱의 origin (예: https://app.example.com). 웹에서만 읽는다.
final appOriginProvider = Provider<String>((ref) => Uri.base.origin);

/// 현재 탭을 [url]로 이동시킨다 (소셜 로그인 제공자로 보낼 때)
final browserRedirectProvider = Provider<Future<void> Function(Uri url)>(
  (ref) =>
      (url) => launchUrl(url, webOnlyWindowName: '_self'),
);
