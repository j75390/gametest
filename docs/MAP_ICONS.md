# 지도 아이콘 이미지 교체

사용자가 기존 선 아이콘의 가독성과 품질을 지적하여, 장소별로 독립된 투명 PNG 8개를 내장 image_gen으로 새로 제작했다. 다른 게임의 아이콘을 복제하거나 한 시트를 잘라 쓰지 않았다.

파일은 `assets/map/icons/`에 보관하고 기존 SVG 원본은 보존한다. 지도 노드와 상단 범례는 같은 PNG를 참조한다. 최신 사용자 요청에 따라 원형 바탕과 반복 이름을 없앴다. 노드는 64×64, 그림 최대 폭 56픽셀, 범례는 32픽셀이다. 비활성 아이콘도 알파를 낮추지 않고 약간의 색 변화로만 구분한다. 최신 요청에 따라 밑줄도 제거하고 지도에는 아이콘 그림만 표시한다. 이름과 현재 위치는 툴팁에서 확인한다. 경로는 10픽셀 간격의 동일 크기 점으로 그린다.

`tools/map_icon_preview.gd`는 8종을 실제 노드 크기로 렌더링하는 검수 화면이다. `tools/map_qa.gd`는 독립 PNG 연결·투명도·mipmap과 기존 지도 이동 규칙을 함께 검사한다.

최종 Godot 실행: 그래프 200시드 실패 0, UI/아이콘 실패 0. 8종 PNG 모두 투명도와 mipmap 확인. 실제 렌더링 `map-fog.png`, `map-relic.png`, `map-icons-preview.png`에서 원형 바탕 제거 및 축소 표시를 확인했다. 환경의 인증서 저장소 메시지 외 게임 스크립트 오류 없음.

## 생성 프롬프트 구성
공통: standalone transparent PNG location icon for a dark gothic roguelike parchment map; cohesive original hand-painted 2D style, thick near-black contour, bold silhouette, ivory bone/aged gold/charcoal/burgundy palette, minimal detail readable at 48–64px, square canvas, complete silhouette with transparent margin, no environment/background/circular badge/UI/labels/watermark, exactly one icon rather than a sheet.

- battle.png: sinister iron helmet with crossed ivory swords.
- elite.png: ivory beast skull with dark curled horns and crimson eye sockets.
- boss.png: gothic black iron crown above ivory skull, ruby accent.
- shop.png: ochre leather coin pouch with three gold coins.
- rest.png: amber campfire over charred crossed logs.
- treasure.png: dark wooden gold-banded treasure chest, slightly open glowing lid.
- event.png: ivory scroll with large purple question mark.
- camp.png: burgundy expedition tent with ivory opening and gold pennant.
