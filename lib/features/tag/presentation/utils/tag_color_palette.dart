import 'package:flutter/material.dart';
import 'package:momeet/core/utils/color_utils.dart';

/// 태그에 사용할 16가지 파스텔 색상 팔레트
class TagColorPalette {
  TagColorPalette._();

  /// 16가지 파스텔 톤 색상 팔레트
  static const List<Color> colors = [
    // 파스텔 레드 계열
    Color(0xFFFFB3B3), // 연한 빨강
    Color(0xFFFFCCCB), // 연한 핑크레드

    // 파스텔 오렌지 계열
    Color(0xFFFFD4B3), // 연한 오렌지
    Color(0xFFFFE4B3), // 연한 피치

    // 파스텔 옐로우 계열
    Color(0xFFFFF4B3), // 연한 노랑
    Color(0xFFFFFFB3), // 연한 크림

    // 파스텔 그린 계열
    Color(0xFFD4FFB3), // 연한 라임
    Color(0xFFB3FFCC), // 연한 민트

    // 파스텔 블루 계열
    Color(0xFFB3E4FF), // 연한 하늘
    Color(0xFFB3D4FF), // 연한 파랑

    // 파스텔 퍼플 계열
    Color(0xFFCCB3FF), // 연한 보라
    Color(0xFFE4B3FF), // 연한 라벤더

    // 파스텔 핑크 계열
    Color(0xFFFFB3E4), // 연한 핑크
    Color(0xFFFFB3D4), // 연한 로즈

    // 파스텔 그레이 계열
    Color(0xFFE6E6E6), // 연한 회색
    Color(0xFFDDDDDD), // 중간 회색
  ];

  /// 기본 색상 (첫 번째 색상)
  static Color get defaultColor => colors.first;

  /// 색상을 Hex 문자열 목록으로 변환
  static List<String> get hexColors =>
      colors.map((color) => color.toHex()).toList();
}
