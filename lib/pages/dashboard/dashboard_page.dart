// [파일 위치: lib/pages/dashboard/dashboard_page.dart]
// 대시보드 메인페이지
// 1. [UX 고도화] StatefulWidget 유지 및 메뉴 재클릭 시 refreshData() 기능 100% 유지
// 2. [구조 개선] PC 모드에서 Infinity height 에러 방지 로직(safeHeight) 유지
// 3. [반응형] 부모-자식 간 Breakpoint(900px)를 MediaQuery로 통일하여 렌더링 충돌 원천 차단
// 4. [🌟스크롤 고도화] 모바일에서 자식 위젯의 터치 간섭을 무시하고 부모 스크롤이 우선권을 갖도록 환경 설정

import 'package:flutter/material.dart';
import 'widgets/notice_board.dart';
import 'widgets/recent_sales.dart';
import 'widgets/custom_calendar.dart';

// ✅ 디자인 시스템 import
import '../../theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  // ✅ 새로고침을 위한 고유 키 생성 (기능 유지)
  Key _refreshKey = UniqueKey();

  // ✅ 외부(main.dart)에서 호출하는 새로고침 함수 (기능 유지)
  void refreshData() {
    if (!mounted) return;
    setState(() {
      _refreshKey = UniqueKey();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("대시보드 데이터를 최신화했습니다."),
        duration: Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 [분석 결과 반영] 자식 위젯들과 100% 동일한 기준으로 화면 크기 판별
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth >= 900;

    return Container(
      key: _refreshKey,
      // 배경색을 명시하여 스크롤 시 빈 공간이 어색하지 않게 처리
      color: AppTheme.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // =======================================================
            // [에러 방어] PC 모드 높이 계산 (기존 로직 유지)
            // =======================================================
            double safeHeight = constraints.maxHeight;
            if (safeHeight == double.infinity) {
              safeHeight = MediaQuery.of(context).size.height - 120;
              if (safeHeight < 600) safeHeight = 600;
            }

            // -------------------------------------------------------
            // [웹/PC 모드] 900px 이상일 때 (가로 배치)
            // -------------------------------------------------------
            if (isWideScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: safeHeight,
                      child: Column(
                        children: [
                          const Expanded(flex: 5, child: NoticeBoard()),
                          const SizedBox(height: 24),
                          const Expanded(flex: 5, child: RecentSales()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: safeHeight,
                      child: const CustomCalendar(),
                    ),
                  ),
                ],
              );
            }

            // -------------------------------------------------------
            // [모바일/태블릿 모드] 900px 미만일 때 (세로 배치 + 전체 스크롤)
            // -------------------------------------------------------
            else {
              return ScrollConfiguration(
                // 파란색 물결 효과 등 모바일 특유의 스크롤 효과를 깔끔하게 조정
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: SingleChildScrollView(
                  // 🌟 [핵심] 사용자가 어디를 만지든 부모 스크롤이 즉각 반응하도록 물리 엔진 설정
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()
                  ),
                  child: Column(
                    // 모바일에서는 내용물만큼만 높이를 차지하도록 설정 (중요)
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. 공지사항
                      const NoticeBoard(),
                      const SizedBox(height: 24),

                      // 2. 최근 영업 활동
                      const RecentSales(),
                      const SizedBox(height: 24),

                      // 3. 캘린더 (모바일은 높이 고정 유지)
                      const SizedBox(height: 750, child: CustomCalendar()),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}