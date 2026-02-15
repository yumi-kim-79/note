// [파일 위치: web/firebase-messaging-sw.js]
// [최종 수정] 중복 알림 제거 + 클릭 이동 완벽 지원
// 1. 시스템이 띄운 '멍청한 알림(이동X)'을 감지하여 즉시 삭제
// 2. 우리가 만든 '똑똑한 알림(이동O)'만 화면에 표시
// 3. PWA(설치된 앱) 상태에서도 클릭 시 앱을 깨우고 페이지 이동

importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-messaging-compat.js");

// 1. Firebase 설정 (기존 값 유지 - 대표님의 키값으로 되어있는지 꼭 확인!)
firebase.initializeApp({
  apiKey: "AIzaSy...",
  authDomain: "sm-sales-note-2026.firebaseapp.com",
  projectId: "sm-sales-note-2026",
  storageBucket: "sm-sales-note-2026.appspot.com",
  messagingSenderId: "103953800507",
  appId: "1:103953800507:web:..."
});

const messaging = firebase.messaging();

// 2. 백그라운드 메시지 핸들러
messaging.onBackgroundMessage(function(payload) {
  console.log('[SW] 메시지 수신:', payload);

  // 🔴 [핵심 기술] 중복 알림 제거 (시스템 알림 끄기)
  // 브라우저가 자동으로 띄운 알림(notification 필드 때문에 생긴 것)을 찾아서 닫아버립니다.
  // 약간의 딜레이를 주어 시스템 알림이 생성된 직후에 닫도록 합니다.
  if (payload.notification) {
    setTimeout(() => {
        self.registration.getNotifications().then(notifications => {
            notifications.forEach(notification => {
                // 'tag'가 없는 알림은 시스템이 만든 '멍청한 알림'일 확률이 높으므로 닫습니다.
                if (!notification.tag || notification.tag !== 'sm-custom-tag') {
                    notification.close();
                }
            });
        });
    }, 100);
  }

  // ✅ [수동 생성] 이동 기능이 포함된 '똑똑한 알림'을 띄웁니다.
  const notificationTitle = payload.data.title || payload.notification.title || 'SM 알림';
  const notificationBody = payload.data.body || payload.notification.body || '새로운 내용이 있습니다.';

  const notificationOptions = {
    body: notificationBody,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    vibrate: [200, 100, 200],
    tag: 'sm-custom-tag', // 태그를 지정하여 위에서 닫히지 않게 보호합니다.
    renotify: true,

    // 클릭 시 이동을 위한 데이터 심기
    data: {
      type: payload.data.type,
      url: getUrlByType(payload.data.type)
    }
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// 3. 알림 클릭 시 페이지 이동 (PWA/웹 완벽 지원)
self.addEventListener('notificationclick', function(event) {
  console.log('[SW] 알림 클릭됨');
  event.notification.close(); // 클릭하면 알림 닫기

  const targetUrl = event.notification.data.url || self.location.origin;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // 1. 이미 열려있는 탭/앱이 있는지 확인
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus().then(function(focusedClient) {
             if ('navigate' in focusedClient) {
                 return focusedClient.navigate(targetUrl);
             }
          });
        }
      }
      // 2. 없다면 새 창 열기
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});

// [보조 함수] 이동할 주소 결정
function getUrlByType(type) {
  const origin = self.location.origin;
  if (type === 'chat') return origin + '/#/chat';
  if (type === 'schedule') return origin + '/#/schedule';
  if (type === 'report') return origin + '/#/report';
  return origin + '/#/';
}