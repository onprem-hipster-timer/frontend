import 'package:momeet/core/share/system_share_result.dart';

/// 웹이 아니면 공유 창이 없다
Future<SystemShareResult> shareWithSystem({
  required String title,
  required String url,
}) async => SystemShareResult.unavailable;
