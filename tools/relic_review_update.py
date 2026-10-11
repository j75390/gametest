"""Apply explicit human visual decisions to their current seed snapshot."""
import json,sys,datetime
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'docs/proposals/relics_20261009'
results=json.loads((p/'results.json').read_text(encoding='utf-8'))
reviews=json.loads((p/'manual_review.json').read_text(encoding='utf-8'))
decisions=json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
for ident,d in decisions.items():
    item=results[ident]
    if d.get('expected_seed') is not None and d['expected_seed']!=item.get('seed'):raise ValueError('seed changed '+ident)
    d['expected_seed']=item.get('seed')
    reviews[ident]={'id':ident,'name':item.get('name'),'seed':item.get('seed'),'attempt':item.get('attempt'),'verdict':d['verdict'],'reason':d['reason'],'reviewed_at':datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).isoformat(),'path':item.get('path')}
(p/'manual_review.json').write_text(json.dumps(reviews,ensure_ascii=False,indent=2),encoding='utf-8')
Path(sys.argv[1]).write_text(json.dumps(decisions,ensure_ascii=False,indent=2),encoding='utf-8')
print('UPDATED',len(decisions),'PASS',sum(x['verdict']=='pass' for x in reviews.values()))
