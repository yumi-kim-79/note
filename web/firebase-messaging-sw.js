importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.17.2/firebase-messaging-compat.js");

// 1. Firebase 설정 (대표님의 firebase_options.dart 파일 내용을 참고하여 채워주세요)
// 아래 값들은 예시입니다. 실제 프로젝트 설정값으로 바꿔야 합니다.
firebase.initializeApp({
  apiKey: "AIzaSy...",
  authDomain: "sm-sales-note-2026.firebaseapp.com",
  projectId: "sm-sales-note-2026",
  storageBucket: "sm-sales-note-2026.appspot.com",
  messagingSenderId: "103953800507",
  appId: "1:103953800507:web:..."
});

// 2. 백그라운드 메시지 핸들러
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png', // 알림 아이콘
    badge: '/icons/Icon-192.png', // 모바일 상단 배지
    vibrate: [200, 100, 200] // 징-지잉-징 (진동 패턴)
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});