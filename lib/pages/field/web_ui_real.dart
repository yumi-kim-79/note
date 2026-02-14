import 'dart:ui_web' as ui;
import 'package:js/js.dart' as js;

@js.JS('eval')
external dynamic _eval(String code);

class PlatformViewRegistry {
  // 기존 기능을 100% 유지합니다.
  void registerViewFactory(String viewId, dynamic cb) {
    ui.platformViewRegistry.registerViewFactory(viewId, cb);
  }
}

final platformViewRegistry = PlatformViewRegistry();

void executeJs(String code) {
  try {
    _eval(code);
  } catch (e) {
    print("JS 실행 오류: $e");
  }
}