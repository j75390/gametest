"""Package reviewed design-sync assets for Claude; do not modify canonical data."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
from prepare_mira_design_sync import ROOT, BASE, NAMES

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def write(path, value):
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2),encoding='utf-8')

def main():
    reviews = read(BASE/'manual_decisions_final.json')
    checked = {}
    for row in reviews:
        path = BASE/row['path']
        assert path.exists(), row['path']
        checked[row['path']] = {**row,'sha256':digest(path),'size':list(Image.open(path).size)}
    assert checked['sd/idle_v4.png']['verdict'] == 'pass'
    cards = []
    for row in read(BASE/'generation_records.json')['cards']:
        id = row['id']
        rel = 'cards/'+id+'_design_v3.png'
        check = checked[rel]
        assert check['verdict'] == 'pass', id
        path=BASE/rel
        cards.append({'id':id,'path':str(path),'resource_path':'res://'+path.relative_to(ROOT).as_posix(),
                      'sha256':digest(path),'reason':check['reason'],'verdict':'pass',
                      'replaces':row['source'],'size':check['size']})
    frames = []
    for name in NAMES:
        rawrel='pixel/'+name+'_raw.png'
        assert checked[rawrel]['verdict']=='pass',name
        path=BASE/'pixel'/(name+'.png')
        im=Image.open(path).convert('RGBA')
        assert im.size==(320,192),name
        bounds=im.getchannel('A').getbbox()
        assert bounds and bounds[0]>0 and bounds[1]>0 and bounds[2]<320 and bounds[3]<192,name
        frames.append({'id':name,'path':str(path),'resource_path':'res://'+path.relative_to(ROOT).as_posix(),
                       'sha256':digest(path),'raw_sha256':checked[rawrel]['sha256'],
                       'reason':checked[rawrel]['reason'],'verdict':'pass','size':[320,192],
                       'bounds':list(bounds)})
    assert len({r['sha256'] for r in frames})==12,'duplicate frames'
    def timeline(*entries):
        return [{'path':next(r['resource_path'] for r in frames if r['id']==name), 'duration':duration}
                for name,duration in entries]
    motions={
      'idle':timeline(('idle',2.4),('idle_blink',.13)),
      'walk':timeline(('walk_a',.16),('walk_pass',.12),('walk_b',.16),('walk_pass',.12)),
      'attack':timeline(('attack_prepare',.18),('attack_release',.30),('idle',.18)),
      'skill':timeline(('skill_charge',.32),('skill_release',.48),('idle',.18)),
      'hurt':timeline(('hurt',.26),('idle_blink',.12),('idle',.14)),
      'death':timeline(('hurt',.16),('death_fall',.30),('death_rest',1.2))}
    mapping={'character':'mira','runtime_applied':False,'cards':cards,'pixel_frames':frames,
             'proposed_motions':motions,'sd_reference':{'path':str(BASE/'sd/idle_v4.png'),
             'sha256':checked['sd/idle_v4.png']['sha256'],'verdict':'pass'},
             'renderer_notes':'Common 320x192 alpha canvas. Nearest filtering; keep aspect and ground pivot y=180. Do not trim per-frame alpha or independently scale frames. These are six short key-pose timelines, not smooth high-frame animation.'}
    write(BASE/'manual_review.json',list(checked.values()))
    write(ROOT/'docs/proposals/CLAUDE_MIRA_DESIGN_SYNC_20261011.json',mapping)
    # Latest combined card list: 38 prior v2 entries with two costume overrides,
    # plus three corrected starter/core entries. No source art is overwritten.
    combined={r['id']:r for r in read(ROOT/'docs/proposals/CLAUDE_MIRA_CARD_MAPPING_20261011.json')}
    for row in cards:
        combined[row['id']]=row
    assert len(combined)==41
    write(ROOT/'docs/proposals/CLAUDE_MIRA_CARD_MAPPING_DESIGN_SYNC_20261011.json',list(combined.values()))
    sheet=Image.new('RGB',(1560,940),'#201b28')
    draw=ImageDraw.Draw(sheet)
    for i,row in enumerate(cards):
        im=Image.open(row['path']).convert('RGB')
        tile=ImageOps.contain(im,(500,420))
        x,y=(i%3)*520,(i//3)*470
        sheet.paste(tile,(x+(500-tile.width)//2,y+35+(420-tile.height)//2))
        draw.text((x+10,y+10),row['id'],fill='#e8d9bf')
    sheet.save(BASE/'card_review.jpg',quality=94)
    report={'result':'PASS','cards_modified':5,'pixel_frames':12,'sd_reference':1,
            'new_assets':18,'combined_card_mapping':41,'reviewed_rejects':sum(r['verdict']=='reject' for r in reviews),
            'checks':['manual verdict','unique frame hashes','RGBA canvas/clear margins','file existence/hash'],
            'runtime_applied':False,'runtime_qa':'Claude pending'}
    write(ROOT/'docs/proposals/MIRA_DESIGN_SYNC_QA_20261011.json',report)
    print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':
    main()
