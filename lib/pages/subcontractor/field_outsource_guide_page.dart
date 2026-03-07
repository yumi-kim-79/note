// [파일 위치: lib/pages/subcontractor/field_outsource_guide_page.dart]
// [설명: 용역/외주업체 관리 가이드 메인 허브 (메뉴판)]

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'fire_safety_guide_page.dart'; // 🌟 소방 가이드 불러오기
import 'electric_safety_guide_page.dart'; // 🌟 전기안전 가이드 불러오기
import 'elevator_safety_guide_page.dart'; // 🌟 [추가] 승강기 가이드 불러오기
import 'parking_lift_safety_guide_page.dart'; // 🌟 [추가] 주차/리프트 가이드 불러오기
import 'cleaning_service_guide_page.dart'; // 🌟 [추가] 미화 가이드 불러오기
import 'water_tank_guide_page.dart'; // 🌟 [추가] 물탱크 가이드 불러오기
import 'disinfection_service_guide_page.dart'; // 🌟 [추가] 소독 가이드 불러오기
import 'integrated_security_guide_page.dart'; // 🌟 [추가] 보안 가이드 불러오기

class FieldOutsourceGuidePage extends StatelessWidget {
  const FieldOutsourceGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("용역업체 관리 가이드", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 18)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textMain),
        elevation: 1,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16, left: 4),
                child: Text("분야별 외주/용역업체 통제 및 평가 지침", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              ),

              // 1. 소방안전 용역업체 관리 (연결 완료!)
              _buildSubcontractorItem(
                context,
                title: "1. 소방안전관리 대행업체\n관리 지침",
                subtitle: "수신기 점검, 불량 내역 이행, 페널티 규정",
                icon: Icons.local_fire_department,
                color: Colors.redAccent,
                destinationPage: const FireSafetyGuidePage(),
              ),

              // 2. 전기안전 용역업체 관리 (연결 완료!)
              _buildSubcontractorItem(
                context,
                title: "2. 전기안전관리 대행업체\n관리 지침",
                subtitle: "열화상 측정, 절연 수치 확인, 페널티 규정",
                icon: Icons.electrical_services,
                color: Colors.orange,
                destinationPage: const ElectricSafetyGuidePage(), // 🚀 연결!
              ),

              // 3. 승강기 유지보수 업체 (연결 완료!)
              _buildSubcontractorItem(
                context,
                title: "3. 승강기 유지보수 용역\n관리 지침",
                subtitle: "월간 정기점검, 갇힘 사고 대응, 부품 견적 검토",
                icon: Icons.elevator,
                color: Colors.blueAccent,
                destinationPage: const ElevatorSafetyGuidePage(), // 🚀 연결!
              ),

              // 4. 주차/리프트 용역 관리 지침 (연결 완료!)
              _buildSubcontractorItem(
                context,
                title: "4. 기계식 주차/리프트 용역\n관리 지침",
                subtitle: "구동부 주유 상태, 센서 정밀 테스트, 페널티 규정",
                icon: Icons.car_repair, // 🌟 자동차 수리 아이콘
                color: Colors.indigo,
                destinationPage: const ParkingLiftSafetyGuidePage(), // 🚀 연결!
              ),

              // 5. 청소/미화 용역 관리 지침 (연결 완료!)
              _buildSubcontractorItem(
                context,
                title: "5. 청소 및 미화 용역\n관리 지침", // 번호는 기존 리스트 순서에 맞게 조정하시면 됩니다 (예: 5번)
                subtitle: "구역별 QR 인증, 사각지대 점검, 민원 발생 시 페널티",
                icon: Icons.cleaning_services,
                color: Colors.green,
                destinationPage: const CleaningServiceGuidePage(), // 🚀 연결 완료!
              ),

              // 6. 물탱크(저수조) 용역 관리 지침 (연결 완료!)
              _buildSubcontractorItem(
                context,
                title: "6. 물탱크 청소 및 수질검사 용역\n관리 지침",
                subtitle: "단수 사전 공지, 채수 입회, 필증 시스템 등록",
                icon: Icons.water_drop,
                color: Colors.lightBlue,
                destinationPage: const WaterTankGuidePage(), // 🚀 연결 완료!
              ),

              // 7. 소독·방역 용역 관리 지침 (연결 완료!)
              _buildSubcontractorItem(
                context,
                title: "7. 소독 및 방역 용역\n관리 지침",
                subtitle: "세대 방문율 체크, MSDS 확인, 민원 기반 평가",
                icon: Icons.health_and_safety,
                color: Colors.lightGreen,
                destinationPage: const DisinfectionServiceGuidePage(), // 🚀 연결 완료!
              ),

              // 8. 통합 보안(경비/CCTV) 용역 관리 지침 (연결 완료!)
              _buildSubcontractorItem(
                context,
                title: "8. 통합 보안(경비/CCTV) 용역\n관리 지침",
                subtitle: "인적/기술 보안 결합 관리, 위약금 없는 해지 조항",
                icon: Icons.security,
                color: Colors.blueGrey,
                destinationPage: const IntegratedSecurityGuidePage(), // 🚀 연결 완료!
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 리스트 디자인 위젯
  Widget _buildSubcontractorItem(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? destinationPage,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          if (destinationPage != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => destinationPage));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("해당 업종 가이드는 현재 준비 중입니다.")));
          }
        },
      ),
    );
  }
}