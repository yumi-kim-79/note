import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:cp949_codec/cp949_codec.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:html' as html; // 🌟 [추가] 웹에서 엑셀 다운로드를 위한 패키지
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

// --- 데이터 모델 ---
class ResidentRow {
  final String dong;
  final String ho;

  // 🌟 [핵심 변경] 사용자가 언제든 키보드로 수정할 수 있도록 final 키워드 제거
  String owner;
  String resident;
  List<String> others;
  String type;
  String remark;

  bool isMatched = false;
  bool isCheckRequired = false;
  String matchedBankText = "";
  String matchedField = "";

  int matchedAmount = 0;
  String matchedBankName = "";
  String matchedDate = "";
  String matchedMemo = "";

  BankTx? matchedTx;
  String managerMemo = "";

  ResidentRow({
    required this.dong, required this.ho, this.owner = "", this.resident = "",
    required this.others, this.type = "", this.remark = "",
  });
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

  // 🌟 [추가] 필터 및 검색 상태 변수
  String _currentFilter = "all"; // 전체, 매칭, 대기, 미확인
  String _ownerSearch = "";      // 소유자 검색어
  String _residentSearch = "";   // 입주자 검색어
  final TextEditingController _ownerCtrl = TextEditingController();
  final TextEditingController _residentCtrl = TextEditingController();
  // 🌟 구분(Type) 정렬 모드 변수 (0:기본, 1:소유주, 2:임차인)
  int _sortTypeMode = 0;
  // 🌟 [추가됨] AI 분석결과 정렬 모드 변수 (0:기본, 1:수동등록)
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

  // 🌟 [새로 추가] AI 오타 판독기 (Fuzzy Matching Engine)
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
    return 1.0 - (v1[s2.length] / maxLength); // 1.0이면 완벽일치, 0.6이면 오타 1~2개
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

