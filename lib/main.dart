// [파일 위치: lib/main.dart]
// [페이지 기능: SM 서비스 매니지먼트 통합 레이아웃 및 실시간 알림 관리]
// 수정 내용:
// 1. [고도화] 알림 팝업에 '읽은 알림 전체 삭제' 기능 추가 (일괄 삭제 로직)
// 2. [기존 유지] 알림 배지, 팝업 목록(최신순), 네이버 지도, 메뉴 등 100% 동일

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅용
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

import 'theme/app_theme.dart';
import 'services/notification_service.dart';

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

  // 알림 서비스 초기화
  await NotificationService().init();

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

    _pages = [
      DashboardPage(key: _dashboardKey),
      SalesWritePage(onSaved: () => _onMenuSelected(2)),
      SalesListPage(),
      const AdminPage(),
      const ChecklistPage(),
      ChatPage(isVisible: _selectedIndex == 5),
      const SettingsPage(),
      FieldRoutePage(key: _routePageKey),
      const BuildingInfoPage(),
      FieldSchedulePage(key: _schedulePageKey),
      FieldReportPage(key: _reportPageKey),
    ];
  }

  void _onMenuSelected(int index) async {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (_selectedIndex == index) {
      _triggerPageRefresh(index);
      if (isMobile) Navigator.pop(context);
      return;
    }

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

  void _triggerPageRefresh(int index) {
    switch (index) {
      case 0: _dashboardKey.currentState?.refreshData(); break;
      case 9: _schedulePageKey.currentState?.refreshData(); break;
      case 10: _reportPageKey.currentState?.refreshData(); break;
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

  // 배지 카운트용 (정렬 없음 - 에러 방지)
  Stream<int> _getUnreadNotificationCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('targetUid', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ✅ [신규] 읽은 알림 일괄 삭제 함수
  Future<void> _deleteReadNotifications(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. 내 알림 중 '읽음(true)' 처리된 것만 가져오기
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('targetUid', isEqualTo: user.uid)
          .where('isRead', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제할 읽은 알림이 없습니다.")));
        }
        return;
      }

      // 2. 일괄 삭제 (Batch) 실행
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("읽은 알림을 모두 삭제했습니다.")));
      }
    } catch (e) {
      print("알림 삭제 중 오류: $e");
    }
  }

  // 알림 목록 팝업 (정렬 없음 - 즉시 표시)
  void _showNotificationList(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("최신 알림", style: TextStyle(fontWeight: FontWeight.bold)),
            // 카운트 표시 (선택 사항)
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 450,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('targetUid', isEqualTo: user.uid)
                .limit(20) // 최신 20개만 로드 (정렬은 메모리에서)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];

              // 메모리상 최신순 정렬
              docs.sort((a, b) {
                Timestamp t1 = a['createdAt'] ?? Timestamp.now();
                Timestamp t2 = b['createdAt'] ?? Timestamp.now();
                return t2.compareTo(t1);
              });

              if (docs.isEmpty) return const Center(child: Text("새로운 알림이 없습니다.", style: TextStyle(color: Colors.grey)));

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final bool isRead = data['isRead'] ?? false;
                  final DateTime time = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead ? Colors.grey[100] : AppTheme.primaryLight,
                      child: Icon(Icons.notifications_active, color: isRead ? Colors.grey : AppTheme.primaryColor, size: 20),
                    ),
                    title: Text(data['title'] ?? '알림', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['body'] ?? '', style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(DateFormat('MM.dd HH:mm').format(time), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    onTap: () async {
                      // 1. 읽음 처리
                      await docs[index].reference.update({'isRead': true});
                      if (!mounted) return;
                      Navigator.pop(ctx);

                      // 2. 페이지 이동
                      _handleNotificationClick(data['type']);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          // ✅ [추가됨] 읽은 알림 삭제 버튼
          TextButton(
            onPressed: () async {
              await _deleteReadNotifications(context);
              // 삭제 후 팝업 유지 (목록이 갱신됨)
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text("읽은 알림 삭제"),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))
        ],
      ),
    );
  }

  void _handleNotificationClick(String? type) {
    switch (type) {
      case 'schedule': _onMenuSelected(9); break;
      case 'chat': _onMenuSelected(5); break;
      case 'report': _onMenuSelected(10); break;
      default: break;
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
        DateTime start = (data['startDate'] as Timestamp?)?.toDate() ?? (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        DateTime end = (data['endDate'] as Timestamp?)?.toDate() ?? start;
        DateTime endDateBase = DateTime(end.year, end.month, end.day);
        return endDateBase.isBefore(todayBase) && data['status'] != 'completed';
      }).length;
    });
  }

  // [파일 위치: lib/main.dart]
