// [파일 위치: lib/pages/guide/field_guide_main_page.dart]
// [페이지 설명: 현장 업무 표준 가이드 메인 리스트 화면 (메뉴판)]

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart'; // 🌟 테마 경로 확인
import 'field_standard_manual_page.dart'; // 🌟 아까 만든 1번 가이드 페이지 불러오기
import 'field_inspection_checklist_page.dart'; // 🌟 2번 체리리스트 페이지 불러오기
import 'field_practical_checklist_page.dart'; // 🚀 [추가] 3번 실전 체크리스트 페이지 (같은 폴더이므로 경로 최적화)
import 'fire_safety_handbook_page.dart'; // 🚨 [추가] 4번 소방시설 자체점검 안내 핸드북 페이지 불러오기

class FieldGuideMainPage extends StatelessWidget {
  const FieldGuideMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
            "현장 업무 표준 가이드",
            style: TextStyle(color: AppTheme.textMain, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textMain),
        elevation: 1,
      ),
      // 🌟 PC/태블릿/모바일 완벽 대응 중앙 정렬
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 4),
                child: Text("SM종합관리 현장 관리 기본 지침서", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              ),

              // 1. 현장 업무 표준 매뉴얼 (방금 만든 PDF 기반 페이지 연결 완료!)
              _buildGuideItem(
                context,
                title: "1. 현장 업무 표준 매뉴얼",
                date: "2026.03.06",
                icon: Icons.rule_folder, // 🌟 순정 규정/폴더 아이콘
                color: Colors.blue,
                destinationPage: const FieldStandardManualPage(),
              ),

              // 2. 건물시설 정기점검 체크리스트
              _buildGuideItem(
                context,
                title: "2. 표준 건물시설 정기점검표\n   (상주/순회)",
                date: "2026.03.06",
                icon: Icons.checklist_rtl, // 🌟 체크리스트 아이콘
                color: Colors.orange,
                destinationPage: const FieldInspectionChecklistPage(), // 🚀 연결 완료!
              ),

              // 3. 업체 관리 가이드 (기존 3번에서 번호 밀림)
              _buildGuideItem(
                context,
                title: "3. 건물 체크리스트",
                date: "2026.03.06",
                icon: Icons.engineering,
                color: Colors.teal,
                destinationPage: const FieldPracticalChecklistPage(),
              ),

              // 👇 🚨 [신규 추가] 4. 소방시설 자체점검 안내 핸드북
              _buildGuideItem(
                context,
                title: "4. 공동주택 소방시설\n   자체점검 안내 설명서",
                date: "2026.03.19", // 최신 업데이트 날짜 적용
                icon: Icons.local_fire_department, // 직관적인 소방(불꽃) 아이콘 적용
                color: Colors.red, // 안전/소방을 의미하는 빨간색 테마
                destinationPage: const FireSafetyHandbookPage(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 가이드 리스트 디자인 위젯
  Widget _buildGuideItem(BuildContext context, {
    required String title,
    required String date,
    required IconData icon,
    required Color color,
    Widget? destinationPage,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.4)
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text("최종 업데이트: $date", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          if (destinationPage != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationPage),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("상세 매뉴얼은 현재 준비 중입니다."))
            );
          }
        },
      ),
    );
  }
}