// [파일 위치: lib/services/auth_service.dart]
// 수정 내용: 모바일 로그인 에러 수정 코드 유지 + 관리자용 직원 관리 기능 복구

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // 직원 등록 시 관리자 로그아웃 방지용
import 'package:flutter/foundation.dart'; // 웹/앱 구분용

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. 로그인 (모바일 에러 방지 포함)
  Future<void> login({required String email, required String password}) async {
    // [중요] 웹일 때만 로그인 유지 설정 (안드로이드 에러 방지)
    if (kIsWeb) {
      await _auth.setPersistence(Persistence.LOCAL);
    }
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // 2. 로그아웃
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 3. 현재 유저 정보
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------
  // [복구된 기능] 관리자 페이지(AdminPage)용 함수들
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
    // [트릭] 현재 관리자 계정을 로그아웃 시키지 않기 위해 '임시 앱'을 만들어 계정 생성
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
        'rank': rank, // 직급
        'role': role, // 권한 (admin / user)
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid,
      });

      // 임시 앱 제거
      await tempApp.delete();
    } catch (e) {
      await tempApp.delete();
      rethrow; // 에러 발생 시 상위로 전달
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