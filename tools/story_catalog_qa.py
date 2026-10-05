"""Contract checks for authored content and the single runtime export."""
from pathlib import Path
import collections,copy,hashlib,json,sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/content_tool'))
import content_tool as ct
from godot_bridge import export_catalog
D=ct.load_data();C=json.loads((ROOT/'data/content_tool/catalog.json').read_text(encoding='utf-8'))
ready=lambda k:[r for r in D[k] if r.get('text_ready') and not r.get('archived')]
assert len(ready('relics'))==154
assert collections.Counter(r['rarity'] for r in ready('relics'))=={'일반':60,'고급':40,'희귀':25,'영웅':12,'전설':5,'고대':12}
assert len({r['name'] for r in ready('relics')})==154
common=[e for e in ready('events') if e['category']=='COMMON'];personal=[e for e in ready('events') if e['category']=='CHARACTER']
assert len(common)==100 and collections.Counter(e['act'] for e in common)=={i:20 for i in range(1,6)}
assert len(personal)==72 and set(collections.Counter(e['character_restriction'] for e in personal).values())=={6}
assert len(ready('powers'))==300 and len(ready('regions'))==5 and len(ready('potions'))==20
assert len([p for p in ready('powers') if p.get('rule_review')=='specified'])==42
assert len(C['relics'])==9 and len(C['powers'])==4 and len(C['potions'])==4
assert len([e for e in C['events'] if e.get('pool')=='common'])==20
assert not any(r['rarity']=='고대' for r in C['relics'])
for r in ready('relics'):
    assert r.get('text_review_state')=='pending_user'
    if r['rarity']=='고대':
        event=next(e for e in personal if e['id']==r['origin_event'])
        assert event['character_restriction']==r['character_restriction']
        assert event['runtime']['requires_flags']
        assert any(c.get('relic')==r['id'] for c in event['choices'])
        assert not r['runtime']['shop'] and not r['runtime']['ordinary_drop']
    if r['approval_state']=='approved':assert r['implementation']=='playable'
for region in ready('regions')[1:]:assert region['implementation']=='manuscript'
for k,items in D.items():
    assert len({r['id'] for r in items})==len(items),(k,'duplicate ID')
    for item in items:assert not ct.validate_item(k,item),(k,item['id'])
# All review references resolve to the same authoritative records.
map_k={'지역':'regions','이벤트':'events','유물':'relics','스토리':'lore','파워':'powers'}
for k,items in D.items():
    for item in items:
        if not item.get('text_ready'):continue
        for link in item.get('runtime',{}).get('related',[]):
            group,id=link.split(':',1)
            if group in map_k:assert any(r['id']==id for r in D[map_k[group]]),link
# Every cost/reward target used in a playable event must be executable, and leaving is free.
relic_ids={r['id'] for r in C['relics']}
for e in C['events']:
    if e.get('pool')!='common':continue
    assert e['act']==1
    assert all(c.get('relic') in relic_ids for c in e['choices'] if c.get('relic'))
    assert any(not any(c.get(k,0) for k in ('hp_cost','gold_cost','requires_flags','relic')) for c in e['choices'])
# Failed export never replaces the good catalog; text-only is not an art-validation bypass for cards.
path=ROOT/'data/content_tool/catalog.json';before=hashlib.sha256(path.read_bytes()).hexdigest()
bad=copy.deepcopy(D);bad['cards'][0]['image']='';bad['cards'][0]['text_only']=True
try:export_catalog(bad,ROOT)
except ValueError:pass
else:raise AssertionError('Image-less approved card accepted')
assert hashlib.sha256(path.read_bytes()).hexdigest()==before
assert set(C['_library'])==set(D)
print('STORY_CATALOG_QA PASS: 154 relics / 100 common + 72 personal events / 5 regions / 20 new potions / 300 status drafts (42 detailed), valid links, no ancient drops, atomic export')
