"""Export only visually passed files whose generated seed still matches review."""
import json
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
p=root/'docs/proposals/relics_20261009'
results=json.loads((p/'results.json').read_text(encoding='utf-8'))
reviews=json.loads((p/'manual_review.json').read_text(encoding='utf-8'))
passed=[];rejected=[];pending=[]
for ident,item in results.items():
    review=reviews.get(ident,{})
    if review.get('seed')!=item.get('seed'):
        pending.append(ident);continue
    if review.get('verdict')!='pass':
        rejected.append(ident);continue
    path=root/item['path'].removeprefix('res://')
    with Image.open(path) as im:
        assert im.mode=='RGBA' and im.size==(512,512),ident
        assert im.getchannel('A').getextrema()[0]==0,ident
    passed.append({'id':ident,'name':item['name'],'image':item['path'],'seed':item['seed'],'status':'visual_pass','gameplay_changed':False})
data={'source':'local ComfyUI SDXL + BiRefNet','preserve_existing':18,'catalog_modified':False,'passed':passed,'rejected':rejected,'pending_review':pending,'missing':[j['id'] for j in json.loads((p/'jobs.json').read_text(encoding='utf-8')) if j['id'] not in results or 'path' not in results[j['id']]]}
(p/'CLAUDE_ART_MAPPING.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
print('VISUAL_PASS',len(passed),'REJECT',len(rejected),'NEW_SEED_PENDING',len(pending),'MISSING',len(data['missing']))
