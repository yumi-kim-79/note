// [파일 위치: lib/pages/safety/vehicle_safety_page.dart]
// [설명: 현장 안전 수칙 No.01 - 회사 차량 안전 운행 (Enterprise Safety Protocol 양식)]

import 'package:flutter/material.dart';

class VehicleSafetyPage extends StatelessWidget {
  const VehicleSafetyPage({super.key});

  // 🏢 대기업 안전 규정용 컬러 팔레트
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);
  final Color dangerRed = const Color(0xFFDC2626);
  final Color warningOrange = const Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // 기존보다 살짝 더 차분한 배경색
      appBar: AppBar(
        title: const Text(
          "안전 수칙: 차량 운행간 안전수칙",
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
              _buildPromiseHeader(), // 🌟 [신규 양식] 감성적이고 무거운 안전 약속 헤더
              const SizedBox(height: 24),
              _buildStep1(),
              const SizedBox(height: 16),
              _buildStep2(),
              const SizedBox(height: 16),
              _buildStep3(),
              const SizedBox(height: 16),
              _buildDecisionTree(), // 차량 운행 로직
              const SizedBox(height: 16),
              _buildStep4(), // 나와의 약속 (체크리스트)
              const SizedBox(height: 16),
              _buildStep5(), // 사고 발생 시 지원
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🤝 도입부: 우리의 약속 (감성적 & 책임감 부여 양식)
  Widget _buildPromiseHeader() {
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
          const Icon(Icons.verified_user, color: Colors.white, size: 40), // 🌟 순정 보안/약속 아이콘
          const SizedBox(height: 16),
          const Text("우리의 약속", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "\"당신이 운전하는 1분 1초가 SM종합관리의 품격입니다.\n가족이 기다리는 집으로 안전하게 복귀하는 것,\n그것이 오늘 당신의 가장 중요한 임무입니다.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade100, fontSize: 15, height: 1.8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 🚗 1단계: 파트너와의 아침 인사
  Widget _buildStep1() {
    return _buildSectionCard(
      title: "1단계: 파트너(차량)와의 아침 인사 - 기본 점검",
      subtitle: "출발 전 5분의 점검이 고속도로 위 5시간의 낭패를 막습니다.",
      accentColor: safetyBlue,
      icon: Icons.directions_car, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.settings, "신발(타이어) 확인", "공기압이 낮아 보이지 않는지, 타이어 사이에 큰 돌이나 못이 박혀있지 않은지 눈으로 훑어보십시오."),
          _buildActionItem(Icons.opacity, "생명수(냉각수 및 오일) 체크", "차 바닥에 액체가 떨어진 흔적이 있다면 즉시 보고하십시오. 엔진 과열은 고립을 유발합니다."),
          _buildActionItem(Icons.wb_incandescent, "눈과 입(등화 장치) 점검", "방향지시등과 브레이크등은 타인과 대화하는 유일한 수단입니다. 전구가 나갔다면 사고를 유발합니다."),
          _buildActionItem(Icons.delete, "깔끔한 내부", "빈 캔이 브레이크 페달 밑으로 굴러 들어가는 상황을 상상해 보십시오. 운전석 바닥은 항상 비워야 합니다."),
        ],
      ),
    );
  }

  // 📵 2단계: 운행 중 절대 금지 수칙
  Widget _buildStep2() {
    return _buildSectionCard(
      title: "2단계: 운행 중 절대 금지 수칙",
      subtitle: "\"생명은 편집되지 않습니다.\" 오직 도로만 보십시오.",
      accentColor: dangerRed,
      icon: Icons.warning,
      content: Column(
        children: [
          _buildHighlightAction(Icons.phonelink_off, "영상 시청 및 영상 통화 절대 금지", "유튜브, 숏폼 시청은 '눈을 감고 운전하는 것'과 같습니다. 시속 60km에서 3초만 화면을 봐도 50m를 무방비로 돌진합니다.", isDanger: true),
          // 🌟 에러 원인이었던 isWarning 삭제 완료! (기본값으로 깔끔하게 나옵니다)
          _buildHighlightAction(Icons.airline_seat_recline_normal, "전 좌석 안전벨트", "\"잠깐 이동인데 뭐 어때\"라는 생각이 비극을 부릅니다. 안전벨트는 차 밖으로 튕겨 나가지 않게 잡아주는 유일한 생명줄입니다."),
          _buildHighlightAction(Icons.directions_walk, "단지 내 '거북이' 주행", "우리가 관리하는 단지는 아이들이 튀어나올 수 있습니다. 무조건 서행하며, 보행자가 보이면 먼저 멈추고 미소를 지어 주십시오."),
        ],
      ),
    );
  }

  // 🅿️ 3단계: 경사로 주차
  Widget _buildStep3() {
    return _buildSectionCard(
      title: "3단계: 비극을 막는 10초의 기적 - 경사로 주차",
      subtitle: "경사로 주차 사고는 타인의 가정을 파괴할 수 있습니다.",
      accentColor: warningOrange,
      icon: Icons.local_parking, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.block, "고인목(바퀴 받침대) 필수", "\"금방 올 건데\"라는 마음이 차를 괴물로 만듭니다. 고인목을 고여 차가 밀릴 가능성을 0.1%도 남기지 마십시오."),
          _buildActionItem(Icons.rotate_left, "핸들은 벽 쪽으로", "만약의 사태에 대비해 핸들을 길가 연석 방향으로 끝까지 꺾어두십시오. 도로 아래 질주를 막는 마지막 방어선입니다."),
          _buildActionItem(Icons.local_parking, "P단 + 사이드브레이크", "기어만 P에 두지 마십시오. 수동이든 전자식이든 사이드브레이크를 끝까지 체결하는 습관이 프로 정신입니다."),
        ],
      ),
    );
  }

  // 📝 4단계: 나와의 약속 (체크리스트)
  Widget _buildStep4() {
    return _buildSectionCard(
      title: "4단계: 현장 담당자의 '나와의 약속'",
      subtitle: "매일 운전대를 잡기 전 스스로에게 묻습니다.",
      accentColor: primaryNavy,
      icon: Icons.playlist_add_check, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildPledgeItem("나는 오늘 아침 내 차의 등화 장치와 타이어를 확인했는가?"),
          _buildPledgeItem("운전 중 유튜브나 영상을 보고 싶은 유혹을 이겨냈는가?"),
          _buildPledgeItem("단지 내에서 보행자를 위해 여유 있게 브레이크를 밟았는가?"),
          _buildPledgeItem("경사로에서 고인목을 설치하며 '내 차는 움직이지 않는다'고 확신했는가?"),
          _buildPledgeItem("SM 로고가 부착된 차량으로 매너 있는 운전을 실천했는가?"),
        ],
      ),
    );
  }

  // 🛡️ 5단계: 사고 발생 시 지원
  Widget _buildStep5() {
    return _buildSectionCard(
      title: "5단계: 사고 발생 시, 회사는 당신의 뒤에 있습니다",
      subtitle: "숨기지 않는 정직함이 당신을 보호합니다.",
      accentColor: Colors.teal,
      icon: Icons.security, // 🌟 순정 아이콘
      content: Column(
        children: [
          _buildActionItem(Icons.record_voice_over, "정직이 최선입니다", "사고가 났다면 당황하지 말고 즉시 본부에 보고하십시오. 숨기려다 키우는 사고보다, 즉시 보고하여 해결하는 사고가 훨씬 적게 듭니다."),
          _buildActionItem(Icons.sd_card, "증거의 힘", "상대방이 억지를 부린다면 블랙박스 칩(SD카드)을 뽑아 보관하고, 현장 사진을 다각도에서 찍어두십시오. 회사가 당신의 무고함을 증명해 드릴 것입니다."),
        ],
      ),
    );
  }

  // 🔄 차량 안전 프로세스 (Mermaid to UI)
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
                Icon(Icons.account_tree, color: primaryNavy), // 🌟 순정 아이콘
                const SizedBox(width: 8),
                Text("차량 운행 안전 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("출근 및 차량 외관/누유 점검", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("타이어/등화장치 확인 후 안전벨트 착용 및 출발", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 운행 중 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("🚨 유튜브/영상통화 유혹", "절대 금지: 생명과 직결됨"),
                _buildFlowBranch("🧭 내비게이션 조작 필요", "정차 후 안전하게 조작 원칙"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("단지 도착 및 보행자 우선 서행 주행", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 주차 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("경사로 주차 시", "👉 P단 + 사이드 + 핸들 꺾기 + 고인목"),
                _buildFlowBranch("평지 주차 시", "👉 후진 주차 및 차량 내부 정리"),
              ],
            ),
            const SizedBox(height: 16),

            // 최종 결론
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)),
              child: const Text("✨ 안전한 현장 업무 수행 완료 (SM종합관리의 약속)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  // --- [신규 디자인 양식] UI 헬퍼 위젯들 ---

  // 🎨 좌측 컬러 포인트가 있는 새로운 섹션 카드
  Widget _buildSectionCard({required String title, required String subtitle, required Color accentColor, required IconData icon, required Widget content}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      // 🌟 [핵심 해결책] IntrinsicHeight를 추가하여 무한대로 높이가 늘어나 엔진이 뻗는 현상을 완벽 차단!
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 좌측 컬러 바
            Container(width: 6, decoration: BoxDecoration(color: accentColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: accentColor, size: 26),
                        const SizedBox(width: 10),
                        Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const Divider(height: 30, thickness: 1, color: Color(0xFFF1F5F9)),
                    content,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📌 일반적인 액션 아이템
  Widget _buildActionItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⚠️ 강조 액션 아이템 (위험/주의)
  Widget _buildHighlightAction(IconData icon, String title, String desc, {bool isDanger = false}) {
    Color bgColor = isDanger ? Colors.red.shade50 : const Color(0xFFF8FAFC);
    Color iconColor = isDanger ? Colors.red.shade700 : primaryNavy;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDanger ? Colors.red.shade100 : const Color(0xFFE2E8F0))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDanger ? Colors.red.shade800 : primaryNavy, fontSize: 15)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ✅ 나와의 약속 체크리스트 전용 아이템
  Widget _buildPledgeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_box, color: primaryNavy, size: 22), // 🌟 순정 아이콘
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4)),
          ),
        ],
      ),
    );
  }

  // --- 플로우차트용 헬퍼 ---
  Widget _buildFlowStep(String text, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
}