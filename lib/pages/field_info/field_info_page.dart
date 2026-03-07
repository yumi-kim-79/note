// [파일 위치: lib/pages/field_info/field_info_page.dart]
// [페이지 설명: 현장 업무 지원 센터 메인 허브 (메뉴판)]
// [업데이트 내역: 반응형 레이아웃 적용 (태블릿/웹 화면 대응), 매뉴얼 페이지 연결]

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../manual/field_manual_page.dart';  // 📚 [추가] 현장 관리 매뉴얼 페이지
import '../safety/field_safety_page.dart'; // 🌟 프로젝트 이름에 상관없이 정확하게 찾아가는 상대 경로
import '../guide/field_guide_main_page.dart'; // 🌟 [추가] 방금 만든 가이드 허브 페이지 불러오기
import '../subcontractor/field_outsource_guide_page.dart'; // 🌟 [추가] 4번: 용역업체 가이드용 새 주소 불러오기
import '../meeting/meeting_hub_page.dart'; // 🌟 허브 페이지로 임포트 변경!

class FieldInfoPage extends StatelessWidget {
  const FieldInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // 🌟 [반응형 개선] Center와 ConstrainedBox를 사용하여 화면이 넓어져도 콘텐츠를 중앙에 모아줍니다.
      body: Center(
        child: ConstrainedBox(
          // 태블릿이나 PC 웹에서는 최대 600px까지만 넓어지도록 제한 (가장 보기 좋은 폭)
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 상단 타이틀 영역
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 20),
                child: Text(
                    "🚧 현장 지원 센터",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain)
                ),
              ),

              // -----------------------------------------------------
              // 1. 현장 대응 매뉴얼 (🌟 매뉴얼 페이지 연결)
              // -----------------------------------------------------
              _buildMenuCard(
                context,
                icon: Icons.menu_book,
                color: Colors.green,
                title: "현장 대응 매뉴얼",
                subtitle: "현장 상황별 대처법 및 가이드라인",
                onTap: () {
                  // 매뉴얼 리스트 페이지로 이동
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FieldManualPage()));
                },
              ),

              // -----------------------------------------------------
              // 2. 현장 업무 시 주의점 (안전 10계명 연결 완료)
              // -----------------------------------------------------
              _buildMenuCard(
                context,
                icon: Icons.warning, // 🌟 [수정] 모바일 100% 호환 순정 경고 아이콘
                color: Colors.orange,
                title: "현장 업무 시 주의점",
                subtitle: "안전 수칙 및 필수 확인 사항",
                onTap: () {
                  // 🚀 방금 만든 안전 관리(Safety) 페이지로 이동!
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FieldSafetyPage())
                  );
                },
              ),

              // -----------------------------------------------------
              // 3. 시설관리 메뉴얼
              // -----------------------------------------------------
              _buildMenuCard(
                context,
                icon: Icons.build_circle,
                color: Colors.purple,
                title: "시설관리 매뉴얼",
                subtitle: "건물 및 시설 유지보수 가이드\n(체크리스트)",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FieldGuideMainPage()), // 🚀 목적지 연결!
                  );
                },
              ),

              // -----------------------------------------------------
              // 4. 용역업체 관리 가이드
              // -----------------------------------------------------
              _buildMenuCard(
                context,
                icon: Icons.engineering, // 🛠️ 용역/외주 업체에 가장 잘 어울리는 헬멧 쓴 엔지니어 아이콘
                color: Colors.teal, // 🎨 세련된 청록색
                title: "용역업체 관리 가이드",
                subtitle: "용역업체 관리 및 보고체계 가이드",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FieldOutsourceGuidePage()), // 🚀 새로운 전용 페이지로 완벽 연결!
                  );
                },
              ),

              // -----------------------------------------------------
              // 🌟 5. 반상회 및 관리단 회의 가이드 (허브로 연결 변경)
              // -----------------------------------------------------
              _buildMenuCard(
                context,
                icon: Icons.groups,
                color: Colors.indigo,
                title: "반상회 및 회의 진행 가이드",
                subtitle: "입주자대표/관리단 회의 준비 및\n분쟁 대처법",
                onTap: () {
                  Navigator.push(
                    context,
                    // 🌟 MeetingGuidePage 대신 MeetingHubPage 로 변경!
                    MaterialPageRoute(builder: (context) => const MeetingHubPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🗇 메뉴 카드 공통 위젯 (디자인 유지)
  Widget _buildMenuCard(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 조금 더 부드러운 곡선
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 왼쪽 아이콘 영역
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              // 중앙 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)
                    ),
                    const SizedBox(height: 4),
                    Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.3)
                    ),
                  ],
                ),
              ),
              // 오른쪽 화살표 아이콘
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // 준비 중 메시지 표시용 스낵바
  void _showReadySnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("현재 준비 중인 메뉴입니다."),
          duration: Duration(seconds: 1),
        )
    );
  }
}