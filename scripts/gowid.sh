#!/usr/bin/env bash
# gowid.sh — Gowid API helper for Claude Code skill
# Usage: gowid.sh <command> [args]

set -euo pipefail

API_BASE="https://openapi.gowid.com"
API_KEY="${GOWID_API_KEY:-}"

if [ -z "$API_KEY" ]; then
  echo '{"error": "GOWID_API_KEY not set. Add to ~/.zshrc: export GOWID_API_KEY=\"your_key\""}'
  exit 1
fi

# --- helpers ---

api_get() {
  curl -sf -H "Authorization: $API_KEY" "$API_BASE$1" 2>/dev/null
}

api_put() {
  local url="$1"; shift
  curl -sf -X PUT -H "Authorization: $API_KEY" -H "Content-Type: application/json" \
    -d "$1" "$API_BASE$url" 2>/dev/null
}

get_my_email() {
  git config user.email 2>/dev/null || echo ""
}

# --- commands ---

cmd_whoami() {
  local email
  email=$(get_my_email)
  if [ -z "$email" ]; then
    echo '{"error": "git config user.email not set"}'
    exit 1
  fi

  local members
  members=$(api_get "/v1/members")
  echo "$members" | python3 -c "
import sys, json
data = json.load(sys.stdin)['data']
email = '$email'
for m in data:
    if m.get('email','').lower() == email.lower():
        print(json.dumps({'userId': m['userId'], 'userName': m['userName'], 'email': m['email'], 'department': m.get('department',{}).get('name','')}, ensure_ascii=False))
        sys.exit(0)
print(json.dumps({'error': f'No user found for {email}'}))
"
}

cmd_my_expenses() {
  local email
  email=$(get_my_email)
  if [ -z "$email" ]; then
    echo '{"error": "git config user.email not set"}'
    exit 1
  fi

  # Get user info first
  local user_info
  user_info=$(cmd_whoami)
  local user_name
  user_name=$(echo "$user_info" | python3 -c "import sys,json; print(json.load(sys.stdin).get('userName',''))")

  if [ -z "$user_name" ]; then
    echo '{"error": "Could not identify user"}'
    exit 1
  fi

  # Fetch all not-submitted, filter by user
  local all_expenses=""
  local page=0
  while true; do
    local resp
    resp=$(api_get "/v1/expenses/not-submitted?page=$page&size=50")
    local content
    content=$(echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(json.dumps(d.get('content',[]),ensure_ascii=False))")

    if [ "$content" = "[]" ]; then break; fi

    all_expenses="${all_expenses}${content}"

    local is_last
    is_last=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['data'].get('last',True))")
    if [ "$is_last" = "True" ]; then break; fi
    page=$((page + 1))
    if [ $page -gt 50 ]; then break; fi
  done

  # Filter by user and format
  echo "$all_expenses" | python3 -c "
import sys, json

raw = sys.stdin.read()
# Parse concatenated JSON arrays
expenses = []
for chunk in raw.split(']['):
    chunk = chunk.strip()
    if not chunk: continue
    if not chunk.startswith('['): chunk = '[' + chunk
    if not chunk.endswith(']'): chunk = chunk + ']'
    try:
        expenses.extend(json.loads(chunk))
    except: pass

user_name = '$user_name'
cutoff = '20260301'
my_expenses = []

for e in expenses:
    card_user = e.get('cardUserName', '')
    exp_date = e.get('expenseDate', '')
    if card_user == user_name and exp_date >= cutoff:
        my_expenses.append({
            'expenseId': e.get('expenseId'),
            'storeName': e.get('storeName', ''),
            'useAmount': e.get('useAmount', 0),
            'currency': e.get('currency', 'KRW'),
            'expenseDate': exp_date,
            'expenseTime': e.get('expenseTime', ''),
            'cardNumber': e.get('cardNumber', '')[-4:] if e.get('cardNumber') else '',
        })

my_expenses.sort(key=lambda x: x['expenseDate'], reverse=True)
print(json.dumps({'count': len(my_expenses), 'expenses': my_expenses}, ensure_ascii=False, indent=2))
"
}

cmd_detail() {
  local eid="$1"
  local resp
  resp=$(api_get "/v1/expenses/$eid")
  echo "$resp" | python3 -c "
import sys, json
d = json.load(sys.stdin)['data']
card = d.get('card', {})
user = card.get('cardUser', {})
result = {
    'expenseId': d.get('expenseId'),
    'storeName': d.get('storeName', ''),
    'useAmount': d.get('useAmount', 0),
    'currency': d.get('currency', 'KRW'),
    'expenseDate': d.get('expenseDate', ''),
    'expenseTime': d.get('expenseTime', ''),
    'approvalStatus': d.get('approvalStatus', ''),
    'purpose': d.get('purpose', {}),
    'memo': d.get('memo', ''),
    'cardNumber': card.get('cardNumber', '')[-4:] if card.get('cardNumber') else '',
    'cardAlias': card.get('alias', ''),
    'userName': user.get('userName', ''),
}
print(json.dumps(result, ensure_ascii=False, indent=2))
"
}

