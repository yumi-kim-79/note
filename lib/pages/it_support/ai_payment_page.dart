// 전산업무지원 / AI자동수납
//
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:excel/excel.dart' as ex show Border, BorderStyle; // 🌟 엑셀 전용 테두리 설정을 위해 추가!
import 'package:cp949_codec/cp949_codec.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:html' as html; // 🌟 [추가] 웹에서 엑셀 다운로드를 위한 패키지
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'package:csv/csv.dart'; // 👈 이 줄을 꼭 추가해주세요!

// --- 데이터 모델 ---
class ResidentRow {
  final String dong;
  final String ho;
  String owner;
  String resident;
  List<String> others;
  String type;
  String remark;
  bool isMatched;
  bool isCheckRequired;
  String matchedBankText;
  String matchedField;
  int matchedAmount;
  String matchedBankName;
  String matchedDate;
  String matchedMemo;
  String matchedName;
  BankTx? matchedTx;
  String managerMemo;

  bool isMerged;
  // 🌟 [개별 취소 고도화] 흡수한 데이터를 기억하기 위한 비밀 주머니
  ResidentRow? originalMain;
  ResidentRow? originalSub;

  ResidentRow({
    required this.dong, required this.ho, this.owner = "", this.resident = "",
    required this.others, this.type = "", this.remark = "",
    this.isMatched = false, this.isCheckRequired = false, this.matchedBankText = "",
    this.matchedField = "", this.matchedAmount = 0, this.matchedBankName = "",
    this.matchedDate = "", this.matchedMemo = "", this.matchedName = "", this.matchedTx, this.managerMemo = "",
    this.isMerged = false,
  });

  ResidentRow copy() {
    var r = ResidentRow(
      dong: dong, ho: ho, owner: owner, resident: resident,
      others: List.from(others), type: type, remark: remark,
      isMatched: isMatched, isCheckRequired: isCheckRequired,
      matchedBankText: matchedBankText, matchedField: matchedField,
      matchedAmount: matchedAmount, matchedBankName: matchedBankName,
      matchedDate: matchedDate, matchedMemo: matchedMemo, matchedName: matchedName,
      matchedTx: matchedTx, managerMemo: managerMemo,
      isMerged: isMerged,
    );
    r.originalMain = originalMain;
    r.originalSub = originalSub;
    return r;
  }
}

class BankTx {
  final String description;
  final int amount;
  final String bankName;
  final String date;
  final String memo;
  bool isUsed = false;

  // 👇👇 [신규 추가] 가상계좌 판단용 특수 필드
  String txType;
  String cmsCode;

  // 🌟 [추가] 미확인 입금 수동 매칭용 입력 필드들
  String inputDong = "";
  String inputHo = "";
  String inputOwner = "";
  String inputResident = "";
  String inputOthers = "";
  String inputType = "";
  String inputRemark = "";
  String managerMemo = "";

  BankTx({
    required this.description, required this.amount,
    this.bankName = "", this.date = "", this.memo = "",
    this.txType = "", this.cmsCode = "" // 👇 추가됨
  });
}

class AiPaymentPage extends StatefulWidget {
  const AiPaymentPage({super.key});
  @override
  State<AiPaymentPage> createState() => _AiPaymentPageState();
}

class _AiPaymentPageState extends State<AiPaymentPage> {
  List<ResidentRow> _residentList = [];
  List<BankTx> _bankList = [];
  bool _isResidentLoaded = false;
  bool _isBankLoaded = false;
  bool _isProcessing = false;
  List<bool> _showOtherCols = [false, false, false, false];

  Set<ResidentRow> _processedReceipts = {}; // 기존에 추가하신 삭선 기억 바구니
  ResidentRow? _activeReceiptRow; // 👇👇 🌟 [신규 추가] 현재 파란색으로 작업 중인 행을 기억! 👇👇

  String _othersSearch = "";
  String _remarkSearch = "";
  String _bankSearch = ""; // 미확인 탭 통합 검색용
  final TextEditingController _othersCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();
  final TextEditingController _bankCtrl = TextEditingController();
  String _aiSearch = "";
  final TextEditingController _aiCtrl = TextEditingController();

  // 🌟 [추가] 개별 병합 해제 엔진 (마이너스 버튼 클릭 시 작동)
  void _unmergeRow(ResidentRow row) {
    if (row.originalMain == null || row.originalSub == null) return;

    setState(() {
      ResidentRow subToRestore = row.originalSub!;

      // 1. 현재 행(main)을 병합 전 상태로 완벽히 롤백
      row.owner = row.originalMain!.owner;
      row.resident = row.originalMain!.resident;
      row.others = List.from(row.originalMain!.others);
      row.type = row.originalMain!.type;
      row.remark = row.originalMain!.remark;
      row.isMatched = row.originalMain!.isMatched;
      row.isCheckRequired = row.originalMain!.isCheckRequired;
      row.matchedBankText = row.originalMain!.matchedBankText;
      row.matchedField = row.originalMain!.matchedField;
      row.matchedAmount = row.originalMain!.matchedAmount;
      row.matchedBankName = row.originalMain!.matchedBankName;
      row.matchedDate = row.originalMain!.matchedDate;
      row.matchedMemo = row.originalMain!.matchedMemo;
      row.matchedTx = row.originalMain!.matchedTx;
      row.managerMemo = row.originalMain!.managerMemo;

      row.isMerged = false;
      row.originalMain = null;
      row.originalSub = null;

      // 2. 흡수당했던 행(sub)을 바로 밑에 다시 부활시킴
      int idx = _residentList.indexOf(row);
      if (idx != -1) {
        _residentList.insert(idx + 1, subToRestore);
      } else {
        _residentList.add(subToRestore);
      }
    });
    _showSnackBar("${row.dong}동 ${row.ho}호 병합이 개별 해제되었습니다.");
  }

