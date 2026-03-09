// [파일 위치: lib/pages/subcontractor/water_tank_guide_page.dart]
// [설명: 용역업체 관리 지침 - 물탱크 청소 및 수질검사 대행업체 편 (일반 보고 시스템 적용)]

import 'package:flutter/material.dart';

class WaterTankGuidePage extends StatelessWidget {
  const WaterTankGuidePage({super.key});

  // 🏢 SM 표준 메인 컬러 팔레트
  final Color primaryNavy = const Color(0xFF1E293B);   // 메인 강조색 (검은색 박스 등)
  final Color safetyBlue = const Color(0xFF2563EB);    // 가이드 강조색
  final Color dangerRed = const Color(0xFFDC2626);     // 제재/위험 알림색
  final Color warningOrange = const Color(0xFFEA580C); // 주의/미흡 알림색
  final Color successGreen = const Color(0xFF059669);  // 합격/완료 알림색
  final Color expertPurple = const Color(0xFF7C3AED);  // 고경력 전문가 팁 포인트 컬러

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "물탱크 청소 용역 관리 지침",
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
              _buildStep1_CoreCheckpoints(),
              const SizedBox(height: 16),
              _buildFMExpertTips(),
              const SizedBox(height: 16),
              _buildDecisionTree(),
              const SizedBox(height: 16),
              _buildStep3_PenaltyTable(),
              const SizedBox(height: 16),
              _buildStep4_FinalChecklist(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 📄 문서 헤더 (관리번호 삭제 및 중앙 정렬)
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
          const Icon(Icons.water_drop, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text("물탱크 청소 및 수질검사 용역업체\n 관리 지침", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text("• 관리 대상: 저수조 청소업 등록 업체 / 수질검사 전문 기관\n• 핵심 목표: 먹는 물 안전성 확보, SM 업무 협조 체계 강화, 법적 주기 100% 이행", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  // 🔍 1. 용역업체 핵심 점검 가이드
  Widget _buildStep1_CoreCheckpoints() {
    return _buildSectionCard(
      title: "1. 용역업체 핵심 점검 가이드\n (Check-point)",
      subtitle: "입주민 단수 불편을 최소화하고 보이지 않는 탱크 내부를 완벽히 소독하는지 확인하십시오.",
      accentColor: safetyBlue,
      icon: Icons.manage_search,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("① 반기별 청소 및 내부 시설 점검", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.event_available, "법적 청소 주기 준수", "수도법에 따라 6개월마다 1회 의무 실시해야 합니다. (상반기 4~6월, 하반기 9~11월 권장)"),
          _buildActionItem(Icons.plumbing, "내부 부속물 정상 확인", "물을 비웠을 때만 확인 가능한 '볼탑(밸브)', '사다리 부식', '수위 센서' 작동 여부를 사진으로 보고받으십시오."),
          _buildActionItem(Icons.cleaning_services, "고압 세척 및 소독", "전용 세정제와 고압 세척기로 벽면 물때와 바닥 침전물을 완전히 제거하는지 직접 참관하십시오."),

          const Divider(height: 32, thickness: 1, color: Color(0xFFE2E8F0)),

          const Text("② 수질검사 및 결과 보고서 검증", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.science, "채수 과정 담당자 입회", "청소 후 새 물을 채운 상태에서 수질검사 기관이 직접 시료(채수)를 채취하는지 반드시 입회하십시오."),
          _buildActionItem(Icons.assignment_turned_in, "결과 보고서 시스템 등록", "6개 항목 '적합' 판정 보고서와 청소 필증을 수령하여 SM 시스템에 업로드하고 관리대장에 비치하십시오."),
        ],
      ),
    );
  }

  // 💡 고경력 소장 실무 노하우
  Widget _buildFMExpertTips() {
    return _buildSectionCard(
      title: "🔥 고경력 전문가 인사이트\n (업무 협조 강화)",
      subtitle: "고경력 현장 관리자가 입주민 민원을 방지하기 위해 업체와 조율하는 핵심 노하우입니다.",
      accentColor: expertPurple,
      icon: Icons.workspace_premium,
      content: Column(
        children: [
          _buildHighlightAction(
              Icons.campaign,
              "단수 안내문 사전 제공 및 일정 준수 (SM 협력)",
              "작업 최소 3~5일 전, 업체가 정확한 단수 시간을 통보하고 안내문 초안을 제공하는지 등 선제적 업무 협조 태도를 강력히 요구하십시오.",
              isDanger: false, customColor: expertPurple
          ),
          _buildHighlightAction(
              Icons.lock_person,
              "청소 종료 후 맨홀 시건 장치 이중 확인",
              "수질 오염 테러나 이물질 투기를 막기 위해, 청소 완료 후 저수조 뚜껑(맨홀)이 자물쇠로 완벽히 잠겼는지 담당자가 직접 당겨서 확인하십시오.",
              isDanger: true
          ),
        ],
      ),
    );
  }

  // 🔄 2. SM 관리 보고 프로세스 (QR 제외)
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
                const Text("2. SM 물탱크 관리 보고 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 24),

            _buildFlowStep("🗓️ 청소 예정일 2주 전 👉 업체 일정 조율 및 단수 안내문 게시", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("🧹 작업 당일 👉 내부 고압 세척 및 소독 실시 (시설 점검 병행)", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
              child: const Text("내부 부속물(볼탑, 센서 등) 이상 유무?", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("[NO] 이상 없음", "급수 재개 및\n수질검사 시료 채취", successGreen),
                _buildFlowBranch("[YES] 결함 발견", "즉시 수리 지시 및\n부품 교체 견적 보고", warningOrange),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("☁️ '보고서 제출' 👉 업체가 제출한 조치 사진 및 서류 시스템 등록", const Color(0xFFEFF6FF)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 👑 검수 및 공지 영역 (아이콘+글자 일체형 중앙 정렬)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.verified_user, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "현장 담당자 사진/서류 검수 및 완료 처리",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: Colors.white54),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.mark_email_read, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "수질검사 적합 결과 및 청소 완료 입주민 공지",
                          style: TextStyle(color: Colors.orange.shade100, fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⚖️ 3. 평가 및 제재 기준표
  Widget _buildStep3_PenaltyTable() {
    return _buildSectionCard(
      title: "3. 평가 및 제재 기준 (Penalty)",
      subtitle: "먹는 물 안전 및 입주민 생활(단수)과 직결되므로 엄격하게 관리합니다.",
      accentColor: dangerRed,
      icon: Icons.gavel,
      content: Column(
        children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("구분", "위반 행위 (제재 사유)", "제재 수단 (Action)", isHeader: true),
                _buildTableRow(
                    "주의",
                    "• 🌟작업 전 '단수 안내' 미협조\n• 완료 보고 및 사진 제출 지연\n• 청소 후 주변 오물 정리 불량",
                    "• 구두 경고 및 즉시 시정\n• 평가 감점 (-10점)",
                    typeColor: warningOrange
                ),
                _buildTableRow(
                    "경고",
                    "• 법적 청소 주기 미준수 (기한 도래 전 미시행)\n• 수질검사 채수 시 담당자 미입회\n• 부속물 결함 발견 후 보고 누락",
                    "• 공식 시정 공문 발송\n• 용역비 지급 보류\n• 평가 감점 (-30점)",
                    typeColor: dangerRed
                ),
                _buildTableRow(
                    "해지",
                    "• 수질검사 결과 허위 조작 및 부정행위\n• 관리 소홀로 인한 수인성 질병 발생\n• 연간 경고 2회 이상 누적 시",
                    "• 계약 즉시 해지\n• 손해배상 청구 및 고발",
                    typeColor: primaryNavy
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📱 4. 현장 담당자 최종 체크리스트
  Widget _buildStep4_FinalChecklist() {
    return _buildSectionCard(
      title: "4. 현장 담당자 최종 점검 체크리스트",
      subtitle: "청소 전후로 담당자가 직접 확인하고 시스템에 등록할 사항입니다.",
      accentColor: successGreen,
      icon: Icons.fact_check,
      content: Column(
        children: [
          _buildPledgeItem("[협조] 단수 일정 안내 및 주의사항이 전 세대에 미리 공지되었는가?"),
          _buildPledgeItem("[청소] 탱크 바닥 침전물과 벽면 물때가 완벽히 제거된 사진을 확인했는가?"),
          _buildPledgeItem("[시설] 볼탑과 센서가 정상 작동하여 물 넘침 위험은 없는지 확인했는가?"),
          _buildPledgeItem("[채수] 수질검사 기관의 시료 채취 시 담당자가 직접 입회했는가?"),
          _buildPledgeItem("[보안] 작업 종료 후 물탱크 맨홀 뚜껑이 자물쇠로 확실히 잠겼는가?"),
          _buildPledgeItem("[공지] 작업 완료 및 수질 적합 결과를 입주민에게 즉각 안내했는가?"),
        ],
      ),
    );
  }


  // --- UI 헬퍼 위젯들 ---
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

  Widget _buildActionItem(IconData icon, String title, String desc) { return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: const Color(0xFF475569))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))), const SizedBox(height: 4), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))])); }
  Widget _buildHighlightAction(IconData icon, String title, String desc, {bool isDanger = false, Color? customColor}) { Color baseColor = customColor ?? (isDanger ? dangerRed : safetyBlue); return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDanger ? Colors.red.shade50 : (customColor != null ? customColor.withOpacity(0.05) : const Color(0xFFEFF6FF)), borderRadius: BorderRadius.circular(8), border: Border.all(color: isDanger ? Colors.red.shade100 : (customColor != null ? customColor.withOpacity(0.2) : const Color(0xFFBFDBFE)))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: baseColor, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: baseColor, fontSize: 15)), const SizedBox(height: 6), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))])); }
  Widget _buildPledgeItem(String text) { return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_box, color: primaryNavy, size: 22), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4)))],),); }
  Widget _buildTableRow(String col1, String col2, String col3, {bool isHeader = false, Color? typeColor}) { final bgColor = isHeader ? const Color(0xFFF1F5F9) : Colors.white; final textColor = isHeader ? const Color(0xFF1E293B) : const Color(0xFF475569); return Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))), child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: Container(alignment: Alignment.center, padding: const EdgeInsets.all(12), color: bgColor, child: Text(col1, style: TextStyle(color: typeColor ?? textColor, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center))), Container(width: 1, color: const Color(0xFFE2E8F0)), Expanded(flex: 4, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col2, style: TextStyle(color: textColor, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: 13, height: 1.5)))), Container(width: 1, color: const Color(0xFFE2E8F0)), Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col3, style: TextStyle(color: textColor, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: 13, height: 1.5))))]))); }
  Widget _buildFlowStep(String text, Color bgColor) { return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), textAlign: TextAlign.center)); }
  Widget _buildFlowBranch(String condition, String result, Color color) { return Container(width: 280, constraints: const BoxConstraints(maxWidth: 280), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5), width: 2)), child: Column(children: [Text(condition, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), const SizedBox(height: 8), Text(result, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569), height: 1.4), textAlign: TextAlign.center)])); }
}