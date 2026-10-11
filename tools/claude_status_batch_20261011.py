import json, sys
from pathlib import Path
import relic_art_batch as art
ROOT=Path(__file__).resolve().parents[1]
art.RAW=ROOT/'ai/claude_status_cards_20261011'
art.OUT=ROOT/'assets/status/claude_cards_20261011'
for p in [art.RAW,art.OUT]: p.mkdir(parents=True,exist_ok=True)
specs=[('counter','one ancient dark metal shield with outward thorns, muted gold rim, violet reflection'),('barrier','one transparent layered glass shield, three nested facets forming one shield, teal and violet edge glow'),('pain_ledger','one closed aged dark leather ledger with a single red blood droplet on cover, plain cover no writing'),('pain_mirror','one complete antique handheld cracked mirror, aged gold frame, red magical light reflected inside'),('ether_cycle','one circular ring of purple luminous vapour, complete continuous vortex, empty center')]
path=art.RAW/'results.json'
results=json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}
for n,(ident,obj) in enumerate(specs):
 if ident in results and ident not in sys.argv[1:]: continue
 if ident == 'barrier': obj='one medieval heater shield, pointed bottom, silver metal rim, translucent cyan glass shield face, upright front view, violet magic light'
 if ident == 'pain_ledger': obj='a closed leather journal, a closed book seen from front at slight angle, dark brown cover with a small red droplet symbol, one single solid rectangular book block'
 old=results.get(ident,{})
 seed=old.get('seed',111100+n*997)+9973 if ident in sys.argv[1:] else 111100+n*997
 if old: (art.RAW/(ident+'_seed_'+str(old.get('seed','unknown'))+'.json')).write_text(json.dumps(old,indent=2),encoding='utf-8')
 job=dict(id=ident,name=ident,object=obj,seed=seed,prompt='('+obj+':1.7), one isolated fantasy status icon, hand painted dark gothic game illustration, simple readable silhouette, entire object visible, white background, generous margins',negative='text, letters, numbers, words, label, logo, watermark, collage, collection, duplicate, multiple shields, four shields, open book, open pages, unfolded, person, hands, scenery, cropped, photograph, modern equipment')
 try:
  results[ident]=art.generate(job,0)
 except Exception as e: results[ident]=dict(id=ident,state='failed',error=str(e))
 path.write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
 print(ident,results[ident]['state'],flush=True)
