// [파일 위치: lib/pages/safety/confined_space_safety_page.dart]
// [설명: 현장 안전 수칙 - 정화조 및 밀폐공간 진입 (Enterprise Safety Protocol / KOSHA 지침 보강)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfinedSpaceSafetyPage extends StatelessWidget {
  const ConfinedSpaceSafetyPage({super.key});

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
          "안전 수칙: 밀폐공간 진입",
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
              _buildStep1(), // 가스 측정 및 방폭
              const SizedBox(height: 16),
              _buildStep2(), // 강제 환기
              const SizedBox(height: 16),
              _buildStep3(), // 생명줄 및 작업허가제
              const SizedBox(height: 16),
              _buildDecisionTree(), // 로직 트리
              const SizedBox(height: 16),
              _buildStep4(), // 체크리스트
              const SizedBox(height: 16),
              _buildStep5(), // 동반 사망 차단 긴급 대응
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
          const Icon(Icons.warning, color: Colors.white, size: 40), // 🌟 순정 아이콘
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"밀폐공간에서 가장 무서운 것은 가스가 아니라\n'괜찮겠지'라는 방심입니다.\n당신이 마시는 공기, 우리가 책임지고 확인하겠습니다.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 🧪 1단계: 가스 측정 및 폭발 방지 (KOSHA 방폭 지침 보강)
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: 진입 전 '공기 상태' 수치화 (Gas & Explosion)",
      subtitle: "눈에 보이지 않고 냄새도 없습니다. 오직 가스 측정기 데이터만 믿으십시오.",
      accentColor: warningOrange,
      icon: Icons.speed, // 🌟 순정 계기판 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.looks_3, "3-3-3 가스 측정 원칙", "① 3개 지점: 입구, 중간, 바닥면 (가스별 무게가 다름)\n② 3가지 수치: 산소(18~23.5%), 황화수소(10ppm 미만), 일산화탄소(30ppm 미만)\n③ 3회 반복: 진입 전, 작업 중 수시, 휴식 후 재진입 시 필수 측정", isDanger: false),
          _buildActionItem(Icons.volume_up, "경보음은 '절대 금지' 신호", "단 한 번이라도 경보음이 울린다면, 수치가 정상화될 때까지 절대 진입하지 마십시오. 당신의 폐는 가스 정화기가 아닙니다."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("⚠️ KOSHA 방폭(폭발 방지) 필수 지침", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
          const SizedBox(height: 12),
          _buildHighlightAction(Icons.flash_off, "일반 랜턴 및 스마트폰 조작 금지", "정화조 내부는 메탄가스(가연성)가 가득 차 있습니다. 일반 랜턴 전원을 켜거나 폰을 떨어뜨려 스파크가 튀면 폭발합니다. 반드시 '방폭 인증 장비'만 사용하십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 💨 2단계: 강제 환기
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: 강제 환기 - '15분의 기다림' (Ventilation)",
      subtitle: "신선한 공기를 밀어 넣지 않으면 죽은 공기가 당신을 질식시킵니다.",
      accentColor: safetyBlue,
      icon: Icons.air, // 🌟 순정 바람/공기 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.timer, "15분 강제 환기 법칙", "송풍기(Sirocco Fan) 가동 후 최소 15분 이상 공기를 순환시키십시오. 썩은 공기가 완전히 밀려 나가는 최소한의 시간입니다.", isDanger: true),
          _buildActionItem(Icons.autorenew, "작업 중 상시 가동", "진입 후 절대 송풍기를 끄지 마십시오. 부유물이나 퇴적물을 건드리는 순간 새로운 유독 가스가 바닥에서 올라옵니다."),
          _buildActionItem(Icons.vertical_align_bottom, "급기 중심 환기", "배기(빨아들이기)보다는 급기(밀어 넣기) 방식으로 송풍구 끝을 작업자의 호흡기(바닥 쪽) 근처에 위치시키십시오."),
        ],
      ),
    );
  }

  // 🪢 3단계: 생명줄과 신호수 (KOSHA 작업허가제 보강)
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 생명줄과 신호수 - '고립 방지' (Support)",
      subtitle: "밖에 지켜보는 눈이 없다면, 그것은 작업이 아니라 도박입니다.",
      accentColor: dangerRed,
      icon: Icons.people, // 🌟 순정 사람/팀 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.engineering, "외부 신호수(감시인) 배치", "입구에는 안의 동료와 소통할 신호수를 배치하십시오. 신호수는 절대 자리를 비우거나 다른 업무를 병행해선 안 됩니다."),
          _buildHighlightAction(Icons.link, "구조용 로프 및 하네스 착용", "만약의 사태에 대비해 전신형 안전그네를 착용하고 구조용 삼각대에 연결하십시오. 밖에서 끌어올릴 수 있는 유일한 생명선입니다.", isDanger: true),
          _buildActionItem(Icons.ring_volume, "1분 간격 교신", "작업자와 신호수는 1분 간격으로 대화하거나 수신호를 주고받아 의식 상태를 수시로 확인하십시오."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("⚠️ KOSHA 밀폐공간 작업허가제 (법적 의무)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
          const SizedBox(height: 12),
          _buildHighlightAction(Icons.assignment_turned_in, "임의 개방 절대 금지 (사전 승인)", "밀폐공간은 관리감독자(현장소장 등)가 장비, 환기, 인원을 확인한 후 '작업허가서'를 발급하기 전까지 맨홀 뚜껑 개방 자체가 불법입니다.", isDanger: true),
        ],
      ),
    );
  }

  // 📝 4단계: 현장 담당자 체크리스트
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 밀폐공간 진입 필수 체크리스트",
      subtitle: "맨홀을 열기 전, 스마트폰으로 최종 점검하십시오.",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check,
      content: Column(
        children: [
          _buildPledgeItem("[허가] 관리감독자의 사전 작업허가를 득하고 맨홀을 개방했는가?"),
          _buildPledgeItem("[측정] 가스 측정기의 유효기간이 지나지 않았고, 배터리가 충분한가?"),
          _buildPledgeItem("[환기] 송풍기를 켜고 15분이 지났으며, 송풍구가 내부 깊숙이 향해 있는가?"),
          _buildPledgeItem("[인원] 내가 안에 있을 때 나를 지켜봐 줄 신호수가 입구에 고정 배치되었는가?"),
          _buildPledgeItem("[보호] 사고 발생 시 나를 끌어올려 줄 생명줄이 내 하네스에 단단히 연결되었는가?"),
          _buildPledgeItem("[소통] 외부 신호수와 주고받을 수신호나 방폭 무전기 상태는 양호한가?"),
        ],
      ),
    );
  }

  // 🚨 5단계: 사고 발생 시 긴급 대응
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 사고 발생 시 긴급 대응 (Emergency Response)",
      subtitle: "동료를 살리려다 당신도 죽습니다. 철저히 절차에 따르십시오.",
      accentColor: Colors.teal,
      icon: Icons.local_hospital, // 🌟 순정 구급/병원 아이콘
      content: Column(
        children: [
          _buildHighlightAction(Icons.do_not_step, "구조를 위한 임의 진입 절대 금지!", "밀폐공간 질식 사고 사망자의 절반(50%) 이상은 쓰러진 동료를 구조하러 맨몸으로 들어간 동료입니다! 절대로 뛰어들지 마십시오.", isDanger: true),
          _buildActionItem(Icons.support, "FM 구조 원칙", "즉시 119에 신고 👉 송풍기를 최대 출력으로 가동 👉 외부에서 구조용 삼각대/로프를 이용해 끌어올리기 👉 공기호흡기(SCBA) 없이는 진입 금지."),
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
                Text("밀폐공간 안전 작업 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("작업허가 득 👉 환기구 개방 및 송풍기 가동", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("15분 강제 환기 실시", "내부 공기 완전 순환"),
                _buildFlowBranch("3-3-3 가스 측정", "산소/유해가스 3개 지점 확인"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 가스 측정 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("🚨 산소 부족 / 가스 감지", "👉 진입 금지 및 환기 지속/재측정"),
                _buildFlowBranch("✅ 정상 수치 도달", "👉 전신 하네스 및 생명줄 착용 진행"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("외부 신호수 배치 👉 진입 👉 작업 중 지속 환기/측정/교신", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("작업 완료 및 퇴장 보고 (허가서 종료)", const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // SM종합관리 디테일
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Text("✅ SM종합관리의 생명선 (증거 보존)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Divider(height: 16, color: Colors.white54),
                  Text("진입 전 가스 측정기 수치 화면 사진 채증\n입구 신호수 고정 배치 및 생명줄 체결 사진 기록", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
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
            _buildContactButton("소방서 (구급/구조)", "119", isDanger: true),
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