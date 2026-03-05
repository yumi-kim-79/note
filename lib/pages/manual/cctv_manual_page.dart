// [파일 위치: lib/pages/manual/cctv_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.07 - CCTV 및 개인정보 (Enterprise / 100% 호환 순정 아이콘 버전)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CctvManualPage extends StatelessWidget {
  const CctvManualPage({super.key});

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
          "현장 대응 매뉴얼: CCTV 열람",
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
              _buildStep6(), // 모바일 체크리스트 UI
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
          Text("1. 개인정보보호법 준수를 통한 법적 리스크 원천 차단\n2. 정당한 권리자의 열람 권한 보장\n3. 철저한 기록 관리를 통한 책임 면책",
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  // 📝 1단계: 열람 요청 접수 및 신분 확인
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 열람 요청 접수 및 신분 확인 (Reception)",
      icon: Icons.assignment_ind, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("열람 요청 시 '왜 보여달라고 하는지'와 '누가 요청하는지'를 명확히 기록합니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.badge, "신분 확인", "신분증을 대조하여 요청자가 입주민 또는 사건 관계자인지 정확히 확인"), // 🌟 순정
          const SizedBox(height: 8),
          const Text("🔍 요청 사유 파악", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.local_police, "범죄 수사", "경찰관이 공문(협조요청서)을 지참한 경우"), // 🌟 순정
          _buildHighlightBox(Icons.warning, "사건/사고", "차량 파손, 쓰레기 무단 투기, 폭행 등 본인의 권익 침해"), // 🌟 순정
          _buildHighlightBox(Icons.block, "단순 확인", "\"궁금해서\" 등의 사유는 즉시 거절", isDanger: true), // 🌟 순정
          const SizedBox(height: 8),
          _buildInfoRow(Icons.edit, "신청서 작성", "반드시 SM종합관리 표준 서식에 따라 사유와 시간을 적게 함"), // 🌟 순정
        ],
      ),
    );
  }

  // ⚖️ 2단계: 상황별 열람 권한 판별
  Widget _buildStep2() {
    return _buildCard(
      title: "2단계: 상황별 열람 권한 판별 (Legal Grounds)",
      icon: Icons.policy, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("개인정보보호법에 따라 관리자가 현장에서 즉시 판단해야 할 기준입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildCaseBox("Case A", "경찰관이 동행한 경우", "• 수사 목적임을 확인하고 즉시 협조\n• 별도의 마스킹(모자이크) 없이 열람 및 복제 가능\n• 단, 경찰관 신분증과 협조 공문 확인 필수"),
          const SizedBox(height: 12),
          _buildCaseBox("Case B", "개인이 본인 영상 열람을 요청한 경우", "• 요청자 본인만 찍힌 경우: 열람 가능\n• 타인이 함께 찍힌 경우: 타인의 동의가 없으면 반드시 마스킹(모자이크) 처리 후 열람/제공"),
          const SizedBox(height: 12),
          _buildHighlightBox(Icons.notification_important, "Case C: 긴급 상황", "인명 사고, 화재 등 급박한 생명/재산 보호를 위한 경우 우선 열람 후 사후 기록", isDanger: true), // 🌟 순정
        ],
      ),
    );
  }

  // 🏢 3단계: 관리 형태별 운영 매뉴얼
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: 관리 형태별 운영 매뉴얼 (Operation Mode)",
      icon: Icons.apartment, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("단지 특성에 따른 CCTV 열람 대응 방식입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),

          const Text("1. 상주 인원이 있는 단지", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person, "관리 주체", "관리소장 또는 보안요원"), // 🌟 순정
          _buildInfoRow(Icons.visibility, "운영 방식", "현장에서 즉시 신청서를 받고, 관리자 입회하에 열람 실시"), // 🌟 순정
          _buildHighlightBox(Icons.phonelink_erase, "보안 수칙", "모니터 화면을 개인 스마트폰으로 직접 촬영하는 행위 엄격 금지 (필요 시 공식 복제 제공)", isWarning: true), // 🌟 순정

          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          const Text("2. 상주 인원이 없는 단지 (순회 관리)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.directions_car, "관리 주체", "순회 담당 관리자 또는 SM 본부 관제팀"), // 🌟 순정
          _buildInfoRow(Icons.access_time, "운영 방식", "① 고객센터로 원격 열람 예약\n② 현장 방문 시 시간 맞춰 방문 열람\n③ 클라우드(NVR) 원격 확보 후 검토"), // 🌟 순정
          _buildInfoRow(Icons.info, "필수 조치", "주차타워나 입구에 'CCTV 관리책임자: SM종합관리' 안내판 부착 필수"), // 🌟 순정
        ],
      ),
    );
  }

  // 🔒 4단계: 기술적 보호 및 영상 제공
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: 기술적 보호 및 영상 제공 (Technical)",
      icon: Icons.security, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("영상을 외부로 내보낼 때(USB 등) 반드시 지켜야 할 철칙입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.visibility_off, "마스킹(모자이크) 처리", "타인 얼굴이나 번호판이 포함된 경우 식별 불가능하게 처리 (비용 발생 시 요청자 부담 고지)"), // 🌟 순정
          _buildInfoRow(Icons.receipt, "로그 기록 대장", "일시, 목적, 열람자 인적사항, 파기 예정일을 'CCTV 열람/복제 대장'에 반드시 기록"), // 🌟 순정
          _buildInfoRow(Icons.save, "저장 기간 준수", "통상 30일 이내(용량에 따라 상이) 보관 후 자동 삭제되도록 설정 확인"), // 🌟 순정
        ],
      ),
    );
  }

  // 🔄 CCTV 대응 프로세스 (Mermaid to Enterprise UI)
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
                Text("CCTV 열람 대응 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("CCTV 열람 요청 접수", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 1차 분기점
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("요청자: 경찰 (수사)", "👉 신분확인 및 공문접수\n👉 즉시 열람 및 영상 제공"),
                _buildFlowBranch("요청자: 개인 (피해)", "👉 타인 영상 포함 여부 확인"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 2차 분기점 (개인 요청 시)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("본인만 있음 / 타인 동의 됨", "👉 신청서 작성 후 열람"),
                _buildFlowBranch("타인 포함됨 (동의 불가)", "👉 마스킹 처리 후 열람/제공"),
              ],
            ),
            const SizedBox(height: 16),

            // SM종합관리 기록
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
              child: const Column(
                children: [
                  Text("✅ SM종합관리 기록 및 서명 필수", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Divider(height: 16),
                  Text("모든 과정 후 반드시 'CCTV 관리대장' 작성 및 서명 징구", style: TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  // ⚖️ 5단계: 책임 소재 및 법적 대응 (Table UI)
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 책임 소재 및 법적 대응 (Liability)",
      icon: Icons.gavel, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enterprise Table
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("위반 사례", "법적 처벌", "책임 주체", isHeader: true),
                _buildTableRow("무단 열람/제공", "5년 이하 징역 또는\n5천만 원 이하 벌금", "관리 담당자\n및 회사"),
                _buildTableRow("마스킹 미이행", "개인정보 보호법 위반\n(민사상 손해배상)", "관리 주체\n(SM)"),
                _buildTableRow("대장 미기록", "과태료 부과 대상", "관리회사\n(SM)"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user, color: Color(0xFF64748B), size: 20), // 🌟 순정
                SizedBox(width: 10),
                Expanded(
                  child: Text("SM종합관리의 방어: \"우리는 법률이 정한 열람 절차를 준수하며, 신청서 없이는 단 1초의 영상도 외부 유출하지 않는다\"는 원칙을 고수하여 분쟁에 휘말리지 않음.",
                      style: TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 6단계: 현장 담당자 최종 체크리스트
  Widget _buildStep6() {
    return _buildCard(
      title: "6단계: 현장 담당자 최종 체크리스트 (Mobile)",
      icon: Icons.playlist_add_check, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChecklistItem("[확인] 요청자가 작성한 신청서에 '구체적인 사유'가 적혀 있는가?"),
          _buildChecklistItem("[동의] 타인 정보 포함 시 마스킹 비용(업체 의뢰 시)에 대해 동의를 얻었는가?"),
          _buildChecklistItem("[촬영] 모니터를 스마트폰으로 촬영하지 못하게 통제했는가?", isAlert: true),
          _buildChecklistItem("[기록] 경찰관 방문 시 소속/성명/연락처를 대장에 정확히 기재했는가?"),
          _buildChecklistItem("[로그] USB 등 영상 제공 시 비밀번호를 설정하여 전달했는가?"),
        ],
      ),
    );
  }

  // 🚨 공공기관 긴급 연락처 (크기 완벽 통일 175x65)
  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text("🚨 관련 공공기관 긴급 연락처", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildContactButton("경찰서 (범죄/수사)", "112", isDanger: true),
            _buildContactButton("개인정보침해신고", "118", isDanger: true),
            _buildContactButton("SM 본부 관제팀", "내부망 확인", isDanger: false),
            _buildContactButton("CCTV 유지보수", "단지별 상이", isDanger: false),
          ],
        ),
      ],
    );
  }

  // 🌟 버튼 크기 강제 통일 (SizedBox 적용)
  Widget _buildContactButton(String title, String number, {bool isDanger = false}) {
    Color itemColor = isDanger ? Colors.red.shade600 : primaryNavy;

    // 번호가 없거나 텍스트인 경우 전화걸기 방지
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

  Widget _buildInfoRow(IconData icon, String title, String desc, {Color? colorOverride}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorOverride ?? const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, height: 1.5),
                children: [
                  TextSpan(text: "$title: ", style: TextStyle(fontWeight: FontWeight.bold, color: colorOverride ?? const Color(0xFF0F172A))),
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

  // 📊 책임 소재 표(Table) UI 생성 헬퍼
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

  // ✅ 체크리스트 UI 생성 헬퍼
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