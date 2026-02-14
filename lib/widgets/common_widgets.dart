// [파일 위치: lib/widgets/common_widgets.dart]
// 수정 내용: backgroundColor, textColor, width, height 파라미터 추가 (에러 해결용)

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// 🟦 공통 카드 (너비, 높이 조절 기능 추가)
class CommonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;  // ✅ [에러 해결] 너비 추가
  final double? height; // ✅ [에러 해결] 높이 추가

  const CommonCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
        // 그림자 제거 (구글 애드센스 스타일은 Flat함)
      ),
      child: child,
    );
  }
}

// 🟦 공통 버튼 (배경색, 글자색, 너비 조절 기능 추가)
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width; // ✅ [에러 해결] 버튼 너비
  final Color? backgroundColor; // ✅ [에러 해결] 배경색 커스텀
  final Color? textColor; // ✅ [에러 해결] 글자색 커스텀

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          // 배경색이 지정되면 그 색을 쓰고, 아니면 테마 기본색(파랑) 사용
          backgroundColor: backgroundColor ?? AppTheme.primaryColor,
          // 글자색이 지정되면 그 색을 쓰고, 아니면 흰색 사용
          foregroundColor: textColor ?? Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}