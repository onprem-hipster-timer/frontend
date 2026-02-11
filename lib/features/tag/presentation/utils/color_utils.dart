import 'package:flutter/material.dart';

/// Color 확장 메서드
///
/// API에서 색상을 Hex String (#RRGGBB)으로 주고받으므로
/// Flutter의 Color 객체와 변환하는 유틸리티를 제공합니다.
extension ColorExt on Color {
  /// Color를 Hex 문자열로 변환
  ///
  /// 예: Color(0xFF123456) -> "#123456"
  String toHex() {
    return '#${toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Hex 문자열에서 Color 생성
  ///
  /// 예: "#123456" -> Color(0xFF123456)
  /// 예: "123456" -> Color(0xFF123456)
  static Color fromHex(String hexString) {
    // # 제거
    String cleanHex = hexString.replaceAll('#', '');
    
    // 6자리가 아닌 경우 기본 색상 반환
    if (cleanHex.length != 6) {
      return Colors.grey;
    }
    
    return Color(int.parse('FF$cleanHex', radix: 16));
  }
}

/// 미리 정의된 파스텔 색상 팔레트
class TagColors {
  TagColors._();

  /// 태그에 사용할 수 있는 파스텔 톤 색상 팔레트 (16가지)
  static const List<Color> palette = [
    // 파스텔 레드 계열
    Color(0xFFFFB3BA),
    Color(0xFFFFCDD2),
    
    // 파스텔 오렌지 계열
    Color(0xFFFFDCC4),
    Color(0xFFFFE0B2),
    
    // 파스텔 옐로우 계열
    Color(0xFFFFEFB5),
    Color(0xFFF9FBE7),
    
    // 파스텔 그린 계열
    Color(0xFFBAE1FF),
    Color(0xFFC8E6C9),
    
    // 파스텔 블루 계열
    Color(0xFFB3E5FC),
    Color(0xFFBBDEFB),
    
    // 파스텔 퍼플 계열
    Color(0xFFD1C4E9),
    Color(0xFFE1BEE7),
    
    // 파스텔 핑크 계열
    Color(0xFFF8BBD9),
    Color(0xFFFFCDD2),
    
    // 파스텔 그레이 계열
    Color(0xFFF5F5F5),
    Color(0xFFEEEEEE),
  ];

  /// 색상을 Hex 문자열로 변환하는 헬퍼 메서드
  static List<String> get paletteHex =>
      palette.map((color) => color.toHex()).toList();

  /// 기본 태그 색상 (첫 번째 팔레트 색상)
  static Color get defaultColor => palette.first;
  static String get defaultColorHex => defaultColor.toHex();
}
