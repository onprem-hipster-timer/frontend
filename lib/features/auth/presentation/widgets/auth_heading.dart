import 'package:material_ui/material_ui.dart';

/// 인증 화면 맨 위의 제목과 한 줄 소개. [brand]면 제목을 앱 이름처럼 크게 주색으로 쓴다
class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.brand = false,
  });

  final String title;
  final String subtitle;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = brand
        ? theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, textAlign: TextAlign.center, style: titleStyle),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
