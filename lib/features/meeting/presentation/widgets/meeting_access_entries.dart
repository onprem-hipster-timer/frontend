import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_access.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 비공개 모임을 열 수 있는 이메일·도메인을 하나씩 넣는 칸과 넣은 것의 칩. 넣을 때 형식을 보고(아니면 칸 아래에
/// 알린다), 이미 넣은 것은 대소문자와 상관없이 다시 넣지 않고 칸만 비운다. 칩의 x로 뺀다
class MeetingAccessEntries extends StatefulWidget {
  const MeetingAccessEntries({
    super.key,
    required this.emails,
    required this.domains,
    required this.onAdd,
    required this.onRemove,
    this.enabled = true,
  });

  final List<String> emails;
  final List<String> domains;
  final ValueChanged<MeetingAccessEntry> onAdd;
  final ValueChanged<String> onRemove;
  final bool enabled;

  @override
  State<MeetingAccessEntries> createState() => _MeetingAccessEntriesState();
}

class _MeetingAccessEntriesState extends State<MeetingAccessEntries> {
  /// 글자 배율 1에서 이 폭부터 칸 옆에 추가 단추를 둔다(배율만큼 넓어진다)
  static const _rowFrom = 280.0;

  final _input = TextEditingController();
  var _invalid = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    if (_input.text.trim().isEmpty) return;
    final entry = parseMeetingAccessEntry(_input.text);
    if (entry == null) return setState(() => _invalid = true);
    final known =
        widget.emails.contains(entry.value) ||
        widget.domains.contains(entry.value);
    if (!known) widget.onAdd(entry);
    _input.clear();
    setState(() => _invalid = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final field = TextField(
      controller: _input,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: meetingAccessFieldLabel,
        hintText: meetingAccessFieldHint,
        errorText: _invalid ? meetingAccessInvalid : null,
      ),
      onChanged: (_) {
        if (_invalid) setState(() => _invalid = false);
      },
      onSubmitted: (_) => _add(),
    );
    final add = FilledButton.tonal(
      onPressed: enabled ? _add : null,
      style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
      child: const Text(meetingAccessAdd),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 좁으면 칸을 한 줄 다 쓰고 추가 단추는 그 아래 오른쪽에 둔다
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth <
                  MediaQuery.textScalerOf(context).scale(_rowFrom)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: add,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 8),
                    Padding(padding: const EdgeInsets.only(top: 4), child: add),
                  ],
                ),
        ),
        if (widget.emails.isNotEmpty || widget.domains.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final email in widget.emails)
                _EntryChip(
                  value: email,
                  domain: false,
                  enabled: enabled,
                  onRemove: widget.onRemove,
                ),
              for (final domain in widget.domains)
                _EntryChip(
                  value: domain,
                  domain: true,
                  enabled: enabled,
                  onRemove: widget.onRemove,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 넣은 이메일·도메인 하나와 빼기 단추. 도메인은 앞에 '@'를 붙여 보이고, 길면 여러 줄로 보인다
class _EntryChip extends StatelessWidget {
  const _EntryChip({
    required this.value,
    required this.domain,
    required this.enabled,
    required this.onRemove,
  });

  final String value;
  final bool domain;
  final bool enabled;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ink = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.4);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadius.pillAll,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              domain ? Icons.domain : Icons.alternate_email,
              size: 18,
              color: ink,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                domain ? '@$value' : value,
                style: theme.textTheme.labelLarge?.copyWith(color: ink),
              ),
            ),
            IconButton(
              onPressed: enabled ? () => onRemove(value) : null,
              tooltip: meetingAccessRemove,
              iconSize: 18,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
