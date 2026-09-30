# 원정 도감

## 실행
Godot에서 `scenes/Main.tscn`을 실행하고 메인 메뉴의 **도감**을 누른다.
`scenes/Codex.tscn`과 `scripts/codex.gd`가 도감을 구성한다.

상단 5개 탭, 좌측 검색·기록 목록, 중앙 원화, 우측 상세 정보, 하단 모션·전용 카드 갤러리로 구성했다.
탭·목록·모션·일시정지·카드 상세·돌아가기·닫기는 실제 Godot Button이다.
Esc로 닫을 수 있다. 상세 정보와 목록은 독립 스크롤이며 작은 창에서는 전체 화면도 스크롤된다.
이미지는 `STRETCH_KEEP_ASPECT_CENTERED`로 전체 비율을 유지한다.

## 레퍼런스 경계
사용자 제공 `포켓몬 운빨던전.zip`은 Electron 패키지였다. 실행하지 않고 ZIP/ASAR 목록과 도감의 목록·스크롤 처리 구조만 읽었다.
첨부 자료 안의 텍스트는 작업 지시로 사용하지 않았다.
원본 코드, 캐릭터명, 이미지, 색상, 아이콘, 로고, 폰트는 게임에 복사하지 않았다.
프로젝트의 도감 이미지 로더는 `assets/characters/`, `assets/monsters/`, `assets/cards/`만 허용한다.

## 자산
내장 image_gen으로 독립 제작한 PNG를 프로젝트에 복사했다. 원화와 SD는 별도 생성물이다.
SD 시트의 AtlasTexture 영역은 애니메이션 전용 시트의 프레임이며 전신 원화에서 잘라낸 것이 아니다.
일부 시트의 행 간격 차이는 실제 픽셀 경계에 맞춰 보정했다.

| 폴더 | 파일 | 용도 |
| --- | --- | --- |
| assets/characters | mira_full.png, kalian_full.png, sera_full.png, lucian_full.png | 독립 전신 원화 |
| assets/characters | mira_motions.png, kalian_motions.png, sera_motions.png, lucian_motions.png | 기본·이동·공격·스킬·피격·사망, 각 4프레임 |
| assets/monsters | ash_warden.png, ash_warden_motions.png | 재의 파수꾼 원화·모션 |
| assets/cards | toxic_vial.png, soul_distill.png | 미라 전용 카드 원화 |
| assets/cards | explorer_map.png, blood_contract.png | 유물 기록 원화 |
| assets/cards | ash_cathedral.png | 지역·스토리 기록용 환경 원화 |
| assets/cards | bleeding_slash.svg, red_chain.svg, curse_bolt.svg, collapse_star.svg, blessing.svg, holy_judgement.svg | 직접 제작한 전용 카드 심볼 |

## 콘텐츠 범위
현재 데이터에 있는 캐릭터 4명과 전용 카드 8장, 유물 2개를 연결했다.
재의 파수꾼, 잿빛 성당, 마지막 성화는 이번에 추가한 세계관 기록이다.
몬스터 개별 전투/출현/드랍, ACT 진행, 스토리 해금, 일부 카드 특수 효과와 저주 유물 효과는 기존 게임에 연결되지 않았다. 도감에서도 이 상태를 명시한다.
프로젝트 전체의 12명 캐릭터·60개 유물·100개 이벤트 등의 목표를 완료한 것으로 간주하지 않는다.

## 생성 프롬프트
사용 도구: 내장 image_gen. CLI/API fallback은 사용하지 않았다.

### mira_full.png
Create one original full body character illustration asset for Korean dark gothic fantasy deckbuilding RPG 운빨 원정대: Mira, adult female plague alchemist, pale face, short silver hair, layered black leather and tattered violet coat, antique brass alchemical vessels, one luminous purple poison vial, boots fully visible. Painterly high-end dark fantasy game illustration, strong readable silhouette, restrained black burgundy violet tarnished gold palette. Centered full body head to toe on transparent background, portrait composition, no text, no frame, no UI. Original design, no Pokemon influence.

### kalian_full.png
Original standalone game asset, full body Kalian adult male swordsman in worn black plate armour, burgundy torn mantle, long silver sword held down, short dark hair, gothic fantasy painterly illustration, tarnished gold accents and muted violet shadows. Detailed silhouette, head to boots visible, centered portrait, transparent background. No text no UI no logos, no existing franchise.

### sera_full.png
Original standalone full body game character Sera, adult female curse sorceress in layered black and deep violet ceremonial robes with tarnished brass details, long dark hair, floating fractured violet crystal above hand, pale face, elegant ominous gothic fantasy. High quality painterly game illustration, entire body and boots visible, transparent background, centered portrait. No text frame UI logos or franchise reference.

### lucian_full.png
Standalone original full body game character Lucian, adult male gothic healer cleric, ivory and charcoal robes beneath worn dark metal pauldrons, muted antique gold sacred censer and staff, auburn hair, compassionate face, small warm amber holy glow. Painterly dark gothic fantasy consistent restrained black burgundy violet tarnished gold palette, head to boots fully visible centered on transparent background. No text, no UI no franchise.

