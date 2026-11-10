import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/router.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_button.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_email_field.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:momeet/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:momeet/shared/widgets/error_banner.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    super.key,
    this.initialEmail,
    this.googleCode,
    this.accountLinkFlowId,
  });

  /// 회원가입 폼에서 전환해 올 때 이어받는 이메일.
  ///
  /// URL이 아닌 라우터 `extra`(인메모리)로 전달돼 재입력 부담을 줄입니다.
  /// 비밀번호는 보안상 이어받지 않습니다.
  final String? initialEmail;

  /// Google 로그인을 마치고 돌아올 때 Kratos가 붙여 주는 `code`.
  ///
  /// 있으면 이 화면이 로그인을 마친다. 로그인 뒤 이동은 다른 로그인과 같이 라우터가
  /// `redirect`를 검사해 정한다.
  final String? googleCode;

  /// Google 이메일로 이미 가입된 계정이 있을 때 Kratos가 넘기는 로그인 플로우 ID.
  ///
  /// 있으면 그 계정 이메일을 고정하고 비밀번호를 받아, 로그인하면서 Google을 계정에 연결한다.
  final String? accountLinkFlowId;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  /// Google을 연결할 기존 계정 이메일. 있으면 계정 연결 화면이다.
  String? _linkEmail;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    final googleCode = widget.googleCode;
    if (googleCode != null) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _completeGoogleSignIn(googleCode),
      );
    }
    final linkFlowId = widget.accountLinkFlowId;
    if (googleCode == null && linkFlowId != null) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadAccountLink(linkFlowId),
      );
    }
  }

  /// 이 브라우저에서 시작한 Google 로그인이 아니면 남이 보낸 링크일 수 있으므로 보안 경고로 보낸다.
  bool _blockUnstartedGoogleSignIn() {
    if (ref.read(authProvider.notifier).hasPendingGoogleSignIn) return false;
    context.goNamed(
      AppRoute.securityWarning.name,
      queryParameters: {'blocked': GoRouterState.of(context).uri.toString()},
    );
    return true;
  }

  /// Google에서 돌아온 code로 로그인을 마친다.
  Future<void> _completeGoogleSignIn(String code) async {
    final auth = ref.read(authProvider.notifier);
    if (_blockUnstartedGoogleSignIn()) return;
    try {
      await auth.completeGoogleSignIn(code);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Kratos가 기존 계정 연결을 요청한 플로우를 읽어 연결할 계정 이메일을 보여 준다.
  Future<void> _loadAccountLink(String flowId) async {
    if (_blockUnstartedGoogleSignIn()) return;
    try {
      final email = await ref
          .read(authProvider.notifier)
          .googleAccountLinkEmail(flowId);
      if (!mounted) return;
      setState(() {
        if (email == null) {
          _errorMessage = '연결 요청이 만료되었거나 올바르지 않습니다. Google로 다시 로그인해주세요.';
        } else {
          _linkEmail = email;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final linkEmail = _linkEmail;
      if (linkEmail != null) {
        await ref
            .read(authProvider.notifier)
            .completeGoogleAccountLink(
              flowId: widget.accountLinkFlowId!,
              email: linkEmail,
              password: _passwordController.text,
            );
      } else {
        await ref
            .read(authProvider.notifier)
            .signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      }
    } on EmailNotVerifiedException catch (e) {
      // 서버가 새 인증 플로우를 만들어 코드를 다시 보냈다. 그 플로우로 인증 화면을 연다
      if (mounted) {
        context.goNamed(
          AppRoute.verification.name,
          queryParameters: {
            if (e.verificationFlowId != null) 'flow': e.verificationFlowId!,
          },
          extra: _linkEmail ?? _emailController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or App Name
              Text(
                'momeet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '일상을 계획하고 기록하세요',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_linkEmail case final linkEmail?)
                      _AccountLinkNotice(email: linkEmail)
                    else
                      AuthEmailField(controller: _emailController),
                    const SizedBox(height: 16),
                    AuthPasswordField(
                      controller: _passwordController,
                      label: '비밀번호',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoute.forgotPassword.path),
                  child: const Text('비밀번호를 잊으셨나요?'),
                ),
              ),
              const SizedBox(height: 8),

              ErrorBanner(message: _errorMessage, onDismiss: _clearError),

              AuthButton(
                text: _linkEmail == null ? '로그인' : '로그인하고 Google 연결',
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),

              if (_linkEmail == null)
                GoogleSignInButton(
                  onError: (message) => setState(() => _errorMessage = message),
                ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('계정이 없으신가요?'),
                  TextButton(
                    onPressed: () => context.push(
                      AppRoute.signup.path,
                      extra: _emailController.text.trim(),
                    ),
                    child: const Text('회원가입'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 기존 계정 연결 안내: 어느 계정에 Google을 연결하는지 보여 준다 (이메일은 바꿀 수 없다)
class _AccountLinkNotice extends StatelessWidget {
  const _AccountLinkNotice({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(77),
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.link_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$email(으)로 이미 가입된 계정이 있습니다.\n'
              '이 계정의 비밀번호로 로그인하면 Google 계정이 연결되고, 다음부터 Google로 로그인할 수 있습니다.',
            ),
          ),
        ],
      ),
    );
  }
}
