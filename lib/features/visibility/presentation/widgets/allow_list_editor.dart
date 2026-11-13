import 'package:material_ui/material_ui.dart';

/// 공유를 허용할 이메일·도메인을 넣고 빼는 칸과 목록
///
/// 칸에서 완료를 누르거나 추가 버튼을 누르면 [onSubmit]으로 [draft]를 넣는다.
class AllowListEditor extends StatelessWidget {
  const AllowListEditor({
    super.key,
    required this.emails,
    required this.domains,
    required this.draft,
    required this.error,
    required this.enabled,
    required this.onSubmit,
    required this.onDraftChanged,
    required this.onRemove,
  });

  final List<String> emails;
  final List<String> domains;
  final TextEditingController draft;

  /// [draft]를 넣지 못한 까닭
  final String? error;
  final bool enabled;
  final VoidCallback onSubmit;
  final VoidCallback onDraftChanged;
  final void Function(String entry) onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: draft,
            enabled: enabled,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onChanged: (_) => onDraftChanged(),
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              label: const Text('이메일 또는 도메인', maxLines: 2),
              hintText: 'name@example.com 또는 example.com',
              hintMaxLines: 2,
              helperText: '도메인을 넣으면 그 도메인의 모든 주소를 허용합니다',
              helperMaxLines: 3,
              errorText: error,
              errorMaxLines: 4,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                tooltip: '추가',
                onPressed: enabled ? onSubmit : null,
              ),
            ),
          ),
          for (final email in emails)
            _AllowedEntry(
              entry: email,
              icon: Icons.alternate_email,
              enabled: enabled,
              onRemove: () => onRemove(email),
            ),
          for (final domain in domains)
            _AllowedEntry(
              entry: domain,
              icon: Icons.domain,
              enabled: enabled,
              onRemove: () => onRemove(domain),
            ),
        ],
      ),
    );
  }
}

/// 허용 목록의 이메일이나 도메인 한 줄
class _AllowedEntry extends StatelessWidget {
  const _AllowedEntry({
    required this.entry,
    required this.icon,
    required this.enabled,
    required this.onRemove,
  });

  final String entry;
  final IconData icon;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(entry),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: '$entry 빼기',
        onPressed: enabled ? onRemove : null,
      ),
    );
  }
}
