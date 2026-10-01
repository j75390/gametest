"""One-time CLI import preserving existing runtime fields and approved artwork."""
import copy,json
from pathlib import Path

def run(project, tool):
    for kind in tool.TYPE_ORDER:
        path=project/'data'/('enchantments.json' if kind=='enchants' else kind+'.json')
        raw=json.loads(path.read_text(encoding='utf-8-sig'))
        rows=[x for v in raw.values() for x in v] if isinstance(raw,dict) else raw
        existing={x['id'] for x in tool.load_data()[kind]}
        for original in rows:
            if original['id'] in existing:continue
            left=copy.deepcopy(original);item={}
            for key in ('id','name','rarity','type','character','target','keywords','effect','act','hp','choices'):
                if key in left:item[key]=left.pop(key)
            art=left.pop('art');assert (project/art.removeprefix('res://')).is_file(),art
            item['image' if kind in ('cards','monsters','events') else 'icon']=art
            item.update(approval_state='approved',art_source='MANUAL',approval_basis='Preserved existing shipped runtime asset; path verified; no new generated art approved')
            if kind=='cards':item.update(energy_cost=left.pop('cost'),description='기존 수치 효과는 runtime 필드 및 게임의 공통 효과 문구를 사용합니다.')
            elif kind=='relics':item.update(curse_tag=left.pop('cursed',False),flavor_text='기존 원정 기록에서 이관',scope='GLOBAL_MAP' if original.get('reveal_map') else 'PERSONAL')
            elif kind=='potions':item.setdefault('effect','HP %s 회복'%left.get('heal',0))
            elif kind=='monsters':
                item.update(rank={'일반':'NORMAL','엘리트':'ELITE','보스':'BOSS'}[item.pop('type')],attack_pattern=left.pop('pattern'),description=item.pop('effect'),powers=[])
            elif kind=='events':
                item.update(title=item.pop('name'),story=item.pop('effect'),category='COMMON')
            elif kind=='powers':
                item.update(category='BUFF' if item.pop('type')=='버프' else 'DEBUFF',stack_mode='DURATION' if item['id']=='venom' else 'COUNTER',tooltip=item['effect'],duration=0,max_stack=0,trigger='공격 시' if item['id']=='empower' else '턴 시작')
                left['behavior']={'venom':'dot_percent','bleed':'dot_flat','empower':'next_attack'}[item['id']]
            item['runtime']=left
            ok,errors=tool.upsert_item(kind,item)
            if not ok:raise ValueError(errors)
    return tool.validate_all()
