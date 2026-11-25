import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/trial/presentation/utils/trial_preview_kind.dart';

/// 랜딩·모임 소개의 미리보기 칸(`data-preview`)은 배포 때 tool/landing_previews/capture.mjs가 그 width·height로
/// 미리보기 화면(`/demo/preview?kind=<종류>`)을 찍어 채운다. 찍기는 배포에서만 돌므로 칸을 여기서 확인한다.
void main() {
  final html = File('web/index.html').readAsStringSync();
  final pages = {
    for (final path in ['web/index.html', 'web/meet.html'])
      path: RegExp(
        r'<(?:img|source)\b[^>]*\bdata-preview="[^"]*"[^>]*>',
      ).allMatches(File(path).readAsStringSync()).map((m) => m[0]!).toList(),
  };
  final slots = pages.values.expand((tags) => tags).toList();

  String? attr(String tag, String name) =>
      RegExp('\\s$name="([^"]*)"').firstMatch(tag)?[1];

  // 미리보기 화면이 줄이거나 빈 띠 없이 그리는 크기(논리 픽셀)
  const widths = (272, 480);
  const heights = {
    TrialPreviewKind.calendar: (200, 260),
    TrialPreviewKind.todo: (88, 200),
    TrialPreviewKind.timer: (300, 460),
    TrialPreviewKind.meeting: (599, 1100),
  };

  // 모임 화면 그림은 폭 360 휴대폰 화면을 칸의 폭에 맞게 줄이므로, 격자와 추천 시간 제목까지 들려면 높이가 폭의
  // 이만큼은 되어야 한다
  const meetingMinRatio = 2.2;

  // 랜딩의 기능 소개 카드마다 있는 종류
  const bentoKinds = {'calendar', 'todo', 'timer'};

  final kinds = slots.map((tag) => attr(tag, 'data-preview')).toSet();
  final landingKinds = pages['web/index.html']!
      .map((tag) => attr(tag, 'data-preview'))
      .toSet();

  test('미리보기 칸의 종류는 미리보기 화면이 아는 이름이고 기능 소개의 세 종류가 모두 있다', () {
    expect(TrialPreviewKind.values.map((k) => k.name), containsAll(kinds));
    expect(landingKinds, containsAll(bentoKinds));
  });

  test('미리보기 칸마다 미리보기 화면이 그릴 수 있는 정수 폭·높이가 있다', () {
    for (final tag in slots) {
      final kind = TrialPreviewKind.values.byName(attr(tag, 'data-preview')!);
      final width = int.tryParse(attr(tag, 'width') ?? '');
      final height = int.tryParse(attr(tag, 'height') ?? '');
      final (minHeight, maxHeight) = heights[kind]!;
      expect(width, isNotNull, reason: tag);
      expect(height, isNotNull, reason: tag);
      expect(width, inInclusiveRange(widths.$1, widths.$2), reason: tag);
      expect(height, inInclusiveRange(minHeight, maxHeight), reason: tag);
      if (kind == TrialPreviewKind.meeting) {
        expect(
          height,
          greaterThanOrEqualTo(width! * meetingMinRatio),
          reason: tag,
        );
      }
    }
  });

  test('미리보기 그림에는 무엇을 보이는지 적은 대체 글이 있다', () {
    final images = slots.where((tag) => tag.startsWith('<img'));
    expect(images, isNotEmpty);
    for (final tag in images) {
      expect(attr(tag, 'alt')?.trim(), isNotEmpty, reason: tag);
    }
  });

  test('기능 소개의 카드마다 체험하기 링크가 있다', () {
    final start = html.indexOf('<section class="bento"');
    final section = html.substring(start, html.indexOf('</section>', start));
    final cards = section
        .split(RegExp(r'<div class="bento-card(?: wide)?">'))
        .skip(1)
        .toList();
    expect(cards, hasLength(3));
    for (final card in cards) {
      expect(card, contains('href="/demo"'));
    }
  });
}
