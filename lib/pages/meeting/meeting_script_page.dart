// [파일 위치: lib/pages/meeting/meeting_script_page.dart]
// [고도화: 프리미엄 UI/UX + 구어체 변환 대본 엔진 + 국토부/DB 연동 + 현장 필수 행동요령 추가]

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'dart:convert'; // 🌟 추가: JSON 데이터 변환용
import 'package:http/http.dart' as http; // 🌟 추가: API 통신용
import '../../services/building_service.dart'; // 🌟 서비스 엔진 연결
import '../../models/building_model.dart';   // 🌟 데이터 바구니 연결

class MeetingScriptPage extends StatefulWidget {
  const MeetingScriptPage({super.key});

  @override
  State<MeetingScriptPage> createState() => _MeetingScriptPageState();
}

class _MeetingScriptPageState extends State<MeetingScriptPage> {
  // 🏢 SM 프리미엄 브랜드 컬러 팔레트
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color safetyBlue = const Color(0xFF2563EB);
  final Color dangerRed = const Color(0xFFEF4444);
  final Color successGreen = const Color(0xFF10B981);
  final Color surfaceGrey = const Color(0xFFF8FAFC);
  final Color textMain = const Color(0xFF1E293B);

  // 📝 기본 입력 컨트롤러
  final TextEditingController _totalHouseholdsCtrl = TextEditingController();
  final TextEditingController _onlineVotesCtrl = TextEditingController();
  final TextEditingController _offlineAttendeesCtrl = TextEditingController();

  // 📋 상세 안건 리스트 관리 (제목, 사유, 내용, 근거)
  final List<Map<String, TextEditingController>> _agendaEntries = [
    {
      "title": TextEditingController(),
      "reason": TextEditingController(),
      "content": TextEditingController(),
      "legal": TextEditingController(),
    }
  ];

  // 🔑 [인증키 설정] 국토부 및 카카오 API 공식 키
  final String _molitKey = "6d6808551481d40d1b5869e0ad497be2c35ca49bde3fc91b72790429a0d55970";
  final String _kakaoKey = "e1fc7f4a7281b14f7c8be88f6e146462"; // 🌟 카카오 엔진 사용!

  // 🔄 상태 관리 변수
  String? _selectedBuilding;
  bool _isLoadingBuildingInfo = false;
  BuildingInfo? _buildingInfo; // 🌟 Map 대신 우리가 만든 모델 클래스로 변경!

