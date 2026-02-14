// [파일 위치: lib/main.dart]
// [페이지 기능: SM 서비스 매니지먼트 통합 레이아웃 및 실시간 알림 관리]
// 수정 내용:
// 1. [UX 고도화] 메뉴 중복 클릭 시 해당 페이지 데이터 새로고침(Refresh) 기능 추가
// 2. [레이아웃] IndexedStack을 Expanded로 감싸 페이지 하단 터짐 방지
// 3. [로직] 미완료 업무 카운팅 및 배지 디자인(DeepOrange) 적용

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

import 'theme/app_theme.dart';

// 페이지 임포트
import 'pages/dashboard/dashboard_page.dart';
import 'pages/sales/sales_write_page.dart';
import 'pages/sales/sales_list_page.dart';
import 'pages/sales/checklist_page.dart';
import 'pages/chat/chat_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/login_page.dart';
import 'pages/admin_page.dart';
import 'pages/field/field_route_page.dart';
import 'pages/building_info_page.dart';
import 'pages/field/field_schedule_page.dart';
import 'pages/field/field_report_page.dart';

import 'services/auth_service.dart';
import 'services/sales_service.dart';

// 네이버 지도 전역 컨트롤러
NaverMapController? globalMapController;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    try {
      await NaverMapSdk.instance.initialize(
          clientId: 's9qk2rcdyp',
          onAuthFailed: (ex) {
            print("********* 네이버 지도 인증 실패: $ex *********");
          }
      );
    } catch (e) {
      print("********* 네이버 지도 초기화 오류: $e *********");
    }
  }

  runApp(const SMSalesNoteApp());
}

