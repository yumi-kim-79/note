# CLAUDE.md — Claude Code 작업 지침 (노트)

> 이 파일은 Claude Code가 세션 시작 시 자동으로 읽는 지침 파일입니다.
> 모든 작업은 아래 절차를 반드시 따릅니다.

---

## 🔁 작업 시작 전 필수 절차

```bash
cat docs/CONTEXT.md
cat docs/CHANGELOG.md
cat docs/ARCHITECTURE.md
```

파일을 읽은 후 현재 상태를 요약하고 **무엇을 할지 확인**받은 뒤 작업을 시작하세요.

---

## ✅ 작업 완료 후 필수 절차

### 1. CONTEXT.md 업데이트
- 완료된 항목 ✅ 체크
- 다음 작업 순서 조정

### 2. CHANGELOG.md 맨 위에 작업 이력 추가

### 3. Git commit & push
```bash
git add -A
git commit -m "작업 내용 한 줄 요약"
git push origin main
```

> ⚠️ main 브랜치에는 직접 push하지 않습니다. PR을 통해서만 머지합니다.
> 단, docs/ 업데이트는 main 직접 push 허용.

---

## 📁 docs/ 파일 역할

| 파일 | 역할 | 업데이트 시점 |
|------|------|--------------|
| `CONTEXT.md` | 프로젝트 현재 상태 스냅샷 | 매 작업 완료 후 |
| `CHANGELOG.md` | 작업 이력 누적 기록 | 매 작업 완료 후 |
| `ARCHITECTURE.md` | 기술 스택, 구조, 규칙 | 구조 변경 시 |
| `tasks/TASK_TEMPLATE.md` | 새 작업 시작 템플릿 | 복사해서 사용 |

---

## 🌿 브랜치 전략

```
main        ← 프로덕션 (직접 push 금지, PR만)
develop     ← 기본 개발 브랜치
feature/*   ← 기능 개발
```

---

## 🔥 Firebase 정보

| 항목 | 내용 |
|------|------|
| 배포 URL | xn--bl3b03itzc92b.com |
| 프로젝트 ID | firebase_options.dart 확인 |

---

## ⚡ 자주 쓰는 명령어

```bash
# Flutter 빌드 & 배포
flutter build web --release
firebase deploy --only hosting

# Preview Channel 배포
firebase hosting:channel:deploy preview --expires 7d
```
