// [파일 위치: lib/pages/field_info/field_contact_page.dart]
// [페이지 설명: 현장 문제해결형 공유 전화번호부 (내부DB + 네이버 지역 검색 API 연동)]
// [기능: 증상/상호명 검색, 하이브리드 리스트 노출, 🌟네이버 업체 원클릭 저장, 🌟폐업/결번 즉시 신고, 전화 걸기, 🗺️네이버 지도 연동 및 클립보드 자동완성, 🏆신뢰도 랭킹 및 더보기]

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🌟 클립보드(복사/붙여넣기) 자동 감지를 위해 추가됨
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🌟 유저 신분 확인용

// =======================================================
// 🗂️ 1. 데이터 모델 (우리 DB와 네이버 결과를 하나로 묶어주는 그릇)
// =======================================================
class FieldContact {
  String id;
  String name;
  String phone;
  List<String> tags;
  double rating; // 내부 DB 평점
  String memo;
  String status; // 'active' 또는 'closed'
  bool isFromNaver; // 네이버 출신인지 구분하는 꼬리표
  int trustScore; // 🌟 [신규] 네이버 데이터 신뢰도 점수 (100점 만점)

  FieldContact({
    required this.id,
    required this.name,
    required this.phone,
    this.tags = const [],
    this.rating = 0.0,
    this.memo = '',
    this.status = 'active',
    this.isFromNaver = false,
    this.trustScore = 0, // 기본값 0점
  });

  // 파이어베이스(DB) 데이터를 객체로 변환
  factory FieldContact.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FieldContact(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(), // 숫자 형변환 안전처리
      memo: data['memo'] ?? '',
      status: data['status'] ?? 'active',
      isFromNaver: false,
      trustScore: 100, // 🌟 우리 DB에 등록된 업체는 이미 검증되었으므로 100점 만점 부여
    );
  }

  // 객체를 DB에 저장할 형태로 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'tags': tags,
      'rating': rating,
      'memo': memo,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(), // 등록 시간
    };
  }
}

// =======================================================
// 📱 2. 전화번호부 메인 UI
// =======================================================
class FieldContactPage extends StatefulWidget {
  const FieldContactPage({super.key});

  @override
  State<FieldContactPage> createState() => _FieldContactPageState();
}

