# 운빨원정대 Content Tool v1.0

## 특징
별도 라이브러리 설치 없이 **Python 3**만 있으면 실행되는 로컬 웹 제작 툴입니다.

지원:
- 카드
- 유물
- 포션
- 마법부여(카드 인챈트)
- 파워/상태이상
- 몬스터/엘리트/보스
- 이벤트
- JSON 저장/검증
- Godot 데이터 Export
- Codex용 REST API/CLI
- ComfyUI 연결/이미지 생성
- 인수인계 문서 자동 생성

## Windows 실행
`RUN_TOOL.bat` 더블클릭.

브라우저:
http://127.0.0.1:8765

## 직접 실행
```bash
python content_tool.py serve
```

## 자체 테스트
```bash
python content_tool.py self-test
```

정상:
`SELF-TEST PASS`

## Codex에게 사용시키기
프로젝트에 이 폴더를 넣거나, 별도 tools 폴더로 유지한 뒤 Codex에 `CODEX_API.md`를 읽게 하세요.

## Godot Export
GUI의 `Godot Export`에서 프로젝트 폴더를 입력합니다.

조건:
선택한 경로 안에 `project.godot`이 있어야 합니다.

결과:
`<GodotProject>/data/content_tool/*.json`

## ComfyUI
기본 주소:
`http://127.0.0.1:8188`

`연결 확인` 후 이미지 생성 버튼을 사용할 수 있습니다.

기본 내장 워크플로는 `CheckpointLoaderSimple + KSampler` 방식입니다.
FLUX나 특수 노드 워크플로만 쓰는 환경은 API Format JSON 템플릿을 별도로 연결해야 합니다.

## 중요
ComfyUI 이미지가 생성되면 바로 `approved`가 아니라 `needs_review`가 됩니다.
검수한 자산만 승인해서 게임에 사용하세요.
