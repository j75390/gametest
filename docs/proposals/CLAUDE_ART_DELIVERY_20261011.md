> 최신: 아래 미완료17개는 전부 재작업 합격. CLAUDE_REDO_DELIVERY_20261011.md와 새 MAPPING을 사용하세요. 기존36+새17=53개 납품 준비.

# Claude 그림 요청 처리 — 2026-10-11

원 요청: 바탕화면 실행 프로젝트 docs/CODEX_ART_HANDOFF_2026-10-11.md. 스냅샷: CLAUDE_REQUEST_SNAPSHOT_20261011.md.

## 적용 가능
- 이벤트 30장: assets/delivery/claude_20261011/events. CLAUDE_EVENT_ART_MAPPING_20261011.json의 동일 seed 육안 합격만 복사. 1024×1536 RGB PNG. SDXL 768×1152 생성 후 리샘플한 결과이며 원본은 ai/claude_events_20261011 보존.
- 상태 힘·취약 2장과 유물 교대종/양면 처방판/가라앉지 않는 추/검은 여과지 4장: assets/delivery/claude_20261011/status, relics. CLAUDE_ICON_ART_MAPPING_20261011.json 참조. 512×512 RGBA.
- 기존 유물 154종과 도감 허브 5종 보존.

## 현재 보류
- 이벤트 common_act1_05: 빵·토큰 빠짐, common_act1_26: 수레가 뒤집히지 않음, common_act1_28: 꺼진 촛불 대신 불꽃. 합격 폴더에 포함하지 않음.
- 몬스터 첫 전신 배치 12종: 발은 보이지만 직업 도구/기도 자세가 빠져 모두 불합격. 두 번째 전신 배치도 직업 도구·자세·화풍 오류가 있어 보류. ai/claude_monsters_20261011/manual_review.json에 seed별 불합격 이유 기록.
- 약화·시계: 최종 시도도 검 여러 개·가짜 다이얼 글자로 불합격. 생성만으로 합격 아님.

## Claude 적용
Content Tool 승격, image 경로 변경, runtime.tint 제거, 실행 검증은 Claude 담당. delivery 폴더만 사용하며 assets/events 또는 assets/monsters의 원시 배치 폴더 전체를 승격하지 말 것. Codex는 canonical content/catalog/scripts와 바탕화면 실행본을 변경하지 않음. 자동 push 없음.

이전 A 도감 프레임·아이콘, B 연대표 32장, C 음향 요청은 별도 미완료 목록이며 이번 산출물로 완료 처리하지 않음.

이벤트 3장 구도 가이드 재시도도 평면적인 결과로 불합격. 현재 동일 seed 검수 기록을 기준으로 보류 상태를 유지한다.

최종 QA: 합격 36파일(이벤트30, 상태2, 유물4), 규격·투명도·현재 seed 검사 통과. 진행 중 배치 없음. 미완료17개(이벤트3+몬스터12+상태1+유물1).
