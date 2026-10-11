from PIL import Image, ImageDraw
from pathlib import Path
import json

root=Path(__file__).resolve().parents[2]
jobs=json.loads((root/'docs/proposals/shop_sources.json').read_text(encoding='utf-8'))
folder=root/'assets/ui/shop'
folder.mkdir(parents=True,exist_ok=True)
manifest=[]
for j in jobs:
    im=Image.open(j['source']).convert('RGBA')
    if j['alpha']:
        bounds=im.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox()
        im=im.crop(bounds)
        im.thumbnail((j['w']-16,j['h']-16),Image.Resampling.LANCZOS)
        out=Image.new('RGBA',(j['w'],j['h']))
        out.alpha_composite(im,((j['w']-im.width)//2,j['h']-8-im.height))
    else:
        im.thumbnail((j['w'],j['h']),Image.Resampling.LANCZOS)
        out=Image.new('RGBA',(j['w'],j['h']),(16,12,20,255))
        out.alpha_composite(im,((j['w']-im.width)//2,(j['h']-im.height)//2))
    out.save(folder/(j['name']+'.png'))
    manifest.append({'name':j['name'],'path':f"assets/ui/shop/{j['name']}.png",'size':list(out.size),'alpha_range':list(out.getchannel('A').getextrema()),'status':'needs_review'})
bg=Image.open(folder/'shop_background.png').convert('RGBA')
merchant=Image.open(folder/'merchant.png').convert('RGBA')
merchant.thumbnail((360,600),Image.Resampling.LANCZOS)
bg.alpha_composite(merchant,(25,220))
# Review-only occlusion: the scene's counter stands in front of the merchant.
# Independent production assets remain unchanged.
scene=Image.open(folder/'shop_background.png').convert('RGBA')
bg.alpha_composite(scene.crop((0,590,1440,900)),(0,590))
tray=Image.open(folder/'display_tray.png').convert('RGBA')
tray.thumbnail((420,110),Image.Resampling.LANCZOS)
bg.alpha_composite(tray,(690,555))
bg.convert('RGB').save(root/'docs/proposals/shop_composition_review.png')
(root/'docs/proposals/shop_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(manifest,ensure_ascii=False))
