import 'package:momeet/shared/api/rest/export.dart';

/// 내 리소스 하나(일정·할 일·타이머)의 공유 설정을 읽고 바꾼다
abstract interface class ResourceVisibility {
  /// 지금 설정. 설정이 없으면(비공개) null
  Future<VisibilityRead?> load();

  /// [update]로 바꾼다(PUT)
  Future<void> save(VisibilityUpdate update);

  /// 설정을 지워 비공개로 되돌린다(DELETE)
  Future<void> clear();
}
