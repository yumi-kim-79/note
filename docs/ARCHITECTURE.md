# ARCHITECTURE.md — 노트 기술 스택 & 구조

> 마지막 업데이트: 2026-03-25

---

## 🛠️ 기술 스택

| 영역 | 기술 |
|------|------|
| 프론트엔드 | Flutter Web (Dart) |
| 백엔드 | Firebase (Auth, Firestore, Hosting, Functions) |
| 지도 | 네이버 지도 (app_naver_map_holder) |
| 주소 검색 | 다음 우편번호 (daum_postcode_web) |
| IDE | Android Studio |
| 버전 관리 | GitHub (yumi-kim-79/note) |

---

## 📦 Firebase 정보

| 항목 | 내용 |
|------|------|
| 배포 URL | xn--bl3b03itzc92b.com |
| 프로젝트 ID | firebase_options.dart 확인 필요 |

---

## 🗂️ 파일 구조

```
lib/
├── main.dart                            ← 단일 진입점
├── firebase_options.dart
├── models/
│   ├── building_loc.dart                ← 건물 위치 모델
│   └── building_model.dart              ← 건물 모델
├── pages/
│   ├── login_page.dart
│   ├── admin_page.dart
│   ├── building_info_page.dart
│   ├── settings/
│   │   └── settings_page.dart
│   ├── dashboard/                       ← 메인 대시보드
│   │   ├── dashboard_page.dart
│   │   └── widgets/
│   │       ├── custom_calendar.dart
│   │       ├── notice_board.dart
│   │       └── recent_sales.dart
│   ├── chat/
│   │   └── chat_page.dart
│   ├── field/                           ← 현장 관리
│   │   ├── field_report_page.dart
│   │   ├── field_route_page.dart
│   │   ├── field_schedule_page.dart
│   │   ├── web_ui_real.dart
│   │   └── web_ui_stub.dart
│   ├── field_info/
│   │   ├── field_contact_page.dart
│   │   └── field_info_page.dart
│   ├── guide/                           ← 현장 가이드
│   │   ├── field_guide_main_page.dart
│   │   ├── field_inspection_checklist_page.dart
│   │   ├── field_practical_checklist_page.dart
│   │   ├── field_standard_manual_page.dart
│   │   └── fire_safety_handbook_page.dart
│   ├── manual/                          ← 장애 대응 매뉴얼
│   │   ├── blackout_manual_page.dart    ← 정전
│   │   ├── cctv_manual_page.dart
│   │   ├── defect_manual_page.dart      ← 하자
│   │   ├── elevator_manual_page.dart
│   │   ├── field_manual_page.dart
│   │   ├── fire_manual_page.dart        ← 화재
│   │   ├── freeze_manual_page.dart      ← 동파
│   │   ├── leakage_manual_page.dart     ← 누수
│   │   └── parking_tower_manual_page.dart
│   ├── safety/                          ← 안전 교육 (11종)
│   │   ├── basement_safety_page.dart
│   │   ├── chemical_safety_page.dart
│   │   ├── confined_space_safety_page.dart
│   │   ├── electrical_safety_page.dart
│   │   ├── evidence_safety_page.dart
│   │   ├── field_safety_page.dart
│   │   ├── fire_work_safety_page.dart
│   │   ├── heavy_load_safety_page.dart
│   │   ├── ladder_safety_page.dart
│   │   ├── machinery_safety_page.dart
│   │   └── vehicle_safety_page.dart
│   ├── subcontractor/                   ← 하도급 가이드 (9종)
│   │   ├── cleaning_service_guide_page.dart
│   │   ├── disinfection_service_guide_page.dart
│   │   ├── electric_safety_guide_page.dart
│   │   ├── elevator_safety_guide_page.dart
│   │   ├── field_outsource_guide_page.dart
│   │   ├── fire_safety_guide_page.dart
│   │   ├── integrated_security_guide_page.dart
│   │   ├── parking_lift_safety_guide_page.dart
│   │   └── water_tank_guide_page.dart
│   ├── sales/                           ← 영업 관리
│   │   ├── checklist_page.dart
│   │   ├── sales_list_page.dart
│   │   ├── sales_write_page.dart
│   │   └── tax_invoice_page.dart
│   ├── sales_info/
│   │   ├── sales_info_page.dart
│   │   └── sales_inquiry_list_page.dart
│   ├── meeting/                         ← 회의 관리
│   │   ├── meeting_guide_page.dart
│   │   ├── meeting_hub_page.dart
│   │   ├── meeting_script_page.dart
│   │   └── test.dart
│   └── it_support/
│       └── ai_payment_page.dart
├── services/
│   ├── auth_service.dart
│   ├── building_service.dart            ← 건물 데이터 (Firestore 컬렉션 확인 필요)
│   ├── notification_service.dart
│   └── sales_service.dart              ← 영업 데이터 (Firestore 컬렉션 확인 필요)
├── theme/
│   └── app_theme.dart
├── utils/
│   ├── daum_postcode_stub.dart
│   └── daum_postcode_web.dart
└── widgets/
    ├── app_naver_map_holder.dart
    ├── app_naver_map_holder_stub.dart
    └── common_widgets.dart
```

---

## 🔗 aivex-super 통합 연동 예정 데이터

| 데이터 | 출처 | 표시 방식 |
|--------|------|---------|
| 건물 수 | building_service (컬렉션 확인 필요) | 숫자 카드 |
| 영업 현황 | sales_service (컬렉션 확인 필요) | 숫자 카드 |
| 최근 현장 보고 | field_report 관련 (확인 필요) | 리스트 |

---

## ⚠️ 주의사항

| 항목 | 내용 |
|------|------|
| 네이버 지도 | Web/Stub 패턴 적용 |
| 다음 주소 | Web/Stub 패턴 적용 |
| Firebase Functions | functions/ 폴더 별도 존재 |
| main push | PR 경유만 허용 |
