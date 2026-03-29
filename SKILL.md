---
name: gowid-expense
description: Gowid 법인카드 경비 관리 어시스턴트. 미제출 경비 조회, 용도 지정, 제출, 자동 분류 규칙 확인. "경비", "미제출", "고위드", "gowid" 요청에 사용.
triggers:
  - "경비"
  - "미제출"
  - "내 경비"
  - "경비 제출"
  - "고위드"
  - "gowid"
---

# Gowid 경비 어시스턴트

Gowid 법인카드 미제출 경비를 조회하고, 용도를 지정하여 제출하는 Claude Code 스킬.

## 셋업 확인

스킬 실행 시 **반드시 먼저** 아래를 확인:

```bash
# 1. API 키 확인 (없으면 에러 메시지 출력됨)
python3 ~/.claude/skills/gowid-expense/scripts/gowid.py whoami

# 2. Windows 사용자는 python3 대신 python 사용
python ~/.claude/skills/gowid-expense/scripts/gowid.py whoami
```

API 키는 스크립트에 내장되어 있어 별도 설정 불필요.

## 사용자 식별

```bash
# git 이메일로 Gowid userId 조회
python3 ~/.claude/skills/gowid-expense/scripts/gowid.py whoami
# Windows: python ~/.claude/skills/gowid-expense/scripts/gowid.py whoami
```

`whoami` 결과에서 `userId`를 이후 모든 요청의 사용자 식별자로 사용.

## 헬퍼 스크립트

모든 API 호출은 `scripts/gowid.py`를 통해 수행. 경로:

```
~/.claude/skills/gowid-expense/scripts/gowid.py
```

## 워크플로우

### 1. 내 미제출 경비 조회

사용자가 "내 경비", "미제출", "경비 보여줘" 등 요청 시:

```bash
python3 ~/.claude/skills/gowid-expense/scripts/gowid.py my-expenses
```

결과를 **한국어 테이블**로 표시:

```
📋 미제출 경비 (N건)

| # | 날짜 | 가맹점 | 금액 | 추천 용도 | ID |
|---|------|--------|------|----------|-----|
| 1 | 03/26 | READ - MEETING ... | 30,430원 | IT서비스 이용료 | 32625805 |
```

- 금액이 USD/SGP 등 해외인 경우 원화 환산 금액도 함께 표시
- 용도 추천은 auto_rules 기반 (헬퍼가 처리)

### 2. 경비 제출

사용자가 "이거 식비로 제출해", "32625805 IT서비스로 제출" 등 요청 시:

```bash
# 용도 지정 + 제출
python3 ~/.claude/skills/gowid-expense/scripts/gowid.py submit <expenseId> <purposeId> [--memo "메모"] [--participants "id1,id2"]
```

**식비 제출 시**:
- 인당 한도 초과(점심 12,000원, 야근 12,000원, 금요미식회 15,000원)면 참석자 필수
- "누구랑 먹었어요?" 물어보기
- 참석자 이름 → userId 변환은 `gowid.py members`로 조회

**IT서비스 제출 시**:
- 메모에 서비스명 자동 기입 (예: "Notion 워크스페이스")

### 3. 용도 목록 조회

```bash
python3 ~/.claude/skills/gowid-expense/scripts/gowid.py purposes
```

### 4. 팀원 목록 (참석자 선택용)

```bash
python3 ~/.claude/skills/gowid-expense/scripts/gowid.py members
```

### 5. 경비 상세 조회

```bash
python3 ~/.claude/skills/gowid-expense/scripts/gowid.py detail <expenseId>
```

### 6. 자동 분류 규칙 조회

```bash
python3 ~/.claude/skills/gowid-expense/scripts/gowid.py rules [검색어]
```

### 7. 규칙 추가 제안

사용자가 "이 가맹점 규칙 추가해줘" 요청 시:
1. 가맹점 패턴, 용도, 메모를 확인
2. GitHub Issue 생성 제안:

