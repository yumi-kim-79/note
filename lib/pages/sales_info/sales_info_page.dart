// 영업정보 페이지 허브 페이지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart'; // 👇 🌟 [에러 해결!] main.dart에 있는 GlobalUserState를 불러오는 마법의 연결선입니다.
import 'sales_inquiry_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SalesInfoPage extends StatelessWidget {
  const SalesInfoPage({super.key});

  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);

  // 🌟 [고도화] 새로고침 시에도 중단 없는 실시간 뱃지 감시기
  Stream<int> _getSalesBadgeCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    // 1. 유저의 정보를 실시간으로 감시하는 스트림을 먼저 생성합니다.
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userSnap) async {

      if (!userSnap.exists) return 0;

      final userData = userSnap.data() as Map<String, dynamic>;
      final String department = userData['department'] ?? '미지정';
      final String role = userData['role'] ?? 'user';

      // 2. 영업부이거나 관리자인지 여기서 직접 확인합니다. (GlobalUserState가 늦게 채워져도 상관없음)
      if (department != '영업부' && role != 'admin') {
        return 0;
      }

      // 3. 조건이 맞다면 실제 신규접수 개수를 가져옵니다.
      final inquirySnap = await FirebaseFirestore.instance
          .collection('sales_inquiries')
          .where('status', isEqualTo: '신규접수')
          .get();

      return inquirySnap.docs.length;
    });
  }

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
                      // 🌟 1. 신규 문의 접수 카드에 실시간 뱃지 감시기를 씌워줍니다!
                      StreamBuilder<int>(
                          stream: _getSalesBadgeCountStream(),
                          builder: (context, snapshot) {
                            int badgeCount = snapshot.data ?? 0;
                            return _buildMenuCard(
                                context,
                                "신규 문의 접수", "전화/온라인으로 들어온 신규 건물 관리 문의를 기록하고 관리합니다.",
                                Icons.add_call, safetyBlue,
                                badgeCount: badgeCount,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesInquiryListPage()))
                            );
                          }
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

  // 🌟 badgeCount 파라미터를 추가하고, 아이콘 우측 상단에 빨간 뱃지를 그리는 로직
  Widget _buildMenuCard(BuildContext context, String title, String desc, IconData icon, Color color, {bool isReady = true, VoidCallback? onTap, int badgeCount = 0}) {
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
            // 🌟 아이콘과 뱃지를 겹쳐서 그리기 위해 Stack 사용
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 36, color: color),
                ),
                // 🌟 숫자가 1 이상일 때만 빨간 뱃지 표시
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
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