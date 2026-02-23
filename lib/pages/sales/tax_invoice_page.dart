// [메뉴명: 국세청(계산서) 대조]
// [파일 위치: lib/pages/sales/tax_invoice_page.dart]

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:cp949_codec/cp949_codec.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:html' as html;

import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

// --- 데이터 모델 ---
class InvoiceData {
  final String category;
  final String companyName;
  final String siteName;
  final int amount;

  final String publishDate;
  final String bizNum;
  final String repName;
  final String address;
  final String email;
  final String receiptType;
  final String itemName;
  final String remark;
  final String authNum; // 🌟 [추가됨] 국세청 승인번호

  InvoiceData({
    this.category = '-',
    required this.companyName,
    this.siteName = '-',
    required this.amount,
    this.publishDate = '-',
    this.bizNum = '-',
    this.repName = '-',
    this.address = '-',
    this.email = '-',
    this.receiptType = '-',
    this.itemName = '-',
    this.remark = '-',
    this.authNum = '-', // 🌟 기본값 추가
  });
}

enum MatchStatus { perfect, partial, mismatch, none }

class MatchResult {
  final InvoiceData? internalData;
  InvoiceData? ntsData;
  MatchStatus status;
  double score;
  String memo;

  MatchResult({
    this.internalData,
    this.ntsData,
    this.status = MatchStatus.none,
    this.score = 0.0,
    this.memo = '',
  });
}

class TaxInvoicePage extends StatefulWidget {
  const TaxInvoicePage({super.key});

  @override
  State<TaxInvoicePage> createState() => _TaxInvoicePageState();
}

class _TaxInvoicePageState extends State<TaxInvoicePage> {
  final ScrollController _horizontalScrollController = ScrollController();

  List<List<String>> _rawInternalRows = [];
  List<List<String>> _rawNtsRows = [];

  bool _isInternalLoaded = false;
  bool _isNtsLoaded = false;
  bool _isMatched = false;
  bool _isMatching = false; // 🌟 AI 분석 중 상태 변수

  String _internalFileName = '';
  String _ntsFileName = '';

  List<InvoiceData> _internalList = [];
  List<InvoiceData> _ntsList = [];
  List<MatchResult> _results = [];

  int _sortColumnIndex = 3;
  bool _sortAscending = true;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  String _currentFilter = 'all';

