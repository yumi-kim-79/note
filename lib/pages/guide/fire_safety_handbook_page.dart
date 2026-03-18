// [파일 위치: lib/pages/guide/fire_safety_handbook_page.dart]
// [설명: 공동주택 세대 소방시설 자체점검 안내 및 자가진단 디지털 핸드북 (외관 참고사진 추가판)]

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FireSafetyHandbookPage extends StatefulWidget {
  const FireSafetyHandbookPage({super.key});

  @override
  State<FireSafetyHandbookPage> createState() => _FireSafetyHandbookPageState();
}

class _FireSafetyHandbookPageState extends State<FireSafetyHandbookPage> {
  // 🏢 앱 브랜드 컬러
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF1D4ED8);
  final Color dangerRed = const Color(0xFFDC2626);
  final Color successGreen = const Color(0xFF059669);
  final Color bgGrey = const Color(0xFFF1F5F9);

  // 탭 컨트롤
  int _currentTab = 0;

  // 👇 여기서부터 3줄을 추가해 주세요!
  final Map<String, String> _checkStatus = {}; // 각 항목별 상태 (양호/불량/해당없음) 저장
  final Map<String, String> _badReasons = {};  // 불량 항목의 세부 사유 텍스트 저장
  bool _isAgreed = false;                      // 서명 대체 (법적 동의) 체크 여부

  // 🗂️ [내용 유지 & 외관 사진 라벨 추가] 기존 텍스트 100% 유지 + 이미지 경로 세팅 완료
  final List<Map<String, dynamic>> _handbookCategories = [
    {
      "chapter": "제2장",
      "title": "소화설비의 점검방법",
      "icon": Icons.fire_extinguisher,
      "items": [
        {
          "title": "1) 소화기 점검",
          "subtitle": "외관 상태 및 지시압력계, 내용연수 적정 여부",
          "description": "손쉽게 사용할 수 있는 장소(습기, 직사광선을 피하여 보관)에 비치해야 합니다. 용기의 변형, 손상, 부식된 소화기는 전문가(소방시설점검업체 등)의 점검 후 새것으로 교체합니다. 수동식 분말소화기의 내용연수는 '제조일자'로부터 10년입니다.",

          "referenceImageLabel": "수동식 분말소화기 전체 외관",
          "referenceImagePath": "assets/fire_images/2_1_main.png",

          "expertTip": "소화기 손잡이 전단부에 안전핀이 체결되었는지 반드시 확인하세요.",

          "goodImageLabel": "압력계 바늘 '녹색' (양호)",
          "goodImagePath": "assets/fire_images/2_1_yes.png",

          "badImageLabel": "황색(손실) 또는 적색(과압)",
          "badImagePath": "assets/fire_images/2_1_no.png",

          "checkPoints": [
            "손쉽게 사용할 수 있는 장소에 설치되어 있습니까?",
            "용기 변형, 손상, 부식 여부가 없습니까?",
            "안전핀 체결이 정상적으로 되어 있습니까?",
            "지시압력계의 바늘이 정상(녹색) 위치에 있습니까?",
            "수동식 분말소화기 내용연수(10년)가 지나지 않았습니까?"
          ]
        },
        {
          "title": "2) 자동확산소화기 점검",
          "subtitle": "설치상태 및 외형 변형·지시압력계 확인",
          "description": "자동확산소화기는 보일러가 설치된 장소의 천장에 설치되어 화재 발생 시 자동으로 소화약제를 분사합니다.",

          "referenceImageLabel": "자동확산소화기 전체 외관 (보일러실 천장)",
          "referenceImagePath": "assets/fire_images/2_2_main.png",

          "expertTip": "외형이 찌그러지거나 부식되지 않았는지 천장을 올려다보며 육안으로 점검합니다.",

          "goodImageLabel": "설치 양호 및 압력 녹색",
          "goodImagePath": "assets/fire_images/2_2_yes.png",

          "badImageLabel": "변형/부식 및 압력 불량",
          "badImagePath": "assets/fire_images/2_2_no.png",

          "checkPoints": [
            "천장에 정상적으로 설치되어 있습니까?",
            "외형의 변형, 손상, 부식 여부가 없습니까?",
            "지시압력계의 바늘이 정상(녹색) 위치에 있습니까?"
          ]
        },
        {
          "title": "3) 주거용 주방자동소화장치 점검",
          "subtitle": "조작부 전원 및 가스누설탐지기 상태",
          "description": "가스렌지가 설치된 장소의 천장 또는 싱크대 상단 안에 설치되어 화재 발생 시 가루형태 약제가 자동으로 방출되며 가스를 차단합니다.",

          "referenceImageLabel": "주거용 주방자동소화장치 전체 외관 (렌지후드 주변)",
          "referenceImagePath": "assets/fire_images/2_3_main.png",

          "expertTip": "수신부는 가스배관 또는 싱크대 상부 하단에 설치되며, '전원표시등'이 켜져 있어야 정상 작동 상태입니다.",

          "goodImageLabel": "전원등 점등 (양호)",
          "goodImagePath": "assets/fire_images/2_3_yes.png",

          "badImageLabel": "전원 꺼짐 / 탐지기 불량",
          "badImagePath": "assets/fire_images/2_3_no.png",

          "checkPoints": [
            "소화약제용기 지시압력계가 정상(녹색) 위치에 있습니까?",
            "수신부(조작부)의 전원표시등이 정상적으로 점등(녹색)되어 있습니까?"
          ]
        },
        {
          "title": "4) 스프링클러 점검",
          "subtitle": "스프링클러 헤드 변형·손상 육안 점검",
          "description": "화재 발생 시 천장에 설치된 헤드를 통해 물이 분사되어 초기에 화재를 진압하는 중요한 소방시설입니다.",

          "referenceImageLabel": "스프링클러 헤드 외관 (천장)",
          "referenceImagePath": "assets/fire_images/2_4_main.png",

          "expertTip": "물이 분사될 때 중요한 '헤드부분의 설치상태'를 육안으로 꼼꼼히 점검해야 합니다.",

          "goodImageLabel": "헤드 노출 및 상태 양호",
          "goodImagePath": "assets/fire_images/2_4_yes.png",

          "badImageLabel": "인테리어로 인한 헤드 가림/훼손",
          "badImagePath": "assets/fire_images/2_4_no.png",

          "checkPoints": [
            "스프링클러 헤드에 변형이나 손상이 없습니까?",
            "헤드가 천장에서 탈락되거나 페인트, 도배지 등으로 덮여있지 않습니까?",
            "부식된 곳 없이 깨끗한 상태를 유지하고 있습니까?"
          ]
        }
      ]
    },
    {
      "chapter": "제3장",
      "title": "경보설비의 점검방법",
      "icon": Icons.notifications_active,
      "items": [
        {
          "title": "1) 자동화재탐지설비(화재감지기) 점검",
          "subtitle": "감지기 변형·손상·탈락 여부 확인",
          "description": "화재 시 연기나 열을 감지하여 경보를 울려주는 설비입니다. 감지기의 변형, 손상, 인위적인 탈락 등을 육안으로 직접 점검해야 합니다.",

          "referenceImageLabel": "자동화재탐지설비 외관 (거실/방 천장)",
          "referenceImagePath": "assets/fire_images/3_1_main.png",

          "expertTip": "인테리어 공사 시 감지기를 떼어내거나 비닐, 도배 풀 등으로 덮어두면 화재 감지가 불가능해져 대형 참사로 이어집니다.",

          "goodImageLabel": "정상 부착 (양호)",
          "goodImagePath": "assets/fire_images/3_1_yes.png",

          "badImageLabel": "탈락 및 비닐 씌움 (불량)",
          "badImagePath": "assets/fire_images/3_1_no.png",

          "checkPoints": [
            "감지기가 천장에서 탈락되거나 덜렁거리지 않습니까?",
            "감지기 겉면에 변형이나 파손된 곳이 없습니까?",
            "도배지, 테이프, 비닐 등 이물질로 감지기가 덮여 있지 않습니까?"
          ]
        },
        {
          "title": "2) 가스누설경보기 점검",
          "subtitle": "전원표시등 정상 점등 및 외관 확인",
          "description": "주방 가스 누출 시 이를 감지하여 알람을 울려주는 설비입니다. 가스누설경보기의 정상 점등 상태를 육안으로 확인합니다.",

          "referenceImageLabel": "가스누설경보기 외관 (주방 천장 또는 바닥)",
          "referenceImagePath": "assets/fire_images/3_2_main.png",

          "expertTip": "외관의 변형이나 전선 탈락이 없는지 함께 점검하십시오.",

          "goodImageLabel": "녹색 전원등 점등 (양호)",
          "goodImagePath": "assets/fire_images/3_2_yes.png",

          //"badImageLabel": "전원 꺼짐 및 전선 탈락",
          //"badImagePath": "assets/fire_images/3_2_no.png",

          "checkPoints": [
            "가스누설경보기 전원표시등에 불(녹색)이 정상적으로 들어와 있습니까?",
            "기기 외관에 변형, 손상, 벽면 탈락 등의 문제가 없습니까?"
          ]
        }
      ]
    },
    {
      "chapter": "제4장",
      "title": "피난설비의 점검방법",
      "icon": Icons.directions_run,
      "items": [
        {
          "title": "1) 완강기 점검",
          "subtitle": "설치 위치(규격) 및 장애물 피난 지장 여부",
          "description": "공동주택의 경우 3층~10층까지 설치 대상입니다. 부속품 결속 상태, 손상 및 부식 여부, 로프걸이 조임볼트 및 로프상태(끊어짐 유무 등)를 확인합니다.",

          "referenceImageLabel": "완강기 보관함 및 지지대 전체 외관",
          "referenceImagePath": "assets/fire_images/4_1_main.png",

          "expertTip": "창문 규격이 법적 기준을 충족해야 대피가 가능합니다. (가로 50cm 이상, 세로 100cm 이상, 바닥으로부터 높이 120cm 이하 - 발판 설치로 보완 가능)",

          "goodImageLabel": "로프 정상 및 전면 개방 (양호)",
          "goodImagePath": "assets/fire_images/4_1_yes.png",

          "badImageLabel": "장애물 적치 및 로프 훼손",
          "badImagePath": "assets/fire_images/4_1_no.png",

          "checkPoints": [
            "피난기구(완강기) 위치가 적정합니까? (창문 전면 개방 가능 창)",
            "완강기 외형에 변형, 손상, 부식 여부가 없습니까?",
            "로프가 끊어지거나 훼손된 곳은 없습니까?",
            "완강기 설치 위치 주변 및 창문 앞에 피난에 지장을 주는 장애물(에어컨 실외기 등)이 없습니까?"
          ]
        },
        {
          "title": "2) 하향식 피난구용 내림식 사다리 점검",
          "subtitle": "표지판 부착 및 덮개 위 장애물 적치 확인",
          "description": "발코니 바닥에 설치되어 화재 시 덮개를 열고 사다리를 펼쳐 아래층으로 대피할 수 있는 생명 통로입니다.",

          "referenceImageLabel": "하향식 피난구 덮개 전체 외관 (발코니 바닥)",
          "referenceImagePath": "assets/fire_images/4_2_main.png",

          "expertTip": "하향식 피난구 덮개 위에 세탁기, 화분, 수납장 등 무거운 물건을 올려두면 화재 시 대피가 불가능하여 매우 위험합니다.",

          "goodImageLabel": "표지 부착 및 상단 비워둠 (양호)",
          "goodImagePath": "assets/fire_images/4_2_yes.png",

          "badImageLabel": "덮개 위 세탁기/짐 적치 (불량)",
          "badImagePath": "assets/fire_images/4_2_no.png",

          "checkPoints": [
            "피난기구 위치 표지(피난사다리 스티커)가 잘 보이게 부착되어 있습니까?",
            "사용방법(1.덮개 열기 2.사다리 내리기 등) 표지가 유무합니까?",
            "하향식 피난구 덮개 위나 주변에 피난에 지장을 주는 장애물(세탁기, 물건 등)이 없습니까?"
          ]
        }
      ]
    },
    {
      "chapter": "제5장",
      "title": "기타설비의 점검방법",
      "icon": Icons.home_repair_service,
      "items": [
        {
          "title": "1) 대피공간 점검",
          "subtitle": "방화문(갑종) 적정 및 내부 적치물 확인",
          "description": "화재 시 불길과 연기를 피해 구조대가 올 때까지 안전하게 대피할 수 있는 구획된 공간입니다. 방화문이 상시 닫혀 있어야 제 역할을 합니다.",

          "referenceImageLabel": "대피공간 방화문 전체 외관",
          "referenceImagePath": "assets/fire_images/5_1_main.png",

          "expertTip": "대피공간을 개인 창고로 사용하여 자전거, 타이어, 재활용 쓰레기 등을 가득 쌓아두는 행위는 소방관련법 위반입니다.",

          //"goodImageLabel": "방화문 닫힘 및 공간 확보 (양호)",
          //"goodImagePath": "assets/fire_images/5_1_yes.png",

          "badImageLabel": "내부 창고 사용 및 물건 적치",
          "badImagePath": "assets/fire_images/5_1_no.png",

          "checkPoints": [
            "대피공간에 규격에 맞는 방화문(방화구획)이 적정하게 설치되어 있습니까?",
            "방화문이 항상 닫힌 상태를 유지하고 있습니까?",
            "대피공간 내부에 적치물(쌓아놓은 물건)로 인한 피난 장애 여부가 없습니까?"
          ]
        },
        {
          "title": "2) 경량칸막이 점검",
          "subtitle": "표지 부착 여부 및 피난 장애물 확인",
          "description": "이웃집 발코니와 맞닿아 있는 얇은 벽으로, 화재 시 파괴하고 옆집으로 피난할 수 있는 설비입니다.",

          "referenceImageLabel": "경량칸막이 설치 벽면 (발코니)",
          "referenceImagePath": "assets/fire_images/5_2_main.png",

          "expertTip": "벽면을 두드려 경량칸막이 위치를 확인하고, 그 앞에는 '비상탈출구(적재금지)' 표지를 부착해야 합니다.",

          //"goodImageLabel": "공간 확보 및 표지 부착 (양호)",
          //"goodImagePath": "assets/fire_images/5_2_yes.png",

          "badImageLabel": "붙박이장 설치 및 짐 쌓아둠 (불량)",
          "badImagePath": "assets/fire_images/5_2_no.png",

          "checkPoints": [
            "경량칸막이 위치에 '비상탈출(화재 시 이 벽을 파괴하세요!)' 정보를 포함한 표지가 부착되어 있습니까?",
            "칸막이 앞에 세탁기, 수납장 등 적치물(쌓아놓은 물건)로 인한 피난 장애가 발생하지 않았습니까?"
          ]
        }
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text("공동주택 소방시설 자체점검 안내", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _currentTab == 0 ? _buildGuideListView(isMobile) : _buildChecklistReadyView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildTabItem("📖 점검 안내 가이드북", 0),
          _buildTabItem("✅ 세대 자가점검표 (제출용)", 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isActive = _currentTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? safetyBlue : Colors.transparent, width: 3)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isActive ? safetyBlue : Colors.grey.shade500),
          ),
        ),
      ),
    );
  }

  // 🚩 제1장 배너 + 제2~5장 (아코디언 리스트)
  Widget _buildGuideListView(bool isMobile) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 20),
      children: [
        _buildOfficialHeaderBanner(isMobile),
        const SizedBox(height: 24),

        ..._handbookCategories.map((categoryData) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,

                  // 👇 🌟 [수정 핵심] 특정 장이 아니라 '무조건(true)' 다 펼쳐놓도록 변경했습니다!
                  initiallyExpanded: true,

                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryNavy.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(categoryData['icon'], color: primaryNavy, size: 24),
                  ),
                  title: Row(
                    children: [
                      Text("${categoryData['chapter']}.", style: TextStyle(color: safetyBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(categoryData['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100, width: 2))),
                      child: Column(
                        children: ((categoryData['items'] as List?) ?? []).map((item) => _buildDetailCard(item, isMobile)).toList(),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildOfficialHeaderBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: safetyBlue, borderRadius: BorderRadius.circular(4)), child: const Text("제1장", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 10),
                    const Expanded(child: Text("공동주택 소방시설 자체점검 안내", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 16),
                Text("공동주택 소방시설의 안전성 강화를 위한\n세대 전수점검 안내 설명서", style: TextStyle(color: Colors.white, fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, height: 1.4)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.orange, size: 20), SizedBox(width: 8),
                    Text("세대 전수점검 의무 및 법적 근거", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "2022년 12월 1일자로 전부 개정된 「소방시설 설치 및 관리에 관한 법률」 시행규칙[별표3] 제6조에 따라, 공동주택은 2년 이내에 모든 세대에 대하여 소방 전수점검을 완료해야 합니다. (작동점검 50%, 종합점검 30% 이상 실시)",
                  style: TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.6),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("▪ 실시 대상 : 특정소방대상물 중 공동주택 (5층 이상 주택)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), height: 1.5)),
                      Text("▪ 실시 시기 : 2년 이내 (점검 결과는 관리자가 2년간 보관)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), height: 1.5)),
                      Text("▪ 의 무 자 : 관리자(입주자대표회의, 관리소장) 및 입주민", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), height: 1.5)),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // 🚩 1. 디테일 카드 (수정됨: 사진이 1개만 있을 때 자동 맞춤 처리 추가)
  Widget _buildDetailCard(Map<String, dynamic> data, bool isMobile) {
    // 🌟 [핵심 로직] 양호, 불량 데이터가 실제로 존재하는지 확인해서 상자에 담습니다.
    List<Widget> statusImages = [];
    if (data['goodImageLabel'] != null) {
      statusImages.add(_buildImagePlaceholder(data['goodImageLabel'], true, data['goodImagePath']));
    }
    if (data['badImageLabel'] != null) {
      statusImages.add(_buildImagePlaceholder(data['badImageLabel'], false, data['badImagePath']));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
          const SizedBox(height: 6),
          Text(data['subtitle'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: safetyBlue)),
          const SizedBox(height: 12),
          Text(data['description'], style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.6)),
          const SizedBox(height: 24),

          // 전체 외관 참고 사진 영역
          if (data['referenceImageLabel'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.search, color: Colors.blueGrey.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text("💡 이 설비는 이렇게 생겼습니다 (위치 및 외관)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey.shade700)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildReferenceImagePlaceholder(data['referenceImageLabel'], data['referenceImagePath']),
                const SizedBox(height: 24),
              ],
            ),

          // 🌟 [수정됨] 양호 / 불량 비교 사진 자동 배치 처리
          if (statusImages.isNotEmpty) ...[
            if (statusImages.length == 1)
              statusImages[0] // 사진이 1개만 있으면 넓게 하나만 띄움!
            else
              isMobile
                  ? Column(
                children: [
                  statusImages[0],
                  const SizedBox(height: 16),
                  statusImages[1],
                ],
              )
                  : Row(
                children: [
                  Expanded(child: statusImages[0]),
                  const SizedBox(width: 16),
                  Expanded(child: statusImages[1]),
                ],
              ),
            const SizedBox(height: 24),
          ],

          // 점검 세부 가이드
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("점검 세부 가이드", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text(data['expertTip'], style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 별지 36호 체크리스트
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.orange, size: 20), SizedBox(width: 8),
                    Text("별지 제36호 서식 점검 항목", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                ...((data['checkPoints'] as List?) ?? []).map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54)),
                      Expanded(child: Text(point, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4))),
                    ],
                  ),
                )).toList(),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 🚩 2. 전체 외관 사진 틀 (수정됨: BoxFit.contain 적용)
  Widget _buildReferenceImagePlaceholder(String label, String? imagePath) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // 사진 외 영역 배경색
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          // 이미지 경로가 있으면 사진을 contain으로 띄움
          image: imagePath != null && imagePath.isNotEmpty
              ? DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.contain, // 🌟 [수정 핵심] 사진 비율 유지하며 액자 안에 쏙!
          )
              : null,
        ),
        // 이미지가 없을 때만 기존의 안내 글씨를 보여줌
        child: imagePath == null || imagePath.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 36, color: Colors.blueGrey.shade200),
              const SizedBox(height: 8),
              Text("[$label]\n전체 외관 사진 교체 공간", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600, fontWeight: FontWeight.bold)),
            ],
          ),
        )
            : null,
      ),
    );
  }

  // 🚩 3. 양호/불량 비교 사진 틀 (수정됨: 원본 사진이 짤리지 않도록 BoxFit.contain 적용)
  Widget _buildImagePlaceholder(String label, bool isGood, String? imagePath) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // 사진이 칸보다 작을 때 남는 여백에 깔리는 배경색 (양호는 옅은 녹색, 불량은 옅은 붉은색)
              color: isGood ? successGreen.withOpacity(0.05) : dangerRed.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isGood ? successGreen.withOpacity(0.3) : dangerRed.withOpacity(0.3), width: 2),
              // 👇 이 부분을 cover 에서 contain 으로 변경했습니다!
              image: imagePath != null && imagePath.isNotEmpty
                  ? DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.contain, // 🌟 사진이 절대 짤리지 않고 원본 비율 그대로 액자 안에 쏙 들어갑니다!
              )
                  : null,
            ),
            // 이미지가 없을 때만 기존의 아이콘을 보여줌
            child: imagePath == null || imagePath.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isGood ? Icons.thumb_up_alt : Icons.warning_amber_rounded, size: 40, color: isGood ? successGreen : dangerRed),
                  const SizedBox(height: 8),
                  Text("[$label]\n사진 공간", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                ],
              ),
            )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: isGood ? successGreen : dangerRed, borderRadius: BorderRadius.circular(4)),
          child: Text(isGood ? "양호" : "불량", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  // 🚩 [수정됨] 세대 자가점검표 (A안: 원스크롤 스텝 및 입력폼)
  Widget _buildChecklistReadyView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // 상단 안내
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📄 [별지 제36호 서식] 세대 소방시설 자가점검표", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              SizedBox(height: 8),
              Text("우리 집 소방시설의 상태를 확인하고 체크해 주십시오. '불량'인 경우 하단에 사유를 간략히 적어주시면 관리사무소에서 조치에 참고합니다.", style: TextStyle(color: Color(0xFF475569), height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 🌟 항목별 체크리스트 자동 생성 (가이드북 데이터 연동)
        ..._handbookCategories.expand((category) {
          return (category['items'] as List).map((item) => _buildChecklistItemCard(item['title']));
        }),

        const SizedBox(height: 24),

        // 🌟 서명 대체 (법적 동의) 체크박스
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Checkbox(
                value: _isAgreed,
                activeColor: safetyBlue,
                onChanged: (val) => setState(() => _isAgreed = val ?? false),
              ),
              const Expanded(
                child: Text("본 세대는 소방시설법 시행규칙에 따라 위 점검을 직접 실시하였으며, 내용이 틀림없음을 확인합니다.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 🌟 최종 제출 및 PDF 출력 버튼
        ElevatedButton.icon(
          onPressed: _generateAndPrintPdf,
          icon: const Icon(Icons.print, color: Colors.white),
          label: const Text("점검 완료 및 PDF 서식 출력", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isAgreed ? safetyBlue : Colors.grey, // 동의해야 파란색 활성화
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // 🚩 개별 점검 항목 카드 UI (3지 선다 및 불량 사유 입력창)
  Widget _buildChecklistItemCard(String title) {
    String currentStatus = _checkStatus[title] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          // 3지 선다 버튼
          Row(
            children: [
              _buildStatusOption(title, "양호", currentStatus, successGreen),
              const SizedBox(width: 8),
              _buildStatusOption(title, "불량", currentStatus, dangerRed),
              const SizedBox(width: 8),
              _buildStatusOption(title, "해당없음", currentStatus, Colors.grey.shade600),
            ],
          ),
          // 🌟 '불량' 선택 시 부드럽게 나타나는 텍스트 입력창
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: currentStatus == "불량"
                ? Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                onChanged: (val) => _badReasons[title] = val,
                decoration: InputDecoration(
                  hintText: "어떤 부분이 불량인지 간단히 적어주세요.",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // 🚩 3지 선다 버튼 생성기
  Widget _buildStatusOption(String title, String statusLabel, String currentStatus, Color activeColor) {
    bool isSelected = currentStatus == statusLabel;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _checkStatus[title] = statusLabel;
            if (statusLabel != "불량") _badReasons.remove(title); // 불량이 아니면 사유 초기화
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.1) : Colors.white,
            border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(statusLabel, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : Colors.grey.shade600)),
        ),
      ),
    );
  }

  // 🖨️ [핵심] PDF 생성 및 출력 (별지 제36호 서식 구현)
  Future<void> _generateAndPrintPdf() async {
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("하단의 '점검 내용이 틀림없음을 확인합니다' 항목에 체크해 주세요."), backgroundColor: Colors.redAccent));
      return;
    }

    // 한글 폰트 로드 (printing 패키지 제공 기본 한글 폰트)
    final font = await PdfGoogleFonts.nanumGothicRegular();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 20),
              pw.Text('[별지 제36호 서식]', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 10),
              pw.Text('소방시설 등 외관점검표(세대점검용)', style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 30),

              // 🌟 PDF 표 그리기 (관공서 양식)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3), // 점검 항목명
                  1: const pw.FlexColumnWidth(1), // 양호
                  2: const pw.FlexColumnWidth(1), // 불량
                  3: const pw.FlexColumnWidth(1.5), // 해당없음
                  4: const pw.FlexColumnWidth(3.5), // 불량 내용
                },
                children: [
                  // 표 제목(헤더) 행
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text('점검 항목', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text('양호', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text('불량', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text('해당없음', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text('불량 내용 (조치사항)', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)))),
                    ],
                  ),
                  // 사용자가 체크한 데이터 행 반복
                  ..._handbookCategories.expand((category) {
                    return (category['items'] as List).map((item) {
                      String title = item['title'];
                      String status = _checkStatus[title] ?? "";
                      String reason = _badReasons[title] ?? "";

                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text(status == "양호" ? "V" : "", style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)))),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text(status == "불량" ? "V" : "", style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, color: PdfColors.red)))),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text(status == "해당없음" ? "V" : "", style: pw.TextStyle(font: font)))),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(reason, style: pw.TextStyle(font: font, fontSize: 10))),
                        ],
                      );
                    });
                  }),
                ],
              ),
              pw.SizedBox(height: 40),

              // 하단 서명란
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('점검일자 : 20   년   월   일', style: pw.TextStyle(font: font, fontSize: 12)),
                      pw.SizedBox(height: 10),
                      pw.Text('점검자(세대주) :                   (서명)', style: pw.TextStyle(font: font, fontSize: 12)),
                    ],
                  )
              ),
            ],
          );
        },
      ),
    );

    // 🌟 기기 기본 프린트/PDF 저장 창 띄우기
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '세대소방점검표_별지36호',
    );
  }
}