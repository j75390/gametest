# Codex 요청: 미라 손그림 SD 모션 세트 (도트 아님)

## 배경
- 사용자 피드백: 전투 화면의 미라가 도트로 보인다. 원하는 건 `mira_sd_idle_v4.png`와 같은 **손그림 SD 일러스트 화풍**이다.
- 그런데 손그림 SD는 기본 자세 1장뿐이라 모션이 없다. 도트 12프레임은 현재 `pixel_motions_backup`에 보관만 해 둔 상태.
- 따라서 **같은 손그림 SD 화풍으로 동작별 프레임**이 필요하다.

## 요청 (우선순위 순)
1. idle 2장: 기본, 눈 깜빡임(또는 숨쉬기 변형)
2. attack 3장: 준비 → 휘두름/시전 → 복귀
3. skill 3장: 주술/연금술 시전 (보라 마법 이펙트는 캐릭터와 분리된 레이어면 더 좋음)
4. hurt 1장, death 2장(쓰러지는 중, 쓰러짐)
5. walk는 필요 없음(전투에서 제자리 이동은 코드로 처리)

## 규격
- 투명 배경 PNG, 모든 프레임 **같은 캔버스 크기와 같은 발 위치**(기본 1254×1254 유지 가능).
- 의상, 머리, 새 가면 장식은 `mira_sd_idle_v4.png`와 동일. 도트용 디자인 동기화 기준과 같게.
- 선화 두께와 채색 질감은 idle_v4와 통일. 도트화/최근접 확대용 아님(선형 필터로 표시).
- 납품 위치: `assets/delivery/claude_20261011/mira_sd_motion/` 에 `idle.png`, `idle_blink.png`, `attack_1..3.png`, `skill_1..3.png`, `hurt.png`, `death_1..2.png`
- 리뷰 JSON(verdict pass/fail)과 함께 알려줄 것.

## Claude 쪽 적용 계획
`data/character_assets.json`의 `motions`에 프레임 경로와 duration을 넣고 `pixel_art:false`로 표시. 코드는 이미 지원함.
