// [파일 위치: lib/services/notification_service.dart]
// 알림관련
// [최종 수정] 클라이언트(앱)에서의 직접 발송 로직 제거 -> 서버(Cloud Functions) 위임 방식 적용
// 효과 1: 웹(PWA)에서 알림이 2개 뜨는 중복 문제 원천 해결
// 효과 2: 앱 내에 민감한 인증 키(service-account.json)를 포함하지 않아도 되어 보안 강화

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ [추가] 현재 사용자 확인용
import 'package:flutter/foundation.dart';
import '../main.dart'; // 🌟 [추가] GlobalUserState 사용을 위해 추가

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // 웹 푸시를 위한 VAPID Key (기존 키 유지)
  final String _vapidKey = "BLVhS7nkRAE6a0V3d6BH8XzfKnNjfsM-omTlVBOWES_HFgU6YOL1cY2N2lRIVVhPz5KK6MksXqHNiMZAOBcY3nw";

  Future<void> init() async {
    // 알림 권한 요청 (기존 유지)
    await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true
    );

    // ✅ [변경] 기존의 '_initializeServiceAccount()' 호출 제거
    // 이유: 이제 앱이 직접 발송하지 않고 서버가 발송하므로, 앱에서 구글 인증을 할 필요가 없습니다.
  }

  Future<String?> getToken() async {
    if (kIsWeb) return await _firebaseMessaging.getToken(vapidKey: _vapidKey);
    return await _firebaseMessaging.getToken();
  }

  // 알림 발송 요청 (실제 발송은 서버가 담당)
  Future<void> sendNotification({
    required String targetToken, // (서버가 DB에서 조회하므로 사실상 안 쓰이지만, 인터페이스 유지를 위해 남김)
    required String targetUid,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      // ✅ [핵심 기능 유지] DB(notifications 컬렉션)에 알림 내용을 저장합니다.
      // 이 저장이 완료되면 -> Cloud Functions(index.js)가 감지하고 -> 실제 푸시를 발송합니다.
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetUid': targetUid,
        'title': title,
        'body': body,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      debugPrint("✅ [NotificationService] DB 저장 완료 (발송은 서버가 수행함)");

      // 🗑️ [삭제됨] http.post 직접 발송 코드 제거
      // 이 코드가 존재하면 'Notification' 필드가 포함된 메시지를 보내게 되어
      // 웹에서 중복 알림(시스템 알림 + 서비스워커 알림)이 발생합니다.
      // 이제 발송 권한은 오직 '서버(index.js)'에게만 있습니다.

    } catch (e) {
      debugPrint("❌ 알림 저장 실패: $e");
    }
  }

  // ✅ [고도화 완료] 나를 제외한 모든 담당자에게 알림을 생성하는 함수
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      // 🌟 [스마트 캐싱 적용] FirebaseAuth 대신 메모리에 저장된 UID를 즉시 사용합니다.
      final myUid = GlobalUserState.uid;
      if (myUid.isEmpty) return;

      // 1. 모든 유저 목록 가져오기
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection(
          'users').get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (var doc in usersSnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;

        // 🌟 [핵심 수정] 문서 ID(doc.id) 뿐만 아니라, 필드에 저장된 'uid'값이 있다면 그것을 우선 사용합니다.
        // (문서 ID가 UID가 아닌 경우를 대비한 2중 안전장치)
        String targetUid = userData['uid'] ?? doc.id;

        // 2. 나를 제외한 모든 유저에게 알림 문서 생성
        if (targetUid != myUid) {
          DocumentReference notifyRef = FirebaseFirestore.instance.collection(
              'notifications').doc();
          batch.set(notifyRef, {
            'targetUid': targetUid, // 실제 푸시를 보낼 대상 UID
            'title': title,
            'body': body,
            'type': type,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
          count++;
        }

        // Firestore Batch는 한 번에 500개까지만 가능하므로 안전하게 끊어서 처리 (대기업형 방어코드)
        if (count >= 450) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
        }
      }

      if (count > 0) {
        await batch.commit(); // 나머지 남은 것들 한 번에 저장
        debugPrint("✅ [Broadcast] $count명의 담당자에게 알림 데이터 생성 완료");
      }
    } catch (e) {
      debugPrint("❌ [Broadcast] 알림 생성 실패: $e");
    }
  }
}