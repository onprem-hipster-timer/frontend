import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';

/// 2027년 3월 1일 [hour]시 [minute]분(UTC)
DateTime at(int hour, [int minute = 0]) =>
    DateTime.utc(2027, 3, 1, hour, minute);

TimeSpan span(int from, int to) => TimeSpan(at(from), at(to));

void main() {
  group('구간', () {
    test('시작·끝을 UTC로 담아 같은 순간이면 같은 구간이다', () {
      final local = TimeSpan(at(9).toLocal(), at(10).toLocal());
      expect(local, span(9, 10));
      expect(local.start.isUtc, isTrue);
      expect({local, span(9, 10)}, hasLength(1));
    });

    test('끝이 시작보다 뒤가 아니면 빈 구간이다', () {
      expect(span(9, 9).isEmpty, isTrue);
      expect(span(10, 9).isEmpty, isTrue);
      expect(span(9, 10).isEmpty, isFalse);
    });
  });

  group('합치기', () {
    test('겹치거나 맞닿은 구간은 하나로, 떨어진 구간은 따로 시작 순으로 둔다', () {
      expect(
        mergeSpans([span(13, 14), span(9, 10), span(10, 11), span(10, 12)]),
        [span(9, 12), span(13, 14)],
      );
    });

    test('안에 든 구간은 바깥 구간에 흡수되고 같은 구간이 여럿이어도 하나다', () {
      expect(mergeSpans([span(9, 18), span(10, 11), span(9, 18)]), [
        span(9, 18),
      ]);
    });

    test('빈 구간은 버린다', () {
      expect(mergeSpans([span(9, 9), span(11, 10)]), isEmpty);
      expect(mergeSpans(const []), isEmpty);
    });
  });

  group('덮는지', () {
    final merged = mergeSpans([span(9, 12)]);

    test('안에 들거나 경계가 같으면 덮는다', () {
      expect(spansCover(merged, span(9, 12)), isTrue);
      expect(spansCover(merged, span(10, 11)), isTrue);
    });

    test('한쪽 끝이라도 밖으로 나가면 덮지 않는다', () {
      expect(spansCover(merged, span(8, 10)), isFalse);
      expect(spansCover(merged, span(11, 13)), isFalse);
      expect(spansCover(merged, span(12, 13)), isFalse);
    });

    test('맞닿은 두 구간에 걸친 칸은 합친 뒤에만 덮는다', () {
      final pieces = [
        TimeSpan(at(9), at(9, 15)),
        TimeSpan(at(9, 15), at(9, 30)),
      ];
      final cell = TimeSpan(at(9), at(9, 30));
      expect(spansCover(pieces, cell), isFalse);
      expect(spansCover(mergeSpans(pieces), cell), isTrue);
    });
  });

  group('빼기', () {
    test('가운데를 빼면 둘로 나뉜다', () {
      expect(subtractSpans([span(9, 18)], [span(12, 13)]), [
        span(9, 12),
        span(13, 18),
      ]);
    });

    test('끝을 덮는 구간을 빼면 남은 쪽만 남는다', () {
      expect(subtractSpans([span(9, 12)], [span(8, 10)]), [span(10, 12)]);
      expect(subtractSpans([span(9, 12)], [span(11, 13)]), [span(9, 11)]);
    });

    test('모두 덮으면 아무것도 남지 않는다', () {
      expect(subtractSpans([span(9, 12)], [span(9, 12)]), isEmpty);
      expect(
        subtractSpans([span(9, 12)], [span(9, 10), span(10, 12)]),
        isEmpty,
      );
    });

    test('맞닿기만 하거나 떨어진 구간은 아무것도 빼지 않는다', () {
      expect(subtractSpans([span(9, 12)], [span(12, 13), span(7, 9)]), [
        span(9, 12),
      ]);
    });

    test('여러 구간에서 여러 구간을 빼고 남은 것을 합쳐 돌려준다', () {
      expect(
        subtractSpans(
          [span(9, 11), span(10, 12), span(14, 18)],
          [span(10, 11), span(15, 16), span(17, 20)],
        ),
        [span(9, 10), span(11, 12), span(14, 15), span(16, 17)],
      );
    });
  });
}
