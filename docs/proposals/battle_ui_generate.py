from pathlib import Path
import sys,json,time,urllib.request,urllib.parse
from PIL import Image,ImageDraw,ImageFont
p=Path(__file__).resolve().parents[2];sys.path.insert(0,str(p/'tools/content_tool'));import content_tool as ct
out=p/'assets/ui/battle';out.mkdir(parents=True,exist_ok=True)
raw=p/'ai/battle_ui_20261008_output';raw.mkdir(parents=True,exist_ok=True)
jobs=json.loads((p/'docs/proposals/battle_ui_jobs.json').read_text(encoding='utf-8'))
base='http://127.0.0.1:8188'
for attempt in range(90):
 try:ct._get_json(base+'/system_stats');break
 except Exception:time.sleep(2)
else:raise RuntimeError('ComfyUI offline')
result={}
for j in jobs:
 id=j['id'];dest=out/(id+'.png');source=raw/(id+'.png')
 if not source.exists():
  print('START '+id,flush=True)
  wf=ct._basic_workflow(j['prompt'],'collage, grid, sprite sheet, multiple objects, duplicates, text, letters, numbers, logo, watermark, cropped, cut off, scenery, rectangular border',768,768,j['seed'],'sd_xl_base_1.0.safetensors','battle_ui/'+id)
  wf['5']['inputs'].update(steps=22,cfg=6.0)
  wf['8']={'class_type':'LoadBackgroundRemovalModel','inputs':{'bg_removal_name':'birefnet.safetensors'}}
  wf['9']={'class_type':'RemoveBackground','inputs':{'bg_removal_model':['8',0],'image':['6',0]}}
  wf['10']={'class_type':'InvertMask','inputs':{'mask':['9',0]}}
  wf['11']={'class_type':'JoinImageWithAlpha','inputs':{'image':['6',0],'alpha':['10',0]}}
  wf['7']['inputs']['images']=['11',0]
  (raw/(id+'.workflow.json')).write_text(json.dumps(wf),encoding='utf-8')
  r=ct._post_json(base+'/prompt',{'prompt':wf});pid=r['prompt_id']
  for _ in range(300):
   hist=ct._get_json(base+'/history/'+pid)
   if pid in hist:
    imgs=[im for node in hist[pid].get('outputs',{}).values() for im in node.get('images',[])]
    if imgs:break
    if hist[pid].get('status',{}).get('status_str')=='error':raise RuntimeError(str(hist[pid]['status']))
   time.sleep(1)
  else:raise RuntimeError('Timeout '+id)
  urllib.request.urlretrieve(base+'/view?'+urllib.parse.urlencode(imgs[0]),source)
 im=Image.open(source).convert('RGBA');bounds=im.getchannel('A').point(lambda a:255 if a>28 else 0).getbbox();assert bounds
 im=im.crop(bounds);side=j['size'];im.thumbnail((int(side*.88),int(side*.88)),Image.Resampling.LANCZOS)
 canvas=Image.new('RGBA',(side,side));canvas.alpha_composite(im,((side-im.width)//2,(side-im.height)//2));canvas.save(dest)
 result[id]={'path':'res://assets/ui/battle/'+dest.name,'size':[side,side],'state':'needs_review','source':'COMFYUI','seed':j['seed']}
 print('DONE '+id,flush=True)
# Deterministic text-free button states share exactly one silhouette and safe text area.
for state in ['normal','hover','disabled']:
 scale=3;w,h=1080,360;im=Image.new('RGBA',(w,h));mask=Image.new('L',(w,h));d=ImageDraw.Draw(mask)
 poly=[(78,54),(1002,54),(1050,180),(1002,306),(78,306),(30,180)];d.polygon(poly,fill=255)
 top,bottom=((51,30,67),(17,13,23)) if state=='normal' else (((80,43,103),(27,17,41)) if state=='hover' else ((31,29,34),(15,14,18)))
 for y in range(h):
  t=y/(h-1);c=tuple(int(a+(b-a)*t) for a,b in zip(top,bottom));ImageDraw.Draw(im).line((0,y,w,y),fill=c+(255,))
 im.putalpha(mask);d=ImageDraw.Draw(im)
 gold=(166,139,87,255) if state=='normal' else ((225,191,118,255) if state=='hover' else (91,83,74,255))
 d.line(poly+[poly[0]],fill=gold,width=6,joint='curve')
 inner=[(91,73),(989,73),(1028,180),(989,287),(91,287),(52,180)];d.line(inner+[inner[0]],fill=gold[:3]+(130,),width=3)
 for x in [85,995]:
  d.polygon([(x,157),(x+15,180),(x,203),(x-15,180)],fill=gold)
 for y in [54,306]:d.polygon([(540,y-10),(550,y),(540,y+10),(530,y)],fill=gold)
 im=im.resize((360,120),Image.Resampling.LANCZOS);name='end_turn_'+state;im.save(out/(name+'.png'))
 result[name]={'path':'res://assets/ui/battle/'+name+'.png','size':[360,120],'state':'needs_review','source':'authored_ui','text_safe_rect':[54,32,252,56]}
(raw/'results.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
(p/'docs/proposals/battle_ui_manifest.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print('COMPLETE '+str(len(result)),flush=True)
