# 미라 가면 개편과 ACT I 이야기 — 2026-10-03

## 적용
- 미라 이름/얼굴/보라 머리/의상/스탯/덱 유지. 토끼 가면을 얼굴이 보이는 머리 옆 위의 상아색 까마귀 부리형 역병의사 가면으로 교체.
- 독립 자산 20장: 선택 좌상, 전신 투명, 초상화, 배경 포함 원화 2, 파노라마 1, 카드 2, 도트 12. 기존 원본은 보존하고 `data/character_assets.json` 및 Content Tool에서 새 경로를 연결.
- 도트는 1254×1254 RGBA 독립 프레임. 기존 6종 모션과 재생 시간 유지. 시트 자르기/원화 축소 없음. 생성 원본과 검수 내역: `mira-plague-assets.json`.
- 원정 시작 시 에델이 미라의 가면 속 이름을 알아보며 지워진 수령인 칸을 언급. 다른 캐릭터에게는 기존 대사 사용. 보상 3종과 한 번 지급 규칙 유지.
- 미라가 실제로 진입한 첫 이벤트 칸은 `empty_ward`(빈 병동). 전용 일러스트 1장. 명패 보관/사본 작성/떠남 중 하나 선택 → 응답 → 지도. 이후 이벤트 칸은 기존 뒤틀린 제단 유지.
- 명패는 현재 **원정 내 조사물/기록**이며 전투 유물로 지급하지 않는다. 효과를 임의로 추가하지 않았고 선택 전에 설명한다. 병동 후속 구조 사건/유물화는 미완성.
- 도감 스토리의 서문 2개와 조건부 조사 기록 3개는 `data/story_records.json`에서 읽는다. 조사 결과는 실제 선택한 것만 보이며 새 원정에서 초기화. 이안의 정체/후반 반전은 도입에서 공개하지 않는다.

## 제작 흐름
`tools/content_tool/data/ash_arrival_input.json`, `empty_ward_input.json`, `*_plague_input.json`을 CLI `add`로 반영. 이미지 경로 변경 시 needs_review → 실제 이미지 확인 → approved → validate → export.

```
python tools/content_tool/content_tool.py validate
python tools/content_tool/content_tool.py export --godot .
```

카드/이벤트 런타임 원본은 기존 `data/content_tool/catalog.json`. 캐릭터와 스토리 분류는 현재 툴에서 지원하지 않으므로 기존 `Data.read`를 통해 캐릭터/스토리 JSON을 읽는다. 임의의 두 번째 전투 수치 원본을 만들지 않는다.

## 검증
- Content Tool 27개 검증, invalid 0. 기존 미승인 explorers_map 초안은 여전히 export 제외.
- Godot 실제 실행: ACT_ARRIVAL_QA, SELECTION_RELIC_QA, MIRA_STORY_QA 통과.
- MIRA_STORY_QA: 1440×900/1280×720, 실제 노드 진입, 3개 배타 선택, 중복 방지, 도감 조건, 지도 복귀와 노드 완료, 새 원정 초기화, 타 캐릭터의 기존 이벤트 유지.
- 모션 검사의 구형 폴더명 하드코딩을 현재 프로필 경로 비교로 교체. 바탕화면 MIRA_MOTION_QA failures=0, MIRA_HIT_QA failures=0, MIRA_STORY_QA PASS.

## 남은 범위
5 ACT 전체 연결, 이안의 후반 편지/엔딩, 조사 기록 영구 저장, 명패의 후속 사건 및 전투 유물화, 전투 배경/음향은 아직 구현하지 않았다. 이번 구현은 미라 미술 통일과 ACT I 도입·첫 조사 사건이다.

사용자 지시에 따라 로컬만 저장하며 push하지 않는다.
