// [파일 위치: lib/pages/guide/field_inspection_checklist_page.dart]
// [설명: 현장 업무 가이드 - 표준 건물시설 정기점검표 (이론 및 가이드라인 전용)]

import 'package:flutter/material.dart';

class FieldInspectionChecklistPage extends StatelessWidget {
  const FieldInspectionChecklistPage({super.key});

  // 🏢 대기업 표준 컬러
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);
  final Color dangerRed = const Color(0xFFDC2626);
  final Color warningOrange = const Color(0xFFF59E0B);
  final Color successGreen = const Color(0xFF10B981);
  final Color residentTagColor = const Color(0xFF10B981); // 상주/매일
  final Color patrolTagColor = const Color(0xFFF59E0B);   // 순회/주기

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "건물시설 정기점검표 (SOP 가이드)",
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
              _buildDocumentHeader(),
              const SizedBox(height: 24),
              _buildStep1_Safety(), // 1. 안전 및 준비
              const SizedBox(height: 16),
              _buildDecisionTree(), // 2. 점검 동선 프로세스
              const SizedBox(height: 16),
              _buildStep2_Checklists(), // 3. 구역별 정밀 점검 (이론)
              const SizedBox(height: 16),
              _buildStep3_ExpertTips(), // 4. FM 전문가 팁
              const SizedBox(height: 16),
              _buildStep4_AdminAction(), // 5. 행정 조치 가이드
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 📄 문서 헤더
  Widget _buildDocumentHeader() {
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
          const Icon(Icons.verified_user, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text("건물·시설물 통합 정기점검표", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text("• 점검 대상: 공용부 전체 및 기계/전기 설비\n• 점검 원칙: 육안 점검, 오감 점검(소음, 진동), 타임스탬프 채증", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  // 🛡️ 1. 점검 전 필수 안전 확인
  Widget _buildStep1_Safety() {
    return _buildSectionCard(
      title: "1. 점검 전 필수 안전 확인 (Safety First)",
      subtitle: "현장 투입 전 담당자의 준비 상태를 최종 점검합니다.",
      accentColor: safetyBlue,
      icon: Icons.health_and_safety,
      content: Column(
        children: [
          _buildPledgeItem("[복장] 회사 근무복 및 안전화 착용 상태가 양호한가?"),
          _buildPledgeItem("[장비] 고성능 랜턴, 비상키, 검전기, 스마트폰 배터리를 확보했는가?"),
          _buildPledgeItem("[숙지] 해당 단지의 최근 주요 민원 및 사고 이력을 파악했는가?"),
        ],
      ),
    );
  }

  // 🔄 2. 시설 점검 운영 프로세스
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
                Icon(Icons.route, color: primaryNavy),
                const SizedBox(width: 8),
                Text("2. 시설 점검 동선 프로세스 (SOP)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("현장 단지 도착 👉 안전 장구 및 민원 이력 숙지", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("외곽 및 분리수거장", "진입로/미화/주차/배수로"),
                _buildFlowBranch("1층 로비 및 게시판", "자동문/공문/우편함"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("최상층 이동 후 하향 순회 (Top-Down)", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("복도/계단/소방 시설", "적재물/창문/유도등/PD함"),
                _buildFlowBranch("전유부 민원 세대 방문", "누수 등 세대 민원 처리"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("지하 기계/전기실 정밀 점검 👉 결과 전송 및 보고", const Color(0xFFF1F5F9)),
          ],
        ),
      ),
    );
  }

  // 📋 3. 구역별 정밀 점검 항목 (이론용)
  Widget _buildStep2_Checklists() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryNavy, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: primaryNavy, size: 28),
              const SizedBox(width: 10),
              Text("3. 구역별 정밀 점검 항목", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
            ],
          ),
          const SizedBox(height: 8),
          const Text("※ 실제 점검은 현장관리 메인 메뉴의 '실전 체크리스트'를 이용하세요.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),

          _buildChecklistGroup(
            title: "A. 현관 및 건물 외곽 (Entrance & Exterior)",
            icon: Icons.domain,
            color: const Color(0xFF3B82F6),
            items: [
              _buildCheckListItem("건물 진입로 및 주변 주차/미화 상태", "쓰레기 무단 투기 및 주차 라인 훼손 확인", true),
              _buildCheckListItem("분리수거장 운영 상태 및 소모품 재고", "종량제 봉투 및 마대 자루 잔여량 확인", true),
              _buildCheckListItem("현관 로비폰 및 자동문 구동 상태", "FM: 하단 레일 이물질 및 끼임 방지 센서 테스트", true),
              _buildCheckListItem("주차장 배수로 및 트렌치 퇴적물 상태", "FM: 악취 발생 및 폭우 시 역류 가능성 확인", false),
              _buildCheckListItem("외벽 균열(크랙) 및 담장 노후화", "FM: 강풍 시 낙하물 사고 예방 차원 정밀 확인", false),
            ],
          ),
          const SizedBox(height: 16),
          _buildChecklistGroup(
            title: "B. 승강기 및 주차 설비 (Elevator & Tower)",
            icon: Icons.elevator,
            color: const Color(0xFF8B5CF6),
            items: [
              _buildCheckListItem("승강기 내부 청결 및 조명 점등 상태", "광고물 무단 부착 및 바닥 오염 확인", true),
              _buildCheckListItem("승강기 버튼 및 로프 이음/진동 확인", "오르내릴 때 평소와 다른 쇳소리(마찰음) 감지", true),
              _buildCheckListItem("승강기 월 정기점검 기록지 부착 여부", "FM: 승강기안전공단 법적 안전점검 기한 확인", false),
              _buildCheckListItem("주차타워/카리프트 구동음 및 대기 상태", "도어 센서 및 체인 구동부 이음 확인", false),
              _buildCheckListItem("비상 통화 장치(인터폰) 작동 시험", "FM: 갇힘 사고 시 외부 구호 통화 가능 여부", false),
            ],
          ),
          const SizedBox(height: 16),
          _buildChecklistGroup(
            title: "C. 계단 및 복도 공용부 (Stairs & Corridor)",
            icon: Icons.stairs,
            color: const Color(0xFF10B981),
            items: [
              _buildCheckListItem("비상유도등 및 복도 센서등 점등 상태", "불이 들어오지 않는 층수 즉각 기록 및 교체", true),
              _buildCheckListItem("수도검침함 내부 동파/누수 확인", "특히 동절기에 헌 옷이나 보온재 채움 상태 확인", true),
              _buildCheckListItem("복도 내 개인 물품(자전거 등) 적치 여부", "FM: 피난 통로 방해 시 소방법 위반 스티커 부착", false),
              _buildCheckListItem("각 층 계단 창문 및 난간 고정 상태", "창문 닫힘 상태 및 흔들리는 난간 보수", false),
              _buildCheckListItem("방화문 자동 폐쇄 장치(도어클로저)", "FM: 화재 시 연기 차단 가능 여부 (도어스토퍼 제거)", false),
            ],
          ),
          const SizedBox(height: 16),
          _buildChecklistGroup(
            title: "D. 지하 기계실 및 핵심 설비 (MEP Room)",
            icon: Icons.precision_manufacturing,
            color: const Color(0xFFF59E0B),
            items: [
              _buildCheckListItem("소방 펌프실 및 물탱크실 청결 상태", "누수 흔적 및 바닥 물고임 즉시 확인", true),
              _buildCheckListItem("집수정 펌프 가동 및 수위 알람 상태", "오동작 시 즉각 범람 위험", true),
              _buildCheckListItem("전기실/발전기실 습기 및 온도 관리", "환기팬 가동 상태 및 패널 내부 이상한 타는 냄새 확인", true),
              _buildCheckListItem("각종 배관 및 밸브 누수(물 맺힘) 확인", "배관 보온재 찢어짐 및 밸브 조인트 미세 누수", false),
              _buildCheckListItem("압력계 및 온도계 지침 정상 범위", "FM: 모터/펌프 과부하 및 이상 압력 선제 파악", false),
            ],
          ),
        ],
      ),
    );
  }

  // 💡 4. FM 전문가 팁
  Widget _buildStep3_ExpertTips() {
    return _buildSectionCard(
      title: "4. FM 전문가 필수 점검 (사고 예방 핵심)",
      subtitle: "대기업 관리 현장에서 대형 사고와 배상 책임을 막는 필수 3대 항목입니다.",
      accentColor: dangerRed,
      icon: Icons.model_training,
      content: Column(
        children: [
          _buildHighlightAction(Icons.door_front_door, "방화문 도어스토퍼(말굽) 개방 절대 금지", "환기를 위해 방화문을 고정해두면 화재 시 연기 확산으로 대참사가 발생하며 형사 처벌 대상입니다. 무조건 닫고 안내문을 부착하십시오.", isDanger: true),
          _buildHighlightAction(Icons.water_damage, "옥상 누수 전조: 최상층 천장 '백화 현상'", "단순 바닥 균열뿐만 아니라, 최상층 복도 천장에 '하얀 가루(백화)'가 맺혔는지 확인하십시오. 철근 부식 및 본격적인 누수 직전의 강력한 신호입니다.", isDanger: false),
          _buildHighlightAction(Icons.earbuds, "PD(Pipe Duct)실 내부 소음 확인", "복도 벽면의 배관 통로(PD) 문에 귀를 대보십시오. 평소보다 물 흐르는 소리가 크거나 폭포수 같은 낙수 소리가 들리면 내부 배관 파열입니다.", isDanger: false),
        ],
      ),
    );
  }

  // 🛠️ 5. 행정 조치 가이드
  Widget _buildStep4_AdminAction() {
    return _buildSectionCard(
      title: "5. 점검 후 행정 조치 및 보고 가이드",
      subtitle: "현장 발견 후 처리가 완벽해야 진정한 FM입니다.",
      accentColor: primaryNavy,
      icon: Icons.assignment_turned_in,
      content: Column(
        children: [
          _buildActionItem(Icons.build_circle, "경미 사항 (즉시 조치)", "전등 교체, 광고물 제거, 간단한 나사 조임 등은 현장에서 즉시 조치 후 완료 사진을 채증합니다."),
          _buildActionItem(Icons.report_problem, "중대 사항 (수리 의뢰)", "펌프 고장, 대형 누수, 외벽 크랙 등은 즉시 사진을 찍어 본사 현장 부장에게 보고하고, 관리단에 견적 및 수리 의뢰 공문을 발송합니다."),
          _buildActionItem(Icons.send_to_mobile, "민원 피드백 (종결)", "순회 중 해결한 입주민 접수 민원은 반드시 '현장관리 앱'에서 [완료] 처리하고, 입주민에게 처리 완료 문자를 발송하여 신뢰도를 높입니다."),
        ],
      ),
    );
  }

  // --- UI 헬퍼 위젯들 ---

  Widget _buildChecklistGroup({required String title, required IconData icon, required Color color, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)), border: Border(bottom: BorderSide(color: color.withOpacity(0.1)))),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckListItem(String title, String desc, bool isDaily) {
    Color tagColor = isDaily ? residentTagColor : patrolTagColor;
    String tagText = isDaily ? "상주/매일" : "순회/주기";

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_box_outline_blank, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: tagColor.withOpacity(0.3))),
                      child: Text(tagText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor)),
                    ),
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required Color accentColor, required IconData icon, required Widget content}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, decoration: BoxDecoration(color: accentColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
            Expanded(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: accentColor, size: 26), const SizedBox(width: 10), Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy)))]), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))), const Divider(height: 30, thickness: 1, color: Color(0xFFF1F5F9)), content]))),
          ],
        ),
      ),
    );
  }

  Widget _buildPledgeItem(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_box, color: primaryNavy, size: 22), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4)))],),);
  }

  Widget _buildActionItem(IconData icon, String title, String desc) {
    return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: const Color(0xFF475569))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))), const SizedBox(height: 4), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))]));
  }

  Widget _buildHighlightAction(IconData icon, String title, String desc, {bool isDanger = false}) {
    Color bgColor = isDanger ? Colors.red.shade50 : const Color(0xFFEFF6FF); Color iconColor = isDanger ? Colors.red.shade700 : safetyBlue;
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDanger ? Colors.red.shade100 : const Color(0xFFBFDBFE))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: iconColor, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 15)), const SizedBox(height: 6), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))]));
  }

  Widget _buildFlowStep(String text, Color bgColor) { return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), textAlign: TextAlign.center)); }
  Widget _buildFlowBranch(String condition, String result) { return Container(width: 240, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))), child: Column(children: [Text(condition, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))), const SizedBox(height: 8), Text(result, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A), height: 1.4), textAlign: TextAlign.center)])); }
}