cmd_submit() {
  local eid="$1"
  local purpose_id="$2"
  local memo="${3:-}"
  local participants="${4:-}"

  # Pre-check
  local detail
  detail=$(api_get "/v1/expenses/$eid")
  local status
  status=$(echo "$detail" | python3 -c "import sys,json; print(json.load(sys.stdin)['data'].get('approvalStatus',''))")

  if [ "$status" != "NOT_SUBMITTED" ]; then
    echo "{\"error\": \"Already $status\", \"expenseId\": $eid}"
    exit 0
  fi

  # Set memo if provided
  if [ -n "$memo" ]; then
    api_put "/v1/expenses/$eid/memo" "{\"memo\": \"$memo\"}" > /dev/null
  fi

  # Build submit body
  local body="{\"purposeId\": $purpose_id"
  if [ -n "$participants" ]; then
    body="$body, \"participantIdList\": [$participants]"
  fi
  if [ -n "$memo" ]; then
    body="$body, \"memo\": \"$memo\""
  fi
  body="$body}"

  local resp
  resp=$(api_put "/v1/expenses/$eid" "$body")
  echo "{\"success\": true, \"expenseId\": $eid, \"purposeId\": $purpose_id, \"memo\": \"$memo\"}"
}

cmd_purposes() {
  api_get "/v2/purposes?isActivated=true" | python3 -c "
import sys, json
data = json.load(sys.stdin)['data']
purposes = []
for p in sorted(data, key=lambda x: x['name']):
    purposes.append({
        'purposeId': p['purposeId'],
        'name': p['name'],
        'category': p.get('category', {}).get('name', ''),
        'limitAmount': p.get('limitAmount', 0),
        'hasRequirements': len(p.get('requirements', [])) > 0,
    })
print(json.dumps(purposes, ensure_ascii=False, indent=2))
"
}

cmd_members() {
  api_get "/v1/members" | python3 -c "
import sys, json
data = json.load(sys.stdin)['data']
members = []
for m in sorted(data, key=lambda x: x['userName']):
    if m.get('status') != 'NORMAL': continue
    members.append({
        'userId': m['userId'],
        'userName': m['userName'],
        'email': m.get('email', ''),
        'department': m.get('department', {}).get('name', ''),
    })
print(json.dumps(members, ensure_ascii=False, indent=2))
"
}

cmd_rules() {
  local query="${1:-}"
  local rules_file
  rules_file="$(dirname "$0")/../data/auto_rules.json"

  if [ ! -f "$rules_file" ]; then
    echo '{"error": "auto_rules.json not found"}'
    exit 1
  fi

  python3 -c "
import sys, json
with open('$rules_file') as f:
    data = json.load(f)
rules = data.get('rules', [])
query = '$query'.lower()
if query:
    rules = [r for r in rules if query in r.get('store_pattern','').lower() or query in r.get('purpose_name','').lower()]
result = [{'pattern': r.get('store_pattern',''), 'purpose': r.get('purpose_name',''), 'memo': r.get('requirement_answer',''), 'confidence': r.get('confidence',0)} for r in rules[:50]]
print(json.dumps({'count': len(rules), 'showing': len(result), 'rules': result}, ensure_ascii=False, indent=2))
"
}

# --- main ---

CMD="${1:-help}"
shift || true

case "$CMD" in
  whoami)       cmd_whoami ;;
  my-expenses)  cmd_my_expenses ;;
  detail)       cmd_detail "$@" ;;
  submit)       cmd_submit "$@" ;;
  purposes)     cmd_purposes ;;
  members)      cmd_members ;;
  rules)        cmd_rules "$@" ;;
  help|*)
    echo "Usage: gowid.sh <command>"
    echo ""
    echo "Commands:"
    echo "  whoami        현재 사용자 확인 (git email → Gowid user)"
    echo "  my-expenses   내 미제출 경비 조회"
    echo "  detail <id>   경비 상세 조회"
    echo "  submit <id> <purposeId> [memo] [participant_ids]"
    echo "                경비 제출"
    echo "  purposes      용도 목록"
    echo "  members       팀원 목록 (참석자 선택용)"
    echo "  rules [query] 자동 분류 규칙 조회"
    ;;
esac
