// [파일 위치: lib/pages/manual/freeze_manual_page.dart]
// [설명: 현장 대응 매뉴얼 No.02 - 동파 방지 및 해빙 (Enterprise / 100% 호환 순정 아이콘 버전)]

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FreezeManualPage extends StatelessWidget {
  const FreezeManualPage({super.key});

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
          "현장 대응 매뉴얼: 동파 방지 및 해빙",
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
              Icon(Icons.flag, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text("최종 목표", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          Text("1. 동파 사고 제로화\n2. 해빙 시 화재 사고 원천 차단\n3. 공용/전용 책임 명확화",
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  // ❄️ 1단계: 동절기 사전 예방 조치
  Widget _buildStep1() {
    return _buildCard(
      title: "1단계: 동절기 사전 예방 조치 (Pre-Winter Check)",
      icon: Icons.ac_unit, // 🌟 순정 아이콘 유지
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("기온이 영하 5도 이하로 떨어지기 전, 현장 담당자가 반드시 완료해야 하는 예방 리스트입니다.", style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.archive, "계량기함 밀폐 보온", "헌 옷, 에어캡(뽁뽁이), 보온재를 활용하여 계량기함 내부 틈새를 완전히 밀폐"), // 🌟 [수정] archive
          _buildHighlightBox(Icons.power, "열선(Heater Cable) 안전 점검", "• 과열 방지: 열선이 겹쳐지면 국부 과열(화재) 위험이 크므로 겹침 부위 확인\n• 절연 상태: 피복 손상 여부 및 누전 차단기 정상 작동 확인", isWarning: true), // 🌟 [수정] power
          const SizedBox(height: 8),
          _buildInfoRow(Icons.opacity, "퇴수 조치", "외부 노출 배관, 옥상 수전, 소방 배관 말단 드레인 밸브의 잔류수 제거"), // 🌟 [수정] opacity
        ],
      ),
    );
  }

  // 🔍 2단계: 동파 발생 시 초동 진단
  Widget _buildStep2() {
    return _buildCard(
      title: "2단계: 동파 발생 시 초동 진단 (Initial Diagnosis)",
      icon: Icons.search, // 🌟 [수정] search 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("\"물 소리가 안 난다\"는 민원 접수 시 즉시 확인해야 할 진단 로직입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildCaseBox("단수 범위 파악", "동파 지점 특정", "• 특정 세대만 단수: 해당 세대 계량기 또는 세대 내부 배관 동파\n• 라인 전체/건물 전체 단수: 메인 급수관, 옥상 물탱크 출구, 펌프실 배관 동파"),
          const SizedBox(height: 12),
          _buildCaseBox("계량기 파손", "유리면 파손 확인", "• 계량기 유리면이 깨졌거나 부풀어 올랐다면 즉시 동파 교체 대상으로 분류"),
        ],
      ),
    );
  }

  // 🔥 3단계: FM 해빙 작업 지침
  Widget _buildStep3() {
    return _buildCard(
      title: "3단계: FM 해빙 작업 지침 (Safe Thawing)",
      icon: Icons.opacity, // 🌟 [수정] opacity 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("해빙 작업 중 발생하는 '배관 파손'과 '화재'를 막기 위한 엄격한 수칙입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.whatshot, "단계적 온수 사용", "처음부터 50도 이상의 뜨거운 물을 부으면 온도 차로 배관/계량기 파손. 미지근한 물(30도)부터 서서히 온도 상승"), // 🌟 [수정] whatshot
          _buildInfoRow(Icons.waves, "헤어드라이어 활용", "배관에 직접 대지 않고 10cm 이상 거리를 두고 열기를 순환시켜 해빙"), // 🌟 [수정] waves
          const SizedBox(height: 8),
          _buildHighlightBox(Icons.block, "토치(직화) 절대 금지", "가스 토치를 배관에 직접 대는 행위는 화재 및 배관 변형의 주범이므로 SM종합관리 현장 담당자 절대 금기 사항임", isDanger: true), // 🌟 [수정] block
        ],
      ),
    );
  }

  // ⚖️ 4단계: 책임 소재 및 비용 부담 기준 (기업형 Table UI)
  Widget _buildStep4() {
    return _buildCard(
      title: "4단계: 책임 소재 및 비용 부담 기준 (Liability)",
      icon: Icons.gavel, // 🌟 [수정] gavel 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("악성 미납자나 민원인 대응을 위한 법적 기준입니다.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          // 모바일에서 깨지지 않는 커스텀 Table UI
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildTableRow("구분", "동파 부위", "책임 및 비용 주체", isHeader: true),
                _buildTableRow("전용부", "세대 내 노출 배관,\n세대 계량기 유리 파손", "해당 호실\n소유자/점유자"),
                _buildTableRow("공용부", "복도 입상관, 지하 주차장 배관, 메인 밸브", "관리단\n(공용 관리비)"),
                _buildTableRow("관리사무소", "관리자가 보온 권고 및 조치를 다했음에도 발생한 동파", "입주민\n자기 책임 원칙"),
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
                Icon(Icons.security, color: Color(0xFF64748B), size: 20), // 🌟 [수정] security 순정
                SizedBox(width: 10),
                Expanded(
                  child: Text("SM종합관리의 방어: \"관리회사는 공용부에 대한 보온 조치 및 세대별 예방 안내문을 배부함으로써 선량한 관리자의 주의 의무(집합건물법)를 다했음\"을 강조.",
                      style: TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📸 5단계: 기록 및 증거 확보
  Widget _buildStep5() {
    return _buildCard(
      title: "5단계: 현장 기록 및 증거 확보 (Evidence)",
      icon: Icons.camera_alt, // 🌟 [수정] camera_alt 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.add_a_photo, "조치 전 사진 촬영", "동파된 배관의 상태, 계량기 파손 여부를 날짜/시간이 나오게 촬영"), // 🌟 [수정] add_a_photo 순정
          _buildInfoRow(Icons.edit, "해빙 일지 작성", "조치 시간, 사용 장비, 복구 확인 시간 등을 상세히 기록하여 추후 관리비 부과 근거로 활용"), // 🌟 [수정] edit 순정
          _buildInfoRow(Icons.assignment, "안내문 부착", "해빙 완료 후 해당 세대에 \"수도꼭지 미세 개방\" 등 사후 예방 수칙을 서면으로 전달"), // 🌟 [수정] assignment 순정
        ],
      ),
    );
  }

  // ✅ 6단계: 상황별 대응 체크리스트
  Widget _buildStep6() {
    return _buildCard(
      title: "6단계: 상황별 대응 체크리스트 (Mobile Check-list)",
      icon: Icons.playlist_add_check, // 🌟 [수정] playlist_add_check 순정
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChecklistItem("[확인] 계량기 유리 파손 여부 (파손 시 지자체 신고 및 교체)"),
          _buildChecklistItem("[안전] 해빙 작업 전 가연성 물질 제거 및 소화기 비치"),
          _buildChecklistItem("[금지] 가스 토치 등 직화 장비 사용 여부 체크 (사용 금지)", isAlert: true),
          _buildChecklistItem("[기록] 조치 완료 후 누수 여부 재점검 및 사진 전송"),
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
            _buildContactButton("수도사업소(동파 신고)", "120", isDanger: true),
            _buildContactButton("소방서 (화재/오신고)", "119", isDanger: true),
            _buildContactButton("한국전력 (열선 누전)", "123", isDanger: true),
            _buildContactButton("가스안전공사", "1544-4500", isDanger: false),
          ],
        ),
      ],
    );
  }

  // 🌟 버튼 크기 강제 통일 (SizedBox 적용)
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
        icon: Icon(Icons.phone, size: 20, color: itemColor), // 🌟 [수정] phone 순정
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
          Container(width: 1, height: 50, color: const Color(0xFFE2E8F0)),
          Expanded(flex: 4, child: Container(padding: const EdgeInsets.all(12), color: bgColor, child: Text(col2, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13)))),
          Container(width: 1, height: 50, color: const Color(0xFFE2E8F0)),
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
          Icon(isAlert ? Icons.cancel : Icons.check_box, color: isAlert ? Colors.red.shade600 : primaryNavy, size: 22), // 🌟 [수정] cancel / check_box 순정 아이콘
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 15, color: isAlert ? Colors.red.shade800 : const Color(0xFF1E293B), fontWeight: isAlert ? FontWeight.bold : FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}