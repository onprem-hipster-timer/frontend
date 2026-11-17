// 실행 환경(브라우저) 정보와 동작. 테스트에서 덮어쓸 수 있게 프로바이더로 둔다.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 웹에서 실행 중인지
final isWebProvider = Provider<bool>((ref) => kIsWeb);

/// 웹 앱의 origin (예: https://app.example.com). 웹에서만 읽는다.
final appOriginProvider = Provider<String>((ref) => Uri.base.origin);

/// 지금 브라우저 주소의 앱 경로(해시 라우팅이라 `#` 뒤, 예: `/meetings/abc`). 웹이 아니면 null
final browserRouteProvider = Provider<String?>(
  (ref) => kIsWeb ? Uri.base.fragment : null,
);

/// 현재 탭을 [url]로 이동시킨다 (소셜 로그인 제공자로 보낼 때)
final browserRedirectProvider = Provider<Future<void> Function(Uri url)>(
  (ref) =>
      (url) => launchUrl(url, webOnlyWindowName: '_self'),
);

/// [url]을 새 탭(앱이면 외부 브라우저)으로 연다 (약관 보기)
final openLinkProvider = Provider<Future<void> Function(Uri url)>(
  (ref) =>
      (url) => launchUrl(url),
);
