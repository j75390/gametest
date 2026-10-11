import json,shutil,hashlib
from pathlib import Path
from PIL import Image,ImageDraw
r=Path(__file__).resolve().parents[1];a=r/'ai/mira_wave3_comfy_20261011';o=r/'assets/delivery/claude_20261011/cards_wave3';o.mkdir(parents=True,exist_ok=True)
rows=json.loads((a/'approved_decisions.json').read_text(encoding='utf-8'));mapping=[]
for row in rows:
 id=row['id'];dest=o/f'{id}_v3.png';shutil.copy2(row['path'],dest)
 im=Image.open(dest);im.verify()
 row.update(path=f'res://assets/delivery/claude_20261011/cards_wave3/{id}_v3.png',sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),engine='imagegen_after_comfy_rejection')
 mapping.append(dict(id=id,path=row['path'],verdict='pass'))
(o/'manual_review.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
(r/'docs/proposals/CLAUDE_MIRA_CARD_MAPPING_WAVE3_20261011.json').write_text(json.dumps(mapping,ensure_ascii=False,indent=2),encoding='utf-8')
out=Image.new('RGB',(1200,((len(rows)+4)//5)*265),'#16121d');d=ImageDraw.Draw(out)
for n,row in enumerate(rows):
 im=Image.open(r/row['path'][6:]).convert('RGB');im.thumbnail((240,240));x=(n%5)*240;y=(n//5)*265;out.paste(im,(x,y));d.text((x+5,y+244),row['id'],fill='white')
out.save(o/'review.jpg')
print(f'Packaged visually approved {len(rows)} cards; unique hashes {len(set(x["sha256"] for x in rows))}')

