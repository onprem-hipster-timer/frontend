typedef StressText = ({String label, String value});

/// 레이아웃을 깨뜨리기 쉬운 입력 문자열.
abstract final class StressTexts {
  static const StressText koreanLong = (
    label: '한국어 긴 문장',
    value: '다음 주 월요일 오전 회의 전까지 분기별 매출 보고서 초안을 검토하고 팀장님께 의견을 정리해서 공유하기',
  );
  static const StressText latinUnbroken = (
    label: '띄어쓰기 없는 영문',
    value: 'quarterly_report_final_v2_reviewed_by_design_team',
  );
  static const StressText emoji = (
    label: '이모지',
    value: '🔥 마감 임박 🚀✨ 출시 준비 🎉🎉🎉 체크리스트 ✅✅',
  );
  static const StressText numeric = (
    label: '숫자',
    value: '2026-11-09 v1.23.456 #12345678901234567890',
  );

  static const all = [koreanLong, latinUnbroken, emoji, numeric];
}
