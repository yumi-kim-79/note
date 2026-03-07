// [파일 위치: lib/pages/meeting/meeting_guide_page.dart]
// [설명: 입주자대표회의, 관리단 집회, 반상회 등 회의 진행 및 분쟁 대처 실무 가이드]

import 'package:flutter/material.dart';

class MeetingGuidePage extends StatelessWidget {
  const MeetingGuidePage({super.key});

  // 🏢 SM 표준 메인 컬러 팔레트
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);
  final Color dangerRed = const Color(0xFFDC2626);
  final Color warningOrange = const Color(0xFFEA580C);
  final Color successGreen = const Color(0xFF059669);
  final Color expertPurple = const Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "회의 진행 및 대처 가이드",
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
              _buildStep1_Preparation(), // 1. 회의 전 준비
              const SizedBox(height: 16),
              _buildStep2_Execution(),   // 2. 회의 진행 노하우
              const SizedBox(height: 16),
              _buildFMExpertTips(),      // 🌟 고경력자 멘탈 관리 및 분쟁 대처
              const SizedBox(height: 16),
              _buildStep3_PostMeeting(), // 3. 사후 처리 및 의사록
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
          const Icon(Icons.forum, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text("관리단 집회 및 입주자대표 회의\n실무 매뉴얼", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text("• 대상: 반상회, 입주자대표회의, 상가 관리단 집회\n• 핵심 목표: 적법한 절차 준수, 감정적 분쟁 차단, 투명한 의사결정 지원", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  // 🔍 1. 회의 전 준비사항 (절차적 하자 방지)
  Widget _buildStep1_Preparation() {
    return _buildSectionCard(
      title: "1. 회의 개최 전 필수 준비 (절차적 하자 방지)",
      subtitle: "회의 공지 절차에 하자가 있으면 회의 결과 전체가 무효 소송에 휘말릴 수 있습니다.",
      accentColor: safetyBlue,
      icon: Icons.edit_document,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionItem(Icons.calendar_month, "법정 소집 공고일 준수", "관리규약에 명시된 소집 기한(보통 회의 개최 5~7일 전)을 반드시 지켜 공고문을 게시하고, 게시 날짜가 찍힌 인증 사진을 남겨두십시오."),
          _buildActionItem(Icons.list_alt, "명확한 안건(의안) 상정", "공고문에는 '안건 1. 주차장 규정 개정의 건'처럼 구체적으로 명시해야 합니다. '기타 안건'이라는 이름으로 현장에서 즉흥적으로 중요한 안건을 통과시키면 불법입니다."),
          _buildActionItem(Icons.how_to_reg, "위임장 및 서면결의서 징구", "바빠서 불참하는 입주민을 위해 사전에 위임장이나 서면결의서를 배포하고, 회의 시작 전 '성원(의결 정족수)'이 충족되었는지 정확히 계산하십시오."),
        ],
      ),
    );
  }

  // 🎤 2. 회의 진행 노하우 (SM의 역할)
  Widget _buildStep2_Execution() {
    return _buildSectionCard(
      title: "2. 현장 회의 진행 가이드 (SM 관리자의 역할)",
      subtitle: "관리소장은 결정권자가 아닙니다. 회의가 원활히 흘러가도록 돕는 '조력자'입니다.",
      accentColor: successGreen,
      icon: Icons.mic_external_on,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionItem(Icons.record_voice_over, "녹음 안내 및 기록", "회의 시작 전 '정확한 의사록 작성을 위해 본 회의는 녹음됩니다'라고 선언한 후 스마트폰이나 녹음기를 중앙에 비치하십시오. (막말과 억지 주장을 줄이는 효과가 큽니다)"),
          _buildActionItem(Icons.gavel, "객관적 자료 기반 브리핑", "안건에 대해 설명할 때는 내 개인적인 의견을 빼고, '3개 업체의 견적 비교 결과', '관련 법령 및 규약' 등 팩트와 수치 위주로만 건조하게 보고하십시오."),
          _buildActionItem(Icons.timer, "시간 관리 및 안건 유도", "특정 입주민이 안건과 상관없는 개인적인 불만을 길게 늘어놓을 경우, '해당 건은 회의 종료 후 따로 말씀 듣겠습니다. 지금은 OOO 안건에 집중해 주십시오'라며 부드럽지만 단호하게 끊어내십시오."),
        ],
      ),
    );
  }

  // 💡 [FM 핵심] 고경력 소장 멘탈 관리 및 분쟁 대처법
  Widget _buildFMExpertTips() {
    return _buildSectionCard(
      title: "🔥 고경력 소장의 멘탈 및 분쟁 관리 노하우",
      subtitle: "회의 중 입주민 간 고성이 오가거나 관리소를 향해 공격이 들어올 때의 대처법입니다.",
      accentColor: expertPurple,
      icon: Icons.workspace_premium,
      content: Column(
        children: [
          _buildHighlightAction(
              Icons.front_hand,
              "입주민 간의 이권 다툼에 절대 개입하지 마십시오.",
              "A파와 B파 입주민이 싸울 때, 소장이 어느 한쪽 편을 드는 순간 '관리소장 퇴진 운동'으로 번집니다. 철저하게 제3자 입장을 유지하며 '법과 관리규약에 따르면 이렇습니다'라고 앵무새처럼 원칙만 답변하십시오.",
              isDanger: true, customColor: dangerRed
          ),
          _buildHighlightAction(
              Icons.shield,
              "관리소를 향한 공격성 발언 대처법 (감정 분리)",
              "회의 중 누군가 '관리소는 맨날 뭐하는 거냐'며 화를 내더라도 같이 화내거나 변명하려 하지 마십시오. '말씀하신 불편 사항은 접수했으며, 규약에 따라 개선 방안을 찾아 차기 안건으로 올리겠습니다'라며 사무적으로 넘겨버리십시오.",
              isDanger: false, customColor: expertPurple
          ),
        ],
      ),
    );
  }

  // 📝 3. 사후 처리 및 의사록
  Widget _buildStep3_PostMeeting() {
    return _buildSectionCard(
      title: "3. 사후 처리 및 회의록(의사록) 작성",
      subtitle: "회의가 끝난 후의 투명한 공지가 신뢰받는 관리업체의 기본입니다.",
      accentColor: warningOrange,
      icon: Icons.fact_check,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionItem(Icons.edit_note, "신속한 의사록(회의록) 작성", "녹음본과 메모를 바탕으로 누가 어떤 발언을 했고, 어떤 안건이 몇 표로 가결/부결되었는지 팩트 위주로 의사록을 작성하십시오."),
          _buildActionItem(Icons.draw, "대표자 서명 날인", "작성된 의사록은 회의를 주재한 대표(회장) 및 참석 임원들의 서명이나 도장을 반드시 받아야 법적 효력이 생깁니다."),
          _buildActionItem(Icons.campaign, "결과 게시판 공지", "의결된 주요 사항을 요약하여 엘리베이터 및 1층 게시판에 신속히 부착하십시오. 투명한 공개는 입주민들의 쓸데없는 오해와 민원을 사전에 차단합니다."),
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

  Widget _buildActionItem(IconData icon, String title, String desc) {
    return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: const Color(0xFF475569))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))), const SizedBox(height: 4), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))]));
  }

  Widget _buildHighlightAction(IconData icon, String title, String desc, {bool isDanger = false, Color? customColor}) {
    Color baseColor = customColor ?? (isDanger ? dangerRed : safetyBlue);
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDanger ? Colors.red.shade50 : (customColor != null ? customColor.withOpacity(0.05) : const Color(0xFFEFF6FF)), borderRadius: BorderRadius.circular(8), border: Border.all(color: isDanger ? Colors.red.shade100 : (customColor != null ? customColor.withOpacity(0.2) : const Color(0xFFBFDBFE)))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: baseColor, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: baseColor, fontSize: 15)), const SizedBox(height: 6), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))]));
  }
}