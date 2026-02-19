// [파일 위치: lib/pages/dashboard/dashboard_page.dart]
// 수정 내용:
// 1. [UX 고도화] StatefulWidget으로 전환 및 메뉴 재클릭 시 refreshData() 기능 추가
// 2. [구조 개선] PC 모드에서 Expanded 중첩으로 인한 하단 터짐 오류 해결 로직 유지
// 3. [반응형] LayoutBuilder를 활용한 웹(Row) / 모바일(Column) 완벽 전환 로직 유지
// 4. [Fix] PC 모드에서 부모 위젯이 무한대 높이(Infinity)를 줄 경우 화면이 하얗게 뻗는 렌더링 에러 완벽 방어
// 5. [🌟핵심 Fix] 자식 위젯(notice_board, recent_sales)과 반응형(PC/모바일) 판별 기준을 통일하여 렌더링 충돌(하얀 화면) 영구 해결

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
  // ✅ 새로고침을 위한 고유 키 생성 (UniqueKey가 바뀔 때마다 하위 위젯들이 초기화됩니다)
  Key _refreshKey = UniqueKey();

  // ✅ 외부(main.dart)에서 메뉴 중복 클릭 시 호출할 새로고침 함수
  void refreshData() {
    if (!mounted) return;
    setState(() {
      _refreshKey = UniqueKey(); // 키를 변경하여 페이지 전체를 강제로 다시 그림
    });

    // 사용자 알림용 스낵바
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
    // 🌟 [핵심 변경 포인트]
    // 자식 위젯들과 똑같이 '브라우저 전체 넓이'를 기준으로 PC/모바일을 판별합니다.
    // 이전처럼 constraints.maxWidth를 쓰면 사이드바 너비 때문에 부모와 자식의 기준이 어긋나 화면이 터졌습니다.
    final bool isWideScreen = MediaQuery.of(context).size.width >= 900;

    // ✅ 최상단에 Key를 연결하여 새로고침 시 모든 하위 위젯(공지사항, 달력 등)이 최신 데이터를 다시 불러오게 함
    return Container(
      key: _refreshKey,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // =======================================================
            // [에러 방어 코드] 부모가 무한대(Infinity) 높이를 줄 경우
            // MediaQuery를 이용해 화면 사이즈 기반의 안전한 높이 계산
            // =======================================================
            double safeHeight = constraints.maxHeight;
            if (safeHeight == double.infinity) {
              // 상단 헤더나 여백을 고려해 브라우저 창 높이에서 약 120 픽셀을 뺌
              safeHeight = MediaQuery.of(context).size.height - 120;
              // 화면을 너무 작게 줄였을 때 위젯이 깨지지 않도록 최소 높이 600 보장
              if (safeHeight < 600) safeHeight = 600;
            }

            // -------------------------------------------------------
            // [웹/PC 모드] 전체 화면이 900px 이상일 때 (통일된 기준)
            // -------------------------------------------------------
            if (isWideScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측 구역 (공지사항 + 최근영업)
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      // 🚨 에러 원인이었던 constraints.maxHeight 대신 safeHeight 사용
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

                  // 우측 구역 (달력)
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      // 🚨 동일하게 safeHeight 적용
                      height: safeHeight,
                      child: const CustomCalendar(),
                    ),
                  ),
                ],
              );
            }

            // -------------------------------------------------------
            // [모바일/태블릿 모드] 전체 화면이 900px 미만일 때 (위아래 배치)
            // -------------------------------------------------------
            else {
              return SingleChildScrollView(
                // ✅ [스크롤 고도화 1] 메인 화면이 항상 스크롤 우선권을 가지도록 강력한 물리 엔진 장착
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  children: [
                    // 1. 공지사항
                    const NoticeBoard(),
                    const SizedBox(height: 24),

                    // 2. 최근 영업 활동
                    const RecentSales(),
                    const SizedBox(height: 24),

                    // 3. 캘린더
                    const SizedBox(height: 750, child: CustomCalendar()),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}