# Claude 재작업 17개 완료 — 2026-10-11

최신 요청 `CLAUDE_REDO_REQUEST_SNAPSHOT_20261011.md`의 17개를 전부 새로 제작했다. 이전 문서의 미완료17개 기록은 이 문서로 대체한다. 기존 합격36개는 보존하여 최신 요청 전체 53개가 납품 폴더에 준비되어 있다.

## 합격 자산

- `assets/delivery/claude_20261011/monsters/<id>_v2.png`: 요청 몬스터12종, 768×1152 RGBA. 기존 재의 파수꾼은 유지.
- `assets/delivery/claude_20261011/status/weak_v2.png`: 휘어진 검 한 자루, 512×512 RGBA.
- `assets/delivery/claude_20261011/relics/relic_uncommon_005.png`: 숫자·글자 없는 회중시계, 512×512 RGBA.
- `assets/delivery/claude_20261011/events/common_act1_05.png`, `26.png`, `28.png`에 해당하는 전체 ID 파일: 금속패가 놓인 저울/뒤집힌 구호품 수레/꺼진 촛불 앞 수사. 각 1024×1536 RGB.

정확한 절대경로·검수이유·SHA256: `CLAUDE_REDO_ART_MAPPING_20261011.json`.
한눈에 보는 검수판: `CLAUDE_REDO_REVIEW_20261011.jpg`.

## 제작 및 검수

ComfyUI 반복 결과가 소품·화풍 기준에 못 미쳐, 사용자의 최신 승인에 따라 내장 imagegen으로17개 원화를 제작했다. 몬스터는 기존 `ash_warden.png`, 이벤트는 `empty_ward_v1.png`를 화풍 참고로 사용했다. 실제 생성 사양은 아래 원고에 정리했다. 원본과 중간 자료는 `ai/claude_redo_20261011` 및 sources.json의 원본 경로에 보존한다.

배경이 남는 몬스터·아이콘은 로컬 ComfyUI BiRefNet으로 정리하고 여백을 확보했다. 발 아래 잔여물이 발견된 호송 갑주는 배경만 다시 편집한 뒤 재추출했다. 원화를 덮어쓰지 않았다. 최종 전신의 손·발·관절, 도장/등불/방패/명부판/가위/밸브/문짝 등 필수 소품, 가짜 글자, 밝은 바탕에서의 외곽을 육안검수했다.

규격·alpha·외곽 여백·최종 파일 해시 검사는 `tools/claude_art_delivery_qa.py`로 실행한다. 내장 생성에는 ComfyUI seed가 없으므로 새 manifest는 실제 파일 SHA256과 원본 경로로 판정을 고정했다. 기존 ComfyUI 판정을 새 그림에 재사용하지 않았다.

## Claude 통합

이 폴더의 합격본만 적용한다. 몬스터 image 교체와 runtime.tint 제거, 이벤트/유물 승격, 약화 icon 교체와 실제 게임 화면 검증은 Claude 담당이다. Codex는 content/catalog/scripts와 바탕화면 실행본을 수정하지 않았다. 납품 완료와 게임 적용 완료는 구분한다.

캐릭터는 같은 캔버스 여백/발 기준선으로 정리했다. 체격 대비는 원화에 있지만 게임 표시 높이는 현재 코드가 결정한다. 수문장·정예의 크기 차이를 실제 전투에서 확인할 것. 원본을 임의로 비균등 확대하지 말 것.

이전 도감 프레임·연대표32장·음향 요청은 이번 재작업 범위와 별개다. 자동 push 없음.
