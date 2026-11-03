// 비밀번호 재설정
//
// 이메일 → 메일로 받은 6자리 코드 → 새 비밀번호, 세 단계를 한 화면에서 진행한다.
// 새 비밀번호를 저장하면 로그인 상태가 되고, 라우터가 홈으로 보낸다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_button.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_text_field.dart';
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

  @override
  Widget build(BuildContext context) {
    final (guide, buttonText) = switch (_step) {
      _Step.email => ('가입한 이메일 주소를 입력해주세요.\n비밀번호 재설정 코드를 보내드립니다.', '코드 받기'),
      _Step.code => (
        '${_emailController.text.trim()}(으)로 보낸 6자리 코드를 입력해주세요.',
        '확인',
      ),
      _Step.newPassword => ('새 비밀번호를 입력해주세요.', '비밀번호 변경'),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
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
                _Step.email => [
                  AuthTextField(
                    controller: _emailController,
                    label: '이메일',
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.email_outlined,
                    onSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),
                ],
                _Step.code => [
                  AuthTextField(
                    controller: _codeController,
                    label: '재설정 코드',
                    hint: '6자리 숫자',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.pin_outlined,
                    onSubmitted: (_) => _submit(),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? '재설정 코드를 입력해주세요'
                        : null,
                  ),
                ],
                _Step.newPassword => [
                  AuthTextField(
                    controller: _passwordController,
                    label: '새 비밀번호',
                    obscureText: true,
                    prefixIcon: Icons.lock_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '새 비밀번호를 입력해주세요';
                      }
                      if (value.length < 8) {
                        return '비밀번호는 8자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: '새 비밀번호 확인',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outlined,
                    onSubmitted: (_) => _submit(),
                    validator: (value) => value != _passwordController.text
                        ? '비밀번호가 일치하지 않습니다'
                        : null,
                  ),
                ],
              },
              const SizedBox(height: 32),
              AuthButton(
                text: buttonText,
                onPressed: _submit,
                isLoading: _isLoading,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
