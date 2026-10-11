from package_claude_art_20261011 import D,fit,record,NN
from PIL import Image
import json
rest=D/'rest';target=rest/'characters/mira';target.mkdir(parents=True,exist_ok=True)
rows=[]
for id in ['rest_sit','rest_doze_1','rest_doze_2']:
 im=fit(rest/'raw'/('mira_'+id+'.png'),(128,128),8);im.save(target/(id+'.png'));rows.append(record(target/(id+'.png'),'미라 옆 까마귀 가면·상아 소매·검정 긴 치마·약병 통일, 자연스러운 접힌 무릎 및 두 손, 도트 휴식 자세.'))
(target/'manual_review.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
preview=Image.open(rest/'campfire_scene_v1.png').convert('RGBA')
im=Image.open(target/'rest_sit.png');preview.alpha_composite(im,(80,35))
logs=Image.open(rest/'campfire_logs_v1.png');preview.alpha_composite(logs,(208,144))
flame=Image.open(rest/'flame_2.png');preview.alpha_composite(flame,(226,123))
preview.resize((1440,900),NN).save(rest/'mira_camp_preview.png')
# Non-Mira draft explicitly excluded after user narrowed scope; preserve raw only.
(rest/'SCOPE.json').write_text(json.dumps({'character_scope':'mira_only','excluded':['raw/kalian_rest_sit.png'],'reason':'사용자: 다른 캐릭터 확정 아님. 미라만.'},ensure_ascii=False,indent=2),encoding='utf8')
print('Mira rest 3 reviewed; other characters excluded')

