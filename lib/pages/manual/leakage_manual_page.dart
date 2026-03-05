// [파일 위치: lib/pages/manual/leakage_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.01 - 누수(Leakage) 반응형 UI (Enterprise 버전)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LeakageManualPage extends StatelessWidget {
  const LeakageManualPage({super.key});

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
      backgroundColor: const Color(0xFFF8FAFC), // 더 깔끔하고 고급스러운 연회색 배경 (Slate 50)
      appBar: AppBar(
        title: const Text(
          "현장 대응 매뉴얼: 누수(Leakage)",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        elevation: 0.5, // 섀도우를 얇게 주어 세련되게
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
              _buildStep5(),
              const SizedBox(height: 16),
              _buildDecisionTree(),
              const SizedBox(height: 16),
              _buildStep6(),
              const SizedBox(height: 32),
              _buildEmergencyContacts(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 최종 목표 헤더 (톤다운된 세련된 그라데이션)
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
              Icon(Icons.flag, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text("최종 목표", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          Text("1. 2차 피해 방지 (안전 확보)\n2. 법적 책임 소재의 명확한 증거 확보\n3. 민원 발생 최소화 (정확한 안내)",
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  // 🛠️ 1단계: 출동 전 준비 (AIVEX 완벽 제거)
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 출동 전 준비 (Preparation)",
      icon: Icons.home_repair_service,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("현장에 도착해서 당황하지 않도록 '누수 키트'를 반드시 지참합니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.check_circle_outline, "필수 장비", "강력 후속 전등, 비접촉식 검전기(누전 확인용), 수평계, 스마트폰(촬영용), 열화상 카메라(모바일 연동형)"),
          _buildInfoRow(Icons.description_outlined, "필수 서류", "해당 단지 계량기 위치도 및 배관 도면 (SM노트 내 저장/확인 필수)"),
        ],
      ),
    );
  }

  // 🚨 2단계: 초동 조치 (위험 요소만 컬러 포인트 유지)
  Widget _buildStep2() {
    return _buildCard(
      title: "2단계: 현장 도착 후 초동 조치",
      icon: Icons.warning_amber_rounded,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("현장 도착 즉시 '안전'과 '차단'을 동시에 진행합니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildHighlightBox(Icons.electrical_services, "전기 안전 확인 (감전/화재 방지)", "누수 지점 하단에 콘센트/가전제품이 있다면 즉시 해당 구역 차단기(두꺼비집) 내림", isDanger: true),
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.gas_meter, "가스 밸브 확인", "배관 누수가 가스 감지기 오작동 및 부식을 유발할 수 있으므로 가스 냄새 여부 체크", isWarning: true),
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.water_drop, "메인 밸브 차단", "• 전용부: 양수기함 내 앵글 밸브 폐쇄\n• 공용부: 펌프실 또는 해당 라인 입상관 밸브 폐쇄"),
        ],
      ),
    );
  }

  // 🔍 3단계: 정밀 진단
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: 정밀 진단 및 원인 파악",
      icon: Icons.plumbing,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("단순히 물을 잠그는 것을 넘어, '누가 수리비를 낼 것인가'를 결정짓는 핵심 단계입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildBulletText("수도계량기 별표(⭐) 테스트"),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• 밸브를 잠갔을 때 별이 멈추면 👉 냉/온수 배관 누수 (100% 전용부 소유주 책임)", style: TextStyle(color: Color(0xFF334155), height: 1.5)),
                Text("• 밸브를 잠가도 계속 돌면 👉 계량기 이전 공용관 누수 (관리단 책임)", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, height: 1.5)),
              ],
            ),
          ),
          _buildBulletText("하수/방수 테스트"),
          const Padding(
            padding: EdgeInsets.only(left: 20.0, bottom: 12.0),
            child: Text("• 물을 쓸 때만 새거나, 윗집이 샤워할 때만 샌다면 방수층 균열 또는 하수관 파손 의심", style: TextStyle(color: Color(0xFF334155), height: 1.5)),
          ),
          _buildBulletText("미세 누수 확인 (열화상)"),
          const Padding(
            padding: EdgeInsets.only(left: 20.0),
            child: Text("• 육안으로 안 보일 때 열화상 카메라로 벽면의 온도 차를 확인하여 물줄기 파악", style: TextStyle(color: Color(0xFF334155), height: 1.5)),
          ),
        ],
      ),
    );
  }

  // 🏢 4단계: 특수 시설물
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: 특수 시설물 대응",
      icon: Icons.domain,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHighlightBox(Icons.fire_hydrant_alt, "소방 스프링클러 누수", "1. 프리액션 밸브(Pre-action) 오작동 확인\n2. 화재가 아님을 확인 후, 수신반에서 구역 솔레노이드 밸브 폐쇄\n3. 소방차 출동 방지를 위해 상황실 보고 및 119 오신고 정정", isDanger: true),
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.thermostat, "난방(중앙/지역) 누수", "세대 내 분배기 누수인지 확인. 난방수는 일반 수돗물과 색이나 냄새가 다르므로 즉시 구분할 것.", isWarning: true),
        ],
      ),
    );
  }

  // 📸 5단계: 증거 확보
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 법적 증거 확보 및 기록",
      icon: Icons.camera_alt_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("악성 민원 방지를 위한 가장 중요한 방어 수단입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.filter_1, "원인 지점 촬영", "윗집 바닥, 배관 터진 곳 등"),
          _buildInfoRow(Icons.filter_2, "피해 지점 촬영", "아랫집 천장, 젖은 가구 등"),
          _buildInfoRow(Icons.filter_3, "계량기 촬영", "날짜와 시간이 찍히도록 조치 전/후 계량기 상태 비교 촬영"),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildInfoRow(Icons.edit_document, "SM노트에 기록", "몇 시 몇 분에 어떤 조치를 취했는지 실시간 타임스탬프로 명확히 기록할 것"),
        ],
      ),
    );
  }

  // 🔄 의사결정 트리 UI (모노톤 & 그레이스케일로 기업형 통일)
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
                Icon(Icons.account_tree_outlined, color: Color(0xFF475569)),
                SizedBox(width: 8),
                Text("상황별 의사결정 흐름도", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("누수 신고 접수 및 현장 안전 확인", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("계량기 테스트 진행", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 분기점 (알록달록함 제거, 통일된 아웃라인 스타일)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("계량기 멈춤", "전용부/배관 누수\n👉 윗집 통보 및 보험 안내"),
                _buildFlowBranch("계량기 계속 돔", "공용부 배관 누수\n👉 관리소 직영수리/업체호출"),
                _buildFlowBranch("계량기 반응 없음", "방수/하수관 문제\n(물 쓸때만 샌다면 윗집 책임)"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("최종 조치: 현장 보고서 작성 완료", const Color(0xFFF1F5F9)),
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
      width: 240, // PC/태블릿에서도 가지런하게 보이도록 사이즈 고정
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1))
      ),
      child: Column(
        children: [
          Text(condition, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(result, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A), height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // 💬 6단계: CS 커뮤니케이션
  Widget _buildStep6() {
    return _buildCard(
      title: "6단계: 민원 관리 및 커뮤니케이션 (CS)",
      icon: Icons.support_agent,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("피해 세대(아랫집)와 원인 세대(윗집) 사이의 분쟁을 조율하고 중립을 유지합니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Text("현장 안내 권장 멘트", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  ],
                ),
                SizedBox(height: 12),
                Text("\"현재 관리 규약 및 집합건물법에 따라 원인 파악을 마쳤습니다. 전용부 누수의 경우 소유주께서 수리 및 배상 책임을 지게 됩니다. 원활한 처리를 위해 일상생활배상책임보험 접수를 권장해 드립니다.\"",
                    style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.6, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
              SizedBox(width: 8),
              Expanded(child: Text("특정 사설 업체 소개를 지양하고, 관리회사는 '객관적 증거 제공자'로서의 위치를 지킵니다.", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), height: 1.4))),
            ],
          )
        ],
      ),
    );
  }

  // 🚨 공공기관 긴급 연락처 (크기 완벽 통일 및 기업형 라인 버튼 디자인)
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
          // 화면에 꽉 차게 나열되도록 설정
          children: [
            _buildContactButton("소방서 (오신고 정정)", "119", isDanger: true),
            _buildContactButton("한국전력 (누전/정전)", "123", isDanger: true),
            _buildContactButton("가스안전공사", "1544-4500", isDanger: true),
            _buildContactButton("상수도/다산콜", "120", isDanger: false),
          ],
        ),
      ],
    );
  }

  // 🌟 버튼 크기 강제 통일 (SizedBox 적용)
  Widget _buildContactButton(String title, String number, {bool isDanger = false}) {
    Color itemColor = isDanger ? Colors.red.shade600 : primaryNavy;

    return SizedBox(
      width: 175, // 가로 폭 완벽 통일
      height: 65, // 세로 폭 완벽 통일
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: itemColor,
          side: BorderSide(color: itemColor.withOpacity(0.3), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero, // 텍스트 짤림 방지
        ),
        icon: Icon(Icons.phone_in_talk, size: 20, color: itemColor),
        label: Text("$title\n$number", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: itemColor, height: 1.3)),
        onPressed: () => _makePhoneCall(number),
      ),
    );
  }

  // --- 공통 UI 헬퍼 위젯들 (컬러 톤 다운 및 통일) ---

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

  Widget _buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}