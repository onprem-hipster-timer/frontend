import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/config/legal_links.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_button.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_heading.dart';
import 'package:momeet/features/auth/presentation/widgets/consent_check_tile.dart';

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

  /// 약관 동의와 선택한 사용성 분석 동의를 한 요청으로 보낸다. 계정에 저장되면 이 브라우저에도 그 값을 둔다
  Future<void> _submit() async {
    setState(() => _submitting = true);
    final analytics = _analytics;
    try {
      await ref
          .read(myProfileProvider.notifier)
          .agree(widget.version, analytics: analytics);
      ref
          .read(analyticsConsentProvider.notifier)
          .set(AnalyticsConsent.of(analytics));
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
              ConsentCheckTile(
                label: ConsentLabels.all,
                emphasized: true,
                value: _requiredChecked && _analytics,
                onChanged: _setAll,
              ),
              const Divider(height: 1),
              ConsentCheckTile(
                label: ConsentLabels.ageOver14,
                value: _ageOver14,
                onChanged: (value) => setState(() => _ageOver14 = value),
              ),
              ConsentCheckTile(
                label: ConsentLabels.terms,
                link: LegalLinks.terms,
                value: _terms,
                onChanged: (value) => setState(() => _terms = value),
              ),
              ConsentCheckTile(
                label: ConsentLabels.privacy,
                link: LegalLinks.privacy,
                value: _privacy,
                onChanged: (value) => setState(() => _privacy = value),
              ),
              ConsentCheckTile(
                label: '[선택] 화면 개선을 위한 사용성 분석 동의',
                description:
                    '화면 이용 기록이 Microsoft Clarity(미국)로 전송되어 최대 9개월 보관됩니다. '
                    '입력한 내용은 가려지고, 거부해도 이용에 제한이 없습니다.',
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
