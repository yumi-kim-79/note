// [파일 위치: lib/pages/safety/heavy_load_safety_page.dart]
// [설명: 현장 안전 수칙 - 중량물 취급 및 운반 (Enterprise Safety Protocol / KOSHA 지침 보강)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HeavyLoadSafetyPage extends StatelessWidget {
  const HeavyLoadSafetyPage({super.key});

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
          "안전 수칙: 중량물 취급",
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
              _buildStep1(), // 인체공학적 자세 & 스트레칭
              const SizedBox(height: 16),
              _buildStep2(), // 20kg 법칙 & 반복 하중
              const SizedBox(height: 16),
              _buildStep3(), // 이동 경로 확보
              const SizedBox(height: 16),
              _buildDecisionTree(), // 로직 트리
              const SizedBox(height: 16),
              _buildStep4(), // 체크리스트
              const SizedBox(height: 16),
              _buildStep5(), // 긴급 조치
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
          const Icon(Icons.fitness_center, color: Colors.white, size: 40), // 🌟 순정 무게/덤벨 아이콘
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"당신의 허리는 SM종합관리의 기둥입니다.\n무거운 것은 기계와 동료에게 맡기고,\n당신의 몸을 가장 먼저 아끼십시오.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 🦵 1단계: 인체공학적 자세 (KOSHA 스트레칭 보강)
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: 허리를 지키는 '인체공학적 자세' (Ergonomics)",
      subtitle: "허리만 숙이는 것은 척추에 수백 kg의 하중을 때리는 것과 같습니다.",
      accentColor: safetyBlue,
      icon: Icons.accessibility, // 🌟 순정 자세/사람 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.pan_tool, "무릎으로 드십시오", "허리를 꼿꼿이 세운 상태에서 무릎을 굽혀 앉은 뒤, 물건을 잡고 '다리 힘'으로 밀고 일어나야 합니다. (스쿼트 자세 응용)", isDanger: false),
          _buildActionItem(Icons.compress, "내 몸에 밀착", "물건이 몸에서 멀어질수록 허리가 받는 무게는 몇 배로 늘어납니다. 가슴과 배 쪽으로 최대한 끌어당겨 무게 중심을 두십시오."),
          _buildActionItem(Icons.compare_arrows, "발의 너비", "어깨너비보다 조금 넓게 벌려 단단히 지지하고, 한 발을 약간 앞으로 내어 무게 중심을 잡으십시오."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("⚠️ KOSHA 근골격계 질환 예방 지침", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
          const SizedBox(height: 12),
          _buildHighlightAction(Icons.sports_gymnastics, "작업 전 3분 스트레칭 필수", "차가운 상태의 굳은 인대로 무거운 것을 들면 즉각 파열됩니다. 작업 전 반드시 허리, 무릎, 손목 스트레칭을 3분간 실시하십시오.", isDanger: true),
        ],
      ),
    );
  }

  // ⚖️ 2단계: 20kg 법칙 (KOSHA 반복 작업 기준 보강)
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: '20kg 법칙'과 보조 장비 (Teamwork)",
      subtitle: "자신의 힘을 과신하지 마십시오. 규정된 무게를 넘으면 도구를 쓰십시오.",
      accentColor: warningOrange,
      icon: Icons.local_shipping, // 🌟 순정 운반/트럭 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.people, "20kg 초과 시 2인 1조", "쌀 한 포대(20kg)가 넘는 펌프나 모터는 절대 혼자 들지 마십시오. '하나, 둘, 셋!' 신호에 맞춰 동료와 함께 들어야 무게가 쏠리지 않습니다.", isDanger: true),
          _buildActionItem(Icons.shopping_cart, "대차(구루마/핸드카) 적극 활용", "바퀴가 달린 이동 도구가 있다면 5m 거리라도 반드시 활용하십시오. 들고 가는 것보다 밀고 가는 것이 관절 보호에 훨씬 유리합니다."),
          _buildActionItem(Icons.front_hand, "미끄럼 방지 장갑", "미끄러운 금속체인 펌프 등을 들 때는 마찰력이 강한 코팅 장갑을 착용하여 놓침 사고(발등 골절)를 예방하십시오."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildHighlightAction(Icons.repeat, "반복 작업 시 무게 제한 (KOSHA 기준)", "하루 10회 이상 지속적으로 운반해야 하는 작업(수처리 소금 포대 등)의 경우, 1인당 한계 중량을 10~15kg으로 낮추어 적용해야 합니다.", isDanger: false),
        ],
      ),
    );
  }

  // 🚧 3단계: 이동 경로 확보
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 이동 경로의 '장애물 제거' (Path Clearance)",
      subtitle: "무거운 것을 들고 있을 때는 시야가 좁아집니다. 길을 먼저 닦으십시오.",
      accentColor: primaryNavy,
      icon: Icons.directions_walk, // 🌟 순정 보행/경로 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.search, "사전 경로 확인", "물건을 들기 전, 내가 지나갈 지하실/기계실 바닥에 젖은 곳이나 턱, 발에 걸릴 호스 등이 없는지 먼저 눈으로 확인하십시오."),
          _buildHighlightAction(Icons.rotate_right, "허리 급회전 절대 금지", "물건을 든 상태에서 허리만 홱 돌리는 동작은 디스크 파열의 1순위 주범입니다. 방향을 바꿀 때는 '발'을 움직여 몸 전체를 회전시키십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 📝 4단계: 체크리스트
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 중량물 취급 필수 체크리스트",
      subtitle: "물건을 들어 올리기 전, 스마트폰으로 확인하는 5가지",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check,
      content: Column(
        children: [
          _buildPledgeItem("[자세] 허리를 숙이지 않고 무릎을 굽혀 물건을 잡았는가?"),
          _buildPledgeItem("[밀착] 물건을 내 몸쪽으로 최대한 바짝 당겼는가?"),
          _buildPledgeItem("[무게] 20kg이 넘는다면 동료를 부르거나 구루마를 가져왔는가?"),
          _buildPledgeItem("[경로] 이동 동선에 미끄러운 물기나 발에 걸릴 물건이 없는가?"),
          _buildPledgeItem("[보호] 안전화를 착용하여 물건을 놓쳤을 때의 발가락 부상을 예방했는가?"),
        ],
      ),
    );
  }

  // 🚨 5단계: 사고 발생 시 긴급 조치
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 부상 발생 시 긴급 조치 (Emergency Response)",
      subtitle: "참는 것은 미덕이 아닙니다. 즉각 보고가 원칙입니다.",
      accentColor: Colors.teal,
      icon: Icons.healing,
      content: Column(
        children: [
          _buildHighlightAction(Icons.airline_seat_flat, "허리 통증 발생 시", "즉시 모든 작업을 중단하고 편안한 바닥에 눕거나 앉으십시오. \"조금 더 참으면 되겠지\"라는 생각이 평생의 장애를 부릅니다.", isDanger: true),
          _buildActionItem(Icons.personal_injury, "낙하 사고 시 (발등 골절)", "발등에 물건이 떨어졌다면 무리하게 걷지 말고 그 자리에 앉아 신발을 벗어 붓기를 확인하십시오. 냉찜질 후 즉시 병원을 방문하십시오."),
        ],
      ),
    );
  }

  // 🔄 프로세스 로직 트리
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
                Text("중량물 운반 안전 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("중량물 운반 상황 발생 👉 3분 스트레칭 실시", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 무게 분기점
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("🚨 무게 20kg 이상 (Yes)", "👉 무조건 동료 호출 (2인 1조)\n👉 또는 구루마(대차) 확보"),
                _buildFlowBranch("✅ 무게 20kg 미만 (No)", "👉 혼자 들되, 무릎을 굽히는\n인체공학적 자세 숙지"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("이동 경로 시야 확보 및 바닥 장애물/물기 제거", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("무릎 굽히기 👉 가슴 밀착 👉 다리 힘으로 들기 👉 서행 이동", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("목적지 하차 완료 (급회전 금지)", const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // SM종합관리 디테일
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Text("✅ SM종합관리의 배려 (건강 기록)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Divider(height: 16, color: Colors.white54),
                  Text("펌프 등 대형 교체 시 2인 1조 작업 사진 기록\n안전모/안전화 등 보호구 착용 상태 보고", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
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
            _buildContactButton("소방서 (긴급구조)", "119", isDanger: true),
            _buildContactButton("가까운 정형외과", "지도 검색", isDanger: false),
            _buildContactButton("SM 본부 안전관리팀", "내부망 확인", isDanger: false),
          ],
        ),
      ],
    );
  }

  // --- UI 헬퍼 위젯들 (무한 높이 멈춤 에러 방지 적용 완료) ---

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