// [파일 위치: lib/services/notification_service.dart]
// [최종 수정] FormatException을 원천 차단하기 위해, 하드코딩된 키 대신 service-account.json 파일을 직접 읽어서 사용하도록 인증 방식 변경

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // ✅ rootBundle을 사용하기 위해 추가
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final String _vapidKey = "BLVhS7nkRAE6a0V3d6BH8XzfKnNjfsM-omTlVBOWES_HFgU6YOL1cY2N2lRIVVhPz5KK6MksXqHNiMZAOBcY3nw";

  // ✅ [수정] 더 이상 하드코딩된 JSON을 사용하지 않으므로, 해당 변수 삭제
  // final String _serviceAccountJson = ...

  // ✅ [추가] 서비스 계정 인증 정보를 담을 변수
  static AccessCredentials? _credentials;
  static String? _projectId;

  Future<void> init() async {
    await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
    // ✅ [추가] 앱 시작 시, 한번만 서비스 계정 파일을 읽어서 인증 정보를 생성
    await _initializeServiceAccount();
  }

  // ✅ [추가] service-account.json 파일을 읽어 AccessCredentials를 생성하는 함수
  Future<void> _initializeServiceAccount() async {
    // 이미 초기화되었다면 다시 실행하지 않음 (효율성)
    if (_credentials != null && _projectId != null) return;

    try {
      final jsonString = await rootBundle.loadString('assets/service-account.json');
      final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);
      final client = await clientViaServiceAccount(accountCredentials, ['https://www.googleapis.com/auth/firebase.messaging']);
      
      _credentials = client.credentials;
      _projectId = (jsonDecode(jsonString) as Map<String, dynamic>)['project_id'];
      
      debugPrint("✅ 서비스 계정 인증 성공!");

    } catch (e) {
      debugPrint("❌ 서비스 계정 인증 실패: $e");
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) return await _firebaseMessaging.getToken(vapidKey: _vapidKey);
    return await _firebaseMessaging.getToken();
  }

  Future<void> sendNotification({
    required String targetToken,
    required String targetUid,
    required String title,
    required String body,
    required String type,
  }) async {
    // ✅ [수정] 인증 정보가 준비될 때까지 잠시 대기
    if (_credentials == null || _projectId == null) {
      debugPrint("⏳ 서비스 계정 인증을 기다리는 중...");
      await _initializeServiceAccount(); // 재시도
      if (_credentials == null || _projectId == null) {
          debugPrint("❌ 인증 정보 로드 실패. 푸시 전송을 중단합니다.");
          return;
      }
    }

    try {
      // 1. 장부 기록 (기존 유지)
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetUid': targetUid,
        'title': title,
        'body': body,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 2. 푸시 발송 (인증 방식 변경)
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          // ✅ [수정] 저장해둔 AccessToken을 헤더에 추가
          'Authorization': 'Bearer ${_credentials!.accessToken.data}'
        },
        body: jsonEncode({
          // ...
          'message': {
            'token': targetToken,
            'notification': {'title': title, 'body': body},
            // ✅ [추가] 알림을 탭했을 때 이동할 페이지 정보를 'data' 필드에 숨겨서 보냅니다.
            'data': {
              'type': type, // 'chat', 'schedule' 등
            },

            'android': {
              'priority': 'high',
              'notification': {'channel_id': 'high_importance_channel', 'default_sound': true}
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default', 'badge': 1}
              }
            }
          }
        }),
      );
      
      if (response.statusCode == 200) {
         debugPrint("🚀 푸시 전송 성공");
      } else {
         debugPrint("😥 푸시 전송 실패: ${response.body}");
      }

    } catch (e) {
      debugPrint("❌ 알림 시스템 에러: $e");
    }
  }
}