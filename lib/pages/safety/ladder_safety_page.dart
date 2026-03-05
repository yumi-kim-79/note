// [파일 위치: lib/pages/safety/ladder_safety_page.dart]
// [설명: 현장 안전 수칙 No.03 - 고소(사다리 및 옥상) 작업 (Enterprise Safety Protocol / KOSHA 지침 보강)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LadderSafetyPage extends StatelessWidget {
  const LadderSafetyPage({super.key});

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
          "안전 수칙: 고소(사다리/옥상) 작업",
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
              _buildStep1(), // 사다리 작업
              const SizedBox(height: 16),
              _buildStep2(), // 옥상 작업
              const SizedBox(height: 16),
              _buildStep3(), // 바닥/신발 점검
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
          const Icon(Icons.architecture, color: Colors.white, size: 40), // 🌟 순정 아이콘 (건축/구조)
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"높은 곳에서의 작업은 기술보다 안전이 먼저입니다.\n당신이 딛는 발판 하나, 잡는 난간 하나에\nSM종합관리의 철저함이 담겨야 합니다.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 🪜 1단계: 사다리 작업의 정석 (KOSHA 최신 지침 보강)
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: 사다리 작업의 정석 - 'A형'과 '2인 1조'",
      subtitle: "사다리는 이동 수단이지 작업대가 아닙니다. 불가피한 작업 시 법적 철칙을 지키십시오.",
      accentColor: warningOrange,
      icon: Icons.height, // 🌟 순정 아이콘 (높이)
      content: Column(
        children: [
          _buildActionItem(Icons.change_history, "반드시 A형 사다리만 사용", "일자형 사다리를 벽에 기대어 작업하는 것은 미끄러짐 사고의 주범입니다. 반드시 벌어짐 방지 장치가 확실히 고정된 A형 사다리만 사용하십시오."),
          _buildHighlightAction(Icons.people, "2인 1조 (선택 아닌 필수)", "한 명은 위에서 작업하고, 다른 한 명은 아래에서 사다리를 단단히 지탱하며 주변 보행자를 통제하는 '안전 감시관' 역할을 겸해야 합니다.", isDanger: true),
          _buildActionItem(Icons.do_not_step, "최상단 발판은 '금지의 구역'", "사다리 맨 꼭대기 칸에 올라서면 무게 중심이 흔들려 추락합니다. 반드시 꼭대기에서 두 번째 칸 이하에서만 작업하십시오."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("⚠️ KOSHA (안전보건공단) 법적 추가 지침", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
          const SizedBox(height: 12),
          _buildHighlightAction(Icons.security, "안전모 의무 및 3.5m 이상 금지", "사다리 작업 시 '안전모' 착용은 법적 의무입니다. 또한 3.5m 이상의 높이에서는 사다리를 작업대로 사용할 수 없으며, 반드시 고소작업대(렌탈)를 이용해야 합니다.", isDanger: true),
        ],
      ),
    );
  }

  // 🏢 2단계: 옥상 작업의 생명선 (채광창 위험 추가)
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: 옥상 작업의 생명선 - '난간'과 '안전고리'",
      subtitle: "옥상은 강풍과 노후된 시설물로 인해 예기치 못한 사고가 빈번합니다.",
      accentColor: dangerRed,
      icon: Icons.domain, // 🌟 순정 아이콘 (건물/옥상)
      content: Column(
        children: [
          _buildActionItem(Icons.front_hand, "난간을 믿지 말고 테스트하라", "옥상 난간은 안쪽이 부식된 경우가 많습니다. 손으로 짚기 전, 발로 하단을 툭툭 쳐보거나 흔들어보아 하중을 견딜 수 있는지 먼저 확인하십시오."),
          _buildHighlightAction(Icons.link, "난간 밖 작업 시 '생명줄' 체결", "난간 근처나 밖으로 몸을 내밀 때는 전신형 안전그네(하네스)를 착용하고, 튼튼한 구조물에 연결된 생명줄에 안전고리를 반드시 체결하십시오.", isDanger: true),
          _buildActionItem(Icons.air, "기상 상황 엄수", "강풍(초속 10m 이상)이 불거나 비가 내려 바닥이 미끄러울 때는 옥상 작업을 즉시 중단하십시오. 어떤 상황도 당신의 안전보다 급하지 않습니다."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildHighlightAction(Icons.wb_sunny, "채광창(썬라이트) 밟기 절대 금지", "[추락사망 1위 원인] 옥상에 설치된 플라스틱 채광창은 햇빛에 삭아 밟는 순간 부서집니다. 채광창 주변 1m 이내 접근을 금지하십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 🥾 3단계: 바닥 및 신발 점검
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 추락 방지를 위한 '바닥 및 신발' 점검",
      subtitle: "안전한 고소 작업은 가장 낮은 곳, 당신의 발밑에서 시작됩니다.",
      accentColor: safetyBlue,
      icon: Icons.foundation, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.straighten, "바닥 수평 확인", "사다리를 설치할 바닥이 경사지거나 미끄럽지 않은지 확인하십시오. 부득이한 경우 수평을 맞출 수 있는 안전 보조 장치를 활용해야 합니다."),
          _buildActionItem(Icons.clean_hands, "안전화 상태 점검", "안전화 바닥에 기름기나 진흙이 묻어있으면 사다리 발판에서 미끄러지기 쉽습니다. 올라가기 전 신발 바닥을 한 번 닦아내는 여유가 필요합니다."),
        ],
      ),
    );
  }

  // 📝 4단계: 나와의 약속 (체크리스트)
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 현장 담당자 고소 작업 필수 체크리스트",
      subtitle: "발을 떼기 전, 스마트폰으로 확인하는 5가지 생명선",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildPledgeItem("[장비] A형 사다리의 고정 고리와 벌어짐 방지끈이 튼튼한가?"),
          _buildPledgeItem("[보호] 작업 전 안전모의 턱끈을 확실하게 조였는가?"),
          _buildPledgeItem("[인원] 사다리 하단을 잡아줄 동료와 소통이 준비되었는가?"),
          _buildPledgeItem("[금지] 무의식중에 사다리 맨 꼭대기에 올라가려 하지는 않는가?"),
          _buildPledgeItem("[확인] 옥상 난간의 부식을 테스트하고, 채광창(썬라이트)을 우회했는가?"),
          _buildPledgeItem("[생명] 난간 근처 작업 시 내 몸을 잡아줄 안전고리를 걸었는가?"),
        ],
      ),
    );
  }

  // 🛡️ 5단계: 사고 발생 시 긴급 대응
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 사고 발생 시 긴급 대응 (Emergency Response)",
      subtitle: "침착한 대응이 2차 손상과 법적 책임을 막습니다.",
      accentColor: Colors.teal,
      icon: Icons.healing, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.medical_services, "추락 사고 발생 시 (절대 안정)", "부상자를 무리하게 일으키려 하지 마십시오. 척추/경추 부상 위험이 있으므로 즉시 119에 신고하고 구조대원이 올 때까지 곁을 지키십시오.", isDanger: true),
          _buildActionItem(Icons.report, "보고의 중요성 및 현장 보존", "경미한 미끄러짐이라도 본부에 보고하십시오. 또한 중대재해 조사를 위해 119 후송 후 사고 현장(사다리 등)을 임의로 치우지 말고 보존 및 사진 촬영을 하십시오."),
        ],
      ),
    );
  }

  // 🔄 고소 작업 안전 판단 로직 (Mermaid to UI)
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
                Text("고소 작업 안전 판단 로직", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("고소 작업 발생 (사다리 또는 옥상)", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 분기점
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("사다리 사용 (3.5m 이하)", "👉 A형 사다리 및 안전모 필수\n👉 2인 1조 배치 및 최상단 탑승 금지"),
                _buildFlowBranch("옥상 작업", "👉 난간 부식 발/손으로 테스트\n👉 채광창(썬라이트) 접근 금지"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("안전 장구(안전고리/하네스) 체결 후 작업 진행", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // SM종합관리 철저함
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Text("✅ SM종합관리의 철저함 (기록 의무)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Divider(height: 16, color: Colors.white54),
                  Text("작업 전 2인 1조 배치 사진 채증\n안전고리(생명줄) 체결 상태 사진 일지 등록", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
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
            _buildContactButton("소방서 (긴급구조)", "119", isDanger: true),
            _buildContactButton("산업안전보건공단", "1644-4544", isDanger: false),
            _buildContactButton("SM 본부 안전관리팀", "내부망 확인", isDanger: false),
          ],
        ),
      ],
    );
  }

  // --- [신규 디자인 양식] UI 헬퍼 위젯들 ---

  // 🎨 좌측 컬러 포인트가 있는 새로운 섹션 카드 (멈춤 버그 해결된 버전)
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

  // 🌟 버튼 크기 강제 통일
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