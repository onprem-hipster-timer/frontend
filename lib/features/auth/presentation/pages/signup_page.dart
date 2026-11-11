import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/router.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_button.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_heading.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_switch_prompt.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_new_password_fields.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_email_field.dart';
import 'package:momeet/features/auth/presentation/widgets/google_sign_in_button.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key, this.initialEmail});

  /// 로그인 폼에서 전환해 올 때 이어받는 이메일.
  ///
  /// URL이 아닌 라우터 `extra`(인메모리)로 전달돼 재입력 부담을 줄입니다.
  /// 비밀번호는 보안상 이어받지 않습니다.
  final String? initialEmail;

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(authProvider.notifier);
      final email = _emailController.text.trim();
      final verificationFlowId = await notifier.signUpWithEmail(
        email: email,
        password: _passwordController.text,
      );

      if (!mounted) return;
      if (verificationFlowId == null) {
        // 인증 메일이 없는 설정이면 바로 로그인 화면으로
        context.goNamed(AppRoute.login.name, extra: email);
      } else {
        context.goNamed(
          AppRoute.verification.name,
          queryParameters: {'flow': verificationFlowId},
          extra: email,
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    showAppSnackBar(context, message, kind: AppNoticeKind.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                title: '회원가입',
                subtitle: 'momeet과 함께 하루를 시작하세요',
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthEmailField(controller: _emailController),
                    const SizedBox(height: 16),
                    AuthNewPasswordFields(
                      password: _passwordController,
                      confirm: _confirmPasswordController,
                      label: '비밀번호',
                      onSubmitted: _handleSignup,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AuthButton(
                text: '회원가입',
                onPressed: _handleSignup,
                isLoading: _isLoading,
              ),
              GoogleSignInButton(signUp: true, onError: _showError),
              const SizedBox(height: 24),
              AuthSwitchPrompt(
                question: '이미 계정이 있으신가요?',
                actionLabel: '로그인',
                onPressed: () => context.go(
                  AppRoute.login.path,
                  extra: _emailController.text.trim(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
