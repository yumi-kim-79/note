// [파일 위치: lib/pages/manual/elevator_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.03 - 승강기 사고 및 갇힘 (Enterprise 버전)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ElevatorManualPage extends StatelessWidget {
  const ElevatorManualPage({super.key});

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
          "현장 대응 매뉴얼: 승강기 사고",
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
          Text("1. 갇힘 승객의 안전 확보 및 심리적 안정\n2. 신속한 구조 요청 (FM 절차 준수)\n3. 사고 원인 기록 및 책임 소재 확인",
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  // 🗣️ 1단계: 사고 접수 및 긴급 소통
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 사고 접수 및 긴급 소통 (Communication)",
      icon: Icons.record_voice_over_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("사고 알람/인터폰 접수 즉시, 승객의 공포심을 줄이는 '표준 멘트'를 시행합니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote, color: Color(0xFF475569), size: 20),
                    SizedBox(width: 8),
                    Text("안심 멘트 (FM)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                SizedBox(height: 8),
                Text("\"관리사무소입니다. 놀라셨죠? 현재 승강기가 안전 장치에 의해 멈춘 상태이니 안심하십시오. 강제로 문을 열면 위험하니 그대로 대기해 주세요. 즉시 구조대를 호출했습니다.\"",
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF334155), height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.health_and_safety_outlined, "상태 파악", "승객 인원, 노약자/임산부/환자 탑승 여부 및 승강기 내 조명/환기 상태 확인"),
          _buildInfoRow(Icons.speaker_phone_outlined, "지시 사항", "바닥에 주저앉아 편안하게 대기 요청, 문 밖에서 계속 대화하며 상황을 알림"),
        ],
      ),
    );
  }

  // 🚨 2단계: 즉시 구조 요청 및 보고
  Widget _buildStep2() {
    return _buildCard(
      title: "2단계: 즉시 구조 요청 및 보고 (Emergency Call)",
      icon: Icons.emergency_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("관리자는 독단적으로 판단하지 말고, 정해진 매뉴얼 순서대로 구조를 요청합니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildHighlightBox(Icons.build_outlined, "유지관리업체 호출", "승강기 내 부착된 고유번호(7자리) 또는 단지 내 계약된 업체에 즉시 신고"),
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.local_fire_department_outlined, "119 구조대 병행 신고", "• 승객 중 환자/노약자가 있는 경우\n• 유지관리업체 도착이 20분 이상 소요될 것으로 예상되는 경우", isDanger: true),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.campaign_outlined, "비상 방송", "단지 내 방송을 통해 \"현재 O동 승강기 점검 중으로 사용이 중단되었습니다\" 안내 (추가 민원 방지)"),
        ],
      ),
    );
  }

  // 🛑 3단계: 현장 도착 및 관리자 대기
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: 현장 도착 및 관리자 대기 (On-site Action)",
      icon: Icons.front_hand_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("업체가 올 때까지 관리자가 현장에서 취해야 할 FM 행동입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.format_list_numbered_outlined, "층수 확인", "승강기가 정확히 어느 층 사이(또는 어느 층)에 멈췄는지 기계실이나 표시기로 확인"),
          _buildInfoRow(Icons.chat_outlined, "현장 대기", "승강기 문 앞에서 대기하며 승객에게 현재 상황 실시간 공유 (예: \"업체가 5분 뒤 도착 예정입니다\")"),
          const SizedBox(height: 12),
          _buildHighlightBox(Icons.do_not_disturb_alt_outlined, "🚫 절대 금지 사항", "전문 기술자 없이 관리자가 비상키로 문을 강제 개방하는 행위 절대 금지. (승객 추락 및 기기 파손 위험)", isDanger: true),
        ],
      ),
    );
  }

  // 🛡️ 4단계: 구조 완료 및 사후 조치
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: 구조 완료 및 사후 조치 (Recovery)",
      icon: Icons.check_circle_outline,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("승객 구조 후 관리자가 반드시 챙겨야 할 '증거'와 '절차'입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.people_alt_outlined, "승객 상태 최종 확인", "구조된 승객의 외상 여부를 확인하고, 필요한 경우 인적 사항 기록"),
          _buildInfoRow(Icons.description_outlined, "원인 파악 및 수리", "유지관리업체로부터 '점검 레포트'를 수령하여 단순 오작동인지 부품 교체인지 확인"),
          _buildInfoRow(Icons.block_outlined, "운행 중지 안내", "수리가 완벽히 끝날 때까지 해당 승강기에 '안내문' 부착 및 안전 라인 설치"),
        ],
      ),
    );
  }

  // 🔄 사고 대응 프로세스 (Mermaid to Enterprise UI)
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
                Icon(Icons.account_tree_outlined, color: Color(0xFF475569)),
                SizedBox(width: 8),
                Text("사고 대응 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("갇힘 사고 접수 및 인터폰 연결 (안심 유도)", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 분기점
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("응급환자/노약자 탑승", "👉 119 및 유지관리업체\n동시 신고 (즉시)"),
                _buildFlowBranch("일반 승객", "👉 유지관리업체 즉시 신고\n(20분 초과 예상시 119)"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("현장 도착 및 문 밖 대화 유지 (구조대 도착 대기)", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("전문가에 의한 안전한 구조 실시", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 병렬 처리 박스
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
              child: const Column(
                children: [
                  Text("사후 조치 및 기기 수리 완료 후 운행 재개", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Divider(height: 16),
                  Text("✅ SM종합관리 기록 사항", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13)),
                  SizedBox(height: 4),
                  Text("현장 사진 및 점검 레포트 사진 일지 업로드 必", style: TextStyle(color: Color(0xFF334155), fontSize: 13)),
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

  // ⚖️ 5단계: 책임 소재 및 법적 대응 (Table UI)
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 책임 소재 및 법적 대응 (Liability)",
      icon: Icons.gavel_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("악성 민원인이 정신적 피해 보상을 요구하며 소송을 제기할 때를 대비한 방어 전략입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          // Enterprise Table
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("구분", "발생 원인", "책임 주체", isHeader: true),
                _buildTableRow("기기 노후", "부품 노후로 인한 급정지 및 고장", "관리단\n(장충금)"),
                _buildTableRow("유지보수 부실", "정기 점검 시 발견 가능한 결함 방치", "유지관리업체\n(보험 처리)"),
                _buildTableRow("이용자 과실", "승강기 내에서 뛰거나 문을 발로 차는 행위", "해당\n이용자"),
                _buildTableRow("관리회사 방어", "정기 점검 일지 및 사고 직후 적법한 구조 절차 이행", "SM종합관리\n책임 면책"),
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
                Icon(Icons.shield_outlined, color: Color(0xFF64748B), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text("SM종합관리의 강점: \"우리는 매월 정기점검을 실시하였으며, 사고 발생 시 매뉴얼에 따라 5분 내 구조 요청 및 안심 멘트를 시행하여 선량한 관리자의 의무를 다했다\"는 점을 기록으로 증명.",
                      style: TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 6단계: 상황별 대응 체크리스트
  Widget _buildStep6() {
    return _buildCard(
      title: "6단계: 현장 담당자 체크리스트 (Mobile Check-list)",
      icon: Icons.checklist_rtl_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChecklistItem("[소통] 승객에게 \"강제 개방 금지\" 및 \"안심 유도\" 멘트 실시 여부"),
          _buildChecklistItem("[신고] 유지관리업체 도착 예정 시간 확인 및 기록"),
          _buildChecklistItem("[안전] 119 병행 신고가 필요한 긴급 상황인지 판별 여부"),
          _buildChecklistItem("[기록] 구조 완료 후 승객 특이사항 및 점검 레포트 사진 촬영"),
          _buildChecklistItem("[보고] 사고 원인(단전, 부품 고장 등) 파악 후 SM 본부 보고"),
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
            _buildContactButton("승강기안전공단", "1566-1277", isDanger: false),
            _buildContactButton("한국전력 (정전확인)", "123", isDanger: false),
            // 유지보수업체는 단지마다 다르므로 빈 템플릿 제공
            _buildContactButton("유지보수업체", "단지별 상이", isDanger: false),
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
        icon: Icon(Icons.phone_in_talk, size: 20, color: itemColor),
        label: Text("$title\n$number", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: itemColor, height: 1.3)),
        onPressed: isCallable ? () => _makePhoneCall(number) : null, // 텍스트면 비활성화
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

  // 📊 책임 소재 표(Table) UI 생성 헬퍼
  Widget _buildTableRow(String col1, String col2, String col3, {bool isHeader = false}) {
    final bgColor = isHeader ? const Color(0xFFF1F5F9) : Colors.white;
    final textColor = isHeader ? const Color(0xFF1E293B) : const Color(0xFF475569);
    final fontWeight = isHeader ? FontWeight.bold : FontWeight.normal;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col1, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13), textAlign: TextAlign.center))),
          Container(width: 1, height: 50, color: const Color(0xFFE2E8F0)),
          Expanded(flex: 4, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col2, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13)))),
          Container(width: 1, height: 50, color: const Color(0xFFE2E8F0)),
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
          Icon(isAlert ? Icons.cancel_outlined : Icons.check_box_outlined, color: isAlert ? Colors.red.shade600 : primaryNavy, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 15, color: isAlert ? Colors.red.shade800 : const Color(0xFF1E293B), fontWeight: isAlert ? FontWeight.bold : FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}