// Password Change Bottom Sheet
//
// Supabase reauthenticate()로 이메일(또는 SMS) OTP를 발송한 뒤,
// updateUser(password + nonce)로만 비밀번호를 변경합니다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/theme/app_colors.dart';
import 'package:momeet/shared/widgets/error_banner.dart';

/// 비밀번호 변경 바텀 시트
class PasswordChangeSheet extends ConsumerStatefulWidget {
  const PasswordChangeSheet({super.key});

  @override
  ConsumerState<PasswordChangeSheet> createState() =>
      _PasswordChangeSheetState();
}

class _PasswordChangeSheetState extends ConsumerState<PasswordChangeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nonceController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isNonceVisible = false;

  bool _reauthCodeSent = false;
  bool _isSendingCode = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nonceController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNonce(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '인증 코드를 입력해주세요';
    }
    if (value.trim().length < 6) {
      return '인증 코드 형식이 올바르지 않습니다';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '새 비밀번호를 입력해주세요';
    }
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }
    if (value != _newPasswordController.text) {
      return '새 비밀번호와 일치하지 않습니다';
    }
    return null;
  }

  bool _validateNewPasswordFieldsOnly() {
    final newPwdError = _validateNewPassword(_newPasswordController.text);
    final confirmError = _validateConfirmPassword(
      _confirmPasswordController.text,
    );
    if (newPwdError != null || confirmError != null) {
      return false;
    }
    return true;
  }

  Future<void> _requestReauthenticationCode() async {
    if (!_validateNewPasswordFieldsOnly()) {
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      await ref
          .read(authProvider.notifier)
          .requestPasswordChangeReauthentication();

      if (!mounted) return;

      setState(() => _reauthCodeSent = true);

      setState(() => _errorMessage = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('인증 코드를 이메일(또는 등록된 휴대전화)로 보냈습니다.'),
          backgroundColor:
              Theme.of(context).extension<AppColors>()?.success ?? Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is AuthException ? e.message : '인증 코드를 보내지 못했습니다';
      });
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _handlePasswordChange() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_reauthCodeSent) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '먼저 「인증 코드 받기」를 눌러 재인증을 진행해주세요.';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(authProvider.notifier)
          .updatePasswordWithReauthNonce(
            newPassword: _newPasswordController.text.trim(),
            nonce: _nonceController.text.trim(),
          );

      if (mounted) {
        final successColor =
            Theme.of(context).extension<AppColors>()?.success ?? Colors.green;
        context.pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('비밀번호가 성공적으로 변경되었습니다'),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is AuthException ? e.message : '비밀번호 변경에 실패했습니다';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = ref.watch(currentUserProvider)?.email;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '비밀번호 변경',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.close,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  ErrorBanner(
                    message: _errorMessage,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                  if (userEmail != null && userEmail.isNotEmpty) ...[
                    Text(
                      '인증 코드는 $userEmail (또는 계정에 등록된 휴대전화)로 발송됩니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_isNewPasswordVisible,
                    validator: _validateNewPassword,
                    decoration: InputDecoration(
                      labelText: '새 비밀번호',
                      hintText: '8자 이상의 새 비밀번호를 입력하세요',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    validator: _validateConfirmPassword,
                    decoration: InputDecoration(
                      labelText: '새 비밀번호 확인',
                      hintText: '새 비밀번호를 다시 입력하세요',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nonceController,
                    obscureText: !_isNonceVisible,
                    validator: _validateNonce,
                    autocorrect: false,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: '인증 코드',
                      hintText: '메일(또는 SMS)로 받은 코드를 입력하세요',
                      prefixIcon: const Icon(Icons.pin_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNonceVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isNonceVisible = !_isNonceVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _isSendingCode
                          ? null
                          : _requestReauthenticationCode,
                      icon: _isSendingCode
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.mark_email_read_outlined),
                      label: Text(_reauthCodeSent ? '인증 코드 다시 받기' : '인증 코드 받기'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: (_isSubmitting || _isSendingCode)
                        ? null
                        : _handlePasswordChange,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('변경 중...'),
                            ],
                          )
                        : const Text(
                            '비밀번호 변경',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '보안 안내',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Supabase 재인증: 「인증 코드 받기」로 서버에서 코드를 발송합니다.\n'
                          '• 코드를 입력한 뒤에만 비밀번호가 서버에 반영됩니다.\n'
                          '• 새 비밀번호는 8자 이상이어야 하며, 다른 서비스와 다른 비밀번호를 쓰는 것을 권장합니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 비밀번호 변경 시트를 표시하는 헬퍼 함수
Future<void> showPasswordChangeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (context) => const PasswordChangeSheet(),
  );
}
