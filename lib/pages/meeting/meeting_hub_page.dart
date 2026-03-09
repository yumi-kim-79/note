import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'meeting_guide_page.dart';
import 'meeting_script_page.dart';
import 'test.dart';

class MeetingHubPage extends StatelessWidget {
  const MeetingHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("회의 및 분쟁 관리 허브", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 18)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textMain),
        elevation: 0.5,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("📋 회의 및 입주민 분쟁 지원", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text("입주자대표회의 준비부터 사후 회의록 작성, 그리고 분쟁 대처까지 현장소장(담당자)님들을 위한 완벽한 지원 가이드", style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
              ),

              // 1. 회의 진행 및 대처 가이드
              _buildHubCard(
                context,
                icon: Icons.menu_book,
                color: Colors.indigo,
                title: "1. 회의 진행 및 대처 실무 가이드",
                subtitle: "적법한 절차 준수 및 분쟁 대처 노하우",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MeetingGuidePage()));
                },
              ),

              // 2. [실무] 회의진행 (마법의 대본)
              _buildHubCard(
                context,
                icon: Icons.mic_external_on,
                color: Colors.blue,
                title: "2. [실무] 회의진행 (순서 및 멘트)",
                subtitle: "안건설정 후 회의진행 순서 및 멘트 자동생성",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MeetingScriptPage()));
                },
              ),

              if (false) // 3번 숨김 스위치
              // 3. 스마트 의사록 작성기
              _buildHubCard(
                context,
                icon: Icons.edit_document,
                color: Colors.teal,
                title: "3.스마트 의사록 작성기 (준비 중)",
                subtitle: "안건 및 표결 결과를 입력하면 회의록 자동 생성",
                onTap: () => _showReadySnackbar(context),
              ),

              if (false) // 4번 숨김 스위치
              // 4. 필수 법정 양식 다운로드
              _buildHubCard(
                context,
                icon: Icons.download_rounded,
                color: Colors.orange,
                title: "4.회의 필수 양식 다운로드 (준비 중)",
                subtitle: "회의 소집 공고문, 위임장, 서면결의서 표준 양식",
                onTap: () => _showReadySnackbar(context),
              ),

              if (false) // 5번 숨김 스위치
              // 5. 주요 분쟁 및 민원 판례집
              _buildHubCard(
                context,
                icon: Icons.gavel,
                color: Colors.redAccent,
                title: "5.주요 분쟁/민원 판례집 (준비 중)",
                subtitle: "주차장, 층간소음 등 대표적 분쟁에 대한 법적 기준",
                onTap: () => _showReadySnackbar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 허브 메뉴 카드 공통 위젯
  Widget _buildHubCard(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showReadySnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("현재 개발 준비 중인 메뉴입니다."), duration: Duration(seconds: 1)));
  }
}