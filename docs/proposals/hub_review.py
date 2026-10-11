from pathlib import Path
from PIL import Image, ImageDraw
import json
root=Path(__file__).resolve().parents[2]
jobs=json.loads((root/'docs/proposals/hub_sources_20261009.json').read_text(encoding='utf-8'))
folder=root/'assets/ui/codex/hub'
folder.mkdir(parents=True,exist_ok=True)
sheet=Image.new('RGB',(1320,560),'#15101d')
draw=ImageDraw.Draw(sheet)
manifest=[]
for i,j in enumerate(jobs):
    im=Image.open(j['source']).convert('RGB')
    im.thumbnail((1024,768),Image.Resampling.LANCZOS)
    out=Image.new('RGB',(1024,768),'#15101d')
    out.paste(im,((1024-im.width)//2,(768-im.height)//2))
    out.save(folder/(j['name']+'.png'))
    small=out.resize((220,165),Image.Resampling.LANCZOS)
    x=20+i*260
    sheet.paste(small,(x,35))
    draw.text((x,215),j['name']+' 220x165',fill='#e2d4b8')
    larger=out.resize((240,180),Image.Resampling.LANCZOS)
    sheet.paste(larger,(x,280))
    manifest.append({'id':j['name'],'path':f"assets/ui/codex/hub/{j['name']}.png",'size':[1024,768],'status':'needs_review','note':'Illustration only. Dynamic title/description and hub frame are separate.'})
sheet.save(root/'docs/proposals/hub_review_20261009.png')
(root/'docs/proposals/hub_manifest_20261009.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print('5 hub illustrations saved; preview at intended small size')
