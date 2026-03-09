// [파일 위치: lib/pages/manual/field_manual_page.dart]
// [페이지 설명: 현장 관리 매뉴얼 리스트 화면 (본사 통제형 하드코딩 리스트)]

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'leakage_manual_page.dart';
import 'freeze_manual_page.dart';
import 'elevator_manual_page.dart';
import 'blackout_manual_page.dart';
import 'fire_manual_page.dart';
import 'parking_tower_manual_page.dart';
import 'cctv_manual_page.dart';
import 'defect_manual_page.dart';

class FieldManualPage extends StatelessWidget {
  const FieldManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
            "현장 대응 매뉴얼",
            style: TextStyle(color: AppTheme.textMain, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textMain),
        elevation: 1,
      ),
      // 🌟 태블릿/웹/모바일 모두 완벽 대응하는 중앙 정렬 및 폭 제한
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 4),
                child: Text("SM종합관리 표준 대응 매뉴얼", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              ),

              // 1. 누수 매뉴얼
              _buildManualItem(
                context,
                title: "1. 누수 발생 시 단지 내\n  초기 대응 매뉴얼",
                date: "2026.03.05",
                icon: Icons.opacity, // 🌟 [수정] 모바일 100% 호환 순정 물방울 아이콘
                color: Colors.blue,
                destinationPage: const LeakageManualPage(),
              ),

              // 2. 동파 매뉴얼
              _buildManualItem(
                context,
                title: "2. 동절기 배관 동파 방지 및\n  해빙 매뉴얼",
                date: "2026.03.05",
                icon: Icons.ac_unit, // 🌟 눈송이 순정 (안전함)
                color: Colors.lightBlueAccent,
                destinationPage: const FreezeManualPage(),
              ),

              // 3. 승강기 매뉴얼
              _buildManualItem(
                context,
                title: "3. 승강기 오작동 및 \n  갇힘 사고발생시 매뉴얼",
                date: "2026.03.05",
                icon: Icons.unfold_more, // 🌟 [수정] 모바일 100% 호환 상하(승강기) 순정 아이콘
                color: Colors.orange,
                destinationPage: const ElevatorManualPage(),
              ),

              // 4. 정전 매뉴얼
              _buildManualItem(
                context,
                title: "4. 정전 및 발전기 기동 확인\n  매뉴얼",
                date: "2026.03.05",
                icon: Icons.flash_on, // 🌟 [수정] 모바일 100% 호환 번개 순정 아이콘
                color: Colors.amber,
                destinationPage: const BlackoutManualPage(),
              ),

              // 5. 소방 매뉴얼
              _buildManualItem(
                context,
                title: "5. 화재 또는 소방 시설 및\n  전기 설비 구동 시 매뉴얼",
                date: "2026.03.05",
                icon: Icons.whatshot, // 🌟 [수정] 모바일 100% 호환 불꽃(소방) 순정 아이콘
                color: Colors.redAccent,
                destinationPage: const FireManualPage(),
              ),

              // 6. 주차타워 매뉴얼
              _buildManualItem(
                context,
                title: "6. 주차타워 차량파손\n  전복 사고 매뉴얼",
                date: "2026.03.05",
                icon: Icons.directions_car, // 🌟 [수정] 모바일 100% 호환 자동차(주차) 순정 아이콘
                color: Colors.blueGrey,
                destinationPage: const ParkingTowerManualPage(),
              ),

              // 7. CCTV 매뉴얼
              _buildManualItem(
                context,
                title: "7. CCTV 열람 및\n  개인정보 대응 매뉴얼",
                date: "2026.03.05",
                icon: Icons.videocam, // 🌟 절대 깨지지 않는 순정 캠코더 아이콘
                color: Colors.teal,
                destinationPage: const CctvManualPage(),
              ),

              // 8. 하자 민원 매뉴얼
              _buildManualItem(
                context,
                title: "8. 하자 민원 대응 및\n  책임 소재 매뉴얼",
                date: "2026.03.05",
                icon: Icons.plumbing, // 🌟 순정 수리/배관 아이콘
                color: Colors.indigo,
                destinationPage: const DefectManualPage(),
              ),

              const SizedBox(height: 24), // 하단 여백 추가
            ],
          ),
        ),
      ),
      // 🌟 본사 통제 원칙에 따라 현장 직원의 '직접 등록(추가) 버튼' 영구 삭제 유지
    );
  }

  // 📝 매뉴얼 리스트 디자인 위젯
  Widget _buildManualItem(BuildContext context, {
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
          // 🚀 목적지(destinationPage)가 입력되어 있으면 그 화면으로 이동!
          if (destinationPage != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationPage),
            );
          } else {
            // 목적지가 없으면 준비 중 알림 띄우기
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("상세 내용은 현재 준비 중입니다."))
            );
          }
        },
      ),
    );
  }
}