  // ---------------------------------------------------------
  // 🌐 [고도화 완성] 서비스 파일(BuildingService)을 이용한 간편 호출
  // ---------------------------------------------------------
  Future<void> _fetchBuildingInfoFromMOLIT(String buildingName) async {
    setState(() {
      _selectedBuilding = buildingName;
      _isLoadingBuildingInfo = true;
      _buildingInfo = null;
    });

    try {
      // 🌟 복잡한 과정 없이 딱 한 줄로 데이터 요청!
      final info = await BuildingService.getFullBuildingInfo(buildingName);

      setState(() => _buildingInfo = info);

    } catch (e) {
      debugPrint("API 연동 에러: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ $e"), backgroundColor: Colors.orange),
      );
    } finally {
      setState(() => _isLoadingBuildingInfo = false);
    }
  }

  // 🌟 추가: 날짜 포맷 헬퍼 (20260206 -> 2026.02.06)
  String _formatDate(dynamic date) {
    if (date == null || date.toString().length < 8) return "-";
    String d = date.toString();
    return "${d.substring(0, 4)}.${d.substring(4, 6)}.${d.substring(6, 8)}";
  }

  bool _isScriptGenerated = false;
  int _totalHouseholds = 0;
  int _onlineVotes = 0;
  int _offlineAttendees = 0;
  int _totalAttendees = 0;
  int _requiredQuorum = 0;
  bool _isQuorumMet = false;
  double _attendanceRate = 0.0;

  // 👇👇 🌟 [신규 추가] 담당자가 더블클릭해서 수정한 멘트를 영구적으로 기억하는 바구니 👇👇
  Map<String, String> _userEdits = {};

  // 🌟 [추가] 100개 DB를 담아둘 메모리 캐시 변수
  List<Map<String, dynamic>> _dbTemplatesCache = [];

  // 🌟 [추가] 앱 화면이 켜질 때 DB를 한 번만 싹 불러옵니다.
  @override
  void initState() {
    super.initState();
    _fetchDbTemplates();
  }

  Future<void> _fetchDbTemplates() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('agenda_templates').get();
      setState(() {
        _dbTemplatesCache = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      debugPrint("DB 로드 실패: $e");
    }
  }

  @override
  void dispose() {
    _totalHouseholdsCtrl.dispose();
    _onlineVotesCtrl.dispose();
    _offlineAttendeesCtrl.dispose();
    for (var entry in _agendaEntries) {
      for (var ctrl in entry.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  // ---------------------------------------------------------
  // 📂 [DB 연동 완료] 검색 및 페이징이 적용된 스마트 안건 로드
  // ---------------------------------------------------------
  Future<void> _loadStandardAgenda(int index) async {
    if (_dbTemplatesCache.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DB 데이터를 불러오는 중입니다. 잠시 후 다시 시도해주세요.")));
      return;
    }

    final selectedAgenda = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AgendaSearchDialog(dbTemplates: _dbTemplatesCache),
    );

    if (selectedAgenda != null) {
      setState(() {
        _agendaEntries[index]["title"]!.text = selectedAgenda["title"] ?? "";
        _agendaEntries[index]["reason"]!.text = selectedAgenda["reason"] ?? "";
        _agendaEntries[index]["content"]!.text = selectedAgenda["content"] ?? "";
        _agendaEntries[index]["legal"]!.text = selectedAgenda["legal"] ?? "";

        // 🌟 [문제 해결] DB를 불러올 때 기존 이 안건에 대한 수동 수정 기억을 싹 지웁니다!
        _userEdits.remove("agenda_${index}_desc");
        _userEdits.remove("agenda_${index}_vote");
        _userEdits.remove("agenda_${index}_resolve");
      });
    }
  }

  Widget _buildDbSelectItem(int index, BuildContext ctx, String title, String reason, String content, String legal) {
    return Card(
      elevation: 0,
      color: surfaceGrey,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569))),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _agendaEntries[index]["title"]!.text = title;
              _agendaEntries[index]["reason"]!.text = reason;
              _agendaEntries[index]["content"]!.text = content;
              _agendaEntries[index]["legal"]!.text = legal;

              // 🌟 [문제 해결] 여기서도 이전 수정 기억을 지워 새 내용이 스크립트에 바로 꽂히게 합니다!
              _userEdits.remove("agenda_${index}_desc");
              _userEdits.remove("agenda_${index}_vote");
              _userEdits.remove("agenda_${index}_resolve");
            });
            Navigator.pop(ctx);
          },
          icon: const Icon(Icons.download, size: 18, color: Colors.white),
          label: const Text("불러오기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: safetyBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ),
    );
  }

  void _addAgenda() {
    setState(() => _agendaEntries.add({"title": TextEditingController(), "reason": TextEditingController(), "content": TextEditingController(), "legal": TextEditingController()}));
  }

  void _removeAgenda(int index) {
    if (_agendaEntries.length > 1) {
      setState(() { _agendaEntries[index].values.forEach((c) => c.dispose()); _agendaEntries.removeAt(index); });
    }
  }

  // 🌟 [고도화 1] 성원 입력 없이도 일단 대본 초안을 만들어주는 기능
  void _generateScript() {
    FocusScope.of(context).unfocus();
    int total = int.tryParse(_totalHouseholdsCtrl.text) ?? 0;
    int online = int.tryParse(_onlineVotesCtrl.text) ?? 0;
    int offline = int.tryParse(_offlineAttendeesCtrl.text) ?? 0;

    setState(() {
      _totalHouseholds = total; _onlineVotes = online; _offlineAttendees = offline;
      _totalAttendees = online + offline;
      _requiredQuorum = total > 0 ? (total / 2).floor() + 1 : 0;

      // 인원수가 0명이면 무조건 '성원 달성(성공)' 뼈대를 보여줍니다.
      _isQuorumMet = total == 0 ? true : (_totalAttendees >= _requiredQuorum);
      _attendanceRate = total > 0 ? (_totalAttendees / _totalHouseholds) * 100 : 0.0;
      _isScriptGenerated = true;
    });
  }

  // 🌟 [고도화 2] 담당자가 수정한 멘트는 100% 보존하고, 숫자만 정밀 교체하는 기능
  void _refreshQuorumOnly() {
    FocusScope.of(context).unfocus();
    int total = int.tryParse(_totalHouseholdsCtrl.text) ?? 0;

    setState(() {
      // 1. 과거 숫자들 임시 저장 (치환용)
      String oldTotal = _totalHouseholds.toString();
      String oldOnline = _onlineVotes.toString();
      String oldOffline = _offlineAttendees.toString();
      String oldTotalAtt = _totalAttendees.toString();
      String oldRate = _attendanceRate.toStringAsFixed(1);

      // 2. 새로운 숫자 적용
      _totalHouseholds = total;
      _onlineVotes = int.tryParse(_onlineVotesCtrl.text) ?? 0;
      _offlineAttendees = int.tryParse(_offlineAttendeesCtrl.text) ?? 0;
      _totalAttendees = _onlineVotes + _offlineAttendees;
      _requiredQuorum = total > 0 ? (total / 2).floor() + 1 : 0;
      _isQuorumMet = total == 0 ? true : (_totalAttendees >= _requiredQuorum);
      _attendanceRate = total > 0 ? (_totalAttendees / _totalHouseholds) * 100 : 0.0;
      String newRate = _attendanceRate.toStringAsFixed(1);

      // 3. 🌟 [핵심] 주변 단어까지 통째로 묶어서 바꿔치기하여 엉뚱한 숫자가 바뀌는 걸 원천 차단!
      if (_userEdits.containsKey("intro_success")) {
        String intro = _userEdits["intro_success"]!;
        intro = intro.replaceAll('총 $oldTotal세대 중', '총 $_totalHouseholds세대 중');
        intro = intro.replaceAll('통해 $oldOnline세대가', '통해 $_onlineVotes세대가');
        intro = intro.replaceAll('현장에 $oldOffline세대가', '현장에 $_offlineAttendees세대가');
        intro = intro.replaceAll('총 $oldTotalAtt세대,', '총 $_totalAttendees세대,');
        intro = intro.replaceAll('출석률 $oldRate%', '출석률 $newRate%');
        _userEdits["intro_success"] = intro;
      }

      if (_userEdits.containsKey("intro_fail")) {
        String intro = _userEdits["intro_fail"]!;
        intro = intro.replaceAll('투표 $oldOnline명', '투표 $_onlineVotes명');
        intro = intro.replaceAll('참석 $oldOffline명', '참석 $_offlineAttendees명');
        intro = intro.replaceAll('총 $oldTotalAtt명', '총 $_totalAttendees명');
        intro = intro.replaceAll('출석률 $oldRate%', '출석률 $newRate%');
        _userEdits["intro_fail"] = intro;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정 멘트 보존 완료! 성원 숫자가 실시간 갱신되었습니다."), backgroundColor: Colors.green));
  }

  // (도우미) 숫자 계산 공통 함수
  void _calculateQuorum() {
    int total = int.tryParse(_totalHouseholdsCtrl.text) ?? 0;
    int online = int.tryParse(_onlineVotesCtrl.text) ?? 0;
    int offline = int.tryParse(_offlineAttendeesCtrl.text) ?? 0;

    _totalHouseholds = total; _onlineVotes = online; _offlineAttendees = offline;
    _totalAttendees = online + offline;
    _requiredQuorum = total > 0 ? (total / 2).floor() + 1 : 0;
    _isQuorumMet = total > 0 && _totalAttendees >= _requiredQuorum;
    _attendanceRate = total > 0 ? (_totalAttendees / _totalHouseholds) * 100 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 모바일 뷰어 감지
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("회의 진행 프롬프터 (SM 프로)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18)),
        backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Color(0xFF0F172A)), elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.shade200, height: 1)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 24.0, vertical: isMobile ? 16.0 : 32.0),
            children: [
              _buildTopGuideBanner(isMobile),
              const SizedBox(height: 24),
              _buildBuildingSearchSection(isMobile),
              const SizedBox(height: 24),
              _buildInputSection(isMobile),
              const SizedBox(height: 32),
              if (_isScriptGenerated) _buildScriptOutput(isMobile),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // 💡 대기업 스타일 프리미엄 가이드 배너 (상세 내용 및 법적 경고 고도화)
  Widget _buildTopGuideBanner(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.lightbulb, color: Colors.amber, size: 24)),
              const SizedBox(width: 16),
              const Expanded(child: Text("회의 전 필수 준비 및 성원\n확보 가이드", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5))),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24, height: 1)),

          // 🌟 [추가] 담당자 필수 숙지: 왜 성원 확보에 목숨을 걸어야 하는가? (법적 경고)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFDC2626).withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.gavel_rounded, color: Color(0xFFFCA5A5), size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: const Text("담당자 필수 숙지 : 성원(의결 정족수)(총원의 50%초과(예,총원100세대 중 51세대시 인정)) 미달 시 치명적 법적 리스크", style: TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 8),
                const Text("집합건물법, 공동주택관리법 및 주택법 등 관련 법령에 따르면, 의결 정족수를 충족하지 못한 상태에서 처리된 안건은 법적으로 '원천 무효' 처리됩니다. 이는 추후 일부 입주민의 '총회 결의 무효 확인 소송' 등 심각한 법적 분쟁의 빌미가 됩니다. 따라서 현장 참석자만 믿지 마시고, 사전에 '반상회' 앱을 통해 전자 투표로 법적 정족수를 미리 확보하는 것이 담당자의 가장 핵심적인 업무입니다.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildGuideStepRow("STEP 1", "사전 공지 및 반상회 앱 투표 개설", "바쁜 직장인 입주민들도 스마트폰으로 1분 만에 참여할 수 있도록 회의 7일 전 반드시 '반상회' 앱에 안건을 등록하고 전자투표를 개설하세요. 성원 달성률이 획기적으로 올라갑니다."),
          const SizedBox(height: 12),
          _buildGuideStepRow("STEP 2", "현장 본인 확인 (매우 중요)", "회의 당일 안내 데스크에 반드시 '입주자명부(최신본)'를 비치하세요. 참석자의 신분증과 대조하여 본인(또는 적법한 대리인)임을 확인 후 서명을 받아야 추후 법적 효력 분쟁을 막을 수 있습니다."),
          const SizedBox(height: 12),
          _buildGuideStepRow("STEP 3", "유연한 현장 대처", "위 노력에도 불구하고 성원 미달 시 당황하지 마십시오. 생성된 '간담회용 대본'에 따라 부드럽게 전환 후, 현장에서 즉시 '반상회 앱 투표 기간 연장'을 선언하시면 됩니다."),
        ],
      ),
    );
  }

  Widget _buildGuideStepRow(String badge, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 60, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  // 🏢 건물 검색 및 제원 패널
  Widget _buildBuildingSearchSection(bool isMobile) {
    return _buildCardWrapper(
      title: "건물 제원 연동 (주민 질의 실시간 대응)",
      icon: Icons.domain_verification,
      isMobile: isMobile,
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('buildings').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator(backgroundColor: Color(0xFFE2E8F0), color: Color(0xFF2563EB));
              List<String> names = snapshot.data!.docs.map((doc) => doc['name'].toString()).toList();
              return Autocomplete<String>(
                optionsBuilder: (val) => val.text.isEmpty ? const Iterable<String>.empty() : names.where((s) => s.contains(val.text)),
                onSelected: (s) => _fetchBuildingInfoFromMOLIT(s),
                fieldViewBuilder: (ctx, ctrl, node, onSub) => _buildModernTextField(ctrl, node, "건물명을 검색하여 건축물대장을 불러오세요", Icons.search),
              );
            },
          ),
          if (_isLoadingBuildingInfo) const Padding(padding: EdgeInsets.only(top: 24), child: CircularProgressIndicator())
          else if (_buildingInfo != null) _buildBuildingInfoDashboard(isMobile),
        ],
      ),
    );
  }

  Widget _buildBuildingInfoDashboard(bool isMobile) {
    if (_buildingInfo == null) return const SizedBox.shrink();

    // 🌟 화면에 뿌려줄 항목들을 리스트로 정리합니다.
    final items = [
      {"label": "주소", "value": _buildingInfo!.address},
      {"label": "대지/연면적", "value": "${_buildingInfo!.platArea} / ${_buildingInfo!.totalArea}"},
      {"label": "주용도", "value": _buildingInfo!.mainPurpose},
      {"label": "사용승인일", "value": _buildingInfo!.useAprvDate},
      {"label": "건축규모", "value": _buildingInfo!.flrInfo},
      {"label": "세대/가구", "value": _buildingInfo!.householdInfo}, // 🌟 새로 추가됨!
      {"label": "주차장", "value": _buildingInfo!.parkingInfo},   // 🌟 새로 추가됨!
      {"label": "승강기", "value": _buildingInfo!.liftInfo},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBAE6FD))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: safetyBlue, borderRadius: BorderRadius.circular(4)),
                  child: const Text("전용 서버 연동 완료", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
              ),
              const SizedBox(width: 10),
              Expanded(child: Text("$_selectedBuilding 핵심 제원", style: TextStyle(fontWeight: FontWeight.bold, color: textMain, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24, runSpacing: 16,
            children: items.map((e) => SizedBox(
              width: isMobile ? (MediaQuery.of(context).size.width / 2) - 50 : 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e['label']!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(e['value']!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textMain)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // 📥 성원 및 안건 입력 섹션
  Widget _buildInputSection(bool isMobile) {
    return _buildCardWrapper(
      title: "성원 확인 및 안건 상정",
      icon: Icons.how_to_reg,
      isMobile: isMobile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 모바일이면 위아래 정렬, PC면 양옆 정렬
          isMobile
              ? Column(
            children: [
              _buildLabelTextField("총 세대(의결권) 수", _totalHouseholdsCtrl, Icons.home, isNumber: true),
              const SizedBox(height: 16),
              _buildLabelTextField("앱 사전투표 참여", _onlineVotesCtrl, Icons.touch_app, isNumber: true),
              const SizedBox(height: 16),
              _buildLabelTextField("현장 참석자 수", _offlineAttendeesCtrl, Icons.groups, isNumber: true),
            ],
          )
              : Row(
            children: [
              Expanded(child: _buildLabelTextField("총 세대(의결권) 수", _totalHouseholdsCtrl, Icons.home, isNumber: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildLabelTextField("앱 사전투표 참여", _onlineVotesCtrl, Icons.touch_app, isNumber: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildLabelTextField("현장 참석자 수", _offlineAttendeesCtrl, Icons.groups, isNumber: true)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
          const Text("📋 회의 안건 상세 구조화", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._agendaEntries.asMap().entries.map((e) => _buildAgendaInputItem(e.key, isMobile)).toList(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _addAgenda,
              icon: const Icon(Icons.add_circle, color: Color(0xFF2563EB)),
              label: const Text("안건 추가", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 24),

          // 👇👇 🌟 [수정] 대본 생성 버튼과 새로고침 버튼을 나란히 배치 👇👇
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _generateScript,
                    icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                    label: const Text("프롬프터 멘트 초안 세팅", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.5)),
                    style: ElevatedButton.styleFrom(backgroundColor: safetyBlue, elevation: 4, shadowColor: safetyBlue.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ),
              if (_isScriptGenerated) const SizedBox(width: 12),
              if (_isScriptGenerated) Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _refreshQuorumOnly,
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    label: const Text("성원 새로고침", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: successGreen, elevation: 4, shadowColor: successGreen.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaInputItem(int idx, bool isMobile) {
    var entry = _agendaEntries[idx];
    return Container(
      margin: const EdgeInsets.only(bottom: 20), padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(color: surfaceGrey, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(8)), child: Text("${idx + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(child: _buildModernTextField(entry["title"]!, null, "안건 제목 (예: 주차장 규정 개정)", Icons.title)),
              if (!isMobile) const SizedBox(width: 12),
              if (!isMobile)
                ElevatedButton.icon(
                  onPressed: () => _loadStandardAgenda(idx),
                  icon: const Icon(Icons.storage, size: 16, color: Colors.white),
                  label: const Text("DB 로드", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              if (!isMobile && _agendaEntries.length > 1) Padding(padding: const EdgeInsets.only(left: 8.0), child: IconButton(icon: Icon(Icons.delete, color: dangerRed), onPressed: () => _removeAgenda(idx))),
            ],
          ),
          if (isMobile) const SizedBox(height: 12),
          if (isMobile)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _loadStandardAgenda(idx),
                    icon: const Icon(Icons.storage, size: 16, color: Colors.white),
                    label: const Text("DB 로드", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ),
                if (_agendaEntries.length > 1) IconButton(icon: Icon(Icons.delete, color: dangerRed), onPressed: () => _removeAgenda(idx)),
              ],
            ),
          const SizedBox(height: 16),
          _buildModernTextField(entry["reason"]!, null, "제안 사유 (주민 설득 명분)", Icons.info_outline, maxLines: 2),
          const SizedBox(height: 12),
          _buildModernTextField(entry["content"]!, null, "주요 내용 (투표 핵심 항목)", Icons.list_alt, maxLines: 2),
          const SizedBox(height: 12),
          _buildModernTextField(entry["legal"]!, null, "법적 근거 (공동주택관리법 등)", Icons.gavel, maxLines: 1),

          // 🌟 [추가] 실시간 법적 근거 AI 추천 (스마트 칩)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: entry["title"]!,
            builder: (context, value, child) {
              String inputText = value.text;
              List<String> suggestions = _getLegalSuggestions(inputText);

              if (suggestions.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 16),
                        SizedBox(width: 6),
                        Text("관련 법령 스마트 추천 (클릭 시 자동 입력)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: suggestions.map((legalText) => ActionChip(
                        label: Text(legalText, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        backgroundColor: const Color(0xFFFEF3C7),
                        side: const BorderSide(color: Color(0xFFFDE68A)),
                        onPressed: () {
                          entry["legal"]!.text = legalText;
                        },
                      )).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🌟 [추가] 입력된 텍스트와 DB의 키워드를 매칭하여 법령을 찾아주는 함수
  List<String> _getLegalSuggestions(String inputText) {
    if (inputText.trim().isEmpty || _dbTemplatesCache.isEmpty) return [];

    Set<String> suggestions = {};
    for (var template in _dbTemplatesCache) {
      List<dynamic> keywords = template['keywords'] ?? [];
      String legal = template['legal'] ?? '';

      if (legal.isEmpty) continue;

      for (var kw in keywords) {
        if (inputText.contains(kw.toString())) {
          suggestions.add(legal);
          break; // 해당 안건에서는 1개만 매칭되면 다음 안건으로 넘어감
        }
      }
      if (suggestions.length >= 3) break; // 최대 3개까지만 추천
    }
    return suggestions.toList();
  }

  // ---------------------------------------------------------
  // 🎙️ 대본 출력 섹션 (자연스러운 구어체 + 현장 행동요령 탑재)
  // ---------------------------------------------------------
  Widget _buildScriptOutput(bool isMobile) {
    String rateStr = _attendanceRate.toStringAsFixed(1); // 🌟 소수점 1자리까지 깔끔하게 표시

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.mic_external_on, color: const Color(0xFFD97706), size: isMobile ? 24 : 32),
                  const SizedBox(width: 8),
                  Text("실전 회의 프롬프터", style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), letterSpacing: -1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _isQuorumMet ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(30), border: Border.all(color: _isQuorumMet ? successGreen : dangerRed)),
                child: Row(
                  children: [
                    Icon(_isQuorumMet ? Icons.check_circle : Icons.warning_rounded, color: _isQuorumMet ? successGreen : dangerRed, size: 16),
                    const SizedBox(width: 6),
                    Text(_isQuorumMet ? "성원 달성 ($rateStr%)" : "성원 미달 ($rateStr%)", style: TextStyle(color: _isQuorumMet ? successGreen : dangerRed, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1)),

          // 🚨 공통: 마이크 켜기 전 사전 행동 요령 박스
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA), width: 2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.gavel_rounded, color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: const Text("마이크를 켜기 전, 법적 필수 사항을 확인하세요!", style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 15))),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("1. 데스크에 '최신 입주자명부'가 비치되었는지 확인합니다.\n2. 현장에 오신 분들의 신분증 대조 및 참석자 명부 서명이 완료되었는지 점검합니다.\n3. 대리 참석자의 경우, 위임장 원본과 관계 증명 서류가 취합되었는지 최종 확인합니다.\n4. 회의 시작 전 '정확한 의사록 작성을 위해 본 회의는 녹음됩니다.'\n    라고 선언한 후 스마트폰이나 녹음기를 중앙에 비치한다.\n\n※ 위 절차가 완벽히 끝난 후, 마이크를 잡아 부드럽게 시작하십시오.", style: TextStyle(color: Color(0xFF991B1B), fontSize: 14, height: 1.6)),
              ],
            ),
          ),

          // 🌟 [핵심] 기존의 안전한 멘트 출력 함수로 100% 원복!
          _isQuorumMet ? _buildScriptSuccess(isMobile) : _buildScriptFailed(isMobile),
        ],
      ),
    );
  }

  // 🟢 [상황 A] 성원 달성 (ID를 "intro_success"로 분리)
  Widget _buildScriptSuccess(bool isMobile) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildActionHint("안내 방송을 끄고 마이크를 테스트한 뒤 부드럽게 시작합니다.", isMobile),

      // 👇 여기 ID가 "intro_success" 로 변경되었습니다. (멘트는 원본 그대로 100% 동일) 👇
      _buildDialog("intro_success", "관리소장\n(담당자)", "존경하는 소유주 및 입주민 여러분, 바쁘신 와중에도 우리 단지의 더 나은 내일을 위해 오늘 회의에 참석해 주셔서 진심으로 감사드립니다.\n\n회의를 시작하기에 앞서 잠시 성원 보고를 드리겠습니다. 우리 단지 총 $_totalHouseholds세대 중, 감사하게도 '반상회' 앱을 통해 $_onlineVotes세대가 미리 전자 투표를 해주셨고, 오늘 이 현장에 $_offlineAttendees세대가 귀한 걸음을 해주셨습니다. 합계 총 $_totalAttendees세대, 출석률 ${_attendanceRate.toStringAsFixed(1)}% 로 법적 의결 정족수를 넉넉히 넘겨 성원되었음을 기쁜 마음으로 보고드립니다.\n\n이어서 우리 단지를 위해 늘 애쓰시는 회장(대표)님의 짧은 인사 말씀과 함께 정식 개회 선언이 있겠습니다.", safetyBlue, isMobile),

      _buildDialog("pres_1", "회장(대표)", "여러분, 반갑습니다. 귀한 시간 내어주셔서 대단히 감사합니다. 소장님 보고대로 성원이 완벽하게 되었으므로, 지금부터 정기 총회를 적법하게 개회하겠습니다.", primaryNavy, isMobile),
      _buildActionHint("🔨 회장님은 의사봉을 3번 두드립니다. (탕! 탕! 탕!)", isMobile),

      const SizedBox(height: 32),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)), child: const Text("📢 회의 진행 규칙 사전 안내", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 16))),
      const SizedBox(height: 16),
      _buildDialog("rules", "관리소장\n(담당자)", "본격적인 안건 심의에 앞서, 원활한 회의 진행을 위한 사전 안내 말씀 드립니다.\n\n회의 중 상정된 안건과 무관한 발언으로 회의 진행에 심각한 방해를 초래할 경우, 관련 법령 및 관리규약(의사 진행 규칙)에 따라 부득이하게 발언권 제한 및 퇴장(퇴정) 조치가 이루어질 수 있음을 양해 부탁드립니다.\n\n안건 외에 평소 궁금하셨던 점은 회의 마지막에 '기타 건의사항' 시간을 별도로 넉넉히 마련해 두었으니, 그때 자유롭게 말씀해 주시면 성심껏 답변해 드리겠습니다. 입주민 여러분의 성숙한 협조를 부탁드립니다.", safetyBlue, isMobile),

      ..._agendaEntries.asMap().entries.map((e) {
        var data = e.value;
        String spokenTitle = data["title"]!.text.replaceAll(RegExp(r'\[.*?\]\s*'), '').trim();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 40),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: Text("제 ${e.key + 1}안건 심의", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 16))),
          const SizedBox(height: 16),
          _buildDialog("agenda_${e.key}_desc", "관리소장\n(담당자)", "자, 그럼 본격적으로 오늘 준비된 안건들을 하나씩 살펴보겠습니다. 제 ${e.key + 1}안건, [$spokenTitle]에 대해 설명해 드리겠습니다.\n\n소유주 여러분, 이번 안건을 상정하게 된 배경을 짧게 말씀드리면, 다름이 아니라 ${data["reason"]!.text} 때문입니다. 입주민분들의 불편을 최소화하고 단지를 올바르게 운영하기 위해 꼭 필요한 조치입니다.\n\n이에 따라 저희 관리사무소에서는 다음과 같은 세부 방안을 준비했습니다. 화면(또는 유인물)을 봐주십시오.\n\n${data["content"]!.text}\n\n참고로 본 조치는 [${data["legal"]!.text}]에 의거하여 적법하게 진행된다는 점 안내해 드립니다. 본 안건에 대해 궁금하신 점이나 더 좋은 의견 있으시면 편하게 말씀해 주십시오.", safetyBlue, isMobile),
          _buildActionHint("⏱️ 주민들의 질의응답을 성심껏 받고 현장 찬반 거수를 진행합니다.", isMobile),
          _buildDialog("agenda_${e.key}_vote", "관리소장\n(담당자)", "충분한 논의가 된 것 같습니다. 집계 결과, 사전 온라인 투표 찬성표와 방금 해주신 현장 거수를 합산하여 과반수 찬성이 확인되었습니다. 회장님, 최종 의결해 주십시오.", safetyBlue, isMobile),
          _buildDialog("agenda_${e.key}_resolve", "회장(대표)", "네, 이상 다른 반대 의견 없으시다면 제 ${e.key + 1}안건은 원안대로 가결되었음을 선포합니다.", primaryNavy, isMobile),
          _buildActionHint("🔨 회장 의사봉 3번 타격 (탕! 탕! 탕!)", isMobile),
        ]);
      }).toList(),

      const SizedBox(height: 40),
      const Divider(),
      const SizedBox(height: 24),

      _buildDialog("close_1", "관리소장\n(담당자)", "이상으로 오늘 상정된 정식 안건에 대한 심의를 모두 마쳤습니다. 안건 통과에 협조해 주셔서 감사합니다.\n\n다음으로, 오늘 다룬 안건 외에 평소 단지 관리에 대해 궁금하셨던 점이나, 개선이 필요하다고 느끼신 '건의 사항'이 있으시면 자유롭게 말씀해 주시기 바랍니다.", safetyBlue, isMobile),
      _buildActionHint("⏱️ 주민 건의사항 청취 및 메모 (즉시 답변 가능한 것은 답변하고, 검토가 필요한 부분은 '차기 안건으로 적극 검토하겠다'고 정중히 답변합니다.)", isMobile),
      _buildDialog("close_2", "관리소장\n(담당자)", "다양한 의견과 애정 어린 조언 진심으로 감사드립니다. 오늘 주신 말씀은 저희 관리 업무에 적극 반영하도록 하겠습니다. 더 이상 의견이 없으시면, 회장님의 폐회 선언으로 오늘 자리를 마무리하겠습니다.", safetyBlue, isMobile),
      _buildDialog("close_3", "회장(대표)", "입주민 여러분, 긴 시간 정말 수고 많으셨습니다. 이것으로 오늘 회의를 모두 마치겠습니다. 조심히 돌아가십시오. 폐회를 선언합니다.", primaryNavy, isMobile),
      _buildActionHint("🔨 마지막 의사봉 3타 (탕! 탕! 탕!) 후 박수로 마무리합니다.", isMobile),
    ]);
  }

  // 🔴 [상황 B] 성원 미달 (ID를 "intro_fail"로 분리)
  Widget _buildScriptFailed(bool isMobile) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildActionHint("분위기가 가라앉지 않도록 밝고 긍정적인 톤으로 상황을 설명합니다.", isMobile),

      // 👇 여기 ID가 "intro_fail" 로 변경되었습니다. (멘트는 원본 그대로 100% 동일) 👇
      _buildDialog("intro_fail", "관리소장\n(담당자)", "존경하는 소유주 및 입주민 여러분, 바쁘신 와중에도 우리 단지를 위해 귀한 걸음 해주셔서 진심으로 감사드립니다.\n\n본 회의에 앞서 성원 현황을 확인해 본 결과, 앱 사전 투표 $_onlineVotes명, 오늘 현장 참석 $_offlineAttendees명으로 합계 총 $_totalAttendees명, 즉 출석률 ${_attendanceRate.toStringAsFixed(1)}% 에 그쳐 안타깝게도 법적 의결 정족수인 과반수에 조금 미달하였습니다.\n\n따라서 법적으로 안건을 확정 짓는 '공식 총회'는 열 수가 없게 되었습니다. 하지만 귀한 시간 내어 오신 만큼, 오늘 자리는 단지 현안에 대해 편하게 의견을 나누는 '주민 간담회'로 대신하고자 합니다. 먼저 회장님의 짧은 인사와 안내 말씀이 있겠습니다.", safetyBlue, isMobile),

      _buildActionHint("🚨 (주의) 성원이 안 되었으므로 절대로 의사봉을 치지 마십시오.", isMobile),
      _buildDialog("pres_fail", "회장(대표)", "여러분, 반갑습니다. 정족수 부족으로 오늘 안건을 통과시키지 못해 개인적으로 많이 아쉽습니다. \n\n하지만 우리 단지 발전을 위해 꼭 처리해야 할 안건들인 만큼, 소장님의 브리핑을 잘 들어주시기 바랍니다. 그리고 오늘 자정이 지나기 전에 [ O일간 ] 반상회 앱 온라인 투표 기간을 연장 오픈하겠습니다. 댁에 돌아가시면 꼭 스마트폰으로 투표해 주시고, 이웃분들에게도 적극적인 독려를 부탁드립니다.", primaryNavy, isMobile),

      const SizedBox(height: 32),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)), child: const Text("📢 간담회 진행 규칙 사전 안내", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 16))),
      const SizedBox(height: 16),
      _buildDialog("rules_fail", "관리소장\n(담당자)", "안건 브리핑에 앞서, 원활한 간담회 진행을 위한 안내 말씀 드립니다.\n\n설명 중인 안건과 무관한 발언으로 타인의 청취를 방해하거나 진행에 심각한 지장을 초래할 경우, 부득이하게 발언권이 제한되거나 퇴장 조치될 수 있음을 양해 부탁드립니다.\n\n안건 외의 질문이나 건의 사항은 브리핑이 모두 끝난 후 '기타 건의사항' 시간에 별도로 충분히 들을 예정이니, 그때 자유롭게 말씀해 주시면 감사하겠습니다.", safetyBlue, isMobile),

      _buildActionHint("⏱️ 이후 소장님이 준비된 안건의 '제안 사유'와 '주요 내용'만 간략히 브리핑합니다.", isMobile),

      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 24),

      _buildDialog("close_1_fail", "관리소장\n(담당자)", "준비된 안건에 대한 설명은 여기까지입니다. 온라인 투표에 많은 참여 부탁드립니다.\n\n혹시 설명드린 내용 외에도 단지 운영과 관련하여 평소 궁금하셨던 점이나 건의하실 내용이 있다면 편하게 말씀해 주시기 바랍니다.", safetyBlue, isMobile),
      _buildActionHint("⏱️ 주민 건의사항 청취 및 메모 (즉시 답변 가능한 것은 답변하고, 검토가 필요한 부분은 '적극 검토하겠다'고 정중히 답변합니다.)", isMobile),
      _buildDialog("close_2_fail", "관리소장\n(담당자)", "다양한 의견 주셔서 대단히 감사합니다. 오늘 주신 귀한 말씀은 관리 업무에 꼼꼼히 반영하도록 하겠습니다. 이상으로 주민 간담회를 모두 마치겠습니다. 조심히 돌아가십시오.", safetyBlue, isMobile),
      _buildActionHint("👏 참석자들에게 감사 인사를 전하며 박수로 마무리합니다. (앱 추가 투표 알림톡 발송 준비)", isMobile),
    ]);
  }

  // 🛠️ UI 헬퍼 메서드들
  Widget _buildCardWrapper({required String title, required IconData icon, required bool isMobile, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: textMain, size: 24), const SizedBox(width: 12), Expanded(child: Text(title, style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: textMain, letterSpacing: -0.5)))]),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
          child,
        ],
      ),
    );
  }

  Widget _buildLabelTextField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
        _buildModernTextField(ctrl, null, "", icon, isNumber: isNumber),
      ],
    );
  }

  Widget _buildModernTextField(TextEditingController ctrl, FocusNode? node, String hint, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl, focusNode: node, keyboardType: isNumber ? TextInputType.number : TextInputType.multiline, maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      ),
    );
  }

  // 🌟 [핵심] 이제부터 각 대본은 고유한 'id'를 가집니다.
  Widget _buildDialog(String id, String speaker, String text, Color color, bool isMobile) {
    // 바구니(_userEdits)에 담당자가 수정한 내용이 있으면 그걸 쓰고, 없으면 기본 멘트를 씁니다!
    String actualText = _userEdits[id] ?? text;

    return EditableDialogBubble(
      key: ValueKey(id), // 🌟 화면이 새로고침 돼도 멘트가 섞이지 않게 고정
      speaker: speaker,
      initialText: actualText,
      color: color,
      isMobile: isMobile,
      onChanged: (newText) {
        // 담당자가 화면에서 타자를 쳐서 수정하면, 즉시 바구니에 영구 저장됩니다!
        _userEdits[id] = newText;
      },
    );
  }

  Widget _buildActionHint(String hint, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(left: isMobile ? 0 : 116, bottom: 24), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(8)),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 2.0), child: Icon(Icons.touch_app, color: Color(0xFFD97706), size: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text(hint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB45309), height: 1.5)))
          ]
      ),
    );
  }
}

