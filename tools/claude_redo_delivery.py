"""Package the 17 manually inspected replacements; never change canonical data."""
import json, hashlib, shutil
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
RAW=ROOT/'ai/claude_redo_20261011'
DEL=ROOT/'assets/delivery/claude_20261011'
reasons={
 'round_doll':'Covered face, articulated doll hands, nursing uniform and confirmation stamp; full shoes.',
 'waiting_patient':'Bent waist and reaching ash-filled hand, worn ward gown; coherent legs and feet.',
 'lamp_pilgrim':'Lantern cradled at chest, faint flame, opposite hand on staff; hood and full boots.',
 'recovery_agent':'Large open ledger satchel with papers/fragments, stamp, cord and obscuring hat.',
 'seal_clerk':'Long arms holding huge rectangular-based stamp; downward cuff ink and full feet.',
 'convoy_armor':'Empty dark visor, low broad armor, rusty shield and geometric shoulder mark. Background-foot residue corrected.',
 'ash_warden_elite':'Tall narrow warden family armor, caked grey ash and hanging censer; full boots.',
 'convoy_captain':'Bent helmet plume, blank ledger board, visible fingers and separate shield; upright stance.',
 'first_volunteer':'Joined prayer hands, calm sad face, worn robes and ash trails; both complete shoes.',
 'head_nurse':'Angular hood, apron, blank prescription board and large scissors; straight stance and full shoes.',
 'shaft_keeper':'Stocky worker, torso chains and distinct valve wheel; workwear and complete heavy boots.',
 'ash_warden_boss':'Massive warden family, complete timber door with hinges and handle, ember seams and full boots.',
 'weak':'Exactly one sagging bent sword, no duplicates or lettering; legible small silhouette.',
 'relic_uncommon_005':'One coherent hinged pocket watch, two hands and plain grooves; no numerals or fake text.',
 'common_act1_05':'Two scale pans; plain metal tag on pan, bread behind; textured gothic scene, no text.',
 'common_act1_26':'Overturned wagon, spilled crates/sacks and wheel ruts toward cathedral; no choice-result imagery.',
 'common_act1_28':'Extinguished black wick without flame, praying monk back view; cold moonlit painted scene.'
}
rows=json.loads((RAW/'sources.json').read_text(encoding='utf-8-sig'))
assert set(reasons)=={r['id'] for r in rows}
manifest=[]
for row in rows:
 key=row['id'];src=Path(row['source']);shutil.copy2(src,RAW/(key+'_approved_source.png'))
 if key.startswith('common_act1_'):
  cat='events';name=key+'.png';size=(1024,1536)
  dest=DEL/cat/name;dest.parent.mkdir(parents=True,exist_ok=True)
  Image.open(src).convert('RGB').resize(size,Image.Resampling.LANCZOS).save(dest)
 else:
  cat='status' if key=='weak' else 'relics' if key.startswith('relic_') else 'monsters'
  name=key+'.png' if cat=='relics' else key+'_v2.png';size=(512,512) if cat!='monsters' else (768,1152)
  dest=DEL/cat/name;dest.parent.mkdir(parents=True,exist_ok=True)
  shutil.copy2(ROOT/'assets/monsters/claude_redo_20261011'/(key+'_v2.png'),dest)
 im=Image.open(dest);assert im.size==size,(key,im.size)
 if cat!='events':
  assert im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0,key
  box=im.getchannel('A').point(lambda v:255 if v>32 else 0).getbbox()
  assert box and box[0]>=30 and box[1]>=30 and box[2]<=size[0]-30 and box[3]<=size[1]-30,(key,box)
 manifest.append({'id':key,'category':cat,'path':str(dest.resolve()),'source':str(src),'method':'built-in imagegen; local ComfyUI BiRefNet cutout for sprites/icons','verdict':'pass','reason':reasons[key],'size':list(size),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
(RAW/'manual_review.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'docs/proposals/CLAUDE_REDO_ART_MAPPING_20261011.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(1440,1260),'#adb6b6');draw=ImageDraw.Draw(sheet)
for i,item in enumerate([m for m in manifest if m['category']=='monsters']):
 im=Image.open(item['path']);im.thumbnail((225,355));x=i%6*240;y=i//6*420
 sheet.paste(im,(x+(240-im.width)//2,y),im);draw.text((x+4,y+360),item['id'],fill='black')
for i,item in enumerate([m for m in manifest if m['category']=='events']):
 im=Image.open(item['path']);im.thumbnail((230,355));x=i*240;y=840;sheet.paste(im,(x,y));draw.text((x+4,y+360),item['id'],fill='black')
for i,item in enumerate([m for m in manifest if m['category'] in ['status','relics']]):
 im=Image.open(item['path']);im.thumbnail((220,220));x=720+i*240;y=860;sheet.paste(im,(x,y),im);draw.text((x+4,y+260),item['id'],fill='black')
sheet.save(ROOT/'docs/proposals/CLAUDE_REDO_REVIEW_20261011.jpg')
print('PASS 17 replacements: manual decisions, dimensions, alpha, margins, SHA256 manifest')
