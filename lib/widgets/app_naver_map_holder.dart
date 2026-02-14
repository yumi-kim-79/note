// [파일 위치: lib/widgets/app_naver_map_holder.dart]
// 수정 내용:
// 1. BuildingLoc 모델 import 경로 수정 (충돌 해결)
// 2. main.dart의 globalMapController와 연동 (지도 제어권 확보)
// 3. 기존 마커 그룹핑 및 라벨링 로직 100% 유지

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용

// ✅ [핵심] 모델 파일 import (페이지 import X)
import '../models/building_loc.dart';
// ✅ [핵심] 전역 컨트롤러 사용을 위해 main.dart import
import '../../main.dart';

class AppNaverMapHolder {
  // =========================
  // 1. 카메라 이동
  // =========================
  static Future<void> moveCamera(double lat, double lng) async {
    // main.dart에 선언된 전역 컨트롤러(globalMapController) 사용
    if (globalMapController == null || kIsWeb) return;

    try {
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: NLatLng(lat, lng),
        zoom: 16, // 상세 보기 줌 레벨
      )..setAnimation(animation: NCameraAnimation.fly, duration: const Duration(milliseconds: 800));

      await globalMapController!.updateCamera(cameraUpdate);
    } catch (e) {
      debugPrint("카메라 이동 오류: $e");
    }
  }

  // =========================
  // 2. 마커 업데이트 (그룹핑 + 라벨링 로직 유지)
  // =========================
  static Future<void> updateMarkers(
      BuildingLoc company,
      List<BuildingLoc> visits,
      ) async {
    if (globalMapController == null || kIsWeb) return;

    // 1. 기존 마커 초기화
    await globalMapController!.clearOverlays();

    // 2. 데이터 통합 (본사 + 방문지)
    List<Map<String, dynamic>> allPoints = [];

    // 본사 데이터
    allPoints.add({
      'type': 'HQ',
      'loc': company,
      'index': -1,
      'label': '🏢'
    });

    // 방문지 데이터
    for (int i = 0; i < visits.length; i++) {
      allPoints.add({
        'type': 'Visit',
        'loc': visits[i],
        'index': i,
        'label': '${i + 1}'
      });
    }

    // 3. 좌표 기준 그룹핑 (겹치는 마커 처리)
    // 소수점 5자리(약 1m 내외)가 같으면 같은 위치로 간주
    Map<String, List<Map<String, dynamic>>> groupedPoints = {};
    for (var p in allPoints) {
      BuildingLoc loc = p['loc'];
      String key = "${loc.lat.toStringAsFixed(5)},${loc.lng.toStringAsFixed(5)}";
      groupedPoints.putIfAbsent(key, () => []).add(p);
    }

    // 4. 실제 마커 생성
    Set<NMarker> markersToAdd = {};

    for (var entry in groupedPoints.entries) {
      List<Map<String, dynamic>> items = entry.value;

      // 정렬 우선순위: 본사(HQ) -> 인덱스 순
      items.sort((a, b) {
        if (a['type'] == 'HQ') return -1;
        if (b['type'] == 'HQ') return 1;
        return (a['index'] as int).compareTo(b['index'] as int);
      });

      var topItem = items.first; // 대표 항목
      BuildingLoc loc = topItem['loc'];

      // 라벨 합치기 (예: "🏢+1", "1+2")
      String combinedLabel = items.map((e) => e['label']).join('+');

      // 정보창 내용 합치기 (건물명 나열)
      String combinedNames = items.map((e) => e['loc'].name).join(', ');

      bool hasHQ = items.any((e) => e['type'] == 'HQ');

      // NMarker 생성
      final marker = NMarker(
        id: hasHQ ? 'company' : topItem['loc'].uuid, // 고유 ID 사용
        position: NLatLng(loc.lat, loc.lng),
        caption: NOverlayCaption(text: combinedLabel), // 마커 밑 텍스트
      );

      // 색상 및 레이어 설정
      if (hasHQ) {
        // 본사: 남색, 제일 위에 표시
        marker.setIconTintColor(const Color(0xFF1A233A));
        marker.setZIndex(999);
      } else {
        // 방문지: 빨간색/주황색
        marker.setIconTintColor(const Color(0xFFFF6355));
        marker.setZIndex(100);
      }

      // 마커 클릭 이벤트 (정보창 표시)
      final onMarkerInfoWindow = NInfoWindow.onMarker(
          id: marker.info.id,
          text: combinedNames
      );
      marker.setOnTapListener((m) {
        m.openInfoWindow(onMarkerInfoWindow);
      });

      markersToAdd.add(marker);
    }

    // 지도에 마커 일괄 추가
    await globalMapController!.addOverlayAll(markersToAdd);

    // 5. 경로선(Polyline) 그리기 - 선택 사항 (필요시 활성화)
    /*
    if (visits.isNotEmpty) {
      List<NLatLng> pathCoords = [NLatLng(company.lat, company.lng)];
      for (var v in visits) pathCoords.add(NLatLng(v.lat, v.lng));

      final path = NPathOverlay(
        id: 'route_path',
        coords: pathCoords,
        width: 2,
        color: Colors.red,
        outlineColor: Colors.white,
      );
      await globalMapController!.addOverlay(path);
    }
    */

    // 6. 카메라 이동 (목록이 있으면 본사 또는 첫 방문지로)
    if (visits.isNotEmpty) {
      await moveCamera(company.lat, company.lng);
    }
  }
}