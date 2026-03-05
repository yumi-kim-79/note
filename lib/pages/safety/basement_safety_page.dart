// [파일 위치: lib/pages/safety/basement_safety_page.dart]
// [설명: 현장 안전 수칙 No.02 - 지하실 및 계단실 순회 (Enterprise Safety Protocol 양식)]

import 'package:flutter/material.dart';

class BasementSafetyPage extends StatelessWidget {
  const BasementSafetyPage({super.key});

  // 🏢 대기업 안전 규정용 컬러 팔레트
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);
  final Color dangerRed = const Color(0xFFDC2626);
  final Color warningOrange = const Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "안전 수칙: 지하실 및 계단실 순회",
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
              _buildStep1(),
              const SizedBox(height: 16),
              _buildStep2(),
              const SizedBox(height: 16),
              _buildStep3(), // 🌟 KOSHA 지침(가스/감전) 보강된 3단계
              const SizedBox(height: 16),
              _buildDecisionTree(),
              const SizedBox(height: 16),
              _buildStep4(),
              const SizedBox(height: 16),
              _buildStep5(),
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
          const Icon(Icons.flashlight_on, color: Colors.white, size: 40), // 🌟 순정 랜턴 아이콘
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"어둠 속에서도 당신의 안전은 빛나야 합니다.\n조명이 없는 곳에 첫발을 내딛기 전,\n당신의 안전 장비를 먼저 믿을 수 있게 준비하십시오.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 🔦 1단계: 시야 확보
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: 어둠을 밝히는 '시야 확보' (Visual First)",
      subtitle: "지하실은 바닥의 단차나 고인 물이 보이지 않아 대형 사고로 이어질 수 있습니다.",
      accentColor: safetyBlue,
      icon: Icons.visibility,
      content: Column(
        children: [
          _buildActionItem(Icons.highlight, "헤드랜턴 사용 권장", "두 손이 자유로워야 비상시 대처가 가능합니다. 진입 전 배터리 잔량을 확인하고 헤드랜턴을 착용하십시오."),
          _buildActionItem(Icons.radar, "먼저 비추고 나중에 움직일 것", "문을 열자마자 발을 들이지 마십시오. 불빛으로 바닥의 물기, 기름때, 튀어나온 배관을 먼저 확인하는 것이 '프로'입니다."),
          _buildActionItem(Icons.battery_charging_full, "예비 광원 소지", "메인 조명이 꺼질 경우를 대비해 스마트폰 플래시 외에 보조 소형 라이트를 반드시 주머니에 소지하십시오."),
        ],
      ),
    );
  }

  // 🚶 2단계: 3점 지지 보행
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: 흔들림 없는 '3점 지지 보행' (Stability)",
      subtitle: "계단에서의 추락은 뇌진탕이나 골절 등 치명적인 부상으로 직결됩니다.",
      accentColor: warningOrange,
      icon: Icons.stairs, // 🌟 순정 계단 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.pan_tool, "난간은 당신의 생명줄입니다", "가파른 지하 계단이나 습기가 많은 곳에서는 반드시 한 손으로 난간을 잡으십시오. 양손에 짐을 들고 이동하는 것은 사고를 부르는 지름길입니다.", isDanger: true),
          _buildHighlightAction(Icons.phonelink_erase, "스마트폰 사용 절대 금지", "계단을 오르내리며 통화나 문자를 하는 것은 눈을 가리고 걷는 것과 같습니다. 스마트폰은 평지에서만 사용하십시오."),
          _buildHighlightAction(Icons.snowshoeing, "미끄럼 주의 (Slip-Watch)", "지하실 바닥은 결로로 항상 젖어 있을 수 있습니다. 보폭을 줄이고, 발바닥 전체로 지면을 누르듯 천천히 이동하십시오."),
        ],
      ),
    );
  }

  // 📡 3단계: 사전 예고제 및 환경 통제 (KOSHA 지침 추가)
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 고립을 막는 '사전 예고제' 및 환경 통제",
      subtitle: "아무도 모르는 곳에서 사고가 나면 구조가 늦어집니다. 알리는 것이 '생존'입니다.",
      accentColor: dangerRed,
      icon: Icons.record_voice_over,
      content: Column(
        children: [
          _buildActionItem(Icons.send_to_mobile, "진입 보고 필수", "\"OO빌라 지하 저수조 진입합니다. 10분 뒤 나오겠습니다.\"라고 팀 단톡방이나 본부에 반드시 알리십시오."),
          _buildHighlightAction(Icons.timer, "10분의 골든타임", "진입 보고 후 10분 내에 '퇴장 완료' 보고가 없다면, 팀원은 즉시 전화를 걸거나 현장을 확인해야 합니다.", isDanger: true),
          _buildActionItem(Icons.architecture, "머리 위 돌출물 주의", "지하실은 배관이나 덕트가 낮습니다. 고성능 전등으로 머리 위를 수시로 확인하여 충돌을 예방하십시오."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("⚠️ 추가 위험 환경 통제 (SM 전문 지침)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.air, "밀폐공간 악취/가스 확인", "문을 열었을 때 심한 악취나 메탄 가스 냄새가 난다면 절대 진입하지 말고, 환기팬을 먼저 가동하십시오."),
          _buildActionItem(Icons.flash_on, "침수 구역 감전 주의", "바닥에 물이 발목 이상 차올랐다면 숨겨진 배수펌프 전선 등에 의한 감전 위험이 큽니다. 메인 전원을 차단하기 전까지 물에 들어가지 마십시오."),
        ],
      ),
    );
  }

  // 📝 4단계: 나와의 약속 (체크리스트)
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 현장 담당자 스스로 체크하는 순회 리스트",
      subtitle: "어둠 속으로 들어가기 전, 나를 지키는 5가지 질문",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check,
      content: Column(
        children: [
          _buildPledgeItem("[밝기] 조명이 없는 곳에서 내 발밑과 머리 위를 환하게 비출 수 있는가?"),
          _buildPledgeItem("[지지] 계단을 이용할 때 한 손은 항상 난간을 잡고 있는가?"),
          _buildPledgeItem("[금지] 계단 이동 중에 무의식적으로 스마트폰을 보고 있지는 않은가?"),
          _buildPledgeItem("[소통] 내가 지금 지하실에 들어간다는 사실을 누군가 알고 있는가?"),
          _buildPledgeItem("[안전] 내 작업화 바닥이 미끄럽지는 않은지, 닳지는 않았는지 확인했는가?"),
          _buildPledgeItem("[환경] 환기가 안 된 집수정이나 젖은 바닥의 감전 위험을 먼저 살폈는가?"), // 추가된 항목
        ],
      ),
    );
  }

  // 🛡️ 5단계: 사고 발생 시 지원
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 사고 발생 시 대응 (Emergency Support)",
      subtitle: "회사는 당신의 빠른 쾌유와 안전을 위해 모든 지원을 아끼지 않습니다.",
      accentColor: Colors.teal,
      icon: Icons.healing,
      content: Column(
        children: [
          _buildActionItem(Icons.sos, "고립되었다면", "당황하지 말고 소지한 전등으로 입구 쪽을 비추거나, 벽/배관을 두드려 소리를 내고 비상벨이 있다면 작동시키십시오."),
          _buildActionItem(Icons.medical_services, "부상 시", "무리하게 움직여 2차 손상(골절 악화 등)을 입지 말고, 본부에 사고 사실을 즉시 알려 119 구급대를 기다리십시오."),
        ],
      ),
    );
  }

  // 🔄 순회 안전 가이드 로직
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
                Text("지하/계단실 순회 안전 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("지하/계단실 진입 전", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 준비 단계
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("1. 장비 확인", "조명 기구(랜턴) 작동 점검"),
                _buildFlowBranch("2. 진입 보고", "팀원/본부에 진입 사실 공지"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 시야 확보 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("시야 확보 실패 (No)", "👉 진입 즉시 중단 및 조명 보강"),
                _buildFlowBranch("시야 확보 완료 (Yes)", "👉 3점 지지(난간 잡기) 보행으로 진입"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("작업/순회 중 (스마트폰 금지 & 머리 위 주의)", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 퇴장 및 지원 체계
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("정상 퇴장 시", "👉 본부에 '퇴장 완료' 보고\n👉 다음 현장으로 무사히 이동"),
                _buildFlowBranch("🚨 10분 무응답 시", "👉 본부/팀원의 긴급 확인 체계 가동"),
              ],
            ),
          ],
        ),
      ),
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
      // 🌟 [핵심] 높이 무한대 에러 방지용 IntrinsicHeight
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