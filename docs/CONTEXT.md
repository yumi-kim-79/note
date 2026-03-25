# CONTEXT.md — 노트 프로젝트 현황

> **Claude Code 필독 파일** | 마지막 업데이트: 2026-03-25
> 작업 시작 전 이 파일을 읽고 현재 상태를 파악하세요.
> 구조 상세는 `docs/ARCHITECTURE.md` 참고.

---

## 🏗️ 프로젝트 개요

**노트(Note)** — 공동주택 관리사무소 업무 관리 솔루션
현장점검, 안전교육, 하도급 가이드, 영업관리, 회의, 매뉴얼 등 포함

| 항목 | 내용 |
|------|------|
| 배포 URL | xn--bl3b03itzc92b.com |
| Firebase 프로젝트 ID | firebase_options.dart 확인 필요 |
| GitHub 저장소 | github.com/yumi-kim-79/note |
| 로컬 폴더 | ~/에이벡스/note/ |
| 플랫폼 | Flutter Web |

---

## 📍 현재 상태 (Current State)

- ✅ Flutter Web 배포 완료
- ✅ GitHub 저장소 생성 및 코드 업로드 (yumi-kim-79/note)
- ✅ 파일 구조 파악 완료 (ARCHITECTURE.md 기록됨)
- ✅ Claude Code 워크플로우 세팅 (docs/ 폴더)
- 🔄 협업자 초대 진행 중 (yuseok8052-bit)
- ⬜ Firebase 프로젝트 ID 확인
- ⬜ Firestore 컬렉션명 확인 (building_service.dart, sales_service.dart)
- ⬜ aivex-super 통합 대시보드 연동

---

## 🎯 다음 작업 (Next Up)

| 순서 | 작업 |
|------|------|
| 1 | ⬜ Firebase 프로젝트 ID 확인 (firebase_options.dart) |
| 2 | ⬜ Firestore 컬렉션명 파악 (building_service, sales_service) |
| 3 | ⬜ aivex-super 통합 대시보드 연동 |

---

## ⚠️ 주요 주의사항

| 항목 | 내용 |
|------|------|
| 네이버 지도 | app_naver_map_holder.dart 사용 |
| 다음 주소 | daum_postcode_web.dart 사용 (Web/Stub 패턴) |
| Firebase Functions | functions/ 폴더 존재 |
| main push | PR 경유만 허용 |
