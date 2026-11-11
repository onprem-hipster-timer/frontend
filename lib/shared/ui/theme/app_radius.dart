import 'package:material_ui/material_ui.dart';

/// 모서리 반지름 토큰.
abstract final class AppRadius {
  /// 시트 손잡이 같은 가는 막대
  static const double xs = 2;

  /// 작은 강조 상자, 선택 줄
  static const double sm = 4;

  /// 칩·작은 카드
  static const double md = 8;

  /// 입력 칸·버튼·카드
  static const double lg = 12;

  /// 큰 카드·섹션
  static const double xl = 16;

  /// 하단 시트 윗모서리
  static const double sheet = 20;

  /// 알약 모양
  static const double pill = 999;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}