  // =======================================================
  // 🌟 [고도화] 담당자 전용 '수납 팝업창' (전체화면 + 메모 + 총계 + 엑셀 + 체크박스 계산기)
  // =======================================================
  void _showReceiptPopup() {
    // 1. 일반 매칭완료 데이터 준비
    List<ResidentRow> matchedList = _residentList.where((r) {
      if (!r.isMatched || r.isCheckRequired) return false;
      if (r.matchedTx != null && (_isAutoPaymentTx(r.matchedTx!) || _isVirtualAccountTx(r.matchedTx!))) return false;
      return true;
    }).toList();

    // 2. 자동이체 및 가상계좌 데이터 준비
    List<BankTx> autoList = _bankList.where((tx) => tx.amount > 0 && _isAutoPaymentTx(tx)).toList();
    List<BankTx> vBankList = _bankList.where((tx) => tx.amount > 0 && _isVirtualAccountTx(tx)).toList();

    if (matchedList.isEmpty && autoList.isEmpty && vBankList.isEmpty) {
      _showSnackBar("표시할 수납 데이터가 없습니다.");
      return;
    }

    int popupMainTab = 0;
    int popupSubTab = 0;
    int sortMode = 0;
    String selectedDong = "전체";

    // 👇 🌟 [요구사항 반영] 체크된 항목들을 담아둘 마법의 바구니 생성!
    Set<BankTx> checkedBankTxs = {};

    List<String> availableDongs = matchedList.map((r) => r.dong).where((d) => d.isNotEmpty).toSet().toList();
    availableDongs.sort((a, b) {
      int? numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), ''));
      int? numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numA != null && numB != null) return numA.compareTo(numB);
      return a.compareTo(b);
    });

    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {

                List<ResidentRow> displayList = matchedList.where((r) {
                  if (selectedDong != "전체" && r.dong != selectedDong) return false;
                  return true;
                }).toList();
                if (sortMode == 1) displayList.sort((a, b) => a.matchedDate.compareTo(b.matchedDate));
                else if (sortMode == 2) displayList.sort((a, b) => b.matchedDate.compareTo(a.matchedDate));

                int totalAmt = 0; int rcvAmt = 0; int unRcvAmt = 0;
                int totalCnt = displayList.length; int rcvCnt = 0; int unRcvCnt = 0;
                for(var r in displayList) {
                  totalAmt += r.matchedAmount;
                  if(_processedReceipts.contains(r)) { rcvAmt += r.matchedAmount; rcvCnt++; }
                  else { unRcvAmt += r.matchedAmount; unRcvCnt++; }
                }

                List<BankTx> displayBankList = popupSubTab == 0 ? autoList : vBankList;
                int bankTotalAmt = displayBankList.fold(0, (sum, tx) => sum + tx.amount);
                // 👇 🌟 [요구사항 계산] 체크된 항목들의 합계
                int checkedTotalAmt = checkedBankTxs.fold(0, (sum, tx) => sum + tx.amount);

                // 👇 🌟 [초고도화 엑셀 다운로드] 탭과 상관없이 3개의 시트(일반, 자동이체, 가상계좌)를 하나로 묶어 한 번에 뽑아줍니다!
                void downloadReceiptExcel() {
                  var excel = Excel.createExcel();
                  String defaultSheet = excel.getDefaultSheet() ?? "Sheet1";
                  excel.rename(defaultSheet, "일반수납");

                  // ==========================================
                  // 1️⃣ 일반 수납 내역 시트
                  // ==========================================
                  var sheet1 = excel["일반수납"];
                  sheet1.appendRow([TextCellValue("거래일"), TextCellValue("입금액"), TextCellValue("동"), TextCellValue("호"), TextCellValue("매칭이름"), TextCellValue("내용 및 거래내용"), TextCellValue("상대은행"), TextCellValue("담당자 메모"), TextCellValue("수납상태")]);

                  // 필터 무시하고 '하나도 빠짐없이' 전체 명단을 정렬만 맞춰서 가져옵니다.
                  List<ResidentRow> exportMatched = List.from(matchedList);
                  if (sortMode == 1) exportMatched.sort((a, b) => a.matchedDate.compareTo(b.matchedDate));
                  else if (sortMode == 2) exportMatched.sort((a, b) => b.matchedDate.compareTo(a.matchedDate));

                  int totalAmt1 = 0; int rcvAmt1 = 0; int unRcvAmt1 = 0;
                  int rcvCnt1 = 0; int unRcvCnt1 = 0;

                  for(var row in exportMatched) {
                    bool isProcessed = _processedReceipts.contains(row);
                    totalAmt1 += row.matchedAmount;
                    if (isProcessed) { rcvAmt1 += row.matchedAmount; rcvCnt1++; }
                    else { unRcvAmt1 += row.matchedAmount; unRcvCnt1++; }

                    sheet1.appendRow([
                      TextCellValue(row.matchedDate.split(' ')[0]), TextCellValue(_formatCurrency(row.matchedAmount)), TextCellValue(row.dong), TextCellValue(row.ho), TextCellValue(row.matchedName), TextCellValue(row.matchedBankText), TextCellValue(row.matchedBankName), TextCellValue(row.managerMemo), TextCellValue(isProcessed ? "수납완료" : "미수납")
                    ]);
                    int rIdx = sheet1.maxRows - 1;
                    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rIdx)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4')); // 메모 노란색
                    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rIdx)).cellStyle = CellStyle(fontColorHex: isProcessed ? ExcelColor.fromHexString('#FF4CAF50') : ExcelColor.fromHexString('#FFF44336'), bold: true);
                  }
                  sheet1.appendRow([TextCellValue("")]);
                  sheet1.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액")]);
                  sheet1.appendRow([TextCellValue("입금액 총액"), TextCellValue("${exportMatched.length}건"), TextCellValue("${_formatCurrency(totalAmt1)}원")]);
                  sheet1.appendRow([TextCellValue("수납액 총액"), TextCellValue("${rcvCnt1}건"), TextCellValue("${_formatCurrency(rcvAmt1)}원")]);
                  sheet1.appendRow([TextCellValue("미수납액 총액"), TextCellValue("${unRcvCnt1}건"), TextCellValue("${_formatCurrency(unRcvAmt1)}원")]);

                  // ==========================================
                  // 2️⃣ 자동이체 (PG/카드) 시트
                  // ==========================================
                  var sheet2 = excel["자동이체(PG_카드)"];
                  sheet2.appendRow([TextCellValue("동"), TextCellValue("호"), TextCellValue("거래일시"), TextCellValue("구분"), TextCellValue("적요(내용)"), TextCellValue("입금액"), TextCellValue("상대은행"), TextCellValue("담당자 메모")]);

                  int totalAmt2 = 0;
                  for (var tx in autoList) {
                    totalAmt2 += tx.amount;
                    String dong = "-"; String ho = "-";
                    if (tx.isUsed) { try { var mr = _residentList.firstWhere((r) => r.matchedTx == tx); dong = mr.dong; ho = mr.ho; } catch (e) {} }

                    sheet2.appendRow([
                      TextCellValue(dong), TextCellValue(ho), TextCellValue(tx.date), TextCellValue("자동납부(PG)"), TextCellValue(tx.description), TextCellValue(_formatCurrency(tx.amount)), TextCellValue(tx.bankName), TextCellValue(tx.managerMemo)
                    ]);
                    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: sheet2.maxRows - 1)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4')); // 메모 노란색
                  }
                  sheet2.appendRow([TextCellValue("")]);
                  sheet2.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액")]);
                  sheet2.appendRow([TextCellValue("총 수납액"), TextCellValue("${autoList.length}건"), TextCellValue("${_formatCurrency(totalAmt2)}원")]);

                  // ==========================================
                  // 3️⃣ 가상계좌 (제휴/아파트아이) 시트
                  // ==========================================
                  var sheet3 = excel["가상계좌(제휴_아파트아이)"];
                  sheet3.appendRow([TextCellValue("동"), TextCellValue("호"), TextCellValue("거래일시"), TextCellValue("구분"), TextCellValue("적요(내용)"), TextCellValue("입금액"), TextCellValue("상대은행"), TextCellValue("담당자 메모")]);

                  int totalAmt3 = 0;
                  for (var tx in vBankList) {
                    totalAmt3 += tx.amount;
                    String dong = "-"; String ho = "-";
                    if (tx.isUsed) { try { var mr = _residentList.firstWhere((r) => r.matchedTx == tx); dong = mr.dong; ho = mr.ho; } catch (e) {} }

                    sheet3.appendRow([
                      TextCellValue(dong), TextCellValue(ho), TextCellValue(tx.date), TextCellValue("가상계좌/제휴"), TextCellValue(tx.description), TextCellValue(_formatCurrency(tx.amount)), TextCellValue(tx.bankName), TextCellValue(tx.managerMemo)
                    ]);
                    sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: sheet3.maxRows - 1)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4')); // 메모 노란색
                  }
                  sheet3.appendRow([TextCellValue("")]);
                  sheet3.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액")]);
                  sheet3.appendRow([TextCellValue("총 수납액"), TextCellValue("${vBankList.length}건"), TextCellValue("${_formatCurrency(totalAmt3)}원")]);

                  // ==========================================
                  // 4️⃣ 확인필요 내역 시트 (추가)
                  // ==========================================
                  var sheet4 = excel["확인필요"];
                  sheet4.appendRow([TextCellValue("동"), TextCellValue("호"), TextCellValue("소유자"), TextCellValue("입주자"), TextCellValue("입금일자"), TextCellValue("입금액"), TextCellValue("상대은행"), TextCellValue("은행적요(내용)"), TextCellValue("매칭사유(AI판단)"), TextCellValue("담당자 메모")]);

                  int totalCheckAmt = 0;
                  var checkList = _residentList.where((r) {
                    if (!r.isMatched || !r.isCheckRequired) return false;
                    if (r.matchedTx != null && (_isAutoPaymentTx(r.matchedTx!) || _isVirtualAccountTx(r.matchedTx!))) return false;
                    return true;
                  }).toList();

                  for (var r in checkList) {
                    totalCheckAmt += r.matchedAmount;
                    sheet4.appendRow([
                      TextCellValue(r.dong), TextCellValue(r.ho), TextCellValue(r.owner), TextCellValue(r.resident), TextCellValue(r.matchedDate.split(' ')[0]), TextCellValue(_formatCurrency(r.matchedAmount)), TextCellValue(r.matchedBankName), TextCellValue(r.matchedBankText), TextCellValue(r.matchedField), TextCellValue(r.managerMemo)
                    ]);
                    sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: sheet4.maxRows - 1)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4')); // 메모 노란색
                  }
                  sheet4.appendRow([TextCellValue("")]);
                  sheet4.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액")]);
                  sheet4.appendRow([TextCellValue("확인필요 총액"), TextCellValue("${checkList.length}건"), TextCellValue("${_formatCurrency(totalCheckAmt)}원")]);

                  // 요약 부분 볼드 강조 및 오렌지색 글씨
                  int s4Max = sheet4.maxRows - 1;
                  sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: s4Max)).cellStyle = CellStyle(bold: true);
                  sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: s4Max)).cellStyle = CellStyle(bold: true);
                  sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: s4Max)).cellStyle = CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#FFFF9800'));

                  // ==========================================
                  // 5️⃣ 미확인 입금 내역 시트 (추가)
                  // ==========================================
                  var sheet5 = excel["미확인입금"];
                  sheet5.appendRow([TextCellValue("거래일시"), TextCellValue("입금액"), TextCellValue("적요(내용)"), TextCellValue("상대은행"), TextCellValue("담당자 메모")]);

                  int totalUnconfirmedAmt = 0;
                  var unconfirmedList = _bankList.where((tx) => !tx.isUsed && tx.amount > 0 && !_isAutoPaymentTx(tx) && !_isVirtualAccountTx(tx)).toList();

                  for (var tx in unconfirmedList) {
                    totalUnconfirmedAmt += tx.amount;
                    sheet5.appendRow([
                      TextCellValue(tx.date), TextCellValue(_formatCurrency(tx.amount)), TextCellValue(tx.description), TextCellValue(tx.bankName), TextCellValue(tx.managerMemo)
                    ]);
                    sheet5.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: sheet5.maxRows - 1)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4')); // 메모 노란색
                  }
                  sheet5.appendRow([TextCellValue("")]);
                  sheet5.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액")]);
                  sheet5.appendRow([TextCellValue("미확인입금 총액"), TextCellValue("${unconfirmedList.length}건"), TextCellValue("${_formatCurrency(totalUnconfirmedAmt)}원")]);

                  // 요약 부분 볼드 강조 및 빨간색 글씨
                  int s5Max = sheet5.maxRows - 1;
                  sheet5.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: s5Max)).cellStyle = CellStyle(bold: true);
                  sheet5.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: s5Max)).cellStyle = CellStyle(bold: true);
                  sheet5.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: s5Max)).cellStyle = CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#FFF44336'));

                  // 최종 파일 생성 및 다운로드
                  var bytes = excel.encode();
                  if (bytes != null) {
                    DateTime n = DateTime.now();
                    String dateStr = "${n.year}${n.month.toString().padLeft(2,'0')}${n.day.toString().padLeft(2,'0')}";
                    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
                    final url = html.Url.createObjectUrlFromBlob(blob);
                    html.AnchorElement(href: url)..setAttribute("download", "[수납전산처리_통합본]_$dateStr.xlsx")..click();
                    html.Url.revokeObjectUrl(url);
                    _showSnackBar("통합 수납 리스트 엑셀 다운로드가 완료되었습니다.");
                  }
                }

                void editMemoInDialog(dynamic rowOrTx) {
                  TextEditingController ctrl = TextEditingController(text: rowOrTx.managerMemo);
                  String title = rowOrTx is ResidentRow ? "${rowOrTx.dong}동 ${rowOrTx.ho}호 메모" : "수납 메모";
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
                        ElevatedButton(onPressed: () {
                          String newText = ctrl.text.trim();
                          if (newText.isNotEmpty && newText != rowOrTx.managerMemo) {
                            final now = DateTime.now();
                            newText = "[${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}] $newText";
                          }
                          setDialogState(() => rowOrTx.managerMemo = newText);
                          setState(() {});
                          Navigator.pop(ctx);
                        }, child: const Text("저장"))
                      ]
                  ));
                }

                Widget buildTabButton(String title, int tabIndex) {
                  bool isActive = popupMainTab == tabIndex;
                  return InkWell(
                    onTap: () => setDialogState(() => popupMainTab = tabIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: isActive ? Colors.blue[800] : Colors.grey[200], borderRadius: BorderRadius.circular(8), boxShadow: isActive ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : []),
                      child: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  );
                }

                Widget buildTotalBox(String title, int amount, Color color) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${_formatCurrency(amount)} 원", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                    ]),
                  );
                }

                return Dialog(
                    insetPadding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                        width: double.maxFinite, height: double.maxFinite, padding: const EdgeInsets.all(24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Icon(Icons.fact_check, color: Colors.blue[700], size: 28),
                                    const SizedBox(width: 8),
                                    Text(popupMainTab == 0 ? "수납 전산처리 (일반매칭)" : "대행사 수납 확인 (자동/가상)", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  ]),
                                  Row(children: [
                                    buildTabButton("일반 수납 내역", 0),
                                    const SizedBox(width: 8),
                                    buildTabButton("자동/가상 수납 내역", 1),
                                  ]),
                                  Row(children: [
                                    ElevatedButton.icon(
                                        onPressed: downloadReceiptExcel,
                                        icon: const Icon(Icons.download, size: 18),
                                        label: const Text("엑셀 다운로드", style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(icon: const Icon(Icons.close, size: 32), onPressed: () => Navigator.pop(ctx)),
                                  ])
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (popupMainTab == 0) ...[
                                // ==========================================
                                // 🌟 [탭 0] 일반 매칭완료 내역
                                // ==========================================
                                Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey[300]!), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                                    child: Row(children: [
                                      Expanded(flex: 3, child: InkWell(
                                          onTap: () { setDialogState(() { sortMode = (sortMode + 1) % 3; }); },
                                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("거래일", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 2), Icon(sortMode == 0 ? Icons.sort : (sortMode == 1 ? Icons.arrow_upward : Icons.arrow_downward), size: 16, color: sortMode == 0 ? Colors.grey : Colors.blue[700]), if (sortMode == 1) const Text("(빠른순)", style: TextStyle(fontSize: 10, color: Colors.blue)), if (sortMode == 2) const Text("(느린순)", style: TextStyle(fontSize: 10, color: Colors.blue))])
                                      )),
                                      const Expanded(flex: 3, child: Center(child: Text("입금액", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      Expanded(flex: 7, child: Container(
                                          decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.grey[300]!))),
                                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                                            Container(width: double.infinity, alignment: Alignment.center, padding: const EdgeInsets.only(bottom: 4), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))), child: const Text("SM명부자료", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                                            Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
                                              Expanded(flex: 2, child: Container(alignment: Alignment.center, height: 22, child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: selectedDong, isDense: true, icon: const Icon(Icons.filter_list, size: 14, color: Colors.blue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue), items: ["전체", ...availableDongs].map((dong) => DropdownMenuItem<String>(value: dong, child: Text(dong == "전체" ? "동(전체)" : "$dong동", style: const TextStyle(fontSize: 11)))).toList(), onChanged: (val) { if (val != null) setDialogState(() { selectedDong = val; }); })))),
                                              const Expanded(flex: 2, child: Center(child: Text("호", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                              const Expanded(flex: 3, child: Center(child: Text("매칭이름", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))))
                                            ]))
                                          ])
                                      )),
                                      const Expanded(flex: 5, child: Center(child: Text("내용 및 거래내용", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 3, child: Center(child: Text("상대은행", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 4, child: Center(child: Text("담당자 메모", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    ])
                                ),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!)),
                                    child: ListView.builder(
                                        itemCount: displayList.length,
                                        itemBuilder: (context, index) {
                                          var row = displayList[index];
                                          String matchedName = row.matchedName;
                                          bool isActive = _activeReceiptRow == row;
                                          bool isProcessed = _processedReceipts.contains(row) && !isActive;
                                          Color bgColor = isActive ? Colors.blue.withOpacity(0.15) : (isProcessed ? Colors.grey[100]! : (index % 2 == 0 ? Colors.white : Colors.grey[50]!));

                                          TextStyle _rowStyle(Color baseColor, {bool isBold = false, double size = 12}) {
                                            if (isActive) return TextStyle(fontSize: size * 1.4, fontWeight: FontWeight.w900, color: Colors.blue[900]);
                                            else if (isProcessed) return TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.grey[400], decoration: TextDecoration.lineThrough, decorationColor: Colors.grey[500]);
                                            else return TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: baseColor);
                                          }
                                          Widget _safeText(String text, TextStyle style, int flex) {
                                            return Expanded(flex: flex, child: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 4), child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: style))));
                                          }

                                          return InkWell(
                                              onTap: () {
                                                setDialogState(() {
                                                  if (_activeReceiptRow == row) { _processedReceipts.add(row); _activeReceiptRow = null; }
                                                  else { if (_activeReceiptRow != null) _processedReceipts.add(_activeReceiptRow!); _activeReceiptRow = row; _processedReceipts.remove(row); }
                                                });
                                              },
                                              child: Container(
                                                  decoration: BoxDecoration(color: bgColor, border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  child: Row(children: [
                                                    Expanded(flex: 3, child: Stack(alignment: Alignment.center, children: [
                                                      if (isProcessed) Positioned(left: 2, child: InkWell(onTap: () { setDialogState(() { _processedReceipts.remove(row); }); }, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.withOpacity(0.3))), child: const Icon(Icons.close, size: 12, color: Colors.red)))),
                                                      Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: FittedBox(fit: BoxFit.scaleDown, child: Text(row.matchedDate.split(' ')[0], style: _rowStyle(Colors.black87)))),
                                                    ])),
                                                    _safeText("${_formatCurrency(row.matchedAmount)}원", _rowStyle(Colors.blue[800]!, isBold: true, size: 13), 3),
                                                    _safeText(row.dong, _rowStyle(Colors.black87, isBold: true), 2),
                                                    _safeText(row.ho, _rowStyle(Colors.black87, isBold: true), 2),
                                                    _safeText(matchedName, _rowStyle(Colors.teal[700]!, isBold: true), 3),
                                                    _safeText(row.matchedBankText, _rowStyle(Colors.black87), 5),
                                                    _safeText(row.matchedBankName, _rowStyle(Colors.grey), 3),
                                                    Expanded(flex: 4, child: InkWell(
                                                        onTap: () => editMemoInDialog(row),
                                                        child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.all(4), alignment: Alignment.center, decoration: BoxDecoration(color: row.managerMemo.isEmpty ? Colors.white : Colors.yellow[100], border: Border.all(color: row.managerMemo.isEmpty ? Colors.grey[300]! : Colors.yellow[400]!), borderRadius: BorderRadius.circular(4)), child: Text(row.managerMemo.isEmpty ? "+ 메모" : row.managerMemo, style: TextStyle(fontSize: 10, color: row.managerMemo.isEmpty ? Colors.grey : Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis))
                                                    ))
                                                  ])
                                              )
                                          );
                                        }
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueGrey[100]!)),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text("✅ 수납체크 상태 :  $rcvCnt건 / 총 $totalCnt건", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
                                    Row(children: [
                                      buildTotalBox("입금액 총액 ($totalCnt건)", totalAmt, Colors.black87), const SizedBox(width: 16),
                                      buildTotalBox("수납액 총액 ($rcvCnt건)", rcvAmt, Colors.green[700]!), const SizedBox(width: 16),
                                      buildTotalBox("미수납액 총액 ($unRcvCnt건)", unRcvAmt, Colors.red[700]!),
                                    ])
                                  ]),
                                )

                              ] else ...[
                                // ==========================================
                                // 🌟 [탭 1] 자동/가상 수납 내역 (체크박스 탑재)
                                // ==========================================
                                Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      // 👇 🌟 [기능 개선] 라디오 버튼을 바꿀 때마다 체크된 목록(장바구니)을 비워줍니다.
                                      Radio<int>(value: 0, groupValue: popupSubTab, activeColor: Colors.indigo, onChanged: (v) => setDialogState(() { popupSubTab = v!; checkedBankTxs.clear(); })),
                                      Text("자동이체 (PG/카드) ${autoList.length}건", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 15)),
                                      const SizedBox(width: 40),
                                      Radio<int>(value: 1, groupValue: popupSubTab, activeColor: Colors.indigo, onChanged: (v) => setDialogState(() { popupSubTab = v!; checkedBankTxs.clear(); })),
                                      Text("가상계좌 (제휴/아파트아이) ${vBankList.length}건", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 15)),
                                    ])
                                ),
                                Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey[300]!), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                                    child: Row(children: [
                                      // 👇 🌟 [요구사항] 전체 선택/해제용 마스터 체크박스
                                      Expanded(flex: 3, child: Checkbox(
                                          value: displayBankList.isNotEmpty && checkedBankTxs.length == displayBankList.length,
                                          activeColor: Colors.indigo,
                                          onChanged: (val) {
                                            setDialogState(() {
                                              if (val == true) checkedBankTxs.addAll(displayBankList);
                                              else checkedBankTxs.clear();
                                            });
                                          }
                                      )),
                                      Expanded(flex: 5, child: Center(child: Text("동", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      Expanded(flex: 6, child: Center(child: Text("호", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      Expanded(flex: 10, child: Center(child: Text("거래일시", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      Expanded(flex: 12, child: Center(child: Text(popupSubTab == 0 ? "구분 (결제수단)" : "구분 (가상계좌)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      Expanded(flex: 22, child: Center(child: Text("적요 (입금내역)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      Expanded(flex: 10, child: Center(child: Text("입금액", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      Expanded(flex: 10, child: Center(child: Text("상대은행", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      Expanded(flex: 15, child: Center(child: Text("담당자 메모", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    ])
                                ),
                                Expanded(
                                    child: Container(
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!)),
                                        child: ListView.builder(
                                            itemCount: displayBankList.length,
                                            itemBuilder: (ctx, idx) {
                                              var tx = displayBankList[idx];
                                              String d = "-"; String h = "-";
                                              if (tx.isUsed) { try { var mr = _residentList.firstWhere((r) => r.matchedTx == tx); d = mr.dong; h = mr.ho; } catch(e){} }
                                              return Container(
                                                  decoration: BoxDecoration(
                                                      color: checkedBankTxs.contains(tx) ? Colors.indigo.withOpacity(0.1) : (idx % 2 == 0 ? Colors.white : Colors.indigo.withOpacity(0.02)),
                                                      border: Border(bottom: BorderSide(color: Colors.grey[200]!))
                                                  ),
                                                  child: Row(children: [
                                                    // 👇 🌟 [요구사항] 개별 체크박스
                                                    Expanded(flex: 3, child: Checkbox(
                                                        value: checkedBankTxs.contains(tx),
                                                        activeColor: Colors.indigo,
                                                        onChanged: (val) {
                                                          setDialogState(() {
                                                            if (val == true) checkedBankTxs.add(tx);
                                                            else checkedBankTxs.remove(tx);
                                                          });
                                                        }
                                                    )),
                                                    Expanded(flex: 5, child: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 16), child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                                    Expanded(flex: 6, child: Container(alignment: Alignment.center, child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                                    Expanded(flex: 10, child: Container(alignment: Alignment.center, child: Text(tx.date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
                                                    Expanded(flex: 12, child: Container(alignment: Alignment.center, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: popupSubTab == 1 ? Colors.teal : Colors.indigo, borderRadius: BorderRadius.circular(4)), child: Text(popupSubTab == 1 ? "가상계좌" : "자동납부(PG)", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))))),
                                                    Expanded(flex: 22, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text(tx.description, style: TextStyle(color: popupSubTab == 1 ? Colors.teal[900] : Colors.indigo[900], fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis))),
                                                    Expanded(flex: 10, child: Container(alignment: Alignment.center, child: Text("${_formatCurrency(tx.amount)}원", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                                    Expanded(flex: 10, child: Container(alignment: Alignment.center, child: Text(tx.bankName.isEmpty ? "-" : tx.bankName, style: const TextStyle(color: Colors.grey, fontSize: 12)))),
                                                    Expanded(flex: 15, child: InkWell(
                                                        onTap: () => editMemoInDialog(tx),
                                                        child: Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(8), alignment: Alignment.center, decoration: BoxDecoration(color: tx.managerMemo.isEmpty ? Colors.white : Colors.yellow[100], border: Border.all(color: tx.managerMemo.isEmpty ? Colors.grey[300]! : Colors.yellow[400]!), borderRadius: BorderRadius.circular(4)), child: Text(tx.managerMemo.isEmpty ? "+ 메모입력" : tx.managerMemo, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: tx.managerMemo.isEmpty ? Colors.grey : Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis))
                                                    )),
                                                  ])
                                              );
                                            }
                                        )
                                    )
                                ),
                                Container(
                                    margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigo[100]!)),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                      Text("총 ${displayBankList.length}건", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo[900])),
                                      const SizedBox(width: 32),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        // 👇 🌟 [요구사항] 선택된 항목들의 합계 금액 표시
                                        Text("☑️ 선택 항목 합계 (${checkedBankTxs.length}건)", style: TextStyle(fontSize: 13, color: Colors.indigo[500], fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text("${_formatCurrency(checkedTotalAmt)} 원", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo[600])),
                                        Container(margin: const EdgeInsets.symmetric(vertical: 6), width: 180, height: 1, color: Colors.indigo[200]), // 얇은 구분선

                                        // 👇 기존 전체 합계
                                        Text("전체 수납액 총합", style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text("${_formatCurrency(bankTotalAmt)} 원", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.indigo[900])),
                                      ])
                                    ])
                                )
                              ]
                            ]
                        )
                    )
                );
              }
          );
        }
    );
  }

  // 🌟 [핵심] 지능형 병합 엔진 (흡수 데이터 기억 로직 추가)
  void _handleSmartMerge(String dong, String ho) async {
    List<ResidentRow> targets = _residentList.where((r) => r.dong == dong && r.ho == ho).toList();
    if (targets.length < 2) return;

    int rowsWithMoney = targets.where((r) => r.matchedAmount > 0).length;
    if (rowsWithMoney > 1) {
      _showNoticePopup("병합 불가", "동일 세대에 각각 입금액이 존재합니다. 중복 입금일 가능성이 있어 합칠 수 없습니다.");
      return;
    }

    ResidentRow rowA = targets[0];
    ResidentRow rowB = targets[1];

    bool hasConflict = (rowA.owner.isNotEmpty && rowB.owner.isNotEmpty && rowA.owner != rowB.owner) ||
        (rowA.resident.isNotEmpty && rowB.resident.isNotEmpty && rowA.resident != rowB.resident);

    if (hasConflict) {
      _showMergeSelectionDialog(rowA, rowB);
    } else {
      _executeMerge(rowA, rowB);
    }
  }

  void _executeMerge(ResidentRow main, ResidentRow sub) {
    setState(() {
      // 🌟 [고도화] 나중에 해제할 수 있도록 현재 상태를 뱃속에 기억
      main.originalMain = main.copy();
      main.originalSub = sub.copy();

      if (main.owner.isEmpty) main.owner = sub.owner;
      if (main.resident.isEmpty) main.resident = sub.resident;
      if (main.type.isEmpty) main.type = sub.type;
      if (main.remark.isEmpty) main.remark = sub.remark;
      if (main.managerMemo.isEmpty) main.managerMemo = sub.managerMemo;

      if (sub.matchedAmount > 0) {
        main.isMatched = sub.isMatched;
        main.isCheckRequired = sub.isCheckRequired;
        main.matchedAmount = sub.matchedAmount;
        main.matchedBankText = sub.matchedBankText;
        main.matchedField = sub.matchedField;
        main.matchedBankName = sub.matchedBankName;
        main.matchedDate = sub.matchedDate;
        main.matchedMemo = sub.matchedMemo;
        main.matchedTx = sub.matchedTx;
      }

      main.isMerged = true;
      _residentList.remove(sub);
    });
    _showSnackBar("${main.dong}동 ${main.ho}호 데이터가 하나로 합쳐졌습니다.");
  }

  void _showMergeSelectionDialog(ResidentRow a, ResidentRow b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("정보 충돌 발생 - 선택해주세요"),
        content: const Text("양쪽 행에 서로 다른 정보가 있습니다.\n어느 쪽 정보를 유지하며 합칠까요?"),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); _executeMerge(a, b); },
            child: Text("위쪽 정보 유지 (${a.owner.isEmpty ? '미입력' : a.owner})"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              a.owner = b.owner; a.resident = b.resident;
              _executeMerge(a, b);
            },
            child: Text("아래쪽 정보 유지 (${b.owner.isEmpty ? '미입력' : b.owner})"),
          ),
        ],
      ),
    );
  }

  // 🌟 [추가] 필터 및 검색 상태 변수
  String _currentFilter = "all";
  String _ownerSearch = "";
  String _residentSearch = "";
  final TextEditingController _ownerCtrl = TextEditingController();
  final TextEditingController _residentCtrl = TextEditingController();
  int _sortTypeMode = 0;
  int _sortAiMode = 0;
  int _sortDateMode = 0; // 🌟 [추가] 거래일 정렬 모드 (0: 기본, 1: 빠른순, 2: 느린순)

  // 🌟 [추가] 거래일 정렬을 위한 클릭 가능한 헤더 위젯
  Widget _sortableDateHeader(int flex) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => setState(() {
          _sortDateMode = (_sortDateMode + 1) % 3;
          _sortAiMode = 0; // 날짜 정렬 시 다른 정렬은 초기화
          _sortTypeMode = 0;
        }),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("거래일시", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _sortDateMode > 0 ? AppTheme.primaryColor : AppTheme.textMain)),
                  Icon(Icons.sort, size: 14, color: _sortDateMode > 0 ? AppTheme.primaryColor : Colors.grey)
                ]
            ),
            if (_sortDateMode == 1) const Text("(빠른순)", style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            if (_sortDateMode == 2) const Text("(느린순)", style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // =======================================================
  // [도우미 함수] 안전한 텍스트 추출 및 금액 포맷터
  // =======================================================
  String _getSafe(List<String> row, int index) {
    if (index >= 0 && index < row.length) {
      return row[index].replaceAll('\n', '').replaceAll('\r', '').trim();
    }
    return "";
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;
    int maxLength = max(s1.length, s2.length);
    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);
    for (int i = 0; i <= s2.length; i++) v0[i] = i;
    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) v0[j] = v1[j];
    }
    return 1.0 - (v1[s2.length] / maxLength);
  }

  // =======================================================
  // 🛡️ [명부 로더] (동적 컬럼 인식 - 양식 호환성 강화)
  // =======================================================
  Future<void> _loadResidentExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx', 'xls', 'csv'], withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      String ext = result.files.single.extension?.toLowerCase() ?? '';
      final bytes = result.files.single.bytes;
      if (bytes == null) throw Exception("파일 데이터를 읽을 수 없습니다.");

      List<List<String>> rawRows = _getRowsFromBytes(ext, bytes);
      if (rawRows.isEmpty) throw Exception("데이터 추출에 실패했습니다.");

      int dataStartRow = -1;
      int ownerIdx = -1, residentIdx = -1, typeIdx = -1, remarkIdx = -1;
      List<int> otherIndices = [];

      for (int i = 0; i < min(30, rawRows.length); i++) {
        String fullRowText = rawRows[i].join('').replaceAll(' ', '').replaceAll('\n', '');

        if (fullRowText.contains('동') && fullRowText.contains('호')) {
          List<String> subRow = (i + 1 < rawRows.length)
              ? rawRows[i + 1].map((e) => e.replaceAll(' ', '').replaceAll('\n', '')).toList()
              : [];

          int findNameIdx(int idx) {
            if (subRow.isEmpty) return idx;
            bool isHeaderRow = subRow.any((e) => e.contains("성명") || e.contains("연락처") || e.contains("관계"));
            if (!isHeaderRow) return idx;
            for (int k = idx; k <= idx + 2 && k < subRow.length; k++) {
              if (subRow[k].contains("성명") || subRow[k].contains("이름")) return k;
            }
            return idx;
          }

          for (int j = 0; j < rawRows[i].length; j++) {
            String colName = rawRows[i][j].replaceAll(' ', '').replaceAll('\n', '');
            if (colName == "소유자") ownerIdx = findNameIdx(j);
            if (colName == "입주자") residentIdx = findNameIdx(j);
            if (colName.startsWith("기타")) otherIndices.add(findNameIdx(j));
            if (colName.contains("소유주/임차인") || colName == "구분") typeIdx = j;
            if (colName == "비고") remarkIdx = j;
          }

          dataStartRow = i + 1;
          if (subRow.any((e) => e.contains("성명") || e.contains("연락처"))) {
            dataStartRow++;
          }
          break;
        }
      }

      if (dataStartRow == -1) throw Exception("명부 데이터를 찾을 수 없습니다.");

      List<ResidentRow> tempResidentList = [];
      List<bool> activeOthers = [false, false, false, false];

      for (int i = dataStartRow; i < rawRows.length; i++) {
        var row = rawRows[i];
        String dong = _getSafe(row, 0);
        String ho = _getSafe(row, 1);

        if (dong.isEmpty && ho.isEmpty) continue;
        if (dong == "성명" || ho == "연락처") continue;

        int offset = (ownerIdx != -1 && rawRows[dataStartRow-1].length > ownerIdx && rawRows[dataStartRow-1][ownerIdx].contains("성명")) ? 0 : 0;

        String owner = ownerIdx != -1 ? _getSafe(row, ownerIdx + offset) : "";
        String resident = residentIdx != -1 ? _getSafe(row, residentIdx + offset) : "";

        List<String> others = [];
        for (int j = 0; j < otherIndices.length && j < 4; j++) {
          String val = _getSafe(row, otherIndices[j] + offset);
          others.add(val.isEmpty ? "-" : val);
          if (val.isNotEmpty && val != "-") activeOthers[j] = true;
        }

        while(others.length < 4) others.add("-");

        String type = typeIdx != -1 ? _getSafe(row, typeIdx) : "";
        String remark = remarkIdx != -1 ? _getSafe(row, remarkIdx) : "";

        tempResidentList.add(ResidentRow(
          dong: dong, ho: ho, owner: owner, resident: resident,
          others: others, type: type, remark: remark,
        ));
      }

      setState(() {
        _residentList = tempResidentList; _showOtherCols = activeOthers; _isResidentLoaded = true;
      });
      _showSnackBar("입주자 명부 ${tempResidentList.length}세대 로드 완료!");
    } catch (e) {
      _showNoticePopup("명부 로드 실패", "오류 내용: $e");
    }
  }

  // =======================================================
  // 🛡️ [수술 1] 무결점 State Machine CSV 파서
  // =======================================================
  List<List<String>> _getRowsFromBytes(String ext, List<int> bytes) {
    List<List<String>> rows = [];
    String rawString = "";

    // 1. 유니코드 찌꺼기(BOM) 방어를 포함한 디코딩
    try { rawString = utf8.decode(bytes); }
    catch(e) {
      try { rawString = cp949.decode(bytes); }
      catch(e2) { rawString = utf8.decode(bytes, allowMalformed: true); }
    }

    if (rawString.isEmpty) return [];

    // 2. 대기업급 State Machine 로직 (따옴표 안의 엔터, 쉼표 보호)
    List<String> currentRow = [];
    StringBuffer currentCell = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < rawString.length; i++) {
      String char = rawString[i];

      if (char == '"') {
        // 따옴표 내부의 따옴표 ("") 이스케이프 처리
        if (inQuotes && i + 1 < rawString.length && rawString[i + 1] == '"') {
          currentCell.write('"');
          i++;
        } else {
          inQuotes = !inQuotes; // 모드 스위치
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        // 찐 줄바꿈
        if (char == '\r' && i + 1 < rawString.length && rawString[i + 1] == '\n') i++;
        currentRow.add(currentCell.toString().trim());
        if (currentRow.any((c) => c.isNotEmpty)) rows.add(List.from(currentRow));
        currentRow.clear();
        currentCell.clear();
      } else {
        currentCell.write(char);
      }
    }

    // 마지막 꼬리 데이터 처리
    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString().trim());
      rows.add(currentRow);
    }
    return rows;
  }

  // =======================================================
  // 🛡️ [수술 완료] 신협 최강 앵커 '거래시간' 탑재 + 커트라인 하향 파서
  // =======================================================
  Future<void> _loadBankExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx', 'xls', 'csv'], withData: true,
      );
      if (result == null) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) throw Exception("데이터를 읽을 수 없습니다.");

      String ext = result.files.single.extension?.toLowerCase() ?? '';
      List<List<String>> rawRows = _getRowsFromBytes(ext, bytes);

      if (rawRows.isEmpty) throw Exception("데이터 추출에 실패했습니다.");

      // 🧼 글자 세척기
      String clean(String text) => text.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '');

      int headerIdx = -1;
      String bankType = "UNKNOWN";

      // 🌟 [가중치 족보] 첫 번째 단어는 10점짜리 앵커, 나머지는 1점짜리 공통 단어
      Map<String, List<String>> signatures = {
        "IBK": ["상대계좌예금주명", "상대은행", "거래내용", "거래일시", "입금"],
        "SAEMAUL": ["비고", "거래후잔액", "내용", "거래일시", "입금"],
        "KB": ["내통장표시", "보낸분받는분", "출금액원", "거래일시", "입금액원"],
        "SUHYUP": ["보낸분받는분", "입출금은행", "일자", "입금", "출금"],
        "HANA": ["의뢰인수취인", "거래특이사항", "거래일시", "적요", "입금"],

        // 🌟 [핵심 수술] 신협이 농협보다 먼저 검사되도록 순서 변경 (동점일 경우 신협 우선권)
        // 신협의 가장 큰 특징인 '거래시간'을 10점짜리 무적 앵커로 설정!
        "SHINHYUP_P1": ["거래시간", "잔액", "거래기록사항", "거래점", "적요"],
        "SHINHYUP_P2": ["순번거래일자거래시간", "출금금액", "입금금액", "거래후잔액", "거래기록사항"],
        "SHINHYUP_C": ["출금수수료포함", "거래종류", "거래일자", "입금", "내용"],

        "NH_P1": ["기록사항", "취급점", "거래일시", "입금금액", "거래내용"],
        "NH_P2": ["기록사항", "거래점", "거래일자", "입금금액", "거래내용"],
        "NH_C": ["거래기록사항", "거래점", "거래일자", "입금금액", "거래내용"],

        "WOORI": ["기재내용", "취급점", "거래일시", "입금원", "거래후잔액원"],
        "POST": ["내역", "거래국", "거래일시", "입금액", "출금액"],
        "SHINHAN": ["입금인코드", "거래일시", "적요", "입금액", "내용"],
      };

      for (int i = 0; i < min(50, rawRows.length - 1); i++) {
        String currentRowText = clean(rawRows[i].join(''));
        String nextRowText = clean(i + 1 < rawRows.length ? rawRows[i+1].join('') : "");
        String windowText = currentRowText + nextRowText;
        if (windowText.isEmpty) continue;

        int bestScore = 0;
        String bestBank = "";
        int tempHeaderIdx = -1; // 🌟 [추가] 앵커가 정확히 어느 줄에 있는지 저장하는 변수

        for (var entry in signatures.entries) {
          List<String> sig = entry.value;
          int currentScore = 0;

          String anchor = clean(sig[0]); // 10점짜리 앵커
          if (windowText.contains(anchor)) {
            currentScore += 10;

            for (int j = 1; j < sig.length; j++) {
              if (windowText.contains(clean(sig[j]))) currentScore += 1;
            }

            // 🌟 커트라인을 12점에서 11점(앵커 + 1개만 맞아도 통과)으로 하향 조정!
            if (currentScore >= 11 && currentScore > bestScore) {
              bestScore = currentScore;
              bestBank = entry.key;

              // 🌟 [핵심 수술] 두 줄을 합쳐서 찾았더라도, 앵커(기재내용 등)가 윗줄에 있는지 아랫줄에 있는지 정확히 추적하여 '조회일시' 같은 쓰레기 줄을 버립니다.
              if (currentRowText.contains(anchor)) {
                tempHeaderIdx = i;
              } else {
                tempHeaderIdx = i + 1;
              }
            }
          }
        }

        if (bestBank.isNotEmpty) {
          bankType = bestBank;
          headerIdx = tempHeaderIdx; // 🌟 묶음(i)이 아닌, 핀셋으로 찾은 정확한 줄 번호를 부여!
          break;
        }
      }

      if (headerIdx == -1) throw Exception("은행 양식 식별 실패: 앵커가 포함된 필수 기둥을 찾지 못했습니다.");

      List<String> h = rawRows[headerIdx];
      List<String> hNext = (headerIdx + 1 < rawRows.length) ? rawRows[headerIdx+1] : [];

      int findCol(List<String> keys, {bool isAmt = false}) {
        for (var k in keys) {
          for (int i = 0; i < h.length; i++) {
            String combined = clean(h[i] + (hNext.length > i ? hNext[i] : ""));
            if (combined.contains(clean(k))) {
              if (isAmt && (combined.contains("일자") || combined.contains("시간") || combined.contains("일시"))) continue;
              if (isAmt && combined.contains("출금") && !combined.contains("입")) continue;
              if (isAmt && combined.contains("잔액")) continue;
              return i;
            }
          }
        }
        return -1;
      }

      // 기둥 위치 찾기
      int dateIdx = findCol(["거래일시", "거래일자", "일자"]);
      int timeIdx = findCol(["거래시간", "시간"]);
      int amtIdx = findCol(["입금액", "입금금액", "입금"], isAmt: true);
      int bankIdx = findCol(["상대은행", "거래점", "처리점", "거래국", "입출금은행"]);
      int typeIdx = findCol(["거래구분", "구분", "거래종류"]);
      int cmsIdx = findCol(["cms", "cms코드", "입금인코드", "수취인코드"]);

      int desc1Idx = -1; int desc2Idx = -1;

      // 은행별 "진짜 이름" 기둥 핀셋 타격
      if (bankType == "IBK") {
        desc1Idx = findCol(["거래내용"]); desc2Idx = findCol(["상대계좌예금주명"]);
      } else if (bankType == "SHINHAN") {
        desc1Idx = findCol(["내용"]); desc2Idx = findCol(["적요"]);
      } else if (bankType == "KB") {
        desc1Idx = findCol(["내통장표시"]); desc2Idx = findCol(["보낸분받는분", "적요"]);
      } else if (bankType == "SUHYUP") {
        desc1Idx = findCol(["보낸분받는분"]); desc2Idx = findCol(["내용"]);
      } else if (bankType == "SAEMAUL") {
        desc1Idx = findCol(["내용"]); desc2Idx = findCol(["적요", "비고"]);
      } else if (bankType == "HANA") {
        desc1Idx = findCol(["적요"]); desc2Idx = findCol(["의뢰인수취인"]);
      } else if (bankType.startsWith("NH")) {
        desc1Idx = findCol(["거래기록사항", "기록사항"]); desc2Idx = findCol(["거래내용", "내용"]);
      } else if (bankType.startsWith("SHINHYUP_P")) {
        desc1Idx = findCol(["거래기록사항"]); desc2Idx = findCol(["적요", "거래종류"]);
      } else if (bankType == "SHINHYUP_C") {
        desc1Idx = findCol(["내용"]); desc2Idx = findCol(["적요", "거래점"]);
      } else {
        desc1Idx = findCol(["기재내용", "내용", "내역", "적요"]);
        desc2Idx = findCol(["비고", "메모", "의뢰인"]);
      }

      if (amtIdx == -1 || desc1Idx == -1) throw Exception("[$bankType] 필수 기둥 분석 실패 (금액/내용)");

      List<BankTx> tempBankList = [];
      int dataStart = headerIdx + (hNext.any((e) => clean(e).contains("입금") || clean(e).contains("출금")) ? 2 : 1);

      for (int i = dataStart; i < rawRows.length; i++) {
        var row = rawRows[i];
        if (row.length < 3) continue;

        String getSafe(int idx) => (idx != -1 && idx < row.length) ? row[idx].trim() : "";

        // 🌟 [강력 필터 1] 날짜 기둥에 '총 50건' 같은 요약 정보가 있으면 즉시 스킵
        String dateVal = getSafe(dateIdx);
        if (dateVal.contains("총") || dateVal.contains("건") || dateVal.contains("합계")) continue;

        String rawAmt = getSafe(amtIdx).split('.')[0];
        int amt = int.tryParse(rawAmt.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (amt <= 0) continue;

        String mainDesc = getSafe(desc1Idx);
        String subDesc = getSafe(desc2Idx);

        if (mainDesc.isEmpty && subDesc.isEmpty) {
          mainDesc = row.join(" ").replaceAll(RegExp(r'\s+'), ' ');
        }

        String fullDesc = (subDesc.isNotEmpty && subDesc != mainDesc) ? "$mainDesc [$subDesc]" : mainDesc;

        // 🌟 [강력 필터 2] 내용에 요약 키워드가 포함되어 있으면 스킵
        if (fullDesc.isEmpty ||
            fullDesc.contains("합계") ||
            fullDesc.contains("소계") ||
            fullDesc.contains("총계") ||
            (fullDesc.contains("총") && fullDesc.contains("건"))) continue;

        if (fullDesc.isEmpty || fullDesc.contains("합계") || fullDesc.contains("소계")) continue;

        String date = getSafe(dateIdx);
        if (timeIdx != -1) date = "$date ${getSafe(timeIdx)}";

        // 🌟 [핵심 수술 2] 엑셀에서 뽑아낸 '진짜 거래구분(제휴)'과 'CMS코드'를 가상계좌 식별기로 넘겨줍니다!
        tempBankList.add(BankTx(
            description: fullDesc,
            amount: amt,
            date: date,
            bankName: getSafe(bankIdx),
            txType: getSafe(typeIdx), // 💡 수정됨: 실제 엑셀의 '거래구분' 칸 텍스트
            cmsCode: getSafe(cmsIdx)  // 💡 수정됨: 실제 엑셀의 'CMS코드' 칸 텍스트
        ));
      } // 👈 🌟 [긴급 픽스] 바로 여기에 for문을 닫아주는 중괄호 '}' 가 빠져있었습니다!!

      setState(() { _bankList = tempBankList; _isBankLoaded = true; });
      _showSnackBar("[$bankType] ${tempBankList.length}건 로드 성공!");
    } catch (e) {
      _showNoticePopup("분석 오류", "$e");
    }
  }

  // 매칭 로직 전체
  void _runAiMatching() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 800));

    for (var tx in _bankList) tx.isUsed = false;

    List<ResidentRow> uniqueResidents = [];
    Set<String> seenDongHo = {};
    for (var r in _residentList) {
      String key = "${r.dong}_${r.ho}";
      if (!seenDongHo.contains(key)) {
        r.isMatched = false;
        r.isCheckRequired = false;
        r.matchedField = "";
        r.matchedTx = null;
        r.matchedAmount = 0;
        r.matchedBankText = "";
        r.matchedDate = "";
        r.matchedMemo = "";
        r.matchedBankName = "";
        uniqueResidents.add(r);
        seenDongHo.add(key);
      }
    }
    _residentList = uniqueResidents;

    for (var tx in _bankList) {
      if (tx.isUsed || tx.amount <= 0) continue;

      // 🚨 [수정] 자동이체 스킵 로직 삭제! 이제 "카드1-202"도 AI가 읽습니다.

      String originalDesc = tx.description;
      String normalizedDesc = "";
      for (int k = 0; k < originalDesc.length; k++) {
        int code = originalDesc.codeUnitAt(k);
        if (code >= 0xFF01 && code <= 0xFF5E) { normalizedDesc += String.fromCharCode(code - 0xFEE0); }
        else if (code == 0x3000) { normalizedDesc += " "; }
        else { normalizedDesc += String.fromCharCode(code); }
      }

      // 🌟 기존 띄어쓰기(\s) 제거 기능 100% 유지 + 은행 특수 투명 공백 및 괄호 파쇄 기능 추가
      String descNoSpace = normalizedDesc.toLowerCase()
          .replaceAll(RegExp(r'[\s\u200B-\u200D\uFEFF\u00A0\u3000]'), '')
          .replaceAll(RegExp(r'[()\[\]<>{}_*?!]'), '');

      // 👇 🌟 [핀셋 수술 1-1] 한글 발음 동(Dong) 번역기 (에이3 -> 1-3)
      descNoSpace = descNoSpace.replaceAllMapped(RegExp(r'(에이|비|씨|디|이|에프)(\d+)'), (match) {
        Map<String, String> pMap = {'에이': '1', '비': '2', '씨': '3', '디': '4', '이': '5', '에프': '6'};
        return '${pMap[match.group(1)!]}-${match.group(2)}';
      });

      // 👇 🌟 [핀셋 수술 1-2] 한글 발음 동(Dong) 번역기 (에이동 -> 1동)
      descNoSpace = descNoSpace.replaceAllMapped(RegExp(r'(에이|비|씨|디|이|에프)동'), (match) {
        Map<String, String> pMap = {'에이': '1', '비': '2', '씨': '3', '디': '4', '이': '5', '에프': '6'};
        return '${pMap[match.group(1)!]}동';
      });

      // =======================================================
      // 🛡️ [수술 1] 1~100동 무한 번역기 (Safety Lock 최종 고도화)
      // 🌟 [수정] 한 글자(A~Z)일 때만 동으로 번역하고, CM/SK 등 건물명 약자는 보호합니다!
      // =======================================================
      descNoSpace = descNoSpace.replaceAllMapped(
          RegExp(r'(^|[가-힣])([a-z])(동|단지|-|/|,|\.)'), // 🌟 [핵심] ([a-z]+)를 ([a-z])로 변경!
              (match) {
            String prefix = match.group(1) ?? '';
            String alpha = match.group(2) ?? '';
            String suffix = match.group(3) ?? '';

            // 이제 한 글자(a~z)만 들어오므로 1~26동까지만 번역됩니다.
            int num = alpha.codeUnitAt(0) - 96;

            if (num > 0 && num <= 26) {
              return '$prefix$num$suffix';
            }
            return match.group(0)!;
          }
      );

      // 👇 🌟 [방해 단어 분쇄기 초고도화] 은행명, 이체 방식 등 찌꺼기를 완벽하게 날립니다.
      String stopWordsPattern = r'(pg|자동|카드|결제|체크|페이|pay|토스|toss|나이스|nice|kcp|다날|danal|모빌리언스|카카오|kakao|네이버|비대면|펌뱅킹|입금|송금|cd|atm|이체|대체|스마트|인터넷|올원|뱅크|은행|nh|농협|국민|신한|우리|기업|하나|새마을|수협|신협|우체국|타행|창구|mb|pc|폰|e-|센터일괄|cm|관리비)';
      String cleanDescNoSpace = descNoSpace.replaceAll(RegExp(stopWordsPattern), '');

      cleanDescNoSpace = cleanDescNoSpace.replaceAll(RegExp(r'(거래|거래일|거래일자)[:\s]*\d{1,4}[-./]?\d{1,4}'), '');
      cleanDescNoSpace = cleanDescNoSpace.replaceAll(RegExp(r'\d+차'), '');

      cleanDescNoSpace = cleanDescNoSpace
          .replaceAll(RegExp(r'\d{4}[.\-/]\d{1,2}[.\-/]\d{1,2}'), '')
          .replaceAll(RegExp(r'010[.\-]?\d{3,4}[.\-]?\d{4}'), '')
          .replaceAll(RegExp(r'\d{9,11}'), '');

      // =======================================================
      // 🛡️ [수술 2] 영문+숫자 복합 추출기 (cm 오탐지 방지 및 하이픈 보존)
      // =======================================================
      String exDong = ""; String exHo = "";
      bool hasExplicitPattern = false; bool hasExplicitHoOnly = false; bool isSwappedPossible = false;

      var cardForceMatch = RegExp(r'카드(\d+)-(\d+)').firstMatch(descNoSpace);
      if (cardForceMatch != null) {
        exDong = cardForceMatch.group(1)!;
        exHo = cardForceMatch.group(2)!;
        hasExplicitPattern = true;
      }

      // 👇 🌟 [cm 오탐지 방어] 정규식에 숫자(\d)를 필수로 넣어 순수 영문(cm)을 동/호수로 착각하지 못하게 막습니다.
      if (!hasExplicitPattern) {
        var m1 = RegExp(r'([a-z0-9\-]*\d[a-z0-9\-]*)동\s*([a-z0-9\-]*\d[a-z0-9\-]*)호?').firstMatch(cleanDescNoSpace);
        if (m1 != null) { exDong = m1.group(1)!; exHo = m1.group(2)!; hasExplicitPattern = true; }
      }

      if (!hasExplicitPattern) {
        var m3 = RegExp(r'([a-z0-9\-]*\d[a-z0-9\-]*)(?:-|_|/|,|:|\.)([a-z0-9\-]*\d[a-z0-9\-]*)').firstMatch(cleanDescNoSpace);
        if (m3 != null) {
          exDong = m3.group(1)!; exHo = m3.group(2)!;
          hasExplicitPattern = true; isSwappedPossible = true;
        }
      }

      if (!hasExplicitPattern) {
        var m2 = RegExp(r'([a-z0-9\-]*\d[a-z0-9\-]*)호(?:\s*([a-z0-9\-]*\d[a-z0-9\-]*)동)?').firstMatch(cleanDescNoSpace);
        if (m2 != null) {
          exHo = m2.group(1)!;
          if (m2.group(2) != null) { exDong = m2.group(2)!; hasExplicitPattern = true; }
          else { hasExplicitHoOnly = true; }
        }
      }

      // 숫자가 무조건 1개 이상 포함된 덩어리만 정확하게 추출
      List<String> rawNumbers = RegExp(r'[a-z0-9\-]*\d[a-z0-9\-]*').allMatches(cleanDescNoSpace).map((m) => m.group(0)!).toList();

      if (!hasExplicitPattern && !hasExplicitHoOnly) {
        if (rawNumbers.length >= 2) {
          exDong = rawNumbers[0]; exHo = rawNumbers[1];
          hasExplicitPattern = true;
          isSwappedPossible = true;
        }
      }

      ResidentRow? bestMatchRow;
      int highestScore = 0;
      String bestMatchReason = "";
      bool bestNeedsCheck = false;
      String bestMatchedNameStr = "";

      // 🌟 [특급 수술 1] 동(Dong) 판독기: 단방향 일방통행 및 영문 이름 흡수 방어!
      bool isSmartDongMatch(String dbDongStr, String bankDongStr, {bool allowMath = true}) {
        String cleanDb = dbDongStr.toLowerCase().trim();
        String cleanBank = bankDongStr.toLowerCase().trim();

        if (RegExp(r'^0+\d+$').hasMatch(cleanBank)) cleanBank = int.parse(cleanBank).toString();
        if (RegExp(r'^0+\d+$').hasMatch(cleanDb)) cleanDb = int.parse(cleanDb).toString();

        if (cleanDb.isEmpty || cleanDb == cleanBank) return true;

        if (allowMath) {
          int? dbN = int.tryParse(cleanDb);
          int? bkN = int.tryParse(cleanBank);
          if (dbN != null && bkN != null) {
            if (dbN == bkN) return true;
            if (bkN > 0 && bkN < 100 && dbN >= 100 && (dbN % 100) == bkN) return true;
            if (dbN > 0 && dbN < 100 && bkN >= 100 && (bkN % 100) == dbN) return true;
            return false;
          }
        }

        String dbAlphaOnly = cleanDb.replaceAll(RegExp(r'[^a-z]'), '');
        if (dbAlphaOnly.isNotEmpty && RegExp(r'^\d+$').hasMatch(cleanBank)) {
          int dbNum = 0;
          for (int i = 0; i < dbAlphaOnly.length; i++) {
            dbNum = dbNum * 26 + (dbAlphaOnly.codeUnitAt(i) - 96);
          }
          if (dbNum.toString() == cleanBank) return true;
        }

        String bankAlphaOnly = cleanBank.replaceAll(RegExp(r'[^a-z]'), '');
        if (bankAlphaOnly.isNotEmpty && RegExp(r'^\d+$').hasMatch(cleanDb)) {
          int bankNum = 0;
          for (int i = 0; i < bankAlphaOnly.length; i++) {
            bankNum = bankNum * 26 + (bankAlphaOnly.codeUnitAt(i) - 96);
          }
          if (bankNum.toString() == cleanDb) return true;
        }

        // 👇 🌟 [초정밀 안전 수술] 영문 이름 흡수 방어 (ex: 104yangyingzi -> 104)
        if (cleanBank.startsWith(cleanDb)) {
          String leftover = cleanBank.substring(cleanDb.length);
          if (RegExp(r'^[a-z]+$').hasMatch(leftover)) return true;
        }
        if (cleanBank.endsWith(cleanDb)) {
          String leftover = cleanBank.substring(0, cleanBank.length - cleanDb.length);
          if (RegExp(r'^[a-z]+$').hasMatch(leftover)) return true;
        }

        return cleanDb.contains(cleanBank);
      }

      // 🌟 [특급 수술 2] 호수(Ho) 판독기: 엄격한 일치 및 영문 이름 흡수 방어!
      bool isSmartHoMatch(String dbHoStr, String bankHoStr, String fullRawDesc) {
        if (dbHoStr.isEmpty || bankHoStr.isEmpty) return false;

        String cleanBankHo = bankHoStr.toLowerCase().trim();
        String cleanDbHo = dbHoStr.toLowerCase().trim();

        if (cleanDbHo == cleanBankHo) return true;

        bool isBankNumeric = RegExp(r'^\d+$').hasMatch(cleanBankHo);
        bool isDbNumeric = RegExp(r'^\d+$').hasMatch(cleanDbHo);

        if (isBankNumeric && isDbNumeric) {
          int bN = int.tryParse(cleanBankHo) ?? 0;
          int dN = int.tryParse(cleanDbHo) ?? 0;
          if (bN == dN) return true;

        } else {
          if (cleanBankHo.startsWith("$cleanDbHo-")) return true;
          if (cleanDbHo.startsWith("$cleanBankHo-")) return true;
        }

        if (cleanBankHo.startsWith(cleanDbHo)) {
          String leftover = cleanBankHo.substring(cleanDbHo.length);
          int? monthVal = int.tryParse(leftover);
          if (monthVal != null && monthVal >= 1 && monthVal <= 12) {
            if (fullRawDesc.contains("${bankHoStr}월") || fullRawDesc.contains("${bankHoStr}분")) {
              return true;
            }
          }
          // 👇 🌟 [핀셋 수술 2-1] 영문 이름 흡수 방어하되, 남은 알파벳이 딱 'b'면 지하이므로 절대 버리지 않음!
          if (leftover != 'b' && RegExp(r'^[a-z]+$').hasMatch(leftover)) return true;
        }

        // 👇 🌟 영문 이름이 호수 앞에 붙은 경우 방어 (ex: yangyingzi301 -> 301)
        if (cleanBankHo.endsWith(cleanDbHo)) {
          String leftover = cleanBankHo.substring(0, cleanBankHo.length - cleanDbHo.length);
          // 👇 🌟 [핀셋 수술 2-2] 남은 알파벳이 딱 'b'면 지하이므로 절대 버리지 않음!
          if (leftover != 'b' && RegExp(r'^[a-z]+$').hasMatch(leftover)) return true;
        }

        return false;
      }

      // =======================================================
      // 🛡️ [수술 3] DB 세척기 고도화 (.0 악성 찌꺼기 및 하이픈 파괴 방지)
      // =======================================================
      for (var row in _residentList) {
        // 👇 🌟 [핀셋 수술 3] 명부 호수에 적힌 한글 '지하'를 소문자 'b'로 은밀히 치환하여 메모리에 올립니다!
        String cleanHo = row.ho.trim().toLowerCase().replaceAll(RegExp(r'\.0+$'), '').replaceAll('지하', 'b').replaceAll(RegExp(r'[^a-z0-9\-]'), '');
        String cleanDong = row.dong.trim().toLowerCase().replaceAll(RegExp(r'\.0+$'), '').replaceAll(RegExp(r'[^a-z0-9\-]'), '');
        if (cleanHo.isEmpty) continue;

        int currentScore = 0;
        List<String> hitReasons = [];
        bool isEmptyRecord = row.owner.trim().isEmpty && row.resident.trim().isEmpty && row.others.every((e) => e.trim() == "-" || e.trim().isEmpty) && row.remark.trim().isEmpty;

        String targetHoNum = int.tryParse(cleanHo)?.toString() ?? cleanHo;
        String targetDongNum = int.tryParse(cleanDong)?.toString() ?? cleanDong;

        bool isDongHoMatch = false;
        bool isHoMatch = false;
        bool isJoinedMatch = false;
        bool isStrongJoinedMatch = false;

        // 👇 🌟 [새치기 방어용] 글자가 토씨 하나 안 틀리고 완벽히 똑같은지 확인하는 변수 추가!
        bool isPerfectHo = false;
        bool isSuperExactHo = false;

        // 1. [동·호수 판단 로직]
        if (hasExplicitPattern) {
          bool dongMatches = isSmartDongMatch(targetDongNum, exDong);
          bool hoMatches = isSmartHoMatch(targetHoNum, exHo, descNoSpace);

          if (dongMatches && hoMatches) {
            isDongHoMatch = true;
            // 🌟 은행 호수와 DB 호수가 100% 일치하면 가산점 예약!
            if (targetHoNum == exHo.toLowerCase().trim()) isPerfectHo = true;
          }
          // 알파벳 엇갈림 교차 합체 검사 (1b+111-1 == 1+b111-1)
          else if (exDong.isNotEmpty && exHo.isNotEmpty) {
            String joinedBank = (exDong + exHo).replaceAll(RegExp(r'[^a-z0-9]'), '');
            String joinedDb = (cleanDong + cleanHo).replaceAll(RegExp(r'[^a-z0-9]'), '');
            if (joinedBank == joinedDb && RegExp(r'[a-z]').hasMatch(joinedBank)) {
              isDongHoMatch = true;
            }
          }
          else if (isSwappedPossible) {
            bool swappedDongMatches = isSmartDongMatch(targetDongNum, exHo, allowMath: false);
            bool swappedHoMatches = isSmartHoMatch(targetHoNum, exDong, descNoSpace);
            if (swappedDongMatches && swappedHoMatches) {
              isDongHoMatch = true;
              if (targetHoNum == exDong.toLowerCase().trim()) isPerfectHo = true;
            }
          }
        } else if (hasExplicitHoOnly) {
          if (isSmartHoMatch(targetHoNum, exHo, descNoSpace)) {
            isHoMatch = true;
            if (targetHoNum == exHo.toLowerCase().trim()) isPerfectHo = true;
          }
        } else {
          if (rawNumbers.length == 1) {
            String numStr = rawNumbers[0];
            String joinedTarget = cleanDong + cleanHo;
            String joinedTargetReverse = cleanHo + cleanDong;

            // 👇 🌟 [우선순위 0] 절대 불변의 100% 호수 단독 일치 (1202 == 1202호)
            // 찰흙 합체(1+202=1202)의 오해보다 무조건 우선하도록 최고 권한 부여!
            if (numStr == targetHoNum.toLowerCase().trim()) {
              isSuperExactHo = true;
            }
            // 👇 🌟 [우선순위 1] 찰흙 합체 매칭 (1동 202호 -> 1202)
            else if (joinedTarget.isNotEmpty && numStr == joinedTarget) {
              isDongHoMatch = true;
              if (targetHoNum == numStr.replaceAll(cleanDong, '').toLowerCase().trim()) isPerfectHo = true;
            } else if (joinedTargetReverse.isNotEmpty && numStr == joinedTargetReverse) {
              isDongHoMatch = true;
              if (targetHoNum == numStr.replaceAll(cleanDong, '').toLowerCase().trim()) isPerfectHo = true;
            }
            // 👇 🌟 [우선순위 2] 지하세대 단독 호수 완벽 방어 (b105 == b105)
            else if (isSmartHoMatch(targetHoNum, numStr, descNoSpace)) {
              isHoMatch = true;
              if (targetHoNum == numStr.toLowerCase().trim()) isPerfectHo = true;
            }
            // 👇 🌟 [우선순위 3] 알파벳 융합 번역기 (b3 -> B동 3호 -> 2동 3호)
            else {
              var alphaMatch = RegExp(r'^([a-z])(\d+)$').firstMatch(numStr);
              if (alphaMatch != null) {
                int alphaDong = alphaMatch.group(1)!.codeUnitAt(0) - 96; // a=1, b=2...
                String hoNum = alphaMatch.group(2)!;
                if (targetDongNum == alphaDong.toString() && targetHoNum == hoNum) {
                  isDongHoMatch = true;
                  isPerfectHo = true;
                }
              }
            }

            // 👇 🌟 [우선순위 4] 동/호 단순 유추 (찌꺼기 처리 유지)
            if (!isSuperExactHo && !isDongHoMatch && !isHoMatch) {
              if (joinedTarget.length >= 3 && numStr == joinedTarget) {
                isJoinedMatch = true;
                if (joinedTarget.length >= 5) isStrongJoinedMatch = true;
              } else if (joinedTargetReverse.length >= 3 && numStr == joinedTargetReverse) {
                isJoinedMatch = true;
                if (joinedTargetReverse.length >= 5) isStrongJoinedMatch = true;
              }
            }
          }
        }

        // [동·호수 점수 부여]
        // 👇 🌟 아래 점수 부여 블록을 이렇게 덮어씌워 주십시오!
        if (isSuperExactHo) {
          currentScore += 65; // 찰흙합체(62점)를 무조건 박살내는 절대 권한 점수!
          hitReasons.add("호수(완벽일치)");
        }
        else if (isDongHoMatch) {
          currentScore += 60;
          if (isPerfectHo) currentScore += 2;
          hitReasons.add("동-호");
        }
        else if (isHoMatch) {
          currentScore += 50;
          if (isPerfectHo) currentScore += 2;
          hitReasons.add("호수");
        }
        else if (isJoinedMatch) {
          if (isStrongJoinedMatch) { currentScore += 40; hitReasons.add("동호완벽유추"); }
          else { currentScore += 20; hitReasons.add("동호단순유추"); }
        }

        // 2. [이름 판단 로직]
        bool exactNameHit = false;
        bool remarkNameHit = false;
        bool partialNameHit = false;
        bool typoNameHit = false;
        String matchedNameType = "";

        String safeDesc = cleanDescNoSpace.replaceAll(RegExp(r'\d+원'), '');

        // 👇 🌟 [대표님 천재적 아이디어 적용: 김정호 꼬리 자르기 방어]
        String bankNameCandidate = safeDesc.replaceAll(RegExp(r'\d+[동호]?'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');

        String currentMatchedNameStr = "";

        // 🌟 [추가 수술] 스팸 필터 단어장
        String pureBankName = bankNameCandidate.replaceAll(RegExp(r'타행|모바일|인터넷|스마트|이체|건별|대량|지점|자동|nh|농협|국민|신한|우리|기업|하나|새마을|수협|신협|우체국|올원|뱅크|은행|cd|atm|폰|페이|pay|mb|pc|e-|센터일괄|cm|관리비'), '');

        // 👇 🌟 [핵심 수술 1] '상대은행(보낸분)' 기둥도 영어 이름의 성지이므로 검색 대상에 긴급 추가합니다!
        String bankNameSpace = tx.bankName.toLowerCase().replaceAll(RegExp(r'[^a-z가-힣]'), '');

        // 🌟 [최종 무결점 고도화] 영어 3글자 연속 매칭 룰 추가
        void checkName(String rawName, String type) {
          if (rawName.isEmpty || rawName == "-") return;

          bool isCorporation = RegExp(r'\(주\)|주식회사|\(유\)|\(사\)|\(재\)').hasMatch(rawName);
          String preProcessedName = rawName.replaceAll(RegExp(r'\(주\)|주식회사|\(유\)|\(사\)|\(재\)'), '');

          List<String> subNames = preProcessedName.split(RegExp(r'[,/.;|()\[\]]'));
          subNames.add(preProcessedName.replaceAll(RegExp(r'[()\[\]<>{}_*?!]'), ''));

          for (String sub in subNames) {
            String cleanName = sub.toLowerCase().replaceAll(RegExp(r'[^a-z가-힣]'), '');
            if (cleanName.isEmpty) continue;

            if (cleanName.length < 2) {
              if (isCorporation) {
                if (cleanName != pureBankName && !pureBankName.contains(cleanName)) continue;
              } else {
                if (cleanName != pureBankName && cleanName != bankNameCandidate) continue;
              }
            }

            bool isExact = false;

            // 1. 기본 포함 검사 (거래내용 + 상대은행 모두 뒤집니다!)
            if (cleanName == bankNameCandidate || cleanName == pureBankName ||
                descNoSpace.contains(cleanName) || bankNameSpace.contains(cleanName)) {
              isExact = true;
            }
            else if (pureBankName.length >= 2 && pureBankName.contains(cleanName)) {
              isExact = true;
            }
            // 2. 상대은행 데이터가 명부 이름의 일부를 포함할 때
            else if (bankNameSpace.length >= 2 && bankNameSpace.contains(cleanName)) {
              isExact = true;
            }
            else if (pureBankName.length >= 3 && cleanName.contains(pureBankName)) {
              isExact = true;
            }
            else if (bankNameSpace.length >= 3 && cleanName.contains(bankNameSpace)) {
              isExact = true;
            }
            else if (pureBankName.length == 2 && cleanName.length == 3 && (cleanName.endsWith('동') || cleanName.endsWith('호')) && cleanName.startsWith(pureBankName)) {
              isExact = true;
            }
            // 👇 🌟 [핵심 수술 완료] 대표님 아이디어 적용: 무조건 이름 덩어리의 '맨 앞 3글자(Prefix)'만 핀셋 매칭!
            // (eng 같은 꼬리 글자 우연 일치로 인한 과오납 완벽 차단)
            else if (RegExp(r'[a-z]').hasMatch(cleanName) && cleanName.length >= 3) {
              String prefix = cleanName.substring(0, 3); // 앞에서 딱 3글자만 자릅니다!

              // 은행 거래내용이나 상대은행 텍스트에 그 앞 3글자가 있으면 즉시 검거!
              if (descNoSpace.contains(prefix) || bankNameSpace.contains(prefix)) {
                isExact = true;
              }
            }
            else if (RegExp(r'[a-z]').hasMatch(cleanName) && RegExp(r'[a-z]').hasMatch(pureBankName)) {
              int charIdx = 0;
              for (int i = 0; i < cleanName.length && charIdx < pureBankName.length; i++) {
                if (cleanName[i] == pureBankName[charIdx]) charIdx++;
              }
              if (charIdx == pureBankName.length && pureBankName.length >= 2) isExact = true;
            }

            if (isExact) {
              if (type == "비고") remarkNameHit = true; else exactNameHit = true;
              matchedNameType = type;
              currentMatchedNameStr = rawName;
              return;
            }

            // 오타 및 부분 일치 로직 유지
            if (!exactNameHit && !remarkNameHit && (isDongHoMatch || isHoMatch || isJoinedMatch) && pureBankName.isNotEmpty) {
              double sim = _calculateSimilarity(cleanName, pureBankName);
              if (sim >= 0.8) { partialNameHit = true; matchedNameType = "$type(오타-신뢰고)"; currentMatchedNameStr = rawName; }
              else if (sim >= 0.6) { typoNameHit = true; matchedNameType = "$type(오타-신뢰저)"; currentMatchedNameStr = rawName; }
              else if (!partialNameHit && pureBankName.length >= 2 && cleanName.contains(pureBankName)) {
                partialNameHit = true; matchedNameType = "$type(일부)"; currentMatchedNameStr = rawName;
              }
            }
          }
        }

        //checkName(row.owner, "소유자"); //소유자 매칭제외 앞에 주석 처리로 못읽게 처리함.
        if (!exactNameHit) checkName(row.resident, "입주자");
        if (!exactNameHit) { for (String other in row.others) checkName(other, "기타인원"); }
        if (!exactNameHit && !remarkNameHit) checkName(row.remark, "비고");

        // 👇 🌟 [에클라 새치기 방지] 이름이 완벽하게 맞았을 때, 남들에게 스틸당하지 않도록 점수를 55점(슈퍼 만점)으로 올립니다!
        if (exactNameHit || remarkNameHit) { currentScore += 55; hitReasons.add(matchedNameType); }
        else if (partialNameHit) { currentScore += 40; hitReasons.add(matchedNameType); }
        else if (typoNameHit) { currentScore += 30; hitReasons.add(matchedNameType); }

        if (currentScore > 0 && isEmptyRecord) { currentScore -= 10; hitReasons.add("정보없음(-10)"); }

        // 3. [최종 판정 로직]
        if (currentScore > highestScore) {
          highestScore = currentScore;
          bestMatchRow = row;
          bestMatchedNameStr = currentMatchedNameStr.isNotEmpty ? currentMatchedNameStr : (row.owner.isNotEmpty ? row.owner : row.resident);

          if (currentScore >= 40) {
            // 👇 🌟 [핵심 수술] VIP 프리패스 명단 맨 앞에 'isSuperExactHo'를 당당하게 추가합니다!
            if (isSuperExactHo || isDongHoMatch || isHoMatch || isStrongJoinedMatch || exactNameHit || remarkNameHit || partialNameHit) {
              bestNeedsCheck = false;
              bestMatchReason = hitReasons.join("+");
            } else {
              bestNeedsCheck = true;
              bestMatchReason = "확인필요(${hitReasons.join("+")})";
            }
          } else {
            bestNeedsCheck = true;
            bestMatchReason = "확인필요(${hitReasons.join("+")})";
          }
        }
      }

      if (highestScore >= 30 && bestMatchRow != null) {
        ResidentRow targetRow = bestMatchRow;
        if (targetRow.isMatched) {
          ResidentRow cloneRow = ResidentRow(dong: targetRow.dong, ho: targetRow.ho, owner: targetRow.owner, resident: targetRow.resident, others: List.from(targetRow.others), type: targetRow.type, remark: targetRow.remark);
          cloneRow.managerMemo = targetRow.managerMemo;
          int insertIdx = _residentList.indexOf(targetRow) + 1;
          while (insertIdx < _residentList.length && _residentList[insertIdx].dong == targetRow.dong && _residentList[insertIdx].ho == targetRow.ho) { insertIdx++; }
          _residentList.insert(insertIdx, cloneRow);
          targetRow = cloneRow;
        }
        targetRow.isMatched = true;
        targetRow.isCheckRequired = bestNeedsCheck;
        targetRow.matchedBankText = tx.description;
        targetRow.matchedAmount = tx.amount;
        targetRow.matchedBankName = tx.bankName;
        targetRow.matchedDate = tx.date;
        targetRow.matchedMemo = tx.memo;
        targetRow.matchedName = bestMatchedNameStr;
        targetRow.matchedField = "$bestMatchReason(${highestScore}점)";
        targetRow.matchedTx = tx;
        tx.isUsed = true;
      }
    }
    setState(() => _isProcessing = false);
    _showSnackBar("AI 스코어링 엔진 매칭 완료!");
  }

  // 🌟 [추가] 실무자 수동 개입 (Manual Override) 로직
  void _changeStatus(ResidentRow row, String newStatus) {
    setState(() {
      if (newStatus == "매칭완료") {
        row.isMatched = true;
        row.isCheckRequired = false;
        if (!row.matchedField.contains("[수동확정]")) {
          row.matchedField = "${row.matchedField} [수동확정]";
        }
      } else if (newStatus == "확인필요") {
        row.isMatched = true;
        row.isCheckRequired = true;
      } else if (newStatus == "매칭대기") {
        if (row.matchedTx != null) { row.matchedTx!.isUsed = false; row.matchedTx = null; }
        int cloneCount = _residentList.where((r) => r.dong == row.dong && r.ho == row.ho).length;
        if (cloneCount > 1) {
          _residentList.remove(row);
        } else {
          row.isMatched = false; row.isCheckRequired = false;
          row.matchedBankText = ""; row.matchedAmount = 0;
          row.matchedBankName = ""; row.matchedDate = "";
          row.matchedMemo = ""; row.matchedField = "";
        }
      }
    });
  }

  void _downloadExcel() {
    var excel = Excel.createExcel();
    String defaultSheet = excel.getDefaultSheet() ?? "Sheet1";
    excel.rename(defaultSheet, "전체세대");

    void createSheet(String sheetName, List<ResidentRow> rows) {
      var sheet = excel[sheetName];
      sheet.appendRow([
        TextCellValue("동"), TextCellValue("호"), TextCellValue("소유자"), TextCellValue("입주자"),
        TextCellValue("기타1"), TextCellValue("기타2"), TextCellValue("기타3"), TextCellValue("기타4"),
        TextCellValue("구분"), TextCellValue("비고"), TextCellValue("입금일자"), TextCellValue("은행적요(내용)"),
        TextCellValue("입금액"), TextCellValue("담당자메모"), TextCellValue("최종상태")
      ]);

      for (int i = 0; i < rows.length; i++) {
        var r = rows[i];
        String status = r.isMatched ? (r.isCheckRequired ? "확인필요" : "매칭완료") : "매칭대기";
        sheet.appendRow([
          TextCellValue(r.dong), TextCellValue(r.ho), TextCellValue(r.owner), TextCellValue(r.resident),
          TextCellValue(r.others[0]), TextCellValue(r.others[1]), TextCellValue(r.others[2]), TextCellValue(r.others[3]),
          TextCellValue(r.type), TextCellValue(r.remark), TextCellValue(r.matchedDate), TextCellValue(r.matchedBankText),
          TextCellValue(r.matchedAmount > 0 ? _formatCurrency(r.matchedAmount) : ""),
          TextCellValue(r.managerMemo),
          TextCellValue(status)
        ]);

        int currentRowIdx = sheet.maxRows - 1;

        // 🌟 앞뒤 행을 스캔하여 그룹(다중 입금) 여부 파악
        bool sameAsPrev = i > 0 && rows[i - 1].dong == r.dong && rows[i - 1].ho == r.ho;
        bool sameAsNext = i < rows.length - 1 && rows[i + 1].dong == r.dong && rows[i + 1].ho == r.ho;
        bool isGroup = sameAsPrev || sameAsNext;
        bool isTop = isGroup && !sameAsPrev;
        bool isBottom = isGroup && !sameAsNext;

        // 테두리 설정
        ex.Border thickGreen = ex.Border(borderColorHex: ExcelColor.fromHexString('#FF2E7D32'), borderStyle: ex.BorderStyle.Medium);
        ex.Border thinGrey = ex.Border(borderColorHex: ExcelColor.fromHexString('#FFEEEEEE'), borderStyle: ex.BorderStyle.Thin);

        for (int col = 0; col < 15; col++) {
          ex.Border? topBorder = isTop ? thickGreen : null;
          ex.Border? bottomBorder = isGroup ? (isBottom ? thickGreen : thinGrey) : thinGrey;
          ex.Border? leftBorder = (isGroup && col == 0) ? thickGreen : null;
          ex.Border? rightBorder = (isGroup && col == 14) ? thickGreen : null;

          var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRowIdx));

          // 🚨 [에러 완벽 해결] null을 허용하지 않는 속성이므로, 분기 처리하여 개별 적용
          if (col == 13) {
            // 메모 칸: 노란색 배경 추가
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4'),
              verticalAlign: VerticalAlign.Center,
              topBorder: topBorder,
              bottomBorder: bottomBorder,
              leftBorder: leftBorder,
              rightBorder: rightBorder,
            );
          } else if (sheetName == "전체세대" && status == "매칭완료") {
            // 전체세대 매칭완료 행: 연초록색 배경 추가
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#FFE8F5E9'),
              verticalAlign: VerticalAlign.Center,
              topBorder: topBorder,
              bottomBorder: bottomBorder,
              leftBorder: leftBorder,
              rightBorder: rightBorder,
            );
          } else {
            // 나머지 일반 칸: 배경색 지정 없이 테두리만 적용 (null 에러 방지)
            cell.cellStyle = CellStyle(
              verticalAlign: VerticalAlign.Center,
              topBorder: topBorder,
              bottomBorder: bottomBorder,
              leftBorder: leftBorder,
              rightBorder: rightBorder,
            );
          }
        }
      }
    }

    // 🌟 [엑셀 고도화] 4개 주요 시트 생성 (매칭완료/확인필요에서 가상계좌, 자동이체 완벽 제외)
    createSheet("전체세대", _residentList);

    createSheet("매칭완료", _residentList.where((r) {
      if (!r.isMatched || r.isCheckRequired) return false;
      if (r.matchedTx != null && (_isAutoPaymentTx(r.matchedTx!) || _isVirtualAccountTx(r.matchedTx!))) return false;
      return true;
    }).toList());

    createSheet("확인필요", _residentList.where((r) {
      if (!r.isMatched || !r.isCheckRequired) return false;
      if (r.matchedTx != null && (_isAutoPaymentTx(r.matchedTx!) || _isVirtualAccountTx(r.matchedTx!))) return false;
      return true;
    }).toList());

    createSheet("매칭대기", _residentList.where((r) => !r.isMatched).toList());

    // 👇 🌟 [신규 생성] "수납확인(자동_가상)" 전용 엑셀 시트 추가!
    var autoPaidSheet = excel["수납확인(자동_가상)"];
    autoPaidSheet.appendRow([
      TextCellValue("동"), TextCellValue("호"), TextCellValue("거래일시"),
      TextCellValue("구분"), TextCellValue("적요(내용)"), TextCellValue("입금액"),
      TextCellValue("상대은행"), TextCellValue("담당자메모")
    ]);

    for (var tx in _bankList.where((t) => t.amount > 0 && (_isAutoPaymentTx(t) || _isVirtualAccountTx(t)))) {
      String dong = "-"; String ho = "-";
      if (tx.isUsed) {
        try {
          var matchedRow = _residentList.firstWhere((r) => r.matchedTx == tx);
          dong = matchedRow.dong; ho = matchedRow.ho;
        } catch (e) {}
      }

      autoPaidSheet.appendRow([
        TextCellValue(dong), TextCellValue(ho), TextCellValue(tx.date),
        TextCellValue(_isVirtualAccountTx(tx) ? "가상계좌/제휴" : "자동납부(PG)"),
        TextCellValue(tx.description), TextCellValue(_formatCurrency(tx.amount)),
        TextCellValue(tx.bankName), TextCellValue(tx.managerMemo)
      ]);
    }

    // 👇 미확인 입금 시트 생성 (여기서도 가상/자동이체는 제외시켜 중복 방지)
    var unconfirmedSheet = excel["미확인입금"];
    unconfirmedSheet.appendRow([
      TextCellValue("거래일시"), TextCellValue("적요(내용)"),
      TextCellValue("입금액"), TextCellValue("은행명"),
      TextCellValue("은행메모(원본)"), TextCellValue("담당자메모")
    ]);

    for (var tx in _bankList.where((t) => !t.isUsed && t.amount > 0 && !_isAutoPaymentTx(t) && !_isVirtualAccountTx(t))) {
      unconfirmedSheet.appendRow([
        TextCellValue(tx.date), TextCellValue(tx.description),
        TextCellValue(_formatCurrency(tx.amount)), TextCellValue(tx.bankName),
        TextCellValue(tx.memo), TextCellValue(tx.managerMemo)
      ]);

      int currentRowIdx = unconfirmedSheet.maxRows - 1;
      var memoCell = unconfirmedSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRowIdx));

      memoCell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4'),
        verticalAlign: VerticalAlign.Center,
      );
    }

    excel.setDefaultSheet("전체세대");

    var bytes = excel.encode();
    if (bytes != null) {
      DateTime n = DateTime.now();
      String dateStr = "${n.year}${n.month.toString().padLeft(2,'0')}${n.day.toString().padLeft(2,'0')}";
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)..setAttribute("download", "[AI수납정산결과]_$dateStr.xlsx")..click();
      html.Url.revokeObjectUrl(url);
      _showSnackBar("엑셀 다운로드가 완료되었습니다.");
    }
  }

  void _showMemoEditPopup(ResidentRow row) {
    TextEditingController ctrl = TextEditingController(text: row.managerMemo);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("${row.dong}동 ${row.ho}호 담당자 메모", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl, maxLines: 3,
            decoration: const InputDecoration(hintText: "특이사항을 입력하세요", border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            ElevatedButton(
                onPressed: () {
                  String newText = ctrl.text.trim();
                  if (newText.isNotEmpty && newText != row.managerMemo) {
                    final now = DateTime.now();
                    String timestamp = "[${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}]";
                    if (!newText.startsWith('[')) { newText = "$timestamp $newText"; }
                  }
                  setState(() => row.managerMemo = newText);
                  Navigator.pop(ctx);
                },
                child: const Text("저장")
            )
          ],
        )
    );
  }

  void _showOthersEditPopup(ResidentRow row) {
    List<TextEditingController> ctrls = List.generate(
        4, (i) => TextEditingController(text: row.others[i] == "-" ? "" : row.others[i])
    );
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("${row.dong}동 ${row.ho}호 기타 인원 전체 수정", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: ctrls[i],
                  decoration: InputDecoration(labelText: "기타 인원 ${i + 1}", border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                ),
              )),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            ElevatedButton(
                onPressed: () {
                  setState(() { row.others = ctrls.map((c) => c.text.trim().isEmpty ? "-" : c.text.trim()).toList(); });
                  Navigator.pop(ctx);
                },
                child: const Text("저장")
            )
          ],
        )
    );
  }

  // 🌟 [관제탑 전용 메모리 청소]
  @override
  void dispose() {
    _ownerCtrl.dispose();
    _residentCtrl.dispose();
    _othersCtrl.dispose(); // 추가됨
    _remarkCtrl.dispose(); // 추가됨
    _bankCtrl.dispose();   // 추가됨
    _aiCtrl.dispose(); // 추가
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 800) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.desktop_mac, size: 80, color: Colors.black26),
              const SizedBox(height: 24),
              const Text("PC 환경 최적화 메뉴", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              const SizedBox(height: 12),
              const Text("엑셀 업로드 및 AI 자동수납 작업은\nPC 웹 브라우저 환경에서 이용해 주세요.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.5, color: AppTheme.textSub)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          if (_isResidentLoaded && _isBankLoaded) _buildSummaryBar(),
          Expanded(
            child: _residentList.isEmpty ? _buildEmptyState() : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      width: double.infinity,
      color: Colors.white,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("AI 자동수납 시스템 (전산팀)", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                const SizedBox(height: 4),
                Text("${GlobalUserState.fullName} 담당자 • AI 수납 분석 모드", style: const TextStyle(color: AppTheme.textSub, fontSize: 13)),
              ]
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _uploadBtn("입주자 명부", Icons.people_alt_outlined, _loadResidentExcel, _isResidentLoaded),
              _uploadBtn("은행 입금내역", Icons.account_balance_wallet_outlined, _loadBankExcel, _isBankLoaded),
              ElevatedButton.icon(
                onPressed: (_isResidentLoaded && _isBankLoaded && !_isProcessing) ? _runAiMatching : null,
                icon: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome, size: 20),
                label: Text(_isProcessing ? "분석 중..." : "AI 수납 매칭", style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: (_residentList.isNotEmpty) ? _downloadExcel : null,
                icon: const Icon(Icons.download, size: 20),
                label: const Text("엑셀 다운로드", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700], foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _manualMatchFromBank(BankTx tx, {bool isCheckRequired = false}) {
    if (tx.inputDong.trim().isEmpty || tx.inputHo.trim().isEmpty) {
      _showSnackBar("동과 호수를 필수로 입력해주세요.", isError: true);
      return;
    }

    setState(() {
      ResidentRow newRow = ResidentRow(
        dong: tx.inputDong.trim(),
        ho: tx.inputHo.trim(),
        owner: tx.inputOwner.trim(),
        resident: tx.inputResident.trim(),
        others: [tx.inputOthers.trim(), "-", "-", "-"],
        type: tx.inputType.trim(),
        remark: tx.inputRemark.trim(),
      );

      newRow.isMatched = true;
      newRow.isCheckRequired = isCheckRequired;
      newRow.matchedBankText = tx.description;
      newRow.matchedAmount = tx.amount;
      newRow.matchedBankName = tx.bankName;
      newRow.matchedDate = tx.date;
      newRow.matchedMemo = tx.memo;
      newRow.matchedField = isCheckRequired ? "수동등록 (미확인➔확인필요)" : "수동등록 (미확인➔매칭완료)";
      newRow.matchedTx = tx;
      newRow.managerMemo = tx.managerMemo;

      int insertIdx = _residentList.length;
      for (int i = 0; i < _residentList.length; i++) {
        if (_residentList[i].dong == newRow.dong && _residentList[i].ho == newRow.ho) {
          insertIdx = i + 1;
          while (insertIdx < _residentList.length && _residentList[insertIdx].dong == newRow.dong && _residentList[insertIdx].ho == newRow.ho) {
            insertIdx++;
          }
          break;
        }
      }
      _residentList.insert(insertIdx, newRow);
      tx.isUsed = true;
    });
    _showSnackBar("${tx.inputDong}동 ${tx.inputHo}호 이동이 완료되었습니다.");
  }

  // =======================================================
  // 🌟 [수정 3] "수납 확인" 탭 클릭 시 전용 심플 UI 헤더 적용
  // =======================================================
  Widget _buildDataTable() {
    List<dynamic> displayList = [];

    // --- 🛡️ 6차 초정밀 필터 엔진 (빨간 화면 방어 및 AI 검색 추가) ---
    if (_currentFilter == "unconfirmed" || _currentFilter == "auto_paid") {
      // 1. 미확인 및 수납확인(PG) 탭 필터링
      displayList = _bankList.where((tx) {
        // 기본 조건 필터 (미확인 vs PG/가상)
        if (_currentFilter == "unconfirmed") {
          if (tx.isUsed || tx.amount <= 0 || _isAutoPaymentTx(tx) || _isVirtualAccountTx(tx)) return false;
        } else {
          bool isTypeMatch = (_receiptSubTab == 0) ? _isAutoPaymentTx(tx) : _isVirtualAccountTx(tx);
          if (!isTypeMatch || tx.amount <= 0) return false;
        }

        // 🌟 통합 검색 (날짜, 금액, 적요, 은행명)
        if (_bankSearch.isEmpty) return true;
        String search = _bankSearch.toLowerCase();
        return tx.description.toLowerCase().contains(search) ||
            tx.date.contains(search) ||
            tx.amount.toString().contains(search) ||
            tx.bankName.toLowerCase().contains(search);
      }).toList();
    }
    else {
      // 2. 일반/매칭/대기/확인필요 탭 필터링
      List<Map<String, dynamic>> wrappedList = [];
      for (int i = 0; i < _residentList.length; i++) {
        var r = _residentList[i];
        bool isSpecial = r.matchedTx != null && (_isAutoPaymentTx(r.matchedTx!) || _isVirtualAccountTx(r.matchedTx!));

        if (_currentFilter == "matched" && (!r.isMatched || r.isCheckRequired || isSpecial)) continue;
        if (_currentFilter == "check_required" && (!r.isCheckRequired || isSpecial)) continue;
        if (_currentFilter == "pending" && r.isMatched) continue;

        // 🔍 전방위 다중 필터망
        if (_ownerSearch.isNotEmpty && !r.owner.toLowerCase().contains(_ownerSearch.toLowerCase())) continue;
        if (_residentSearch.isNotEmpty && !r.resident.toLowerCase().contains(_residentSearch.toLowerCase())) continue;
        if (_othersSearch.isNotEmpty && !r.others.any((name) => name.toLowerCase().contains(_othersSearch.toLowerCase()))) continue;
        if (_remarkSearch.isNotEmpty && !r.remark.toLowerCase().contains(_remarkSearch.toLowerCase())) continue;

        // 🌟 [추가] AI 분석 결과 필터링
        if (_aiSearch.isNotEmpty && !r.matchedField.toLowerCase().contains(_aiSearch.toLowerCase())) continue;

        wrappedList.add({'index': i, 'item': r});
      }

      // (정렬 로직 유지)
      if (_sortAiMode == 1) {
        wrappedList.sort((a, b) {
          int scoreA = a['item'].matchedField.contains("수동") ? 1 : 0;
          int scoreB = b['item'].matchedField.contains("수동") ? 1 : 0;
          if (scoreA != scoreB) return scoreB.compareTo(scoreA);
          return (a['index'] as int).compareTo(b['index'] as int);
        });
      } else if (_sortAiMode == 2) {
        wrappedList.sort((a, b) {
          ResidentRow rowA = a['item']; ResidentRow rowB = b['item'];
          if (!rowA.isMatched && rowB.isMatched) return 1;
          if (rowA.isMatched && !rowB.isMatched) return -1;
          if (!rowA.isMatched && !rowB.isMatched) return (a['index'] as int).compareTo(b['index'] as int);
          int dateCmp = rowA.matchedDate.compareTo(rowB.matchedDate);
          if (dateCmp != 0) return dateCmp;
          return (a['index'] as int).compareTo(b['index'] as int);
        });
      }
      displayList = wrappedList.map((e) => e['item']).toList();
    }

    // 👇 🌟 [신규 추가] 공통 거래일 정렬 로직 (모든 탭에 공통 적용됩니다!)
    if (_sortDateMode != 0) {
      displayList.sort((a, b) {
        String dateA = ""; String dateB = "";
        if (a is BankTx) dateA = a.date; else if (a is ResidentRow) dateA = a.matchedDate;
        if (b is BankTx) dateB = b.date; else if (b is ResidentRow) dateB = b.matchedDate;

        if (dateA.isEmpty && dateB.isNotEmpty) return 1;
        if (dateA.isNotEmpty && dateB.isEmpty) return -1;

        int cmp = dateA.compareTo(dateB);
        return _sortDateMode == 1 ? cmp : -cmp; // 1: 빠른순(과거), 2: 느린순(최신)
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Container(
            color: Colors.grey[100], padding: const EdgeInsets.symmetric(vertical: 8),
            child: _currentFilter == "auto_paid"
                ? Builder(
                builder: (context) {
                  // 🌟 라디오 버튼 옆에 보여줄 건수 계산
                  int autoCount = _bankList.where((tx) => tx.amount > 0 && _isAutoPaymentTx(tx)).length;
                  int vBankCount = _bankList.where((tx) => tx.amount > 0 && _isVirtualAccountTx(tx)).length;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Radio<int>(value: 0, groupValue: _receiptSubTab, activeColor: Colors.indigo, onChanged: (v) => setState(() => _receiptSubTab = v!)),
                          Text("자동이체 (PG/카드) $autoCount건", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          const SizedBox(width: 30),
                          Radio<int>(value: 1, groupValue: _receiptSubTab, activeColor: Colors.indigo, onChanged: (v) => setState(() => _receiptSubTab = v!)),
                          Text("가상계좌 (제휴/아파트아이) $vBankCount건", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        // 🌟 자동이체, 가상계좌 모두 동/호수 헤더를 표시하도록 통일!
                        children: [
                          _headerCell("동", 5), _headerCell("호", 6), _sortableDateHeader(10),
                          _headerCell(_receiptSubTab == 0 ? "구분 (결제수단)" : "구분 (가상계좌)", 12),
                          _headerCell("적요 (입금내역)", 22), _headerCell("입금액", 10),
                          _headerCell("상대은행", 10), _headerCell("담당자 메모", 20)
                        ],
                      )
                    ],
                  );
                }
            )
                : Row(
              children: [
                _headerCell("동", 5),
                _headerCell("호", 6),
                _searchHeaderCell("소유자", 10, _ownerCtrl, (v) => setState(() => _ownerSearch = v)),
                _searchHeaderCell("입주자", 10, _residentCtrl, (v) => setState(() => _residentSearch = v)),

                // 🌟 [수정] 기타 인원 검색바 장착 (접힌 내용까지 전수조사)
                _searchHeaderCell("기타(전수조사)", 10, _othersCtrl, (v) => setState(() => _othersSearch = v)),

                // '구분' 정렬 칸 (기존 유지)
                Expanded(flex: 6, child: InkWell( onTap: () => setState(() { _sortTypeMode = (_sortTypeMode + 1) % 3; _sortAiMode = 0; _sortDateMode = 0; }), child: Column( mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [ Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Text("구분", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _sortTypeMode > 0 ? AppTheme.primaryColor : AppTheme.textMain)), Icon(Icons.sort, size: 14, color: _sortTypeMode > 0 ? AppTheme.primaryColor : Colors.grey)]), if (_sortTypeMode == 1) const Text("(소유주)", style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)), if (_sortTypeMode == 2) const Text("(임차인)", style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)), ], ), )),

                // 🌟 [수정] 비고 검색바 장착
                _searchHeaderCell("비고", 10, _remarkCtrl, (v) => setState(() => _remarkSearch = v)),

                _headerCell("상태(보내기)", 11),

                // 🌟 [수정 완료] 수납확인 탭 에러 방지 + AI 분석 결과 검색 기능 탑재
                Expanded(
                  flex: 20,
                  child: (_currentFilter == "unconfirmed" || _currentFilter == "auto_paid")
                      ? _searchHeaderCell("미확인/수납 통합 검색", 20, _bankCtrl, (v) => setState(() => _bankSearch = v))
                      : _searchHeaderCell("AI 분석 결과 검색", 20, _aiCtrl, (v) => setState(() => _aiSearch = v)),
                ),

                // 담당자 메모 칸 (수납 보기 버튼 유지)
                Expanded(flex: 12, child: _currentFilter == "matched" ? Column( mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [ InkWell( onTap: _showReceiptPopup, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: Colors.blue[700], borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]), child: const Text("수납 보기", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))), ), const SizedBox(height: 6), const Text("담당자 메모", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMain)), ], ) : const Text("담당자 메모", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMain))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: displayList.isEmpty
                ? const Center(child: Text("데이터가 없습니다.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final item = displayList[index];
                if (item is BankTx) {
                  if (_currentFilter == "auto_paid") return _buildAutoPaidRow(item, index, _receiptSubTab == 1);
                  return _buildUnconfirmedRow(item);
                }
                bool isTop = false, isBottom = false, isGroup = false;
                if (item is ResidentRow) {
                  bool sameAsPrev = index > 0 && displayList[index - 1] is ResidentRow && (displayList[index - 1] as ResidentRow).dong == item.dong && (displayList[index - 1] as ResidentRow).ho == item.ho;
                  bool sameAsNext = index < displayList.length - 1 && displayList[index + 1] is ResidentRow && (displayList[index + 1] as ResidentRow).dong == item.dong && (displayList[index + 1] as ResidentRow).ho == item.ho;
                  isGroup = sameAsPrev || sameAsNext; isTop = isGroup && !sameAsPrev; isBottom = isGroup && !sameAsNext;
                }
                return _buildResidentRow(item as ResidentRow, isGroup: isGroup, isTop: isTop, isBottom: isBottom);
              },
            ),
          ),
          if (_currentFilter == "auto_paid" && displayList.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: Colors.indigo.shade50, border: Border(top: BorderSide(color: Colors.indigo.shade200, width: 2))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("${_receiptSubTab == 0 ? '자동이체' : '가상계좌'} 총 건수 :  ${displayList.length} 건", style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 30),
                  Text("총 입금 합계 :  ${_formatCurrency(displayList.fold(0, (sum, item) => sum + (item as BankTx).amount))} 원", style: TextStyle(fontSize: 20, color: Colors.indigo[900], fontWeight: FontWeight.w900)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildResidentRow(ResidentRow row, {bool isGroup = false, bool isTop = false, bool isBottom = false}) {
    BorderSide thickGreen = BorderSide(color: Colors.green.shade800, width: 2.5);
    BorderSide thinGrey = BorderSide(color: Colors.grey.shade200);

    // 🌟 [핵심 수정 1] 텍스트 입력 후 UI를 즉시 갱신하도록 setState 추가
    Widget _editableCell(String fieldName, String value, Function(String) onChanged, int flex, {bool highlight = false, bool isType = false}) {
      Color borderColor = row.isCheckRequired ? Colors.orange[300]! : (row.isMatched ? Colors.green[300]! : Colors.grey[300]!);

      return Expanded(
          flex: flex,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6), height: 28,
            child: InlineEditableText(
              text: value,
              // 🚨 여기서 화면 새로고침 지시!
              onChanged: (v) {
                setState(() {
                  onChanged(v);
                });
              },
              isHighlight: highlight,
              isType: isType,
              borderColor: borderColor,
            ),
          )
      );
    }

    // 🌟 [핵심 수정 2] 기타 인원 셀 수정 시에도 UI 즉시 갱신
    Widget _editableOthersCell(int flex) {
      String initVal = (row.others.isNotEmpty && row.others[0] != "-") ? row.others[0] : "";
      Color borderColor = row.isCheckRequired ? Colors.orange[300]! : (row.isMatched ? Colors.green[300]! : Colors.grey[300]!);

      return Expanded(
          flex: flex,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6), height: 28,
                  child: InlineEditableText(
                    text: initVal,
                    // 🚨 여기서 화면 새로고침 지시!
                    onChanged: (v) {
                      setState(() {
                        if (row.others.isEmpty) row.others = [v, "-", "-", "-"];
                        else row.others[0] = v.isEmpty ? "-" : v;
                      });
                    },
                    borderColor: borderColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showOthersEditPopup(row),
                icon: Icon(Icons.group_add_outlined, size: 16, color: borderColor),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              )
            ],
          )
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: row.isCheckRequired ? Colors.orange.withOpacity(0.12) : (row.isMatched ? Colors.green.withOpacity(0.08) : Colors.transparent),
        border: Border(
          top: isTop ? thickGreen : BorderSide.none,
          bottom: isGroup ? (isBottom ? thickGreen : thinGrey) : thinGrey,
          left: isGroup ? thickGreen : BorderSide.none,
          right: isGroup ? thickGreen : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isTop)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: InkWell(
                      onTap: () => _handleSmartMerge(row.dong, row.ho),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  )
                else if (row.isMerged)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: InkWell(
                      onTap: () => _unmergeRow(row),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.remove, size: 14, color: Colors.white),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 20),

                Expanded(
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                      alignment: Alignment.center,
                      child: Text(
                          row.dong.isEmpty ? "-" : row.dong,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: (row.isMatched && row.matchedField.contains("동")) ? FontWeight.bold : FontWeight.normal,
                              color: (row.isMatched && row.matchedField.contains("동")) ? Colors.green[900] : AppTheme.textMain,
                              fontSize: 11
                          ),
                          overflow: TextOverflow.ellipsis
                      )
                  ),
                ),
              ],
            ),
          ),

          _dataCell(row.ho, 6, isHighlight: row.isMatched && row.matchedField.contains("호")),

          _editableCell("owner", row.owner, (v) => row.owner = v, 10, highlight: row.isMatched && row.matchedBankText.contains(row.owner) && row.owner.isNotEmpty),
          _editableCell("resident", row.resident, (v) => row.resident = v, 10, highlight: row.isMatched && row.matchedBankText.contains(row.resident) && row.resident.isNotEmpty),
          _editableOthersCell(10),

          _editableCell("type", row.type, (v) => row.type = v, 6, isType: true),
          _editableCell("remark", row.remark, (v) => row.remark = v, 10),

          Expanded(
            flex: 11,
            child: (row.isMatched || row.isCheckRequired) ? Container(
              height: 26, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: row.isCheckRequired ? "확인필요" : "매칭완료",
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  isExpanded: true,
                  style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: "매칭완료", child: Text("매칭완료", style: TextStyle(color: Colors.green))),
                    DropdownMenuItem(value: "확인필요", child: Text("확인필요", style: TextStyle(color: Colors.orange))),
                    DropdownMenuItem(value: "매칭대기", child: Text("매칭 취소", style: TextStyle(color: Colors.red))),
                  ],
                  onChanged: (val) { if (val != null) _changeStatus(row, val == "매칭 취소" ? "매칭대기" : val); },
                ),
              ),
            ) : const SizedBox(),
          ),

          Expanded(
            flex: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  if (row.isMatched)
                    IconButton(
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        icon: const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        onPressed: () => _showBankDetailsPopup(row)
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(
                            builder: (context) {
                              String displayDate = "";
                              if (row.isMatched && row.matchedDate.isNotEmpty) {
                                displayDate = row.matchedDate.split(' ')[0].replaceAll('-', '.').replaceAll('/', '.');
                                if (!displayDate.endsWith('.')) displayDate += ".";
                              }
                              return Text(
                                row.isMatched ? "$displayDate / ${row.matchedBankText} / ${_formatCurrency(row.matchedAmount)}원" : "-",
                                style: TextStyle(color: row.isCheckRequired ? Colors.orange[900] : (row.isMatched ? Colors.green[900] : Colors.grey), fontWeight: FontWeight.bold, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                        ),
                        if (row.isMatched && row.matchedField.isNotEmpty)
                          Text(
                            row.matchedField,
                            style: TextStyle(
                                color: row.matchedField.contains("수동") ? Colors.blue[800] : Colors.grey,
                                fontSize: 9,
                                fontWeight: row.matchedField.contains("수동") ? FontWeight.bold : FontWeight.normal
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
              flex: 12,
              child: InkWell(
                onTap: () => _showMemoEditPopup(row),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  padding: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: row.managerMemo.isEmpty ? Colors.grey[50] : Colors.yellow[100],
                      border: Border.all(color: row.managerMemo.isEmpty ? Colors.grey[200]! : Colors.yellow[400]!),
                      borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(
                    row.managerMemo.isEmpty ? "+ 메모입력" : row.managerMemo,
                    style: TextStyle(fontSize: 10, color: row.managerMemo.isEmpty ? Colors.grey : Colors.black87),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }

  Widget _buildUnconfirmedRow(BankTx tx) {
    // 🌟 [핵심 수정 3] 미확인 입금 수동 입력창도 UI 즉시 갱신
    Widget _inputCell(String hint, String value, Function(String) onChanged, int flex) {
      return Expanded(
          flex: flex,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            height: 28,
            child: InlineEditableText(
              text: value,
              hintText: hint,
              // 🚨 여기서 화면 새로고침 지시!
              onChanged: (v) {
                setState(() {
                  onChanged(v);
                });
              },
              borderColor: Colors.grey[300]!,
            ),
          )
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _inputCell("동", tx.inputDong, (v) => tx.inputDong = v, 5),
          _inputCell("호", tx.inputHo, (v) => tx.inputHo = v, 6),
          _inputCell("소유자", tx.inputOwner, (v) => tx.inputOwner = v, 10),
          _inputCell("입주자", tx.inputResident, (v) => tx.inputResident = v, 10),
          _inputCell("기타", tx.inputOthers, (v) => tx.inputOthers = v, 10),
          _inputCell("구분", tx.inputType, (v) => tx.inputType = v, 6),
          _inputCell("비고", tx.inputRemark, (v) => tx.inputRemark = v, 10),

          Expanded(
            flex: 11,
            child: Container(
              height: 26, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.red[300]!), borderRadius: BorderRadius.circular(4)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: "미확인",
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  isExpanded: true,
                  style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: "미확인", child: Text("미확인", style: TextStyle(color: Colors.red))),
                    DropdownMenuItem(value: "확인필요", child: Text("확인필요(보내기)", style: TextStyle(color: Colors.orange))),
                    DropdownMenuItem(value: "매칭완료", child: Text("매칭완료(보내기)", style: TextStyle(color: Colors.green))),
                  ],
                  onChanged: (val) {
                    if (val == "매칭완료") _manualMatchFromBank(tx, isCheckRequired: false);
                    else if (val == "확인필요") _manualMatchFromBank(tx, isCheckRequired: true);
                  },
                ),
              ),
            ),
          ),

          Expanded(
            flex: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.date, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  Text(
                    "❌ ${tx.description} / ${_formatCurrency(tx.amount)}원",
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
              flex: 12,
              child: InkWell(
                  onTap: () {
                    TextEditingController ctrl = TextEditingController(text: tx.managerMemo);
                    showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                            title: const Text("미확인 입금 메모", style: TextStyle(fontWeight: FontWeight.bold)),
                            content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: "특이사항을 입력하세요", border: OutlineInputBorder())),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
                              ElevatedButton(
                                  onPressed: () {
                                    String newText = ctrl.text.trim();
                                    if (newText.isNotEmpty && newText != tx.managerMemo) {
                                      final now = DateTime.now();
                                      String timestamp = "[${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}]";
                                      if (!newText.startsWith('[')) {
                                        newText = "$timestamp $newText";
                                      }
                                    }
                                    setState(() => tx.managerMemo = newText);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text("저장")
                              )
                            ]
                        )
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    padding: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: tx.managerMemo.isEmpty ? Colors.white : Colors.yellow[100],
                        border: Border.all(color: tx.managerMemo.isEmpty ? Colors.grey[300]! : Colors.yellow[400]!),
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(
                      tx.managerMemo.isEmpty ? "+ 메모입력" : tx.managerMemo,
                      style: TextStyle(fontSize: 10, color: tx.managerMemo.isEmpty ? Colors.grey : Colors.black87),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  )
              )
          ),
        ],
      ),
    );
  }

  // =======================================================
  // 🌟 [수정] "수납 확인" 전용 UI (가상계좌 시 동/호 렌더링 지원)
  // =======================================================
  Widget _buildAutoPaidRow(BankTx tx, int index, bool isVBank) {
    String dong = "-";
    String ho = "-";

    // 👇 🌟 자동이체(카드)든 가상계좌든, AI가 동/호수를 찾았다면 무조건 가져옵니다!
    if (tx.isUsed) {
      try {
        for (var r in _residentList) {
          if (r.matchedTx == tx) {
            dong = r.dong;
            ho = r.ho;
            break;
          }
        }
      } catch (e) { /* 매칭 못찾음 */ }
    }

    return Container(
      decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.indigo.withOpacity(0.03),
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))
      ),
      child: Row(
        children: [
          // 🌟 가상계좌/자동이체 모두 동/호수 열 렌더링 (매칭 안 된 건 - 로 표시됨)
          Expanded(flex: 5, child: Container(alignment: Alignment.center, child: Text(dong, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)))),
          Expanded(flex: 6, child: Container(alignment: Alignment.center, child: Text(ho, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)))),

          Expanded(flex: 10, child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4), alignment: Alignment.center, child: Text(tx.date, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)))),
          Expanded(flex: 12, child: Container(alignment: Alignment.center, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isVBank ? Colors.teal : Colors.indigo, borderRadius: BorderRadius.circular(4)), child: Text(isVBank ? "가상계좌" : "자동납부(PG)", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))))),
          Expanded(flex: 22, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text(tx.description, textAlign: TextAlign.center, style: TextStyle(color: isVBank ? Colors.teal[900] : Colors.indigo[900], fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis))),
          Expanded(flex: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text("${_formatCurrency(tx.amount)}원", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)))),
          Expanded(flex: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text(tx.bankName.isEmpty ? "-" : tx.bankName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)))),

          Expanded(flex: 20, child: InkWell(
            onTap: () {
              TextEditingController ctrl = TextEditingController(text: tx.managerMemo);
              showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("수납 메모", style: TextStyle(fontWeight: FontWeight.bold)), content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: "특이사항 입력", border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")), ElevatedButton(onPressed: () { String newText = ctrl.text.trim(); if (newText.isNotEmpty && newText != tx.managerMemo) { final now = DateTime.now(); newText = "[${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}] $newText"; } setState(() => tx.managerMemo = newText); Navigator.pop(ctx); }, child: const Text("저장"))]));
            },
            child: Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(8), alignment: Alignment.center, decoration: BoxDecoration(color: tx.managerMemo.isEmpty ? Colors.white : Colors.yellow[100], border: Border.all(color: tx.managerMemo.isEmpty ? Colors.grey[300]! : Colors.yellow[400]!), borderRadius: BorderRadius.circular(4)), child: Text(tx.managerMemo.isEmpty ? "+ 메모입력" : tx.managerMemo, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: tx.managerMemo.isEmpty ? Colors.grey : Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis)),
          )),
        ],
      ),
    );
  }

  Widget _buildOthersCell(ResidentRow row, int flex, {bool isHighlight = false}) {
    List<String> validOthers = row.others.where((e) => e != "-" && e.isNotEmpty).toList();
    Widget content;
    if (validOthers.isEmpty) {
      content = Text("-", style: TextStyle(color: isHighlight ? Colors.green[900] : AppTheme.textMain, fontSize: 11));
    } else if (validOthers.length == 1) {
      content = Text(validOthers[0], style: TextStyle(color: isHighlight ? Colors.green[900] : AppTheme.textMain, fontSize: 11, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis);
    } else {
      content = InkWell(
        onTap: () => _showOthersDetailsPopup(row.dong, row.ho, validOthers),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), border: Border.all(color: Colors.purple.withOpacity(0.2)), borderRadius: BorderRadius.circular(4)),
          child: Text("${validOthers[0]} 외 ${validOthers.length - 1}", style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
        ),
      );
    }
    return Expanded(flex: flex, child: Container(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10), alignment: Alignment.center, color: Colors.transparent, child: content));
  }

  Widget _headerCell(String title, int flex) {
    return Expanded(
        flex: flex,
        child: Container(
            alignment: Alignment.center, // 🌟 컨테이너 내부의 모든 요소를 정중앙으로!
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
                title,
                textAlign: TextAlign.center, // 🌟 글씨 자체도 정중앙으로!
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMain),
                overflow: TextOverflow.ellipsis
            )
        )
    );
  }

  Widget _searchHeaderCell(String title, int flex, TextEditingController ctrl, Function(String) onChanged) {
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Container(
            margin: const EdgeInsets.only(top: 4, left: 6, right: 6), height: 28,
            child: TextField(controller: ctrl, onChanged: onChanged, style: const TextStyle(fontSize: 11), decoration: InputDecoration(hintText: "검색", prefixIcon: const Icon(Icons.search, size: 12), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)), fillColor: Colors.white, filled: true)),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(String text, int flex, {bool isHighlight = false, Color? textColor}) {
    return Expanded(flex: flex, child: Container(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10), alignment: Alignment.center, color: Colors.transparent, child: Text(text.isEmpty ? "-" : text, textAlign: TextAlign.center, style: TextStyle(fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal, color: isHighlight ? Colors.green[900] : (textColor ?? AppTheme.textMain), fontSize: 11), overflow: TextOverflow.ellipsis)));
  }

  void _showOthersDetailsPopup(String dong, String ho, List<String> others) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Row(children: [const Icon(Icons.people_alt, color: Colors.purple), const SizedBox(width: 8), Text("$dong동 $ho호 기타 인원", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: others.map((name) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.person, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]))).toList()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기", style: TextStyle(fontWeight: FontWeight.bold)))]));
  }

  void _showBankDetailsPopup(ResidentRow row) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("은행 입금 상세정보", style: TextStyle(fontWeight: FontWeight.bold)), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [_detailRow("거래일시", row.matchedDate.isNotEmpty ? row.matchedDate : "-"), const Divider(), _detailRow("내 용", row.matchedBankText, isHighlight: true), _detailRow("입 금 액", "${_formatCurrency(row.matchedAmount)}원", isHighlight: true), const Divider(), _detailRow("상대은행", row.matchedBankName.isNotEmpty ? row.matchedBankName : "-"), _detailRow("메 모", row.matchedMemo.isNotEmpty ? row.matchedMemo : "-")]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]));
  }

  Widget _detailRow(String title, String value, {bool isHighlight = false}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 80, child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))), Expanded(child: Text(value, style: TextStyle(fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal, color: isHighlight ? AppTheme.primaryColor : Colors.black87, fontSize: isHighlight ? 15 : 14)))]));
  }

  Widget _uploadBtn(String title, IconData icon, VoidCallback onPressed, bool isDone) {
    return OutlinedButton.icon(onPressed: onPressed, icon: Icon(isDone ? Icons.check_circle : icon, color: isDone ? Colors.green : AppTheme.primaryColor), label: Text(isDone ? "$title 완료" : title), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), side: BorderSide(color: isDone ? Colors.green : AppTheme.borderColor)));
  }

    // =======================================================
    // 🌟 결제 수단 분류 엔진 (자동이체 vs 가상계좌)
    // =======================================================
    int _receiptSubTab = 0; // 0: 자동이체, 1: 가상계좌

  // 🗂️ [가상계좌 식별기]
  bool _isVirtualAccountTx(BankTx tx) {
    String desc = tx.description.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    String type = tx.txType.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    String cms = tx.cmsCode.replaceAll(RegExp(r'[^0-9]'), '');

    // 1. 거래구분 또는 내용에 '제휴' 나 '가상'이 있으면 무조건 가상계좌!
    if (type.contains('가상') || type.contains('제휴')) return true;
    if (desc.contains('가상') || desc.contains('제휴')) return true;

    // 2. 아파트아이 전용
    if (desc.contains('아파트아이')) return true;

    // 3. '거래일0225' 등 숫자만 붙은 오류 방어막
    if (RegExp(r'(거래|거래일|거래일자)[:\s]*\d{1,4}[-./]?\d{1,4}').hasMatch(desc)) return true;

    // 4. [대표님 추가요청] CMS코드란에 연속된 숫자 9자리 이상이 있으면 무조건 가상계좌!
    if (cms.length >= 9) return true;

    return false;
  }

  // 🗂️ [자동이체 식별기] (스마트 분리망 적용)
  bool _isAutoPaymentTx(BankTx tx) {
    if (_isVirtualAccountTx(tx)) return false;

    String normalizedDesc = "";
    for (int k = 0; k < tx.description.length; k++) {
      int code = tx.description.codeUnitAt(k);
      if (code >= 0xFF01 && code <= 0xFF5E) normalizedDesc += String.fromCharCode(code - 0xFEE0);
      else if (code == 0x3000) normalizedDesc += " ";
      else normalizedDesc += String.fromCharCode(code);
    }
    String cleanDesc = normalizedDesc.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    // 0️⃣ [핀테크 수동송금 예외처리] - 최우선 방어막
    // 입주민이 수동으로 보낸 카카오페이, 토스 등은 PG사 탭으로 빠지지 않게 무조건 보호합니다.
    if (cleanDesc.contains('카카오페이') || cleanDesc.contains('토스') || cleanDesc.contains('toss') || cleanDesc.contains('네이버페이')) {
      return false;
    }

    // 1️⃣ [확실한 대행사 키워드] - 이지스엔터프라이즈 등 복구!
    List<String> strongPgKeywords = [
      '이지스', '엔터프라이즈', 'pg', '나이스', 'nice', 'kcp', '다날', 'danal',
      '모빌리언스', '펌뱅킹', '전자금융', '센터일괄', '한강아이린관리', '세틀뱅크', '효성fms',
      '아파트관리비',
    ];
    for (String k in strongPgKeywords) {
      if (cleanDesc.contains(k)) return true;
    }

    // 2️⃣ [카드결제 특수 패턴] - "카드3-6" 등 아파트 대행사 고유 포맷 완벽 흡수
    if (RegExp(r'카드\d+-\d+').hasMatch(cleanDesc)) {
      return true;
    }

    // 3️⃣ [조건부 키워드] - 대행사도 쓰고 주민도 쓰는 단어
    if (cleanDesc.contains('자동') || cleanDesc.contains('결제') || cleanDesc.contains('카드')) {
      // 텍스트 안에 숫자가 단 하나도 없다면, 대행사 대량 정산금으로 간주 (예: 우리카드결제)
      if (!RegExp(r'\d').hasMatch(cleanDesc)) return true;
    }

    // 4️⃣ [관리비 전용 텍스트 필터 + 🌟 송금자명(상대은행) 핀셋 방어 로직]
    if (cleanDesc.contains('아파트관리') || cleanDesc.contains('관리비')) {
      if (!RegExp(r'\d').hasMatch(cleanDesc)) { // 숫자가 없는 경우 (대행사 의심)

        // 🌟 [핵심 수술] 상대은행(보낸분) 텍스트를 소문자로 변환하여 싹 스캔합니다.
        String bankNameLower = tx.bankName.toLowerCase().replaceAll(RegExp(r'\s+'), '');

        // 1. 상대은행에 법인/대행사 냄새가 나는 단어가 있으면 얄짤없이 대행사(true)로 보냄
        if (RegExp(r'주식회사|\(주\)|\(유\)|\(사\)|페이|pay|정산|엔터프라이즈|관리|센터|이체|kcp|nice|나이스|다날|danal|모빌리언스|세틀뱅크|효성|fms|pg|결제').hasMatch(bankNameLower)) {
          return true;
        }

        // 2. 👇 [제한 해제!] 보낸 사람 이름이 한글 또는 영어 알파벳으로 이루어져 있다면 길이에 상관없이 사람으로 인정!
        // -> 한국인(홍길동), 한글 긴 이름(알렉산드르), 외국인 영어 이름(johndoe) 모두 통과!
        if (RegExp(r'^[가-힣a-z]+$').hasMatch(bankNameLower)) {
          return false; // 🟢 대행사 탭으로 가지 않고 '일반 매칭 엔진'으로 무사히 넘어갑니다!
        }

        // 그 외의 경우는 기존대로 대행사 대량 입금으로 간주
        return true;
      }
    }

    return false;
  }

  // =======================================================
  // 🌟 [수정 2] 요약 칩에 "수납 확인(PG)" 탭 추가 및 카운트 분리
  // =======================================================
  Widget _buildSummaryBar() {
    // 👇 일반 매칭에서 수납확인(자동/가상) 데이터는 뺍니다!
    int matchedCount = _residentList.where((r) => r.isMatched && !r.isCheckRequired && (r.matchedTx == null || (!_isAutoPaymentTx(r.matchedTx!) && !_isVirtualAccountTx(r.matchedTx!)))).length;
    int checkCount = _residentList.where((r) => r.isMatched && r.isCheckRequired && (r.matchedTx == null || (!_isAutoPaymentTx(r.matchedTx!) && !_isVirtualAccountTx(r.matchedTx!)))).length;

    // 🌟 [오류 보정] 자동이체로 동/호수가 매칭된 세대가 "매칭대기" 인원에 들어가는 버그 방지!
    int pendingCount = _residentList.where((r) => !r.isMatched).length;

    int unconfirmedCount = _bankList.where((tx) => !tx.isUsed && tx.amount > 0 && !_isAutoPaymentTx(tx) && !_isVirtualAccountTx(tx)).length;
    // 수납확인 탭 = 자동이체 + 가상계좌 모두 합친 갯수
    int autoPaidCount = _bankList.where((tx) => tx.amount > 0 && (_isAutoPaymentTx(tx) || _isVirtualAccountTx(tx))).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        spacing: 12,
        children: [
          _summaryChip("전체 세대", "${_residentList.length}", Colors.blue, "all", "입주자명부에 등록된 총 입주자 세대수"),
          _summaryChip("매칭 완료", "$matchedCount", Colors.green, "matched", "입주자명부와 은행데이터와 매칭된 세대"),
          _summaryChip("확인 필요", "$checkCount", Colors.orange, "check_required", "입주자명부와 은행데이터중 일부 매칭되어 확인이 필요한 세대"),
          _summaryChip("매칭 대기", "$pendingCount", Colors.grey, "pending", "입주자명부에는 있는데 은행데이터엔 없는 세대"),
          // 🌟 새로 추가된 파란색 탭!
          _summaryChip("수납 확인", "$autoPaidCount", Colors.indigo, "auto_paid", "PG사, 카드납부, 아파트아이 등 대행사 입금 내역"),
          _summaryChip("미확인 입금", "$unconfirmedCount", Colors.red, "unconfirmed", "은행데이터엔 있는데 입주자명부에 없는 세대 / 확인필요"),
        ],
      ),
    );
  }

  // 🌟 [툴팁 적용 완료] Tooltip 위젯으로 감싸고 0.3초 딜레이 및 디자인 적용
  Widget _summaryChip(String label, String value, Color color, String filterType, String tooltipMessage) {
    bool isSelected = _currentFilter == filterType;
    return Tooltip(
      message: tooltipMessage, // 마우스를 올리면 이 문구가 보입니다!
      waitDuration: const Duration(milliseconds: 300), // 마우스를 올리고 0.3초 뒤에 자연스럽게 뜸
      textStyle: const TextStyle(fontSize: 12, color: Colors.white), // 말풍선 글씨색
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8), // 말풍선 배경색 (반투명 검정)
        borderRadius: BorderRadius.circular(6), // 말풍선 모서리 둥글게
      ),
      child: InkWell(
        onTap: () => setState(() => _currentFilter = filterType),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: isSelected ? color : color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Text(value, style: TextStyle(fontSize: 14, color: isSelected ? Colors.white : color, fontWeight: FontWeight.w900))]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.drive_folder_upload, size: 100, color: Colors.grey[200]), const SizedBox(height: 20), const Text("데이터가 없습니다.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)), const Text("상단 버튼을 눌러 명부와 입금내역 엑셀을 업로드해 주세요.", style: TextStyle(color: Colors.grey))]));
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green));
  }

  void _showNoticePopup(String title, String message) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인"))]));
  }
}
// =======================================================
// 🌟 [UI/UX 메모리 최적화] 인라인 에디팅(Inline Editing) 위젯
// 평소엔 가벼운 Text로 렌더링하고, 클릭 시에만 무거운 TextField로 변환!
// =======================================================
class InlineEditableText extends StatefulWidget {
  final String text;
  final String? hintText;
  final Function(String) onChanged;
  final bool isHighlight;
  final bool isType;
  final Color borderColor;

