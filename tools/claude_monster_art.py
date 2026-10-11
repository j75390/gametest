"""Claude ACT I enemies and status icon staging, local ComfyUI."""
import json,sys
from pathlib import Path
import relic_art_batch as art
root=Path(__file__).resolve().parents[1]
art.RAW=root/'ai/claude_monsters_20261011';art.OUT=root/'assets/monsters/claude_20261011'
art.RAW.mkdir(parents=True,exist_ok=True);art.OUT.mkdir(parents=True,exist_ok=True)
objects={
'round_doll':'one full body articulated wooden nursing doll in faded grey night shift uniform and apron, cloth completely covering face, visible wooden joints, one hand holds a small wooden approval stamp, both feet visible, standing',
'waiting_patient':'one full body stooped elderly hospital patient in worn long grey gown, covered face, one arm extended gently forward with ash in palm, tired posture, two feet in worn slippers visible',
'lamp_pilgrim':'one full body hooded pilgrim in repaired dark grey cloak, face hidden, cradling a small lit warm lantern at chest in one hand, simple walking staff in other hand, boots visible',
'recovery_agent':'one full body medieval bureaucratic investigator wearing a long dark grey coat and broad hat hiding face, heavy ledger satchel with paper protruding, holds confiscation stamp and a cord, worn boots visible',
'seal_clerk':'one full body gaunt clerk in faded grey medieval uniform, very long thin arms, holding a single oversized wooden stamp, ink stains on sleeve, obscured face, worn shoes visible',
'convoy_armor':'one full body hollow medieval convoy armor, empty black visor, asymmetrical rusty shield, plain worn shoulder insignia, heavy boots visible, standing guard',
'ash_warden_elite':'one full body tall gothic armored cathedral veteran guard, dark old plate armor covered with grey incense ash, carrying a heavy brass censer, red faded torn cloth, boots visible, upright guard stance',
'convoy_captain':'one full body medieval convoy captain, bent feather on closed helmet, holds a plain ledger board in one hand and broad shield in the other, dark grey armor and worn brown boots',
'first_volunteer':'one full body elderly priest in worn ash grey vestments, hands clasped in prayer, ash trickling from cloth, peaceful sad partly hidden face, dark boots visible, no gore',
'head_nurse':'one full body head nurse wearing angular grey linen hood and long apron, rigid straight posture, prescription board in one hand and large antique scissors in other, face obscured, shoes visible',
'shaft_keeper':'one full body bulky medieval freight elevator worker, heavy brown work clothes wrapped with rusty chains, one hand holding an iron ventilation valve wheel, face shadowed, large boots visible',
'ash_warden_boss':'one full body massive cathedral gatekeeper in black gothic plate armor, carrying a whole heavy ancient door as a shield, dead embers trapped in armor joints, dark red cloak, massive boots visible',
'weak':'one single old bent sword with curved drooping blade, intact dull sword, tired sagging cloth wrapped around hilt, single object, muted dusty purple and grey',
'vulnerable':'(one shattered plain shield split by a huge jagged crack:1.8), no coat of arms, single object, aged brass and dark grey metal',
'strength':'one tightly clenched armored gauntlet fist, warm amber glow between fingers, single object, aged bronze and dark metal',
'relic_uncommon_002':'one small antique bronze shift bell with a short wooden handle and faded purple cord, blank undecorated surface, entire bell visible',
'relic_uncommon_005':'one single circular brass pocket watch with white clock face and two dark hands, closed case, front view, no numerals',
'relic_uncommon_007':'one hinged double-sided antique brass prescription plate opened like a diptych, two ivory panels, abstract plant engraving on one and short tally strokes on other, purple worn cord',
'relic_uncommon_010':'one conical pointed iron plumb bob suspended from one short rope, pointed tip facing down',
'relic_uncommon_018':'(one folded sheet of solid black paper:1.8), opaque charcoal paper, torn fibrous edges, no holes, no frame'
}
journal=art.RAW/'results.json';results=json.loads(journal.read_text()) if journal.exists() else {}
selected=set(sys.argv[1:])
for i,(ident,obj) in enumerate(objects.items()):
 if selected and ident not in selected:continue
 if not selected and ident in results:continue
 attempt=results.get(ident,{}).get('attempt',-1)+1
 job={'id':ident+'_v1','name':ident,'seed':11140000+i*997,'object':obj,'prompt':obj+', (single isolated figure:1.4), front three quarter view, complete silhouette, generous white empty margin around entire object, entire body and feet in frame, pure white background, detailed dark gothic fantasy oil painting, aged materials, ash grey and faded violet shadows, subtle warm amber accent, no letters, no scenery'}
 job['prompt']='(realistic oil painting:1.5), '+job['prompt']
 if ident in ['weak','vulnerable','strength'] or ident.startswith('relic_'):
  job['prompt']='('+obj+':1.8), single isolated object, centered on plain white background, complete object with empty margins, detailed hand painted gothic fantasy inventory icon'

 job['negative']='(text, letters, numbers, logo, watermark:2), (cartoon, comic, anime, thick outlines:1.6), cropped feet, cropped head, portrait, multiple figures, extra limbs, extra hands, malformed fingers, gore, scenery, border, collage'
 if ident in ['weak','vulnerable','strength'] or ident.startswith('relic_'):
  job['negative']+=', person, human, standing figure, body, legs, clothing, scenery, duplicate objects, collage, grid, collection, exploded view, parts diagram'
 if ident not in ['weak','vulnerable','strength'] and not ident.startswith('relic_'):
  job.update(width=768,height=1152,output_size=[768,1152])
  job['prompt']='('+obj+':1.9), full length standing figure with both feet visible, isolated white background, realistic gothic fantasy illustration, detailed professional tools and costume, complete silhouette'

  job['negative']+=', (portrait, headshot, bust, closeup, seated, sitting:2)'
 print('START '+ident,flush=True);results[ident]=art.generate(job,attempt)
 journal.write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8');print('DONE '+ident,flush=True)
