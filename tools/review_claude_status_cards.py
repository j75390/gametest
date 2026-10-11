import hashlib,json,shutil
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
work=root/'ai/claude_status_cards_20261011'
results=json.loads((work/'results.json').read_text(encoding='utf-8'))
reasons={'counter':('pass','Single thorn shield, readable gold violet silhouette, complete edge.'),'barrier':('reject','Opaque shield with trophy base; lacks translucent layered glass barrier.'),'pain_ledger':('pass','Closed leather book with one small blood droplet, no lettering, complete silhouette.'),'pain_mirror':('pass','Single antique mirror with complete gilded frame, cracked red reflection.'),'ether_cycle':('pass','Single purple vapour ring, full perimeter, readable circular movement.')}
rows=[]
for ident,(verdict,reason) in reasons.items():
 src=root/'assets/status/claude_cards_20261011'/f'{ident}.png'
 row=dict(id=ident,seed=results[ident]['seed'],source=str(src),source_sha256=hashlib.sha256(src.read_bytes()).hexdigest(),verdict=verdict,reason=reason,method='local_comfyui')
 if verdict=='pass':
  dest=root/'assets/delivery/claude_20261011/status'/f'{ident}_v1.png'
  dest.parent.mkdir(parents=True,exist_ok=True)
  shutil.copy2(src,dest)
  im=Image.open(dest)
  assert im.size==(512,512) and im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0
  row.update(path=str(dest),size=list(im.size),sha256=hashlib.sha256(dest.read_bytes()).hexdigest())
 rows.append(row)
(work/'manual_review.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
(root/'docs/proposals/CLAUDE_CARD_STATUS_MAPPING_20261011.json').write_text(json.dumps([r for r in rows if r['verdict']=='pass'],ensure_ascii=False,indent=2),encoding='utf-8')
print('4 pass, barrier reject, current seeds and hashes recorded')
