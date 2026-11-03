// Password Change Bottom Sheet
//
// 현재 비밀번호로 다시 인증한 뒤 새 비밀번호로 바꿉니다 (AuthNotifier.changePassword).

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
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '현재 비밀번호를 입력해주세요';
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

  Future<void> _handlePasswordChange() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
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

  Widget _passwordField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String label,
    required String hint,
    required IconData icon,
    required bool visible,
    required VoidCallback onToggleVisible,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisible,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  _passwordField(
                    controller: _currentPasswordController,
                    validator: _validateCurrentPassword,
                    label: '현재 비밀번호',
                    hint: '지금 쓰는 비밀번호를 입력하세요',
                    icon: Icons.lock_open,
                    visible: _isCurrentPasswordVisible,
                    onToggleVisible: () => setState(
                      () => _isCurrentPasswordVisible =
                          !_isCurrentPasswordVisible,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _passwordField(
                    controller: _newPasswordController,
                    validator: _validateNewPassword,
                    label: '새 비밀번호',
                    hint: '8자 이상의 새 비밀번호를 입력하세요',
                    icon: Icons.lock,
                    visible: _isNewPasswordVisible,
                    onToggleVisible: () => setState(
                      () => _isNewPasswordVisible = !_isNewPasswordVisible,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _passwordField(
                    controller: _confirmPasswordController,
                    validator: _validateConfirmPassword,
                    label: '새 비밀번호 확인',
                    hint: '새 비밀번호를 다시 입력하세요',
                    icon: Icons.lock_reset,
                    visible: _isConfirmPasswordVisible,
                    onToggleVisible: () => setState(
                      () => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _handlePasswordChange,
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
                          '• 현재 비밀번호를 확인한 뒤에만 비밀번호가 바뀝니다.\n'
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
