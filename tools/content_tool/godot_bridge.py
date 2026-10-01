"""Content Tool authoring -> one validated, atomic Godot runtime catalog."""
import copy
import hashlib
import json
from pathlib import Path

KINDS = ['cards','relics','potions','enchants','powers','monsters','events']
ALIASES = {'enchants':'enchantments'}

def runtime_item(kind, item):
    row = copy.deepcopy(item.get('runtime', {}))
    for key in ('id','name','rarity','type','character','target','keywords','effect','act','hp','choices'):
        if key in item: row[key] = copy.deepcopy(item[key])
    row['art'] = item.get('image', item.get('icon', ''))
    if kind == 'cards':
        row['cost'] = item['energy_cost']
        if isinstance(row.get('keywords'),str):row['keywords']=[x.strip() for x in row['keywords'].split(',') if x.strip()]
        row.setdefault('effect',item['description'])
    elif kind == 'monsters':
        row['type'] = {'NORMAL':'일반','ELITE':'엘리트','BOSS':'보스'}[item['rank']]
        row['pattern'] = item['attack_pattern']
        row['effect'] = item['description']
        row['powers'] = item.get('powers',[])
    elif kind == 'events':row.update(name=item['title'],effect=item['story'])
    elif kind == 'relics':row['cursed'] = item.get('curse_tag',False)
    elif kind == 'powers':
        for key in ('category','stack_mode','duration','max_stack','trigger','tooltip'):row[key]=item.get(key,0 if key in ('duration','max_stack') else '')
        row['type']={'BUFF':'버프','DEBUFF':'디버프','POWER':'파워','CURSE':'저주','SPECIAL':'특수'}[item['category']]
    row.setdefault('sources',[]);row.setdefault('related',[])
    return row

def export_catalog(data, project):
    from content_tool import validate_item
    project=project.resolve()
    if not (project/'project.godot').is_file():raise ValueError('project.godot required')
    result={};pending=[];assets=[]
    for kind in KINDS:
        rows=[];ids=set()
        for item in data[kind]:
            errs=validate_item(kind,item)
            if errs:raise ValueError(f'{kind}/{item.get("id")}: {errs}')
            if item['id'] in ids:raise ValueError('Duplicate ID: '+item['id'])
            ids.add(item['id'])
            if item.get('approval_state')!='approved':
                pending.append(kind+'/'+item['id']);continue
            row=runtime_item(kind,item)
            art=row['art']
            if art.startswith('res://'):
                path=(project/art[6:]).resolve()
                if not path.is_relative_to(project):raise ValueError('Art must stay inside project')
                if not path.is_file():raise ValueError('Missing approved art: '+art)
            else:
                path=Path(art).resolve()
                if not art or not path.is_file() or path.suffix.lower() not in ('.png','.webp','.jpg','.svg'):raise ValueError('Approved art file required: '+str(art))
                raw=path.read_bytes();digest=hashlib.sha256(raw).hexdigest()
                target=Path('assets/content_tool')/(digest+path.suffix.lower())
                assets.append((project/target,raw));row['art']='res://'+target.as_posix()
            if kind=='cards':
                if not isinstance(row['cost'],(int,float)) or row['cost']<0:raise ValueError('Invalid card cost')
                if not any(k in row for k in ('damage','block','heal','bleed','next_attack','venom_turns')):raise ValueError('Card needs executable runtime effects')
                for k in ('damage','block','heal','bleed','next_attack','venom_turns'):
                    if k in row and (not isinstance(row[k],(int,float)) or row[k]<0):raise ValueError('Invalid numeric effect: '+k)
            if kind=='monsters' and (row['hp']<=0 or not row.get('pattern') or any('damage' not in a or 'name' not in a for a in row['pattern'])):raise ValueError('Monster HP/pattern invalid')
            rows.append(row)
        result[ALIASES.get(kind,kind)]=rows
    pools={}
    for row in result['cards']:pools.setdefault(row['character'],[]).append(row)
    result['cards']=pools
    # Existing game entry points require these records; never publish a broken catalog.
    required={'cards':('strike','defend'),'relics':('explorer_map','blood_contract'),'potions':('healing_draught',),'enchantments':('sharpen',),'events':('twisted_altar',),'powers':('venom','bleed','empower'),'monsters':('ash_warden','ash_warden_elite','ash_warden_boss')}
    for kind,names in required.items():
        rows=[r for pool in pools.values() for r in pool] if kind=='cards' else result[kind]
        if not set(names)<={r['id'] for r in rows}:raise ValueError('Required game records missing or unapproved: '+kind)
    # Preserve rank order used by the existing encounter selector.
    result['monsters'].sort(key=lambda r:['일반','엘리트','보스'].index(r['type']))
    result['_meta']={'format':1,'source_sha256':hashlib.sha256(json.dumps(data,sort_keys=True,ensure_ascii=False).encode()).hexdigest(),'excluded':pending}
    for path,raw in assets:path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(raw)
    dest=project/'data/content_tool/catalog.json';dest.parent.mkdir(parents=True,exist_ok=True)
    temp=dest.with_suffix('.tmp');temp.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');temp.replace(dest)
    return {'export_dir':str(dest.parent),'godot_written':[str(dest)],'excluded':pending,'counts':{k:len(v) for k,v in result.items() if k!='_meta'}}
