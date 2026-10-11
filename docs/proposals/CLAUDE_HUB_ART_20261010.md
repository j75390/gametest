# Claude 도감 허브 삽화 전달 — 2026-10-10

요청 근거: CLAUDE_CODEX_REDESIGN_SOURCE_2026-10-09.md §8. 이번 완료 범위는 허브 삽화 5종이며 카드 틀·캐릭터 필터·연대표 장면은 별도 후속 작업이다.

| 화면 | 적용 경로 | 검수 |
|---|---|---|
| 카드 | res://assets/ui/claude_hub_20261010/hub_cards.png | 겹친 보라색 카드, 외곽 온전 |
| 유물 | res://assets/ui/claude_hub_20261010/hub_relics.png | 열린 유물 상자, 단일 구성 |
| 포션 | res://assets/ui/claude_hub_20261010/hub_potions.png | 황동 연금 장치와 보라색 병, 첫 결과 글자 오류 재생성 후 제거 확인 |
| 몬스터 | res://assets/ui/claude_hub_20261010/hub_monsters.png | 뿔 달린 괴수 도해, 책 대신 괴수 실루엣 중심 |
| 스토리 | res://assets/ui/claude_hub_20261010/hub_chronicle.png | 고대 연대기 책, 보라색 보석·황동 장식 |

모두 로컬 ComfyUI SDXL + BiRefNet 렌더, 512×512 RGBA. 육안 검수 완료. ai/claude_hub_20261010의 workflow.json에 seed·프롬프트 보관. 글자와 화면 버튼은 Claude가 UI에서 배치. 그림은 독립 삽화이며 프레임/타일 전체 화면이 아니다.

Claude는 기존 허브 타일의 그림 영역에 비율 유지로 적용하고 작은 화면에서 확인. canonical 데이터·scripts·실행본 미수정, push 없음.
