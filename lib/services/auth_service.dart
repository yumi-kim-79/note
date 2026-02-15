// [파일 위치: lib/services/auth_service.dart]
// 수정 내용:
// 1. 기존 기능(모바일 로그인 에러 방지, 관리자 직원 관리) 100% 유지
// 2. 로그인 성공 시 내 알림 토큰(fcmToken)을 DB에 자동 저장하는 기능 추가

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // 직원 등록 시 관리자 로그아웃 방지용
import 'package:flutter/foundation.dart'; // 웹/앱 구분용

// ✅ 알림 서비스를 가져옵니다 (FCM 토큰 발급용)
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. 로그인 (기존 모바일 에러 방지 코드 유지 + 알림 토큰 저장 기능 통합)
  Future<void> login({required String email, required String password}) async {
    // [기존 유지] 웹일 때만 로그인 유지 설정 (안드로이드 에러 방지)
    if (kIsWeb) {
      await _auth.setPersistence(Persistence.LOCAL);
    }

    // 로그인 실행
    UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);

    // ------------------------------------------------------------------
    // ✅ [추가 로직] 로그인 성공 시, 내 알림 토큰을 DB(users 컬렉션)에 저장합니다.
    // ------------------------------------------------------------------
    User? user = credential.user;
    if (user != null) {
      try {
        // NotificationService에서 내 기기의 고유 토큰을 가져옵니다.
        String? token = await NotificationService().getToken();

        if (token != null) {
          // users 컬렉션의 내 문서에 fcmToken 필드를 추가하거나 갱신합니다.
          // SetOptions(merge: true)를 사용하여 기존의 이름, 직급 정보는 그대로 보존합니다.
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'lastLoginAt': FieldValue.serverTimestamp(), // 마지막 로그인 시간 기록
          }, SetOptions(merge: true));

          print("✅ FCM 토큰이 성공적으로 DB에 저장되었습니다: $token");
        }
      } catch (e) {
        // 로그인 자체는 성공했으므로 알림 저장 실패 시 에러만 출력하고 중단하지 않습니다.
        print("⚠️ 알림 토큰 저장 중 오류 발생 (로그인은 성공함): $e");
      }
    }
    // ------------------------------------------------------------------
  }

  // 2. 로그아웃
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 3. 현재 유저 정보
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------
  // [기존 기능 보존] 관리자 페이지(AdminPage)용 함수들
  // ---------------------------------------------------------

  // 4. 직원 목록 실시간 가져오기 (Stream)
  Stream<QuerySnapshot> getEmployeesStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true) // 최신 등록순
        .snapshots();
  }

  // 5. 직원 등록 (관리자가 로그인 상태를 유지하면서 새 계정 생성)
  Future<void> registerEmployee({
    required String email,
    required String password,
    required String name,
    required String rank,
    required String role,
  }) async {
    // 현재 관리자 계정을 로그아웃 시키지 않기 위해 '임시 앱'을 만들어 계정 생성
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'tempRegisterApp',
      options: Firebase.app().options,
    );

    try {
      // 임시 앱으로 회원가입 시도
      UserCredential uc = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = uc.user!.uid;

      // Firestore DB에 직원 정보 저장
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'rank': rank,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid,
      });

      // 임시 앱 제거
      await tempApp.delete();
    } catch (e) {
      await tempApp.delete();
      rethrow;
    }
  }

  // 6. 직원 정보 수정
  Future<void> updateEmployee({
    required String uid,
    required String name,
    required String rank,
    required String role,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'rank': rank,
      'role': role,
    });
  }

  // 7. 직원 삭제
  Future<void> deleteEmployee(String uid) async {
    // Firestore 문서 삭제 (DB에서만 안 보이게 처리)
    await _firestore.collection('users').doc(uid).delete();
  }
}