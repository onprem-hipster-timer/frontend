// 실행 환경(브라우저) 정보. 테스트에서 덮어쓸 수 있게 프로바이더로 둔다.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 웹에서 실행 중인지
final isWebProvider = Provider<bool>((ref) => kIsWeb);
