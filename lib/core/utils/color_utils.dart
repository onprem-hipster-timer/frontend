import 'package:flutter/material.dart';

/// Color 객체를 Hex 문자열로 변환하거나, Hex 문자열에서 Color를 생성하는 확장 메서드
///
/// API에서 색상을 Hex String (#RRGGBB)으로 주고받으므로
/// Flutter의 Color 객체와 변환하는 유틸리티를 제공합니다.
extension HexColor on Color {
  /// Color를 Hex 문자열로 변환
  ///
  /// 예시:
  /// ```dart
  /// Color(0xFF123456).toHex() // "#123456"
  /// Colors.red.toHex() // "#F44336"
  /// ```
  String toHex() {
    return '#${toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Hex 문자열에서 Color 생성 (정적 메서드)
  ///
  /// # 기호가 있어도 없어도 파싱 가능합니다.
  /// 6자리 hex 값만 지원합니다.
  ///
  /// 예시:
  /// ```dart
  /// HexColor.fromHex("#123456") // Color(0xFF123456)
  /// HexColor.fromHex("123456")  // Color(0xFF123456)
  /// HexColor.fromHex("invalid") // Colors.grey (기본값)
  /// ```
  static Color fromHex(String hexString) {
    // # 제거
    String cleanHex = hexString.replaceAll('#', '');

    // 6자리가 아닌 경우 기본 색상 반환
    if (cleanHex.length != 6) {
      return Colors.grey;
    }

    // 대소문자 구분 없이 파싱
    try {
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (e) {
      // 파싱 실패 시 기본 색상 반환
      return Colors.grey;
    }
  }
}
