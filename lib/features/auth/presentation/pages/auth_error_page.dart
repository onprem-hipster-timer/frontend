// 인증 오류
//
// Kratos가 브라우저 이동 중 오류를 만나면 이 화면으로 보낸다 (예: 만료되거나 잘못된 메일 링크).

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';

class AuthErrorPage extends StatelessWidget {
  const AuthErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('인증 오류')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link_off_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '링크가 만료되었거나 올바르지 않습니다.\n처음부터 다시 시도해주세요.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.goNamed(AppRoute.login.name),
                child: const Text('로그인 화면으로'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
