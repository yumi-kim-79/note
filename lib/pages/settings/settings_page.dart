// [파일 위치: lib/pages/settings/settings_page.dart]
// 역할: 알림 설정 페이지 알람세
//알람기능
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 실제 알림 기능은 서버 연동이 필요하므로, 여기서는 UI 스위치만 구현
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("알림 설정", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text("업무 톡톡 알림 받기"),
                subtitle: const Text("새 메시지가 오면 알림을 받습니다."),
                value: _pushEnabled,
                activeColor: const Color(0xFF1A233A),
                onChanged: (val) => setState(() => _pushEnabled = val),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text("알림음"),
                value: _soundEnabled,
                activeColor: const Color(0xFF1A233A),
                onChanged: (val) => setState(() => _soundEnabled = val),
              ),
              SwitchListTile(
                title: const Text("진동"),
                value: _vibrationEnabled,
                activeColor: const Color(0xFF1A233A),
                onChanged: (val) => setState(() => _vibrationEnabled = val),
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