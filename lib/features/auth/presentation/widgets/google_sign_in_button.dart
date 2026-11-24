// "Google 계정으로 계속하기" 버튼 (로그인·회원가입 화면 공용)
//
// 서버(Kratos)에 Google 로그인이 켜졌는지 묻는 동안에는 같은 자리·크기의 막힌 버튼('잠시만 기다려 주세요')을
// 두어 화면이 움직이지 않게 하고, 켜져 있으면 누를 수 있는 버튼이, 꺼져 있거나 묻지 못하면 구분선과 함께 사라진다.
// 누르면 브라우저가 Google로 갔다가 로그인 화면(/login)으로 돌아오고, 로그인 화면이 돌아온 code로 로그인을 마친다.
//
// 모양은 GoogleSignInButtonView

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/features/auth/presentation/widgets/google_sign_in_button_view.dart';
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
    final availability = ref.watch(googleSignInAvailableProvider);
    final waiting = availability.isLoading && !availability.hasValue;
    if (!waiting && availability.value != true) return const SizedBox.shrink();

    return GoogleSignInButtonView(
      waiting: waiting,
      starting: _starting,
      onPressed: _start,
    );
  }
}
