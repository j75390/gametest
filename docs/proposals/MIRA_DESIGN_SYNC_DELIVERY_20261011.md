# 미라 의상 통일 자산 — Claude 적용 인계

사용자가 좋아한 원정 시작 일러스트를 기준으로 상아색 블라우스/검정 높은 목깃/검정 코르셋/긴 검정 치마/어두운 가지색 머리/머리 옆 상아 까마귀 가면을 맞췄다. 선택 일러스트는 변경하지 않았다.

## 완료한 자산
- 의상이 드러나는 카드 5장: strike, defend, soul_binding, bear_the_pain, borrowed_pain. 기존 장면의 효과와 구도를 유지한 수정본. 수비는 정면 인물과 정면 원형 결계를 유지한다. 구속은 넓은 장면이므로 중앙 정사각형 crop으로 미라를 잘라 버리지 말고 전체 구도를 보존한다.
- 독립 도트 PNG 12장: idle, idle_blink, walk_a, walk_pass, walk_b, attack_prepare, attack_release, skill_charge, skill_release, hurt, death_fall, death_rest. 기본/이동/공격/스킬/피격/사망 6개 짧은 키포즈 타임라인용이며 고프레임 애니메이션 완성이 아니다.
- 손그림 SD 기본 자세 1장: sd/idle_v4.png. 디자인 및 도감용 기본 자세 후보. 이 그림을 줄여 도트 모션으로 대체하지 않는다. 손그림 SD의 나머지 11개 모션을 만들었다는 뜻이 아니다. 전투 모션 교체는 위 독립 도트 12장을 사용한다.
- 중간 결과 7장 불합격 보존: 걸음 구분 부족 4장, 이동 중 약병 누락 1장, 투척 약병/마법 효과 잘림 2장. 모두 재수정했으며 최신 통과 자산에 연결하지 않는다.

## 경로·검수
기본 폴더: assets/delivery/claude_20261011/mira_design_sync/

- CLAUDE_MIRA_DESIGN_SYNC_20261011.json: 카드 5개, 프레임 12개, SD 1개, 해시와 proposed_motions.
- CLAUDE_MIRA_CARD_MAPPING_DESIGN_SYNC_20261011.json: 이전 카드 v2 38개 중 대신 앓기/옮겨진 고통을 최신 의상 수정본으로 교체하고 기본 카드 3개를 추가한 최신 41개 연결 목록. 이전 38개 mapping보다 우선한다.
- 기존 poison_infusion_scene_v1.png / venom_hex_ritual_v4.png는 상아 소매·가면 또는 사물 중심 구도가 이미 맞아 유지한다. 이번에 다시 생성하지 않았다.
- manual_review.json: 검수 대상의 판정·이유·파일 해시. needs_review는 통과가 아니다.
- generation_records.json / pixel_generation_records.json / pixel_retry_records.json: 생성·수정 프롬프트와 원본 경로. 원본/불합격 이미지를 보존한다.
- card_review.jpg / pixel_review.png: 최신 전달 파일의 육안 검수판. 게임 실행 화면이 아니다.
- MIRA_DESIGN_SYNC_QA_20261011.json: 18개 최신 자산, 프레임 고유 해시, 파일/투명 외곽 검사 PASS. 실제 게임 QA는 아직 하지 않았다.

## Claude 적용 시
1. 카드 연결은 위 최신 mapping을 병합한다. content/catalog export는 Claude만 수행한다. 카드 효과/수치는 이번 변경에 포함되지 않는다.
2. data/character_assets.json의 미라 motions에 proposed_motions를 병합한다. 선택/소개 일러스트는 유지한다. walk_b는 반대 보폭 생성이 반복 실패하여 명확한 들어 올린 발걸음으로 수정한 키포즈다. walk_a → walk_pass → walk_b → walk_pass 연결을 제안한다.
3. 도트는 전부 **320×192 공통 투명 캔버스**, 바닥 y=180. nearest 필터를 쓰고 비율을 유지한다. 프레임마다 alpha를 잘라 새 크기로 표시하거나 개별 크기 보정하지 않는다. 가로로 누운 프레임도 같은 캔버스 기준으로 표시한다. 투명 폭이 넓으므로 기존 고해상도 SD의 폭 맞춤 scale을 그대로 사용하면 작아질 수 있다. 전투 캐릭터의 보이는 높이/바닥 축을 기준으로 한 번만 배율을 정한다.
4. 도감과 전투의 CharacterVisual 경로를 같이 확인한다. 기본/깜빡임, 걷기, 투척, 스킬, 피격, 쓰러짐을 실제로 재생해 바닥·크기 변화·손/팔 연결·효과 잘림을 최종 확인한다. 카드 손패/상세/보상에서도 작은 크기 가독성과 구속의 전체 구도를 확인한다.

## 범위와 남은 일
Codex는 자산·제안·검수 문서만 수정했다. canonical/content/catalog/scripts/실행 복사본은 변경하지 않았으며 push하지 않았다. 실제 적용 및 Godot 실행 QA는 Claude 담당으로 남아 있다.

이전 얼굴 중심 그림 38장은 보존한다. MIRA_ART_PLACEMENT_20261011.md의 스토리/이벤트 재사용 후보는 기존 의상 차이가 있으므로 실제 배치 전에 이번 디자인 기준으로 인물 부분만 수정해야 한다. 해당 후보를 현재 미라 의상과 동일한 최종 자산으로 간주하지 않는다.
