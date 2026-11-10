import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/config/legal_links.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_button.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_heading.dart';

/// 로그인 뒤 약관 동의. 필수 항목에 모두 동의해야 앱을 쓸 수 있다.
///
/// 동의를 마치면 라우터가 원래 가려던 화면으로 보낸다.
class ConsentPage extends ConsumerWidget {
  const ConsentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final version = profile.value?.consentVersion;
    if (profile.hasError && !profile.isLoading) {
      return Scaffold(
        body: AppErrorState(
          title: '약관 정보를 불러오지 못했습니다',
          error: profile.error,
          onRetry: () => ref.invalidate(myProfileProvider),
          secondaryLabel: '로그아웃',
          secondaryIcon: Icons.logout,
          onSecondary: () => _signOut(context, ref),
        ),
      );
    }
    if (profile.isLoading || version == null) {
      return const Scaffold(body: AppLoading());
    }
    // 약관 버전이 바뀌면 체크를 모두 지우고 다시 받는다
    return _ConsentForm(key: ValueKey(version), version: version);
  }
}

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(authProvider.notifier).signOut();
  } on Exception catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, '로그아웃 실패: $e', kind: AppNoticeKind.error);
    }
  }
}

class _ConsentForm extends ConsumerStatefulWidget {
  const _ConsentForm({super.key, required this.version});

  /// 동의할 약관 버전 (프로필이 알려 준 값)
  final String version;

  @override
  ConsumerState<_ConsentForm> createState() => _ConsentFormState();
}

class _ConsentFormState extends ConsumerState<_ConsentForm> {
  bool _ageOver14 = false;
  bool _terms = false;
  bool _privacy = false;
  bool _analytics = false;
  bool _submitting = false;

  bool get _requiredChecked => _ageOver14 && _terms && _privacy;

  @override
  void initState() {
    super.initState();
    _analytics = ref.read(analyticsConsentProvider) == AnalyticsConsent.granted;
  }

  void _setAll(bool value) => setState(() {
    _ageOver14 = value;
    _terms = value;
    _privacy = value;
    _analytics = value;
  });

  Future<void> _submit() async {
    setState(() => _submitting = true);
    ref
        .read(analyticsConsentProvider.notifier)
        .set(_analytics ? AnalyticsConsent.granted : AnalyticsConsent.denied);
    try {
      await ref.read(myProfileProvider.notifier).agree(widget.version);
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 409) {
        showAppSnackBar(
          context,
          '약관이 바뀌었습니다. 바뀐 내용을 확인하고 다시 동의해 주세요.',
          kind: AppNoticeKind.error,
        );
        ref.invalidate(myProfileProvider);
        return;
      }
      _showError(e);
    } on Exception catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(Object error) {
    showAppSnackBar(
      context,
      '동의 저장에 실패했습니다: $error',
      kind: AppNoticeKind.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 앱 위에 뜬 동의 배너에서 고른 값도 따라간다
    ref.listen(analyticsConsentProvider, (_, next) {
      setState(() => _analytics = next == AnalyticsConsent.granted);
    });
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                title: '약관 동의',
                subtitle: 'momeet을 이용하려면 아래 항목에 동의해 주세요',
              ),
              const SizedBox(height: 32),
              _AllConsentTile(
                value: _requiredChecked && _analytics,
                onChanged: _setAll,
              ),
              const Divider(height: 1),
              _ConsentItem(
                label: '[필수] 만 14세 이상입니다',
                value: _ageOver14,
                onChanged: (value) => setState(() => _ageOver14 = value),
              ),
              _ConsentItem(
                label: '[필수] 이용약관 동의',
                link: LegalLinks.terms,
                value: _terms,
                onChanged: (value) => setState(() => _terms = value),
              ),
              _ConsentItem(
                label: '[필수] 개인정보 수집·이용 동의',
                link: LegalLinks.privacy,
                value: _privacy,
                onChanged: (value) => setState(() => _privacy = value),
              ),
              _ConsentItem(
                label: '[선택] 사용성 분석(Microsoft Clarity) 동의',
                description:
                    '방문·클릭·스크롤·화면 재현 정보가 Microsoft(미국)로 전송되어 '
                    '최대 30일 보관됩니다. 거부해도 이용에 제한이 없습니다.',
                value: _analytics,
                onChanged: (value) => setState(() => _analytics = value),
              ),
              const SizedBox(height: 32),
              AuthButton(
                text: '동의하고 시작하기',
                onPressed: _requiredChecked ? _submit : null,
                isLoading: _submitting,
              ),
              const SizedBox(height: 24),
              _Decline(
                onPressed: _submitting ? null : () => _signOut(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 모든 항목(선택 포함)을 한 번에 켜고 끈다
class _AllConsentTile extends StatelessWidget {
  const _AllConsentTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        '전체 동의',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 동의하지 않는 길. 왜 쓸 수 없는지 알리고 로그아웃한다
class _Decline extends StatelessWidget {
  const _Decline({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '필수 항목에 동의하지 않으면 momeet을 이용할 수 없습니다. '
          '만 14세 미만은 가입할 수 없습니다.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(onPressed: onPressed, child: const Text('동의하지 않고 로그아웃')),
      ],
    );
  }
}

/// 동의 항목 하나. [link]를 주면 옆에 '보기'를 둔다
class _ConsentItem extends ConsumerWidget {
  const _ConsentItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.link,
    this.description,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Uri? link;
  final String? description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = this.link;
    final description = this.description;
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(label),
      subtitle: description == null ? null : Text(description),
      secondary: link == null
          ? null
          : TextButton(
              onPressed: () => ref.read(openLinkProvider)(link),
              child: const Text('보기'),
            ),
    );
  }
}
