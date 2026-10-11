from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib
ROOT=Path(__file__).resolve().parents[1]
R=ROOT/'assets/delivery/claude_20261011/rest'
NN=Image.Resampling.NEAREST
bg=Image.open(R/'raw/campfire_scene_v2.png').convert('RGB').resize((360,225),NN)
bg.save(R/'campfire_scene_v2.png');bg.resize((1440,900),NN).save(R/'campfire_scene_v2_4x.png')
preview=bg.convert('RGBA')
mira=Image.open(R/'characters/mira/rest_sit.png').convert('RGBA').resize((80,80),NN)
preview.alpha_composite(mira,(78,77))
logs=Image.open(R/'campfire_logs_v1.png').convert('RGBA');preview.alpha_composite(logs,(148,140))
flame=Image.open(R/'flame_2.png').convert('RGBA');preview.alpha_composite(flame,(166,112))
preview.resize((1440,900),NN).save(R/'campfire_scene_v2_mira_preview.png')
layout=bg.resize((1440,900),NN);d=ImageDraw.Draw(layout)
for n,(x,y) in enumerate([(472,608),(968,608),(604,552),(836,552)]):
 d.ellipse((x-12,y-4,x+12,y+4),outline=(134,208,203),width=2);d.text((x+15,y-15),str(n+1),fill=(134,208,203))
d.rectangle((290,150,700,220),outline=(130,130,175),width=2)
d.rectangle((350,700,1090,870),outline=(130,130,175),width=2)
d.ellipse((708,596,732,620),outline=(255,184,80),width=3)
layout.save(R/'campfire_scene_v2_layout_QA.png')
path=R/'campfire_scene_v2.png'
entry={'path':'res://assets/delivery/claude_20261011/rest/campfire_scene_v2.png','verdict':'pass','reason':'육안검수: 중앙 대칭 불빛, 불·장작·인물 없는 배경. 불중심(180,152) 및 4인 좌석 바닥 확보, 중앙 기둥 없음. 기존 도트 화풍 유지. UI/말풍선은 코드로 덮는 영역이며 그림에 없음.','size':[360,225],'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'four_x':'campfire_scene_v2_4x.png','runtime_qa':'pending Claude integration','review_previews':['campfire_scene_v2_mira_preview.png','campfire_scene_v2_layout_QA.png']}
reviewpath=R/'manual_review.json';rows=json.loads(reviewpath.read_text(encoding='utf8'));rows=[r for r in rows if r.get('path')!=entry['path']];rows.append(entry);reviewpath.write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
assert Image.open(path).size==(360,225)
large=Image.open(R/'campfire_scene_v2_4x.png')
assert large.size==(1440,900)
assert large.resize((360,225),NN).tobytes()==bg.tobytes()
print('PASS: opaque360x225, exact4x1440x900, source preserved; game integration pending')
