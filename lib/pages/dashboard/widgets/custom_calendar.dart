// [파일 위치: lib/pages/dashboard/widgets/custom_calendar.dart]
// 대시보드 [캘린더,일정현황]
// 1. [다이어트] 일정 등록/수정 기능(팝업, 버튼 등)을 모두 제거하여 순수 '뷰어(Viewer)'로 최적화
// 2. [기능 동기화] 다중일(기간) 달력 표시 로직 적용
// 3. [버그 방지] StreamSubscription 적용으로 메모리 누수 방지
// 4. [UI 개선] 하단 목록을 화면 끝까지 확장 (Expanded)
// 5. [기능 추가] 팀 뷰 그룹핑 (아코디언) 및 읽기 전용 상세 팝업 추가

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // ✅ StreamSubscription 사용
import 'dart:math';

import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:universal_html/html.dart' as html;

import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';
import '../../../main.dart'; // 🌟 [고도화 추가] 스마트 캐싱(GlobalUserState) 사용을 위한 준비

class CustomCalendar extends StatefulWidget {
  const CustomCalendar({super.key});

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<dynamic>> _events = {};
  bool _isTeamView = false;

  StreamSubscription<QuerySnapshot>? _scheduleSubscription; // 🌟 스트림 관리 변수

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchSchedules();
  }

  @override
  void dispose() {
    _scheduleSubscription?.cancel(); // 🌟 위젯 종료 시 스트림 해제
    super.dispose();
  }

  // ✅ [데이터 로드] 다중일(기간) 로직 완벽 적용
  void _fetchSchedules() {
    // 🌟 [핵심 고도화] 매번 Auth 모듈을 깨우는 대신, 이미 메모리에 있는 내 UID를 0초 만에 즉시 가져옵니다.
    String myUid = GlobalUserState.uid;
    if (myUid.isEmpty) return;

    Query query = FirebaseFirestore.instance.collection('schedules');

    if (!_isTeamView) {
      query = query.where('uid', isEqualTo: myUid);
    }

    _scheduleSubscription?.cancel(); // 기존 스트림 닫기

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

  // ✅ [엑셀 출력] 현장 페이지와 동일
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

      List<CellValue> row = [
        TextCellValue(event['author'] ?? '미상'),
        TextCellValue(event['title'] ?? ''),
        TextCellValue(event['buildingName'] ?? '-'),
        TextCellValue(dateStr),
        TextCellValue("${DateFormat('HH:mm').format(startTime)} ~ ${DateFormat('HH:mm').format(endTime)}"),
        TextCellValue(firstContent),
      ];

      for (var h in history) row.add(TextCellValue(h));

      for (int col = 0; col < row.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1)).value = row[col];
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
        ..download = '일정현황_${viewType}_$dateStr.xlsx';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. 헤더 영역 (제목 + 엑셀 + 토글)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("📅 일정 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              Row(
                children: [
                  IconButton(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.download, color: Colors.green),
                    tooltip: "엑셀 다운로드",
                  ),
                  const SizedBox(width: 8),
                  ToggleButtons(
                    constraints: const BoxConstraints(minHeight: 32, minWidth: 60),
                    isSelected: [!_isTeamView, _isTeamView],
                    onPressed: (index) {
                      setState(() => _isTeamView = index == 1);
                      _fetchSchedules();
                    },
                    borderRadius: BorderRadius.circular(4),
                    selectedColor: Colors.white,
                    fillColor: AppTheme.primaryColor,
                    color: AppTheme.textSub,
                    borderColor: AppTheme.borderColor,
                    selectedBorderColor: AppTheme.primaryColor,
                    children: const [
                      Text("내 일정", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text("팀 전체", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. 캘린더 (디자인 시스템 적용)
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.textSub),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.textSub),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
              todayTextStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor, width: 1.5),
              ),
              selectedTextStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              markerDecoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              weekendTextStyle: const TextStyle(color: AppTheme.errorColor),
              defaultTextStyle: const TextStyle(color: AppTheme.textMain),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...events.take(4).map((e) {
                        int color = (e as Map)['colorCode'] ?? 0xFF1A233A;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 5, height: 5,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Color(color)),
                        );
                      }),
                      if (events.length > 4)
                        const Text("+", style: TextStyle(fontSize: 8, color: AppTheme.textSub, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderColor),

          // 3. 리스트 영역 (화면 끝까지 시원하게 확장!)
          Expanded(
            child: _getEventsForDay(_selectedDay!).isEmpty
                ? const Center(child: Text("일정이 없습니다.", style: TextStyle(color: AppTheme.textSub)))
                : _isTeamView
                ? _buildGroupedTeamList() // 🌟 팀 뷰일 때 그룹핑 함수 호출
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _getEventsForDay(_selectedDay!).length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _buildCustomEventCard(_getEventsForDay(_selectedDay!)[index]),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ [고도화 추가] 팀 뷰 그룹핑 함수
  Widget _buildGroupedTeamList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return const Center(
        child: Text("팀원들의 일정이 없습니다.", style: TextStyle(color: AppTheme.textSub)),
      );
    }

    Map<String, List<dynamic>> groupedEvents = {};
    for (var event in events) {
      String author = event['author'] ?? '이름 미상';
      if (groupedEvents[author] == null) groupedEvents[author] = [];
      groupedEvents[author]!.add(event);
    }

    var sortedKeys = groupedEvents.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        String authorName = sortedKeys[index];
        List<dynamic> authorEvents = groupedEvents[authorName]!;

        return Card(
          key: PageStorageKey('dashboard_$authorName'),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppTheme.borderColor)
          ),
          child: ExpansionTile(
            key: PageStorageKey('dashboard_tile_$authorName'),
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

  // ✅ [UI 통일] 터치 시 읽기 전용(Viewer) 팝업 띄우기 (수락 대기 딱지 추가!)
  Widget _buildCustomEventCard(Map<String, dynamic> event) {
    Color eventColor = Color(event['colorCode'] ?? 0xFF1A233A);
    List<dynamic> logs = event['workLogs'] ?? [];
    String lastText = "";
    String lastAuthor = "";
    String lastWriterUid = "";

    DateTime start = (event['startDate'] as Timestamp?)?.toDate() ?? (event['date'] as Timestamp).toDate();
    DateTime end = (event['endDate'] as Timestamp?)?.toDate() ?? start;
    bool isMultiDay = !DateUtils.isSameDay(start, end);

    String dateRangeStr = isMultiDay
        ? "${DateFormat('MM.dd').format(start)}~${DateFormat('MM.dd').format(end)}"
        : DateFormat('MM.dd').format(start);

    DateTime createdAt = (event['createdAt'] as Timestamp?)?.toDate() ?? start;
    String createInfoStr = "${DateFormat('yyyy.MM.dd').format(createdAt)} ${DateFormat('HH:mm').format(createdAt)}";

    // 🌟 [핵심 고도화] 제목 및 상태값 가져오기
    String title = event['title'] ?? '';
    String status = event['status'] ?? 'active';
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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

    // 🌟 터치 시 상세 팝업 오픈
    return GestureDetector(
      onTap: () => _showViewOnlyDialog(event),
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
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        // 🌟 [추가됨] 현장 페이지와 동일한 수락 대기 딱지 표시
                        if (status == 'pending' && originalOwnerUid == currentUid)
                          const TextSpan(
                              text: "🚨[수락 대기] ",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)
                          )
                        else if (status == 'pending')
                          TextSpan(
                              text: "⏳[대기중] ",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade700)
                          ),

                        TextSpan(
                            text: "$title  ",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain)
                        ),
                        TextSpan(
                            text: "$createInfoStr  ",
                            style: const TextStyle(fontSize: 12, color: Colors.grey)
                        ),
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
          ],
        ),
      ),
    );
  }

  // ✅ [고도화 추가] 읽기 전용(Viewer) 상세 팝업 함수
  void _showViewOnlyDialog(Map<String, dynamic> event) {
    Color eventColor = Color(event['colorCode'] ?? 0xFF1A233A);
    String title = event['title'] ?? '제목 없음';
    String buildingName = event['buildingName'] ?? '건물 미지정';
    String buildingAddress = event['buildingAddress'] ?? '';

    DateTime start = (event['startDate'] as Timestamp?)?.toDate() ?? (event['date'] as Timestamp).toDate();
    DateTime end = (event['endDate'] as Timestamp?)?.toDate() ?? start;
    bool isMultiDay = !DateUtils.isSameDay(start, end);

    String dateRangeStr = isMultiDay
        ? "${DateFormat('yyyy-MM-dd').format(start)} ~ ${DateFormat('yyyy-MM-dd').format(end)}"
        : DateFormat('yyyy-MM-dd').format(start);

    DateTime startTime = (event['startTime'] as Timestamp).toDate();
    DateTime endTime = (event['endTime'] as Timestamp).toDate();
    String timeStr = "${DateFormat('HH:mm').format(startTime)} ~ ${DateFormat('HH:mm').format(endTime)}";

    List<dynamic> logs = event['workLogs'] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: CommonCard(
            width: min(500, MediaQuery.of(context).size.width * 0.9),
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: eventColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: eventColor, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text("일정 상세정보", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: eventColor)),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),

                // 내용
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                        const SizedBox(height: 20),

                        Row(children: [
                          const Icon(Icons.calendar_today, size: 18, color: AppTheme.textSub),
                          const SizedBox(width: 8),
                          Text(dateRangeStr, style: const TextStyle(fontSize: 16)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.access_time, size: 18, color: AppTheme.textSub),
                          const SizedBox(width: 8),
                          Text(timeStr, style: const TextStyle(fontSize: 16)),
                        ]),
                        const SizedBox(height: 12),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.location_on, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(buildingName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              if (buildingAddress.isNotEmpty)
                                Text(buildingAddress, style: const TextStyle(fontSize: 14, color: AppTheme.textSub)),
                            ],
                          )),
                        ]),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: AppTheme.borderColor),
                        ),

                        const Text("📋 업무내용 및 히스토리", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        const SizedBox(height: 12),

                        if (logs.isEmpty)
                          Text(event['content'] ?? "내용이 없습니다.", style: const TextStyle(fontSize: 15))
                        else
                          ...logs.map((log) {
                            String logTime = "";
                            if (log['createdAt'] != null && log['createdAt'] is Timestamp) {
                              logTime = DateFormat('yy.MM.dd HH:mm').format((log['createdAt'] as Timestamp).toDate());
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(log['author'] ?? '알 수 없음', style: const TextStyle(fontSize: 13, color: AppTheme.textSub, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Text(logTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(log['text'] ?? '', style: const TextStyle(fontSize: 15, color: AppTheme.textMain)),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}