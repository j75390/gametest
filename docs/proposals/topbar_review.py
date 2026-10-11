from PIL import Image, ImageDraw
from pathlib import Path
import json

root=Path(__file__).resolve().parents[2]
folder=root/'assets/ui/topbar'
jobs=json.loads((root/'docs/proposals/topbar_sources.json').read_text(encoding='utf-8'))
folder.mkdir(parents=True,exist_ok=True)
records=[]
sheet=Image.new('RGBA',(1500,520),(26,21,32,255))
draw=ImageDraw.Draw(sheet)
for i,j in enumerate(jobs):
    im=Image.open(j['source']).convert('RGBA')
    bounds=im.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox()
    if bounds:
        im=im.crop(bounds)
    # Mechanical resampling only: preserve original generated art and alpha.
    if j['name']=='topbar_frame':
        im=im.resize((1440,76),Image.Resampling.LANCZOS)
        sheet.alpha_composite(im,(30,30))
    else:
        im.thumbnail((j['width']-8,j['height']-8),Image.Resampling.LANCZOS)
        fitted=Image.new('RGBA',(j['width'],j['height']))
        fitted.alpha_composite(im,((j['width']-im.width)//2,(j['height']-im.height)//2))
        im=fitted
        x=60+(i-1)*230
        sheet.alpha_composite(im,(x,180))
        draw.text((x,285),j['name'],fill='#e3d4b9')
        enlarged=im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST)
        sheet.alpha_composite(enlarged,(x,315))
    path=folder/(j['name']+'.png')
    im.save(path)
    records.append({'name':j['name'],'path':path.relative_to(root).as_posix(),'size':list(im.size),'alpha_range':list(im.getchannel('A').getextrema()),'center_alpha':im.getpixel((im.width//2,im.height//2))[3],'status':'needs_review'})
sheet.convert('RGB').save(root/'docs/proposals/topbar_review.png')
(root/'docs/proposals/topbar_manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(records,ensure_ascii=False))
