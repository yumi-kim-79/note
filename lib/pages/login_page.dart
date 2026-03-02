// [파일 위치: lib/pages/login_page.dart]
// 로그인 페이지
// 1. [디자인] 기본 아이콘/텍스트 삭제 -> 회사 로고 이미지(sm_logo.png)로 교체
// 2. [기능] 아이디/비밀번호 입력 로직 및 디자인 시스템(AppTheme) 100% 유지

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

// ✅ 디자인 시스템 import
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _tryLogin() async {
    if (_idController.text.isEmpty || _pwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요.')));
      return;
    }

    await NotificationService().init();

    setState(() => _isLoading = true);

    try {
      // 1. 아이디 처리 (@sm.com 자동 완성)
      String inputId = _idController.text.trim();
      String finalEmail = inputId;
      if (!inputId.contains('@')) {
        finalEmail = "$inputId@sm.com";
      }

      // 2. [비밀번호 처리] 4자리만 입력했다면 뒤에 '00' 붙여서 로그인 시도
      String inputPw = _pwController.text.trim();
      String finalPw = inputPw;
      if (inputPw.length == 4) {
        finalPw = "${inputPw}00";
      }

      await _authService.login(
        email: finalEmail,
        password: finalPw,
      );
    } catch (e) {
      if (mounted) {
        String message = e.toString().replaceAll("Exception: ", "");
        if (message.contains("user-not-found")) message = "등록되지 않은 아이디입니다.";
        else if (message.contains("wrong-password")) message = "비밀번호가 틀렸습니다.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, // 테마 배경색 사용
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: CommonCard( // ✅ 디자인 통일: 공통 카드 위젯 사용
              width: 400, // 로그인 박스 너비 고정
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // -------------------------------------------------------
                  // ✅ [수정] 로고 이미지 적용 (기존 아이콘/텍스트 대체)
                  // -------------------------------------------------------
                  Image.asset(
                    'assets/images/sm_logo.png', // 등록한 이미지 파일명
                    width: 220, // 로고 크기 (필요에 따라 조절하세요)
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "로그인하여 업무를 시작하세요",
                    style: TextStyle(color: AppTheme.textSub),
                  ),
                  const SizedBox(height: 40),

                  // 아이디 입력창
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: "아이디 (전화번호)",
                      hintText: "예: 01012345678",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    keyboardType: TextInputType.text, // 영문/한글 입력 가능
                  ),
                  const SizedBox(height: 20),

                  // 비밀번호 입력창
                  TextField(
                    controller: _pwController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "비밀번호",
                      hintText: "4자리 입력",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.text,
                    onSubmitted: (_) => _tryLogin(),
                  ),
                  const SizedBox(height: 32),

                  // 로그인 버튼
                  CommonButton(
                    text: "로그인",
                    onPressed: _isLoading ? null : _tryLogin,
                    isLoading: _isLoading,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}