// [파일 위치: lib/pages/dashboard/widgets/recent_sales.dart]
// 대시보드 [최근작성노트]
// 1. [기능 추가] '나만 보기(isPrivate)' 필터링 적용 (남이 쓴 비공개 글은 리스트에서 완전 제외)
// 2. [UI 개선] 내가 쓴 비공개 글은 제목 옆과 팝업창에 자물쇠(🔒) 아이콘 표시
// 3. [안정성 유지] PC/모바일 반응형 레이아웃 충돌 방지 로직(Expanded, MainAxisSize) 100% 유지
// 4. [기존 기능 유지] 5개씩 보기(페이지네이션), 팝업창, 다중 이미지 뷰어 100% 유지
// 5. [🌟 핵심 해결] 모바일(화면 좁음)일 때 ListView 대신 Column을 사용하여 내부 스크롤을 막고, 전체 화면 스크롤이 정상 작동하도록 개선

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ 인증 정보 확인용
import 'package:intl/intl.dart';
import '../../../services/sales_service.dart';
import '../../../main.dart'; // 🌟 [고도화 추가] GlobalUserState(스마트 캐싱)를 가져옵니다.

// ✅ 디자인 시스템 import
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

class RecentSales extends StatefulWidget {
  const RecentSales({super.key});

  @override
  State<RecentSales> createState() => _RecentSalesState();
}

class _RecentSalesState extends State<RecentSales> {
  final SalesService _salesService = SalesService();

