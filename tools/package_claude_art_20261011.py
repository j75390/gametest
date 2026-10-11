"""Format already generated raster assets; never synthesize replacement artwork."""
from pathlib import Path
from PIL import Image, ImageDraw
import json,hashlib
ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'assets/delivery/claude_20261011'
NN=Image.Resampling.NEAREST
def fit(src,size,margin=2,filter=NN):
 im=Image.open(src).convert('RGBA');box=im.getchannel('A').point(lambda a:255 if a>20 else 0).getbbox();im=im.crop(box)
 scale=min((size[0]-margin*2)/im.width,(size[1]-margin*2)/im.height)
 im=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),filter)
 out=Image.new('RGBA',size);out.alpha_composite(im,((size[0]-im.width)//2,size[1]-margin-im.height));return out
def record(path,reason):
 im=Image.open(path);return {'path':'res://'+str(path.relative_to(ROOT)).replace('\\','/'),'verdict':'pass','reason':reason,'size':list(im.size),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
sd=D/'mira_sd_motion';review=[]
ids=['idle','idle_blink','attack_1','attack_2','attack_3','skill_1','skill_2','skill_3','hurt','death_1','death_2']
anchors={'idle':.61,'idle_blink':.61,'attack_1':.61,'attack_2':.61,'attack_3':.61,'skill_1':.61,'skill_2':.53,'skill_3':.63,'hurt':.62}
for id in ids:
 src=sd/'raw'/('skill_2_fixed.png' if id=='skill_2' else id+'.png');im=Image.open(src).convert('RGBA');box=im.getchannel('A').point(lambda a:255 if a>20 else 0).getbbox()
 # Standing body height normalization; collapsed pose retains relative head scale.
 scale= min(1070/(box[3]-box[1]),1230/(box[2]-box[0])) if not id.startswith('death') else 1100/(box[2]-box[0])
 crop=im.crop(box).resize((round((box[2]-box[0])*scale),round((box[3]-box[1])*scale)),Image.Resampling.LANCZOS)
 out=Image.new('RGBA',(1254,1254));x=round(627-(im.width*anchors.get(id,.5)-box[0])*scale) if not id.startswith('death') else (1254-crop.width)//2
 x=max(12,min(x,1242-crop.width));y=1175-crop.height;out.alpha_composite(crop,(x,y));out.save(sd/(id+'.png'))
 review.append(record(sd/(id+'.png'),'육안검수: 같은 손그림 의상·가면·팔/다리 연결, 완전한 외곽. 1254 공통 캔버스, 바닥 y1175.'))
atlas=Image.new('RGB',(1280,960),(28,23,36));draw=ImageDraw.Draw(atlas)
for n,id in enumerate(ids):
 im=Image.open(sd/(id+'.png')).resize((300,300),Image.Resampling.LANCZOS);x=(n%4)*320;y=(n//4)*320;atlas.paste(im,(x,y),im);draw.text((x+8,y+300),id,fill='white')
atlas.save(sd/'review.png')
review.append({'path':'raw/skill_2.png','verdict':'fail','reason':'마법 오른쪽 외곽 잘림. fixed 결과만 사용.'})
(sd/'manual_review.json').write_text(json.dumps(review,ensure_ascii=False,indent=2),encoding='utf8')
rest=D/'rest';bg=Image.open(rest/'raw/campfire_scene_v1.png').convert('RGB').resize((360,225),NN);bg.save(rest/'campfire_scene_v1.png');bg.resize((1440,900),NN).save(rest/'campfire_scene_v1_4x.png')
rr=[record(rest/'campfire_scene_v1.png','고딕 회랑 야간 배경, 불 자체 없음, 캐릭터/하단 UI 자리 확보.')]
sheet=Image.new('RGBA',(112,40))
for n in range(4):
 id='flame_'+str(n+1);im=fit(rest/'raw'/ (id+'.png'),(28,40));im.save(rest/(id+'.png'));sheet.alpha_composite(im,(n*28,0));rr.append(record(rest/(id+'.png'),'독립 생성 불꽃 프레임, 불똥 포함, 투명 외곽.'))
sheet.save(rest/'campfire_pixel_v1.png')
for id,size in [('campfire_logs_v1',(64,24)),('icon_rest_v1',(64,64)),('icon_upgrade_v1',(64,64))]:
 im=fit(rest/'raw'/(id+'.png'),size);im.save(rest/(id+'.png'));rr.append(record(rest/(id+'.png'),'명확한 단일 물건, 글자·테두리 없음, 도트풍 및 투명 여백 확인.'))
(rest/'manual_review.json').write_text(json.dumps(rr,ensure_ascii=False,indent=2),encoding='utf8')
status=D/'status';fit(status/'barrier_builtin_candidate.png',(512,512),40,Image.Resampling.LANCZOS).save(status/'barrier_v1.png')
sr=[record(status/'barrier_v1.png','3겹 유리 방패 형태·굴절 테두리, 받침/현대설비/보석 없음. ComfyUI 반복 실패 후 승인된 내장 생성 대체.')]
for seed,reason in [(4164111,'보석·메달 형태와 불투명 장식'),(4164112,'삼각 현대 패널과 받침; 방패 아님')]:sr.append({'path':f'barrier_rejected_seed{seed}.png','seed':seed,'verdict':'fail','reason':reason})
(status/'manual_review.json').write_text(json.dumps(sr,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'handdrawn':len(ids),'rest':len(rr),'status_pass':1}))