  String _filterCategory = 'all';
  String _searchSiteQuery = '';
  bool _isSiteSearchActive = false;
  final TextEditingController _siteSearchController = TextEditingController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _siteSearchController.dispose();
    super.dispose();
  }

  // =======================================================
  // [로직 1] 공통 파일 읽기
  // =======================================================
  List<List<String>> _getRowsFromBytes(String ext, List<int> bytes) {
    List<List<String>> rows = [];
    if (ext == 'xlsx' || ext == 'xls') {
      var excel = Excel.decodeBytes(bytes);
      String sheetName = excel.tables.keys.first;
      var table = excel.tables[sheetName];
      if (table != null) {
        for (var row in table.rows) {
          rows.add(row.map((e) => e?.value?.toString() ?? '').toList());
        }
      }
    } else if (ext == 'csv') {
      String csvString;
      try { csvString = utf8.decode(bytes); }
      catch(e) {
        try { csvString = cp949.decode(bytes); }
        catch(e2) { csvString = utf8.decode(bytes, allowMalformed: true); }
      }
      List<String> lines = csvString.split(RegExp(r'\r\n|\n'));
      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        List<String> row = [];
        bool inQuotes = false; String currentToken = "";
        for (int i = 0; i < line.length; i++) {
          String char = line[i];
          if (char == '"') { inQuotes = !inQuotes; }
          else if (char == ',' && !inQuotes) { row.add(currentToken.trim()); currentToken = ""; }
          else { currentToken += char; }
        }
        row.add(currentToken.trim());
        rows.add(row);
      }
    }
    return rows;
  }

  // =======================================================
  // [로직 2] 우리 장부 업로드 및 파싱 (예외/기간 처리 고도화)
  // =======================================================
  Future<void> _uploadInternalData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx', 'xls', 'csv'], withData: true,
      );
      if (result == null) return;
      String ext = result.files.single.extension?.toLowerCase() ?? '';
      final bytes = result.files.single.bytes;
      if (bytes == null || !['xlsx', 'xls', 'csv'].contains(ext)) {
        _showErrorSnackBar("올바른 엑셀(.xlsx) 또는 CSV 파일이 아닙니다."); return;
      }
      _rawInternalRows = _getRowsFromBytes(ext, bytes);
      _internalFileName = result.files.single.name;
      _processInternalData();
    } catch (e) { _showNoticePopup("파일 읽기 오류", "장부 파일을 읽는 중 오류가 발생했습니다.\n$e"); }
  }

  void _processInternalData() {
    if (_rawInternalRows.isEmpty) return;
    try {
      List<InvoiceData> parsedList = [];
      int targetMonthIdx = -1;
      Set<String> foundMonths = {};

      for (var cols in _rawInternalRows) {
        if (cols.isEmpty) continue;
        if (targetMonthIdx == -1) {
          for (int i = 0; i < cols.length; i++) {
            String cell = cols[i].replaceAll(' ', '');
            if (cell.contains('$_selectedMonth월')) targetMonthIdx = i;
            if (cell.contains('월')) {
              var match = RegExp(r'(\d+)월').firstMatch(cell);
              if (match != null) foundMonths.add("${match.group(1)}월");
            }
          }
        }
        if (cols.length < 3 || cols[0].contains('업종') || cols[1].contains('업체명')) continue;
        String company = cols[1].trim();
        if (company.isEmpty) continue;

        int amount = 0;
        if (targetMonthIdx != -1 && cols.length > targetMonthIdx) {
          String amountStr = cols[targetMonthIdx].replaceAll(RegExp(r'[",원\s]'), '');
          if (amountStr.contains('.')) amountStr = amountStr.split('.')[0];
          amount = int.tryParse(amountStr) ?? 0;
        }
        if (amount <= 0) continue;

        parsedList.add(InvoiceData(category: cols[0].trim(), companyName: company, siteName: cols[2].trim(), amount: amount));
      }

      // 🚨 기간 불일치 즉시 차단 및 초기화 (고도화)
      if (targetMonthIdx == -1) {
        String monthHint = foundMonths.isNotEmpty ? "\n(파일 내 감지된 항목: ${foundMonths.join(', ')})" : "";
        _showNoticePopup("기간 불일치 안내 (장부)", "현재 설정된 '$_selectedMonth월' 데이터가 장부에 없습니다.$monthHint\n\n기간을 먼저 맞게 설정하신 후 파일을 처음부터 다시 업로드해 주세요.");
        setState(() {
          _isInternalLoaded = false;
          _internalFileName = '';
          _rawInternalRows.clear(); // 🌟 핵심: 파일 메모리 완전히 삭제 (초기화)
          _internalList.clear();
        });
        return;
      }

      setState(() { _internalList = parsedList; _isInternalLoaded = true; });
      _showSuccessSnackBar("우리 장부 $_selectedMonth월 데이터 ${parsedList.length}건 로드 완료!");
    } catch (e) {
      _showNoticePopup("장부 업로드 오류", "장부 파일을 분석하는 중 오류가 발생했습니다.\n형식이 훼손되지 않았는지 확인해 주세요.\n상세 원인: $e");
      setState(() { _isInternalLoaded = false; _internalFileName = ''; });
    }
  }

  // =======================================================
  // [로직 3] 국세청 파싱 (예외/기간 처리 고도화)
  // =======================================================
  Future<void> _uploadNtsData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx', 'xls', 'csv'], withData: true,
      );
      if (result == null) return;
      String ext = result.files.single.extension?.toLowerCase() ?? '';
      final bytes = result.files.single.bytes;
      if (bytes == null) return;
      _rawNtsRows = _getRowsFromBytes(ext, bytes);
      _ntsFileName = result.files.single.name;
      _processNtsData();
    } catch (e) { _showNoticePopup("국세청 파일 읽기 오류", "오류가 발생했습니다.\n$e"); }
  }

  DateTime? _parseDate(String dateStr) {
    final clean = dateStr.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 8) {
      int y = int.tryParse(clean.substring(0,4)) ?? 0;
      int m = int.tryParse(clean.substring(4,6)) ?? 0;
      int d = int.tryParse(clean.substring(6,8)) ?? 0;
      if (y > 0 && m > 0 && d > 0) return DateTime(y, m, d);
    }
    return null;
  }

  void _processNtsData() {
    if (_rawNtsRows.isEmpty) return;
    try {
      List<InvoiceData> parsedList = [];
      bool isHeaderFound = false;
      int companyIdx = -1, amountIdx = -1, dateIdx = -1, bizNumIdx = -1, repNameIdx = -1;
      int addressIdx = -1, emailIdx = -1, receiptTypeIdx = -1, itemNameIdx = -1, remarkIdx = -1;
      int authNumIdx = -1; // 🌟 [추가됨] 승인번호 인덱스

      DateTime targetStart = DateTime(_selectedYear, _selectedMonth, 1);
      DateTime targetEnd = DateTime(_selectedYear, _selectedMonth + 1, 15, 23, 59, 59);
      int fileDetectedYear = -1, fileDetectedMonth = -1;

      for (var cols in _rawNtsRows) {
        if (cols.isEmpty) continue;
        if (!isHeaderFound) {
          for (int i = 0; i < cols.length; i++) {
            String cell = cols[i].replaceAll(RegExp(r'\s'), '');
            if (cell.contains('작성일자') || cell.contains('승인번호')) isHeaderFound = true;
          }
          if (isHeaderFound) {
            for (int i = 0; i < cols.length; i++) {
              String cell = cols[i].replaceAll(RegExp(r'\s'), '');
              if (cell == '상호' && companyIdx == -1) companyIdx = i;
              if (cell == '합계금액' || cell == '총합계금액') amountIdx = i;
              if (cell == '작성일자') dateIdx = i;
              if (cell.contains('공급자사업자등록번호')) bizNumIdx = i;
              if (cell == '대표자명' && repNameIdx == -1) repNameIdx = i;
              if (cell == '주소' && addressIdx == -1) addressIdx = i;
              if (cell.contains('이메일') && emailIdx == -1) emailIdx = i;
              if (cell.contains('영수/청구')) receiptTypeIdx = i;
              if (cell == '품목명') itemNameIdx = i;
              if (cell == '비고' || cell == '품목비고') remarkIdx = i;
              if (cell == '승인번호' && authNumIdx == -1) authNumIdx = i; // 🌟 [추가됨] 승인번호 찾기
            }
          }
          continue;
        }

        if (companyIdx != -1 && amountIdx != -1 && cols.length > max(companyIdx, amountIdx)) {
          String company = cols[companyIdx].trim();
          if (company.isEmpty) continue;

          String safeGet(int idx) => (idx != -1 && cols.length > idx) ? cols[idx].trim() : '-';
          String publishDate = safeGet(dateIdx);

          DateTime? pDate = _parseDate(publishDate);
          if (pDate != null) {
            if (fileDetectedYear == -1) { fileDetectedYear = pDate.year; fileDetectedMonth = pDate.month; }
            if (pDate.isBefore(targetStart) || pDate.isAfter(targetEnd)) continue;

            // 🌟 [고도화] 날짜를 YYYY-MM-DD 형태로 예쁘게 만들고, 다음 달이면 [익월] 태그를 붙입니다!
            publishDate = "${pDate.year}-${pDate.month.toString().padLeft(2, '0')}-${pDate.day.toString().padLeft(2, '0')}";
            if (pDate.month != _selectedMonth) {
              publishDate = "[익월] $publishDate";
            }
          } else { continue; }

          String amountStr = cols[amountIdx].replaceAll(RegExp(r'[",원\s]'), '');
          if (amountStr.contains('.')) amountStr = amountStr.split('.')[0];
          int amount = int.tryParse(amountStr) ?? 0;

          parsedList.add(InvoiceData(
            category: '국세청자료', companyName: company, amount: amount, publishDate: publishDate,
            bizNum: safeGet(bizNumIdx), repName: safeGet(repNameIdx), address: safeGet(addressIdx),
            email: safeGet(emailIdx), receiptType: safeGet(receiptTypeIdx), itemName: safeGet(itemNameIdx), remark: safeGet(remarkIdx),
            authNum: safeGet(authNumIdx), // 🌟 [추가됨] 승인번호 저장
          ));
        }
      }

      // 🚨 기간 불일치 즉시 차단 및 초기화 (고도화)
      if (parsedList.isEmpty && fileDetectedYear != -1) {
        _showNoticePopup("기간 불일치 안내 (국세청)", "업로드하신 자료는 '$fileDetectedYear년 $fileDetectedMonth월' 데이터입니다.\n하지만 현재 설정은 '$_selectedYear년 $_selectedMonth월'입니다.\n\n기간을 먼저 맞게 설정하신 후 파일을 처음부터 다시 업로드해 주세요.");
        setState(() {
          _isNtsLoaded = false;
          _ntsFileName = '';
          _rawNtsRows.clear(); // 🌟 핵심: 파일 메모리 완전히 삭제 (초기화)
          _ntsList.clear();
        });
        return;
      }

      setState(() { _ntsList = parsedList; _isNtsLoaded = true; });
      _showSuccessSnackBar("국세청 $_selectedMonth월 데이터 ${parsedList.length}건 로드 완료!");
    } catch (e) {
      _showNoticePopup("국세청 업로드 오류", "국세청 파일을 분석하는 중 오류가 발생했습니다.\n형식이 훼손되지 않았는지 확인해 주세요.\n상세 원인: $e");
      setState(() { _isNtsLoaded = false; _ntsFileName = ''; });
    }
  }

  // 🌟 [고도화] 날짜 변경 시 자동실행(AutoMatching) 방지 및 재검증 로직
  void _onDateChanged() {
    // 날짜를 바꾸면 기존에 업로드된 파일을 새 날짜 기준으로 다시 분석만 합니다. (자동 실행 삭제!)
    if (_rawInternalRows.isNotEmpty) _processInternalData();
    if (_rawNtsRows.isNotEmpty) _processNtsData();

    // 만약 날짜 변경으로 인해 데이터가 비워졌다면 대조 결과도 초기화
    if (!_isInternalLoaded || !_isNtsLoaded) {
      setState(() {
        _isMatched = false;
        _results.clear();
      });
    }
  }

  // =======================================================
  // 🌟 [슈퍼 패스] 수동 이동 상태를 최우선으로 판별하는 통합 헬퍼 함수
  // =======================================================
  bool _isPerfect(MatchResult r) => r.memo.contains("[수동:완벽매칭]") || (!r.memo.contains("[수동:") && r.status == MatchStatus.perfect);
  bool _isPartial(MatchResult r) => r.memo.contains("[수동:확인요망]") || (!r.memo.contains("[수동:") && r.status == MatchStatus.partial);
  bool _isMissing(MatchResult r) => r.memo.contains("[수동:미발행]") || (!r.memo.contains("[수동:") && r.status == MatchStatus.mismatch && r.ntsData == null);
  bool _isAmtError(MatchResult r) => r.memo.contains("[수동:금액오류]") || (!r.memo.contains("[수동:") && r.status == MatchStatus.mismatch && r.ntsData != null && r.internalData != null);
  // 🌟 [고도화 추가] 내부장부누락 헬퍼 (수동 이동 및 자동 상태 감지)
  bool _isInternalMissing(MatchResult r) => r.memo.contains("[수동:장부누락]") || (!r.memo.contains("[수동:") && r.status == MatchStatus.mismatch && r.internalData == null);

  List<MatchResult> get _filteredResults {
    List<MatchResult> temp = _results;
    if (_currentFilter == 'perfect') temp = temp.where((r) => _isPerfect(r)).toList();
    else if (_currentFilter == 'partial') temp = temp.where((r) => _isPartial(r)).toList();
    else if (_currentFilter == 'missing') temp = temp.where((r) => _isMissing(r)).toList();
    else if (_currentFilter == 'amount_error') temp = temp.where((r) => _isAmtError(r)).toList();
    else if (_currentFilter == 'internal_missing') temp = temp.where((r) => _isInternalMissing(r)).toList(); // 🌟 필터 추가

    if (_filterCategory != 'all') temp = temp.where((r) => (r.internalData?.category ?? '-') == _filterCategory).toList();
    if (_searchSiteQuery.isNotEmpty) temp = temp.where((r) => (r.internalData?.siteName ?? '').toLowerCase().contains(_searchSiteQuery.toLowerCase())).toList();
    return temp;
  }

  void _downloadExcel() {
    if (_results.isEmpty) return;
    var excel = Excel.createExcel();

    // 🌟 시트를 만들어주는 고도화된 내부 도우미 함수
    void buildSheet(String sheetName, List<MatchResult> dataList, String sortType) {
      Sheet sheet = excel[sheetName];
      List<MatchResult> sortedList = List.from(dataList);

      if (sortType == 'name') sortedList.sort((a, b) => (a.internalData?.companyName ?? '').compareTo(b.internalData?.companyName ?? ''));
      else if (sortType == 'amount') sortedList.sort((a, b) => (b.internalData?.amount ?? 0).compareTo(a.internalData?.amount ?? 0));
      else if (sortType == 'error') sortedList.sort((a, b) {
        int diffA = ((a.internalData?.amount ?? 0) - (a.ntsData?.amount ?? 0)).abs();
        int diffB = ((b.internalData?.amount ?? 0) - (b.ntsData?.amount ?? 0)).abs();
        return diffB.compareTo(diffA);
      });

      // 🌟 [고도화] 엑셀 헤더에 9번째 열 '상세 비고' 추가
      sheet.appendRow([
        TextCellValue('상태'), TextCellValue('업종'), TextCellValue('현장명'),
        TextCellValue('우리장부 업체명'), TextCellValue('우리장부 금액'),
        TextCellValue('국세청 업체명'), TextCellValue('국세청 금액'), TextCellValue('AI 분석결과'),
        TextCellValue('상세 비고 (승인번호 및 합산내역)') // 🌟 추가됨
      ]);

      for (var r in sortedList) {
        String statusStr = '상태불명(확인요망)';
        if (_isPerfect(r)) statusStr = '완벽매칭';
        else if (_isPartial(r)) statusStr = '확인요망';
        else if (_isMissing(r)) statusStr = '미발행/누락';
        else if (_isAmtError(r)) statusStr = '금액오류';
        else if (_isInternalMissing(r)) statusStr = '내부장부누락';

        String internalAmount = r.internalData != null ? _formatCurrency(r.internalData!.amount) : '-';
        String ntsAmount = r.ntsData != null ? _formatCurrency(r.ntsData!.amount) : '-';

        // 🌟 [고도화] 엑셀 전용 상세 비고 텍스트 생성 로직
        String detailRemark = '-';
        if (r.ntsData != null) {
          if (r.ntsData!.companyName.contains("건 합산)")) {
            // 합산 데이터인 경우: 팝업용 엔터(\n\n)를 " / " 기호로 바꿔서 엑셀 한 칸에 가로로 쭉 나열!
            detailRemark = r.ntsData!.remark.replaceAll('\n\n', ' / ');
          } else {
            // 일반 데이터인 경우: 단일 승인번호 출력
            detailRemark = r.ntsData!.authNum != '-' ? "승인: ${r.ntsData!.authNum}" : "-";
          }
        }

        // 🌟 9번째 열에 detailRemark 삽입
        sheet.appendRow([
          TextCellValue(statusStr),
          TextCellValue(r.internalData?.category ?? '-'),
          TextCellValue(r.internalData?.siteName ?? '-'),
          TextCellValue(r.internalData?.companyName ?? '(없음)'),
          TextCellValue(internalAmount),
          TextCellValue(r.ntsData?.companyName ?? '(없음)'),
          TextCellValue(ntsAmount),
          TextCellValue(r.memo),
          TextCellValue(detailRemark) // 🌟 추가됨
        ]);
      }
    }

    // 🌟 엑셀 시트 분류 시에도 슈퍼 패스를 적용합니다.
    buildSheet('1_전체보기', _results, 'name');
    buildSheet('2_완벽매칭', _results.where((r) => _isPerfect(r)).toList(), 'amount');
    buildSheet('3_확인요망', _results.where((r) => _isPartial(r)).toList(), 'amount');
    buildSheet('4_미발행_누락', _results.where((r) => _isMissing(r)).toList(), 'amount');
    buildSheet('5_금액오류', _results.where((r) => _isAmtError(r)).toList(), 'error');
    buildSheet('6_내부장부누락', _results.where((r) => _isInternalMissing(r)).toList(), 'amount');

    String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    if (excel.tables.keys.contains(defaultSheet) && defaultSheet != '1_전체보기') excel.delete(defaultSheet);

    var bytes = excel.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)..setAttribute("download", "국세청_대조결과_$_selectedYear년$_selectedMonth월.xlsx")..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length; if (b.isEmpty) return a.length;
    List<int> v0 = List<int>.generate(b.length + 1, (i) => i); List<int> v1 = List<int>.filled(b.length + 1, 0);
    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        int cost = (a[i] == b[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= b.length; j++) v0[j] = v1[j];
    }
    return v1[b.length];
  }

  List<String> _getKeywords(String text) {
    if (text == '-' || text.isEmpty) return [];
    return text.split(' ').where((w) => w.length >= 2).toList();
  }

  int _getKeywordMatchCount(String source, List<String> keywords) {
    if (keywords.isEmpty) return 0;
    int count = 0; String cleanSource = source.replaceAll(' ', '');
    for (var k in keywords) { if (cleanSource.contains(k)) count++; }
    return count;
  }

  double _calculateSimilarity(String a, String b) {
    String cleanA = _normalizeCompanyName(a); String cleanB = _normalizeCompanyName(b);
    int distance = _levenshteinDistance(cleanA, cleanB);
    int maxLength = max(cleanA.length, cleanB.length);
    if (maxLength == 0) return 1.0;
    return 1.0 - (distance / maxLength);
  }

  String _normalizeCompanyName(String name) {
    return name.replaceAll(RegExp(r'\s+|\(주\)|\㈜|주식회사|유한회사|\(유\)|\(합\)|\(재\)'), '').replaceAll(RegExp(r'[^\wㄱ-ㅎ가-힣]'), '').toLowerCase();
  }

  // =======================================================
  // 🌟 [최종 고도화] 투 패스(Two-Pass) + 합산 매칭(1.5회전) 엔진
  // =======================================================
  Future<void> _runAutoMatching() async {
    setState(() { _isMatching = true; });
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      List<MatchResult> tempResults = [];
      List<InvoiceData> remainingNts = List.from(_ntsList);
      List<InvoiceData> unmatchedInternal = List.from(_internalList);

      int loopCount = 0;

      // ---------------------------------------------------------
      // 🥇 [1회전] VIP 선발: 금액이 100% 일치하는 1:1 데이터 우선 매칭
      // ---------------------------------------------------------
      List<InvoiceData> pass1UnmatchedInternal = [];

      for (var internal in unmatchedInternal) {
        loopCount++;
        if (loopCount % 20 == 0) await Future.delayed(const Duration(milliseconds: 1));

        String iName = _normalizeCompanyName(internal.companyName);
        List<String> iSiteKeywords = _getKeywords(internal.siteName);

        var exactAmountCandidates = remainingNts.where((nts) {
          if (nts.amount != internal.amount) return false;
          String nName = _normalizeCompanyName(nts.companyName);
          double nameSim = _calculateSimilarity(internal.companyName, nts.companyName);
          return iName == nName || nName.contains(iName) || iName.contains(nName) || nameSim > 0.8;
        }).toList();

        if (exactAmountCandidates.isNotEmpty) {
          InvoiceData? bestNts; double maxScore = -1.0;
          for (var cand in exactAmountCandidates) {
            double currentScore = 0.0;
            String ntsFullText = (cand.itemName + cand.remark).replaceAll(' ', '');
            int keywordMatches = _getKeywordMatchCount(ntsFullText, iSiteKeywords);
            currentScore += (keywordMatches * 2.0) + _calculateSimilarity(internal.companyName, cand.companyName);
            if (currentScore > maxScore) { maxScore = currentScore; bestNts = cand; }
          }
          if (bestNts != null) {
            MatchResult result = MatchResult(internalData: internal, ntsData: bestNts);
            bool isStrictNameMatch = _normalizeCompanyName(bestNts.companyName) == iName;
            int keywordMatches = _getKeywordMatchCount((bestNts.itemName + bestNts.remark), iSiteKeywords);

            if (isStrictNameMatch || keywordMatches > 0) {
              result.status = MatchStatus.perfect;
              result.memo = keywordMatches > 0 ? "완벽 매칭 (현장 확인됨)" : "자동 매칭 완료";
            } else {
              result.status = MatchStatus.partial;
              result.memo = "금액 일치 / 업체명 유사";
            }
            tempResults.add(result);
            remainingNts.remove(bestNts);
            continue;
          }
        }
        pass1UnmatchedInternal.add(internal);
      }

      // ---------------------------------------------------------
      // 🌟 [1.5회전] 합산 매칭 (1:N): 쪼개진 국세청 계산서를 더해서 장부와 맞추기
      // ---------------------------------------------------------
      List<InvoiceData> pass1_5UnmatchedInternal = [];

      for (var internal in pass1UnmatchedInternal) {
        loopCount++;
        if (loopCount % 20 == 0) await Future.delayed(const Duration(milliseconds: 1));

        String iName = _normalizeCompanyName(internal.companyName);

        // 1. 이름이 비슷한 국세청 데이터들을 전부 끌어모읍니다. (속도를 위해 최대 15개까지만)
        var nameMatchedNts = remainingNts.where((nts) {
          String nName = _normalizeCompanyName(nts.companyName);
          double nameSim = _calculateSimilarity(internal.companyName, nts.companyName);
          return iName == nName || nName.contains(iName) || iName.contains(nName) || nameSim > 0.8;
        }).take(15).toList();

        if (nameMatchedNts.length >= 2) {
          List<InvoiceData> matchedSubset = [];
          int n = nameMatchedNts.length;

          // 2. 비트마스크를 활용하여 가능한 모든 경우의 수를 순식간에 더해봅니다.
          for (int i = 1; i < (1 << n); i++) {
            int currentSum = 0; List<InvoiceData> tempSubset = [];
            for (int j = 0; j < n; j++) {
              if ((i & (1 << j)) != 0) {
                currentSum += nameMatchedNts[j].amount;
                tempSubset.add(nameMatchedNts[j]);
              }
            }
            // 3. 더한 값이 우리 장부 금액과 1원까지 일치하면 빙고!
            if (currentSum == internal.amount) {
              matchedSubset = tempSubset; break;
            }
          }

          if (matchedSubset.length >= 2) {
            // 🌟 4. 합산된 가상 영수증 생성 (글자 수 제한을 없애서 날짜 짤림 현상 완벽 제거!)
            String combinedDates = matchedSubset.map((e) => e.publishDate).toSet().join(', ');

            String detailedRemark = matchedSubset.map((e) {
              // 🌟 이미 정제된 publishDate를 그대로 사용하여 [익월] 태그가 유지되게 합니다.
              return "[${e.publishDate}] ${_formatCurrency(e.amount)}원 (승인:${e.authNum})";
            }).join('\n\n');

            InvoiceData virtualNts = InvoiceData(
              category: '국세청자료',
              companyName: "${matchedSubset.first.companyName} (${matchedSubset.length}건 합산)",
              amount: internal.amount,
              publishDate: combinedDates,
              bizNum: matchedSubset.first.bizNum,
              repName: matchedSubset.first.repName,
              itemName: matchedSubset.map((e) => e.itemName).join(' / '),
              remark: detailedRemark, // 🌟 상세 정보가 담긴 텍스트를 비고에 삽입!
              authNum: '합산데이터 (비고란 참조)',
            );

            MatchResult result = MatchResult(internalData: internal, ntsData: virtualNts);
            result.status = MatchStatus.partial; // 🌟 대표님 요청: 확인 요망으로 보냄!
            result.memo = "⚠️ ${matchedSubset.length}건 합산 일치 (내역 확인요망)";
            tempResults.add(result);

            // 🌟 사용된 국세청 데이터 조각들은 남은 목록에서 영구 제거
            for (var match in matchedSubset) remainingNts.remove(match);
            continue;
          }
        }
        pass1_5UnmatchedInternal.add(internal);
      }

      // ---------------------------------------------------------
      // 🥈 [2회전] 패자부활전: 금액은 틀리지만 상호명이 비슷한 데이터 (금액 오류)
      // ---------------------------------------------------------
      List<InvoiceData> pass2UnmatchedInternal = [];

      for (var internal in pass1_5UnmatchedInternal) { // 🌟 1.5회전에서 살아남은 애들만 투입
        loopCount++;
        if (loopCount % 20 == 0) await Future.delayed(const Duration(milliseconds: 1));

        String iName = _normalizeCompanyName(internal.companyName);
        List<String> iSiteKeywords = _getKeywords(internal.siteName);

        var candidates = remainingNts.where((nts) {
          String nName = _normalizeCompanyName(nts.companyName);
          double nameSim = _calculateSimilarity(internal.companyName, nts.companyName);
          return iName == nName || nName.contains(iName) || iName.contains(nName) || nameSim > 0.8;
        }).toList();

        if (candidates.isNotEmpty) {
          InvoiceData? bestNts; double maxScore = -1.0;
          for (var cand in candidates) {
            double currentScore = 0.0;
            String ntsFullText = (cand.itemName + cand.remark).replaceAll(' ', '');
            int keywordMatches = _getKeywordMatchCount(ntsFullText, iSiteKeywords);
            currentScore += (keywordMatches * 2.0) + _calculateSimilarity(internal.companyName, cand.companyName);
            if (currentScore > maxScore) { maxScore = currentScore; bestNts = cand; }
          }

          if (bestNts != null) {
            MatchResult result = MatchResult(internalData: internal, ntsData: bestNts);
            result.status = MatchStatus.mismatch;
            result.memo = "금액 불일치 (현장/업체 유사)";
            tempResults.add(result);
            remainingNts.remove(bestNts);
            continue;
          }
        }
        pass2UnmatchedInternal.add(internal);
      }

      // ---------------------------------------------------------
      // 🥉 [3회전] 잔여 데이터 정리 (미발행/누락 및 내부장부누락)
      // ---------------------------------------------------------
      for (var internal in pass2UnmatchedInternal) {
        tempResults.add(MatchResult(internalData: internal, status: MatchStatus.mismatch, memo: "국세청 매입내역 없음 (미발행/누락)"));
      }
      for (var nts in remainingNts) {
        tempResults.add(MatchResult(ntsData: nts, status: MatchStatus.mismatch, memo: "내부 장부 누락 (미등록 지출)"));
      }

      setState(() {
        _results = tempResults;
        _sortResults();
        _isMatched = true;
      });

    } catch (e) {
      _showNoticePopup("AI 분석 오류", "데이터를 대조하는 중 알 수 없는 오류가 발생했습니다.\n\n상세 에러: $e");
    } finally {
      setState(() { _isMatching = false; });
    }
  }

  void _showNoticePopup(String title, String message) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.orange), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
          content: Text(message, style: const TextStyle(height: 1.5, fontSize: 14)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
    );
  }

  void _showErrorSnackBar(String message) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor)); }
  void _showSuccessSnackBar(String message) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green)); }

  void _onSort(int columnIndex, bool ascending) {
    setState(() { _sortColumnIndex = columnIndex; _sortAscending = ascending; _sortResults(); });
  }

  // =======================================================
  // 🌟 [최종 고도화] AI 분석결과 텍스트별 랭킹(우선순위) 부여 함수
  // =======================================================
  int _getMemoPriority(String memo) {
    if (memo.contains("[수동:")) return 1;
    if (memo.contains("완벽 매칭")) return 2;
    if (memo.contains("자동 매칭 완료")) return 3;
    if (memo.contains("금액 일치")) return 4;
    if (memo.contains("합산 일치")) return 5; // 🌟 새로 추가됨 (확인요망 중 최우선 노출)
    if (memo.contains("금액 불일치")) return 6;
    if (memo.contains("확인 요망")) return 7;
    if (memo.contains("내부 장부 누락")) return 8;
    return 9;
  }

  // =======================================================
  // 🌟 [최종 고도화] 5번 인덱스 스마트 정렬 & 3번 인덱스 빈칸 강제 하단 고정
  // =======================================================
  void _sortResults() {
    _results.sort((a, b) {
      if (_sortColumnIndex == 0) { int cmp = b.status.index.compareTo(a.status.index); return _sortAscending ? cmp : -cmp; }
      else if (_sortColumnIndex == 1) { String aVal = a.internalData?.category ?? 'z'; String bVal = b.internalData?.category ?? 'z'; return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal); }
      else if (_sortColumnIndex == 2) { String aVal = a.internalData?.siteName ?? ''; String bVal = b.internalData?.siteName ?? ''; return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal); }
      else if (_sortColumnIndex == 3) {
        String aName = a.internalData?.companyName ?? '';
        String bName = b.internalData?.companyName ?? '';

        // 🌟 [고도화] 상호명이 아예 없는 빈칸 데이터는 오름차순/내림차순 상관없이 무조건 맨 밑으로 던집니다!
        bool aEmpty = aName.trim().isEmpty;
        bool bEmpty = bName.trim().isEmpty;

        if (aEmpty && !bEmpty) return 1;  // a가 비어있으면 순서를 뒤로 미룸
        if (!aEmpty && bEmpty) return -1; // b가 비어있으면 순서를 뒤로 미룸

        return _sortAscending ? aName.compareTo(bName) : bName.compareTo(aName);
      }
      else if (_sortColumnIndex == 4) { int aVal = a.internalData?.amount ?? a.ntsData?.amount ?? 0; int bVal = b.internalData?.amount ?? b.ntsData?.amount ?? 0; return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal); }
      else if (_sortColumnIndex == 5) {
        int rankA = _getMemoPriority(a.memo);
        int rankB = _getMemoPriority(b.memo);
        int cmp = rankA.compareTo(rankB);
        if (cmp == 0) cmp = a.memo.compareTo(b.memo);
        return _sortAscending ? cmp : -cmp;
      }
      return 0;
    });
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  void _showNtsDetails(InvoiceData data) {
    bool hasNextMonth = data.publishDate.contains('[익월]'); // 🌟 팝업에서도 익월 감지

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(children: const [Icon(Icons.receipt_long, color: Colors.blue), SizedBox(width: 8), Text("국세청 세금계산서 상세", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow("상호명", data.companyName),
                _buildDetailRow("승인번호", data.authNum),
                _buildDetailRow("사업자번호", data.bizNum),
                _buildDetailRow("대표자명", data.repName),
                _buildDetailRow("주소", data.address), _buildDetailRow("이메일", data.email), _buildDetailRow("구분", data.receiptType),
                _buildDetailRow("발행일자", data.publishDate, valueColor: hasNextMonth ? Colors.redAccent : null), // 🌟 익월이면 발행일자를 빨간색으로!
                _buildDetailRow("품목명", data.itemName), _buildDetailRow("비고", data.remark),
                const Divider(height: 24), _buildDetailRow("발행금액(합계)", "${_formatCurrency(data.amount)}원", isHighlight: true),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기", style: TextStyle(fontWeight: FontWeight.bold)))],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        // 🌟 valueColor 옵션을 추가하여 특정 글자를 빨갛게 칠할 수 있도록 확장
        Expanded(child: Text(value, style: TextStyle(fontWeight: isHighlight || valueColor != null ? FontWeight.bold : FontWeight.w500, color: valueColor ?? (isHighlight ? Colors.blue : Colors.black87), fontSize: 14))),
      ]),
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
              const Icon(Icons.desktop_mac, size: 80, color: Colors.black26), const SizedBox(height: 24),
              const Text("PC 환경 최적화 메뉴", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain)), const SizedBox(height: 12),
              const Text("엑셀 업로드 및 AI 데이터 대조 작업은\nPC 웹 브라우저 환경에서 이용해 주세요.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.5, color: AppTheme.textSub)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24), color: Colors.white,
            child: Wrap(
              spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("국세청(계산서) 대조 시스템", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain)), const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<int>(
                                value: _selectedYear, underline: const SizedBox(),
                                items: List.generate(10, (index) => DropdownMenuItem(value: 2020 + index, child: Text("${2020 + index}년", style: const TextStyle(fontWeight: FontWeight.bold)))),
                                onChanged: (val) { if(val!=null) setState(() { _selectedYear = val; _onDateChanged(); }); },
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: _selectedMonth, underline: const SizedBox(),
                                items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text("${index + 1}월", style: const TextStyle(fontWeight: FontWeight.bold)))),
                                onChanged: (val) { if(val!=null) setState(() { _selectedMonth = val; _onDateChanged(); }); },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text("우측 버튼을 통해 양쪽 데이터를 업로드하면 AI가 지정된 연/월에 맞춰 지능적으로 분석합니다.", style: TextStyle(color: AppTheme.textSub, fontSize: 13)),
                  ],
                ),
                Wrap(
                  spacing: 12, runSpacing: 12, alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildUploadBtn(isLoaded: _isInternalLoaded, title: "우리 장부", fileName: _internalFileName, onPressed: _uploadInternalData),
                    _buildUploadBtn(isLoaded: _isNtsLoaded, title: "국세청 파일", fileName: _ntsFileName, onPressed: _uploadNtsData),
                    // 🌟 [고도화 반영] 빙글빙글 스피너가 들어간 AI 대조 버튼!
                    ElevatedButton.icon(
                      onPressed: (_isInternalLoaded && _isNtsLoaded && !_isMatching)
                          ? () async { await _runAutoMatching(); }
                          : null,
                      icon: _isMatching
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.smart_toy, size: 18, color: Colors.white),
                      label: Text(_isMatching ? "AI 대조 분석 중..." : "AI 대조 실행", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isInternalLoaded && _isNtsLoaded) ? AppTheme.primaryColor : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          if (_isMatched) _buildSummaryDashboard(),

          Expanded(child: !_isMatched ? _buildReadyState() : _buildResultTable()),
        ],
      ),
    );
  }

  Widget _buildUploadBtn({required bool isLoaded, required String title, required String fileName, required VoidCallback onPressed}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        OutlinedButton.icon(onPressed: onPressed, icon: Icon(isLoaded ? Icons.check_circle : Icons.upload_file, color: isLoaded ? Colors.green : AppTheme.primaryColor), label: Text(isLoaded ? "$title 로드완료" : "$title 업로드"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
        if (fileName.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(fileName, style: const TextStyle(fontSize: 11, color: Colors.grey))),
      ],
    );
  }

  Widget _buildSummaryDashboard() {
    int totalInternal = _internalList.length; int totalNts = _ntsList.length;
    int perfect = _results.where((r) => _isPerfect(r)).length;
    int partial = _results.where((r) => _isPartial(r)).length;
    int missingNts = _results.where((r) => _isMissing(r)).length;
    int mismatchAmt = _results.where((r) => _isAmtError(r)).length;
    int internalMissing = _results.where((r) => _isInternalMissing(r)).length; // 🌟 개수 카운트 추가

    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Wrap(
        spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 12, runSpacing: 8,
            children: [
              _summaryChip("전체보기", "", Colors.black87, 'all', icon: Icons.list), _summaryChip("우리 장부", "$totalInternal건", Colors.blue, 'all'), _summaryChip("국세청 데이터", "$totalNts건", Colors.indigo, 'all'),
              Container(width: 1, height: 20, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 4)),
              _summaryChip("완벽 매칭", "$perfect건", Colors.green, 'perfect', icon: Icons.check_circle), _summaryChip("확인 요망", "$partial건", Colors.orange, 'partial', icon: Icons.warning_rounded), _summaryChip("미발행/누락", "$missingNts건", Colors.red, 'missing', icon: Icons.error),
              if (mismatchAmt > 0) _summaryChip("금액 오류", "$mismatchAmt건", Colors.redAccent, 'amount_error', icon: Icons.money_off),
              if (internalMissing > 0) _summaryChip("내부장부누락", "$internalMissing건", Colors.purple, 'internal_missing', icon: Icons.post_add), // 🌟 전용 버튼 추가 (보라색 아이콘)
            ],
          ),
          ElevatedButton.icon(
            onPressed: _downloadExcel, icon: const Icon(Icons.download, size: 18, color: Colors.white), label: const Text("엑셀 다운로드", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          )
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String count, Color baseColor, String filterValue, {IconData? icon}) {
    bool isSelected = _currentFilter == filterValue;
    return InkWell(
      onTap: () { setState(() { _currentFilter = filterValue; }); },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? baseColor : baseColor.withValues(alpha:0.05), borderRadius: BorderRadius.circular(50), border: Border.all(color: isSelected ? baseColor : baseColor.withValues(alpha:0.3), width: isSelected ? 2 : 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: isSelected ? Colors.white : baseColor), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : baseColor, fontWeight: FontWeight.bold)),
          if (count.isNotEmpty) ...[const SizedBox(width: 8), Text(count, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : baseColor, fontWeight: FontWeight.w900))]
        ]),
      ),
    );
  }

  Widget _buildReadyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon((_isInternalLoaded && _isNtsLoaded) ? Icons.task_alt : Icons.cloud_upload_outlined, size: 80, color: (_isInternalLoaded && _isNtsLoaded) ? Colors.green.withValues(alpha:0.5) : Colors.black12), const SizedBox(height: 16),
          Text((_isInternalLoaded && _isNtsLoaded) ? "데이터 분석 준비 완료!\n'AI 대조 실행' 버튼을 눌러주세요." : "우측 상단에서 🌟연/월을 먼저 선택🌟하신 후,\n장부와 국세청 파일을 업로드해주세요.", textAlign: TextAlign.center, style: TextStyle(color: (_isInternalLoaded && _isNtsLoaded) ? AppTheme.textMain : AppTheme.textSub, fontSize: 16, height: 1.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // =======================================================
  // 🌟 [최종 고도화] 화면에 딱 맞게 배분하는 가중치(Flex)
  // =======================================================
  final int _flexStatus = 10;
  final int _flexCategory = 12;
  final int _flexSite = 20;
  final int _flexComp = 40;       // (공간 확보를 위해 조금 줄임)
  final int _flexAmount = 18;
  final int _flexAi = 28;
  final int _flexMove = 14;       // 🌟 [추가] 상태 변경(보내기) 칸
  final int _flexAction = 14;

  Widget _buildResultTable() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      width: double.infinity,
      child: Column(
        children: [
          Container(
            color: Colors.grey[100],
            child: Row(
              children: [
                _buildHeaderCell("상태", _flexStatus, isStatusHeader: true),
                _buildHeaderCell("업종", _flexCategory, isCategoryHeader: true),
                _buildHeaderCell("현장명", _flexSite, isSiteHeader: true),
                _buildHeaderCell("대조 내역(우리장부 vs 국세청자료)", _flexComp, index: 3),
                _buildHeaderCell("발행금액", _flexAmount, index: 4),
                _buildHeaderCell("AI 분석결과", _flexAi, index: 5),
                _buildHeaderCell("보내기", _flexMove), // 🌟 [추가됨] 보내기 헤더
                _buildHeaderCell("비고", _flexAction, isLast: true),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredResults.length,
              itemBuilder: (context, index) => _buildCustomRow(_filteredResults[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, int flexValue, {int? index, bool isStatusHeader = false, bool isCategoryHeader = false, bool isSiteHeader = false, bool isLast = false}) {
    Widget headerChild = Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMain), textAlign: TextAlign.center));

    if (isStatusHeader && _currentFilter == 'all') {
      headerChild = PopupMenuButton<String>(
        tooltip: "상태 필터", onSelected: (val) => setState(() => _currentFilter = val),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const Icon(Icons.arrow_drop_down, size: 16)]),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'perfect', child: Text("완벽 매칭")),
          const PopupMenuItem(value: 'partial', child: Text("확인 요망")),
          const PopupMenuItem(value: 'missing', child: Text("미발행/누락")),
          const PopupMenuItem(value: 'amount_error', child: Text("금액 오류")),
          const PopupMenuItem(value: 'internal_missing', child: Text("내부장부누락")), // 🌟 헤더 필터 추가
        ],
      );
    } else if (isCategoryHeader) {
      // 🌟 [고도화] 업종 목록 추출 후 ㄱㄴㄷ 정렬 & '기타'는 무조건 맨 아래로
      List<String> sortedCategories = _results.map((e) => e.internalData?.category ?? '-').toSet().toList();
      sortedCategories.sort((a, b) {
        if (a == '기타') return 1;  // '기타'는 무조건 b보다 뒤로 보냄
        if (b == '기타') return -1; // '기타'는 무조건 a보다 뒤로 보냄
        return a.compareTo(b);     // 나머지는 평범하게 가나다순 정렬
      });

      headerChild = PopupMenuButton<String>(
        tooltip: "업종 필터", onSelected: (val) => setState(() => _filterCategory = val),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: Text(_filterCategory == 'all' ? title : _filterCategory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _filterCategory != 'all' ? Colors.blue : Colors.black), overflow: TextOverflow.ellipsis)), const Icon(Icons.arrow_drop_down, size: 16)]),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'all', child: Text("전체 업종 (해제)")), // 최상단 고정
          ...sortedCategories.map((c) => PopupMenuItem(value: c, child: Text(c))) // 정렬된 목록
        ],
      );
    } else if (isSiteHeader) {
      headerChild = _isSiteSearchActive
          ? TextField(controller: _siteSearchController, decoration: InputDecoration(hintText: "검색...", suffixIcon: IconButton(icon: const Icon(Icons.close, size: 14), onPressed: () => setState(() { _siteSearchController.clear(); _searchSiteQuery = ''; _isSiteSearchActive = false; }))), style: const TextStyle(fontSize: 12), onChanged: (val) => setState(() => _searchSiteQuery = val))
          : InkWell(onTap: () => setState(() => _isSiteSearchActive = true), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _searchSiteQuery.isNotEmpty ? Colors.blue : Colors.black)), const Icon(Icons.search, size: 14, color: Colors.grey)]));
    } else if (index != null) {
      headerChild = InkWell(
        onTap: () => _onSort(index, _sortColumnIndex == index ? !_sortAscending : true),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)), if (_sortColumnIndex == index) Icon(_sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 16, color: Colors.blue)]),
      );
    }

    return Expanded(flex: flexValue, child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4), decoration: BoxDecoration(border: Border(right: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade300))), child: headerChild));
  }

  Widget _buildCustomRow(MatchResult result) {
    // 🌟 [고도화] 색상 및 아이콘 지정 (내부장부누락은 보라색 계열로 차별화)
    Color bgColor = Colors.transparent; IconData statusIcon = Icons.help_outline; Color statusColor = Colors.grey;
    if (_isPerfect(result)) { bgColor = Colors.green.withValues(alpha: 0.05); statusColor = Colors.green; statusIcon = Icons.check_circle; }
    else if (_isPartial(result)) { bgColor = Colors.orange.withValues(alpha: 0.05); statusColor = Colors.orange; statusIcon = Icons.warning_rounded; }
    else if (_isMissing(result) || _isAmtError(result)) { bgColor = Colors.red.withValues(alpha: 0.05); statusColor = Colors.redAccent; statusIcon = Icons.error; }
    else if (_isInternalMissing(result)) { bgColor = Colors.purple.withValues(alpha: 0.05); statusColor = Colors.purple; statusIcon = Icons.post_add; } // 🌟 보라색 추가

    // 🌟 [최종 고도화] 현장명 핀셋 추출 (불필요한 단어 싹 제거)
    String siteMatchText = ""; Color siteMatchColor = Colors.grey;
    if (result.internalData != null && result.ntsData != null) {
      String internalSite = result.internalData!.siteName.replaceAll(' ', '');
      if (internalSite != '-' && internalSite.isNotEmpty) {
        String ntsItem = result.ntsData!.itemName.trim();
        String ntsRemark = result.ntsData!.remark.trim();
        String ntsFullRaw = [if (ntsItem != '-' && ntsItem.isNotEmpty) ntsItem, if (ntsRemark != '-' && ntsRemark.isNotEmpty) ntsRemark].join(' ').trim();
        String ntsClean = ntsFullRaw.replaceAll(' ', '');

        if (ntsClean.contains(internalSite)) {
          siteMatchText = "일치"; siteMatchColor = Colors.green;
        } else if (ntsFullRaw.isNotEmpty) {
          // 🌟 1. 국세청 비고란 텍스트를 띄어쓰기 기준으로 쪼갭니다.
          List<String> ntsWords = ntsFullRaw.split(RegExp(r'\s+'));
          List<String> matchedWords = [];

          // 🌟 2. 쪼개진 각 단어(어절)마다 우리 현장명과 비슷한지 검사합니다.
          for (String word in ntsWords) {
            bool isMatch = false;
            if (internalSite.length >= 2) {
              for (int i = 0; i <= internalSite.length - 2; i++) {
                if (word.contains(internalSite.substring(i, i + 2))) {
                  isMatch = true; break;
                }
              }
            } else if (internalSite.isNotEmpty && word.contains(internalSite)) {
              isMatch = true;
            }
            // 비슷하게 걸린 단어만 통과시킵니다. ("12월"이나 "소방"은 여기서 탈락!)
            if (isMatch) matchedWords.add(word);
          }

          // 🌟 3. 걸러진 단어만 군더더기 없이 출력합니다.
          if (matchedWords.isNotEmpty) {
            siteMatchText = matchedWords.join(' '); // "도담오피스텔"만 남음!
            siteMatchColor = Colors.redAccent;
          } else {
            siteMatchText = "기재안됨";
            siteMatchColor = Colors.redAccent;
          }
        } else {
          siteMatchText = "기재안됨";
          siteMatchColor = Colors.redAccent;
        }
      }
    }

    Widget flexCell(int flexValue, Widget child, {Alignment alignment = Alignment.centerLeft, bool isLast = false}) => Expanded(flex: flexValue, child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), decoration: BoxDecoration(border: Border(right: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade200))), alignment: alignment, child: child));

    // 🌟 [고도화] 5개의 탭을 모두 오갈 수 있는 슈퍼 패스 수동이동 버튼
    Widget moveButton = PopupMenuButton<String>(
      tooltip: "다른 탭으로 보내기",
      onSelected: (String action) {
        setState(() {
          result.memo = result.memo.replaceAll(RegExp(r'\s*\[수동:.*?\]'), '').trim();
          result.memo = "${result.memo} $action";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(4), color: Colors.blue.shade50),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [Text("이동", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)), Icon(Icons.arrow_drop_down, size: 14, color: Colors.blue)]),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: "[수동:완벽매칭]", child: Text("✅ 완벽 매칭으로", style: TextStyle(fontSize: 12))),
        const PopupMenuItem(value: "[수동:확인요망]", child: Text("⚠️ 확인 요망으로", style: TextStyle(fontSize: 12))),
        const PopupMenuItem(value: "[수동:미발행]", child: Text("🚨 미발행/누락으로", style: TextStyle(fontSize: 12))),
        const PopupMenuItem(value: "[수동:금액오류]", child: Text("💸 금액 오류로", style: TextStyle(fontSize: 12))),
        const PopupMenuItem(value: "[수동:장부누락]", child: Text("📝 내부장부 누락으로", style: TextStyle(fontSize: 12))), // 🌟 5번째 버튼 추가
      ],
    );

    return Container(
      decoration: BoxDecoration(color: bgColor, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: IntrinsicHeight(
        child: Row(
          children: [
            flexCell(_flexStatus, Icon(statusIcon, color: statusColor), alignment: Alignment.center),
            flexCell(_flexCategory, Text(result.internalData?.category ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub), textAlign: TextAlign.center), alignment: Alignment.center),
            flexCell(_flexSite, Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(result.internalData?.siteName ?? '-', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              if (siteMatchText.isNotEmpty) Text("↳ $siteMatchText", style: TextStyle(fontSize: 10, color: siteMatchColor, fontWeight: FontWeight.bold)),
            ])),
            flexCell(_flexComp, _buildCompanyNameCell(result)),
            flexCell(_flexAmount, _buildAmountCell(result), alignment: Alignment.center),
            flexCell(_flexAi, Text(result.memo, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold))),
            flexCell(_flexMove, Center(child: moveButton), alignment: Alignment.center), // 🌟 [추가됨] 화면에 '이동' 버튼 배치
            flexCell(_flexAction, Center(child: result.ntsData != null ? OutlinedButton(onPressed: () => _showNtsDetails(result.ntsData!), style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)), child: const Text("자세히", style: TextStyle(fontSize: 11))) : const SizedBox.shrink()), isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyNameCell(MatchResult result) {
    bool isNameDiff = (result.internalData?.companyName != result.ntsData?.companyName);
    bool hasNextMonth = result.ntsData?.publishDate.contains('[익월]') ?? false; // 🌟 익월 태그 감지

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), color: Colors.blue.withValues(alpha:0.1), child: const Text("우리", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold))), const SizedBox(width: 8), Expanded(child: Text(result.internalData?.companyName ?? '(없음)', style: const TextStyle(fontWeight: FontWeight.w500, height: 1.5), overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 6),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ // 🌟 여러 줄을 대비해 위쪽 정렬
        Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), color: Colors.red.withValues(alpha:0.1), child: const Text("국세", style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Expanded(
            child: RichText(
              // 🌟 overflow: TextOverflow.ellipsis 속성을 과감히 지워서 4건 이상 합쳐져도 글자가 아랫줄로 넘어가며 전부 보이게 만듭니다!
                text: TextSpan(children: [
                  TextSpan(text: result.ntsData?.companyName ?? '(없음)', style: TextStyle(fontSize: 14, height: 1.5, color: (isNameDiff && result.ntsData != null) ? Colors.red : Colors.black87)),
                  if (result.ntsData != null) TextSpan(
                      text: "  [작성일: ${result.ntsData!.publishDate}]",
                      style: TextStyle(fontSize: 12, color: hasNextMonth ? Colors.redAccent : Colors.black54, fontWeight: hasNextMonth ? FontWeight.bold : FontWeight.normal) // 🌟 익월이면 빨간색 굵은 글씨로 강조
                  )
                ])
            )
        )
      ]),
    ]);
  }

  Widget _buildAmountCell(MatchResult result) {
    bool isAmountDiff = (result.internalData?.amount != result.ntsData?.amount);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(result.internalData != null ? "${_formatCurrency(result.internalData!.amount)}원" : '-', style: const TextStyle(fontWeight: FontWeight.w500, height: 1.5)),
          const SizedBox(height: 6),
          Text(result.ntsData != null ? "${_formatCurrency(result.ntsData!.amount)}원" : '-', style: TextStyle(color: (isAmountDiff && result.ntsData != null) ? Colors.red : Colors.black87, fontWeight: isAmountDiff ? FontWeight.bold : FontWeight.w500, height: 1.5)),
        ]);
  }
}