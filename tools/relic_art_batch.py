"""ComfyUI relic staging. Does not modify canonical Content Tool or catalog.
Resumable, deterministic prompts/seeds, numerical screening then human review.
"""
import argparse,json,sys,time,urllib.request,urllib.parse
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/content_tool'))
import content_tool as ct
RAW=ROOT/'ai/relics_20261009_output'
OUT=ROOT/'assets/relics/comfy_batch_20261009'
DOC=ROOT/'docs/proposals/relics_20261009'
BASE='http://127.0.0.1:8188'
USE_GUIDES=False
for p in [RAW,OUT,DOC]:p.mkdir(parents=True,exist_ok=True)

def write(path,data):
    temp=path.with_suffix(path.suffix+'.tmp')
    temp.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    temp.replace(path)

def plan():
    data=json.loads((ROOT/'tools/content_tool/data/content.json').read_text(encoding='utf-8-sig'))
    objects=json.loads((ROOT/'ai/relic_objects_20261009.json').read_text(encoding='utf-8'))
    jobs=[];preserved=[]
    for item in data['relics']:
        if item.get('archived'):continue
        art=item.get('image') or item.get('icon')
        if art:
            preserved.append({'id':item['id'],'name':item['name'],'path':art})
            continue
        _,group,num=item['id'].split('_')
        obj=objects[group][str(int(num))]
        prompt='('+obj+':1.45), (single isolated object:1.35), centered, entire object visible, empty margins, pure white background, hand painted fantasy illustration, aged materials, detailed craftsmanship, clean silhouette'
        jobs.append({'id':item['id'],'name':item['name'],'object':obj,'prompt':prompt,'seed':910000+len(jobs)*997,'rarity':item.get('rarity',''),'state':'queued'})
    write(DOC/'jobs.json',jobs);write(DOC/'preserved.json',preserved)
    return jobs

def screen(im):
    a=np.asarray(im.getchannel('A'))>64
    area=float(a.mean());bbox=im.getchannel('A').point(lambda x:255 if x>64 else 0).getbbox()
    flags=[]
    if not bbox or area<.025:flags.append('empty_or_too_small')
    if area>.82:flags.append('background_not_removed')
    edge=float(np.concatenate([a[:3].ravel(),a[-3:].ravel(),a[:,:3].ravel(),a[:,-3:].ravel()]).mean())
    if edge>.04:flags.append('possible_edge_crop')
    labels,n=ndimage.label(a)
    sizes=np.bincount(labels.ravel())[1:]
    large=int((sizes>max(600, a.sum()*.08)).sum())
    if large>2:flags.append('multiple_disconnected_objects')
    return {'alpha_area':round(area,4),'edge_occupancy':round(edge,4),'large_components':large,'visible_bounds':bbox,'flags':flags}

