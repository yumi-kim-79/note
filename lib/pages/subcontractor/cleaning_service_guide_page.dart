// [파일 위치: lib/pages/subcontractor/cleaning_service_guide_page.dart]
// [페이지 설명: 미화(청소) 용역업체 관리 및 평가 지침]
// [핵심 로직: SM 스마트 보고 시스템 (선 점검 완료 후 지정 장소 QR 보고 및 입주민 실시간 공개)]
// [업데이트 날짜: 2026.03.07]

import 'package:flutter/material.dart';

class CleaningServiceGuidePage extends StatelessWidget {
  const CleaningServiceGuidePage({super.key});

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
          "미화 용역 관리 지침",
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

  Widget _buildDocumentHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.cleaning_services, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text("미화 용역업체 관리 및 평가 지침", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text("• 관리 대상: 건물 미화 용역업체 / 파견 미화원\n• 핵심 목표: 선(先)완벽미화 후(後)시스템보고, 입주민 실시간 결과 공개", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildStep1_CoreCheckpoints() {
    return _buildSectionCard(
      title: "1. 용역업체 핵심 점검 가이드",
      subtitle: "단순 작업 여부가 아닌, 결과물의 품질과 보고의 정확성을 검증하십시오.",
      accentColor: safetyBlue,
      icon: Icons.manage_search,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("① 작업 완료 후 지정장소 QR 보고 체계", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.qr_code_2, "지정 장소 QR 인증", "모든 청소 루틴을 완벽히 마친 후, 단지 내 지정된 장소에서만 QR 코드를 스캔하여 보고서를 작성해야 합니다."),
          _buildActionItem(Icons.person_pin, "현장 담당자 실명제", "매번 방문자가 다를 수 있으므로, 보고서 작성 시 당일 작업자의 성명과 연락처 기재를 의무화하십시오."),
          const Divider(height: 32, thickness: 1, color: Color(0xFFE2E8F0)),
          const Text("② 사진 증빙 및 특이사항 기록", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.add_a_photo, "고화질 현장 사진 첨부", "승강기 내부, 분리수거장 등 핵심 구역의 청소 후 상태를 광각 사진으로 촬영하여 업로드하게 하십시오."),
          _buildActionItem(Icons.note_alt, "시설 결함 별도 보고", "미화 작업 중 발견된 시설 파손이나 누수 등 특이사항은 별도 비고란에 기록하여 즉시 접수되도록 교육하십시오."),
        ],
      ),
    );
  }

