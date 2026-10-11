"""Resumable staging for Claude ACT I event art, no canonical writes."""
import sys,json,time,urllib.request,urllib.parse
from pathlib import Path
from PIL import Image,ImageDraw
sys.path.insert(0,str(Path(__file__).resolve().parent/'content_tool'))
import content_tool as ct
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'assets/events/claude_20261011'; RAW=ROOT/'ai/claude_events_20261011'
OUT.mkdir(parents=True,exist_ok=True);RAW.mkdir(parents=True,exist_ok=True)
scenes=[
'A hooded peddler at a small wooden stall examining empty glass medicine bottles, brown sediment in the bottles, hospital corridor behind, side view',
'A stack of clean cloth bandages on a delivery cart, blank parchment shipping tag with a rectangular hole cut out, cathedral ward doorway',
'An elderly caregiver in profile sewing the sleeve of an old coat beside a candle, many identical repaired coats hanging behind, quiet hospital room',
'A tiny folded patchwork blanket under an empty iron hospital bed, visible careful stitching in different cloth pieces, close low angle',
'A ration counter with a brass balance scale, bread loaf and blank metal identification tokens beside the scale, hooded clerk in profile',
'An old disinfection room, cold metal basin bubbling without a flame, iron forceps beside it, blank fogged glass partition, subdued candle',
'A woman in side profile sharing candle flames in a small chapel, many short and long candles, one small warm flame',
'A nun seen from behind stirring a cauldron of soup in a stone kitchen, wooden bowls in a line, no steam despite warm glow',
'An empty wooden confessional booth with a lattice divider, one empty chair on each side, a faint shadow through the lattice, quiet candle',
'A hospital return counter piled with worn walking sticks and round spectacles, empty clerk chair, no writing anywhere',
'A weary bell keeper standing beside a motionless hanging rope, open palm counting fingers, tower interior, bell hidden in shadow',
'Many different sizes of worn shoes arranged in pairs on a hospital threshold, soles worn on the same side, low perspective',
'An aged medical record sheet turned over on a desk, blank parchment surface, simple identical wax seals on either side, candlelight',
'A narrow mail slot among old bricks, one clean folded letter entering and one damp crumpled letter below, dripping wall',
'A locked wooden medicine cabinet filled with identical purple glass bottles, rusty key hanging beside the lock, old ward',
'A few worn metal tokens on the hospital floor, blank faceless circular surfaces, caregiver shadow nearby, close view',
'A silent emergency ward, patients seated far apart sketching abstract shapes on paper, wrapped faces in side view, no visible writing',
'A half burned blank prescription sheet in cold fireplace ashes, edges curling inward, one dying ember, close still life',
'A faded clock in a hospital waiting room, blank circular dial with an erased pale patch, weary visitor from behind',
'A modest makeshift clinic outside a cathedral, diluted medicine bottles and basin of water, repaired cloth awning, healer from behind',
'Behind a hospital guard station an industrial medieval freight elevator with rusty chains, open blank ledger and six plain bed tokens, no people',
'An old repaired coat hung inside a ward, turned out lining with small purple alchemical stains and careful stitching, candlelight, no text',
'At the foot of a ruined fortress a refugee holding a torn blank travel pass with a simple sword wax seal, face in shadow',
'An astronomer desk with a blank star chart drawn only with points and connecting lines, one disconnected point, parchment corner mysteriously folded',
'A traveling caregiver wrapping a patient arm with clean bandage, plain oil bottle left unopened, patient turning away from a small sacred emblem',
'Collapsed wooden choir railing in a cathedral, sheets of blank music parchment visible inside a narrow dark gap, dust and candlelight',
'An abandoned ash-covered pulpit with an open blank sermon manuscript, trailing ash across the pages, dark gothic nave',
'An abandoned apothecary storeroom with many wooden drawers, empty brass label holders, herbs and dusty glass bottles, narrow perspective',
'A rusted half erased heraldic shield above a stone gateway, humble bundles and worn blankets at the base, cold dusk',
'A dry courtyard well behind a cathedral, wet bucket rope glistening though no water below, one nearby lantern',
'An overturned relief cart with scattered cloth packages and bread, a single wheel rut leading toward the cathedral entrance, twilight',
'A silent armored patrol standing motionless like a statue before a fortress gate, dark visor, no weapon raised, tall full scene',
'A monk seen from behind praying all night before an extinguished candleholder, cold wax and unlit wick clearly visible, moonlit chapel'
]
ids=[f'common_act1_{i:02}' for i in range(1,21)]+['act1_ledger','mira_coat','kalian_personal_1','sera_personal_1','lucian_personal_1']+[f'common_act1_{i:02}' for i in range(21,29)]
overrides={
'common_act1_02':'Close view of a pile of white rolled bandages with a large blank parchment tag, a square hole visibly cut through the tag, on a wooden cart in a medieval ward',
'common_act1_03':'Close view of one elderly caregiver sewing a worn grey coat sleeve by candlelight, needle and thread touching the sleeve, identical coats hanging behind',
'common_act1_04':'Close still life of one neatly folded tiny patchwork blanket made from many sewn cloth squares, under an empty iron hospital bed, low perspective',
'common_act1_05':'One simple antique brass balance scale standing on a dark wooden table, exactly two hanging pans attached to one straight horizontal crossbar, bread loaf beside its base, a plain metal tag on table',
'common_act1_06':'Close still life of a round antique copper cauldron filled with bubbling cold water, long iron forceps resting across its rim, old stone disinfection room, cauldron sitting directly on wooden table',
'common_act1_08':'A nun stirring thick soup inside a large black cooking pot with a wooden spoon, three bowls of soup on the counter, medieval stone kitchen, no flames above pot',
'common_act1_10':'Close still life on a medieval hospital wooden return counter, pile of worn walking sticks and two round brass spectacles together, empty chair behind',
'common_act1_11':'One elderly bell keeper alone in an ancient stone bell tower, hands held open at chest, staring at his empty palm, untouched rope hanging far behind him',
'common_act1_13':'One blank folded ivory parchment sheet sitting alone on a dark worn wooden tabletop, one small red wax seal on each side of the paper, simple still life, no other documents',
'common_act1_14':'Close still life of a narrow horizontal dark mail slit in an old brick wall, wet folded blank envelopes piled underneath, no exposed pages',
'common_act1_17':'A quiet medieval infirmary inside an old stone cathedral, three patients with cloth wrapped mouths seated separately on wooden benches, holding blank paper, candles only, gothic arches',
'common_act1_19':'One antique brass clock with entirely blank worn dial and faded white patch hanging on a rough stone cathedral infirmary wall, empty wooden visitor bench underneath, candlelight',
'common_act1_20':'A small medieval healer tent outside an old gothic cathedral, repaired canvas awning, wooden table with tiny antique glass potion vials and earthenware water pitcher, hooded healer in side view',
'common_act1_21':'A pile of snapped wooden beams and splintered planks on an old cathedral floor, blank ivory paper sheets caught among the broken wood, low close perspective, dark arches in background',
'common_act1_23':'One antique wooden apothecary chest with six large plain drawers, completely blank drawer fronts with simple brass handles, one open drawer filled with dried herbs, dark stone storeroom',
'common_act1_26':'Broken wooden wagon wreckage with two detached wheels and scattered cloth relief bundles on cathedral courtyard paving, bread fallen onto ground, low close view, ruined cart frame tilted sideways',
'common_act1_28':'A monk praying in a dark stone chapel before an extinguished brass candleholder, melted wax stump, short black wick, no flames anywhere, moonlight only',
}
journal=RAW/'results.json';results=json.loads(journal.read_text()) if journal.exists() else {}
selected=set(sys.argv[1:]);use_guides='--guides' in selected;selected.discard('--guides'); retry=bool(selected)
for i,(ident,scene) in enumerate(zip(ids,scenes)):
 if selected and ident not in selected:continue
 if not retry and ident in results and (OUT/f'{ident}.png').exists():continue
 attempt=results.get(ident,{}).get('attempt',-1)+1;seed=11100000+i*997+attempt*123457
 scene=overrides.get(ident,scene)
 prompt='('+scene+':1.5), (realistic oil painting:1.3), dark gothic fantasy, intricate material textures, ash grey and desaturated violet shadows, one small warm light accent, quiet subtle unease, vertical composition, blank unmarked objects'
 negative='(text, lettering, words, numbers, watermark, signature, artist signature, logo, caption, writing, bottle labels:2.3), (cartoon, comic, anime, cel shading, flat vector, line drawing, thick outlines:1.6), UI, frame, border, collage, split panels, modern hospital, modern plumbing, faucet, electrical equipment, gore, blood, front portrait, extra limbs, deformed hands, blurry'
 wf=ct._basic_workflow(prompt,negative,768,1152,seed,'sd_xl_base_1.0.safetensors','claude_events_20261011/'+ident)
 wf['5']['inputs'].update(steps=28,cfg=6,sampler_name='dpmpp_2m',scheduler='karras')
 guide=RAW/f'{ident}_guide.png'
 if use_guides and guide.exists():
  b='eventguideboundary';body=(f'--{b}\r\nContent-Disposition: form-data; name="image"; filename="{guide.name}"\r\nContent-Type: image/png\r\n\r\n'.encode()+guide.read_bytes()+f'\r\n--{b}--\r\n'.encode())
  uploaded=json.loads(urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8188/upload/image',data=body,headers={'Content-Type':'multipart/form-data; boundary='+b})).read())['name']
  wf['12']={'class_type':'LoadImage','inputs':{'image':uploaded}}
  wf['13']={'class_type':'VAEEncode','inputs':{'pixels':['12',0],'vae':['1',2]}}
  wf['5']['inputs'].update(latent_image=['13',0],denoise=.45)
 (RAW/f'{ident}_a{attempt}.workflow.json').write_text(json.dumps(wf,indent=2),encoding='utf-8')
 print('START '+ident,flush=True);pid=ct._post_json('http://127.0.0.1:8188/prompt',{'prompt':wf})['prompt_id']
 for _ in range(900):
  hist=ct._get_json('http://127.0.0.1:8188/history/'+pid).get(pid,{})
  images=[im for node in hist.get('outputs',{}).values() for im in node.get('images',[])]
  if images:break
  if hist.get('status',{}).get('status_str')=='error':raise RuntimeError(hist['status'])
  time.sleep(1)
 else:raise TimeoutError(ident)
 raw=RAW/f'{ident}_a{attempt}.png';urllib.request.urlretrieve('http://127.0.0.1:8188/view?'+urllib.parse.urlencode(images[0]),raw)
 Image.open(raw).convert('RGB').resize((1024,1536),Image.Resampling.LANCZOS).save(OUT/f'{ident}.png')
 results[ident]={'seed':seed,'attempt':attempt,'path':str(OUT/f'{ident}.png'),'state':'needs_review','scene':scene}
 journal.write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8');print('DONE '+ident,flush=True)
 for start in range(0,len(ids),9):
  sheet=Image.new('RGB',(720,1152),'#26232a');d=ImageDraw.Draw(sheet)
  for j,key in enumerate(ids[start:start+9]):
   p=OUT/f'{key}.png'
   if not p.exists():continue
   x=(j%3)*240;y=(j//3)*384;sheet.paste(Image.open(p).resize((232,348)),(x,y));d.text((x+4,y+351),key,fill='white')
  sheet.save(RAW/f'review_{start//9+1:02}.png')
