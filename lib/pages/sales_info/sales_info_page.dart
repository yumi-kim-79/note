//영업정보 페이지 허브 페이지

import 'package:flutter/material.dart';
import 'sales_inquiry_list_page.dart'; // 1번 메뉴 연결용

class SalesInfoPage extends StatelessWidget {
  const SalesInfoPage({super.key});

  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assessment, color: primaryNavy, size: 32),
                    const SizedBox(width: 12),
                    Text("영업 정보 허브 (Sales Hub)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text("신규 단지 문의 접수 및 영업 활동을 관리하는 통합 대시보드입니다.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 32),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: isMobile ? 1 : 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: isMobile ? 2.5 : 2.0,
                    children: [
                      // 🌟 1. 신규 문의 접수 (활성화)
                      _buildMenuCard(
                          context,
                          "신규 문의 접수", "전화/온라인으로 들어온 신규 건물 관리 문의를 기록하고 관리합니다.",
                          Icons.add_call, safetyBlue,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesInquiryListPage()))
                      ),

                      // 2. 준비 중
                      _buildMenuCard(context, "견적서 및 제안서 관리", "작성된 견적서와 제안서를 단지별로 보관하고 진행률을 체크합니다.", Icons.request_quote, Colors.grey, isReady: false),

                      // 3. 준비 중
                      _buildMenuCard(context, "영업 타겟(DB) 관리", "네이버 지도를 기반으로 우리 회사가 타겟팅할 아파트/상가 목록입니다.", Icons.domain_verification, Colors.grey, isReady: false),

                      // 4. 준비 중
                      _buildMenuCard(context, "계약 성공 현황", "최종 계약이 성사되어 현장팀으로 이관된 단지 히스토리입니다.", Icons.handshake, Colors.grey, isReady: false),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String desc, IconData icon, Color color, {bool isReady = true, VoidCallback? onTap}) {
    return InkWell(
      onTap: isReady ? onTap : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("현재 개발 준비 중인 메뉴입니다."))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isReady ? color.withOpacity(0.3) : Colors.grey.shade300, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isReady ? primaryNavy : Colors.grey))),
                      if (!isReady) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)), child: const Text("준비중", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)))
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(desc, style: TextStyle(fontSize: 13, color: isReady ? Colors.grey.shade600 : Colors.grey.shade400, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}