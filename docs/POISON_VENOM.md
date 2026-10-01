# 독 / 맹독 분리 — 2026-10-02

- `poison` = 독, COUNTER / dot_flat. 자신의 턴 시작마다 중첩 수만큼 방어 무시 HP 피해 후 1중첩 감소. 재부여는 중첩 합산.
- `venom` = 맹독, DURATION / dot_percent. 최대 HP의 8%(올림, 최소 1) 피해 후 1턴 감소. 기존 맹독 주술 ID, 3턴/강화4턴, 8%, 재사용 시 지속시간 갱신 동작 유지.
- 두 상태는 동시에 존재하고 별도로 감소/해제한다. 플레이어와 몬스터에 같은 UnitStatus 적용. 맹독 툴팁에는 실제 적용 비율과 다음 피해를 표시한다.
- 미라 `poison_infusion` 독 주입 추가: 비용1, 독5/강화8. 기존 보상·상점 캐릭터 풀에 연결, 시작 덱은 그대로. 검수한 독 심볼을 카드 이미지로 공유한다.
- 편집 원본 `tools/content_tool/data/content.json`, API 수정/validate/export. 런타임 `data/content_tool/catalog.json`. 독은 기존 미승인 테스트 항목을 정식 정의로 전환했다. 기존 맹독 ID는 바꾸지 않았다. 게임 저장/불러오기 자체는 아직 미구현이다.

## 이미지
ComfyUI SDXL base 1.0, 768×768 각각 독립 생성. 병 그림은 사용하지 않는다.
- 독 `assets/status/poison_v3.png`: seed9468, prompt_id cf1c7dea-3801-45c1-8b27-30bd921d028c. 초록 액체 방울.
- 맹독 `assets/status/venom_v1.png`: seed9360, prompt_id 4a0fbf6a-55f0-44cb-8546-ba1567d0363b. 보라 독 해골.
- 독 v1은 다중 배열, v2는 얼굴 형태라 불합격. PC work에 보존, 게임 미포함. 최종 두 장을 시각 검수 후 approved로 export했다. 투명 PNG가 아닌 배경 포함 아이콘이며 34px 전투 표시에서 서로 구분됨을 확인했다.
- 도감의 이미지 경로 허용 목록에 status/content_tool을 추가했다. 새 승인 이미지가 '전용 아트 미등록'으로 표시되던 원인 수정.

## 검증
REST validate 24/24 오류0. Godot 4.7.2 바탕화면 실제 프로젝트에서 `POISON_SPLIT_QA failures=0`.
최대HP72/100/250 비례·고정 동시 피해, 독 중첩 합산, 독립 만료, 강화, 기존 맹독 수치, 실제 카드 두 장 사용, 양쪽 HP바 아이콘 및 툴팁 문자열, 양쪽 턴 피해, 다음 전투 초기화, 도감 두 레코드/아트 로딩 검사.
`docs/poison-venom-battle.png`, `docs/poison-venom-codex.png` 실제 렌더링. 테스트의 방어999와 양쪽 상태는 QA 시나리오이며 일반 원정 초기값이 아니다. 마우스 hover 팝업 자체의 자동 시각 검사는 미실시.
바탕화면 파일은 Git HEAD와 비교해 일치 확인 후 백업/병합. 백업 `work/before-poison-split-desktop.zip` (PC 로컬).