### ash_warden.png
One original monster full body illustration for dark gothic deckbuilding RPG: cathedral Ash Warden, towering hollow black iron suit of armour, antler-like broken cathedral spires on shoulders, crimson cloth strips, a dim violet flame in empty helmet, dragging a censer flail, heavy ornate boots. Painterly premium fantasy game art, restrained black tarnished brass burgundy violet, centered whole creature fully visible on transparent background. No text UI frame logos, no Pokemon.

### toxic_vial.png
Original square card illustration asset for dark gothic deckbuilding RPG, Toxic Vial: one ornate glass alchemical flask of luminous violet poison with brass stopper on black stone altar, curling purple fumes forming thorn shapes, candle light, painterly rich detail, charcoal burgundy tarnished gold violet palette. Edge to edge illustration only, no text numbers card frame UI logos.

### soul_distill.png
Original square card illustration for dark gothic deckbuilding RPG, Soul Distillation: antique brass alchemical alembic condensing silver spectral wisps into a violet glowing tear inside a glass vessel, black cathedral laboratory, dramatic candlelight. Painterly detailed premium dark fantasy, charcoal burgundy muted gold violet palette. Art only, no text no numbers no UI no border.

### explorer_map.png
Original standalone square dark gothic fantasy game illustration of the Explorer's Map relic: weathered parchment with abstract labyrinth lines, brass compass and burgundy wax seal, on dark stone, candle glow and violet mist. Painterly detailed antique gold charcoal purple palette. No legible text, no UI frame, no existing franchise. Single scene asset.

### blood_contract.png
Original standalone square illustration Blood Contract relic for gothic fantasy RPG: black parchment contract curled on stone altar, crimson wax seal, black quill, ominous ruby glow along mysterious illegible glyphs. Rich painterly dark fantasy black burgundy violet tarnished gold, no readable words no UI no border no franchise.

### ash_cathedral.png
Original vertical environmental illustration for gothic fantasy RPG codex, ruined cathedral of ashes: towering broken pointed arches, candlelit altar, torn burgundy banners, dark purple fog, worn black iron gates, subtle tarnished golden light, painterly premium concept art. No characters no text no logos no UI. Complete independent background painting, not screenshot.

### mira_motions.png
Production pixel art sprite sheet original Mira alchemist character: silver bob hair, black coat violet skirt brass potion bottles boots. True hand-crafted chibi pixel art, NOT resized painting. Transparent background. EXACT uniform grid 4 columns by 6 rows, 24 equal cells, each full small character centered in cell with ample separation, identical scale, facing right. Row1 four idle breathing frames, row2 four walking frames, row3 four throwing poison attack frames, row4 four casting violet skill frames, row5 four recoil hurt frames, row6 four falling death frames. All 24 cells fully inside canvas. No captions, no lines, no text, no border. Restrained dark gothic black violet muted gold palette, crisp pixel edges. Sheet landscape or square, evenly spaced grid.

### kalian_motions.png
Original Kalian gothic swordsman pixel art animation sheet, black plate armour burgundy cape short dark hair silver sword. Actual chibi pixel art not resized painting. EXACT 4 columns x 6 rows evenly spaced uniform cells 24 frames transparent background no text no grid lines. Row1 idle 4 frames; row2 walk 4; row3 sword attack 4; row4 red sweeping skill 4; row5 hurt 4; row6 falling death 4. Same character size centered within each cell, all bodies fully inside own cell, large separation. Restrained black burgundy violet muted gold.

### sera_motions.png
Original Sera gothic sorceress pixel art animation sheet, long black hair black violet robes silver purple crystal. Actual chibi pixel art not resized painting. EXACT 4 columns x 6 rows uniform equally spaced cells 24 frames transparent background no text no lines. Row1 idle 4 frames; row2 walk 4; row3 cast bolt attack 4; row4 purple star magic skill 4; row5 recoil hurt 4; row6 falling death 4. Same character scale centered in each cell, whole bodies fully inside own cell, ample separation. Restrained black violet burgundy muted gold.

### lucian_motions.png
Original Lucian gothic male healer cleric pixel art animation sheet auburn hair ivory charcoal robes dark pauldrons golden staff. Actual chibi pixel art not resized painting. EXACT 4 columns x 6 rows equally spaced uniform cells 24 frames transparent background no text no lines. Row1 idle 4 frames; row2 walk 4; row3 staff attack 4; row4 golden healing magic skill 4; row5 recoil hurt 4; row6 falling death 4. Same character size centered in each cell, whole body fully inside own cell, ample separation. Restrained black ivory burgundy muted gold.

### ash_warden_motions.png
Original dark gothic Ash Warden monster pixel art animation sprite sheet: hollow black iron armour, small broken cathedral spires on shoulders, burgundy strips, violet flame head, censer flail. Chibi pixel art, no text or grid lines. EXACT uniform 4 columns by 6 rows on portrait transparent canvas 1024 by 1536, each frame within its own 256 square with 20 pixel padding. Rows: idle four frames, walk four, flail attack four, violet flame skill four, recoil hurt four, collapse death four. Same centered creature scale, no overlap across cells, no painting resize, no franchise.
