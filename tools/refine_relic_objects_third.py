import json
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'ai/relic_objects_20261009.json'
d=json.loads(p.read_text(encoding='utf-8'))
changes={
'common':{7:'two tiny soft beige wool balls attached to opposite ends of a short brown string, antique textile, entire short cord visible',16:'one red candle wax lump, a solid irregular rounded red blob with a flat bottom, single wax nugget',20:'a small blank rectangular ochre parchment slip with clipped corners and one punched round hole, empty tan paper surface',24:'a loose brass gauge pointer, a single long thin pointed triangular strip with a small round mounting hole at its broad end',34:'one small crumpled brown linen rag, soft draped fabric folds, entire loose textile visible',37:'one single brown leather glove with five finger sleeves, no second glove, entire glove visible',38:'one small blank wooden rectangular tag with a short pointed spike attached at its bottom, a single plant marker',46:'one round glass lens in a broken brass rim with one short bent side arm, a single broken lens',51:'a loose thin curved metal carrying bail, narrow brass wire formed into a semicircle, a small hook at each end'},
'uncommon':{4:'a blank rectangular ochre parchment slip with scalloped edges, a tiny red wax blob stuck on the corner, unmarked tan paper',16:'a single wooden hand stamp, short brown handle and circular brass bottom, small anchor engraved into its brass face',17:'two plain ivory ceramic cups side by side joined by a short brown cord, complete pair of cups only',19:'a folded blank ochre parchment sheet, tiny purple wax blob on a folded corner, unmarked tan paper',20:'a single small wooden bobbin wound with shining thin silver wire, one tiny green sprig tucked into the wire',24:'a sealed amber glass specimen tube containing a dry brown root clipping, cylindrical glass tube with visible thick rims and cork cap',25:'a single long silver sewing needle with a short purple thread through a tiny hole at its blunt end'}
}
for group,items in changes.items():
    for num,desc in items.items():d[group][str(num)]=desc
p.write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf-8')
print('REFINED',sum(map(len,changes.values())))
