// [파일 위치: lib/pages/manual/parking_tower_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.06 - 주차타워 사고 (Enterprise / 100% 호환 순정 아이콘 버전)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ParkingTowerManualPage extends StatelessWidget {
  const ParkingTowerManualPage({super.key});

  // 🏢 대기업 표준 메인 컬러 (Corporate Navy)
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color primaryBlue = const Color(0xFF0F172A);

  // 📞 전화 걸기 함수
  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // 고급스러운 연회색 배경
      appBar: AppBar(
        title: const Text(
          "현장 대응 매뉴얼: 주차타워 사고",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        elevation: 0.5,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildGoalHeader(),
              const SizedBox(height: 20),
              _buildStep1(),
              const SizedBox(height: 16),
              _buildStep2(),
              const SizedBox(height: 16),
              _buildStep3(),
              const SizedBox(height: 16),
              _buildStep4(),
              const SizedBox(height: 16),
              _buildDecisionTree(), // 사고 대응 프로세스 (UI 로직)
              const SizedBox(height: 16),
              _buildStep5(),
              const SizedBox(height: 16),
              _buildStep6(), // 모바일 체크리스트 UI
              const SizedBox(height: 32),
              _buildEmergencyContacts(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 최종 목표 헤더
  Widget _buildGoalHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text("최종 목표", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          Text("1. 추가 인명 피해 방지\n2. 기계 결함 vs 사용자 과실의 명확한 증거 확보\n3. 관리회사 책임 면책 근거 마련",
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  // 🛑 1단계: 사고 접수 및 긴급 비상 정지
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 사고 접수 및 긴급 비상 정지 (Emergency Stop)",
      icon: Icons.stop, // 🌟 [수정] stop 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("사고 발생 인지 즉시 기계를 정지시키고 현장을 통제하여 2차 추락이나 파손을 막습니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          _buildHighlightBox(Icons.pan_tool, "비상 정지 버튼 작동", "조작반의 비상 정지 버튼을 즉시 눌러 모든 구동을 멈춤", isDanger: true), // 🌟 [수정] pan_tool 순정
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.block, "출입 금지 및 안전선 설치", "타워 내부로의 진입을 엄격히 금지하고, 입구에 안전 테이프 및 차단막 설치", isWarning: true), // 🌟 [수정] block 순정
          const SizedBox(height: 8),
          _buildInfoRow(Icons.power_settings_new, "전원 차단 (필요시)", "기계적 오작동으로 인한 폭주 위험이 있을 경우 메인 차단기 내림"), // 🌟 [수정] power_settings_new 순정
        ],
      ),
    );
  }

  // 🚑 2단계: 인명 사고(대인) 발생 시 긴급 구조
  Widget _buildStep2() {
    return _buildCard(
      title: "2단계: 인명 사고(대인) 발생 시 긴급 구조 (Life Rescue)",
      icon: Icons.healing, // 🌟 [수정] healing 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("사람이 갇히거나 다친 경우, 관리자의 독단적 판단은 형사 처벌로 이어질 수 있습니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.local_hospital, "119 및 유지관리업체 동시 신고", "인명 피해 상황을 알리고 즉시 출동 요청"), // 🌟 [수정] local_hospital 순정
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.warning, "강제 구조 금지", "관리자가 기계를 수동으로 조작하여 구조를 시도하는 행위 절대 금지. (기계 급하강으로 인한 압사 위험)", isDanger: true), // 🌟 [수정] warning 순정
          const SizedBox(height: 8),
          _buildInfoRow(Icons.record_voice_over, "지속적 소통", "구조대 도착 전까지 부상자와 대화하며 상태를 확인하고 안심 유도"), // 🌟 [수정] record_voice_over 순정
        ],
      ),
    );
  }

  // 🔍 3단계: 현장 진단 및 원인 분석
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: 현장 진단 및 원인 분석 (Diagnosis)",
      icon: Icons.search, // 🌟 [수정] search 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("차량 파손이나 전복 시, '사용자 부주의'인지 '기계 결함'인지 판별하는 것이 핵심입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),

          const Text("🚗 사용자 과실 체크 (Most Common)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.straighten, "차량 규격 초과", "대형 SUV나 개조 차량이 제한 높이/무게를 초과했는지 확인"), // 🌟 [수정] straighten 순정
          _buildInfoRow(Icons.directions_car, "입고 불량", "사이드미러 미접힘, 트렁크 열림, 차량이 팔레트 중앙에서 벗어났는지 확인"), // 🌟 [수정] directions_car 순정
          _buildInfoRow(Icons.exit_to_app, "운전자 이탈 전 조치", "주차 브레이크 미체결, 기어 P단 미위치 여부 확인"), // 🌟 [수정] exit_to_app 순정

          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          const Text("⚙️ 기계 결함 체크", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.settings_input_antenna, "센서 오작동", "입구 센서나 낙하 방지 장치가 작동하지 않았는지 확인"), // 🌟 [수정] settings_input_antenna 순정
          _buildInfoRow(Icons.build, "부품 파손", "와이어로프 소선 파단, 체인 이탈, 감속기 고장 여부 확인"), // 🌟 [수정] build 순정
          _buildInfoRow(Icons.hearing, "이상 소음/냄새", "사고 직전 \"끼이익\" 하는 금속 마찰음이나 타는 냄새가 있었는지 확인"), // 🌟 [수정] hearing 순정
        ],
      ),
    );
  }

  // 📸 4단계: SM종합관리의 법적 증거 확보
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: SM종합관리의 법적 증거 확보 (Evidence)",
      icon: Icons.gavel, // 🌟 [수정] gavel 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("소송에서 관리회사를 지키는 가장 강력한 무기들입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.videocam, "CCTV 및 블랙박스 백업", "사고 당시의 영상, 차량 입고 시점의 영상을 즉시 확보"), // 🌟 [수정] videocam 순정
          _buildInfoRow(Icons.storage, "로그 데이터(Log Data) 추출", "주차 시스템 컴퓨터에 기록된 에러 코드와 작동 기록 사진 촬영"), // 🌟 [수정] storage 순정
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.camera_alt, color: Color(0xFF475569), size: 20), // 🌟 [수정] camera_alt 순정
                    SizedBox(width: 8),
                    Text("현장 타임스탬프 필수 촬영 항목", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBulletText("파손된 차량의 부위와 위치"),
                _buildBulletText("팔레트 위의 차량 타이어 위치 (정중앙인지 이탈했는지)"),
                _buildBulletText("조작반의 설정 상태 및 안내 문구 화면"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔄 주차타워 사고 대응 프로세스 (Mermaid to Enterprise UI)
  Widget _buildDecisionTree() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFCBD5E1))),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree, color: Color(0xFF475569)), // 🌟 [수정] account_tree 순정
                SizedBox(width: 8),
                Text("주차타워 사고 대응 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("사고 발생 및 경보", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("비상 정지 버튼 작동 및 현장 통제", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 인명피해 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("인명 피해 (Yes)", "👉 119 신고 및 유지관리업체 긴급 호출\n👉 구조대 도착 및 구조 지원"),
                _buildFlowBranch("인명 피해 (No)", "👉 유지관리업체 신고 및 원인 파악"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 원인 판별 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("원인: 사용자 과실", "👉 규격 초과 / 주차 불량 증거 사진 채증"),
                _buildFlowBranch("원인: 기계 결함", "👉 로그 데이터 및 부품 파손 사진 채증"),
              ],
            ),
            const SizedBox(height: 16),

            // SM종합관리 기록
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
              child: const Column(
                children: [
                  Text("✅ SM종합관리 법적 방어 조치", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Divider(height: 16),
                  Text("• 현장 보고서 작성 및 CCTV 영상 백업\n• 구조 지원 및 채증 데이터 통합 보관", style: TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStep(String text, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), textAlign: TextAlign.center),
    );
  }

  Widget _buildFlowBranch(String condition, String result) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
      child: Column(
        children: [
          Text(condition, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(result, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A), height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ⚖️ 5단계: 책임 소재 및 법적 방어 (Table UI)
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 책임 소재 및 법적 방어 (Liability)",
      icon: Icons.security, // 🌟 [수정] security 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enterprise Table
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("사고 유형", "주요 원인", "책임 주체", isHeader: true),
                _buildTableRow("차량 전복/추락", "입고 후 주차 브레이크 미체결,\n차량 규격 초과", "운전자\n(100% 자차 처리)"),
                _buildTableRow("기계에 의한 파손", "리프트 하강 중 기계 오작동으로\n인한 충돌", "유지관리업체/관리단\n(배상책임보험)"),
                _buildTableRow("대인 사고", "이용자 진입 금지 구역\n무단 침입", "이용자\n본인 과실 상계"),
                _buildTableRow("SM종합관리 방어", "정기 안전검사 합격증 비치 및\n일일 육안 점검 기록", "SM종합관리\n책임 면책"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user, color: Color(0xFF64748B), size: 20), // 🌟 [수정] verified_user 순정
                SizedBox(width: 10),
                Expanded(
                  child: Text("SM종합관리의 전략: \"우리는 매월 전문 업체를 통해 정기 검사를 실시하였으며(증거 제출), 이용자 주의사항을 입구에 명확히 게시(사진 제출)했으므로 관리상 과실이 없음\"을 주장.",
                      style: TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 6단계: 현장 담당자 최종 체크리스트
  Widget _buildStep6() {
    return _buildCard(
      title: "6단계: 현장 담당자 최종 체크리스트 (Mobile)",
      icon: Icons.playlist_add_check, // 🌟 [수정] playlist_add_check 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChecklistItem("[긴급] 비상 정지 버튼 즉시 눌렀는가?", isAlert: true),
          _buildChecklistItem("[통제] 입구에 안전 테이프를 설치하여 추가 진입을 막았는가?", isAlert: true),
          _buildChecklistItem("[채증] 사고 차량의 사이드미러, 트렁크, 기어 상태를 촬영했는가?"),
          _buildChecklistItem("[채증] 주차 타워 입구의 '안내문(주의사항)'이 잘 보이는지 사진 찍었는가?"),
          _buildChecklistItem("[기록] 유지관리업체 기사가 말한 사고 원인을 녹취하거나 확인서로 받았는가?"),
          _buildChecklistItem("[보고] 사고 경위서 작성 후 SM 본부 및 보험사에 즉시 접수했는가?"),
        ],
      ),
    );
  }

  // 🚨 공공기관 긴급 연락처 (크기 완벽 통일 175x65)
  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text("🚨 관련 공공기관 긴급 연락처", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildContactButton("소방서 (긴급구조)", "119", isDanger: true),
            _buildContactButton("경찰서 (분쟁/사고)", "112", isDanger: true),
            _buildContactButton("주차기 유지보수업체", "단지별 상이", isDanger: false),
            _buildContactButton("단지 영업배상보험", "담당자 확인", isDanger: false),
          ],
        ),
      ],
    );
  }

  // 🌟 버튼 크기 강제 통일 (SizedBox 적용)
  Widget _buildContactButton(String title, String number, {bool isDanger = false}) {
    Color itemColor = isDanger ? Colors.red.shade600 : primaryNavy;

    // 번호가 없거나 텍스트인 경우 전화걸기 방지
    bool isCallable = RegExp(r'[0-9]').hasMatch(number);

    return SizedBox(
      width: 175,
      height: 65,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: itemColor,
          side: BorderSide(color: itemColor.withOpacity(0.3), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        icon: Icon(Icons.phone, size: 20, color: itemColor), // 🌟 [수정] phone 순정
        label: Text("$title\n$number", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: itemColor, height: 1.3)),
        onPressed: isCallable ? () => _makePhoneCall(number) : null,
      ),
    );
  }

  // --- 공통 UI 헬퍼 위젯들 ---

  Widget _buildCard({required String title, required IconData icon, required Widget content}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryNavy, size: 24),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy))),
              ],
            ),
            const Divider(height: 30, thickness: 1, color: Color(0xFFF1F5F9)),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, height: 1.5),
                children: [
                  TextSpan(text: "$title: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightBox(IconData icon, String title, String desc, {bool isDanger = false, bool isWarning = false}) {
    Color bgColor = const Color(0xFFF8FAFC);
    Color iconColor = const Color(0xFF475569);
    Color titleColor = const Color(0xFF1E293B);

    if (isDanger) {
      bgColor = Colors.red.shade50;
      iconColor = Colors.red.shade700;
      titleColor = Colors.red.shade800;
    } else if (isWarning) {
      bgColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade700;
      titleColor = Colors.orange.shade900;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDanger ? Colors.red.shade100 : (isWarning ? Colors.orange.shade100 : const Color(0xFFE2E8F0)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 14)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155), height: 1.4))),
        ],
      ),
    );
  }

  // 📊 책임 소재 표(Table) UI 생성 헬퍼
  Widget _buildTableRow(String col1, String col2, String col3, {bool isHeader = false}) {
    final bgColor = isHeader ? const Color(0xFFF1F5F9) : Colors.white;
    final textColor = isHeader ? const Color(0xFF1E293B) : const Color(0xFF475569);
    final fontWeight = isHeader ? FontWeight.bold : FontWeight.normal;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col1, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13), textAlign: TextAlign.center))),
          Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
          Expanded(flex: 5, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col2, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13)))),
          Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col3, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13), textAlign: TextAlign.center))),
        ],
      ),
    );
  }

  // ✅ 체크리스트 UI 생성 헬퍼
  Widget _buildChecklistItem(String text, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isAlert ? Icons.warning : Icons.check_box, color: isAlert ? Colors.red.shade600 : primaryNavy, size: 22), // 🌟 [수정] warning / check_box 순정
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 15, color: isAlert ? Colors.red.shade800 : const Color(0xFF1E293B), fontWeight: isAlert ? FontWeight.bold : FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}