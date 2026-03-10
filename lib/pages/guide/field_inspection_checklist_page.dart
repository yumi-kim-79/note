// [파일 위치: lib/pages/guide/field_inspection_checklist_page.dart]
// [설명: 현장 업무 가이드 - 표준 건물시설 정기점검표 (이론 및 가이드라인 전용)]

import 'package:flutter/material.dart';

class FieldInspectionChecklistPage extends StatelessWidget {
  const FieldInspectionChecklistPage({super.key});

  // 🏢 대기업 표준 컬러
  final Color primaryNavy = const Color(0xFF1E293B);
  final Color safetyBlue = const Color(0xFF2563EB);
  final Color dangerRed = const Color(0xFFDC2626);
  final Color warningOrange = const Color(0xFFF59E0B);
  final Color successGreen = const Color(0xFF10B981);
  final Color residentTagColor = const Color(0xFF10B981); // 상주/매일
  final Color patrolTagColor = const Color(0xFFF59E0B);   // 순회/주기

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "건물시설 정기점검표 (SOP 가이드)",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        elevation: 0.5,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildDocumentHeader(),
              const SizedBox(height: 24),
              _buildStep1_Safety(), // 1. 안전 및 준비
              const SizedBox(height: 16),
              _buildDecisionTree(), // 2. 점검 동선 프로세스
              const SizedBox(height: 16),
              _buildStep2_Checklists(), // 3. 구역별 정밀 점검 (이론)
              const SizedBox(height: 16),
              _buildStep3_ExpertTips(), // 4. FM 전문가 팁
              const SizedBox(height: 16),
              _buildStep4_AdminAction(), // 5. 행정 조치 가이드
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 📄 문서 헤더
  Widget _buildDocumentHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text("건물·시설물 통합 정기점검표", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text("• 점검 대상: 공용부 전체 및 기계/전기 설비\n• 점검 원칙: 육안 점검, 오감 점검(소음, 진동), 타임스탬프 채증", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  // 🛡️ 1. 점검 전 필수 안전 확인
  Widget _buildStep1_Safety() {
    return _buildSectionCard(
      title: "1. 점검 전 필수 안전 확인 (Safety First)",
      subtitle: "현장 투입 전 담당자의 준비 상태를 최종 점검합니다.",
      accentColor: safetyBlue,
      icon: Icons.health_and_safety,
      content: Column(
        children: [
          _buildPledgeItem("[복장] 회사 근무복 및 안전화 착용 상태가 양호한가?"),
          _buildPledgeItem("[장비] 고성능 랜턴, 비상키, 검전기, 스마트폰 배터리를 확보했는가?"),
          _buildPledgeItem("[숙지] 해당 단지의 최근 주요 민원 및 사고 이력을 파악했는가?"),
        ],
      ),
    );
  }

  // 🔄 2. 시설 점검 운영 프로세스
  Widget _buildDecisionTree() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFCBD5E1))),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route, color: primaryNavy),
                const SizedBox(width: 8),
                Text("2. 시설 점검 동선 프로세스 (SOP)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
              ],
            ),
            const SizedBox(height: 24),
            _buildFlowStep("현장 단지 도착 👉 안전 장구 및 민원 이력 숙지", const Color(0xFFF1F5F9)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("외곽 및 분리수거장", "진입로/미화/주차/배수로"),
                _buildFlowBranch("1층 로비 및 게시판", "자동문/공문/우편함"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("최상층 이동 후 하향 순회 (Top-Down)", const Color(0xFFE2E8F0)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFlowBranch("복도/계단/소방 시설", "적재물/창문/유도등/PD함"),
                _buildFlowBranch("전유부 민원 세대 방문", "누수 등 세대 민원 처리"),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, color: Color(0xFF94A3B8), size: 20)),

            _buildFlowStep("지하 기계/전기실 정밀 점검 👉 결과 전송 및 보고", const Color(0xFFF1F5F9)),
          ],
        ),
      ),
    );
  }

  // 📋 3. 구역별 정밀 점검 항목 (이론용 SOP + 🚨특수상황 포함)
  Widget _buildStep2_Checklists() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryNavy, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: primaryNavy, size: 28),
              const SizedBox(width: 10),
              Text("3. 구역별 정밀 점검 항목 (기본 45문항 + 특수 16문항)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
            ],
          ),
          const SizedBox(height: 8),
          const Text("※ 실제 현장 점검 시에는 '실전 체크리스트' 메뉴를 이용해 결과를 서버로 전송하세요.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),

          // 🌟 그룹 A. 현관 및 분리수거장 (8항목)
          _buildChecklistGroup(
            title: "A. 현관 및 분리수거장 (미화 및 첫인상)",
            icon: Icons.domain,
            color: const Color(0xFF3B82F6),
            items: [
              _buildCheckListItem("건물 앞 진입로 쓰레기 청소", "휴지/담배꽁초 등 바닥 오염물 제거", true),
              _buildCheckListItem("분리수거장 정리정돈 상태", "종이상자 압축 및 플라스틱 용기 넘침 방지", true),
              _buildCheckListItem("종량제 봉투 및 마대자루 재고", "청소 및 폐기물 처리를 위한 잔여 수량 파악", true),
              _buildCheckListItem("공동현관 자동문 유리 손자국", "유리 세정제를 활용한 끈적임 및 얼룩 세척", true),
              _buildCheckListItem("로비폰(비밀번호 기계) 먼지 제거", "화면 먼지 제거 및 버튼 터치 작동 확인", true),
              _buildCheckListItem("우편함 및 택배함 찌라시 제거", "무단 부착 스티커 및 불법 전단지 즉시 폐기", true),
              _buildCheckListItem("1층 바닥 타일 깨짐 및 파손", "보행자 걸림을 유발하는 타일 들뜸/크랙 파악", false),
              _buildCheckListItem("건물 입구 미끄럼 방지 발매트", "우천 대비 발매트 훼손 여부 및 흙먼지 털기", false),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 그룹 B. 승강기 및 주차장 (8항목)
          _buildChecklistGroup(
            title: "B. 승강기 및 주차장 (이용자 편의/안전)",
            icon: Icons.elevator,
            color: const Color(0xFF8B5CF6),
            items: [
              _buildCheckListItem("엘리베이터 거울 및 벽면 얼룩", "내부 거울 오염 및 벽면 긁힘/낙서 훼손 확인", true),
              _buildCheckListItem("엘리베이터 바닥 흙/먼지 청소", "외부 유입 모래 및 흙 대걸레 상시 세척", true),
              _buildCheckListItem("엘리베이터 문 틈새(레일) 이물질", "하단 레일 홈에 낀 돌멩이 등 붓으로 긁어내기", true),
              _buildCheckListItem("엘리베이터 천장 전등 깜빡임", "내부 조명 깜빡임 및 점등 불량 전구 확인", false),
              _buildCheckListItem("주차장 주차선 및 화살표 표시", "바닥 도색 지워짐 및 방향 표시 가시성 확인", false),
              _buildCheckListItem("주차장 바닥 턱(스토퍼) 덜렁거림", "차량 바퀴 닿는 고무 턱 나사 풀림/파손 건들기", false),
              _buildCheckListItem("주차장 코너 주황색 볼록거울", "반사경 각도 틀어짐 및 표면 먼지 오염 확인", false),
              _buildCheckListItem("기계식 주차장 문 앞 바닥 청결", "미끄럼 유발 기름때 및 주변 쓰레기 청소", false),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 그룹 C. 계단 및 복도 공용부 (8항목)
          _buildChecklistGroup(
            title: "C. 계단 및 복도 공용부 (보행 환경/소음)",
            icon: Icons.stairs,
            color: const Color(0xFF10B981),
            items: [
              _buildCheckListItem("복도 바닥 껌자국 및 커피 얼룩", "층별 순회하며 바닥 고착 오염물 및 끈적임 닦기", true),
              _buildCheckListItem("계단 쇠 손잡이(난간) 끈적임 닦기", "보행자 접촉면 먼지 및 이물질 상시 걸레질", true),
              _buildCheckListItem("계단 창문 틀(레일) 벌레 사체 청소", "창틀 홈에 쌓인 파리/모기 사체 및 거미줄 털기", true),
              _buildCheckListItem("복도 천장 센서등 켜짐 테스트", "보행자 인식 후 즉각(1초 내) 점등 여부 확인", false),
              _buildCheckListItem("비상구 안내 표지판 초록 불빛", "피난구 유도등 24시간 상시 점등 상태 점검", false),
              _buildCheckListItem("복도 앞 자전거/택배 상자 길 막음", "소방법 위반 적재물 방치 및 피난 방해물 확인", false),
              _buildCheckListItem("계단 무거운 쇠문(방화문) 닫히는 속도", "도어클로저 텐션 이상에 의한 급격한 닫힘 확인", false),
              _buildCheckListItem("각 층 벽면 페인트 벗겨짐 및 낙서", "복도/계단 벽면 도장 박리 및 훼손 여부 확인", false),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 그룹 D. 기계실 외관 및 창고 (8항목)
          _buildChecklistGroup(
            title: "D. 기계실 외관 및 창고 (정리정돈/기본 점검)",
            icon: Icons.precision_manufacturing,
            color: const Color(0xFFF59E0B),
            items: [
              _buildCheckListItem("지하 기계실 철문 튼튼한 자물쇠 잠금", "위험 구역 외부인 무단 출입 방지용 시건장치 확인", true),
              _buildCheckListItem("기계실 환풍기 부드럽게 돌아가는 소리", "가동 시 마찰음/쇳소리 등 이상 소음 밖에서 청취", true),
              _buildCheckListItem("청소 창고 내부 대걸레 및 빗자루 정리", "청소용구 악취 방지 건조 및 제자리 정돈 상태", true),
              _buildCheckListItem("창고 안 락스/세제통 뚜껑 꽉 닫힘", "화학약품 뚜껑 밀폐 및 휘발/독성 냄새 누출 방어", true),
              _buildCheckListItem("예비 형광등 및 화장지 소모품 정리", "수선/교체용 자재 품목별 선반 정돈 상태 확인", false),
              _buildCheckListItem("정화조실(화장실 물 모이는 곳) 환기 냄새", "배기 불량에 의한 외부 악취/가스 유출 여부 냄새 맡기", false),
              _buildCheckListItem("지하실 천장 네모난 판(마감재) 떨어짐", "텍스/SMC 등 천장 마감재 처짐 및 바닥 탈락 확인", false),
              _buildCheckListItem("지하실 바닥 구석 거미줄 및 곰팡이", "습기 취약 구역 곰팡이 번식 및 결로 현상 청소", false),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 그룹 E. 옥상 및 건물 외부 시설 (8항목)
          _buildChecklistGroup(
            title: "E. 옥상 및 건물 외부 시설 (야외 환경)",
            icon: Icons.roofing,
            color: const Color(0xFFEC4899), // 핑크색 계열
            items: [
              _buildCheckListItem("옥상 바닥 빗물 빠지는 구멍 막힘 치우기", "배수구(루프드레인) 주변 낙엽/비닐 퇴적물 수거", true),
              _buildCheckListItem("옥상 바닥 초록색/회색 페인트 까짐", "우레탄 방수층 들뜸 및 가뭄 논바닥 같은 갈라짐 밟아보기", false),
              _buildCheckListItem("옥상 가장자리 벽(난간) 흔들림 테스트", "옥상 파라펫 및 쇠창살 앵커 고정 튼튼함 흔들어 확인", false),
              _buildCheckListItem("옥상 은색 환풍기(벤틸레이터) 돌아가는지", "무동력 환풍기 회전 불량 멈춤 및 끼익거리는 소음 점검", false),
              _buildCheckListItem("옥상 구석 담배꽁초 및 빈 캔 버려진 것", "흡연 등 무단 취식에 의한 화재 위험물/쓰레기 수거", false),
              _buildCheckListItem("건물 밖 자전거 보관소 지붕 먼지 털기", "외부 보관소 캐노피 오염 털기 및 주변 흙먼지 정돈", false),
              _buildCheckListItem("건물 밖 커다란 에어컨 실외기 주변 박스 치우기", "화재 원인이 되는 실외기 열풍 배출구 주변 적치물 제거", false),
              _buildCheckListItem("건물 앞 작은 정원(화단) 잡초 뽑기", "조경수 나뭇가지 꺾임 및 화단 내 무성한 잡초 정리", false),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 그룹 F. 지하실 침수 특별 관리 (5항목)
          _buildChecklistGroup(
            title: "F. 지하실 침수 특별 관리 (누수 예방)",
            icon: Icons.water_damage,
            color: const Color(0xFF0EA5E9), // 라이트 블루 계열
            items: [
              _buildCheckListItem("지하주차장 입구 빗물 막이판(차수판) 상태", "우천 대비 철판 찌그러짐 및 모래주머니 훼손 여부 확인", false),
              _buildCheckListItem("물 모이는 웅덩이(집수정) 안쪽 쓰레기 건져내기", "수위 센서 간섭 유발 부유물(비닐 등) 긴 막대로 제거", false),
              _buildCheckListItem("물 퍼내는 펌프 상자(제어반) '자동' 불빛 확인", "배수펌프 컨트롤 판넬 스위치 '자동(Auto)' 모드 유지 확인", false),
              _buildCheckListItem("지하실 천장 파이프 물방울 맺힘(누수) 확인", "배관 조인트 결로 및 주차 차량 석회물 낙수 피해 예방", false),
              _buildCheckListItem("지하실 밖 환기구(드라이에어리어) 빗물 고임", "1층 외부 창문 공간 내 낙엽 퇴적 및 수영장 우수 고임 점검", false),
            ],
          ),

          // 👇👇 🌟 [핵심 고도화] 비상 및 계절별 특수점검 이론 가이드 추가 👇👇
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: dangerRed, size: 24),
                const SizedBox(width: 10),
                Expanded(child: Text("🚨 비상/계절별 특수 점검 SOP (상황 발생 시 선택적 수행)", style: TextStyle(fontWeight: FontWeight.bold, color: dangerRed, fontSize: 16))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 🌟 특수 그룹 S1
          _buildChecklistGroup(
            title: "S1. 장마 및 태풍 (여름철 집중호우/강풍)",
            icon: Icons.water_drop,
            color: const Color(0xFF0D9488),
            items: [
              _buildCheckListItem("옥상 빗물 빠지는 구멍(루프드레인) 청소", "배수구 쓰레기/비닐/낙엽 등 이물질 완전 제거 (옥상 범람 방지)", false),
              _buildCheckListItem("복도 및 계단 창문 꽉 닫고 잠금쇠 채우기", "전 층 공용부 창문 밀폐 및 크리센트(잠금장치) 체결 확인", false),
              _buildCheckListItem("건물 밖 날아갈 수 있는 물건 묶기", "입간판, 분리수거통 등 비산출 위험물 벽면 밀착 및 끈 결박", false),
              _buildCheckListItem("지하주차장 입구 차수판/모래주머니 전진 배치", "집중호우 대비 지하 유입 방지용 모래주머니 및 차수판 전진 비치", false),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 특수 그룹 S2
          _buildChecklistGroup(
            title: "S2. 한파 및 동파 (겨울철 영하권 강추위)",
            icon: Icons.ac_unit,
            color: const Color(0xFF3B82F6),
            items: [
              _buildCheckListItem("복도 및 계단 창문 틈새 막기 (찬바람 유입 차단)", "공용부 창문 완전 밀폐를 통한 내부 배관 동파 원천 차단", false),
              _buildCheckListItem("1층 공동현관 자동문 끝까지 닫히는지 확인", "자동문 구동부 점검 및 개방 방치를 통한 1층 계량기 동파 예방", false),
              _buildCheckListItem("복도 수도 계량기함 안쪽 보온재(헌 옷/뽁뽁이) 채우기", "계량기함 내부 보온재(헌 옷, 뽁뽁이 등) 밀실 충진 상태 점검", false),
              _buildCheckListItem("지하 기계실 전열기(미니 히터) 켜기 및 화재 주의", "펌프실 동파 방지용 히터 가동 및 주변 인화성 물질(종이 등) 수거", false),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 특수 그룹 S3
          _buildChecklistGroup(
            title: "S3. 폭설 및 결빙 (겨울철 눈/빙판길)",
            icon: Icons.severe_cold,
            color: const Color(0xFF6366F1),
            items: [
              _buildCheckListItem("눈 치우는 넉가래(눈삽)와 빗자루 1층에 꺼내두기", "신속한 제설 초기 대응을 위한 제설 장비 1층 전진 비치", false),
              _buildCheckListItem("건물 입구 염화칼슘(눈 녹이는 약) 제설함 확인", "염화칼슘 잔여량 파악 및 보관 중 경화(돌처럼 굳음) 현상 점검", false),
              _buildCheckListItem("1층 출입구 대리석 바닥 미끄럼 방지 매트 깔기", "눈/물기로 인한 대리석 바닥 낙상 사고 예방용 대형 발매트 전개", false),
              _buildCheckListItem("외부 주차장 진입로(언덕길) 얼음 깨기", "경사로 구간 결빙 조기 제거 및 차량 미끄럼/충돌 사고 방지 조치", false),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 특수 그룹 S4
          _buildChecklistGroup(
            title: "S4. 강풍 및 건조 (봄/가을철 화재 조심)",
            icon: Icons.local_fire_department,
            color: const Color(0xFFEF4444),
            items: [
              _buildCheckListItem("건물 주변 화단 바짝 마른 낙엽 싹 치우기", "담배꽁초 불씨 착화 위험이 높은 건조한 낙엽 및 쓰레기 선제 수거", false),
              _buildCheckListItem("층별 빨간 소화기 위치 및 동그란 안전핀 확인", "소화기 은폐 여부 점검 및 안전핀 정상 체결/부식 상태 확인", false),
              _buildCheckListItem("옥상 안테나 및 낡은 구조물 흔들림 검사", "강풍 시 추락/비산 위험이 있는 노후 구조물 앵커 고정 상태 점검", false),
              _buildCheckListItem("옥상 무거운 쇠문(방화문) 닫힘 상태 유지", "돌풍에 의한 방화문 파손 및 인명 피해 예방을 위한 상시 폐쇄 유지", false),
            ],
          ),
        ],
      ),
    );
  }

  // 💡 4. FM 전문가 팁
  Widget _buildStep3_ExpertTips() {
    return _buildSectionCard(
      title: "4. FM 전문가 필수 점검 (사고 예방 핵심)",
      subtitle: "대기업 관리 현장에서 대형 사고와 배상 책임을 막는 필수 3대 항목입니다.",
      accentColor: dangerRed,
      icon: Icons.model_training,
      content: Column(
        children: [
          _buildHighlightAction(Icons.door_front_door, "방화문 도어스토퍼(말굽) 개방 절대 금지", "환기를 위해 방화문을 고정해두면 화재 시 연기 확산으로 대참사가 발생하며 형사 처벌 대상입니다. 무조건 닫고 안내문을 부착하십시오.", isDanger: true),
          _buildHighlightAction(Icons.water_damage, "옥상 누수 전조: 최상층 천장 '백화 현상'", "단순 바닥 균열뿐만 아니라, 최상층 복도 천장에 '하얀 가루(백화)'가 맺혔는지 확인하십시오. 철근 부식 및 본격적인 누수 직전의 강력한 신호입니다.", isDanger: false),
          _buildHighlightAction(Icons.earbuds, "PD(Pipe Duct)실 내부 소음 확인", "복도 벽면의 배관 통로(PD) 문에 귀를 대보십시오. 평소보다 물 흐르는 소리가 크거나 폭포수 같은 낙수 소리가 들리면 내부 배관 파열입니다.", isDanger: false),
        ],
      ),
    );
  }

  // 🛠️ 5. 행정 조치 가이드
  Widget _buildStep4_AdminAction() {
    return _buildSectionCard(
      title: "5. 점검 후 행정 조치 및 보고 가이드",
      subtitle: "현장 발견 후 처리가 완벽해야 진정한 FM입니다.",
      accentColor: primaryNavy,
      icon: Icons.assignment_turned_in,
      content: Column(
        children: [
          _buildActionItem(Icons.build_circle, "경미 사항 (즉시 조치)", "전등 교체, 광고물 제거, 간단한 나사 조임 등은 현장에서 즉시 조치 후 완료 사진을 채증합니다."),
          _buildActionItem(Icons.report_problem, "중대 사항 (수리 의뢰)", "펌프 고장, 대형 누수, 외벽 크랙 등은 즉시 사진을 찍어 본사 현장 부장에게 보고하고, 관리단에 견적 및 수리 의뢰 공문을 발송합니다."),
          _buildActionItem(Icons.send_to_mobile, "민원 피드백 (종결)", "순회 중 해결한 입주민 접수 민원은 반드시 '현장관리 앱'에서 [완료] 처리하고, 입주민에게 처리 완료 문자를 발송하여 신뢰도를 높입니다."),
        ],
      ),
    );
  }

  // --- UI 헬퍼 위젯들 ---

  Widget _buildChecklistGroup({required String title, required IconData icon, required Color color, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)), border: Border(bottom: BorderSide(color: color.withOpacity(0.1)))),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckListItem(String title, String desc, bool isDaily) {
    Color tagColor = isDaily ? residentTagColor : patrolTagColor;
    String tagText = isDaily ? "상주/매일" : "순회/주기";

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_box_outline_blank, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: tagColor.withOpacity(0.3))),
                      child: Text(tagText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor)),
                    ),
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required Color accentColor, required IconData icon, required Widget content}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, decoration: BoxDecoration(color: accentColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
            Expanded(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: accentColor, size: 26), const SizedBox(width: 10), Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy)))]), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))), const Divider(height: 30, thickness: 1, color: Color(0xFFF1F5F9)), content]))),
          ],
        ),
      ),
    );
  }

  Widget _buildPledgeItem(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_box, color: primaryNavy, size: 22), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.4)))],),);
  }

  Widget _buildActionItem(IconData icon, String title, String desc) {
    return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: const Color(0xFF475569))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))), const SizedBox(height: 4), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))]));
  }

  Widget _buildHighlightAction(IconData icon, String title, String desc, {bool isDanger = false}) {
    Color bgColor = isDanger ? Colors.red.shade50 : const Color(0xFFEFF6FF); Color iconColor = isDanger ? Colors.red.shade700 : safetyBlue;
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDanger ? Colors.red.shade100 : const Color(0xFFBFDBFE))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: iconColor, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 15)), const SizedBox(height: 6), Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5))]))]));
  }

  Widget _buildFlowStep(String text, Color bgColor) { return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), textAlign: TextAlign.center)); }
  Widget _buildFlowBranch(String condition, String result) { return Container(width: 240, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))), child: Column(children: [Text(condition, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))), const SizedBox(height: 8), Text(result, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A), height: 1.4), textAlign: TextAlign.center)])); }
}