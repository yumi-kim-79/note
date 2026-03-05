// [파일 위치: lib/pages/manual/defect_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.08 - 하자 민원 대응 (Enterprise / 100% 호환 순정 아이콘 및 법무부/국토부 기준 보강 버전)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DefectManualPage extends StatelessWidget {
  const DefectManualPage({super.key});

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
          "현장 대응 매뉴얼: 하자 민원",
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
              _buildDecisionTree(), // 사고 대응 프로세스 (UI 로직)
              const SizedBox(height: 16),
              _buildStep5(),
              const SizedBox(height: 16),
              _buildStep6(), // 악성 민원인 특별 대응 가이드
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
              Icon(Icons.flag, color: Colors.white, size: 24), // 🌟 순정
              SizedBox(width: 8),
              Text("최종 목표", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          Text("1. 법적 근거에 기반한 정확한 책임 소재 판정\n2. 불필요한 관리회사/관리단 지출 원천 차단\n3. 민원인과의 감정 소모 방지 및 방어 증거 확보",
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  // 🗣️ 1단계: 민원 접수 시 초기 응대
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 민원 접수 시 초기 응대 (Reception)",
      icon: Icons.headset, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("담당자는 민원 접수 시 절대 \"고쳐주겠다\"는 확답이나 긍정을 해서는 안 됩니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20), // 🌟 순정
                    SizedBox(width: 8),
                    Text("표준 응대 멘트 (FM)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                SizedBox(height: 8),
                Text("\"불편을 드려 죄송합니다. 우선 현장을 방문하여 하자의 원인이 '전유부분(세대 내)'인지 '공용부분(건물 전체)'인지 법적 기준에 따라 먼저 확인해 드리겠습니다.\"",
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF334155), height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildHighlightBox(Icons.block, "절대 금지 멘트 (책임 인정)", "\"저희가 바로 처리해 드릴게요\", \"관리소에서 수리업체 알아봐서 보내드릴게요\" 👉 원인 파악 전 회사의 책임으로 전가되는 치명적 실수임", isDanger: true),
        ],
      ),
    );
  }

  // 🔍 2단계: 현장 실사 및 원인 판별 (국토부/법무부 기준 보강)
  Widget _buildStep2() {
    return _buildCard(
      title: "2단계: 현장 실사 및 법적 원인 판별 (Diagnosis)",
      icon: Icons.search, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("현장을 방문하여 하자의 위치와 원인을 과학적·법적 근거로 분류합니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.build, "육안 및 장비 검사", "누수 탐지기, 열화상 카메라 등을 활용하여 하자가 어디서 시작되었는지 최초 발원지 추적"),

          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("⚖️ 판별 기준 (집합건물법 및 대법원 판례)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          _buildCaseBox("전유부분 (Private)", "소유자 개별 책임", "• 세대 현관문 안쪽 공간, 개별 창틀, 마감재\n• 대법원 판례: '계량기 밸브 이후 세대 내부로 인입되는 바닥 배관'은 전유부분으로 판시함"),
          const SizedBox(height: 8),
          _buildCaseBox("공용부분 (Common)", "관리단 공동 책임", "• 옥상 방수층, 외벽 크랙, 계단실, 엘리베이터\n• 세대 간 연결되는 수직 메인 배관(입상관), 주차장"),
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.apartment, "시공사 책임 (하자담보책임기간)", "신축/준신축의 경우, 부위에 따라 2~10년(마감재 2년, 방수 5년, 내력구조 10년 등) 내 발생한 하자는 시공사에 보수 청구 (국토부 기준)", isWarning: true),
        ],
      ),
    );
  }

  // 📊 3단계: 정확한 책임 소재 분류표
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: 정확한 책임 소재 분류표 (Liability)",
      icon: Icons.account_balance, // 🌟 순정 (법원/은행 느낌)
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("담당자가 입주민의 무리한 요구를 차단할 때 제시할 '법적 책임 가이드라인'입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          // Enterprise Table
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("하자 유형", "세부 내용", "책임 주체", isHeader: true),
                _buildTableRow("옥상/외벽 누수", "옥상 방수층 균열, 외벽 크랙으로 인한 침수", "관리단\n(장충금/수선비)"),
                _buildTableRow("내부 배관 누수", "세대 바닥 난방관, 수도 가지관 파손", "소유자\n(자비 수리 원칙)"),
                _buildTableRow("창틀 누수", "세대 개별 창틀 코킹 노후로 인한 빗물 유입", "소유자\n(전유부 소모품)"),
                _buildTableRow("층간 소음", "바닥 충격음, 세대 내 생활 소음 진동", "입주민 당사자\n(관리소는 중재만)"),
                _buildTableRow("결로/곰팡이", "환기 미비(사용자 과실) vs 단열 불량(시공사)", "정밀 진단 후\n책임자 배정"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📝 4단계: 상황별 대응 프로세스
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: 상황별 대응 프로세스 (Step-by-Step)",
      icon: Icons.assignment, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCaseBox("상황 A", "공용부 하자로 판명될 때",
              "• 조치 안내: \"확인 결과 건물 외벽(또는 옥상) 문제로 확인되었습니다. 관리단 의결(또는 대표 승인) 절차를 거쳐 수리 계획을 수립하겠습니다.\"\n"
                  "• 기록: 수선 내역과 견적서를 투명하게 관리하여 차후 관리비 부과 근거 마련"),
          const SizedBox(height: 12),
          _buildCaseBox("상황 B", "전유부 하자로 판명될 때 (가장 중요)",
              "• 거절의 기술: \"확인 결과 세대 내부 배관 노후로 인한 하자입니다. 집합건물법 제11조 및 관리규약에 따라 소유자께서 직접 보수하셔야 하는 부분입니다.\"\n"
                  "• 대안 제시: \"필요하시다면 검증된 외부 수리 업체 리스트를 안내해 드릴 수는 있으나, 계약 및 결제는 직접 진행하셔야 합니다.\""),
        ],
      ),
    );
  }

  // 🔄 하자 판별 및 대응 로직 (Mermaid to Enterprise UI)
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
                Icon(Icons.account_tree, color: Color(0xFF475569)), // 🌟 순정
                SizedBox(width: 8),
                Text("하자 판별 및 대응 로직 흐름도", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("하자 민원 접수 👉 현장 방문 및 원인 실사", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 1차 분기점
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("공용부분 (옥상/외벽/입상관)", "👉 관리사무소 조치 및 비용 부담\n👉 보수 업체 견적 및 관리단 승인"),
                _buildFlowBranch("전유부분 (세대내부/창틀)", "👉 소유자 직접 자비 수리 안내\n👉 책임 소재 고지 및 면책 증빙"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("최종 수리 완료 확인 및 결과 보고", const Color(0xFFE2E8F0)),
            const SizedBox(height: 16),

            // SM종합관리 기록
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
              child: const Column(
                children: [
                  Text("✅ SM종합관리 법적 방어 (증거 수집)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Divider(height: 16),
                  Text("• 실사 사진(열화상 등) 및 판정 근거 일지 필수 저장\n• 전유부 하자의 경우 입주민 확인서 또는 안내 문자 캡처 보관", style: TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 5단계: 현장 담당자 필수 확인사항 (체크리스트)
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 현장팀 필수 확인사항 (Check-list)",
      icon: Icons.playlist_add_check, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChecklistItem("[채증] 하자의 최초 발생 시점과 현재 상태 사진 촬영 완료"),
          _buildChecklistItem("[판정] 집합건물법 기준에 따른 전용/공용 분류 명시"),
          _buildChecklistItem("[고지] 전용부 하자의 경우, 소유주에게 직접 수리 의무가 있음을 정중히 고지"),
          _buildChecklistItem("[기록] 입주민의 억지 주장이나 욕설 등이 있을 경우 녹취 또는 상세 일지 작성", isAlert: true),
          _buildChecklistItem("[보험] 공용부 하자로 인한 세대 피해 시, 건물 화재보험(특약) 적용 가능 여부 검토"),
        ],
      ),
    );
  }

  // 🛡️ 6단계: 악성 민원인 특별 대응 가이드 (국토부/형법 근거 추가)
  Widget _buildStep6() {
    return _buildCard(
      title: "6단계: 악성 민원인 특별 대응 요령 (Special Guide)",
      icon: Icons.security, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("관리회사와 직원을 보호하기 위한 강력한 방어 및 절연 절차입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.mail, "내용증명 등 서면 대응", "구두 설명에도 불구하고 억지를 부린다면, '책임 소재 판정 통보서'를 내용증명 등 공식 문건으로 발송하여 분쟁을 조기 차단하십시오."), // 🌟 순정
          _buildInfoRow(Icons.menu_book, "정확한 법령 인용", "\"본 건물이 '공동주택법'인지 '집합건물법'인지 확인 후 대응 / 예) 본 상가/오피스텔은 '집합건물법' 제5조에 따라 전유부 수선 의무가 소유자에게 있습니다\"라고 명확히 선을 긋습니다."), // 🌟 순정
          _buildHighlightBox(Icons.money_off, "무료 수리 (배임) 절대 불가", "\"좋은 게 좋은 거다\"라며 회사 돈이나 타 입주민의 관리비로 특정 세대의 전유부를 고쳐주면, 담당자 및 회사의 업무상 배임죄가 성립될 수 있음을 강조하십시오.", isDanger: true),
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.gavel, "형사 고발 경고 (최후 수단)", "폭언, 업무 마비, 난동 지속 시 형법 제314조(업무방해) 및 제311조(모욕죄)에 의거하여 경찰 출동 및 형사 고발 조치됨을 엄중 고지합니다.", isDanger: true),
        ],
      ),
    );
  }

  // 🚨 관련 기관 연락처
  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text("🚨 법률 및 행정 지원 연락처", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildContactButton("대한법률구조공단", "132", isDanger: false),
            _buildContactButton("국토교통부 민원콜", "1599-0001", isDanger: false),
            _buildContactButton("하자심사분쟁위원회", "031-910-4200", isDanger: false),
            _buildContactButton("경찰서 (업무방해)", "112", isDanger: true),
          ],
        ),
      ],
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
        icon: Icon(Icons.phone, size: 20, color: itemColor), // 🌟 순정
        label: Text("$title\n$number", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: itemColor, height: 1.3)),
        onPressed: isCallable ? () => _makePhoneCall(number) : null,
      ),
    );
  }

  // --- 공통 UI 헬퍼 위젯들 ---

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

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, height: 1.5),
                children: [
                  TextSpan(text: "$title: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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

  // 📊 책임 소재 표(Table) UI
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
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col3, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13), textAlign: TextAlign.center))),
        ],
      ),
    );
  }

  // ✅ 체크리스트 UI
  Widget _buildChecklistItem(String text, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isAlert ? Icons.warning : Icons.check_box, color: isAlert ? Colors.red.shade600 : primaryNavy, size: 22), // 🌟 순정
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 15, color: isAlert ? Colors.red.shade800 : const Color(0xFF1E293B), fontWeight: isAlert ? FontWeight.bold : FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}