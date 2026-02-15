// [파일 위치: web/firebase-messaging-sw.js]
// [최종 수정] Data-Only 메시지 대응 + 클릭 시 페이지 이동 고도화
// 1. 서버에서 보낸 'data' 필드를 읽어서 알림 표시
// 2. 알림 클릭 시 'type'에 따라 해당 페이지(URL)로 이동

importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-messaging-compat.js");

// 1. Firebase 설정 (기존 값 유지)
// ⚠️ 주의: 혹시 firebase_options.dart의 값이 바뀌었다면 여기도 똑같이 맞춰주세요.
firebase.initializeApp({
  apiKey: "AIzaSy...", // (보안상 생략, 대표님의 기존 실제 키값을 그대로 두시면 됩니다)
  authDomain: "sm-sales-note-2026.firebaseapp.com",
  projectId: "sm-sales-note-2026",
  storageBucket: "sm-sales-note-2026.appspot.com",
  messagingSenderId: "103953800507",
  appId: "1:103953800507:web:..."
});

const messaging = firebase.messaging();

// 2. [고도화] 백그라운드 메시지 핸들러
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] 백그라운드 메시지 수신:', payload);

  // [핵심 변경] 서버가 'notification' 없이 'data'만 보내므로 data에서 꺼내야 함
  // 만약 data가 없으면 기존 방식(notification)을 대비책으로 사용
  const notificationTitle = payload.data.title || payload.notification?.title || 'SM 알림';
  const notificationBody = payload.data.body || payload.notification?.body || '내용이 없습니다.';
  const type = payload.data.type || 'default'; // 클릭 시 이동할 페이지 타입

  const notificationOptions = {
    body: notificationBody,
    icon: '/icons/Icon-192.png', // 기존 설정 유지
    badge: '/icons/Icon-192.png', // 기존 설정 유지
    vibrate: [200, 100, 200],      // 기존 설정 유지

    // [추가] 클릭 이벤트를 위해 데이터 심어두기
    data: {
      type: type,
      url: getUrlByType(type) // 타입에 따른 URL 결정 함수 호출
    }
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// 3. [신규 기능] 알림 클릭 시 페이지 이동 처리
self.addEventListener('notificationclick', function(event) {
  console.log('[Service Worker] 알림 클릭됨');

  event.notification.close(); // 알림 닫기

  const targetUrl = event.notification.data.url || '/'; // 이동할 주소

  // 브라우저 탭 관리 로직
  // 1. 이미 열려있는 탭이 있으면 그곳으로 이동
  // 2. 없으면 새 창 열기
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // 이미 열린 탭 중 URL이 일치하는 게 있는지 확인 (혹은 그냥 앱 포커스)
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        // 앱이 열려있다면 포커스만 이동
        if ('focus' in client) {
          return client.focus();
        }
      }
      // 열린 탭이 없다면 새 창 열기
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});

// [보조 함수] 타입에 따른 이동 URL 매핑 (웹 URL 구조에 맞게 수정 가능)
function getUrlByType(type) {
  // Flutter Web은 보통 /#/ 경로를 사용합니다.
  const baseUrl = self.location.origin + '/#';

  switch (type) {
    case 'chat':
      return baseUrl + '/chat'; // 채팅 페이지
    case 'schedule':
      return baseUrl + '/schedule'; // 일정 페이지
    case 'report':
      return baseUrl + '/report'; // 보고 페이지
    default:
      return baseUrl + '/'; // 메인 대시보드
  }
}