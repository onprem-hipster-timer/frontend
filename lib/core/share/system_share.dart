// 시스템 공유 창. 웹에서는 브라우저의 Web Share API를 쓰고, 그 밖에는 없다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/share/system_share_result.dart';
import 'package:momeet/core/share/system_share_stub.dart'
    if (dart.library.js_interop) 'package:momeet/core/share/system_share_web.dart';

export 'package:momeet/core/share/system_share_result.dart';

/// [title]과 [url]을 시스템 공유 창으로 보낸다
typedef SystemShare =
    Future<SystemShareResult> Function({
      required String title,
      required String url,
    });

/// 시스템 공유 창. 테스트는 바꿔 끼운다
final systemShareProvider = Provider<SystemShare>((ref) => shareWithSystem);
