// 이메일 인증
//
// 가입 직후, 인증 전 로그인 시도(서버가 새 플로우를 줌), 인증 메일 링크(?flow=)로 들어온다.
// 앱은 API 플로우를 쓰므로 메일 링크를 열어도 인증이 끝나지 않는다. 메일의 6자리 코드를 입력받는다.
// 이메일 인증 전에는 세션이 없으므로, 인증을 마치면 로그인 화면으로 보낸다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_button.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/widgets/error_banner.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key, this.flowId, this.email});

  /// 코드를 보낸 인증 플로우. 없으면 이메일부터 받는다.
  final String? flowId;

  /// 코드를 보낸 이메일 (가입 화면에서 넘어올 때)
  final String? email;

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _flowId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _flowId = widget.flowId;
    _emailController.text =
        widget.email ?? ref.read(currentUserProvider)?.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 액션을 실행하고 실패하면 오류 배너에 띄운다. 성공하면 true.
  Future<bool> _run(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await action();
      return true;
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e is AuthException ? e.message : e.toString(),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    String? flowId;
    final sent = await _run(() async {
      flowId = await ref
          .read(authProvider.notifier)
          .sendVerificationCode(_emailController.text.trim());
    });
    if (sent && mounted) {
      setState(() {
        _flowId = flowId;
        _codeController.clear();
      });
    }
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final verified = await _run(
      () => ref
          .read(authProvider.notifier)
          .verifyEmail(flowId: _flowId!, code: _codeController.text.trim()),
    );
    if (verified && mounted) _leave();
  }

  /// 로그인 상태면 홈으로, 아니면 이메일을 채운 로그인 화면으로 간다.
  void _leave() {
    if (ref.read(isAuthenticatedProvider)) {
      context.goNamed(AppRoute.calendar.name);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이메일이 인증되었습니다. 로그인해주세요.')));
    context.goNamed(AppRoute.login.name, extra: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final hasFlow = _flowId != null;
    final email = _emailController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('이메일 인증')),
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
                !hasFlow
                    ? '인증 코드를 받을 이메일을 입력해주세요.'
                    : email.isEmpty
                    ? '메일로 받은 6자리 코드를 입력해주세요.'
                    : '$email(으)로 보낸 6자리 코드를 입력해주세요.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!hasFlow) ...[
                AuthTextField(
                  controller: _emailController,
                  label: '이메일',
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.email_outlined,
                  onSubmitted: (_) => _sendCode(),
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
                const SizedBox(height: 32),
                AuthButton(
                  text: '코드 받기',
                  onPressed: _sendCode,
                  isLoading: _isLoading,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ] else ...[
                AuthTextField(
                  controller: _codeController,
                  label: '인증 코드',
                  hint: '6자리 숫자',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.pin_outlined,
                  onSubmitted: (_) => _verify(),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? '인증 코드를 입력해주세요'
                      : null,
                ),
                const SizedBox(height: 32),
                AuthButton(
                  text: '인증하기',
                  onPressed: _verify,
                  isLoading: _isLoading,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                          _flowId = null;
                          _errorMessage = null;
                        }),
                  child: const Text('코드 다시 받기'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
