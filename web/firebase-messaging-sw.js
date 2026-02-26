// [파일 위치: web/firebase-messaging-sw.js]
// [최종 고도화] 중복 알림 차단 + 클릭 이동 완벽 지원 (PWA 최적화 및 플러터 라우팅 대응)

importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-messaging-compat.js");

// 1. Firebase 설정 (⚠️ 대표님의 실제 키값 유지)
firebase.initializeApp({
  apiKey: "AIzaSy...",
  authDomain: "sm-sales-note-2026.firebaseapp.com",
  projectId: "sm-sales-note-2026",
  storageBucket: "sm-sales-note-2026.appspot.com",
  messagingSenderId: "103953800507",
  appId: "1:103953800507:web:..."
});

const messaging = firebase.messaging();

// ============================================================================
// 2. 백그라운드 메시지 핸들러
// ============================================================================
messaging.onBackgroundMessage(function(payload) {
  console.log('[SW] 백그라운드 메시지 수신 (시스템이 자동으로 표시함):', payload);
  // 🔴 수동 알림(showNotification)을 삭제하여 안드로이드 절전 모드에서의 중복/누락 방지
});

// ============================================================================
// 3. 알림 클릭 시 페이지 이동 (PWA/웹 완벽 지원)
// ============================================================================
self.addEventListener('notificationclick', function(event) {
  console.log('[SW] 알림 클릭됨:', event.notification);
  event.notification.close(); // 클릭하면 즉시 알림 상자 닫기

  const origin = self.location.origin;
  let targetUrl = origin + '/#/'; // 기본 홈 화면 경로

  // 🌟 [핵심 보정] 서버에서 온 경로를 플러터 웹의 Hash(#) 방식에 맞게 자동 변환
  if (event.notification.data && event.notification.data.url) {
      let path = event.notification.data.url;
      // 경로에 /#/ 가 없으면 강제로 붙여줍니다. (예: '/chat' -> '/#/chat')
      if (!path.startsWith('/#/')) {
          if (path.startsWith('/')) path = '/#' + path;
          else path = '/#/' + path;
      }
      targetUrl = origin + path;
  } else if (event.notification.data && event.notification.data.type) {
      // (백업) 기존 타입별 이동 방식 유지
      targetUrl = getUrlByType(event.notification.data.type);
  }

  console.log('[SW] 최종 이동할 주소:', targetUrl);

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // 1. 이미 우리 웹사이트 탭이 열려있는지 확인
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url.includes(origin) && 'focus' in client) {
          // 🌟 [안정성 고도화] 일부 모바일 브라우저에서 focusedClient가 null이 되는 현상 방지
          return client.focus().then(() => {
             if ('navigate' in client) {
                 return client.navigate(targetUrl); // 정확한 페이지로 즉시 이동!
             }
          });
        }
      }
      // 2. 열려있는 탭이 없다면 아예 새 창(PWA 앱)으로 열기
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});

// ============================================================================
// [보조 함수] 이동 주소 백업 로직 (안전망)
// ============================================================================
function getUrlByType(type) {
  const origin = self.location.origin;
  if (type === 'chat') return origin + '/#/chat';
  if (type === 'schedule') return origin + '/#/schedule';
  if (type === 'notice') return origin + '/#/notice';
  if (type === 'report') return origin + '/#/report';
  return origin + '/#/';
}