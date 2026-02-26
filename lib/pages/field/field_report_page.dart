// [파일 위치: lib/pages/field/field_report_page.dart]
// [페이지 기능: 현장 업무 결과 보고, 미완료 업무 관리, 팀 전체 조회, PDF/공유]
// 수정 내용:
// 1. [오류 수정] 누락된 함수(_copyReport 등) 복구 및 Async Context 경고 해결
// 2. [기능 추가] 전체 탭 조회 기간 기본값 '오늘'로 변경
// 3. [기능 추가] 완료 처리 시 시간(completedAt) 저장 및 카드 하단 표시
// 4. [기존 유지] 사진(HEIC), 자동완성, 잠금로직, 반응형(Full Width) 등 100% 유지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // min 함수
import 'dart:io'; // 파일 처리
import 'package:flutter/foundation.dart';// ✅ kIsWeb을 사용하기 위해 반드시 필요합니다.
import '../../services/notification_service.dart';
import '../../main.dart'; // 🌟 [고도화 추가] GlobalUserState(스마트 캐싱)를 가져옵니다.

// ✅ [추가] 아래 4줄을 import 목록에 추가하세요
import '../../services/sales_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';

// 이미지 피커
import 'package:image_picker/image_picker.dart';

// 프린트 패키지
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// 디자인 시스템
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class FieldReportPage extends StatefulWidget {
  const FieldReportPage({super.key});

  @override
  FieldReportPageState createState() => FieldReportPageState(); // ✅ _ 제거
}

class FieldReportPageState extends State<FieldReportPage> with SingleTickerProviderStateMixin {
  // ✅ [수정] 오늘 탭도 '기간' 조회를 위해 종료일 변수 추가 (기본값: 오늘 하루)
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _selectedEndDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SalesService _salesService = SalesService();

  // ✅ [고도화] 내 정보 저장 변수 (권한 및 실명제용)
  bool _isAdmin = false;       // 관리자 여부
  String _myName = "사용자";    // 내 이름 (예: 홍길동 대리)
  String _myUid = "";          // 내 UID

  // 탭 컨트롤러 (3개)
  late TabController _tabController;

  // 팀 전체 검색용 변수
  DateTime _searchStartDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _searchEndDate = DateTime.now();
  Key _streamKey = UniqueKey(); // ✅ 스트림 재생성용 키

  void refreshData() { // ✅ 외부(main)에서 호출할 함수
    if (!mounted) return;
    setState(() {
      _streamKey = UniqueKey();
      _fetchMyInfo(); // 내 정보도 최신화
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("데이터를 최신화했습니다."), duration: Duration(milliseconds: 800))
    );
  }

  String _searchKeyword = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 탭 설정
    _tabController = TabController(length: 3, vsync: this);

    // ✅ [고도화] 내 정보(권한, 이름) 가져오기 실행 (여기에 추가됨)
    _fetchMyInfo();

