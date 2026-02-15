// [파일 위치: lib/services/notification_service.dart]
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final String _vapidKey = "BLVhS7nkRAE6a0V3d6BH8XzfKnNjfsM-omTlVBOWES_HFgU6YOL1cY2N2lRIVVhPz5KK6MksXqHNiMZAOBcY3nw";

  // ✅ [고도화] FormatException을 방지하기 위해 키를 한 줄로 완벽히 정제했습니다.
  final String _serviceAccountJson = jsonEncode({
    "type": "service_account",
    "project_id": "sm-sales-note-2026",
    "private_key_id": "10c325b778c8d50dcec2160a8e2394cb3b7e8931",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCsn8LicwIUJZmz\ngP9bQpU0uSpgfG1ozxRRIjFEq2CAdyXIfPEq5Uk0CyLCN4LWbdQsEf6jsGrnrosJ\nGt3ZDAeD4k5gh7zFjI4i2KGtEdwt4UqMV69/aB4kwFLPAU0tvQ0cJNLdhIkxB3T7\na3yLsrcPxffmizuc1m18av7Srz2f8impunYdv2IiLNYq2z41HU0SdlEn/9fZYj2K\nlVrJgf8StwGr5LS1dmX6U0mBlWEFj0usifN/nKTexUiX3eSoJD5uCR/jeZSs8/vY\n2QsxjQ+K4O+prVfqNzvMOmmuMSdTc9EXBl0Fr9VkquLFiRM+NJtZkifJOhQXAzMo\nSBfBq65rAgMBAAECggEACJ2ktXa2CNljlYD/vcdR+SKwycYME+oaAn6pZNsE4wSP\nXzVVOCXfhHh10KnCnv82UsjHI9ZfT5b3m4m6vuWJznxSGyFLO7TrNzQGxcOZcLTI\n6r5JpRtGPeFXgLt45aqE5/2yhJnj2w2bOh1ARxyxZFkmKVyTqh1Ns6MHeu6CLeRs\nPEZ9y92LR35tqHzN2MbqFsxZNXNyOY8Mwlhza6kFp4YAiPG8aeGxJ2hZLNvNVWFn\naSONL/L0ha0W7OVXPri4UO45jD01+me6duDeTWDal1vpjFDV5+DHxjgNBfexYvlp\n9MVc+4qIh5mhppV4M0Zf1uD1hosyzZlf0Ji8WvYowQKBgQDl7JgQ6wiTWX7hQdKb\npu+Zp0syz8ppJqeyYGQjdcpL8BMU7abeizTi6fzFU9x2a1RCqM0Q71GID8nE2C23\njVV9wDgWaqp3exusYUwp43K9epaFeKLRYyM0KJlKQC7C40yck4QL4oepq5F3msIY\nnD72YGkSg69or9JUrSYVJM94IQKBgQDAM5GGHn7Wh248/2GEJMa3brv72JaBKv+M\nErJeh0IzmfDabwSFCSRlKMuNjdTrcvZ+IfNUtgFZ9hD9cyApB7bNEmvOCJkYX1bL\nY5ErotmZWFT81u4FLjIIL+Qs98Z+Nn0Qz6JsnYVMgUjnquKfecPwKitSMxfUbdRU\nRRaCXMzlCwKBgQDcg9DIkRKVd8Unt6CNZkrwHDIUFpQzyz4U5zvDgqo1sJgsf02G\nrQ5Y/z9N5gNQk9mpYQnkTxLsIvBJ2WfnXib7R0rDvSOnGixNZLfOiPU34wXQFwZZ\nOfK+iJ2USABRK/0DQrvnRikEwqbuhj/XqKr+UzMS7bDI+RYJ3lLi/n344QKBgGRC\nwlfvUoUAUs44/hqbwJlxh1hh7GjnEDV2j1tmPW+DjzOzE+1+DmFCvaRS504HQ3Qa\nq791zhCqnsRHqPAeWQpy4I+yxoIDQdiJUPItWkt222alS7aiGXFR4jpe6klujSEW\n3wi/xwhYrLE10EPmNmQddbEVlr3C/sFqy9Hz45vAoGBAMg5CLVfMMIfMp34eZ+y\nq8lOfaBFd28A4EBvxl/iFMstAIk7AI1y4znMRl82OFb4UMxhiYnGkjmfffmxRyB6\nynKXWfJWjPMTRyyKQgHX2f+rN/5MWHB6SFgrrlH2Az24r0WGApa8mkeyv44g7wrV\nSCAXoNhC+4mUCujRaxdKkfWq\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@sm-sales-note-2026.iam.gserviceaccount.com",
    "client_id": "107151852558316670523",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40sm-sales-note-2026.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  });

  Future<void> init() async {
    await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
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
    try {
      // 1. 장부 기록
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetUid': targetUid,
        'title': title,
        'body': body,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 2. 푸시 발송
      final serviceAccount = ServiceAccountCredentials.fromJson(_serviceAccountJson);
      final client = await clientViaServiceAccount(serviceAccount, ['https://www.googleapis.com/auth/firebase.messaging']);
      final Map<String, dynamic> jsonMap = jsonDecode(_serviceAccountJson);
      final String projectId = jsonMap['project_id'];

      final response = await client.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': {
            'token': targetToken,
            'notification': {'title': title, 'body': body},
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
      client.close();
      if (response.statusCode == 200) debugPrint("🚀 푸시 전송 성공");
    } catch (e) {
      debugPrint("❌ 알림 시스템 에러: $e");
    }
  }
}