"""Build human review documents from the same authoring records used by the game."""
import json
from pathlib import Path
R=Path(__file__).resolve().parents[1];D=json.loads((R/'tools/content_tool/data/content.json').read_text(encoding='utf-8'));OUT=R/'docs/text-review';OUT.mkdir(exist_ok=True)
def ready(k):return [x for x in D[k] if x.get('text_ready') and not x.get('archived')]
def stage(r):return {'playable':'게임 적용 · 문구 검수 가능','manuscript':'후반 진행 원고','proposal':'효과/수치 검수안 · 미구현'}.get(r.get('implementation'),'검수안')
def save(name,rows): (OUT/name).write_text('\n\n'.join(rows)+'\n',encoding='utf-8')
rows=['# 성화가 기억하는 이름 — 스토리·지역 검수 원고','후반부·결말 스포일러 포함. 현재 실제 전투 진행은 ACT I까지입니다. 일러스트는 추가하지 않았습니다.','## 이야기의 중심','고통을 없앤다고 믿은 치료는 고통을 다른 수령인에게 옮기는 방식이었다. 성당은 기록하고, 운하는 운반하고, 온실은 약으로 만들고, 서고는 이름을 지우고, 성소는 부담을 배분했다. 미라는 잊게 만드는 약의 안정화에 참여했다. 이제 자신의 서명을 지우는 대신 환자가 어디로 갔는지 찾아간다.\n\n백색막은 인간의 의도를 심판하지 않는다. 사람들은 설명할 수 없는 현상을 이용해 제도를 만들었고, 그 제도가 위험과 거짓을 키웠다. 괴이함은 유지하되 모든 문제를 악신 하나의 명령으로 정리하지 않는다.']
for r in ready('regions'):rows += [f"## ACT {r['act']} · {r['name']}",r['description'],r['runtime']['notes']]
rows += ['## 세계와 인물의 기록']
for r in ready('lore'):
    if not r['id'].startswith('evidence_'):rows += [f"### {r['name']}",r['description']]
save('01-story-regions.md',rows)
rows=['# 유물 154종 검수 원고','일반60 · 고급40 · 희귀25 · 영웅12 · 전설5 · 고대12. 현재 실제 효과가 있는 유물은 기존3+신규6=9종입니다. 나머지145종의 효과와 수치는 제안이며 자동으로 보상 풀에 들어가지 않습니다.','고대 유물은 캐릭터당 하나이며 해당 개인 연속 사건에서만 획득하는 설계입니다. 모든 원고는 사용자 검수 대기입니다.']
for rarity in ['일반','고급','희귀','영웅','전설','고대']:
    rows += ['## '+rarity]
    for r in ready('relics'):
        if r['rarity']!=rarity:continue
        rows += [f"### {r['name']} · `{r['id']}`",f"**효과:** {r['effect']}",f"**기록:** {r['flavor_text']}",f"{stage(r)} · 적용 범위 {r.get('scope','PERSONAL')} · {r.get('stacking','UNIQUE_PER_OWNER')}"]
        if r.get('origin_event'): rows += ['연결 사건: `'+r['origin_event']+'` · '+r['character_restriction']+' 전용']
save('02-relics.md',rows)
for filename,cat,title in [('03-common-events.md','COMMON','공통 이벤트 100편'),('04-character-events.md','CHARACTER','개인 이벤트 72편')]:
    rows=['# '+title,'선택 결과까지 포함한 검수용 원고입니다. ACT I 공통20편만 현재 플레이에 연결됩니다. 개인72편과 후반 공통80편은 조건·결과가 작성된 원고이며 아직 플레이에 투입되지 않습니다.']
    for r in ready('events'):
        if r['category']!=cat:continue
        rows += [f"## {r['title']} · ACT {r['act']} · `{r['id']}`",r['story']]
        if r.get('character_restriction'): rows += ['전용: '+r['character_restriction']+' · 유형: '+r.get('runtime',{}).get('encounter_tier','')]
        req=r.get('runtime',{}).get('requires_flags',[])
        if req:rows+=['필요 기록: '+', '.join('`'+x+'`' for x in req)]
        for c in r['choices']:rows += [f"- **{c['name']}** — {c.get('description','')}\n  - 결과: {c.get('reply','')}"]
    save(filename,rows)
rows=['# 포션 20종 신규 원고','기존 회복약은 유지합니다. 신규3종은 상점 즉시 회복으로 연결되며, 나머지17종은 전투 포션 설계입니다. 포션 보관·전투 중 사용은 이번에 구현하지 않았습니다.']
for r in ready('potions'):rows += ['## '+r['name'],r['effect'],r['flavor_text'],stage(r)]
save('05-potions.md',rows)
rows=['# 상태 원고 300종','기존 원본을 보존하고 제작 도감에 옮겼습니다. 42종은 규칙을 구체화했습니다. 현재 전투에 적용되는 중독·맹독·출혈·저주 증폭 4종은 기존 구현을 유지합니다. 아래 300항목을 신규300기능 구현으로 계산하지 않습니다.']
for r in ready('powers'):rows += [f"## {r['name']} · `{r['id']}`",'구분: '+r.get('design_group','')+' · 중첩: '+r['stack_mode'],r['tooltip']]
save('06-statuses.md',rows)
readme='''# 글 원고 검수 안내

게임 메인 메뉴 → 도감 → 왼쪽 아래 **원고 검수 ↗**를 누르면 별도 화면에서 원고를 모두 읽을 수 있습니다. 돌아가면 원래 도감의 목록과 선택이 유지됩니다. 이미지 없는 항목은 본문을 넓게 표시합니다.

| 원고 | 수량 | 현재 적용 |
|---|---:|---|
| [스토리·지역](01-story-regions.md) | 5지역 · 3결말 · 인물/세계 기록 | ACT I 장부 장면과 조사 해금, 후반은 원고 |
| [유물](02-relics.md) | 154종 | 9종 실제 효과, 145종 설계 |
| [공통 이벤트](03-common-events.md) | 100편 | ACT I 20편, 후반80편 원고 |
| [개인 이벤트](04-character-events.md) | 72편 | 12명×6편, 전부 원고 |
| [새 포션](05-potions.md) | 20종 | 즉시 회복3종, 전투형17종 원고 |
| [상태](06-statuses.md) | 기존300종 | 42종 규칙 구체화, 전투 구현4종은 별도 유지 |

검수 우선순위는 이야기의 인과관계 → 미라 개인6편 → 유물의 기록문과 효과 → 이벤트 대가/보상 → 상태의 계산 규칙입니다. 수치와 문구는 모두 변경 가능한 초안입니다.

ACT I의 사건이 남기는 단서는 고른 선택에 따라 다릅니다. 무료로 떠나는 선택이 있으며, HP 비용으로 죽거나 같은 유물을 재구매할 수 없습니다. 파수꾼 뒤의 이송 장부는 임의 이벤트를 만나지 않아도 발견합니다. 해당 장면을 읽은 뒤 검은 운하의 지역 기록이 열리지만, ACT II 전투로 진행되지는 않습니다.

원본 데이터는 Content Tool의 `data/content.json`, 게임이 읽는 파일은 내보낸 `data/content_tool/catalog.json`입니다. 이 문서는 그 원본에서 생성한 읽기용 사본입니다. 원고 이미지·새 일러스트는 제작하지 않았습니다.
'''
(OUT/'README.md').write_text(readme,encoding='utf-8')
print('Review documents:',len(list(OUT.glob('*.md'))))
