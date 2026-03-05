// [파일 위치: lib/pages/safety/fire_work_safety_page.dart]
// [설명: 현장 안전 수칙 - 화기 및 연마 작업 (Enterprise Safety Protocol / KOSHA 지침 보강)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FireWorkSafetyPage extends StatelessWidget {
  const FireWorkSafetyPage({super.key});

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
          "안전 수칙: 화기/연마 작업",
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
              _buildStep1(), // 방화 구획 (11m 법적 기준 보강)
              const SizedBox(height: 16),
              _buildStep2(), // 방화포 및 화재감시자 보강
              const SizedBox(height: 16),
              _buildStep3(), // 보호구
              const SizedBox(height: 16),
              _buildStep4(), // 30분 사후 감시
              const SizedBox(height: 16),
              _buildDecisionTree(), // 로직 트리
              const SizedBox(height: 16),
              _buildStep5(), // 체크리스트
              const SizedBox(height: 16),
              _buildStep6(), // 긴급 대응
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
          const Icon(Icons.local_fire_department, color: Colors.white, size: 40), // 🌟 순정 화재/소방 아이콘
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"불꽃은 통제될 때 기술이 되고, 방치될 때 재앙이 됩니다.\n작업이 끝난 후에도\n당신의 눈은 불씨를 찾아야 합니다.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 🔥 1단계: 방화 구획 설정 (KOSHA 11m 기준 보강)
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: 완벽한 '방화 구획' 설정 (Fire Zone)",
      subtitle: "불꽃이 튀는 반경 내에 탈 수 있는 것은 단 하나도 남기지 마십시오.",
      accentColor: dangerRed,
      icon: Icons.not_interested, // 🌟 순정 금지 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.architecture, "반경 11m 인화물질 완전 제거", "[KOSHA 법적 기준] 용접 불티는 최대 11m까지 비산합니다. 반경 11m 이내의 종이박스, 폐유, 보온재 등을 모두 치우고, 치울 수 없는 설비는 방화포로 덮으십시오.", isDanger: true),
          _buildActionItem(Icons.fire_extinguisher, "소화기 전진 배치", "'어딘가에 있겠지'는 안 됩니다. 대형 ABC 분말 소화기 2대 이상을 작업자의 손이 즉시 닿는 위치(2m 이내)에 세워두십시오."),
          _buildActionItem(Icons.speed, "가연성 가스 확인", "지하 정화조, 배수 펌프실, 도장 작업 근처라면 반드시 가스 농도를 측정하여 폭발 위험을 사전 차단하십시오."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildHighlightAction(Icons.assignment_turned_in, "화기작업 사전 허가제", "불꽃을 일으키는 모든 작업은 현장소장(관리감독자)의 사전 '화기작업 허가서' 발급 및 서명 없이는 절대 실시할 수 없습니다.", isDanger: true),
        ],
      ),
    );
  }

  // 🛡️ 2단계: 불꽃 확산 차단 및 화재감시자 (보강)
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: 불꽃 확산 차단 및 감시 (Spark Control)",
      subtitle: "불꽃은 생각보다 멀리, 그리고 깊숙이 날아갑니다.",
      accentColor: warningOrange,
      icon: Icons.shield, // 🌟 순정 방패 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.policy, "화재감시자 지정 및 배치", "[법적 의무] 작업자 외에 불꽃의 튐과 확산을 전문적으로 감시할 '화재감시자'를 반드시 1명 이상 배치해야 합니다. 감시자는 소화기를 들고 대기합니다.", isDanger: true),
          _buildActionItem(Icons.layers, "불꽃 비산 방지 덮개 (방화포)", "불꽃이 튀는 방향에 내화성 방화포(Fire Blanket)나 불연성 차단막을 꼼꼼히 설치하여 인접한 전선이나 보온재를 보호하십시오."),
          _buildActionItem(Icons.arrow_downward, "하부 수평 공간 주의", "위에서 작업할 경우 불꽃이 아래층이나 틈새로 떨어져 보이지 않는 곳에서 발화할 수 있습니다. 하부 공간에도 방화포를 깔거나 감시인을 두십시오."),
        ],
      ),
    );
  }

  // 🥽 3단계: 전문가의 방패
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 전문가의 방패 - '보호구' 착용 (PPE)",
      subtitle: "불꽃으로부터 당신의 시력과 호흡기를 보호하는 것은 타협 불가 조건입니다.",
      accentColor: safetyBlue,
      icon: Icons.face_retouching_natural, // 🌟 순정 안면 보호 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.visibility, "안구 및 안면 보호", "용접 시에는 전용 용접면을, 그라인더 작업 시에는 파편이 눈에 박히지 않도록 얼굴 전체를 가리는 '보안면'을 반드시 착용하십시오."),
          _buildActionItem(Icons.masks, "방진 및 방독 마스크", "금속 가루나 용접 흄(연기)은 폐에 치명적인 중금속 덩어리입니다. 반드시 KOSHA 인증 1급 이상의 방진 마스크를 착용하십시오."),
          _buildActionItem(Icons.checkroom, "불연성 작업복/가죽 장갑", "나일론 등 합성섬유 옷은 불티에 녹아 피부에 늘어붙습니다. 면 소재/불연 작업복과 반드시 '가죽제 용접 장갑'을 착용하십시오."),
        ],
      ),
    );
  }

  // ⏱️ 4단계: 사후 감시
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 숨은 불씨 찾기 - '30분 사후 감시'",
      subtitle: "화기 작업의 종료는 연장이 멈췄을 때가 아니라, 불씨가 완전히 사라졌을 때입니다.",
      accentColor: primaryNavy,
      icon: Icons.timer, // 🌟 순정 타이머 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.search, "최소 30분 이상 잔류 불씨 감시", "작업 후 즉시 철수하지 마십시오. 우레탄 폼이나 보온재 내부로 들어간 불티는 산소를 만나 천천히 타들어가다 30분 뒤 대형 화재로 번집니다.", isDanger: false),
          _buildActionItem(Icons.thermostat, "열기 및 연기 감지", "화재감시자는 현장에 남아 작업 부위의 온도가 충분히 내려갔는지 확인하고, 타는 냄새가 없는지 최종 점검 후 철수하십시오."),
        ],
      ),
    );
  }

  // 📝 5단계: 체크리스트
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 화기 작업 필수 체크리스트",
      subtitle: "불꽃을 일으키기 전, 나를 점검하는 5가지 확인",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check,
      content: Column(
        children: [
          _buildPledgeItem("[허가] 관리사무소장(관리감독자)의 사전 화기작업 승인을 받았는가?"),
          _buildPledgeItem("[환경] 작업 주변 반경 11m 이내에 가연물(종이/기름 등)을 모두 치웠는가?"),
          _buildPledgeItem("[차단] 불티가 튀지 않게 방화포를 치고, 화재감시자(소화기 지참)를 배치했는가?"),
          _buildPledgeItem("[보호] 내 눈과 폐를 지킬 보안면과 방진 마스크를 올바르게 착용했는가?"),
          _buildPledgeItem("[마무리] 작업이 끝난 후 30분 동안 현장에 남아 숨은 불씨를 감시했는가?"),
        ],
      ),
    );
  }

  // 🚨 6단계: 사고 발생 시 긴급 대응
  Widget _buildStep6() {
    return _buildSectionCard(
      title: "6단계: 사고 발생 시 긴급 대응 (Emergency Response)",
      subtitle: "초기 1분의 진압이 건물 전체를 구합니다.",
      accentColor: Colors.teal,
      icon: Icons.campaign, // 🌟 순정 확성기/알림 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.fire_extinguisher, "초기 발화 시 즉각 진압", "당황하지 말고 전진 배치한 소화기를 사용하여 즉시 진압하십시오. 초기 1분의 소화기 한 대는 소방차 열 대의 위력과 같습니다."),
          _buildHighlightAction(Icons.warning, "대형 화재 전조 시 신속 대피", "불길이 소화기로 감당 안 될 조짐이 보이면 즉시 \"불이야!\" 외치고, 수신반 경보기를 작동시킨 후 대피하여 119에 신고하십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 🔄 화기 작업 로직 트리
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
                Text("화기/연마 작업 안전 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("화기작업 허가서 승인 득 👉 반경 11m 인화물 제거", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("방화포/비산 방지막 설치", "상하부 틈새 완벽 차단"),
                _buildFlowBranch("화재감시자 및 소화기 배치", "즉시 투입 가능한 2m 이내"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 보호구 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("🚨 보호구 미비 (No)", "👉 작업 절대 금지 및 장비 수령"),
                _buildFlowBranch("✅ 보안면/마스크 완비 (Yes)", "👉 화기 작업 실시"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("작업 완료 후 화재감시자 주도 '30분 잔불 감시'", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("최종 안전(온도) 확인 후 현장 철수", const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // SM종합관리 디테일
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Text("✅ SM종합관리의 철두철미 (법적 증거)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Divider(height: 16, color: Colors.white54),
                  Text("소화기 전진 배치 및 방화포 덮은 현장 사진 보고\n작업 종료 후 30분 사후 감시 일지 기록", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
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
            _buildContactButton("소방서 (화재/구급)", "119", isDanger: true),
            _buildContactButton("산업안전보건공단", "1644-4544", isDanger: false),
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