// [파일 위치: lib/pages/field_info/field_manual_page.dart]
// [페이지 설명: 현장 관리 매뉴얼 리스트 화면]
// [기능: 상황별 대응 매뉴얼 목록 조회 및 상세보기 연결]

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FieldManualPage extends StatelessWidget {
  const FieldManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
            "현장 관리 매뉴얼",
            style: TextStyle(color: AppTheme.textMain, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textMain),
        elevation: 1,
      ),
      // 🌟 태블릿/웹 대응을 위해 중앙 정렬 및 폭 제한 적용
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 4),
                child: Text("필독 매뉴얼", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              ),

              // 📝 매뉴얼 항목들 (나중에는 파이어베이스 DB에서 불러오게 업데이트 할 예정입니다)
              _buildManualItem(
                  context,
                  title: "누수 발생 시 단지 내 초기 대응 매뉴얼",
                  date: "2026.03.01",
                  icon: Icons.water_drop,
                  color: Colors.blue
              ),
              _buildManualItem(
                  context,
                  title: "동절기 배관 동파 방지 및 해빙 가이드",
                  date: "2025.12.10",
                  icon: Icons.ac_unit,
                  color: Colors.lightBlueAccent
              ),
              _buildManualItem(
                  context,
                  title: "승강기 오작동 및 갇힘 사고 행동 요령",
                  date: "2025.09.15",
                  icon: Icons.elevator,
                  color: Colors.orange
              ),
              _buildManualItem(
                  context,
                  title: "정전 및 발전기 기동 확인 매뉴얼",
                  date: "2025.07.20",
                  icon: Icons.electric_bolt,
                  color: Colors.amber
              ),
            ],
          ),
        ),
      ),
      // 관리자용 매뉴얼 등록 버튼 (추후 기능 연결)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("매뉴얼 등록 기능은 준비 중입니다."))
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 📝 매뉴얼 리스트 디자인 위젯
  Widget _buildManualItem(BuildContext context, {
    required String title,
    required String date,
    required IconData icon,
    required Color color,
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
          // 상세 매뉴얼 내용 보기 (다음 스텝에서 구현)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("상세 내용은 현재 준비 중입니다."))
          );
        },
      ),
    );
  }
}