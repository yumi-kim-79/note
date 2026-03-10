//영업 정보 신규건물 접수 페이지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/daum_postcode_stub.dart' if (dart.library.html) '../../utils/daum_postcode_web.dart';

class SalesInquiryListPage extends StatefulWidget {
  const SalesInquiryListPage({super.key});

  @override
  State<SalesInquiryListPage> createState() => _SalesInquiryListPageState();
}

class _SalesInquiryListPageState extends State<SalesInquiryListPage> {
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF4A89DC);
  final Color tableHeaderColor = const Color(0xFF8B95A1);

  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  Map<String, dynamic>? _currentMolitRawData; // 🌟 API 원본을 기억할 변수
  int _registerPage = 1; // 🌟 [추가] 현재 보고 있는 대장 페이지 번호

  final _bNameCtrl = TextEditingController();
  final _bAddressCtrl = TextEditingController();
  final _bInfoCtrl = TextEditingController();
  final _callerNameCtrl = TextEditingController();
  final _callerRankCtrl = TextEditingController();
  final _callerPhoneCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  // 👇👇 🌟 [핵심 보안] 오직 대표님 이메일만 '삭제' 권한 부여 👇👇
  bool get _isSuperAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.email == 'yuseok8052@gmail.com';
  }

  // -----------------------------------------------------------------
  // 🗑️ 슈퍼 관리자 전용 삭제 기능 (팝업 & 모바일 카드 & PC 표 겸용)
  // -----------------------------------------------------------------
  Future<void> _deleteInquiry(String docId, String bName, {BuildContext? dialogCtx}) async {
    bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("영구 삭제 (슈퍼 관리자 전용)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Text("'$bName' 접수 내역을 완전히 삭제하시겠습니까?\n(접수 번호는 복구되지 않습니다)"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("삭제", style: TextStyle(color: Colors.white))),
          ],
        )
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('sales_inquiries').doc(docId).delete();
      if (mounted) {
        if (dialogCtx != null) Navigator.pop(dialogCtx); // 팝업에서 호출했을 때만 닫기
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("안전하게 삭제되었습니다.")));
      }
    }
  }

  List<dynamic> _currentFloorList = []; // 🌟 층별 상세 리스트를 담을 주머니

  // 👇👇 🌟 [Step 1 업그레이드] 3대 API 통합 수집 엔진 👇👇
  Future<void> _searchAddressAndFetchMolit() async {
    try {
      Map<String, String>? result = await searchAddress();
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

      final baseUrl = "https://asia-northeast3-sm-sales-note-2026.cloudfunctions.net/fetchMolitData";

      // 🌟 [핵심 해결] numOfRows를 추가하여 지하부터 꼭대기 층까지 한 번에 긁어옵니다.
      final results = await Future.wait([
        http.get(Uri.parse("$baseUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrTitleInfo")),
        http.get(Uri.parse("$baseUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrFlrOulnInfo&numOfRows=1")), // 👈 층별 최대 1개
        http.get(Uri.parse("$baseUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrWclfInfo&numOfRows=1")),  // 👈 정화조 최대 1개
      ]);

      if (results[0].statusCode == 200) {
        final titleItem = json.decode(utf8.decode(results[0].bodyBytes))['response']?['body']?['items']?['item'];
        final floorItems = json.decode(utf8.decode(results[1].bodyBytes))['response']?['body']?['items']?['item'];
        final sewerItem = json.decode(utf8.decode(results[2].bodyBytes))['response']?['body']?['items']?['item'];

        var item = (titleItem is List) ? titleItem[0] : titleItem;
        if (item == null) throw "해당 주소의 표제부 정보가 없습니다.";

        // 정화조 데이터가 있다면 메인 데이터에 합쳐줍니다.
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

          if (floorItems is List) _currentFloorList = floorItems;
          else if (floorItems != null) _currentFloorList = [floorItems];
          else _currentFloorList = [];

          _bInfoCtrl.text = "[건축물대장 제원]\n"
              "• 사용승인일: $approvalDate\n"
              "• 총 $totalHousehold호실 (세대 $hhldCnt / 가구 $fmlyCnt / 호 $hoCnt)\n"
              "• 연면적: ${item['totArea'] ?? '0'} ㎡ / 대지면적: ${item['platArea'] ?? '0'} ㎡\n"
              "• 규모: 지상 ${item['grndFlrCnt'] ?? '0'}층, 지하 ${item['ugrndFlrCnt'] ?? '0'}층\n"
              "• 승강기: ${item['rideUseElvtCnt'] ?? '0'}대\n"
              "• 주차: 총 $totalParking대 (자주식 ${autoParking}대 / 기계식 ${mechParking}대)";
        });
      }
    } catch (e) {
      setState(() => _bInfoCtrl.text = "연동 실패: $e");
    }
  }

  // -----------------------------------------------------------------
  // 🌟 문의 접수 및 상세 확인 팝업 (새로고침 스위치 완벽 탑재)
  // -----------------------------------------------------------------
  Future<void> _showInquiryDialog({DocumentSnapshot? doc}) async {
    bool isEdit = doc != null;
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isAuthor = !isEdit || (doc['authorUid'] == currentUser?.uid);

    String currentReceiptNo = "";

    if (isEdit) {
      var data = doc.data() as Map<String, dynamic>;
      currentReceiptNo = data['receiptNo'] ?? '';
      _bNameCtrl.text = data['buildingName'] ?? '';
      _bAddressCtrl.text = data['address'] ?? '';
      _bInfoCtrl.text = data['buildingInfo'] ?? '';

      if (_bAddressCtrl.text.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("국토부 대장 정보를 불러오고 있습니다..."), duration: Duration(seconds: 1)));
        await _fetchMolitOnly(_bAddressCtrl.text);
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
          // 🌟 [핵심] 팝업창 전용 상태 관리자 (이게 있어야 새로고침 스위치가 생깁니다!)
          return StatefulBuilder(
              builder: (context, setDialogState) {
                bool isMobileDialog = MediaQuery.of(context).size.width < 600;

                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Row(
                    children: [
                      Icon(isEdit ? Icons.manage_search : Icons.add_call, color: primaryNavy),
                      const SizedBox(width: 8),
                      Expanded(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(isEdit ? (isAuthor ? "문의 상세 및 수정 [$currentReceiptNo]" : "문의 상세 (읽기 전용) [$currentReceiptNo]") : "신규 문의 접수", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
                          )
                      ),
                      if (isEdit && !isAuthor && !isMobileDialog)
                        Container(margin: const EdgeInsets.only(left: 12), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)), child: Text("작성자만 수정 가능", style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold)))
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
                          if (isMobileDialog) ...[
                            _buildTextField("건물명 (단지명)", _bNameCtrl, Icons.domain, readOnly: !isAuthor),
                            const SizedBox(height: 8),
                            // 🌟 모바일 화면일 때 새로고침 스위치(setDialogState) 전달
                            SizedBox(width: double.infinity, height: 50, child: _buildKakaoButton(isAuthor, setDialogState)),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(flex: 3, child: _buildTextField("건물명 (단지명)", _bNameCtrl, Icons.domain, readOnly: !isAuthor)),
                                const SizedBox(width: 12),
                                // 🌟 PC 화면일 때 새로고침 스위치(setDialogState) 전달
                                Expanded(flex: 2, child: SizedBox(height: 50, child: _buildKakaoButton(isAuthor, setDialogState))),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildTextField("상세 주소 (검색 시 자동 입력)", _bAddressCtrl, Icons.location_on, readOnly: !isAuthor),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              const Text("🏢 건축물대장 상세 제원", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              const Spacer(),
                              if (_currentMolitRawData != null)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() => _registerPage = 1);
                                    _showFullRegisterPopup(_currentMolitRawData!);
                                  },
                                  icon: const Icon(Icons.find_in_page, size: 16),
                                  label: const Text("건대장 전체보기"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[800],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildTextField("건축물대장 제원 (카카오 주소 검색 시 자동 연동)", _bInfoCtrl, Icons.domain_verification, maxLines: null, readOnly: !isAuthor),

                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),

                          if (isMobileDialog) ...[
                            _buildTextField("문의자 성함", _callerNameCtrl, Icons.person, readOnly: !isAuthor),
                            const SizedBox(height: 8),
                            _buildTextField("직책 (예: 대표,회장 등)", _callerRankCtrl, Icons.badge, readOnly: !isAuthor),
                            const SizedBox(height: 8),
                            _buildTextField("연락처 (번호)", _callerPhoneCtrl, Icons.phone, readOnly: !isAuthor),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(child: _buildTextField("문의자 성함", _callerNameCtrl, Icons.person, readOnly: !isAuthor)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTextField("직책 (예: 대표,회장,총무,감사 등)", _callerRankCtrl, Icons.badge, readOnly: !isAuthor)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTextField("연락처 (번호)", _callerPhoneCtrl, Icons.phone, readOnly: !isAuthor)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),

                          const Text("📝 상세 상담 내용 및 영업 메모", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _memoCtrl, maxLines: null, minLines: 5, keyboardType: TextInputType.multiline, readOnly: !isAuthor,
                            decoration: InputDecoration(
                              hintText: isAuthor ? "고객의 니즈, 현재 업체의 불만사항, 견적 요청 내용 등을 상세히 적어주세요." : "작성자만 수정할 수 있습니다.",
                              filled: true, fillColor: isAuthor ? Colors.yellow.shade50 : Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4A89DC), width: 2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    if (isEdit && _isSuperAdmin)
                      TextButton.icon(
                        onPressed: () => _deleteInquiry(doc!.id, _bNameCtrl.text, dialogCtx: ctx),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("기록 삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      )
                    else
                      const SizedBox.shrink(),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 8),
                        if (isAuthor)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: safetyBlue, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                            onPressed: () async {
                              if (_bNameCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("건물명은 필수입니다."))); return;
                              }

                              final data = {
                                'buildingName': _bNameCtrl.text, 'address': _bAddressCtrl.text, 'buildingInfo': _bInfoCtrl.text,
                                'callerName': _callerNameCtrl.text, 'callerRank': _callerRankCtrl.text, 'callerPhone': _callerPhoneCtrl.text,
                                'memo': _memoCtrl.text, 'updatedAt': FieldValue.serverTimestamp(),
                              };

                              if (isEdit) {
                                await FirebaseFirestore.instance.collection('sales_inquiries').doc(doc!.id).update(data);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정되었습니다.")));
                              } else {
                                String yy = (DateTime.now().year % 100).toString();
                                String newReceiptNo = '$yy-0001';

                                var qs = await FirebaseFirestore.instance.collection('sales_inquiries')
                                    .orderBy('createdAt', descending: true)
                                    .limit(1)
                                    .get();

                                if (qs.docs.isNotEmpty) {
                                  var lastData = qs.docs.first.data();
                                  if (lastData.containsKey('receiptNo')) {
                                    String lastNo = lastData['receiptNo'];
                                    if (lastNo.startsWith('$yy-')) {
                                      int nextNum = int.parse(lastNo.split('-')[1]) + 1;
                                      newReceiptNo = '$yy-${nextNum.toString().padLeft(4, '0')}';
                                    }
                                  }
                                }

                                data['receiptNo'] = newReceiptNo;
                                data['status'] = '접수완료';
                                data['createdAt'] = FieldValue.serverTimestamp();
                                data['authorUid'] = currentUser?.uid ?? '';
                                data['authorName'] = currentUser?.displayName ?? '영업 담당자';

                                await FirebaseFirestore.instance.collection('sales_inquiries').add(data);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("접수 성공 (접수번호: $newReceiptNo)")));
                              }
                              if (mounted) Navigator.pop(ctx);
                            },
                            child: Text(isEdit ? "수정 저장" : "접수 등록", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          )
                      ],
                    )
                  ],
                );
              }
          ); // 🌟 StatefulBuilder 닫기 괄호
        }
    );
  }

  // 🌟 [핵심] 괄호 안에 StateSetter setDialogState 가 추가되었습니다.
  Widget _buildKakaoButton(bool isAuthor, StateSetter setDialogState) {
    return ElevatedButton.icon(
      onPressed: isAuthor ? () async {
        await _searchAddressAndFetchMolit(); // 1. 주소 검색 후 데이터를 가져올 때까지 대기
        setDialogState(() {});               // 2. 팝업창 새로고침 (건대장 버튼이 짠! 하고 나타납니다)
      } : null,
      icon: const Icon(Icons.search, color: Colors.black87, size: 18),
      label: const FittedBox(fit: BoxFit.scaleDown, child: Text("카카오 주소 검색", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade300, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    );
  }

  // 👇 1. int 옆에 '?'를 붙여서 null을 허용하게 만듭니다.
  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {int? maxLines = 1, bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label, alignLabelWithHint: true,
        // 👇 2. maxLines == 1 인지 검사할 때, null이 아님을 보장하기 위해 '?? 1' 을 추가합니다.
        prefixIcon: (maxLines ?? 1) == 1
            ? Icon(icon, size: 20, color: Colors.grey)
            : Padding(padding: const EdgeInsets.only(bottom: 40), child: Icon(icon, size: 20, color: Colors.grey)),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4A89DC), width: 2)),
      ),
    );
  }

  // =================================================================
  // 📱 [모바일/태블릿 전용] 반응형 카드 리스트 아이템 UI
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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(4)),
                  child: Text(receiptNo, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(bName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: safetyBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(data['status'] ?? '접수완료', style: TextStyle(color: safetyBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),

            _buildMobileInfoRow(Icons.calendar_today, "접수일", dateStr),
            _buildMobileInfoRow(Icons.location_on, "주소", data['address'] ?? ''),
            _buildMobileInfoRow(Icons.person, "문의자", "${data['callerName'] ?? ''}$rankStr  |  ${data['callerPhone'] ?? ''}"),
            if (memo.isNotEmpty) _buildMobileInfoRow(Icons.edit_note, "메모", memo.replaceAll('\n', ' '), maxLines: 2),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showInquiryDialog(doc: doc),
                    icon: const Icon(Icons.manage_search, color: Colors.white, size: 18),
                    label: const Text("상세 열기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: safetyBlue, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                  ),
                ),
                // 🌟 모바일 카드 삭제 버튼 (슈퍼 관리자만 보임)
                if (_isSuperAdmin) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _deleteInquiry(doc.id, bName),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                    child: const Icon(Icons.delete, size: 20),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String label, String value, {int maxLines = 1}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4))),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // 🖥️ 메인 UI 화면 구성 (페이지네이션 10개 자르기 완벽 탑재)
  // -----------------------------------------------------------------
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
                return (data['buildingName'] ?? '').toString().contains(_searchQuery) || (data['callerName'] ?? '').toString().contains(_searchQuery);
              }).toList();
              totalCount = docs.length;
            }

            // 🌟 [핵심 고도화] 10개씩 자르기 로직 (Pagination)
            int totalPages = (totalCount / _itemsPerPage).ceil();
            if (totalPages == 0) totalPages = 1;
            if (_currentPage > totalPages) _currentPage = totalPages;

            // 전체 문서(docs) 중 현재 페이지에 해당하는 10개(pageDocs)만 쏙 뽑아냅니다!
            List<QueryDocumentSnapshot> pageDocs = docs.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

            return Padding(
              padding: EdgeInsets.all(isSuperSmall ? 12.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSuperSmall) ...[
                    Text("신규 문의 접수 대장 (총 $totalCount건)", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showInquiryDialog(),
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text("신규 문의 접수", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: safetyBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: FittedBox(
                                alignment: Alignment.centerLeft, fit: BoxFit.scaleDown,
                                child: Text("신규 문의 접수 대장 (총 $totalCount건)", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                            )
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showInquiryDialog(),
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text("신규 문의 접수", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: safetyBlue, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        )
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  isSuperSmall
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("검색어", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity, height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                        child: TextField(
                            controller: _searchCtrl,
                            // 🌟 검색어를 치면 무조건 1페이지로 돌아가도록 초기화!
                            onChanged: (val) => setState(() { _searchQuery = val; _currentPage = 1; }),
                            decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.search, size: 20), contentPadding: EdgeInsets.symmetric(vertical: 12), hintText: "건물명 또는 문의자 검색")
                        ),
                      ),
                    ],
                  )
                      : Row(
                    children: [
                      const Text("검색어  |  ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      Container(
                        width: 300, height: 40,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                        child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() { _searchQuery = val; _currentPage = 1; }),
                            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), hintText: "건물명 또는 문의자 검색")
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🌟 리스트 데이터 (docs 대신 10개만 뽑아둔 pageDocs 사용)
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
                                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                                  child: Column(
                                    children: [
                                      Container(
                                        color: tableHeaderColor,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: const Row(
                                          children: [
                                            Expanded(flex: 2, child: Text("접수번호", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(flex: 2, child: Text("접수일", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(flex: 3, child: Text("단지명 (건물명)", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(flex: 3, child: Text("건물 주소", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(flex: 2, child: Text("문의자 / 연락처", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(flex: 2, child: Text("진행 상태", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(flex: 2, child: Text("비고 (메모)", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(flex: 2, child: Text("관리", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.separated(
                                            itemCount: pageDocs.length,
                                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
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
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  child: Row(
                                                    children: [
                                                      Expanded(flex: 2, child: Text(receiptNo, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryNavy))),
                                                      Expanded(flex: 2, child: Text(dateStr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                                                      Expanded(flex: 3, child: Text(data['buildingName'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87))),
                                                      Expanded(flex: 3, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(data['address'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis))),
                                                      Expanded(flex: 2, child: Text("${data['callerName'] ?? ''}$rankStr\n${data['callerPhone'] ?? ''}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                                                      Expanded(flex: 2, child: Text(data['status'] ?? '접수완료', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: safetyBlue))),
                                                      Expanded(flex: 2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(memo.replaceAll('\n', ' '), textAlign: TextAlign.left, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)))),

                                                      Expanded(
                                                          flex: 2,
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              SizedBox(
                                                                height: 28,
                                                                child: ElevatedButton(
                                                                  onPressed: () => _showInquiryDialog(doc: pageDocs[index]),
                                                                  style: ElevatedButton.styleFrom(backgroundColor: safetyBlue, padding: const EdgeInsets.symmetric(horizontal: 12), elevation: 0),
                                                                  child: const Text("열기", style: TextStyle(fontSize: 12, color: Colors.white)),
                                                                ),
                                                              ),
                                                              if (_isSuperAdmin) ...[
                                                                const SizedBox(width: 8),
                                                                SizedBox(
                                                                  height: 28, width: 28,
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
                          );
                        }
                    ),
                  ),

                  // 👇👇 🌟 [핵심 고도화] 하단 페이지 네비게이션 버튼 UI 추가 👇👇
                  if (totalPages > 1)
                    Container(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 30),
                            color: _currentPage > 1 ? primaryNavy : Colors.grey,
                            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("$_currentPage / $totalPages", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 30),
                            color: _currentPage < totalPages ? primaryNavy : Colors.grey,
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

  // 🏛️ [고도화] 실제 건축물대장 양식을 재현한 멀티 페이지 팝업 (PC/모바일 반응형 완벽 분리)
  void _showFullRegisterPopup(Map<String, dynamic> item) {
    // 🌟 디바이스 너비를 구해서 모바일/태블릿인지 PC인지 확실히 구분합니다.
    bool isMobile = MediaQuery.of(context).size.width < 768;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( // 팝업 안에서 페이지 전환을 위해 필요합니다.
        builder: (context, setPopupState) => Dialog(
          insetPadding: EdgeInsets.all(isMobile ? 12 : 24), // 📱 모바일은 여백 축소
          child: Container(
            width: 1000,
            constraints: const BoxConstraints(maxHeight: 900),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              children: [
                // 🌟 [UI 고도화] 헤더 영역 (엑스 버튼이 절대 깨지거나 밀리지 않는 강제 고정 구조)
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
                                fontSize: isMobile ? 16 : 22,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("(총 3쪽 중 제 $_registerPage 쪽)", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 28)
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 2, color: Colors.black),

                // 페이지별 내용물
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildRegisterPageContent(item, isMobile), // 🌟 isMobile 전달
                  ),
                ),

                // 하단 페이지 네비게이션
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _registerPage > 1 ? () => setPopupState(() => _registerPage--) : null,
                      child: const Text("이전 페이지"),
                    ),
                    SizedBox(width: isMobile ? 20 : 40),
                    ElevatedButton(
                      onPressed: _registerPage < 3 ? () => setPopupState(() => _registerPage++) : null,
                      child: const Text("다음 페이지"),
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

  // 🌟 [UI 핵심] PC에서는 원본 100% 유지, 모바일에서만 가로 스크롤 허용!
  Widget _buildResponsiveTable(Widget tableWidget, bool isMobile) {
    if (!isMobile) {
      return tableWidget; // 💻 PC 화면: 래퍼 없이 원본 그대로 리턴! (화면 꽉 차게 복구)
    }
    // 📱 모바일/태블릿: 표가 찌그러지지 않게 가로 스크롤 적용
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 500),
        child: tableWidget,
      ),
    );
  }

  // 📄 [최종 수정] 가이드북 100% 매핑 + 반응형 UI 보완
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

    if (_registerPage == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🏠 건축물 기본 정보", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildResponsiveTable(
              _buildOfficialTable([
                _buildTableRow("대지위치", _bAddressCtrl.text, "지번", item['platGbCdNm']?.toString() ?? "-"),
                _buildTableRow("명칭", item['bldNm']?.toString() ?? "-", "호수/세대수", "${item['hoCnt'] ?? 0}호 / ${item['hhldCnt'] ?? 0}세대"),
                _buildTableRow("대지면적", "${item['platArea'] ?? 0} ㎡", "연면적", "${item['totArea'] ?? 0} ㎡"),
                _buildTableRow("건축면적", "${item['archArea'] ?? 0} ㎡", "용적률산정연면적", "${item['vlRatEstmTotArea'] ?? 0} ㎡"),
                _buildTableRow("건폐율", "${item['bcRat'] ?? 0} %", "용적률", "${item['vlRat'] ?? 0} %"),
                _buildTableRow("주구조", item['strctCdNm']?.toString() ?? "-", "주용도", item['mainPurpsCdNm']?.toString() ?? "-"),
                _buildTableRow("층수", "지상 ${item['grndFlrCnt']}층 / 지하 ${item['ugrndFlrCnt']}층", "사용승인일", _formatDate(item['useAprDay'])),
              ]),
              isMobile
          ),
          const SizedBox(height: 30),
          const Text("🚗 주차 및 승강기 현황", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
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
          const Text("🏢 건축물 현황 (층별 상세)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildResponsiveTable(
              Table(
                border: TableBorder.all(color: Colors.black),
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
          const SizedBox(height: 30),
          const Text("🚽 기타 부속 시설 (정화조/저수조)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
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
          const Text("📝 변동사항 및 기재사항", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildResponsiveTable(
              _buildOfficialTable([
                _buildTableRow("변동일", "변동내용 및 원인", "변동일", "변동내용 및 원인"),
                _buildTableRow(changeDate, "신규작성(신축)", "-", "-"),
              ]),
              isMobile
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text("이하 여백", style: TextStyle(color: Colors.grey))),
          ),
        ],
      );
    }
  }

  Widget _buildOfficialTable(List<TableRow> rows) {
    return Table(
      border: TableBorder.all(color: Colors.black, width: 1),
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
      padding: const EdgeInsets.all(12),
      color: isHeader ? Colors.grey[100] : Colors.white,
      alignment: Alignment.center,
      child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal
          )
      ),
    );
  }

  // 🌟 [Step 1 업그레이드] 기존 내역 열 때 3대 데이터를 다시 긁어오는 엔진
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

      final baseUrl = "https://asia-northeast3-sm-sales-note-2026.cloudfunctions.net/fetchMolitData";

      // 🌟 [핵심 해결] 열기 버튼을 눌렀을 때도 전 층을 다 가져오도록 세팅!
      final results = await Future.wait([
        http.get(Uri.parse("$baseUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrTitleInfo")),
        http.get(Uri.parse("$baseUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrFlrOulnInfo&numOfRows=1")),
        http.get(Uri.parse("$baseUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrWclfInfo&numOfRows=1")),
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

          if (floorItems is List) _currentFloorList = floorItems;
          else if (floorItems != null) _currentFloorList = [floorItems];
          else _currentFloorList = [];
        });
      }
    } catch (e) {
      debugPrint("데이터 복구 실패: $e");
    }
  }

  // 🌟 [추가] 날짜를 2006.07.03 형식으로 변환하는 함수
  String _formatDate(dynamic date) {
    String dateStr = date?.toString() ?? "";
    if (dateStr.length == 8) {
      return "${dateStr.substring(0, 4)}.${dateStr.substring(4, 6)}.${dateStr.substring(6, 8)}";
    }
    return dateStr.isNotEmpty ? dateStr : "-";
  }
} // <--- 2. 🌟 중요! _SalesInquiryListPageState