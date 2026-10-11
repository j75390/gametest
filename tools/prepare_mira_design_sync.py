"""Format independently generated assets; never paint or slice animation frames."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/delivery/claude_20261011/mira_design_sync'
NAMES = ['idle', 'idle_blink', 'walk_a', 'walk_pass', 'walk_b',
         'attack_prepare', 'attack_release', 'skill_charge', 'skill_release',
         'hurt', 'death_fall', 'death_rest']

def main():
    rows = []
    for name in NAMES:
        source = BASE / 'pixel' / (name + '_raw.png')
        if not source.exists():
            continue
        im = Image.open(source).convert('RGBA')
        bbox = im.getchannel('A').getbbox()
        if not bbox:
            raise ValueError(f'empty alpha: {name}')
        cut = im.crop(bbox)
        # Format deliberately generated pixel-art only. The hand-painted SD
        # master is never passed through this pipeline as substitute pixel art.
        target_h = 160 if name in ('death_rest', 'death_fall') else 168
        scale = min(304 / cut.width, target_h / cut.height)
        size = (max(1, round(cut.width * scale)), max(1, round(cut.height * scale)))
        cut = cut.resize(size, Image.Resampling.NEAREST)
        canvas = Image.new('RGBA', (320, 192))
        # Visually reviewed boot/torso anchors avoid centering on spell effects.
        anchor = {'idle':.60,'idle_blink':.60,'walk_a':.64,'walk_pass':.60,
                  'walk_b':.62,'attack_prepare':.57,'attack_release':.47,
                  'skill_charge':.64,'skill_release':.46,'hurt':.60,
                  'death_fall':.68,'death_rest':.58}[name]
        x = max(6, min(314-size[0], round(160-size[0]*anchor)))
        y = 180-size[1]
        canvas.alpha_composite(cut, (x, y))
        dest = BASE / 'pixel' / (name + '.png')
        canvas.save(dest)
        rows.append({'id':name,'raw':str(source.relative_to(ROOT)),
                     'path':str(dest.relative_to(ROOT)), 'size':[320,192],
                     'bounds':[x,y,x+size[0],y+size[1]], 'verdict':'needs_review'})
    preview = Image.new('RGB', (3*660, 4*430), '#25212c')
    draw = ImageDraw.Draw(preview)
    for i, row in enumerate(rows):
        im = Image.open(ROOT / row['path']).resize((640,384), Image.Resampling.NEAREST)
        x,y=(i%3)*660+10,(i//3)*430+32
        preview.paste(im,(x,y),im)
        draw.text((x,y-22),row['id'],fill='#e8d9bf')
    preview.save(BASE / 'pixel_review.png')
    (BASE / 'formatted_frames.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'formatted':len(rows),'expected':12,'preview':str(BASE/'pixel_review.png')}))

if __name__ == '__main__':
    main()
