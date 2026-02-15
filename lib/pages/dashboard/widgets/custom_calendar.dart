// [파일 위치: lib/pages/dashboard/widgets/custom_calendar.dart]
// 수정 내용:
// 1. [디자인] 현장 일정 페이지(FieldSchedulePage)와 100% 동일한 디자인(CommonCard, 폰트사이즈) 적용
// 2. [기능] 일정 등록 팝업을 현장 페이지와 동일한 최신 버전(기간설정, 건물검색, 수정자 기록 등)으로 교체
// 3. [기타] 엑셀 출력 로직 및 정렬 방식 동기화
// 4. [추가] 일정 수정 시 작성자에게 알림 발송 로직 적용 (NotificationService)

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // 반응형 계산용

// ✅ TextSpan 충돌 방지
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:universal_html/html.dart' as html;

// ✅ 알림 서비스 import (추가됨)
import '../../../services/notification_service.dart';

// ✅ 디자인 시스템 import
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchSchedules();
  }

  // ✅ [데이터 로드] startDate ~ endDate 로직 적용 (현장 페이지와 동일)
  void _fetchSchedules() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Query query = FirebaseFirestore.instance.collection('schedules');

    if (!_isTeamView) {
      query = query.where('uid', isEqualTo: user.uid);
    }

    query.snapshots().listen((snapshot) {
      Map<DateTime, List<dynamic>> newEvents = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // 날짜 필드 호환성 처리 (startDate 우선)
        DateTime date;
        if (data['startDate'] != null) {
          date = (data['startDate'] as Timestamp).toDate();
        } else {
          date = (data['date'] as Timestamp).toDate();
        }

        // 캘린더 마커용 키 (UTC 기준)
        DateTime dateKey = DateTime.utc(date.year, date.month, date.day);

        if (newEvents[dateKey] == null) newEvents[dateKey] = [];
        newEvents[dateKey]!.add({...data, 'id': doc.id});
      }
      if (mounted) setState(() => _events = newEvents);
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // ✅ [엑셀 출력] 현장 페이지와 동일한 헤더 및 정렬 로직 적용
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

    // 정렬 (팀 보기일 경우 이름순 -> 시간순)
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

          // 3. 리스트 영역 (높이 고정 및 스크롤)
          SizedBox(
            height: 250,
            child: _events[DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]?.isEmpty ?? true
                ? const Center(child: Text("일정이 없습니다.", style: TextStyle(color: AppTheme.textSub)))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _getEventsForDay(_selectedDay!).length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _buildCustomEventCard(_getEventsForDay(_selectedDay!)[index]),
            ),
          ),

          const Spacer(),
          const SizedBox(height: 12),

          // 일정 등록 버튼
          CommonButton(
            onPressed: () => _showScheduleDialog(),
            icon: Icons.add,
            text: "일정 등록",
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  // ✅ [UI 통일] FieldSchedulePage와 동일한 카드 디자인 (CommonCard 사용, 폰트 사이즈 통일)
  Widget _buildCustomEventCard(Map<String, dynamic> event) {
    Color eventColor = Color(event['colorCode'] ?? 0xFF1A233A);
    List<dynamic> logs = event['workLogs'] ?? [];
    String lastText = "";
    String lastAuthor = "";
    String lastWriterUid = "";

    // 1. 기간 및 시간 계산
    DateTime start = (event['startDate'] as Timestamp?)?.toDate() ?? (event['date'] as Timestamp).toDate();
    DateTime end = (event['endDate'] as Timestamp?)?.toDate() ?? start;
    bool isMultiDay = !DateUtils.isSameDay(start, end);

    String dateRangeStr = isMultiDay
        ? "${DateFormat('MM.dd').format(start)}~${DateFormat('MM.dd').format(end)}"
        : DateFormat('MM.dd').format(start);

    DateTime createdAt = (event['createdAt'] as Timestamp?)?.toDate() ?? start;
    String createInfoStr = "${DateFormat('yyyy.MM.dd').format(createdAt)} ${DateFormat('HH:mm').format(createdAt)}";

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
      // ✅ [통일] CommonCard 사용 (현장 페이지와 동일)
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
                  // [제목 + 작성일시 + 기간] RichText (현장 페이지와 동일한 폰트 사이즈)
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
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

                  // 내용 표시
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

                  // 건물명 표시
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

// ✅ [고도화] 일정 등록/수정 다이얼로그 (FieldSchedulePage와 100% 동일 로직)
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: CommonCard(
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
          });
          Navigator.pop(context);
        });
      });
    });
  }

  Future<void> _saveSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_titleCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("일정 제목을 입력해주세요."))); return; }

    String myName = '직원';
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        myName = "${userData['name'] ?? ''} ${userData['rank'] ?? ''}".trim();
        if (myName.isEmpty) myName = "직원";
      }
    } catch(e) { print("이름 실패: $e"); }

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
    };

    scheduleData['lastModifierUid'] = user.uid;
    scheduleData['lastModifierName'] = myName;

    try {
      if (isEditMode) {
        // 1. 일정 업데이트
        await FirebaseFirestore.instance.collection('schedules').doc(widget.existingData!['id']).update(scheduleData);

        // =============================================================
        // ✅ [알림 로직 추가] 남의 글을 수정했을 때 알림 발송
        // =============================================================
        String ownerUid = widget.existingData!['uid'] ?? ''; // 글 쓴 사람 ID
        String modifierUid = user.uid; // 지금 수정하는 사람(나) ID

        // "주인이 내가 아닐 때"만 실행
        if (ownerUid.isNotEmpty && ownerUid != modifierUid) {
          // 1) 주인(작성자)의 정보를 DB에서 가져옴
          DocumentSnapshot ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerUid).get();

          if (ownerDoc.exists) {
            Map<String, dynamic> ownerData = ownerDoc.data() as Map<String, dynamic>;
            String? targetToken = ownerData['fcmToken']; // 주인의 토큰

            // 2) 주인이 토큰을 가지고 있다면 알림 발송
            if (targetToken != null && targetToken.isNotEmpty) {
              String notiTitle = "일정 수정 알림";
              String notiBody = "$myName 님이 '${_titleCtrl.text}' 일정을 수정했습니다.";

              await NotificationService().sendNotification(
                targetToken: targetToken,
                targetUid: ownerUid,      // 추가됨
                title: notiTitle,
                body: notiBody,
                type: 'schedule',         // 추가됨
              );
            }
          }
        }
        // =============================================================

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
                if (_endDate.isBefore(_startDate)) {
                  _endDate = _startDate;
                }
              } else {
                _endDate = date;
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

  // ✅ [고도화] 10가지 눈에 띄는 색상 라벨 (현장 페이지와 동일)
  Widget _buildColorPicker() {
    final colors = [
      0xFF1E88E5, 0xFFE53935, 0xFF43A047, 0xFFFB8C00, 0xFF8E24AA,
      0xFF00ACC1, 0xFF3949AB, 0xFFD81B60, 0xFF8D6E63, 0xFF546E7A,
    ];
    return Row(children: colors.map((color) {
      return GestureDetector(
          onTap: () => setState(() { _selectedColor = color; _hasChanges = true; }),
          child: Container(margin: const EdgeInsets.only(right: 12), width: 32, height: 32, decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle, border: _selectedColor == color ? Border.all(color: Colors.black, width: 2) : null), child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 18) : null));
    }).toList());
  }
}