class _FieldContactPageState extends State<FieldContactPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<FieldContact> _naverContacts = [];
  bool _isNaverSearching = false;
  int _naverSearchStart = 1; // 🌟 [신규] 네이버 추가 5개 불러오기를 위한 페이징 시작점

  // 👑 [수정됨] 접속한 사람이 '진짜 관리자'인지 검사하는 로직
  bool get _isSuperAdmin {
    final user = FirebaseAuth.instance.currentUser;
    // 🚨 'admin@sm.com' 부분을 대표님이 실제로 로그인하실 때 쓰는 이메일로 반드시 바꿔주세요!
    return user != null && user.email == 'yuseok8052@gmail.com';
  }

  // -----------------------------------------------------
  // 🗺️ 네이버 지도 연동 (🌟 주소 압축 고도화)
  // -----------------------------------------------------
  Future<void> _openNaverMap(FieldContact contact) async {
    // 🌟 1. 너무 긴 주소 때문에 네이버 지도가 못 찾는 현상 방지: 앞 2어절만 추출
    String shortAddress = '';
    if (contact.memo.isNotEmpty) {
      List<String> parts = contact.memo.split(' ');
      if (parts.length >= 2) {
        shortAddress = "${parts[0]} ${parts[1]}"; // 예: "인천광역시 중구"
      } else {
        shortAddress = contact.memo;
      }
    }

    // 🌟 2. 상호명과 압축된 주소를 합쳐서 정확도 극대화
    final String fullQuery = "${contact.name} $shortAddress".trim();
    final encodedQuery = Uri.encodeComponent(fullQuery);

    // 네이버 지도 검색 URL
    final url = Uri.parse("https://map.naver.com/v5/search/$encodedQuery");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _showSnackBar("네이버 지도에서 번호를 [복사]한 후 앱으로 돌아오세요.");
    } else {
      _showSnackBar("지도를 열 수 없습니다.", isError: true);
    }
  }

  // -----------------------------------------------------
  // 🌐 네이버 지역 검색 API (🌟 신뢰도 채점 및 더보기 기능 추가)
  // -----------------------------------------------------
  Future<void> _searchNaver(String query, {bool isLoadMore = false}) async {
    if (query.trim().isEmpty) {
      setState(() => _naverContacts.clear());
      return;
    }

    setState(() {
      _isNaverSearching = true;
      if (!isLoadMore) {
        _naverSearchStart = 1; // 새 검색이면 시작점 초기화
        _naverContacts.clear();
      } else {
        _naverSearchStart += 5; // 더보기면 시작점 +5 이동
      }
    });

    try {
      const firebaseFuncUrl = "https://searchnaverproxy-pjaqc5w3jq-du.a.run.app";
      // 🌟 start 파라미터를 붙여서 서버에 보냄 (더 검색하기 지원)
      final requestUrl = "$firebaseFuncUrl?query=${Uri.encodeQueryComponent(query)}&start=$_naverSearchStart";

      print("📡 전용 서버로 네이버 검색 요청: $query (시작점: $_naverSearchStart)");
      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        if (items.isEmpty && !isLoadMore) {
          _showSnackBar("네이버 검색 결과가 없습니다.");
        }

        List<FieldContact> newResults = items.map((item) {
          // <b> 태그 등 불필요한 문자 제거
          String cleanName = item['title'].toString().replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&amp;', '&');
          String category = item['category']?.toString().split('>').last ?? '일반업체';

          String phoneNum = item['telephone']?.toString().trim() ?? '';
          String address = item['roadAddress']?.toString().trim() ?? item['address']?.toString().trim() ?? '';
          String link = item['link']?.toString().trim() ?? '';

          // 🌟 [핵심] SM 신뢰도 자동 채점 로직 (100점 만점)
          int score = 0;
          if (address.isNotEmpty) score += 50; // 1순위: 주소가 정확히 있는가? (50점)
          if (link.isNotEmpty) score += 30;    // 2순위: 홈페이지/블로그 링크가 있는가? (30점)
          if (phoneNum.isNotEmpty) score += 20; // 3순위: 전화번호가 즉시 제공되는가? (20점)

          if (phoneNum.isEmpty) phoneNum = '전화번호 미제공';

          return FieldContact(
            id: 'naver_${item['mapx']}_${item['mapy']}',
            name: cleanName,
            phone: phoneNum,
            tags: ['#$category'],
            isFromNaver: true,
            memo: address,
            trustScore: score, // 🌟 채점된 점수 탑재!
          );
        }).toList();

        setState(() {
          if (isLoadMore) {
            _naverContacts.addAll(newResults); // 더보기일 경우 기존 리스트 뒤에 추가
          } else {
            _naverContacts = newResults; // 새 검색일 경우 덮어쓰기
          }
          // 🌟 신뢰도 점수가 높은 알짜배기 업체부터 위로 오도록 자동 내림차순 정렬!
          _naverContacts.sort((a, b) => b.trustScore.compareTo(a.trustScore));
        });
        print("✅ 네이버 검색 성공: 총 ${_naverContacts.length}건 정렬 완료");

      } else {
        _showSnackBar("서버 통신 실패 (에러코드: ${response.statusCode})", isError: true);
      }
    } catch (e) {
      print("🚨 치명적 통신 오류: $e");
      _showSnackBar("인터넷 연결 또는 서버 상태를 확인하세요.", isError: true);
    } finally {
      setState(() => _isNaverSearching = false);
    }
  }

  // -----------------------------------------------------
  // 📞 전화 걸기
  // -----------------------------------------------------
  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar("전화를 걸 수 없는 기기이거나 번호입니다.", isError: true);
      }
    } catch (e) {
      _showSnackBar("전화 연결 중 오류가 발생했습니다.", isError: true);
    }
  }

  // 👑 [추가 2] 관리자 전용 영구 삭제 함수 (여기에 복사해 넣으세요!)
  // -----------------------------------------------------
  Future<void> _confirmDeleteByAdmin(FieldContact contact) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text("영구 삭제 (관리자 전용)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: Text("⚠️ 주의\n'${contact.name}' 업체를 DB에서 완전히 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("영구 삭제", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('field_contacts').doc(contact.id).delete();
        _showSnackBar("관리자 권한으로 영구 삭제되었습니다.");
      } catch (e) {
        _showSnackBar("삭제 중 오류가 발생했습니다.", isError: true);
      }
    }
  }

  // -----------------------------------------------------
  // 🚨 폐업/결번 신고 확인 팝업 (DB 상태 업데이트)
  // -----------------------------------------------------
  Future<void> _confirmReportClosed(FieldContact contact) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("폐업/결번 신고", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("'${contact.name}' 업체를 폐업(결번) 처리하시겠습니까?\n이후로는 다른 직원들이 헛걸음하지 않도록 비활성화됩니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("신고하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('field_contacts').doc(contact.id).update({'status': 'closed'});
        _showSnackBar("폐업 처리가 완료되어 리스트에서 비활성화되었습니다.");
      } catch (e) {
        _showSnackBar("처리 중 오류가 발생했습니다.", isError: true);
      }
    }
  }
  // 🌟 [여기 추가!] 실수로 누른 폐업 신고를 다시 살려내는 '복구' 팝업
  // -----------------------------------------------------
  Future<void> _confirmRestoreClosed(FieldContact contact) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.green),
            SizedBox(width: 8),
            Text("폐업 신고 취소 (복구)", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("'${contact.name}' 업체를 다시 '정상 영업' 상태로 복구하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("복구하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // status를 다시 'active'로 돌려놓습니다!
        await FirebaseFirestore.instance.collection('field_contacts').doc(contact.id).update({'status': 'active'});
        _showSnackBar("정상 영업 상태로 복구되었습니다.");
      } catch (e) {
        _showSnackBar("처리 중 오류가 발생했습니다.", isError: true);
      }
    }
  }

  // -----------------------------------------------------
  // 📝 새 업체 등록 / 수정 / 저장 팝업
  // -----------------------------------------------------
  void _showAddDialog({FieldContact? initialData}) async {
    String clipboardText = "";

    // 🌟 [버그 수정됨] 클립보드를 깐깐하게 스캔합니다!
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      // 글자에서 숫자만 쏙 빼서 몇 개인지 셉니다.
      String numbersOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

      // 전체 길이가 20자 미만이고, 숫자가 최소 8개 이상(일반 전화번호 길이)일 때만 전화번호로 인정!
      if (text.length < 20 && numbersOnly.length >= 8) {
        clipboardText = text;
      }
    }

    if (!mounted) return;

    final nameCtrl = TextEditingController(text: initialData?.name ?? '');
    String initialPhone = (initialData?.phone == '전화번호 미제공') ? '' : (initialData?.phone ?? '');
    final phoneCtrl = TextEditingController(text: initialPhone.isEmpty ? clipboardText : initialPhone);
    final tagsCtrl = TextEditingController(text: initialData?.tags.join(', ') ?? '');
    final memoCtrl = TextEditingController(text: initialData?.memo ?? '');

    // 🌟 [수정 포인트] 기본 별점 5.0이지만, 기존 데이터가 있으면 그 별점을 가져옴
    double currentRating = (initialData != null && !initialData.isFromNaver && initialData.rating > 0)
        ? initialData.rating
        : 5.0;

    // 🌟 [수정 포인트] 팝업창 제목을 상황에 맞게 변경
    String dialogTitle = "새 업체 등록";
    if (initialData != null) {
      dialogTitle = initialData.isFromNaver ? "⭐ 우리 DB로 저장" : "📝 업체 정보 수정";
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(dialogTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (clipboardText.isNotEmpty && initialPhone.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.paste, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(child: Text("지도에서 복사한 번호 '$clipboardText'를 자동 입력했습니다.", style: const TextStyle(fontSize: 12, color: Colors.blue))),
                        ],
                      ),
                    ),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "업체명 (상호)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "전화번호", hintText: "직접 입력 혹은 붙여넣기", border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text("평점: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(" ${currentRating.toStringAsFixed(1)}점", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Slider(
                    value: currentRating, min: 1.0, max: 5.0,
                    divisions: 8,
                    activeColor: Colors.amber,
                    onChanged: (val) {
                      setDialogState(() => currentRating = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: "태그 (쉼표로 구분)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: memoCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "메모", border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  _showSnackBar("상호명과 전화번호는 필수입니다.", isError: true);
                  return;
                }

                List<String> rawTags = tagsCtrl.text.split(',');
                List<String> formattedTags = rawTags.map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => e.startsWith('#') ? e : '#$e').toList();

                final newContactMap = {
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'tags': formattedTags,
                  'rating': currentRating,
                  'memo': memoCtrl.text.trim(),
                  // status와 createdAt는 기존 것을 유지하기 위해 생략하거나 아래에서 분기 처리
                };

                try {
                  // 🌟 [핵심 수정 포인트] 수정인지 등록인지 구별해서 처리합니다!
                  if (initialData != null && !initialData.isFromNaver && initialData.id.isNotEmpty) {
                    // 1. 우리 DB에 있던 데이터면 -> '수정(업데이트)'
                    await FirebaseFirestore.instance.collection('field_contacts').doc(initialData.id).update(newContactMap);
                    if (mounted) Navigator.pop(ctx);
                    _showSnackBar("성공적으로 수정되었습니다!");
                  } else {
                    // 2. 신규 등록이거나 네이버 업체 가져오기면 -> '새로 추가(add)'
                    newContactMap['status'] = 'active';
                    newContactMap['createdAt'] = FieldValue.serverTimestamp();
                    await FirebaseFirestore.instance.collection('field_contacts').add(newContactMap);
                    if (mounted) Navigator.pop(ctx);
                    _showSnackBar("성공적으로 등록되었습니다!");

                    if (initialData != null && initialData.isFromNaver) {
                      setState(() { _naverContacts.clear(); _searchController.clear(); _searchQuery = ""; });
                    }
                  }
                } catch (e) {
                  _showSnackBar("저장 중 오류가 발생했습니다.", isError: true);
                }
              },
              child: Text(initialData != null && !initialData.isFromNaver ? "수정하기" : "저장하기", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("공유 전화번호부", style: TextStyle(color: AppTheme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textMain),
        elevation: 1,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildSearchBar(),
              if (_isNaverSearching && _naverContacts.isEmpty) const LinearProgressIndicator(color: Colors.green),
              Expanded(child: _buildHybridContactList()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text("업체 등록", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        onSubmitted: (val) => _searchNaver(val.trim()),
        decoration: InputDecoration(
          hintText: "증상이나 상호 검색 후 '엔터'를 누르세요",
          prefixIcon: IconButton(icon: const Icon(Icons.search, color: AppTheme.primaryColor), onPressed: () => _searchNaver(_searchQuery)),
          suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() { _searchQuery = ""; _naverContacts.clear(); });
              }
          ),
          filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildHybridContactList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('field_contacts').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        List<FieldContact> internalContacts = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          internalContacts = snapshot.data!.docs.map((doc) => FieldContact.fromFirestore(doc)).toList();
        }

        if (_searchQuery.isNotEmpty) {
          // 🌟 1. 검색어를 띄어쓰기 기준으로 쪼갭니다. (예: "구리 수도꼭지" -> ["구리", "수도꼭지"])
          List<String> searchTerms = _searchQuery.toLowerCase().split(' ').where((s) => s.isNotEmpty).toList();

          internalContacts = internalContacts.where((c) {
            String nameLower = c.name.toLowerCase();
            String memoLower = c.memo.toLowerCase();
            String tagsLower = c.tags.join(' ').toLowerCase();

            // 🌟 2. 쪼갠 단어들이 업체명, 메모(주소), 태그 중 어디든 '모두' 포함되어야 합격! (AND 검색)
            return searchTerms.every((term) =>
            nameLower.contains(term) || tagsLower.contains(term) || memoLower.contains(term)
            );
          }).toList();
        }

        List<FieldContact> uniqueNaverContacts = _naverContacts.where((naver) {
          bool isDuplicate = internalContacts.any((internal) {
            String internalCleanPhone = internal.phone.replaceAll(RegExp(r'[^0-9]'), '');
            String naverCleanPhone = naver.phone.replaceAll(RegExp(r'[^0-9]'), '');
            return internalCleanPhone == naverCleanPhone || internal.name == naver.name;
          });
          return !isDuplicate;
        }).toList();

        List<FieldContact> finalContacts = [...internalContacts, ...uniqueNaverContacts];

        if (finalContacts.isEmpty) {
          return const Center(child: Text("검색 결과가 없습니다.\n우측 하단 버튼을 눌러 등록해주세요.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // 🌟 검색어가 있을 때(네이버 연동 중일 때) 하단에 '더 검색하기' 버튼 렌더링 공간(+1) 추가
          itemCount: finalContacts.length + (_searchQuery.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            // 🌟 리스트의 맨 마지막 칸에 도달하면 [더 검색하기] 버튼 렌더링
            if (index == finalContacts.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: _isNaverSearching ? null : () => _searchNaver(_searchQuery, isLoadMore: true),
                  icon: _isNaverSearching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline),
                  label: const Text("더 검색하기 (추가 5개)", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              );
            }
            return _buildContactCard(finalContacts[index]);
          },
        );
      },
    );
  }

  // 📇 업체 카드 UI (🌟 업체명, 연락처 라벨 추가 및 버튼 완벽 복구)
  Widget _buildContactCard(FieldContact contact) {
    bool isClosed = contact.status == 'closed';
    bool isNaver = contact.isFromNaver;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isNaver ? Colors.green.withOpacity(0.3) : Colors.transparent, width: 1.5)
      ),
      color: isClosed ? Colors.grey[200] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        // 🌟 [수정 1] 업체명 라벨 부착!
        title: Text(
          "업체명 : ${contact.name}",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isClosed ? Colors.grey : AppTheme.textMain,
              decoration: isClosed ? TextDecoration.lineThrough : null
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                if (isNaver)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                    child: Text("N 검색 • 신뢰도 ${contact.trustScore}점", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                if (!isClosed && !isNaver)
                  Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), Text(" ${contact.rating}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]),
              ],
            ),
            const SizedBox(height: 8),

            // 🌟 [수정 2] 연락처 라벨 부착!
            Text("연락처 : ${contact.phone}", style: TextStyle(color: isClosed ? Colors.grey : AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            Wrap(spacing: 6, children: contact.tags.map((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isClosed ? Colors.grey[300] : AppTheme.primaryLight, borderRadius: BorderRadius.circular(4)), child: Text(tag, style: TextStyle(fontSize: 11, color: isClosed ? Colors.grey[600] : AppTheme.primaryColor)))).toList()),

            // 🌟 [수정 3] 주소/메모 라벨 부착!
            if (contact.memo.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("주소/메모 : ${contact.memo}", style: TextStyle(fontSize: 12, color: Colors.grey[600]))
              ),
          ],
        ),

        // 🌟 버튼들 완벽 복구 (폐업 신고, 정보 수정, 관리자 삭제 등 모두 포함)
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isClosed) ...[
              const Text("폐업/결번", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              // 🌟 [여기에 추가됨!] 실수로 폐업 처리했을 때 다시 살려내는 복구 버튼
              if (!isNaver)
                IconButton(
                  tooltip: "폐업 신고 취소 (정상 복구)",
                  icon: const Icon(Icons.restore, color: Colors.green, size: 28),
                  onPressed: () => _confirmRestoreClosed(contact),
                ),

              if (_isSuperAdmin)
                IconButton(
                  tooltip: "영구 삭제 (관리자)",
                  icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                  onPressed: () => _confirmDeleteByAdmin(contact),
                ),

            ] else ...[
              if (!isNaver && _isSuperAdmin)
                IconButton(
                  tooltip: "영구 삭제 (관리자)",
                  icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                  onPressed: () => _confirmDeleteByAdmin(contact),
                ),
              if (!isNaver)
                IconButton(
                  tooltip: "정보 수정",
                  icon: const Icon(Icons.edit_note, color: Colors.blue, size: 30),
                  onPressed: () => _showAddDialog(initialData: contact),
                ),
              if (!isNaver)
                IconButton(
                  tooltip: "폐업/결번 신고",
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  onPressed: () => _confirmReportClosed(contact),
                ),
              if (isNaver)
                IconButton(
                  tooltip: "네이버 지도 보기 (전화번호 찾기)",
                  icon: const Icon(Icons.map_outlined, color: Colors.green, size: 28),
                  onPressed: () => _openNaverMap(contact),
                ),
              if (isNaver)
                IconButton(
                  tooltip: "우리 DB로 저장",
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 28),
                  onPressed: () => _showAddDialog(initialData: contact),
                ),
              IconButton(
                tooltip: "전화 걸기",
                icon: const Icon(Icons.phone_in_talk, color: Colors.green, size: 28),
                onPressed: () => _makePhoneCall(contact.phone),
              ),
            ],
          ],
        ),
      ),
    );
  }
}