// [파일 위치: lib/main.dart]
// [최종 수정 내용]
// 1. [Feature] 알림 팝업 내 '모두 삭제(안 읽은 알림 포함)' 기능 추가 및 버튼 스타일 수정
// 2. [Feature] 앱 실행 중 소리/진동/상단배너 알림 로직 통합 (flutter_local_notifications)
// 3. [Fix] 모바일 우측 상단 배치, 흰색 화면 버그, 버튼 스타일 에러 등 모든 이슈 해결
// 4. [Maintenance] 기존 기능(지도, 메뉴, 화면 이동 등) 100% 유지

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'dart:async'; // StreamSubscription 사용

// ✅ 알림/진동 패키지
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import 'theme/app_theme.dart';
import 'services/notification_service.dart';

// 페이지(Page) 임포트
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

NaverMapController? globalMapController;

// ✅ 알림 플러그인 인스턴스
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 알림 서비스 초기화
  await NotificationService().init();

  // ✅ 로컬 알림(소리/진동) 초기화 설정
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  if (!kIsWeb) {
    try {
      await NaverMapSdk.instance.initialize(
          clientId: 's9qk2rcdyp',
          onAuthFailed: (ex) {
            print("********* 네이버 지도 인증 실패: $ex *********");
          });
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

  // ✅ 알림 리스너 관리
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

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
      SalesWritePage(onSaved: () => _onMenuSelected(2, isDrawerClick: false)),
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

    // ✅ 앱 실행 중 실시간 알림 감지 시작 (소리/진동)
    _listenToNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // ✅ Firestore 실시간 감지 -> 소리/진동/배너 실행
  void _listenToNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetUid', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // 1. 진동
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate();
          }
          // 2. 상단 배너 알림
          final data = change.doc.data() as Map<String, dynamic>;
          _showLocalNotification(
            title: data['title'] ?? '새 알림',
            body: data['body'] ?? '내용이 있습니다.',
          );
        }
      }
    });
  }

  Future<void> _showLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, title, body, platformChannelSpecifics,
    );
  }

  // ✅ 메뉴 선택 함수 (흰색 화면 버그 해결)
  void _onMenuSelected(int index, {bool isDrawerClick = true}) async {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (_selectedIndex == index) {
      _triggerPageRefresh(index);
      if (isMobile && isDrawerClick) Navigator.pop(context);
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

    if (isMobile && isDrawerClick) {
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

  // ✅ [기존] 읽은 알림만 삭제
  Future<void> _deleteReadNotifications(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('targetUid', isEqualTo: user.uid)
          .where('isRead', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제할 읽은 알림이 없습니다.")));
        return;
      }
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) { batch.delete(doc.reference); }
      await batch.commit();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("읽은 알림을 삭제했습니다.")));
    } catch (e) { print("알림 삭제 오류: $e"); }
  }

  // ✅ [신규] '모두 삭제' 기능 (안 읽은 것도 포함)
  Future<void> _deleteAllNotifications(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      // 읽음/안읽음 구분 없이 나에게 온 모든 알림 조회
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('targetUid', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제할 알림이 없습니다.")));
        return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) { batch.delete(doc.reference); }
      await batch.commit();

      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("모든 알림을 삭제했습니다.")));
    } catch (e) { print("전체 삭제 오류: $e"); }
  }

  void _showNotificationList(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("최신 알림", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          height: 450,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('targetUid', isEqualTo: user.uid)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
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
                      await docs[index].reference.update({'isRead': true});
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _handleNotificationClick(data['type']);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          // ✅ [신규] 모두 삭제 버튼 (빨간색)
          TextButton(
            onPressed: () async { await _deleteAllNotifications(context); },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              // ✅ [수정] 스타일 에러 해결 (fontWeight를 textStyle 안으로)
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text("모두 삭제"),
          ),
          // ✅ [기존] 읽은 알림 삭제 버튼
          TextButton(
            onPressed: () async { await _deleteReadNotifications(context); },
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("읽은 알림 삭제"),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))
        ],
      ),
    );
  }

  void _handleNotificationClick(String? type) {
    switch (type) {
      case 'schedule': _onMenuSelected(9, isDrawerClick: false); break;
      case 'chat': _onMenuSelected(5, isDrawerClick: false); break;
      case 'report': _onMenuSelected(10, isDrawerClick: false); break;
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
          WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _onMenuSelected(0, isDrawerClick: false); });
        }

        // 알림 버튼 (배지 포함)
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

        // 유저 정보 위젯
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
          // ✅ [모바일] 앱바 우측 상단에 알림/정보 배치
          appBar: isWideScreen
              ? null
              : AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: AppTheme.textMain),
            title: Text(
                _getTitleByIndex(_selectedIndex),
                style: const TextStyle(color: AppTheme.textMain, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            centerTitle: false,
            actions: [
              notificationButton,
              const SizedBox(width: 8),
              userInfoWidget,
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
                                        notificationButton,
                                        const SizedBox(width: 20),
                                        userInfoWidget,
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