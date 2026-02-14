// 안드로이드 빌드 시 웹 전용 코드가 읽히지 않도록 막아주는 파일입니다.
class PlatformViewRegistry {
  void registerViewFactory(String viewId, dynamic cb) {
    // 안드로이드에서는 웹 뷰 팩토리가 필요 없으므로 아무 작업도 하지 않습니다.
  }
}

final platformViewRegistry = PlatformViewRegistry();

void executeJs(String code) {
  // 안드로이드 환경에서는 JS eval을 무시합니다.
}