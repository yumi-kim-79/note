// [파일 위치: lib/pages/dashboard/dashboard_page.dart]
// 수정 내용:
// 1. [UX 고도화] StatefulWidget으로 전환 및 메뉴 재클릭 시 refreshData() 기능 추가
// 2. [구조 개선] PC 모드에서 Expanded 중첩으로 인한 하단 터짐 오류 해결 로직 유지
// 3. [반응형] LayoutBuilder를 활용한 웹(Row) / 모바일(Column) 완벽 전환 로직 유지

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
    // ✅ 최상단에 Key를 연결하여 새로고침 시 모든 하위 위젯(공지사항, 달력 등)이 최신 데이터를 다시 불러오게 함
    return Container(
      key: _refreshKey,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // -------------------------------------------------------
            // [웹/PC 모드] 화면이 900px보다 넓을 때
            // -------------------------------------------------------
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측 구역 (공지사항 + 최근영업)
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: constraints.maxHeight,
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
                      height: constraints.maxHeight,
                      child: const CustomCalendar(),
                    ),
                  ),
                ],
              );
            }

            // -------------------------------------------------------
            // [모바일/태블릿 모드] 화면이 좁을 때 (위아래 배치)
            // -------------------------------------------------------
            else {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 1. 공지사항
                    const SizedBox(height: 400, child: NoticeBoard()),
                    const SizedBox(height: 24),

                    // 2. 최근 영업 활동
                    const SizedBox(height: 400, child: RecentSales()),
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