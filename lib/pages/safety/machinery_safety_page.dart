// [파일 위치: lib/pages/safety/machinery_safety_page.dart]
// [설명: 현장 안전 수칙 No.06 - 기계실 회전체 점검 (Enterprise Safety Protocol / KOSHA 지침 보강)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MachinerySafetyPage extends StatelessWidget {
  const MachinerySafetyPage({super.key});

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
          "안전 수칙: 기계실 회전체",
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
              _buildStep1(), // 복장 단속 (면장갑 금지 보강)
              const SizedBox(height: 16),
              _buildStep2(), // 정지 후 점검 (청소 금지 보강)
              const SizedBox(height: 16),
              _buildStep3(), // 가드 보호막
              const SizedBox(height: 16),
              _buildDecisionTree(), // 로직 트리
              const SizedBox(height: 16),
              _buildStep4(), // 체크리스트
              const SizedBox(height: 16),
              _buildStep5(), // 끼임 사고 긴급 대응
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
          const Icon(Icons.autorenew, color: Colors.white, size: 40), // 🌟 순정 회전/기계 아이콘
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"회전하는 기계 앞에서는 당신의 옷깃 하나도 위협이 됩니다.\n기계를 멈추는 짧은 시간이\n당신의 안전한 내일을 보장합니다.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 👔 1단계: 복장 및 신체 단속 (KOSHA 면장갑 금지 보강)
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: '말림 사고' 원천 차단 - 복장/신체 단속",
      subtitle: "사고는 기계가 사람을 '끌어당기면서' 시작됩니다. 연결고리를 제거하십시오.",
      accentColor: dangerRed,
      icon: Icons.checkroom, // 🌟 순정 옷걸이 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.architecture, "밀착 복장 준수", "작업복 소매는 반드시 단추를 채우거나 팔목에 밀착시키십시오. 헐렁한 옷자락이나 밖으로 내어 입은 상의는 회전축에 감길 위험이 100%입니다."),
          _buildActionItem(Icons.do_not_disturb_alt, "부속물 완전 제거", "넥타이, 목걸이, 특히 '목에 두른 수건'은 절대 금지입니다. '잠깐인데 괜찮겠지'라는 생각이 돌이킬 수 없는 절단/질식 사고를 부릅니다."),
          _buildActionItem(Icons.face, "머리카락 및 장신구", "긴 머리는 반드시 안전모나 모자 안에 넣어 고정하고, 시계나 반지 등 기계에 걸릴 수 있는 장신구는 진입 전 모두 해제하십시오."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("⚠️ KOSHA 회전체 장갑 착용 금지 규정", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
          const SizedBox(height: 12),
          _buildHighlightAction(Icons.pan_tool, "면장갑 착용 절대 금지", "회전체 근처에서 면장갑(코팅장갑 포함)의 실오라기가 말려 들어가면 손 전체가 절단됩니다. 기계 내부를 만질 때는 반드시 기계를 멈추거나, 차라리 '맨손' 또는 밀착되는 전용 가죽장갑을 사용하십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 🛑 2단계: 정지 후 점검 (KOSHA 청소/주유 규정 보강)
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: '정지 후 점검' - 0%의 움직임 확인",
      subtitle: "기계가 돌고 있을 때 무언가를 조절하는 행위는 '도박'입니다.",
      accentColor: warningOrange,
      icon: Icons.stop_circle, // 🌟 순정 정지 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.power_settings_new, "비의도적 가동 방지 (LOTO)", "내가 점검하는 동안 타인이 기계를 켜지 못하도록 스위치에 '점검 중 가동 금지' 표지판을 부착하고 조작반을 잠그십시오.", isDanger: true),
          _buildActionItem(Icons.remove_red_eye, "완전 정지 눈으로 확인", "전원을 껐더라도 관성에 의해 기계가 한동안 더 돕니다. 눈과 귀로 기계가 '완전히 0' 상태가 된 것을 확인한 후 손을 대십시오."),
          _buildActionItem(Icons.crisis_alert, "비상 정지 버튼 위치 숙지", "작업 전, 해당 장비의 '비상 정지(Emergency Stop)' 붉은 버튼 위치를 반드시 눈으로 확인하고 즉각 누를 수 있게 대비하십시오."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildHighlightAction(Icons.cleaning_services, "운전 중 청소/주유 절대 금지", "[산업안전보건규칙] 기계가 돌아가는 중에 헝겊으로 먼지를 닦거나 윤활유(오일)를 주입하는 행위는 법으로 금지되어 있습니다. 무조건 정지 후 실시하십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 🛡️ 3단계: 가드는 생명 보호막
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 가드(Guard)는 '생명 보호막'입니다",
      subtitle: "보호 덮개는 번거로운 짐이 아니라 최후의 보루입니다.",
      accentColor: safetyBlue,
      icon: Icons.shield, // 🌟 순정 방패 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.gpp_bad, "덮개 임의 제거 절대 금지", "\"안이 안 보인다\"거나 \"오일 넣기 불편하다\"는 핑계로 보호 덮개(가드/케이싱)를 떼어낸 채 기계를 돌리지 마십시오."),
          _buildHighlightAction(Icons.build_circle, "점검 후 즉시 100% 복구", "부득이하게 점검을 위해 열었다면, 직후 나사 하나까지 완벽하게 체결하여 복구하십시오. 다음 점검자가 방심하고 지나가다 다칠 수 있습니다.", isDanger: false),
          _buildActionItem(Icons.hearing, "가드 상태(소음) 점검", "가드가 헐겁거나 파손되어 회전체에 닿아 '끼기긱' 하는 마찰 소음이 발생하지 않는지 수시로 확인하고 보수하십시오."),
        ],
      ),
    );
  }

  // 📝 4단계: 나와의 약속 (체크리스트)
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 현장 담당자 회전체 점검 필수 체크리스트",
      subtitle: "기계실 문을 열기 전, 나를 점검하는 5가지 확인",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check,
      content: Column(
        children: [
          _buildPledgeItem("[복장] 소매가 펄럭이지 않게 단단히 여미고 넥타이/수건을 제거했는가?"),
          _buildPledgeItem("[안전] 회전체에 말려 들어갈 수 있는 헐렁한 면장갑을 벗었는가?"),
          _buildPledgeItem("[정지] 기계 전원을 끄고 관성 없이 완전히 멈춘 것을 눈으로 보았는가?"),
          _buildPledgeItem("[표지] 조작반에 '점검 중' 표지를 붙여 타인의 조작을 확실히 막았는가?"),
          _buildPledgeItem("[확인] 점검이 끝난 후 보호 가드(덮개)를 원래대로 튼튼하게 고정했는가?"),
        ],
      ),
    );
  }

  // 🚨 5단계: 사고 발생 시 긴급 대응
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 사고 발생 시 긴급 대응 (Emergency Response)",
      subtitle: "당황하여 억지로 당기면 신체 부위가 절단됩니다.",
      accentColor: Colors.teal,
      icon: Icons.local_hospital,
      content: Column(
        children: [
          _buildHighlightAction(Icons.do_not_touch, "끼임 사고 목격 시 (역회전 금지)", "즉시 '비상 정지' 버튼을 누르거나 메인 전원을 끄십시오. 억지로 몸을 빼려 하면 상처가 깊어집니다. 구조대의 장비 없이 임의로 기계를 역회전시키지 마십시오.", isDanger: true),
          _buildActionItem(Icons.report_problem, "보고 및 위험 요소 제거", "기계실 내부에 덮개가 없는 V벨트나 기어를 발견하면 즉시 본부에 보고하십시오. \"아직 사고 안 났으니 괜찮다\"는 침묵이 내일 동료를 다치게 합니다."),
        ],
      ),
    );
  }

  // 🔄 회전체 점검 로직 트리
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
                Icon(Icons.account_tree, color: primaryNavy),
                const SizedBox(width: 8),
                Text("회전체 점검 안전 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("기계실 입실 👉 복장/수건/면장갑 단속", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("기계 전원 차단 및 가동 금지 표지판 부착", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 정지 확인 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("🚨 관성 회전 중 (No)", "절대 접근 금지\n완전 정지 시까지 대기"),
                _buildFlowBranch("✅ 완전 정지 (Yes)", "보호 덮개 개방 및 점검 실시\n(운전 중 청소/주유 금지)"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("점검 완료 👉 덮개 완벽 체결 👉 표지판 제거 및 가동", const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // SM종합관리 디테일
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Text("✅ SM종합관리의 세심함 (기록 의무)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Divider(height: 16, color: Colors.white54),
                  Text("작업 전 올바른 복장 점검 사진(셀카) 보고\n점검 후 가드(덮개) 복구 완료 사진 일지 기록", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚨 공공기관 연락처
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
            _buildContactButton("소방서 (절단/끼임 구조)", "119", isDanger: true),
            _buildContactButton("산업안전보건공단", "1644-4544", isDanger: false),
            _buildContactButton("SM 본부 안전관리팀", "내부망 확인", isDanger: false),
          ],
        ),
      ],
    );
  }

  // --- UI 헬퍼 위젯들 ---

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