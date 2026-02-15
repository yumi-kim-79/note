// [파일 위치: lib/pages/settings/settings_page.dart]
// [고도화 완료] Firestore 연동으로 실제 알림 설정 저장/로드 기능 구현

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 설정 상태 변수
  bool _isLoading = true; // 데이터 로딩 중 상태
  bool _pushEnabled = true;
  bool _schedulePushEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    // 페이지가 시작될 때 Firestore에서 현재 설정값 불러오기
    _loadSettings();
  }

  // ✅ [추가] Firestore에서 설정값 불러오는 함수
  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Firestore에 저장된 값으로 상태 업데이트 (값이 없으면 true가 기본값)
        setState(() {
          _pushEnabled = data['allowChatPush'] ?? true;
          _schedulePushEnabled = data['allowSchedulePush'] ?? true;
          _soundEnabled = data['isSound'] ?? true;
          _vibrationEnabled = data['isVibrate'] ?? true;
        });
      }
    } catch (e) {
      // 에러 처리
      debugPrint("설정 로드 실패: $e");
    } finally {
      // 로딩 상태 해제
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ [추가] 스위치 값을 Firestore에 저장하는 함수
  Future<void> _updateSetting(String key, bool value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // users 컬렉션의 내 문서에 해당 키(key)의 값을 업데이트
      await _firestore.collection('users').doc(user.uid).set(
        {key: value},
        SetOptions(merge: true), // 다른 필드는 유지하고 이 필드만 덮어쓰기
      );
    } catch (e) {
      debugPrint("설정 저장 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: const Text("⚙️ 설정", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          // 로딩 중이면 인디케이터 표시, 아니면 설정 목록 표시
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text("알림 설정", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text("업무 톡톡 알림 받기"),
                      subtitle: const Text("새 메시지가 오면 알림을 받습니다."),
                      value: _pushEnabled,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      // ✅ [수정] 스위치 변경 시 UI와 DB 모두 업데이트
                      onChanged: (val) {
                        setState(() => _pushEnabled = val);
                        _updateSetting('allowChatPush', val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("일정 관리 알림 받기"),
                      subtitle: const Text("새로운 일정이 등록되거나 변경되면 알림을 받습니다."),
                      value: _schedulePushEnabled,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      // ✅ [수정] 스위치 변경 시 UI와 DB 모두 업데이트
                      onChanged: (val) {
                        setState(() => _schedulePushEnabled = val);
                        _updateSetting('allowSchedulePush', val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text("알림음"),
                      value: _soundEnabled,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      // ✅ [수정] 스위치 변경 시 UI와 DB 모두 업데이트 (키 이름: isSound)
                      onChanged: (val) {
                        setState(() => _soundEnabled = val);
                        _updateSetting('isSound', val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("진동"),
                      value: _vibrationEnabled,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      // ✅ [수정] 스위치 변경 시 UI와 DB 모두 업데이트 (키 이름: isVibrate)
                      onChanged: (val) {
                        setState(() => _vibrationEnabled = val);
                        _updateSetting('isVibrate', val);
                      },
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: const Text("💡 알림 안내\n이 설정은 앱 실행 중일 때 적용됩니다.\n완전한 푸시 알림(앱 종료 시 수신)은 서버 설정이 필요합니다.", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    )
                  ],
                ),
        ),
      ],
    );
  }
}
