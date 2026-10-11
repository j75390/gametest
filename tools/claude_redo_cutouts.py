"""Use local ComfyUI BiRefNet to prepare reviewed illustrated sprite cutouts."""
import json, time, urllib.request, urllib.parse, sys
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
RAW=ROOT/'ai/claude_redo_20261011'
OUT=ROOT/'assets/monsters/claude_redo_20261011'
OUT.mkdir(parents=True,exist_ok=True)
BASE='http://127.0.0.1:8188'
def post(route,obj):
 return json.loads(urllib.request.urlopen(urllib.request.Request(BASE+route,data=json.dumps(obj).encode(),headers={'Content-Type':'application/json'})).read())
rows=json.loads((RAW/'sources.json').read_text(encoding='utf-8'))
selected=set(sys.argv[1:])
for row in rows:
 key=row['id']
 if selected and key not in selected:continue
 dest=OUT/(key+'_v2.png')
 if dest.exists():continue
 src=Path(row['source']);boundary='cutoutupload'
 data=(f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="redo_{key}.png"\r\nContent-Type: image/png\r\n\r\n'.encode()+src.read_bytes()+f'\r\n--{boundary}--\r\n'.encode())
 uploaded=json.loads(urllib.request.urlopen(urllib.request.Request(BASE+'/upload/image',data=data,headers={'Content-Type':'multipart/form-data; boundary='+boundary})).read())['name']
 wf={'1':{'class_type':'LoadImage','inputs':{'image':uploaded}},'2':{'class_type':'LoadBackgroundRemovalModel','inputs':{'bg_removal_name':'birefnet.safetensors'}},'3':{'class_type':'RemoveBackground','inputs':{'bg_removal_model':['2',0],'image':['1',0]}},'4':{'class_type':'InvertMask','inputs':{'mask':['3',0]}},'5':{'class_type':'JoinImageWithAlpha','inputs':{'image':['1',0],'alpha':['4',0]}},'6':{'class_type':'SaveImage','inputs':{'images':['5',0],'filename_prefix':'claude_redo/'+key}}}
 pid=post('/prompt',{'prompt':wf})['prompt_id']
 for _ in range(300):
  h=json.loads(urllib.request.urlopen(BASE+'/history/'+pid).read()).get(pid,{})
  ims=[im for v in h.get('outputs',{}).values() for im in v.get('images',[])]
  if ims:break
  if h.get('status',{}).get('status_str')=='error':raise RuntimeError(h['status'])
  time.sleep(1)
 else:raise TimeoutError(key)
 tmp=RAW/(key+'_cutout.png');urllib.request.urlretrieve(BASE+'/view?'+urllib.parse.urlencode(ims[0]),tmp)
 im=Image.open(tmp).convert('RGBA');bounds=im.getchannel('A').point(lambda v:255 if v>32 else 0).getbbox()
 if not bounds:raise ValueError('empty alpha '+key)
 isicon=key=='weak' or key.startswith('relic_')
 w,h=(512,512) if isicon else (768,1152)
 im=im.crop(bounds);im.thumbnail((w-80,h-80),Image.Resampling.LANCZOS)
 final=Image.new('RGBA',(w,h));final.alpha_composite(im,((w-im.width)//2,(h-im.height)//2 if isicon else h-40-im.height));final.save(dest)
 print('CUTOUT '+key,flush=True)
