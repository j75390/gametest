# 지도 플레이어 위치 표시

## 동작
- 현재 장소 위에 실제 선택 캐릭터의 전용 얼굴 PNG와 금색 테두리, 장소를 가리키는 표식을 표시한다. `현재 위치` 문구로 구분한다.
- 원정 진입과 이동/조우 완료 후 `expedition.current_id`에서 다시 배치한다. 캐릭터나 노드 종류를 하드코딩하지 않는다.
- 지도 장소 아이콘은 기존처럼 원형 바탕 없이 유지한다. 얼굴 테두리는 사용자가 요청한 플레이어 위치 표시에만 사용한다.
- 장식 Controls는 mouse_filter IGNORE이므로 경로 선택과 스크롤을 가로채지 않는다.
- 전신을 잘라 쓰지 않고 내장 image_gen에서 4개의 독립 얼굴 초상화를 새로 만들었다. `data/character_assets.json`의 map_portrait로 연결하고 mipmap을 사용한다.

## 여러 플레이어
`map_view.set_players(players)`에는 player_id, slot, character_id, node_id, color, is_local을 전달한다. 같은 노드의 얼굴은 나란히, 다른 노드는 각 위치에 표시한다. P1~P4 번호와 테두리 색을 사용하고 로컬 플레이어 테두리를 강조한다. 안개로 가려진 노드·잘못된 노드·알 수 없는 초상화는 표시하지 않으며 맵 공개 상태나 이동 권한을 바꾸지 않는다.

현재 본 게임은 싱글 플레이어만 전달한다. 멀티 방/접속/호스트 권한/실제 네트워크 동기화는 아직 미구현이다. docs/map-party-position-preview.png는 4인 위치 표시 테스트이며 실제 온라인 접속 화면이 아니다.

## 검증
- tools/map_players_qa.gd: 싱글 4캐릭터의 얼굴, 클릭 통과, 같은 위치 4인 겹침 방지, 다른 위치 분리, 안개 내 숨김, 잘못된 위치, P번호 유지, 공개 상태 불변, 제거 후 잔상 없음.
- tools/map_qa.gd: 200개 시드와 실제 이동·전투·보상 복귀, 시작/이동 후 얼굴 위치 연결.
- 두 검사 실패 0.

## 생성 프롬프트
도구: 내장 image_gen, transparent_background=true. 새 정사각형 head-and-shoulders game portrait for a 64px player-location marker. Face dominant, both eyes open and visible, centered tight bust, elegant detailed anime game painting, clear readable silhouette, true alpha. No full body, scenery, frame, UI, lettering, collage or chibi. 전신 픽셀을 잘라 쓰지 않고 새 독립 초상화 생성.
- 미라: 원본 full_02 얼굴 참조. Violet eyes, dark plum hair, small white rabbit mask, black/lavender gothic outfit, gentle adult face.
- 칼리안: 승인된 builtin_v1 전신 얼굴 참조. Adult male, crimson eyes, silver-white hair, black/gold armor, crimson collar.
- 세라: 미라 원화는 그림체만 참조. Adult female mage, violet eyes, dark violet hair, ornate black-violet witch hat, purple rose, gold filigree collar.
- 루시안: 미라 원화는 그림체만 참조. Adult male priest, brown hair, amber eyes, ivory/black clerical collar, antique gold cross.
