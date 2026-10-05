from pathlib import Path
import json,shutil,sys
from PIL import Image
p=Path('gametest').resolve();sys.path.insert(0,str(p/'tools/content_tool'))
import content_tool as ct
from godot_bridge import export_catalog
jobs=json.loads((p/'ai/icon_batch_20261006_v2.json').read_text(encoding='utf-8'))
results=json.loads((p/'ai/icon_batch_20261006_v2_output/results.json').read_text(encoding='utf-8'))
assert len(results)==18 and all(r.get('ok') for r in results.values()), 'Generation still running'
short={'status_draft_001':'공격 카드의 타격 피해가 중첩당 1 증가합니다.','status_draft_002':'카드로 얻는 방어도가 중첩당 1 증가합니다.','status_draft_006':'자신의 턴 시작 시 HP를 3 회복합니다.','status_draft_007':'받는 공격 피해를 중첩만큼 흡수합니다.','status_draft_008':'상태이상으로 잃는 HP가 25% 감소합니다.','status_draft_011':'다음 디버프 부여 한 번을 막습니다.'}
flavor={'relic_uncommon_001':'이름은 지워지지 않았다. 그 이름을 부를 사람이 병동에서 사라졌을 뿐이다.','relic_uncommon_002':'교대 종은 아직 울린다. 다음 근무자의 이름을 적는 칸만 오래 비어 있다.','relic_uncommon_005':'간호장은 초침이 멎은 뒤에도 회진 시간을 지켰다. 누군가 기다리는 시간을 재고 있었기 때문이다.','relic_uncommon_010':'운하의 추는 물 위에 남았다. 수송 장부에는 그날의 화물만 가벼워졌다고 적혔다.','relic_uncommon_018':'찌꺼기를 버리기 전에 빛에 비추었다. 검은 선 하나가 글씨의 끝처럼 안으로 접혀 있었다.','relic_uncommon_022':'푸른 불 아래서는 두 약병이 다른 색으로 보였다. 미라는 불을 끄기 전에 마개에도 홈을 냈다.','potion_text_03':'로엔은 잔을 건네기 전에 약이 아니라 차라고 말했다. 설명을 듣고 마실 수 있다는 것이 드물어진 곳이었다.'}
for j in jobs:
 key=j['type']+'/'+j['id']; src=Path(results[key]['output']); im=Image.open(src)
 assert im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0,key
 name=j['id']+'_comfy_v2.png'; dest=p/'assets/generated_icons'/name;dest.parent.mkdir(exist_ok=True);shutil.copy2(src,dest)
 old=json.loads((p/'ai/icon_batch_20261006_output'/(j['id']+'.before.json')).read_text(encoding='utf-8'))
 fields={'id':j['id'],'icon':'res://assets/generated_icons/'+name,'text_only':False,'art_source':'COMFYUI','art_review_state':'agent_verified','generation':results[key]}
 if j['id'] in short: fields.update(effect=short[j['id']],description=short[j['id']])
 if j['id'] in flavor:fields['flavor_text']=flavor[j['id']]
 assert ct.upsert_item(j['type'],fields)[0]
 assert ct.upsert_item(j['type'],{'id':j['id'],'approval_state':old.get('approval_state','draft')})[0]
 print(key,'linked')
print(export_catalog(ct.load_data(),p)['counts'])
