//카카오 건물주소 검색 api 통합페이지

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/building_model.dart';

class BuildingService {
  // 🔑 기존 키 및 URL 100% 유지
  static const String _kakaoKey = "e1fc7f4a7281b14f7c8be88f6e146462";
  static const String _proxyUrl = "https://asia-northeast3-sm-sales-note-2026.cloudfunctions.net/fetchMolitData";

  /// 🏢 [고도화 버전] 기존 기능 100% 유지 + 층별/정화조 데이터 동시 수집
  static Future<BuildingInfo> getFullBuildingInfo(String buildingName) async {
    try {
      // 1. Firestore 건물 정보 조회 (기존 유지)
      final buildingSnap = await FirebaseFirestore.instance
          .collection('buildings')
          .where('name', isEqualTo: buildingName)
          .get();

      if (buildingSnap.docs.isEmpty) throw "DB에 해당 건물 정보가 없습니다.";
      String fullAddress = buildingSnap.docs.first.data()['address'] ?? "";

      // 2. 카카오 API 주소 분석 (기존 유지)
      final kakaoRes = await http.get(
        Uri.parse("https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(fullAddress)}"),
        headers: {"Authorization": "KakaoAK $_kakaoKey"},
      );

      if (kakaoRes.statusCode != 200) {
        throw "카카오 주소 변환 실패 (인증 오류 또는 서비스 제한)";
      }

      final kakaoData = json.decode(utf8.decode(kakaoRes.bodyBytes));
      if (kakaoData['documents'] == null || kakaoData['documents'].isEmpty) {
        throw "카카오에서 주소 데이터를 찾을 수 없습니다.";
      }

      var addr = kakaoData['documents'][0]['address'];
      String sigunguCd = addr['b_code'].substring(0, 5);
      String bjdongCd = addr['b_code'].substring(5, 10);
      String bun = addr['main_address_no'].toString().padLeft(4, '0');
      String ji = addr['sub_address_no'].toString().isEmpty ? "0000" : addr['sub_address_no'].toString().padLeft(4, '0');

      // 3. 🌟 [고도화] 파이어베이스 프록시 서버 호출 (numOfRows 추가로 전 층/전체 정화조 데이터 확보!)
      final results = await Future.wait([
        http.get(Uri.parse("$_proxyUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrTitleInfo")),
        http.get(Uri.parse("$_proxyUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrFlrOulnInfo&numOfRows=1")), // 👈 층별 최대 1개
        http.get(Uri.parse("$_proxyUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrWclfInfo&numOfRows=1")),    // 👈 정화조 최대 1개
      ]);

      // 🚨 [기존 유지] 서버 500 에러(API not found 등) 대응 로직 (표제부 기준)
      if (results[0].statusCode != 200) {
        String errorDetail = "국토부 서버 응답 오류";
        try {
          final errorData = json.decode(results[0].body);
          errorDetail = errorData['details'] ?? errorData['error'] ?? errorDetail;
        } catch (_) {}
        throw "[$errorDetail] 서버 설정을 확인해주세요.";
      }

      final molitData = json.decode(utf8.decode(results[0].bodyBytes));

      // 🚨 [기존 유지] 데이터 구조 널 체크
      var responseBody = molitData['response']?['body'];
      if (responseBody == null || responseBody['items'] == null || responseBody['items']['item'] == null) {
        throw "해당 건물은 국토부 건축물대장 정보가 존재하지 않습니다.";
      }

      var item = responseBody['items']['item'];
      if (item is List) item = item[0];

      // 🌟 [고도화] 추가 데이터 파싱 (층별 리스트 및 정화조)
      final floorItems = json.decode(utf8.decode(results[1].bodyBytes))['response']?['body']?['items']?['item'];
      final sewerItem = json.decode(utf8.decode(results[2].bodyBytes))['response']?['body']?['items']?['item'];

      // 🌟 1 & 2. [기존 유지] 주차대수 및 세대/가구/호수 합계 계산
      int parseIntSafely(dynamic val) {
        if (val == null) return 0;
        if (val is int) return val;
        return int.tryParse(val.toString()) ?? 0;
      }

      int autoParking = parseIntSafely(item['indrAutoUtcnt']) + parseIntSafely(item['oudrAutoUtcnt']);
      int mechParking = parseIntSafely(item['indrMechUtcnt']) + parseIntSafely(item['oudrMechUtcnt']);
      int hhldCnt = parseIntSafely(item['hhldCnt']);
      int fmlyCnt = parseIntSafely(item['fmlyCnt']);
      int hoCnt = parseIntSafely(item['hoCnt']);
      int totalHousehold = hhldCnt + fmlyCnt + hoCnt;

      // 🌟 3. [기존 유지] 사용승인일 예쁘게 다듬기
      String rawDate = item['useAprDay']?.toString() ?? "";
      String formattedDate = "-";
      if (rawDate.length == 8) {
        formattedDate = "${rawDate.substring(0, 4)}.${rawDate.substring(4, 6)}.${rawDate.substring(6, 8)}";
      } else if (rawDate.isNotEmpty) {
        formattedDate = rawDate;
      }

      // 4. [기존 유지 + 고도화 추가] 정리된 데이터 반환
      return BuildingInfo(
        address: fullAddress,
        platArea: "${item['platArea'] ?? '0'} ㎡",
        totalArea: "${item['totArea'] ?? '0'} ㎡",
        mainPurpose: "${item['mainPurpsCdNm'] ?? '미분류'}",
        useAprvDate: formattedDate,
        flrInfo: "지상 ${item['grndFlrCnt'] ?? '0'}층 / 지하 ${item['ugrndFlrCnt'] ?? '0'}층",
        liftInfo: "승용 ${item['rideUseElvtCnt'] ?? '0'}대 / 비상 ${item['emgenUseElvtCnt'] ?? '0'}대",
        householdInfo: "세대 $hhldCnt / 가구 $fmlyCnt\n호수 $hoCnt / 합계 $totalHousehold",
        parkingInfo: "자주식 $autoParking대\n기계식 $mechParking대",

        // 👇 새로운 데이터는 조용히 밑에 담아서 보냅니다. (기존 코드는 영향을 받지 않음)
        sewerInfo: (sewerItem is List) ? sewerItem[0] : sewerItem,
        floorList: (floorItems is List) ? floorItems : (floorItems != null ? [floorItems] : []),
        rawTitleItem: item,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================
  // 🌟 [신규 추가] 특정 건물의 '호수별 전유/공용 면적' 리스트 가져오기
  // ==========================================================
  static Future<List<Map<String, dynamic>>> getUnitAreaList(String fullAddress) async {
    try {
      // 1. 카카오 API로 주소 -> 법정동/시군구/본번/부번 변환 (기존 로직 완벽 재사용)
      final kakaoRes = await http.get(
        Uri.parse("https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(fullAddress)}"),
        headers: {"Authorization": "KakaoAK $_kakaoKey"},
      );

      if (kakaoRes.statusCode != 200) throw "카카오 주소 변환 실패";
      final kakaoData = json.decode(utf8.decode(kakaoRes.bodyBytes));
      if (kakaoData['documents'] == null || kakaoData['documents'].isEmpty) throw "카카오 주소 검색 실패";

      var addr = kakaoData['documents'][0]['address'];
      String sigunguCd = addr['b_code'].substring(0, 5);
      String bjdongCd = addr['b_code'].substring(5, 10);
      String bun = addr['main_address_no'].toString().padLeft(4, '0');
      String ji = addr['sub_address_no'].toString().isEmpty ? "0000" : addr['sub_address_no'].toString().padLeft(4, '0');

      // 2. 파이어베이스 만능 서버 호출 (operation 파라미터로 전유부 데이터 요청)
      // numOfRows=100을 주어 한 번에 넉넉하게 100호실씩 긁어옵니다.
      final url = "$_proxyUrl?sigunguCd=$sigunguCd&bjdongCd=$bjdongCd&bun=$bun&ji=$ji&operation=getBrExposPubuseAreaInfo&numOfRows=100";
      final molitRes = await http.get(Uri.parse(url));

      if (molitRes.statusCode != 200) throw "전유부 데이터 서버 응답 오류";

      final molitData = json.decode(utf8.decode(molitRes.bodyBytes));
      var items = molitData['response']?['body']?['items']?['item'];
      if (items == null) return []; // 데이터가 없으면 빈 리스트 반환

      // 리스트 형태가 아니면(1건이면) 리스트로 감싸줌
      List<dynamic> itemList = items is List ? items : [items];

      // 3. 우리가 쓰기 편하게 리스트로 가공
      List<Map<String, dynamic>> resultList = [];
      for (var item in itemList) {
        // '전유' 부분만 필터링 (공용면적 제외하고 실제 전용면적만 추출)
        if (item['exposPubuseGbCdNm'] == '전유') {
          resultList.add({
            "dong": item['dongNm'] ?? '',          // 동 (예: 101동)
            "ho": item['hoNm'] ?? '',              // 호수 (예: 201호)
            "area": item['area']?.toString() ?? '0', // 전용면적 (㎡)
            "floor": item['flrNoNm'] ?? '',        // 층수 (예: 2층)
          });
        }
      }
      return resultList;
    } catch (e) {
      // 에러 발생 시 앱이 뻗지 않고 빈 리스트를 반환하거나 에러를 던집니다.
      throw "전유부 데이터 조회 실패: $e";
    }
  }
}