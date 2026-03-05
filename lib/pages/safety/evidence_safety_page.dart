// [파일 위치: lib/pages/safety/evidence_safety_page.dart]
// [설명: 현장 안전 수칙 - 현장 채증 및 사후 복구 (Enterprise Safety Protocol / 개인정보보호법 보강)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EvidenceSafetyPage extends StatelessWidget {
  const EvidenceSafetyPage({super.key});

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
          "안전 수칙: 채증 및 사후 복구",
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
              _buildStep1(), // 타임스탬프 및 개인정보 보호 보강
              const SizedBox(height: 16),
              _buildStep2(), // 잔해물 회수
              const SizedBox(height: 16),
              _buildStep3(), // 공구 확인 및 원상복구
              const SizedBox(height: 16),
              _buildDecisionTree(), // 로직 트리
              const SizedBox(height: 16),
              _buildStep4(), // 체크리스트
              const SizedBox(height: 16),
              _buildStep5(), // 법적 책임 (Table UI 적용)
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
          const Icon(Icons.camera_alt, color: Colors.white, size: 40), // 🌟 순정 카메라 아이콘
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"현장을 떠날 때 당신이 남겨야 할 것은\n오직 '완벽한 결과'와 '빈틈없는 기록'뿐입니다.\n당신의 기록이 SM종합관리의 정직함을 증명합니다.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 📸 1단계: 타임스탬프 채증 (개인정보보호법 보강)
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: 법적 면책의 핵심 - '타임스탬프' 디지털 기록",
      subtitle: "\"나중에 찍어야지\"는 늦습니다. 모든 공정은 실시간으로 기록되어야 효력을 갖습니다.",
      accentColor: safetyBlue,
      icon: Icons.access_time, // 🌟 순정 시계/시간 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.collections, "전/중/후 3단계 촬영 법칙", "① 작업 전(Before): 하자의 원인과 최초 상태 명확히 촬영\n② 작업 중(During): 내부 보강 등 보이지 않는 곳의 수리 과정 촬영\n③ 작업 후(After): 수리 완료 및 주변 정돈 상태 촬영"),
          _buildHighlightAction(Icons.gps_fixed, "타임스탬프 앱 필수 사용", "날짜, 시각, GPS 위치가 자동으로 찍히는 전용 앱을 사용하십시오. 악성 민원인이 \"예전 사진 아니냐\"고 억지 부릴 때 내놓을 '불변의 증거'입니다.", isDanger: false),
          _buildActionItem(Icons.zoom_in, "확대와 전체 샷 병행", "고장 난 미세한 부분(확대)과 해당 위치가 어디인지 알 수 있는 전체 배경(원거리)을 함께 남겨야 상황 재구성이 가능합니다."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("⚠️ 개인정보보호법 준수 (SM 필수 지침)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
          const SizedBox(height: 12),
          _buildHighlightAction(Icons.person_off, "사생활 및 개인정보 촬영 절대 금지", "세대 내부 촬영 시 입주민의 얼굴, 거울에 비친 모습, 가족사진 등이 찍히면 형사 고발 대상이 됩니다. 주차장에서는 타 차량 번호판이 찍히지 않도록 오직 수리 부위만 제한적으로 촬영하십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 🧹 2단계: 100% 잔해물 회수
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: 사고를 예방하는 '100% 잔해물 회수'",
      subtitle: "남겨진 작은 나사 하나가 아이의 발을 찌를 수 있습니다.",
      accentColor: warningOrange,
      icon: Icons.cleaning_services, // 🌟 순정 청소 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.brush, "'자석 자루'와 '솔' 활용", "전선 쪼가리, 피복 조각, 금속 가루는 눈에 띄지 않습니다. 작업 후 반드시 자석이나 빗자루, 진공청소기로 주변을 완벽히 청소하십시오."),
          _buildActionItem(Icons.delete, "보온재 및 폐부품 회수", "뜯어낸 보온재나 고장 난 부품을 단지 내 쓰레기장에 방치하지 마십시오. 반드시 수거 전용 봉투에 담아 본부/지정된 장소로 회수하십시오."),
          _buildHighlightAction(Icons.water_damage, "수분 완벽 제거 (낙상 방지)", "누수 작업이나 청소 후 바닥에 남은 물기는 반드시 마른걸레로 닦아내어 입주민의 미끄러짐(낙상) 사고를 원천 차단하십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 🧰 3단계: 공구 인벤토리 및 원상복구
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 내 장비는 내가 챙긴다 - '공구 인벤토리'",
      subtitle: "비싼 장비를 두고 오면 자산 손실이자, 타인의 안전 위협입니다.",
      accentColor: primaryNavy,
      icon: Icons.home_repair_service, // 🌟 순정 수리/공구함 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.format_list_numbered, "공구 개수 최종 확인", "작업 시작 전 꺼냈던 공구의 개수와 종료 후 가방에 넣은 공구의 개수가 일치하는지 마지막으로 세어보십시오."),
          _buildHighlightAction(Icons.lock, "시설물 완벽 원상복구", "열었던 기계실 문, 점검구 덮개, 조작반 도어 등이 꽉 닫히고 잠겨 있는지 확인하십시오. '열려 있는 문'은 관리 부실의 첫 번째 신호입니다.", isDanger: true),
        ],
      ),
    );
  }

  // 📝 4단계: 체크리스트
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 현장 담당자 마무리 필수 체크리스트",
      subtitle: "현장을 떠나기 전, 뒤돌아서서 확인하는 5가지",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check,
      content: Column(
        children: [
          _buildPledgeItem("[사진] 작업 전, 중, 후 사진이 타임스탬프와 함께 모두 찍혔는가?"),
          _buildPledgeItem("[청소] 바닥에 나사, 전선 피복, 물기 등 위험 요소가 전혀 없는가?"),
          _buildPledgeItem("[회수] 내 공구 가방에 빠진 공구가 없는지 대조 확인했는가?"),
          _buildPledgeItem("[복구] 점검구, 기계실 문, 조작반 덮개를 모두 원래대로 닫고 잠갔는가?"),
          _buildPledgeItem("[보고] 수리 결과에 대해 입주민(또는 본부)에게 설명하고 확인받았는가?"),
        ],
      ),
    );
  }

  // ⚖️ 5단계: 법적 책임 및 관리자의 품격 (Table UI)
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 법적 책임 및 관리자의 품격 (Liability)",
      subtitle: "우리의 꼼꼼함이 회사를 법적 분쟁에서 구합니다.",
      accentColor: dangerRed,
      icon: Icons.gavel, // 🌟 순정 법봉 아이콘
      content: Column(
        children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("구분 (항목)", "부실 관리 시 발생 리스크", "SM종합관리 방어 전략", isHeader: true),
                _buildTableRow("사진 기록 부재", "수리 범위 및 원인에 대한 분쟁, 악성 민원 발생", "타임스탬프 앱 기반 3단계 채증 데이터 제출"),
                _buildTableRow("잔해물 방치", "입주민 낙상 또는 찔림 사고 시 막대한 배상 책임", "청소/물기 제거 완료 후의 깨끗한 현장 사진 촬영"),
                _buildTableRow("시설물 개방", "외부인 침입 감전 사고 및 설비 파손 리스크", "최종 도어 잠금 상태 확인 및 일지 기록 제출"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔄 작업 종료 로직 트리
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
                Text("작업 종료 및 사후 복구 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("현장 작업 완료 👉 완료 상태 최종 확인", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("타임스탬프 채증", "전/중/후 및 개인정보 차단"),
                _buildFlowBranch("잔해물 100% 제거", "나사, 전선, 바닥 수분 제거"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 공구 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("🚨 남겨진 공구 발견 (Yes)", "👉 가방 수납 및 폐기물 회수"),
                _buildFlowBranch("✅ 현장 정리 완벽 (No)", "👉 시설물 문/덮개 잠금 확인"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("입주민/관리단 최종 확인 및 서명 👉 본부 보고 후 철수", const Color(0xFFE2E8F0)),
            const SizedBox(height: 16),

            // SM종합관리 디테일
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Text("✅ SM종합관리의 신뢰 구축", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Divider(height: 16, color: Colors.white54),
                  Text("채증 데이터 본사 서버 실시간 저장 (분쟁 차단)\n고객 만족도 및 확인 서명 기록 영구 보존", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚨 공공기관 연락처 (보고망)
  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text("🚨 업무 종료 후 필수 보고망", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildContactButton("SM 본부 관제센터", "내부망 확인", isDanger: false),
            _buildContactButton("관리단 대표/소장", "연락처 확인", isDanger: false),
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

  // 📊 책임 소재 표(Table) UI 생성 헬퍼
  Widget _buildTableRow(String col1, String col2, String col3, {bool isHeader = false}) {
    final bgColor = isHeader ? const Color(0xFFF1F5F9) : Colors.white;
    final textColor = isHeader ? const Color(0xFF1E293B) : const Color(0xFF475569);
    final fontWeight = isHeader ? FontWeight.bold : FontWeight.normal;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col1, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13), textAlign: TextAlign.center))),
          Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
          Expanded(flex: 5, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col2, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13)))),
          Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
          Expanded(flex: 4, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col3, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13), textAlign: TextAlign.center))),
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