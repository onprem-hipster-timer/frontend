import 'package:momeet/core/text/nfc.dart';

/// 게스트 이름의 정규형: NFC로 바꾸고, 이어진 공백을 한 칸으로 줄이고, 앞뒤 공백을 뗀다(backend와 같다)
String guestName(String input) =>
    nfc(input).replaceAll(RegExp(r'\s+'), ' ').trim();
