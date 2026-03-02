// [파일 위치: lib/pages/field/field_schedule_page.dart]
// 현장업무지원 / 일정관리
// 1. [긴급 수정] 'TextSpan' 이름 충돌 해결 (import 구문에 hide TextSpan 추가)
// 2. [UI 개선] 리스트 카드 디자인 변경 (제목+작성날짜+기간+작성시간 한 줄 표시)
// 3. [기능] 일정 등록 시 '시작일' ~ '종료일' 기간 설정 기능
// 4. [UI] 색상 라벨 10개 확장 (스크롤)

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // ✅ [추가] 반응형 UI 계산용
import '../../services/notification_service.dart'; // ✅ 추가
import 'dart:async'; // ✅ [추가] StreamSubscription(수도꼭지 잠금) 사용을 위해 추가
import '../../main.dart'; // 🌟 [고도화 추가] GlobalUserState(스마트 캐싱)를 가져옵니다.

// ✅ [핵심 수정] TextSpan 충돌 방지를 위해 hide에 TextSpan 추가
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:universal_html/html.dart' as html;

// ✅ 디자인 시스템 import
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class FieldSchedulePage extends StatefulWidget {
  const FieldSchedulePage({super.key});

  @override
  FieldSchedulePageState createState() => FieldSchedulePageState(); // ✅ 여기 _ 제거
}

class FieldSchedulePageState extends State<FieldSchedulePage> {
  Key _refreshKey = UniqueKey();

  // 🌟 [추가됨] 검색어 저장 및 텍스트 컨트롤러
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  void refreshData() { // ✅ 외부(main)에서 호출할 함수
    if (!mounted) return;
    setState(() {
      _refreshKey = UniqueKey(); // 키를 바꿔서 화면 전체 강제 갱신
      _fetchSchedules();         // 데이터 다시 불러오기
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("일정 데이터를 최신화했습니다."), duration: Duration(milliseconds: 800))
    );
  }

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<dynamic>> _events = {};
  bool _isTeamView = false;

