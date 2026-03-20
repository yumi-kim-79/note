//영업 정보 신규건물 접수 페이지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/daum_postcode_stub.dart' if (dart.library.html) '../../utils/daum_postcode_web.dart';
import 'package:url_launcher/url_launcher.dart';

class SalesInquiryListPage extends StatefulWidget {
  const SalesInquiryListPage({super.key});

  @override
  State<SalesInquiryListPage> createState() => _SalesInquiryListPageState();
}

// 🌟 [추가] 영업부 전체 실시간 푸시 알림 발송 엔진
Future<void> _sendNotificationToSalesDept(String bName, String receiptNo) async {
  try {
    // 1. '영업부' 소속 직원들만 싹 찾아냅니다.
    final salesUsers = await FirebaseFirestore.instance
        .collection('users')
        .where('department', isEqualTo: '영업부')
        .get();

    if (salesUsers.docs.isEmpty) return;

    // 2. 한 번에 여러 명에게 알림을 쏘기 위해 '배치(Batch)' 작업을 준비합니다.
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var userDoc in salesUsers.docs) {
      // 각 영업부 직원의 알림장(notifications)에 배달지를 넣습니다.
      final notiRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notiRef, {
        'targetUid': userDoc.id,
        'title': '🚨 신규 영업 문의 접수',
        'body': '[$receiptNo] $bName 건이 신규 접수되었습니다.',
        'type': 'sales_inquiry', // 나중에 알림 클릭 시 이동할 표식
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. 일괄 발송!
    await batch.commit();
    debugPrint("📢 영업부 전체 알림 발송 완료 (${salesUsers.docs.length}명)");
  } catch (e) {
    debugPrint("❌ 알림 발송 중 오류: $e");
  }
}

class _SalesInquiryListPageState extends State<SalesInquiryListPage> {
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF4A89DC);
  final Color tableHeaderColor = const Color(0xFF8B95A1);

  // 👇 🌟 [수술 1] 스위치를 키보드 충격에도 끄떡없는 '클래스 전역 변수(금고)'로 완전히 피신시킵니다!
  bool _isSearchingAddress = false;

  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  Map<String, dynamic>? _currentMolitRawData;
  int _registerPage = 1;

  final _bNameCtrl = TextEditingController();
  final _bAddressCtrl = TextEditingController();
  final _bInfoCtrl = TextEditingController();
  final _callerNameCtrl = TextEditingController();
  final _callerRankCtrl = TextEditingController();
  final _callerPhoneCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  bool get _isSuperAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.email == 'yuseok8052@gmail.com';
  }

  Future<void> _deleteInquiry(String docId, String bName, {BuildContext? dialogCtx}) async {
    bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🌟 모서리 둥글게
          title: const Text("영구 삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Text("'$bName' 접수 내역을 완전히 삭제하시겠습니까?\n(접수 번호는 복구되지 않습니다)"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소", style: TextStyle(color: Colors.grey))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("삭제", style: TextStyle(color: Colors.white))),
          ],
        )
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('sales_inquiries').doc(docId).delete();
      if (mounted) {
        if (dialogCtx != null) Navigator.pop(dialogCtx);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("안전하게 삭제되었습니다.")));
      }
    }
  }

  List<dynamic> _currentFloorList = [];

  // 🌟 [추가] 매립된 화면에서 결과를 던져주면 팝업을 띄우지 않고 바로 받습니다!
  Future<void> _searchAddressAndFetchMolit({Map<String, String>? embeddedResult}) async {
    try {
      Map<String, String>? result = embeddedResult ?? await searchAddress();
      if (result == null) return;

      String address = result['address'] ?? '';
      String bName = result['buildingName'] ?? '';

      setState(() {
        _bAddressCtrl.text = address;
        if (_bNameCtrl.text.trim().isEmpty && bName.isNotEmpty) {
          _bNameCtrl.text = bName;
        }
        _bInfoCtrl.text = "국토부 데이터(표제부/층별/정화조) 통합 연동 중...";
      });

      final kakaoRes = await http.get(
        Uri.parse("https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(address)}"),
        headers: {"Authorization": "KakaoAK e1fc7f4a7281b14f7c8be88f6e146462"},
      );
      final kakaoData = json.decode(utf8.decode(kakaoRes.bodyBytes));
      var addrData = kakaoData['documents'][0]['address'];

      String sigunguCd = addrData['b_code'].substring(0, 5);
      String bjdongCd = addrData['b_code'].substring(5, 10);
      String bun = addrData['main_address_no'].toString().padLeft(4, '0');
      String ji = addrData['sub_address_no'].toString().isEmpty ? "0000" : addrData['sub_address_no'].toString().padLeft(4, '0');

      // 🌟 [핵심] 일반 대지인지 파악하고 주건축물(0)만 타겟팅 (이전 단계 버그 픽스 유지)
      String platGbCd = (addrData['mountain_yn'] == 'Y') ? '1' : '0';
      final baseUrl = "https://asia-northeast3-sm-sales-note-2026.cloudfunctions.net/fetchMolitData";
      final commonParams = "sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&platGbCd=$platGbCd&bun=$bun&ji=$ji&mainAtchGbCd=0&numOfRows=100&pageNo=1";

      final results = await Future.wait([
        http.get(Uri.parse("$baseUrl?$commonParams&operation=getBrTitleInfo")),
        http.get(Uri.parse("$baseUrl?$commonParams&operation=getBrFlrOulnInfo")),
        http.get(Uri.parse("$baseUrl?$commonParams&operation=getBrWclfInfo")),
      ]);

      if (results[0].statusCode == 200) {
        final titleItem = json.decode(utf8.decode(results[0].bodyBytes))['response']?['body']?['items']?['item'];
        final floorItems = json.decode(utf8.decode(results[1].bodyBytes))['response']?['body']?['items']?['item'];
        final sewerItem = json.decode(utf8.decode(results[2].bodyBytes))['response']?['body']?['items']?['item'];

        var item = (titleItem is List) ? titleItem[0] : titleItem;
        if (item == null) throw "해당 주소의 표제부 정보가 없습니다.";

        if (sewerItem != null) {
          item['sewer_info'] = (sewerItem is List) ? sewerItem[0] : sewerItem;
        }

        int parseIntSafely(dynamic val) {
          if (val == null) return 0;
          if (val is int) return val;
          return int.tryParse(val.toString()) ?? 0;
        }

        int hhldCnt = parseIntSafely(item['hhldCnt']);
        int fmlyCnt = parseIntSafely(item['fmlyCnt']);
        int hoCnt = parseIntSafely(item['hoCnt']);
        int totalHousehold = hhldCnt + fmlyCnt + hoCnt;

        int autoParking = parseIntSafely(item['indrAutoUtcnt']) + parseIntSafely(item['oudrAutoUtcnt']);
        int mechParking = parseIntSafely(item['indrMechUtcnt']) + parseIntSafely(item['oudrMechUtcnt']);
        int totalParking = autoParking + mechParking;

        String approvalDate = _formatDate(item['useAprDay']);

        setState(() {
          _currentMolitRawData = item;

          if (floorItems is List) _currentFloorList = List.from(floorItems);
          else if (floorItems != null) _currentFloorList = [floorItems];
          else _currentFloorList = [];

          // 🌟 [정렬 고도화] 옥탑 -> 지상 최고층 -> 지상 1층 -> 지하 1층 -> 지하 최하층 순서로 정렬
          _currentFloorList.sort((a, b) {
            int getSortValue(dynamic f) {
              if (f == null) return 0;
              // flrGbCd: 10(지하), 20(지상), 30(옥탑)
              int gbCd = int.tryParse(f['flrGbCd']?.toString() ?? '0') ?? 0;
              int no = int.tryParse(f['flrNo']?.toString() ?? '0') ?? 0;
              String flrName = f['flrNoNm']?.toString() ?? "";

              // 코드가 없을 경우 글자를 보고 판단하는 강력한 안전장치
              if (gbCd == 0) {
                if (flrName.contains("옥탑")) gbCd = 30;
                else if (flrName.contains("지하")) gbCd = 10;
                else gbCd = 20;
              }

              if (gbCd == 30) return 1000 + no; // 옥탑 (예: 옥탑1층 = 1001점)
              if (gbCd == 20) return no;        // 지상 (예: 지상8층 = 8점)
              if (gbCd == 10) return -no;       // 지하 (예: 지하1층 = -1점, 지하2층 = -2점)
              return 0;
            }
            return getSortValue(b).compareTo(getSortValue(a)); // 높은 점수가 위로 가도록 내림차순 정렬
          });

          // 🌟 줄 간격과 오와 열을 맞춘 깔끔한 보고서 형태
          _bInfoCtrl.text =
              "▪ 사용승인일 :  $approvalDate\n"
              "▪ 총 호실수 :  $totalHousehold호실 (세대 $hhldCnt / 가구 $fmlyCnt / 호 $hoCnt)\n"
              "▪ 면적 정보 :  연면적 ${item['totArea'] ?? '0'} ㎡ / 대지면적 ${item['platArea'] ?? '0'} ㎡\n"
              "▪ 건축 규모 :  지상 ${item['grndFlrCnt'] ?? '0'}층 / 지하 ${item['ugrndFlrCnt'] ?? '0'}층\n"
              "▪ 승강기수 :  총 ${item['rideUseElvtCnt'] ?? '0'}대\n"
              "▪ 주차 대수 :  총 $totalParking대 (자주식 ${autoParking}대 / 기계식 ${mechParking}대)";
        });
      }
    } catch (e) {
      setState(() => _bInfoCtrl.text = "연동 실패: $e");
    }
  }

  Future<void> _showInquiryDialog({DocumentSnapshot? doc}) async {
    bool isEdit = doc != null;
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isAuthor = !isEdit || (doc['authorUid'] == currentUser?.uid);

    String currentReceiptNo = "";

    // 👇 🌟 [수술 2-1] 팝업을 열자마자 내 직책과 이름을 서버에서 잽싸게 가져옵니다.
    String myFullName = '담당자';
    if (currentUser != null) {
      try {
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          var uData = userDoc.data()!;
          String rank = uData['rank'] ?? '';
          String name = uData['name'] ?? '';
          if (name.isEmpty && currentUser.email != null) name = currentUser.email!.split('@').first;
          myFullName = "$rank $name".trim();
        }
      } catch (e) {
        debugPrint("내 정보 로드 실패: $e");
      }
    }

    // 👇 🌟 [수술 2-2] 상태 리스트를 4개로 간소화하고, 실명제 메뉴를 자동으로 꽂아 넣습니다!
    String myCompleteStatus = '접수완료($myFullName)';
    List<String> _statusOptions = [
      '신규접수',
      '접수완료($myFullName)',
      '계약완료($myFullName)',
      '보류/드랍($myFullName)'
    ];
    String _selectedStatus = '신규접수';

    if (isEdit) {
      var data = doc.data() as Map<String, dynamic>;
      currentReceiptNo = data['receiptNo'] ?? '';

      _selectedStatus = data['status'] ?? '신규접수';

      // 🌟 남이 이미 접수한 건(예: 접수완료(대리 김철수))을 열었을 때 메뉴가 깨지지 않도록, 남의 상태도 선택지에 안전하게 추가해줍니다.
      if (!_statusOptions.contains(_selectedStatus)) {
        _statusOptions.insert(1, _selectedStatus);
      }

      _bNameCtrl.text = data['buildingName'] ?? '';
      _bAddressCtrl.text = data['address'] ?? '';
      _bInfoCtrl.text = data['buildingInfo'] ?? '';

      if (_bAddressCtrl.text.isNotEmpty) {
        // 🌟 1. 기존의 작은 스낵바 대신 화면 중앙을 가리는 고급 로딩창 띄우기
        showDialog(
          context: context,
          barrierDismissible: false, // 로딩 중 다른 곳 터치 방지
          builder: (BuildContext context) {
            return const Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("국토부 정보를 불러오고 있습니다.\n다소 시간이 걸릴 수 있습니다.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.5)),
                  ],
                ),
              ),
            );
          },
        );

        await _fetchMolitOnly(_bAddressCtrl.text);

        // 🌟 2. 데이터 가져오기가 끝나면 로딩창을 닫기
        if (mounted) Navigator.pop(context);
      }

      _callerNameCtrl.text = data['callerName'] ?? '';
      _callerRankCtrl.text = data['callerRank'] ?? '';
      _callerPhoneCtrl.text = data['callerPhone'] ?? '';
      _memoCtrl.text = data['memo'] ?? '';
    } else {
      _currentMolitRawData = null;
      _currentFloorList = [];

      _bNameCtrl.clear(); _bAddressCtrl.clear(); _bInfoCtrl.clear();
      _callerNameCtrl.clear(); _callerRankCtrl.clear(); _callerPhoneCtrl.clear(); _memoCtrl.clear();
    }

    if (!mounted) return;

    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                bool isMobileDialog = MediaQuery.of(context).size.width < 600;

                return AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  insetPadding: EdgeInsets.all(isMobileDialog ? 16 : 24),
                  title: Row(
                    children: [
                      Icon(isEdit ? Icons.manage_search : Icons.add_call, color: primaryNavy),
                      const SizedBox(width: 8),
                      Expanded(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              // 🌟 [수술 1] 제목에서 "읽기 전용"이라는 문구를 뺐습니다. (누구나 수정 가능하니까요!)
                              child: Text(isEdit ? "문의 상세 및 수정 [$currentReceiptNo]" : "신규 문의 접수", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
                          )
                      ),
                      // 🌟 [수술 2] "작성자만 수정 가능" 이라는 빨간 경고 딱지도 삭제했습니다.
                    ],
                  ),
                  content: Container(
                    width: double.maxFinite,
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),

                          if (isMobileDialog) ...[
                            // 🌟 [수술 3] readOnly 옵션을 풀어 누구나 글씨를 고칠 수 있게 했습니다!
                            _buildTextField("건물명 (단지명)", _bNameCtrl, Icons.domain, readOnly: false),
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, height: 48, child: _buildKakaoButton(true, () { // 누구나 카카오 검색 가능
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (fullscreenCtx) => Scaffold(
                                        appBar: AppBar(title: const Text("📍 카카오 주소 검색", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black87), elevation: 1),
                                        body: buildDaumPostcodeWidget(
                                            onComplete: (result) async {
                                              Navigator.pop(fullscreenCtx);
                                              await _searchAddressAndFetchMolit(embeddedResult: result);
                                              setDialogState(() {});
                                            }
                                        ),
                                      )
                                  )
                              );
                            })),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(flex: 3, child: _buildTextField("건물명 (단지명)", _bNameCtrl, Icons.domain, readOnly: false)),
                                const SizedBox(width: 12),
                                Expanded(flex: 2, child: SizedBox(height: 48, child: _buildKakaoButton(true, () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (fullscreenCtx) => Scaffold(
                                            appBar: AppBar(title: const Text("📍 카카오 주소 검색", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black87), elevation: 1),
                                            body: buildDaumPostcodeWidget(
                                                onComplete: (result) async {
                                                  Navigator.pop(fullscreenCtx);
                                                  await _searchAddressAndFetchMolit(embeddedResult: result);
                                                  setDialogState(() {});
                                                }
                                            ),
                                          )
                                      )
                                  );
                                }))),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildTextField("상세 주소 (검색 시 자동 입력)", _bAddressCtrl, Icons.location_on, readOnly: false),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text("🏢 건축물대장 제원", style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF475569), fontSize: isMobileDialog ? 18 : 20, height: 1.3)),
                              ),
                              if (_currentMolitRawData != null)
                                Container(
                                  margin: const EdgeInsets.only(left: 12),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() => _registerPage = 1);
                                      _showFullRegisterPopup(_currentMolitRawData!);
                                    },
                                    icon: const Icon(Icons.find_in_page, size: 16),
                                    label: Text(isMobileDialog ? "건대장 보기" : "건대장 전체보기"),
                                    style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.symmetric(horizontal: isMobileDialog ? 10 : 16, vertical: 10), elevation: 0),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _bInfoCtrl, maxLines: null, readOnly: false,
                            style: const TextStyle(fontSize: 14, height: 1.6, letterSpacing: 0.5),
                            decoration: InputDecoration(
                              hintText: "카카오 주소 검색 시 자동으로 제원 정보가 입력됩니다.", filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.all(16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4A89DC), width: 1.5)),
                            ),
                          ),

                          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1, color: Color(0xFFE2E8F0))),

                          if (isMobileDialog) ...[
                            _buildTextField("문의자 성함", _callerNameCtrl, Icons.person, readOnly: false),
                            const SizedBox(height: 12),
                            _buildTextField("직책 (예: 대표,회장 등)", _callerRankCtrl, Icons.badge, readOnly: false),
                            const SizedBox(height: 12),
                            _buildPhoneField("연락처 (번호)", _callerPhoneCtrl, readOnly: false)
                          ] else ...[
                            Row(
                              children: [
                                Expanded(child: _buildTextField("문의자 성함", _callerNameCtrl, Icons.person, readOnly: false)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTextField("직책 (예: 대표,회장,총무 등)", _callerRankCtrl, Icons.badge, readOnly: false)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildPhoneField("연락처 (번호)", _callerPhoneCtrl, readOnly: false)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),

                          if (isEdit) ...[
                            const Text("📌 영업 진행 상태 (공유 뱃지 연동)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 15)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50, // 누구나 활성화된 색상으로 보이게 함
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedStatus,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4A89DC)),
                                  // 👇 🌟 [방어 1] 좁은 모바일 화면에서 드롭다운 글씨가 길면 '...'으로 예쁘게 생략하여 팝업창 찢어짐을 방지합니다.
                                  items: _statusOptions.map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(
                                          status,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis // 👈 넘치면 자동으로 ... 처리
                                      )
                                  )).toList(),
                                  // 🌟 [수술 4] 작성자 제한 없이 누구나 드롭다운을 조작할 수 있게 잠금 완전 해제!
                                  onChanged: (val) {
                                    setDialogState(() {
                                      _selectedStatus = val!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          const Text("📝 상세 상담 내용 및 영업 메모", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 15)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _memoCtrl, maxLines: null, minLines: 5, keyboardType: TextInputType.multiline, readOnly: false, // 누구나 메모 수정 가능
                            decoration: InputDecoration(
                              hintText: "고객의 니즈, 현재 업체의 불만사항, 견적 요청 내용 등을 상세히 적어주세요.",
                              filled: true, fillColor: Colors.amber.shade50.withOpacity(0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4A89DC), width: 2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  actions: [
                    // 👇 🌟 [핵심 수술] 삭제 버튼: 오직 최초 작성자(isAuthor) 이거나 슈퍼관리자(대표님)일 때만 노출!
                    if (isEdit && (isAuthor || _isSuperAdmin))
                      TextButton.icon(
                        onPressed: () => _deleteInquiry(doc!.id, _bNameCtrl.text, dialogCtx: ctx),
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        label: const Text("기록 삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      )
                    else
                      const SizedBox.shrink(),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))),
                        const SizedBox(width: 12),
                        // 👇 🌟 [핵심 수술] 저장 버튼: 누구나 저장할 수 있도록 자물쇠 제거!
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: safetyBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (_bNameCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("건물명은 필수입니다."))); return;
                            }

                            final data = {
                              'buildingName': _bNameCtrl.text, 'address': _bAddressCtrl.text, 'buildingInfo': _bInfoCtrl.text,
                              'callerName': _callerNameCtrl.text, 'callerRank': _callerRankCtrl.text, 'callerPhone': _callerPhoneCtrl.text,
                              'memo': _memoCtrl.text,
                              'status': _selectedStatus,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (isEdit) {
                              // [수정 모드] 기존 데이터 업데이트
                              await FirebaseFirestore.instance.collection('sales_inquiries').doc(doc!.id).update(data);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정되었습니다.")));
                            } else {
                              // [신규 등록 모드] 접수번호 생성 및 저장
                              String yy = (DateTime.now().year % 100).toString();
                              String newReceiptNo = '$yy-0001';

                              var qs = await FirebaseFirestore.instance.collection('sales_inquiries')
                                  .orderBy('createdAt', descending: true)
                                  .limit(1)
                                  .get();

                              if (qs.docs.isNotEmpty) {
                                var lastData = qs.docs.first.data() as Map<String, dynamic>;
                                if (lastData.containsKey('receiptNo')) {
                                  String lastNo = lastData['receiptNo'];
                                  if (lastNo.startsWith('$yy-')) {
                                    int nextNum = int.parse(lastNo.split('-')[1]) + 1;
                                    newReceiptNo = '$yy-${nextNum.toString().padLeft(4, '0')}';
                                  }
                                }
                              }

                              // 🌟 [삭제] 전화번호/이메일을 가져오던 구형 로직(finalAuthorName) 폐기 완료

                              data['receiptNo'] = newReceiptNo;
                              data['status'] = '신규접수';
                              data['createdAt'] = FieldValue.serverTimestamp();
                              data['authorUid'] = currentUser?.uid ?? '';
                              // 👇 🌟 [명찰 고도화 수술] 팝업 열 때 이미 users DB에서 가져온 "직책 이름(myFullName)"을 명찰로 딱 붙여줍니다!
                              data['authorName'] = myFullName.isNotEmpty ? myFullName : '영업 담당자';

                              // 1. DB 저장
                              await FirebaseFirestore.instance.collection('sales_inquiries').add(data);

                              // 2. 🌟 [영업부 전체 알림 발송]
                              await _sendNotificationToSalesDept(_bNameCtrl.text, newReceiptNo);

                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("접수 성공 (접수번호: $newReceiptNo) 및 영업부 알림 완료")));
                            }

                            if (mounted) Navigator.pop(ctx);
                          },
                          child: Text(isEdit ? "수정 저장" : "접수 등록", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                        )
                      ],
                    )
                  ],
                );
              }
          );
        }
    );
  }

  // 🌟 카카오 버튼을 누르면 스위치를 켜주도록 매개변수 변경
  Widget _buildKakaoButton(bool isAuthor, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: isAuthor ? onPressed : null,
      icon: const Icon(Icons.search, color: Colors.black87, size: 18),
      label: const Text("카카오 주소 검색", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
      ),
    );
  }

  // 🌟 [수정 1] 입력창 UI 고도화 (라벨 짤림 방지 및 여백 확보)
  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {int? maxLines = 1, bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        // 👇 🌟 [핵심 해결] 여러 줄(메모장)일 때만 위로 올리고, 1줄일 때는 정중앙에 둬서 글씨 윗부분이 짤리는 현상 원천 차단!
        alignLabelWithHint: maxLines == null || maxLines > 1,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: (maxLines ?? 1) == 1
            ? Icon(icon, size: 20, color: Colors.grey.shade400)
            : Padding(padding: const EdgeInsets.only(bottom: 40), child: Icon(icon, size: 20, color: Colors.grey.shade400)),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
        // 👇 🌟 [핵심 해결] vertical 여백을 14 -> 16으로 살짝 늘려서 글씨가 숨쉴 수 있는 공간 확보
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4A89DC), width: 1.5)),
      ),
    );
  }

  // 🌟 전화 걸기 버튼이 포함된 특수 텍스트 필드
  Widget _buildPhoneField(String label, TextEditingController ctrl, {bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      keyboardType: TextInputType.phone,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.phone, size: 20, color: Colors.grey.shade400),
        // 🌟 여기에 둥근 초록색 전화 버튼을 달아줍니다.
        suffixIcon: Padding(
          padding: const EdgeInsets.all(6.0),
          child: ElevatedButton(
            onPressed: () async {
              final phone = ctrl.text.replaceAll(RegExp(r'[^0-9]'), ''); // 숫자만 추출
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("연락처를 먼저 입력해주세요.")));
                return;
              }
              final Uri launchUri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("전화를 걸 수 없는 기기입니다.")));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // 초록색 통화 버튼
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              elevation: 0,
            ),
            child: const Icon(Icons.call, size: 18),
          ),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  // =================================================================
  // 📱 [모바일/태블릿 전용] 대기업 앱 스타일의 고급스러운 카드 디자인
  // =================================================================
  Widget _buildMobileCardItem(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String receiptNo = data['receiptNo'] ?? '-';
    Timestamp? ts = data['createdAt'];
    String dateStr = ts != null ? DateFormat('yy.MM.dd').format(ts.toDate()) : '-';
    String callerRank = data['callerRank'] ?? '';
    String rankStr = callerRank.isNotEmpty ? "($callerRank)" : "";
    String memo = data['memo'] ?? '';
    String bName = data['buildingName'] ?? '이름없음';

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // 🌟 카드 간격 넓힘
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // 🌟 부드러운 모서리
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)), // 🌟 은은한 그림자
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20), // 🌟 내부 여백 넉넉하게
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(6)),
                  child: Text(receiptNo, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(bName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
                // 👇 🌟 [수술 3-1] 우측 상단 뱃지 텍스트 줄바꿈 적용 (괄호 앞에서 줄바꿈)
                // 👇 🌟 [방어 2] 뱃지를 'Flexible'이라는 유연한 스펀지로 감싸서, 공간이 부족하면 알아서 찌그러지거나 글씨를 줄이도록 세팅했습니다!
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: safetyBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      (data['status'] ?? '신규접수').replaceAll('(', '\n('),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: safetyBlue, fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
                      maxLines: 2, // 최대 2줄까지만 허용
                      overflow: TextOverflow.ellipsis, // 공간 모자라면 ... 처리
                    ),
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),

            // 👇 🌟 [수술 3-2] 모바일에서도 가독성을 위해 접수일과 접수인을 별도 라인으로 분리하고, 직책/이름을 줄바꿈 처리했습니다.
            _buildMobileInfoRow(Icons.calendar_today, "접수일", dateStr),
            _buildMobileInfoRow(Icons.assignment_ind, "접수인", data['authorName'] ?? '담당자 미정'),
            _buildMobileInfoRow(Icons.location_on, "주소", data['address'] ?? ''),
            _buildMobileInfoRow(Icons.person, "문의자", "${data['callerName'] ?? ''}$rankStr  |  ${data['callerPhone'] ?? ''}"),
            if (memo.isNotEmpty) _buildMobileInfoRow(Icons.edit_note, "메모", memo.replaceAll('\n', ' '), maxLines: 2),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showInquiryDialog(doc: doc),
                    icon: const Icon(Icons.manage_search, color: Colors.white, size: 18),
                    label: const Text("상세 열기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: safetyBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                  ),
                ),
                if (_isSuperAdmin) ...[
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _deleteInquiry(doc.id, bName),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: const Icon(Icons.delete, size: 22),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  // 🌟 [UI 고도화] 라벨의 너비를 넉넉하게 주어 글씨가 짤리지 않게 방어
  Widget _buildMobileInfoRow(IconData icon, String label, String value, {int maxLines = 1}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          SizedBox(width: 65, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;
    bool isSuperSmall = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("영업 관리 > 신규 문의 접수", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
        backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black87), elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('sales_inquiries').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {

            int totalCount = 0;
            List<QueryDocumentSnapshot> docs = [];

            if (snapshot.hasData) {
              docs = snapshot.data!.docs.where((doc) {
                if (_searchQuery.isEmpty) return true;

                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                // 1. 기본 텍스트 정보 (건물명, 문의자, 주소)
                String bName = (data['buildingName'] ?? '').toString();
                String cName = (data['callerName'] ?? '').toString();
                String addr = (data['address'] ?? '').toString();

                // 2. 📅 날짜 검색용 데이터 생성 (여러 형식을 하나의 긴 문자열로 합침)
                String dateSearchStr = "";
                if (data['createdAt'] != null) {
                  DateTime dt = (data['createdAt'] as Timestamp).toDate();
                  // 대표님이 요청하신 모든 포맷을 다 때려넣습니다.
                  // '26.03.16', '3.16', '3/16', '3월 16일', '03.16' 등
                  dateSearchStr = "${DateFormat('yy.MM.dd').format(dt)} "
                      "${DateFormat('M.d').format(dt)} "
                      "${DateFormat('M/d').format(dt)} "
                      "${DateFormat('M월 d일').format(dt)} "
                      "${DateFormat('MM.dd').format(dt)} "
                      "${DateFormat('MM/dd').format(dt)}";
                }

                // 3. 🔍 통합 검색 (모든 조건 중 하나라도 맞으면 통과!)
                return bName.contains(_searchQuery) ||
                    cName.contains(_searchQuery) ||
                    addr.contains(_searchQuery) || // 🌟 주소 검색 추가
                    dateSearchStr.contains(_searchQuery); // 🌟 날짜 검색 추가
              }).toList();

              totalCount = docs.length;
            }

            int totalPages = (totalCount / _itemsPerPage).ceil();
            if (totalPages == 0) totalPages = 1;
            if (_currentPage > totalPages) _currentPage = totalPages;

            List<QueryDocumentSnapshot> pageDocs = docs.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

            return Padding(
              padding: EdgeInsets.all(isSuperSmall ? 16.0 : 24.0), // 🌟 모바일 기본 여백 살짝 조절
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSuperSmall) ...[
                    Text("신규 문의 접수 대장 (총 $totalCount건)", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showInquiryDialog(),
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text("신규 문의 접수", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: safetyBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16), // 버튼 큼지막하게
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: FittedBox(
                                alignment: Alignment.centerLeft, fit: BoxFit.scaleDown,
                                child: Text("신규 문의 접수 대장 (총 $totalCount건)", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))
                            )
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showInquiryDialog(),
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text("신규 문의 접수", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: safetyBlue, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                        )
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  isSuperSmall
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("검색어", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity, height: 48,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() { _searchQuery = val; _currentPage = 1; }),
                            decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500), contentPadding: const EdgeInsets.symmetric(vertical: 14), hintText: "건물명 또는 문의자 검색", hintStyle: TextStyle(color: Colors.grey.shade400))
                        ),
                      ),
                    ],
                  )
                      : Row(
                    children: [
                      const Text("검색어  |  ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      Container(
                        width: 300, height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() { _searchQuery = val; _currentPage = 1; }),
                            decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500), contentPadding: const EdgeInsets.symmetric(vertical: 12), hintText: "건물명 또는 문의자 검색", hintStyle: TextStyle(color: Colors.grey.shade400))
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : pageDocs.isEmpty
                        ? const Center(child: Text("접수된 문의 내역이 없습니다.", style: TextStyle(color: Colors.grey)))
                        : isMobile
                        ? ListView.builder(
                      itemCount: pageDocs.length,
                      itemBuilder: (context, index) => _buildMobileCardItem(pageDocs[index]),
                    )
                        : LayoutBuilder(
                        builder: (context, constraints) {
                          double minWidth = 1100;
                          double actualWidth = math.max(constraints.maxWidth, minWidth);

                          return Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: actualWidth,
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), // 🌟 테두리 부드럽게
                                  child: ClipRRect( // 🌟 모서리 안쪽 내용물 둥글게 자르기
                                    borderRadius: BorderRadius.circular(12),
                                    child: Column(
                                      children: [
                                        Container(
                                          color: tableHeaderColor,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: const Row(
                                            children: [
                                              // 👇 🌟 [수술 2] PC 화면: 표가 찌그러지지 않도록 가로 비율(flex)을 재조정하고, '접수인' 칸을 추가했습니다.
                                              Expanded(flex: 2, child: Text("접수번호", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(flex: 2, child: Text("접수일", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(flex: 3, child: Text("단지명 (건물명)", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(flex: 3, child: Text("건물 주소", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(flex: 2, child: Text("문의자 / 연락처", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(flex: 2, child: Text("진행 상태", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(flex: 3, child: Text("비고 (메모)", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                              Expanded(flex: 2, child: Text("접수인", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))), // 🌟 추가됨
                                              Expanded(flex: 2, child: Text("관리", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.separated(
                                              itemCount: pageDocs.length,
                                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                                              itemBuilder: (context, index) {
                                                var data = pageDocs[index].data() as Map<String, dynamic>;
                                                String receiptNo = data['receiptNo'] ?? '-';
                                                Timestamp? ts = data['createdAt'];
                                                String dateStr = ts != null ? DateFormat('yy.MM.dd').format(ts.toDate()) : '-';
                                                String callerRank = data['callerRank'] ?? '';
                                                String rankStr = callerRank.isNotEmpty ? "($callerRank)" : "";
                                                String memo = data['memo'] ?? '';

                                                return InkWell(
                                                  hoverColor: Colors.blue.shade50,
                                                  onTap: () => _showInquiryDialog(doc: pageDocs[index]),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    child: Row(
                                                      children: [
                                                        // 👇 🌟 [수술 3] 헤더(제목)와 1:1로 오와 열이 정확하게 맞도록 데이터 칸의 flex도 동일하게 맞춰줍니다.
                                                        Expanded(flex: 2, child: Text(receiptNo, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryNavy))),
                                                        Expanded(flex: 2, child: Text(dateStr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                                                        Expanded(flex: 3, child: Text(data['buildingName'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87))),
                                                        Expanded(flex: 3, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(data['address'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis))),
                                                        Expanded(flex: 2, child: Text("${data['callerName'] ?? ''}$rankStr\n${data['callerPhone'] ?? ''}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                                                        // 👇 🌟 [방어 3] PC나 태블릿에서도 폭이 좁아지면 칸을 벗어나지 않게 maxLines와 ellipsis(말줄임표)를 꽉 채워 넣었습니다.
                                                        Expanded(flex: 2, child: Text((data['status'] ?? '신규접수').replaceAll('(', '\n('), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: safetyBlue, height: 1.3))),
                                                        Expanded(flex: 3, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(memo.replaceAll('\n', ' '), textAlign: TextAlign.left, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)))),

                                                        // 접수자 (가독성 유지 + 넘침 방지)
                                                        Expanded(flex: 2, child: Text((data['authorName'] ?? '담당자 미정').replaceFirst(' ', '\n'), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3))),

                                                        Expanded(
                                                            flex: 2,
                                                            child: Row( // 👈 기존의 [열기/삭제] 관리 버튼 시작 부분
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                SizedBox(
                                                                  height: 30,
                                                                  child: ElevatedButton(
                                                                    onPressed: () => _showInquiryDialog(doc: pageDocs[index]),
                                                                    style: ElevatedButton.styleFrom(backgroundColor: safetyBlue, padding: const EdgeInsets.symmetric(horizontal: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                                                    child: const Text("열기", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                ),
                                                                if (_isSuperAdmin) ...[
                                                                  const SizedBox(width: 8),
                                                                  SizedBox(
                                                                    height: 30, width: 30,
                                                                    child: IconButton(
                                                                      padding: EdgeInsets.zero,
                                                                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                                      onPressed: () => _deleteInquiry(pageDocs[index].id, data['buildingName'] ?? ''),
                                                                      tooltip: "영구 삭제",
                                                                    ),
                                                                  )
                                                                ]
                                                              ],
                                                            )
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                    ),
                  ),

                  if (totalPages > 1)
                    Container(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 28),
                            color: _currentPage > 1 ? primaryNavy : Colors.grey.shade300,
                            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("$_currentPage / $totalPages", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 28),
                            color: _currentPage < totalPages ? primaryNavy : Colors.grey.shade300,
                            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                          ),
                        ],
                      ),
                    )
                ],
              ),
            );
          }
      ),
    );
  }

  // 🏛️ [고도화] 실제 건축물대장 양식을 재현한 멀티 페이지 팝업 (깔끔한 UI 버전)
  void _showFullRegisterPopup(Map<String, dynamic> item) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPopupState) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🌟 둥근 모서리 적용
          insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
          child: Container(
            width: 1000,
            constraints: const BoxConstraints(maxHeight: 900),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _registerPage == 3 ? "집합건축물대장(표제부, 을) 변동사항" : "집합건축물대장(표제부, 갑)",
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 22, // 🌟 모바일에서도 제목 잘 보이게
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("(총 3쪽 중 제 $_registerPage 쪽)", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 28, color: Colors.black54)
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, thickness: 2, color: Color(0xFF1E293B)), // 🌟 세련된 네이비 라인
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: _buildRegisterPageContent(item, isMobile),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: _registerPage > 1 ? () => setPopupState(() => _registerPage--) : null,
                      child: const Text("이전 페이지", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: isMobile ? 16 : 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: _registerPage < 3 ? () => setPopupState(() => _registerPage++) : null,
                      child: const Text("다음 페이지", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveTable(Widget tableWidget, bool isMobile) {
    if (!isMobile) {
      return tableWidget;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 500),
        child: tableWidget,
      ),
    );
  }

  Widget _buildRegisterPageContent(Map<String, dynamic> item, bool isMobile) {
    int auto = (item['indrAutoUtcnt'] ?? 0) + (item['oudrAutoUtcnt'] ?? 0);
    int mech = (item['indrMechUtcnt'] ?? 0) + (item['oudrMechUtcnt'] ?? 0);

    var sewer = item['sewer_info'];
    String sewerType = "-";
    String sewerCap = "-";
    if (sewer != null) {
      sewerType = sewer['modeCdNm']?.toString() ?? sewer['etcMode']?.toString() ?? "기타오수처리시설";
      sewerCap = sewer['capaPsper']?.toString() ?? "-";
    }

    // 🌟 표 제목 디자인 통일
    Widget sectionTitle(String title) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.blue.shade100)),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue.shade900)),
      );
    }

    if (_registerPage == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("🏠 건축물 기본 정보"),
          _buildResponsiveTable(
              _buildOfficialTable([
                _buildTableRow("대지위치", _bAddressCtrl.text, "지번", item['platGbCdNm']?.toString() ?? "-"),
                // 👇 🌟 [수술 완료] 가구수를 추가하여 '세대/가구/호' 3종 세트를 모두 표기합니다.
                _buildTableRow(
                    "명칭", item['bldNm']?.toString() ?? "-",
                    "세대/가구/호", "${item['hhldCnt'] ?? 0} 세대 / ${item['fmlyCnt'] ?? 0} 가구 / ${item['hoCnt'] ?? 0} 호"
                ),
                _buildTableRow("대지면적", "${item['platArea'] ?? 0} ㎡", "연면적", "${item['totArea'] ?? 0} ㎡"),
                _buildTableRow("건축면적", "${item['archArea'] ?? 0} ㎡", "용적률산정연면적", "${item['vlRatEstmTotArea'] ?? 0} ㎡"),
                _buildTableRow("건폐율", "${item['bcRat'] ?? 0} %", "용적률", "${item['vlRat'] ?? 0} %"),
                _buildTableRow("주구조", item['strctCdNm']?.toString() ?? "-", "주용도", item['mainPurpsCdNm']?.toString() ?? "-"),
                _buildTableRow("층수", "지상 ${item['grndFlrCnt']}층 / 지하 ${item['ugrndFlrCnt']}층", "사용승인일", _formatDate(item['useAprDay'])),
              ]),
              isMobile
          ),
          const SizedBox(height: 32),
          sectionTitle("🚗 주차 및 승강기 현황"),
          _buildResponsiveTable(
              _buildOfficialTable([
                _buildTableRow("자주식 주차", "$auto 대", "기계식 주차", "$mech 대"),
                _buildTableRow("승용 승강기", "${item['rideUseElvtCnt'] ?? 0} 대", "비상용 승강기", "${item['emgenUseElvtCnt'] ?? 0} 대"),
              ]),
              isMobile
          ),
        ],
      );
    } else if (_registerPage == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("🏢 건축물 현황 (층별 상세)"),
          _buildResponsiveTable(
              Table(
                border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1), 2: FlexColumnWidth(2), 3: FlexColumnWidth(1)},
                children: [
                  TableRow(
                    children: [
                      _buildTableCell("구분", isHeader: true),
                      _buildTableCell("층별", isHeader: true),
                      _buildTableCell("용도", isHeader: true),
                      _buildTableCell("면적(㎡)", isHeader: true),
                    ],
                  ),
                  if (_currentFloorList.isEmpty)
                    TableRow(children: [
                      _buildTableCell("-"), _buildTableCell("조회된 층별 데이터가 없습니다"), _buildTableCell("-"), _buildTableCell("-"),
                    ])
                  else
                    ..._currentFloorList.map((f) => TableRow(
                      children: [
                        _buildTableCell(f['mainAtchGbCdNm']?.toString() ?? "주건축물"),
                        _buildTableCell(f['flrNoNm']?.toString() ?? "-"),
                        _buildTableCell(f['mainPurpsCdNm']?.toString() ?? "-"),
                        _buildTableCell("${f['area'] ?? 0}"),
                      ],
                    )).toList(),
                ],
              ),
              isMobile
          ),
          const SizedBox(height: 32),
          sectionTitle("🚽 기타 부속 시설 (정화조/저수조)"),
          _buildResponsiveTable(
              _buildOfficialTable([
                _buildTableRow("정화조 형식", sewerType, "용량", "$sewerCap 인용"),
                _buildTableRow("저수조 용량", "${item['wtr_capacity'] ?? '-'} ㎡", "기타", "-"),
              ]),
              isMobile
          ),
        ],
      );
    } else {
      String changeDate = _formatDate(item['pmsDay']);
      if (changeDate == "-") changeDate = _formatDate(item['useAprDay']);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("📝 변동사항 및 기재사항"),
          _buildResponsiveTable(
              _buildOfficialTable([
                _buildTableRow("변동일", "변동내용 및 원인", "변동일", "변동내용 및 원인"),
                _buildTableRow(changeDate, "신규작성(신축)", "-", "-"),
              ]),
              isMobile
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: Text("이하 여백", style: TextStyle(color: Colors.grey, fontSize: 16))),
          ),
        ],
      );
    }
  }

  // 🌟 표 테두리를 고급스러운 연회색으로 변경
  Widget _buildOfficialTable(List<TableRow> rows) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1), 3: FlexColumnWidth(2)},
      children: rows,
    );
  }

  TableRow _buildTableRow(String label1, String val1, String label2, String val2) {
    return TableRow(
      children: [
        _buildTableCell(label1, isHeader: true),
        _buildTableCell(val1),
        _buildTableCell(label2, isHeader: true),
        _buildTableCell(val2),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(14), // 🌟 셀 내부 여백 넓힘
      color: isHeader ? const Color(0xFFF8FAFC) : Colors.white, // 🌟 헤더 배경색을 고급스러운 슬레이트 색상으로
      alignment: Alignment.center,
      child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14, // 🌟 글자 크기 살짝 키움
              color: isHeader ? const Color(0xFF334155) : Colors.black87,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal
          )
      ),
    );
  }

  // 🌟 [API 로직 유지] 기존 내역 열기 시 전 층 타겟팅
  Future<void> _fetchMolitOnly(String address) async {
    try {
      final kakaoRes = await http.get(
        Uri.parse("https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(address)}"),
        headers: {"Authorization": "KakaoAK e1fc7f4a7281b14f7c8be88f6e146462"},
      );
      final kakaoData = json.decode(utf8.decode(kakaoRes.bodyBytes));
      var addrData = kakaoData['documents'][0]['address'];

      String sigunguCd = addrData['b_code'].substring(0, 5);
      String bjdongCd = addrData['b_code'].substring(5, 10);
      String bun = addrData['main_address_no'].toString().padLeft(4, '0');
      String ji = addrData['sub_address_no'].toString().isEmpty ? "0000" : addrData['sub_address_no'].toString().padLeft(4, '0');

      // 🌟 [핵심] 일반 대지인지 파악하고 주건축물(0)만 타겟팅 (이전 단계 버그 픽스 유지)
      String platGbCd = (addrData['mountain_yn'] == 'Y') ? '1' : '0';
      final baseUrl = "https://asia-northeast3-sm-sales-note-2026.cloudfunctions.net/fetchMolitData";
      final commonParams = "sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&platGbCd=$platGbCd&bun=$bun&ji=$ji&mainAtchGbCd=0&numOfRows=100&pageNo=1";

      final results = await Future.wait([
        http.get(Uri.parse("$baseUrl?$commonParams&operation=getBrTitleInfo")),
        http.get(Uri.parse("$baseUrl?$commonParams&operation=getBrFlrOulnInfo")),
        http.get(Uri.parse("$baseUrl?$commonParams&operation=getBrWclfInfo")),
      ]);

      if (results[0].statusCode == 200) {
        final titleItem = json.decode(utf8.decode(results[0].bodyBytes))['response']?['body']?['items']?['item'];
        final floorItems = json.decode(utf8.decode(results[1].bodyBytes))['response']?['body']?['items']?['item'];
        final sewerItem = json.decode(utf8.decode(results[2].bodyBytes))['response']?['body']?['items']?['item'];

        setState(() {
          _currentMolitRawData = (titleItem is List) ? titleItem[0] : titleItem;
          if (sewerItem != null && _currentMolitRawData != null) {
            _currentMolitRawData!['sewer_info'] = (sewerItem is List) ? sewerItem[0] : sewerItem;
          }

          if (floorItems is List) _currentFloorList = List.from(floorItems);
          else if (floorItems != null) _currentFloorList = [floorItems];
          else _currentFloorList = [];

          // 🌟 [정렬 고도화] 기존 내역을 열 때도 동일하게 최고층부터 정렬 적용!
          _currentFloorList.sort((a, b) {
            int getSortValue(dynamic f) {
              if (f == null) return 0;
              int gbCd = int.tryParse(f['flrGbCd']?.toString() ?? '0') ?? 0;
              int no = int.tryParse(f['flrNo']?.toString() ?? '0') ?? 0;
              String flrName = f['flrNoNm']?.toString() ?? "";

              if (gbCd == 0) {
                if (flrName.contains("옥탑")) gbCd = 30;
                else if (flrName.contains("지하")) gbCd = 10;
                else gbCd = 20;
              }

              if (gbCd == 30) return 1000 + no;
              if (gbCd == 20) return no;
              if (gbCd == 10) return -no;
              return 0;
            }
            return getSortValue(b).compareTo(getSortValue(a));
          });
        });
      }
    } catch (e) {
      debugPrint("데이터 복구 실패: $e");
    }
  }

  String _formatDate(dynamic date) {
    String dateStr = date?.toString() ?? "";
    if (dateStr.length == 8) {
      return "${dateStr.substring(0, 4)}.${dateStr.substring(4, 6)}.${dateStr.substring(6, 8)}";
    }
    return dateStr.isNotEmpty ? dateStr : "-";
  }
}