import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/marquee_text.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '흐르는 긴 이름', type: MarqueeText, path: '[달력]')
Widget marqueeText(BuildContext context) {
  final knobs = context.knobs;
  final place = knobs.object.dropdown(
    label: '쓰이는 곳',
    description: '공휴일 이름은 월 보기 칸에서 두 번 흐른 뒤 멈추고, 일정 칩은 마우스를 올린 동안 계속 흐른다',
    options: const ['공휴일 이름', '일정 칩'],
  );
  final holiday = place == '공휴일 이름';
  final text = knobs.string(label: '글자', initialValue: '부처님 오신 날 대체공휴일');
  final active = knobs.boolean(
    label: '흐르기',
    description: '끄면 칸에 맞춰 말줄임으로 줄인다',
    initialValue: true,
  );
  final width = knobs.double.slider(
    label: '칸 폭',
    description: '폭 360 화면의 월 보기 칸은 약 50',
    initialValue: 50,
    min: 30,
    max: 240,
    divisions: 42,
    precision: 0,
  );
  final colors = AppColors.of(context);
  const chipColor = Color(0xFF3F51B5);
  return Center(
    child: SizedBox(
      width: width,
      child: holiday
          ? MarqueeText(
              text,
              active: active,
              loops: 2,
              style: TextStyle(
                color: colors.holiday,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            )
          // 월 보기 일정 칩과 같은 바탕·글자
          : Container(
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.9),
                borderRadius: AppRadius.xsAll,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: MarqueeText(
                text,
                active: active,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
    ),
  );
}