class SMSalesNoteApp extends StatelessWidget {
  const SMSalesNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SM Service Management',
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) return const MainLayoutPage();
          return const LoginPage();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});
  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _selectedIndex = 0;
  final SalesService _salesService = SalesService();
  final PageController _pageController = PageController();
  late final Widget _permanentNaverMap;
  late final List<Widget> _pages;

  // ✅ [고도화] 각 페이지의 새로고침 함수를 호출하기 위한 고유 키(Key) 정의
  final GlobalKey<FieldReportPageState> _reportPageKey = GlobalKey<FieldReportPageState>();
  final GlobalKey<FieldSchedulePageState> _schedulePageKey = GlobalKey<FieldSchedulePageState>();
  final GlobalKey<FieldRoutePageState> _routePageKey = GlobalKey<FieldRoutePageState>();
  final GlobalKey<DashboardPageState> _dashboardKey = GlobalKey<DashboardPageState>();

  bool _isFieldSupportExpanded = false;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _permanentNaverMap = const SizedBox.shrink();
    } else {
      _permanentNaverMap = NaverMap(
        options: const NaverMapViewOptions(locationButtonEnable: true, consumeSymbolTapEvents: false),
        onMapReady: (controller) => globalMapController = controller,
      );
    }

    // ✅ [고도화] 페이지 생성 시 정의한 Key를 전달합니다. (나중에 각 페이지 파일 수정 필요)
    _pages = [
      DashboardPage(key: _dashboardKey),
      SalesWritePage(onSaved: () => _onMenuSelected(2)),
      SalesListPage(),
      const AdminPage(),
      const ChecklistPage(),
      const ChatPage(),
      const SettingsPage(),
      FieldRoutePage(key: _routePageKey),
      const BuildingInfoPage(),
      FieldSchedulePage(key: _schedulePageKey),
      FieldReportPage(key: _reportPageKey),
    ];
  }

  // ✅ [핵심 고도화] 메뉴 선택 로직 수정
  void _onMenuSelected(int index) async {
    final isMobile = MediaQuery.of(context).size.width < 900;

    // 1. 이미 같은 메뉴가 선택된 상태에서 또 눌렀을 때 (새로고침 로직)
    if (_selectedIndex == index) {
      _triggerPageRefresh(index); // 새로고침 신호 발생
      if (isMobile) Navigator.pop(context); // 모바일은 메뉴 닫기
      return;
    }

    // 2. 다른 메뉴로 이동할 때
    if (_selectedIndex == 5 && index != 5) {
      await _salesService.updateLastReadTime();
    }

    if (!mounted) return;

    setState(() => _selectedIndex = index);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }

    if (index == 5) {
      await _salesService.updateLastReadTime();
    } else if (index == 7) {
      // 경로 관리 페이지는 진입 시 자동 갱신
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_routePageKey.currentState?.mounted == true) {
          _routePageKey.currentState?.refreshRoute();
        }
      });
    }

    if (isMobile) {
      Navigator.pop(context);
    }
  }

  // ✅ [신규] 특정 페이지의 새로고침(Refresh) 명령을 내리는 함수
  void _triggerPageRefresh(int index) {
    switch (index) {
      case 0: _dashboardKey.currentState?.refreshData(); break; // 대시보드
      case 9: _schedulePageKey.currentState?.refreshData(); break; // 일정관리
      case 10: _reportPageKey.currentState?.refreshData(); break; // 업무보고
    // 필요에 따라 다른 페이지 키도 추가 가능
    }
  }

  void _logout() { AuthService().logout(); }

  String _getTitleByIndex(int index) {
    switch(index) {
      case 0: return 'SM 종합 현황판';
      case 1: return '새 노트작성';
      case 2: return '노트관리';
      case 3: return '관리자 설정';
      case 4: return '체크리스트';
      case 5: return '업무 톡톡';
      case 6: return '설정';
      case 7: return '경로 관리 (AI)';
      case 8: return '건물 DB 정보';
      case 9: return '일정 관리';
      case 10: return '업무 보고';
      default: return '';
    }
  }

  Stream<int> _getOverdueWorkCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('schedules')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      DateTime today = DateTime.now();
      DateTime todayBase = DateTime(today.year, today.month, today.day);

      return snapshot.docs.where((doc) {
        final data = doc.data();
        DateTime start = (data['startDate'] as Timestamp?)?.toDate() ??
            (data['date'] as Timestamp?)?.toDate() ??
            DateTime.now();
        DateTime end = (data['endDate'] as Timestamp?)?.toDate() ?? start;
        DateTime endDateBase = DateTime(end.year, end.month, end.day);
        return endDateBase.isBefore(todayBase) && data['status'] != 'completed';
      }).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        String userName = userData?['name'] ?? '사용자';
        String userRank = userData?['rank'] ?? '';
        bool isAdmin = (userData?['role'] ?? 'user') == 'admin';

        if (!isAdmin && _selectedIndex == 3) {
          WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _onMenuSelected(0); });
        }

        Widget menuContent = Container(
          color: AppTheme.surfaceColor,
          child: Column(
            children: [
              Container(
                  height: 80,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.business_center, size: 28, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('SM Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                          Text('Management', style: TextStyle(fontSize: 12, color: AppTheme.textSub)),
                        ],
                      )
                    ],
                  )
              ),
              const Divider(height: 1, color: AppTheme.borderColor),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      _buildMenuItem(icon: Icons.dashboard_outlined, title: '대시보드', index: 0),
                      _buildMenuItem(icon: Icons.edit_note, title: '새 노트작성', index: 1),
                      _buildMenuItem(icon: Icons.article_outlined, title: '노트관리', index: 2),
                      _buildMenuItem(icon: Icons.playlist_add_check_circle_outlined, title: '체크리스트', index: 4),

                      StreamBuilder<int>(
                        stream: _salesService.getUnreadMessageCountStream(),
                        builder: (context, snap) => _buildMenuItem(
                            icon: Icons.chat_bubble_outline,
                            title: '업무 톡톡',
                            index: 5,
                            badgeCount: _selectedIndex == 5 ? 0 : (snap.data ?? 0)
                        ),
                      ),

                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: const PageStorageKey('FieldSupportMenu'),
                          leading: const Icon(Icons.map_outlined, size: 22),
                          title: const Text("현장팀 업무지원", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          initiallyExpanded: _isFieldSupportExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _isFieldSupportExpanded = expanded;
                            });
                          },
                          iconColor: AppTheme.primaryColor,
                          collapsedIconColor: AppTheme.textSub,
                          children: [
                            _buildSubMenuItem(icon: Icons.calendar_today, title: "일정 관리", index: 9),
                            _buildSubMenuItem(icon: Icons.alt_route, title: "경로 관리 (AI)", index: 7),
                            StreamBuilder<int>(
                              stream: _getOverdueWorkCountStream(),
                              builder: (context, snap) => _buildSubMenuItem(
                                  icon: Icons.assignment_outlined,
                                  title: "업무 보고",
                                  index: 10,
                                  badgeCount: snap.data ?? 0
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 32, indent: 24, endIndent: 24, color: AppTheme.borderColor),
                      _buildMenuItem(icon: Icons.business, title: '건물 DB 정보', index: 8),
                      _buildMenuItem(icon: Icons.settings_outlined, title: '설정', index: 6),
                      if (isAdmin) _buildMenuItem(icon: Icons.admin_panel_settings_outlined, title: '관리자 설정', index: 3),
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppTheme.textSub),
                        title: const Text("로그아웃", style: TextStyle(color: AppTheme.textSub, fontSize: 14)),
                        onTap: _logout,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          appBar: isWideScreen ? null : AppBar(title: Text(_getTitleByIndex(_selectedIndex))),
          drawer: isWideScreen ? null : Drawer(child: menuContent),
          body: Row(
            children: [
              if (isWideScreen) SizedBox(width: 260, child: menuContent),
              Expanded(
                child: Stack(
                  children: [
                    if (!kIsWeb) Offstage(offstage: _selectedIndex != 7, child: _permanentNaverMap),
                    Container(
                      color: (_selectedIndex == 7 && !kIsWeb) ? Colors.transparent : AppTheme.backgroundColor,
                      child: Column(
                        children: [
                          if (isWideScreen)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              color: AppTheme.surfaceColor,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_getTitleByIndex(_selectedIndex), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        CircleAvatar(backgroundColor: AppTheme.primaryLight, radius: 16, child: Text(userName.isNotEmpty ? userName[0] : 'U', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 14))),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text(userRank, style: const TextStyle(color: AppTheme.textSub, fontSize: 12))
                                          ],
                                        )
                                      ],
                                    )
                                  ]
                              ),
                            ),
                          if (isWideScreen) const Divider(height: 1, color: AppTheme.borderColor),

                          Expanded(
                            child: IndexedStack(
                              index: _selectedIndex,
                              children: _pages,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required int index, int badgeCount = 0}) {
    final bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => _onMenuSelected(index),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(color: isSelected ? AppTheme.primaryLight : Colors.transparent, borderRadius: BorderRadius.circular(50)),
          child: Row(
              children: [
                Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.textSub, size: 22),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? AppTheme.primaryColor : AppTheme.textMain, fontSize: 14))),
                if (badgeCount > 0)
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(badgeCount > 99 ? "99+" : "$badgeCount", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                  )
              ]
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem({required IconData icon, required String title, required int index, int badgeCount = 0}) {
    final bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => _onMenuSelected(index),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.only(left: 56, top: 10, bottom: 10, right: 16),
          decoration: BoxDecoration(color: isSelected ? AppTheme.primaryLight : Colors.transparent, borderRadius: BorderRadius.circular(50)),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppTheme.primaryColor : AppTheme.textSub),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(color: isSelected ? AppTheme.primaryColor : AppTheme.textMain, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14))),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
                  child: Text("$badgeCount", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
      ),
    );
  }
}