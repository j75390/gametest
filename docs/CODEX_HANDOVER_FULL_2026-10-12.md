# Codex 종합 인수인계 — 2026-10-12 (Claude → Codex)

이 문서 하나로 지금까지의 대화·결정·작업·남은 일을 파악할 수 있게 정리했다. 그림 규격은 각 항목의 문서를 따른다.

## 0. 먼저 알아야 할 것
- **Claude 작업 폴더는 git 저장소가 아니다.** 프로젝트: `C:\Users\j9357\OneDrive\Desktop\운빨원정대_Godot4_시작프로젝트`. Codex 폴더(`gametest`, 원격 github.com/j75390/gametest)에는 커밋 안 된 변경 120개가 있다. **Claude는 이 저장소를 건드리지 않았고 commit/push도 하지 않았다.** 푸시 방법(프로젝트 동기화 여부)은 사용자 결정 대기 중이다. Claude 쪽 코드·데이터는 Codex 폴더로 복사하지 않았다. 복사한 것은 `docs/`의 문서와 참고 캡처뿐이다.
- **미라 우선 규칙:** 칼리안·세라·루시안 등 다른 캐릭터의 카드·SD·휴식 그림과 콘텐츠는 미라가 완성되기 전에는 만들지 않는다.
- **적용 규칙:** Claude는 Codex 리뷰 JSON/매핑 JSON에서 `pass`인 것만 게임에 적용한다. 그림이 없으면 코드로 때우지 않고 Codex에 요청한다.
- **사용자가 화낸 점(10-12):** 마감 시각(아침 7시)을 정해 줬는데 Claude가 3시간 일찍 멈추고 끝났다고 보고했다. 시간 규율을 지키기로 했다. Codex도 마감이 주어지면 끝까지 쓸 것.

## 1. 이번 대화에서 사용자가 요구한 것
1. "그림 확인하고 작업" — Codex의 미라 3차 카드 그림 19장을 확인해 적용.
2. 이벤트는 **슬더스2처럼 실제 효과**(비용·보상)가 있어야 한다. 스토리만 얻는 이벤트는 안 된다. 해금은 이벤트가 아니라 **timeline식 진행 조건**이다.
3. 공격 카드에 취약 등을 반영한 **실제 피해**를 보여 주기 → 구현, 사용자: "아주 맘에 들었어".
4. 아침 7시까지 다음 스토리라인, 몬스터, 패턴 등을 진행하고 끝나면 정리 보고 + 필요한 그림은 Codex에 인수인계.
5. 푸시 요청(미결, 위 §0).

## 2. 이번에 Claude가 한 일
| 영역 | 내용 |
|---|---|
| 미라 카드 3차 그림 | 19장 전부 pass로 적용(`cards_wave3/`, `_v3.png`) |
| 이벤트 효과 | 선택지마다 `▶ HP 4 잃음 · 최대 HP +4` 한 줄. 부작용 카드를 비용으로 쓰는 `curse_add` 신설 |
| 공격 카드 피해 미리보기 | 취약·약화·보너스 반영, 초록(증가)/빨강(감소) |
| ACT II · 검은 운하 | 몬스터 9, 필수 6, 공통 12, 미라 1. 지도 3·8행 고정 사건, 보스 직전/직후 필수 사건 |
| ACT III · 유리 온실 | 몬스터 8, 필수 5, 공통 12, 미라 2. ACT II 선택이 ACT III 문장으로 나타남(`dialogue_by_flag`) |
| ACT IV · 이름 없는 서고 | 몬스터 8, 필수 5, 공통 12, 미라 1(07:05 구현) |
| 패턴 엔진 | 첫 행동(opener), HP 국면(phases), 중독 정화(cleanse), 부작용 카드(side_effect) |
| ACT 전환 | 다음 ACT로 내려갈 때 HP 30% 회복, 덱·유물·골드·조사 기록 유지 |
| 테스트 | `act2_qa`, `act3_qa`, `act4_qa`, `act_fights_qa`(25전투), `event_effects_qa`, `damage_preview_qa` 등. 전체 묶음은 52개 중 51개 통과(실패 1개는 낡은 기대값이라 고침). ACT IV 이후 전체 재실행은 안 함 |

몬스터 수치와 이벤트 보상은 **플레이해 보지 않은 추정치**다. ACT II~IV 몬스터는 ACT I 몬스터 그림을 임시로 쓰고 있고, 이벤트에는 일러스트가 없다.

## 3. Codex가 만들어야 할 그림 (우선순위)
### 1순위 — ACT II · III (`CODEX_ACT2_ACT3_ART_2026-10-12.md`)
- 몬스터 17종: 768×1152 투명 PNG, `monsters/<id>_v1.png` (id는 문서 표대로)
- 전투 배경 2장: 1586×992, `backgrounds/battle_canal_v1.png`, `battle_greenhouse_v1.png` (파일이 있으면 코드가 자동 사용)
- 필수 이벤트 일러스트 11장: 1024×1536, `events/<id>_v1.png`

### 2순위 — 미라 상태·포션·UI (`CODEX_ART_GAPS_2026-10-11.md`)
- 상태 아이콘 3: `status/toxic_vapor_v1.png`, `slow_steep_v1.png`, `brewing_bench_v1.png` (512×512 투명)
- 포션 아이콘 4: `potions/potion_text_07|09|10|12_v1.png`
- 소모 더미 아이콘 1: `ui/pile_exhaust.png`

### 3순위 — 공통 풀 이벤트 일러스트 27장 (ACT II 12, ACT III 12, 미라 개인 3)
### 4순위 — 이전 후순위: 유물 63개 아이콘, ACT I 이벤트 중 그림 없는 것, 미라 카드 4차
### 5순위 — ACT IV (`CODEX_ACT4_ART_2026-10-12.md`): 몬스터 8, 배경 `battle_library_v1.png`, 필수 이벤트 5, 공통 12 + 미라 1(후순위)

## 4. 납품 방식
- 위치: `assets/delivery/claude_20261012/{monsters,backgrounds,events,...}/` (빈 폴더는 만들어 두었다)
- 리뷰 JSON(`manual_review.json`)과 매핑 JSON(`docs/proposals/CLAUDE_*_MAPPING_20261012.json`, 항목 `{id, path, verdict}`)을 함께 둔다.
- Claude가 받으면: 몬스터는 `assets/monsters/<id>_v1.png`로 복사 → 몬스터 `image` 교체 → **별도 호출로 재승인** → export → `--import` → 전투 화면 확인. 배경은 고정 경로에 복사만. 이벤트는 `image` 교체 + `text_only` 해제.

## 5. 사용자 결정 대기 (Codex는 신경 쓰지 않아도 됨)
ACT 전환 HP 회복 30%, 제조식 처리 보상, 보스 국면 전환 / ACT IV 제안값 / 효과 한 줄 표시와 10-10 규칙의 충돌 여부 / 연대기 해금 조건 H03·H06·H08의 진행 조건 전환 / ACT V 구현 여부.

## 6. 참고 문서 (모두 `docs/`)
`WORK_REPORT_2026-10-12.md`(전체 작업 보고), `CODEX_PENDING_2026-10-12.md`(그림 목록 한 장 요약), `ACT3_STORY_DESIGN_2026-10-12.md`, `ACT4_STORY_DESIGN_2026-10-12.md`, `claude_refs_20261012/`(참고 캡처).
