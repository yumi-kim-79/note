// [파일 위치: lib/pages/sales/checklist_page.dart]
// 수정 내용:
// 1. [반응형 UI 강화] 다이얼로그 너비 및 높이를 화면 크기에 맞춰 유동적으로 조절 (Overflow 방지)
// 2. [키보드 대응] 키보드가 올라올 때 입력창이 가려지지 않도록 스크롤 영역 최적화
// 3. [기능 유지] 프린트, 복사, 엔터 줄바꿈, 체크리스트 등 기존 기능 100% 보존
// 4. [🌟고도화] 작성자 '이름+직책' 추가 및 UI 표시
// 5. [🌟고도화] 복사/공유/프린트 시 입주자대표 정보 및 메모가 누락되지 않도록 데이터 추출 로직 완벽 보완

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // min 함수 사용

// 프린트 기능을 위한 패키지
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// 디자인 시스템 import
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/sales_service.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final SalesService _salesService = SalesService();

  // 체크리스트 항목 데이터 (25개 항목)
  final List<String> _checklistItems = [
    "1. 공용부 비밀번호 (공동현관/관리자/CCTV/도어락/열쇠/마스터키/카드키 등)",
    "2. 주차차단기 인수인계 (리모컨/카드키/메인보드 키/제조사/매뉴얼)",
    "3. 음식물 및 분리수거 관리 (현재 관리 방식 및 제안)",
    "4. 시설물 누수 피해 이력",
    "5. 시설물 동파 피해 이력",
    "6. 침수 피해 이력",
    "7. 최근 공사 이력 (대형/소형 공사 내역)",
    "8. 시설물 관련 정기 관리 필요 항목 (관리업체 진행)",
    "9. 건물 고유번호증 개설 여부",
    "10. 용역업체 정보 (승강기/전기/소방/주차/청소/소독/정화조/저수조 등)",
    "11. 기존 용역업체 변경 및 해지 여부",
    "12. 용역업체 변경 시 업체 정보 (총무팀 위임/지정 등)",
    "13. 용역업체 계약금액 및 조건",
    "14. 옥상 중계기 설치 여부 (전기료 협정 등)",
    "15. 통신 및 기타 비용 발생 여부 (인터넷/보안/기타 설비)",
    "16. 도로 점용료(사용료) 발생 여부",
    "17. 관리비 수납 계좌 운영 (SM계좌 / 관리단 계좌)",
    "18. 관리단 계좌 사용 시 인계 (고유번호증/통장/인증서/암호)",
    "19. 상가 보유 시 협의 내용 (관리비/상호/업종 등)",
    "20. 공과금(전기/수도) 고객번호 및 명의자 정보",
    "21. 관리비 면제 세대 유무 및 항목",
    "22. 공실 세대 유무 및 리스트",
    "23. 건축주 정산(공실분) 항목 및 금액 정보",
    "24. 건축주 / 시공사 연락처 유무",
    "25. 분양팀 연락처 (현재 분양 중일 경우)"
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

        // ✅ [고도화] 작성자 이름뿐만 아니라 직책(rank)도 가져와서 합칩니다.
        final String myName = userData?['name'] ?? '담당자';
        final String myRank = userData?['rank'] ?? '';
        final String authorInfo = "$myName $myRank".trim(); // 예: "홍길동 과장"

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Column(
            children: [
              // 헤더 영역
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("인수인계 체크리스트", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    CommonButton(
                      text: "새 리스트 작성",
                      icon: Icons.add,
                      // ✅ [고도화] 직책이 포함된 authorInfo 전달
                      onPressed: () => _showChecklistDialog(context, null, authorInfo),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),

              // 리스트 영역
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _salesService.getChecklistsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(child: Text("작성된 체크리스트가 없습니다.", style: TextStyle(color: Colors.grey)));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final docId = docs[index].id;

                        // 진행률 계산
                        final List items = data['checkItems'] ?? [];
                        final int completed = items.where((i) => i['isChecked'] == true).length;
                        final double progress = items.isEmpty ? 0 : completed / items.length;

                        return GestureDetector(
                          // ✅ [고도화] 직책이 포함된 authorInfo 전달
                          onTap: () => _showChecklistDialog(context, {...data, 'id': docId}, authorInfo),
                          child: CommonCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // 진행률 원형 그래프
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 50, height: 50,
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        backgroundColor: AppTheme.backgroundColor,
                                        strokeWidth: 5,
                                        color: progress == 1.0 ? Colors.green : AppTheme.primaryColor,
                                      ),
                                    ),
                                    Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['buildingName'] ?? '건물명 없음', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(data['address'] ?? '주소 없음', style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text("작성일: ${data['createdAt'] != null ? DateFormat('yyyy-MM-dd').format((data['createdAt'] as Timestamp).toDate()) : '-'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
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

  void _showChecklistDialog(BuildContext context, Map<String, dynamic>? data, String authorName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _HandoverDetailDialog(
        data: data,
        checklistItems: _checklistItems,
        authorName: authorName,
      ),
    );
  }
}

// ==============================================================================
// [상세 팝업 위젯] - 데이터 입력 및 프린트
// ==============================================================================
class _HandoverDetailDialog extends StatefulWidget {
  final Map<String, dynamic>? data;
  final List<String> checklistItems;
  final String authorName;

  const _HandoverDetailDialog({
    super.key,
    this.data,
    required this.checklistItems,
    required this.authorName,
  });

  @override
  State<_HandoverDetailDialog> createState() => _HandoverDetailDialogState();
}

class _HandoverDetailDialogState extends State<_HandoverDetailDialog> {
  final SalesService _salesService = SalesService();

  // 컨트롤러
  late TextEditingController _buildingNameCtrl;
  late TextEditingController _buildingAddressCtrl;
  late TextEditingController _householdCtrl;
  late TextEditingController _elevatorCtrl;
  late TextEditingController _parkingCtrl;
  late TextEditingController _prevCompanyInfoCtrl;
  late TextEditingController _remarksCtrl;

  List<Map<String, dynamic>> _committeeList = [];
  DateTime _startDate = DateTime.now();
  late List<Map<String, dynamic>> _currentCheckItems;

  @override
  void initState() {
    super.initState();
    _buildingNameCtrl = TextEditingController(text: widget.data?['buildingName'] ?? '');
    _buildingAddressCtrl = TextEditingController(text: widget.data?['address'] ?? '');
    _householdCtrl = TextEditingController(text: widget.data?['bldArea'] ?? '');
    _elevatorCtrl = TextEditingController(text: widget.data?['bldFloor'] ?? '');
    _parkingCtrl = TextEditingController(text: widget.data?['bldUsage'] ?? '');
    _prevCompanyInfoCtrl = TextEditingController(text: widget.data?['prevCompany'] ?? '');
    _remarksCtrl = TextEditingController(text: widget.data?['remarks'] ?? '');

    if (widget.data != null && widget.data!['committeeMembers'] != null) {
      _committeeList = List<Map<String, dynamic>>.from(widget.data!['committeeMembers']);
    } else {
      _committeeList = [{'unit': '', 'role': '', 'name': '', 'contact': ''}];
    }

    if (widget.data?['contractDate'] != null) {
      _startDate = (widget.data!['contractDate'] as Timestamp).toDate();
    }

    if (widget.data != null && widget.data!['checkItems'] != null) {
      _currentCheckItems = List<Map<String, dynamic>>.from(widget.data!['checkItems']);
    } else {
      _currentCheckItems = widget.checklistItems.map((title) => {
        'title': title,
        'isChecked': false,
        'memo': ''
      }).toList();
    }
  }

  // ✅ [고도화] 텍스트 포맷팅 (복사/공유 시 정보 누락 방지 완벽 적용)
  String _formatChecklistText() {
    String text = "[SM 인수인계 체크리스트]\n";
    text += "출력일: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}\n";
    // 작성자 직책 포함
    text += "작성자: ${widget.data?['author'] ?? widget.authorName}\n\n";

    text += "■ 1. 기본 정보\n";
    text += "- 건물명: ${_buildingNameCtrl.text}\n";
    text += "- 주소: ${_buildingAddressCtrl.text}\n";
    text += "- 관리시작일: ${DateFormat('yyyy-MM-dd').format(_startDate)}\n";
    text += "- 건물개요: 세대수 ${_householdCtrl.text} / 승강기 ${_elevatorCtrl.text} / 주차 ${_parkingCtrl.text}\n\n";

    text += "■ 2. 입주자대표 / 관리단\n";
    // 정보 누락 방지 로직: 이름, 연락처, 동호수, 직책 중 하나라도 입력되어 있으면 출력
    List<String> validMembers = [];
    for (var m in _committeeList) {
      if (m['name'].toString().trim().isNotEmpty ||
          m['contact'].toString().trim().isNotEmpty ||
          m['unit'].toString().trim().isNotEmpty ||
          m['role'].toString().trim().isNotEmpty) {
        String info = "";
        if(m['unit'].toString().isNotEmpty) info += "[${m['unit']}] ";
        if(m['role'].toString().isNotEmpty) info += "${m['role']} ";
        if(m['name'].toString().isNotEmpty) info += "${m['name']} ";
        if(m['contact'].toString().isNotEmpty) info += "(${m['contact']})";
        validMembers.add(info);
      }
    }
    text += validMembers.isEmpty ? "(정보 없음)\n" : validMembers.join("\n") + "\n";
    text += "\n";

    text += "■ 3. 기존 관리업체 정보\n";
    text += "${_prevCompanyInfoCtrl.text.trim().isEmpty ? '(정보 없음)' : _prevCompanyInfoCtrl.text}\n\n";

    text += "■ 4. 비고 (특이사항)\n";
    text += "${_remarksCtrl.text.trim().isEmpty ? '(내용 없음)' : _remarksCtrl.text}\n\n";

    text += "■ 5. 체크 리스트 내역\n";
    // 💡 수정: 작성 여부와 상관없이 25개 항목 전체를 무조건 출력합니다.
    for (var item in _currentCheckItems) {
      String status = item['isChecked'] == true ? "[V]" : "[ ]";
      text += "$status ${item['title']}\n";

      // 메모가 있으면 출력하고, 없으면 빈칸(공란)으로 둡니다.
      String memoText = (item['memo'] != null && item['memo'].toString().trim().isNotEmpty)
          ? item['memo']
          : "";
      text += "   └ 메모: $memoText\n";
    }

    return text;
  }

  void _copyToClipboard() {
    final text = _formatChecklistText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("내용이 복사되었습니다."), duration: Duration(seconds: 2)),
    );
  }

  // ✅ [고도화] 프린트(PDF) 출력 (데이터 누락 방지 및 직책 표시)
  Future<void> _printChecklist() async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nanumGothicRegular();
    final boldFont = await PdfGoogleFonts.nanumGothicBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return [
            pw.Header(
                level: 0,
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("[SM] 인수인계 체크리스트", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text("출력일: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10)),
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
                      _buildPdfRow("건물명", _buildingNameCtrl.text),
                      _buildPdfRow("주소", _buildingAddressCtrl.text),
                      // 직책까지 포함된 authorName 적용
                      _buildPdfRow("작성자", widget.data?['author'] ?? widget.authorName),
                      _buildPdfRow("관리시작일", DateFormat('yyyy-MM-dd').format(_startDate)),
                      _buildPdfRow("건물개요", "세대수: ${_householdCtrl.text} / 승강기: ${_elevatorCtrl.text} / 주차: ${_parkingCtrl.text}"),
                    ]
                )
            ),
            pw.SizedBox(height: 16),
            pw.Text("■ 입주자대표 / 관리단 정보", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // 누락 방지 로직 적용
                    ..._committeeList.where((m) => m['name'].toString().trim().isNotEmpty || m['contact'].toString().trim().isNotEmpty || m['role'].toString().trim().isNotEmpty).map((m) {
                      String info = "";
                      if(m['unit'].toString().isNotEmpty) info += "[${m['unit']}] ";
                      if(m['role'].toString().isNotEmpty) info += "${m['role']} ";
                      if(m['name'].toString().isNotEmpty) info += "${m['name']} ";
                      if(m['contact'].toString().isNotEmpty) info += "(${m['contact']})";
                      return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Text(info, style: const pw.TextStyle(fontSize: 12))
                      );
                    }).toList(),
                    // 입력된 위원이 아무도 없으면
                    if (_committeeList.every((m) => m['name'].toString().trim().isEmpty && m['contact'].toString().trim().isEmpty && m['role'].toString().trim().isEmpty))
                      pw.Text("정보 없음", style: const pw.TextStyle(fontSize: 12))
                  ]
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text("■ 기존 관리업체 정보", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Text(_prevCompanyInfoCtrl.text.trim().isEmpty ? '정보 없음' : _prevCompanyInfoCtrl.text, style: const pw.TextStyle(fontSize: 12)),
            ),
            pw.SizedBox(height: 16),
            pw.Text("■ 비고 (특이사항)", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Text(_remarksCtrl.text.trim().isEmpty ? '내용 없음' : _remarksCtrl.text, style: const pw.TextStyle(fontSize: 12)),
            ),
            pw.SizedBox(height: 24),
            pw.Text("■ 인수인계 세부 내역", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            // 💡 수정: where 필터링 삭제. 체크 여부 상관없이 모든 항목을 출력합니다.
            ..._currentCheckItems.map((item) {
              bool isChecked = item['isChecked'] == true;
              String memoText = (item['memo'] != null && item['memo'].toString().trim().isNotEmpty)
                  ? item['memo']
                  : ""; // 메모가 없으면 공란으로 처리

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(5),
                decoration: isChecked ? pw.BoxDecoration(color: PdfColors.green50) : null,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(isChecked ? "[V] " : "[ ] ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item['title'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2, left: 4),
                            child: pw.Text("└ 메모: $memoText", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 70, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Text(":", style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 4),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_buildingNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('건물명을 입력해주세요.')));
      return;
    }
    try {
      if (widget.data == null) {
        await _salesService.addChecklist(
            buildingName: _buildingNameCtrl.text,
            address: _buildingAddressCtrl.text,
            contractDate: _startDate,
            prevCompany: _prevCompanyInfoCtrl.text,
            committeeMembers: _committeeList,
            remarks: _remarksCtrl.text,
            checkItems: _currentCheckItems,
            author: widget.authorName,
            bldArea: _householdCtrl.text,
            bldFloor: _elevatorCtrl.text,
            bldUsage: _parkingCtrl.text
        );
      } else {
        await _salesService.updateChecklist(
            docId: widget.data!['id'],
            buildingName: _buildingNameCtrl.text,
            address: _buildingAddressCtrl.text,
            contractDate: _startDate,
            prevCompany: _prevCompanyInfoCtrl.text,
            committeeMembers: _committeeList,
            remarks: _remarksCtrl.text,
            checkItems: _currentCheckItems,
            bldArea: _householdCtrl.text,
            bldFloor: _elevatorCtrl.text,
            bldUsage: _parkingCtrl.text
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 중 오류가 발생했습니다.')));
    }
  }

  Future<void> _delete() async {
    if (widget.data == null) return;
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("삭제 확인", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("데이터가 전부 삭제됩니다. 계속하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    if (confirm == true) {
      await _salesService.deleteChecklist(widget.data!['id']);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("체크리스트가 삭제되었습니다.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isMobile ? 10 : 20),
      child: CommonCard(
        width: min(1000, screenWidth * 0.95),
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🌟 [UI 고도화] 제목 옆에 작성자 정보(직책 포함)를 깔끔한 배지 형태로 표시
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8, // 모바일 화면이 좁아서 줄바꿈될 때의 간격
                      children: [
                        const Text("인수인계 정보 입력", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight, // 테마의 연한 배경색 적용
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person, size: 14, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                  widget.data?['author'] ?? widget.authorName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 우측 버튼들 (복사/공유/프린트/닫기) 유지
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.copy, size: 24), onPressed: _copyToClipboard, tooltip: "복사"),
                      IconButton(icon: const Icon(Icons.share_outlined, color: AppTheme.primaryColor, size: 26), onPressed: () => Share.share(_formatChecklistText()), tooltip: "공유"),
                      IconButton(icon: const Icon(Icons.print_outlined, size: 26), onPressed: _printChecklist, tooltip: "출력"),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.close, size: 26), onPressed: () => Navigator.pop(context)),
                    ],
                  )
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),

            // 내용 (스크롤)
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("1. 기본 및 건물 정보", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      const SizedBox(height: 12),

                      // 1행: 건물명, 날짜
                      isMobile
                          ? Column(children: [
                        _buildTextField("건물명", _buildingNameCtrl),
                        const SizedBox(height: 12),
                        _buildDatePicker("관리시작일"),
                      ])
                          : Row(children: [
                        Expanded(child: _buildTextField("건물명", _buildingNameCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDatePicker("관리시작일")),
                      ]),
                      const SizedBox(height: 12),

                      _buildTextField("주소", _buildingAddressCtrl),
                      const SizedBox(height: 12),

                      // 3행: 세대수, 승강기, 주차
                      isMobile
                          ? Column(children: [
                        _buildTextField("세대수", _householdCtrl),
                        const SizedBox(height: 8),
                        _buildTextField("승강기", _elevatorCtrl),
                        const SizedBox(height: 8),
                        _buildTextField("주차대수", _parkingCtrl),
                      ])
                          : Row(children: [
                        Expanded(child: _buildTextField("세대수", _householdCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField("승강기", _elevatorCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField("주차대수", _parkingCtrl)),
                      ]),

                      const SizedBox(height: 24),

                      // 2. 입주자대표/관리단 정보
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("2. 입주자대표 / 관리단 정보", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          TextButton.icon(
                            onPressed: () => setState(() => _committeeList.add({'unit': '', 'role': '', 'name': '', 'contact': ''})),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("인원 추가"),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),

                      ..._committeeList.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var member = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8), color: Colors.grey[50]),
                          child: isMobile
                              ? Column(children: [
                            Row(children: [
                              Expanded(child: TextFormField(initialValue: member['unit'], decoration: const InputDecoration(labelText: "동/호수", isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), onChanged: (v) => member['unit'] = v)),
                              const SizedBox(width: 8),
                              Expanded(child: TextFormField(initialValue: member['role'], decoration: const InputDecoration(labelText: "직책", isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), onChanged: (v) => member['role'] = v)),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: TextFormField(initialValue: member['name'], decoration: const InputDecoration(labelText: "성함", isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), onChanged: (v) => member['name'] = v)),
                              const SizedBox(width: 8),
                              Expanded(child: TextFormField(initialValue: member['contact'], decoration: const InputDecoration(labelText: "연락처", isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), onChanged: (v) => member['contact'] = v)),
                            ]),
                            Align(alignment: Alignment.centerRight, child: TextButton.icon(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 18), label: const Text("삭제", style: TextStyle(color: AppTheme.errorColor)), onPressed: () { setState(() { if(_committeeList.length > 1) _committeeList.removeAt(idx); else _committeeList[0] = {'unit': '', 'role': '', 'name': '', 'contact': ''}; }); })),
                          ])
                              : Row(children: [
                            Expanded(flex: 2, child: TextFormField(initialValue: member['unit'], decoration: const InputDecoration(labelText: "동/호수", isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), onChanged: (v) => member['unit'] = v)),
                            const SizedBox(width: 8),
                            Expanded(flex: 2, child: TextFormField(initialValue: member['role'], decoration: const InputDecoration(labelText: "직책", isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), onChanged: (v) => member['role'] = v)),
                            const SizedBox(width: 8),
                            Expanded(flex: 2, child: TextFormField(initialValue: member['name'], decoration: const InputDecoration(labelText: "성함", isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), onChanged: (v) => member['name'] = v)),
                            const SizedBox(width: 8),
                            Expanded(flex: 3, child: TextFormField(initialValue: member['contact'], decoration: const InputDecoration(labelText: "연락처", isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), onChanged: (v) => member['contact'] = v)),
                            const SizedBox(width: 8),
                            IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor), onPressed: () { setState(() { if(_committeeList.length > 1) _committeeList.removeAt(idx); else _committeeList[0] = {'unit': '', 'role': '', 'name': '', 'contact': ''}; }); })
                          ]),
                        );
                      }).toList(),

                      const SizedBox(height: 24),
                      const Text("3. 기존 관리업체 정보", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      const SizedBox(height: 12),
                      _buildTextField("업체명 / 담당자 / 연락처 / 인수인계일 등", _prevCompanyInfoCtrl, maxLines: null),

                      const SizedBox(height: 24),
                      const Text("4. 비고 (특이사항)", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      const SizedBox(height: 12),
                      _buildTextField("기타 특이사항 입력", _remarksCtrl, maxLines: null),

                      const SizedBox(height: 24),
                      const Text("5. 인수인계 체크리스트", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      const Divider(),
                      ..._currentCheckItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: item['isChecked'] ? AppTheme.primaryColor : AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(8),
                            color: item['isChecked'] ? const Color(0xFFE8F5E9) : Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                title: Text(item['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                value: item['isChecked'] ?? false,
                                activeColor: AppTheme.primaryColor,
                                onChanged: (val) => setState(() => item['isChecked'] = val!),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                                child: TextFormField(
                                  initialValue: item['memo'],
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  decoration: const InputDecoration(
                                    hintText: "상세 메모 입력 (엔터로 줄바꿈 가능)",
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                  onChanged: (val) {
                                    item['memo'] = val;
                                    if (val.isNotEmpty && item['isChecked'] == false) {
                                      setState(() => item['isChecked'] = true);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 버튼
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (widget.data != null)
                    Expanded(
                      child: TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text("삭제"),
                      ),
                    ),
                  if (widget.data != null) const SizedBox(width: 10),
                  Expanded(flex: 2, child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("취소"))),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: CommonButton(text: "저장", onPressed: _save)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int? maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: maxLines == null ? TextInputType.multiline : TextInputType.text,
      textInputAction: maxLines == null ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDatePicker(String label) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) setState(() => _startDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
      ),
    );
  }
}