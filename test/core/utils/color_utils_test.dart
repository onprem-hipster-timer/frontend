import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:momeet/core/utils/color_utils.dart';

void main() {
  group('HexColor Extension Tests', () {
    test('should convert Color to hex string correctly', () {
      // Given
      const color1 = Color(0xFF123456);
      const color2 = Color(0xFFFFFFFF);
      const color3 = Color(0xFF000000);

      // When & Then
      expect(color1.toHex(), equals('#123456'));
      expect(color2.toHex(), equals('#FFFFFF'));
      expect(color3.toHex(), equals('#000000'));
    });

    test('should parse hex string to Color correctly', () {
      // Given & When
      final color1 = HexColor.fromHex('#123456');
      final color2 = HexColor.fromHex('FFFFFF');
      final color3 = HexColor.fromHex('#000000');

      // Then
      expect(color1, equals(const Color(0xFF123456)));
      expect(color2, equals(const Color(0xFFFFFFFF)));
      expect(color3, equals(const Color(0xFF000000)));
    });

    test('should return default color for invalid hex strings', () {
      // Given & When
      final color1 = HexColor.fromHex('invalid');
      final color2 = HexColor.fromHex('#12345');  // 5자리
      final color3 = HexColor.fromHex('#1234567'); // 7자리

      // Then
      expect(color1, equals(Colors.grey));
      expect(color2, equals(Colors.grey));
      expect(color3, equals(Colors.grey));
    });

    test('should handle case-insensitive hex parsing', () {
      // Given & When
      final color1 = HexColor.fromHex('#abcdef');
      final color2 = HexColor.fromHex('#ABCDEF');
      final color3 = HexColor.fromHex('AbCdEf');

      // Then
      expect(color1, equals(const Color(0xFFABCDEF)));
      expect(color2, equals(const Color(0xFFABCDEF)));
      expect(color3, equals(const Color(0xFFABCDEF)));
    });

    test('should be reversible (hex -> color -> hex)', () {
      // Given
      const originalHex = '#FF5733';

      // When
      final color = HexColor.fromHex(originalHex);
      final resultHex = color.toHex();

      // Then
      expect(resultHex, equals(originalHex));
    });
  });
}
