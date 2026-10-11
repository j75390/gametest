import json,sys,time,urllib.request,urllib.parse
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/content_tool'))
import content_tool as ct
BASE='http://127.0.0.1:8188'
RAW=ROOT/'ai/mira_wave3_comfy_20261011';RAW.mkdir(parents=True,exist_ok=True)
OUT=ROOT/'assets/delivery/claude_20261011/cards_wave3';OUT.mkdir(parents=True,exist_ok=True)
specs=json.loads((ROOT/'ai/mira_wave3_specs_20261011.json').read_text())
journal=RAW/'results.json';results=json.loads(journal.read_text()) if journal.exists() else {}
negative='(text, letters, numbers, watermark, logo, card border, frame, UI, panels, collage, sheet:1.8), photograph, photorealistic, face closeup, portrait, modern hospital, machinery, extra fingers, malformed hands, disconnected limbs, blurry'
for n,(id,obj) in enumerate(specs):
 if id in results and id not in sys.argv[1:]:continue
 attempt=results.get(id,{}).get('attempt',-1)+1;seed=731100+n*997+attempt*99173
 prompt='('+obj+':1.6), dynamic close action scene, hand painted 2D fantasy game illustration, bold brushwork, dark violet background, chemical color accent, borderless square art, no text.'
 wf=ct._basic_workflow(prompt,negative,1024,1024,seed,'sd_xl_base_1.0.safetensors','mira_wave3/'+id)
 wf['5']['inputs'].update(steps=28,cfg=6.0,sampler_name='dpmpp_2m',scheduler='karras')
 (RAW/f'{id}_{seed}.workflow.json').write_text(json.dumps(wf,indent=2))
 print('START '+id,flush=True)
 try:
  pid=ct._post_json(BASE+'/prompt',{'prompt':wf})['prompt_id']
  for _ in range(900):
   h=ct._get_json(BASE+'/history/'+pid).get(pid)
   if h:
    images=[im for node in h.get('outputs',{}).values() for im in node.get('images',[])]
    if images:break
    if h.get('status',{}).get('status_str')=='error':raise RuntimeError(str(h['status']))
   time.sleep(1)
  else:raise TimeoutError(id)
  src=RAW/f'{id}_{seed}.png';urllib.request.urlretrieve(BASE+'/view?'+urllib.parse.urlencode(images[0]),src)
  dest=OUT/(id+'_v3.png');Image.open(src).convert('RGB').save(dest)
  results[id]={'id':id,'seed':seed,'attempt':attempt,'prompt':prompt,'source':str(src),'path':'res://'+str(dest.relative_to(ROOT)).replace('\\','/'),'state':'needs_review'}
  print('DONE '+id,flush=True)
 except Exception as e:results[id]={'id':id,'attempt':attempt,'state':'failed','error':str(e)};print('FAIL '+id,flush=True)
 journal.write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf8')
 sheet=Image.new('RGB',(1000,1000),(28,23,33));d=ImageDraw.Draw(sheet)
 for i,(ident,_) in enumerate(specs):
  p=OUT/(ident+'_v3.png')
  if p.exists():sheet.paste(Image.open(p).convert('RGB').resize((190,190)),((i%5)*200,(i//5)*250))
  d.text(((i%5)*200+3,(i//5)*250+195),ident,fill='white')
 sheet.save(RAW/'review.png')
print('BATCH FINISHED',flush=True)

