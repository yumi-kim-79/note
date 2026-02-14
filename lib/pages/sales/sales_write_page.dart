// [파일 위치: lib/pages/sales/sales_write_page.dart]
// 수정 내용:
// 1. [웹 호환성] Image.file() 대신 웹에서는 Image.network() 사용 (Blob URL)
// 2. [HEIC 대응] 웹에서 HEIC 선택 시 '엑박' 대신 '변환 대기 아이콘' 표시
// 3. [로직 연결] SalesService의 uploadImage에 파일 경로가 아닌 XFile 객체 전달
// 4. [기존 유지] 디자인, 버튼, 텍스트 필드 등 기존 기능 100% 동일

import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb 확인용
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // 이미지 압축
import 'package:flutter/services.dart'; // Clipboard

import '../../services/sales_service.dart';
import '../../widgets/common_widgets.dart';
import '../../theme/app_theme.dart';

class SalesWritePage extends StatefulWidget {
  final VoidCallback onSaved;
  const SalesWritePage({super.key, required this.onSaved});

  @override
  State<SalesWritePage> createState() => _SalesWritePageState();
}

class _SalesWritePageState extends State<SalesWritePage> {
  // 컨트롤러 및 서비스 초기화
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final SalesService _salesService = SalesService();

  // 사진 관리 리스트 (XFile 사용 - 웹/앱 공통)
  final List<XFile> _selectedFiles = [];

  // 상태 변수
  bool _isUploading = false;       // 업로드 중인지
  bool _isImageProcessing = false; // 이미지 가져오는 중인지
  bool _isPrivate = false;         // 나만 보기 여부

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------
            // 1. 헤더 (제목 + 공개 설정)
            // ---------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                    "📝 새 노트 작성",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)
                ),
                Row(
                  children: [
                    Text(
                      _isPrivate ? "🔒 나만 보기" : "📢 전체 공개",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isPrivate ? Colors.grey[700] : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isPrivate,
                      activeColor: Colors.grey,
                      activeTrackColor: Colors.grey[300],
                      inactiveThumbColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.3),
                      onChanged: (val) => setState(() => _isPrivate = val),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),

            // ---------------------------------------------------------
            // 2. 입력 필드 (제목 & 내용)
            // ---------------------------------------------------------
            const Text("제목", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: "제목 (입력하지 않으면 내용만 저장됩니다)",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            const Text("상세 내용", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: "영업 현장 상황, 고객 반응, 특이사항 등을 상세히 기록하세요.",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ---------------------------------------------------------
            // 3. 사진 첨부 섹션
            // ---------------------------------------------------------
            const Text("현장 사진 / 명함 첨부", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
            const SizedBox(height: 8),

            Column(
              children: [
                // (1) 선택된 사진 그리드
                if (_selectedFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 한 줄에 4개
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                // ✅ [핵심] 웹/앱, HEIC 여부에 따라 다르게 그리기
                                child: _buildImagePreview(file),
                              ),
                            ),
                            // 삭제 버튼
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedFiles.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                // (2) 사진 추가 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isImageProcessing ? null : _showPickImageOptions,
                    icon: _isImageProcessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add_a_photo, size: 18, color: AppTheme.primaryColor),
                    label: Text(
                      _isImageProcessing ? "처리 중..." : "사진 추가하기",
                      style: const TextStyle(color: AppTheme.textMain, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: AppTheme.backgroundColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ---------------------------------------------------------
            // 4. 저장 버튼
            // ---------------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 50,
              child: CommonButton(
                text: _isUploading ? "저장 중..." : "작성 완료 및 저장",
                icon: Icons.save,
                isLoading: _isUploading,
                onPressed: (_isUploading || _isImageProcessing) ? null : _saveNote,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // 🔍 [핵심] 미리보기 위젯 (웹 HEIC 대응)
  // ===============================================================
  Widget _buildImagePreview(XFile file) {
    // 확장자 체크 (대소문자 무시)
    String ext = file.name.split('.').last.toLowerCase();
    bool isHeic = ext == 'heic' || ext == 'heif';

    if (kIsWeb) {
      // 🌐 웹 환경
      if (isHeic) {
        // ⚠️ 브라우저는 HEIC를 렌더링 못함 -> 안내 아이콘 표시
        return Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.image_aspect_ratio, color: Colors.orange, size: 28),
              SizedBox(height: 4),
              Text("변환 대기", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        );
      } else {
        // JPG, PNG 등은 Blob URL로 즉시 표시
        return Image.network(
          file.path,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        );
      }
    } else {
      // 📱 앱 환경 (기존대로 파일 경로로 표시)
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }
  }

  // ===============================================================
  // [이미지 선택 로직]
  // ===============================================================
  void _showPickImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.textMain),
              title: const Text('카메라로 촬영', style: TextStyle(color: AppTheme.textMain)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.textMain),
              title: const Text('앨범에서 선택', style: TextStyle(color: AppTheme.textMain)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isImageProcessing = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        if (kIsWeb) {
          // 🌐 [Web] 원본 그대로 추가 (서버가 변환함)
          setState(() => _selectedFiles.add(image));
        } else {
          // 📱 [App] 압축 실행 후 추가 (데이터 절약)
          final compressed = await _compressForApp(image);
          if (compressed != null) {
            setState(() => _selectedFiles.add(compressed));
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사진을 불러오지 못했습니다.")));
    } finally {
      if (mounted) setState(() => _isImageProcessing = false);
    }
  }

  // [App Only] 이미지 압축 함수
  Future<XFile?> _compressForApp(XFile file) async {
    try {
      final String targetPath = '${file.path}_compressed.jpg';
      var result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 70,    // 품질 70%
        minWidth: 800,  // 가로 800px 리사이징
        minHeight: 800,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      print("압축 실패(그냥 원본 사용): $e");
      return file;
    }
  }

  // ===============================================================
  // [저장 로직]
  // ===============================================================
  Future<void> _saveNote() async {
    if (_contentCtrl.text.isEmpty && _titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목이나 내용을 입력해주세요.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> imageUrls = [];

      // 1. 이미지 순차 업로드
      // (SalesService의 uploadImage가 웹/앱 분기 처리를 해줍니다)
      for (XFile file in _selectedFiles) {
        String fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";

        // 🚨 중요: 여기서 file(XFile) 자체를 넘겨야 합니다. file.path를 넘기면 안 됨!
        String url = await _salesService.uploadImage(
            file,
            "sales_notes/${_salesService.auth.currentUser?.uid}/$fileName"
        );
        imageUrls.add(url);
      }

      // 2. Firestore 데이터 저장
      await _salesService.addSalesNote(
        title: _titleCtrl.text,
        content: _contentCtrl.text,
        visitType: "일반",
        imageUrl: imageUrls.isNotEmpty ? imageUrls.first : "",
        imageUrls: imageUrls,
        isPrivate: _isPrivate,
      );

      // 3. 성공 처리
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Text("저장 완료", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text("새노트가 성공적으로 저장되었습니다."),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // widget.onSaved(); // 필요하면 주석 해제 (목록 리로드 등)
                  },
                  child: const Text("확인", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor))
              )
            ],
          ),
        );

        // 4. 입력 필드 초기화
        _titleCtrl.clear();
        _contentCtrl.clear();
        setState(() {
          _selectedFiles.clear();
          _isPrivate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("저장 실패", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: Text("오류가 발생했습니다.\n\n$e"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인"))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}