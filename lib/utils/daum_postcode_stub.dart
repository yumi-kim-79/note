import 'package:flutter/material.dart';

Future<Map<String, String>?> searchAddress() async {
  return null;
}

// 🌟 모바일(앱) 환경을 위한 빈 껍데기 위젯 (에러 방지용)
Widget buildDaumPostcodeWidget({required Function(Map<String, String>) onComplete}) {
  return const Center(
      child: Text('모바일 앱 환경에서는 카카오 주소 검색 패키지가 필요합니다.', style: TextStyle(color: Colors.grey))
  );
}