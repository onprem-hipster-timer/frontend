// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';

class SecurityWarningPage extends StatelessWidget {
  const SecurityWarningPage({super.key, this.attemptedUrl});

  final String? attemptedUrl;

  static const contactEmail = 'jjh4450git@gmail.com';
  static const repoUrl = 'https://github.com/onprem-hipster-timer/frontend';

  @visibleForTesting
  static const maxDisplayLength = 200;

  /// blocked 파라미터를 안전하게 표시할 수 있는 형태로 정제
  ///
  /// - 길이 제한 (DoS 방지)
  /// - URL/경로 패턴이 아닌 값은 차단 (소셜 엔지니어링 방지)
  @visibleForTesting
  static String? sanitizeBlockedUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*:').hasMatch(raw);
    final looksLikePath = raw.startsWith('/') || raw.startsWith('//');

    if (!hasScheme && !looksLikePath) return null;

    if (raw.length > maxDisplayLength) {
      return '${raw.substring(0, maxDisplayLength)}...';
    }
    return raw;
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text 복사됨'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final displayUrl = sanitizeBlockedUrl(attemptedUrl);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 80,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  '보안 경고',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '허가되지 않은 리다이렉트가 감지되었습니다.',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '이 링크는 외부 사이트나 등록되지 않은 경로로 이동시키려는 시도일 수 있습니다.\n'
                  '직접 이 URL을 입력하지 않았다면, 피싱 공격의 대상이 되었을 가능성이 있습니다.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (displayUrl != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withAlpha(77),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: colorScheme.error.withAlpha(77)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '차단된 리다이렉트 경로',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          displayUrl,
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                Text(
                  '이 문제가 반복되거나 의심스러운 활동을 발견하셨다면\n아래 연락처로 신고해 주세요.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _ContactTile(
                  icon: Icons.email_outlined,
                  label: '이메일',
                  value: contactEmail,
                  onCopy: () => _copyToClipboard(context, contactEmail),
                ),
                const SizedBox(height: 8),
                _ContactTile(
                  icon: Icons.code,
                  label: 'GitHub',
                  value: repoUrl,
                  onCopy: () => _copyToClipboard(context, repoUrl),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoute.calendar.path),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('홈으로 돌아가기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(label),
        subtitle: SelectableText(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 20),
          tooltip: '복사',
          onPressed: onCopy,
        ),
      ),
    );
  }
}
