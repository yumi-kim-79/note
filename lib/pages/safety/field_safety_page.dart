// [파일 위치: lib/pages/safety/field_safety_page.dart]
// [페이지 설명: 현장 안전 수칙 및 필수 확인 사항 메인 리스트 화면 (메뉴판)]

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart'; // 🌟 테마 경로 확인 필요
import 'vehicle_safety_page.dart'; // 🌟 [추가] 방금 만든 차량 안전 페이지 불러오기
import 'basement_safety_page.dart'; // 🌟 [추가] 방금 만든 지하실 안전 페이지 불러오기
import 'ladder_safety_page.dart';
import 'electrical_safety_page.dart';
import 'confined_space_safety_page.dart';
import 'machinery_safety_page.dart';
import 'fire_work_safety_page.dart';
import 'heavy_load_safety_page.dart';
import 'chemical_safety_page.dart';
import 'evidence_safety_page.dart';

class FieldSafetyPage extends StatelessWidget {
  const FieldSafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
            "안전수칙 및 필수확인 사항",
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
                child: Text("SM종합관리 안전수칙 및 필수확인 사항", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              ),

              // 1. 회사 차량 안전 운행 (연결 완료)
              _buildSafetyItem(
                context,
                title: "1. 회사 차량 안전 운행 수칙",
                date: "2026.03.05",
                icon: Icons.directions_car, // 🌟 순정 자동차 아이콘
                color: Colors.blue,
                destinationPage: const VehicleSafetyPage(), // 🚀 방금 만든 페이지로 연결!
              ),

              // 2. 지하실 및 계단 안전으로 연결 완료
              _buildSafetyItem(
                context,
                title: "2. 지하실 및 계단실 순회\n  안전 수칙",
                date: "2026.03.05",
                icon: Icons.flashlight_on, // 🌟 순정 랜턴 아이콘
                color: Colors.orange,
                destinationPage: const BasementSafetyPage(), // 🚀 연결!
              ),

              // 3. 고소 및 옥상 (사다리/옥상)
              _buildSafetyItem(
                context,
                title: "3. 고소(사다리 및 옥상) 작업\n  안전 수칙",
                date: "2026.03.05",
                icon: Icons.warning,
                color: Colors.orange,
                destinationPage: const LadderSafetyPage(), // 🚀 3번째로 만든 페이지 연결!
              ),

              // 4. 전기 및 기계 작업 안전 (전기 작업 페이지로 연결)
              _buildSafetyItem(
                context,
                title: "4. 전기 활선 및 설비 교체 작업\n  안전 수칙",
                date: "2026.03.05",
                icon: Icons.power, // 🌟 순정 전기 아이콘
                color: Colors.redAccent,
                destinationPage: const ElectricalSafetyPage(), // 🚀 연결 완료!
              ),

              // 5. 밀폐공간 및 정화조 안전
              _buildSafetyItem(
                context,
                title: "5. 정화조 및 지하 밀폐공간 진입시\n  안전 수칙",
                date: "2026.03.05",
                icon: Icons.warning, // 🌟 순정 경고/가스 아이콘
                color: Colors.deepPurple,
                destinationPage: const ConfinedSpaceSafetyPage(), // 🚀 방금 만든 페이지 연결!
              ),

              // 6. 기계실 회전체 점검 안전
              _buildSafetyItem(
                context,
                title: "6. 기계실 회전체(펌프/휀) 점검\n  안전 수칙",
                date: "2026.03.05",
                icon: Icons.autorenew, // 🌟 순정 회전/기계 아이콘
                color: Colors.brown,
                destinationPage: const MachinerySafetyPage(), // 🚀 연결 완료!
              ),

              // 7. 화기 및 연마 작업 (새로 추가)
              _buildSafetyItem(
                context,
                title: "7. 용접, 그라인더 등 화기,연마 작업\n  안전 수칙",
                date: "2026.03.05",
                icon: Icons.local_fire_department, // 🌟 순정 소방/화재 아이콘
                color: Colors.red,
                destinationPage: const FireWorkSafetyPage(), // 🚀 연결 완료!
              ),

              // 8. 중량물 취급 및 운반 안전
              _buildSafetyItem(
                context,
                title: "8. 중량물 취급 및 운반\n  안전 수칙(근골격계 예방)",
                date: "2026.03.05",
                icon: Icons.fitness_center, // 🌟 순정 중량물/운동 아이콘
                color: Colors.teal,
                destinationPage: const HeavyLoadSafetyPage(), // 🚀 연결 완료!
              ),

              // 9. 화학물질 취급 안전 (새로 추가)
              _buildSafetyItem(
                context,
                title: "9. 락스 및 유해 화학물질 취급\n  안전 수칙",
                date: "2026.03.05",
                icon: Icons.science, // 🌟 순정 화학/과학 아이콘
                color: Colors.indigo,
                destinationPage: const ChemicalSafetyPage(), // 🚀 연결 완료!
              ),

              // 10. 현장 채증 및 사후 복구
              _buildSafetyItem(
                context,
                title: "10. 현장 채증(타임스탬프) 및\n  사후 복구 수칙",
                date: "2026.03.05",
                icon: Icons.camera_alt, // 🌟 순정 카메라 아이콘
                color: Colors.blueGrey,
                destinationPage: const EvidenceSafetyPage(), // 🚀 연결 완료!
              ),

              const SizedBox(height: 24), // 하단 여백 추가
            ],
          ),
        ),
      ),
    );
  }

  // 📝 안전 매뉴얼 리스트 디자인 위젯 (매뉴얼 양식 100% 동일)
  Widget _buildSafetyItem(BuildContext context, {
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