// [파일 위치: web/firebase-messaging-sw.js]
// [최종 고도화] 글로벌 표준 PWA 알림 라우팅 (순정 위임) + 캐시 강제 파괴

importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-messaging-compat.js");

// ============================================================================
// 1. Firebase 설정 (⚠️ 대표님의 실제 키값으로 반드시 유지해주세요)
// ============================================================================
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
// 2. 백그라운드 메시지 핸들러 (순정 위임)
// ============================================================================
// 🌟 서버에서 보낸 fcmOptions.link를 통해 브라우저가 알아서 화면을 열고 이동하므로
// 여기서는 별도의 수동 팝업(showNotification)을 띄우지 않습니다. (중복 알림 원천 차단)
messaging.onBackgroundMessage(function(payload) {
  console.log('[SW] 백그라운드 메시지 수신 (시스템이 자동으로 표시 및 클릭 이동 처리함):', payload);
});

// ============================================================================
// 🌟 [핵심 기능 100% 유지] 서비스 워커 강제 즉시 업데이트 (캐시 무시 및 즉각 반영)
// 이 코드가 있어야 대표님이 코드를 수정했을 때 직원들 폰에 1초 만에 새 코드가 덮어씌워집니다.
// ============================================================================
self.addEventListener('install', function(event) {
  console.log('[SW] 새로운 서비스 워커 설치 중... 대기 없이 즉시 적용합니다.');
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  console.log('[SW] 새로운 서비스 워커 가동 완료! 모든 화면의 제어권을 뺏어옵니다.');
  event.waitUntil(clients.claim());
});

// 🗑️ (삭제됨) 기존의 수동 'notificationclick' 가로채기 코드는 삭제되었습니다.
// 이제 서버(index.js)에서 동봉한 fcmOptions.link 주소를 파이어베이스 순정 엔진이 읽고
// 플러터 웹의 정확한 해시(#) 경로로 완벽하게 이동시켜 줍니다!