// [파일 위치: lib/pages/manual/fire_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.05 - 소방 및 전기 연동 (Enterprise 버전)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FireManualPage extends StatelessWidget {
  const FireManualPage({super.key});

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
          "현장 대응 매뉴얼: 소방 및 전기 연동",
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
              _buildDecisionTree(), // 소방/전기 대응 프로세스
              const SizedBox(height: 16),
              _buildStep5(), // 모바일 체크리스트 UI
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
          Text("1. 화재 시 설비 가동률 100% 보장\n2. 오작동 시 수해(물난리) 피해 최소화\n3. 설비 노후화 징후 조기 포착",
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  // 🚨 1단계: 수신기 및 전기 연동 초기 대응
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 소방 수신기(P형/R형) 및 전기 연동 초기 대응",
      icon: Icons.notifications_active_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("화재 경보 시 현장 담당자는 당황하지 말고 '수신반'의 데이터를 먼저 읽어야 합니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.dashboard_outlined, "화재 구역 점등", "몇 층, 어느 구역인지 정확히 확인"),
          _buildInfoRow(Icons.link_outlined, "전기 연동 상태", "승강기 하향(Homing), 비상방송 송출, 방화셔터 및 제연 팬 가동 여부 확인"),
          _buildInfoRow(Icons.settings_power_outlined, "펌프 기동 확인", "주펌프/보조펌프에 '기동' 램프가 들어왔는지 확인"),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildHighlightBox(Icons.directions_run, "현장 출동 및 육안 확인", "• 2인 1조 원칙. 소화기 및 무전기 지참\n• 연기, 탄 냄새, 수온 상승 여부 확인", isDanger: true),
        ],
      ),
    );
  }

  // 💧 2단계: 스프링클러(SP) 긴급 조치
  Widget _buildStep2() {
    return _buildCard(
      title: "2단계: 스프링클러(SP) 작동/파손 시 긴급 조치",
      icon: Icons.water_drop_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("스프링클러는 초당 1.5리터 이상의 물이 쏟아집니다. 1분만 늦어도 아랫집 천장이 무너집니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(height: 16),
          _buildCaseBox("상황 A", "전유부(세대 내부) 헤드 파손", "발생: 인테리어 공사, 이삿짐 충격, 노후 이탈\n\n• 구역 밸브 폐쇄: 해당 층 복도 '알람밸브실' 내 메인 밸브 즉시 폐쇄\n• 드레인(배수): 밸브 하단 드레인 밸브를 열어 잔류수 강제 배출\n• 지하 펌프 정지: 기계실 이동 후 펌프 '수동 정지' 전환"),
          const SizedBox(height: 12),
          _buildCaseBox("상황 B", "공용부(주차장/복도) 헤드 파손", "발생: 겨울철 동파, 차량 상부 충돌\n\n• 프리액션 차단: 인근 프리액션 밸브실 1차측 밸브 폐쇄\n• 수신반 복구: 감지기 오작동 시 수신반 솔레노이드 밸브 연동 해제"),
        ],
      ),
    );
  }

  // 🎧 3단계: 지하 소방펌프 이상 징후 판별
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: 지하 소방펌프 가동 시 이상 징후 판별",
      icon: Icons.hearing_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("펌프 가동 시 소리와 냄새만으로 '정상'과 '고장'을 구분해야 합니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          const Text("🔊 소음(Noise) 판별법", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.check_circle_outline, "정상", "규칙적이고 웅장한 모터 회전음"),
          _buildInfoRow(Icons.warning_amber_outlined, "이상 1 (금속음)", "\"까르륵/깡깡\" 소리 👉 임펠러 파손 또는 이물질 유입"),
          _buildInfoRow(Icons.vibration_outlined, "이상 2 (진동음)", "바닥이 떨릴 정도의 심한 진동 👉 펌프 축(Shaft) 정렬 불량"),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("👃 냄새(Odor) 판별법", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.local_fire_department_outlined, "고무 타는 냄새", "커플링/벨트 마찰열 👉 즉시 정지 후 점검"),
          _buildInfoRow(Icons.electrical_services_outlined, "전기 타는 냄새", "모터 내부 코일 과열 👉 화재 위험 및 소실 주의", colorOverride: Colors.red.shade700),
          _buildInfoRow(Icons.water_outlined, "비린 냄새/악취", "배관 내 고인 '사수' 방출 👉 정상 현상"),
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.search_outlined, "누수 확인", "메카니컬 씰 부위에서 분수처럼 솟구치는지 확인 (약간 떨어짐은 냉각용 정상)"),
        ],
      ),
    );
  }

  // ⚖️ 4단계: 책임 소재 및 법적 대응 (Table UI)
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: 책임 소재 확정 및 SM종합관리의 법적 방어",
      icon: Icons.gavel_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enterprise Table
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("구분", "발생 원인", "책임 주체", isHeader: true),
                _buildTableRow("세대 내 파손", "입주민 부주의(물건 부딪힘),\n세대 내 동파(창문 개방)", "해당 입주민\n(원상복구/배상)"),
                _buildTableRow("공용부 파손", "복도/주차장 배관 노후,\n공용부 동파", "관리단\n(수선비)"),
                _buildTableRow("펌프실 고장", "소음/진동 방치로 인한 펌프 소실", "관리회사(SM)\n과실 여부 검토"),
                _buildTableRow("SM의 방어", "일일 펌프실 순찰 일지\n(소음/냄새 무특이사항) 및 사진", "SM 면책\n(정상적 관리 증명)"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📈 소방/전기 대응 프로세스 (Mermaid to Enterprise UI)
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
                Text("소방 및 전기 연동 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("화재 경보 / 수압 저하 발생", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("수신기 구역 확인 및 현장 출동", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 스프링클러 작동 여부 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("스프링클러 작동 (Yes/수해)", "👉 알람/프리액션 밸브 즉시 차단\n👉 지하 펌프실 이동"),
                _buildFlowBranch("스프링클러 미작동 (No/비화재보)", "👉 수신기 복구 및 감지기 교체"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 펌프 가동 상태 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("이상 소음 / 탄 냄새 발생", "👉 펌프 수동 정지 및 긴급 보수 보고"),
                _buildFlowBranch("정상 가동", "👉 수압 복구 확인 후 자동 대기"),
              ],
            ),
            const SizedBox(height: 16),

            // SM종합관리 기록
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
              child: const Column(
                children: [
                  Text("✅ SM종합관리 법적 증거 확보", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Divider(height: 16),
                  Text("• 현장 조치 시각 및 밸브 차단 사진\n• 펌프 이상 수치 및 소음 녹음 기록", style: TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.5)),
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

  // ✅ 5단계: 현장 담당자 최종 체크리스트
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 현장 담당자 최종 체크리스트 (Mobile)",
      icon: Icons.checklist_rtl_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChecklistItem("[초동] 수신반 '연동' 정지 여부 확인 (오작동 시 물난리 방지용)"),
          _buildChecklistItem("[차단] 세대 내 SP 터졌을 때 해당 층 알람밸브 위치 확인 및 차단 완료"),
          _buildChecklistItem("[점검] 지하 펌프 기동 시 모터 부근에서 탄 냄새가 나는지 확인", isAlert: true),
          _buildChecklistItem("[점검] 펌프 하우징에서 비정상적인 금속성 타격음이 들리는지 확인", isAlert: true),
          _buildChecklistItem("[기록] 펌프 토출 압력이 설계 압력(예: 0.7MPa)까지 올라가는지 확인"),
          _buildChecklistItem("[CS] 입주민에게 \"점검 중 소음/냄새 발생 가능\" 사전 공지 완료"),
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
            _buildContactButton("소방서 (화재/구조)", "119", isDanger: true),
            _buildContactButton("소방시설 유지보수", "단지별 상이", isDanger: false),
            _buildContactButton("전기안전관리자", "단지별 상이", isDanger: false),
            _buildContactButton("수도사업소", "120", isDanger: false),
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

  Widget _buildInfoRow(IconData icon, String title, String desc, {Color? colorOverride}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorOverride ?? const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, height: 1.5),
                children: [
                  TextSpan(text: "$title: ", style: TextStyle(fontWeight: FontWeight.bold, color: colorOverride ?? const Color(0xFF0F172A))),
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
          Icon(isAlert ? Icons.warning_amber_rounded : Icons.check_box_outlined, color: isAlert ? Colors.red.shade600 : primaryNavy, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 15, color: isAlert ? Colors.red.shade800 : const Color(0xFF1E293B), fontWeight: isAlert ? FontWeight.bold : FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}