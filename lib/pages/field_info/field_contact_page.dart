// [파일 위치: lib/pages/field_info/field_contact_page.dart]
// [페이지 설명: 현장 문제해결형 공유 전화번호부 (내부DB + 네이버 지역 검색 API 연동)]
// [기능: 증상/상호명 검색, 하이브리드 리스트 노출, 🌟다중 연락처(본사/팩스 등) 지원, 네이버 업체 원클릭 저장, 폐업/결번 즉시 신고, 개별 전화 걸기, 네이버 지도 연동 및 클립보드 자동완성, 신뢰도 랭킹 및 더보기]

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🌟 클립보드(복사/붙여넣기) 자동 감지를 위해 추가됨
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🌟 유저 신분 확인용

// =======================================================
// 🗂️ 1-1. 하위 데이터 모델 (개별 연락처 관리용)
// =======================================================
class PhoneEntry {
  String label; // 예: 본사, 현장소장, 팩스 등
  String number;

  PhoneEntry({required this.label, required this.number});

  Map<String, dynamic> toMap() => {'label': label, 'number': number};

  factory PhoneEntry.fromMap(Map<String, dynamic> map) {
    return PhoneEntry(
      label: map['label'] ?? '기본',
      number: map['number'] ?? '',
    );
  }
}

// =======================================================
// 🗂️ 1-2. 데이터 모델 (다중 연락처 배열 탑재)
// =======================================================
class FieldContact {
  String id;
  String name;
  List<PhoneEntry> phones; // 🌟 [고도화] 단일 phone -> 다중 phones 리스트로 변경
  List<String> tags;
  double rating; // 내부 DB 평점
  String memo;
  String status; // 'active' 또는 'closed'
  bool isFromNaver; // 네이버 출신인지 구분하는 꼬리표
  int trustScore; // 네이버 데이터 신뢰도 점수 (100점 만점)

  FieldContact({
    required this.id,
    required this.name,
    required this.phones,
    this.tags = const [],
    this.rating = 0.0,
    this.memo = '',
    this.status = 'active',
    this.isFromNaver = false,
    this.trustScore = 0,
  });

