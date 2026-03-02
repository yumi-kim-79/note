// [파일 위치: lib/pages/field/field_route_page.dart]
// 현장업무지원 / 경로관리
// 1. [웹 페이지 전용 수정] 하단 '마지막 현장 퇴근/복귀 스위치' 및 '안내 시작 버튼'을 웹에서는 숨김 처리 (if (!kIsWeb) 적용)
// 2. 새로고침 아이콘 검은색 강제 (태블릿 이슈 해결 유지)
// 3. 햄버거 버튼 검은색 강제 (태블릿 이슈 해결 유지)
// 4. 기존 기능 100% 유지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart'; // kIsWeb 사용
import 'dart:io' show Platform;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Completer 사용
import 'package:flutter/services.dart'; // 📋 클립보드 복사 기능용
import '../../main.dart'; // 🌟 [고도화 추가] GlobalUserState(스마트 캐싱)를 가져옵니다.

// 네이버 지도 패키지 (앱용)
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/building_loc.dart';

// ✅ 조건부 임포트 (웹이면 real, 앱이면 stub을 'ui'라는 이름으로 부름)
import 'web_ui_stub.dart'
if (dart.library.html) 'web_ui_real.dart' as ui;

import 'package:universal_html/html.dart' as html;

class FieldRoutePage extends StatefulWidget {
  const FieldRoutePage({super.key});

  // 🌟 [핵심 고도화] 외부(하단 메뉴바)에서도 경로 변경 상태를 확인할 수 있도록 전역 변수(static)로 격상!
  static bool globalHasUnsavedChanges = false;

  @override
  State<FieldRoutePage> createState() => FieldRoutePageState();
}

