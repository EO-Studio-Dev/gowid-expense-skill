# gowid-expense-bot

Claude Code에서 법인카드 경비를 자동 분류하고 제출하는 스킬.

## 이게 뭐야?

법인카드 쓰고 Gowid 앱에서 일일이 용도 선택하고 제출하는 거, Claude Code가 대신 해줍니다.

- **자동 처리**: IT서비스 구독, 통신비, 노트북 대여 등 반복 결제 → 확인 한 번이면 끝
- **대화형 처리**: 식비 참석자, 교통비 출발지 등 → Claude가 물어보고 제출
- **직접 지정**: "이거 도서구입비로 해줘" → 바로 제출

## 설치

터미널에서 한 줄 복붙:

```bash
curl -s https://raw.githubusercontent.com/EO-Studio-Dev/gowid-expense-bot/main/install.sh | bash
```

설치 후 새 터미널을 열거나 `source ~/.zshrc` 실행.

## 사용법

Claude Code에서 자연어로:

```
"내 경비 보여줘"
"경비 처리해줘"
"이거 IT서비스로 제출해"
"3번 식비로, 중철이랑 먹었어"
"용도 목록 보여줘"
```

### 처리 흐름

```
"경비 처리해줘"
  ↓
📋 미제출 경비 10건

자동 제출 가능 (4건):
  ANTHROPIC CLAUDE TEAM  → IT서비스 이용료 (Claude 팀 구독)
  NOTION LABS            → IT서비스 이용료 (Notion 워크스페이스)
  ZOOM.COM               → IT서비스 이용료 (Zoom 화상회의)
  LG U+ 통신요금          → 통신비

이 4건 제출할까요? → "응" → ✅ 제출 완료

대화 필요 (3건):
  쿠팡이츠  → "점심식비인가요? 누구랑 먹었어요?"
  카카오T택시 → "업무교통비? 어디서 어디로?"
  교보문고   → "도서구입비? 무슨 책이에요?"
```

## 자동 분류 규칙

289개 가맹점 패턴이 등록되어 있습니다:

| 카테고리 | 규칙 수 | 예시 |
|---------|---------|------|
| IT서비스 이용료 | 100 | Notion, Slack, Zoom, Figma, GitHub, Airtable... |
| US-식비 | 78 | DoorDash, Starbucks, In-N-Out, Trader Joe's... |
| 매거진 구독료 | 13 | Bloomberg, NYT, WSJ, Forbes, Wired... |
| 도서구입비 | 15 | 교보문고, 알라딘, 예스24, Audible... |
| 업무교통비 | 8 | 카카오T택시, 우버택시, SR, 지하철... |
| 기타 | 75 | 서류발급비, 주차비, 통신비, 우편비... |

규칙에 없는 가맹점은 Claude가 용도를 물어봅니다.

## 요구사항

- [Claude Code](https://claude.ai/claude-code) 설치
- Gowid 법인카드 계정 (`@eoeoeo.net` 이메일)

## 구조

```
gowid-expense/
├── SKILL.md              # Claude Code 스킬 정의
├── scripts/
│   └── gowid.sh          # Gowid API 헬퍼 (7개 커맨드)
├── data/
│   └── auto_rules.json   # 자동 분류 규칙 (289개)
├── install.sh            # 원클릭 설치 스크립트
├── README.md
└── LICENSE               # MIT
```

## 기여하기

새 가맹점 규칙을 추가하고 싶으면:
1. Claude Code에서 "이 가맹점 규칙 추가해줘"라고 말하거나
2. [GitHub Issue](https://github.com/EO-Studio-Dev/gowid-expense-bot/issues)에 등록

## 라이선스

MIT