  // [설정] 5개씩 유지
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    // 🌟 [핵심 고도화] 매번 Auth 모듈을 깨우는 대신, 폰 메모리에 있는 내 UID를 0초 만에 꺼내옵니다.
    final String myUid = GlobalUserState.uid;
    // ✅ PC/모바일 환경 구분 (에러 방지용 핵심 변수)
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    Widget buildCard() {
      return CommonCard(
        padding: EdgeInsets.zero,
        child: StreamBuilder<QuerySnapshot>(
          stream: _salesService.getSalesNotesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var allDocs = snapshot.hasData ? snapshot.data!.docs : [];

            // =======================================================
            // ✅ [고도화 1] 나만 보기(비공개) 필터링 로직
            // =======================================================
            allDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              bool isPrivate = data['isPrivate'] ?? false;
              String authorUid = data['uid'] ?? '';

              // 공개 글이면 무조건 통과
              if (!isPrivate) return true;
              // 🌟 [고도화 적용] 비공개 글이면 작성자와 내 메모리 속 UID가 같을 때만 통과
              return authorUid == myUid;
            }).toList();

            if (allDocs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("작성된 노트가 없습니다.", style: TextStyle(color: AppTheme.textSub)),
                ),
              );
            }

            // 페이지네이션 계산 로직 유지
            int totalItems = allDocs.length;
            int totalPages = (totalItems / _itemsPerPage).ceil();

            if (_currentPage > totalPages) _currentPage = totalPages;
            if (_currentPage < 1) _currentPage = 1;

            int startIndex = (_currentPage - 1) * _itemsPerPage;
            int endIndex = startIndex + _itemsPerPage;
            if (endIndex > totalItems) endIndex = totalItems;

            final currentDocs = allDocs.sublist(startIndex, endIndex);

            // =======================================================
            // 🌟 [대기업 렌더링 방식 적용] 모바일 스크롤 버그 원천 차단
            // =======================================================
            Widget listWidget;

            if (isMobile) {
              // 모바일 환경: ListView를 쓰지 않고 Column으로 렌더링하여 터치 가로채기 방지
              listWidget = Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 여백 최소화
                  children: currentDocs.asMap().entries.map((entry) {
                    int index = entry.key;
                    var doc = entry.value;
                    final data = doc.data() as Map<String, dynamic>;
                    DateTime date = (data['createdAt'] as Timestamp).toDate();
                    bool isPrivate = data['isPrivate'] ?? false;

                    Widget item = ListTile(
                      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      dense: true,
                      leading: const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
                      title: Row(
                        children: [
                          if (isPrivate)
                            const Padding(
                              padding: EdgeInsets.only(right: 6.0),
                              child: Icon(Icons.lock, size: 14, color: Colors.grey),
                            ),
                          Expanded(
                            child: Text(
                              data['title'] ?? '(제목 없음)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        "${data['author']} • ${DateFormat('MM/dd HH:mm').format(date)}",
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSub),
                      ),
                      onTap: () => _showDetailPopup(context, data),
                    );

                    // 마지막 항목이 아니면 밑줄 추가
                    if (index < currentDocs.length - 1) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [item, const Divider(height: 1, color: AppTheme.borderColor)],
                      );
                    }
                    return item;
                  }).toList(),
                ),
              );
            } else {
              // PC 환경: 기존 방식대로 스크롤이 가능한 ListView 유지
              listWidget = ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                itemCount: currentDocs.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderColor),
                itemBuilder: (context, index) {
                  final data = currentDocs[index].data() as Map<String, dynamic>;
                  DateTime date = (data['createdAt'] as Timestamp).toDate();
                  bool isPrivate = data['isPrivate'] ?? false;

                  return ListTile(
                    visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    dense: true,
                    leading: const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
                    title: Row(
                      children: [
                        if (isPrivate)
                          const Padding(
                            padding: EdgeInsets.only(right: 6.0),
                            child: Icon(Icons.lock, size: 14, color: Colors.grey),
                          ),
                        Expanded(
                          child: Text(
                            data['title'] ?? '(제목 없음)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      "${data['author']} • ${DateFormat('MM/dd HH:mm').format(date)}",
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSub),
                    ),
                    onTap: () => _showDetailPopup(context, data),
                  );
                },
              );
            }

            return Column(
              // 🚨 [핵심 유지] 모바일/PC 렌더링 에러 방지
              mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
              children: [
                isMobile ? listWidget : Expanded(child: listWidget),
                if (totalPages > 1)
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 18, color: AppTheme.textSub),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                        ),
                        const SizedBox(width: 12),
                        ...List.generate(totalPages, (index) {
                          int pageNum = index + 1;
                          bool isCurrent = _currentPage == pageNum;
                          return InkWell(
                            onTap: () => setState(() => _currentPage = pageNum),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCurrent ? AppTheme.primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$pageNum",
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : AppTheme.textMain,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSub),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // 🚨 [핵심 유지] 모바일/PC 렌더링 에러 방지
      mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
      children: [
        const Text("🔥 최근 작성 노트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
        const SizedBox(height: 12),
        isMobile ? buildCard() : Expanded(child: buildCard()),
      ],
    );
  }

  // ✅ [유지 & 개선] 상세 보기 팝업
  void _showDetailPopup(BuildContext context, Map<String, dynamic> data) {
    DateTime date = (data['createdAt'] as Timestamp).toDate();
    bool isPrivate = data['isPrivate'] ?? false; // ✅ 팝업에도 표시용

    // 이미지 처리 로직 유지
    List<String> images = [];
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      images = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      images.add(data['imageUrl']);
    }

    bool hasImage = images.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CommonCard(
          width: 900,
          height: 700,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // ✅ [고도화] 팝업창 제목 앞에도 자물쇠 아이콘 추가
                        if (isPrivate) const Icon(Icons.lock, color: Colors.grey, size: 20),
                        if (isPrivate) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['title'] ?? '(제목 없음)',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ],
              ),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 10),

              // 본문
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 텍스트 영역
                    Expanded(
                      flex: hasImage ? 6 : 10,
                      child: SingleChildScrollView(
                        child: Text(
                          data['content'] ?? '',
                          style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textMain),
                        ),
                      ),
                    ),

                    // 이미지 영역 (있을 경우)
                    if (hasImage) ...[
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Text("<첨부 사진 ${images.length}장>", style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1, // 크게 한 장씩 스크롤
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.2,
                                ),
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _showZoomableImage(context, images[index]),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppTheme.borderColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          images[index],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderColor),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${data['author']}  |  ${DateFormat('yyyy-MM-dd HH:mm').format(date)}",
                  style: const TextStyle(color: AppTheme.textSub, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ [유지] 이미지 확대 기능 유지
  void _showZoomableImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}