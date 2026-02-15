import UIKit
import Flutter
// ✅ [신규 추가] 알림 패키지 임포트
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ [신규 추가] 앱 실행 중 알림 처리를 위한 대리자(Delegate) 설정
    // 이것이 있어야 앱을 보고 있을 때도 상단 배너가 뜹니다.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    // ✅ [기존 유지] 플러그인 등록 (지도 등 기존 기능 유지)
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}