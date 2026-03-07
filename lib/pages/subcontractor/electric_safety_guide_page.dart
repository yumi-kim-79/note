// [파일 위치: lib/pages/subcontractor/electric_safety_guide_page.dart]
// [설명: 용역업체 통제 지침 (전기 편) - QR코드 제출 및 입주민 공개 시스템 탑재]

import 'package:flutter/material.dart';

class ElectricSafetyGuidePage extends StatelessWidget {
  const ElectricSafetyGuidePage({super.key});

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
          "전기 용역 관리 지침",
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
          const Icon(Icons.electrical_services, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text("전기안전 용역업체 관리 및 평가 지침", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text("• 관리 대상: 전기안전관리 대행업체 / 상주 전기안전관리자\n• 핵심 목표: 선(先)정밀계측 후(後)시스템보고, 측정 데이터 투명 공개", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  // 🔍 1. 용역업체 핵심 점검 가이드
  Widget _buildStep1_CoreCheckpoints() {
    return _buildSectionCard(
      title: "1. 용역업체 핵심 점검 가이드 (Check-point)",
      subtitle: "전기업체의 전문 장비 활용도를 감시하고 '수치화된 데이터'를 요구하십시오.",
      accentColor: safetyBlue,
      icon: Icons.manage_search,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("① 작업 완료 후 지정장소 QR 보고 체계", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.qr_code_2, "지정 장소 QR 인증", "모든 전기실 및 분전반 점검을 완벽히 마친 후, 단지 내 지정 장소에서 QR 코드를 스캔하여 보고서를 제출해야 합니다."),
          _buildActionItem(Icons.person_pin, "현장 담당자 실명제", "방문 시마다 작업자가 다를 수 있으므로, 당일 현장에 온 담당자의 성명과 연락처 기재를 의무화하십시오."),
          const Divider(height: 32, thickness: 1, color: Color(0xFFE2E8F0)),
          const Text("② 정밀 계측 데이터 및 열화상 증빙", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.speed, "실측 수치 입력 필수", "절연저항(MΩ) 및 전류(A) 수치를 단순 '양호'가 아닌 측정된 데이터로 시스템에 직접 입력하게 하십시오."),
          _buildActionItem(Icons.thermostat, "열화상 Hot-spot 사진", "분전함 내부 이상 발열 부위의 열화상 촬영 사진과 조치 전/후 사진을 즉시 업로드하게 하십시오."),
        ],
      ),
    );
  }

  // 💡 고경력 소장 실무 노하우
  Widget _buildFMExpertTips() {
    return _buildSectionCard(
      title: "🔥 고경력 전문가 인사이트 (사고 원천 차단)",
      subtitle: "고경력 현장 관리자가 전기업체를 관리할 때 짚고 넘어가는 실무 디테일입니다.",
      accentColor: expertPurple,
      icon: Icons.workspace_premium,
      content: Column(
        children: [
          _buildHighlightAction(
              Icons.trending_up,
              "전력 피크 시간대(여름/겨울) 계측 요구",
              "진정한 부하 테스트를 위해 에어컨이나 난방기가 최대로 가동되는 '피크 시간대'에 방문하여 점검을 완료하고 보고하도록 강제하십시오.",
              isDanger: false, customColor: expertPurple
          ),
          _buildHighlightAction(
              Icons.inventory_2,
              "EPS/TPS실 가연성 적치물 엄격 관리",
              "분전함 내부에 가연성 물질(박스, 세제 등)을 두는 것은 화재 시 대참사의 원인입니다. 점검 보고 시 해당 구역의 적치물 제거 상태 사진을 필히 확인하십시오.",
              isDanger: true
          ),
        ],
      ),
    );
  }

  // 🔄 2. SM 스마트 보고 및 입주민 공개 프로세스
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
                Icon(Icons.important_devices, color: primaryNavy),
                const SizedBox(width: 8),
                const Text("2. SM 스마트 보고 및 입주민 공개 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("⚡ 전기 점검 실시 👉 열화상 촬영 및 절연/전류 정밀 측정", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("📱 지정장소 이동 👉 QR 스캔 및 방문자 정보(성명/연락처) 입력", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("📸 결과 보고서 작성 👉 계측 데이터 및 열화상 사진 서버 전송", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 👑 승인 및 공개 영역 (아이콘+글자 일체형 중앙 정렬)
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
                          "현장 담당자 데이터 검수 및 최종 [승인]",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: Colors.white54),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "입주민 앱(게시판)에 점검 보고서 및 안전 상태 즉시 공개",
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
      title: "3. 용역업체 평가 및 제재 기준 (Strict)",
      subtitle: "전기는 화재와 직결되므로 시스템 미준수 시 더욱 엄격하게 관리합니다.",
      accentColor: dangerRed,
      icon: Icons.gavel,
      content: Container(
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            _buildTableRow("구분", "위반 행위 (제재 사유)", "제재 수단 (Action)", isHeader: true),
            _buildTableRow("주의", "• 방문자 정보(성명/연락처) 오기\n• 점검 수치 기록 누락 및 오기", "• 시정 교육 및 데이터 재입력\n• 평가 감점 (-10점)", typeColor: warningOrange),
            _buildTableRow("경고", "• 이상 발열 부위 조치 미이행\n• QR 보고 누락 및 가라 점검 의심", "• 공식 경고장 및 용역비 차감\n• 평가 감점 (-40점)", typeColor: dangerRed),
            _buildTableRow("해지", "• 점검 데이터 허위 조작 적발 시\n• 관리 소홀로 인한 화재/정전 발생", "• 계약 즉시 해지\n• 민형사상 손해배상 청구", typeColor: primaryNavy),
          ],
        ),
      ),
    );
  }

  // 📱 4. 현장 담당자 최종 체크리스트
  Widget _buildStep4_FinalChecklist() {
    return _buildSectionCard(
      title: "4. 현장 담당자 최종 체크리스트 (Mobile)",
      subtitle: "담당자가 보고서를 승인하기 전 앱에서 최종 확인해야 할 항목입니다.",
      accentColor: successGreen,
      icon: Icons.fact_check,
      content: Column(
        children: [
          _buildPledgeItem("[신원] 보고서에 작성된 담당자 성명/연락처가 방문자와 일치하는가?"),
          _buildPledgeItem("[데이터] 단순 '양호'가 아닌 실제 계측 수치가 입력되어 있는가?"),
          _buildPledgeItem("[열화상] 온도가 높게 측정된 부위에 대해 즉각 재조치 지시를 하였는가?"),
          _buildPledgeItem("[승인] 허위 내용이 없음을 확인하고 시스템에서 최종 승인 처리했는가?"),
          _buildPledgeItem("[입주민] 승인 완료 후 입주민 앱에 '전기설비 안전' 상태가 정상 노출되는가?"),
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