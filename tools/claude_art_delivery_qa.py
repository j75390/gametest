import json, hashlib
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
checks=[]
for manifest in ["CLAUDE_EVENT_ART_MAPPING_20261011.json","CLAUDE_ICON_ART_MAPPING_20261011.json"]:
 for item in json.loads((root/"docs/proposals"/manifest).read_text(encoding="utf-8")):
  path=Path(item["path"]);im=Image.open(path)
  isevent="events" in path.parts
  assert im.size==((1024,1536) if isevent else (512,512)),str(path)
  if not isevent: assert im.mode=="RGBA" and im.getchannel("A").getextrema()[0]==0,str(path)
  family="claude_events_20261011" if isevent else "claude_monsters_20261011"
  result=json.loads((root/"ai"/family/"results.json").read_text(encoding="utf-8"))[item["id"]]
  assert result["seed"]==item["seed"],"stale seed: "+item["id"]
  checks.append(item["id"])
redo=root/"docs/proposals/CLAUDE_REDO_ART_MAPPING_20261011.json"
if redo.exists():
 for item in json.loads(redo.read_text(encoding="utf-8")):
  path=Path(item["path"]);im=Image.open(path)
  assert item['verdict']=='pass' and list(im.size)==item['size'],item['id']
  assert hashlib.sha256(path.read_bytes()).hexdigest()==item['sha256'],item['id']
  if item['category']!='events':
   assert im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0,item['id']
   box=im.getchannel('A').point(lambda v:255 if v>32 else 0).getbbox()
   assert box and box[0]>=30 and box[1]>=30 and box[2]<=im.width-30 and box[3]<=im.height-30,item['id']
  checks.append(item['id'])
 assert len(checks)==len(set(checks))==53,'missing or duplicate delivery ids'
print("PASS",len(checks),"reviewed delivery files: dimensions, alpha, current seeds")
