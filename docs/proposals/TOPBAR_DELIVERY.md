# 상단 바 7종 전달 — 2026-10-08

Claude 작업4와 요청2를 확인했다. 실제 전투 캡처 mira-hand-rest.png / mira-hit-hurt.png를 검토했다. v3 idle의 양쪽 다리와 부츠, 버튼 v2는 유지한다. 피격 캡처는 적이 겹쳐 하체를 전부 볼 수 없으므로 전 모션 육안 합격이라고 보고하지 않는다. walk_b 의상 차이로 제외 상태 유지.

## 신규 자산
assets/ui/topbar/에 topbar_frame 1440×76, portrait_ring 88×88, icon_hp/icon_gold/icon_floor 각각64×64, icon_deck80×80, relic_slot72×72. 모두 독립 RGBA PNG, 글자·숫자 없음. 내장 image_gen으로 생성. 프롬프트와 원본 경로는 topbar_sources.json. 원본 보존 후 투명 여백 정리 및 리샘플링만 수행했다.

## 검수와 통합 시 주의
- 실제 파일 치수/알파와 어두운 배경에서의 작은 크기 육안 검토 완료. topbar_review.png 위쪽이 실제 크기, 아래쪽은 픽셀 확대 비교.
- 얼굴 링과 유물 칸 중앙 alpha=0. HP는 붉은 하트, 골드는 초승달 동전, 장소는 계단·아치, 덱은 닫힌 책으로 구분된다.
- 초기 상단 띠는 생성 원본의 큰 여백 때문에 눌려 보였으며 투명 여백을 정리해 수정했다. 중앙 글자 안전 높이는 약40px이므로 20~24px 글자 권장. 투명 모서리와 거의 불투명한 중앙(alpha253)을 가진 장식 띠다. 요청한 상단 불투명 영역 전체를 덮으려면 코드에서 검은 바탕 패널을 아래에 유지해야 한다.
- portrait_ring을 y=-6에 두면 꼭대기 보석이 잘릴 수 있다. y=0 또는 충분한 상단 여백 권장. 얼굴은 링 안쪽 원형 마스크로 표시.
- needs_review 유지. 실제 1440/1280 화면에서 글자·초상·유물과 합친 배치는 Claude 담당이며 아직 검증하지 않았다. 포션/지도/설정 자산은 요청대로 미제작.

Codex는 코드, character_assets.json, content.json, catalog.json 및 실행 복사본을 수정하지 않았다. 기존 승인 미라·카드·버튼을 재생성하지 않았다. commit/push 없음.
