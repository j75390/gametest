"""Stage Claude-requested hub illustrations through local ComfyUI only."""
import json
import sys
from pathlib import Path
import relic_art_batch as art
root=Path(__file__).resolve().parents[1]
art.RAW=root/'ai/claude_hub_20261010'; art.OUT=root/'assets/ui/claude_hub_20261010'
art.RAW.mkdir(parents=True,exist_ok=True);art.OUT.mkdir(parents=True,exist_ok=True)
objects={
 'cards':'three overlapping enchanted purple playing cards, illustrated magical violet vortex on each card, no writing, thick aged brass corners',
 'relics':'one open antique wooden treasure chest containing an ornate crescent pendant and bronze bell, aged brass fittings, violet glow',
 'potions':'one compact antique alchemical distillation apparatus, glass flask of purple liquid connected by a curved glass tube to a green glass receiver, brass stand, medieval laboratory equipment',
 'monsters':'one antique parchment bestiary folio open to an ink illustration of a horned skeletal beast, aged leather binding, only creature illustration and no handwriting',
 'chronicle':'one closed ancient leather chronicle book, brass clasps and purple wax seal, small luminous violet crystal embedded in cover, no lettering',
}
results=json.loads((art.RAW/'results.json').read_text(encoding='utf-8')) if (art.RAW/'results.json').exists() else {}
for i,(ident,obj) in enumerate(objects.items()):
 if len(sys.argv)>1 and ident not in sys.argv[1:]:continue
 job={'id':'hub_'+ident,'seed':10101000+i*997,'name':ident,'object':obj,'prompt':obj+', single centered composition, entire object visible with generous empty margins, pure white background, richly painted gothic fantasy game illustration, detailed aged materials, dramatic violet and warm candlelight accents, clear readable silhouette, no text'}
 print('START '+ident,flush=True)
 if ident=='potions':job['prompt']='one antique brass alchemy stand holding a round purple potion bottle with completely smooth blank glass, a curved blank glass tube, no measurement marks, no inscriptions, medieval fantasy inventory illustration, entire apparatus centered, pure white background, purple and gold materials, hand painted'
 results[ident]=art.generate(job,1 if len(sys.argv)>1 else 0)
 (art.RAW/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
 print('DONE '+ident,flush=True)
