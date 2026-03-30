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
  bool isMultiGroupExcluded; // 🌟 [신규] 다중호실 그룹에서 개별 제외된 행
  ResidentRow? originalMain;
  ResidentRow? originalSub;

  ResidentRow({
    required this.dong, required this.ho, this.owner = "", this.resident = "",
    required this.others, this.type = "", this.remark = "",
    this.isMatched = false, this.isCheckRequired = false, this.matchedBankText = "",
    this.matchedField = "", this.matchedAmount = 0, this.matchedBankName = "",
    this.matchedDate = "", this.matchedMemo = "", this.matchedName = "", this.matchedTx, this.managerMemo = "",
    this.isMerged = false,
    this.isMultiGroupExcluded = false, // 🌟 신규
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
    r.isMultiGroupExcluded = isMultiGroupExcluded;
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
  // 🌟 [고도화] 담당자 전용 '수납 팝업창' (4단 탭: 일반, 대행사, 확인필요, 미확인 통합 대시보드)
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

    // 3. 확인필요 및 미확인 데이터 준비 (신규 탭용)
    List<ResidentRow> checkList = _residentList.where((r) {
      if (!r.isMatched || !r.isCheckRequired) return false;
      if (r.matchedTx != null && (_isAutoPaymentTx(r.matchedTx!) || _isVirtualAccountTx(r.matchedTx!))) return false;
      return true;
    }).toList();
    List<BankTx> unconfirmedList = _bankList.where((tx) => !tx.isUsed && tx.amount > 0 && !_isAutoPaymentTx(tx) && !_isVirtualAccountTx(tx)).toList();

    if (matchedList.isEmpty && autoList.isEmpty && vBankList.isEmpty && checkList.isEmpty && unconfirmedList.isEmpty) {
      _showSnackBar("표시할 수납 데이터가 없습니다.");
      return;
    }

    int popupMainTab = 0;
    int popupSubTab = 0;
    int sortMode = 0;
    String selectedDong = "전체";

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
                int checkedTotalAmt = checkedBankTxs.fold(0, (sum, tx) => sum + tx.amount);

                // 👇 🌟 [초고도화 엑셀 다운로드] 순수 숫자로 뽑아내고 엑셀 전용 '콤마(,)' 서식을 입혀 합계 계산을 완벽 지원합니다!
                void downloadReceiptExcel() {
                  var excel = Excel.createExcel();
                  String defaultSheet = excel.getDefaultSheet() ?? "Sheet1";
                  excel.rename(defaultSheet, "일반수납");

                  // 🌟 [핵심] 돈에 콤마를 찍어주는 엑셀 전용 마법의 옷 (숫자는 숫자로 유지하되 눈에만 콤마가 보임)
                  CellStyle moneyStyle = CellStyle(numberFormat: NumFormat.standard_3); // #,##0 포맷
                  CellStyle boldMoneyStyle = CellStyle(numberFormat: NumFormat.standard_3, bold: true);

                  // ==========================================
                  // 1️⃣ 일반 수납 내역 시트
                  // ==========================================
                  var sheet1 = excel["일반수납"];
                  sheet1.appendRow([TextCellValue("거래일"), TextCellValue("입금액"), TextCellValue("단위"), TextCellValue("동"), TextCellValue("호"), TextCellValue("매칭이름"), TextCellValue("내용 및 거래내용"), TextCellValue("상대은행"), TextCellValue("담당자 메모"), TextCellValue("수납상태")]);

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
                      TextCellValue(row.matchedDate.split(' ')[0]), IntCellValue(row.matchedAmount), TextCellValue("원"), TextCellValue(row.dong), TextCellValue(row.ho), TextCellValue(row.matchedName), TextCellValue(row.matchedBankText), TextCellValue(row.matchedBankName), TextCellValue(row.managerMemo), TextCellValue(isProcessed ? "수납완료" : "미수납")
                    ]);
                    int rIdx = sheet1.maxRows - 1;
                    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIdx)).cellStyle = moneyStyle; // 🌟 콤마 옷 입히기!
                    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rIdx)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4')); // 메모 노란색
                    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rIdx)).cellStyle = CellStyle(fontColorHex: isProcessed ? ExcelColor.fromHexString('#FF4CAF50') : ExcelColor.fromHexString('#FFF44336'), bold: true);
                  }
                  sheet1.appendRow([TextCellValue("")]);
                  sheet1.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액"), TextCellValue("단위")]);

                  sheet1.appendRow([TextCellValue("입금액 총액"), TextCellValue("${exportMatched.length}건"), IntCellValue(totalAmt1), TextCellValue("원")]);
                  sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sheet1.maxRows - 1)).cellStyle = boldMoneyStyle;

                  sheet1.appendRow([TextCellValue("수납액 총액"), TextCellValue("${rcvCnt1}건"), IntCellValue(rcvAmt1), TextCellValue("원")]);
                  sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sheet1.maxRows - 1)).cellStyle = boldMoneyStyle;

                  sheet1.appendRow([TextCellValue("미수납액 총액"), TextCellValue("${unRcvCnt1}건"), IntCellValue(unRcvAmt1), TextCellValue("원")]);
                  sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sheet1.maxRows - 1)).cellStyle = boldMoneyStyle;

                  // ==========================================
                  // 2️⃣ 자동이체 (PG/카드) 시트
                  // ==========================================
                  var sheet2 = excel["자동이체(PG_카드)"];
                  sheet2.appendRow([TextCellValue("동"), TextCellValue("호"), TextCellValue("거래일시"), TextCellValue("구분"), TextCellValue("적요(내용)"), TextCellValue("입금액"), TextCellValue("단위"), TextCellValue("상대은행"), TextCellValue("담당자 메모")]);

                  int totalAmt2 = 0;
                  for (var tx in autoList) {
                    totalAmt2 += tx.amount;
                    String dong = "-"; String ho = "-";
                    if (tx.isUsed) { try { var mr = _residentList.firstWhere((r) => r.matchedTx == tx); dong = mr.dong; ho = mr.ho; } catch (e) {} }

                    sheet2.appendRow([
                      TextCellValue(dong), TextCellValue(ho), TextCellValue(tx.date), TextCellValue("자동납부(PG)"), TextCellValue(tx.description), IntCellValue(tx.amount), TextCellValue("원"), TextCellValue(tx.bankName), TextCellValue(tx.managerMemo)
                    ]);
                    int rIdx = sheet2.maxRows - 1;
                    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rIdx)).cellStyle = moneyStyle; // 🌟 콤마 옷 입히기!
                    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rIdx)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4'));
                  }
                  sheet2.appendRow([TextCellValue("")]);
                  sheet2.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액"), TextCellValue("단위")]);

                  sheet2.appendRow([TextCellValue("총 수납액"), TextCellValue("${autoList.length}건"), IntCellValue(totalAmt2), TextCellValue("원")]);
                  sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sheet2.maxRows - 1)).cellStyle = boldMoneyStyle;

                  // ==========================================
                  // 3️⃣ 가상계좌 (제휴/아파트아이) 시트
                  // ==========================================
                  var sheet3 = excel["가상계좌(제휴_아파트아이)"];
                  sheet3.appendRow([TextCellValue("동"), TextCellValue("호"), TextCellValue("거래일시"), TextCellValue("구분"), TextCellValue("적요(내용)"), TextCellValue("입금액"), TextCellValue("단위"), TextCellValue("상대은행"), TextCellValue("담당자 메모")]);

                  int totalAmt3 = 0;
                  for (var tx in vBankList) {
                    totalAmt3 += tx.amount;
                    String dong = "-"; String ho = "-";
                    if (tx.isUsed) { try { var mr = _residentList.firstWhere((r) => r.matchedTx == tx); dong = mr.dong; ho = mr.ho; } catch (e) {} }

                    sheet3.appendRow([
                      TextCellValue(dong), TextCellValue(ho), TextCellValue(tx.date), TextCellValue("가상계좌/제휴"), TextCellValue(tx.description), IntCellValue(tx.amount), TextCellValue("원"), TextCellValue(tx.bankName), TextCellValue(tx.managerMemo)
                    ]);
                    int rIdx = sheet3.maxRows - 1;
                    sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rIdx)).cellStyle = moneyStyle; // 🌟 콤마 옷 입히기!
                    sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rIdx)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4'));
                  }
                  sheet3.appendRow([TextCellValue("")]);
                  sheet3.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액"), TextCellValue("단위")]);

                  sheet3.appendRow([TextCellValue("총 수납액"), TextCellValue("${vBankList.length}건"), IntCellValue(totalAmt3), TextCellValue("원")]);
                  sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sheet3.maxRows - 1)).cellStyle = boldMoneyStyle;

                  // ==========================================
                  // 4️⃣ 확인필요 내역 시트
                  // ==========================================
                  var sheet4 = excel["확인필요"];
                  sheet4.appendRow([TextCellValue("동"), TextCellValue("호"), TextCellValue("소유자"), TextCellValue("입주자"), TextCellValue("입금일자"), TextCellValue("입금액"), TextCellValue("단위"), TextCellValue("상대은행"), TextCellValue("은행적요(내용)"), TextCellValue("매칭사유(AI판단)"), TextCellValue("담당자 메모")]);

                  int totalCheckAmt = 0;
                  for (var r in checkList) {
                    totalCheckAmt += r.matchedAmount;
                    sheet4.appendRow([
                      TextCellValue(r.dong), TextCellValue(r.ho), TextCellValue(r.owner), TextCellValue(r.resident), TextCellValue(r.matchedDate.split(' ')[0]), IntCellValue(r.matchedAmount), TextCellValue("원"), TextCellValue(r.matchedBankName), TextCellValue(r.matchedBankText), TextCellValue(r.matchedField), TextCellValue(r.managerMemo)
                    ]);
                    int rIdx = sheet4.maxRows - 1;
                    sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rIdx)).cellStyle = moneyStyle; // 🌟 콤마 옷 입히기!
                    sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rIdx)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4'));
                  }
                  sheet4.appendRow([TextCellValue("")]);
                  sheet4.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액"), TextCellValue("단위")]);

                  sheet4.appendRow([TextCellValue("확인필요 총액"), TextCellValue("${checkList.length}건"), IntCellValue(totalCheckAmt), TextCellValue("원")]);
                  sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sheet4.maxRows - 1)).cellStyle = boldMoneyStyle;

                  int s4Max = sheet4.maxRows - 1;
                  sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: s4Max)).cellStyle = CellStyle(bold: true);
                  sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: s4Max)).cellStyle = CellStyle(bold: true);
                  sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: s4Max)).cellStyle = CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#FFFF9800'));

                  // ==========================================
                  // 5️⃣ 미확인 입금 내역 시트
                  // ==========================================
                  var sheet5 = excel["미확인입금"];
                  sheet5.appendRow([TextCellValue("거래일시"), TextCellValue("입금액"), TextCellValue("단위"), TextCellValue("적요(내용)"), TextCellValue("상대은행"), TextCellValue("담당자 메모")]);

                  int totalUnconfirmedAmt = 0;
                  for (var tx in unconfirmedList) {
                    totalUnconfirmedAmt += tx.amount;
                    sheet5.appendRow([
                      TextCellValue(tx.date), IntCellValue(tx.amount), TextCellValue("원"), TextCellValue(tx.description), TextCellValue(tx.bankName), TextCellValue(tx.managerMemo)
                    ]);
                    int rIdx = sheet5.maxRows - 1;
                    sheet5.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIdx)).cellStyle = moneyStyle; // 🌟 콤마 옷 입히기!
                    sheet5.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rIdx)).cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFFF9C4'));
                  }
                  sheet5.appendRow([TextCellValue("")]);
                  sheet5.appendRow([TextCellValue("요약"), TextCellValue("건수"), TextCellValue("금액"), TextCellValue("단위")]);

                  sheet5.appendRow([TextCellValue("미확인입금 총액"), TextCellValue("${unconfirmedList.length}건"), IntCellValue(totalUnconfirmedAmt), TextCellValue("원")]);
                  sheet5.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sheet5.maxRows - 1)).cellStyle = boldMoneyStyle;

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

                // 👇 🌟 [신규] 이중 팝업창 없이 그 자리에서 조용히 저장하고 닫히는 인라인 메모 엔진!
                void handleMemoSave(dynamic rowOrTx, String newText) {
                  if (newText != rowOrTx.managerMemo) {
                    // 시간 도장이 안 찍혀있고, 글씨를 새로 썼을 때만 타임스탬프 쾅!
                    if (newText.isNotEmpty && !newText.startsWith('[')) {
                      final now = DateTime.now();
                      newText = "[${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}] $newText";
                    }

                    setDialogState(() {
                      if (rowOrTx is ResidentRow && rowOrTx.matchedField.contains("일괄수납")) {
                        List<ResidentRow> group = _getMultiGroup(rowOrTx);
                        for(var r in group) r.managerMemo = newText;
                      } else {
                        rowOrTx.managerMemo = newText;
                      }
                    });
                    setState(() {});
                  }
                }

                Widget buildTabButton(String title, int tabIndex) {
                  bool isActive = popupMainTab == tabIndex;
                  return InkWell(
                    onTap: () => setDialogState(() => popupMainTab = tabIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: isActive ? Colors.blue[800] : Colors.grey[200], borderRadius: BorderRadius.circular(8), boxShadow: isActive ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : []),
                      child: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 13)),
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
                                    Text(
                                        popupMainTab == 0 ? "수납 전산처리 (일반매칭)" :
                                        popupMainTab == 1 ? "대행사 수납 확인 (자동/가상)" :
                                        popupMainTab == 2 ? "확인필요 내역 (수동검토)" :
                                        "미확인 입금 내역 (주인찾기)",
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                                    ),
                                  ]),
                                  Row(children: [
                                    buildTabButton("일반 수납", 0), const SizedBox(width: 6),
                                    buildTabButton("자동/가상", 1), const SizedBox(width: 6),
                                    buildTabButton("확인필요", 2), const SizedBox(width: 6),
                                    buildTabButton("미확인입금", 3),
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

                                          bool isGroup = false; bool isTop = false; bool isBottom = false;
                                          if (row.matchedField.contains("일괄수납") && row.matchedTx != null) {
                                            bool sameAsPrev = index > 0 && displayList[index - 1].matchedTx == row.matchedTx;
                                            bool sameAsNext = index < displayList.length - 1 && displayList[index + 1].matchedTx == row.matchedTx;
                                            isGroup = sameAsPrev || sameAsNext;
                                            isTop = isGroup && !sameAsPrev;
                                            isBottom = isGroup && !sameAsNext;
                                          }

                                          List<ResidentRow> targetGroup = isGroup ? displayList.where((r) => r.matchedTx == row.matchedTx).toList() : [row];
                                          bool isActive = _activeReceiptRow != null && targetGroup.contains(_activeReceiptRow);
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

                                          BorderSide greenBorder = BorderSide(color: Colors.green.shade600, width: 2.0);
                                          BorderSide defaultBorder = BorderSide(color: Colors.grey[200]!);

                                          return InkWell(
                                              onTap: () {
                                                setDialogState(() {
                                                  if (isActive) {
                                                    _processedReceipts.addAll(targetGroup);
                                                    _activeReceiptRow = null;
                                                  } else {
                                                    if (_activeReceiptRow != null) {
                                                      List<ResidentRow> prevGroup = _activeReceiptRow!.matchedField.contains("일괄수납") ? displayList.where((r) => r.matchedTx == _activeReceiptRow!.matchedTx).toList() : [_activeReceiptRow!];
                                                      _processedReceipts.addAll(prevGroup);
                                                    }
                                                    _activeReceiptRow = row;
                                                    targetGroup.forEach((r) => _processedReceipts.remove(r));
                                                  }
                                                });
                                              },
                                              child: Container(
                                                  decoration: BoxDecoration(color: bgColor, border: Border(top: isTop ? greenBorder : (isGroup ? BorderSide.none : defaultBorder), bottom: isBottom ? greenBorder : defaultBorder, left: isGroup ? greenBorder : BorderSide.none, right: isGroup ? greenBorder : BorderSide.none)),
                                                  padding: EdgeInsets.only(top: isTop || !isGroup ? 12 : 6, bottom: isBottom || !isGroup ? 12 : 6),
                                                  child: Row(children: [
                                                    Expanded(flex: 3, child: Stack(alignment: Alignment.center, children: [
                                                      if (isProcessed) Positioned(left: 2, child: InkWell(onTap: () { setDialogState(() { targetGroup.forEach((r) => _processedReceipts.remove(r)); }); }, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.withOpacity(0.3))), child: const Icon(Icons.close, size: 12, color: Colors.red)))),
                                                      Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: FittedBox(fit: BoxFit.scaleDown, child: Text(row.matchedDate.split(' ')[0], style: _rowStyle(Colors.black87)))),
                                                    ])),
                                                    (row.matchedField.contains("🔗") || row.matchedField.contains("[일괄수납 포함]")) ? _safeText("↪ 그룹포함", _rowStyle(Colors.grey, size: 12), 3) : _safeText("${_formatCurrency(row.matchedAmount)}원", _rowStyle(Colors.blue[800]!, isBold: true, size: 13), 3),
                                                    _safeText(row.dong, _rowStyle(Colors.black87, isBold: true), 2),
                                                    _safeText(row.ho, _rowStyle(Colors.black87, isBold: true), 2),
                                                    _safeText(matchedName, _rowStyle(Colors.teal[700]!, isBold: true), 3),
                                                    _safeText(row.matchedBankText, _rowStyle(Colors.black87), 5),
                                                    _safeText(row.matchedBankName, _rowStyle(Colors.grey), 3),
                                                    Expanded(flex: 4, child: PopupInlineMemoEditor(initialText: row.managerMemo, margin: const EdgeInsets.symmetric(horizontal: 4), onSaved: (val) { setDialogState(() { handleMemoSave(row, val); }); }))
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

                              ] else if (popupMainTab == 1) ...[
                                // ==========================================
                                // 🌟 [탭 1] 자동/가상 수납 내역
                                // ==========================================
                                Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                                      Expanded(flex: 3, child: Checkbox(value: displayBankList.isNotEmpty && checkedBankTxs.length == displayBankList.length, activeColor: Colors.indigo, onChanged: (val) { setDialogState(() { if (val == true) checkedBankTxs.addAll(displayBankList); else checkedBankTxs.clear(); }); })),
                                      const Expanded(flex: 5, child: Center(child: Text("동", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 6, child: Center(child: Text("호", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 10, child: Center(child: Text("거래일시", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      Expanded(flex: 12, child: Center(child: Text(popupSubTab == 0 ? "구분 (결제수단)" : "구분 (가상계좌)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 22, child: Center(child: Text("적요 (입금내역)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 10, child: Center(child: Text("입금액", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 10, child: Center(child: Text("상대은행", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 15, child: Center(child: Text("담당자 메모", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
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
                                                  decoration: BoxDecoration(color: checkedBankTxs.contains(tx) ? Colors.indigo.withOpacity(0.1) : (idx % 2 == 0 ? Colors.white : Colors.indigo.withOpacity(0.02)), border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                                                  child: Row(children: [
                                                    Expanded(flex: 3, child: Checkbox(value: checkedBankTxs.contains(tx), activeColor: Colors.indigo, onChanged: (val) { setDialogState(() { if (val == true) checkedBankTxs.add(tx); else checkedBankTxs.remove(tx); }); })),
                                                    Expanded(flex: 5, child: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 16), child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                                    Expanded(flex: 6, child: Container(alignment: Alignment.center, child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                                    Expanded(flex: 10, child: Container(alignment: Alignment.center, child: Text(tx.date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
                                                    Expanded(flex: 12, child: Container(alignment: Alignment.center, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: popupSubTab == 1 ? Colors.teal : Colors.indigo, borderRadius: BorderRadius.circular(4)), child: Text(popupSubTab == 1 ? "가상계좌" : "자동납부(PG)", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))))),
                                                    Expanded(flex: 22, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text(tx.description, style: TextStyle(color: popupSubTab == 1 ? Colors.teal[900] : Colors.indigo[900], fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis))),
                                                    Expanded(flex: 10, child: Container(alignment: Alignment.center, child: Text("${_formatCurrency(tx.amount)}원", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                                    Expanded(flex: 10, child: Container(alignment: Alignment.center, child: Text(tx.bankName.isEmpty ? "-" : tx.bankName, style: const TextStyle(color: Colors.grey, fontSize: 12)))),
                                                    Expanded(flex: 15, child: PopupInlineMemoEditor(initialText: tx.managerMemo, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), onSaved: (val) { setDialogState(() { handleMemoSave(tx, val); }); })),
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
                                        Text("☑️ 선택 항목 합계 (${checkedBankTxs.length}건)", style: TextStyle(fontSize: 13, color: Colors.indigo[500], fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text("${_formatCurrency(checkedTotalAmt)} 원", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo[600])),
                                        Container(margin: const EdgeInsets.symmetric(vertical: 6), width: 180, height: 1, color: Colors.indigo[200]),
                                        Text("전체 수납액 총합", style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text("${_formatCurrency(bankTotalAmt)} 원", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.indigo[900])),
                                      ])
                                    ])
                                ),
                              ] else if (popupMainTab == 2) ...[
                                // ==========================================
                                // 🌟 [탭 2] 확인필요 내역 (오렌지색)
                                // ==========================================
                                Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(color: Colors.orange[50], border: Border.all(color: Colors.orange[200]!), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                                    child: Row(children: [
                                      const Expanded(flex: 3, child: Center(child: Text("동", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 3, child: Center(child: Text("호", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 6, child: Center(child: Text("입금일자", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 6, child: Center(child: Text("입금액", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 12, child: Center(child: Text("은행적요(내용)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 12, child: Center(child: Text("AI 매칭 사유", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 8, child: Center(child: Text("담당자 메모", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    ])
                                ),
                                Expanded(
                                    child: Container(
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!)),
                                        child: ListView.builder(
                                            itemCount: checkList.length,
                                            itemBuilder: (ctx, idx) {
                                              var r = checkList[idx];
                                              return Container(
                                                  decoration: BoxDecoration(color: idx % 2 == 0 ? Colors.white : Colors.orange.withOpacity(0.02), border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                                                  child: Row(children: [
                                                    Expanded(flex: 3, child: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 12), child: Text(r.dong, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                                    Expanded(flex: 3, child: Container(alignment: Alignment.center, child: Text(r.ho, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                                    Expanded(flex: 6, child: Container(alignment: Alignment.center, child: Text(r.matchedDate.split(' ')[0], style: const TextStyle(fontSize: 13)))),
                                                    Expanded(flex: 6, child: Container(alignment: Alignment.center, child: Text("${_formatCurrency(r.matchedAmount)}원", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange[900])))),
                                                    Expanded(flex: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: Text(r.matchedBankText, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))),
                                                    Expanded(flex: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: Text(r.matchedField, style: TextStyle(fontSize: 11, color: Colors.orange[800], fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))),
                                                    Expanded(flex: 8, child: PopupInlineMemoEditor(initialText: r.managerMemo, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), onSaved: (val) { setDialogState(() { handleMemoSave(r, val); }); })),
                                                  ])
                                              );
                                            }
                                        )
                                    )
                                ),
                                Container(
                                    margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange[200]!)),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                      Text("확인필요 총 ${checkList.length}건", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange[900])),
                                      const SizedBox(width: 32),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        Text("확인필요 금액 총합", style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text("${_formatCurrency(checkList.fold(0, (sum, r) => sum + r.matchedAmount))} 원", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.orange[900])),
                                      ])
                                    ])
                                ),
                              ] else ...[
                                // ==========================================
                                // 🌟 [탭 3] 미확인 입금 내역 (빨간색)
                                // ==========================================
                                Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.red[200]!), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                                    child: Row(children: [
                                      const Expanded(flex: 6, child: Center(child: Text("입금일자", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 6, child: Center(child: Text("입금액", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 14, child: Center(child: Text("적요 (입금내역)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 8, child: Center(child: Text("상대은행", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      const Expanded(flex: 10, child: Center(child: Text("담당자 메모", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    ])
                                ),
                                Expanded(
                                    child: Container(
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!)),
                                        child: ListView.builder(
                                            itemCount: unconfirmedList.length,
                                            itemBuilder: (ctx, idx) {
                                              var tx = unconfirmedList[idx];
                                              return Container(
                                                  decoration: BoxDecoration(color: idx % 2 == 0 ? Colors.white : Colors.red.withOpacity(0.02), border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                                                  child: Row(children: [
                                                    Expanded(flex: 6, child: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 12), child: Text(tx.date, style: const TextStyle(fontSize: 13)))),
                                                    Expanded(flex: 6, child: Container(alignment: Alignment.center, child: Text("${_formatCurrency(tx.amount)}원", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red[900])))),
                                                    Expanded(flex: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: Text(tx.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))),
                                                    Expanded(flex: 8, child: Container(alignment: Alignment.center, child: Text(tx.bankName.isEmpty ? "-" : tx.bankName, style: const TextStyle(fontSize: 12, color: Colors.grey)))),
                                                    Expanded(flex: 10, child: PopupInlineMemoEditor(initialText: tx.managerMemo, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), onSaved: (val) { setDialogState(() { handleMemoSave(tx, val); }); })),
                                                  ])
                                              );
                                            }
                                        )
                                    )
                                ),
                                Container(
                                    margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                      Text("미확인 입금 총 ${unconfirmedList.length}건", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red[900])),
                                      const SizedBox(width: 32),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        Text("미확인 금액 총합", style: TextStyle(fontSize: 12, color: Colors.red[800], fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text("${_formatCurrency(unconfirmedList.fold(0, (sum, tx) => sum + tx.amount))} 원", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.red[900])),
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

      String originalDesc = tx.description;
      String normalizedDesc = "";
      for (int k = 0; k < originalDesc.length; k++) {
        int code = originalDesc.codeUnitAt(k);
        if (code >= 0xFF01 && code <= 0xFF5E) { normalizedDesc += String.fromCharCode(code - 0xFEE0); }
        else if (code == 0x3000) { normalizedDesc += " "; }
        else { normalizedDesc += String.fromCharCode(code); }
      }

      String descNoSpace = normalizedDesc.toLowerCase()
          .replaceAll(RegExp(r'[\s\u200B-\u200D\uFEFF\u00A0\u3000]'), '')
          .replaceAll(RegExp(r'[()\[\]<>{}_*?!]'), '');

      // 👇 🌟 [스마트 문맥 센서 1] 에이~지 + 숫자 (스카이702, 가우디702 완벽 보호)
      descNoSpace = descNoSpace.replaceAllMapped(RegExp(r'(?<![가-힣])(에이|비|씨|디|이|에프|지)(\d+)'), (match) {
        Map<String, String> pMap = {'에이': '1', '비': '2', '씨': '3', '디': '4', '이': '5', '에프': '6', '지': '7'};
        return '${pMap[match.group(1)!]}-${match.group(2)}';
      });

      // 👇 🌟 [스마트 문맥 센서 2] 에이~지 + 동 (이동환, 단비동 완벽 보호)
      descNoSpace = descNoSpace.replaceAllMapped(RegExp(r'(?<![가-힣])(에이|비|씨|디|이|에프|지)동(?![가-힣])'), (match) {
        Map<String, String> pMap = {'에이': '1', '비': '2', '씨': '3', '디': '4', '이': '5', '에프': '6', '지': '7'};
        return '${pMap[match.group(1)!]}동';
      });

      descNoSpace = descNoSpace.replaceAllMapped(RegExp(r'(\d+)지하'), (match) => 'b${match.group(1)}');
      descNoSpace = descNoSpace.replaceAll('지하', 'b');

      descNoSpace = descNoSpace.replaceAllMapped(
          RegExp(r'(^|[가-힣])([a-z])(동|단지|-|/|,|\.)'),
              (match) {
            String prefix = match.group(1) ?? '';
            String alpha = match.group(2) ?? '';
            String suffix = match.group(3) ?? '';
            int num = alpha.codeUnitAt(0) - 96;
            if (num > 0 && num <= 26) { return '$prefix$num$suffix'; }
            return match.group(0)!;
          }
      );

      String stopWordsPattern = r'(pg|자동|카드|결제|체크|페이|pay|토스|toss|나이스|nice|kcp|다날|danal|모빌리언스|카카오|kakao|네이버|비대면|펌뱅킹|입금|송금|cd|atm|이체|대체|스마트|인터넷|올원|뱅크|은행|nh|농협|국민|신한|우리|기업|하나|새마을|수협|신협|우체국|타행|창구|mb|pc|폰|e-|센터일괄|cm|관리비)';
      String cleanDescNoSpace = descNoSpace.replaceAll(RegExp(stopWordsPattern), '');

      cleanDescNoSpace = cleanDescNoSpace.replaceAll(RegExp(r'(거래|거래일|거래일자)[:\s]*\d{1,4}[-./]?\d{1,4}'), '');
      cleanDescNoSpace = cleanDescNoSpace.replaceAll(RegExp(r'\d+차'), '');
      cleanDescNoSpace = cleanDescNoSpace
          .replaceAll(RegExp(r'\d{4}[.\-/]\d{1,2}[.\-/]\d{1,2}'), '')
          .replaceAll(RegExp(r'010[.\-]?\d{3,4}[.\-]?\d{4}'), '')
          .replaceAll(RegExp(r'\d{9,11}'), '');
      cleanDescNoSpace = cleanDescNoSpace.replaceAll(RegExp(r'\d{1,2}월'), '').replaceAll(RegExp(r'\d분기'), '');

      // 👇 🌟 [양방향 투명 쐐기] 영어이름+숫자 (MIAYESU802) 또는 숫자+영어이름 (802MIAYESU) 완벽 분리!
      descNoSpace = descNoSpace.replaceAllMapped(RegExp(r'([a-z]{2,})(\d+)'), (m) => '${m.group(1)}_${m.group(2)}');
      cleanDescNoSpace = cleanDescNoSpace.replaceAllMapped(RegExp(r'([a-z]{2,})(\d+)'), (m) => '${m.group(1)}_${m.group(2)}');
      descNoSpace = descNoSpace.replaceAllMapped(RegExp(r'(\d+)([a-z]{2,})'), (m) => '${m.group(1)}_${m.group(2)}');
      cleanDescNoSpace = cleanDescNoSpace.replaceAllMapped(RegExp(r'(\d+)([a-z]{2,})'), (m) => '${m.group(1)}_${m.group(2)}');

      // =======================================================
      // 🌟 [하이브리드 판독기] 범위(201-206) vs 동호수(1-1701) vs 분할호수(1-1101-1) 방어
      // =======================================================
      bool isRangeForced = false;
      String rangeOriginalText = "";

      var hybridMatch = RegExp(r'(\d{1,4})[-~,](\d{1,4})').firstMatch(cleanDescNoSpace);
      if (hybridMatch != null) {
        String fullStr = hybridMatch.group(0)!;
        int sIdx = cleanDescNoSpace.indexOf(fullStr);
        int eIdx = sIdx + fullStr.length;

        bool hasPrev = sIdx > 0 && ['-', '~', ','].contains(cleanDescNoSpace[sIdx - 1]);
        bool hasNext = eIdx < cleanDescNoSpace.length && ['-', '~', ','].contains(cleanDescNoSpace[eIdx]);

        if (!hasPrev && !hasNext) {
          String num1Str = hybridMatch.group(1)!;
          String num2Str = hybridMatch.group(2)!;
          int n1 = int.tryParse(num1Str) ?? 0;
          int n2 = int.tryParse(num2Str) ?? 0;

          // 🌟 [완벽 공식 1] 101호 및 1층(0001) 증발 사건 완전 해결! 동/호수 절대 판별식
          // 1. 앞자리(동) 1~99 + 뒷자리(호) 100 이상 (예: 1-0101 -> 1동 101호)
          // 2. 앞자리 100 이상이어도 두 숫자 차이가 80 이상 (예: 101-201)
          // 3. 🌟 [추가] 뒷자리가 '0'으로 시작하면 1층(1-0001)이든 뭐든 묻지도 따지지도 않고 가상계좌로 프리패스!
          bool isObviousDongHo = (n1 > 0 && n1 < 100 && n2 >= 100) ||
              (n2 > n1 && (n2 - n1) >= 80) ||
              num2Str.startsWith('0');

          if (!isObviousDongHo) {
            // 🌟 [완벽 공식 2] 가상계좌의 '0101' 형태를 '101'로 변환 (Zero-Padding 파괴 안경)
            String pNum1 = n1.toString();
            String pNum2 = n2.toString();

            bool existsDirect = _residentList.any((r) {
              String cleanDbD = r.dong.replaceAll(RegExp(r'[^0-9]'),'');
              String cleanDbH = r.ho.replaceAll(RegExp(r'[^0-9]'),'');
              // 원본(0101)과 숫자변환본(101) 모두 매칭 허용!
              return (cleanDbD.isEmpty || cleanDbD == num1Str || cleanDbD == pNum1) &&
                  (cleanDbH.startsWith(num2Str) || cleanDbH.startsWith(pNum2));
            });

            bool existsSwapped = _residentList.any((r) {
              String cleanDbD = r.dong.replaceAll(RegExp(r'[^0-9]'),'');
              String cleanDbH = r.ho.replaceAll(RegExp(r'[^0-9]'),'');
              return (cleanDbD.isEmpty || cleanDbD == num2Str || cleanDbD == pNum2) &&
                  (cleanDbH.startsWith(num1Str) || cleanDbH.startsWith(pNum1));
            });

            if (!existsDirect && !existsSwapped) {
              isRangeForced = true;
              rangeOriginalText = "$num1Str-$num2Str";
              cleanDescNoSpace = cleanDescNoSpace.replaceFirst(fullStr, num1Str);
              descNoSpace = descNoSpace.replaceFirst(fullStr, num1Str);
            }
          }
        }
      }

      String exDong = ""; String exHo = "";
      bool hasExplicitPattern = false; bool hasExplicitHoOnly = false; bool isSwappedPossible = false;

      var cardForceMatch = RegExp(r'카드(\d+)-(\d+)').firstMatch(descNoSpace);
      if (cardForceMatch != null) {
        exDong = cardForceMatch.group(1)!; exHo = cardForceMatch.group(2)!; hasExplicitPattern = true;
      }

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

      List<String> rawNumbers = RegExp(r'[a-z0-9\-]*\d[a-z0-9\-]*').allMatches(cleanDescNoSpace).map((m) => m.group(0)!).toList();
      if (!hasExplicitPattern && !hasExplicitHoOnly) {
        if (rawNumbers.length >= 2) {
          exDong = rawNumbers[0]; exHo = rawNumbers[1];
          hasExplicitPattern = true; isSwappedPossible = true;
        }
      }

      ResidentRow? bestMatchRow;
      int highestScore = 0;
      String bestMatchReason = "";
      bool bestNeedsCheck = false;
      String bestMatchedNameStr = "";

      bool isSmartDongMatch(String dbDongStr, String bankDongStr, {bool allowMath = true}) {
        String cleanDb = dbDongStr.toLowerCase().trim(); String cleanBank = bankDongStr.toLowerCase().trim();
        if (RegExp(r'^0+\d+$').hasMatch(cleanBank)) cleanBank = int.parse(cleanBank).toString();
        if (RegExp(r'^0+\d+$').hasMatch(cleanDb)) cleanDb = int.parse(cleanDb).toString();
        if (cleanDb.isEmpty || cleanDb == cleanBank) return true;

        if (allowMath) {
          int? dbN = int.tryParse(cleanDb); int? bkN = int.tryParse(cleanBank);
          if (dbN != null && bkN != null) {
            if (dbN == bkN) return true;
            if (bkN > 0 && bkN < 100 && dbN >= 100 && (dbN % 100) == bkN) return true;
            if (dbN > 0 && dbN < 100 && bkN >= 100 && (bkN % 100) == dbN) return true;
            return false;
          }
        }
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

      bool isSmartHoMatch(String dbHoStr, String bankHoStr, String fullRawDesc) {
        if (dbHoStr.isEmpty || bankHoStr.isEmpty) return false;
        String cleanBankHo = bankHoStr.toLowerCase().trim(); String cleanDbHo = dbHoStr.toLowerCase().trim();
        if (cleanDbHo == cleanBankHo) return true;

        bool isBankNumeric = RegExp(r'^\d+$').hasMatch(cleanBankHo);
        bool isDbNumeric = RegExp(r'^\d+$').hasMatch(cleanDbHo);

        if (isBankNumeric && isDbNumeric) {
          int bN = int.tryParse(cleanBankHo) ?? 0; int dN = int.tryParse(cleanDbHo) ?? 0;
          if (bN == dN) return true;
        } else {
          if (cleanBankHo.startsWith("$cleanDbHo-")) return true;
          if (cleanDbHo.startsWith("$cleanBankHo-")) return true;
        }
        if (cleanBankHo.startsWith(cleanDbHo)) {
          String leftover = cleanBankHo.substring(cleanDbHo.length);
          int? monthVal = int.tryParse(leftover);
          if (monthVal != null && monthVal >= 1 && monthVal <= 12) {
            if (fullRawDesc.contains("${bankHoStr}월") || fullRawDesc.contains("${bankHoStr}분")) return true;
          }
          if (leftover != 'b' && RegExp(r'^[a-z]+$').hasMatch(leftover)) return true;
        }
        if (cleanBankHo.endsWith(cleanDbHo)) {
          String leftover = cleanBankHo.substring(0, cleanBankHo.length - cleanDbHo.length);
          if (leftover != 'b' && RegExp(r'^[a-z]+$').hasMatch(leftover)) return true;
        }
        if (cleanDbHo.contains('b') || cleanBankHo.contains('b')) {
          String bankNoHyphen = cleanBankHo.replaceAll(RegExp(r'[^a-z0-9]'), '');
          String dbNoHyphen = cleanDbHo.replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (bankNoHyphen == dbNoHyphen) return true;
        }
        if (!cleanDbHo.contains('b') && !cleanBankHo.contains('b') && cleanDbHo.contains('-')) {
          String dbNoHyphen = cleanDbHo.replaceAll(RegExp(r'[^0-9]'), '');
          String bankNoHyphen = cleanBankHo.replaceAll(RegExp(r'[^0-9]'), '');
          if (dbNoHyphen.isNotEmpty && bankNoHyphen.isNotEmpty && dbNoHyphen == bankNoHyphen) return true;
        }
        return false;
      }

      // 👇 🌟 [절대 보호법] 명부에 존재하는 찐 호수(원본 숫자)들을 스캔!
      Set<String> exactDbHos = _residentList.map((r) => r.ho.replaceAll(RegExp(r'[^0-9]'), '')).where((s) => s.isNotEmpty).toSet();

      for (var row in _residentList) {
        String cleanHo = row.ho.trim().toLowerCase().replaceAll(RegExp(r'\.0+$'), '').replaceAll('지하', 'b').replaceAll(RegExp(r'[^a-z0-9\-]'), '');
        String cleanDong = row.dong.trim().toLowerCase().replaceAll(RegExp(r'\.0+$'), '').replaceAll(RegExp(r'[^a-z0-9\-]'), '');
        if (cleanHo.isEmpty) continue;

        int currentScore = 0; List<String> hitReasons = [];
        bool isEmptyRecord = row.owner.trim().isEmpty && row.resident.trim().isEmpty && row.others.every((e) => e.trim() == "-" || e.trim().isEmpty) && row.remark.trim().isEmpty;
        String targetHoNum = int.tryParse(cleanHo)?.toString() ?? cleanHo;
        String targetDongNum = int.tryParse(cleanDong)?.toString() ?? cleanDong;

        bool isDongHoMatch = false; bool isHoMatch = false; bool isJoinedMatch = false; bool isStrongJoinedMatch = false;
        bool isPerfectHo = false; bool isSuperExactHo = false;

        if (hasExplicitPattern) {
          bool dongMatches = isSmartDongMatch(targetDongNum, exDong);
          bool hoMatches = isSmartHoMatch(targetHoNum, exHo, descNoSpace);
          if (dongMatches && hoMatches) {
            isDongHoMatch = true;
            if (targetHoNum == exHo.toLowerCase().trim()) isPerfectHo = true;
          } else if (exDong.isNotEmpty && exHo.isNotEmpty) {
            String joinedBank = (exDong + exHo).replaceAll(RegExp(r'[^a-z0-9]'), '');
            String joinedDb = (cleanDong + cleanHo).replaceAll(RegExp(r'[^a-z0-9]'), '');
            if (joinedBank == joinedDb && RegExp(r'[a-z]').hasMatch(joinedBank)) isDongHoMatch = true;
          } else if (isSwappedPossible) {
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
            if (targetHoNum == exHo.toLowerCase().trim()) { isPerfectHo = true; isSuperExactHo = true; }
          }
        } else {
          if (rawNumbers.length == 1) {
            String numStr = rawNumbers[0];
            String joinedTarget = cleanDong + cleanHo;
            String joinedTargetReverse = cleanHo + cleanDong;

            if (numStr == targetHoNum.toLowerCase().trim()) {
              isSuperExactHo = true;
            }
            else if (joinedTarget.isNotEmpty && numStr == joinedTarget) {
              // 🚨 [도둑질 방어 1] 102호가 1102호를 가져가려 할 때 차단!
              if (numStr != targetHoNum && exactDbHos.contains(numStr)) {
                // Do nothing (패스)
              } else {
                isDongHoMatch = true;
                if (numStr.startsWith(cleanDong) && targetHoNum == numStr.substring(cleanDong.length).toLowerCase().trim()) isPerfectHo = true;
              }
            } else if (joinedTargetReverse.isNotEmpty && numStr == joinedTargetReverse) {
              if (numStr != targetHoNum && exactDbHos.contains(numStr)) {
                // Do nothing
              } else {
                isDongHoMatch = true;
                if (numStr.endsWith(cleanDong) && targetHoNum == numStr.substring(0, numStr.length - cleanDong.length).toLowerCase().trim()) isPerfectHo = true;
              }
            } else if (isSmartHoMatch(targetHoNum, numStr, descNoSpace)) {
              isHoMatch = true;
              if (targetHoNum == numStr.toLowerCase().trim()) isPerfectHo = true;
            } else {
              var alphaMatch = RegExp(r'^([a-z])(\d+)$').firstMatch(numStr);
              if (alphaMatch != null) {
                int alphaDong = alphaMatch.group(1)!.codeUnitAt(0) - 96;
                String hoNum = alphaMatch.group(2)!;
                if (targetDongNum == alphaDong.toString() && targetHoNum == hoNum) { isDongHoMatch = true; isPerfectHo = true; }
              }
            }
            if (!isSuperExactHo && !isDongHoMatch && !isHoMatch) {
              if (joinedTarget.length >= 3 && numStr == joinedTarget) {
                if (!(numStr != targetHoNum && exactDbHos.contains(numStr))) {
                  isJoinedMatch = true; if (joinedTarget.length >= 5) isStrongJoinedMatch = true;
                }
              } else if (joinedTargetReverse.length >= 3 && numStr == joinedTargetReverse) {
                if (!(numStr != targetHoNum && exactDbHos.contains(numStr))) {
                  isJoinedMatch = true; if (joinedTargetReverse.length >= 5) isStrongJoinedMatch = true;
                }
              }
            }
          }
        }

        if (isSuperExactHo) { currentScore += 85; hitReasons.add("호수(완벽일치)"); }
        else if (isDongHoMatch) { currentScore += 60; if (isPerfectHo) { currentScore += 20; hitReasons.add("동호(완벽일치)"); } else hitReasons.add("동-호"); }
        else if (isHoMatch) { currentScore += 50; if (isPerfectHo) currentScore += 2; hitReasons.add("호수"); }
        else if (isJoinedMatch) { if (isStrongJoinedMatch) { currentScore += 40; hitReasons.add("동호완벽유추"); } else { currentScore += 20; hitReasons.add("동호단순유추"); } }

        bool exactNameHit = false; bool remarkNameHit = false; bool partialNameHit = false; bool typoNameHit = false; String matchedNameType = "";
        String safeDesc = cleanDescNoSpace.replaceAll(RegExp(r'\d+원'), '');
        String bankNameCandidate = safeDesc.replaceAll(RegExp(r'\d+[동호]?'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
        String currentMatchedNameStr = "";

        String pureBankName = bankNameCandidate.replaceAll(RegExp(r'타행|모바일|인터넷|스마트|이체|건별|대량|지점|자동|nh|농협|국민|신한|우리|기업|하나|새마을|수협|신협|우체국|올원|뱅크|은행|cd|atm|폰|페이|pay|mb|pc|e-|센터일괄|cm|관리비'), '');
        String bankNameSpace = tx.bankName.toLowerCase().replaceAll(RegExp(r'[^a-z가-힣]'), '');

        void checkName(String rawName, String type) {
          if (rawName.isEmpty || rawName == "-" || exactNameHit || remarkNameHit) return;
          bool isCorporation = RegExp(r'\(주\)|주식회사|\(유\)|\(사\)|\(재\)').hasMatch(rawName);
          String preProcessedName = rawName.replaceAll(RegExp(r'\(주\)|주식회사|\(유\)|\(사\)|\(재\)'), '');
          List<String> subNames = preProcessedName.split(RegExp(r'[,/.;|()\[\]]'));
          subNames.add(preProcessedName.replaceAll(RegExp(r'[()\[\]<>{}_*?!]'), ''));

          for (String sub in subNames) {
            String cleanName = sub.toLowerCase().replaceAll(RegExp(r'[^a-z가-힣]'), '');
            if (cleanName.isEmpty) continue;
            if (cleanName.length < 2) {
              if (isCorporation) { if (cleanName != pureBankName && !pureBankName.contains(cleanName)) continue; }
              else { if (cleanName != pureBankName && cleanName != bankNameCandidate) continue; }
            }
            bool isExact = false;
            if (cleanName == bankNameCandidate || cleanName == pureBankName || descNoSpace.contains(cleanName) || bankNameSpace.contains(cleanName)) isExact = true;
            else if (pureBankName.length >= 2 && pureBankName.contains(cleanName)) isExact = true;
            else if (bankNameSpace.length >= 2 && bankNameSpace.contains(cleanName)) isExact = true;
            else if (pureBankName.length >= 3 && cleanName.contains(pureBankName)) isExact = true;
            else if (bankNameSpace.length >= 3 && cleanName.contains(bankNameSpace)) isExact = true;
            else if (pureBankName.length == 2 && cleanName.length == 3 && (cleanName.endsWith('동') || cleanName.endsWith('호')) && cleanName.startsWith(pureBankName)) isExact = true;

            if (!isExact && RegExp(r'[a-z]').hasMatch(cleanName) && cleanName.length >= 4) {
              String dbPrefix = cleanName.substring(0, 4);
              if (pureBankName.length >= 4 && pureBankName.contains(dbPrefix)) { if (_calculateSimilarity(cleanName, pureBankName) >= 0.75) isExact = true; }
              else if (bankNameSpace.length >= 4 && bankNameSpace.contains(dbPrefix)) { if (_calculateSimilarity(cleanName, bankNameSpace) >= 0.75) isExact = true; }
            }

            if (isExact) {
              if (type == "비고") remarkNameHit = true; else exactNameHit = true;
              matchedNameType = type; currentMatchedNameStr = rawName; return;
            }

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

        // 🚨 [소유자 배제] 입주자, 기타인원, 비고만 검사
        if (!exactNameHit) checkName(row.resident, "입주자");
        if (exactNameHit || partialNameHit) {
          List<String> allNames = [row.resident, ...row.others].where((n) => n.trim().isNotEmpty && n != "-").toList();
          int matchedNameCount = 0;
          for (String name in allNames) {
            String cleanName = name.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
            if (cleanName.length < 2) continue;
            String superClean = (tx.description + tx.bankName).toLowerCase().replaceAll(RegExp(r'\s+'), '');
            if (superClean.contains(cleanName)) matchedNameCount++;
          }
          if (matchedNameCount >= 2) { currentScore += 20; hitReasons.add("가족/기타인원콤보(+20)"); }
        }
        if (!exactNameHit) { for (String other in row.others) checkName(other, "기타인원"); }
        if (!exactNameHit && !remarkNameHit) checkName(row.remark, "비고");

        if (!exactNameHit && !remarkNameHit) {
          String superCleanBankText = (tx.description + tx.bankName).replaceAll(RegExp(r'\s+'), '').toLowerCase();
          String descEngOnly = tx.description.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
          String bankNameEngOnly = tx.bankName.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();

          for (String name in [row.resident, row.remark]) {
            if (name.trim().isEmpty || name == "-") continue;
            String superCleanName = name.replaceAll(RegExp(r'\s+'), '').toLowerCase();
            String dbEngOnly = superCleanName.replaceAll(RegExp(r'[^a-z]'), '');
            bool isRescued = false;
            if (RegExp(r'[a-z]').hasMatch(superCleanName) && superCleanName.length >= 3 && superCleanBankText.contains(superCleanName)) { isRescued = true; }
            else if (dbEngOnly.length >= 4) {
              String dbPrefix = dbEngOnly.substring(0, 4);
              if (descEngOnly.length >= 4 && descEngOnly.contains(dbPrefix) && _calculateSimilarity(dbEngOnly, descEngOnly) >= 0.75) isRescued = true;
              else if (bankNameEngOnly.length >= 4 && bankNameEngOnly.contains(dbPrefix) && _calculateSimilarity(dbEngOnly, bankNameEngOnly) >= 0.75) isRescued = true;
            }
            if (isRescued) { exactNameHit = true; matchedNameType = "영문특수구출"; currentMatchedNameStr = name; break; }
          }
        }

        if (exactNameHit || remarkNameHit) { currentScore += 55; hitReasons.add(matchedNameType); }
        else if (partialNameHit) { currentScore += 40; hitReasons.add(matchedNameType); }
        else if (typoNameHit) { currentScore += 30; hitReasons.add(matchedNameType); }

        if (currentScore > 0 && isEmptyRecord) { currentScore -= 10; hitReasons.add("정보없음(-10)"); }

        if (!isSuperExactHo && !isDongHoMatch && !isHoMatch) {
          String superCleanBankTextForHo = (tx.description + tx.bankName).replaceAll(RegExp(r'\s+'), '').toLowerCase();
          String squashedDongHo = "${targetDongNum.toLowerCase().trim()}${targetHoNum.toLowerCase().trim()}";

          if (squashedDongHo.length >= 3 && superCleanBankTextForHo.contains(squashedDongHo)) {
            // 🚨 [도둑질 방어 2] 102호가 1102호를 우기려 할 때 완벽 차단!
            if (squashedDongHo != targetHoNum && exactDbHos.contains(squashedDongHo)) {
              // 방어 성공! 패스!
            } else {
              int idx = superCleanBankTextForHo.indexOf(squashedDongHo);
              bool isPartialNumber = false;
              if (idx > 0 && RegExp(r'\d').hasMatch(superCleanBankTextForHo[idx - 1])) isPartialNumber = true;

              if (idx + squashedDongHo.length < superCleanBankTextForHo.length) {
                String nextChar = superCleanBankTextForHo[idx + squashedDongHo.length];
                if (RegExp(r'\d').hasMatch(nextChar) || nextChar == '호') {
                  isPartialNumber = true;
                }
              }
              if (!isPartialNumber) { currentScore += 64; hitReasons.add("동호수붙여쓰기(+64)"); isSuperExactHo = true; isHoMatch = true; }
            }
          }
        }

        // 🌟 [수술 2] '101-110' 덩어리뿐만 아니라, 쪼개진 동(101)과 호(110)를 각각 검사해서 1108호 감점 철벽 방어!
        if (currentScore >= 20 && (rawNumbers.isNotEmpty || exDong.isNotEmpty || exHo.isNotEmpty)) {
          bool isNumberMatchAny = false;
          bool isTruncatedNumber = false;

          List<String> numsToCheck = [...rawNumbers];
          if (exDong.isNotEmpty) numsToCheck.add(exDong);
          if (exHo.isNotEmpty) numsToCheck.add(exHo);

          for (String numStr in numsToCheck) {
            if (numStr.isEmpty) continue;
            String cleanTargetHo = targetHoNum.toLowerCase().trim();
            String cleanTargetDong = targetDongNum.toLowerCase().trim();
            if (numStr == cleanTargetHo || numStr == cleanTargetDong) { isNumberMatchAny = true; break; }
            if (cleanTargetHo.startsWith(numStr) || cleanTargetDong.startsWith(numStr)) { isTruncatedNumber = true; }
          }
          if (!isNumberMatchAny && !isHoMatch && !isSuperExactHo && !isDongHoMatch) {
            if (isTruncatedNumber && (exactNameHit || remarkNameHit)) {
              hitReasons.add("번호잘림의심(감점면제)");
            } else {
              currentScore -= 45; hitReasons.add("타세대번호기재감점(-45)");
            }
          }
        }

        if (currentScore > highestScore) {
          highestScore = currentScore;
          bestMatchRow = row;
          // 🚨 [소유자 배제] 이름 대타(Fallback)에서 소유자 삭제
          bestMatchedNameStr = currentMatchedNameStr.isNotEmpty ? currentMatchedNameStr : row.resident;

          if (currentScore >= 40) {
            bool hasDongHoMatch = isSuperExactHo || isDongHoMatch || isHoMatch || isStrongJoinedMatch;
            bool hasNameMatch = exactNameHit || remarkNameHit;
            bool hasDongHoInfo = hasExplicitPattern || hasExplicitHoOnly;
            bool isDongHoWrong = hasDongHoInfo && !hasDongHoMatch;
            if (isDongHoWrong && hasNameMatch) { bestNeedsCheck = true; bestMatchReason = "확인필요(동호수불일치+${hitReasons.join("+")})"; }
            else if (hasDongHoMatch || hasNameMatch) { bestNeedsCheck = false; bestMatchReason = hitReasons.join("+"); }
            else { bestNeedsCheck = true; bestMatchReason = "확인필요(${hitReasons.join("+")})"; }
          } else { bestNeedsCheck = true; bestMatchReason = "확인필요(${hitReasons.join("+")})"; }
        }
      }

      // 👇 🌟 [201호 스마트 검사] 동(Dong)과 이름 없이 호수(201)만 맞췄을 때의 다중동 안전망 (옵션 B)
      if (bestMatchRow != null &&
          (bestMatchReason.contains("호수") || hasExplicitHoOnly) &&
          !bestMatchReason.contains("동-호") &&
          !bestMatchReason.contains("동호") &&
          !bestMatchReason.contains("동호수붙여쓰기")) {

        String cleanMatchedHo = bestMatchRow!.ho.trim().toLowerCase().replaceAll(RegExp(r'\.0+$'), '').replaceAll('지하', 'b').replaceAll(RegExp(r'[^a-z0-9\-]'), '');

        int sameHoCount = _residentList.where((r) {
          String cleanR = r.ho.trim().toLowerCase().replaceAll(RegExp(r'\.0+$'), '').replaceAll('지하', 'b').replaceAll(RegExp(r'[^a-z0-9\-]'), '');
          return cleanR == cleanMatchedHo;
        }).length;

        if (sameHoCount >= 2) {
          bool hasNameMatch = bestMatchReason.contains("입주자") || bestMatchReason.contains("기타인원") || bestMatchReason.contains("비고") || bestMatchReason.contains("영문특수구출") || bestMatchReason.contains("가족");
          if (!hasNameMatch) {
            bestNeedsCheck = true;
            bestMatchReason = "확인필요(동미확인-${sameHoCount}개동에 ${bestMatchRow!.ho} 존재)";
          }
        }
      }

      // ======================================================
      // 🌟 [최종 판정소] 단독 매칭 & 완벽이름 탈환 & 동명이인
      // ======================================================
      if (bestMatchRow != null) {
        bool isDongHoDictator = bestMatchReason.contains("동호(완벽일치)") ||
            bestMatchReason.contains("동-호") ||
            bestMatchReason.contains("호수(완벽일치)") ||
            bestMatchReason.contains("동호수붙여쓰기");

        if (isDongHoDictator) {
          bestNeedsCheck = false;
          if (isRangeForced) {
            bestNeedsCheck = true;
            bestMatchReason = "확인필요(범위입금:$rangeOriginalText➔$bestMatchReason)";
          }
        } else {
          String descForCheck = tx.description.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
          String pureDesc = descForCheck.replaceAll(RegExp(r'타행|모바일|인터넷|스마트|이체|건별|대량|지점|자동|nh|농협|국민|신한|우리|기업|하나|새마을|수협|신협|우체국|올원|뱅크|은행|cd|atm|폰|페이|pay|mb|pc|e-|센터일괄|cm|관리비'), '');

          String bankForCheck = tx.bankName.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
          String pureBank = bankForCheck.replaceAll(RegExp(r'주식회사|\(주\)|\(유\)|\(사\)|타행|모바일|인터넷|스마트|이체|건별|대량|지점|자동|nh|농협|국민|신한|우리|기업|하나|새마을|수협|신협|우체국|올원|뱅크|은행|cd|atm|폰|페이|pay|mb|pc|e-|센터일괄|cm|관리비'), '');

          String current1stName = bestMatchedNameStr.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');

          bool isCurrentPerfect = false;
          if (current1stName.isNotEmpty) {
            if (current1stName == descForCheck || current1stName == pureDesc ||
                (bankForCheck.isNotEmpty && current1stName == bankForCheck) ||
                (pureBank.isNotEmpty && current1stName == pureBank)) {
              isCurrentPerfect = true;
            }
          }

          if (!isCurrentPerfect) {
            ResidentRow? perfectNameCandidate;
            String perfectName = "";

            for (var r in _residentList) {
              if (r == bestMatchRow) continue;
              // 🚨 [소유자 배제]
              List<String> namesToCheck = [r.resident, r.remark, ...r.others];

              for (String name in namesToCheck) {
                if (name.trim().isEmpty || name == "-") continue;
                String cleanName = name.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
                if (cleanName.length < 2) continue;

                if (cleanName == descForCheck || cleanName == pureDesc ||
                    (cleanName.isNotEmpty && (cleanName == bankForCheck || cleanName == pureBank))) {
                  perfectNameCandidate = r;
                  perfectName = name;
                  break;
                }
              }
              if (perfectNameCandidate != null) break;
            }

            if (perfectNameCandidate != null) {
              bestMatchRow = perfectNameCandidate;
              highestScore = highestScore + 30;
              bestNeedsCheck = false;
              bestMatchReason = "완벽이름우선탈환(${bestMatchReason})";
              bestMatchedNameStr = perfectName;
            }
          }

          if (bestMatchRow != null) {
            String cleanBestName = bestMatchedNameStr.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
            if (cleanBestName.length >= 2) {
              int exactNameCount = _residentList.where((r) {
                // 🚨 [소유자 배제]
                List<String> names = [r.resident, ...r.others, r.remark];
                return names.any((name) {
                  String cn = name.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
                  return cn == cleanBestName;
                });
              }).length;

              if (exactNameCount >= 2) {
                bestNeedsCheck = true;
                bestMatchReason = "확인필요(동명이인${exactNameCount}명-$bestMatchReason)";
              }
            }
          }
        }
      }

      if (bestMatchRow != null && bestMatchReason.contains("번호잘림의심")) {
        bestNeedsCheck = true;
        if (!bestMatchReason.contains("확인필요")) {
          bestMatchReason = "확인필요($bestMatchReason)";
        }
      }

      if (highestScore >= 30 && bestMatchRow != null) {
        ResidentRow targetRow = bestMatchRow;
        if (targetRow.isMatched) {
          bool isSpecialTx = targetRow.matchedTx != null && (_isAutoPaymentTx(targetRow.matchedTx!) || _isVirtualAccountTx(targetRow.matchedTx!));
          if (!isSpecialTx && !targetRow.matchedField.contains("⚠️중복입금")) {
            targetRow.matchedField = "⚠️중복입금의심 / ${targetRow.matchedField}";
            targetRow.isCheckRequired = true;
          }
          ResidentRow cloneRow = targetRow.copy();
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

        bool isSpecialMatch = tx.txType == '수동PG' || tx.txType == '수동가상' || _isAutoPaymentTx(tx) || _isVirtualAccountTx(tx);
        bool isDuplicate = !isSpecialMatch && (
            bestMatchReason.contains("⚠️중복입금") ||
                _residentList.where((r) => r.dong == targetRow.dong && r.ho == targetRow.ho && r.isMatched && r != targetRow).isNotEmpty);

        if (isDuplicate) {
          targetRow.matchedField = "⚠️중복입금의심 / $bestMatchReason(${highestScore}점)";
          targetRow.isCheckRequired = true;
        } else {
          targetRow.matchedField = "$bestMatchReason(${highestScore}점)";
        }

        targetRow.matchedTx = tx;
        tx.isUsed = true;
      }
    }
    setState(() => _isProcessing = false);
    _showSnackBar("AI 스코어링 엔진 매칭 완료!");
  }

  // 🌟 [신규] 다중호실 그룹 탐색 도우미 (운명 공동체 찾기)
  List<ResidentRow> _getMultiGroup(ResidentRow row) {
    String multiName = "";
    if (row.matchedField.contains("다중호실") || row.matchedField.contains("일괄수납")) {
      multiName = row.matchedName.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
    } else {
      for (var r in _residentList) {
        if (r.matchedField.contains("다중호실") || r.matchedField.contains("일괄수납")) {
          String mn = r.matchedName.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
          List<String> names = [row.owner, row.resident, ...row.others, row.remark];
          if (names.any((n) {
            String cn = n.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
            if (cn.length < 2) return false;
            return cn == mn || cn.contains(mn) || (mn.contains(cn) && cn.length >= 3) ||
                (cn.length >= 4 && mn.length >= 4 && _calculateSimilarity(cn, mn) >= 0.72);
          })) {
            multiName = mn;
            break;
          }
        }
      }
    }

    if (multiName.isEmpty || multiName.length < 2) return [row];

    List<ResidentRow> group = [];
    for (var r in _residentList) {
      if (r.isMultiGroupExcluded) continue;
      List<String> names = [r.owner, r.resident, ...r.others, r.remark];
      bool match = names.any((n) {
        String cn = n.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
        if (cn.length < 2) return false;
        return cn == multiName || cn.contains(multiName) || (multiName.contains(cn) && cn.length >= 3) ||
            (cn.length >= 4 && multiName.length >= 4 && _calculateSimilarity(cn, multiName) >= 0.72);
      });
      if (match) group.add(r);
    }

    group.sort((a, b) {
      if (a.matchedTx != null && b.matchedTx == null) return -1;
      if (a.matchedTx == null && b.matchedTx != null) return 1;
      int dCmp = a.dong.compareTo(b.dong);
      if (dCmp != 0) return dCmp;
      return a.ho.compareTo(b.ho);
    });

    return group;
  }

  // 🌟 [업데이트] 실무자 수동 개입 (다중 묶음 폐지, 철저한 1:1 단독 제어 + 중복입금 클론 삭제)
  void _changeStatus(ResidentRow row, String newStatus) {
    setState(() {
      if (newStatus == "매칭완료" || newStatus == "확인필요") {
        row.isMatched = true;
        row.isCheckRequired = (newStatus == "확인필요");
        if (row.matchedTx != null && (row.matchedTx!.txType == '수동PG' || row.matchedTx!.txType == '수동가상')) {
          row.matchedTx!.txType = "";
        }
        if (!row.matchedField.contains("[수동확정]") && newStatus == "매칭완료") {
          row.matchedField = "${row.matchedField} [수동확정]";
        }
        _showSnackBar(newStatus == "매칭완료" ? "${row.dong}동 ${row.ho}호 매칭완료 처리되었습니다." : "${row.dong}동 ${row.ho}호 확인필요 처리되었습니다.");
      } else if (newStatus == "수동PG" || newStatus == "수동가상") {
        row.isMatched = true;
        row.isCheckRequired = false;
        row.matchedField = "[수동이동] 대행사 수납";
        if (row.matchedTx != null) row.matchedTx!.txType = newStatus;
        _showSnackBar(newStatus == "수동PG" ? "자동이체(PG) 탭으로 이동되었습니다." : "가상계좌 탭으로 이동되었습니다.");
      } else if (newStatus == "매칭대기") {
        if (row.matchedTx != null) row.matchedTx!.isUsed = false; // 🌟 돈을 미확인으로 반환!
        row.matchedTx = null;
        row.isMatched = false;
        row.isCheckRequired = false;
        row.matchedAmount = 0;
        row.matchedBankText = "";
        row.matchedBankName = "";
        row.matchedDate = "";
        row.matchedMemo = "";
        row.matchedField = "";

        // 🌟 중복입금 때문에 복제되었던 껍데기(클론) 행이었다면 아예 삭제해 버림!
        int sameDongHoCount = _residentList.where((r) => r.dong == row.dong && r.ho == row.ho).length;
        if (sameDongHoCount > 1) {
          _residentList.remove(row);
        }
        _showSnackBar("매칭이 취소되어 미확인 입금 탭으로 이동되었습니다.", isError: true);
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

  // =======================================================
  // 🌟 [최종 고도화] 미확인 입금 수동 매칭 시 '스마트 데이터 보존 엔진' 작동!
  // =======================================================
  void _manualMatchFromBank(BankTx tx, {bool isCheckRequired = false}) {
    if (tx.inputDong.trim().isEmpty || tx.inputHo.trim().isEmpty) {
      _showSnackBar("동과 호수를 필수로 입력해주세요.", isError: true);
      return;
    }

    setState(() {
      String targetDong = tx.inputDong.trim();
      String targetHo = tx.inputHo.trim();

      ResidentRow? existingRow;
      try { existingRow = _residentList.firstWhere((r) => r.dong == targetDong && r.ho == targetHo); } catch (e) {}

      ResidentRow newRow;
      if (existingRow != null) {
        // 🌟 [핵심] 기존 정보가 있으면 절대 덮어쓰지 않고, 남는 방(기타, 메모)으로 안전하게 대피시킵니다!
        newRow = existingRow;

        // 🛠️ 도우미 엔진: 남는 기타 인원 칸을 찾아서 대리납부자 이름을 쏙 넣어줍니다.
        void safelyAddOther(String name) {
          if (name.isEmpty) return;
          if (newRow.owner == name || newRow.resident == name || newRow.others.contains(name)) return; // 이미 있으면 패스
          for (int i = 0; i < newRow.others.length; i++) {
            if (newRow.others[i] == "-" || newRow.others[i].trim().isEmpty) {
              newRow.others[i] = name;
              return;
            }
          }
          // 기타 칸 4개가 다 찼다면 마지막 수단으로 메모장으로 보냅니다.
          String timeStamp = "[${DateTime.now().month}/${DateTime.now().day}]";
          newRow.managerMemo = newRow.managerMemo.isEmpty ? "$timeStamp 대리입금자: $name" : "${newRow.managerMemo}\n$timeStamp 대리입금자: $name";
        }

        // 1. 소유자 보호 로직 (🌟 trim() 검사 추가)
        String inOwner = tx.inputOwner.trim();
        if (inOwner.isNotEmpty) {
          if (newRow.owner.trim().isEmpty || newRow.owner == "-") newRow.owner = inOwner;
          else if (newRow.owner != inOwner) safelyAddOther(inOwner);
        }

        // 2. 입주자 보호 로직 (🌟 trim() 검사 추가)
        String inResident = tx.inputResident.trim();
        if (inResident.isNotEmpty) {
          if (newRow.resident.trim().isEmpty || newRow.resident == "-") newRow.resident = inResident;
          else if (newRow.resident != inResident) safelyAddOther(inResident);
        }

        // 3. 기타 인원 추가 로직
        String inOthers = tx.inputOthers.trim();
        if (inOthers.isNotEmpty) safelyAddOther(inOthers);

        // 4. 구분(타입) 채우기 (🌟 trim() 검사 추가)
        String inType = tx.inputType.trim();
        if (inType.isNotEmpty) {
          if (newRow.type.trim().isEmpty || newRow.type == "-") newRow.type = inType;
        }

        // 5. 비고(Remark) 보호 로직 (🌟 trim() 검사 추가)
        String inRemark = tx.inputRemark.trim();
        if (inRemark.isNotEmpty) {
          if (newRow.remark.trim().isEmpty || newRow.remark == "-") {
            newRow.remark = inRemark;
          } else if (newRow.remark != inRemark) {
            String timeStamp = "[${DateTime.now().month}/${DateTime.now().day}]";
            newRow.managerMemo = newRow.managerMemo.isEmpty ? "$timeStamp 추가비고: $inRemark" : "${newRow.managerMemo}\n$timeStamp 추가비고: $inRemark";
          }
        }
      } else {
        // 🌟 아예 명부에 없던 신규 세대면 깔끔하게 새로 생성
        newRow = ResidentRow(
          dong: targetDong, ho: targetHo, owner: tx.inputOwner.trim(), resident: tx.inputResident.trim(),
          others: [tx.inputOthers.trim().isEmpty ? "-" : tx.inputOthers.trim(), "-", "-", "-"], type: tx.inputType.trim(), remark: tx.inputRemark.trim(),
        );
        int insertIdx = _residentList.length;
        for (int j = 0; j < _residentList.length; j++) {
          if (_residentList[j].dong == newRow.dong) { insertIdx = j; break; }
        }
        _residentList.insert(insertIdx, newRow);
      }

      // 👇 🌟 최종 수납 매칭 확정
      newRow.isMatched = true;
      newRow.isCheckRequired = isCheckRequired;
      newRow.matchedBankText = tx.description;
      newRow.matchedAmount = tx.amount;
      newRow.matchedBankName = tx.bankName;
      newRow.matchedDate = tx.date;
      newRow.matchedMemo = tx.memo;

      // 🌟 [치명적 누락 해결] 수동 일반매칭/확인필요 시 txType을 리셋하여 남색 탭(가상/자동)에 유령처럼 나타나는 것을 방지!
      if (tx.txType != '수동PG' && tx.txType != '수동가상') {
        tx.txType = "";
      }

      newRow.matchedTx = tx;

      // 만약 미확인 탭에서 메모까지 입력해서 보냈다면? 기존 메모와 안전하게 합체!
      if (tx.managerMemo.isNotEmpty) {
        if (!newRow.managerMemo.contains(tx.managerMemo)) {
          newRow.managerMemo = newRow.managerMemo.isEmpty ? tx.managerMemo : "${newRow.managerMemo}\n${tx.managerMemo}";
        }
      }

      newRow.isMultiGroupExcluded = false;
      newRow.matchedField = isCheckRequired ? "수동등록 (미확인➔확인필요)" : "수동등록 (미확인➔매칭완료)";

      tx.isUsed = true; // 돈 사용 완료 처리
    });

    _showSnackBar("${tx.inputDong}동 ${tx.inputHo}호 이동 및 명부 매칭이 완료되었습니다.");
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

        // 🌟 [최종 고도화] AI 분석 결과 '열' 전체 데이터 통합 검색 엔진
        if (_aiSearch.isNotEmpty) {
          // 사용자가 입력한 검색어 (소문자 변환 + 콤마 제거로 금액 검색 대응)
          String search = _aiSearch.toLowerCase().replaceAll(',', '');

          // 🧐 이 칸에 표시되는 모든 데이터를 하나의 '검색용 텍스트'로 합체!
          String combinedText = (
              r.matchedDate +              // 1. 날짜 (2024.03.19)
                  r.matchedBankText +          // 2. 은행 적요 (아파트관리비...)
                  r.matchedAmount.toString() + // 3. 금액 (50000)
                  r.matchedField +             // 4. AI 판정 근거 (이름일치...)
                  r.matchedName                // 5. AI가 최종 매칭한 이름
          ).toLowerCase().replaceAll(',', ''); // 검색 대상에서도 콤마 제거

          // 합쳐진 전체 텍스트 중에 검색어가 하나라도 없으면 이 행은 탈락!
          if (!combinedText.contains(search)) continue;
        }

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

    // ==============================================================
    // 🌟 [최종 고도화] 다중호실 시각화 정렬 (생존자 뭉치기 + 제외자 하단 강등)
    // ==============================================================
    List<dynamic> clusteredList = [];
    Set<dynamic> processedItems = {};

    // 1. 전체 리스트에서 다중호실 그룹 이름(키워드)들을 전부 수집
    Set<String> allMultiNames = {};
    for (var r in _residentList) {
      if (r.matchedField.contains("다중호실") || r.matchedField.contains("일괄수납")) {
        allMultiNames.add(r.matchedName.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), ''));
      }
    }

    for (var item in displayList) {
      if (processedItems.contains(item)) continue;

      if (item is ResidentRow && allMultiNames.isNotEmpty) {
        String myName = "";
        List<String> names = [item.owner, item.resident, ...item.others, item.remark];
        for (String name in names) {
          String cn = name.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
          if (cn.length < 2) continue;
          for (String mn in allMultiNames) {
            if (cn == mn || cn.contains(mn) || (mn.contains(cn) && cn.length >= 3) ||
                (cn.length >= 4 && mn.length >= 4 && _calculateSimilarity(cn, mn) >= 0.72)) {
              myName = mn; break;
            }
          }
          if (myName.isNotEmpty) break;
        }

        // 가족(그룹)을 찾았다면, 화면에 있는 내 가족들을 다 불러모읍니다!
        if (myName.isNotEmpty) {
          List<ResidentRow> family = [];
          for (var other in displayList) {
            if (other is ResidentRow && !processedItems.contains(other)) {
              List<String> oNames = [other.owner, other.resident, ...other.others, other.remark];
              bool isFamily = oNames.any((n) {
                String cn = n.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
                if (cn.length < 2) return false;
                return cn == myName || cn.contains(myName) || (myName.contains(cn) && cn.length >= 3) ||
                    (cn.length >= 4 && myName.length >= 4 && _calculateSimilarity(cn, myName) >= 0.72);
              });

              // 🌟 제외되어 이름이 지워졌더라도, 숨겨둔 돈(TX) 끈으로 가족 확인!
              if (!isFamily && item.matchedTx != null && other.matchedTx == item.matchedTx) isFamily = true;

              if (isFamily) family.add(other);
            }
          }

          if (family.length > 1) {
            // 🌟 정렬 1순위: 생존자(false) 위로, 제외자(true) 아래로
            // 🌟 정렬 2순위: 동/호수 오름차순 (복귀 시 제자리 찾기)
            family.sort((a, b) {
              if (a.isMultiGroupExcluded != b.isMultiGroupExcluded) {
                return a.isMultiGroupExcluded ? 1 : -1;
              }
              int dongA = int.tryParse(a.dong.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              int dongB = int.tryParse(b.dong.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              if (dongA != dongB) return dongA.compareTo(dongB);

              int hoA = int.tryParse(a.ho.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              int hoB = int.tryParse(b.ho.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return hoA.compareTo(hoB);
            });

            clusteredList.addAll(family);
            processedItems.addAll(family);
            continue;
          }
        }
      }
      clusteredList.add(item);
      processedItems.add(item);
    }
    displayList = clusteredList; // 🌟 완벽하게 재배치된 리스트로 덮어쓰기!

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
                          _headerCell("동", 5), _headerCell("호", 5), _sortableDateHeader(10),
                          _headerCell(_receiptSubTab == 0 ? "구분 (결제수단)" : "구분 (가상계좌)", 10),
                          _headerCell("적요 (입금내역)", 20), _headerCell("입금액", 9),
                          _headerCell("상대은행", 9),
                          _headerCell("상태(보내기)", 11), // 🌟 신규 추가된 헤더 공간
                          _headerCell("담당자 메모", 16)
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
                  // 🌟 기존: 동+호 같은 행 그룹
                  bool sameAsPrev = index > 0 &&
                      displayList[index - 1] is ResidentRow &&
                      (displayList[index - 1] as ResidentRow).dong == item.dong &&
                      (displayList[index - 1] as ResidentRow).ho == item.ho;
                  bool sameAsNext = index < displayList.length - 1 &&
                      displayList[index + 1] is ResidentRow &&
                      (displayList[index + 1] as ResidentRow).dong == item.dong &&
                      (displayList[index + 1] as ResidentRow).ho == item.ho;
                  isGroup = sameAsPrev || sameAsNext;
                  isTop = isGroup && !sameAsPrev;
                  isBottom = isGroup && !sameAsNext;

                  // 🌟 [신규] 다중호실일괄입금 그룹
                  // 같은 이름이 다중호실 매칭된 TX와 연결된 경우 모두 묶음 (복수 입금자 완벽 지원)
                  if (!isGroup) {
                    // 🚨 수정: 다중호실 감지된 모든 이름을 Set에 담아 복수 입금자를 지원합니다!
                    Set<String> multiNames = {};
                    for (var r in _residentList) {
                      // 👇 🌟 [핵심] 매칭완료 후 부여되는 "일괄수납" 글자도 같이 찾아야 그룹이 안 풀립니다!
                      if (r.matchedField.contains("다중호실") || r.matchedField.contains("일괄수납")) {
                        multiNames.add(r.matchedName.toLowerCase()
                            .replaceAll(RegExp(r'\s+'), '')
                            .replaceAll(RegExp(r'[^a-z가-힣]'), ''));
                      }
                    }

                    bool isMultiRoomRow = false;
                    String matchedMultiName = "";
                    if (multiNames.isNotEmpty) {
                      List<String> names = [item.owner, item.resident, ...item.others, item.remark];
                      for (String name in names) {
                        String cn = name.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
                        if (cn.length < 2) continue;

                        for (String mName in multiNames) {
                          if (cn == mName || cn.contains(mName) || (mName.contains(cn) && cn.length >= 3) ||
                              (cn.length >= 4 && mName.length >= 4 && _calculateSimilarity(cn, mName) >= 0.72)) {
                            isMultiRoomRow = true;
                            matchedMultiName = mName; // 어떤 다중 그룹에 속하는지 기억
                            break;
                          }
                        }
                        if (isMultiRoomRow) break;
                      }
                    }

                    // 🌟 제외된 행이면 그룹 참여 안함!
                    if (isMultiRoomRow && !item.isMultiGroupExcluded) {
                      bool checkSameGroup(ResidentRow targetRow) {
                        if (targetRow.isMultiGroupExcluded) return false;
                        List<String> tNames = [targetRow.owner, targetRow.resident, ...targetRow.others, targetRow.remark];
                        return tNames.any((name) {
                          String cn = name.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
                          if (cn.length < 2) return false;
                          return cn == matchedMultiName || cn.contains(matchedMultiName) || (matchedMultiName.contains(cn) && cn.length >= 3) ||
                              (cn.length >= 4 && matchedMultiName.length >= 4 && _calculateSimilarity(cn, matchedMultiName) >= 0.72);
                        });
                      }

                      bool multiSameAsPrev = index > 0 && displayList[index - 1] is ResidentRow && checkSameGroup(displayList[index - 1] as ResidentRow);
                      bool multiSameAsNext = index < displayList.length - 1 && displayList[index + 1] is ResidentRow && checkSameGroup(displayList[index + 1] as ResidentRow);

                      isGroup = multiSameAsPrev || multiSameAsNext;
                      isTop = isGroup && !multiSameAsPrev;
                      isBottom = isGroup && !multiSameAsNext;
                    }
                  }
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
    // 🌟 [신규] 같은 이름이 다중호실 그룹에 속하는지 확인 (복수 입금자 지원)
    Set<String> multiGroupNames = {};
    for (var r in _residentList) {
      // 👇 🌟 [핵심] 여기도 "일괄수납"을 추가해야 초록 테두리가 유지됩니다!
      if (r.matchedField.contains("다중호실") || r.matchedField.contains("일괄수납")) {
        multiGroupNames.add(r.matchedName.toLowerCase()
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll(RegExp(r'[^a-z가-힣]'), ''));
      }
    }

    bool isMultiRoom = false;
    if (multiGroupNames.isNotEmpty) {
      List<String> myNames = [row.owner, row.resident, ...row.others, row.remark];
      for (String name in myNames) {
        String cn = name.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^a-z가-힣]'), '');
        if (cn.length < 2) continue;
        for (String mName in multiGroupNames) {
          if (cn == mName || cn.contains(mName) || (mName.contains(cn) && cn.length >= 3) ||
              (cn.length >= 4 && mName.length >= 4 && _calculateSimilarity(cn, mName) >= 0.72)) {
            isMultiRoom = true;
            break;
          }
        }
        if (isMultiRoom) break;
      }
    }

    // 👇 🌟 [신규] 매칭 전엔 주황색 선, 매칭 완료 후엔 초록색 선으로 묶음!
    BorderSide thickGreen = (isMultiRoom && !row.isMatched)
        ? BorderSide(color: Colors.orange.shade700, width: 2.5)
        : BorderSide(color: Colors.green.shade800, width: 2.5);
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
              onChanged: (v) { setState(() { onChanged(v); }); },
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
        color: row.isMultiGroupExcluded
            ? Colors.grey.withOpacity(0.08)
            : (isMultiRoom
            ? (row.isCheckRequired ? Colors.yellow.withOpacity(0.15) : Colors.green.withOpacity(0.08)) // 👇 🌟 매칭완료 시 초록색 연하게 변경!
            : (row.isCheckRequired
            ? Colors.orange.withOpacity(0.12)
            : (row.isMatched ? Colors.green.withOpacity(0.08) : Colors.transparent))),
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
            // 🌟 [신규] 다중호실 그룹 행이면 매칭여부 상관없이 dropdown 표시!
            child: (row.isMatched || row.isCheckRequired || isMultiRoom) ? Builder(
                builder: (context) {
                  // 🌟 [다이어트] 매칭대기면 글씨만 보여줌
                  if (!row.isMatched && !row.isCheckRequired) {
                    return Container(
                        alignment: Alignment.center,
                        child: const Text("매칭 대기중", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))
                    );
                  }

                  // 🌟 자동이체/가상계좌 여부 확인
                  bool isAuto = row.matchedTx != null && _isAutoPaymentTx(row.matchedTx!);
                  bool isVBank = row.matchedTx != null && _isVirtualAccountTx(row.matchedTx!);

                  // 🌟 자동이체/가상계좌 → 드롭다운으로 보내기 가능
                  if (isAuto || isVBank) {
                    return Container(
                      height: 26,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isVBank ? Colors.teal[50] : Colors.indigo[50],
                        border: Border.all(
                            color: isVBank ? Colors.teal[300]! : Colors.indigo[300]!
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: isVBank ? "수동가상" : "수동PG",
                          icon: Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: isVBank ? Colors.teal[800] : Colors.indigo[800],
                          ),
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isVBank ? Colors.teal[800] : Colors.indigo[800],
                          ),
                          items: const [
                            DropdownMenuItem(value: "수동PG",
                                child: Text("자동이체", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: "수동가상",
                                child: Text("가상계좌", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: "매칭완료",
                                child: Text("일반매칭으로", style: TextStyle(color: Colors.green))),
                            DropdownMenuItem(value: "확인필요",
                                child: Text("확인필요로", style: TextStyle(color: Colors.orange))),
                            DropdownMenuItem(value: "매칭대기",
                                child: Text("매칭취소", style: TextStyle(color: Colors.red))),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            if (val == "수동PG" || val == "수동가상") {
                              // 🌟 자동이체 ↔ 가상계좌 전환
                              setState(() {
                                if (row.matchedTx != null) {
                                  row.matchedTx!.txType = val;
                                }
                              });
                              _showSnackBar(val == "수동PG"
                                  ? "자동이체 탭으로 변경되었습니다."
                                  : "가상계좌 탭으로 변경되었습니다.");
                            } else {
                              // 🌟 일반매칭/확인필요/취소로 보내기
                              _changeStatus(row, val == "매칭취소" ? "매칭대기" : val);
                              if (val == "매칭완료" || val == "확인필요") {
                                // 일반으로 보낼 때 txType 초기화
                                if (row.matchedTx != null) {
                                  row.matchedTx!.txType = "수동일반";
                                }
                                _showSnackBar(val == "매칭완료"
                                    ? "일반 매칭완료로 이동되었습니다."
                                    : "확인필요로 이동되었습니다.");
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }

                  // 🌟 일반 매칭은 기존 드롭다운 그대로
                  return Container(
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
                    DropdownMenuItem(value: "수동PG", child: Text("자동이체(PG)로", style: TextStyle(color: Colors.indigo))),
                    DropdownMenuItem(value: "수동가상", child: Text("가상계좌로", style: TextStyle(color: Colors.teal))),
                    DropdownMenuItem(value: "매칭대기", child: Text("매칭 취소", style: TextStyle(color: Colors.red))),
                  ],
                        onChanged: (val) { if (val != null) _changeStatus(row, val == "매칭 취소" ? "매칭대기" : val); },
                      ),
                    ),
                  );
                }
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
                                color: row.matchedField.contains("다중호실")
                                    ? Colors.orange[800]
                                    : (row.matchedField.contains("수동")
                                    ? Colors.blue[800]
                                    : Colors.grey),
                                fontSize: 9,
                                fontWeight: (row.matchedField.contains("수동") ||
                                    row.matchedField.contains("다중호실"))
                                    ? FontWeight.bold
                                    : FontWeight.normal
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),

                        // 🌟 [신규] 일괄수납 및 다중호실 직관적 UI 뱃지
                        if (row.matchedField.contains("[일괄수납 대표]"))
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue[50], border: Border.all(color: Colors.blue[300]!), borderRadius: BorderRadius.circular(4)),
                            child: Text("👑 일괄수납 묶음완료", style: TextStyle(fontSize: 10, color: Colors.blue[900], fontWeight: FontWeight.bold)),
                          )
                        else if (row.matchedField.contains("🔗"))
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey[100], border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                            child: Text("🔗 일괄수납 포함", style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                          )
                        else if (row.matchedField.contains("다중호실일괄입금"))
                            Builder(
                                builder: (context) {
                                  // 🌟 긴 텍스트에서 우리가 만든 '1동 103호, 104호' 부분만 쏙 빼서 예쁘게 출력!
                                  String roomsInfo = "다중호실 일괄입금 확인필요";
                                  var match = RegExp(r'다중호실일괄입금-([^\/]+)').firstMatch(row.matchedField);
                                  if (match != null) {
                                    roomsInfo = "${match.group(1)} 다중입금 감지";
                                  }
                                  return Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.orange[50], border: Border.all(color: Colors.orange[300]!), borderRadius: BorderRadius.circular(3)),
                                    child: Text(
                                      "⚠️ $roomsInfo",
                                      style: TextStyle(fontSize: 9, color: Colors.orange[900], fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }
                            ),
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

    // =======================================================
    // 🌟 [최종 고도화] 소유자 자동 스캔 레이더 (다주택자 완벽 지원!)
    // =======================================================
    bool isOwnerRegistered = false;
    String matchedOwnerInfo = "";
    String cleanBankText = (tx.description + tx.bankName).replaceAll(RegExp(r'\s+'), '');

    List<String> ownedUnits = []; // 🌟 소유한 모든 호수를 담을 바구니

    for (var r in _residentList) {
      if (r.owner.trim().isEmpty || r.owner == "-") continue;
      String cleanOwner = r.owner.replaceAll(RegExp(r'\s+'), '');

      // 이름이 2글자 이상이고, 은행 내역에 소유자 이름이 포함되어 있다면?
      if (cleanOwner.length >= 2 && cleanBankText.contains(cleanOwner)) {
        ownedUnits.add("${r.dong}동 ${r.ho}호"); // 찾을 때마다 바구니에 담습니다!
      }
    }

    // 바구니에 담긴 데이터가 있다면 뱃지 생성!
    if (ownedUnits.isNotEmpty) {
      isOwnerRegistered = true;
      if (ownedUnits.length == 1) {
        matchedOwnerInfo = ownedUnits.first; // 1채면 그냥 보여줌
      } else {
        // 🌟 여러 채를 가지고 있다면 "ㅇㅇ동 ㅇㅇ호 외 N세대" 형태로 깔끔하게 축약!
        matchedOwnerInfo = "${ownedUnits.first} 외 ${ownedUnits.length - 1}세대";
      }
    }
    // =======================================================

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      // 👇 🌟 [핵심] 여러 줄의 타세대를 입력할 수 있도록 Column으로 감쌉니다!
      child: Column(
        children: [
          Row(
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
                      value: "미확인", icon: const Icon(Icons.arrow_drop_down, size: 16), isExpanded: true,
                      style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: "미확인", child: Text("미확인", style: TextStyle(color: Colors.red))),
                        DropdownMenuItem(value: "확인필요", child: Text("확인필요(보내기)", style: TextStyle(color: Colors.orange))),
                        DropdownMenuItem(value: "매칭완료", child: Text("매칭완료(보내기)", style: TextStyle(color: Colors.green))),
                        DropdownMenuItem(value: "수동PG", child: Text("자동이체(PG)로", style: TextStyle(color: Colors.indigo))),
                        DropdownMenuItem(value: "수동가상", child: Text("가상계좌로", style: TextStyle(color: Colors.teal))),
                      ],
                      onChanged: (val) {
                        if (val == "매칭완료") _manualMatchFromBank(tx, isCheckRequired: false);
                        else if (val == "확인필요") _manualMatchFromBank(tx, isCheckRequired: true);
                        else if (val == "수동PG" || val == "수동가상") {
                          setState(() {
                            tx.txType = val!;
                            if (tx.inputDong.trim().isNotEmpty && tx.inputHo.trim().isNotEmpty) _manualMatchFromBank(tx, isCheckRequired: false);
                          });
                          _showSnackBar(val == "수동PG" ? "자동이체(PG) 탭으로 이동되었습니다." : "가상계좌 탭으로 이동되었습니다.");
                        }
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
                      Text("❌ ${tx.description} / ${_formatCurrency(tx.amount)}원", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
                      if (isOwnerRegistered)
                        Container(margin: const EdgeInsets.only(top: 3), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue[50], border: Border.all(color: Colors.blue[200]!), borderRadius: BorderRadius.circular(4)), child: Text("💡 (소유자 등록 : $matchedOwnerInfo)", style: TextStyle(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))
                    ],
                  ),
                ),
              ),

              Expanded(flex: 12, child: const SizedBox()) // 메모 부분 생략(공간 유지)
            ],
          ),
        ],
      ),
    );
  }

  // =======================================================
  // 🌟 [수정] "수납 확인" 전용 UI (가상계좌 시 동/호 렌더링 지원 및 상태보내기 추가)
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
          Expanded(flex: 5, child: Container(alignment: Alignment.center, child: Text(dong, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)))),
          Expanded(flex: 5, child: Container(alignment: Alignment.center, child: Text(ho, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)))),

          Expanded(flex: 10, child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4), alignment: Alignment.center, child: Text(tx.date, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)))),
          Expanded(flex: 10, child: Container(alignment: Alignment.center, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isVBank ? Colors.teal : Colors.indigo, borderRadius: BorderRadius.circular(4)), child: Text(isVBank ? "가상계좌" : "자동납부(PG)", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))))),
          Expanded(flex: 20, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text(tx.description, textAlign: TextAlign.center, style: TextStyle(color: isVBank ? Colors.teal[900] : Colors.indigo[900], fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis))),
          Expanded(flex: 9, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text("${_formatCurrency(tx.amount)}원", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)))),
          Expanded(flex: 9, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text(tx.bankName.isEmpty ? "-" : tx.bankName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)))),

          // 👇 🌟 신규: 상태(보내기) 드롭다운 (양방향 데이터 컨트롤)
          Expanded(
            flex: 11,
            child: Container(
              height: 26, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue[300]!), borderRadius: BorderRadius.circular(4)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: isVBank ? "수동가상" : "수동PG",
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  isExpanded: true,
                  style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: "수동PG", child: Text("자동이체로", style: TextStyle(color: Colors.indigo))),
                    DropdownMenuItem(value: "수동가상", child: Text("가상계좌로", style: TextStyle(color: Colors.teal))),
                    DropdownMenuItem(value: "수동일반", child: Text("일반 매칭으로", style: TextStyle(color: Colors.green))),
                    DropdownMenuItem(value: "수동미확인", child: Text("미확인으로", style: TextStyle(color: Colors.red))),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      if (val == "수동PG" || val == "수동가상") {
                        tx.txType = val;
                        _showSnackBar(val == "수동PG" ? "자동이체(PG)로 변경되었습니다." : "가상계좌로 변경되었습니다.");
                      } else if (val == "수동일반") {
                        // 💡 일반 매칭으로 던질 때는 동/호수가 연결되어 있는지 검사!
                        if (tx.isUsed) {
                          tx.txType = "수동일반";
                          try {
                            var matchedRow = _residentList.firstWhere((r) => r.matchedTx == tx);
                            matchedRow.isCheckRequired = false;
                            matchedRow.matchedField = "[수동이동] 일반 수납확정";
                          } catch(e) {}
                          _showSnackBar("일반 매칭완료 탭으로 이동되었습니다.");
                        } else {
                          // 동호수가 없으면 일반 매칭을 할 수 없으므로 빨간 탭(미확인)으로 던짐
                          tx.txType = "수동미확인";
                          _showSnackBar("매칭된 세대가 없어 미확인 탭으로 이동합니다.", isError: true);
                        }
                      } else if (val == "수동미확인") {
                        tx.txType = "수동미확인";
                        if (tx.isUsed) {
                          try {
                            var matchedRow = _residentList.firstWhere((r) => r.matchedTx == tx);
                            matchedRow.isMatched = false;
                            matchedRow.matchedTx = null;
                            tx.isUsed = false;
                          } catch(e) {}
                        }
                        _showSnackBar("미확인 입금 탭으로 이동되었습니다.");
                      }
                    });
                  },
                ),
              ),
            ),
          ),

          Expanded(flex: 16, child: InkWell(
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

  // 🌟 [수정] 모든 검색창에 '한 번에 지우기(X)' 버튼을 장착합니다.
  Widget _searchHeaderCell(String title, int flex, TextEditingController ctrl, Function(String) onChanged) {
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Container(
            margin: const EdgeInsets.only(top: 4, left: 6, right: 6),
            height: 28,
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: "검색",
                prefixIcon: const Icon(Icons.search, size: 12),

                // 🎯 [핵심] 글자가 있을 때만 오른쪽에 X 버튼을 띄웁니다.
                suffixIcon: ctrl.text.isNotEmpty
                    ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.cancel, size: 14, color: Colors.grey),
                  onPressed: () {
                    ctrl.clear(); // 1. 입력창 글자 지우기
                    onChanged(""); // 2. 검색어 변수 초기화 및 화면 새로고침
                  },
                )
                    : null,

                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
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
    if (tx.txType == '수동가상') return true;
    // 🌟 일반/미확인으로 수동 이동된 데이터는 가상계좌에서 즉시 방출!
    if (tx.txType == '수동PG' || tx.txType == '수동일반' || tx.txType == '수동미확인') return false;

    String desc = tx.description.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    String type = tx.txType.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    String cms = tx.cmsCode.replaceAll(RegExp(r'[^0-9]'), '');

    if (type.contains('가상') || type.contains('제휴')) return true;
    if (desc.contains('가상') || desc.contains('제휴')) return true;
    if (desc.contains('아파트아이')) return true;
    if (RegExp(r'(거래|거래일|거래일자)[:\s]*\d{1,4}[-./]?\d{1,4}').hasMatch(desc)) return true;
    if (cms.length >= 9) return true;

    return false;
  }

  // 🗂️ [자동이체 식별기] (스마트 분리망 적용)
  bool _isAutoPaymentTx(BankTx tx) {
    if (tx.txType == '수동PG') return true;
    // 🌟 일반/미확인으로 수동 이동된 데이터는 PG에서 즉시 방출!
    if (tx.txType == '수동가상' || tx.txType == '수동일반' || tx.txType == '수동미확인') return false;

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
    // 🌟 단, pg/자동이체/결제 키워드가 같이 있으면 대행사이므로 통과!
    bool hasPgKeyword = cleanDesc.contains('pg') ||
        cleanDesc.contains('자동이체') ||
        cleanDesc.contains('펌뱅킹') ||
        cleanDesc.contains('센터일괄');

    if (!hasPgKeyword) {
      if (cleanDesc.contains('카카오페이') ||
          cleanDesc.contains('토스') ||
          cleanDesc.contains('toss') ||
          cleanDesc.contains('네이버페이')) {
        return false;
      }
    }

    // 1️⃣ [확실한 대행사 키워드]
    List<String> strongPgKeywords = [
      '이지스', '엔터프라이즈', 'pg', '나이스', 'nice', 'kcp', '다날', 'danal',
      '모빌리언스', '펌뱅킹', '센터일괄', '한강아이린관리', '세틀뱅크', '효성fms',
      '아파트관리비', '자동이체', '월분관리비'
    ];
    for (String k in strongPgKeywords) {
      if (cleanDesc.contains(k)) return true;
    }

    // 2️⃣ [카드결제 특수 패턴]
    if (RegExp(r'카드\d+-\d+').hasMatch(cleanDesc)) {
      return true;
    }

    // 3️⃣ [조건부 키워드]
    if (cleanDesc.contains('자동') || cleanDesc.contains('결제') || cleanDesc.contains('카드')) {
      if (!RegExp(r'\d').hasMatch(cleanDesc)) return true;
    }

    // 4️⃣ [관리비 전용 텍스트 필터 + 🌟 송금자명(상대은행) 핀셋 방어 로직]
    if (cleanDesc.contains('아파트관리') || cleanDesc.contains('관리비')) {
      if (!RegExp(r'\d').hasMatch(cleanDesc)) { // 숫자가 없는 경우 (대행사 의심)
        String bankNameLower = tx.bankName.toLowerCase().replaceAll(RegExp(r'\s+'), '');

        if (RegExp(r'주식회사|\(주\)|\(유\)|\(사\)|페이|pay|정산|엔터프라이즈|관리|센터|이체|kcp|nice|나이스|다날|danal|모빌리언스|세틀뱅크|효성|fms|pg|결제').hasMatch(bankNameLower)) {
          return true;
        }

        if (RegExp(r'^[가-힣a-z]+$').hasMatch(bankNameLower)) {
          return false; // 🟢 사람으로 인정!
        }
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
// 🌟 [고도화] Tab키와 Enter키 만으로 다음 칸으로 초고속 점프하는 터보 엔진 장착!
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
  late FocusNode _focusNode; // 실제 입력 시 포커스
  late FocusNode _readModeFocusNode; // 🌟 [신규] 탭(Tab) 키 감지용 투명 레이더

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focusNode = FocusNode();
    _readModeFocusNode = FocusNode();

    // 1. 입력 모드에서 바깥을 클릭하면 저장
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        setState(() {
          _isEditing = false;
          widget.onChanged(_controller.text);
        });
      }
    });

    // 2. 🌟 [신규] 읽기 모드일 때 사용자가 Tab 키를 눌러 이 칸으로 넘어오면 즉시 입력 모드로 변신!
    _readModeFocusNode.addListener(() {
      if (_readModeFocusNode.hasFocus && !_isEditing) {
        setState(() => _isEditing = true);
        WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
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
    _readModeFocusNode.dispose(); // 메모리 청소
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.next, // 🌟 [신규] 키보드에 '다음' 버튼(또는 엔터) 활성화
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
          // 🌟 [신규] 엔터를 치면 즉시 저장하고, 빛의 속도로 '다음 칸'으로 커서 이동!
          setState(() {
            _isEditing = false;
            widget.onChanged(v);
          });
          FocusScope.of(context).nextFocus();
        },
      );
    }

    // [읽기 모드] 가벼운 렌더링
    return Focus(
      focusNode: _readModeFocusNode, // 🌟 [신규] 탭(Tab) 키를 감지하는 센서 부착
      child: InkWell(
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
      ),
    );
  }
}

// =======================================================
// 🌟 [UI/UX 혁신] 팝업창 전용 '트랜스포머 인라인 메모장'
// 클릭하면 무제한으로 쭉 늘어나 줄바꿈(엔터)이 가능하고,
// 작성 후 바깥을 클릭하면 깔끔하게 축소되며 ... 으로 처리되는 마법의 위젯!
// =======================================================
class PopupInlineMemoEditor extends StatefulWidget {
  final String initialText;
  final Function(String) onSaved;
  final EdgeInsetsGeometry margin;

  const PopupInlineMemoEditor({
    super.key,
    required this.initialText,
    required this.onSaved,
    this.margin = const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
  });

  @override
  State<PopupInlineMemoEditor> createState() => _PopupInlineMemoEditorState();
}

class _PopupInlineMemoEditorState extends State<PopupInlineMemoEditor> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      // 포커스를 잃으면(바탕을 클릭하면) 자동으로 저장 모드 발동
      if (!_focusNode.hasFocus && _isEditing) {
        _saveAndClose();
      }
    });
  }

  @override
  void didUpdateWidget(PopupInlineMemoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText && !_isEditing) {
      _controller.text = widget.initialText;
    }
  }

  void _saveAndClose() {
    setState(() {
      _isEditing = false;
      widget.onSaved(_controller.text.trim());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEmpty = _controller.text.isEmpty && !_isEditing;
    Color bgColor = isEmpty ? Colors.white : Colors.yellow[100]!;
    Color borderColor = isEmpty ? Colors.grey[300]! : Colors.yellow[400]!;

    if (_isEditing) {
      // 🌟 [작성 모드] 고무줄처럼 아래로 제한 없이 쭉쭉 늘어나는 무제한 텍스트 필드!
      return Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue[400]!, width: 2.0),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 6)],
        ),
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null, // 🔥 핵심: 줄바꿈(엔터) 무제한 허용!
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          decoration: const InputDecoration(
            hintText: "메모 입력 (엔터로 줄바꿈)",
            hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
            contentPadding: EdgeInsets.all(8),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      );
    }

    // 🌟 [열람 모드] 평소에는 얌전하게 제자리를 지키며, 길면 ... 처리
    return ExcludeFocus( // 👇 🌟 [핵심] Tab 키를 쳐서 이동할 때 이 메모칸은 100% 무시하고 건너뜁니다! (오직 마우스 클릭만 허용)
      child: InkWell(
        onTap: () {
          setState(() => _isEditing = true);
          // 클릭 즉시 키보드 포커스 활성화
          WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
        },
        child: Container(
          margin: widget.margin,
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isEmpty ? "+ 메모입력" : _controller.text,
            style: TextStyle(
              fontSize: 11,
              color: isEmpty ? Colors.grey : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // 평소엔 2줄까지만 보여주고
            overflow: TextOverflow.ellipsis, // 넘치면 ... 처리!
          ),
        ),
      ),
    );
  }
}
