// [파일 위치: lib/pages/guide/field_practical_checklist_page.dart]
// [설명: 현장 업무 가이드 - 실전 건물시설 정기점검표 (총 45문항, 초보자 맞춤형 상세 설명, 해당없음 버튼, PDF 완비)]

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FieldPracticalChecklistPage extends StatefulWidget {
  const FieldPracticalChecklistPage({super.key});

  @override
  State<FieldPracticalChecklistPage> createState() => _FieldPracticalChecklistPageState();
}

class _FieldPracticalChecklistPageState extends State<FieldPracticalChecklistPage> {
  // 🏢 대기업 표준 컬러
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);
  final Color dangerRed = const Color(0xFFDC2626);
  final Color warningOrange = const Color(0xFFF59E0B);
  final Color successGreen = const Color(0xFF10B981);
  final Color naGrey = const Color(0xFF94A3B8); // 🌟 해당없음 전용 회색

  // 📝 상태 데이터
  String? _selectedBuilding;
  bool _isSaving = false;
  bool _isPrinting = false;

  final Map<String, String> _checkStates = {};
  final Map<String, TextEditingController> _remarkControllers = {};

  // 👇👇 🌟 [고도화 1] 개별 스위치 변수 분리 및 실시간 항목 계산기 👇👇
  bool _isRegularActive = true;  // 일반 정기점검
  bool _isS1Active = false;      // 특수 S1 (장마/태풍)
  bool _isS2Active = false;      // 특수 S2 (한파/동파)
  bool _isS3Active = false;      // 특수 S3 (폭설/결빙)
  bool _isS4Active = false;      // 특수 S4 (강풍/건조)

  // 🧮 [계산기 엔진] 현재 켜진 스위치를 감지하여 멋진 타이틀을 자동으로 만들어줍니다!
  String _getDynamicTitle(bool reg, bool s1, bool s2, bool s3, bool s4) {
    int regCount = reg ? _inspectionData.fold(0, (sum, g) => sum + (g['items'] as List).length) : 0;
    int spCount = 0;
    if (s1) spCount += (_specialInspectionData[0]['items'] as List).length;
    if (s2) spCount += (_specialInspectionData[1]['items'] as List).length;
    if (s3) spCount += (_specialInspectionData[2]['items'] as List).length;
    if (s4) spCount += (_specialInspectionData[3]['items'] as List).length;

    int total = regCount + spCount;

    if (regCount > 0 && spCount > 0) return "건물 정밀 점검표 (기본 $regCount + 특수 $spCount = 총 $total항목)";
    if (regCount == 0 && spCount > 0) return "비상/특수 점검표 (총 $total항목)";
    if (regCount > 0 && spCount == 0) return "건물 정밀 점검표 (총 $regCount항목)";
    return "맞춤 점검표 (선택된 항목 없음)";
  }

  // 🗂️ [고도화] 총 45문항! 초보자도 100% 이해하는 '어린이 눈높이' 상세 지침
  final List<Map<String, dynamic>> _inspectionData = [
    {
      "group": "A. 현관 및 분리수거장 (미화 및 첫인상)",
      "icon": Icons.domain,
      "color": const Color(0xFF3B82F6),
      "items": [
        {
          "title": "건물 앞 진입로 쓰레기 청소",
          "desc": "건물 들어오는 길에 떨어진 휴지나 담배꽁초를 빗자루로 싹 쓸어주세요.",
          "isDaily": true
        },
        {
          "title": "분리수거장 정리정돈 상태",
          "desc": "종이상자는 납작하게 접고, 플라스틱 통이 넘치지 않게 꾹꾹 눌러 담아주세요.",
          "isDaily": true
        },
        {
          "title": "종량제 봉투 및 마대자루 재고",
          "desc": "창고에 청소할 때 쓸 쓰레기봉투와 마대자루가 몇 개 남았는지 세어보고 부족하면 적어주세요.",
          "isDaily": true
        },
        {
          "title": "공동현관 자동문 유리 손자국",
          "desc": "사람들이 자주 만지는 1층 자동문 유리에 묻은 끈적한 손자국을 유리 세정제로 뽀득뽀득 닦아주세요.",
          "isDaily": true
        },
        {
          "title": "로비폰(비밀번호 기계) 먼지 제거",
          "desc": "1층에서 호수 누르는 기계 화면을 부드러운 천으로 닦고, 버튼이 잘 눌리는지 꾹꾹 눌러보세요.",
          "isDaily": true
        },
        {
          "title": "우편함 및 택배함 찌라시 제거",
          "desc": "우편함에 허락 없이 덕지덕지 붙여놓은 스티커나 전단지를 깔끔하게 떼어주세요.",
          "isDaily": true
        },
        {
          "title": "1층 바닥 타일 깨짐 및 파손",
          "desc": "현관 바닥 타일이 깨지거나 들떠서 사람들이 걸려 넘어질 만한 곳이 없는지 바닥을 잘 살펴보세요.",
          "isDaily": false
        },
        {
          "title": "건물 입구 미끄럼 방지 발매트",
          "desc": "비 오는 날 깔아둔 발매트가 찢어지거나 너무 흙투성이가 아닌지 확인하고 털어주세요.",
          "isDaily": false
        },
      ]
    },
    {
      "group": "B. 승강기 및 주차장 (이용자 편의/안전)",
      "icon": Icons.elevator,
      "color": const Color(0xFF8B5CF6),
      "items": [
        {
          "title": "엘리베이터 거울 및 벽면 얼룩",
          "desc": "엘리베이터 안쪽 거울에 튄 얼룩을 닦고, 벽에 긁힌 자국이나 낙서가 없는지 살펴보세요.",
          "isDaily": true
        },
        {
          "title": "엘리베이터 바닥 흙/먼지 청소",
          "desc": "사람들이 밟고 들어온 흙이나 모래가 없게 엘리베이터 바닥을 대걸레로 깨끗이 닦아주세요.",
          "isDaily": true
        },
        {
          "title": "엘리베이터 문 틈새(레일) 이물질",
          "desc": "문이 열리고 닫히는 바닥 홈에 낀 돌멩이나 쓰레기를 붓으로 긁어내서 문이 고장 나지 않게 해요.",
          "isDaily": true
        },
        {
          "title": "엘리베이터 천장 전등 깜빡임",
          "desc": "엘리베이터 안이 어둡지 않게 천장 전등 중 깜빡거리거나 꺼진 전구가 없는지 고개를 들어 확인하세요.",
          "isDaily": false
        },
        {
          "title": "주차장 주차선 및 화살표 표시",
          "desc": "바닥에 하얗게 칠해진 주차선이나 화살표 그림이 너무 지워져서 잘 안 보이지 않는지 확인해요.",
          "isDaily": false
        },
        {
          "title": "주차장 바닥 턱(스토퍼) 덜렁거림",
          "desc": "자동차 바퀴가 닿는 바닥의 고무 턱이 나사가 빠져서 덜렁거리거나 깨지지 않았는지 발로 툭툭 건드려보세요.",
          "isDaily": false
        },
        {
          "title": "주차장 코너 주황색 볼록거울",
          "desc": "코너를 돌 때 반대편 차를 보여주는 둥근 거울이 엉뚱한 곳을 보거나 먼지가 뽀얗게 앉지 않았는지 보세요.",
          "isDaily": false
        },
        {
          "title": "기계식 주차장 문 앞 바닥 청결",
          "desc": "기계식 주차장 문 앞에 차가 미끄러지지 않게 바닥에 흘린 기름때나 쓰레기를 치워주세요.",
          "isDaily": false
        },
      ]
    },
    {
      "group": "C. 계단 및 복도 공용부 (보행 환경/소음)",
      "icon": Icons.stairs,
      "color": const Color(0xFF10B981),
      "items": [
        {
          "title": "복도 바닥 껌자국 및 커피 얼룩",
          "desc": "층마다 복도를 걸어 다니며 바닥에 까맣게 붙은 껌이나 커피 쏟은 끈적한 자국을 닦아주세요.",
          "isDaily": true
        },
        {
          "title": "계단 쇠 손잡이(난간) 끈적임 닦기",
          "desc": "사람들이 오르내릴 때 잡는 계단 손잡이에 먼지가 까맣게 묻어나지 않게 걸레로 닦아주세요.",
          "isDaily": true
        },
        {
          "title": "계단 창문 틀(레일) 벌레 사체 청소",
          "desc": "층마다 있는 계단 창문 틀에 죽어있는 파리나 모기, 거미줄을 빗자루로 살살 털어내세요.",
          "isDaily": true
        },
        {
          "title": "복도 천장 센서등 켜짐 테스트",
          "desc": "복도를 걸어갈 때 내 움직임을 알아채고 머리 위 전등이 1초 만에 바로바로 켜지는지 확인하세요.",
          "isDaily": false
        },
        {
          "title": "비상구 안내 표지판 초록 불빛",
          "desc": "문 위에 달린 초록색 달리기 모양(비상구) 간판 불빛이 24시간 항상 밝게 켜져 있는지 보세요.",
          "isDaily": false
        },
        {
          "title": "복도 앞 자전거/택배 상자 길 막음",
          "desc": "입주민이 복도나 계단에 개인 자전거, 택배 상자를 쌓아둬서 지나가기 비좁은 곳이 있는지 확인해요.",
          "isDaily": false
        },
        {
          "title": "계단 무거운 쇠문(방화문) 닫히는 속도",
          "desc": "계단 쇠문이 닫힐 때 '쾅!' 하고 너무 세게 닫히면 다칠 수 있어요. 부드럽고 천천히 닫히는지 확인하세요.",
          "isDaily": false
        },
        {
          "title": "각 층 벽면 페인트 벗겨짐 및 낙서",
          "desc": "복도나 계단 벽면 페인트가 지저분하게 벗겨지거나 누군가 펜으로 낙서를 해둔 곳이 없는지 찾아보세요.",
          "isDaily": false
        },
      ]
    },
    {
      "group": "D. 기계실 외관 및 창고 (정리정돈/기본 점검)",
      "icon": Icons.precision_manufacturing,
      "color": const Color(0xFFF59E0B),
      "items": [
        {
          "title": "지하 기계실 철문 튼튼한 자물쇠 잠금",
          "desc": "위험한 기계가 있는 지하 기계실 문은 아무나 못 들어가게 튼튼한 자물쇠로 꽉 잠겨있어야 해요.",
          "isDaily": true
        },
        {
          "title": "기계실 환풍기 부드럽게 돌아가는 소리",
          "desc": "기계실 밖에서 들었을 때 환풍기가 '왱~' 하고 부드럽게 잘 돌아가는지, 삐걱거리는 쇳소리가 나지 않는지 들어보세요.",
          "isDaily": true
        },
        {
          "title": "청소 창고 내부 대걸레 및 빗자루 정리",
          "desc": "대걸레는 냄새 안 나게 말려두고, 빗자루와 쓰레받기가 쓰기 편하게 제자리에 가지런히 정리되어 있는지 보세요.",
          "isDaily": true
        },
        {
          "title": "창고 안 락스/세제통 뚜껑 꽉 닫힘",
          "desc": "바닥 닦는 약품이나 세제통 뚜껑이 꽉 닫혀있는지 확인해요. 뚜껑이 열려있으면 독한 냄새가 나고 쏟아지면 위험해요.",
          "isDaily": true
        },
        {
          "title": "예비 형광등 및 화장지 소모품 정리",
          "desc": "나중에 갈아 끼울 새 전구나 화장지 같은 물건들이 창고 선반에 종류별로 예쁘게 놓여있는지 확인하세요.",
          "isDaily": false
        },
        {
          "title": "정화조실(화장실 물 모이는 곳) 환기 냄새",
          "desc": "정화조실 문틈으로 코를 찌르는 심한 똥 냄새가 밖으로 새어 나오지 않는지 코를 킁킁거려 맡아보세요.",
          "isDaily": false
        },
        {
          "title": "지하실 천장 네모난 판(마감재) 떨어짐",
          "desc": "지하실 천장을 덮고 있는 네모난 판이 덜렁거리거나 바닥으로 뚝 떨어져 있지 않은지 위를 쳐다보세요.",
          "isDaily": false
        },
        {
          "title": "지하실 바닥 구석 거미줄 및 곰팡이",
          "desc": "지하실 구석구석에 거미줄이 쳐져 있거나 축축한 벽에 까맣게 곰팡이가 핀 곳이 있다면 청소해 주세요.",
          "isDaily": false
        },
      ]
    },
    {
      "group": "E. 옥상 및 건물 외부 시설 (야외 환경)",
      "icon": Icons.roofing,
      "color": const Color(0xFFEC4899),
      "items": [
        {
          "title": "옥상 바닥 빗물 빠지는 구멍 막힘 치우기",
          "desc": "옥상 바닥 구석에 뚫린 구멍이 낙엽이나 비닐봉지로 막혀있지 않은지 빗자루로 싹 치워주세요. 비 오면 물바다가 돼요.",
          "isDaily": true
        },
        {
          "title": "옥상 바닥 초록색/회색 페인트 까짐",
          "desc": "옥상 바닥에 칠해진 페인트가 딱지처럼 떨어져 나가거나 가뭄 논바닥처럼 쩍쩍 갈라진 곳이 있는지 밟아보세요.",
          "isDaily": false
        },
        {
          "title": "옥상 가장자리 벽(난간) 흔들림 테스트",
          "desc": "옥상 끝부분에 있는 쇠창살이나 담벼락을 두 손으로 잡고 흔들었을 때 덜렁거리지 않고 튼튼한지 꽉 쥐어보세요.",
          "isDaily": false
        },
        {
          "title": "옥상 은색 환풍기(벤틸레이터) 돌아가는지",
          "desc": "옥상에 세워진 은색 동그란 환풍기가 바람에 빙글빙글 잘 돌아가는지 쳐다보세요. 멈춰있으면 화장실 냄새가 안 빠져요.",
          "isDaily": false
        },
        {
          "title": "옥상 구석 담배꽁초 및 빈 캔 버려진 것",
          "desc": "사람들이 몰래 옥상에 올라와서 구석에 버리고 간 담배꽁초나 캔커피 쓰레기가 없는지 싹 주워주세요.",
          "isDaily": false
        },
        {
          "title": "건물 밖 자전거 보관소 지붕 먼지 털기",
          "desc": "건물 밖에 있는 자전거 보관소 지붕에 뽀얗게 쌓인 먼지를 털어내고 주변 흙먼지를 쓸어주세요.",
          "isDaily": false
        },
        {
          "title": "건물 밖 커다란 에어컨 실외기 주변 박스 치우기",
          "desc": "건물 밖에 놓여있는 윙윙 돌아가는 에어컨 실외기 주변에 종이박스를 쌓아두면 안 돼요. 다 치워주세요.",
          "isDaily": false
        },
        {
          "title": "건물 앞 작은 정원(화단) 잡초 뽑기",
          "desc": "건물 앞 작은 정원(화단)에 잡초가 너무 지저분하게 많이 자랐거나, 바람에 꺾여 덜렁거리는 나뭇가지가 없는지 보세요.",
          "isDaily": false
        },
      ]
    },
    // 🌟 [신규 추가] 지하실 침수 및 누수 특별 관리 5항목
    {
      "group": "F. 지하실 침수 특별 관리 (누수 예방)",
      "icon": Icons.water_damage,
      "color": const Color(0xFF0EA5E9),
      "items": [
        {
          "title": "지하주차장 입구 빗물 막이판(차수판) 상태",
          "desc": "비가 엄청 많이 올 때 빗물이 지하로 폭포처럼 쏟아지지 않게 막아주는 무거운 철판이나 모래주머니가 찢어진 곳 없이 잘 있는지 확인하세요.",
          "isDaily": false
        },
        {
          "title": "물 모이는 웅덩이(집수정) 안쪽 쓰레기 건져내기",
          "desc": "지하에 물이 모이는 웅덩이(집수정) 안을 후레쉬로 비춰보세요. 비닐봉지가 둥둥 떠다니면 펌프가 막혀서 지하실이 물바다가 되니 긴 막대기로 건져내세요.",
          "isDaily": false
        },
        {
          "title": "물 퍼내는 펌프 상자(제어반) '자동' 불빛 확인",
          "desc": "벽에 붙어있는 펌프 스위치 철상자에 스위치가 '수동'이 아니라 '자동'으로 돌아가 있는지, 전기가 들어온다는 불빛이 켜져 있는지 꼭 확인하세요.",
          "isDaily": false
        },
        {
          "title": "지하실 천장 파이프 물방울 맺힘(누수) 확인",
          "desc": "지하실 천장을 지나가는 파이프에서 물방울이 맺혀 바닥으로 뚝뚝 떨어지는지 쳐다보세요. 그 아래 주차된 자동차에 석회물이 떨어지면 큰일 나요.",
          "isDaily": false
        },
        {
          "title": "지하실 밖 환기구(드라이에어리어) 빗물 고임",
          "desc": "1층 밖에서 지하실로 공기가 통하게 뚫어놓은 창문 공간을 내려다보세요. 그곳에 빗물이 수영장처럼 고여있거나 낙엽이 쌓여있으면 지하실 벽으로 물이 스며들어요.",
          "isDaily": false
        },
      ]
    },
  ];
  // 🌟 [신규 추가] 비상/계절별 특수점검 16항목 데이터
  final List<Map<String, dynamic>> _specialInspectionData = [
    {
      "group": "S1. 장마 및 태풍 (여름철 집중호우/강풍)",
      "icon": Icons.water_drop,
      "color": const Color(0xFF0D9488),
      "items": [
        {"title": "옥상 빗물 빠지는 구멍(루프드레인) 청소", "desc": "옥상에 올라가서 빗물이 내려가는 구멍이 쓰레기나 비닐, 나뭇잎으로 막혀있지 않은지 싹 치워주세요. 막히면 옥상이 물바다가 됩니다!", "isDaily": false},
        {"title": "복도 및 계단 창문 꽉 닫고 잠금쇠 채우기", "desc": "층마다 돌아다니면서 열려있는 모든 창문을 닫고, 바람에 덜컹거리지 않게 창문 잠금쇠(크리센트)까지 딸깍 소리 나게 꽉 채워주세요.", "isDaily": false},
        {"title": "건물 밖 날아갈 수 있는 물건 묶기", "desc": "건물 밖에 세워둔 입간판, 재활용 분리수거통, 큰 화분 등이 강풍에 날아가 남의 차를 부수지 않게 벽으로 바짝 붙이고 끈으로 꽁꽁 묶어주세요.", "isDaily": false},
        {"title": "지하주차장 입구 차수판/모래주머니 전진 배치", "desc": "갑자기 비가 쏟아져서 물이 지하로 넘칠 때 1초라도 빨리 막을 수 있도록, 무거운 철판이나 모래주머니를 입구 바로 옆으로 꺼내두세요.", "isDaily": false},
      ]
    },
    {
      "group": "S2. 한파 및 동파 (겨울철 영하권 강추위)",
      "icon": Icons.ac_unit,
      "color": const Color(0xFF3B82F6),
      "items": [
        {"title": "복도 및 계단 창문 틈새 막기 (찬바람 유입 차단)", "desc": "찬 바람이 쌩쌩 들어오면 복도에 있는 수도관이 얼어 터집니다. 조금이라도 열려있는 창문이 없는지 확인하고 전부 꽉 닫아주세요.", "isDaily": false},
        {"title": "1층 공동현관 자동문 끝까지 닫히는지 확인", "desc": "1층 문이 고장 나서 계속 열려있으면 1층 수도 계량기가 바로 얼어버려요. 사람이 지나간 후 문이 끝까지 빈틈없이 꽉 닫히는지 지켜보세요.", "isDaily": false},
        {"title": "복도 수도 계량기함 안쪽 보온재(헌 옷/뽁뽁이) 채우기", "desc": "복도 벽에 있는 수도 계량기 철판 문을 열어보고, 안쪽에 안 입는 수건이나 뽁뽁이가 꽉 차 있어서 배관이 따뜻하게 덮여있는지 꾹꾹 눌러보세요.", "isDaily": false},
        {"title": "지하 기계실 전열기(미니 히터) 켜기 및 화재 주의", "desc": "펌프가 있는 기계실이 너무 추우면 안 되니 동파 방지용 히터를 켜두되, 주변에 종이박스 같은 타기 쉬운 물건이 없는지 꼭 치워주세요.", "isDaily": false},
      ]
    },
    {
      "group": "S3. 폭설 및 결빙 (겨울철 눈/빙판길)",
      "icon": Icons.severe_cold,
      "color": const Color(0xFF6366F1),
      "items": [
        {"title": "눈 치우는 넉가래(눈삽)와 빗자루 1층에 꺼내두기", "desc": "창고 깊숙이 쳐박혀 있던 눈삽과 큰 빗자루를 경비원이나 입주민이 바로바로 쓸 수 있도록 1층 현관문 안쪽에 잘 보이게 세워두세요.", "isDaily": false},
        {"title": "건물 입구 염화칼슘(눈 녹이는 약) 제설함 확인", "desc": "눈이 오면 바닥에 바로 뿌릴 수 있게 염화칼슘 포대가 넉넉히 있는지, 딱딱하게 돌덩이처럼 굳어서 못 쓰게 되지는 않았는지 꾹 눌러보세요.", "isDaily": false},
        {"title": "1층 출입구 대리석 바닥 미끄럼 방지 매트 깔기", "desc": "매끈한 대리석 바닥에 눈 묻은 신발로 들어오면 꽈당 넘어지기 쉽습니다. 입구부터 엘리베이터 앞까지 두꺼운 발매트를 쫙 깔아주세요.", "isDaily": false},
        {"title": "외부 주차장 진입로(언덕길) 얼음 깨기", "desc": "차가 들어오고 나가는 언덕길 바닥에 눈이 얼어붙었다면, 망치나 뾰족한 삽으로 살살 깨서 자동차 바퀴가 헛돌지 않게 미끄럼을 방지해 주세요.", "isDaily": false},
      ]
    },
    {
      "group": "S4. 강풍 및 건조 (봄/가을철 화재 조심)",
      "icon": Icons.local_fire_department,
      "color": const Color(0xFFEF4444),
      "items": [
        {"title": "건물 주변 화단 바짝 마른 낙엽 싹 치우기", "desc": "누군가 생각 없이 툭 버린 담배꽁초 불씨 하나에 큰불이 날 수 있어요. 건물 구석이나 화단에 쌓인 바삭바삭한 낙엽들을 빗자루로 싹 쓸어 담아주세요.", "isDaily": false},
        {"title": "층별 빨간 소화기 위치 및 동그란 안전핀 확인", "desc": "불이 났을 때 당황하지 않고 쓸 수 있게 소화기가 구석에 숨겨져 있지 않은지, 손잡이에 꽂힌 동그란 안전핀이 빠져있진 않은지 쓱 쳐다봐주세요.", "isDaily": false},
        {"title": "옥상 안테나 및 낡은 구조물 흔들림 검사", "desc": "옥상에 세워진 낡은 구조물이나 간판이 거센 봄바람에 덜렁거려서 1층 바닥으로 뚝 떨어질 위험은 없는지 두 손으로 꽉 잡고 흔들어보세요.", "isDaily": false},
        {"title": "옥상 무거운 쇠문(방화문) 닫힘 상태 유지", "desc": "바람이 세게 불어서 옥상 문이 '쾅!' 닫히다가 문이 박살 나거나 사람이 다칠 수 있어요. 문이 제멋대로 열리지 않게 꼭 닫아두세요.", "isDaily": false},
      ]
    }
  ];

  String _searchRecordQuery = "";
  int _currentRecordPage = 1;

  @override
  void initState() {
    super.initState();
    void initControllers(List<Map<String, dynamic>> dataList) {
      for (var group in dataList) {
        for (var item in group['items']) {
          _remarkControllers[item['title']] = TextEditingController();
        }
      }
    }
    initControllers(_inspectionData);
    initControllers(_specialInspectionData);
  }

  @override
  void dispose() {
    for (var controller in _remarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 🌟 [추가됨] 작성자 본인 확인 후 기록 삭제
  Future<void> _confirmDeleteRecord(String docId, String bName,
      BuildContext dialogCtx) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            backgroundColor: Colors.white,
            title: const Row(children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text("점검 기록 삭제", style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red))
            ]),
            content: Text(
                "[$bName] 건물의 점검 기록을 정말 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                      "취소", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("삭제하기", style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('inspections')
            .doc(docId)
            .delete();
        if (mounted) {
          Navigator.pop(dialogCtx); // 상세 보기 팝업도 같이 닫기
          _showSnackBar("점검 기록이 삭제되었습니다.", false);
        }
      } catch (e) {
        _showSnackBar("삭제 중 오류가 발생했습니다.", true);
      }
    }
  }

  // ---------------------------------------------------------
  // 💾 1. 서버 저장 로직 (저장 즉시 리스트에 나타나도록 시간 엔진 교체)
  // ---------------------------------------------------------
  Future<void> _saveInspection() async {
    if (_selectedBuilding == null) {
      _showSnackBar("먼저 점검할 건물을 선택해주세요.", true);
      return;
    }
    if (!_isRegularActive && !_isS1Active && !_isS2Active && !_isS3Active && !_isS4Active) {
      _showSnackBar("최소 1개 이상의 점검 모드 스위치를 켜주세요.", true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String inspectorName = "현장 담당자";
      String inspectorRank = "";

      if (user != null) {
        final uDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (uDoc.exists) { inspectorName = uDoc['name'] ?? '현장 담당자'; inspectorRank = uDoc['rank'] ?? ''; }
      }

      Map<String, dynamic> results = {};
      _checkStates.forEach((key, state) {
        bool isReg = _inspectionData.any((g) => (g['items'] as List).any((i) => i['title'] == key));
        bool isS1 = (_specialInspectionData[0]['items'] as List).any((i) => i['title'] == key);
        bool isS2 = (_specialInspectionData[1]['items'] as List).any((i) => i['title'] == key);
        bool isS3 = (_specialInspectionData[2]['items'] as List).any((i) => i['title'] == key);
        bool isS4 = (_specialInspectionData[3]['items'] as List).any((i) => i['title'] == key);

        if ((_isRegularActive && isReg) || (_isS1Active && isS1) || (_isS2Active && isS2) || (_isS3Active && isS3) || (_isS4Active && isS4)) {
          results[key] = { "status": state, "remark": _remarkControllers[key]?.text.trim() ?? "" };
        }
      });

      if (results.isEmpty) {
        _showSnackBar("최소 1개 이상의 항목을 점검(체크)해주세요.", true);
        setState(() => _isSaving = false);
        return;
      }

      await FirebaseFirestore.instance.collection('inspections').add({
        "buildingName": _selectedBuilding, "inspectorUid": user?.uid ?? "unknown", "inspectorName": inspectorName, "inspectorRank": inspectorRank,
        "createdAt": Timestamp.now(), // 🌟 [핵심 해결 1] 서버 시간 대기 없이 기기 시간을 즉시 꽂아 바로 노출되게 만듭니다!
        "isRegularActive": _isRegularActive,
        "isS1Active": _isS1Active, "isS2Active": _isS2Active, "isS3Active": _isS3Active, "isS4Active": _isS4Active,
        "results": results,
      });

      _showSnackBar("✅ 점검 결과가 성공적으로 서버에 저장되었습니다.", false);

      setState(() {
        _selectedBuilding = null; _checkStates.clear();
        for (var c in _remarkControllers.values) { c.clear(); }
        _currentRecordPage = 1; // 🌟 [핵심 해결 2] 저장 완료 시 무조건 1페이지로 점프시켜 내 기록을 바로 보게 합니다!
        _searchRecordQuery = ""; // 검색어도 초기화
      });
    } catch (e) {
      _showSnackBar("저장 중 오류가 발생했습니다: $e", true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------
  // 🖨️ 2. PDF 출력 로직 (동적 타이틀 & 과거 데이터 호환성 보장)
  // ---------------------------------------------------------
  Future<void> _printChecklistPdf(Map<String, dynamic> data, String dateStr) async {
    setState(() => _isPrinting = true);
    try {
      final pdf = pw.Document();
      final fontRegular = await PdfGoogleFonts.nanumGothicRegular();
      final fontBold = await PdfGoogleFonts.nanumGothicBold();

      String bName = data['buildingName'] ?? '미상';
      String iName = data['inspectorName'] ?? '미상';
      String iRank = data['inspectorRank'] ?? '';
      Map<String, dynamic> results = data['results'] ?? {};

      bool regAct = data['isRegularActive'] ?? true;
      bool s1Act = data['isS1Active'] ?? (data['isSpecialActive'] ?? false);
      bool s2Act = data['isS2Active'] ?? (data['isSpecialActive'] ?? false);
      bool s3Act = data['isS3Active'] ?? (data['isSpecialActive'] ?? false);
      bool s4Act = data['isS4Active'] ?? (data['isSpecialActive'] ?? false);

      String reportTitle = _getDynamicTitle(regAct, s1Act, s2Act, s3Act, s4Act);

      List<Map<String, dynamic>> activeGroups = [];
      if (regAct) activeGroups.addAll(_inspectionData);
      if (s1Act) activeGroups.add(_specialInspectionData[0]);
      if (s2Act) activeGroups.add(_specialInspectionData[1]);
      if (s3Act) activeGroups.add(_specialInspectionData[2]);
      if (s4Act) activeGroups.add(_specialInspectionData[3]);

      List<pw.TableRow> tableRows = [
        pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: pw.Text("점검 구역", style: pw.TextStyle(font: fontBold, fontSize: 9), textAlign: pw.TextAlign.center)),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: pw.Text("점검 항목명", style: pw.TextStyle(font: fontBold, fontSize: 9), textAlign: pw.TextAlign.center)),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: pw.Text("결과", style: pw.TextStyle(font: fontBold, fontSize: 9), textAlign: pw.TextAlign.center)),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: pw.Text("특이사항/조치내역", style: pw.TextStyle(font: fontBold, fontSize: 9), textAlign: pw.TextAlign.center)),
            ]
        )
      ];

      for (var group in activeGroups) {
        String groupName = group['group'].toString().split('.').last.trim();
        for (var item in group['items']) {
          String title = item['title'];
          var res = results[title];
          String statusText = "미점검"; PdfColor statusColor = PdfColors.grey600;
          if (res != null) {
            if (res['status'] == 'pass') { statusText = "합격"; statusColor = PdfColors.green700; }
            else if (res['status'] == 'warn') { statusText = "미흡"; statusColor = PdfColors.orange700; }
            else if (res['status'] == 'fail') { statusText = "불량"; statusColor = PdfColors.red700; }
            else if (res['status'] == 'na') { statusText = "해당없음"; statusColor = PdfColors.grey500; }
          }
          String remark = res != null ? (res['remark'] ?? '') : '';

          tableRows.add(pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: pw.Text(groupName, style: pw.TextStyle(font: fontRegular, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: pw.Text(title, style: pw.TextStyle(font: fontRegular, fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: pw.Text(statusText, style: pw.TextStyle(font: fontBold, fontSize: 8, color: statusColor), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: pw.Text(remark, style: pw.TextStyle(font: fontRegular, fontSize: 8))),
              ]
          ));
        }
      }

      pdf.addPage(
          pw.MultiPage(
              pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(24),
              build: (pw.Context context) {
                return [
                  pw.Header(level: 0, child: pw.Text("SM종합관리 $reportTitle", style: pw.TextStyle(font: fontBold, fontSize: 14))),
                  pw.SizedBox(height: 8),
                  pw.Container(
                      padding: const pw.EdgeInsets.all(8), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text("• 점검 대상 건물 : $bName", style: pw.TextStyle(font: fontBold, fontSize: 11)), pw.SizedBox(height: 4), pw.Text("• 점검 일시 : $dateStr", style: pw.TextStyle(font: fontRegular, fontSize: 11))]),
                            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text("• 담당자 : $iName $iRank", style: pw.TextStyle(font: fontBold, fontSize: 11)), pw.SizedBox(height: 4), pw.Text("• 소속 : SM현장지원팀", style: pw.TextStyle(font: fontRegular, fontSize: 11))]),
                          ]
                      )
                  ),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                    columnWidths: { 0: const pw.FlexColumnWidth(1.5), 1: const pw.FlexColumnWidth(3.5), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(2.5) },
                    children: tableRows,
                  ),
                ];
              }
          )
      );
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: '${bName}_맞춤점검보고서_$dateStr.pdf');
    } catch (e) { _showSnackBar("PDF 생성 중 오류가 발생했습니다.", true); } finally { setState(() => _isPrinting = false); }
  }

  // ---------------------------------------------------------
  // 📋 3. 기록 팝업 (동적 타이틀 연동)
  // ---------------------------------------------------------
  void _showRecordDetailDialog(Map<String, dynamic> data, String dateStr, String docId) {
    String bName = data['buildingName'] ?? '미상';
    String iName = data['inspectorName'] ?? '현장 담당자';
    String iRank = data['inspectorRank'] ?? '';
    String inspectorUid = data['inspectorUid'] ?? '';
    Map<String, dynamic> results = data['results'] ?? {};

    bool isAuthor = FirebaseAuth.instance.currentUser?.uid == inspectorUid;

    bool regAct = data['isRegularActive'] ?? true;
    bool s1Act = data['isS1Active'] ?? (data['isSpecialActive'] ?? false);
    bool s2Act = data['isS2Active'] ?? (data['isSpecialActive'] ?? false);
    bool s3Act = data['isS3Active'] ?? (data['isSpecialActive'] ?? false);
    bool s4Act = data['isS4Active'] ?? (data['isSpecialActive'] ?? false);

    String popupTitle = _getDynamicTitle(regAct, s1Act, s2Act, s3Act, s4Act);

    List<Map<String, dynamic>> activeGroups = [];
    if (regAct) activeGroups.addAll(_inspectionData);
    if (s1Act) activeGroups.add(_specialInspectionData[0]);
    if (s2Act) activeGroups.add(_specialInspectionData[1]);
    if (s3Act) activeGroups.add(_specialInspectionData[2]);
    if (s4Act) activeGroups.add(_specialInspectionData[3]);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 800, height: MediaQuery.of(context).size.height * 0.8, padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(color: primaryNavy, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.assignment, color: Colors.white, size: 24), const SizedBox(width: 10),
                          Expanded(child: Text("[$bName] ${popupTitle.replaceAll('건물 정밀 점검표 ', '')}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryNavy),
                      icon: _isPrinting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.print, size: 18),
                      label: const Text("인쇄", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _isPrinting ? null : () => _printChecklistPdf(data, dateStr),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16), color: const Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("점검자 정보", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text("$iName $iRank", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy))])),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(child: Padding(padding: const EdgeInsets.only(left: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("점검 일시", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(dateStr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy))]))),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: activeGroups.map((group) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group['group'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
                          const Divider(),
                          ...group['items'].map<Widget>((item) {
                            String title = item['title']; var res = results[title];
                            IconData sIcon = Icons.help_outline; Color sColor = Colors.grey; String sText = "미점검"; String sRemark = "";
                            if (res != null) {
                              if (res['status'] == 'pass') { sIcon = Icons.check_circle; sColor = successGreen; sText = "합격"; }
                              else if (res['status'] == 'warn') { sIcon = Icons.warning_rounded; sColor = warningOrange; sText = "미흡"; }
                              else if (res['status'] == 'fail') { sIcon = Icons.cancel; sColor = dangerRed; sText = "불량"; }
                              else if (res['status'] == 'na') { sIcon = Icons.remove_circle_outline; sColor = naGrey; sText = "해당없음"; }
                              sRemark = res['remark'] ?? '';
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(sIcon, color: sColor, size: 20), const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (sRemark.isNotEmpty) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey[300]!)), child: Text("사유/조치: $sRemark", style: const TextStyle(fontSize: 13, color: Color(0xFF475569))))
                                      ],
                                    ),
                                  ),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(sText, style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 12)))
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isAuthor) TextButton.icon(onPressed: () => _confirmDeleteRecord(docId, bName, ctx), icon: const Icon(Icons.delete, color: Colors.red), label: const Text("기록 삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))) else const SizedBox(),
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? dangerRed : successGreen));
  }

  // ---------------------------------------------------------
  // 📱 메인 화면 (상단 제목 실시간 변경 & 모바일 짤림 방지 적용)
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    String currentTitle = _getDynamicTitle(_isRegularActive, _isS1Active, _isS2Active, _isS3Active, _isS4Active);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        // 👇 🌟 [모바일 최적화] 긴 제목이 모바일에서 두 줄로 깨지거나 짤리지 않도록 FittedBox 장착 👇
        title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(currentTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 18))
        ),
        backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Color(0xFF1E293B)), elevation: 0.5,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.shade200, height: 1)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildInteractiveChecklistSection(),
              const SizedBox(height: 32),
              const Divider(thickness: 2, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 24),
              _buildRecentRecordsSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🚀 인터랙티브 체크리스트 영역 (개별 5종 스위치 + 다이내믹 타이틀 연동)
  // ---------------------------------------------------------
  Widget _buildInteractiveChecklistSection() {
    bool isMobile = MediaQuery.of(context).size.width < 800; // 태블릿/모바일 넉넉하게 분기
    String currentTitle = _getDynamicTitle(_isRegularActive, _isS1Active, _isS2Active, _isS3Active, _isS4Active);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryNavy, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check, color: primaryNavy, size: 28),
              const SizedBox(width: 10),
              // 🌟 현재 켜진 스위치 항목 수를 헤더에도 실시간 노출!
              Expanded(child: Text(currentTitle.replaceAll('건물 정밀 점검표 ', ''), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
            ],
          ),
          const SizedBox(height: 20),

          const Text("🏢 점검 대상 건물 선택", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 8),

          // 자동완성 검색 기능 (유지)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('buildings').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              List<String> buildingNames = snapshot.data!.docs.map((doc) => doc['name'].toString()).toList();
              return Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return buildingNames;
                  return buildingNames.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) { setState(() => _selectedBuilding = selection); FocusScope.of(context).unfocus(); },
                fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                  if (_selectedBuilding == null && textEditingController.text.isNotEmpty) { WidgetsBinding.instance.addPostFrameCallback((_) => textEditingController.clear()); }
                  return TextField(
                    controller: textEditingController, focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: "건물명을 입력하여 검색하세요", prefixIcon: const Icon(Icons.search, color: Color(0xFF475569)),
                      suffixIcon: textEditingController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { textEditingController.clear(); setState(() => _selectedBuilding = null); focusNode.unfocus(); }) : const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
                    ),
                  );
                },
                optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                  final double boxWidth = MediaQuery.of(context).size.width > 850 ? 810 : MediaQuery.of(context).size.width - 40;
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0, borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 250, maxWidth: boxWidth),
                        child: ListView.builder(
                          padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            return InkWell(
                              onTap: () => onSelected(options.elementAt(index)),
                              child: Container(padding: const EdgeInsets.all(16.0), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))), child: Text(options.elementAt(index), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // 👇👇 🌟 [핵심] 분리된 5개의 스위치 영역 레이아웃 👇👇
          const Text("🔘 점검 모드 스위치 (필요한 항목만 ON)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 8),

          // 1. 일반 점검 스위치 (단독)
          _buildToggleSwitch("기본: 일반 정기점검 (45항목)", Icons.fact_check, safetyBlue, _isRegularActive, (v) => setState(() => _isRegularActive = v)),
          const SizedBox(height: 12),

          // 2. 비상/특수 점검 스위치 (PC는 2칸씩, 모바일은 1줄로 세로 정렬)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20), SizedBox(width: 6),
                    Text("비상/계절별 특수점검", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                isMobile
                    ? Column(
                  children: [
                    _buildToggleSwitch("S1. 장마 및 태풍 (집중호우/강풍)", Icons.water_drop, const Color(0xFF0D9488), _isS1Active, (v) => setState(() => _isS1Active = v)), const SizedBox(height: 8),
                    _buildToggleSwitch("S2. 한파 및 동파 (영하권 강추위)", Icons.ac_unit, const Color(0xFF3B82F6), _isS2Active, (v) => setState(() => _isS2Active = v)), const SizedBox(height: 8),
                    _buildToggleSwitch("S3. 폭설 및 결빙 (눈/빙판길)", Icons.severe_cold, const Color(0xFF6366F1), _isS3Active, (v) => setState(() => _isS3Active = v)), const SizedBox(height: 8),
                    _buildToggleSwitch("S4. 강풍 및 건조 (화재 조심)", Icons.local_fire_department, const Color(0xFFEF4444), _isS4Active, (v) => setState(() => _isS4Active = v)),
                  ],
                )
                    : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildToggleSwitch("S1. 장마 및 태풍 (여름)", Icons.water_drop, const Color(0xFF0D9488), _isS1Active, (v) => setState(() => _isS1Active = v))), const SizedBox(width: 8),
                        Expanded(child: _buildToggleSwitch("S2. 한파 및 동파 (겨울)", Icons.ac_unit, const Color(0xFF3B82F6), _isS2Active, (v) => setState(() => _isS2Active = v))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildToggleSwitch("S3. 폭설 및 결빙 (겨울)", Icons.severe_cold, const Color(0xFF6366F1), _isS3Active, (v) => setState(() => _isS3Active = v))), const SizedBox(width: 8),
                        Expanded(child: _buildToggleSwitch("S4. 강풍 및 건조 (봄/가을)", Icons.local_fire_department, const Color(0xFFEF4444), _isS4Active, (v) => setState(() => _isS4Active = v))),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 👆👆 ======================================================= 👆👆

          // 🌟 켜져 있는 스위치에 따라 리스트 출력!
          if (_isRegularActive) ..._inspectionData.map((group) => _buildChecklistGroupInteractive(group)).toList(),
          if (_isS1Active) _buildChecklistGroupInteractive(_specialInspectionData[0]),
          if (_isS2Active) _buildChecklistGroupInteractive(_specialInspectionData[1]),
          if (_isS3Active) _buildChecklistGroupInteractive(_specialInspectionData[2]),
          if (_isS4Active) _buildChecklistGroupInteractive(_specialInspectionData[3]),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_upload, color: Colors.white),
              label: Text(_isSaving ? "서버에 저장 중..." : "점검 결과 서버로 전송", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: _isSaving ? null : _saveInspection,
            ),
          )
        ],
      ),
    );
  }

  // 🌟 [유지] 모바일에서 글씨가 안 깨지는 스마트 스위치 생성기 (FittedBox 적용)
  Widget _buildToggleSwitch(String title, IconData icon, Color color, bool isActive, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!isActive),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isActive ? color : Colors.grey[300]!, width: isActive ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? color : Colors.grey[600], fontSize: 14))
                )
            ),
            SizedBox(
              height: 30, // 🌟 스위치 높이를 살짝 줄여서 레이아웃이 뚱뚱해지지 않게 방어
              child: Switch(
                value: isActive,
                onChanged: onChanged,
                activeColor: color,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistGroupInteractive(Map<String, dynamic> group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: group['color'].withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12))),
            child: Row(
              children: [
                Icon(group['icon'], color: group['color'], size: 20),
                const SizedBox(width: 8),
                Text(group['group'], style: TextStyle(
                    fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: (group['items'] as List).map((item) =>
                _buildInteractiveItem(item)).toList()),
          ),
        ],
      ),
    );
  }

  // 🌟 [고도화] 4개의 버튼(합격/미흡/불량/해당없음)을 배치
  Widget _buildInteractiveItem(Map<String, dynamic> item) {
    String title = item['title'];
    String state = _checkStates[title] ?? '';
    // 미흡이나 불량일 때만 사유 적는 칸 표시
    bool showTextField = state == 'warn' || state == 'fail';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: item['isDaily']
                    ? successGreen.withOpacity(0.1)
                    : warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(item['isDaily'] ? "필수확인" : "꼼꼼확인", style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: item['isDaily'] ? successGreen : warningOrange)),
              ),
              Expanded(child: Text(title, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 4),
          // 🌟 초보자용 상세 가이드 텍스트 (어린이 눈높이)
          Text(item['desc'], style: const TextStyle(
              fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 10),

          // 🌟 버튼 4개 가로 배치 (해당없음 추가)
          Row(
            children: [
              Expanded(
                  child: _buildStateBtn(title, 'pass', "합격", successGreen)),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildStateBtn(title, 'warn', "미흡", warningOrange)),
              const SizedBox(width: 6),
              Expanded(child: _buildStateBtn(title, 'fail', "불량", dangerRed)),
              const SizedBox(width: 6),
              Expanded(child: _buildStateBtn(title, 'na', "해당\n없음", naGrey)),
              // 가로 공간을 위해 줄바꿈
            ],
          ),

          if (showTextField)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                controller: _remarkControllers[title],
                decoration: InputDecoration(
                  hintText: state == 'warn'
                      ? "어떤 부분이 미흡한지, 어떻게 조치할지 적어주세요."
                      : "불량 원인 및 긴급 조치 사항을 꼭 적어주세요.",
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: state == 'warn' ? Colors.orange.shade50 : Colors
                      .red.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🌟 (도우미) 점검 버튼 생성기 (모바일 짤림 완벽 방어)
  Widget _buildStateBtn(String title, String type, String label, Color color) {
    bool isSelected = _checkStates[title] == type;
    return GestureDetector(
      onTap: () => setState(() => _checkStates[title] = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2), // 🌟 좁은 화면 대비 가로 여백 최소화
        decoration: BoxDecoration(color: isSelected ? color : Colors.white,
            border: Border.all(color: isSelected ? color : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: FittedBox( // 👇 🌟 [모바일 최적화] '해당없음' 같이 긴 글씨가 좁은 버튼 밖으로 삐져나가는 것 방지 👇
          fit: BoxFit.scaleDown,
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : Colors.grey.shade600)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 📂 DB 저장 기록 불러오기 (건물명, 점검자, 날짜 띄어쓰기 무시 및 만능 통합 검색)
  // ---------------------------------------------------------
  Widget _buildRecentRecordsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: primaryNavy, size: 24),
              const SizedBox(width: 8),
              Text("작성된 체크리스트 서버 기록", style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy)),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 검색창 힌트 텍스트 변경
          TextField(
            onChanged: (val) =>
                setState(() {
                  _searchRecordQuery = val.trim();
                  _currentRecordPage = 1;
                }),
            decoration: InputDecoration(
              hintText: "건물명, 담당자명, 날짜(예: 3.4, 3월4일, 03/04) 검색",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('inspections')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return const Center(child: Padding(padding: EdgeInsets.all(16),
                    child: Text("저장된 기록이 없습니다.",
                        style: TextStyle(color: Colors.grey))));

              // 🌟 만능 통합 검색 필터링 로직
              var docs = snapshot.data!.docs.where((doc) {
                if (_searchRecordQuery.isEmpty) return true;

                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String query = _searchRecordQuery.toLowerCase();
                String queryNoSpace = query.replaceAll(' ', ''); // 띄어쓰기 무시용

                // 1. 건물명 확인 (띄어쓰기 무시 매칭 포함)
                String bName = (data['buildingName'] ?? '')
                    .toString()
                    .toLowerCase();
                String bNameNoSpace = bName.replaceAll(' ', '');
                bool isNameMatch = bName.contains(query) ||
                    bNameNoSpace.contains(queryNoSpace);

                // 2. 점검자 및 직급 확인
                String iName = (data['inspectorName'] ?? '')
                    .toString()
                    .toLowerCase();
                String iRank = (data['inspectorRank'] ?? '')
                    .toString()
                    .toLowerCase();
                String inspectorFull = "$iName $iRank";
                String inspectorNoSpace = inspectorFull.replaceAll(' ', '');
                bool isInspectorMatch = inspectorFull.contains(query) ||
                    inspectorNoSpace.contains(queryNoSpace);

                // 3. 🌟 날짜 확인 (한국인들이 쓰는 모든 날짜 표기법 생성)
                bool isDateMatch = false;
                Timestamp? ts = data['createdAt'];
                if (ts != null) {
                  DateTime dt = ts.toDate();

                  List<String> dateFormats = [
                    DateFormat('yyyy.MM.dd').format(dt), // 2026.03.04
                    DateFormat('yyyy-MM-dd').format(dt), // 2026-03-04
                    DateFormat('MM.dd').format(dt), // 03.04
                    DateFormat('MM/dd').format(dt), // 03/04
                    DateFormat('MM월 dd일').format(dt), // 03월 04일
                    DateFormat('MM월dd일').format(dt), // 03월04일
                    "${dt.month}.${dt.day}", // 3.4
                    "${dt.month}/${dt.day}", // 3/4
                    "${dt.month}월 ${dt.day}일", // 3월 4일
                    "${dt.month}월${dt.day}일", // 3월4일
                    "${dt.year}년 ${dt.month}월 ${dt.day}일", // 2026년 3월 4일
                  ];

                  // 생성된 수많은 날짜 포맷 중 하나라도 검색어에 걸리면 합격!
                  isDateMatch = dateFormats.any((df) =>
                  df.contains(query) || df.replaceAll(' ', '').contains(
                      queryNoSpace));
                }

                // 건물명, 점검자, 날짜 중 하나라도 일치하면 보여줌
                return isNameMatch || isInspectorMatch || isDateMatch;
              }).toList();

              if (docs.isEmpty) return const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      "검색 결과가 없습니다.", style: TextStyle(color: Colors.grey))));

              int itemsPerPage = 5;
              int totalPages = (docs.length / itemsPerPage).ceil();
              if (_currentRecordPage > totalPages)
                _currentRecordPage = totalPages;
              var pageDocs = docs
                  .skip((_currentRecordPage - 1) * itemsPerPage)
                  .take(itemsPerPage)
                  .toList();

              return Column(
                children: [
                  ...pageDocs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<
                        String,
                        dynamic>;
                    Timestamp? ts = data['createdAt'];
                    String dateStr = ts != null ? DateFormat('yyyy.MM.dd HH:mm')
                        .format(ts.toDate()) : '날짜 없음';

                    Map<String, dynamic> results = data['results'] ?? {};
                    int passCount = 0;
                    int warnCount = 0;
                    int failCount = 0;
                    int naCount = 0;
                    results.forEach((k, v) {
                      if (v['status'] == 'pass')
                        passCount++;
                      else if (v['status'] == 'warn')
                        warnCount++;
                      else if (v['status'] == 'fail')
                        failCount++;
                      else if (v['status'] == 'na') naCount++;
                    });
                    int totalCount = passCount + warnCount + failCount +
                        naCount;

                    return Card(
                      elevation: 0,
                      color: const Color(0xFFF8FAFC),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius
                          .circular(8),
                          side: const BorderSide(color: Color(0xFFE2E8F0))),
                      child: ListTile(
                        onTap: () =>
                            _showRecordDetailDialog(data, dateStr, doc.id),
                        title: Text(data['buildingName'] ?? '미상',
                            style: TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: primaryNavy)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("점검일: $dateStr\n점검자: ${data['inspectorName'] ??
                                '미상'} ${data['inspectorRank'] ?? ''}",
                                style: const TextStyle(fontSize: 12,
                                    color: Colors.grey,
                                    height: 1.4)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text("총 $totalCount건",
                                        style: const TextStyle(fontSize: 11,
                                            color: Color(0xFF475569),
                                            fontWeight: FontWeight.bold))),
                                Container(padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: successGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text("합격 $passCount",
                                        style: TextStyle(fontSize: 11,
                                            color: successGreen,
                                            fontWeight: FontWeight.bold))),
                                if (warnCount > 0) Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: warningOrange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text("미흡 $warnCount",
                                        style: TextStyle(fontSize: 11,
                                            color: warningOrange,
                                            fontWeight: FontWeight.bold))),
                                if (failCount > 0) Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: dangerRed.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text("불량 $failCount",
                                        style: TextStyle(fontSize: 11,
                                            color: dangerRed,
                                            fontWeight: FontWeight.bold))),
                                if (naCount > 0) Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: naGrey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text("해당없음 $naCount",
                                        style: TextStyle(fontSize: 11,
                                            color: naGrey,
                                            fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14,
                            color: Colors.grey),
                      ),
                    );
                  }).toList(),

                  if (totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.chevron_left),
                            onPressed: _currentRecordPage > 1 ? () =>
                                setState(() => _currentRecordPage--) : null),
                        Text("$_currentRecordPage / $totalPages",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.chevron_right),
                            onPressed: _currentRecordPage < totalPages ? () =>
                                setState(() => _currentRecordPage++) : null),
                      ],
                    )
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}