from pathlib import Path
from PIL import Image, ImageDraw
import json

root = Path(__file__).resolve().parents[2]
names = ['idle','idle_blink','walk_a','walk_pass','walk_b','attack_prepare','attack_release','skill_charge','skill_release','hurt','death_fall','death_rest']
canvas = Image.new('RGBA',(1600,1200),(24,20,30,255))
draw = ImageDraw.Draw(canvas)
records = []
for index,name in enumerate(names):
    path = root/'assets/characters/mira/pixel_sd_plague_v3'/f'{name}.png'
    im = Image.open(path).convert('RGBA')
    alpha = im.getchannel('A')
    assert alpha.getextrema()[0] == 0
    bbox = alpha.getbbox()
    records.append({'name':name,'path':path.relative_to(root).as_posix(),'size':list(im.size),'visible_bounds':list(bbox),'status':'needs_animation_review'})
    preview = im.copy()
    preview.thumbnail((380,345),Image.Resampling.LANCZOS)
    x,y = (index%4)*400,(index//4)*400
    canvas.alpha_composite(preview,(x+(400-preview.width)//2,y+20+(345-preview.height)))
    draw.text((x+20,y+380),name,fill='#eee4cd')
canvas.convert('RGB').save(root/'docs/proposals/mira_anatomy_v3_review.png')
(root/'docs/proposals/mira_motion_v3_manifest.json').write_text(json.dumps({'status':'needs_review','frames':records,'integration_owner':'Claude','note':'Independent frames. Preserve v2; review foot baseline and body size in animation before replacing character_assets.json.'},ensure_ascii=False,indent=2),encoding='utf-8')
print('12 independent transparent frames inspected; manifest and sheet saved')