  Widget _buildFMExpertTips() {
    return _buildSectionCard(
      title: "🔥 고경력 전문가 인사이트\n (보고 품질 관리)",
      subtitle: "고경력 현장 관리자가 업체 보고서 승인 시 반드시 대조하는 포인트입니다.",
      accentColor: expertPurple,
      icon: Icons.workspace_premium,
      content: Column(
        children: [
          _buildHighlightAction(Icons.history, "과거 사진 재사용(가라 보고) 원천 차단", "업로드된 사진의 타임스탬프나 채광 상태를 확인하여 과거 사진을 돌려막기 하는지 불시에 현장 점검과 대조하십시오.", isDanger: true),
          _buildHighlightAction(Icons.contact_phone, "실시간 후속 조치 콜백(Call-back)", "보고서에 기록된 연락처로 무작위 해피콜을 실시하여 실제 작업 인원 본인이 맞는지, 특이사항을 인지하고 있는지 확인하십시오.", isDanger: false, customColor: expertPurple),
        ],
      ),
    );
  }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.important_devices, color: primaryNavy),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    "2. SM 스마트 보고 및 입주민 공개 프로세스",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("🧹 미화 작업 실시 👉 지정된 구역 루틴\n 완벽 이행", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("📱 지정장소 이동 👉 QR 스캔 및 방문자\n 정보(성명/연락처) 입력", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("📸 결과 보고서 작성 👉 작업 사진 및\n 특이사항 서버 전송", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 👑 승인 및 공개 영역 (아이콘+글자 동시 중앙 정렬)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 🌟 아이콘+글자 뭉치를 중앙으로
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.verified_user, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Flexible( // 🌟 글자가 길어질 때만 줄바꿈 작동
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
                    mainAxisAlignment: MainAxisAlignment.center, // 🌟 아이콘+글자 뭉치를 중앙으로
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.groups, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 8),
                      Flexible( // 🌟 글자가 길어질 때만 줄바꿈 작동
                        child: Text(
                          "입주민 앱(게시판)에 점검 보고서 및 미화 상태 즉시 공개",
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

  Widget _buildStep3_PenaltyTable() {
    return _buildSectionCard(
      title: "3. 용역업체 평가 및 제재 기준 (Strict)",
      subtitle: "시스템 신뢰도를 떨어뜨리는 행위에는 무관용 원칙을 적용합니다.",
      accentColor: dangerRed,
      icon: Icons.gavel,
      content: Container(
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            _buildTableRow("구분", "위반 행위 (제재 사유)", "제재 수단 (Action)", isHeader: true),
            _buildTableRow("주의", "• 방문자 정보(성명/연락처) 오기\n• 사진 화질 불량으로 판독 불가", "• 시정 교육 및 재보고\n• 평가 감점 (-10점)", typeColor: warningOrange),
            _buildTableRow("경고", "• 🌟입주민 청소 불만 민원 월 3회 이상\n• QR 보고 누락 및 지류 편법 보고", "• 시정 공문 및 용역비 차감\n• 평가 감점 (-40점)", typeColor: dangerRed),
            _buildTableRow("해지", "• 점검 사진 조작(과거 사진 재사용)\n• 상습적 허위 실명 보고 적발 시", "• 계약 즉시 해지\n• 민형사상 손해배상 청구", typeColor: primaryNavy),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4_FinalChecklist() {
    return _buildSectionCard(
      title: "4. 현장 담당자 최종 체크리스트 (Mobile)",
      subtitle: "담당자가 보고서를 승인하기 전 앱에서 최종 확인해야 할 항목입니다.",
      accentColor: successGreen,
      icon: Icons.fact_check,
      content: Column(
        children: [
          _buildPledgeItem("[실명] 보고서에 작성된 작업자 성명과 연락처가 실제 방문자와 일치하는가?"),
          _buildPledgeItem("[품질] 업로드된 사진상에 쓰레기나 얼룩이 보이지 않고 청결한가?"),
          _buildPledgeItem("[특이사항] 시설 파손 등 비고란에 적힌 내용에 대해 즉각 유선 연락을 취했는가?"),
          _buildPledgeItem("[승인] 검토가 끝난 보고서를 승인하여 입주민이 볼 수 있게 처리했는가?"),
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

  Widget _buildActionItem(IconData icon, String title, String desc) { return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: const Color(0xFF475569))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))), const SizedBox(height: 4), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))])); }
  Widget _buildHighlightAction(IconData icon, String title, String desc, {bool isDanger = false, Color? customColor}) { Color baseColor = customColor ?? (isDanger ? dangerRed : safetyBlue); return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDanger ? Colors.red.shade50 : (customColor != null ? customColor.withOpacity(0.05) : const Color(0xFFEFF6FF)), borderRadius: BorderRadius.circular(8), border: Border.all(color: isDanger ? Colors.red.shade100 : (customColor != null ? customColor.withOpacity(0.2) : const Color(0xFFBFDBFE)))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: baseColor, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: baseColor, fontSize: 15)), const SizedBox(height: 6), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))])); }
  Widget _buildPledgeItem(String text) { return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_box, color: primaryNavy, size: 22), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4)))],),); }
  Widget _buildTableRow(String col1, String col2, String col3, {bool isHeader = false, Color? typeColor}) { final bgColor = isHeader ? const Color(0xFFF1F5F9) : Colors.white; final textColor = isHeader ? const Color(0xFF1E293B) : const Color(0xFF475569); return Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))), child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: Container(alignment: Alignment.center, padding: const EdgeInsets.all(12), color: bgColor, child: Text(col1, style: TextStyle(color: typeColor ?? textColor, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center))), Container(width: 1, color: const Color(0xFFE2E8F0)), Expanded(flex: 4, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col2, style: TextStyle(color: textColor, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: 13, height: 1.5)))), Container(width: 1, color: const Color(0xFFE2E8F0)), Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col3, style: TextStyle(color: textColor, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: 13, height: 1.5))))]))); }
  Widget _buildFlowStep(String text, Color bgColor) { return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), textAlign: TextAlign.center)); }
  Widget _buildFlowBranch(String condition, String result, Color color) { return Container(width: 280, constraints: const BoxConstraints(maxWidth: 280), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5), width: 2)), child: Column(children: [Text(condition, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), const SizedBox(height: 8), Text(result, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569), height: 1.4), textAlign: TextAlign.center)])); }
}