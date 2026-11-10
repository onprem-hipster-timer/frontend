// 비밀번호 재설정과 비밀번호 변경
//
// 이메일 → 메일로 받은 6자리 코드 → 새 비밀번호, 세 단계를 한 화면에서 진행한다.
// 새 비밀번호를 저장하면 로그인 상태가 되고 홈으로 간다.
//
// 로그인한 사용자의 비밀번호 변경도 이 화면에서 한다. 이메일은 고를 수 없고 계정 이메일로 코드를
// 보낸다. 현재 비밀번호만으로는 바꿀 수 없다(backend가 메일 복구 세션이 아닌 변경을 거절한다).

import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_button.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_code_field.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_new_password_fields.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_email_field.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/widgets/error_banner.dart';

enum _Step { email, code, newPassword }

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  _Step _step = _Step.email;
  String? _recoveryFlowId;
  String? _settingsFlowId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifier = ref.read(authProvider.notifier);
      switch (_step) {
        case _Step.email:
          // 로그인한 사용자는 계정 이메일로만 받는다
          final accountEmail = ref.read(currentUserProvider)?.email;
          if (accountEmail != null) _emailController.text = accountEmail;
          _recoveryFlowId = await notifier.sendRecoveryCode(
            _emailController.text.trim(),
          );
          _codeController.clear();
          _goTo(_Step.code);
        case _Step.code:
          _settingsFlowId = await notifier.verifyRecoveryCode(
            flowId: _recoveryFlowId!,
            code: _codeController.text.trim(),
          );
          _goTo(_Step.newPassword);
        case _Step.newPassword:
          await notifier.completeRecovery(
            settingsFlowId: _settingsFlowId!,
            newPassword: _passwordController.text,
          );
          if (mounted) {
            showAppSnackBar(context, '비밀번호를 바꿨습니다. 다른 기기의 로그인은 끊겼습니다.');
            context.goNamed(AppRoute.calendar.name);
          }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e is AuthException ? e.message : e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goTo(_Step step) {
    if (mounted) setState(() => _step = step);
  }

  /// 단계별 안내 문구와 버튼 이름. [accountEmail]이 있으면 로그인한 계정의 비밀번호 변경이다
  (String, String) _texts(String? accountEmail) {
    return switch (_step) {
      _Step.email when accountEmail != null => (
        '$accountEmail(으)로 비밀번호 변경 코드를 보내드립니다.',
        '코드 받기',
      ),
      _Step.email => ('가입한 이메일 주소를 입력해주세요.\n비밀번호 재설정 코드를 보내드립니다.', '코드 받기'),
      _Step.code => (
        '${_emailController.text.trim()}(으)로 보낸 6자리 코드를 입력해주세요.',
        '확인',
      ),
      _Step.newPassword => ('새 비밀번호를 입력해주세요.', '비밀번호 변경'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final accountEmail = ref.watch(currentUserProvider)?.email;
    final (guide, buttonText) = _texts(accountEmail);

    return Scaffold(
      appBar: AppBar(
        title: Text(accountEmail != null ? '비밀번호 변경' : '비밀번호 재설정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErrorBanner(
                message: _errorMessage,
                onDismiss: () => setState(() => _errorMessage = null),
              ),
              Text(
                guide,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ...switch (_step) {
                _Step.email when accountEmail != null => const <Widget>[],
                _Step.email => [
                  AuthEmailField(
                    controller: _emailController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
                _Step.code => [
                  AuthCodeField(
                    controller: _codeController,
                    label: '재설정 코드',
                    onSubmitted: (_) => _submit(),
                  ),
                ],
                _Step.newPassword => [
                  AuthNewPasswordFields(
                    password: _passwordController,
                    confirm: _confirmPasswordController,
                    label: '새 비밀번호',
                    onSubmitted: _submit,
                  ),
                ],
              },
              const SizedBox(height: 32),
              AuthButton(
                text: buttonText,
                onPressed: _submit,
                isLoading: _isLoading,
              ),
              if (_step == _Step.code)
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                          _step = _Step.email;
                          _errorMessage = null;
                        }),
                  child: const Text('코드 다시 받기'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
