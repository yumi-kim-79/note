// [파일 위치: lib/pages/field_info/field_info_page.dart]
// [페이지 설명: 현장 정보 업무 지원 센터 메인 허브 (메뉴판)]
// [업데이트 내역: 반응형 레이아웃 적용 (태블릿/웹 화면 대응), 매뉴얼 페이지 연결]

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'field_contact_page.dart'; // 📞 공유 전화번호부 페이지
import '../manual/field_manual_page.dart';  // 📚 [추가] 현장 관리 매뉴얼 페이지

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
                    "🚧 현장 업무 지원 센터",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain)
                ),
              ),

              // -----------------------------------------------------
              // 1. 문제해결형 공유 전화번호부 (기능 100% 유지)
              // -----------------------------------------------------
              _buildMenuCard(
                context,
                icon: Icons.contact_phone,
                color: Colors.blue,
                title: "문제해결형 공유 전화번호부",
                subtitle: "증상(태그) 검색, 검증된 업체 전화 연결 및 네이버 검색",
                onTap: () {
                  // 전화번호부 상세 페이지로 이동
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FieldContactPage()));
                },
              ),

              // -----------------------------------------------------
              // 2. 현장 관리 매뉴얼 (🌟 매뉴얼 페이지 연결)
              // -----------------------------------------------------
              _buildMenuCard(
                context,
                icon: Icons.menu_book,
                color: Colors.green,
                title: "현장 관리 매뉴얼",
                subtitle: "현장 상황별 대처법 및 가이드라인",
                onTap: () {
                  // 매뉴얼 리스트 페이지로 이동
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FieldManualPage()));
                },
              ),

              // -----------------------------------------------------
              // 3. 현장 업무 시 주의점 (현재 준비 중)
              // -----------------------------------------------------
              _buildMenuCard(
                context,
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                title: "현장 업무 시 주의점",
                subtitle: "안전 수칙 및 필수 확인 사항",
                onTap: () => _showReadySnackbar(context),
              ),

              // -----------------------------------------------------
              // 4. 시설관리 메뉴얼 (현재 준비 중)
              // -----------------------------------------------------
              _buildMenuCard(
                context,
                icon: Icons.build_circle,
                color: Colors.purple,
                title: "시설관리 매뉴얼",
                subtitle: "건물 및 시설 유지보수 가이드",
                onTap: () => _showReadySnackbar(context),
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