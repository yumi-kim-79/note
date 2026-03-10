// 건축물대장 통합 모델 페이지
// 데이터를 담는 곳
// lib/models/building_model.dart

class BuildingInfo {
  final String address;
  final String platArea;
  final String totalArea;
  final String mainPurpose;
  final String useAprvDate;
  final String flrInfo;
  final String liftInfo;
  final String householdInfo;
  final String parkingInfo;

  // 🌟 고도화를 위해 추가된 항목 (선택 사항이므로 기존 코드에 절대 에러를 일으키지 않음)
  final Map<String, dynamic>? sewerInfo;   // 정화조 정보
  final List<dynamic> floorList;           // 층별 상세 리스트
  final Map<String, dynamic>? rawTitleItem; // 원본 표제부 데이터

  BuildingInfo({
    required this.address,
    required this.platArea,
    required this.totalArea,
    required this.mainPurpose,
    required this.useAprvDate,
    required this.flrInfo,
    required this.liftInfo,
    required this.householdInfo,
    required this.parkingInfo,
    // 기존에 생성하던 곳에서 에러가 안 나도록 선택적(Optional) 처리
    this.sewerInfo,
    this.floorList = const [],
    this.rawTitleItem,
  });
}