// [파일 위치: lib/pages/dashboard/widgets/notice_board.dart]
// 수정 내용:
// 1. [웹 호환성] 사진 선택 시 즉시 미리보기 표시 (Image.network)
// 2. [UX 개선] 저장 시 화면 전체가 검게 변하지 않고, 다이얼로그 안에서 '업로드 중...' 표시
// 3. [최적화] SalesService 연동 (HEIC 대응 업로드)
// 4. [기존 유지] 페이징, 상세 보기, 수정/삭제 등 기존 기능 100% 동일

import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../services/sales_service.dart';

// ✅ 디자인 시스템 import
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

class NoticeBoard extends StatefulWidget {
  const NoticeBoard({super.key});

  @override
  State<NoticeBoard> createState() => _NoticeBoardState();
}

class _NoticeBoardState extends State<NoticeBoard> {
  final SalesService _salesService = SalesService();

  // [설정] 한 페이지에 5개씩 표시
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        bool isAdmin = false;
        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          isAdmin = (userData['role'] == 'admin');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [1] 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("📢 사내 공지사항", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                if (isAdmin)
                  IconButton(
                    onPressed: () => _showNoticeDialog(context),
                    icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                    tooltip: "공지사항 등록",
                  )
              ],
            ),
            const SizedBox(height: 12),

            // [2] 본문 (리스트)
            Expanded(
              child: CommonCard(
                padding: EdgeInsets.zero,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _salesService.getNoticesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final allDocs = snapshot.hasData ? snapshot.data!.docs : [];

                    if (allDocs.isEmpty) {
                      return const Center(child: Text("등록된 공지사항이 없습니다.", style: TextStyle(color: AppTheme.textSub)));
                    }

                    // 페이징 계산
                    int totalItems = allDocs.length;
                    int totalPages = (totalItems / _itemsPerPage).ceil();

                    if (_currentPage > totalPages) _currentPage = totalPages;
                    if (_currentPage < 1) _currentPage = 1;

                    int startIndex = (_currentPage - 1) * _itemsPerPage;
                    int endIndex = startIndex + _itemsPerPage;
                    if (endIndex > totalItems) endIndex = totalItems;

                    final currentDocs = allDocs.sublist(startIndex, endIndex);

                    return Column(
                      children: [
                        // 리스트 영역
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            itemCount: currentDocs.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderColor),
                            itemBuilder: (context, index) {
                              final doc = currentDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              DateTime date = (data['createdAt'] as Timestamp).toDate();
                              bool hasImage = (data['imageUrl'] != null && data['imageUrl'] != "");

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                leading: Icon(Icons.campaign, color: hasImage ? AppTheme.primaryColor : Colors.orange, size: 20),
                                title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(DateFormat('yyyy.MM.dd HH:mm').format(date), style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
                                trailing: hasImage ? const Icon(Icons.image, size: 16, color: AppTheme.textSub) : null,
                                onTap: () => _showDetailPopup(context, doc.id, data, isAdmin),
                              );
                            },
                          ),
                        ),

                        // 페이지 번호
                        if (totalPages > 1)
                          Container(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(icon: const Icon(Icons.chevron_left, size: 18, color: AppTheme.textSub), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
                                const SizedBox(width: 8),
                                ...List.generate(totalPages, (index) {
                                  int pageNum = index + 1;
                                  bool isCurrent = _currentPage == pageNum;
                                  return InkWell(
                                    onTap: () => setState(() => _currentPage = pageNum),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: isCurrent ? AppTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(4)),
                                      child: Text("$pageNum", style: TextStyle(color: isCurrent ? Colors.white : AppTheme.textMain, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 8),
                                IconButton(icon: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSub), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // [팝업 1] 공지사항 등록 (✅ 수정됨: 업로드 로딩 UI 개선)
  // ------------------------------------------------------------------
  void _showNoticeDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    XFile? _selectedFile;
    bool _isProcessing = false; // 이미지 가져오는 중
    bool _isUploading = false;  // 서버 업로드 중 (저장 버튼 클릭 시)

    showDialog(
      context: context,
      barrierDismissible: false, // 바깥 클릭 방지
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: CommonCard(
                width: 800,
                height: 520,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text("📢 공지사항 등록", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 왼쪽: 제목/내용 입력
                          Expanded(
                              flex: 6,
                              child: Column(
                                  children: [
                                    TextField(
                                        controller: titleCtrl,
                                        enabled: !_isUploading, // 업로드 중엔 수정 불가
                                        decoration: const InputDecoration(labelText: "제목")
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                        child: TextField(
                                            controller: contentCtrl,
                                            maxLines: null,
                                            expands: true,
                                            enabled: !_isUploading,
                                            textAlignVertical: TextAlignVertical.top,
                                            decoration: const InputDecoration(labelText: "내용", hintText: "공지할 내용을 입력하세요")
                                        )
                                    )
                                  ]
                              )
                          ),
                          const SizedBox(width: 24),

                          // 오른쪽: 사진 첨부 영역
                          Expanded(
                              flex: 4,
                              child: Column(
                                  children: [
                                    const Text("사진 첨부", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                                    const SizedBox(height: 10),

                                    // ✅ 미리보기 영역 (업로드 중이면 로딩 표시)
                                    Container(
                                      height: 180,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          border: Border.all(color: AppTheme.borderColor),
                                          borderRadius: BorderRadius.circular(8),
                                          color: AppTheme.backgroundColor
                                      ),
                                      child: _isUploading
                                          ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 12),
                                          Text("업로드 중...", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor))
                                        ],
                                      )
                                          : (_selectedFile == null
                                          ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.image_not_supported, size: 40, color: AppTheme.textSub),
                                          SizedBox(height: 8),
                                          Text("사진 없음", style: TextStyle(color: AppTheme.textSub, fontSize: 12))
                                        ],
                                      )
                                          : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _buildImagePreview(_selectedFile!),
                                      )),
                                    ),

                                    const SizedBox(height: 12),

                                    // ✅ 사진 가져오기 버튼
                                    SizedBox(
                                      width: double.infinity,
                                      height: 42,
                                      child: OutlinedButton.icon(
                                          onPressed: (_isProcessing || _isUploading) ? null : () async {
                                            setStateDialog(() => _isProcessing = true);
                                            final ImagePicker picker = ImagePicker();
                                            try {
                                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                                              if (image != null) {
                                                if (!kIsWeb) {
                                                  final compressed = await _compressForApp(image);
                                                  setStateDialog(() => _selectedFile = compressed ?? image);
                                                } else {
                                                  setStateDialog(() => _selectedFile = image);
                                                }
                                              }
                                            } finally {
                                              setStateDialog(() => _isProcessing = false);
                                            }
                                          },
                                          icon: _isProcessing
                                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Icon(Icons.camera_alt, size: 16),
                                          label: Text(
                                            _isProcessing ? "처리 중..." : "사진 선택하기",
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.primaryColor,
                                            side: const BorderSide(color: AppTheme.borderColor),
                                          )
                                      ),
                                    ),

                                    if (_selectedFile != null && !_isUploading)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: TextButton.icon(
                                          onPressed: () => setStateDialog(() => _selectedFile = null),
                                          icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                                          label: const Text("사진 삭제", style: TextStyle(color: Colors.red, fontSize: 12)),
                                          style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8)),
                                        ),
                                      )
                                  ]
                              )
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ✅ 하단 버튼 (취소 / 등록)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: _isUploading ? null : () => Navigator.pop(context),
                            child: const Text("취소", style: TextStyle(color: AppTheme.textSub))
                        ),
                        const SizedBox(width: 8),
                        CommonButton(
                          text: _isUploading ? "저장 중..." : "등록",
                          width: 100,
                          isLoading: _isUploading,
                          onPressed: _isUploading ? null : () async {
                            if (titleCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("제목을 입력해주세요.")));
                              return;
                            }

                            // 1. 업로드 상태 시작 (화면 갱신)
                            setStateDialog(() => _isUploading = true);

                            try {
                              String imageUrl = "";

                              if (_selectedFile != null) {
                                String fileName = "${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}";
                                String path = "notices/$fileName";
                                // 2. 이미지 업로드 (서버 변환 대기 포함)
                                imageUrl = await _salesService.uploadImage(_selectedFile!, path);
                              }

                              // 3. DB 저장
                              await _salesService.addNotice(title: titleCtrl.text, content: contentCtrl.text, imageUrl: imageUrl);

                              if (context.mounted) {
                                Navigator.pop(context); // 팝업 닫기
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("공지사항이 등록되었습니다.")));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
                                setStateDialog(() => _isUploading = false); // 실패 시 로딩 해제
                              }
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================================================================
  // ✅ [미리보기 함수] 웹/앱 모두 호환
  // ==================================================================
  Widget _buildImagePreview(XFile file) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    } else {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }
  }

  // ✅ [앱 전용 압축]
  Future<XFile?> _compressForApp(XFile file) async {
    try {
      final String targetPath = '${file.path}_compressed.jpg';
      var result = await FlutterImageCompress.compressAndGetFile(
        file.path, targetPath, quality: 70, minWidth: 800, minHeight: 800, format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      return file;
    }
  }

  // ------------------------------------------------------------------
  // [팝업 2] 상세 보기 (기존 유지)
  // ------------------------------------------------------------------
  void _showDetailPopup(BuildContext context, String docId, Map<String, dynamic> data, bool isAdmin) {
    DateTime date = (data['createdAt'] as Timestamp).toDate();
    String? imageUrl = data['imageUrl'];
    bool hasImage = (imageUrl != null && imageUrl.isNotEmpty);

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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(data['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain))), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
              const Divider(color: AppTheme.borderColor),
              Text("작성일: ${DateFormat('yyyy-MM-dd HH:mm').format(date)}", style: const TextStyle(color: AppTheme.textSub, fontSize: 13)),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: hasImage ? 5 : 10, child: SingleChildScrollView(child: Text(data['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textMain)))),
                    if (hasImage) ...[
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: Column(children: [const Text("<사진 클릭 시 확대>", style: TextStyle(fontSize: 12, color: AppTheme.primaryColor)), const SizedBox(height: 8), Expanded(child: GestureDetector(onTap: () => _showZoomableImage(context, imageUrl), child: Container(decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(8)), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.contain)))))]))
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isAdmin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CommonButton(text: "수정", icon: Icons.edit, width: 100, onPressed: () { Navigator.pop(context); _showEditDialog(context, docId, data); }),
                    const SizedBox(width: 12),
                    CommonButton(text: "삭제", icon: Icons.delete, width: 100, backgroundColor: AppTheme.errorColor, onPressed: () async { bool? confirm = await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("공지사항 삭제"), content: const Text("정말로 삭제하시겠습니까?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red)))])); if (confirm == true) { await _salesService.deleteNotice(docId); Navigator.pop(context); } }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // [팝업 3] 수정 다이얼로그 (기존 유지)
  // ------------------------------------------------------------------
  void _showEditDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final titleCtrl = TextEditingController(text: data['title']);
    final contentCtrl = TextEditingController(text: data['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("공지사항 수정", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 600, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "제목")), const SizedBox(height: 16), TextField(controller: contentCtrl, maxLines: 8, decoration: const InputDecoration(labelText: "내용"))])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: AppTheme.textSub))),
          ElevatedButton(onPressed: () async { await _salesService.updateNotice(docId, titleCtrl.text, contentCtrl.text); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공지사항이 수정되었습니다.'))); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white), child: const Text("수정 완료")),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // [팝업 4] 이미지 확대 보기 (기존 유지)
  // ------------------------------------------------------------------
  void _showZoomableImage(BuildContext context, String imageUrl) {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.black.withOpacity(0.9), insetPadding: EdgeInsets.zero, child: Stack(children: [Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: Image.network(imageUrl))), Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)))])));
  }
}