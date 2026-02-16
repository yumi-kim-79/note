// [파일 위치: lib/main.dart]
// [최종 수정 완료] 2026-02-15
// 1. [Fix] 'const' 에러 해결 -> 'final'로 변경하여 변수 할당 허용
// 2. [Fix] 네이버 지도 -> 기존 'NaverMapSdk'로 원복하여 빨간 에러 해결
// 3. [Logic] 웹(PWA) 포그라운드 충돌 해결 (초기화 안 된 FLN 호출 방지)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 필수
import 'dart:async';

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

final GlobalKey<MainLayoutPageState> mainLayoutKey = GlobalKey<MainLayoutPageState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// ✅ 안드로이드 알림 채널 정의
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  '중요한 업무 알림',
  description: '업무 톡톡 및 일정 알림을 위한 채널입니다.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// =======================================================
// 🌙 [백그라운드 핸들러] 앱이 꺼져있을 때(Background/Terminated) 알림 생성
// =======================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 웹에서는 이 핸들러가 실행되지 않으므로 바로 종료
  if (kIsWeb) return;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("🌙 [App 백그라운드] 메시지 수신: ${message.messageId}");

  final FlutterLocalNotificationsPlugin backPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initIOS = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initSettings = InitializationSettings(android: initAndroid, iOS: initIOS);
  await backPlugin.initialize(initSettings);

  final data = message.data;

  // 알림 채널 세부 설정
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high
  );

  // 백그라운드에서 직접 알림 표시
  await backPlugin.show(
      DateTime.now().millisecond,
      data['title'] ?? '알림',
      data['body'] ?? '내용',
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      payload: data['type']
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService().init();

  // ✅ [Web 호환성] 웹이 아닐 때만 네이티브 알림 플러그인 초기화
  if (!kIsWeb) {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? type = response.payload;
        if (type != null) {
          debugPrint("🔔 [포그라운드 알림 탭] 이동 요청 타입: $type");
          mainLayoutKey.currentState?.handleNotificationClick(type);
        }
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } else {
    // 웹일 경우 권한 요청만 수행
    await FirebaseMessaging.instance.requestPermission();
  }

  // FCM 포그라운드 리스너 (로그 확인용)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📱 [FCM] 포그라운드 수신: ${message.data}");
  });

  // ✅ 네이버 지도 초기화 (웹 제외)
  if (!kIsWeb) {
    try {
      // ignore: deprecated_member_use
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
          if (snapshot.hasData) return MainLayoutPage(key: mainLayoutKey);
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
  State<MainLayoutPage> createState() => MainLayoutPageState();
}

class MainLayoutPageState extends State<MainLayoutPage> {
  int _selectedIndex = 0;
  final SalesService _salesService = SalesService();
  final PageController _pageController = PageController();
  late final Widget _permanentNaverMap;
  late final List<Widget> _pages;

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

    _listenToNotifications(); // 포그라운드 처리
    _setupInteractedMessage(); // 백그라운드 처리
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 앱(App) 환경에서만 로컬 알림 클릭 체크
    if (!kIsWeb) {
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final response = notificationAppLaunchDetails!.notificationResponse;
        if (response != null && response.payload != null) {
          handleNotificationClick(response.payload);
        }
      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    String? type = message.data['type'];
    if (type == null && message.notification != null) {
      if (message.notification!.title!.contains('메시지')) type = 'chat';
    }
    if (type != null) {
      debugPrint("🚀 [백그라운드 알림 클릭] 이동 요청: $type");
      handleNotificationClick(type);
    }
  }

  void handleNotificationClick(String? type) {
    if (type == null) return;

    int pageIndex = -1;
    switch (type) {
      case 'chat': pageIndex = 5; break;
      case 'schedule': pageIndex = 9; break;
      case 'report': pageIndex = 10; break;
      default: debugPrint("알 수 없는 알림 타입: $type");
    }

    if (pageIndex != -1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if(mounted) _onMenuSelected(pageIndex, isDrawerClick: false);
      });
    }
  }

  // ✅ [수정] 포그라운드 알림 리스너 (DB 변경 감지)
  void _listenToNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetUid', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {

      bool canVibrate = true;
      bool canSound = true;

      // 앱 환경에서만 설정값 로드
      if (!kIsWeb) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final settings = userDoc.data() as Map<String, dynamic>?;
        canVibrate = settings?['isVibrate'] ?? true;
        canSound = settings?['isSound'] ?? true;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final String type = data['type'] ?? '';

          // 🚀 [중요 수정] 웹(Web)일 때와 앱(App)일 때 처리를 분리
          if (kIsWeb) {
            // [Web] 하단 SnackBar 삭제됨 (요청사항 반영)
            // [Web] 화면을 보고 있을 때는 알림 팝업 없음. (빨간 뱃지만 업데이트 됨)
            // [Web] 진동은 가능하면 실행
            if (canVibrate) {
              // 웹 진동은 브라우저 정책에 따라 안 될 수도 있음 (무시해도 됨)
              // Vibration.vibrate();
            }
          } else {
            // [App] 모바일 앱에서는 네이티브 알림(상단 배너 + 소리/진동) 실행
            if (canVibrate) {
              Vibration.hasVibrator().then((has) { if (has == true) Vibration.vibrate(); });
            }
            if (canSound) {
              _showLocalNotification(
                title: data['title'] ?? '새 알림',
                body: data['body'] ?? '내용이 있습니다.',
                payload: type,
              );
            }
          }
        }
      }
    });
  }

  Future<void> _showLocalNotification(
      {required String title, required String body, String? payload}) async {

    // ⚠️ 웹에서는 이 함수를 호출하지 않도록 안전장치
    if (kIsWeb) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

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
    switch (index) {
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
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("삭제할 읽은 알림이 없습니다.")));
        return;
      }
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("읽은 알림을 삭제했습니다.")));
    } catch (e) {
      print("알림 삭제 오류: $e");
    }
  }

  Future<void> _deleteAllNotifications(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('targetUid', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("삭제할 알림이 없습니다.")));
        return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("모든 알림을 삭제했습니다.")));
    } catch (e) {
      print("전체 삭제 오류: $e");
    }
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
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              docs.sort((a, b) {
                Timestamp t1 = a['createdAt'] ?? Timestamp.now();
                Timestamp t2 = b['createdAt'] ?? Timestamp.now();
                return t2.compareTo(t1);
              });

              if (docs.isEmpty)
                return const Center(
                    child: Text("새로운 알림이 없습니다.",
                        style: TextStyle(color: Colors.grey)));

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final bool isRead = data['isRead'] ?? false;
                  final DateTime time =
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      isRead ? Colors.grey[100] : AppTheme.primaryLight,
                      child: Icon(Icons.notifications_active,
                          color: isRead ? Colors.grey : AppTheme.primaryColor,
                          size: 20),
                    ),
                    title: Text(data['title'] ?? '알림',
                        style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['body'] ?? '',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(DateFormat('MM.dd HH:mm').format(time),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    onTap: () async {
                      await docs[index].reference.update({'isRead': true});
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      mainLayoutKey.currentState?.handleNotificationClick(data['type']);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _deleteAllNotifications(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text("모두 삭제"),
          ),
          TextButton(
            onPressed: () async {
              await _deleteReadNotifications(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("읽은 알림 삭제"),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))
        ],
      ),
    );
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
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        String userName = userData?['name'] ?? '사용자';
        String userRank = userData?['rank'] ?? '';
        bool isAdmin = (userData?['role'] ?? 'user') == 'admin';

        if (!isAdmin && _selectedIndex == 3) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onMenuSelected(0, isDrawerClick: false);
          });
        }

        Widget notificationButton = StreamBuilder<int>(
          stream: _getUnreadNotificationCountStream(),
          builder: (context, snap) {
            int count = snap.data ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none,
                      color: AppTheme.textMain),
                  onPressed: () => _showNotificationList(context),
                  tooltip: "알림 확인",
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints:
                      const BoxConstraints(minWidth: 10, minHeight: 10),
                    ),
                  )
              ],
            );
          },
        );

        Widget userInfoWidget = Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              radius: 16,
              child: Text(userName.isNotEmpty ? userName[0] : 'U',
                  style: const TextStyle(
                      color: AppTheme.primaryColor, fontSize: 14)),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textMain)),
                if (userRank.isNotEmpty)
                  Text(userRank,
                      style: const TextStyle(
                          color: AppTheme.textSub, fontSize: 11))
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
                  child: Image.asset('assets/images/sm_logo.png',
                      height: 65, fit: BoxFit.contain)),
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      _buildMenuItem(
                          icon: Icons.dashboard_outlined,
                          title: '대시보드',
                          index: 0),
                      _buildMenuItem(
                          icon: Icons.edit_note, title: '새 노트작성', index: 1),
                      _buildMenuItem(
                          icon: Icons.article_outlined, title: '노트관리', index: 2),
                      _buildMenuItem(
                          icon: Icons.playlist_add_check_circle_outlined,
                          title: '체크리스트',
                          index: 4),
                      StreamBuilder<int>(
                        stream: _salesService.getUnreadMessageCountStream(),
                        builder: (context, snap) => _buildMenuItem(
                            icon: Icons.chat_bubble_outline,
                            title: '업무 톡톡',
                            index: 5,
                            badgeCount:
                            _selectedIndex == 5 ? 0 : (snap.data ?? 0)),
                      ),
                      Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: const PageStorageKey('FieldSupportMenu'),
                          leading: const Icon(Icons.map_outlined, size: 22),
                          title: const Text("현장팀 업무지원",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          initiallyExpanded: _isFieldSupportExpanded,
                          onExpansionChanged: (expanded) => setState(
                                  () => _isFieldSupportExpanded = expanded),
                          iconColor: AppTheme.primaryColor,
                          collapsedIconColor: AppTheme.textSub,
                          children: [
                            _buildSubMenuItem(
                                icon: Icons.calendar_today,
                                title: "일정 관리",
                                index: 9),
                            _buildSubMenuItem(
                                icon: Icons.alt_route,
                                title: "경로 관리 (AI)",
                                index: 7),
                            StreamBuilder<int>(
                              stream: _getOverdueWorkCountStream(),
                              builder: (context, snap) => _buildSubMenuItem(
                                  icon: Icons.assignment_outlined,
                                  title: "업무 보고",
                                  index: 10,
                                  badgeCount: snap.data ?? 0),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                          height: 32,
                          indent: 24,
                          endIndent: 24,
                          color: AppTheme.borderColor),
                      _buildMenuItem(
                          icon: Icons.business, title: '건물 DB 정보', index: 8),
                      _buildMenuItem(
                          icon: Icons.settings_outlined, title: '설정', index: 6),
                      if (isAdmin)
                        _buildMenuItem(
                            icon: Icons.admin_panel_settings_outlined,
                            title: '관리자 설정',
                            index: 3),
                      ListTile(
                        leading:
                        const Icon(Icons.logout, color: AppTheme.textSub),
                        title: const Text("로그아웃",
                            style: TextStyle(
                                color: AppTheme.textSub, fontSize: 14)),
                        onTap: _logout,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          appBar: isWideScreen
              ? null
              : AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: AppTheme.textMain),
            title: Text(_getTitleByIndex(_selectedIndex),
                style: const TextStyle(
                    color: AppTheme.textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
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
                    if (!kIsWeb)
                      Offstage(
                          offstage: _selectedIndex != 7,
                          child: _permanentNaverMap),
                    Container(
                      color: (_selectedIndex == 7 && !kIsWeb)
                          ? Colors.transparent
                          : AppTheme.backgroundColor,
                      child: Column(
                        children: [
                          if (isWideScreen)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              color: AppTheme.surfaceColor,
                              child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_getTitleByIndex(_selectedIndex),
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        notificationButton,
                                        const SizedBox(width: 20),
                                        userInfoWidget,
                                      ],
                                    )
                                  ]),
                            ),
                          if (isWideScreen)
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

  Widget _buildMenuItem(
      {required IconData icon,
        required String title,
        required int index,
        int badgeCount = 0}) {
    final bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => _onMenuSelected(index),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(50)),
          child: Row(children: [
            Icon(icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSub,
                size: 22),
            const SizedBox(width: 16),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                        isSelected ? AppTheme.primaryColor : AppTheme.textMain,
                        fontSize: 14))),
            if (badgeCount > 0)
              Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(badgeCount > 99 ? "99+" : "$badgeCount",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)))
          ]),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(
      {required IconData icon,
        required String title,
        required int index,
        int badgeCount = 0}) {
    final bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => _onMenuSelected(index),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding:
          const EdgeInsets.only(left: 56, top: 10, bottom: 10, right: 16),
          decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(50)),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSub),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textMain,
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14))),
              if (badgeCount > 0)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                      color: Colors.deepOrange, shape: BoxShape.circle),
                  child: Text("$badgeCount",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
      ),
    );
  }
}