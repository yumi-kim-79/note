// ✅ [수정] 포그라운드 시각적 알림은 MainLayoutPage의 Firestore 리스너가 전담합니다.
// 이 리스너는 중복 알림을 유발하므로, 시각적 표시 기능을 제거하고 디버그용으로만 남겨둡니다.
FirebaseMessaging.onMessage.listen
(
(RemoteMessage message) {
debugPrint("📱 [FCM] 포그라운드 메시지 수신: ${message.notification?.title}");
// 이 리스너가 시각적 알림을 직접 표시하지 않도록 내부 코드를 비워둡니다.
// 모든 포그라운드 알림(소리/진동/배너) 표시는 MainLayoutPage의 _listenToNotifications가 담당합니다.
});