```bash
gh issue create --repo EO-Studio-Dev/gowid-expense-bot \
  --title "규칙 추가: <가맹점> → <용도>" \
  --body "패턴: <pattern>\n용도: <purposeName> (ID: <purposeId>)\n메모: <memo>\n제안자: $(git config user.email)"
```

## 용도 ID 빠른 참조

| ID | 용도 | API 제출 | 비고 |
|----|------|---------|------|
| 12556 | 점심식비 | ✅ 가능 | 인당 12,000원 |
| 12555 | 야근식비 | ✅ 가능 | 인당 12,000원 |
| 131887 | 금요미식회(점심식비) | ✅ 가능 | 인당 15,000원 |
| 12553 | 회식비 | ✅ 가능 | |
| 12552 | 기타식비 | ✅ 가능 | |
| 12532 | IT서비스 이용료 | ✅ 가능 | 메모에 서비스명 |
| 70602 | 멤버십 구독료 | ✅ 가능 | 메모에 서비스명 |
| 12536 | 매거진 구독료 | ✅ 가능 | 메모에 서비스명 |
| 12546 | 우편비 | ✅ 가능 | |
| 72341 | 통신비 | ✅ 가능 | |
| 72017 | 노트북 대여(정기결제) | ✅ 가능 | |
| 12533 | 소모품비(10만원이하) | ✅ 가능 | |
| 12551 | 업무교통비 | ❌ 불가 | 필수항목 강제 (출발지/도착지) |
| 12550 | 야근교통비 | ❌ 불가 | 필수항목 강제 (출퇴근 시간) |
| 12537 | 도서구입비 | ❌ 불가 | 필수항목 강제 (책 제목) |
| 12531 | 서류발급비 | ❌ 불가 | 필수항목 강제 (프로젝트명) |
| 85747 | 업무추진비(스탭식비,촬영음료) | ✅ 가능 | 프로젝트 필요 |
| 12530 | 온라인 마케팅 | ✅ 가능 | 프로젝트 필요 |

## API 제출 제한 (필수항목 강제 용도)

Gowid Open API는 `purposeRequirementAnswerMap` 필드를 처리하지 못한다.
서버에서 필수항목이 강제된 용도(업무교통비, 야근교통비, 도서구입비, 서류발급비 등)는
API로 제출 시 500 에러가 발생한다.

**제출 불가 용도 판별**: `purposes` 커맨드에서 `hasRequirements: true`인 용도 중
IT서비스 이용료(12532), 멤버십 구독료(70602), 매거진 구독료(12536)를 제외한 나머지.
(이 3개는 서버에서 필수항목 체크가 비활성화되어 있어 API 제출 가능)

**제출 불가 용도를 만났을 때의 행동**:
1. 사용자에게 "이 용도는 Gowid 웹에서 직접 제출해야 합니다"라고 안내
2. 절대로 다른 용도(예: IT서비스)로 대체 제출하지 말 것 — 관리자 승인 시 용도 불일치로 반려됨
3. 메모만 먼저 설정해두면 웹에서 제출할 때 편함: `gowid.py submit <id> <purposeId> --dry-run`

**이미 제출된 건(SUBMITTED)은 API로 변경/취소 불가**:
- 제출 취소 엔드포인트 없음 (DELETE, cancel 모두 404)
- SUBMITTED 상태에서 용도 변경 PUT → 500 에러
- 잘못 제출된 건은 반드시 Gowid 웹에서 수정해야 함

## 주의사항

- 이 스킬은 **본인 경비만** 조회/제출합니다
- API 키는 회사 공용입니다. 외부에 절대 공유하지 마세요
- 제출 후 Gowid에서 관리자 승인을 기다리면 됩니다
- 이미 제출된 건은 자동으로 건너뜁니다 (중복 제출 방지)
- **필수항목 강제 용도는 API 제출 불가** — Gowid 웹에서 직접 제출 안내