def generate(job,attempt):
    ident=job['id'];seed=job['seed']+attempt*123457
    negative='(text, letters, typography, words, label, logo, watermark:2.0), (collage, grid, collection, multiple objects, duplicate, sheet, frame, border, card layout, panel:1.6), face, eyes, person, hands, modern plumbing, faucet, cropped, scenery, blurry'
    negative=job.get('negative',negative)
    if 'two plain ivory ceramic cups' in job['object']:
        negative=negative.replace('multiple objects, duplicate, ','')+', three cups, four cups, single cup'
    if ident=='relic_common_007':negative+=', (electronics, connector, electrical plug, headphone, plastic, cable:2.0)'
    exclusions={
        'relic_common_024':'clock, watch, dial, face, numbers, gauge body',
        'relic_common_038':'separate pieces, plant, flower pot, rod, cylinder',
        'relic_common_046':'two lenses, spectacles, binoculars, duplicate lens',
        'relic_uncommon_024':'second vial, empty vial, loose root',
        'relic_uncommon_025':'brush, feather, tassel, pin, quill',
        'relic_uncommon_033':'undivided bowl, four compartments',
        'relic_uncommon_034':'abacus, rods, fence, bars',
        'relic_uncommon_036':'hose, faucet body, pipework',
        'relic_uncommon_040':'three candles, four candles, single candle',
        'relic_rare_016':'two tubes, bottle, hollow white tube',
        'relic_rare_017':'mushroom, separate stamp disk',
        'relic_epic_010':'treble clef, musical note, multiple panels',
        'relic_ancient_002':'full sword, dagger, separate weapon',
        'relic_ancient_005':'flower, sun emblem, star emblem'
    }
    if ident in exclusions:negative+=', ('+exclusions[ident]+':1.7)'
    if ident in ['relic_common_016','relic_common_024','relic_common_034']:negative+=', (seamless texture, pattern, repeated objects, closeup crop:2.0)'
    if 'crystal' not in job['object'] and 'medallion' not in job['object']:negative+=', gems, jewel'
    prompt=job['prompt']+(' Exactly one complete object, distant enough for all edges to fit, empty background.' if attempt else '')
    wf=ct._basic_workflow(prompt,negative,job.get('width',768),job.get('height',768),seed,'sd_xl_base_1.0.safetensors','relics_20261009/'+ident)
    wf['5']['inputs'].update(steps=25,cfg=6.0,sampler_name='dpmpp_2m',scheduler='karras')
    guide=ROOT/'ai/relic_structure_guides'/f'{ident}.png'
    if USE_GUIDES and guide.exists():
        boundary='relicguideboundary'
        body=(f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{ident}_guide.png"\r\nContent-Type: image/png\r\n\r\n'.encode()+guide.read_bytes()+f'\r\n--{boundary}--\r\n'.encode())
        req=urllib.request.Request(BASE+'/upload/image',data=body,headers={'Content-Type':'multipart/form-data; boundary='+boundary})
        uploaded=json.loads(urllib.request.urlopen(req).read())
        wf['12']={'class_type':'LoadImage','inputs':{'image':uploaded['name']}}
        wf['13']={'class_type':'VAEEncode','inputs':{'pixels':['12',0],'vae':['1',2]}}
        wf['5']['inputs'].update(latent_image=['13',0],denoise=.42,cfg=6.5)
        wf['2']['inputs']['text']+=' Professional painted game inventory artifact, three dimensional sculpted volume, rich material texture, realistic highlights, aged craftsmanship, soft studio light, no flat vector shapes.'
    wf['8']={'class_type':'LoadBackgroundRemovalModel','inputs':{'bg_removal_name':'birefnet.safetensors'}}
    wf['9']={'class_type':'RemoveBackground','inputs':{'bg_removal_model':['8',0],'image':['6',0]}}
    wf['10']={'class_type':'InvertMask','inputs':{'mask':['9',0]}}
    wf['11']={'class_type':'JoinImageWithAlpha','inputs':{'image':['6',0],'alpha':['10',0]}}
    wf['7']['inputs']['images']=['11',0]
    write(RAW/f'{ident}_a{attempt}.workflow.json',wf)
    pid=ct._post_json(BASE+'/prompt',{'prompt':wf})['prompt_id']
    for _ in range(900):
        hist=ct._get_json(BASE+'/history/'+pid).get(pid)
        if hist:
            images=[im for node in hist.get('outputs',{}).values() for im in node.get('images',[])]
            if images:break
            if hist.get('status',{}).get('status_str')=='error':raise RuntimeError(str(hist['status']))
        time.sleep(1)
    else:raise TimeoutError(ident)
    source=RAW/f'{ident}_a{attempt}.png'
    urllib.request.urlretrieve(BASE+'/view?'+urllib.parse.urlencode(images[0]),source)
    im=Image.open(source).convert('RGBA');qa=screen(im)
    bounds=im.getchannel('A').point(lambda x:255 if x>28 else 0).getbbox()
    if not bounds:raise ValueError('empty alpha')
    ow,oh=job.get('output_size',[512,512])
    im=im.crop(bounds);im.thumbnail((ow-64,oh-64),Image.Resampling.LANCZOS)
    canvas=Image.new('RGBA',(ow,oh));canvas.alpha_composite(im,((ow-im.width)//2,(oh-im.height)//2));canvas.save(OUT/f'{ident}.png')
    return {'id':ident,'name':job['name'],'path':'res://assets/relics/comfy_batch_20261009/'+ident+'.png','source':str(source),'seed':seed,'attempt':attempt,'qa':qa,'state':'needs_review','object':job['object']}

def sheets(jobs,results):
    font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',15)
    for start in range(0,len(jobs),24):
        sub=jobs[start:start+24]
        sheet=Image.new('RGB',(1440,1000),'#19151f');draw=ImageDraw.Draw(sheet)
        for i,j in enumerate(sub):
            x=i%6*240;y=i//6*250
            path=OUT/(j['id']+'.png')
            if path.exists():
                im=Image.open(path).convert('RGBA');im.thumbnail((195,195));sheet.paste(im,(x+22,y+8),im)
            draw.text((x+8,y+208),j['name'],font=font,fill='#eee1c8')
            draw.text((x+8,y+229),j['id'],font=font,fill='#b6a587')
        sheet.save(DOC/f'review_{start//24+1:02}.png')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--retry',nargs='*');ap.add_argument('--limit',type=int);ap.add_argument('--review-only',action='store_true');ap.add_argument('--guides',action='store_true');args=ap.parse_args()
    USE_GUIDES=args.guides
    jobs=plan();journal=DOC/'results.json'
    results=json.loads(journal.read_text(encoding='utf-8')) if journal.exists() else {}
    print(f'PLAN {len(jobs)} missing relics; canonical data untouched',flush=True)
    if not args.review_only:
        ct._get_json(BASE+'/system_stats')
        count=0
        for i,j in enumerate(jobs):
            if args.retry is not None and j['id'] not in args.retry:continue
            previous=results.get(j['id'])
            if args.retry is None and previous and previous.get('path') and (OUT/(j['id']+'.png')).exists():continue
            if args.limit and count>=args.limit:break
            count+=1
            attempt=previous.get('attempt',-1)+1 if previous else 0
            print(f'START {i+1}/{len(jobs)} {j["id"]}',flush=True)
            try:
                result=generate(j,attempt)
                if result['qa']['flags']:result=generate(j,attempt+1)
                results[j['id']]=result
                print('DONE '+j['id']+' '+str(result['qa']['flags']),flush=True)
            except Exception as e:
                results[j['id']]={'id':j['id'],'error':str(e),'state':'failed','attempt':attempt}
                print('FAILED '+j['id']+' '+str(e)[:200],flush=True)
            write(journal,results)
            if (i+1)%12==0:sheets(jobs,results)
    sheets(jobs,results)
    print('STAGED '+str(sum('path' in r for r in results.values()))+'/'+str(len(jobs)),flush=True)
