# CLAUDE.md — gowid-expense-skill

## 프로젝트 개요

Gowid 법인카드 경비를 Claude Code에서 자연어로 조회·제출하는 스킬.
서버 없이 각 팀원의 Claude Code에서 직접 Gowid API를 호출하는 구조.

## 아키텍처

```
팀원 Claude Code
  └── gowid-expense 스킬
       ├── SKILL.md (워크플로우 정의)
       ├── scripts/gowid.py (API 헬퍼, Python 3.9+, 외부 패키지 0)
       └── data/auto_rules.json (289개 자동 분류 규칙)
            ↓
       Gowid REST API (회사 공용 키 내장)
```

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `SKILL.md` | Claude Code 스킬 정의 + 워크플로우 |
| `scripts/gowid.py` | Gowid API 헬퍼 (8개 커맨드) |
| `data/auto_rules.json` | 가맹점별 자동 분류 규칙 289개 |
| `README.md` | 설치 가이드 |

## 설치

```bash
npx skills add EO-Studio-Dev/gowid-expense-skill --skill gowid-expense --agent claude-code -y
```

API 키 내장. 설치 후 바로 사용 가능.

## 라이선스

Proprietary — EO Studio 사내 전용