  StreamSubscription<QuerySnapshot>? _scheduleSubscription; // 🌟 [버그 수정] 켜져있는 스트림(수도꼭지)을 기억할 변수

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchSchedules();
  }

  // 🌟 [버그 수정] 화면이 꺼질 때 수도꼭지도 완벽히 잠가줍니다.
  @override
  void dispose() {
    _scheduleSubscription?.cancel();
    super.dispose();
  }

  void _fetchSchedules() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Query query = FirebaseFirestore.instance.collection('schedules');

    if (!_isTeamView) {
      query = query.where('uid', isEqualTo: user.uid);
    }

    // 🌟 [핵심 버그 수정] 기존에 켜져있던 수도꼭지가 있다면 반드시 먼저 잠급니다! (탭 전환 꼬임 방지)
    _scheduleSubscription?.cancel();

    _scheduleSubscription = query.snapshots().listen((snapshot) {
      Map<DateTime, List<dynamic>> newEvents = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        DateTime start;
        if (data['startDate'] != null) {
          start = (data['startDate'] as Timestamp).toDate();
        } else {
          start = (data['date'] as Timestamp).toDate();
        }

        DateTime end;
        if (data['endDate'] != null) {
          end = (data['endDate'] as Timestamp).toDate();
        } else {
          end = start;
        }

        DateTime currentDay = DateTime.utc(start.year, start.month, start.day);
        DateTime lastDay = DateTime.utc(end.year, end.month, end.day);

        // 기간만큼 반복하며 모든 날짜에 일정 꽂아주기
        while (!currentDay.isAfter(lastDay)) {
          if (newEvents[currentDay] == null) newEvents[currentDay] = [];
          newEvents[currentDay]!.add({...data, 'id': doc.id});
          currentDay = currentDay.add(const Duration(days: 1));
        }
      }
      if (mounted) setState(() => _events = newEvents);
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _toggleViewMode(bool isTeam) {
    if (_isTeamView == isTeam) return;
    setState(() => _isTeamView = isTeam);
    _fetchSchedules();
  }

  Future<void> _exportToExcel() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("출력할 날짜를 선택해주세요.")));
      return;
    }

    DateTime dateKey = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    List<dynamic> targetEvents = List.from(_events[dateKey] ?? []);

    if (targetEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("해당 날짜에 출력할 일정이 없습니다.")));
      return;
    }

    targetEvents.sort((a, b) {
      if (_isTeamView) {
        String authorA = a['author'] ?? '';
        String authorB = b['author'] ?? '';
        int nameCompare = authorA.compareTo(authorB);
        if (nameCompare != 0) return nameCompare;
      }
      Timestamp timeA = a['startTime'] ?? Timestamp.now();
      Timestamp timeB = b['startTime'] ?? Timestamp.now();
      return timeA.compareTo(timeB);
    });

    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    List<String> headers = ['담당자(직책)', '제목', '건물명', '기간/일시', '시간', '최초 내용', '수정 로그'];
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center, backgroundColorHex: ExcelColor.fromHexString("#E0E0E0"));
    }

    for (int i = 0; i < targetEvents.length; i++) {
      var event = targetEvents[i];
      DateTime startTime = (event['startTime'] as Timestamp).toDate();
      DateTime endTime = (event['endTime'] as Timestamp).toDate();

      DateTime startD = (event['startDate'] as Timestamp?)?.toDate() ?? (event['date'] as Timestamp).toDate();
      DateTime endD = (event['endDate'] as Timestamp?)?.toDate() ?? startD;
      String dateStr = DateFormat('yyyy-MM-dd').format(startD);
      if (!DateUtils.isSameDay(startD, endD)) {
        dateStr += " ~ ${DateFormat('MM-dd').format(endD)}";
      }

      List<dynamic> logs = event['workLogs'] ?? [];
      String firstContent = "";
      List<String> history = [];

      if (logs.isNotEmpty) {
        var firstLog = logs.first;
        firstContent = "[${firstLog['author']}] ${firstLog['text']}";
        if (logs.length > 1) {
          for (int j = 1; j < logs.length; j++) {
            history.add("[${logs[j]['author']}] ${logs[j]['text']}");
          }
        }
      } else {
        firstContent = event['content'] ?? "";
      }

      List<CellValue> rowData = [
        TextCellValue(event['author'] ?? '미상'),
        TextCellValue(event['title'] ?? ''),
        TextCellValue(event['buildingName'] ?? '-'),
        TextCellValue(dateStr),
        TextCellValue("${DateFormat('HH:mm').format(startTime)} ~ ${DateFormat('HH:mm').format(endTime)}"),
        TextCellValue(firstContent),
      ];

      for (var hist in history) {
        rowData.add(TextCellValue(hist));
      }

      for (int col = 0; col < rowData.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1)).value = rowData[col];
      }
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      String viewType = _isTeamView ? "팀전체" : "나의일정";
      String dateStr = DateFormat('yyyyMMdd').format(_selectedDay!);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'SM일정_${viewType}_$dateStr.xlsx';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }

  void _showScheduleDialog({Map<String, dynamic>? eventData}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddScheduleDialog(
        initialDate: _selectedDay ?? DateTime.now(),
        existingData: eventData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _refreshKey,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("📅 일정 관리", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.download, color: Colors.green),
            tooltip: "엑셀 다운로드",
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: ToggleButtons(
              constraints: const BoxConstraints(minHeight: 32, minWidth: 70),
              isSelected: [!_isTeamView, _isTeamView],
              onPressed: (index) => _toggleViewMode(index == 1),
              borderRadius: BorderRadius.circular(4),
              selectedColor: Colors.white,
              fillColor: AppTheme.primaryColor,
              color: AppTheme.textSub,
              borderColor: AppTheme.borderColor,
              selectedBorderColor: AppTheme.primaryColor,
              children: const [
                Text("내 일정", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text("팀 전체", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: TableCalendar(
              locale: 'ko_KR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              // 🌟 [고도화 1] 요일 글씨 하단부 잘림 완벽 방지 (높이를 넉넉하게 32로 늘려줌)
              daysOfWeekHeight: 32,
              // 🌟 [고도화 2] 달력 접기/펼치기 활성화 설정
              availableCalendarFormats: const {
                CalendarFormat.month: '펼치기 ∨', // 주간 뷰일 때 보이는 버튼 글씨
                CalendarFormat.week: '접기 ∧',   // 월간 뷰일 때 보이는 버튼 글씨
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              headerStyle: HeaderStyle(
                formatButtonVisible: true, // 🌟 숨겨져 있던 접기/펼치기 버튼 노출
                formatButtonShowsNext: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: AppTheme.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                formatButtonPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppTheme.textSub),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppTheme.textSub),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                ),
                selectedTextStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                weekendTextStyle: const TextStyle(color: AppTheme.errorColor),
                defaultTextStyle: const TextStyle(color: AppTheme.textMain),
                markerDecoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              ),
              calendarBuilders: CalendarBuilders(
                // 🌟 [고도화 2] 달력이 접혔을 때는 전체 날짜, 펼쳐졌을 때는 년월만 표시
                headerTitleBuilder: (context, day) {
                  final text = _calendarFormat == CalendarFormat.week
                      ? DateFormat('yyyy년 M월 d일', 'ko_KR').format(_selectedDay ?? day) // 주간(접힘): 오늘/선택된 날짜 전체
                      : DateFormat('yyyy년 M월', 'ko_KR').format(day); // 월간(펼침): 년월만 표시

                  return Center(
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                  );
                },
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox();
                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...events.take(4).map((event) {
                          int colorCode = (event as Map<String, dynamic>)['colorCode'] ?? 0xFF1A233A;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Color(colorCode)),
                          );
                        }),
                        if (events.length > 4)
                          Container(
                            margin: const EdgeInsets.only(left: 2),
                            child: const Text("+", style: TextStyle(fontSize: 10, color: AppTheme.textSub, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.backgroundColor,
            child: Row(
              children: [
                Icon(_isTeamView ? Icons.groups_outlined : Icons.person_outline, size: 20, color: AppTheme.textMain),
                const SizedBox(width: 8),
                Text(
                  _isTeamView ? "팀원별 현황" : "나의 일정",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 15),
                ),
                // 🌟 [핵심 고도화] 팀 전체 뷰일 때만 텍스트 옆에 둥글고 예쁜 검색창 표시
                if (_isTeamView) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "이름/내용 검색",
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textSub),
                          prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.textSub),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                          // 🌟 x 버튼 추가 (누르면 검색어 즉시 초기화)
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.cancel, size: 16, color: AppTheme.textSub),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  const Spacer(),
                ],
                if (_selectedDay != null)
                  Text(
                      DateFormat('MM.dd (E)', 'ko_KR').format(_selectedDay!),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14)
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _selectedDay == null
                  ? const Center(child: Text("날짜를 선택해주세요."))
                  : _isTeamView
                  ? _buildGroupedTeamList()
                  : _buildMyEventList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("일정 등록", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildMyEventList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_busy, size: 40, color: AppTheme.textSub),
            SizedBox(height: 10),
            Text("등록된 일정이 없습니다.", style: TextStyle(color: AppTheme.textSub)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemBuilder: (context, index) => _buildCustomEventCard(events[index]),
    );
  }

  Widget _buildGroupedTeamList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.groups_2_outlined, size: 40, color: AppTheme.textSub),
            SizedBox(height: 10),
            Text("팀원들의 일정이 없습니다.", style: TextStyle(color: AppTheme.textSub)),
          ],
        ),
      );
    }

    Map<String, List<dynamic>> groupedEvents = {};
    String query = _searchQuery.trim().toLowerCase();

    for (var event in events) {
      // 🌟 [검색 필터 로직] 검색어가 입력되었다면? 이름, 제목, 내용 중 하나라도 포함되어야 통과!
      if (query.isNotEmpty) {
        String author = (event['author'] ?? '').toString().toLowerCase();
        String title = (event['title'] ?? '').toString().toLowerCase();
        String content = (event['content'] ?? '').toString().toLowerCase();

        // 셋 다 일치하지 않으면 이 일정은 제외하고 다음으로 넘어갑니다.
        if (!author.contains(query) && !title.contains(query) && !content.contains(query)) {
          continue;
        }
      }

      String originalAuthor = event['author'] ?? '이름 미상';
      if (groupedEvents[originalAuthor] == null) groupedEvents[originalAuthor] = [];
      groupedEvents[originalAuthor]!.add(event);
    }

    // 🌟 [예외 처리] 검색 결과가 하나도 없을 때 보여줄 UI
    if (groupedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 40, color: AppTheme.textSub),
            SizedBox(height: 10),
            Text("검색 조건에 맞는 일정이 없습니다.", style: TextStyle(color: AppTheme.textSub)),
          ],
        ),
      );
    }

    var sortedKeys = groupedEvents.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        String authorName = sortedKeys[index];
        List<dynamic> authorEvents = groupedEvents[authorName]!;

        // ✅ PageStorageKey를 추가하여 열림/닫힘 상태 유지
        return Card(
          key: PageStorageKey(authorName),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppTheme.borderColor)
          ),
          child: ExpansionTile(
            key: PageStorageKey('tile_$authorName'),
            initiallyExpanded: true,
            shape: const Border(),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              radius: 16,
              child: Text(authorName.isNotEmpty ? authorName[0] : '?', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
            title: Text("$authorName (${authorEvents.length}건)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain)),
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            childrenPadding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
            children: authorEvents.map((event) => _buildCustomEventCard(event)).toList(),
          ),
        );
      },
    );
  }

  // ✅ [수정완료] 제목 / 작성날짜 / 기간설정 / 작성시간 순서대로 한 줄에 표시 (RichText)
  Widget _buildCustomEventCard(Map<String, dynamic> event) {
    Color eventColor = Color(event['colorCode'] ?? 0xFF1A233A);
    List<dynamic> logs = event['workLogs'] ?? [];
    String lastText = "";
    String lastAuthor = "";
    String lastWriterUid = "";

    // 1. 기간(Schedule Range)
    DateTime start = (event['startDate'] as Timestamp?)?.toDate() ?? (event['date'] as Timestamp).toDate();
    DateTime end = (event['endDate'] as Timestamp?)?.toDate() ?? start;
    bool isMultiDay = !DateUtils.isSameDay(start, end);

    // 기간 문자열
    String dateRangeStr = isMultiDay
        ? "${DateFormat('MM.dd').format(start)}~${DateFormat('MM.dd').format(end)}"
        : DateFormat('MM.dd').format(start);

    // 2. 작성 일시(Created At) - 없으면 시작 시간으로 대체
    DateTime createdAt = (event['createdAt'] as Timestamp?)?.toDate() ?? start;
    String createDateStr = DateFormat('yyyy.MM.dd').format(createdAt);
    String createTimeStr = DateFormat('HH:mm').format(createdAt);

    // 3. 제목
    String title = event['title'] ?? '';

    // 내용 처리
    if (logs.isNotEmpty) {
      var lastLog = logs.last;
      lastText = lastLog['text'] ?? "";
      lastAuthor = lastLog['author'] ?? "";
      lastWriterUid = lastLog['uid'] ?? "";
    } else {
      lastText = event['content'] ?? "";
      lastWriterUid = event['uid'] ?? "";
    }

    String originalOwnerUid = event['uid'] ?? "";
    bool isWrittenByOther = lastWriterUid.isNotEmpty && (lastWriterUid != originalOwnerUid);

    return GestureDetector(
      onTap: () => _showScheduleDialog(eventData: event),
      child: CommonCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: eventColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ [수정됨] 순서 변경: 제목 -> 작성일시(날짜+시간) -> 기간설정
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        // (1) 제목 (굵게)
                        if (title.isNotEmpty)
                          TextSpan(
                              text: "$title  ",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain)
                          ),

                        // (2) 작성 일시 (날짜 + 시간 붙여서 표시)
                        TextSpan(
                            text: "$createDateStr $createTimeStr  ", // 날짜와 시간 사이 공백, 뒤에 공백 2칸
                            style: const TextStyle(fontSize: 12, color: Colors.grey)
                        ),

                        // (3) 기간 설정 (맨 뒤로 이동, 강조 색상)
                        TextSpan(
                            text: "[$dateRangeStr]",
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),
                  if (lastText.isNotEmpty)
                    isWrittenByOther
                        ? Text(
                      "$lastAuthor : $lastText",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: AppTheme.errorColor, fontWeight: FontWeight.bold),
                    )
                        : Text(
                      lastText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSub),
                    ),
                  if (event['buildingName'] != null && event['buildingName'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event['buildingName'],
                              style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Icon(Icons.chevron_right, size: 20, color: AppTheme.textSub),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ [고도화] 일정 등록/수정 다이얼로그
class _AddScheduleDialog extends StatefulWidget {
  final DateTime initialDate;
  final Map<String, dynamic>? existingData;

  const _AddScheduleDialog({required this.initialDate, this.existingData});

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _titleCtrl = TextEditingController();
  final _newContentCtrl = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  int _selectedColor = 0xFF1E88E5;

  Map<String, String>? _selectedBuilding;
  bool _isBuildingSelected = false;

  // 🌟 [고도화 2차] 경로 관리 포함 방식 (all: 매일, first: 첫날만, none: 안 함)
  String _routeIncludeType = 'all';

  List<Map<String, dynamic>> _workLogs = [];

  bool get isEditMode => widget.existingData != null;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _titleCtrl.addListener(() => setState(() => _hasChanges = true));
    _newContentCtrl.addListener(() => setState(() => _hasChanges = _newContentCtrl.text.isNotEmpty));
  }

  void _initializeData() {
    if (isEditMode) {
      final data = widget.existingData!;
      _titleCtrl.text = data['title'] ?? '';

      if (data['startDate'] != null) {
        _startDate = (data['startDate'] as Timestamp).toDate();
      } else {
        _startDate = (data['date'] as Timestamp).toDate();
      }

      if (data['endDate'] != null) {
        _endDate = (data['endDate'] as Timestamp).toDate();
      } else {
        _endDate = _startDate;
      }

      _startTime = TimeOfDay.fromDateTime((data['startTime'] as Timestamp).toDate());
      _endTime = TimeOfDay.fromDateTime((data['endTime'] as Timestamp).toDate());
      _selectedColor = data['colorCode'] ?? 0xFF1E88E5;

      // 🌟 [고도화 2차] DB에서 옵션 불러오기 (기존 스위치 데이터 호환 처리 포함)
      if (data['routeIncludeType'] != null) {
        _routeIncludeType = data['routeIncludeType'];
      } else if (data['isRouteIncluded'] != null) {
        // 예전 스위치 방식(true/false)으로 저장된 데이터 호환
        _routeIncludeType = data['isRouteIncluded'] ? 'all' : 'none';
      } else {
        _routeIncludeType = 'all'; // 기본값
      }

      if (data['buildingName'] != null) {
        _isBuildingSelected = true;
        _selectedBuilding = {
          'name': data['buildingName'],
          'address': data['buildingAddress'] ?? '',
          'docId': data['buildingId'] ?? '',
        };
      }

      if (data['workLogs'] != null) {
        _workLogs = List<Map<String, dynamic>>.from(data['workLogs']);
      } else if (data['content'] != null && data['content'].toString().isNotEmpty) {
        _workLogs.add({
          'text': data['content'],
          'uid': data['uid'],
          'author': data['author'] ?? '작성자',
          'createdAt': Timestamp.now(),
        });
      }
    } else {
      _startDate = widget.initialDate;
      _endDate = widget.initialDate;
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String originalAuthorUid = isEditMode ? (widget.existingData!['uid'] ?? '') : (user?.uid ?? '');
    Color inputTextColor = (user != null && user.uid != originalAuthorUid) ? AppTheme.errorColor : AppTheme.textMain;

    // 화면 너비 확인
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: CommonCard(
        // ✅ [수정] 모바일은 90%, PC/태블릿은 최대 550px로 제한하여 깔끔하게 표시
        width: min(550, screenWidth * 0.9),
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEditMode ? "일정 상세" : "일정 등록", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("제목", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _titleCtrl,
                        style: TextStyle(color: inputTextColor),
                        decoration: const InputDecoration(hintText: "일정 제목 입력")
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("기간 설정 (시작 ~ 종료)", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: _buildDatePicker(isStart: true)),
                                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("~")),
                                      Expanded(child: _buildDatePicker(isStart: false)),
                                    ],
                                  )
                                ]
                            )
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("시간", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: _buildTimePicker(true)),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("~")),
                            Expanded(child: _buildTimePicker(false))
                          ])
                        ]
                    ),
                    const SizedBox(height: 24),

                    const Text("색상 라벨", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildColorPicker(),
                    ),
                    const SizedBox(height: 24),

                    // 🌟 [고도화 2차] 기간 일정일 때만 '경로 관리 표시 방식' 드롭다운 노출
                    if (!DateUtils.isSameDay(_startDate, _endDate)) ...[
                      const Text("경로 관리(지도) 표시 설정", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _routeIncludeType,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSub),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text("매일 방문 (기간 내내 지도에 표시)")),
                              DropdownMenuItem(value: 'first', child: Text("첫날만 방문 (시작일에만 지도에 표시)")),
                              DropdownMenuItem(value: 'none', child: Text("방문 안 함 (지도에 표시 안 함)")),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _routeIncludeType = newValue;
                                  _hasChanges = true;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Divider(thickness: 1, color: AppTheme.borderColor),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(Icons.business, color: AppTheme.textMain),
                        const SizedBox(width: 8),
                        const Text("방문 건물", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showBuildingSearchSheet,
                          icon: Icon(_isBuildingSelected ? Icons.change_circle_outlined : Icons.search, size: 18),
                          label: Text(_isBuildingSelected ? "건물 변경" : "건물 검색"),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    if (_isBuildingSelected) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryColor)
                        ),
                        child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            _selectedBuilding!['name']!,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain)
                                        ),
                                        Text(
                                            _selectedBuilding!['address']!,
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textSub)
                                        )
                                      ]
                                  )
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedBuilding = null;
                                    _isBuildingSelected = false;
                                    _hasChanges = true;
                                  });
                                },
                                icon: const Icon(Icons.close, size: 20, color: AppTheme.textSub),
                                tooltip: "건물 선택 취소",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ]
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Text("📋 업무내용 및 히스토리", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    const SizedBox(height: 12),

                    if (_workLogs.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _workLogs.map((log) {
                            bool isOriginalAuthor = log['uid'] == originalAuthorUid;
                            String timeStr = "";
                            if (log['createdAt'] != null && log['createdAt'] is Timestamp) {
                              timeStr = DateFormat('yy.MM.dd HH:mm').format((log['createdAt'] as Timestamp).toDate());
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(log['author'] ?? '알 수 없음', style: const TextStyle(fontSize: 12, color: AppTheme.textSub, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    log['text'] ?? '',
                                    style: TextStyle(fontSize: 14, color: isOriginalAuthor ? AppTheme.textMain : AppTheme.errorColor, fontWeight: isOriginalAuthor ? FontWeight.normal : FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    TextField(
                        controller: _newContentCtrl,
                        style: TextStyle(color: inputTextColor),
                        maxLines: null,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(hintText: "추가할 내용이나 수정 사항을 입력하세요...", filled: true, fillColor: AppTheme.backgroundColor)
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppTheme.borderColor),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (isEditMode && widget.existingData!['uid'] == user?.uid)
                    Expanded(
                        flex: 1,
                        child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: TextButton(
                                onPressed: _deleteSchedule,
                                style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                                child: const Text("삭제")
                            )
                        )
                    ),

                  Expanded(
                    flex: 3,
                    child: CommonButton(
                      onPressed: _hasChanges ? _saveSchedule : () => Navigator.pop(context),
                      text: _hasChanges ? "작성 완료 (저장)" : "닫기",
                      backgroundColor: _hasChanges ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuildingSearchSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) {
      return DraggableScrollableSheet(initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (context, scrollController) {
        return _BuildingSearchWidget(scrollController: scrollController, onSelected: (name, address, docId) {
          setState(() {
            _selectedBuilding = {'name': name, 'address': address, 'docId': docId};
            _isBuildingSelected = true;
            _hasChanges = true;

            // 🌟 [핵심 고도화] 제목이 비어있을 때만 선택한 건물명을 제목에 자동 입력합니다!
            // 이미 사용자가 제목을 적어두었다면 기존 제목을 100% 보존합니다.
            if (_titleCtrl.text.trim().isEmpty) {
              _titleCtrl.text = name;
            }
          });
          Navigator.pop(context);
        });
      });
    });
  }

  Future<void> _saveSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🌟 [핵심 제한 해제]
    // 기존 일정(경로관리에서 자동 생성된 일정 등)을 열어서 '수정 및 히스토리 추가'를 할 때는
    // 제목이 없어도 막히지 않고 무조건 저장되도록 제한을 완벽히 풀었습니다.
    // (단, 아예 처음 '신규 일정'을 만들 때만 제목을 필수로 받습니다.)
    if (!isEditMode && _titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("일정 제목을 입력해주세요.")));
      return;
    }

    // 🌟 [핵심 고도화] 통신 불량 시 '직원'으로 뜨던 try-catch 로직 완전 삭제!
    // 폰 메모리에 있는 내 정확한 이름을 0초 만에 즉시 가져옵니다.
    String myName = GlobalUserState.fullName;

    DateTime startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    DateTime endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

    if (_newContentCtrl.text.isNotEmpty) {
      _workLogs.add({
        'text': _newContentCtrl.text,
        'uid': user.uid,
        'author': myName,
        'createdAt': Timestamp.now(),
      });
    }

    final Map<String, dynamic> scheduleData = {
      'title': _titleCtrl.text,
      'content': _workLogs.isNotEmpty ? _workLogs.last['text'] : '',
      'workLogs': _workLogs,
      'date': Timestamp.fromDate(_startDate),
      'startDate': Timestamp.fromDate(_startDate),
      'endDate': Timestamp.fromDate(_endDate),
      'startTime': Timestamp.fromDate(startDateTime),
      'endTime': Timestamp.fromDate(endDateTime),
      'colorCode': _selectedColor,
      'buildingName': _isBuildingSelected ? _selectedBuilding!['name'] : null,
      'buildingAddress': _isBuildingSelected ? _selectedBuilding!['address'] : null,
      'buildingId': _isBuildingSelected ? _selectedBuilding!['docId'] : null,
      'routeIncludeType': _routeIncludeType, // 🌟 [고도화 2차] 표시 방식 옵션 저장
    };

    scheduleData['lastModifierUid'] = user.uid;
    scheduleData['lastModifierName'] = myName;

    try {
      if (isEditMode) {
        await FirebaseFirestore.instance.collection('schedules').doc(widget.existingData!['id']).update(scheduleData);
        // =============================================================
        // ✅ [알림 로직 수정] 남의 글을 수정했을 때 알림 발송 (서버 위임 방식)
        // =============================================================
        String ownerUid = widget.existingData!['uid'] ?? ''; // 글 쓴 사람 ID
        String modifierUid = user.uid; // 지금 수정하는 사람(나) ID

        // "주인이 내가 아닐 때"만 실행
        if (ownerUid.isNotEmpty && ownerUid != modifierUid) {
          print("🚀 타인 일정 수정 감지! 서버에 알림 발송 요청...");

          // 🌟 [핵심 수정] 앱에서 토큰을 검사하지 않습니다!
          // 무조건 DB(notifications)에 남기면, 발송과 토큰 검사는 서버(index.js)가 알아서 합니다.
          await NotificationService().sendNotification(
            targetToken: "",          // 더 이상 쓰지 않는 값이지만 인터페이스 유지를 위해 빈 문자열 전달
            targetUid: ownerUid,      // 알림 받을 원작성자 UID
            title: "일정 수정 알림",
            body: "$myName 님이 '${_titleCtrl.text}' 일정을 수정/댓글을 남겼습니다.",
            type: 'schedule',
          );
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("일정이 업데이트되었습니다.")));
      } else {
        scheduleData['uid'] = user.uid;
        scheduleData['author'] = myName;
        scheduleData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('schedules').add(scheduleData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("일정이 등록되었습니다.")));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류 발생: $e"))); }
  }

  Future<void> _deleteSchedule() async {
    bool? confirm = await showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: Colors.white, title: const Text("삭제 확인"), content: const Text("이 일정을 삭제하시겠습니까?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: AppTheme.errorColor)))]));
    if (confirm == true) { await FirebaseFirestore.instance.collection('schedules').doc(widget.existingData!['id']).delete(); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다."))); }}
  }

  // ✅ [수정] 날짜 선택기 (Start/End 구분)
  Widget _buildDatePicker({required bool isStart}) {
    return InkWell(
        onTap: () async {
          final date = await showDatePicker(
              context: context,
              initialDate: isStart ? _startDate : _endDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030)
          );

          if (date != null) {
            setState(() {
              if (isStart) {
                _startDate = date;
                // 시작일이 종료일보다 늦으면 종료일도 시작일로 맞춤
                if (_endDate.isBefore(_startDate)) {
                  _endDate = _startDate;
                }
              } else {
                _endDate = date;
                // 종료일이 시작일보다 빠르면 시작일도 종료일로 맞춤
                if (_startDate.isAfter(_endDate)) {
                  _startDate = _endDate;
                }
              }
              _hasChanges = true;
            });
          }
        },
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(4), color: Colors.white),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat('yyyy-MM-dd').format(isStart ? _startDate : _endDate)), const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSub)])
        )
    );
  }

  Widget _buildTimePicker(bool isStart) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime, initialEntryMode: TimePickerEntryMode.input);
        if (time != null) {
          setState(() {
            _hasChanges = true;
            if (isStart) {
              _startTime = time;
              final startDT = DateTime(2020, 1, 1, _startTime.hour, _startTime.minute);
              final endDT = startDT.add(const Duration(hours: 1));
              _endTime = TimeOfDay.fromDateTime(endDT);
            } else {
              _endTime = time;
            }
          });
        }
      },
      child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(4), color: Colors.white), child: Text(isStart ? _startTime.format(context) : _endTime.format(context), textAlign: TextAlign.center)),
    );
  }

  // ✅ [고도화] 10가지 눈에 띄는 색상 라벨
  Widget _buildColorPicker() {
    final colors = [
      0xFF1E88E5, // Blue (기존)
      0xFFE53935, // Red (기존)
      0xFF43A047, // Green (기존)
      0xFFFB8C00, // Orange (기존)
      0xFF8E24AA, // Purple (기존)
      0xFF00ACC1, // Cyan (신규)
      0xFF3949AB, // Indigo (신규)
      0xFFD81B60, // Pink (신규)
      0xFF8D6E63, // Brown (신규)
      0xFF546E7A, // Blue Grey (신규)
    ];
    return Row(children: colors.map((color) {
      return GestureDetector(
          onTap: () => setState(() { _selectedColor = color; _hasChanges = true; }),
          child: Container(margin: const EdgeInsets.only(right: 12), width: 32, height: 32, decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle, border: _selectedColor == color ? Border.all(color: Colors.black, width: 2) : null), child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 18) : null));
    }).toList());
  }
}

