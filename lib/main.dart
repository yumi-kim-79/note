// [파일 위치: lib/main.dart]
// [최종 수정 완료] 2026-02-15
// 메인페이지(메인페이지 연결 및 서버 연겨리 뱃지연결등)
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
import 'dart:html' as html; // 🌟 [추가됨] 웹(PWA) 뒤로가기 종료를 위한 패키지

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
import 'pages/sales/tax_invoice_page.dart'; // 👈 추가해주세요
import 'pages/it_support/ai_payment_page.dart'; // 🌟 [추가] 전산팀 페이지 연결

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
// 🌙 [백그라운드 핸들러] 웹 & 네이티브 앱 완벽 호환 모드
// =======================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 🌟 [스마트 스위치] 현재 환경이 웹(PWA)이라면?
  // -> 서비스 워커(sw.js)가 알아서 처리하므로 여기서 즉시 종료! (알림 2개 중복 방지)
  if (kIsWeb) {
    debugPrint("🌙 [Web 백그라운드] 메시지 수신 (브라우저가 처리함)");
    return;
  }

  // 📱 [미래의 앱을 위한 보존 구역] 나중에 출시할 안드로이드/iOS 앱에서는 아래 코드가 작동하여 알림을 띄웁니다!
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

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id, channel.name,
      channelDescription: channel.description,
      importance: Importance.max, priority: Priority.high
  );

  await backPlugin.show(
      DateTime.now().millisecond,
      data['title'] ?? '알림',
      data['body'] ?? '내용',
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      payload: data['type']
  );
}

// =======================================================
// 🌟 [고도화 추가] 스마트 캐싱 (전역 사용자 정보 보관함)
// 앱 어디서든 DB 조회 없이 내 이름/직급을 즉시 꺼내 쓸 수 있습니다.
// =======================================================
class GlobalUserState {
  static String uid = '';
  static String name = '직원';
  static String rank = '';
  static String role = 'user';

  // 이름+직급 조합 (예: 홍길동 대리)을 바로 꺼내쓰는 마법의 헬퍼
  static String get fullName => rank.isNotEmpty ? '$name $rank'.trim() : name;
  static bool get isAdmin => role == 'admin';
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
  DateTime? _lastPressedAt; // 🌟 [추가됨] 뒤로가기 2번 방지용 타이머 장부
  late final Widget _permanentNaverMap;
  late final List<Widget> _pages;

  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  final GlobalKey<FieldReportPageState> _reportPageKey = GlobalKey<FieldReportPageState>();
  final GlobalKey<FieldSchedulePageState> _schedulePageKey = GlobalKey<FieldSchedulePageState>();
  final GlobalKey<FieldRoutePageState> _routePageKey = GlobalKey<FieldRoutePageState>();
  final GlobalKey<DashboardPageState> _dashboardKey = GlobalKey<DashboardPageState>();

  bool _isFieldSupportExpanded = false;
  bool _isGeneralSupportExpanded = false; // ✅ 총무팀 메뉴 펼침 상태
  bool _isAiSystemExpanded = false;       // ✅ AI 시스템 메뉴 펼침 상태
  bool _isSettingsExpanded = false;       // ✅ 설정 메뉴 펼침 상태

  // ✅ [여기에 추가] 담당자 기기 토큰을 DB에 자동 등록하는 함수
  Future<void> _syncFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 현재 기기의 최신 토큰을 가져옵니다
      String? token = await NotificationService().getToken();

