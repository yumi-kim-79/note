// [파일 위치: lib/pages/subcontractor/integrated_security_guide_page.dart]
// [설명: 용역업체 관리 지침 - 통합 보안(경비 및 CCTV) 편 (위약금 없는 해지 조항 탑재)]

import 'package:flutter/material.dart';

class IntegratedSecurityGuidePage extends StatelessWidget {
  const IntegratedSecurityGuidePage({super.key});

  // 🏢 SM 표준 메인 컬러 팔레트
  final Color primaryNavy = const Color(0xFF1E293B);   // 메인 강조색
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
          "통합 보안 용역 관리 지침",
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

  // 📄 문서 헤더 (중앙 정렬 및 관리번호 삭제)
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
          const Icon(Icons.security, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text("통합 보안 용역업체 관리 및 평가 지침", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text("• 관리 대상: 기계보안 및 CCTV 유지보수 업체 (렌탈 파트너사)\n• 핵심 목표: 시스템 가동률 100%, 장애 발생 시 긴급 출동 대응력 강화", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  // 🔍 1. 용역업체 핵심 점검 가이드
  Widget _buildStep1_CoreCheckpoints() {
    return _buildSectionCard(
      title: "1. 파트너사 핵심 관리 가이드 (Check-point)",
      subtitle: "단순 렌탈 계약을 넘어, 시스템 장애 시 대응 속도를 최우선으로 관리하십시오.",
      accentColor: safetyBlue,
      icon: Icons.manage_search,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("① CCTV/기술 보안: 녹화 상태 및 장비 관리", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.videocam, "녹화 가동률(Uptime) 유지", "렌탈 장비의 HDD 오류나 녹화 중단이 없는지 상시 모니터링하고, 장애 발생 시 즉각 보고 체계를 가동하십시오."),
          _buildActionItem(Icons.cleaning_services, "렌즈 클리닝 및 화각 조정", "결정적 순간에 식별이 안 되는 상황을 방지하기 위해, 업체 정기 방문 시 렌즈 청소 여부를 확인하십시오."),
          const Divider(height: 32, thickness: 1, color: Color(0xFFE2E8F0)),
          const Text("② 긴급 대응 및 사후 관리", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _buildActionItem(Icons.timer, "장애 복구 '골든타임' 준수", "보안 공백을 최소화하기 위해 장애 접수 후 현장 출동 및 복구까지 소요되는 시간을 기록하고 평가하십시오."),
          _buildActionItem(Icons.report_gmailerrorred, "장애 이력 데이터화", "반복적으로 발생하는 기기 오류는 렌탈 장비 자체의 결함이므로, 즉각적인 교체를 파트너사에 요구하십시오."),
        ],
      ),
    );
  }

  // 💡 고경력 소장 실무 노하우
  Widget _buildFMExpertTips() {
    return _buildSectionCard(
      title: "🔥 고경력 전문가 인사이트 (계약 및 상생 관리)",
      subtitle: "보안 파트너사와의 긴밀한 협력 관계 유지와 리스크 방지를 위한 팁입니다.",
      accentColor: expertPurple,
      icon: Icons.workspace_premium,
      content: Column(
        children: [
          _buildHighlightAction(
              Icons.gavel,
              "🌟 명백한 과실 시 '위약금 없는 해지' 특약 활용",
              "보안 시스템은 상호 신뢰가 핵심입니다. 업체의 명백한 과실(녹화 중단 방치로 범죄 증거 유실 등) 발생 시 위약금 없이 계약을 파기할 수 있는 일회성 특약을 계약서에 명시하도록 관리하십시오.",
              isDanger: true, customColor: expertPurple
          ),
          _buildHighlightAction(
              Icons.handshake,
              "인력 파견 배제를 통한 기술 보안 집중",
              "우리는 별도의 경비 인력 파견을 요청하지 않으므로, 대신 렌탈 장비의 최신화 및 원격 관제 품질 향상에 모든 관리력을 집중시키십시오.",
              isDanger: false, customColor: expertPurple
          ),
        ],
      ),
    );
  }

  // 🔄 2. SM 관리 및 대응 프로세스
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
                const Text("2. SM 보안 장애 대응 및 관리 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("🚨 시스템 장애 감지 👉 현장 담당자 인지 및 파트너사 긴급 접수", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("⚡ 파트너사 현장 출동 👉 장비 수리 및 렌즈/화질 최적화 실시", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
              child: const Text("장애 복구 및 테스트 완료?", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("[YES] 복구 완료", "정상 가동 사진 및\n조치 완료 보고서 수령", successGreen),
                _buildFlowBranch("[NO] 복구 지연", "장비 교체 요청 및\n보안 공백 최소화 조치", warningOrange),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("☁️ '완료 승인' 👉 담당자가 조치 사진 및 대응 시간을 시스템에 등록", const Color(0xFFEFF6FF)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 👑 검수 및 관리 영역 (아이콘+글자 일체형 중앙 정렬)
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
                          "현장 담당자 장애 복구 확인 및 최종 승인",
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
                          "파트너사 대응 속도 및 시스템 품질 월간 평가 반영",
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

  // ⚖️ 3. 평가 및 제재 기준표 (위약금 없는 해지 명시)
  Widget _buildStep3_PenaltyTable() {
    return _buildSectionCard(
      title: "3. 파트너사 평가 및 제재 기준 (Strict)",
      subtitle: "보안 공백은 대형 사고로 이어지므로 엄격한 계약 특약을 적용합니다.",
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
                    "• 단순 장애 보고 지연\n• 정기 방문 점검 시 렌즈 청소 누락",
                    "• 시정 요청 및 교육 실시\n• 평가 감점 (-10점)",
                    typeColor: warningOrange
                ),
                _buildTableRow(
                    "경고",
                    "• 장애 접수 후 출동 골든타임 미준수\n• CCTV 녹화 중단 24시간 이상 방치",
                    "• 공식 경고 공문 발송\n• 렌탈비 지급 유예\n• 평가 감점 (-35점)",
                    typeColor: dangerRed
                ),
                _buildTableRow(
                    "해지",
                    "• 🌟업체 과실로 사고 증거 확보 실패 시\n• 반복적인 시스템 복구 지연 (SLA 미달)",
                    "• 위약금 없는 즉시 계약 파기\n• 민형사상 손해배상 청구",
                    typeColor: primaryNavy
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text("※ 렌탈 파트너사와 계약 시 명백한 과실에 대한 '무위약금 해지' 특약 필수 삽입.", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 📱 4. 현장 담당자 최종 체크리스트
  Widget _buildStep4_FinalChecklist() {
    return _buildSectionCard(
      title: "4. 현장 담당자 최종 점검 체크리스트",
      subtitle: "장애 복구 완료 후 담당자가 직접 확인하고 시스템에 등록할 사항입니다.",
      accentColor: successGreen,
      icon: Icons.fact_check,
      content: Column(
        children: [
          _buildPledgeItem("[로그] 모니터상에 모든 채널이 '녹화 중(REC)'임을 확인했는가?"),
          _buildPledgeItem("[화질] 렌즈 클리닝 후 야간에도 차량 번호 식별이 가능한가?"),
          _buildPledgeItem("[속도] 장애 접수부터 현장 도착까지의 시간이 계약 기준을 준수했는가?"),
          _buildPledgeItem("[백업] 정전 시에도 시스템이 작동하도록 UPS 상태를 확인했는가?"),
          _buildPledgeItem("[특약] 업체 과실 발생 시 무위약금 해지 조건이 계약서에 반영되었는가?"),
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