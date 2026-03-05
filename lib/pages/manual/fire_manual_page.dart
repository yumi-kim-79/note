// [파일 위치: lib/pages/manual/fire_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.05 - 화재 대응, 소방 및 전기 연동 (Enterprise / 순정 아이콘 버전)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FireManualPage extends StatelessWidget {
  const FireManualPage({super.key});

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
          "현장 대응 매뉴얼: 소방 및 화재 대응",
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
              _buildStep1(), // 수신반 확인
              const SizedBox(height: 16),
              _buildStep2ActualFire(), // 🌟 [신규 추가] 실제 화재 대응 (FM 매뉴얼)
              const SizedBox(height: 16),
              _buildStep3(), // 스프링클러 오작동 조치
              const SizedBox(height: 16),
              _buildStep4(), // 펌프 이상 징후
              const SizedBox(height: 16),
              _buildStep5(), // 책임 소재
              const SizedBox(height: 16),
              _buildDecisionTree(), // 사고 대응 프로세스 (화재/비화재보 분기 추가)
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
              Icon(Icons.flag, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text("최종 목표", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          Text("1. 진성 화재 시 인명 대피 최우선 및 초기 진화\n2. 화재 시 설비 가동률 100% 보장\n3. 오작동 시 수해(물난리) 피해 최소화",
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  // 🚨 1단계: 수신기 및 전기 연동 초기 대응
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 소방 수신반 데이터 판독 (Initial Check)",
      icon: Icons.notifications_active,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("화재 경보 시 현장 담당자는 당황하지 말고 '수신반'의 데이터를 먼저 읽어야 합니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.dashboard, "화재 구역 점등", "몇 동, 몇 층, 어느 구역인지 정확히 확인 (표시창 확인)"),
          _buildInfoRow(Icons.link, "전기 연동 상태", "승강기 1층 하향(Homing), 비상방송 자동 송출, 방화셔터/제연팬 가동 여부 점검"),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildHighlightBox(Icons.directions_run, "현장 출동 (2인 1조)", "• 소화기, 무전기, 마스터키, 방연마스크 지참\n• 현장 도착 전까지 수신반의 '경보 정지' 절대 금지", isWarning: true),
        ],
      ),
    );
  }

  // 🔥 2단계: 실제 화재(진성 화재) 대응 FM 매뉴얼 (신규 추가)
  Widget _buildStep2ActualFire() {
    return _buildCard(
      title: "2단계: 실제 화재 발생 시 행동 요령 (R.A.C.E 원칙)",
      icon: Icons.whatshot, // 순정 불꽃 아이콘
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("한국소방안전원 지침에 따른 진성 화재 시 현장 관리자의 최우선 FM 절차입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(height: 16),
          _buildCaseBox("1. 전파/대피 (Rescue)", "가장 먼저 사람을 살립니다", "• 육성 전파: \"불이야!\"를 외치며 주변에 알림\n• 발신기 작동: 층마다 설치된 수동 발신기를 눌러 건물 전체에 경보 울림\n• 대피 유도: 젖은 수건으로 코/입을 막고 자세를 낮추어 '계단'으로 유도"),
          const SizedBox(height: 8),
          _buildCaseBox("2. 119 신고 (Alarm)", "정확한 정보 전달", "• 119에 전화하여 '정확한 주소', '발화 층수', '현재 연기 색상(검은/흰색)', '고립자 유무'를 상세히 보고"),
          const SizedBox(height: 8),
          _buildCaseBox("3. 설비 통제 (Contain)", "확산 방지 및 2차 사고 차단", "• 승강기 통제: 승강기 사용 절대 금지 (정전 시 갇힘, 연기 굴뚝 효과 방지)\n• 방화문 폐쇄: 열려있는 방화문을 닫아 연기 확산 차단\n• 가스 차단: 메인 가스 밸브 즉시 폐쇄"),
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.security, "4. 초기 진화 (Extinguish)", "• 불길이 천장에 닿기 전(골든타임 3분 내)에만 소화기 및 옥내소화전을 활용해 진화 시도\n• 불길이 이미 천장에 닿아 번지고 있다면 초기 진화를 포기하고 즉각 대피할 것", isDanger: true),
        ],
      ),
    );
  }

  // 💧 3단계: 스프링클러(SP) 오작동/누수 조치 (기존 2단계)
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: 비화재보 및 스프링클러 누수 조치",
      icon: Icons.opacity,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("실제 화재가 아님을 확인한 후, 수해(물난리)를 막기 위한 조치입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.build, "전유부 헤드 파손", "해당 층 복도 '알람밸브실' 내 메인 밸브 폐쇄 👉 하단 드레인 밸브를 열어 잔류수 강제 배출"),
          _buildInfoRow(Icons.pan_tool, "지하 펌프 정지", "기계실 이동 후 소방 펌프를 '수동 정지'로 전환하여 계속 물이 밀려오는 것을 차단"),
          _buildInfoRow(Icons.settings_backup_restore, "수신반 복구", "감지기 오작동으로 터진 경우 수신반에서 솔레노이드 밸브 연동 해제 및 복구 버튼 클릭"),
        ],
      ),
    );
  }

  // 🎧 4단계: 지하 소방펌프 이상 징후 판별 (기존 3단계)
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: 지하 소방펌프 가동 시 이상 징후 판별",
      icon: Icons.hearing,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("펌프 가동 시 소리와 냄새만으로 '정상'과 '고장'을 구분해야 합니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          const Text("🔊 소음(Noise) 판별법", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.check_circle, "정상", "규칙적이고 웅장한 모터 회전음"),
          _buildInfoRow(Icons.warning, "이상 1 (금속음)", "\"까르륵/깡깡\" 소리 👉 임펠러 파손 또는 이물질 유입"),
          _buildInfoRow(Icons.vibration, "이상 2 (진동음)", "바닥이 떨릴 정도의 심한 진동 👉 펌프 축(Shaft) 정렬 불량"),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text("👃 냄새(Odor) 판별법", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.whatshot, "고무 타는 냄새", "커플링/벨트 마찰열 👉 즉시 정지 후 점검"),
          _buildInfoRow(Icons.electrical_services, "전기 타는 냄새", "모터 내부 코일 과열 👉 화재 위험 및 소실 주의", colorOverride: Colors.red.shade700),
        ],
      ),
    );
  }

  // ⚖️ 5단계: 책임 소재 및 법적 대응 (기존 4단계)
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 책임 소재 확정 및 관리회사 법적 방어",
      icon: Icons.gavel,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enterprise Table
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("구분", "발생 원인", "책임 주체", isHeader: true),
                _buildTableRow("세대 내 파손", "입주민 부주의(충격),\n세대 내 동파(창문 개방)", "해당 입주민\n(원상복구/배상)"),
                _buildTableRow("초기 진화 실패", "소화기 미비치, 방화문 쐐기 고정", "관리단 및\n행위자 과실"),
                _buildTableRow("SM의 방어", "매월 소방 작동 기능 점검 일지,\n방화문 개방 금지 공문 부착 증거", "SM 면책\n(정상 관리 증명)"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📈 소방/화재 대응 프로세스 (로직 업데이트)
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
                Icon(Icons.account_tree, color: Color(0xFF475569)),
                SizedBox(width: 8),
                Text("소방 및 화재 대응 프로세스", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("화재 경보 수신 및 구역 확인", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),
            _buildFlowStep("현장 출동 및 진위 여부 육안 확인", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            // 진성 화재 vs 비화재보 분기
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("🔥 진성 화재 (연기/불꽃 확인)", "👉 즉시 119 신고 및 비상 방송\n👉 승강기 금지 및 초기 진화/대피 유도"),
                _buildFlowBranch("💧 비화재보 (오작동/누수)", "👉 알람밸브 즉시 차단\n👉 수신기 복구 및 안내 방송"),
              ],
            ),
            const SizedBox(height: 16),

            // SM종합관리 기록
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
              child: const Column(
                children: [
                  Text("✅ SM종합관리 기록 및 보고 필수", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Divider(height: 16),
                  Text("화재 시 119 신고 시각, 초기 대응 내역 타임스탬프 기록\n누수 시 밸브 차단 사진 및 조치 완료 시각 보고", style: TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.5)),
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

  // ✅ 6단계: 현장 담당자 최종 체크리스트
  Widget _buildStep6() {
    return _buildCard(
      title: "6단계: 소방 대응 최종 체크리스트 (Mobile)",
      icon: Icons.playlist_add_check,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChecklistItem("[화재] 대피 안내 시 \"승강기 절대 탑승 금지\"를 전파했는가?", isAlert: true),
          _buildChecklistItem("[화재] 열려있는 방화문들을 닫아 연기 확산을 막았는가?"),
          _buildChecklistItem("[초동] 수신반 현장 확인 전 임의로 '경보 정지'를 누르지 않았는가?", isAlert: true),
          _buildChecklistItem("[차단] 스프링클러 오작동 시 해당 층 알람밸브 위치 확인 및 차단 완료"),
          _buildChecklistItem("[점검] 지하 펌프 기동 시 모터 부근에서 탄 냄새가 나는지 확인"),
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
            _buildContactButton("소방서 (화재/구조)", "119", isDanger: true),
            _buildContactButton("소방시설 유지보수", "단지별 상이", isDanger: false),
            _buildContactButton("전기안전관리자", "단지별 상이", isDanger: false),
            _buildContactButton("가스안전공사", "1544-4500", isDanger: false),
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
        icon: Icon(Icons.phone, size: 20, color: itemColor),
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
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col1, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13), textAlign: TextAlign.center))),
          Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
          Expanded(flex: 4, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col2, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13)))),
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
          Icon(isAlert ? Icons.warning : Icons.check_box, color: isAlert ? Colors.red.shade600 : primaryNavy, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 15, color: isAlert ? Colors.red.shade800 : const Color(0xFF1E293B), fontWeight: isAlert ? FontWeight.bold : FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}