import '../models/building_loc.dart';

class AppNaverMapHolder {
  // 웹에서는 모바일 전용 기능을 실행하지 않고 조용히 넘깁니다.
  static Future<void> moveCamera(double lat, double lng) async {}

  static Future<void> updateMarkers(
      BuildingLoc company,
      List<BuildingLoc> visits,
      ) async {}
}