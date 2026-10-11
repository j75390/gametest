"""Local ComfyUI glass-barrier retry, isolated from canonical files."""
import json,sys
from pathlib import Path
import relic_art_batch as art
ROOT=Path(__file__).resolve().parents[1]
art.RAW=ROOT/'ai/claude_barrier_20261011_revision4'
art.OUT=ROOT/'assets/delivery/claude_20261011/status'
for path in (art.RAW,art.OUT):path.mkdir(parents=True,exist_ok=True)
seed=int(sys.argv[1]) if len(sys.argv)>1 else 4164111
obj='one translucent magical GLASS barrier shaped as a pointed medieval heater shield, flat broad top edge, two short slanted shoulders, vertical sides tapering to ONE bottom point, simple five-sided heater-shield outline, three parallel translucent pale blue glass plates overlapped by a tiny offset, faint see-through glass center, bright thin refractive edge, no metal body, no stand'
job={'id':'barrier_v1','name':'방어막','object':obj,'seed':seed,
 'prompt':'('+obj+':1.8), isolated dark gothic fantasy game STATUS ICON, hand painted illustration, complete object centered with empty margins, simple readable single shield silhouette, pure white background',
 'negative':'(diamond, rhombus, crystal jewel, gemstone, circular central gem, spokes, ornamental star, gold filigree, opaque metal shield, solid shield face, metal body, trophy, pedestal, stand, base, supports, plinth:2.0), (multiple shields, collection, duplicates, collage, separate objects:1.7), letters, numbers, text, frame, logo, watermark, hand, person, scenery, cropped, face, photograph'}
result=art.generate(job,0)
result['path']='res://assets/delivery/claude_20261011/status/barrier_v1.png'
(art.RAW/('result_'+str(seed)+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))

