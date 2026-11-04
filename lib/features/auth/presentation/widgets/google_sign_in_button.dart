// "Google로 계속하기" 버튼 (로그인·회원가입 화면 공용)
//
// 서버(Kratos)가 Google 로그인을 켰을 때만 보인다. 누르면 브라우저가 Google로 갔다가
// 로그인 화면(/login)으로 돌아오고, 로그인 화면이 돌아온 code로 로그인을 마친다.

import 'package:flutter/material.dart';
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
              minimumSize: const Size.fromHeight(48),
            ),
            child: _starting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Google로 계속하기'),
          ),
        ],
      ),
    );
  }
}
