# 미라 세로 카드 손패 — 2026-10-02

사용자가 기존 손패가 카드 형태가 아닌 정보 패널처럼 보인다고 지적했다. 기존 192×220 패널/VBox 구조를 220×330 세로 카드로 교체했다.

## 실제 적용
- scripts/battle_card.gd: 독립 금속 카드 프레임, 큰 일러스트, 좌상단 정수 에너지, 이름, 별도 타입/등급 띠, 양피지 효과 설명, 캐릭터 제한·강화 여부. 효과는 GameData.effect_text의 원본 수치를 그대로 사용한다. 카드 아트와 밸런스 데이터는 바꾸지 않았다.
- scripts/battle_hand.gd: 부채꼴 회전과 겹침, hover 시 앞으로 상승/확대/정렬. 겹친 카드의 회전·크기를 역변환하여 최상단 실제 카드 영역을 판정한다. 기존 드래그/클릭 대상 선택/취소/자기 카드/입력 잠금 동작 유지.
- main.gd: 미라 전투에서 상단 큰 제목·프로토타입 꼬리말·중복 적 요약을 숨기고 손패 공간 확보. 다른 화면 진입 시 원래 레이아웃 복구. 다른 캐릭터 전투 UI는 이번 범위가 아니다.
- 새 UI 자산 assets/ui/cards/gothic_frame_v1.png. 배경과 일러스트 창에 실제 알파가 있는 1024×1536 PNG. 내장 image_gen으로 독립 제작해 전체 이미지를 사용한다. 참고 게임의 카드 프레임을 잘라 쓰지 않았다. 작은 아이콘 반복 생성이 아니라 주요 카드 UI 프레임 작업이다.
- 상태: approved. 근거는 독립 프레임/투명도 확인, 실제 전투에서 비용·이름·효과 위치와 두 해상도 시각 검수. 원본 게임 콘텐츠 레코드를 일괄 승인한 것은 아니다.

## 검증
Godot 4.7.2 실제 렌더링:
- CARD_SHAPE_QA resolutions=2 failures=0: 1440×900/1280×720, 세로 비율, 효과 영역 넘침, 정수 비용, 겹침/회전, hover 전면/정렬, 화면 복구.
- MIRA_HAND_QA failures=0: 드래그 확정, 대상 밖 드롭, 클릭 후 대상 선택, 우클릭/ESC, 방어, 에너지 부족, 툴팁.
- MIRA_HIT_QA failures=0: 명중 시점/중복 입력/피격/복귀 및 기존 타격 회귀.
- 캡처 docs/card-hand-1440.png, card-hand-1280.png 및 갱신한 mira-hand/mira-hit 화면.

미완성 범위: 실제 전투 배경·효과음·다른 캐릭터 전용 손패·다중 적 조준은 그대로다. 기본 공격/방어는 기존 전용 심볼이며, 모든 카드 일러스트를 새로 제작한 작업은 아니다.

## 생성 기록
도구: 내장 image_gen, transparent_background=true. 원본 exec-6fe3d35c-361e-4ef6-b5b9-c10a34799ac0.png를 복사했다.

프롬프트: One standalone original dark gothic fantasy collectible playing card FRAME asset, portrait 2:3 ratio. This is a physical illustrated deckbuilding card with clipped corners, thick blackened silver and antique gold sculpted perimeter, subtle violet enamel, symmetrical intricate gothic metal filigree. Large EMPTY transparent illustration window in upper middle between 18% and 60% height. Solid dark ivory parchment effect text panel lower middle 66%-89%, blank no writing. A narrow blank dark metal name ribbon at top 8%-17%. Small round antique gold energy medallion at top left, EMPTY center no number. Bottom small blank violet ribbon 91%-96%. Keep ornaments restrained for legibility at 210x315 pixels. True transparent background outside card and in illustration window; parchment text panel and frame opaque. No letters, no words, no numbers, no illustration, no mockup, no hands, no scene, no multiple cards or sheet. Frame fills nearly entire canvas with a tiny margin.
