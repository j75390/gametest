"""Remove generated signature artifacts with local ComfyUI inpainting."""
import json,time,urllib.request,urllib.parse,sys
from pathlib import Path
from PIL import Image,ImageDraw
sys.path.insert(0,str(Path(__file__).resolve().parent/'content_tool'));import content_tool as ct
root=Path(__file__).resolve().parents[1];raw=root/'ai/claude_events_20261011';out=root/'assets/events/claude_20261011'
results=json.loads((raw/'results.json').read_text());base='http://127.0.0.1:8188'
for ident in sys.argv[1:]:
 r=results[ident];attempt=r['attempt'];source=raw/f'{ident}_a{attempt}.png';mask=Image.new('RGB',(768,1152),'black');d=ImageDraw.Draw(mask)
 if ident=='common_act1_13':
  for box in [(0,1030,768,1152),(540,590,768,1152),(0,870,180,1152)]:d.rectangle(box,fill='white')
 else:d.rectangle((560,1100,768,1152),fill='white')
 mp=raw/f'{ident}_mask.png';mask.save(mp)
 def upload(p):
  b='eventinpaintboundary';body=(f'--{b}\r\nContent-Disposition: form-data; name="image"; filename="{p.name}"\r\nContent-Type: image/png\r\n\r\n'.encode()+p.read_bytes()+f'\r\n--{b}--\r\n'.encode())
  return json.loads(urllib.request.urlopen(urllib.request.Request(base+'/upload/image',data=body,headers={'Content-Type':'multipart/form-data; boundary='+b})).read())['name']
 seed=r['seed']+700001;wf=ct._basic_workflow('plain dark aged wooden table and stone floor, blank unmarked worn surface, realistic gothic oil painting','text, letters, numbers, signature, writing, watermark, logo',768,1152,seed,'sd_xl_base_1.0.safetensors','claude_events_20261011/'+ident+'_clean')
 wf['12']={'class_type':'LoadImage','inputs':{'image':upload(source)}};wf['13']={'class_type':'LoadImage','inputs':{'image':upload(mp)}}
 wf['14']={'class_type':'ImageToMask','inputs':{'image':['13',0],'channel':'red'}}
 wf['15']={'class_type':'VAEEncodeForInpaint','inputs':{'pixels':['12',0],'mask':['14',0],'vae':['1',2],'grow_mask_by':8}}
 wf['5']['inputs'].update(latent_image=['15',0],steps=24,denoise=.85,cfg=5,sampler_name='dpmpp_2m',scheduler='karras')
 (raw/f'{ident}_clean.workflow.json').write_text(json.dumps(wf,indent=2));pid=ct._post_json(base+'/prompt',{'prompt':wf})['prompt_id'];print('START '+ident,flush=True)
 for _ in range(900):
  h=ct._get_json(base+'/history/'+pid).get(pid,{});ims=[im for n in h.get('outputs',{}).values() for im in n.get('images',[])]
  if ims:break
  if h.get('status',{}).get('status_str')=='error':raise RuntimeError(h['status'])
  time.sleep(1)
 else:raise TimeoutError(ident)
 p=raw/f'{ident}_clean.png';urllib.request.urlretrieve(base+'/view?'+urllib.parse.urlencode(ims[0]),p)
 Image.open(p).convert('RGB').resize((1024,1536),Image.Resampling.LANCZOS).save(out/f'{ident}.png')
 r.update(seed=seed,state='needs_review',inpaint=True,source=str(p));(raw/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print('DONE '+ident,flush=True)
