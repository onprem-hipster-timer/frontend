import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_access.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_edit_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../meeting_fixtures.dart';

/// DELETE에 정한 상태와 본문으로 답하는 백엔드
class _DeleteBackend implements HttpClientAdapter {
  _DeleteBackend(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: {
      if (body.isNotEmpty) Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

DioException invalid(List<Object?> detail) => httpError(
  '/v1/meetings/meeting-1',
  422,
  data: {'error_type': 'InvalidMeetingError', 'detail': detail},
);

void main() {
  late List<String> calls;
  late FakeMeetingsClient meetings;
  late FakeVisibilityClient visibility;
  late MeetingEditRequests requests;

  setUp(() {
    calls = [];
    meetings = FakeMeetingsClient(
      meeting: makeMeeting(ownerId: 'user-1').copyWith(allowGuests: true),
      calls: calls,
    );
    visibility = FakeVisibilityClient(calls: calls)
      ..current = visibilityOf(VisibilityLevel.public);
    requests = MeetingEditRequests(meetings, visibility);
  });

  Future<MeetingEditSource> load() async =>
      (await requests.load('meeting-1', userId: 'user-1'))!;

  group('불러오기', () {
    test('주인이면 미팅, 공개 범위, 답이 있는지를 읽는다', () async {
      meetings.availability = [
        availabilityOf('p1'),
        availabilityOf(
          'p2',
          slots: [(DateTime.utc(2027, 3, 1), DateTime.utc(2027, 3, 1, 1))],
        ),
      ];
      final source = await load();
      expect(source.base.meeting.title, '팀 회의');
      expect(source.base.audience.level, VisibilityLevel.public);
      expect(source.hasAnswers, isTrue);
    });

    test('아무도 시간을 넣지 않았으면 답이 없다', () async {
      meetings.availability = [availabilityOf('p1')];
      expect((await load()).hasAnswers, isFalse);
    });

    test('주인이 아니면 null이고 공개 범위를 읽지 않는다', () async {
      expect(await requests.load('meeting-1', userId: 'user-2'), isNull);
      expect(await requests.load('meeting-1', userId: null), isNull);
      expect(visibility.reads, 0);
    });

    test('공개 범위를 정한 적이 없으면(404) 미팅의 수준, 그것도 없으면 나만이다', () async {
      visibility.current = null;
      meetings.meeting = meetings.meeting!.copyWith(
        visibilityLevel: VisibilityLevel.allowedEmails,
      );
      expect((await load()).base.audience.level, VisibilityLevel.allowedEmails);

      meetings.meeting = meetings.meeting!.copyWith(visibilityLevel: null);
      expect((await load()).base.audience.level, VisibilityLevel.private);
    });

    test('공개 범위를 읽지 못하면(404 밖) 실패한다', () async {
      visibility.getError = httpError('/v1/visibility', 500);
      await expectLater(load(), throwsA(isA<DioException>()));
    });
  });

  group('저장하기', () {
    Future<(MeetingEditBase, List<MeetingEditStep>)> privatePlan({
      String title = '팀 회의',
    }) async {
      final base = (await load()).base;
      final next = base.draft
          .withPublic(false)
          .withAccessEntry(parseMeetingAccessEntry('kim@example.com')!);
      return (base, base.plan(next, title: title)!);
    }

    test('차례대로 보내고 모두 저장했으면 끝난 값을 돌려준다', () async {
      final (base, steps) = await privatePlan(title: '비밀 회의');
      final outcome = await requests.save(base, steps);

      expect(calls, [
        'update {title: 비밀 회의, allow_guests: false}',
        'visibility allowedEmails',
      ]);
      expect(outcome.complete, isTrue);
      expect(outcome.saved, {
        MeetingEditPart.title,
        MeetingEditPart.guests,
        MeetingEditPart.visibility,
      });
      expect(outcome.base.meeting.title, '비밀 회의');
      expect(outcome.base.audience.emails, ['kim@example.com']);
    });

    test('뒤 요청이 실패하면 앞에서 저장한 것과 못 한 것을 나누고 서버 값을 다시 읽는다', () async {
      final (base, steps) = await privatePlan(title: '비밀 회의');
      visibility.setError = httpError('/v1/visibility', 500);
      final reads = meetings.reads.length;
      final outcome = await requests.save(base, steps);

      expect(outcome.complete, isFalse);
      expect(outcome.saved, {MeetingEditPart.title, MeetingEditPart.guests});
      expect(outcome.unsaved, {MeetingEditPart.visibility});
      expect(meetings.reads.length, reads + 1);
      expect(outcome.base.meeting.title, '비밀 회의');
      expect(outcome.base.meeting.allowGuests, isFalse);
      expect(outcome.base.audience.level, VisibilityLevel.public);
      expect(
        meetingEditOutcomeText(outcome),
        '제목·게스트 로그인은 저장했어요. 공개 범위는 저장하지 못했어요. 잠시 뒤 다시 시도해 주세요',
      );
    });

    test('첫 요청이 실패하면 뒤 요청은 보내지 않고 아무것도 저장하지 않았다고 한다', () async {
      final (base, steps) = await privatePlan();
      meetings.updateError = DioException(
        requestOptions: RequestOptions(path: '/v1/meetings/meeting-1'),
        type: DioExceptionType.connectionError,
      );
      final outcome = await requests.save(base, steps);

      expect(calls, ['update {allow_guests: false}']);
      expect(outcome.saved, isEmpty);
      expect(outcome.unsaved, {
        MeetingEditPart.guests,
        MeetingEditPart.visibility,
      });
      expect(meetingEditOutcomeText(outcome), '저장하지 못했어요. 네트워크 연결을 확인해 주세요');
    });

    test('다시 읽지 못하면 받은 응답으로 맞춘 값이다', () async {
      final (base, steps) = await privatePlan(title: '비밀 회의');
      visibility.setError = httpError('/v1/visibility', 500);
      visibility.getError = httpError('/v1/visibility', 500);
      final outcome = await requests.save(base, steps);

      expect(outcome.base.meeting.title, '비밀 회의');
      expect(outcome.base.audience.level, VisibilityLevel.public);
    });
  });

  group('서버의 거절', () {
    MeetingEditOutcome refused(Object error, Set<MeetingEditPart> unsaved) =>
        MeetingEditOutcome(
          base: MeetingEditBase(
            meeting: makeMeeting(),
            audience: const MeetingAudience(VisibilityLevel.public),
          ),
          unsaved: unsaved,
          error: error,
        );

    const fields = {
      MeetingEditPart.title,
      MeetingEditPart.dates,
      MeetingEditPart.time,
    };

    test('검사 오류의 칸 이름(loc, field, 이름 글자)으로 거절된 것을 고른다', () {
      expect(
        meetingEditRefused(
          refused(
            invalid([
              {
                'loc': ['body', 'end_date'],
                'msg': 'x',
              },
            ]),
            fields,
          ),
        ),
        {MeetingEditPart.dates},
      );
      expect(
        meetingEditRefused(
          refused(
            invalid([
              {'field': 'start_time'},
              'title',
            ]),
            fields,
          ),
        ),
        {MeetingEditPart.time, MeetingEditPart.title},
      );
    });

    test('보내지 않은 것을 가리키거나 칸 이름이 없으면 하나만 보낸 때만 그것이다', () {
      expect(
        meetingEditRefused(
          refused(
            invalid([
              {
                'loc': ['body', 'mode'],
              },
            ]),
            fields,
          ),
        ),
        isEmpty,
      );
      expect(
        meetingEditRefused(refused(invalid([]), {MeetingEditPart.visibility})),
        {MeetingEditPart.visibility},
      );
    });

    test('검사 오류가 아니면 칸을 고르지 않는다', () {
      expect(
        meetingEditRefused(
          refused(httpError('/v1/meetings', 500), {MeetingEditPart.title}),
        ),
        isEmpty,
      );
    });

    test('거절된 칸이 있으면 표시한 칸을, 없으면 바꿀 수 없는 값이 있다고 알린다', () {
      expect(
        meetingEditOutcomeText(
          refused(
            invalid([
              {
                'loc': ['body', 'end_date'],
              },
            ]),
            fields,
          ),
        ),
        '저장하지 못했어요. 표시한 칸을 확인해 주세요',
      );
      expect(
        meetingEditOutcomeText(refused(invalid(['description']), fields)),
        '저장하지 못했어요. 바꿀 수 없는 값이 있어요',
      );
    });
  });

  group('지우기', () {
    Future<void> deleteWith(int status, String body) {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = _DeleteBackend(status, body);
      return MeetingEditRequests(
        MeetingsClient(dio),
        visibility,
      ).delete('meeting-1');
    }

    test('본문이 있든 없든 2xx면 끝난다', () async {
      await deleteWith(204, '');
      await deleteWith(200, '{"ok": true}');
      await deleteWith(202, '');
    });

    test('2xx가 아니면 실패한다', () async {
      await expectLater(
        deleteWith(403, '{"error_type": "x"}'),
        throwsA(isA<DioException>()),
      );
    });
  });

  test('불러온 값 그대로면 보낼 요청이 없다', () async {
    final base = (await load()).base;
    expect(base.plan(base.draft, title: '팀 회의'), isEmpty);
  });
}
