# ACT I 시작 대화와 보상

원정 시작 → 문지기 에델의 대화 2단계 → 3개 중 보상 하나 → 응답 대사 → 성당으로 들어간다 → 기존 지도.

- `scripts/act_arrival.gd`: 독립 일러스트와 대화/선택 버튼, 1440×900 기준 비율 유지.
- `scripts/main.gd`: 원정 초기화 시에만 pending/reward_taken 초기화. 골드80/최대·현재HP6/해당 캐릭터 카드1장 중 하나. 카드 후보는 원정 시작 시 한 번 정하고 선택 버튼에 이름, hover에 실제 효과 표시. 기본 덱 구성은 유지하고 카드 보상을 직접 선택했을 때만 추가한다.
- 보상 선택은 한 번만 반영. 결과 대사를 읽은 후 지도 진입. 선택 전 show_map도 시작 대화로 안내. 지도 노드는 소비하지 않는다. 일반 뒤틀린 제단 이벤트는 ID로 조회하여 새 이벤트 추가 순서에 영향받지 않는다.
- Content Tool CLI add → needs_review → 전체 이미지 검수 후 approved → validate(26/26) → export. 입력 기록 `tools/content_tool/data/ash_arrival_input.json`, 편집 원본 `content.json`, 게임 원본 `data/content_tool/catalog.json`. 도감도 동일 레코드를 읽고 events 이미지 경로 허용.
- 독립 그림 `assets/events/ash_keeper_v1.png`: 내장 imagegen, source exec-98eedecd-5b60-401e-9f76-7723914ad6b3.png. 은발 성인 성당 문지기, 검은 상복 베일/금속 장식, 등불과 내민 손, 폐허 성당, 애니메이션 판타지 화풍, 텍스트·UI 없음. 이미지 전체 사용. 참고 게임의 캐릭터/대사/자산을 복사하지 않았다.
- 참고 URL https://spire-codex.com/kor/events/neow 는 도구에서 Loading만 노출되어 세부 내용을 읽었다고 주장하지 않는다. 사용자가 제공한 스크린샷과 대화→선택→지도 요구사항을 기준으로 구성했다.

검증: ACT_ARRIVAL_QA 두 해상도, 실제 버튼 입력, 세 보상 수치, 중복 방지, 선택 전 지도 차단, 결과→지도, 새 원정 초기화, 기존 일반 이벤트 PASS. SELECTION_RELIC_QA 및 MIRA_HIT_QA PASS. 기존 QA의 원정 준비도 시작 보상 선택을 거치도록 갱신했다. 모든 기존 QA를 재실행한 것은 아니다.

ACT II 자체가 아직 없으므로 보스 이후 다음 ACT 인물/이벤트는 미완성이다. 현재 완료는 ACT I 입장 흐름이며, 저장/불러오기와 멀티 동기화도 미구현이다. 현재 보상 수치는 초기값으로 밸런스 조정 대상이다.
