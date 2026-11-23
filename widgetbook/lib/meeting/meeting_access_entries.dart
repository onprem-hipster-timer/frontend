import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_access.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_access_entries.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _filled = ['momo@example.com', 'tokki@example.com', 'example.org'];

const _long = [
  'gomdori.and.friends.weekly.meetup@example.com',
  'daramjwi.very.long.nickname.for.testing@example.net',
  'research-lab.department-of-design.example.ac.kr',
  'example.org',
];

@widgetbook.UseCase(
  name: '참여할 사람 이메일 넣기',
  type: MeetingAccessEntries,
  path: '[모임]/모임 만들기',
)
Widget meetingAccessEntries(BuildContext context) {
  final knobs = context.knobs;
  final preset = knobs.object.dropdown(
    label: '넣은 것',
    options: const ['없음', '이메일 둘·도메인 하나', '긴 주소 여러 개'],
    initialOption: '이메일 둘·도메인 하나',
  );
  final enabled = knobs.boolean(
    label: '고칠 수 있음',
    initialValue: true,
    description: '모임 설정을 저장하는 중에는 칸과 빼기 단추를 누를 수 없다',
  );
  final width = knobs.double.slider(
    label: '폭',
    description: '280보다 좁으면 추가 단추가 칸 아래 오른쪽으로 내려간다',
    initialValue: 328,
    min: 200,
    max: 560,
    divisions: 36,
    precision: 0,
  );
  final entries = switch (preset) {
    '없음' => const <String>[],
    '긴 주소 여러 개' => _long,
    _ => _filled,
  };
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: SizedBox(
        width: width,
        child: _EntriesHost(
          key: ValueKey(preset),
          initial: entries,
          enabled: enabled,
        ),
      ),
    ),
  );
}

/// 추가·빼기가 화면에 바로 보이도록 넣은 것을 쥔다
class _EntriesHost extends StatefulWidget {
  const _EntriesHost({super.key, required this.initial, required this.enabled});

  final List<String> initial;
  final bool enabled;

  @override
  State<_EntriesHost> createState() => _EntriesHostState();
}

class _EntriesHostState extends State<_EntriesHost> {
  late var _entries = [
    for (final value in widget.initial) ?parseMeetingAccessEntry(value),
  ];

  @override
  Widget build(BuildContext context) => MeetingAccessEntries(
    emails: [
      for (final entry in _entries)
        if (!entry.domain) entry.value,
    ],
    domains: [
      for (final entry in _entries)
        if (entry.domain) entry.value,
    ],
    enabled: widget.enabled,
    onAdd: (entry) => setState(() => _entries = [..._entries, entry]),
    onRemove: (value) => setState(
      () => _entries = [
        for (final entry in _entries)
          if (entry.value != value) entry,
      ],
    ),
  );
}
