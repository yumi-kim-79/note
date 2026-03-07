// [파일 위치: lib/pages/subcontractor/disinfection_service_guide_page.dart]
// [설명: 용역업체 관리 지침 - 소독 및 방역 대행업체 편]

import 'package:flutter/material.dart';

class DisinfectionServiceGuidePage extends StatelessWidget {
  const DisinfectionServiceGuidePage({super.key});

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
          "소독·방역 용역 관리 지침",
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
          const Icon(Icons.health_and_safety, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text("소독·방역 용역업체 관리 및 평가 지침", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text("• 관리 대상: 방역소독업 신고 업체 / 유해생물 방제 서비스 업체\n• 핵심 목표: 법정 소독 이행률 100%, 민원 제로, 해충 없는 단지 조성", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  // 🔍 1. 용역업체 핵심 점검 가이드
  Widget _buildStep1_CoreCheckpoints() {
    return _buildSectionCard(
      title: "1. 용역업체 핵심 점검 가이드 (Check-point)",
      subtitle: "법적 의무 사항 준수 여부와 승인된 약품 사용 여부를 철저히 검증하십시오.",
      accentColor: safetyBlue,
      icon: Icons.manage_search,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("① 법정 소독 횟수 및 일정 관리", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.calendar_month, "법적 주기 준수", "관련 법령에 따른 단지별 소독 주기를 확인하고 기한 내 실시하도록 일정을 조율하십시오."),
          _buildActionItem(Icons.campaign, "사전 공고 시행", "소독 실시 1주일 전, 소독 일정과 부재 세대 대응법을 전 세대에 공지했는지 확인하십시오."),
          _buildActionItem(Icons.medical_services, "약품 안전성(MSDS) 확인", "환경부 승인 제품인지 확인하고, 물질안전보건자료(MSDS)를 현장에 비치하도록 지시하십시오."),

          const Divider(height: 32, thickness: 1, color: Color(0xFFE2E8F0)),

          const Text("② 세대 방문 기록 및 공용부 검증", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.edit_document, "방문 확인 명부 전수 점검", "입주민 서명을 정확히 받았는지, 부재 세대에 안내문을 부착했는지 전수 확인하십시오."),
          _buildActionItem(Icons.bug_report, "공용부 취약지 집중 방제", "정화조, 지하실, 쓰레기장 등 해충 발생 취약 지역에 대한 살포 사진을 반드시 채증하십시오."),
        ],
      ),
    );
  }

  // 💡 고경력 소장 실무 노하우
  Widget _buildFMExpertTips() {
    return _buildSectionCard(
      title: "🔥 고경력 전문가 인사이트 (민원 원천 차단)",
      subtitle: "고경력 현장 관리자가 입주민 만족도를 높이기 위해 관리하는 포인트입니다.",
      accentColor: expertPurple,
      icon: Icons.workspace_premium,
      content: Column(
        children: [
          _buildHighlightAction(
              Icons.person_search,
              "작업자 복장 및 '실내화' 착용 여부 감시",
              "소독 작업자가 세대 내부 진입 시 지저분한 덧신이 아닌 깨끗한 전용 실내화와 단정한 SM 협력업체 명찰/조끼를 착용했는지 확인하십시오.",
              isDanger: false, customColor: expertPurple
          ),
          _buildHighlightAction(
              Icons.cleaning_services,
              "약품 잔여물(얼룩) 방지 교육",
              "분무 소독 시 가구에 얼룩이 남지 않도록 주의시키고, 작업 후 가벼운 뒷정리가 수반되는지 불시에 세대를 방문하여 모니터링하십시오.",
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
                const Text("2. SM 소독·방역 관리 보고 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 24),

            _buildFlowStep("🗓️ 소독 실시 1주 전 👉 세대 공지 및 약품/인원 점검", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("🏠 세대별 방문 및 공용부(정화조/지하) 방제 실시", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
              child: const Text("세대 방문율 90% 이상 달성했는가?", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("[NO] 방문 미달", "부재 세대 보충 소독\n일정 확정 및 재방문", warningOrange),
                _buildFlowBranch("[YES] 소독 양호", "작업 사진 및\n방문 일지 최종 정리", successGreen),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("☁️ '소독증명서' 및 '방문 일지'를 담당자가 시스템에 등록", const Color(0xFFEFF6FF)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 👑 검수 및 관리 영역 (아이콘+글자 중앙 정렬 수정)
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
                          "현장 담당자 데이터 검수 및 최종 승인",
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
                      const Icon(Icons.analytics, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "보건소 제출용 소독 실적 및 민원 발생률 통계 관리",
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
      subtitle: "입주민 불만족은 SM 브랜드 이미지 실추로 이어지므로 강력히 관리합니다.",
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
                    "• 작업 인원 복장 및 명찰 미착용\n• 작업 사진 자료 부실 제출",
                    "• 구두 경고 및 CS 교육\n• 평가 감점 (-5점)",
                    typeColor: warningOrange
                ),
                _buildTableRow(
                    "경고",
                    "• 🌟불친절/오염 등 민원 월 3회 이상\n• 방문 일지 허위 기재 (서명 조작)",
                    "• 공식 시정 공문 발송\n• 용역비 차감 청구\n• 평가 감점 (-30점)",
                    typeColor: dangerRed
                ),
                _buildTableRow(
                    "해지",
                    "• 법정 소독 미이행으로 과태료 발생\n• 작업 중 중대한 인명/재산 사고",
                    "• 계약 즉시 해지\n• 과태료 및 손해배상 청구",
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
      subtitle: "소독 완료 후 담당자가 직접 확인하고 시스템에 등록할 사항입니다.",
      accentColor: successGreen,
      icon: Icons.fact_check,
      content: Column(
        children: [
          _buildPledgeItem("[법규] 이번 소독이 법정 기한을 넘기지 않고 완료되었는가?"),
          _buildPledgeItem("[약품] 사용된 약품이 승인된 제품이며 유통기한이 지나지 않았는가?"),
          _buildPledgeItem("[민원] 소독 기간 중 입주민으로부터의 불만 민원 발생 여부를 확인했는가?"),
          _buildPledgeItem("[방문] 세대별 방문 일지에 입주민의 실제 서명이 누락 없이 기재되었는가?"),
          _buildPledgeItem("[서류] 작업 후 보건소 제출용 '소독증명서' 사본을 즉시 수령했는가?"),
          _buildPledgeItem("[태도] 소독 직원이 입주민과 마주쳤을 때 SM의 매너를 갖추어 대했는가?"),
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