// "Google 계정으로 계속하기" 버튼의 모양 (로그인·회원가입 화면 공용)
//
// 모양·색·로고·글꼴은 Google 브랜딩 가이드라인을 따르므로 앱 테마로 바꾸지 않는다.
// https://developers.google.com/identity/branding-guidelines

import 'package:material_ui/material_ui.dart';

/// 구분선('또는') 아래의 "Google 계정으로 계속하기" 버튼
///
/// [waiting]이면 같은 자리·크기의 막힌 버튼('잠시만 기다려 주세요')을, [starting]이면 글자 대신 진행 표시를 둔다.
class GoogleSignInButtonView extends StatelessWidget {
  const GoogleSignInButtonView({
    super.key,
    required this.waiting,
    required this.starting,
    required this.onPressed,
  });

  /// 서버에 Google 로그인이 켜졌는지 묻는 중
  final bool waiting;

  /// 누른 뒤 Google로 넘어가는 중
  final bool starting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? _GoogleButtonColors.dark
        : _GoogleButtonColors.light;
    // 묻는 동안은 가이드라인의 비활성 색(바탕 61%, 테두리 12%, 글자·로고 38%)이다
    final idle = waiting ? colors.disabled : colors;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('또는'),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: waiting || starting ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: colors.fill,
              disabledBackgroundColor: idle.fill,
              foregroundColor: colors.text,
              disabledForegroundColor: idle.text,
              side: BorderSide(color: idle.stroke),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Google Sans',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
            child: starting
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.text,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: waiting ? 0.38 : 1,
                        child: Image.asset(
                          'assets/google_g_logo.webp',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          waiting ? '잠시만 기다려 주세요' : 'Google 계정으로 계속하기',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// 가이드라인이 정한 밝은·어두운 테마 색
class _GoogleButtonColors {
  const _GoogleButtonColors({
    required this.fill,
    required this.stroke,
    required this.text,
  });

  final Color fill;
  final Color stroke;
  final Color text;

  /// 막힌 버튼의 색: 바탕 61%, 테두리 12%, 글자 38%
  _GoogleButtonColors get disabled => _GoogleButtonColors(
    fill: fill.withValues(alpha: 0.61),
    stroke: (this == light ? text : stroke).withValues(alpha: 0.12),
    text: text.withValues(alpha: 0.38),
  );

  static const light = _GoogleButtonColors(
    fill: Color(0xFFFFFFFF),
    stroke: Color(0xFF747775),
    text: Color(0xFF1F1F1F),
  );

  static const dark = _GoogleButtonColors(
    fill: Color(0xFF131314),
    stroke: Color(0xFF8E918F),
    text: Color(0xFFE3E3E3),
  );
}
