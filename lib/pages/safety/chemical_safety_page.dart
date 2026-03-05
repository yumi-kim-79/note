// [파일 위치: lib/pages/safety/chemical_safety_page.dart]
// [설명: 현장 안전 수칙 - 유해 화학물질 취급 (Enterprise Safety Protocol / KOSHA 지침 보강)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChemicalSafetyPage extends StatelessWidget {
  const ChemicalSafetyPage({super.key});

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
          "안전 수칙: 유해 화학물질",
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
              _buildStep1(), // MSDS 및 라벨링
              const SizedBox(height: 16),
              _buildStep2(), // 보호구
              const SizedBox(height: 16),
              _buildStep3(), // 혼합 금지
              const SizedBox(height: 16),
              _buildStep4(), // 환기
              const SizedBox(height: 16),
              _buildDecisionTree(), // 로직 트리
              const SizedBox(height: 16),
              _buildStep5(), // 체크리스트
              const SizedBox(height: 16),
              _buildStep6(), // 긴급 조치
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
          const Icon(Icons.science, color: Colors.white, size: 40), // 🌟 순정 과학/화학 아이콘
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"약품의 독성은 막고, 당신의 건강은 지키겠습니다.\n섞지 말고, 가리고, 환기하십시오.\n당신의 폐와 피부는 무엇보다 소중합니다.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 📋 1단계: MSDS 및 신분증 확인
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: 약품의 '신분증' 확인 - MSDS 숙지",
      subtitle: "약품의 성격을 아는 것이 사고 예방의 첫걸음입니다.",
      accentColor: safetyBlue,
      icon: Icons.library_books,
      content: Column(
        children: [
          _buildActionItem(Icons.menu_book, "MSDS(물질안전보건자료) 비치", "현장에서 사용하는 모든 약품은 MSDS가 비치되어야 합니다. 처음 보는 약품이라면 유해성, 위험성, 응급처치 요령을 반드시 먼저 읽으십시오."),
          _buildActionItem(Icons.warning, "그경고 표지(그림문자) 확인", "용기에 붙은 해골, 불꽃, 부식 기호를 확인하십시오. '이 약품이 내 몸 어디를 공격하는가?'를 아는 것만으로도 조심성이 2배로 올라갑니다."),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildHighlightAction(Icons.label_important, "소분 용기 라벨링 의무 (법적 필수)", "[산업안전보건법] 생수병이나 빈 통에 약품을 덜어 쓸 때, '경고 표지'를 붙이지 않으면 과태료 대상입니다. 남들이 음료수로 착각해 마시는 끔찍한 사고를 막기 위해 반드시 제품명과 경고를 붙이십시오.", isDanger: true),
        ],
      ),
    );
  }

  // 🥽 2단계: 전용 보호구
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: 화학 물질용 '철갑' 두르기 - 보호구",
      subtitle: "일반 면장갑이나 마스크로는 강한 화학 성분을 막을 수 없습니다.",
      accentColor: warningOrange,
      icon: Icons.sanitizer,
      content: Column(
        children: [
          _buildHighlightAction(Icons.pan_tool, "내화학 전용 장갑 착용", "면장갑이나 얇은 비닐장갑은 화학 성분이 즉시 스며듭니다. 반드시 고무나 니트릴 소재의 두꺼운 '내화학 전용 장갑'을 착용하십시오.", isDanger: true),
          _buildActionItem(Icons.visibility, "보안경은 생명입니다", "약품이 눈에 튀면 찰나의 순간에 시력을 잃을 수 있습니다. 천장 쪽으로 분무기를 뿌리거나 고농축 용액을 따를 때는 반드시 보안경을 착용하십시오."),
          _buildActionItem(Icons.masks, "방독 마스크 활용", "강한 냄새가 나는 소독제나 락스 원액을 사용할 때는 일반 덴탈 마스크가 아닌, 방독 필터가 장착된 마스크 착용을 권장합니다."),
        ],
      ),
    );
  }

  // ☠️ 3단계: 혼합 금지
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 죽음의 칵테일 제조 금지 - '혼합 절대 금지'",
      subtitle: "\"더 깨끗해지겠지\"라는 생각은 현장을 가스실로 만듭니다.",
      accentColor: dangerRed,
      icon: Icons.dangerous,
      content: Column(
        children: [
          _buildHighlightAction(Icons.science, "락스(염소계) + 산성 세제 = 염소가스(Cl2)", "락스와 변기 세정제(산성)가 섞이면 누런색의 맹독성 염소가스가 발생합니다. 한 번만 마셔도 폐에 치명상을 입고 질식할 수 있으니 절대 섞지 마십시오.", isDanger: true),
          _buildActionItem(Icons.hot_tub, "뜨거운 물 사용 주의", "락스를 뜨거운 물에 타면 성분이 급격히 분해되며 유독 가스가 대량 배출됩니다. 반드시 찬물이나 미지근한 물로 희석하십시오."),
          _buildActionItem(Icons.wash, "순차적 사용 시 충분한 헹굼", "불가피하게 한 가지 세제를 쓴 후 다른 세제를 써야 한다면, 앞선 세제를 물로 '완전히' 씻어낸 후에 다음 작업을 진행하십시오."),
        ],
      ),
    );
  }

  // 💨 4단계: 상시 환기
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 신선한 공기 확보 - '상시 환기'",
      subtitle: "밀폐된 공간에서의 약품 사용은 보이지 않는 독을 마시는 것과 같습니다.",
      accentColor: safetyBlue,
      icon: Icons.air,
      content: Column(
        children: [
          _buildActionItem(Icons.toys, "환풍기 가동 및 문 개방", "화장실, 지하실 등 좁은 곳에서 약품 작업을 할 때는 반드시 환풍기를 켜고, 입구 문을 활짝 열어 공기가 밖으로 빠져나가게 하십시오."),
          _buildActionItem(Icons.flag, "풍상(Windward) 위치 선정", "바람이 부는 야외나 통로라면 '바람을 등지고' 작업하십시오. 약품 냄새나 스프레이 가스가 내 얼굴 쪽으로 날아오지 않게 하는 것이 요령입니다."),
        ],
      ),
    );
  }

  // 📝 5단계: 체크리스트
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 현장 담당자 화학물질 필수 체크리스트",
      subtitle: "약품 뚜껑을 열기 전 확인해야 할 5가지 약속",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check,
      content: Column(
        children: [
          _buildPledgeItem("[확인] 약품 용기나 소분 페트병에 이름과 위험 표시 라벨이 정확히 붙어있는가?"),
          _buildPledgeItem("[보호] 얇은 장갑이 아닌 화학 약품용 두꺼운 고무/니트릴 장갑을 꼈는가?"),
          _buildPledgeItem("[보호] 내 눈을 보호할 보안경(또는 보안면)을 확실히 착용했는가?"),
          _buildPledgeItem("[금지] 락스와 다른 세제를 섞으려는 위험한 유혹을 완전히 뿌리쳤는가?"),
          _buildPledgeItem("[환기] 창문을 열거나 환풍기를 켜서 신선한 공기가 통하고 있는가?"),
        ],
      ),
    );
  }

  // 🚨 6단계: 긴급 조치
  Widget _buildStep6() {
    return _buildSectionCard(
      title: "6단계: 사고 발생 시 긴급 조치 (Emergency Response)",
      subtitle: "화학물질 사고의 골든타임은 15분입니다. 즉시 씻어내십시오.",
      accentColor: Colors.teal,
      icon: Icons.local_hospital,
      content: Column(
        children: [
          _buildHighlightAction(Icons.visibility_off, "눈에 들어갔을 때 (절대 비비기 금지)", "작업 시작 전 가장 가까운 수전(물 나오는 곳)을 미리 파악해 두십시오. 약품이 튀면 즉시 흐르는 물이나 식염수로 눈을 뜨고 15분 이상 씻어낸 뒤 바로 병원으로 가십시오.", isDanger: true),
          _buildActionItem(Icons.clean_hands, "피부에 묻었을 때", "오염된 옷을 즉시 벗고 다량의 흐르는 물과 비누로 피부를 깨끗이 씻어내십시오."),
          _buildActionItem(Icons.airline_seat_flat, "가스를 마셨을 때", "즉시 신선한 공기가 있는 야외로 이동하고, 호흡이 곤란하다면 본부에 알린 뒤 즉시 119를 불러 병원 진료를 받으십시오."),
        ],
      ),
    );
  }

  // 🔄 화학물질 안전 취급 프로세스
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
                Text("화학물질 안전 취급 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("약품 작업 발생 👉 MSDS 및 소분 라벨 확인", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("내화학장갑 / 보안경 / 마스크 등 보호구 착용", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 혼합 여부 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("🚨 두 종류 이상 약품 사용", "👉 절대 혼합 금지\n👉 물로 씻은 뒤 순차 사용"),
                _buildFlowBranch("✅ 단일 약품 사용", "👉 정해진 찬물 희석 비율 준수"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("환기 시설 가동(문 개방) 👉 작업 실시 및 징후 감시", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("사용 완료 후 잔여물 헹굼 및 라벨 용기 보관", const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // SM종합관리 디테일
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Text("✅ SM종합관리의 건강 배려 (증빙)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Divider(height: 16, color: Colors.white54),
                  Text("보호구(장갑/보안경) 착용 인증샷 일지 등록\n소분 용기 라벨 및 환기 완료 사진 기록", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
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
            _buildContactButton("응급의료/독성정보", "1339", isDanger: true), // 과거 1339가 현재 119 구급상황관리센터로 통합되었으나 정보 차원에서 기재
            _buildContactButton("산업안전보건공단", "1644-4544", isDanger: false),
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