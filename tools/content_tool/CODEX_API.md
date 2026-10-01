# Codex API / CLI 사용법

Codex는 브라우저를 클릭하지 않고 REST API 또는 CLI로 이 툴을 사용할 수 있다.

## 서버 실행
```bash
python content_tool.py serve --no-browser
```

기본 주소:
`http://127.0.0.1:8765`

## REST API

### 전체 데이터
GET `/api/data`

### 스키마
GET `/api/schema`

### 추가/수정
POST `/api/item`

예:
```json
{
  "type": "powers",
  "item": {
    "id": "poison",
    "name": "맹독",
    "category": "DEBUFF",
    "stack_mode": "COUNTER",
    "target": "ENEMY",
    "trigger": "턴 시작",
    "duration": 0,
    "max_stack": 0,
    "effect": "턴 시작 시 중첩 수만큼 피해를 준다.",
    "tooltip": "턴 시작 시 현재 맹독 중첩 수만큼 피해를 받습니다.",
    "art_source": "COMFYUI",
    "approval_state": "draft"
  }
}
```

### 삭제
DELETE `/api/item?type=powers&id=poison`

### 검증
GET `/api/validate`

### Godot Export
POST `/api/export`
```json
{"godot_path":"C:\\path\\to\\GodotProject"}
```

### 인수인계 생성
POST `/api/handover`

### ComfyUI 상태
GET `/api/comfy/status?url=http://127.0.0.1:8188`

### ComfyUI 생성
POST `/api/comfy/generate`

## CLI

### 목록
```bash
python content_tool.py list cards
```

### JSON 파일에서 추가
```bash
python content_tool.py add cards --file new_card.json
```

### 검증
```bash
python content_tool.py validate
```

### Godot Export
```bash
python content_tool.py export --godot "C:\path\GodotProject"
```

### 인수인계
```bash
python content_tool.py handover --goal "카드 시스템" --completed "기본 UI" --pending "유물 연결"
```

## Codex 작업 규칙
1. 콘텐츠 생성 전 `/api/schema` 또는 Python 스키마를 확인한다.
2. 생성 후 반드시 `validate`를 실행한다.
3. 이미지가 필요한 반복형 자산은 ComfyUI 사용 가능.
4. 핵심 캐릭터/보스/주요 카드 아트는 PREMIUM/MANUAL 규칙을 따른다.
5. 작업 종료 시 `/api/handover` 또는 CLI handover로 인수인계를 갱신한다.
