// [파일 위치: lib/pages/manual/leakage_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.01 - 누수(Leakage) 반응형 UI (Enterprise / 100% 호환 순정 아이콘 버전)]

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

  // 🛠️ 1단계: 출동 전 준비
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 출동 전 준비 (Preparation)",
      icon: Icons.work, // 🌟 [수정] 모바일 100% 호환 공구함 아이콘
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("현장에 도착해서 당황하지 않도록 '누수 키트'를 반드시 지참합니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.check_circle, "필수 장비", "강력 후속 전등, 비접촉식 검전기(누전 확인용), 수평계, 스마트폰(촬영용), 열화상 카메라(모바일 연동형)"),
          _buildInfoRow(Icons.description, "필수 서류", "해당 단지 계량기 위치도 및 배관 도면 (SM노트 내 저장/확인 필수)"),
        ],
      ),
    );
  }

  // 🚨 2단계: 초동 조치
  Widget _buildStep2() {
    return _buildCard(
      title: "2단계: 현장 도착 후 초동 조치",
      icon: Icons.warning, // 🌟 [수정] 모바일 100% 호환 경고 아이콘
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("현장 도착 즉시 '안전'과 '차단'을 동시에 진행합니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildHighlightBox(Icons.power, "전기 안전 확인 (감전/화재 방지)", "누수 지점 하단에 콘센트/가전제품이 있다면 즉시 해당 구역 차단기(두꺼비집) 내림", isDanger: true), // 🌟 [수정] power 아이콘
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.speed, "가스 밸브 확인", "배관 누수가 가스 감지기 오작동 및 부식을 유발할 수 있으므로 가스 냄새 여부 체크", isWarning: true), // 🌟 [수정] speed(계기판) 아이콘
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.opacity, "메인 밸브 차단", "• 전용부: 양수기함 내 앵글 밸브 폐쇄\n• 공용부: 펌프실 또는 해당 라인 입상관 밸브 폐쇄"), // 🌟 [수정] opacity(물방울) 아이콘
        ],
      ),
    );
  }

  // 🔍 3단계: 정밀 진단 (장소별 누수 의심 포인트 보강)
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: 정밀 진단 및 원인 파악",
      icon: Icons.build, // 🌟 순정 아이콘
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

          // 👇👇 🌟 [고도화 추가] 주요 장소별 누수 원인 파악 가이드 👇👇
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("📍 주요 장소별 누수 의심 포인트", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.bathtub, "화장실 천장", "점검구를 열어 윗집 하수관/오수관 쪼인트 누수 또는 바닥 방수층 불량 여부 확인"),
          _buildInfoRow(Icons.weekend, "거실/안방 천장", "윗집 난방(보일러) 배관 엑셀파이프 미세 파열 또는 수도 배관 누수 의심"),
          _buildInfoRow(Icons.local_laundry_service, "세탁실/보일러실", "겨울철 배관 동파, 세탁기 하수구 막힘으로 인한 거품 역류, 보일러 분배기 노후화"),
          _buildInfoRow(Icons.window, "베란다/창틀 누수", "비가 올 때만 샌다면 외부 창틀 실리콘(코킹) 노후화 또는 외벽 자체의 크랙(균열) 의심"),
        ],
      ),
    );
  }

  // 🏢 4단계: 특수 시설물
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: 특수 시설물 대응",
      icon: Icons.domain, // 🌟 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHighlightBox(Icons.whatshot, "소방 스프링클러 누수", "1. 프리액션 밸브(Pre-action) 오작동 확인\n2. 화재가 아님을 확인 후, 수신반에서 구역 솔레노이드 밸브 폐쇄\n3. 소방차 출동 방지를 위해 상황실 보고 및 119 오신고 정정", isDanger: true), // 🌟 [수정] whatshot(불꽃) 아이콘
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.wb_sunny, "난방(중앙/지역) 누수", "세대 내 분배기 누수인지 확인. 난방수는 일반 수돗물과 색이나 냄새가 다르므로 즉시 구분할 것.", isWarning: true), // 🌟 [수정] wb_sunny(열/난방) 아이콘
        ],
      ),
    );
  }

  // 📸 5단계: 증거 확보
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 법적 증거 확보 및 기록",
      icon: Icons.camera_alt, // 🌟 [수정] 모바일 100% 호환 카메라 아이콘
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("악성 민원 방지를 위한 가장 중요한 방어 수단입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.looks_one, "원인 지점 촬영", "윗집 바닥, 배관 터진 곳 등"), // 🌟 [수정] looks_one 아이콘
          _buildInfoRow(Icons.looks_two, "피해 지점 촬영", "아랫집 천장, 젖은 가구 등"), // 🌟 [수정] looks_two 아이콘
          _buildInfoRow(Icons.looks_3, "계량기 촬영", "날짜와 시간이 찍히도록 조치 전/후 계량기 상태 비교 촬영"), // 🌟 [수정] looks_3 아이콘
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildInfoRow(Icons.edit, "SM노트에 기록", "몇 시 몇 분에 어떤 조치를 취했는지 실시간 타임스탬프로 명확히 기록할 것"), // 🌟 [수정] edit 아이콘
        ],
      ),
    );
  }

  // 💬 6단계: 책임 소재별 CS 커뮤니케이션 (스크립트 대폭 보강)
  Widget _buildStep6() {
    return _buildCard(
      title: "6단계: 책임 소재별 CS 대응 및 스크립트",
      icon: Icons.headset_mic, // 🌟 순정 아이콘
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("집합건물법에 따른 정확한 책임 규명과 안내가 분쟁을 막습니다. 절대 사설 업체를 직접 알선하지 마십시오.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),

          // 👇👇 🌟 [오류 해결] 누수 페이지 전용 _buildHighlightBox를 사용하여 에러 완벽 해결! 👇👇
          _buildHighlightBox(
              Icons.person,
              "[전유부 누수] 윗집 배관 터짐 👉 아랫집 피해",
              "• 원칙: 집합건물법 제6조에 따라 해당 호실 소유자/점유자가 100% 수리 및 배상 책임.\n"
                  "• 역할: 누수 지점 확인 및 양측 중재.\n\n"
                  "🗣️ [안내 스크립트]\n"
                  "\"확인 결과 윗집 전용 배관 문제입니다. 관리소에서 윗집에 즉각 수리 및 도배 배상을 요청했습니다. 윗집의 '일상생활배상책임보험'으로 원만히 처리될 수 있도록 중재하겠습니다.\"",
              isWarning: true // 주황색 경고 테마
          ),
          const SizedBox(height: 12),

          _buildHighlightBox(
              Icons.apartment,
              "[공용부 누수] 옥상 방수 불량 👉 최상층 피해",
              "• 원칙: 옥상, 메인 입상관 등은 공용부이므로 관리단(공용 비용)에서 수리 및 배상 책임.\n"
                  "• 역할: 현장 채증 후 관리단 보고 및 공사 기안 상정.\n\n"
                  "🗣️ [안내 스크립트]\n"
                  "\"확인 결과 옥상 방수층 하자로 인한 공용부 책임입니다. 즉시 대표회의(관리단)에 보고하여 옥상 보수 공사 요청하도록 해야합니다. 추후 대표회의(관리단)와 협의후 진행사항은 별도 안내 또는 공지로 진행된다고 안내해야합니다. (필독)대표회의(관리단) 협의시 피해세대 도배 및 복구비용도 협의사항입니다. 협의 완료 후 해당세대에 도배 피해 복구도 공용 비용으로 처리된다 또는 불가한지 안내해야됩니다.\"",
              isDanger: true // 빨간색 위험 테마
          ),
          const SizedBox(height: 12),

          _buildHighlightBox(
              Icons.window,
              "[외벽/창틀 누수] 우천 시 빗물 유입 (원인 모호)",
              "• 외벽 크랙: 공용부 하자로 관리단에서 보수 진행.\n"
                  "• 창틀 실리콘 노후: 전유부 하자로 세대주가 개별 보수.\n\n"
                  "🗣️ [안내 스크립트]\n"
                  "\"세대 창틀의 실리콘 노후화로 인한 빗물 유입은 전용부 관리 사항으로 세대에서 개별 코킹을 하셔야 합니다. 단, 외벽 자체의 크랙이 원인으로 판명될 경우 공용부 수선 계획에 따라 보수 조치하겠습니다.\"",
              isDanger: false, isWarning: false // 파란색 일반 테마
          ),
        ],
      ),
    );
  }

  // 🔄 의사결정 트리 UI
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
                Icon(Icons.account_tree, color: Color(0xFF475569)), // 🌟 [수정] 모바일 100% 호환 트리 아이콘
                SizedBox(width: 8),
                Text("상황별 의사결정 흐름도", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("누수 신고 접수 및 현장 안전 확인", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("계량기 테스트 진행", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 분기점
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
      width: 240,
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

  // 🚨 공공기관 긴급 연락처
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
            _buildContactButton("소방서 (오신고 정정)", "119", isDanger: true),
            _buildContactButton("한국전력 (누전/정전)", "123", isDanger: true),
            _buildContactButton("가스안전공사", "1544-4500", isDanger: true),
            _buildContactButton("상수도/다산콜", "120", isDanger: false),
          ],
        ),
      ],
    );
  }

  // 🌟 버튼 크기 강제 통일
  Widget _buildContactButton(String title, String number, {bool isDanger = false}) {
    Color itemColor = isDanger ? Colors.red.shade600 : primaryNavy;

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
        icon: Icon(Icons.phone, size: 20, color: itemColor), // 🌟 [수정] 순정 전화기 아이콘
        label: Text("$title\n$number", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: itemColor, height: 1.3)),
        onPressed: () => _makePhoneCall(number),
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