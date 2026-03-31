import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 떠있는(Floating) 하단 네비게이션 바가 있는 스캐폴드
///
/// Stack을 사용하여 컨텐츠 위에 알약(Pill) 모양의 둥근 네비게이션 바를 띄웁니다.
/// go_router의 StatefulShellRoute와 함께 사용하도록 설계되었습니다.
class ScaffoldWithNavBar extends StatelessWidget {
  /// 네비게이션 쉘 (페이지 컨텐츠)
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ============================================================
          // Body Layer - 페이지 컨텐츠
          // ============================================================
          Positioned.fill(
            child: Container(
              // 하단 네비게이션 바가 컨텐츠를 가리지 않도록 패딩 적용
              padding: const EdgeInsets.only(bottom: 100),
              child: navigationShell,
            ),
          ),

          // ============================================================
          // Navigation Layer - 떠있는 네비게이션 바
          // ============================================================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFloatingNavBar(context),
          ),
        ],
      ),
    );
  }

  /// 떠있는 알약 모양 네비게이션 바 위젯
  Widget _buildFloatingNavBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      // 화면 양쪽과 하단에서 여백을 두어 "떠있는" 효과 연출
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        // 라이트/다크 모드에 따른 배경색
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        // 완벽한 알약(Pill) 모양을 위한 둥근 모서리
        borderRadius: BorderRadius.circular(30),
        // 입체감을 주는 그림자 효과
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        // 컨테이너와 동일한 둥근 모서리로 자식 위젯 클리핑
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          // ============================================================
          // 기본 BottomNavigationBar 설정
          // ============================================================
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed, // 5개 아이템 고정 배치
          elevation: 0, // 컨테이너의 그림자를 사용하므로 기본 elevation 제거
          backgroundColor: Colors.transparent, // 투명하게 설정 (컨테이너 색상 사용)

          // ============================================================
          // 레이블 숨김 설정 (아이콘만 표시)
          // ============================================================
          showSelectedLabels: false,
          showUnselectedLabels: false,

          // ============================================================
          // 아이콘 색상 설정
          // ============================================================
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: Colors.grey,

          // ============================================================
          // 5개 탭 아이템 정의
          // ============================================================
          items: const [
            // 1. 캘린더 탭
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded, size: 28),
              label: 'Calendar',
              tooltip: '캘린더',
            ),

            // 2. 할 일 탭
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline_rounded, size: 28),
              label: 'Todo',
              tooltip: '할 일',
            ),

            // 3. 타이머 탭
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_rounded, size: 28),
              label: 'Timer',
              tooltip: '타이머',
            ),

            // 4. 태그 탭
            BottomNavigationBarItem(
              icon: Icon(Icons.label_outline_rounded, size: 28),
              label: 'Tags',
              tooltip: '태그',
            ),

            // 5. 마이페이지 탭
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 28),
              label: 'MyPage',
              tooltip: '마이페이지',
            ),
          ],
        ),
      ),
    );
  }

  /// 탭 선택 시 호출되는 콜백
  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // 같은 탭을 다시 탭하면 해당 브랜치의 루트로 이동
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
