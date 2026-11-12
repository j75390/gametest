<p align="center"><img src="docs/images/title.svg" alt="잿빛 원정대" width="85%"></p>

성화가 꺼지고 재만 남은 왕국에서, 서로 다른 사정을 안고 모인 원정대원들이 최초의 불씨를 찾아 폐허로 들어가는 다크 고딕 덱빌딩 로그라이크입니다. Godot 4로 만들었습니다.

![Godot](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-55%20files-478CBF)
![Python](https://img.shields.io/badge/Python-tools-3776AB?logo=python&logoColor=white)
![QA](https://img.shields.io/badge/QA%20scripts-54-8B5CF6)

<p align="center"><img src="docs/images/demo.gif" width="80%"></p>

## 목차
1. [프로젝트 소개](#1-프로젝트-소개)
2. [주요 기능](#2-주요-기능)
3. [게임 화면](#3-게임-화면)
4. [세계관과 스토리](#4-세계관과-스토리)
5. [WBS](#5-wbs)
6. [기술 스택](#6-기술-스택)
7. [시스템 구조](#7-시스템-구조)
8. [콘텐츠 데이터](#8-콘텐츠-데이터)
9. [테스트 결과](#9-테스트-결과)
10. [향후 개선 계획](#10-향후-개선-계획)

---

## 1. 프로젝트 소개

### 1.1 프로젝트 소개

잿빛 원정대는 성화(聖火)가 꺼지고 재만 남은 왕국에서, 최초의 불씨를 찾아 폐허로 들어가는 원정대의 이야기를 카드 전투로 풀어낸 다크 고딕 덱빌딩 로그라이크입니다.

제목의 잿빛은 불이 꺼진 뒤 잿빛으로 가라앉은 왕국과 첫 무대인 잿빛 성당에서, 원정대는 한 명의 영웅이 아니라 서로 다른 사정을 안고 모인 원정대원들에서 왔습니다. 플레이어는 연금술사 미라, 이단심문관 세버린, 피리꾼 칼라모, 과자집의 생존자 에스카 중 한 명을 골라 원정을 시작합니다. 원정대원마다 전용 카드 풀과 전투 키워드가 달라서, 같은 지도를 걸어도 덱을 쌓는 방식이 다릅니다.

- 에너지 3으로 손패를 운영하는 턴제 전투입니다. 카드를 끌어 적을 조준하고, 독과 맹독 같은 상태를 쌓아 승부합니다.
- 원정 지도는 연결선 기준으로 앞 두 칸씩만 공개됩니다. 전투, 엘리트, 상점, 이벤트, 휴식, 보물, 보스 노드가 있습니다.
- 전투가 끝나면 카드 보상을 고르고, 상점에서 카드를 사거나 지웁니다. 유물 115종과 포션 15종이 있습니다.
- 이벤트 175개가 지역마다 이야기를 풀고, 도감에는 아직 만나지 못한 기록이 실루엣으로 남습니다.
- 원정대원은 4명이고 각자 전용 카드 풀을 가집니다(미라 88장, 세버린·칼라모·에스카 각 24장). 몬스터는 5개 지역에 46종(보스 5종)입니다.

### 1.2 프로젝트 배경

#### 세계관 배경
성화가 꺼진 뒤 왕국의 길은 밤마다 달라집니다. 어제 묻은 사람이 오늘 문을 두드리고, 돌아온 사람을 가족이 알아보지 못합니다. 살아남은 마을들은 잿빛 성당에서 가져온 불씨로 문턱을 밝혔지만, 불씨가 약해질수록 안개는 더 가까이 옵니다. 성당 안쪽에는 아직 최초의 불이 남아 있다고 하고, 원정대는 그 불을 가져와 마을을 지키기 위해 폐허로 들어갑니다. 원정은 잿빛 성당에서 시작해 검은 운하, 유리온실, 이름없는 서고, 새벽없는 성소로 이어집니다.

#### 제작 배경
- 덱빌딩 로그라이크는 전투 규칙만으로는 완성되지 않습니다. 카드·유물·몬스터 같은 대량의 콘텐츠와 지도, 상점, 이벤트, 도감, 이야기가 한 흐름으로 이어져야 해서, 이 프로젝트는 그 전체를 처음부터 끝까지 만들어 보는 것을 목표로 했습니다.
- 한 캐릭터의 모험이 아니라 원정대원마다 전용 카드 풀, 도트 전투 모션, 휴식 장면, 선택 화면 일러스트를 갖추는 방향으로 설계했습니다.
- 참고작은 정보 구조와 분위기의 참고에만 쓰고, 디자인·이미지·문구는 복제하지 않는 기준으로 모든 에셋을 새로 만들었습니다.
- 콘텐츠가 수백 개로 늘어나면 코드에 직접 적을 수 없어서 JSON 데이터와 콘텐츠 도구로 관리하고, 검수를 통과한 에셋만 내보내도록 했습니다.
- 화면이 웹페이지나 관리 도구처럼 보이지 않도록 UI·카드·지도·도감까지 고딕 분위기로 통일했고, 독·맹독 같은 상태 이상은 플레이어와 몬스터가 같은 시스템으로 다루게 했습니다.

### 1.3 주요 구현 포인트

#### 손패 전투
카드를 부채꼴로 펼치고, 마우스를 올리면 카드 전체와 효과 문구가 올라옵니다. 카드를 끌면 적을 향한 조준선이 그려지고, 숫자키 1~9로도 카드를 고를 수 있습니다. 에너지, 드로우, 버림, 재셔플을 처리하며, 명중 타이밍에 맞춰 돌진·주술·피격 연출이 재생됩니다.

#### 공통 상태 시스템
독과 맹독을 별개의 상태로 나눴습니다. 독은 중첩 수만큼 방어를 무시하고 피해를 준 뒤 1씩 줄고, 맹독은 최대 HP의 8%를 정해진 턴 동안 줍니다. 두 상태가 동시에 걸려도 따로 줄고 따로 풀립니다. 플레이어와 몬스터가 같은 `UnitStatus`를 쓰고, 툴팁에는 실제 적용 비율과 다음 피해가 표시됩니다.

#### 안개 지도
연결선 기준으로 두 번 이동할 수 있는 범위까지만 공개하고, 이미 공개한 분기와 지나온 길은 그대로 남깁니다. 탐험가의 지도 유물을 얻으면 현재 ACT 전체가 공개되고, 현재 위치는 선택한 캐릭터의 얼굴 마커로 표시됩니다.

#### 데이터 중심 콘텐츠
카드, 유물, 포션, 몬스터, 이벤트, 상태는 코드가 아니라 JSON으로 관리합니다. Python으로 만든 콘텐츠 도구가 원본(`content.json`)을 검증하고 게임이 읽는 `catalog.json`으로 내보내며, 승인되지 않은 에셋은 내보내기에서 막습니다.

#### 도감
아직 만나지 못한 항목은 이름, 설명, 등급, 툴팁을 숨기고 실루엣만 보여 줍니다. 검색과 필터에서도 숨긴 정보가 새지 않도록 했고, 공개 조건(플래그, 유물)이 걸린 기록은 조건을 채우면 열립니다.

#### 자동 저장
원정 지도가 나올 때마다(전투나 이벤트 도중이 아니라 방과 방 사이에) 진행 상황을 자동으로 저장하고, 원정이 끝나면 지웁니다. 점검 스크립트는 실제 저장 파일을 건드리지 않도록 막아 두었고, 도감에서 발견한 기록도 따로 파일로 저장됩니다.

#### 오디오
BGM은 샘플 음원이 아니라 Python(numpy) 스크립트로 작곡해서 루프 이음새가 끊기지 않게 만들었고, BGM 에셋을 점검하는 스크립트도 있습니다.

---

## 2. 주요 기능

### 진행 흐름

```mermaid
flowchart LR
    A["타이틀"] --> B["원정대원 선택"]
    B --> C["ACT 시작 이벤트<br/>(시작 보상)"]
    C --> D["원정 지도"]
    D --> E["전투 · 엘리트"]
    E --> R["카드 보상"]
    R --> D
    D --> S["상점<br/>카드 구매·제거"]
    S --> D
    D --> V["이벤트"]
    V --> D
    D --> F["휴식"]
    F --> D
    D --> T["보물"]
    T --> D
    D --> Z["보스"]
    Z --> N["다음 ACT"]
```

<details>
<summary><b>1. 타이틀과 원정대원 선택</b></summary>

타이틀에서 싱글·멀티·도감·설정으로 들어갑니다. 원정대원 선택 화면에서는 캐릭터의 HP, 소지금, 에너지, 시작 유물을 보고 원정을 시작합니다. 미라의 시작 유물 빛바랜 초승달은 매 전투 시작 시 방어도 3을 줍니다.

<img src="docs/screens/01-title.jpg" width="48%"> <img src="docs/screens/02-select.jpg" width="48%">
</details>

<details>
<summary><b>2. 손패 전투</b></summary>

기본 덱은 공격 5장과 방어 5장입니다. 카드를 끌어 적에게 놓으면 조준선이 나오고, 공격 카드는 피해량을 미리 보여 줍니다. 상태 이상은 HP바 아래 아이콘으로 표시되고 툴팁에 효과가 나옵니다. 화면 위쪽의 포션 벨트(3칸)에서 전투 중에 포션을 씁니다.

<img src="docs/screens/06-battle-aim.jpg" width="48%"> <img src="docs/screens/07-battle-preview.jpg" width="48%">

<img src="docs/screens/09-poison-venom.jpg" width="48%"> <img src="docs/screens/10-deck.jpg" width="48%">
</details>

<details>
<summary><b>3. 원정 지도</b></summary>

앞으로 두 칸까지만 공개되는 안개 지도이고, 금빛 길은 지나온 경로입니다. 탐험가의 지도 유물을 얻으면 현재 ACT 전체가 열립니다.

<img src="docs/screens/04-map.jpg" width="48%"> <img src="docs/screens/05-map-reveal.jpg" width="48%">
</details>

<details>
<summary><b>4. 보상 · 상점 · 휴식</b></summary>

전투를 이기면 전용 카드 3장 중 1장을 고르거나 넘길 수 있고, 엘리트는 유물 3개 중 1개도 고릅니다. 상점은 카드·유물·포션을 3개씩 진열하고, 골드로 사거나 덱에서 카드를 지울 수 있으며 지울 때마다 값이 올라갑니다(75골드, 125골드). 휴식에서는 체력을 회복하거나 카드 1장을 강화합니다.

<img src="docs/screens/11-reward.jpg" width="48%"> <img src="docs/screens/12-reward-elite.jpg" width="48%">

<img src="docs/screens/13-shop.jpg" width="48%"> <img src="docs/screens/14-rest.jpg" width="48%">
</details>

<details>
<summary><b>5. ACT 시작과 이벤트</b></summary>

각 ACT는 이야기 장면으로 시작합니다. ACT I에서는 문지기 에델이 시작 보상(골드, 최대 생명력, 전용 카드 중 하나)을 건넵니다. 이벤트는 상황 글과 2~4개의 선택지로 이루어지고, 선택에 따라 카드 추가·강화, 체력 증감 같은 결과가 따라옵니다.

<img src="docs/screens/03-act-arrival.jpg" width="48%"> <img src="docs/screens/15-event.jpg" width="48%">

<img src="docs/screens/16-event-effects.jpg" width="48%">
</details>

<details>
<summary><b>6. 도감</b></summary>

캐릭터, 카드, 유물, 몬스터, 포션, 인챈트, 이벤트, 파워, 지역, 스토리 탭이 있고 이름 검색과 등급·종류 필터를 쓸 수 있습니다. 첫 화면에는 도감 완성률과 발견한 항목 수가 나오고, 만나지 못한 항목은 실루엣으로만 보입니다.

<img src="docs/screens/17-codex-hub.jpg" width="48%"> <img src="docs/screens/18-codex-cards.jpg" width="48%">

<img src="docs/screens/19-codex-hidden.jpg" width="48%">
</details>

<details>
<summary><b>7. 지역 조사 지도</b></summary>

지역마다 장소가 표시된 조사 지도가 있고, 장소를 누르면 그곳에서 얻은 기록이 나옵니다.

<img src="docs/screens/20-atlas.jpg" width="96%">
</details>

<details>
<summary><b>8. 콘텐츠 도구</b></summary>

`tools/content_tool`은 카드·유물·포션·몬스터·이벤트를 검증하고 게임용 `catalog.json`으로 내보내는 Python 도구입니다. 브라우저로 여는 로컬 웹 화면에서 사람이 편집하고, 스크립트는 REST API와 명령줄로 같은 원본을 고칩니다. 외부 패키지 없이 Python 3만 있으면 돌아갑니다. 에셋은 draft, generated, needs_review, approved, rejected 상태를 가지며 승인된 것만 내보냅니다.
</details>

---

## 3. 게임 화면

<p align="center"><img src="docs/screens/01-title.jpg" width="48%"> <img src="docs/screens/02-select.jpg" width="48%"></p>
<p align="center"><img src="docs/screens/04-map.jpg" width="48%"> <img src="docs/screens/06-battle-aim.jpg" width="48%"></p>
<p align="center"><img src="docs/screens/08-battle-hit.jpg" width="48%"> <img src="docs/screens/09-poison-venom.jpg" width="48%"></p>
<p align="center"><img src="docs/screens/13-shop.jpg" width="48%"> <img src="docs/screens/14-rest.jpg" width="48%"></p>
<p align="center"><img src="docs/screens/17-codex-hub.jpg" width="48%"> <img src="docs/screens/20-atlas.jpg" width="48%"></p>

---

## 4. 세계관과 스토리

원정대원은 모두 불씨 말고도 안고 온 것이 있습니다.

| 원정대원 | 직업 | 전투 키워드 | HP | 원정에 나선 이유 |
|---|---|---|---|---|
| 미라 | 연금술사 | 독 · 연금술 · 흡수 · 저주 | 72 | 지워진 이름들과 자신의 과거를 찾습니다. 십 년 전 자신이 치료했다는 사람들의 이름입니다. |
| 세버린 | 이단심문관 | 죄목 · 판결 · 약화 | 84 | 수백 장의 판결문에 도장을 찍은 끝에 마지막 한 장에서 자기 이름을 발견하고 성당으로 향합니다. |
| 칼라모 | 피리꾼 | 쥐 · 소환 · 군집 | 76 | 쥐를 쫓아 준 대가로 약속된 값을 받아 내려고 도시를 따라 걷습니다. |
| 에스카 | 과자집의 생존자 | 불씨 · 화덕 · 폭발 | 80 | 배고픔과 불 냄새를 잊지 못한 채 마지막 빵을 굽습니다. |

| ACT | 지역 | 몬스터 | 이벤트 |
|---|---|---|---|
| I | 잿빛 성당 | 13 | 42 |
| II | 검은 운하 | 9 | 34 |
| III | 유리온실 | 8 | 31 |
| IV | 이름없는 서고 | 8 | 32 |
| V | 새벽없는 성소 | 8 | 36 |

미라의 이야기는 기록에서 지워진 이름을 따라갑니다. 이름을 어디까지 알려 줄지는 공개 순서로 관리해서, 선택 화면에는 동기만 보이고 진실은 지역을 지날 때마다 도감과 이벤트 기록으로 하나씩 열립니다. 현재 ACT I부터 IV까지 구현했고 ACT V는 데이터만 있습니다.

---

## 5. WBS

[WBS 이미지](docs/images/spec/wbs-1.png)

<details>
<summary><b>WBS</b></summary>

<img src="docs/images/spec/wbs-1.png" width="100%">
</details>

---

## 6. 기술 스택

| 구분 | 기술 | 용도 |
|---|---|---|
| Engine | Godot 4.7 (GL Compatibility) | 게임 실행, 화면 구성, 1440×900 기준 UI |
| Language | GDScript | 전투, 지도, 상점, 휴식, 이벤트, 도감, 설정(스크립트 55개) |
| Data | JSON / `catalog.json` | 카드, 유물, 포션, 몬스터, 이벤트, 상태 |
| Tools | Python | 콘텐츠 도구(검증·내보내기), 에셋 일괄 생성·검수, BGM 작곡 |
| Art | ComfyUI (SDXL) · 이미지 생성 도구 | 캐릭터, 카드, 몬스터, 유물, 이벤트, 지도 일러스트(검수 후 적용) |
| Audio | numpy | 루프 BGM 절차 작곡 |
| Save | `user://` JSON·variant 저장 | 원정 자동 저장, 도감 발견 기록 |
| Editor | Godot AI(MCP) 애드온 | 에디터 연동 작업 |
| VCS | Git / GitHub | 형상 관리 |

---

## 7. 시스템 구조

```mermaid
flowchart TB
    subgraph Data["데이터"]
        J["data/*.json"]
        C["catalog.json"]
    end
    subgraph Tool["콘텐츠 도구 (Python)"]
        CT["content.json<br/>검증 · 내보내기"]
    end
    CT --> C
    C --> GD["game_data.gd"]
    J --> GD
    subgraph Game["게임 (GDScript)"]
        M["main.gd"] --> TM["title_menu"]
        TM --> CS["character_select"]
        CS --> EM["expedition_map"]
        EM --> BS["battle_scene"]
        EM --> SH["shop_view"]
        EM --> RV["rest_view"]
        EM --> EV["event / reward"]
        TM --> CX["codex"]
        BS --> US["unit_status<br/>relic_engine"]
    end
    GD --> M
```

```txt
scripts/    # 화면과 규칙(전투, 손패, 지도, 상점, 휴식, 도감, 상태, 유물)
scenes/     # Main.tscn, Codex.tscn
data/       # 게임이 읽는 JSON
assets/     # 캐릭터, 카드, 몬스터, 유물, 이벤트, UI, 지도, 배경, 오디오
tools/      # 콘텐츠 도구, 에셋 일괄 처리, QA 스크립트(*_qa.gd)
docs/       # 설계 문서, 화면 기록
```

---

## 8. 콘텐츠 데이터

[콘텐츠 이미지](docs/images/spec/content-1.png)

<details>
<summary><b>콘텐츠 현황</b></summary>

<img src="docs/images/spec/content-1.png" width="100%">
</details>

---

## 9. 테스트 결과

전투, 손패, 지도, 상태, 이야기 기록은 Godot 실행기로 돌리는 점검 스크립트 54개로 확인합니다(`Godot --path . --script res://tools/<이름>_qa.gd`). 화면 캡처가 필요한 점검은 헤드리스가 아니라 실제 렌더링으로 실행합니다.

<details>
<summary><b>점검 결과</b></summary>

<img src="docs/images/spec/qa-1.png" width="100%">
</details>

---

## 10. 향후 개선 계획

### 1. 캐릭터 확장

- 현재: 원정대원 4명 모두 전용 카드 풀과 도트 전투 모션을 갖췄지만, 카드 수는 미라가 88장, 나머지 세 명이 24장씩입니다.
- 개선: 세버린·칼라모·에스카의 카드 풀과 이벤트를 넓혀 캐릭터마다 빌드가 갈리는 깊이를 미라 수준으로 맞춥니다.

### 2. ACT V 구현

- 현재: 새벽없는 성소의 몬스터 8종과 이벤트 36개는 데이터로 있지만 플레이 흐름에는 연결하지 않았습니다.
- 개선: 마지막 지역과 결말을 연결하고, 미라의 이름 이야기를 마무리합니다.

### 3. 밸런스와 전체 검증

- 현재: 점검 스크립트는 기능 단위로 통과했지만 전체 재실행과 실제 플레이 밸런스는 확인하지 못했습니다.
- 개선: 점검을 한 번에 돌리는 실행기를 만들고, 한 판을 끝까지 플레이한 기록으로 카드·몬스터 수치를 조정합니다.

### 4. 멀티플레이

- 현재: 멀티 화면은 골격만 있고 네트워크 기반이 없습니다.
- 개선: 호스트가 결과를 한 번 판정해 공유하는 구조로, 공동 이벤트와 개인 이벤트를 나눠 구현합니다.

### 5. 유물 확충

- 현재: 유물 115종입니다.
- 개선: 일반, 고급, 희귀, 영웅, 전설과 캐릭터마다 하나씩 주는 고대 유물을 더해 154종을 목표로 합니다.