// ---------------------------------------------------------
// 🌟 [추가] 더블 탭 시 수정 가능한 실시간 대본 버블 위젯
// ---------------------------------------------------------
class EditableDialogBubble extends StatefulWidget {
  final String speaker;
  final String initialText;
  final Color color;
  final bool isMobile;
  final Function(String)? onChanged; // 🌟 1. 이 줄이 반드시 추가되어야 합니다!

  const EditableDialogBubble({
    super.key,
    required this.speaker,
    required this.initialText,
    required this.color,
    required this.isMobile,
    this.onChanged, // 🌟 2. 생성자 연결
  });

  @override
  State<EditableDialogBubble> createState() => _EditableDialogBubbleState();
}

class _EditableDialogBubbleState extends State<EditableDialogBubble> {
  late TextEditingController _controller;
  bool _isEditing = false;
  late String _currentText;

  @override
  void initState() {
    super.initState();
    _currentText = widget.initialText;
    _controller = TextEditingController(text: _currentText);
  }

  // 🌟 3. 부모가 텍스트(숫자)를 강제로 바꿔주면 즉시 반응하는 엔진 추가!
  @override
  void didUpdateWidget(EditableDialogBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      _currentText = widget.initialText;
      _controller.text = _currentText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveText() {
    setState(() {
      _currentText = _controller.text;
      _isEditing = false;
    });
    // 🌟 4. 내가 타자 친 글씨를 부모(바구니)에게 전송하여 영구 저장!
    if (widget.onChanged != null) {
      widget.onChanged!(_currentText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: widget.isMobile ? 80 : 100, padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]),
            child: Text(widget.speaker, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: -0.5, height: 1.3)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _isEditing
                ? Container(
              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2563EB), width: 2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(controller: _controller, maxLines: null, style: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFF334155)), decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: "수정할 멘트를 입력하세요.")),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(onPressed: _saveText, icon: const Icon(Icons.check, size: 16, color: Colors.white), label: const Text("저장", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), minimumSize: const Size(80, 36)))
                ],
              ),
            )
                : GestureDetector(
              onDoubleTap: () { setState(() { _controller.text = _currentText; _isEditing = true; }); },
              child: Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Stack(
                  children: [
                    Text(_currentText, style: const TextStyle(fontSize: 17, height: 1.6, fontWeight: FontWeight.w500, color: Color(0xFF334155), letterSpacing: -0.3)),
                    Positioned(right: 0, bottom: 0, child: Tooltip(message: "더블 탭하여 멘트 수정", child: Icon(Icons.edit, size: 16, color: Colors.grey.withOpacity(0.4))))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 🌟 [추가] 5개씩 페이징 & 실시간 검색이 지원되는 스마트 다이얼로그
// ---------------------------------------------------------
class AgendaSearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> dbTemplates;

  const AgendaSearchDialog({super.key, required this.dbTemplates});

  @override
  State<AgendaSearchDialog> createState() => _AgendaSearchDialogState();
}

class _AgendaSearchDialogState extends State<AgendaSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filteredList = [];

  int _currentPage = 0;
  final int _itemsPerPage = 5; // 🌟 한 페이지에 5개씩!

  @override
  void initState() {
    super.initState();
    _filteredList = List.from(widget.dbTemplates); // 처음엔 100개 전체 세팅
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // 검색 필터링 로직
  void _runSearch(String query) {
    setState(() {
      _currentPage = 0; // 검색하면 무조건 1페이지로 리셋
      if (query.isEmpty) {
        _filteredList = List.from(widget.dbTemplates);
      } else {
        _filteredList = widget.dbTemplates.where((item) {
          final title = (item['title'] ?? '').toString().toLowerCase();
          final reason = (item['reason'] ?? '').toString().toLowerCase();
          final keywordList = (item['keywords'] as List<dynamic>? ?? []).join(" ").toLowerCase();
          final q = query.toLowerCase();

          return title.contains(q) || reason.contains(q) || keywordList.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 모바일 뷰어 감지 (팝업창 크기 대응)
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    // 페이징 계산
    int totalItems = _filteredList.length;
    int totalPages = (totalItems / _itemsPerPage).ceil();
    int startIndex = _currentPage * _itemsPerPage;
    int endIndex = (startIndex + _itemsPerPage > totalItems) ? totalItems : startIndex + _itemsPerPage;

    List<Map<String, dynamic>> pageItems = _filteredList.isEmpty ? [] : _filteredList.sublist(startIndex, endIndex);

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 700,
        height: isMobile ? MediaQuery.of(context).size.height * 0.8 : 750, // 모바일에서는 화면 높이의 80%만 사용
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.manage_search, color: const Color(0xFF2563EB), size: isMobile ? 24 : 32),
                const SizedBox(width: 12),
                Text("표준 안건 스마트 검색", style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 16),

            // 🌟 검색창
            TextField(
              controller: _searchCtrl,
              onChanged: _runSearch,
              decoration: InputDecoration(
                hintText: "키워드나 상황을 검색하세요 (예: 주차장, 누수)",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                filled: true, fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Text("검색 결과: 총 $totalItems건", style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            const Divider(),

            // 🌟 검색 결과 리스트 (5개씩)
            Expanded(
              child: pageItems.isEmpty
                  ? const Center(child: Text("검색 결과가 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.builder(
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  var data = pageItems[index];
                  return Card(
                    elevation: 0, color: const Color(0xFFF8FAFC),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text("[${data['category'] ?? '일반'}] ${data['title']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(data['reason'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569))),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.pop(context, data), // 🌟 선택한 데이터를 부모 창으로 전달!
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("선택", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🌟 페이징 네비게이션바
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    ),
                    Text(" ${_currentPage + 1} / $totalPages ", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("닫기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            )
          ],
        ),
      ),
    );
  }
}