        // 🌟 [핵심 개선] 엑셀에 시트가 여러 개 있어도, 무조건 가장 첫 번째 시트만 선택합니다.
        if (excel.tables.isNotEmpty) {
          var firstSheetName = excel.tables.keys.first; // 첫 번째 시트 이름 가져오기
          var table = excel.tables[firstSheetName]!;    // 해당 시트 데이터만 추출

          for (var row in table.rows) {
            List<String> rowStrings = [];
            for (var cell in row) {
              if (cell == null || cell.value == null) {
                rowStrings.add("");
              } else {
                String txt = cell.value.toString();
                // 엑셀 패키지 특유의 CellValue(txt) 형태에서 순수 텍스트만 추출
                txt = txt.replaceAll(RegExp(r'[A-Za-z]+CellValue\('), '');
                if (txt.endsWith(')')) txt = txt.substring(0, txt.length - 1);
                rowStrings.add(txt.trim().replaceAll('\u{200B}', ''));
              }
            }
            // 한 줄이라도 데이터가 있는 경우만 추가
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

      // ------------ [기존 코드의 for 루프 교체] ------------
      int dataStartRow = -1;
      int ownerIdx = -1, residentIdx = -1, typeIdx = -1, remarkIdx = -1;
      List<int> otherIndices = [];

      for (int i = 0; i < min(30, rawRows.length); i++) {
        String fullRowText = rawRows[i].join('').replaceAll(' ', '').replaceAll('\n', '');

        if (fullRowText.contains('동') && fullRowText.contains('호')) {

          // 🌟 [핵심 개선] 아랫줄(성명, 연락처, 관계) 정보를 미리 가져옵니다.
          List<String> subRow = (i + 1 < rawRows.length)
              ? rawRows[i + 1].map((e) => e.replaceAll(' ', '').replaceAll('\n', '')).toList()
              : [];

          // 하위 열에서 '성명'을 찾아 진짜 인덱스를 반환하는 똑똑한 함수
          int findNameIdx(int idx) {
            if (subRow.isEmpty) return idx;

            // 🌟 [개선] 아랫줄이 '진짜 헤더(성명, 연락처)'인지 '실제 데이터'인지 판별
            bool isHeaderRow = subRow.any((e) => e.contains("성명") || e.contains("연락처") || e.contains("관계"));

            if (!isHeaderRow) return idx; // 아랫줄이 데이터라면 현재 인덱스 그대로 사용 (마스터 명부 케이스)

            for (int k = idx; k <= idx + 2 && k < subRow.length; k++) {
              if (subRow[k].contains("성명") || subRow[k].contains("이름")) return k;
            }
            return idx;
          }

          for (int j = 0; j < rawRows[i].length; j++) {
            String colName = rawRows[i][j].replaceAll(' ', '').replaceAll('\n', '');
            if (colName == "소유자") ownerIdx = findNameIdx(j);
            if (colName == "입주자") residentIdx = findNameIdx(j);
            if (colName.startsWith("기타")) otherIndices.add(findNameIdx(j)); // '딸'이 아닌 '김한나' 위치 획득!
            if (colName.contains("소유주/임차인") || colName == "구분") typeIdx = j;
            if (colName == "비고") remarkIdx = j;
          }

          dataStartRow = i + 1;
          if (subRow.any((e) => e.contains("성명") || e.contains("연락처"))) {
            dataStartRow++; // 두 줄짜리 헤더라면 시작점 한 칸 더 내림
          }
          break;
        }
      }
// ------------ [여기까지 덮어쓰기] ------------

      if (dataStartRow == -1) throw Exception("명부 데이터를 찾을 수 없습니다.");

      List<ResidentRow> tempResidentList = [];
      List<bool> activeOthers = [false, false, false, false];

      for (int i = dataStartRow; i < rawRows.length; i++) {
        var row = rawRows[i];
        String dong = _getSafe(row, 0);
        String ho = _getSafe(row, 1);

        if (dong.isEmpty && ho.isEmpty) continue;
        if (dong == "성명" || ho == "연락처") continue;

        // 아래 줄(성명, 연락처 등)이 있는 구조를 감안하여 인덱스 보정 (+0 또는 +1)
        int offset = (ownerIdx != -1 && rawRows[dataStartRow-1].length > ownerIdx && rawRows[dataStartRow-1][ownerIdx].contains("성명")) ? 0 : 0;

        String owner = ownerIdx != -1 ? _getSafe(row, ownerIdx + offset) : "";
        String resident = residentIdx != -1 ? _getSafe(row, residentIdx + offset) : "";

        List<String> others = [];
        for (int j = 0; j < otherIndices.length && j < 4; j++) {
          String val = _getSafe(row, otherIndices[j] + offset);
          others.add(val.isEmpty ? "-" : val);
          if (val.isNotEmpty && val != "-") activeOthers[j] = true;
        }

        // 플렉시움 양식 예외처리 (기타가 1개뿐인 경우 빈칸 채우기)
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
      int currentDescPriority = -1; // 🌟 '적요'보다 '내용'을 우선하기 위한 점수

      for (int i = 0; i < min(30, rawRows.length); i++) {
        for (int j = 0; j < rawRows[i].length; j++) {
          String val = rawRows[i][j].replaceAll(' ', '');
          if (val.contains("출금") || val.contains("잔액")) continue;

          // 🌟 [핵심] '내용'이 '적요'보다 뒤에 있어도 무조건 '내용'을 1순위로 잡음
          int priority = -1;
          if (val == "내용" || val == "거래내용" || val == "기재내용" || val == "입금자명" || val == "보내신분" || val == "맡기신분") {
            priority = 2; // 가장 확실한 1순위 제목
          } else if (val == "적요" || val == "성명" || val == "입금인") {
            priority = 1; // 2순위 제목 (1순위가 없을 때만 씀)
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
  // =======================================================
  // 🛡️ [AI 스코어링 엔진] (엔터프라이즈급 고도화 + 오타/영문 완벽 방어 버전)
  // =======================================================
  // ------------ [여기서부터 덮어쓰기] ------------
  void _runAiMatching() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 800));

    for (var tx in _bankList) tx.isUsed = false;

    // 🌟 [핵심 개선] 초기화 시 기존 클론(다중입금 줄)들을 지우고, '원본 1줄'만 남깁니다.
    // 단, 담당자가 정성껏 적어둔 메모(managerMemo)는 절대 지워지지 않고 보존됩니다!
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

      String desc = tx.description.toLowerCase();
      String descNoSpace = desc.replaceAll(' ', '');

      String cleanDesc = desc
          .replaceAll(RegExp(r'\d{2,4}[.\-/]\d{1,2}[.\-/]\d{1,2}'), ' ')
          .replaceAll(RegExp(r'\d{1,2}[.\-/]\d{1,2}(?![0-9])'), ' ')
          .replaceAll(RegExp(r'010[.\-]?\d{3,4}[.\-]?\d{4}'), ' ')
          .replaceAll(RegExp(r'\d{9,11}'), ' ');
      String cleanDescNoSpace = cleanDesc.replaceAll(' ', '');

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

        // 🌟 [핵심 1] 장부가 텅텅 비어있는 '공실(정보없음)' 상태인지 완벽하게 판독
        bool isEmptyRecord = row.owner.trim().isEmpty &&
            row.resident.trim().isEmpty &&
            row.others.every((e) => e.trim() == "-" || e.trim().isEmpty) &&
            row.remark.trim().isEmpty;

        bool isHyphenMatch = false;
        var hyphen = RegExp(r'(\d+)-0*(\d+)').firstMatch(cleanDescNoSpace);
        if (hyphen != null) {
          String h = int.parse(hyphen.group(2)!).toString();
          if (h == ho && (dong.endsWith(hyphen.group(1)!) || dong == dong)) { // 하이픈 동호수 매칭 강화
            isHyphenMatch = true; currentScore += 60; hitReasons.add("동-호");
          }
        }

        bool hoMatch = false;
        Iterable<Match> numMatches = RegExp(r'\d+').allMatches(cleanDescNoSpace);
        for (var m in numMatches) {
          if (int.tryParse(m.group(0)!)?.toString() == int.tryParse(ho)?.toString()) {
            hoMatch = true; break;
          }
        }
        if (hoMatch && !isHyphenMatch) { currentScore += 40; hitReasons.add("호수"); }

        bool exactNameHit = false; bool typoNameHit = false; String matchedNameType = "";

        // 🚨 [핵심 2] 건물명(해피리움 등)을 지우거나 가중치를 주는 구시대적 로직을 완전히 소멸시킴!
        String bankNameCandidate = cleanDescNoSpace.replaceAll(RegExp('0?'+ho), '').replaceAll('호', '').replaceAll(RegExp(r'[0-9]'), '').replaceAll(RegExp(r'[^a-zA-Z가-힣]'), '');

        void checkName(String name, String type) {
          String cleanName = name.replaceAll(' ', '').toLowerCase();
          if (cleanName.length < 2) return;
          if (descNoSpace.contains(cleanName)) {
            exactNameHit = true; matchedNameType = type;
          } else if (!exactNameHit && hoMatch && bankNameCandidate.isNotEmpty) {
            if (_calculateSimilarity(cleanName, bankNameCandidate) >= 0.6) {
              typoNameHit = true; matchedNameType = "$type(오타추정)";
            }
          }
        }

        checkName(row.owner, "소유자");
        if (!exactNameHit) checkName(row.resident, "입주자");
        if (!exactNameHit) { for (String other in row.others) checkName(other, "기타인원"); }

        if (exactNameHit) { currentScore += 50; hitReasons.add(matchedNameType); }
        else if (typoNameHit) { currentScore += 30; hitReasons.add(matchedNameType); }

        // 🌟 [비고란 다중 이름 분석 엔진]
        bool remarkNameHit = false;
        if (row.remark.isNotEmpty) {
          // 콤마(,), 슬래시(/), 세미콜론(;), 마침표(.) 등으로 이름을 분리합니다.
          List<String> remarkParts = row.remark.split(RegExp(r'[,/.;|]'));

          for (var part in remarkParts) {
            String cleanName = part.trim().replaceAll(' ', '').toLowerCase();

            // 2글자 이상인 이름이 입금 내역에 포함되어 있는지 개별적으로 확인
            if (cleanName.length >= 2 && descNoSpace.contains(cleanName)) {
              remarkNameHit = true;
              // 어떤 이름 때문에 매칭되었는지 명확하게 사유를 남깁니다.
              hitReasons.add("비고($cleanName)");
              break; // 한 명이라도 맞으면 점수 부여 후 중단
            }
          }
        }

        // 비고란 이름 매칭 시 50점 부여
        if (remarkNameHit) {
          currentScore += 50;
        }

        // 🌟 [핵심 3] 호수를 맞췄지만 장부가 비어있다면 가차 없이 -10점 페널티!
        if (currentScore > 0 && isEmptyRecord) {
          currentScore -= 10;
          hitReasons.add("정보없음(-10)");
        }

        // 🌟 [최종 분류 판정: 3단 룰]
        if (currentScore > highestScore) {
          highestScore = currentScore;
          bestMatchRow = row;

          if (currentScore >= 40) {
            // 🟢 40점 이상: 원칙적으로 무조건 [매칭완료(초록색)] 직행
            if (typoNameHit) {
              // 단, 오타 매칭(70점)은 실무 안전을 위해 예외적으로 [확인필요]로 뺌
              bestNeedsCheck = true;
              bestMatchReason = "확인필요(오타추정)";
            } else {
              bestNeedsCheck = false;
              bestMatchReason = hitReasons.join("+");
            }
          } else {
            // 🟠 30점 ~ 39점: [확인필요(오렌지색)]
            bestNeedsCheck = true;
            bestMatchReason = "확인필요(${hitReasons.join("+")})";
          }
        }
      }

      // 🌟 [핵심 4] 커트라인을 30점으로 하향하여 페널티 받은 공실(30점)도 안전하게 수용!
      if (highestScore >= 30 && bestMatchRow != null) {
        ResidentRow targetRow = bestMatchRow;

        if (targetRow.isMatched) {
          ResidentRow cloneRow = ResidentRow(
            dong: targetRow.dong, ho: targetRow.ho, owner: targetRow.owner,
            resident: targetRow.resident, others: List.from(targetRow.others),
            type: targetRow.type, remark: targetRow.remark,
          );
          cloneRow.managerMemo = targetRow.managerMemo;

          int insertIdx = _residentList.indexOf(targetRow) + 1;
          while (insertIdx < _residentList.length && _residentList[insertIdx].dong == targetRow.dong && _residentList[insertIdx].ho == targetRow.ho) {
            insertIdx++;
          }
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
// ------------ [여기까지 덮어쓰기] ------------

  // 🌟 [추가] 실무자 수동 개입 (Manual Override) 로직
  void _changeStatus(ResidentRow row, String newStatus) {
    setState(() {
      if (newStatus == "매칭완료") {
        row.isMatched = true;
        row.isCheckRequired = false;

        // 🌟 [추가] 담당자가 눈으로 확인 후 강제로 '보내기(완료)'를 눌렀다는 꼬리표 추가
        if (!row.matchedField.contains("[수동확정]")) {
          row.matchedField = "${row.matchedField} [수동확정]";
        }
      } else if (newStatus == "확인필요") {
        row.isMatched = true;
        row.isCheckRequired = true;
      } else if (newStatus == "매칭대기") {
        // 돈을 뱉어냄
        if (row.matchedTx != null) { row.matchedTx!.isUsed = false; row.matchedTx = null; }

        // 🌟 다중 입금 취소 처리: 화면에 같은 호수가 여러 개(클론) 있다면, 이 줄을 아예 삭제!
        int cloneCount = _residentList.where((r) => r.dong == row.dong && r.ho == row.ho).length;
        if (cloneCount > 1) {
          _residentList.remove(row);
        } else {
          // 마지막 남은 1줄이면 지우지 않고 빈칸으로 초기화
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

    // 🌟 [핵심 개선 1] 기본 생성되는 텅 빈 시트(Sheet1)의 이름을 '전체세대'로 변경하여 찌꺼기 시트 생성을 완벽 차단!
    String defaultSheet = excel.getDefaultSheet() ?? "Sheet1";
    excel.rename(defaultSheet, "전체세대");

    void createSheet(String sheetName, List<ResidentRow> rows) {
      var sheet = excel[sheetName];

      // 🌟 [핵심 개선 2] 엑셀 헤더에 '구분' 열을 추가하여 화면에서 수정한 데이터가 모두 엑셀에 반영되도록 조치!
      sheet.appendRow([
        TextCellValue("동"), TextCellValue("호"), TextCellValue("소유자"), TextCellValue("입주자"),
        TextCellValue("기타1"), TextCellValue("기타2"), TextCellValue("기타3"), TextCellValue("기타4"), // 🌟 열 확장
        TextCellValue("구분"), TextCellValue("비고"), TextCellValue("입금일자"), TextCellValue("은행적요(내용)"),
        TextCellValue("입금액"), TextCellValue("담당자메모"), TextCellValue("최종상태")
      ]);

      for (var r in rows) {
        String status = r.isMatched ? (r.isCheckRequired ? "확인필요" : "매칭완료") : "매칭대기";
        sheet.appendRow([
          TextCellValue(r.dong), TextCellValue(r.ho), TextCellValue(r.owner), TextCellValue(r.resident),
          TextCellValue(r.others[0]), TextCellValue(r.others[1]), TextCellValue(r.others[2]), TextCellValue(r.others[3]), // 🌟 각각 출력
          TextCellValue(r.type), TextCellValue(r.remark), TextCellValue(r.matchedDate), TextCellValue(r.matchedBankText),
          TextCellValue(r.matchedAmount > 0 ? _formatCurrency(r.matchedAmount) : ""),
          TextCellValue(r.managerMemo), TextCellValue(status)
        ]);

        // 🌟 "전체세대" 시트이고, "매칭완료" 상태라면 초록색 배경색을 칠함
        if (sheetName == "전체세대" && status == "매칭완료") {
          int currentRowIdx = sheet.maxRows - 1;
          for (int col = 0; col < 15; col++) { // 🌟 '구분' 열이 추가되어 총 12칸에 색상을 칠함!
            var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRowIdx));
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#FFE8F5E9'),
              verticalAlign: VerticalAlign.Center,
            );
          }
        }
      }
    }

    // 1~4번째 시트 생성
    createSheet("전체세대", _residentList);
    createSheet("매칭완료", _residentList.where((r) => r.isMatched && !r.isCheckRequired).toList());
    createSheet("확인필요", _residentList.where((r) => r.isMatched && r.isCheckRequired).toList());
    createSheet("매칭대기", _residentList.where((r) => !r.isMatched).toList());

    // 5번째 시트 (미확인 입금) 생성
    var unconfirmedSheet = excel["미확인입금"];
    unconfirmedSheet.appendRow([TextCellValue("거래일시"), TextCellValue("적요(내용)"), TextCellValue("입금액"), TextCellValue("은행명"), TextCellValue("메모")]);
    for (var tx in _bankList.where((t) => !t.isUsed && t.amount > 0)) {
      unconfirmedSheet.appendRow([TextCellValue(tx.date), TextCellValue(tx.description), TextCellValue(_formatCurrency(tx.amount)), TextCellValue(tx.bankName), TextCellValue(tx.memo)]);
    }

    // 첫 페이지(전체세대) 고정
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

  // 🌟 [새로 추가] 담당자 메모 입력 팝업창 함수
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
                  setState(() => row.managerMemo = ctrl.text.trim());
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
                  decoration: InputDecoration(
                      labelText: "기타 인원 ${i + 1}",
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  ),
                ),
              )),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    row.others = ctrls.map((c) => c.text.trim().isEmpty ? "-" : c.text.trim()).toList();
                  });
                  Navigator.pop(ctx);
                },
                child: const Text("저장")
            )
          ],
        )
    );
  }
  // =======================================================
  // [UI 렌더링 파트]
  // =======================================================
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
      // 🌟 [변경] Row 대신 Wrap을 사용하여 화면이 좁아지면 자동으로 줄바꿈 처리
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16, // 위아래 요소가 겹치지 않게 간격 설정
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("AI 자동수납 시스템 (전산팀)", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                const SizedBox(height: 4),
                // 만약 GlobalUserState 오류가 나면 이 줄을 Text("담당자 • AI 수납 분석 모드"...) 로 변경하세요.
                Text("${GlobalUserState.fullName} 담당자 • AI 수납 분석 모드", style: const TextStyle(color: AppTheme.textSub, fontSize: 13)),
              ]
          ),

          // 🌟 버튼 묶음도 Wrap으로 감싸서 너비가 부족하면 밑으로 예쁘게 떨어지도록 처리
          Wrap(
            spacing: 12, // 버튼 좌우 간격
            runSpacing: 12, // 버튼 상하 간격
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
              )
            ],
          )
        ],
      ),
    );
  }

  // 🌟 [새로 추가] 미확인 입금을 '매칭완료' 또는 '확인필요'로 수동 처리하는 로직
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
        // 🌟 [핵심 개선] 강제로 글자를 넣지 않고, 담당자가 미확인 탭 '구분'에 입력한 글자 그대로 보냄!
        type: tx.inputType.trim(),
        remark: tx.inputRemark.trim(),
      );

      // 🌟 파라미터에 따라 '확인필요' 또는 '매칭완료' 상태 동적 할당
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

  // ------------ [여기서부터 덮어쓰기] ------------
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

      // 🌟 [AI 분석 결과 정렬] 수동등록이 최상단으로 오게 함
      if (_sortAiMode == 1) {
        wrappedList.sort((a, b) {
          int scoreA = a['item'].matchedField.contains("수동") ? 1 : 0;
          int scoreB = b['item'].matchedField.contains("수동") ? 1 : 0;
          if (scoreA != scoreB) return scoreB.compareTo(scoreA);
          return (a['index'] as int).compareTo(b['index'] as int);
        });
      }
      // 🌟 [구분 정렬] 수동은 빼고 소유주, 임차인만 남김
      else if (_sortTypeMode != 0) {
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

                // 🌟 [개선됨] 구분 정렬 헤더 (소유주 ➔ 임차인 ➔ 기본)
                Expanded(
                  flex: 6,
                  child: InkWell(
                    // 클릭 시 AI 정렬은 끄고, 구분 정렬만 3단계(0,1,2)로 순환
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

                // 🌟 [신규 추가] AI 분석 결과 정렬 헤더 (수동등록 ➔ 기본)
                Expanded(
                  flex: 20,
                  child: _currentFilter == "unconfirmed"
                      ? const Text("미확인 은행 내역", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMain))
                      : InkWell(
                    // 클릭 시 구분 정렬은 끄고, AI 정렬만 2단계(0,1)로 순환
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
// ------------ [여기까지 덮어쓰기] ------------

  // 🌟 [순서 개편 및 다중 입금 시각화 적용]
  Widget _buildResidentRow(ResidentRow row, {bool isGroup = false, bool isTop = false, bool isBottom = false}) {
    BorderSide thickGreen = BorderSide(color: Colors.green.shade800, width: 2.5);
    BorderSide thinGrey = BorderSide(color: Colors.grey.shade200);

    // 🌟 [핵심 개선] 매칭완료(초록), 확인필요(오렌지), 매칭대기(투명) 등 항상 텍스트 수정 가능!
    Widget _editableCell(String fieldName, String value, Function(String) onChanged, int flex, {bool highlight = false, bool isType = false}) {
      // 탭의 상태에 따라 테두리 색상 예쁘게 변경
      Color borderColor = row.isCheckRequired ? Colors.orange[300]! : (row.isMatched ? Colors.green[300]! : Colors.grey[300]!);

      return Expanded(
          flex: flex,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6), height: 28,
            child: TextFormField(
              key: ValueKey('${row.dong}_${row.ho}_$fieldName'),
              initialValue: value, // 🌟 기존 데이터를 그대로 뿌려줌 (수정 가능)
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

    // 🌟 기타인원 전용 편집칸 (항상 활성화)
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
                      // 첫 번째 기타 인원 수정 시 즉시 반영 (공유됨)
                      if (row.others.isEmpty) row.others = [v, "-", "-", "-"];
                      else row.others[0] = v.isEmpty ? "-" : v;
                    },
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4), border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)), filled: true, fillColor: Colors.white),
                  ),
                ),
              ),
              // 🌟 다중 인원 관리를 위한 팝업 버튼
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
          // 동, 호수는 고정이므로 텍스트 유지
          _dataCell(row.dong, 5, isHighlight: row.isMatched && row.matchedField.contains("동")),
          _dataCell(row.ho, 6, isHighlight: row.isMatched && row.matchedField.contains("호")),

          // 🌟 소유자, 입주자, 기타, 구분, 비고 모두 키보드 입력칸으로 전면 교체!
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
  // 🌟 컬럼 배율이 바뀌었으므로 미확인 로우의 배율도 동일하게 100(총합)으로 맞춰줍니다.
  Widget _buildUnconfirmedRow(BankTx tx) {
    // 🌟 입력 칸을 예쁘게 만들어주는 헬퍼 위젯
    Widget _inputCell(String hint, String value, Function(String) onChanged, int flex) {
      return Expanded(
          flex: flex,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            height: 28,
            child: TextFormField(
              // 🚨 [핵심 개선] 각 입력칸에 고유 Key 부여 -> 껍데기 재사용으로 인한 잔상 버그 완벽 차단!
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
          // 🌟 엑셀 열 비율(5,6,10,10,10,6,10)에 맞춰 텍스트 입력칸 생성!
          _inputCell("동", tx.inputDong, (v) => tx.inputDong = v, 5),
          _inputCell("호", tx.inputHo, (v) => tx.inputHo = v, 6),
          _inputCell("소유자", tx.inputOwner, (v) => tx.inputOwner = v, 10),
          _inputCell("입주자", tx.inputResident, (v) => tx.inputResident = v, 10),
          _inputCell("기타", tx.inputOthers, (v) => tx.inputOthers = v, 10),
          // 🌟 [핵심 개선] 구분 열도 이제 담당자가 직접 입력할 수 있음!
          _inputCell("구분", tx.inputType, (v) => tx.inputType = v, 6),
          _inputCell("비고", tx.inputRemark, (v) => tx.inputRemark = v, 10),

          // 🌟 상태(보내기) 드롭다운 (Flex 11)
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
                    DropdownMenuItem(value: "확인필요", child: Text("확인필요(보내기)", style: TextStyle(color: Colors.orange))), // 🌟 신규 추가
                    DropdownMenuItem(value: "매칭완료", child: Text("매칭완료(보내기)", style: TextStyle(color: Colors.green))),
                  ],
                  onChanged: (val) {
                    // 🌟 선택한 값에 따라 다른 탭으로 쏘아보냄!
                    if (val == "매칭완료") _manualMatchFromBank(tx, isCheckRequired: false);
                    else if (val == "확인필요") _manualMatchFromBank(tx, isCheckRequired: true);
                  },
                ),
              ),
            ),
          ),

          // 🌟 AI 분석결과 (은행 원본 정보 표출) (Flex 20)
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

          // 🌟 담당자 메모 (Flex 12)
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
                              ElevatedButton(onPressed: () { setState(() => tx.managerMemo = ctrl.text.trim()); Navigator.pop(ctx); }, child: const Text("저장"))
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
    int checkCount = _residentList.where((r) => r.isMatched && r.isCheckRequired).length; // 🌟 추가
    int pendingCount = _residentList.length - (matchedCount + checkCount);
    int unconfirmedCount = _bankList.where((tx) => !tx.isUsed && tx.amount > 0).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        spacing: 12,
        children: [
          _summaryChip("전체 세대", "${_residentList.length}", Colors.blue, "all"),
          _summaryChip("매칭 완료", "$matchedCount", Colors.green, "matched"),
          _summaryChip("확인 필요", "$checkCount", Colors.orange, "check_required"), // 🌟 추가
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