  // 파이어베이스(DB) 데이터를 객체로 변환
  factory FieldContact.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 🌟 [하위 호환성 유지] 과거에 등록된 단일 phone 데이터도 오류 없이 불러옵니다.
    List<PhoneEntry> parsedPhones = [];
    if (data['phones'] != null) {
      parsedPhones = (data['phones'] as List).map((e) => PhoneEntry.fromMap(e)).toList();
    } else if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
      parsedPhones.add(PhoneEntry(label: '기본', number: data['phone']));
    }

    return FieldContact(
      id: doc.id,
      name: data['name'] ?? '',
      phones: parsedPhones,
      tags: List<String>.from(data['tags'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(), // 숫자 형변환 안전처리
      memo: data['memo'] ?? '',
      status: data['status'] ?? 'active',
      isFromNaver: false,
      trustScore: 100, // 우리 DB에 등록된 업체는 검증되었으므로 100점 만점 부여
    );
  }

  // 객체를 DB에 저장할 형태로 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phones': phones.map((p) => p.toMap()).toList(), // 🌟 리스트로 DB에 저장
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
  int _naverSearchStart = 1; // 네이버 추가 5개 불러오기를 위한 페이징 시작점
  int _currentPage = 1;

  // 👑 관리자 권한 검사
  bool get _isSuperAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.email == 'yuseok8052@gmail.com';
  }

  // -----------------------------------------------------
  // 🗺️ 네이버 지도 연동 (주소 압축 고도화 유지)
  // -----------------------------------------------------
  Future<void> _openNaverMap(FieldContact contact) async {
    String shortAddress = '';
    if (contact.memo.isNotEmpty) {
      List<String> parts = contact.memo.split(' ');
      if (parts.length >= 2) {
        shortAddress = "${parts[0]} ${parts[1]}";
      } else {
        shortAddress = contact.memo;
      }
    }

    final String fullQuery = "${contact.name} $shortAddress".trim();
    final encodedQuery = Uri.encodeComponent(fullQuery);
    final url = Uri.parse("https://map.naver.com/v5/search/$encodedQuery");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _showSnackBar("네이버 지도에서 번호를 [복사]한 후 앱으로 돌아오세요.");
    } else {
      _showSnackBar("지도를 열 수 없습니다.", isError: true);
    }
  }

  // -----------------------------------------------------
  // 🌐 네이버 지역 검색 API (신뢰도 채점 유지)
  // -----------------------------------------------------
  Future<void> _searchNaver(String query, {bool isLoadMore = false}) async {
    if (query.trim().isEmpty) {
      setState(() => _naverContacts.clear());
      return;
    }

    setState(() {
      _isNaverSearching = true;
      if (!isLoadMore) {
        _naverSearchStart = 1;
        _naverContacts.clear();
      } else {
        _naverSearchStart += 5;
      }
    });

    try {
      const firebaseFuncUrl = "https://searchnaverproxy-pjaqc5w3jq-du.a.run.app";
      final requestUrl = "$firebaseFuncUrl?query=${Uri.encodeQueryComponent(query)}&start=$_naverSearchStart";

      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        if (items.isEmpty && !isLoadMore) {
          _showSnackBar("네이버 검색 결과가 없습니다.");
        }

        List<FieldContact> newResults = items.map((item) {
          String cleanName = item['title'].toString().replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&amp;', '&');
          String category = item['category']?.toString().split('>').last ?? '일반업체';

          String phoneNum = item['telephone']?.toString().trim() ?? '';
          String address = item['roadAddress']?.toString().trim() ?? item['address']?.toString().trim() ?? '';
          String link = item['link']?.toString().trim() ?? '';

          int score = 0;
          if (address.isNotEmpty) score += 50;
          if (link.isNotEmpty) score += 30;
          if (phoneNum.isNotEmpty) score += 20;

          if (phoneNum.isEmpty) phoneNum = '전화번호 미제공';

          return FieldContact(
            id: 'naver_${item['mapx']}_${item['mapy']}',
            name: cleanName,
            phones: [PhoneEntry(label: '기본', number: phoneNum)], // 🌟 네이버 결과는 '기본' 라벨로 1개 저장
            tags: ['#$category'],
            isFromNaver: true,
            memo: address,
            trustScore: score,
          );
        }).toList();

        setState(() {
          if (isLoadMore) {
            _naverContacts.addAll(newResults);
          } else {
            _naverContacts = newResults;
          }
          _naverContacts.sort((a, b) => b.trustScore.compareTo(a.trustScore));
        });
      } else {
        _showSnackBar("서버 통신 실패 (에러코드: ${response.statusCode})", isError: true);
      }
    } catch (e) {
      _showSnackBar("인터넷 연결 또는 서버 상태를 확인하세요.", isError: true);
    } finally {
      setState(() => _isNaverSearching = false);
    }
  }

  // -----------------------------------------------------
  // 📞 전화 걸기 (비어있는 번호 예외처리 추가)
  // -----------------------------------------------------
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == '전화번호 미제공') {
      _showSnackBar("유효한 전화번호가 아닙니다.", isError: true);
      return;
    }
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

  // -----------------------------------------------------
  // 🚨 상태 변경 (삭제 / 폐업 / 복구) 유지
  // -----------------------------------------------------
  Future<void> _confirmDeleteByAdmin(FieldContact contact) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 8), Text("영구 삭제 (관리자)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
        content: Text("⚠️ 주의\n'${contact.name}' 업체를 DB에서 완전히 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text("영구 삭제", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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

  Future<void> _confirmReportClosed(FieldContact contact) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text("폐업/결번 신고", style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Text("'${contact.name}' 업체를 폐업(결번) 처리하시겠습니까?\n이후로는 다른 직원들이 헛걸음하지 않도록 비활성화됩니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text("신고하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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

  Future<void> _confirmRestoreClosed(FieldContact contact) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(children: [Icon(Icons.restore, color: Colors.green), SizedBox(width: 8), Text("폐업 신고 취소 (복구)", style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Text("'${contact.name}' 업체를 다시 '정상 영업' 상태로 복구하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => Navigator.pop(ctx, true), child: const Text("복구하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) {
      try {
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

    // 클립보드 스캔
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      String numbersOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.length < 20 && numbersOnly.length >= 8) {
        clipboardText = text;
      }
    }

    if (!mounted) return;

    final nameCtrl = TextEditingController(text: initialData?.name ?? '');
    final tagsCtrl = TextEditingController(text: initialData?.tags.join(', ') ?? '');
    final memoCtrl = TextEditingController(text: initialData?.memo ?? '');
    double currentRating = (initialData != null && !initialData.isFromNaver && initialData.rating > 0) ? initialData.rating : 5.0;

    // 🌟 동적으로 늘어나는 연락처 입력 컨트롤러 리스트
    List<TextEditingController> labelCtrls = [];
    List<TextEditingController> numCtrls = [];

    // 동적 필드 추가 함수
    void addPhoneField(String label, String number) {
      labelCtrls.add(TextEditingController(text: label));
      numCtrls.add(TextEditingController(text: number));
    }

    // 🌟 [버그 수정 1] 클립보드 번호가 실제 텍스트창에 들어갔는지 체크하는 변수
    bool isClipboardUsed = false;

    // 초기 데이터 세팅
    if (initialData != null && initialData.phones.isNotEmpty) {
      for (var p in initialData.phones) {
        String numText = p.number == '전화번호 미제공' ? '' : p.number;

        // 🌟 [버그 수정 2] 네이버 번호가 비어있는데 내가 복사해온 번호가 있다면 자동 붙여넣기!
        if (numText.isEmpty && clipboardText.isNotEmpty) {
          numText = clipboardText;
          isClipboardUsed = true;
        }
        addPhoneField(p.label, numText);
      }
    } else {
      // 신규 등록이면 기본 1세트 + 클립보드 번호 세팅
      addPhoneField('기본', clipboardText);
      if (clipboardText.isNotEmpty) isClipboardUsed = true;
    }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌟 [버그 수정 3] 신규 등록이 아니더라도 복사한 번호를 썼다면 파란색 안내창 띄우기
                  if (isClipboardUsed)
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
                  const SizedBox(height: 16),

                  // 🌟 다중 연락처 입력 UI 영역
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📞 연락처 목록", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        const SizedBox(height: 8),

                        // 🌟 리스트 길이만큼 반복해서 텍스트 필드를 그림
                        ...List.generate(labelCtrls.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: labelCtrls[index],
                                    decoration: const InputDecoration(hintText: "구분 (예: 본사, 팩스)", isDense: true, contentPadding: EdgeInsets.all(10)),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: numCtrls[index],
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(hintText: "전화번호", isDense: true, contentPadding: EdgeInsets.all(10)),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                // 🌟 항목이 2개 이상일 때만 삭제 버튼 표시
                                if (labelCtrls.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setDialogState(() {
                                        labelCtrls.removeAt(index);
                                        numCtrls.removeAt(index);
                                      });
                                    },
                                  )
                                else
                                  const SizedBox(width: 40), // 공간 채우기 용도
                              ],
                            ),
                          );
                        }),

                        // 🌟 연락처 추가(+) 버튼
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setDialogState(() => addPhoneField('', ''));
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("연락처 추가"),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text("평점: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(" ${currentRating.toStringAsFixed(1)}점", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Slider(
                    value: currentRating, min: 1.0, max: 5.0, divisions: 8, activeColor: Colors.amber,
                    onChanged: (val) { setDialogState(() => currentRating = val); },
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
                if (nameCtrl.text.trim().isEmpty) {
                  _showSnackBar("상호명은 필수입니다.", isError: true);
                  return;
                }

                // 🌟 등록된 여러 연락처 수집 (빈 칸 필터링)
                List<PhoneEntry> finalPhones = [];
                for (int i = 0; i < labelCtrls.length; i++) {
                  String lbl = labelCtrls[i].text.trim();
                  String num = numCtrls[i].text.trim();
                  if (num.isNotEmpty) {
                    if (lbl.isEmpty) lbl = "연락처 ${i + 1}"; // 라벨을 안 적었으면 자동 부여
                    finalPhones.add(PhoneEntry(label: lbl, number: num));
                  }
                }

                if (finalPhones.isEmpty) {
                  _showSnackBar("최소 1개의 전화번호를 입력해주세요.", isError: true);
                  return;
                }

                List<String> rawTags = tagsCtrl.text.split(',');
                List<String> formattedTags = rawTags.map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => e.startsWith('#') ? e : '#$e').toList();

                final newContactMap = {
                  'name': nameCtrl.text.trim(),
                  'phones': finalPhones.map((p) => p.toMap()).toList(), // 🌟 리스트 형태로 DB 저장
                  'tags': formattedTags,
                  'rating': currentRating,
                  'memo': memoCtrl.text.trim(),
                };

                try {
                  if (initialData != null && !initialData.isFromNaver && initialData.id.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('field_contacts').doc(initialData.id).update(newContactMap);
                    if (mounted) Navigator.pop(ctx);
                    _showSnackBar("성공적으로 수정되었습니다!");
                  } else {
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
    // 🌟 [추가] 화면 가로 크기를 감지하여 모바일/태블릿(600px 미만)인지 판단합니다.
    final bool isMobile = MediaQuery.of(context).size.width < 600;

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
      // 👇👇 🌟 [고도화] 모바일에서는 작고 둥근 아이콘만, PC에서는 글씨 포함 길게 표시 👇👇
      floatingActionButton: isMobile
          ? FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_business, color: Colors.white),
      )
          : FloatingActionButton.extended(
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
                setState(() { _searchQuery = ""; _naverContacts.clear(); _currentPage = 1; });
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
          List<String> searchTerms = _searchQuery.toLowerCase().split(' ').where((s) => s.isNotEmpty).toList();

          internalContacts = internalContacts.where((c) {
            String nameLower = c.name.toLowerCase();
            String memoLower = c.memo.toLowerCase();
            String tagsLower = c.tags.join(' ').toLowerCase();

            return searchTerms.every((term) =>
            nameLower.contains(term) || tagsLower.contains(term) || memoLower.contains(term)
            );
          }).toList();
        }

        // 중복 제거 검사 (여러 번호 중 하나라도 겹치면 중복 처리)
        List<FieldContact> uniqueNaverContacts = _naverContacts.where((naver) {
          bool isDuplicate = internalContacts.any((internal) {
            String naverCleanPhone = naver.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '');
            bool phoneMatch = internal.phones.any((p) => p.number.replaceAll(RegExp(r'[^0-9]'), '') == naverCleanPhone);
            return phoneMatch || internal.name == naver.name;
          });
          return !isDuplicate;
        }).toList();

        List<FieldContact> finalContacts = [...internalContacts, ...uniqueNaverContacts];

        if (finalContacts.isEmpty) {
          return const Center(child: Text("검색 결과가 없습니다.\n우측 하단 버튼을 눌러 등록해주세요.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
        }

        int itemsPerPage = 5;
        int totalPages = (finalContacts.length / itemsPerPage).ceil();
        if (totalPages == 0) totalPages = 1;
        if (_currentPage > totalPages) _currentPage = totalPages;

        List<FieldContact> pageContacts = finalContacts.skip((_currentPage - 1) * itemsPerPage).take(itemsPerPage).toList();

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: pageContacts.length,
                itemBuilder: (context, index) {
                  return _buildContactCard(pageContacts[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left, size: 30), color: _currentPage > 1 ? AppTheme.primaryColor : Colors.grey, onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("$_currentPage / $totalPages", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),),
                  IconButton(icon: const Icon(Icons.chevron_right, size: 30), color: _currentPage < totalPages ? AppTheme.primaryColor : Colors.grey, onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,),
                ],
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: _isNaverSearching ? null : () async {
                    await _searchNaver(_searchQuery, isLoadMore: true);
                    setState(() { _currentPage = ((finalContacts.length + 5) / itemsPerPage).ceil(); });
                  },
                  icon: _isNaverSearching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_circle_outline),
                  label: const Text("네이버 더 검색하기 (추가 5개)", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryColor, side: const BorderSide(color: AppTheme.primaryColor)),
                ),
              ),
          ],
        );
      },
    );
  }

  // 📇 업체 카드 UI (🌟 다중 연락처 리스트 및 개별 통화 버튼 출력)
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 업체명 라벨
            Text("업체명 : ${contact.name}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isClosed ? Colors.grey : AppTheme.textMain, decoration: isClosed ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 8),

            // 신뢰도 및 별점
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
            const SizedBox(height: 12),

            // 🌟 다중 연락처 박스 (개별 전화걸기 아이콘 탑재)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isClosed ? Colors.grey[300] : Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: contact.phones.map((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: isClosed ? Colors.grey[400] : Colors.blue[300], borderRadius: BorderRadius.circular(4)),
                          child: Text(p.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p.number, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isClosed ? Colors.grey : AppTheme.primaryColor)),
                        ),
                        // 🌟 개별 번호 전화걸기 아이콘
                        InkWell(
                          onTap: isClosed ? null : () => _makePhoneCall(p.number),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: isClosed ? Colors.grey : Colors.green,
                            child: const Icon(Icons.call, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(spacing: 6, children: contact.tags.map((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isClosed ? Colors.grey[300] : AppTheme.primaryLight, borderRadius: BorderRadius.circular(4)), child: Text(tag, style: TextStyle(fontSize: 11, color: isClosed ? Colors.grey[600] : AppTheme.primaryColor)))).toList()),

            if (contact.memo.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text("주소/메모 : ${contact.memo}", style: TextStyle(fontSize: 12, color: Colors.grey[600]))),

            // 🌟 하단 조작 버튼들 (전화걸기 버튼은 위로 올라갔으므로 제거됨)
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isClosed) ...[
                    const Text("폐업/결번", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    if (!isNaver) IconButton(tooltip: "폐업 신고 취소 (정상 복구)", icon: const Icon(Icons.restore, color: Colors.green, size: 28), onPressed: () => _confirmRestoreClosed(contact)),
                    if (_isSuperAdmin) IconButton(tooltip: "영구 삭제 (관리자)", icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28), onPressed: () => _confirmDeleteByAdmin(contact)),
                  ] else ...[
                    if (!isNaver && _isSuperAdmin) IconButton(tooltip: "영구 삭제 (관리자)", icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28), onPressed: () => _confirmDeleteByAdmin(contact)),
                    if (!isNaver) IconButton(tooltip: "정보 수정", icon: const Icon(Icons.edit_note, color: Colors.blue, size: 30), onPressed: () => _showAddDialog(initialData: contact)),
                    if (!isNaver) IconButton(tooltip: "폐업/결번 신고", icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28), onPressed: () => _confirmReportClosed(contact)),
                    if (isNaver) IconButton(tooltip: "네이버 지도 보기 (전화번호 찾기)", icon: const Icon(Icons.map_outlined, color: Colors.green, size: 28), onPressed: () => _openNaverMap(contact)),
                    if (isNaver) IconButton(tooltip: "우리 DB로 저장", icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 28), onPressed: () => _showAddDialog(initialData: contact)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}