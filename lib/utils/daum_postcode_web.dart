// ignore_for_file: avoid_web_libraries_in_flutter, undefined_prefixed_name, undefined_function, undefined_class
import 'dart:async';
import 'dart:js' as js;
import 'dart:html' as html;
// 🌟 [핵심 수정] dart:ui 대신 dart:ui_web을 가져옵니다.
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Future<Map<String, String>?> searchAddress() async {
  Completer<Map<String, String>?> completer = Completer();
  var daum = js.context['daum'];
  if (daum == null) return null;

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

// 🌟 팝업창 안에 쏙 들어가는 매립형(Embed) 카카오 주소 검색 위젯
Widget buildDaumPostcodeWidget({required Function(Map<String, String>) onComplete}) {
  final String viewId = 'daum-postcode-${DateTime.now().millisecondsSinceEpoch}';

  // 🌟 [핵심 수정] ui_web.platformViewRegistry 를 사용합니다!
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final div = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none';

    html.window.requestAnimationFrame((_) {
      var daum = js.context['daum'];
      if (daum != null) {
        var postcode = js.JsObject(daum['Postcode'], [
          js.JsObject.jsify({
            'oncomplete': js.allowInterop((dynamic data) {
              onComplete({
                'address': data['roadAddress'] ?? '',
                'buildingName': data['buildingName'] ?? '',
              });
            }),
            'width': '100%',
            'height': '100%',
          })
        ]);
        // 🌟 open 대신 embed를 사용하여 div 안에 주소창을 쑤셔 넣습니다!
        postcode.callMethod('embed', [div]);
      }
    });
    return div;
  });

  return HtmlElementView(viewType: viewId);
}