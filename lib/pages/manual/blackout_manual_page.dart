// [파일 위치: lib/pages/manual/blackout_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.04 - 정전 및 비상발전기 (Enterprise 버전)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BlackoutManualPage extends StatelessWidget {
  const BlackoutManualPage({super.key});

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
          "현장 대응 매뉴얼: 정전 및 비상발전기",
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
              _buildDecisionTree(), // 정전 대응 프로세스 (UI 로직)
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
          Text("1. 정전 원인 신속 파악\n2. 비상 전원(승강기·소방) 확보\n3. 입주민 불안 해소 및 설비 보호",
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  // 🔍 1단계: 정전 범위 확인 및 원인 파악
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 정전 범위 확인 및 원인 파악 (Diagnosis)",
      icon: Icons.search_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("가장 먼저 '한전 선로 사고'인지 '건물 내부 차단기 트립'인지 구분해야 합니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.visibility_outlined, "주변 상황 확인", "창밖을 보거나 주변 건물, 가로등의 점등 여부 확인"),
          const SizedBox(height: 8),
          _buildCaseBox("외부 요인", "주변도 깜깜함", "한전(123) 측 선로 정전 발생"),
          const SizedBox(height: 8),
          _buildCaseBox("내부 요인", "우리 건물만 정전", "건물 내 메인 차단기(VCB, ACB) 트립 또는 변압기 문제"),
          const SizedBox(height: 12),
          _buildHighlightBox(Icons.electric_meter_outlined, "수변전실 이동", "전기실로 이동하여 수신반의 전압계(V-Meter)가 '0'인지 확인", isDanger: true),
        ],
      ),
    );
  }

  // ⚡ 2단계: 비상발전기 및 ATS 기동 확인
  Widget _buildStep2() {
    return _buildCard(
      title: "2단계: 비상발전기 및 ATS 기동 확인 (Emergency Power)",
      icon: Icons.power_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("정전 직후 10~20초 이내에 비상발전기가 자동으로 돌아가야 합니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          _buildHighlightBox(Icons.settings_power_outlined, "발전기 기동 확인", "비상발전기가 자동으로 시동되었는지 확인. 만약 가동되지 않았다면 수동 기동(Manual Start) 실시"),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.swap_horiz_outlined, "ATS(자동절체스위치) 확인", "한전 전원에서 발전기 전원으로 스위치가 넘어갔는지 확인"),
          _buildInfoRow(Icons.lightbulb_outline, "비상 부하 확인", "승강기, 복도 비상등, 소방 펌프, 지하주차장 일부 전등에 불이 들어오는지 체크"),
        ],
      ),
    );
  }

  // 🚨 3단계: 긴급 현장 순찰 및 승강기 대응
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: 긴급 현장 순찰 및 승강기 대응 (Safety)",
      icon: Icons.directions_run_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("전기가 끊기면 가장 위험한 곳은 승강기입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildHighlightBox(Icons.elevator_outlined, "승강기 갇힘 확인", "비상발전기 가동 후에도 승강기가 멈춰있다면 인터폰으로 승객 갇힘 여부 전수 확인 (사고 시 매뉴얼 No.03 실행)", isDanger: true),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.water_damage_outlined, "전기 집약 시설 점검", "배수 펌프(지하 침수 방지)가 비상 전원으로 작동하는지 확인"),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign_outlined, color: Color(0xFF475569), size: 20),
                    SizedBox(width: 8),
                    Text("입주민 방송 안내", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                SizedBox(height: 8),
                Text("\"현재 한전 선로 사고로 인한 정전입니다. 비상발전기로 승강기는 가동 중이나 사용을 자제해 주시기 바랍니다.\"",
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF334155), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔄 4단계: 한전 복구 및 정상 전원 복귀
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: 한전 복구 및 정상 전원 복귀 (Recovery)",
      icon: Icons.restore_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("한전 전원이 복구되었을 때 기기 손상을 막기 위한 절차입니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.check_circle_outline, "복구 확인", "수변전실 전압계가 정상(220V/380V)으로 돌아왔는지 확인"),
          _buildInfoRow(Icons.swap_horiz_outlined, "절체 확인", "ATS가 발전기에서 다시 한전 전원으로 넘어가는지 확인"),
          _buildInfoRow(Icons.format_list_numbered_outlined, "순차 투입", "부하가 큰 설비(동력반, 펌프 등)는 전압 서지를 막기 위해 순차적으로 차단기를 올림"),
          _buildInfoRow(Icons.power_settings_new_outlined, "발전기 정지", "발전기를 '무부하 운전' 후 서서히 식혀서 정지 (보통 자동 설정되어 있음)"),
        ],
      ),
    );
  }

  // 📈 정전 대응 로직 (Mermaid to Enterprise UI)
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
                Text("정전 대응 로직 흐름도", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("정전 발생 접수", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 1차 분기점
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("주변도 정전", "👉 한전(123) 사고 접수 확인"),
                _buildFlowBranch("우리만 정전", "👉 수변전실 메인 차단기 점검"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 2차 분기점
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("비상발전기 미가동 (No)", "👉 발전기 수동 기동 실시"),
                _buildFlowBranch("비상발전기 자동 기동 (Yes)", "👉 ATS 절체 및 비상전원 공급 확인"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("승강기 갇힘 여부 전수 조사 및 입주민 안내 방송", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("한전 전원 복구 👉 ATS 절체 및 발전기 정지", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // SM종합관리 기록
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
              child: const Column(
                children: [
                  Text("✅ SM종합관리 기록 사항", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Divider(height: 16),
                  Text("정전 원인 및 복구 시간 사진 기록", style: TextStyle(color: Color(0xFF334155), fontSize: 14)),
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

  // ⚖️ 5단계: 책임 소재 및 사고 예방 (Table UI)
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 책임 소재 및 사고 예방 (Liability)",
      icon: Icons.gavel_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("정전으로 인한 가전제품 고장 등 민원 발생 시 대응 기준입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          // Enterprise Table
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("구분", "정전 원인", "책임 주체", isHeader: true),
                _buildTableRow("외부 정전", "한전 선로 사고, 낙뢰, 변압기 폭발", "한국전력공사\n(123)"),
                _buildTableRow("내부 정전", "건물 내 노후 부품 고장, 관리 미비", "관리단\n(수선비용 지출)"),
                _buildTableRow("과부하 정전", "특정 세대의 과도한 전력 사용(에어컨 등)", "해당\n입주민"),
                _buildTableRow("관리회사 방어", "전기안전관리자의 정기 점검 기록 및 정전 시 즉각 대응", "SM종합관리\n책임 면책"),
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
                  child: Text("SM종합관리의 포인트: \"우리는 정기적인 전기안전점검을 수행하였으며, 비상발전기 및 ATS의 정상 작동 여부를 매달 확인(점검 일지 증거)했으므로 관리상 과실이 없음\"을 명확히 함.",
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
          _buildChecklistItem("[원인] 한전 사고인지 단지 내부 사고인지 판별 완료"),
          _buildChecklistItem("[발전기] 비상발전기 시동 및 전압 형성 확인"),
          _buildChecklistItem("[ATS] 비상 전원으로 자동 절체 확인"),
          _buildChecklistItem("[안전] 승강기 갇힘 승객 유무 확인 완료"),
          _buildChecklistItem("[방송] 정전 원인 및 복구 예상 시간 안내 방송 실시"),
          _buildChecklistItem("[기록] 정전 발생 시각 및 복구 시각 SM 본부 보고"),
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
            _buildContactButton("한국전력 (사고접수)", "123", isDanger: true),
            _buildContactButton("소방서 (긴급구조)", "119", isDanger: true),
            _buildContactButton("승강기 유지보수업체", "단지별 상이", isDanger: false),
            _buildContactButton("전기안전관리자", "단지별 상이", isDanger: false),
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

  Widget _buildCaseBox(String badge, String title, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(4)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15))),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5)),
        ],
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