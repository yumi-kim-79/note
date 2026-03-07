// 건축물대장 통합 모델 페이지
// 데이터를 담는 곳

class BuildingInfo {
  final String address;      // 주소
  final String platArea;     // 대지면적
  final String totalArea;    // 연면적
  final String mainPurpose;  // 주용도
  final String useAprvDate;  // 사용승인일
  final String flrInfo;      // 건축규모 (지상/지하)
  final String liftInfo;     // 승강기 대수
  final String householdInfo; // 🌟 추가: 세대 및 가구 정보
  final String parkingInfo;   // 🌟 추가: 주차장 제원 정보

  BuildingInfo({
    required this.address,
    required this.platArea,
    required this.totalArea,
    required this.mainPurpose,
    required this.useAprvDate,
    required this.flrInfo,
    required this.liftInfo,
    required this.householdInfo, // 🌟 추가
    required this.parkingInfo,   // 🌟 추가
  });
}