// _MainLayoutPageState 클래스 내부

  @override
  Widget build(BuildContext context) {
    // 반응형 기준점 설정 (900px 기준)
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        // 유저 정보 가져오기
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        String userName = userData?['name'] ?? '사용자';
        String userRank = userData?['rank'] ?? '';
        bool isAdmin = (userData?['role'] ?? 'user') == 'admin';

        // 관리자가 아닌데 관리자 페이지 접속 시 대시보드로 이동
        if (!isAdmin && _selectedIndex == 3) {
          WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _onMenuSelected(0); });
        }

        // ---------------------------------------------------------------
        // ✅ [1. 공통 위젯 분리] 알림 버튼 (배지 포함)
        // ---------------------------------------------------------------
        Widget notificationButton = StreamBuilder<int>(
          stream: _getUnreadNotificationCountStream(),
          builder: (context, snap) {
            int count = snap.data ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: AppTheme.textMain),
                  onPressed: () => _showNotificationList(context),
                  tooltip: "알림 확인",
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                    ),
                  )
              ],
            );
          },
        );

        // ---------------------------------------------------------------
        // ✅ [2. 공통 위젯 분리] 유저 정보 (이름 + 직급)
        // ---------------------------------------------------------------
        Widget userInfoWidget = Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              radius: 16,
              child: Text(userName.isNotEmpty ? userName[0] : 'U', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 14)),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain)),
                if (userRank.isNotEmpty)
                  Text(userRank, style: const TextStyle(color: AppTheme.textSub, fontSize: 11))
              ],
            )
          ],
        );

        // 사이드 메뉴 컨텐츠
        Widget menuContent = Container(
          color: AppTheme.surfaceColor,
          child: Column(
            children: [
              Container(
                  height: 110,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Image.asset('assets/images/sm_logo.png', height: 65, fit: BoxFit.contain)
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
                          onExpansionChanged: (expanded) => setState(() => _isFieldSupportExpanded = expanded),
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
          // ---------------------------------------------------------------
          // ✅ [3. 모바일/태블릿 상단바 고도화] 좌측 상단에 알림+유저정보 배치
          // ---------------------------------------------------------------
          appBar: isWideScreen
              ? null // PC 화면에서는 AppBar 제거 (Body에 통합)
              : AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: AppTheme.textMain),
            titleSpacing: 0, // 메뉴 아이콘과 타이틀 사이 간격 좁힘
            centerTitle: false, // 왼쪽 정렬 강제
            title: Row(
              children: [
                // 요청하신 대로: 종모양 -> 유저 정보 순서로 좌측 상단 배치
                notificationButton,
                const SizedBox(width: 4),
                userInfoWidget,
              ],
            ),
            actions: [
              // 우측 공간이 비어보이면 로고 등을 넣을 수 있음 (현재는 비워둠)
              const SizedBox(width: 16),
            ],
          ),
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
                          // ---------------------------------------------------------------
                          // ✅ [4. 헤더 반응형 처리]
                          // PC: 페이지 제목 + (알림+유저정보) 우측 배치
                          // 모바일: 페이지 제목만 표시 (알림+유저정보는 앱바에 있음)
                          // ---------------------------------------------------------------
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            color: AppTheme.surfaceColor,
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 페이지 제목
                                  Text(_getTitleByIndex(_selectedIndex), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                                  // PC 환경일 때만 우측에 알림+유저정보 표시 (모바일은 앱바에 있으므로 숨김)
                                  if (isWideScreen)
                                    Row(
                                      children: [
                                        notificationButton,
                                        const SizedBox(width: 20),
                                        userInfoWidget,
                                      ],
                                    )
                                ]
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.borderColor),

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