  const InlineEditableText({
    super.key,
    required this.text,
    this.hintText,
    required this.onChanged,
    this.isHighlight = false,
    this.isType = false,
    required this.borderColor,
  });

  @override
  State<InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<InlineEditableText> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        // 포커스를 잃으면(다른 곳을 클릭하면) 자동으로 텍스트 모드로 복귀 및 저장
        setState(() {
          _isEditing = false;
          widget.onChanged(_controller.text);
        });
      }
    });
  }

  @override
  void didUpdateWidget(InlineEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !_isEditing) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 11,
            fontWeight: widget.isHighlight || (widget.isType && _controller.text.contains("수동")) ? FontWeight.bold : FontWeight.normal,
            color: (widget.isType && _controller.text.contains("수동")) ? Colors.black : Colors.black87
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 10),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
          border: OutlineInputBorder(borderSide: BorderSide(color: widget.borderColor, width: 1.5)),
          filled: true, fillColor: Colors.white,
        ),
        onFieldSubmitted: (v) {
          // 엔터키를 누르면 저장 후 텍스트 모드로 복귀
          setState(() {
            _isEditing = false;
            widget.onChanged(v);
          });
        },
      );
    }

    // [읽기 모드] 가벼운 렌더링
    return InkWell(
      onTap: () {
        setState(() => _isEditing = true);
        WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(4)
        ),
        child: Text(
          widget.text.isEmpty ? (widget.hintText ?? "") : widget.text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11,
              fontWeight: widget.isHighlight || (widget.isType && widget.text.contains("수동")) ? FontWeight.bold : FontWeight.normal,
              color: widget.text.isEmpty
                  ? Colors.grey
                  : ((widget.isType && widget.text.contains("수동")) ? Colors.black : Colors.black87)
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}