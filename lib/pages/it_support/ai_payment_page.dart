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

// --- 데이터 모델 ---
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
    this.matchedDate = "", this.matchedMemo = "", this.matchedTx, this.managerMemo = "",
    this.isMerged = false,
  });

  ResidentRow copy() {
    var r = ResidentRow(
      dong: dong, ho: ho, owner: owner, resident: resident,
      others: List.from(others), type: type, remark: remark,
      isMatched: isMatched, isCheckRequired: isCheckRequired,
      matchedBankText: matchedBankText, matchedField: matchedField,
      matchedAmount: matchedAmount, matchedBankName: matchedBankName,
      matchedDate: matchedDate, matchedMemo: matchedMemo,
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
    this.bankName = "", this.date = "", this.memo = ""
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
  // 🛡️ [궁극의 파서] 엑셀/CSV/HTML 완벽 해독
  // =======================================================
  List<List<String>> _getRowsFromBytes(String ext, List<int> bytes) {
    List<List<String>> rows = [];
    bool isParsedAsExcel = false;

    if (ext.contains('xls') || ext.contains('xlsx')) {
      try {
        var excel = Excel.decodeBytes(bytes);
        if (excel.tables.isNotEmpty) {
          var firstSheetName = excel.tables.keys.first;
          var table = excel.tables[firstSheetName]!;

          for (var row in table.rows) {
            List<String> rowStrings = [];
            for (var cell in row) {
              if (cell == null || cell.value == null) {
                rowStrings.add("");
              } else {
                String txt = cell.value.toString();
                txt = txt.replaceAll(RegExp(r'[A-Za-z]+CellValue\('), '');
                if (txt.endsWith(')')) txt = txt.substring(0, txt.length - 1);
                rowStrings.add(txt.trim().replaceAll('\u{200B}', ''));
              }
            }
            if (rowStrings.any((e) => e.isNotEmpty)) rows.add(rowStrings);
          }
        }
        if (rows.isNotEmpty) isParsedAsExcel = true;
      } catch (e) {
        debugPrint("Excel 파싱 실패: $e");
      }
    }

    if (!isParsedAsExcel) {
      String rawString = "";
      try { rawString = utf8.decode(bytes); }
      catch(e) {
        try { rawString = cp949.decode(bytes); }
        catch(e2) { rawString = utf8.decode(bytes, allowMalformed: true); }
      }

      if (rawString.contains("<table") || rawString.contains("<TABLE")) {
        rawString = rawString.replaceAll(RegExp(r'</tr>', caseSensitive: false), '\n');
        rawString = rawString.replaceAll(RegExp(r'</t[dh]>', caseSensitive: false), ',');
        rawString = rawString.replaceAll(RegExp(r'<[^>]+>'), '');

        List<String> lines = rawString.split(RegExp(r'\r\n|\n'));
        for (String line in lines) {
          if (line.trim().isEmpty) continue;
          rows.add(line.split(',').map((e) => e.trim()).toList());
        }
      } else {
        List<String> currentRow = [];
        String currentCell = "";
        bool inQuotes = false;

        for (int i = 0; i < rawString.length; i++) {
          String char = rawString[i];
          if (char == '"') {
            if (i + 1 < rawString.length && rawString[i + 1] == '"') {
              currentCell += '"'; i++;
            } else {
              inQuotes = !inQuotes;
            }
          } else if (char == ',' && !inQuotes) {
            currentRow.add(currentCell.trim()); currentCell = "";
          } else if ((char == '\n' || char == '\r') && !inQuotes) {
            if (char == '\r' && i + 1 < rawString.length && rawString[i + 1] == '\n') i++;
            currentRow.add(currentCell.trim());
            if (currentRow.any((element) => element.isNotEmpty)) rows.add(currentRow);
            currentRow = []; currentCell = "";
          } else {
            currentCell += char;
          }
        }
        if (currentRow.isNotEmpty || currentCell.isNotEmpty) {
          currentRow.add(currentCell.trim()); rows.add(currentRow);
        }
      }
    }
    return rows;
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
  // 🛡️ [은행 로더] (적요 vs 내용 가로채기 완벽 방어)
  // =======================================================
  Future<void> _loadBankExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx', 'xls', 'csv'], withData: true,
      );
      if (result == null) return;

      String ext = result.files.single.extension?.toLowerCase() ?? '';
      final bytes = result.files.single.bytes;
      if (bytes == null) throw Exception("데이터를 읽을 수 없습니다.");

      List<List<String>> rawRows = _getRowsFromBytes(ext, bytes);
      if (rawRows.isEmpty) throw Exception("데이터 추출에 실패했습니다.");

      int descIdx = -1, amtIdx = -1, bankIdx = -1, dateIdx = -1, memoIdx = -1;
      int dataStartRow = -1;
      int currentDescPriority = -1;

      for (int i = 0; i < min(30, rawRows.length); i++) {
        for (int j = 0; j < rawRows[i].length; j++) {
          String val = rawRows[i][j].replaceAll(' ', '');
          if (val.contains("출금") || val.contains("잔액")) continue;

          int priority = -1;
          if (val == "내용" || val == "거래내용" || val == "기재내용" || val == "입금자명" || val == "보내신분" || val == "맡기신분") {
            priority = 2;
          } else if (val == "적요" || val == "성명" || val == "입금인") {
            priority = 1;
          }

          if (priority > currentDescPriority) {
            descIdx = j;
            currentDescPriority = priority;
          }

          if (amtIdx == -1 && (val == "입금액" || val == "입금" || val == "거래금액" || val == "수납금액")) amtIdx = j;
          if (bankIdx == -1 && (val.contains("거래점명") || val.contains("상대은행"))) bankIdx = j;
          if (dateIdx == -1 && (val.contains("거래일시") || val.contains("거래일자") || val == "일시" || val == "날짜")) dateIdx = j;
          if (memoIdx == -1 && val == "메모") memoIdx = j;
        }

        if (descIdx != -1) {
          dataStartRow = i + 1;
          break;
        }
      }

      if (descIdx == -1) throw Exception("은행 파일에서 '내용' 열을 찾을 수 없습니다.");
      if (dataStartRow >= rawRows.length) throw Exception("실제 입금 데이터가 없습니다.");

      List<BankTx> tempBankList = [];

      for (int i = dataStartRow; i < rawRows.length; i++) {
        var row = rawRows[i];
        String desc = _getSafe(row, descIdx);
        if (desc.isEmpty) continue;

        int amt = 0;
        if (amtIdx != -1) {
          String amtStr = _getSafe(row, amtIdx).replaceAll(RegExp(r'[^0-9]'), '');
          amt = int.tryParse(amtStr) ?? 0;
        }

        String bank = bankIdx != -1 ? _getSafe(row, bankIdx) : "";
        String date = dateIdx != -1 ? _getSafe(row, dateIdx) : "";
        String memo = memoIdx != -1 ? _getSafe(row, memoIdx) : "";

        tempBankList.add(BankTx(description: desc, amount: amt, bankName: bank, date: date, memo: memo));
      }

      setState(() { _bankList = tempBankList; _isBankLoaded = true; });
      _showSnackBar("은행 입금내역 ${tempBankList.length}건 로드 완료!");
    } catch (e) {
      _showNoticePopup("은행 파일 오류", "$e");
    }
  }

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

      String descNoSpace = normalizedDesc.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      String stopWordsPattern = r'(카드|토스|toss|카카오|kakao|비대면|펌뱅킹|입금|송금|페이|pay|결제|kcp|nice)';
      String cleanDescNoSpace = descNoSpace.replaceAll(RegExp(stopWordsPattern), '');

      cleanDescNoSpace = cleanDescNoSpace
          .replaceAll(RegExp(r'\d{4}[.\-/]\d{1,2}[.\-/]\d{1,2}'), '')
          .replaceAll(RegExp(r'010[.\-]?\d{3,4}[.\-]?\d{4}'), '')
          .replaceAll(RegExp(r'\d{9,11}'), '');

      ResidentRow? bestMatchRow;
      int highestScore = 0;
      String bestMatchReason = "";
      bool bestNeedsCheck = false;

      for (var row in _residentList) {
        String ho = row.ho.replaceAll(RegExp(r'[^0-9]'), '');
        String dong = row.dong.replaceAll(RegExp(r'[^0-9]'), '');
        if (ho.isEmpty) continue;

        int currentScore = 0;
        List<String> hitReasons = [];
        bool isEmptyRecord = row.owner.trim().isEmpty && row.resident.trim().isEmpty && row.others.every((e) => e.trim() == "-" || e.trim().isEmpty) && row.remark.trim().isEmpty;

        bool isDongHoMatch = false;
        bool hasExplicitDongHo = false;

        var hoDongRegex = RegExp(r'(\d+)호\s*(\d+)동?');
        var dongHoRegex = RegExp(r'(\d+)동\s*(\d+)호?');
        var symbolRegex = RegExp(r'(\d+)(?:-|_|/|,|:)(\d+)');

        List<Map<String, String>> extractedPairs = [];
        for (var m in hoDongRegex.allMatches(cleanDescNoSpace)) {
          extractedPairs.add({"dong": m.group(2)!, "ho": m.group(1)!});
        }
        for (var m in dongHoRegex.allMatches(cleanDescNoSpace)) {
          extractedPairs.add({"dong": m.group(1)!, "ho": m.group(2)!});
        }
        for (var m in symbolRegex.allMatches(cleanDescNoSpace)) {
          extractedPairs.add({"dong": m.group(1)!, "ho": m.group(2)!});
        }

        if (extractedPairs.isNotEmpty) hasExplicitDongHo = true;

        for (var pair in extractedPairs) {
          String exDong = pair["dong"]!;
          String exHo = int.parse(pair["ho"]!).toString();
          String targetHo = int.parse(ho).toString();
          bool isDongValid = dong.isEmpty || (dong == exDong) || (dong.contains(exDong)) || (exDong.contains(dong)) || (exDong == "1");

          if (isDongValid && exHo == targetHo) {
            isDongHoMatch = true;
            break;
          }
        }

        if (!isDongHoMatch) {
          String cleanDong = dong.replaceAll(RegExp(r'[^0-9]'), '');
          String cleanHo = ho.replaceAll(RegExp(r'[^0-9]'), '');
          String joinedTarget = cleanDong + cleanHo;

          if (joinedTarget.length >= 4 && cleanDescNoSpace.contains(joinedTarget)) {
            isDongHoMatch = true;
            hasExplicitDongHo = true;
          }
        }

        if (isDongHoMatch) {
          currentScore += 60;
          hitReasons.add("동-호");
        }

        bool hoMatch = false;
        if (!isDongHoMatch && !hasExplicitDongHo) {
          Iterable<Match> numMatches = RegExp(r'\d+').allMatches(cleanDescNoSpace);
          for (var m in numMatches) {
            if (int.tryParse(m.group(0)!)?.toString() == int.tryParse(ho)?.toString()) { hoMatch = true; break; }
          }
          if (hoMatch) { currentScore += 40; hitReasons.add("호수"); }
        }

        bool exactNameHit = false; bool typoNameHit = false; String matchedNameType = "";
        String bankNameCandidate = cleanDescNoSpace.replaceAll(RegExp(r'[0-9]'), '').replaceAll(RegExp(r'[^a-zA-Z가-힣]'), '').replaceAll(RegExp(r'^[동호]+|[동호]+$'), '');

        void checkName(String name, String type) {
          String cleanName = name.replaceAll(' ', '').toLowerCase();
          if (cleanName.length < 2 || RegExp(r'[0-9]').hasMatch(cleanName)) return;
          if (descNoSpace.contains(cleanName)) { exactNameHit = true; matchedNameType = type; }
          else if (!exactNameHit && (isDongHoMatch) && bankNameCandidate.isNotEmpty) {
            if (_calculateSimilarity(cleanName, bankNameCandidate) >= 0.6) { typoNameHit = true; matchedNameType = "$type(오타추정)"; }
          }
        }

        checkName(row.owner, "소유자");
        if (!exactNameHit) checkName(row.resident, "입주자");
        if (!exactNameHit) { for (String other in row.others) checkName(other, "기타인원"); }

        bool remarkNameHit = false;
        if (row.remark.isNotEmpty) {
          List<String> remarkParts = row.remark.split(RegExp(r'[,/.;|]'));
          for (var part in remarkParts) {
            String cleanName = part.trim().replaceAll(' ', '').toLowerCase();
            if (RegExp(r'[0-9]').hasMatch(cleanName)) continue;
            if (cleanName.length >= 2 && descNoSpace.contains(cleanName)) {
              remarkNameHit = true; hitReasons.add("비고($cleanName)");
              break;
            }
          }
        }

        if (exactNameHit) { currentScore += 50; hitReasons.add(matchedNameType); }
        else if (typoNameHit) { currentScore += 30; hitReasons.add(matchedNameType); }
        if (remarkNameHit) { currentScore += 50; }
        if (currentScore > 0 && isEmptyRecord) { currentScore -= 10; hitReasons.add("정보없음(-10)"); }

        if (currentScore > highestScore) {
          highestScore = currentScore;
          bestMatchRow = row;
          if (currentScore >= 40) {
            if (typoNameHit) { bestNeedsCheck = true; bestMatchReason = "확인필요(오타추정)"; }
            else { bestNeedsCheck = false; bestMatchReason = hitReasons.join("+"); }
          } else {
            bestNeedsCheck = true; bestMatchReason = "확인필요(${hitReasons.join("+")})";
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

    // 4개 주요 시트 생성
    createSheet("전체세대", _residentList);
    createSheet("매칭완료", _residentList.where((r) => r.isMatched && !r.isCheckRequired).toList());
    createSheet("확인필요", _residentList.where((r) => r.isMatched && r.isCheckRequired).toList());
    createSheet("매칭대기", _residentList.where((r) => !r.isMatched).toList());

    // 미확인 입금 시트 생성
    var unconfirmedSheet = excel["미확인입금"];
    unconfirmedSheet.appendRow([
      TextCellValue("거래일시"), TextCellValue("적요(내용)"),
      TextCellValue("입금액"), TextCellValue("은행명"),
      TextCellValue("은행메모(원본)"), TextCellValue("담당자메모")
    ]);

    for (var tx in _bankList.where((t) => !t.isUsed && t.amount > 0)) {
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

  Widget _buildDataTable() {
    List<dynamic> displayList = [];

    if (_currentFilter == "unconfirmed") {
      displayList = _bankList.where((tx) => !tx.isUsed && tx.amount > 0).toList();
    } else {
      List<Map<String, dynamic>> wrappedList = [];
      for (int i = 0; i < _residentList.length; i++) {
        var r = _residentList[i];
        if (_currentFilter == "matched" && (!r.isMatched || r.isCheckRequired)) continue;
        if (_currentFilter == "check_required" && !r.isCheckRequired) continue;
        if (_currentFilter == "pending" && r.isMatched) continue;
        if (_ownerSearch.isNotEmpty && !r.owner.contains(_ownerSearch)) continue;
        if (_residentSearch.isNotEmpty && !r.resident.contains(_residentSearch)) continue;

        wrappedList.add({'index': i, 'item': r});
      }

      if (_sortAiMode == 1) {
        wrappedList.sort((a, b) {
          int scoreA = a['item'].matchedField.contains("수동") ? 1 : 0;
          int scoreB = b['item'].matchedField.contains("수동") ? 1 : 0;
          if (scoreA != scoreB) return scoreB.compareTo(scoreA);
          return (a['index'] as int).compareTo(b['index'] as int);
        });
      } else if (_sortTypeMode != 0) {
        wrappedList.sort((a, b) {
          ResidentRow rowA = a['item'];
          ResidentRow rowB = b['item'];
          int scoreA = 0; int scoreB = 0;

          if (_sortTypeMode == 1) {
            if (rowA.type.contains("소유주")) scoreA = 1;
            if (rowB.type.contains("소유주")) scoreB = 1;
          } else if (_sortTypeMode == 2) {
            if (rowA.type.contains("임차인")) scoreA = 1;
            if (rowB.type.contains("임차인")) scoreB = 1;
          }

          if (scoreA != scoreB) return scoreB.compareTo(scoreA);
          return (a['index'] as int).compareTo(b['index'] as int);
        });
      }
      displayList = wrappedList.map((e) => e['item']).toList();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Container(
            color: Colors.grey[100], padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _headerCell("동", 5), _headerCell("호", 6),
                _searchHeaderCell("소유자", 10, _ownerCtrl, (v) => setState(() => _ownerSearch = v)),
                _searchHeaderCell("입주자", 10, _residentCtrl, (v) => setState(() => _residentSearch = v)),
                _headerCell("기타", 10),

                Expanded(
                  flex: 6,
                  child: InkWell(
                    onTap: () => setState(() { _sortTypeMode = (_sortTypeMode + 1) % 3; _sortAiMode = 0; }),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("구분", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _sortTypeMode > 0 ? AppTheme.primaryColor : AppTheme.textMain)),
                            Icon(Icons.sort, size: 14, color: _sortTypeMode > 0 ? AppTheme.primaryColor : Colors.grey),
                          ],
                        ),
                        if (_sortTypeMode == 1) const Text("(소유주)", style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        if (_sortTypeMode == 2) const Text("(임차인)", style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                _headerCell("비고", 10),
                _headerCell("상태(보내기)", 11),

                Expanded(
                  flex: 20,
                  child: _currentFilter == "unconfirmed"
                      ? const Text("미확인 은행 내역", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMain))
                      : InkWell(
                    onTap: () => setState(() { _sortAiMode = (_sortAiMode + 1) % 2; _sortTypeMode = 0; }),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("AI 분석 결과", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _sortAiMode > 0 ? AppTheme.primaryColor : AppTheme.textMain)),
                            Icon(Icons.sort, size: 14, color: _sortAiMode > 0 ? AppTheme.primaryColor : Colors.grey),
                          ],
                        ),
                        if (_sortAiMode == 1) const Text("(수동등록)", style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                _headerCell("담당자 메모", 12),
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
                if (item is BankTx) return _buildUnconfirmedRow(item);

                bool isTop = false, isBottom = false, isGroup = false;
                if (item is ResidentRow) {
                  bool sameAsPrev = index > 0 && displayList[index - 1] is ResidentRow && (displayList[index - 1] as ResidentRow).dong == item.dong && (displayList[index - 1] as ResidentRow).ho == item.ho;
                  bool sameAsNext = index < displayList.length - 1 && displayList[index + 1] is ResidentRow && (displayList[index + 1] as ResidentRow).dong == item.dong && (displayList[index + 1] as ResidentRow).ho == item.ho;
                  isGroup = sameAsPrev || sameAsNext;
                  isTop = isGroup && !sameAsPrev;
                  isBottom = isGroup && !sameAsNext;
                }

                return _buildResidentRow(item as ResidentRow, isGroup: isGroup, isTop: isTop, isBottom: isBottom);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentRow(ResidentRow row, {bool isGroup = false, bool isTop = false, bool isBottom = false}) {
    BorderSide thickGreen = BorderSide(color: Colors.green.shade800, width: 2.5);
    BorderSide thinGrey = BorderSide(color: Colors.grey.shade200);

    Widget _editableCell(String fieldName, String value, Function(String) onChanged, int flex, {bool highlight = false, bool isType = false}) {
      Color borderColor = row.isCheckRequired ? Colors.orange[300]! : (row.isMatched ? Colors.green[300]! : Colors.grey[300]!);

      return Expanded(
          flex: flex,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6), height: 28,
            child: TextFormField(
              key: ValueKey('${row.dong}_${row.ho}_$fieldName'),
              initialValue: value,
              onChanged: onChanged, textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: highlight || (isType && value.contains("수동")) ? FontWeight.bold : FontWeight.normal,
                  color: (isType && value.contains("수동")) ? Colors.black : Colors.black87
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                filled: true, fillColor: Colors.white,
              ),
            ),
          )
      );
    }

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
                  child: TextFormField(
                    key: ValueKey('${row.dong}_${row.ho}_others'),
                    initialValue: initVal,
                    onChanged: (v) {
                      if (row.others.isEmpty) row.others = [v, "-", "-", "-"];
                      else row.others[0] = v.isEmpty ? "-" : v;
                    },
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4), border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)), filled: true, fillColor: Colors.white),
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
          // 🌟 [UI 고도화] '동' 앞에 더하기(+) 아이콘 및 파란색 [합] 뱃지 적용
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isTop)
                // 1. 합칠 수 있는 그룹일 때: 초록색 꽉 찬 [+] 버튼을 왼쪽에 배치
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
                // 2. 이미 병합이 완료된 행일 때: 빨간색 마이너스(-) 버튼 노출 (개별 병합 해제)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: InkWell(
                      onTap: () => _unmergeRow(row), // 개별 해제 로직 호출
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.remove, size: 14, color: Colors.white),
                      ),
                    ),
                  )
                else
                // 3. 아무것도 없을 때: 줄맞춤을 위한 투명 여백
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
                        Text(
                          row.isMatched ? "${row.matchedBankText} / ${_formatCurrency(row.matchedAmount)}원" : "-",
                          style: TextStyle(color: row.isCheckRequired ? Colors.orange[900] : (row.isMatched ? Colors.green[900] : Colors.grey), fontWeight: FontWeight.bold, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
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
    Widget _inputCell(String hint, String value, Function(String) onChanged, int flex) {
      return Expanded(
          flex: flex,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            height: 28,
            child: TextFormField(
              key: ValueKey('${tx.hashCode}_$hint'),
              initialValue: value,
              onChanged: onChanged,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: hint, hintStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                filled: true, fillColor: Colors.white,
              ),
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
    return Expanded(flex: flex, child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMain), overflow: TextOverflow.ellipsis));
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

  Widget _buildSummaryBar() {
    int matchedCount = _residentList.where((r) => r.isMatched && !r.isCheckRequired).length;
    int checkCount = _residentList.where((r) => r.isMatched && r.isCheckRequired).length;
    int pendingCount = _residentList.length - (matchedCount + checkCount);
    int unconfirmedCount = _bankList.where((tx) => !tx.isUsed && tx.amount > 0).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        spacing: 12,
        children: [
          _summaryChip("전체 세대", "${_residentList.length}", Colors.blue, "all"),
          _summaryChip("매칭 완료", "$matchedCount", Colors.green, "matched"),
          _summaryChip("확인 필요", "$checkCount", Colors.orange, "check_required"),
          _summaryChip("매칭 대기", "$pendingCount", Colors.grey, "pending"),
          _summaryChip("미확인 입금", "$unconfirmedCount", Colors.red, "unconfirmed"),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color, String filterType) {
    bool isSelected = _currentFilter == filterType;
    return InkWell(
      onTap: () => setState(() => _currentFilter = filterType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? color : color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Text(value, style: TextStyle(fontSize: 14, color: isSelected ? Colors.white : color, fontWeight: FontWeight.w900))]),
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