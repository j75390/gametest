import hashlib,json
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
rows=json.loads((root/'docs/proposals/CLAUDE_MIRA_CARD_MAPPING_20261011.json').read_text(encoding='utf-8-sig'))
assert len(rows)==38 and len({r['id'] for r in rows})==38
for r in rows:
    p=Path(r['path'])
    assert r['verdict']=='pass' and p.name.endswith('_v2.png')
    assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256']
    with Image.open(p) as im:
        assert im.size==(1254,1254)
        im.verify()
assert len(list((root/'ai/claude_mira_cards_20261011/withdrawn_portrait_v1').glob('*.png')))==38
report={'cards':38,'unique_ids':38,'size':[1254,1254],'sha256_and_decode':'pass','preserved_v1':38,'runtime_applied':False}
(root/'docs/proposals/MIRA_V2_DELIVERY_VALIDATION_20261011.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(report)
