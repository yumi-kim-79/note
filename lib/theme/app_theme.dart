// [파일 위치: lib/theme/app_theme.dart]
// 웹,앱 전체적 디자인 설정
// 1. 앱 전체에 적용되는 '기본 아이콘 색상(iconTheme)'을 추가하여 아이콘이 안 보이는 문제 해결.
// 2. CardTheme 관련 에러 유발 코드는 깔끔하게 제거 상태 유지.

import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 구글 애드센스 스타일 색상 팔레트
  static const Color primaryColor = Color(0xFF1A73E8); // 구글 블루
  static const Color primaryLight = Color(0xFFE8F0FE); // 연한 블루
  static const Color backgroundColor = Color(0xFFF8F9FA); // 배경색
  static const Color surfaceColor = Colors.white; // 카드 배경

  static const Color textMain = Color(0xFF202124); // 진한 회색 (아이콘 기본 색상으로 사용)
  static const Color textSub = Color(0xFF5F6368); // 연한 회색
  static const Color borderColor = Color(0xFFDADCE0); // 테두리 색상
  static const Color errorColor = Color(0xFFD93025); // 에러 색상

  // 🛠️ 전체 테마 설정
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      scaffoldBackgroundColor: backgroundColor,

      // ✅ [추가됨] 앱 전체 기본 아이콘 색상 설정
      // 이 설정이 없으면 일부 기기에서 아이콘이 흰색으로 나와 안 보일 수 있습니다.
      iconTheme: const IconThemeData(
        color: textMain, // 아이콘을 기본적으로 '진한 회색'으로 표시
        size: 24,
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
      ),

      // 앱바 스타일
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        // 앱바 내 아이콘은 조금 더 연한 회색(textSub) 사용
        iconTheme: IconThemeData(color: textSub),
        titleTextStyle: TextStyle(color: textMain, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // 버튼 스타일
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // 입력창 스타일
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}