# Codex 인수인계 — 남은 그림 전체 목록 (2026-10-12 아침 기준)

> 이 문서 하나만 보면 된다. 상세 규격은 각 항목의 문서에 있다. **미라 우선 규칙:** 칼리안·세라·루시안 그림(카드·SD·앉은 휴식)은 미라가 완성될 때까지 만들지 않는다.
> 납품 위치 규칙: `assets/delivery/claude_20261012/<폴더>/`, 리뷰 JSON(`manual_review.json`), 매핑 JSON(`docs/proposals/CLAUDE_*_MAPPING_20261012.json`, `{id, path, verdict}`). Claude는 통과분만 적용한다.

## 이번 새벽에 Claude가 적용한 것 (참고)
- 미라 카드 3차 그림 19장 전부 적용 완료(`cards_wave3/`, 매핑 19장 pass). 덱 화면에서 카드마다 다른 그림으로 확인.
- ACT II · ACT III가 끝까지 플레이 가능해졌다. 그림이 없는 부분은 임시 그림으로 돌려 쓰는 중.

## 1순위 — ACT II · III (`docs/CODEX_ACT2_ACT3_ART_2026-10-12.md`)
| 항목 | 개수 | 규격 |
|---|---|---|
| 몬스터 (ACT II 9 + ACT III 8) | 17 | 768×1152 투명 PNG, `monsters/<id>_v1.png`, id는 문서의 표 그대로 |
| 전투 배경 | 2 | 1586×992, `backgrounds/battle_canal_v1.png`, `battle_greenhouse_v1.png` (파일이 있으면 코드가 자동 사용) |
| 필수 이벤트 일러스트 | 11 | 1024×1536, `events/<id>_v1.png` |

## 2순위 — 미라 상태/포션/UI (`docs/CODEX_ART_GAPS_2026-10-11.md`)
| 항목 | 개수 | 비고 |
|---|---|---|
| 상태 아이콘 | 3 | `status/toxic_vapor_v1.png`, `slow_steep_v1.png`, `brewing_bench_v1.png` (512×512 투명) |
| 포션 아이콘 | 4 | `potions/potion_text_07|09|10|12_v1.png`. 도착하면 이미 준비된 효과(에너지+1 / 약화2 / 취약2 / 카드2장)가 게임에 나온다 |
| 소모 더미 아이콘 | 1 | `ui/pile_exhaust.png` (전투 화면 오른쪽 아래) |

## 3순위 — 공통 풀 이벤트 일러스트 27장
ACT II 12편(common_act2_01, 04, 06, 08, 10, 11, 12, 13, 15, 16, 18, 20), ACT III 12편(common_act3_01, 03, 04, 05, 06, 08, 10, 11, 12, 13, 14, 19), 미라 개인 3편(mira_child, mira_tea, mira_signature). 일괄 생성 방식은 Codex가 판단.

## 4순위 — 이전 후순위 (변동 없음)
- 유물 63개 아이콘(글·효과는 준비됨).
- ACT I 이벤트 중 그림 없는 것, 이벤트 154개 중 미라 이벤트부터.
- 미라 카드 4차 그림(카드 목록은 Claude가 확정 후 요청).

## 5순위 — ACT IV (구현 완료, 임시 그림으로 플레이 가능)
`docs/CODEX_ACT4_ART_2026-10-12.md`: 몬스터 8, 배경 `battle_library_v1.png` 1, 필수 이벤트 5, 공통 이벤트 12 + 미라 1(후순위). ACT II·III가 먼저다.

## Claude가 받으면 하는 일
몬스터: `assets/monsters/<id>_v1.png` 복사 → 몬스터 `image` 교체 → 별도 호출 재승인 → export → `--import` → 전투 화면 확인. 배경: 경로 고정, 복사만. 이벤트: `image` 교체 + `text_only` 해제. 상태/포션 아이콘은 지난 문서의 방식 그대로.