    // 팝업 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverduePopup();
    });
  }

  // ✅ [고도화] 내 정보 로드 함수 (스마트 캐싱 적용)
  Future<void> _fetchMyInfo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _myUid = user.uid;

    // 🌟 [핵심 고도화] 통신 불량 시 먹통이 되던 DB 조회(try-catch)를 싹 날려버립니다.
    // 폰 메모리에 있는 내 권한과 정확한 이름을 0초 만에 즉시 가져옵니다.
    if (mounted) {
      setState(() {
        _isAdmin = GlobalUserState.isAdmin;
        _myName = GlobalUserState.fullName;
        if (_myName.isEmpty) _myName = "직원";
      });
    }
  }

  // ====================================================
  // [기능 0] 미완료 일정 팝업
  // ====================================================
  Future<void> _checkOverduePopup() async {
    final user = _auth.currentUser;
    if (user == null) return;
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore.collection('schedules')
        .where('uid', isEqualTo: user.uid)
        .where('endDate', isLessThan: Timestamp.fromDate(todayStart))
        .get();

    int count = snapshot.docs.where((doc) {
      final data = doc.data();
      return (data['status'] != 'completed');
    }).length;

    if (count > 0 && mounted) {
      _showOverdueAlert(count);
    }
  }

  void _showOverdueAlert(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 28),
            SizedBox(width: 10),
            Text("미완료 일정 알림", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("미 완료 업무가 남아있습니다. 업무보고를 완료해 주세요!\n(미완료 건: $count건)"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  // ✅ [추가 1] 앱 전용 이미지 압축 (HEIC -> JPG 변환)
  Future<XFile?> _compressForApp(XFile file) async {
    try {
      final String targetPath = '${file.path}_compressed.jpg';
      var result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 70, minWidth: 800, minHeight: 800, format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) { return file; } // 실패 시 원본 반환
  }

  // ✅ [추가 1] 이미지 미리보기 위젯 (HEIC 및 웹/앱 대응)
  Widget _buildImagePreview(XFile file) {
    String ext = file.name.split('.').last.toLowerCase();
    bool isHeic = ext == 'heic' || ext == 'heif';

    if (kIsWeb) {
      if (isHeic) {
        return Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.image_aspect_ratio, color: Colors.orange, size: 24),
              Text("HEIC 변환대기", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        );
      }
      return Image.network(file.path, fit: BoxFit.cover, width: 80, height: 80);
    } else {
      return Image.file(File(file.path), fit: BoxFit.cover, width: 80, height: 80);
    }
  }

  // ✅ [추가 2] 사진 다운로드 안내 (웹 문법 오류 해결 버전)
  void _downloadImageWeb(String url) {
    // 웹에서는 보안상 직접 다운로드가 까다로우므로 안내 메시지로 대체하여 에러를 방지합니다.
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미지를 길게 누르거나 우클릭하여 '이미지 저장'을 해주세요."))
    );
  }
  // ✅ [추가] 사진 확대 미리보기 (PC/모바일 공통)
  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black, // 배경을 검게 해서 사진에 집중
        insetPadding: EdgeInsets.zero, // 화면 꽉 차게
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. 사진 (손가락으로 확대/축소 가능)
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),
            // 2. 닫기 버튼 (우측 상단)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                tooltip: "닫기",
              ),
            ),
            // 3. 다운로드 버튼 (우측 하단)
            Positioned(
              bottom: 40,
              right: 20,
              child: IconButton(
                onPressed: () => _downloadImageWeb(url), // 기존 다운로드 기능 연결
                icon: const Icon(Icons.download, color: Colors.white, size: 30),
                tooltip: "다운로드",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // [스트림] 오늘(나의 기간) / 미완료 데이터 가져오기
  // ====================================================
  Stream<Map<String, List<Map<String, dynamic>>>> _getSplitReportStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({'today': [], 'overdue': []});

    return _firestore
        .collection('schedules')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> todayList = [];
      List<Map<String, dynamic>> overdueList = [];

      DateTime now = DateTime.now();
      DateTime todayBase = DateTime(now.year, now.month, now.day);

      // ✅ [수정] 오늘 탭의 조회 기간 (Start ~ End)
      DateTime rangeStart = _selectedDate; // 00:00:00
      DateTime rangeEnd = DateTime(_selectedEndDate.year, _selectedEndDate.month, _selectedEndDate.day, 23, 59, 59);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['docId'] = doc.id;

        DateTime start = (data['startDate'] as Timestamp?)?.toDate() ?? (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        DateTime end = (data['endDate'] as Timestamp?)?.toDate() ?? start;

        DateTime dayStart = DateTime(start.year, start.month, start.day);
        DateTime dayEnd = DateTime(end.year, end.month, end.day); // 시간 제거

        // 1. 미완료 탭 로직 (기존 유지): 오늘 기준으로 과거이면서 안 끝난 것
        if (dayEnd.isBefore(todayBase) && data['status'] != 'completed') {
          overdueList.add(data);
        }

        // 2. 오늘(나의 기간) 탭 로직 (기간 교차 검사)
        // (일정 시작일 <= 조회 종료일) AND (일정 종료일 >= 조회 시작일)
        if (dayStart.isBefore(rangeEnd) && dayEnd.isAfter(rangeStart.subtract(const Duration(seconds: 1)))) {
          todayList.add(data);
        } else if (DateUtils.isSameDay(dayStart, rangeStart) || DateUtils.isSameDay(dayEnd, rangeEnd)) {
          // 경계값 안전 장치
          todayList.add(data);
        }
      }

      // 정렬 (방문순서 -> 시간순)
      void sortList(List<Map<String, dynamic>> list) {
        list.sort((a, b) {
          int orderA = a['visitOrder'] ?? 999;
          int orderB = b['visitOrder'] ?? 999;
          if (orderA != orderB) return orderA.compareTo(orderB);
          Timestamp timeA = a['startTime'] ?? Timestamp.now();
          Timestamp timeB = b['startTime'] ?? Timestamp.now();
          return timeA.compareTo(timeB);
        });
      }
      sortList(todayList);
      sortList(overdueList);
      return {'today': todayList, 'overdue': overdueList};
    });
  }

  // ====================================================
  // [기능 1] 완료 처리 (실명제 적용)
  // ====================================================
  Future<void> _toggleComplete(Map<String, dynamic> data) async {
    String docId = data['docId'];
    String currentStatus = data['status'] ?? 'pending';
    bool isNowComplete = currentStatus == 'completed';
    String reportContent = data['reportContent'] ?? '';

    if (!isNowComplete && reportContent.trim().isEmpty) {
      // (내용 없음 경고 팝업 - 기존 코드 유지)
      showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("업무 보고 필수", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("업무 결과나 특이사항을 작성해야 완료 처리할 수 있습니다."),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인", style: TextStyle(fontWeight: FontWeight.bold)))]
      ));
      return;
    }

    // (조기 완료 경고 - 기존 코드 유지)
    if (!isNowComplete) {
      DateTime end = (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      DateTime todayBase = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime endDateBase = DateTime(end.year, end.month, end.day);
      if (endDateBase.isAfter(todayBase)) {
        bool? confirm = await showDialog(context: context, builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("일정 조기 완료"),
            content: const Text("기간이 남았습니다. 지금 완료하시겠습니까?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("아니오")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("예(완료)", style: TextStyle(color: AppTheme.primaryColor)))
            ]
        ));
        if (confirm != true) return;
      }
    }

    // ✅ [고도화] 완료자 실명(completerName) 저장 및 삭제
    await _firestore.collection('schedules').doc(docId).update({
      'status': isNowComplete ? 'pending' : 'completed',
      'completedAt': isNowComplete ? FieldValue.delete() : FieldValue.serverTimestamp(),
      'completerName': isNowComplete ? FieldValue.delete() : _myName, // 완료한 사람 이름 저장
    });
    // -------------------------------------------------------------
    // ✅ [추가] 완료/취소 알림 발송
    // -------------------------------------------------------------
    String ownerUid = data['uid'] ?? '';
    if (ownerUid.isNotEmpty && ownerUid != _myUid) {
      DocumentSnapshot ownerDoc = await _firestore.collection('users').doc(ownerUid).get();
      if (ownerDoc.exists) {
        String? token = (ownerDoc.data() as Map<String, dynamic>)['fcmToken'];
        if (token != null) {
          await NotificationService().sendNotification(
            targetToken: token,
            targetUid: ownerUid,
            title: "업무 상태 변경",
            body: "$_myName 님이 '${data['title']}' 업무를 ${isNowComplete ? '완료 취소' : '처리 완료'}했습니다.",
            type: 'report',
          );
        }
      }
    }
  }

  // ====================================================
  // [기능 2] 보고/수정 다이얼로그 (기존 사진 삭제/수정 기능 추가)
  // ====================================================
  void _showEditReportDialog(Map<String, dynamic> data) {
    String initialText = data['reportContent'] ?? '';
    if (initialText.isEmpty) initialText = "특이사항 없음";

    final TextEditingController noteCtrl = TextEditingController(text: initialText);
    DateTime startDate = (data['startDate'] as Timestamp?)?.toDate() ?? (data['date'] as Timestamp).toDate();
    DateTime endDate = (data['endDate'] as Timestamp?)?.toDate() ?? startDate;
    DateTime newEndDate = endDate;

    // ✅ [추가] 기존에 저장된 이미지 URL 리스트 가져오기
    List<String> existingImages = List<String>.from(data['imageUrls'] ?? []);

    // 새로 추가할 사진 리스트
    List<XFile> newImages = [];
    final ImagePicker picker = ImagePicker();

    bool isDialogUploading = false;
    bool isDialogImageProcessing = false;

    String title = data['title'] ?? '';
    if (title.isEmpty) title = "(추가 방문지)";

    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth > 600 ? 550 : screenWidth * 0.95;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            // 이미지 선택 헬퍼
            Future<void> pickAndProcessImage(ImageSource source) async {
              setStateDialog(() => isDialogImageProcessing = true);
              try {
                List<XFile> pickedFiles = [];
                if (source == ImageSource.camera) {
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) pickedFiles.add(image);
                } else {
                  final List<XFile> images = await picker.pickMultiImage();
                  pickedFiles.addAll(images);
                }

                for (var img in pickedFiles) {
                  XFile? processed = kIsWeb ? img : await _compressForApp(img);
                  if (processed != null) {
                    setStateDialog(() => newImages.add(processed));
                  }
                }
              } catch (e) {
                print("이미지 선택 오류: $e");
              } finally {
                setStateDialog(() => isDialogImageProcessing = false);
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: CommonCard(
                width: dialogWidth,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("업무 결과 보고 ($title)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                      const SizedBox(height: 20),

                      TextField(
                        controller: noteCtrl,
                        maxLines: 4,
                        enabled: !isDialogUploading,
                        decoration: const InputDecoration(
                          labelText: "업무 보고 / 특이사항",
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          filled: true, fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 사진 첨부 버튼
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: (isDialogUploading || isDialogImageProcessing) ? null : () => pickAndProcessImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text("촬영"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: (isDialogUploading || isDialogImageProcessing) ? null : () => pickAndProcessImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text("앨범"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                          ),
                        ],
                      ),

                      // ✅ [사진 통합 리스트] (기존 사진 + 새 사진)
                      if (existingImages.isNotEmpty || newImages.isNotEmpty)
                        Container(
                          height: 80,
                          margin: const EdgeInsets.only(top: 10),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: existingImages.length + newImages.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              // 인덱스 분기 처리
                              bool isExisting = index < existingImages.length;

                              // 보여줄 위젯 결정
                              Widget imageWidget;
                              if (isExisting) {
                                // 1. 기존 서버 이미지
                                imageWidget = Image.network(existingImages[index], fit: BoxFit.cover, width: 80, height: 80);
                              } else {
                                // 2. 새로 추가한 로컬 이미지
                                int newIndex = index - existingImages.length;
                                imageWidget = _buildImagePreview(newImages[newIndex]);
                              }

                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: imageWidget,
                                  ),
                                  // 삭제 버튼 (공통)
                                  Positioned(
                                    right: 0, top: 0,
                                    child: GestureDetector(
                                      onTap: isDialogUploading ? null : () {
                                        setStateDialog(() {
                                          if (isExisting) {
                                            // 기존 목록에서 삭제
                                            existingImages.removeAt(index);
                                          } else {
                                            // 새 목록에서 삭제
                                            newImages.removeAt(index - existingImages.length);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  // 기존 사진 표시 (구분용, 선택사항)
                                  if (isExisting)
                                    Positioned(
                                      left: 0, bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.only(topRight: Radius.circular(4))),
                                        child: const Text("기존", style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ),
                                    )
                                ],
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 기간 설정
                      const Align(alignment: Alignment.centerLeft, child: Text("📅 일정 기간 설정 (미완료 시 연장)", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${DateFormat('MM.dd').format(startDate)} ~ ${DateFormat('MM.dd').format(newEndDate)}", style: const TextStyle(fontSize: 16)),
                            TextButton(
                              onPressed: isDialogUploading ? null : () async {
                                final picked = await showDatePicker(
                                  context: context, initialDate: newEndDate, firstDate: startDate, lastDate: DateTime(2030),
                                );
                                if (picked != null) setStateDialog(() => newEndDate = picked);
                              },
                              child: const Text("종료일 변경"),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 저장 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: isDialogUploading ? null : () => Navigator.pop(context),
                              child: const Text("취소", style: TextStyle(color: Colors.grey))
                          ),
                          const SizedBox(width: 8),
                          CommonButton(
                            text: isDialogUploading ? "저장 중..." : "저장하기",
                            isLoading: isDialogUploading,
                            width: 120,
                            onPressed: (isDialogUploading || isDialogImageProcessing) ? null : () async {
                              setStateDialog(() => isDialogUploading = true);

                              try {
                                // 1. 새 이미지만 업로드
                                List<String> newUploadedUrls = [];
                                for (var img in newImages) {
                                  String fileName = "${DateTime.now().millisecondsSinceEpoch}_${img.name}";
                                  String url = await _salesService.uploadImage(img, "reports/$_myUid/$fileName");
                                  newUploadedUrls.add(url);
                                }

                                // 2. 최종 이미지 리스트 합치기 (남은 기존 사진 + 새로 올린 사진)
                                List<String> finalImageUrls = [...existingImages, ...newUploadedUrls];

                                // 3. Firestore 업데이트 (덮어쓰기)
                                // 주의: 삭제된 기존 사진은 리스트에서 빠졌으므로, 여기서 덮어쓰면 DB에서도 사라진 효과가 납니다.
                                await _firestore.collection('schedules').doc(data['docId']).update({
                                  'reportContent': noteCtrl.text,
                                  'endDate': Timestamp.fromDate(newEndDate),
                                  'isContinuous': !DateUtils.isSameDay(startDate, newEndDate),
                                  'lastModifierName': _myName,
                                  'lastModifiedAt': FieldValue.serverTimestamp(),
                                  'imageUrls': finalImageUrls, // ✅ 최종 리스트로 교체
                                });
                                // -------------------------------------------------------------
                                // ✅ [추가] 보고서 수정 알림 발송
                                // -------------------------------------------------------------
                                String ownerUid = data['uid'] ?? '';
                                if (ownerUid.isNotEmpty && ownerUid != _myUid) {
                                  DocumentSnapshot ownerDoc = await _firestore.collection('users').doc(ownerUid).get();
                                  if (ownerDoc.exists) {
                                    String? token = (ownerDoc.data() as Map<String, dynamic>)['fcmToken'];
                                    if (token != null) {
                                      await NotificationService().sendNotification(
                                        targetToken: token,
                                        targetUid: ownerUid,
                                        title: "업무 보고 수정",
                                        body: "$_myName 님이 '${data['title']}' 보고 내용을 수정했습니다.",
                                        type: 'report',
                                      );
                                    }
                                  }
                                }

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("업무 내용이 수정되었습니다.")));
                              } catch (e) {
                                print("저장 실패: $e");
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
                              } finally {
                                if (context.mounted) setStateDialog(() => isDialogUploading = false);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ====================================================
  // [기능 3] 읽기 전용 상세 팝업 (반응형)
  // ====================================================
  void _showReadOnlyDetail(Map<String, dynamic> data) {
    DateTime start = (data['startTime'] as Timestamp).toDate();
    DateTime end = (data['endTime'] as Timestamp).toDate();
    String buildingName = data['buildingName'] ?? '장소 미정';
    String buildingAddress = data['buildingAddress'] ?? '';
    String content = data['content'] ?? '';
    List logs = data['workLogs'] ?? [];

    String title = data['title'] ?? '';
    if (title.isEmpty) title = "(추가 방문지)";

    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth > 600 ? 550 : screenWidth * 0.95;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: CommonCard(
          width: dialogWidth,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("일정 상세 정보", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ]),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadOnlyRow("제목", title),
                      _buildReadOnlyRow("일시", "${DateFormat('yyyy-MM-dd').format(start)}  ${DateFormat('HH:mm').format(start)} ~ ${DateFormat('HH:mm').format(end)}"),
                      _buildReadOnlyRow("장소", "$buildingName\n$buildingAddress"),
                      if (logs.isNotEmpty) ...[
                        const Text("업무내용 및 히스토리", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub)),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 4, bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey[300]!)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: logs.map<Widget>((log) {
                              String authorName = log['author'] ?? '알수없음';
                              String dateStr = "";
                              if (log['createdAt'] != null && log['createdAt'] is Timestamp) {
                                DateTime dt = (log['createdAt'] as Timestamp).toDate();
                                dateStr = DateFormat('yyyy.MM.dd HH:mm').format(dt);
                              }

                              // ✅ 타인(지시자) 작성 여부 판별
                              String ownerUid = data['uid'] ?? '';
                              String ownerName = data['author'] ?? '';
                              String logUid = log['uid'] ?? '';
                              bool isOther = (logUid.isNotEmpty && ownerUid.isNotEmpty) ? (logUid != ownerUid) : (authorName != ownerName);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 13, height: 1.3),
                                        children: [
                                          TextSpan(text: "• ", style: TextStyle(color: isOther ? Colors.red : AppTheme.textMain)),
                                          TextSpan(
                                            text: "[$authorName] ",
                                            style: TextStyle(
                                              color: isOther ? Colors.blue : AppTheme.textMain, // ✅ 이름은 파란색
                                              fontWeight: isOther ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "${log['text'] ?? ''}",
                                            style: TextStyle(
                                              color: isOther ? Colors.red : AppTheme.textMain, // ✅ 내용은 빨간색
                                              fontWeight: isOther ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (dateStr.isNotEmpty)
                                      Padding(
                                          padding: const EdgeInsets.only(left: 10.0, top: 2.0),
                                          child: Text(dateStr, style: TextStyle(fontSize: 11, color: isOther ? Colors.redAccent : Colors.grey))
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      if (data['reportContent'] != null && data['reportContent'].isNotEmpty) ...[
                        const Text("결과 보고 사항", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                          child: Text(data['reportContent'], style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                      // ✅ [추가] 업로드된 사진 목록 표시 및 다운로드 기능
                      if (data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text("첨부 사진 (클릭 시 다운로드/복사)", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: (data['imageUrls'] as List).length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              String url = data['imageUrls'][index];
                              return GestureDetector(
                                // ✅ 수정: 클릭 시 확대 미리보기 창을 띄웁니다.
                                onTap: () => _showImagePreview(context, url),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(width: 120, color: Colors.grey[200], child: const Icon(Icons.broken_image))),
                                    ),
                                    // 돋보기 아이콘으로 변경 (미리보기라는 힌트)
                                    Positioned(
                                      right: 4, bottom: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      if (data['status'] == 'completed' && data['completedAt'] != null) ...[
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.5))
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 18, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                "최종 처리 완료: ${DateFormat('yyyy년 MM월 dd일 HH:mm').format((data['completedAt'] as Timestamp).toDate())}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub))),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textMain))),
        ],
      ),
    );
  }

  // ====================================================
  // [기능 4] 프린트 / 공유 / 복사 (데이터 로드 로직 수정 - 최종 버그 픽스)
  // ====================================================

  Future<List<Map<String, dynamic>>> _fetchActiveTabData() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    int currentIndex = _tabController.index;
    List<Map<String, dynamic>> filteredList = [];
    QuerySnapshot? snapshot;

    // 1. 탭에 따른 쿼리 분기
    if (currentIndex == 2) {
      // [팀 전체 탭] 화면과 동일하게 1년치(넓은 범위)를 가져와서 내부에서 거릅니다.
      snapshot = await _firestore.collection('schedules')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 365))))
          .get();
    } else {
      // [오늘/미완료 탭] '나(UID)'의 데이터만 조회
      snapshot = await _firestore.collection('schedules')
          .where('uid', isEqualTo: user.uid)
          .get();
    }

    if (snapshot == null || snapshot.docs.isEmpty) return [];

    // 2. 데이터 필터링 (화면 로직과 100% 일치시킴)
    DateTime todayBase = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // ✅ [핵심 수정 1] 탭에 따라 기준 날짜를 다르게 설정
    DateTime targetStart;
    DateTime targetEnd;

    if (currentIndex == 2) {
      // 팀 탭이면 팀 탭 전용 날짜 변수 사용
      targetStart = DateTime(_searchStartDate.year, _searchStartDate.month, _searchStartDate.day);
      targetEnd = DateTime(_searchEndDate.year, _searchEndDate.month, _searchEndDate.day, 23, 59, 59);
    } else {
      // 오늘 탭이면 오늘 탭 전용 날짜 변수 사용
      targetStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      targetEnd = DateTime(_selectedEndDate.year, _selectedEndDate.month, _selectedEndDate.day, 23, 59, 59);
    }

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // [팀 탭 검색어 필터]
      if (currentIndex == 2 && _searchKeyword.isNotEmpty) {
        String bName = (data['buildingName'] ?? '').toString().toLowerCase();
        String author = (data['author'] ?? '').toString().toLowerCase();
        String key = _searchKeyword.toLowerCase();
        if (!bName.contains(key) && !author.contains(key)) continue;
      }

      DateTime start = (data['startDate'] as Timestamp?)?.toDate() ?? (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      DateTime end = (data['endDate'] as Timestamp?)?.toDate() ?? start;

      DateTime dayStart = DateTime(start.year, start.month, start.day);
      DateTime dayEnd = DateTime(end.year, end.month, end.day);

      bool include = false;

      if (currentIndex == 0) {
        // [오늘 탭] 기간 내 포함 여부
        if (dayStart.isBefore(targetEnd) && dayEnd.isAfter(targetStart.subtract(const Duration(seconds: 1)))) {
          include = true;
        } else if (DateUtils.isSameDay(dayStart, targetStart) || DateUtils.isSameDay(dayEnd, targetEnd)) {
          include = true;
        }
      } else if (currentIndex == 1) {
        // [미완료 탭] 과거 & 미완료
        if (dayEnd.isBefore(todayBase) && data['status'] != 'completed') {
          include = true;
        }
      } else if (currentIndex == 2) {
        // [팀 전체 탭]
        // 조건 A: 선택된 기간에 포함되는지 (정상 일정)
        bool isInRange = (dayStart.compareTo(targetEnd) <= 0) && (dayEnd.compareTo(targetStart) >= 0);

        // ✅ [핵심 수정 2] 조건 B: 미완료 추적 (화면에는 보였지만 프린트엔 빠졌던 녀석들)
        // 완료되지 않았고(completed 아님), 종료일이 검색일보다 과거인 경우
        bool isOverdueTracking = (data['status'] != 'completed') && dayEnd.isBefore(targetStart);

        if (isInRange || isOverdueTracking) {
          include = true;
        }
      }

      if (include) {
        filteredList.add(data);
      }
    }

    // 3. 시간순 정렬
    filteredList.sort((a, b) {
      Timestamp timeA = a['startTime'] ?? Timestamp.now();
      Timestamp timeB = b['startTime'] ?? Timestamp.now();
      return timeB.compareTo(timeA); // 최신순
    });

    return filteredList;
  }

  // ✅ [복사] 팀 탭은 담당자별 그룹화
  Future<void> _copyReport() async {
    final reportData = await _fetchActiveTabData();
    if (reportData.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("복사할 내용이 없습니다.")));
      return;
    }

    StringBuffer sb = StringBuffer();
    bool isTeamTab = _tabController.index == 2;
    String tabName = _tabController.index == 0 ? "오늘 업무" : (_tabController.index == 1 ? "미완료 업무" : "팀 전체 업무");

    sb.writeln("[SM $tabName 보고서]");
    sb.writeln("출력일시: ${DateFormat('yyyy.MM.dd HH:mm').format(DateTime.now())}");
    sb.writeln("=================================");

    if (isTeamTab) {
      // 담당자별 그룹화 로직
      Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var item in reportData) {
        String author = item['author'] ?? '담당자 미정';
        if (grouped[author] == null) grouped[author] = [];
        grouped[author]!.add(item);
      }
      var sortedAuthors = grouped.keys.toList()..sort(); // 가나다순

      for (var author in sortedAuthors) {
        sb.writeln("\n👤 담당자: $author (${grouped[author]!.length}건)");
        sb.writeln("---------------------------------");
        for (var item in grouped[author]!) {
          _buildTextForExport(sb, item);
          sb.writeln("---------------------------------");
        }
      }
    } else {
      // 일반 출력
      for (var item in reportData) {
        _buildTextForExport(sb, item);
        sb.writeln("=================================");
      }
    }

    await Clipboard.setData(ClipboardData(text: sb.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("상세 내용이 클립보드에 복사되었습니다.")));
  }

  // ✅ [공유] 팀 탭은 담당자별 그룹화
  Future<void> _shareReport() async {
    final reportData = await _fetchActiveTabData();
    if (reportData.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("공유할 내용이 없습니다.")));
      return;
    }

    StringBuffer sb = StringBuffer();
    bool isTeamTab = _tabController.index == 2;
    String tabName = _tabController.index == 0 ? "오늘 업무" : (_tabController.index == 1 ? "미완료 업무" : "팀 전체 업무");

    sb.writeln("[SM $tabName 보고서 공유]");
    sb.writeln("=================================");

    if (isTeamTab) {
      Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var item in reportData) {
        String author = item['author'] ?? '담당자 미정';
        if (grouped[author] == null) grouped[author] = [];
        grouped[author]!.add(item);
      }
      var sortedAuthors = grouped.keys.toList()..sort();

      for (var author in sortedAuthors) {
        sb.writeln("\n👤 $author");
        sb.writeln("---------------------------------");
        for (var item in grouped[author]!) {
          _buildTextForExport(sb, item);
          sb.writeln("---------------------------------");
        }
      }
    } else {
      for (var item in reportData) {
        _buildTextForExport(sb, item);
        sb.writeln("=================================");
      }
    }

    Share.share(sb.toString());
  }

  // 📝 [공통 텍스트 포맷] 상태값 3단 분리 (완료/미완료/완료전)
  void _buildTextForExport(StringBuffer sb, Map<String, dynamic> item) {
    DateTime start = (item['startTime'] as Timestamp).toDate();
    DateTime end = (item['endTime'] as Timestamp).toDate();

    // ✅ [수정] 상태값 텍스트 정밀화
    String status;
    if (item['status'] == 'completed') {
      status = "[완료]";
    } else {
      // 오늘 날짜 기준
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime endDay = DateTime(end.year, end.month, end.day);

      bool isOverdue = endDay.isBefore(today); // 날짜 지남
      bool isExtended = !DateUtils.isSameDay(start, end); // 기간 업무
      bool isExtending = isExtended && endDay.isAfter(today); // 기간 중

      if (isOverdue || isExtending) {
        status = "[미완료]"; // 지났거나 기간 업무면 미완료
      } else {
        status = "[완료전]"; // 그 외(오늘/미래)는 완료전
      }
    }

    sb.writeln("$status ${item['title'] ?? '(제목 없음)'}");
    sb.writeln("• 일시: ${DateFormat('MM.dd HH:mm').format(start)} ~ ${DateFormat('HH:mm').format(end)}");
    sb.writeln("• 장소: ${item['buildingName'] ?? '-'}");
    // 팀 탭이 아닐 때만 작성자 표시
    if (_tabController.index != 2) sb.writeln("• 작성자: ${item['author'] ?? '담당자'}");

    List logs = item['workLogs'] ?? [];
    if (logs.isNotEmpty) {
      sb.writeln("\n[업무내용 및 히스토리]");

      String ownerUid = item['uid'] ?? '';
      String ownerName = item['author'] ?? '';

      for (var log in logs) {
        String author = log['author'] ?? '알수없음';
        String text = log['text'] ?? '';
        String logTime = "";

        String logUid = log['uid'] ?? '';
        bool isOther = (logUid.isNotEmpty && ownerUid.isNotEmpty) ? (logUid != ownerUid) : (author != ownerName);

        if (log['createdAt'] != null && log['createdAt'] is Timestamp) {
          logTime = DateFormat('yyyy.MM.dd HH:mm').format((log['createdAt'] as Timestamp).toDate());
        }

        // ✅ 타인(지시자) 피드백은 텍스트(카톡/복사) 공유 시 파란점 기호 추가
        if (isOther) {
          sb.writeln("🔵 [$author] $text ($logTime)");
        } else {
          sb.writeln("- [$author] $text ($logTime)");
        }
      }
    }

    if (item['reportContent'] != null && item['reportContent'].toString().isNotEmpty) {
      sb.writeln("\n[결과 보고]\n${item['reportContent']}");
    }

    if (item['status'] == 'completed' && item['completedAt'] != null) {
      String completeTime = DateFormat('yyyy.MM.dd HH:mm').format((item['completedAt'] as Timestamp).toDate());

      // 완료자 실명 표시
      String completerInfo = completeTime;
      if(item['completerName'] != null) {
        completerInfo += " (${item['completerName']})";
      }
      sb.writeln("\n✅ 최종 처리 완료: $completerInfo");
    }
  }

  // ✅ [프린트] 팀 탭은 담당자별 그룹화 PDF
  Future<void> _printReport() async {
    final reportData = await _fetchActiveTabData();
    if (reportData.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("출력할 내용이 없습니다.")));
      return;
    }

    final doc = pw.Document();
    final font = await PdfGoogleFonts.nanumGothicRegular();
    final fontBold = await PdfGoogleFonts.nanumGothicBold();
    bool isTeamTab = _tabController.index == 2;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) {
          List<pw.Widget> widgets = [
            pw.Header(
                level: 0,
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(isTeamTab ? "팀 전체 업무 보고서" : "업무 결과 보고서", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text("출력일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Divider(thickness: 2),
                    ]
                )
            ),
            pw.SizedBox(height: 10),
          ];

          if (isTeamTab) {
            // [팀 탭] 담당자별 그룹화 출력
            Map<String, List<Map<String, dynamic>>> grouped = {};
            for (var item in reportData) {
              String author = item['author'] ?? '담당자 미정';
              if (grouped[author] == null) grouped[author] = [];
              grouped[author]!.add(item);
            }
            var sortedAuthors = grouped.keys.toList()..sort();

            for (var author in sortedAuthors) {
              // 담당자 헤더
              widgets.add(
                  pw.Container(
                      margin: const pw.EdgeInsets.only(top: 10, bottom: 5),
                      padding: const pw.EdgeInsets.all(5),
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      child: pw.Row(
                          children: [
                            pw.Text("👤 $author", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(width: 5),
                            pw.Text("(${grouped[author]!.length}건)", style: const pw.TextStyle(fontSize: 12)),
                          ]
                      )
                  )
              );
              // 해당 담당자의 업무 리스트
              widgets.addAll(grouped[author]!.map((item) => _buildPdfItem(item)).toList());
            }
          } else {
            // [기존] 단순 나열
            widgets.addAll(reportData.map((item) => _buildPdfItem(item)).toList());
          }

          return widgets;
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  // PDF 아이템 생성 헬퍼
  pw.Widget _buildPdfItem(Map<String, dynamic> item) {
    DateTime start = (item['startTime'] as Timestamp).toDate();
    DateTime end = (item['endTime'] as Timestamp).toDate();
    List logs = item['workLogs'] ?? [];

    // ✅ [수정] 상태값 텍스트 정밀화 (PDF용)
    String statusText;
    if (item['status'] == 'completed') {
      statusText = "[완료]";
    } else {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime endDay = DateTime(end.year, end.month, end.day);

      bool isOverdue = endDay.isBefore(today);
      bool isExtended = !DateUtils.isSameDay(start, end);
      bool isExtending = isExtended && endDay.isAfter(today);

      if (isOverdue || isExtending) {
        statusText = "[미완료]";
      } else {
        statusText = "[완료전]";
      }
    }

    return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 15),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // 상태 텍스트 적용
                    pw.Text("$statusText ${item['title'] ?? '(제목 없음)'}", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    if (_tabController.index != 2)
                      pw.Text(item['author'] ?? '담당자', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ]
              ),
              pw.Divider(color: PdfColors.grey300),
              _buildPdfRow("일시", "${DateFormat('MM.dd HH:mm').format(start)} ~ ${DateFormat('HH:mm').format(end)}"),
              _buildPdfRow("장소", "${item['buildingName'] ?? '-'}"),

              if (logs.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text("[업무내용 및 히스토리]", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ...logs.map((log) {
                  String author = log['author'] ?? '알수없음';
                  String text = log['text'] ?? '';
                  String dateStr = "";

                  if (log['createdAt'] != null && log['createdAt'] is Timestamp) {
                    dateStr = DateFormat('yyyy.MM.dd HH:mm').format((log['createdAt'] as Timestamp).toDate());
                  }

                  // ✅ 타인(지시자) 작성 여부 판별 (PDF용)
                  String ownerUid = item['uid'] ?? '';
                  String ownerName = item['author'] ?? '';
                  String logUid = log['uid'] ?? '';
                  bool isOther = (logUid.isNotEmpty && ownerUid.isNotEmpty) ? (logUid != ownerUid) : (author != ownerName);

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 1),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        style: const pw.TextStyle(fontSize: 9),
                        children: [
                          pw.TextSpan(text: "• ", style: pw.TextStyle(color: isOther ? PdfColors.red : PdfColors.black)),
                          pw.TextSpan(
                            text: "[$author] ",
                            style: pw.TextStyle(
                              color: isOther ? PdfColors.blue : PdfColors.black, // ✅ 이름은 파란색
                              fontWeight: isOther ? pw.FontWeight.bold : pw.FontWeight.normal,
                            ),
                          ),
                          pw.TextSpan(
                            text: "$text ($dateStr)",
                            style: pw.TextStyle(
                              color: isOther ? PdfColors.red : PdfColors.black, // ✅ 내용은 빨간색
                              fontWeight: isOther ? pw.FontWeight.bold : pw.FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],

              if (item['reportContent'] != null && item['reportContent'].toString().isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(5),
                  color: PdfColors.blue50,
                  child: pw.Text("결과: ${item['reportContent']}", style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900)),
                ),
              ],

              if (item['status'] == 'completed' && item['completedAt'] != null)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      // 완료자 실명 표시 (PDF)
                        item['completerName'] != null
                            ? "처리완료: ${DateFormat('yyyy.MM.dd HH:mm').format((item['completedAt'] as Timestamp).toDate())} (${item['completerName']})"
                            : "처리완료: ${DateFormat('yyyy.MM.dd HH:mm').format((item['completedAt'] as Timestamp).toDate())}",
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.green700, fontWeight: pw.FontWeight.bold)
                    ),
                  ),
                ),
            ]
        )
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 40, child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  // ====================================================
  // [UI 빌드]
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, List<Map<String, dynamic>>>>(
      key: _streamKey,
      stream: _getSplitReportStream(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'today': [], 'overdue': []};
        final todayList = data['today'] ?? [];
        final overdueList = data['overdue'] ?? [];
        final int overdueCount = overdueList.length;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: const Text("업무 결과 보고", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 40.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.copy, color: AppTheme.textMain), tooltip: "복사", onPressed: _copyReport),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.share, color: AppTheme.primaryColor), tooltip: "공유", onPressed: _shareReport),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.print_outlined, color: AppTheme.textMain), tooltip: "출력", onPressed: _printReport),
                    ],
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  const Tab(text: "오늘 업무보고"),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("미완료"),
                        if (overdueCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
                            child: Text("$overdueCount", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Tab(text: "팀 전체"),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(todayList),
                _buildOverdueTab(overdueList),
                _buildTeamReportTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayTab(List<Map<String, dynamic>> list) {
    return Column(
      children: [
        // ✅ [고도화] 오늘 탭에도 날짜 이동/기간 설정 기능 적용
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28, color: AppTheme.textMain),
                onPressed: () => setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  _selectedEndDate = _selectedDate; // 화살표 이동 시 하루 단위로 초기화
                }),
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: DateTimeRange(start: _selectedDate, end: _selectedEndDate),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked.start;
                      _selectedEndDate = picked.end;
                    });
                  }
                },
                child: Row(
                  children: [
                    Text(
                      DateUtils.isSameDay(_selectedDate, _selectedEndDate)
                          ? DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate)
                          : "${DateFormat('yy.MM.dd').format(_selectedDate)} ~ ${DateFormat('yy.MM.dd').format(_selectedEndDate)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppTheme.textSub),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 28, color: AppTheme.textMain),
                onPressed: () => setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                  _selectedEndDate = _selectedDate;
                }),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        Expanded(
            child: list.isEmpty
                ? const Center(child: Text("해당 기간에 예정된 업무가 없습니다.", style: TextStyle(color: Colors.grey)))
                : _buildBaseList(list, isOverdueMode: false)
        ),
      ],
    );
  }

  Widget _buildOverdueTab(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return const Center(child: Text("미완료된 업무가 없습니다.", style: TextStyle(color: Colors.grey)));
    return _buildBaseList(list, isOverdueMode: true);
  }

  Widget _buildTeamReportTab() {
    return Column(
      children: [
        // ✅ [수정] 오늘 업무보고 탭과 동일한 디자인 & 하루씩 이동 기능 적용
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // 패딩도 동일하게 맞춤
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // [이전 날짜]
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28, color: AppTheme.textMain),
                    onPressed: () {
                      setState(() {
                        // 화살표 누르면: 시작일을 하루 전으로 + 종료일도 시작일과 같게 (하루만 조회)
                        _searchStartDate = _searchStartDate.subtract(const Duration(days: 1));
                        _searchEndDate = _searchStartDate;
                      });
                    },
                  ),

                  // [날짜 표시 및 기간 선택]
                  InkWell(
                    onTap: () async {
                      // 가운데 누르면: 기간 선택 가능
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: DateTimeRange(start: _searchStartDate, end: _searchEndDate),
                      );
                      if (picked != null) {
                        setState(() {
                          _searchStartDate = picked.start;
                          _searchEndDate = picked.end;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          // 시작일과 종료일이 같으면 -> "2026년 02월 12일 (목)" (오늘탭 스타일)
                          // 다르면 -> "26.02.12 ~ 26.02.15" (기간 스타일)
                          DateUtils.isSameDay(_searchStartDate, _searchEndDate)
                              ? DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_searchStartDate)
                              : "${DateFormat('yy.MM.dd').format(_searchStartDate)} ~ ${DateFormat('yy.MM.dd').format(_searchEndDate)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.textSub), // 클릭 가능함 힌트
                      ],
                    ),
                  ),

                  // [다음 날짜]
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28, color: AppTheme.textMain),
                    onPressed: () {
                      setState(() {
                        // 화살표 누르면: 시작일을 하루 뒤로 + 종료일도 시작일과 같게
                        _searchStartDate = _searchStartDate.add(const Duration(days: 1));
                        _searchEndDate = _searchStartDate;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // [검색창 유지]
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: "건물명, 담당자명 검색",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchKeyword.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _searchCtrl.clear();
                      _searchKeyword = "";
                    }),
                  )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
                onChanged: (val) => setState(() => _searchKeyword = val),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppTheme.borderColor),
        // 2. 리스트 출력 (미완료 추적 포함)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // ✅ [핵심] 미완료된 과거 업무도 가져오기 위해 쿼리 날짜 제한을 풉니다.
            // 데이터량이 많아지면 'status' 인덱싱이나 최근 1년 제한 등을 고려해야 합니다.
            // 여기서는 '최근 1년 ~ 미래' 정도로 넓게 잡습니다.
            stream: _firestore.collection('schedules')
                .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 365))))
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var allDocs = snapshot.data!.docs;
              List<DocumentSnapshot> filteredDocs = [];

              // ✅ [필터링 로직] 기간 내 업무 + 미완료 업무(추적) 포함
              for (var doc in allDocs) {
                var data = doc.data() as Map<String, dynamic>;

                // 1. 검색어 필터
                if (_searchKeyword.isNotEmpty) {
                  String bName = (data['buildingName'] ?? '').toString().toLowerCase();
                  String author = (data['author'] ?? '').toString().toLowerCase();
                  String key = _searchKeyword.toLowerCase();
                  if (!bName.contains(key) && !author.contains(key)) continue;
                }

                DateTime start = (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
                DateTime end = (data['endDate'] as Timestamp?)?.toDate() ?? start;

                DateTime dayStart = DateTime(start.year, start.month, start.day);
                DateTime dayEnd = DateTime(end.year, end.month, end.day);

                // [조건 A] 선택된 기간(검색일)에 포함되는 업무
                // (일정 시작 <= 검색 종료) AND (일정 종료 >= 검색 시작)
                bool isInRange = (dayStart.compareTo(_searchEndDate) <= 0) && (dayEnd.compareTo(_searchStartDate) >= 0);

                // [조건 B] 추적 관리: 완료되지 않았고(completed 아님), 종료일이 검색일보다 과거인 경우
                // 즉, "해야 하는데 안 하고 넘어온 것"
                bool isOverdueTracking = (data['status'] != 'completed') && dayEnd.isBefore(_searchStartDate);

                // 둘 중 하나라도 해당되면 리스트에 추가
                if (isInRange || isOverdueTracking) {
                  filteredDocs.add(doc);
                }
              }

              if (filteredDocs.isEmpty) {
                return const Center(child: Text("해당 기간에 업무 보고가 없습니다.", style: TextStyle(color: Colors.grey)));
              }

              // 담당자별 그룹화 로직 (기존 유지)
              Map<String, List<DocumentSnapshot>> groupedDocs = {};
              for (var doc in filteredDocs) {
                var data = doc.data() as Map<String, dynamic>;
                String author = data['author'] ?? '담당자 미정';
                if (groupedDocs[author] == null) groupedDocs[author] = [];
                groupedDocs[author]!.add(doc);
              }

              // 담당자 이름 가나다순 정렬
              var sortedAuthors = groupedDocs.keys.toList()..sort();

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: sortedAuthors.length,
                itemBuilder: (context, index) {
                  String authorName = sortedAuthors[index];
                  List<DocumentSnapshot> authorDocs = groupedDocs[authorName]!;

                  // 그룹 내에서는 최신순 정렬
                  authorDocs.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;
                    Timestamp tA = dataA['startDate'] ?? Timestamp.now();
                    Timestamp tB = dataB['startDate'] ?? Timestamp.now();
                    return tB.compareTo(tA);
                  });

                  // 담당자별 카드 생성
                  return Card(
                    key: PageStorageKey(authorName),
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppTheme.borderColor)
                    ),
                    child: ExpansionTile(
                      key: PageStorageKey('tile_$authorName'),
                      initiallyExpanded: true, // ✅ [수정] 기본값을 true(열림)로 변경
                      shape: const Border(),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryLight,
                        radius: 16,
                        child: Text(
                            authorName.isNotEmpty ? authorName[0] : '?',
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)
                        ),
                      ),
                      title: Text(
                          "$authorName (${authorDocs.length}건)",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain)
                      ),
                      backgroundColor: Colors.white,
                      collapsedBackgroundColor: Colors.white,
                      childrenPadding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
                      children: authorDocs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        data['docId'] = doc.id;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildReportCard(data, false),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ [반응형 수정] PC 좌우 공백 제거 (꽉 찬 화면)
  Widget _buildBaseList(List<Map<String, dynamic>> reports, {required bool isOverdueMode}) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildReportCard(reports[index], isOverdueMode);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data, bool isOverdueMode) {
    bool isCompleted = data['status'] == 'completed';
    DateTime start = (data['startDate'] as Timestamp?)?.toDate() ?? (data['date'] as Timestamp).toDate();
    DateTime end = (data['endDate'] as Timestamp?)?.toDate() ?? start;

    // 날짜 계산
    bool isExtended = !DateUtils.isSameDay(start, end);
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime endDateOnly = DateTime(end.year, end.month, end.day);

    // 1. 기간 중인 업무 (진행 중)
    bool isExtendingNow = isExtended && endDateOnly.isAfter(today.subtract(const Duration(seconds: 1)));

    // 2. ✅ [핵심 수정] 날짜가 지난 과거 업무인지 체크 (팀 탭에서도 미완료 표시를 위함)
    bool isPast = endDateOnly.isBefore(today);

    String displayTitle = data['title'] ?? '';
    if (displayTitle.isEmpty) displayTitle = "(추가 방문지)";

    String author = data['author'] ?? '담당자';

    String dateInfo;
    // [모바일 대응 수정] 문구가 너무 길면 화면이 깨지므로 포맷을 단축합니다.
    // 기존: "시작: 2026-02-13 14:00 (과거 미완료)" -> 너무 김
    // 변경: "02.13 14:00 (미완료)" -> 깔끔함
    if (isOverdueMode || (isPast && !isCompleted)) {
      dateInfo = "${DateFormat('MM.dd HH:mm').format(start)} (미완료)";
    } else {
      dateInfo = DateFormat('HH:mm').format(start);
    }

    List logs = data['workLogs'] ?? [];
    Map<String, dynamic>? latestLog = logs.isNotEmpty ? logs.last : null;

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: () => _showReadOnlyDetail(data),
        child: CommonCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ✅ [핵심 수정] 배지 상태 결정 로직 강화
                  // (미완료 모드) OR (기간 연장 중) OR (이미 날짜가 지난 과거) -> [미완료] (주황색)
                  // 그 외 -> [완료전] (빨간색) / [완료] (초록색)
                  _buildStatusBadge(isCompleted, isOverdueMode || isExtendingNow || isPast),

                  const SizedBox(width: 8),
                  Text(
                    dateInfo,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (isOverdueMode || (isPast && !isCompleted)) ? Colors.deepOrange : AppTheme.textSub,
                        fontSize: (isOverdueMode || (isPast && !isCompleted)) ? 12 : 14
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data['buildingName'] ?? '장소 미정',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                    child: Text(author, style: const TextStyle(fontSize: 11, color: AppTheme.textSub)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Text("📌 $displayTitle", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),

              if (isExtended && !isOverdueMode)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "🗓️ 일정 기간: ${DateFormat('MM.dd').format(start)} ~ ${DateFormat('MM.dd').format(end)}",
                    style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 4),
              if (data['content'] != null && data['content'].toString().isNotEmpty)
                Text(data['content'], style: const TextStyle(color: AppTheme.textSub, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),

              if (latestLog != null) ...[
                Builder(
                    builder: (context) {
                      // ✅ 타인(지시자) 작성 여부 판별
                      String ownerUid = data['uid'] ?? '';
                      String ownerName = data['author'] ?? '';
                      String logUid = latestLog['uid'] ?? '';
                      String logAuthor = latestLog['author'] ?? '알수없음';
                      bool isOther = (logUid.isNotEmpty && ownerUid.isNotEmpty) ? (logUid != ownerUid) : (logAuthor != ownerName);

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isOther ? Colors.red.withOpacity(0.05) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                          border: isOther ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 12, color: isOther ? Colors.red : AppTheme.textSub),
                            const SizedBox(width: 4),
                            Expanded(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 12),
                                  children: [
                                    TextSpan(
                                      text: "$logAuthor: ",
                                      style: TextStyle(
                                        color: isOther ? Colors.blue : AppTheme.textMain, // 이름 파란색
                                        fontWeight: isOther ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "${latestLog['text']}",
                                      style: TextStyle(
                                        color: isOther ? Colors.red : AppTheme.textMain, // 내용 빨간색
                                        fontWeight: isOther ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                ),
              ],

              const Divider(height: 24, color: AppTheme.borderColor),

              if (data['reportContent'] != null && data['reportContent'].isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                  child: Text("📝 ${data['reportContent']}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ),

              // 완료 일시 + 완료자 실명 표시
              if (data['status'] == 'completed' && data['completedAt'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        data['completerName'] != null
                            ? "처리완료: ${DateFormat('yy.MM.dd HH:mm').format((data['completedAt'] as Timestamp).toDate())} (${data['completerName']})"
                            : "처리완료: ${DateFormat('yy.MM.dd HH:mm').format((data['completedAt'] as Timestamp).toDate())}",
                        style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              // 버튼 권한 제어 (B안: 회색 버튼 + 팝업)
              Builder(
                  builder: (context) {
                    // 권한 체크
                    String authorUid = data['uid'] ?? '';
                    bool hasPermission = (_myUid == authorUid) || _isAdmin;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // [1] 보고하기 버튼
                        OutlinedButton.icon(
                          onPressed: () {
                            // 1. 권한 체크
                            if (!hasPermission) {
                              _showAccessDeniedDialog();
                              return;
                            }

                            // ✅ [수정] 완료된 상태라면 경고 팝업 띄우기 (수정 불가)
                            if (isCompleted) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                                      SizedBox(width: 8),
                                      Text("수정 제한", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  content: const Text("취소버튼을 눌러 업무완료를 취소 해야\n다시 보고하기를 할수 있습니다."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("확인", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // 2. 미완료 상태일 때만 정상적으로 수정 팝업 열기
                              _showEditReportDialog(data);
                            }
                          },
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text("보고하기"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: hasPermission ? AppTheme.primaryColor : Colors.grey,
                            side: BorderSide(color: hasPermission ? AppTheme.primaryColor : Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // [2] 완료 버튼
                        Builder(
                            builder: (context) {
                              bool isCurrentCompleted = data['status'] == 'completed';
                              bool hasContent = (data['reportContent'] != null && data['reportContent'].toString().trim().isNotEmpty);
                              bool isLogicEnabled = isCurrentCompleted || hasContent;

                              return ElevatedButton.icon(
                                onPressed: () {
                                  if (!hasPermission) {
                                    _showAccessDeniedDialog();
                                  } else if (!isLogicEnabled) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        title: const Text("알림"),
                                        content: const Text("보고하기에서 업무보고서를 작성해야\n완료버튼이 활성화됩니다."),
                                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인"))],
                                      ),
                                    );
                                  } else {
                                    _toggleComplete(data);
                                  }
                                },
                                icon: Icon(isCurrentCompleted ? Icons.undo : Icons.check, size: 16),
                                label: Text(isCurrentCompleted ? "취소" : "완료"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (hasPermission && isLogicEnabled) ? AppTheme.primaryColor : Colors.grey,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                              );
                            }
                        ),
                      ],
                    );
                  }
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isCompleted, bool isExtendingOrOverdue) {
    String text = isCompleted ? "완료" : (isExtendingOrOverdue ? "미완료" : "완료전");
    Color color = isCompleted ? Colors.green : (isExtendingOrOverdue ? Colors.deepOrange : AppTheme.errorColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: const [
            Icon(Icons.lock_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("권한 없음", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("작성자 본인 또는 관리자만\n수정 및 완료 처리할 수 있습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("확인", style: TextStyle(color: AppTheme.textMain)),
          ),
        ],
      ),
    );
  }
}