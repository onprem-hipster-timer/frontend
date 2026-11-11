// "Google 계정으로 계속하기" 버튼 (로그인·회원가입 화면 공용)
//
// 서버(Kratos)가 Google 로그인을 켰을 때만 보인다. 누르면 브라우저가 Google로 갔다가
// 로그인 화면(/login)으로 돌아오고, 로그인 화면이 돌아온 code로 로그인을 마친다.
//
// 모양·색·로고·글꼴은 Google 브랜딩 가이드라인을 따르므로 앱 테마로 바꾸지 않는다.
// https://developers.google.com/identity/branding-guidelines

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/router.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onError,
    this.signUp = false,
  });

  /// 시작하지 못했을 때 화면에 보여 줄 메시지를 받는다
  final ValueChanged<String> onError;

  /// 회원가입 화면에서 쓰는지
  final bool signUp;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _starting = false;

  Future<void> _start() async {
    // 로그인 뒤 돌아갈 경로는 돌아오는 주소에 그대로 실어 보낸다. 검사는 라우터가 한다.
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    final returnTo = Uri.parse(ref.read(appOriginProvider)).replace(
      path: AppRoute.login.path,
      queryParameters: redirect == null ? null : {'redirect': redirect},
    );

    setState(() => _starting = true);
    try {
      final google = await ref
          .read(authProvider.notifier)
          .startGoogleSignIn(returnTo: returnTo, signUp: widget.signUp);
      await ref.read(browserRedirectProvider)(google);
    } catch (e) {
      if (mounted) {
        setState(() => _starting = false);
        widget.onError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(googleSignInAvailableProvider).value ?? false;
    if (!available) return const SizedBox.shrink();

    final colors = Theme.of(context).brightness == Brightness.dark
        ? _GoogleButtonColors.dark
        : _GoogleButtonColors.light;

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
            onPressed: _starting ? null : _start,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: colors.fill,
              disabledBackgroundColor: colors.fill,
              foregroundColor: colors.text,
              disabledForegroundColor: colors.text,
              side: BorderSide(color: colors.stroke),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Google Sans',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
            child: _starting
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
                      Image.asset(
                        'assets/google_g_logo.webp',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'Google 계정으로 계속하기',
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
