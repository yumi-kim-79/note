// [파일 위치: lib/pages/guide/field_standard_manual_page.dart]
// [설명: 현장 업무 표준 매뉴얼 (PDF 기반 + FM/법적 기준 보강 시각화 SOP)]

import 'package:flutter/material.dart';

class FieldStandardManualPage extends StatelessWidget {
  const FieldStandardManualPage({super.key});

  // 🏢 대기업 표준 메인 컬러 팔레트
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);
  final Color dangerRed = const Color(0xFFDC2626);
  final Color warningOrange = const Color(0xFFEA580C);
  final Color successGreen = const Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "현장 업무 표준 매뉴얼",
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
              _buildStep1_Arrival(), // 현장 도착 행동 요령
              const SizedBox(height: 16),
              _buildStep2_Notice(), // 공문 부착 규격 (시각화)
              const SizedBox(height: 16),
              _buildStep3_Seasonal(), // 계절별 선행 준비 (여름/겨울)
              const SizedBox(height: 16),
              _buildDecisionTree(), // 점검 및 민원 처리 로직 트리
              const SizedBox(height: 16),
              _buildStep4_Inspection(), // 5대 구역 점검 리스트
              const SizedBox(height: 16),
              _buildStep5_Responsibility(), // 전유부 vs 공용부
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
          const Icon(Icons.menu_book, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text("SM종합관리 현장 표준 지침", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"건물의 가치는 당신의 첫걸음에서 시작됩니다.\n규격을 지키는 단정함과 선제적인 점검이\n입주민의 무한한 신뢰를 만듭니다.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 🚶‍♂️ 1. 현장 도착 표준 행동
  Widget _buildStep1_Arrival() {
    return _buildSectionCard(
      title: "1. 현장 도착 즉시 행동 요령",
      subtitle: "건물의 첫인상을 결정하는 가장 중요한 초기 루틴입니다.",
      accentColor: safetyBlue,
      icon: Icons.directions_walk,
      content: Column(
        children: [
          _buildActionItem(Icons.cleaning_services, "청결 상태 1차 점검", "1층 현관, 분리수거장, 주차장, 승강기 내부 청소 상태 확인. 미흡 시 청소업체에 즉각 후속 조치 요청."),
          _buildActionItem(Icons.markunread_mailbox, "방치 우편물 회수", "공용 우편함 및 반송함에 쌓인 장기 방치 우편물과 불법 전단지를 즉시 회수 및 폐기 처리."),
          _buildActionItem(Icons.support_agent, "입주민 대표/관리단 소통", "현장 진입 시 입주민 대표에게 연락하여 현재 건물 상태를 보고하고 추가 특이사항 유무 확인."),
        ],
      ),
    );
  }

  // 📄 2. 승강기 공문 부착 규격
  Widget _buildStep2_Notice() {
    return _buildSectionCard(
      title: "2. 공문 게시 표준 규격 (Visual SOP)",
      subtitle: "가장 잘 보이는 곳에, 가장 정갈하게 부착합니다.",
      accentColor: warningOrange,
      icon: Icons.elevator,
      content: Column(
        children: [
          // 승강기 내부 시각화 UI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                const Text("🏢 승강기 내부 부착 우선순위", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildElevatorWall("1순위", "좌측면 벽", true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildElevatorWall("2순위", "우측면 벽", false)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildElevatorWall("3순위", "정면 (거울 불가 시)", false)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionItem(Icons.height, "부착 높이: 상단 1,600mm", "1번 공문(좌측 상단)의 최고 높이를 성인 어깨 높이인 160cm에 맞춥니다."),
          _buildActionItem(Icons.space_dashboard, "공문 간격: 상하좌우 20mm(2cm)", "문서들이 다닥다닥 붙지 않도록 일정한 여백(2cm)을 유지하여 가독성을 높입니다."),
          _buildHighlightAction(Icons.warning, "소방법 저촉 주의 (필독)", "공문 부착 시 비상호출버튼, 시각장애인용 점자판, 소방 비상구출 안내문을 절대 가리지 않도록 주의하십시오.", isDanger: true),
          _buildActionItem(Icons.restore_page, "철저한 회수 관리", "게시 기한이 지난 공문은 테이프 자국이 남지 않도록 즉시 깔끔하게 회수하여 건물 철에 3년간 보관합니다."),
        ],
      ),
    );
  }

  // 🌤️❄️ 3. 계절별 선행 준비
  Widget _buildStep3_Seasonal() {
    return _buildSectionCard(
      title: "3. 계절별 선행 점검 (사전 재해 예방)",
      subtitle: "사고가 터지기 전, 미리 장비를 비치하고 점검합니다.",
      accentColor: successGreen,
      icon: Icons.ac_unit,
      content: Column(
        children: [
          const Text("☔ 하절기 대비 (장마/수해 - 6월 전 완료)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
          const Divider(height: 16),
          _buildActionItem(Icons.water_drop, "배수로 및 집수정 점검", "옥상 배수로의 낙엽/진흙 등 오물을 제거하고, 지하 집수정 배수 펌프의 정상 가동 및 수위 센서를 테스트합니다."),
          _buildActionItem(Icons.layers, "수해 모래주머니 확보", "단지 내 모래주머니 상태를 점검하고, 부족 시 관할 행정복지센터에서 선제적으로 수령하여 비치합니다."),
          const SizedBox(height: 24),

          const Text("⛄ 동절기 대비 (한파/폭설 - 11월 전 완료)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          const Divider(height: 16),
          _buildActionItem(Icons.snowing, "제설 장비 및 염화칼슘 비치", "눈삽, 넉가래, 빗자루 상태를 점검합니다. 단, 에폭시(코팅) 바닥이나 노출 콘크리트에는 염화칼슘 도포를 절대 금지합니다 (부식 위험)."),
          _buildHighlightAction(Icons.local_fire_department, "열선(히팅케이블) 화재 예방 점검", "[소방 기준] 동파 방지용 열선은 절대 겹쳐 감지 않아야 하며, 반드시 누전차단기에 단독 연결되어 있는지 확인하십시오. 화재 원인 1위입니다.", isDanger: true),
        ],
      ),
    );
  }

  // 📋 4. 5대 구역 점검 리스트
  Widget _buildStep4_Inspection() {
    return _buildSectionCard(
      title: "4. 현장 5대 구역 필수 점검 사항",
      subtitle: "순회 시 반드시 눈으로 확인해야 할 체크리스트입니다.",
      accentColor: primaryNavy,
      icon: Icons.fact_check,
      content: Column(
        children: [
          _buildPledgeItem("[현관/주차장] 도어로비폰, 주차장 바닥 균열, 배수시설, 센서등 점등 상태"),
          _buildPledgeItem("[승강기/주차타워] 승강기 합격필증 부착, 버튼 조명, 주차타워 파렛트 부식 상태"),
          _buildPledgeItem("[옥상] 바닥 방수 균열, 난간 부식(추락 위험), 기계실 및 중계기 고정 상태"),
          _buildPledgeItem("[계단/복도] 비상유도등 작동, 수도검침함, 소방법 위반 자전거/적재물 방치 여부"),
          _buildPledgeItem("[지하 설비실] 방재실 소방수신기 경고등, 물탱크실 누수, 전기실 잠금장치 확인"),
        ],
      ),
    );
  }

  // ⚖️ 5. 전유부 vs 공용부 책임 소재 (Table)
  Widget _buildStep5_Responsibility() {
    return _buildSectionCard(
      title: "5. 책임 소재: 전유부 vs 공용부 구분",
      subtitle: "입주민 민원 응대 시 분쟁을 막는 명확한 기준입니다.",
      accentColor: dangerRed,
      icon: Icons.balance,
      content: Column(
        children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("구분", "의미 및 책임 소재", "주요 해당 구역", isHeader: true),
                _buildTableRow("전유부\n(세대 내부)", "주택 소유자가 독점 소유\n(입주민 개별 사비 처리)", "세대 내부 방, 화장실, 창고, 베란다, 테라스, 각종 계량기 기기 자체"),
                _buildTableRow("공용부\n(세대 외부)", "주택 소유자 공동 소유\n(SM종합관리 유지보수 진행)", "로비, 승강기, 주차장, 옥상, 외벽, 계량기함(PD/EPS) 문짝 및 전단 배관"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildHighlightAction(Icons.announcement, "테라스 및 계량기 관련 특이사항", "도면상 공용부라도 특정 세대만 독점 사용하는 테라스는 전유부로 판단합니다. 계량기 자체는 전유부이나, 계량기로 들어오는 메인 배관(입상관)은 공용부입니다.", isDanger: false),
        ],
      ),
    );
  }

  // 🔄 업무 프로세스 로직 트리
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
                Text("하자 점검 및 민원 처리 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("점검 중 하자 발견 또는 입주민 민원 접수 (앱 확인)", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("일반 점검 등록 (+)", "하자 내용 기재 및 전/중/후 사진 첨부"),
                _buildFlowBranch("할당 민원 접수", "앱에서 '접수하기' 눌러 진행중 변경"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("하자 보수 즉각 실시 및 조치 완료", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("앱에서 '완료 처리' 및 정중한 답변/사진 업로드", const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // SM종합관리 디테일
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Text("✅ 완벽한 민원 답변 템플릿", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Divider(height: 16, color: Colors.white54),
                  Text("\"안녕하세요 SM종합관리 OO대리입니다.\n현장 확인 결과 (원인)을 파악하여 (조치 내용)을 완료하였습니다.\n확인 후 추가 문제 시 언제든 연락 바랍니다. 감사합니다.\"", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI 헬퍼 위젯들 ---

  Widget _buildElevatorWall(String rank, String text, bool isHighlight) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
          color: isHighlight ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(color: isHighlight ? safetyBlue : const Color(0xFFCBD5E1), width: isHighlight ? 2 : 1),
          borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        children: [
          Text(rank, style: TextStyle(color: isHighlight ? safetyBlue : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

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

  Widget _buildTableRow(String col1, String col2, String col3, {bool isHeader = false}) {
    final bgColor = isHeader ? const Color(0xFFF1F5F9) : Colors.white;
    final textColor = isHeader ? const Color(0xFF1E293B) : const Color(0xFF475569);
    final fontWeight = isHeader ? FontWeight.bold : FontWeight.normal;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col1, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13), textAlign: TextAlign.center))),
          Container(width: 1, height: 80, color: const Color(0xFFE2E8F0)),
          Expanded(flex: 4, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col2, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13)))),
          Container(width: 1, height: 80, color: const Color(0xFFE2E8F0)),
          Expanded(flex: 4, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col3, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13)))),
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