class FieldRoutePageState extends State<FieldRoutePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // [앱 전용] 네이버 지도 컨트롤러
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  final BuildingLoc company = BuildingLoc(
    name: "본사(사무실)",
    address: "인천시 부평구 충선로209번길 13",
    lat: 37.507872,
    lng: 126.735597,
    docId: "company",
  );

  List<BuildingLoc> visitList = [];
  List<BuildingLoc> _originalList = [];
  int _currentOptMode = 0;
  bool _isLoading = false;
  final String _webMapId = "naver-map-view-unique";

  bool _isRouteLocked = false;
  bool _returnToOffice = true;

  // ✅ _hasUnsavedChanges 대신 이제 FieldRoutePage.globalHasUnsavedChanges 를 사용합니다.
  bool get _hasUnsavedChanges => FieldRoutePage.globalHasUnsavedChanges;
  set _hasUnsavedChanges(bool value) => FieldRoutePage.globalHasUnsavedChanges = value; // ✅ [추가] 저장되지 않은 변경사항이 있는지 확인하는 변수

  // ✅ [추가] 뒤로 가기 시 띄울 경고 팝업 함수
  Future<bool> _showExitWarningDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("저장되지 않은 변경사항", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text("경로가 변경되었지만 저장되지 않았습니다.\n저장하지 않고 그냥 나가시겠습니까?", style: TextStyle(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // 안 나감
            child: const Text("아니오 (저장할게요)", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // 나감
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("예 (그냥 나감)"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // 외부에서 호출 가능한 새로고침 함수
  void refreshRoute() {
    _loadTodaySchedules(checkDiffOnly: _isRouteLocked, isUnlockAction: !_isRouteLocked);
  }

  @override
  void initState() {
    super.initState();
    _loadTodaySchedules(checkDiffOnly: false, isUnlockAction: false);
    // 웹일 때만 웹 지도 초기화 실행
    if (kIsWeb) _setupWebMap();
  }

  // [웹 전용] 지도 div 요소 등록
  void _setupWebMap() {
    ui.platformViewRegistry.registerViewFactory(_webMapId, (int viewId) {
      final element = html.DivElement()
        ..id = 'map-container'
        ..style.width = '100%'
        ..style.height = '100%';
      // DOM 생성 후 지도 스크립트 실행
      Future.delayed(const Duration(milliseconds: 500), () => _injectWebMapAndMarkers());
      return element;
    });
  }

  // 지도 이동 (앱/웹 분기 처리)
  Future<void> _moveMapTo(double lat, double lng) async {
    if (kIsWeb) {
      ui.executeJs("if(window.naverMapInstance) { window.naverMapInstance.morph(new naver.maps.LatLng($lat, $lng), 16); }");
    } else {
      final controller = await _mapControllerCompleter.future;
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: NLatLng(lat, lng),
        zoom: 16,
      );
      controller.updateCamera(cameraUpdate);
    }
  }

  // [웹 전용] 마커 및 경로 그리기 (JS 주입)
  void _injectWebMapAndMarkers() {
    if (!kIsWeb) return;

    final center = company;
    List<Map<String, dynamic>> allPoints = [];
    allPoints.add({'type': 'HQ', 'loc': company, 'index': -1, 'label': '🏢'});

    for (int i = 0; i < visitList.length; i++) {
      allPoints.add({'type': 'Visit', 'loc': visitList[i], 'index': i, 'label': '${i + 1}'});
    }

    // 같은 좌표 마커 그룹핑
    Map<String, List<Map<String, dynamic>>> groupedPoints = {};
    for (var p in allPoints) {
      BuildingLoc loc = p['loc'];
      String key = "${loc.lat.toStringAsFixed(5)},${loc.lng.toStringAsFixed(5)}";
      groupedPoints.putIfAbsent(key, () => []).add(p);
    }

    String markersJs = "";
    groupedPoints.forEach((key, items) {
      items.sort((a, b) {
        if (a['type'] == 'HQ') return -1;
        if (b['type'] == 'HQ') return 1;
        return (a['index'] as int).compareTo(b['index'] as int);
      });

      var topItem = items.first;
      BuildingLoc loc = topItem['loc'];
      String combinedLabel = items.map((e) => e['label']).join('+');
      String combinedNames = items.map((e) => e['loc'].name).join('<br>');

      bool hasHQ = items.any((e) => e['type'] == 'HQ');
      String bgColor = hasHQ ? '#1A233A' : '#FF6355';
      String widthStyle = combinedLabel.length > 2 ? "padding: 0 5px; width:auto;" : "width:26px;";

      markersJs += """
        (function(){
            try {
                var marker = new naver.maps.Marker({
                    position: new naver.maps.LatLng(${loc.lat}, ${loc.lng}),
                    map: map,
                    zIndex: ${hasHQ ? 9999 : 100}, 
                    icon: { 
                        content: '<div style="cursor:pointer; background:${bgColor}; color:white; height:26px; ${widthStyle} line-height:24px; text-align:center; border-radius:13px; font-weight:bold; border:2px solid white; box-shadow: 2px 2px 5px rgba(0,0,0,0.3);">' +
                                 '${combinedLabel}' + 
                                 '</div>',
                        anchor: new naver.maps.Point(13, 13)
                    }
                });
                
                if(window.currentMarkers) {
                    window.currentMarkers.push(marker);
                }

                var infoWindow = new naver.maps.InfoWindow({
                    content: '<div style="padding:10px 16px; background:white; border:1px solid #ccc; border-radius:8px; font-weight:bold; font-size:16px; line-height:1.2; box-shadow: 2px 2px 5px rgba(0,0,0,0.3);">' +
                             '${combinedNames}' + 
                             '</div>',
                    borderWidth: 0,
                    backgroundColor: "transparent",
                    disableAnchor: false,
                    pixelOffset: new naver.maps.Point(0, -15)
                });

                naver.maps.Event.addListener(marker, 'mouseover', function(e) {
                    infoWindow.open(map, marker);
                });
                naver.maps.Event.addListener(marker, 'mouseout', function(e) {
                    infoWindow.close();
                });
                
                naver.maps.Event.addListener(marker, 'dblclick', function(e) {
                    var newZoom = map.getZoom() + 1;
                    map.morph(e.coord, newZoom);
                });
            } catch(err) {
                console.error("마커 생성 중 오류:", err);
            }
        })();
      """;
    });

    String polylineJs = "if (window.currentPolyline) { window.currentPolyline.setMap(null); window.currentPolyline = null; }";

    if (visitList.isNotEmpty) {
      String pathCoords = "";
      pathCoords += "new naver.maps.LatLng(${company.lat}, ${company.lng}), ";
      for (var loc in visitList) {
        pathCoords += "new naver.maps.LatLng(${loc.lat}, ${loc.lng}), ";
      }
      if (_returnToOffice) {
        pathCoords += "new naver.maps.LatLng(${company.lat}, ${company.lng})";
      } else {
        pathCoords = pathCoords.substring(0, pathCoords.length - 2);
      }

      polylineJs += """
        window.currentPolyline = new naver.maps.Polyline({
            map: map,
            path: [$pathCoords],
            strokeColor: '#FF0000',
            strokeOpacity: 0.8,
            strokeWeight: 4,
            strokeStyle: 'shortdash'
        });
      """;
    }

    final jsCode = """
      (function() {
        function initMapWithRetry(retryCount) {
            if (typeof naver === 'undefined' || !naver.maps) {
                if (retryCount > 50) return; 
                setTimeout(function() { initMapWithRetry(retryCount + 1); }, 500);
                return;
            }

            var mapDiv = document.getElementById('map-container');
            if (!mapDiv) {
                if (retryCount > 50) return;
                setTimeout(function() { initMapWithRetry(retryCount + 1); }, 500);
                return;
            }

            if (!window.naverMapInstance) {
               try {
                   var mapOptions = {
                      center: new naver.maps.LatLng(${center.lat}, ${center.lng}),
                      zoom: 12,
                      logoControl: false
                   };
                   window.naverMapInstance = new naver.maps.Map('map-container', mapOptions);
                   window.currentMarkers = [];
                   console.log("네이버 지도 생성 성공!");
               } catch(err) {
                   console.error("지도 생성 실패:", err);
                   setTimeout(function() { initMapWithRetry(retryCount + 1); }, 500);
                   return;
               }
            }
            
            var map = window.naverMapInstance;
            
            function drawMarkers() {
                if (window.currentMarkers && window.currentMarkers.length > 0) {
                    for (var i = 0; i < window.currentMarkers.length; i++) {
                        if(window.currentMarkers[i]) {
                            window.currentMarkers[i].setMap(null);
                        }
                    }
                }
                window.currentMarkers = [];
                
                $markersJs
                $polylineJs
            }

            setTimeout(drawMarkers, 500);
        }
        
        initMapWithRetry(0);
      })();
    """;

    ui.executeJs(jsCode);
  }

  // [앱 전용] 마커 업데이트 함수
  Future<void> _updateAppMarkers() async {
    if (kIsWeb) return;

    final controller = await _mapControllerCompleter.future;
    controller.clearOverlays(); // 기존 마커 삭제

    // 1. 본사 마커
    final companyMarker = NMarker(
      id: "company",
      position: NLatLng(company.lat, company.lng),
      caption: const NOverlayCaption(text: "본사"),
    );
    controller.addOverlay(companyMarker);

    // 2. 방문지 마커들
    for (int i = 0; i < visitList.length; i++) {
      final loc = visitList[i];
      final marker = NMarker(
        id: loc.docId ?? "visit_$i",
        position: NLatLng(loc.lat, loc.lng),
        caption: NOverlayCaption(text: "${i + 1}. ${loc.name}"),
      );
      controller.addOverlay(marker);
    }

    // 3. 경로선 (Polyline)
    if (visitList.isNotEmpty) {
      List<NLatLng> coords = [NLatLng(company.lat, company.lng)];
      for (var loc in visitList) {
        coords.add(NLatLng(loc.lat, loc.lng));
      }
      if (_returnToOffice) {
        coords.add(NLatLng(company.lat, company.lng));
      }

      final path = NPathOverlay(
        id: "route_path",
        coords: coords,
        color: Colors.red,
        width: 4,
      );
      controller.addOverlay(path);
    }
  }

  // 데이터 로드
  Future<void> _loadTodaySchedules({bool checkDiffOnly = false, bool isUnlockAction = false}) async {
    if (!checkDiffOnly) setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('schedules').where('uid', isEqualTo: user.uid).get();

      List<Map<String, dynamic>> tempSortedList = [];
      bool hasSavedRoute = false;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        DateTime? startDate = (data['startDate'] as Timestamp?)?.toDate();
        DateTime? date = (data['date'] as Timestamp?)?.toDate();
        startDate ??= date;

        if (startDate == null) continue;

        DateTime endDate = (data['endDate'] as Timestamp?)?.toDate() ?? startDate;

        DateTime today = DateTime.now();
        DateTime checkDay = DateTime(today.year, today.month, today.day);
        DateTime startDay = DateTime(startDate.year, startDate.month, startDate.day);
        DateTime endDay = DateTime(endDate.year, endDate.month, endDate.day);

        // 🌟 [고도화 2차] 경로 관리 표시 방식 (all, first, none) 검사!
        String routeIncludeType = data['routeIncludeType'] ?? (data['isRouteIncluded'] == false ? 'none' : 'all');

        if (routeIncludeType == 'none') {
          continue; // "방문 안 함"이면 무조건 패스
        } else if (routeIncludeType == 'first') {
          // "첫날만 방문"인데, 오늘이 시작일(startDay)이 아니면 패스
          if (!checkDay.isAtSameMomentAs(startDay)) continue;
        }

        // 오늘이 '시작일 ~ 종료일' 사이에 포함되는지 완벽 검사
        if (checkDay.isBefore(startDay) || checkDay.isAfter(endDay)) continue;

        int? savedOrder = data['visitOrder'];
        if (savedOrder != null) {
          hasSavedRoute = true;
        }

        String bName = data['buildingName'] ?? "";
        String bAddress = data['buildingAddress'] ?? "";

        if (bName.isNotEmpty && bAddress.isNotEmpty) {
          final coord = await _getCoordinateFromAddress(bAddress);
          if (coord != null) {
            tempSortedList.add({
              'loc': BuildingLoc(
                  name: bName,
                  address: bAddress,
                  lat: coord['lat']!,
                  lng: coord['lng']!,
                  docId: doc.id,
                  isFromSchedule: true
              ),
              'order': savedOrder ?? 9999
            });
          }
        }
      }

      tempSortedList.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      List<BuildingLoc> fetchedList = tempSortedList.map((e) => e['loc'] as BuildingLoc).toList();

      if (mounted) {
        if (checkDiffOnly) {
          bool hasChanges = false;
          Set<String> currentIds = visitList.map((e) => e.docId ?? '').toSet();
          Set<String> newIds = fetchedList.map((e) => e.docId ?? '').toSet();

          if (currentIds.length != newIds.length || !currentIds.containsAll(newIds)) {
            hasChanges = true;
          } else {
            for (var newLoc in fetchedList) {
              var existing = visitList.firstWhere(
                      (e) => e.docId == newLoc.docId,
                  orElse: () => BuildingLoc(name: 'dummy', address: '', lat: 0, lng: 0, docId: 'dummy') // 에러 났던 부분 수정 완료
              );
              if (existing.name != newLoc.name || existing.address != newLoc.address) {
                hasChanges = true;
                break;
              }
            }
          }

          if (hasChanges) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                title: Row(
                  children: const [
                    Icon(Icons.notification_important, color: Colors.orange, size: 28),
                    SizedBox(width: 10),
                    Text("일정 변경 감지", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                content: const Text(
                  "일정관리에서 수정된 내역이 있습니다.\n경로 잠금을 해제하고 변경사항을 적용하시겠습니까?",
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("나중에", style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _loadTodaySchedules(checkDiffOnly: false, isUnlockAction: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("적용하기 (잠금해제)"),
                  ),
                ],
              ),
            );
          }
        } else {
          setState(() {
            visitList = fetchedList;
            _originalList = List.from(fetchedList);
            _hasUnsavedChanges = false; // ✅ 데이터 로드 시 변경사항 초기화
            if (isUnlockAction) {
              _isRouteLocked = false;
            } else if (hasSavedRoute) {
              _isRouteLocked = true;
            } else {
              _isRouteLocked = false;
            }
          });
          if (kIsWeb) _injectWebMapAndMarkers(); else _updateAppMarkers();
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, double>?> _getCoordinateFromAddress(String address) async {
    const String serverUrl = "https://getgeocode-ng3c5bh2dq-uc.a.run.app";
    try {
      final response = await http.get(Uri.parse("$serverUrl?query=$address"));
      if (response.statusCode == 200) {
        final jsonResult = json.decode(response.body);
        if (jsonResult['addresses'] != null && jsonResult['addresses'].length > 0) {
          final first = jsonResult['addresses'][0];
          return {'lat': double.parse(first['y']), 'lng': double.parse(first['x'])};
        }
      }
    } catch (e) {}
    return null;
  }

  // =======================================================
  // 🌟 [경로 최적화 엔진 고도화] 핵심 3가지 모드만 지원
  // =======================================================
  Future<void> _runOptimization(int mode) async {
    if (visitList.isEmpty) return;

    // 🌟 [옵션 3] 초기화(원상복구) 모드
    if (mode == 3) {
      setState(() {
        visitList = List.from(_originalList);
        _currentOptMode = 0;
      });
      if (kIsWeb) _injectWebMapAndMarkers(); else _updateAppMarkers();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("초기 경로로 복구되었습니다. ↩️")));
      return;
    }

    // 내 위치(출발지) 가져오기
    BuildingLoc startPoint;
    if (kIsWeb) {
      startPoint = company;
    } else {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        startPoint = BuildingLoc(name: '내 위치', address: '', lat: position.latitude, lng: position.longitude, docId: 'current');
      } catch (e) { startPoint = company; }
    }

    List<BuildingLoc> optimizedPath = [];

    // 🌟 [옵션 1 & 2] AI 둥글게 돌기 (시계 / 반시계)
    List<BuildingLoc> draftPath = List.from(visitList);
    draftPath.sort((a, b) {
      double angleA = atan2(a.lat - startPoint.lat, a.lng - startPoint.lng);
      double angleB = atan2(b.lat - startPoint.lat, b.lng - startPoint.lng);
      return angleA.compareTo(angleB);
    });

    optimizedPath = _applyTwoOpt(draftPath, startPoint);

    if (mode == 2) {
      optimizedPath = optimizedPath.reversed.toList();
    }

    setState(() {
      visitList = optimizedPath;
      _currentOptMode = mode;
      _hasUnsavedChanges = true; // ✅ AI 최적화 시 변경 발생
    });
    if (kIsWeb) _injectWebMapAndMarkers(); else _updateAppMarkers();

    String msg = mode == 1 ? "AI 최적화 (시계방향) 완료! 🔄" : "AI 최적화 (반시계방향) 완료! 🔄";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =======================================================
  // --- 최적화용 수학 계산 함수들 ---
  // =======================================================

  List<BuildingLoc> _applyTwoOpt(List<BuildingLoc> path, BuildingLoc startNode) {
    List<BuildingLoc> newPath = List.from(path);
    bool improved = true;
    while (improved) {
      improved = false;
      for (int i = 0; i < newPath.length - 1; i++) {
        for (int k = i + 1; k < newPath.length; k++) {
          if (_shouldSwap(newPath, i, k, startNode)) {
            _swapSegments(newPath, i, k);
            improved = true;
          }
        }
      }
    }
    return newPath;
  }

  bool _shouldSwap(List<BuildingLoc> path, int i, int k, BuildingLoc startNode) {
    BuildingLoc pA = (i == 0) ? startNode : path[i - 1];
    BuildingLoc pB = path[i];
    BuildingLoc pC = path[k];
    BuildingLoc pD = (k == path.length - 1) ? path[k] : path[k + 1];

    return (_calcDist(pA.lat, pA.lng, pC.lat, pC.lng) + _calcDist(pB.lat, pB.lng, pD.lat, pD.lng)) <
        (_calcDist(pA.lat, pA.lng, pB.lat, pB.lng) + _calcDist(pC.lat, pC.lng, pD.lat, pD.lng));
  }

  void _swapSegments(List<BuildingLoc> path, int i, int k) {
    List<BuildingLoc> subList = path.sublist(i, k + 1);
    path.replaceRange(i, k + 1, subList.reversed.toList());
  }

  double _calcDist(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    return 12742 * asin(sqrt(0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2));
  }

  Future<void> _launchMultiStopNavi() async {
    // 웹에서는 이 함수가 호출될 일이 없지만(버튼이 숨겨짐), 혹시 몰라 방어 코드 유지
    if (kIsWeb) return;

    if (visitList.isEmpty) return;

    double startLat = company.lat;
    double startLng = company.lng;
    String startName = Uri.encodeComponent("출발");

    double destLat; double destLng; String destName;
    List<BuildingLoc> waypoints = [];

    if (_returnToOffice) {
      destLat = company.lat;
      destLng = company.lng;
      destName = Uri.encodeComponent("본사(복귀)");
      waypoints = List.from(visitList);
    } else {
      var last = visitList.last;
      destLat = last.lat;
      destLng = last.lng;
      destName = Uri.encodeComponent(last.name);
      if (visitList.length > 1) {
        waypoints = visitList.sublist(0, visitList.length - 1);
      }
    }

    StringBuffer url = StringBuffer("nmap://route/car?");
    url.write("slat=$startLat&slng=$startLng&sname=$startName");
    url.write("&dlat=$destLat&dlng=$destLng&dname=$destName");

    for (int i = 0; i < waypoints.length && i < 15; i++) {
      var wp = waypoints[i];
      url.write("&v${i + 1}lat=${wp.lat}&v${i + 1}lng=${wp.lng}");
      url.write("&v${i + 1}name=${Uri.encodeComponent(wp.name)}");
    }
    url.write("&appname=com.sm_general.sales_note");

    try {
      Uri uri = Uri.parse(url.toString());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (Platform.isAndroid) {
          await launchUrl(Uri.parse("market://details?id=com.nhn.android.nmap"), mode: LaunchMode.externalApplication);
        } else if (Platform.isIOS) {
          await launchUrl(Uri.parse("https://apps.apple.com/kr/app/id311867728"), mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("네이버 지도 실행 중 오류가 발생했습니다.")));
    }
  }

  Future<void> _lockRoute() async {
    setState(() => _isRouteLocked = true);
    updateKeepAlive();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);

    // 🌟 [핵심 고도화] DB 조회 지연 및 '직원' 닉네임 에러 원인 제거!
    // 폰 메모리에서 내 이름을 0초 만에 가져옵니다.
    String authorName = GlobalUserState.fullName;

    List<BuildingLoc> updatedList = List.from(visitList);

    for (int i = 0; i < visitList.length; i++) {
      var item = visitList[i];

      if (item.isFromSchedule) {
        try {
          await FirebaseFirestore.instance.collection('schedules').doc(item.docId).update({
            'visitOrder': i,
          });
        } catch (e) {
          print("순서 저장 실패 (${item.name}): $e");
        }
      } else {
        try {
          var docRef = await FirebaseFirestore.instance.collection('schedules').add({
            'uid': user.uid,
            'author': authorName,
            'title': '',
            'content': '경로 관리에서 추가된 방문지',
            'date': Timestamp.fromDate(todayStart),
            'startDate': Timestamp.fromDate(todayStart),
            'endDate': Timestamp.fromDate(todayStart),
            'startTime': Timestamp.now(),
            'endTime': Timestamp.now(),
            'buildingName': item.name,
            'buildingAddress': item.address,
            'visitOrder': i,
            'status': 'active', // 🌟 내 일정이므로 '진행 중' 상태로 즉시 저장
            'colorCode': 0xFF9E9E9E,
            'createdAt': FieldValue.serverTimestamp(),
          });

          updatedList[i] = BuildingLoc(
              name: item.name,
              address: item.address,
              lat: item.lat,
              lng: item.lng,
              docId: docRef.id,
              isFromSchedule: true,
              uuid: item.uuid
          );

        } catch (e) {
          print("추가 방문지 저장 실패: $e");
        }
      }
    }

    setState(() {
      visitList = updatedList;
      _hasUnsavedChanges = false; // ✅ 경로 저장 완료 시 변경사항 초기화
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("경로 및 추가 방문지가 저장되었습니다.")));
  }

  void _unlockRoute() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("경로 잠금 해제", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("잠금을 해제하면 경로 순서가 변경될 수 있습니다.\n해제하시겠습니까?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            TextButton(onPressed: () {
              Navigator.pop(ctx);
              _loadTodaySchedules(checkDiffOnly: false, isUnlockAction: true);
            }, child: const Text("해제", style: TextStyle(color: AppTheme.primaryColor))),
          ],
        )
    );
  }

  void _showBuildingSearchSheet() {
    if (_isRouteLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("경로가 잠겨있습니다. 해제 후 추가하세요.")));
      return;
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9, expand: false,
        builder: (context, scrollController) => _BuildingSearchWidget(
          scrollController: scrollController,
          onSelected: (name, address, docId) async {
            final coord = await _getCoordinateFromAddress(address);
            if (coord != null) {
              setState(() {
                visitList.add(BuildingLoc(name: name, address: address, lat: coord['lat']!, lng: coord['lng']!, docId: docId));
                _hasUnsavedChanges = true; // ✅ 방문지 추가 시 변경 발생
              });
              if (kIsWeb) _injectWebMapAndMarkers(); else _updateAppMarkers();
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // [앱/웹 분기] 지도 위젯 선택
    Widget mapWidget;
    if (kIsWeb) {
      mapWidget = HtmlElementView(viewType: _webMapId);
    } else {
      // [앱 전용] flutter_naver_map 위젯
      mapWidget = NaverMap(
        options: const NaverMapViewOptions(
          indoorEnable: true,
          locationButtonEnable: true, // 앱에서는 현위치 버튼 활성화
          consumeSymbolTapEvents: false,
        ),
        onMapReady: (controller) {
          _mapControllerCompleter.complete(controller);
          // 지도가 준비되면 마커 그리기
          _updateAppMarkers();
        },
      );
    }

    // ✅ [수정완료] PopScope 괄호 닫기 완벽 적용
    return PopScope(
      canPop: !_hasUnsavedChanges, // 변경사항이 없으면 바로 나갈 수 있음
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // 이미 나갔으면 무시

        if (_hasUnsavedChanges) {
          final bool shouldLeave = await _showExitWarningDialog();
          if (shouldLeave && context.mounted) {
            // "예(그냥 나감)"을 선택한 경우: 강제로 나갈 수 있게 상태 변경 후 pop 실행
            setState(() => _hasUnsavedChanges = false);
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("경로 관리 (AI)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), // 텍스트도 검은색 강제
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black), // 뒤로가기 버튼 등 기본 아이콘 검은색
          actions: [
            // 🔄 새로고침 버튼: 크기 30, 색상 검정색(Colors.black) 강제 적용
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black, size: 30),
              onPressed: () {
                if (kIsWeb) {
                  // 웹인 경우 JS 지도 재주입
                  _injectWebMapAndMarkers();
                } else {
                  // 앱인 경우 데이터 리로드 및 마커 갱신
                  refreshRoute();
                }
              },
            ),

            // 🌟 [고도화] 경로 최적화 드롭다운 팝업 버튼 (상태 표시 연동)
            if (!_isRouteLocked)
              Builder(
                  builder: (context) {
                    String btnText = "경로최적화";
                    IconData btnIcon = Icons.auto_awesome;
                    Color btnColor = AppTheme.primaryColor;

                    if (_currentOptMode == 1) { btnText = "시계방향"; btnIcon = Icons.rotate_right; btnColor = Colors.blue; }
                    else if (_currentOptMode == 2) { btnText = "반시계"; btnIcon = Icons.rotate_left; btnColor = Colors.blue; }

                    bool isEnabled = visitList.length >= 2;
                    if (!isEnabled) btnColor = Colors.grey;

                    return PopupMenuButton<int>(
                      tooltip: "경로 최적화 옵션",
                      enabled: isEnabled,
                      onSelected: (int mode) => _runOptimization(mode),
                      position: PopupMenuPosition.under,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(btnIcon, size: 18, color: btnColor),
                            const SizedBox(width: 4),
                            Text(btnText, style: TextStyle(color: btnColor, fontWeight: FontWeight.bold)),
                            Icon(Icons.arrow_drop_down, size: 18, color: btnColor),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 1, child: Row(children: [Icon(Icons.rotate_right, color: Colors.blue, size: 20), SizedBox(width: 10), Text("AI 최적화 (시계방향)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))])),
                        const PopupMenuItem(value: 2, child: Row(children: [Icon(Icons.rotate_left, color: Colors.blue, size: 20), SizedBox(width: 10), Text("AI 최적화 (반시계방향)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))])),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 3, child: Row(children: [Icon(Icons.restore, color: Colors.redAccent, size: 20), SizedBox(width: 10), Text("초기화 (최초 경로 복구)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent))])),
                      ],
                    );
                  }
              ),

            // 경로 저장/해제 버튼
            if (!_isRouteLocked)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  onPressed: visitList.isEmpty ? null : _lockRoute,
                  icon: const Icon(Icons.lock_outline, size: 16),
                  label: const Text("경로저장", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03C75A), // ✅ 네이버 시그니처 초록색으로 강조
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              )
            else
              TextButton.icon(
                onPressed: _unlockRoute,
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text("잠금해제"),
                style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              ),
          ],
        ),
        body: Column(
          children: [
            // 1. 지도 영역 (화면의 40%)
            Expanded(
              flex: 4,
              child: mapWidget,
            ),

            // 2. 하단 리스트 영역 (화면의 60%)
            Expanded(
              flex: 6,
              child: Container(
                color: const Color(0xFFF5F7FA),
                child: Column(
                  children: [
                    // (1) 출발지 정보 + 방문지 추가 버튼
                    InkWell(
                      onTap: () => _moveMapTo(company.lat, company.lng),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        color: Colors.white,
                        child: Row(
                          children: [
                            const Text("🏢", style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("출발: ${company.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain)),
                                  Text(company.address, style: const TextStyle(color: AppTheme.textSub, fontSize: 13), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            // 방문지 추가 버튼 (본사 옆)
                            ElevatedButton.icon(
                              onPressed: _showBuildingSearchSheet,
                              icon: const Icon(Icons.add_location_alt, size: 16),
                              label: const Text("방문지 추가"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRouteLocked ? Colors.grey : const Color(0xFF1A233A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isLoading) const LinearProgressIndicator(),

                    // (2) 방문 리스트
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        buildDefaultDragHandles: false,
                        onReorder: (oldIdx, newIdx) {
                          if (_isRouteLocked) return;
                          if (oldIdx < newIdx) newIdx -= 1;
                          setState(() {
                            final item = visitList.removeAt(oldIdx);
                            visitList.insert(newIdx, item);
                            _hasUnsavedChanges = true; // ✅ 순서 바꿨을 때도 저장 경고 켜기
                          });
                          if (kIsWeb) _injectWebMapAndMarkers(); else _updateAppMarkers();
                        },
                        itemCount: visitList.length,
                        itemBuilder: (context, index) {
                          final building = visitList[index];
                          return Container(
                            key: ValueKey(building.uuid),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderColor),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                              leading: GestureDetector(
                                onTap: () => _moveMapTo(building.lat, building.lng),
                                child: CircleAvatar(
                                    backgroundColor: AppTheme.errorColor,
                                    foregroundColor: Colors.white,
                                    child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold))
                                ),
                              ),
                              title: Text(building.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: building.address));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("주소가 복사되었습니다. 📋"),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        building.address,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textSub),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy, size: 14, color: AppTheme.primaryColor),
                                  ],
                                ),
                              ),

                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 삭제 버튼 (잠금 상태가 아닐 때만)
                                  if (!_isRouteLocked)
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          visitList.removeAt(index);
                                          _hasUnsavedChanges = true; // ✅ 삭제했을 때도 저장 경고 켜기
                                        });
                                        if (kIsWeb) _injectWebMapAndMarkers(); else _updateAppMarkers();
                                      },
                                    ),

                                  // 🍔 드래그 핸들 (햄버거 버튼) - 색상 강제 지정 (Colors.black)
                                  if (!_isRouteLocked)
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 8.0, right: 8.0),
                                        child: Icon(Icons.drag_handle, color: Colors.black), // 검은색 강제
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // (3) 하단 옵션 (복귀 스위치 + 네비 버튼) - 앱에서만 보이도록 처리
                    if (!kIsWeb)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("마지막 현장 퇴근", style: TextStyle(color: _returnToOffice ? AppTheme.textSub : AppTheme.textMain, fontWeight: _returnToOffice ? FontWeight.normal : FontWeight.bold)),
                                Switch(
                                  value: _returnToOffice,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: (val) => setState(() {
                                    _returnToOffice = val;
                                    _hasUnsavedChanges = true; // ✅ 옵션 바꿨을 때도 저장 경고 켜기
                                  }),
                                ),
                                Text("사무실 복귀", style: TextStyle(color: _returnToOffice ? AppTheme.textMain : AppTheme.textSub, fontWeight: _returnToOffice ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            CommonButton(
                              onPressed: (_isRouteLocked && visitList.isNotEmpty) ? _launchMultiStopNavi : null,
                              text: _isRouteLocked ? "네이버 지도 안내 시작 (TBT)" : "경로를 저장해야 안내 가능",
                              icon: Icons.navigation,
                              backgroundColor: _isRouteLocked ? const Color(0xFF03C75A) : Colors.grey[400],
                              width: double.infinity,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ); // ✅ 여기가 PopScope를 닫아주는 진짜 괄호입니다!
  }
}

// [건물 검색 위젯]
class _BuildingSearchWidget extends StatefulWidget {
  final ScrollController scrollController;
  final Function(String name, String address, String docId) onSelected;
  const _BuildingSearchWidget({required this.scrollController, required this.onSelected});
  @override
  State<_BuildingSearchWidget> createState() => _BuildingSearchWidgetState();
}

class _BuildingSearchWidgetState extends State<_BuildingSearchWidget> {
  String _searchText = "";
  int _currentPage = 1;
  final int _itemsPerPage = 7;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))
          ),

          TextField(
            onChanged: (val) => setState(() { _searchText = val; _currentPage = 1; }),
            decoration: InputDecoration(
                hintText: "건물명 또는 주소 검색",
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSub),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0)
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('buildings').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var allDocs = snapshot.data!.docs;
                if (_searchText.isNotEmpty) {
                  allDocs = allDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name = (data['name'] ?? '').toString().toLowerCase();
                    String address = (data['address'] ?? '').toString().toLowerCase();
                    return name.contains(_searchText.toLowerCase()) || address.contains(_searchText.toLowerCase());
                  }).toList();
                }
                if (allDocs.isEmpty) return const Center(child: Text("검색 결과가 없습니다.", style: TextStyle(color: AppTheme.textSub)));

                int totalItems = allDocs.length;
                int totalPages = (totalItems / _itemsPerPage).ceil();
                if (_currentPage > totalPages) _currentPage = totalPages;
                if (_currentPage < 1) _currentPage = 1;
                int startIndex = (_currentPage - 1) * _itemsPerPage;
                int endIndex = startIndex + _itemsPerPage;
                if (endIndex > totalItems) endIndex = totalItems;
                var currentDocs = allDocs.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (context, index) => const Divider(),
                        controller: widget.scrollController,
                        itemCount: currentDocs.length,
                        itemBuilder: (context, index) {
                          var data = currentDocs[index].data() as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(data['address'] ?? '', style: const TextStyle(color: AppTheme.textSub)),
                            trailing: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                            onTap: () => widget.onSelected(data['name'] ?? '', data['address'] ?? '', currentDocs[index].id),
                          );
                        },
                      ),
                    ),
                    if (totalPages > 1)
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
                            Text("$_currentPage / $totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}