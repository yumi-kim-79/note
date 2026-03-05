// [파일 위치: lib/pages/safety/electrical_safety_page.dart]
// [설명: 현장 안전 수칙 No.04 - 전기 설비 및 부품 교체 (Enterprise Safety Protocol / KOSHA 지침 보강)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ElectricalSafetyPage extends StatelessWidget {
  const ElectricalSafetyPage({super.key});

  // 🏢 대기업 안전 규정용 컬러 팔레트
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);
  final Color dangerRed = const Color(0xFFDC2626);
  final Color warningOrange = const Color(0xFFEA580C);

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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "안전 수칙: 전기 설비 교체",
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
              _buildPromiseHeader(),
              const SizedBox(height: 24),
              _buildStep1(), // LOTO 적용
              const SizedBox(height: 16),
              _buildStep2(), // 비접촉 검전
              const SizedBox(height: 16),
              _buildStep3(), // 습기/절연
              const SizedBox(height: 16),
              _buildDecisionTree(), // 로직 트리
              const SizedBox(height: 16),
              _buildStep4(), // 체크리스트
              const SizedBox(height: 16),
              _buildStep5(), // 사고 대응
              const SizedBox(height: 40),
              _buildEmergencyContacts(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🤝 도입부: 우리의 약속
  Widget _buildPromiseHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.electrical_services, color: Colors.white, size: 40), // 🌟 순정 아이콘
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"전기는 두 번의 기회를 주지 않습니다.\n당신의 생명을 지키는 1분의 LOTO는\n우리 가족의 행복을 지키는 1분입니다.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 🔒 1단계: LOTO의 철저한 이행 (KOSHA 열쇠 규칙 보강)
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: 생명을 잠그는 'LOTO' (Lock-Out, Tag-Out)",
      subtitle: "전기 사고의 상당수는 타인이 전원을 다시 올려서 발생합니다. 이를 원천 차단하십시오.",
      accentColor: dangerRed,
      icon: Icons.lock, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.vpn_key, "Lock-Out (물리적 차단) 및 열쇠 소지", "구역 차단기를 내린 후 전용 잠금장치를 거십시오. [KOSHA 필수 지침] 잠금장치의 열쇠는 반드시 '작업자 본인'이 주머니에 소지하여 타인의 임의 개방을 막아야 합니다.", isDanger: true),
          _buildActionItem(Icons.label, "Tag-Out (표찰 부착)", "잠금장치 위에 '작업 중-조작 금지' 표찰을 부착하고, 작업자 성명/연락처/예상 시간을 기재하여 책임 소재를 명확히 하십시오."),
          _buildActionItem(Icons.power_settings_new, "확인 사살 (이중 체크)", "차단기를 내린 후에도 해당 설비의 스위치를 켜보거나 테스터기로 전원이 확실히 차단되었는지 다시 한번 확인하십시오."),
        ],
      ),
    );
  }

  // ⚡ 2단계: 비접촉 검전
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: 보이지 않는 흐름을 읽는 '검전' (Verification)",
      subtitle: "\"내렸으니 당연히 안 통하겠지\"라는 방심이 감전 사고를 부릅니다.",
      accentColor: warningOrange,
      icon: Icons.flash_on, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.sensors, "비접촉식 검전기 상시 휴대", "전선 피복에 대기만 해도 전류를 알려주는 비접촉식 검전기는 전기 작업자의 제1보호구입니다. 전선에 맨손을 대기 전 무조건 사용하십시오."),
          _buildHighlightAction(Icons.rule, "3단계 검전 원칙 (FM 교본)", "① 살아있는 전선에 대어 검전기 정상 작동 확인 👉 ② 실제 작업할 전선에 대어 전류 유무 확인 👉 ③ 다시 살아있는 전선에 대어 검전기 고장 아님을 최종 확인.", isDanger: false),
          _buildHighlightAction(Icons.battery_alert, "잔류 전하 방전", "콘덴서(Capacitor) 등이 포함된 설비는 차단기를 내려도 엄청난 잔류 전기가 남아 있습니다. 충분히 방전시킨 후 작업을 시작하십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 💧 3단계: 습기 및 절연 (아크 플래시 복장 보강)
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 습기와의 전쟁 - '절연' 유지 (Environment)",
      subtitle: "물은 전기의 가장 강력한 전도체입니다. 습기가 있는 환경은 자살 행위입니다.",
      accentColor: safetyBlue,
      icon: Icons.opacity, // 🌟 순정 물방울 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.pan_tool, "젖은 손 작업 엄격 금지", "땀에 젖거나 손에 물기가 있다면 즉시 건조하십시오. 면장갑만 끼는 것은 금물이며, 반드시 'KC 인증 절연 장갑'을 덧끼워야 합니다."),
          _buildActionItem(Icons.dry, "바닥 상태 점검", "바닥에 물기가 있다면 절연 매트를 깔거나 물기를 제거하십시오. 지하실/펌프실에서는 절연화 착용 상태를 엄격히 점검하십시오."),
          _buildHighlightAction(Icons.umbrella, "우천 시 실외 작업 금지", "옥상이나 실외 전기 설비 작업 중 비가 오기 시작하면 즉시 작업을 중단하고 차단기를 내린 후 철수하십시오.", isDanger: true),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("⚠️ 한국전기안전공사 복장 기준", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.checkroom, "합성섬유(나일론 등) 의류 착용 금지", "아크 플래시(전기 폭발) 발생 시 나일론/폴리에스터 등은 피부에 녹아붙어 치명적인 화상을 입힙니다. 가급적 순면 재질의 작업복을 착용하십시오."),
        ],
      ),
    );
  }

  // 📝 4단계: 나와의 약속 (체크리스트)
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 현장 담당자 전기 작업 필수 체크리스트",
      subtitle: "드라이버를 들기 전, 스마트폰으로 확인하는 5가지 생명선",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildPledgeItem("[LOTO] 내가 차단기를 내린 것을 남들이 알 수 있게 잠금(열쇠 소지)과 표찰을 했는가?"),
          _buildPledgeItem("[검전] 비접촉 검전기로 전선에 전기가 흐르지 않음을 직접 3단계로 확인했는가?"),
          _buildPledgeItem("[습기] 지금 내 장갑이나 신발, 작업 바닥이 젖어 있지는 않은가?"),
          _buildPledgeItem("[장비] 사용하는 드라이버나 펜치가 절연 처리가 된 전용 공구인가?"),
          _buildPledgeItem("[복장] 전도성 장신구(시계, 금반지, 목걸이 등)를 모두 제거했는가?"),
        ],
      ),
    );
  }

  // 🛡️ 5단계: 사고 발생 시 긴급 대응
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 사고 발생 시 긴급 대응 (Emergency Response)",
      subtitle: "2차 감전을 막는 것이 동료를 살리는 길입니다.",
      accentColor: Colors.teal,
      icon: Icons.healing, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.front_hand, "감전 사고 목격 시 (맨손 접촉 금지)", "절대로 부상자를 맨손으로 만지지 마십시오. 즉시 메인 차단기를 내리거나 완벽한 절연체(마른 나무 막대, 플라스틱)를 이용해 부상자를 전원에서 떼어낸 후 119에 신고하십시오.", isDanger: true),
          _buildActionItem(Icons.whatshot, "전기 화재 발생 시", "전기 화재에 물을 부으면 감전 폭발이 일어납니다. 반드시 C급 화재용(이산화탄소 또는 할론) 소화기를 사용하십시오."),
        ],
      ),
    );
  }

  // 🔄 전기 작업 프로세스 (Mermaid to UI)
  Widget _buildDecisionTree() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFCBD5E1))),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree, color: primaryNavy), // 🌟 순정 아이콘
                const SizedBox(width: 8),
                Text("전기 작업 및 부품 교체 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("작업 구역 차단기 하향 👉 LOTO(잠금/표찰) 적용", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("비접촉 검전기로 잔류 전류 확인", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 검전 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("🚨 전류 감지됨 (Yes)", "👉 차단기 위치 재확인\n👉 콘덴서 방전 대기"),
                _buildFlowBranch("✅ 전류 없음 (No)", "👉 손/바닥 습기 확인 단계로 이동"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 습기 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("습기 존재 (Yes)", "👉 습기 완전 제거 및 절연 매트/장구 보강"),
                _buildFlowBranch("건조 상태 (No)", "👉 안전하게 부품 교체 및 점검 실시"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("작업 완료 👉 LOTO 해제 👉 차단기 상향 및 작동 확인", const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // SM종합관리 디테일
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Text("✅ SM종합관리의 디테일 (안전 기록)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Divider(height: 16, color: Colors.white54),
                  Text("차단기 LOTO 부착 상태 사진 촬영\n작업 전 절연장갑 착용 사진 일지 등록", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚨 공공기관 긴급 연락처
  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text("🚨 산업 재해 및 긴급 신고망", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildContactButton("소방서 (긴급구조/화재)", "119", isDanger: true),
            _buildContactButton("한국전력 (외부단전)", "123", isDanger: false),
            _buildContactButton("전기안전관리자", "단지별 상이", isDanger: false),
          ],
        ),
      ],
    );
  }

  // --- [신규 디자인 양식] UI 헬퍼 위젯들 (무한 높이 멈춤 에러 방지 적용 완료) ---

  Widget _buildSectionCard({required String title, required String subtitle, required Color accentColor, required IconData icon, required Widget content}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, decoration: BoxDecoration(color: accentColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: accentColor, size: 26),
                        const SizedBox(width: 10),
                        Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const Divider(height: 30, thickness: 1, color: Color(0xFFF1F5F9)),
                    content,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightAction(IconData icon, String title, String desc, {bool isDanger = false}) {
    Color bgColor = isDanger ? Colors.red.shade50 : const Color(0xFFF8FAFC);
    Color iconColor = isDanger ? Colors.red.shade700 : primaryNavy;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDanger ? Colors.red.shade100 : const Color(0xFFE2E8F0))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDanger ? Colors.red.shade800 : primaryNavy, fontSize: 15)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPledgeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_box, color: primaryNavy, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(String title, String number, {bool isDanger = false}) {
    Color itemColor = isDanger ? Colors.red.shade600 : primaryNavy;
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
        icon: Icon(Icons.phone, size: 20, color: itemColor),
        label: Text("$title\n$number", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: itemColor, height: 1.3)),
        onPressed: isCallable ? () => _makePhoneCall(number) : null,
      ),
    );
  }

  Widget _buildFlowStep(String text, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
}