# 잿빛 원정대 시작 화면

2026-10-01. 사용자 고딕 폐허 참고 이미지의 분위기를 반영해 배경을 새로 생성했다. 참고 화면을 잘라 쓰거나 UI 전체 이미지 위에 투명 버튼을 얹지 않았다.

- 배경: assets/backgrounds/title_ruins_v1.png
- UI: scripts/title_menu.gd. 실제 제목 Label과 5개 Button, 키보드 포커스/hover, 중심 비율 배치. 배경은 비율 유지 cover, UI는 1440×900 기준 균등 축소.
- main.gd에서 기존 싱글/멀티/도감/설정/종료 기능에 연결. 다른 화면 진입 시 메뉴를 제거하고 기존 shell 복구. 도감은 메뉴 위에 열고 닫는다.
- 제목 잿빛 원정대. 멀티/설정은 기존 골격이며 기능 완성으로 주장하지 않는다.
- SystemFont Batang → Noto Serif CJK KR → serif 순서로 사용한다. PC 설치 글꼴에 따라 형태가 달라질 수 있다.

검증: Godot 4.7.2 실제 렌더링 tools/title_menu_qa.gd. 1440×900, 1280×720, 1920×1080 버튼 영역 및 화면 캡처, 마우스 싱글/멀티/도감/설정 전환, 선택 뒤 메뉴 복귀. TITLE_MENU_QA resolutions=3 routes=4 failures=0. 종료 버튼은 get_tree().quit에 연결했으며 이 자동 검사의 클릭 대상에서는 제외했다. 최초 검사는 해상도 변경 후 입력 좌표 변환 문제로 실패했고 viewport-local 좌표 입력으로 수정 후 통과했다.

생성 도구: 내장 image_gen. 원본 exec-450e4d6a-d20a-4b44-9328-3314c99900ae.png를 수정 없이 프로젝트에 복사.

프롬프트:
Create an original 16:9 cinematic dark gothic fantasy game main menu BACKGROUND ONLY, no text, no logo, no menu, no buttons. High quality painterly environment: ruined cathedral arch dominating center, hooded stone knight statue and candles on left, distant castle on cliffs and large moon upper right, wet stone stairs, burgundy torn banners, tangled branches, drifting blue teal mist, subtle warm gold candle accents. Center upper-middle and center lower-middle must stay dark and quiet to overlay title and five real menu buttons. Rich environmental detail concentrated edges, atmospheric depth, dark blue black palette. Entire coherent landscape, not a screenshot. Landscape 1536x864 or wider.