class _BuildingSearchWidget extends StatefulWidget {
  final ScrollController scrollController;
  final Function(String name, String address, String docId) onSelected;
  const _BuildingSearchWidget({required this.scrollController, required this.onSelected});
  @override
  State<_BuildingSearchWidget> createState() => _BuildingSearchWidgetState();
}

class _BuildingSearchWidgetState extends State<_BuildingSearchWidget> {
  String _searchText = "";
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16)),
          const Text("건물 검색 및 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 16),
          TextField(onChanged: (val) => setState(() => _searchText = val), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: "건물명 또는 주소 검색")),
          const SizedBox(height: 16),
          Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('buildings').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (_searchText.isNotEmpty) {
                  docs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name = (data['name'] ?? '').toString().toLowerCase();
                    String address = (data['address'] ?? '').toString().toLowerCase();
                    String search = _searchText.toLowerCase();
                    return name.contains(search) || address.contains(search);
                  }).toList();
                }
                if (docs.isEmpty) return const Center(child: Text("검색 결과가 없습니다."));
                return ListView.separated(
                    separatorBuilder: (context, index) => const Divider(),
                    controller: widget.scrollController,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                          leading: const Icon(Icons.location_city, color: AppTheme.textSub),
                          title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(data['address'] ?? ''),
                          onTap: () {
                            widget.onSelected(data['name'] ?? '이름 없음', data['address'] ?? '', docs[index].id);
                          });
                    });
              }))
        ]));
  }
}