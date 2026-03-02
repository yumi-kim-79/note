// [파일 위치: lib/pages/sales/sales_list_page.dart]
// 메인페이지 / 노트관리
// 1. [UI 개선] 상세 팝업 하단 레이아웃을 반응형으로 변경 (모바일에서는 버튼을 다음 줄로 내림)
// 2. [버그 수정] 모바일에서 수정/삭제/공유 버튼이 화면 밖으로 밀리는 현상 해결
// 3. 기존 기능(공유, 복사, 인쇄, 나만 보기 필터 등) 100% 유지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; // 클립보드 복사 기능용
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/sales_service.dart';

// ✅ 디자인 시스템 import
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key});

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  final SalesService _salesService = SalesService();
  final TextEditingController _searchController = TextEditingController();

  String _searchText = "";
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ 노트 내용 포맷팅
  String _formatNoteText(Map<String, dynamic> data) {
    DateTime date = (data['createdAt'] as Timestamp).toDate();
    String dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);

    return """
[SM 업무 노트]
📄 제목: ${data['title'] ?? '(제목 없음)'}
👤 작성자: ${data['author'] ?? '미상'}
📅 작성일: $dateStr

[내용]
${data['content'] ?? ''}
""";
  }

  // ✅ 공유 기능
  void _shareNote(Map<String, dynamic> data, BuildContext context, RenderBox? box) {
    final text = _formatNoteText(data);
    Share.share(
      text,
      subject: data['title'] ?? '업무 노트 공유',
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    );
  }

  // ✅ 클립보드 복사 기능
  void _copyToClipboard(Map<String, dynamic> data) {
    final text = _formatNoteText(data);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("텍스트가 복사되었습니다. 원하시는 곳에 붙여넣으세요."),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // [기능 2] PDF 인쇄
  Future<void> _printNote(Map<String, dynamic> data) async {
    final doc = pw.Document();
    DateTime date = (data['createdAt'] as Timestamp).toDate();

    final font = await PdfGoogleFonts.nanumGothicRegular();
    final boldFont = await PdfGoogleFonts.nanumGothicBold();

    List<String> imageUrls = _getImagesFromData(data);

    List<pw.Widget> pdfImages = [];
    if (imageUrls.isNotEmpty) {
      for (String url in imageUrls) {
        try {
          final netImage = await networkImage(url);
          pdfImages.add(
              pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Image(netImage, fit: pw.BoxFit.contain, height: 300)
              )
          );
        } catch (e) {
          // 이미지 로드 실패 시 무시
        }
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return [
            pw.Header(
                level: 0,
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("업무 노트 상세", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(date), style: const pw.TextStyle(fontSize: 12)),
                    ]
                )
            ),
            pw.SizedBox(height: 20),
            pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfRow("제목", data['title'] ?? '(제목 없음)'),
                      _buildPdfRow("작성자", data['author'] ?? ''),
                      _buildPdfRow("작성일시", DateFormat('yyyy-MM-dd HH:mm').format(date)),
                    ]
                )
            ),
            pw.SizedBox(height: 20),
            pw.Text("■ 상세 내용", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Text(data['content'] ?? '', style: const pw.TextStyle(fontSize: 12, lineSpacing: 4)),
            ),
            pw.SizedBox(height: 20),
            if (pdfImages.isNotEmpty) ...[
              pw.Text("■ 첨부 이미지 (${pdfImages.length}장)", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              ...pdfImages
            ]
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 60, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedNotes() async {
    if (_selectedIds.isEmpty) return;
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("선택 삭제"),
        content: Text("선택한 ${_selectedIds.length}개를 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    if (confirm == true) {
      for (String id in _selectedIds) { await _salesService.deleteSalesNote(id); }
      setState(() => _selectedIds.clear());
    }
  }

  List<String> _getImagesFromData(Map<String, dynamic> data) {
    List<String> images = [];
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      images = List<String>.from(data['imageUrls']);
    }
    if (images.isEmpty && data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      images.add(data['imageUrl']);
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final String myName = userData?['name'] ?? '';
        final String myRole = userData?['role'] ?? 'user';
        final bool isAdmin = myRole == 'admin';

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 헤더 영역
              Container(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    const Icon(Icons.article_outlined, size: 28, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    const Text("노트관리", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    const Spacer(),
                    if (!isMobile)
                      SizedBox(
                        width: 320,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() { _searchText = value; _currentPage = 1; }),
                          decoration: InputDecoration(
                            hintText: "검색 (제목, 내용, 작성자)",
                            prefixIcon: const Icon(Icons.search, color: AppTheme.textSub),
                            suffixIcon: _searchText.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() { _searchText = ""; }); })
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 리스트 영역
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _salesService.getSalesNotesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    var allDocs = snapshot.hasData ? snapshot.data!.docs : [];

                    // ✅ [필터링 1] 나만 보기 처리
                    allDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      bool isPrivate = data['isPrivate'] ?? false;
                      String authorUid = data['uid'] ?? '';

                      if (!isPrivate) return true; // 전체 공개면 통과
                      return authorUid == user?.uid; // 비공개면 내 것만 통과
                    }).toList();

                    // ✅ [필터링 2] 검색어 처리
                    if (_searchText.isNotEmpty) {
                      allDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['title']?.toString().contains(_searchText) ?? false) ||
                            (data['content']?.toString().contains(_searchText) ?? false) ||
                            (data['author']?.toString().contains(_searchText) ?? false);
                      }).toList();
                    }

                    if (allDocs.isEmpty) return const Center(child: Text("데이터가 없습니다.", style: TextStyle(color: AppTheme.textSub)));

                    int totalItems = allDocs.length;
                    int totalPages = (totalItems / _itemsPerPage).ceil();
                    if (_currentPage > totalPages) _currentPage = 1;
                    int startIndex = (_currentPage - 1) * _itemsPerPage;
                    int endIndex = startIndex + _itemsPerPage;
                    if (endIndex > totalItems) endIndex = totalItems;
                    final currentDocs = allDocs.sublist(startIndex, endIndex);

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: currentDocs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = currentDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final DateTime date = (data['createdAt'] as Timestamp).toDate();
                              bool isAuthor = data['author']?.toString().startsWith(myName) ?? false;
                              bool canEdit = isAuthor || isAdmin;
                              bool isPrivate = data['isPrivate'] ?? false;

                              return CommonCard(
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  title: Row(
                                    children: [
                                      // ✅ 비공개 글은 자물쇠 아이콘 표시
                                      if (isPrivate)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 6.0),
                                          child: Icon(Icons.lock, size: 16, color: Colors.grey),
                                        ),
                                      Expanded(
                                        child: Text(
                                          data['title'] ?? '(제목 없음)',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                        "${DateFormat('yyyy-MM-dd HH:mm').format(date)}  |  ${data['author']}",
                                        style: const TextStyle(color: AppTheme.textSub, fontSize: 13)
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textSub),
                                  onTap: () => _showDetailPopup(context, doc.id, data, canEdit),
                                ),
                              );
                            },
                          ),
                        ),

                        // 페이지네이션
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null
                              ),
                              Text("$_currentPage / $totalPages", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                              IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null
                              ),
                            ],
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecureImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
            width: width,
            height: height,
            color: Colors.grey[100],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2))
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey),
                Text("로드 실패", style: TextStyle(fontSize: 10, color: Colors.grey))
              ],
            )
        );
      },
    );
  }

  void _showDetailPopup(BuildContext context, String docId, Map<String, dynamic> data, bool canEdit) {
    DateTime date = (data['createdAt'] as Timestamp).toDate();
    List<String> images = _getImagesFromData(data);

    // ✅ 모바일인지 체크 (폭 600 미만)
    bool isMobilePopup = MediaQuery.of(context).size.width < 600;
    bool isPrivate = data['isPrivate'] ?? false;

    // ✅ [하단 버튼 영역 위젯] 따로 정의 (모바일 대응용)
    Widget buildActionButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min, // ⭐️ 중요: Row 크기 최소화
        children: [
          Builder(
              builder: (btnContext) {
                return IconButton(
                  onPressed: () {
                    final RenderBox box = btnContext.findRenderObject() as RenderBox;
                    _shareNote(data, context, box);
                  },
                  icon: const Icon(Icons.share_outlined, color: Colors.black, size: 24),
                  tooltip: "공유",
                );
              }
          ),
          IconButton(
            onPressed: () => _copyToClipboard(data),
            icon: const Icon(Icons.copy, color: Colors.black, size: 24),
            tooltip: "내용 복사",
          ),
          IconButton(
            onPressed: () => _printNote(data),
            icon: const Icon(Icons.print_outlined, color: Colors.black, size: 24),
            tooltip: "인쇄",
          ),
          if (canEdit) ...[
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditDialog(context, docId, data);
              },
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor, size: 24),
              tooltip: "수정",
            ),
            IconButton(
              onPressed: () async {
                bool? confirm = await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("삭제"), content: const Text("정말 삭제하시겠습니까?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: AppTheme.errorColor)))]));
                if (confirm == true) { await _salesService.deleteSalesNote(docId); Navigator.pop(context); }
              },
              icon: const Icon(Icons.delete, color: AppTheme.errorColor, size: 24),
              tooltip: "삭제",
            ),
          ]
        ],
      );
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CommonCard(
          width: isMobilePopup ? double.maxFinite : 800,
          height: 700,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (제목 + 닫기)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (isPrivate) const Icon(Icons.lock, color: Colors.grey, size: 20),
                        if (isPrivate) const SizedBox(width: 8),
                        Expanded(child: Text(data['title'] ?? '(제목 없음)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context))
                ],
              ),
              const Divider(color: AppTheme.borderColor, thickness: 1),

              // 본문 내용
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(data['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                    ],
                  ),
                ),
              ),

              if (images.isNotEmpty) ...[
                const Divider(color: AppTheme.borderColor),
                Text("첨부 사진 (${images.length}장)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSub)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showZoomableImage(context, images[index]),
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildSecureImage(images[index], fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const Divider(color: AppTheme.borderColor),

              // ✅ [핵심 수정] 하단 영역 반응형 배치
              // 모바일: 위(정보) / 아래(버튼, 가로 스크롤 가능)
              // PC: 왼쪽(정보) / 오른쪽(버튼)
              if (isMobilePopup)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${data['author']}  |  ${DateFormat('yyyy-MM-dd HH:mm').format(date)}", style: const TextStyle(color: AppTheme.textSub, fontSize: 13)),
                    const SizedBox(height: 12),
                    // 버튼이 많으면 잘리지 않고 스크롤되도록 처리
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: buildActionButtons(),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${data['author']}  |  ${DateFormat('yyyy-MM-dd HH:mm').format(date)}", style: const TextStyle(color: AppTheme.textSub, fontSize: 13)),
                    buildActionButtons(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final titleCtrl = TextEditingController(text: data['title']);
    final contentCtrl = TextEditingController(text: data['content']);
    // 수정 시에도 공개/비공개 변경 가능하도록
    bool isPrivate = data['isPrivate'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("노트 수정"),
              content: SizedBox(
                width: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 공개 설정 스위치
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(isPrivate ? "🔒 나만 보기" : "📢 전체 공개", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Switch(
                          value: isPrivate,
                          activeColor: Colors.grey,
                          onChanged: (val) => setState(() => isPrivate = val),
                        ),
                      ],
                    ),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: "제목"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 10,
                      decoration: const InputDecoration(labelText: "내용"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
                ElevatedButton(
                  onPressed: () async {
                    await _salesService.updateSalesNote(
                        docId,
                        titleCtrl.text,
                        contentCtrl.text,
                        isPrivate: isPrivate
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('노트가 수정되었습니다.')));
                    }
                  },
                  child: const Text("수정 완료"),
                )
              ],
            );
          }
      ),
    );
  }

  void _showZoomableImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: _buildSecureImage(imageUrl, fit: BoxFit.contain))),
            Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
            Positioned(
              bottom: 40, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.download, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("사진을 길게 누르거나 우클릭하여 저장", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}