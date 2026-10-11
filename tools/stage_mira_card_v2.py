"""Stage individually reviewed card art, without touching game data."""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('id')
p.add_argument('source')
p.add_argument('--verdict', choices=['pass', 'reject'], required=True)
p.add_argument('--reason', required=True)
p.add_argument('--prompt', default='')
a = p.parse_args()
work = ROOT / 'ai/claude_mira_cards_v2_20261011'
work.mkdir(parents=True, exist_ok=True)
source = Path(a.source)
im = Image.open(source)
record = dict(id=a.id, source=str(source), source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(), verdict=a.verdict, reason=a.reason, prompt=a.prompt, method='built_in_imagegen')
if a.verdict == 'pass':
    dest = ROOT / 'assets/delivery/claude_20261011/cards' / (a.id + '_v2.png')
    dest.parent.mkdir(parents=True, exist_ok=True)
    assert abs(im.width / im.height - 1) < .01, 'Card must be square, never crop anatomy to fix aspect'
    im.convert('RGB').resize((1254, 1254), Image.Resampling.LANCZOS).save(dest)
    record.update(path=str(dest), size=[1254,1254], sha256=hashlib.sha256(dest.read_bytes()).hexdigest())
path = work / 'manual_review.json'
rows = json.loads(path.read_text(encoding='utf-8')) if path.exists() else []
rows = [r for r in rows if r['id'] != a.id] + [record]
path.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
passed = [r for r in rows if r['verdict'] == 'pass']
(ROOT/'docs/proposals/CLAUDE_MIRA_CARD_MAPPING_20261011.json').write_text(json.dumps(passed, ensure_ascii=False, indent=2), encoding='utf-8')
print(a.id, a.verdict, len(passed), 'passed; integration reserved for Claude')