class _BuildingSearchWidget extends StatefulWidget { final ScrollController scrollController; final Function(String name, String address, String docId) onSelected; const _BuildingSearchWidget({required this.scrollController, required this.onSelected}); @override State<_BuildingSearchWidget> createState() => _BuildingSearchWidgetState(); }
class _BuildingSearchWidgetState extends State<_BuildingSearchWidget> { String _searchText = ""; @override Widget build(BuildContext context) { return Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: Column(children: [Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16)), const Text("건물 검색 및 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)), const SizedBox(height: 16), TextField(onChanged: (val) => setState(() => _searchText = val), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: "건물명 또는 주소 검색")), const SizedBox(height: 16), Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('buildings').orderBy('createdAt', descending: true).snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); var docs = snapshot.data!.docs; if (_searchText.isNotEmpty) { docs = docs.where((doc) { var data = doc.data() as Map<String, dynamic>; String name = (data['name'] ?? '').toString().toLowerCase(); String address = (data['address'] ?? '').toString().toLowerCase(); String search = _searchText.toLowerCase(); return name.contains(search) || address.contains(search); }).toList(); } if (docs.isEmpty) return const Center(child: Text("검색 결과가 없습니다.")); return ListView.separated(separatorBuilder: (context, index) => const Divider(), controller: widget.scrollController, itemCount: docs.length, itemBuilder: (context, index) { var data = docs[index].data() as Map<String, dynamic>; return ListTile(leading: const Icon(Icons.location_city, color: AppTheme.textSub), title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(data['address'] ?? ''), onTap: () { widget.onSelected(data['name'] ?? '이름 없음', data['address'] ?? '', docs[index].id); }); }); }))])); } }