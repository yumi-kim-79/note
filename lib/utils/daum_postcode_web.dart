// ignore_for_file: avoid_web_libraries_in_flutter, undefined_prefixed_name, undefined_function, undefined_class
// 파일 위치: lib/utils/daum_postcode_web.dart

import 'dart:async';
import 'dart:js' as js;

Future<Map<String, String>?> searchAddress() async {
  Completer<Map<String, String>?> completer = Completer();

  // 1. 카카오 스크립트 찾기
  var daum = js.context['daum'];
  if (daum == null) return null;

  // 2. 팝업 호출 및 데이터 수신
  var postcode = js.JsObject(daum['Postcode'], [
    js.JsObject.jsify({
      'oncomplete': js.allowInterop((dynamic data) {
        completer.complete({
          'address': data['roadAddress'] ?? '',
          'buildingName': data['buildingName'] ?? '',
        });
      })
    })
  ]);

  postcode.callMethod('open');
  return completer.future;
}