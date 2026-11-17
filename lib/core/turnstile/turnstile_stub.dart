import 'package:momeet/core/turnstile/turnstile.dart';

/// 웹이 아니면 확인 위젯이 없다
TurnstileController Function()? turnstileFactory(String? siteKey) => null;
