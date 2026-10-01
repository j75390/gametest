# Content Tool 연결

## 실행과 원본
바탕화면 LuckyExpedition_ContentTool_v1.1/RUN_TOOL.cmd는 백업된 원본 대신 Git 프로젝트 tools/content_tool/content_tool.py를 실행하는 연결기로 지정했다. 서버 http://127.0.0.1:8765, ComfyUI http://127.0.0.1:8188.
편집 원본은 tools/content_tool/data/content.json 하나다. 다른 PC에서는 이 저장소의 tools/content_tool/RUN_TOOL.cmd를 사용한다. 바탕화면 실행기의 절대 경로는 PC별 설정이다.

## API / CLI
GET /api/schema, GET /api/data, POST /api/item {type,item}, GET /api/validate, POST /api/export {godot_path}, POST /api/handover.
CLI: python tools/content_tool/content_tool.py list cards / validate / export --godot <프로젝트 경로>.
카드 energy_cost, 몬스터 attack_pattern 등을 편집한다. 수치 효과와 기존 추가 필드는 runtime JSON에서 관리하며 GUI 저장 때도 보존한다. 카드 문구는 Godot의 실제 수치 기반 공통 생성 함수를 따른다.

## Godot export
생성물 data/content_tool/catalog.json 하나를 game_data.gd를 통해 도감/전투/상점/보상이 공유한다. 기존 data/*.json은 미연결 프로젝트의 호환/복구용이며 앞으로 수동 병행 수정하지 않는다. export 후 게임을 재실행해야 캐시가 갱신된다.
기존 콘텐츠 21개는 기존 적용 자산 유지 근거를 approval_basis에 기록해 이관했다. 새 이미지를 승인한 것이 아니다. 툴의 샘플 2개는 draft로 보존/제외했다.
approved만 export한다. 필수 게임 레코드가 미승인/누락이면 기존 카탈로그를 유지하고 실패한다. 이미지 경로 변경은 needs_review로 되돌린다. 외부 승인 이미지는 해시 파일명으로 assets/content_tool/에 복사한다. 단일 카탈로그는 임시 파일 검증 후 교체한다.

## ComfyUI
반복 아이콘 API: POST /api/comfy/generate {type:"powers",id:"poison",url:"http://127.0.0.1:8188",prompt:"..."}. 기존 항목 필수. 생성 성공 시 경로/작업 ID를 기록하고 needs_review. 카드/몬스터/이벤트 및 PREMIUM/MANUAL은 이 자동 경로에서 차단한다. GUI도 같은 API를 사용한다.
현재 8188 연결 거부: ComfyUI가 꺼져 있어 실제 이미지 생성/품질 검수는 미실시. 연결 코드가 준비된 상태이지 생성 성공을 확인한 상태가 아니다.

## 공통 상태
unit_status.gd가 플레이어/몬스터에 공통 적용된다. 현재 지원 동작은 기존 맹독(비율 DOT), 출혈(중첩 DOT), 다음 공격 증폭 3개다. status_panel.gd가 양쪽 HP바 아래 아이콘/수치와 hover 툴팁을 구성한다. 몬스터 powers 및 행동 apply_statuses로 같은 모델에 부여할 수 있다. 300개 초안 전체 효과 구현은 아니다.

## 검증 / 제한
REST 카드 비용 수정→validate→export 값 반영→원래 값 복원 PASS. 23개 validate 오류0, 초안2개 제외. CONTENT_STATUS_QA units=2 shared_catalog=true failures=0. 실제 렌더링 MIRA_MOTION_QA 6종/공격/스킬/피격/사망 오류0. Godot import 오류 없음.
ComfyUI 실제 생성, 전체 300효과, 모든 export 스키마/참조 무결성의 포괄 검증, 브라우저 GUI 수동 조작 및 실제 hover 팝업 시각 검수는 남아 있다. 툴은 로컬 단일 제작자용이며 동시 편집 충돌 해결은 미구현이다.

## ComfyUI 실제 생성 테스트 완료
Content Tool /api/comfy/status 정상, /api/comfy/generate로 powers/poison 샘플 생성 성공. SDXL base 1.0, seed 9357, 768×768, prompt_id 6774d649-e584-49b8-b772-ba112cc34a70.
결과: ai/review/comfy_poison_test.png. 상태 needs_review 자동 기록, validate 오류0, export 제외 PASS. export 전후 게임 데이터는 메타데이터를 제외하고 동일함을 비교했다. 게임 효과/아트는 변경되지 않았다.
시각 검수: 병 실루엣은 구분되지만 밝은 배경과 단순한 재질로 현재 다크 고딕 스타일에 미달한다. 최종 승인하지 않았다. 다음 단계는 반복 아이콘용 워크플로/배경/재질 개선이다.
기존 'ComfyUI 꺼짐/생성 미검증' 기록은 이 테스트로 해소했다. 서버 시작 시 이미 실행 중인 인스턴스의 포트/DB 충돌로 추가 실행은 종료됐고, 정상 응답하는 기존 8188 서버를 사용했다.
