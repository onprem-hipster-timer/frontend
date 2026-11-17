import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 앞의 답을 바꿔 묻지 않고 맞춘 것([adjusted])을 지금 질문 위에 알린다. 나타나거나 바뀌면 스크린 리더에도
/// 알린다
class MeetingAdjustmentNotice extends StatefulWidget {
  const MeetingAdjustmentNotice({
    super.key,
    required this.adjusted,
    required this.draft,
  });

  final Set<MeetingAdjustment> adjusted;
  final MeetingDraft draft;

  @override
  State<MeetingAdjustmentNotice> createState() =>
      _MeetingAdjustmentNoticeState();
}

class _MeetingAdjustmentNoticeState extends State<MeetingAdjustmentNotice> {
  List<String> get _lines => [
    for (final adjustment in MeetingAdjustment.values)
      if (widget.adjusted.contains(adjustment))
        meetingAdjustmentText(adjustment, widget.draft),
  ];

  @override
  void initState() {
    super.initState();
    _announce();
  }

  @override
  void didUpdateWidget(MeetingAdjustmentNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.adjusted, widget.adjusted)) _announce();
  }

  void _announce() {
    final text = _lines.join(' ');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || text.isEmpty) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        text,
        Directionality.of(context),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppRadius.lgAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_fix_high_outlined,
              size: 20,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in _lines)
                    Text(
                      keepWords(line),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
