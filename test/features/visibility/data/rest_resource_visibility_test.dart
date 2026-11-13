import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/visibility/data/rest_resource_visibility.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../helpers/fake_rest_clients.dart';

void main() {
  late FakeVisibilityClient client;
  late RestResourceVisibility schedule;

  setUp(() {
    client = FakeVisibilityClient();
    schedule = RestResourceVisibility(client, ResourceType.schedule, 's-1');
  });

  test('설정이 없으면(404) null이다', () async {
    expect(await schedule.load(), isNull);
    expect(client.calls, ['get:schedule/s-1']);
  });

  test('저장된 설정을 그 리소스 종류와 id로 읽는다', () async {
    client.put(
      ResourceType.schedule,
      's-1',
      const VisibilityUpdate(level: VisibilityLevel.friends),
    );
    client.put(
      ResourceType.todo,
      's-1',
      const VisibilityUpdate(level: VisibilityLevel.selected),
    );

    expect((await schedule.load())?.level, VisibilityLevel.friends);
  });

  test('404가 아닌 오류는 그대로 던진다', () async {
    client.readError = httpError('/v1/visibility/schedule/s-1', 403);

    await expectLater(schedule.load(), throwsA(isA<Object>()));
  });

  test('저장은 PUT, 지우기는 DELETE로 보낸다', () async {
    const update = VisibilityUpdate(
      level: VisibilityLevel.allowedEmails,
      allowedEmails: ['a@b.com'],
      allowedDomains: [],
    );
    await schedule.save(update);
    await schedule.clear();

    expect(client.calls, ['put:schedule/s-1', 'delete:schedule/s-1']);
    expect(client.saved, [update]);
    expect(client.settings, isEmpty);
  });
}
