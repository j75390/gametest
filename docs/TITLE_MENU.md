# 잿빛 원정대 시작 화면

## v2 — 로고와 메뉴 장식 재제작
메뉴 강조 수정: 마우스가 진입한 버튼으로 키보드 포커스도 이동한다. 마우스가 벗어나도 마지막 선택을 유지하며 싱글 플레이로 되돌아가지 않는다. tools/title_focus_qa.gd 실제 입력 검사 통과.
사용자가 v1의 얇은 폰트/사각 버튼을 거부하여 내장 image_gen으로 독립 투명 PNG 두 개를 새로 제작했다. assets/ui/title/ashen_logo_v2.png는 정확한 제목 잿빛 원정대의 은색 금속 로고, menu_frame_v2.png는 글자 없는 금색 가시 장식 버튼이다. 원본 전체 이미지를 사용하며 참고 화면을 자르지 않았다. 배경/로고/메뉴 프레임/실제 버튼 글자를 분리한다. 영문 부제 및 하단 문구를 제거하고 1600×900 디자인 기준으로 배치했다. 마우스 hover 또는 키보드 포커스에 청록색 가산 광채를 적용한다. PNG mipmap 활성화.

실제 렌더링에서 원본 크기로 커지는 로고 오류를 수정했다. 세 해상도/메뉴 네 경로/복귀 검사 0 실패. 최신 화면은 title-menu-v2-1440.png, -1280.png, -1920.png. 창 크기 변경 후 안정화 시간을 주어 입력 검증을 보정했고 PNG 저장 결과도 검사한다. 원래 v1 캡처는 역사 기록이다. 시스템 글꼴은 메뉴 글자에만 사용한다. 종료와 멀티/설정 미완성 제한은 아래와 같다.

생성 원본 ID: 로고 exec-9eb70e85-008f-43ed-bbba-acd5c487b5a0, 버튼 exec-d09dc276-fc1d-40cb-b651-e0b268a3d4e2. 둘 다 내장 도구, transparent_background=true.

로고 프롬프트: Generate ONE isolated transparent game title logo asset. Exact Korean text "잿빛 원정대" in ONE horizontal line, accurately spelled, no other text. Massive thick custom gothic Hangul lettering, sculpted chipped silver metal, beveled sharp engraved edges, ivory moonlit face and deep charcoal extruded shadows. Ornate crescent moon and thorned heraldic compass emblem above centered lettering, entwined black thorn branches below and subtle cyan spectral glow accents. AAA dark gothic fantasy title treatment, imposing and intricate not a thin font. Wide landscape composition approximately 2:1, entire logo fills canvas with small transparent margins. True transparent background, no scenery, no frame rectangle, no menu, no watermark.

버튼 프롬프트: ONE isolated game menu button frame asset, no words no letters. Very wide short horizontal gothic blackened metal plaque, aspect 6:1. Tarnished gold thin double beveled outline, clipped spearpoint ends, elegant symmetrical sharp thorn filigree ornaments protruding at far left and right tips, small diamond jewel each tip. Interior nearly black subtly textured blue metal, unobstructed empty center for white Korean menu label. High end dark fantasy RPG UI art. The plaque occupies almost the whole wide canvas edge to edge, minimal transparent padding. Orthographic straight front view. True transparent background outside the plaque. Only one button, no sheet, no mockup, no scenery, no shadows far outside, no text.

## v1 기록

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