      if (token != null) {
        // users 컬렉션에 토큰을 저장하여 서버가 알림 보낼 주소를 알게 합니다
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // 기존 이름, 직급 정보는 유지하고 토큰만 업데이트

        debugPrint("📡 [FCM] 기기 토큰 동기화 성공");
      }
    } catch (e) {
      debugPrint("❌ [FCM] 토큰 동기화 실패: $e");
    }
  }

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
      const TaxInvoicePage(),
      const Scaffold(body: Center(child: Text("공과금(지출) 대조 시스템 준비 중..."))),
      const AiPaymentPage(), // 🌟 [Index 13] 전산팀 AI 자동수납 페이지 연결
    ];

    _listenToNotifications(); // 포그라운드 처리
    _setupInteractedMessage(); // 백그라운드 처리
    // ✅ [여기에 추가] 앱이 켜질 때마다 내 토큰 정보를 서버에 보냅니다.
    _syncFCMToken();
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

    // 🌟 [안전 장치 추가] 소문자로 변환하고 공백을 제거하여 오타를 방지합니다.
    String safeType = type.trim().toLowerCase();

    int pageIndex = -1;
    switch (safeType) {
      case 'chat': pageIndex = 5; break;
      case 'schedule': pageIndex = 9; break;
      case 'report': pageIndex = 10; break;
      default: debugPrint("알 수 없는 알림 타입: $safeType");
    }

    if (pageIndex != -1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if(mounted) {
          // 🌟 [고도화 반영] 1. 페이지 인덱스를 맞추고, 2. 해당 페이지 강제 새로고침(Refresh)을 호출하여 먹통 현상을 막습니다.
          _onMenuSelected(pageIndex, isDrawerClick: false);
          _triggerPageRefresh(pageIndex);
        }
      });
    }
  }

  // ✅ [수정] 포그라운드 알림 리스너 (웹 & 앱 분기 처리)
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

          // 🌟 [스마트 스위치 작동]
          if (kIsWeb) {
            // [웹(PWA) 모드] 앱을 켜놓고 있을 때는 방해되지 않게 빨간 뱃지만 올립니다. (화면 상단 알림창 띄우지 않음)
            debugPrint("🔔 [Web 포그라운드] 새 알림 도착 (뱃지 카운트 증가)");
          } else {
            // 📱 [미래의 앱 모드] 네이티브 앱에서는 화면 상단에 배너 알림과 진동을 발생시킵니다.
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

    // 🌟 [추가된 핵심 방어벽] 경로 관리(7번 탭)에서 다른 탭으로 넘어갈 때 감지!
    if (_selectedIndex == 7 && index != 7 && FieldRoutePage.globalHasUnsavedChanges) {
      bool shouldLeave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text("저장되지 않은 변경사항", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text("경로가 변경되었지만 저장되지 않았습니다.\n저장하지 않고 다른 메뉴로 이동하시겠습니까?", style: TextStyle(height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), // 머무름
              child: const Text("아니오 (저장할게요)", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), // 나감
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("예 (그냥 이동)"),
            ),
          ],
        ),
      ) ?? false;

      if (!shouldLeave) {
        // [아니오]를 누르면 이동 취소. 서랍 메뉴에서 눌렀다면 저장 버튼을 누를 수 있게 서랍을 닫아줌
        if (isMobile && isDrawerClick) Navigator.pop(context);
        return; // 여기서 함수를 종료하여 탭 이동을 완벽히 차단!
      } else {
        // [예]를 누르면 강제로 나갈 수 있도록 센서 초기화 후 아래 로직 그대로 진행
        FieldRoutePage.globalHasUnsavedChanges = false;
      }
    }
    // 🌟 [방어벽 끝]

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
      case 11: return '국세청(계산서) 대조';
      case 12: return '공과금(지출) 대조';
      case 13: return 'AI 자동수납 (전산)';
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

  // =========================================================
  // 🌟 [핵심 고도화] 나에게 이관되어 '수락 대기' 중인 업무 개수 가져오기
  // =========================================================
  Stream<int> _getPendingScheduleCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('schedules')
        .where('uid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length); // 대기 중인 문서 개수 반환
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

        // 🌟 [핵심 고도화 적용] 서버에서 가져온 내 정보를 전역 캐시에 꽉 쥐어줍니다!
        // 이제 다른 페이지에서 DB를 뒤지지 않아도 GlobalUserState.fullName 으로 내 이름을 즉시 꺼내 씁니다.
        GlobalUserState.uid = user?.uid ?? '';
        GlobalUserState.name = userName;
        GlobalUserState.rank = userRank;
        GlobalUserState.role = userData?['role'] ?? 'user';

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
                      // 1. 현장팀 업무지원 (기존)
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
                            // 🌟 [핵심 고도화] 일정 관리 메뉴에 실시간 뱃지 연동!
                            StreamBuilder<int>(
                              stream: _getPendingScheduleCountStream(),
                              builder: (context, snap) => _buildSubMenuItem(
                                  icon: Icons.calendar_today,
                                  title: "일정 관리",
                                  index: 9,
                                  badgeCount: snap.data ?? 0),
                            ),
                            _buildSubMenuItem(icon: Icons.alt_route, title: "경로 관리 (AI)", index: 7),
                            StreamBuilder<int>(
                              stream: _getOverdueWorkCountStream(),
                              builder: (context, snap) => _buildSubMenuItem(
                                  icon: Icons.assignment_outlined, title: "업무 보고", index: 10, badgeCount: snap.data ?? 0),
                            ),
                          ],
                        ),
                      ),

                      // 🌟 2. 전산팀 업무지원 (현장팀 바로 밑에 새로 추가)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: const PageStorageKey('ComputerSupportMenu'),
                          leading: const Icon(Icons.terminal_outlined, size: 22),
                          title: const Text("전산팀 업무지원", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          iconColor: AppTheme.primaryColor,
                          collapsedIconColor: AppTheme.textSub,
                          children: [
                            _buildSubMenuItem(icon: Icons.auto_fix_high, title: "AI 자동수납", index: 13),
                          ],
                        ),
                      ),

                      // 🌟 3. 총무팀 업무지원 (새로 추가된 대메뉴)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: const PageStorageKey('GeneralSupportMenu'),
                          leading: const Icon(Icons.business_center_outlined, size: 22),
                          title: const Text("총무팀 업무지원", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          initiallyExpanded: _isGeneralSupportExpanded,
                          onExpansionChanged: (expanded) => setState(() => _isGeneralSupportExpanded = expanded),
                          iconColor: AppTheme.primaryColor,
                          collapsedIconColor: AppTheme.textSub,
                          children: [
                            // 🌟 3-1. AI 스마트 시스템 (하위 메뉴)
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                key: const PageStorageKey('AiSystemMenu'),
                                tilePadding: const EdgeInsets.only(left: 40, right: 16), // 안쪽으로 들여쓰기
                                leading: const Icon(Icons.smart_toy_outlined, size: 20),
                                title: const Text("AI 스마트 시스템", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                initiallyExpanded: _isAiSystemExpanded,
                                onExpansionChanged: (expanded) => setState(() => _isAiSystemExpanded = expanded),
                                iconColor: AppTheme.primaryColor,
                                collapsedIconColor: AppTheme.textSub,
                                children: [
                                  _buildSubSubMenuItem(icon: Icons.receipt_long, title: "국세청(계산서) 대조", index: 11),
                                  _buildSubSubMenuItem(icon: Icons.payments_outlined, title: "공과금(지출) 대조", index: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 32, indent: 24, endIndent: 24, color: AppTheme.borderColor),

                      // 3. 건물 DB 정보 (기존 위치 유지)
                      _buildMenuItem(icon: Icons.business, title: '건물 DB 정보', index: 8),

                      // 🌟 4. 설정 (새로 묶은 대메뉴)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: const PageStorageKey('SettingsMenu'),
                          leading: const Icon(Icons.settings_outlined, size: 22),
                          title: const Text("설정", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          initiallyExpanded: _isSettingsExpanded,
                          onExpansionChanged: (expanded) => setState(() => _isSettingsExpanded = expanded),
                          iconColor: AppTheme.primaryColor,
                          collapsedIconColor: AppTheme.textSub,
                          children: [
                            _buildSubMenuItem(icon: Icons.notifications_active_outlined, title: '알림 설정', index: 6),
                            if (isAdmin)
                              _buildSubMenuItem(icon: Icons.admin_panel_settings_outlined, title: '관리자 설정', index: 3),
                            // 🌟 [수정] 로그아웃도 InkWell로 감싸서 다른 메뉴들과 UI/터치감을 동일하게 맞춤!
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: InkWell(
                                onTap: _logout,
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  padding: const EdgeInsets.only(left: 56, top: 10, bottom: 10, right: 16),
                                  decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(50)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout, size: 18, color: AppTheme.textSub),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Text("로그아웃", style: TextStyle(color: AppTheme.textMain, fontSize: 14))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        // 🌟 [추가됨] 뒤로가기 2번 방지용 그물망 (PopScope)
        return PopScope(
          canPop: false, // 시스템 자동 뒤로가기를 1차적으로 차단
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            final now = DateTime.now();

            // 2초 이내에 다시 누른 것이 아니라면 (첫 번째 뒤로가기 클릭)
            if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
              _lastPressedAt = now;

              if (context.mounted) {
                // 하단에 친절한 스낵바 안내 메시지 띄우기
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('한 번 더 누르면 종료됩니다.', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.black87,
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  ),
                );
              }
              return;
            }

            // 2초 이내에 다시 한 번 눌렀다면 실제로 종료 로직 실행
            if (kIsWeb) {
              // 웹 브라우저/PWA 환경에서는 히스토리 백을 통해 앱 종료 유도
              html.window.history.back();
            }
          },
          child: Scaffold(
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
          ),
        ); // 🌟 [추가됨] PopScope를 닫아주는 괄호
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
  // 🌟 AI 시스템 등 3단계 깊이를 위한 전용 메뉴 빌더
  Widget _buildSubSubMenuItem(
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
          // left를 72로 주어서 기존 소메뉴(56)보다 더 안쪽으로 들여쓰기
          padding: const EdgeInsets.only(left: 72, top: 10, bottom: 10, right: 16),
          decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(50)),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? AppTheme.primaryColor : AppTheme.textSub),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textMain,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13))),
            ],
          ),
        ),
      ),
    );
  }
}